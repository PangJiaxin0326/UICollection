//
//  ProgressiveViewWorkflow.swift
//  AIUICollection
//
//  Drives one composite-screen run through `ProgressiveWorkflowProfile`: plan
//  once, then build one component per step, rendering each the moment its step
//  lands. The catalog's `AIViewStage` accumulates the components, so a host
//  observing it sees the screen fill in — streaming — rather than waiting for
//  the whole UI.
//

import Foundation
import FoundationModels
import AIToolKit

/// One component as it streamed in: which step, its spec, and how long after
/// the run started it became visible (the streaming latency).
public struct ProgressiveComponent: Sendable {
    public let step: Int
    public let spec: AIViewSpec
    public let secondsSinceStart: Double
}

/// Outcome of a progressive run: the plan and the components that streamed in.
public struct ProgressiveRunResult: Sendable {
    public let plan: [String]
    public let components: [ProgressiveComponent]
    public let sessionError: String?

    public var timeToFirstComponent: Double? { components.first?.secondsSinceStart }

    public init(plan: [String], components: [ProgressiveComponent], sessionError: String?) {
        self.plan = plan
        self.components = components
        self.sessionError = sessionError
    }
}

public struct ProgressiveViewWorkflowRunner: Sendable {
    public let catalog: AIViewCatalog
    public let temperature: Double
    public let maxComponents: Int

    public init(catalog: AIViewCatalog, temperature: Double = 0.2, maxComponents: Int = 4) {
        self.catalog = catalog
        self.temperature = temperature
        self.maxComponents = maxComponents
    }

    /// Nonisolated for the same reason as the plain runner: the profile is
    /// built and sent off the main actor; the catalog is reached via `await`.
    /// `onComponent` fires as each component renders — the streaming hook.
    public func run<M: LanguageModel>(
        intent: String,
        model: M,
        onComponent: (@Sendable (ProgressiveComponent) -> Void)? = nil
    ) async -> ProgressiveRunResult {
        await catalog.resetStage()

        let finishing: [any FinishingTool] = await catalog.finishingTools
        let finishingTools: [any Tool] = finishing.map { $0 as any Tool }
        let finishingNames = finishing.map(\.name)
        let finishingByName = Dictionary(
            uniqueKeysWithValues: finishing.map { ($0.name, $0) }
        )
        let sources: [any AIDataSource] = catalog.sources

        let state = ProgressiveState()
        let temperature = self.temperature

        let profile = ProgressiveWorkflowProfile(
            planInstructions: { AIViewInstructions.progressivePlan() },
            stepInstructions: { index in
                AIViewInstructions.progressiveStep(
                    intent: intent,
                    plan: state.plan,
                    index: index,
                    sources: sources,
                    usedSourceKeys: state.usedSources
                )
            },
            catalogue: finishingTools,
            stepTools: { index in
                let plan = state.plan
                guard index < plan.count, let tool = finishingByName[plan[index]] else { return [] }
                return [tool as any Tool]
            }
        )
        .model(model)
        .temperature(temperature)
        // Cut everything before the current step: each build is a fresh, cheap
        // turn (its instructions carry the running context).
        .historyTransform { entries in
            let cut = state.cutIndex
            guard cut > 0 else { return entries }
            return entries.enumerated().compactMap { index, entry in
                if index == 0, case .instructions = entry { return entry }
                return index >= cut ? entry : nil
            }
        }
        // Stop a build step the moment its one component lands.
        .onToolOutput { call, _ in
            guard state.stage == .build else { return }
            if finishingNames.contains(call.toolName) {
                throw WorkflowStageComplete()
            }
        }
        .transcriptErrorHandlingPolicy(.preserveTranscript)

        let session = LanguageModelSession(profile: profile)
        let started = ContinuousClock.now
        var sessionError: String?
        var components: [ProgressiveComponent] = []

        do {
            // Step 1 — plan: an ordered component list, prompt-schema parsed.
            let planPrompt = """
            User request: \(intent)

            Plan the composite screen: an ordered list of components.

            \(Self.planSchemaPrompt())
            """
            let reply = try await session.respond(to: planPrompt).content
            let selection = AIViewWorkflowRunner.parseSelection(from: reply)
                ?? ToolSelection(toolNames: [])
            state.plan = Self.orderedPlan(
                from: selection, finishingNames: finishingNames, cap: maxComponents
            )

            // Steps 2…N — build one component each, host-stopped, rendered.
            for index in 0..<state.plan.count {
                state.cutIndex = session.transcript.count
                state.step = index
                state.stage = .build
                session.properties.progressiveStage = .build
                session.properties.progressiveStep = index

                let buildPrompt = "Build component \(index + 1) now."
                do {
                    _ = try await session.respond(to: buildPrompt).content
                } catch {
                    let unwrapped =
                        (error as? LanguageModelSession.ToolCallError)?.underlyingError ?? error
                    if !(unwrapped is WorkflowStageComplete) { throw error }
                }

                guard let spec = await catalog.producedSpecs().last else { continue }
                let elapsed = (ContinuousClock.now - started).seconds
                state.usedSources.append(spec.dataSourceKey)
                let component = ProgressiveComponent(
                    step: index, spec: spec, secondsSinceStart: elapsed
                )
                components.append(component)
                onComponent?(component)
            }
        } catch {
            sessionError = "session error: \(error)"
        }

        return ProgressiveRunResult(
            plan: state.plan, components: components, sessionError: sessionError
        )
    }

