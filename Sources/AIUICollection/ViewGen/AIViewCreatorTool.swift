//
//  AIViewCreatorTool.swift
//  AIUICollection
//
//  THE finishing tool: an API for creating views. One instance per template
//  (`create_list`, `create_chart`, …). It is the user-visible action the
//  view-generation workflow exists to call — the scope step selects which
//  template tool fits, the work step calls it once with a data-source key.
//
//  Data-fetching `AIDataSource`s (assistive tools) are PASSED IN as bindings.
//  The model never sees rows: it emits a source *key*; `call` resolves that key
//  to a bound source, fetches the real rows host-side, records a renderable
//  view on the stage, and returns a compact confirmation string.
//

import Foundation
import FoundationModels
import AIToolKit
import SwiftUI

/// The arguments for creating a view. Deliberately minimal (the project's
/// "less text, more visual" rule): a source key, plus an optional short title
/// and an optional style hint. Everything else is host-defaulted — good
/// defaults beat a wide schema the model must fill.
@Generable
public struct AIViewRequest: Sendable {
    @Guide(description: "The key of the data source to display, exactly as listed in the instructions.")
    public var dataSource: String

    @Guide(description: "Optional short title. Omit it when the data speaks for itself.")
    public var title: String?

    @Guide(description: "Optional style hint. chart: bar, line, area, point, or sector. grid: 2 or 3 columns.")
    public var style: String?

    public init(dataSource: String, title: String? = nil, style: String? = nil) {
        self.dataSource = dataSource
        self.title = title
        self.style = style
    }
}

/// A view-creator finishing tool for one template. Holds its bound data
/// sources and the host stage; building the view is its side effect.
public struct AIViewCreatorTool: FinishingTool {
    public typealias Arguments = AIViewRequest
    public typealias Output = String

    public let template: AIViewTemplate
    private let sources: [any AIDataSource]
    private let stage: AIViewStage

    public init(template: AIViewTemplate, sources: [any AIDataSource], stage: AIViewStage) {
        self.template = template
        self.sources = sources
        self.stage = stage
    }

    public var name: String { template.toolName }
    public var description: String { template.routingHint }
    public var progressText: String? { template.progressText }

    /// Data sources are bindings, NOT model-callable: nothing assistive is
    /// registered, so the work step's tool surface is just this one tool.
    public var registeredAssistiveTools: [any Tool] { [] }

    public func call(arguments: AIViewRequest) async throws -> String {
        guard let source = resolve(arguments.dataSource) else {
            let keys = sources.map(\.key).joined(separator: ", ")
            throw GenericToolError(
                message: "Unknown data source '\(arguments.dataSource)'. Valid keys: \(keys).",
                isRetriable: true
            )
        }

        // Real rows, fetched host-side. They go into the view binding, never
        // back to the model.
        let records = await source.fetch()
        let spec = AIViewSpec(
            template: template.rawValue,
            dataSourceKey: source.key,
            title: arguments.title,
            style: arguments.style,
            itemCount: records.count
        )

        let template = self.template
        let title = arguments.title
        let style = arguments.style
        let stage = self.stage
        await MainActor.run {
            stage.record(spec: spec) { presentation in
                AIViewBuilder.build(
                    template: template, records: records,
                    title: title, style: style, presentation: presentation
                )
            }
        }

        return "rendered \(template.toolName) ← \(source.key) (\(records.count) items)"
    }

    private func resolve(_ raw: String) -> (any AIDataSource)? {
        let needle = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = sources.first(where: { $0.key.lowercased() == needle }) { return exact }
        // Salvage a decorated reference ("the contacts source") the way the
        // toolkit's selection parser salvages tool names.
        return sources.first { needle.contains($0.key.lowercased()) }
    }
}
