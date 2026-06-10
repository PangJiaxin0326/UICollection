//
//  AIChartViewTool.swift
//  AIUICollection
//
//  Render a chart of comparative numerical data. The LLM picks the mark
//  encoding via `kind`: bar for discrete categories, line/area for ordered
//  series, point for scatter emphasis, sector for part-of-whole.
//

import AIToolKit
import FoundationModels
import SwiftUI

/// LLM-facing chart kind. Mirrors `AIChart.Kind` but lives at module scope
/// so it doesn't drag in `AIChart`'s generic parameter on the wire format.
public enum AIChartViewKind: String, Codable, Sendable, CaseIterable {
    case bar, line, area, point, sector
}

extension AIChartViewKind: Generable {
    public static var generationSchema: GenerationSchema {
        do {
            return try GenerationSchema(
                root: DynamicGenerationSchema(
                    name: "AIChartViewKind",
                    anyOf: Self.allCases.map(\.rawValue)
                ),
                dependencies: []
            )
        } catch {
            preconditionFailure("Invalid AIChartViewKind schema: \(error)")
        }
    }

    public init(_ content: GeneratedContent) throws {
        guard let rawValue = content.stringValue,
              let value = Self(rawValue: rawValue) else {
            throw GenericToolError(message: "Invalid AI chart view kind.")
        }
        self = value
    }

    public var generatedContent: GeneratedContent { .string(rawValue) }
}

public struct AIChartViewTool: ViewTool {
    @Generable
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

    public typealias Render = @MainActor @Sendable (Input) async throws -> AnyView

    public let render: Render

    public init(render: @escaping Render) {
        self.render = render
    }

    public static let toolName = "render_ai_chart"
    public static let toolDescription = """
        Render a chart for comparative numerical data across labeled \
        categories (sales by week, votes by option, share of total). Pick \
        `kind`: bar for discrete categories, line/area for ordered series, \
        point for scatter, sector for part-of-whole.
        """

    public var name: String { Self.toolName }
    public var description: String { Self.toolDescription }

    @MainActor public func call(arguments input: Input) async throws -> AnyView {
        try await render(input)
    }
}
