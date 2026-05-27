//
//  AIListViewTool.swift
//  AIUICollection
//
//  Render the prototype sortable vertical list. The LLM picks this when the
//  answer is a peer set of entities the user will browse and drill into.
//  The host's `render` closure resolves the `model` key into the actual
//  items + detail-tap view; this tool just declares the schema and routes.
//

import AIToolKit
import SwiftUI

public struct AIListViewTool: ViewTool {
    public struct Input: Codable, Sendable {
        public let model: String
        public let sortedBy: AISortOption?

        public init(model: String, sortedBy: AISortOption? = nil) {
            self.model = model
            self.sortedBy = sortedBy
        }
    }

    public typealias Render = @MainActor @Sendable (Input, ToolContext) async throws -> AnyView

    public let render: Render

    public init(render: @escaping Render) {
        self.render = render
    }

    public static let name = "render_ai_list"
    public static let description = """
        Render the prototype sortable vertical list. Use when the answer is \
        a peer set of entities the user will browse and drill into \
        (contacts, documents, companies). The host owns detail-on-tap.
        """

    public static let schema: ToolSchema = .object(
        properties: [
            "model": .string(description: ViewToolDefaults.modelHelp),
            "sortedBy": .string(description: "Initial sort: 'Most recent', 'Oldest first', 'A–Z', 'Z–A'."),
        ],
        required: ["model"]
    )

    public func makeView(_ input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
