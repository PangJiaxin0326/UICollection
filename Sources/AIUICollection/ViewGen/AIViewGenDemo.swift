//
//  AIViewGenDemo.swift
//  AIUICollection
//
//  Proof that the FinishingTool really creates a view — provider-free. It
//  invokes one `AIViewCreatorTool` directly (no LLM, no network), then renders
//  whatever the tool recorded on the stage. Swap the direct call for
//  `AIViewWorkflowRunner.run(intent:model:)` to drive the same path from a
//  model.
//

import SwiftUI

/// Renders the view a single creator tool produces for a chosen data source.
@MainActor
public struct AIGeneratedView: View {
    private let catalog: AIViewCatalog
    private let template: AIViewTemplate
    private let dataSource: String
    private let title: String?
    private let style: String?

    @State private var rendered: AIRenderedView?
    @State private var failure: String?

    public init(
        catalog: AIViewCatalog = .sample(),
        template: AIViewTemplate,
        dataSource: String,
        title: String? = nil,
        style: String? = nil
    ) {
        self.catalog = catalog
        self.template = template
        self.dataSource = dataSource
        self.title = title
        self.style = style
    }

    public var body: some View {
        Group {
            if let rendered {
                rendered.makeView(.standalone)
            } else if let failure {
                ContentUnavailableView("Could not build view", systemImage: "exclamationmark.triangle", description: Text(failure))
            } else {
                ProgressView()
            }
        }
        .task { await generate() }
    }

    private func generate() async {
        guard let tool = catalog.finishing.first(where: { $0.template == template }) else {
            failure = "No tool for template \(template.rawValue)"
            return
        }
        do {
            _ = try await tool.call(
                arguments: AIViewRequest(dataSource: dataSource, title: title, style: style)
            )
            rendered = catalog.stage.latest
        } catch {
            failure = "\(error)"
        }
    }
}

#Preview("Generated chart") {
    AIGeneratedView(template: .chart, dataSource: "revenue_by_week", title: "Weekly revenue", style: "bar")
}

#Preview("Generated stats") {
    AIGeneratedView(template: .stats, dataSource: "product_kpis", title: "This week")
}

#Preview("Generated gallery") {
    AIGeneratedView(template: .gallery, dataSource: "trip_photos", title: "Kyoto")
}

#Preview("Generated timeline") {
    AIGeneratedView(template: .timeline, dataSource: "order_history")
}
