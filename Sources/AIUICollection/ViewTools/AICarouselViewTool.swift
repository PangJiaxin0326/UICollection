//
//  AICarouselViewTool.swift
//  AIUICollection
//
//  Render a hero paging carousel — pick this for a handful of premium
//  options the user should swipe through (featured agents, packages,
//  recommendations).
//

import AIToolKit
import SwiftUI

public struct AICarouselViewTool: ViewTool {
    public struct Input: Codable, Sendable {
        public let model: String
        public let title: String

        public init(model: String, title: String) {
            self.model = model
            self.title = title
        }
    }

    public typealias Render = @MainActor @Sendable (Input, ToolContext) async throws -> AnyView

    public let render: Render

    public init(render: @escaping Render) {
        self.render = render
    }

    public static let name = "render_ai_carousel"
    public static let description = """
        Render a hero paging carousel for a small set of premium options the \
        user should swipe through (featured agents, packages, \
        recommendations). Each card supports an eyebrow ticker and optional \
        CTA via the host's render closure.
        """

    public static let schema: ToolSchema = .object(
        properties: [
            "model": .string(description: ViewToolDefaults.modelHelp),
            "title": .string(description: "Section title shown above the carousel."),
        ],
        required: ["model", "title"]
    )

    public func makeView(_ input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
