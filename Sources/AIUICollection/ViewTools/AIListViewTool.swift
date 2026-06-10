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
import FoundationModels
import SwiftUI

public struct AIListViewTool: ViewTool {
    @Generable
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

    public static let toolName = "render_ai_list"
    public static let toolDescription = """
        Render the prototype sortable vertical list. Use when the answer is \
        a peer set of entities the user will browse and drill into \
        (contacts, documents, companies). The host owns detail-on-tap.
        """

    public var name: String { Self.toolName }
    public var description: String { Self.toolDescription }

    @MainActor public func call(arguments input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
