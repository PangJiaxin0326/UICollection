//
//  AIChartViewTool.swift
//  AIUICollection
//
//  Render a chart of comparative numerical data. The LLM picks the mark
//  encoding via `kind`: bar for discrete categories, line/area for ordered
//  series, point for scatter emphasis, sector for part-of-whole.
//

import AIToolKit
import SwiftUI

/// LLM-facing chart kind. Mirrors `AIChart.Kind` but lives at module scope
/// so it doesn't drag in `AIChart`'s generic parameter on the wire format.
public enum AIChartViewKind: String, Codable, Sendable, CaseIterable {
    case bar, line, area, point, sector
}

public struct AIChartViewTool: ViewTool {
    public struct Input: Codable, Sendable {
        public let model: String
        public let title: String
        public let subtitle: String
        public let kind: AIChartViewKind

        public init(model: String, title: String, subtitle: String, kind: AIChartViewKind = .bar) {
            self.model = model
            self.title = title
            self.subtitle = subtitle
            self.kind = kind
        }
    }

    public typealias Render = @MainActor @Sendable (Input, ToolContext) async throws -> AnyView

    public let render: Render

    public init(render: @escaping Render) {
        self.render = render
    }

    public static let name = "render_ai_chart"
    public static let description = """
        Render a chart for comparative numerical data across labeled \
        categories (sales by week, votes by option, share of total). Pick \
        `kind`: bar for discrete categories, line/area for ordered series, \
        point for scatter, sector for part-of-whole.
        """

    public static let inputSchema: ToolSchema = .object(
        properties: [
            "model": .string(description: ViewToolDefaults.modelHelp),
            "title": .string(description: "Chart title."),
            "subtitle": .string(description: "Short caption beneath the title."),
            "kind": .string(description: "One of: bar, line, area, point, sector."),
        ],
        required: ["model", "title", "subtitle", "kind"]
    )

    @MainActor public func call(_ input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
