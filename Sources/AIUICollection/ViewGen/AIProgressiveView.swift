//
//  AIProgressiveView.swift
//  AIUICollection
//
//  The streaming face of the progressive workflow: it observes the catalog's
//  stage and renders an `AIScreen` whose sections appear one by one as each
//  build step lands. Drive it with `ProgressiveViewWorkflowRunner.run` (LLM) or
//  the provider-free `demoBuild` (previews) — either way the view fills in.
//

import SwiftUI

@MainActor
public struct AIProgressiveView: View {
    private let catalog: AIViewCatalog
    private let title: String
    private let build: @Sendable () async -> Void

    @State private var isStreaming = true

    /// - Parameters:
    ///   - catalog: the surface whose stage accumulates components.
    ///   - title: the screen title.
    ///   - build: populates the stage progressively (the LLM runner, or
    ///     `demoBuild`). The view flips out of the streaming state when it ends.
    public init(
        catalog: AIViewCatalog,
        title: String,
        build: @escaping @Sendable () async -> Void
    ) {
        self.catalog = catalog
        self.title = title
        self.build = build
    }

    public var body: some View {
        AIScreen(title: title, sections: sections, isStreaming: isStreaming)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: catalog.stage.renders.count)
            .animation(.easeInOut, value: isStreaming)
            .task {
                await build()
                isStreaming = false
            }
    }

    private var sections: [AIScreenSection] {
        catalog.stage.renders.map { rendered in
            let source = catalog.sources.first { $0.key == rendered.spec.dataSourceKey }
            return AIScreenSection(
                id: rendered.id,
                title: rendered.spec.title ?? source?.key.aiHumanized ?? rendered.spec.template.capitalized,
                subtitle: source?.description,
                content: rendered.makeView(.section)
            )
        }
    }

    /// Provider-free streaming for previews/tests: build the given
    /// (template, source) steps directly, with a pause between each to mimic
    /// the per-component latency of the real workflow.
    public static func demoBuild(
        catalog: AIViewCatalog,
        steps: [(template: AIViewTemplate, source: String, style: String?)],
        pause: Duration = .milliseconds(650)
    ) async {
        catalog.resetStage()
        for step in steps {
            try? await Task.sleep(for: pause)
            guard let tool = catalog.finishing.first(where: { $0.template == step.template }) else { continue }
            _ = try? await tool.call(
                arguments: AIViewRequest(dataSource: step.source, style: step.style)
            )
        }
    }
}

extension String {
    /// "revenue_by_week" → "Revenue by week".
    public var aiHumanized: String {
        let spaced = replacingOccurrences(of: "_", with: " ")
        return spaced.prefix(1).uppercased() + spaced.dropFirst()
    }
}

#Preview("Progressive — sales overview") {
    let catalog = AIViewCatalog.sample()
    return AIProgressiveView(catalog: catalog, title: "Sales overview") {
        await AIProgressiveView.demoBuild(catalog: catalog, steps: [
            (.stats, "product_kpis", nil),
            (.chart, "revenue_by_week", "bar"),
            (.chart, "sales_by_month", "line"),
            (.list, "order_history", nil),
        ])
    }
}

#Preview("Progressive — morning brief") {
    let catalog = AIViewCatalog.sample()
    return AIProgressiveView(catalog: catalog, title: "Good morning") {
        await AIProgressiveView.demoBuild(catalog: catalog, steps: [
            (.stats, "health_today", nil),
            (.timeline, "order_history", nil),
            (.gallery, "trip_photos", nil),
        ])
    }
}
