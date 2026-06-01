//
//  AICardViewTool.swift
//  AIUICollection
//
//  Render a hero feature card for a single rich entity (a recipe, a
//  recommended product, a flight option). Single-item — pair the `model`
//  key with an optional `id` when the host's model exposes more than one
//  candidate.
//

import AIToolKit
import SwiftUI

public struct AICardViewTool: ViewTool {
    public struct Input: Codable, Sendable {
        public let model: String
        public let id: String?

        public init(model: String, id: String? = nil) {
            self.model = model
            self.id = id
        }
    }

    public typealias Render = @MainActor @Sendable (Input, ToolContext) async throws -> AnyView

    public let render: Render

    public init(render: @escaping Render) {
        self.render = render
    }

    public static let name = "render_ai_card"
    public static let description = """
        Render a hero feature card for a single rich entity worth pausing on \
        (a recipe, a recommended product, a flight option). Use when the \
        answer is one item, not a list.
        """

    public static let inputSchema: ToolSchema = .object(
        properties: [
            "model": .string(description: ViewToolDefaults.modelHelp),
            "id": .string(description: "Optional id of the specific entity within the model. Omit when the model has one canonical item."),
        ],
        required: ["model"]
    )

    @MainActor public func call(_ input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
