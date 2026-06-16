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
        await catalog.resetStage()

        let finishing: [any FinishingTool] = await catalog.finishingTools
        let finishingTools: [any Tool] = finishing.map { $0 as any Tool }
        let finishingNames = finishing.map(\.name)
        let sources: [any AIDataSource] = catalog.sources

        let state = RunState()
        let monitor = WorkTurnMonitor(finishingToolNames: finishingNames)
        let temperature = self.temperature

        // The view creators register no assistive tools, so the work surface is
        // simply the selected finishing tools (the full set if selection empty).
        let workTools: @Sendable () -> [any Tool] = {
            let selection = state.selection
            let chosen = selection.isEmpty
                ? finishing
                : finishing.filter { selection.contains($0.name) }
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

            // Flip to work: cut all scope history; the selection crossed
            // host-side via `state`.
            state.cutIndex = session.transcript.count
            session.properties.workflowStage = .work
            state.stage = .work

            // Step 2 — work: one corrective retry budget for a bad source key.
            let workPrompt = """
            User request: \(intent)

            Build the view now.
            """
            var prompt = workPrompt
            for attempt in 0...2 {
                do {
                    _ = try await session.respond(to: prompt).content
                    break
                } catch {
                    let unwrapped =
                        (error as? LanguageModelSession.ToolCallError)?.underlyingError ?? error
                    if unwrapped is WorkflowStageComplete { break }
                    guard attempt < 2 else { throw error }
                    prompt = """
                    Your previous attempt failed: \(error)

                    Call exactly ONE template tool with a `dataSource` set to a \
                    valid key from the list, then finish. \(workPrompt)
                    """
                }
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
    /// uses. `nil` → the caller falls back to the full catalogue.
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
private final class RunState: @unchecked Sendable {
    private let lock = NSLock()
    private var _stage: WorkflowStage = .scope
    private var _selection: [String] = []
    private var _cutIndex = 0

    var stage: WorkflowStage {
        get { lock.lock(); defer { lock.unlock() }; return _stage }
        set { lock.lock(); _stage = newValue; lock.unlock() }
    }
    var selection: [String] {
        get { lock.lock(); defer { lock.unlock() }; return _selection }
        set { lock.lock(); _selection = newValue; lock.unlock() }
    }
    var cutIndex: Int {
        get { lock.lock(); defer { lock.unlock() }; return _cutIndex }
        set { lock.lock(); _cutIndex = newValue; lock.unlock() }
    }
}
