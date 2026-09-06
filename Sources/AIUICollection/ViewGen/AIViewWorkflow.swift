//
//  AIViewWorkflow.swift
//  AIUICollection
//
//  Drives one view-generation run through the toolkit's native
//  `WorkflowProfile` (select-then-work) over any `FoundationModels`
//  `LanguageModel`. This is the host glue the experiment and the app share:
//
//    1. SCOPE — intent + the template catalogue (rendered by the profile),
//       tool calling disallowed; the reply contract (the `ToolSelection` JSON
//       schema + an example) rides in the prompt and is parsed host-side. One
//       round, ~10 output tokens.
//    2. WORK — intent again + the selected template tool(s); scope history
//       cut; the host stops the session (`WorkTurnMonitor`) the moment a
//       finishing output (a created view) lands.
//
//  The created view is a side effect on the catalog's `AIViewStage`; the run
//  result reports the typed selection and the produced `AIViewSpec`s.
//

import Foundation
import Synchronization
import FoundationModels
import AIToolKit

/// Outcome of one run: what the router selected and what got created.
public struct AIViewRunResult: Sendable {
    /// The validated template tool names the scope step chose.
    public let selection: [String]
    /// The specs created during the work step (latest is `last`).
    public let specs: [AIViewSpec]
    /// A session-level error string, if the run threw.
    public let sessionError: String?

    public var latest: AIViewSpec? { specs.last }

    public init(selection: [String], specs: [AIViewSpec], sessionError: String?) {
        self.selection = selection
        self.specs = specs
        self.sessionError = sessionError
    }
}

public struct AIViewWorkflowRunner: Sendable {
    public let catalog: AIViewCatalog
    public let temperature: Double

    public init(catalog: AIViewCatalog, temperature: Double = 0.2) {
        self.catalog = catalog
        self.temperature = temperature
    }

    /// Nonisolated on purpose: the session machinery runs off the main actor,
    /// so the profile is built and sent from a nonisolated region. The catalog
    /// (main-actor) is reached only through `await` snapshots; the created view
    /// is recorded on the stage from inside the tool call.
    public func run<M: LanguageModel>(intent: String, model: M) async -> AIViewRunResult {
        guard await catalog.beginRun() else {
            return AIViewRunResult(selection: [], specs: [], sessionError: "This catalog already has an active run.")
        }
        let result = await runAdmitted(intent: intent, model: model)
        await catalog.endRun()
        return result
    }

    private func runAdmitted<M: LanguageModel>(intent: String, model: M) async -> AIViewRunResult {
        await catalog.resetStage()

        let finishing: [any FinishingTool] = await catalog.finishingTools
        let finishingTools: [any Tool] = finishing.map { $0 as any Tool }
        let finishingNames = finishing.map(\.name)
        let sources: [any AIDataSource] = catalog.sources

        let state = RunState()
        let monitor = WorkTurnMonitor(finishingToolNames: finishingNames)
        let temperature = self.temperature

        // The view creators register no assistive tools, so the work surface is
        // simply the selected finishing tools. Invalid selections never act.
        let workTools: @Sendable () -> [any Tool] = {
            let selection = state.selection
            let chosen = finishing.filter { selection.contains($0.name) }
            return chosen.map { $0 as any Tool }
        }

        let profile = WorkflowProfile(
            scopeInstructions: { AIViewInstructions.scope() },
            workInstructions: { AIViewInstructions.work(sources: sources) },
            catalogue: finishingTools,
            workTools: workTools
        )
        .model(model)
        .temperature(temperature)
        .historyTransform { entries in
            let cut = state.cutIndex
            guard cut > 0 else { return entries }
            return entries.enumerated().compactMap { index, entry in
                if index == 0, case .instructions = entry { return entry }
                return index >= cut ? entry : nil
            }
        }
        .onToolCall { call in
            if state.stage == .work { monitor.recordCall(call) }
        }
        .onToolOutput { call, _ in
            guard state.stage == .work else { return }
            if monitor.recordOutput(call) { throw WorkflowStageComplete() }
        }
        .transcriptErrorHandlingPolicy(.preserveTranscript)

        let session = LanguageModelSession(profile: profile)
        var sessionError: String?
        do {
            // Step 1 — scope: prompt-schema selection (no guided generation).
            let scopePrompt = """
            User request: \(intent)

            Select the view template this request needs.

            \(Self.selectionSchemaPrompt())
            """
            let reply = try await session.respond(to: scopePrompt).content
            let selection = Self.parseSelection(from: reply) ?? ToolSelection(toolNames: [])
            state.selection = selection.validated(against: finishingNames)
            guard !state.selection.isEmpty else {
                return AIViewRunResult(selection: [], specs: [], sessionError: "No valid view template was selected.")
            }
            try Task.checkCancellation()

            // Flip to work: cut all scope history; the selection crossed
            // host-side via `state`.
            state.cutIndex = session.transcript.count
            session.properties.workflowStage = .work
            state.stage = .work

            // Step 2 — work: execute once; a failed tool may already have effects.
            let workPrompt = """
            User request: \(intent)

            Build the view now.
            """
            do {
                _ = try await session.respond(to: workPrompt).content
            } catch {
                let unwrapped = (error as? LanguageModelSession.ToolCallError)?.underlyingError ?? error
                if !(unwrapped is WorkflowStageComplete) { throw error }
            }
        } catch {
            sessionError = "session error: \(error)"
        }

        let specs = await catalog.producedSpecs()
        return AIViewRunResult(
            selection: state.selection,
            specs: specs,
            sessionError: sessionError
        )
    }

    // MARK: - Prompt-schema selection (the proven, cheaper-than-guided path)

    /// The scope reply contract rendered into the prompt: the official JSON
    /// encoding of `ToolSelection.generationSchema` plus one example.
    static func selectionSchemaPrompt() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let schemaJSON = (try? encoder.encode(ToolSelection.generationSchema))
            .map { String(decoding: $0, as: UTF8.self) }
            ?? #"{"properties":{"toolNames":{"items":{"type":"string"},"type":"array"}},"required":["toolNames"],"type":"object"}"#
        return """
        Reply with ONLY a JSON object matching this JSON schema — no prose, no \
        code fences:
        \(schemaJSON)

        Example — a request best shown as a chart would be answered:
        {"toolNames": ["create_chart"]}
        """
    }

    /// Parses the outermost JSON object of the scope reply into a typed
    /// `ToolSelection`, via the same `GeneratedContent` path guided generation
    /// uses. `nil` means selection failed; callers must not expand tool access.
    static func parseSelection(from reply: String) -> ToolSelection? {
        guard let start = reply.firstIndex(of: "{"),
              let end = reply.lastIndex(of: "}"),
              start < end
        else { return nil }
        guard let content = try? GeneratedContent(json: String(reply[start...end]))
        else { return nil }
        return try? ToolSelection(content)
    }
}

/// Host-side run state mirrored for the profile hooks (which can't read session
/// properties). Lock-based: the hooks and the history transform run
/// synchronously with the session's request machinery.
private final class RunState: Sendable {
    private struct State: Sendable {
        var stage: WorkflowStage = .scope
        var selection: [String] = []
        var cutIndex: Int = 0
    }
    private let state = Mutex(State())

    var stage: WorkflowStage {
        get { state.withLock { $0.stage } }
        set { state.withLock { $0.stage = newValue } }
    }

    var selection: [String] {
        get { state.withLock { $0.selection } }
        set { state.withLock { $0.selection = newValue } }
    }

    var cutIndex: Int {
        get { state.withLock { $0.cutIndex } }
        set { state.withLock { $0.cutIndex = newValue } }
    }
}
