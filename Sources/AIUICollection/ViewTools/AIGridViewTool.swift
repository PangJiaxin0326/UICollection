//
//  AIGridViewTool.swift
//  AIUICollection
//
//  Render a bento-style adaptive grid of icon-led tiles. For KPI / metric
//  dashboards, prefer `AIStatsViewTool` (same grid shell, specialized tile).
//

import AIToolKit
import FoundationModels
import SwiftUI

public struct AIGridViewTool: ViewTool {
    @Generable
    public struct Input: Codable, Sendable {
        public let model: String
        public let title: String?
        public let columns: Int?

        public init(model: String, title: String? = nil, columns: Int? = nil) {
            self.model = model
            self.title = title
            self.columns = columns
        }
    }

    public typealias Render = @MainActor @Sendable (Input, ToolContext) async throws -> AnyView

    public let render: Render

    public init(render: @escaping Render) {
        self.render = render
    }

    public static let toolName = "render_ai_grid"
    public static let toolDescription = """
        Render a bento-style adaptive grid of icon-led tiles. Use for menus, \
        action launchers, capability overviews — peer items with no inherent \
        ordering.
        """

    public var name: String { Self.toolName }
    public var description: String { Self.toolDescription }

    @MainActor public func call(arguments input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