    /// The plan reply contract: the `ToolSelection` schema with an ORDERED,
    /// multi-element example (order is the build order).
    static func planSchemaPrompt() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let schemaJSON = (try? encoder.encode(ToolSelection.generationSchema))
            .map { String(decoding: $0, as: UTF8.self) }
            ?? #"{"properties":{"toolNames":{"items":{"type":"string"},"type":"array"}},"required":["toolNames"],"type":"object"}"#
        return """
        Reply with ONLY a JSON object matching this JSON schema — no prose, no \
        code fences. The array order is the order the components are built:
        \(schemaJSON)

        Example — a dashboard might be answered:
        {"toolNames": ["create_stats", "create_chart", "create_list"]}
        """
    }

    /// Validate the plan against the catalogue while PRESERVING the model's
    /// order (unlike `ToolSelection.validated`, which sorts to catalogue
    /// order). Repeats are allowed; capped at `cap`.
    static func orderedPlan(
        from selection: ToolSelection, finishingNames: [String], cap: Int
    ) -> [String] {
        var plan: [String] = []
        for raw in selection.toolNames {
            let needle = raw.lowercased()
            if let exact = finishingNames.first(where: { $0.lowercased() == needle }) {
                plan.append(exact)
            } else if let match = finishingNames.first(where: { needle.contains($0.lowercased()) }) {
                plan.append(match)
            }
        }
        return Array(plan.prefix(cap))
    }
}

/// Host-side run state mirrored for the profile hooks/instructions (which run
/// synchronously with the session machinery). Lock-based.
private final class ProgressiveState: @unchecked Sendable {
    private let lock = NSLock()
    private var _stage: ProgressiveStage = .plan
    private var _step = 0
    private var _plan: [String] = []
    private var _used: [String] = []
    private var _cutIndex = 0

    var stage: ProgressiveStage {
        get { lock.lock(); defer { lock.unlock() }; return _stage }
        set { lock.lock(); _stage = newValue; lock.unlock() }
    }
    var step: Int {
        get { lock.lock(); defer { lock.unlock() }; return _step }
        set { lock.lock(); _step = newValue; lock.unlock() }
    }
    var plan: [String] {
        get { lock.lock(); defer { lock.unlock() }; return _plan }
        set { lock.lock(); _plan = newValue; lock.unlock() }
    }
    var usedSources: [String] {
        get { lock.lock(); defer { lock.unlock() }; return _used }
        set { lock.lock(); _used = newValue; lock.unlock() }
    }
    var cutIndex: Int {
        get { lock.lock(); defer { lock.unlock() }; return _cutIndex }
        set { lock.lock(); _cutIndex = newValue; lock.unlock() }
    }
}

private extension Duration {
    var seconds: Double {
        let c = components
        return Double(c.seconds) + Double(c.attoseconds) / 1e18
    }
}
