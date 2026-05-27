//
//  AIKanbanViewTool.swift
//  AIUICollection
//
//  Render a multi-column kanban board. Pick when items group naturally by
//  stage or status (todo, in progress, done; deal stages; pipeline phases).
//

import AIToolKit
import SwiftUI

public struct AIKanbanViewTool: ViewTool {
    public struct Input: Codable, Sendable {
        public let model: String

        public init(model: String) {
            self.model = model
        }
    }

    public typealias Render = @MainActor @Sendable (Input, ToolContext) async throws -> AnyView

    public let render: Render

    public init(render: @escaping Render) {
        self.render = render
    }

    public static let name = "render_ai_kanban"
    public static let description = """
        Render a multi-column kanban board. Pick when items group naturally \
        by stage or status (Backlog → In progress → Done, deal stages, \
        pipeline phases). The host's render closure groups items into \
        columns.
        """

    public static let schema: ToolSchema = .object(
        properties: [
            "model": .string(description: ViewToolDefaults.modelHelp),
        ],
        required: ["model"]
    )

    public func makeView(_ input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
