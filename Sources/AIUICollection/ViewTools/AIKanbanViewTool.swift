//
//  AIKanbanViewTool.swift
//  AIUICollection
//
//  Render a multi-column kanban board. Pick when items group naturally by
//  stage or status (todo, in progress, done; deal stages; pipeline phases).
//

import AIToolKit
import FoundationModels
import SwiftUI

public struct AIKanbanViewTool: ViewTool {
    @Generable
    public struct Input: Codable, Sendable {
        public let model: String

        public init(model: String) {
            self.model = model
        }
    }

    public typealias Render = @MainActor @Sendable (Input) async throws -> AnyView

    public let render: Render

    public init(render: @escaping Render) {
        self.render = render
    }

    public static let toolName = "render_ai_kanban"
    public static let toolDescription = """
        Render a multi-column kanban board. Pick when items group naturally \
        by stage or status (Backlog → In progress → Done, deal stages, \
        pipeline phases). The host's render closure groups items into \
        columns.
        """

    public var name: String { Self.toolName }
    public var description: String { Self.toolDescription }

    @MainActor public func call(arguments input: Input) async throws -> AnyView {
        try await render(input)
    }
}
