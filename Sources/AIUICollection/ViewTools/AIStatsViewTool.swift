//
//  AIStatsViewTool.swift
//  AIUICollection
//
//  Render a KPI / metric dashboard. Each tile shows a headline number, an
//  optional unit, and an optional signed delta pill.
//

import AIToolKit
import FoundationModels
import SwiftUI

public struct AIStatsViewTool: ViewTool {
    @Generable
    public struct Input: Codable, Sendable {
        public let model: String
        public let title: String
        public let columns: Int?

        public init(model: String, title: String, columns: Int? = nil) {
            self.model = model
            self.title = title
            self.columns = columns
        }
    }

    public typealias Render = @MainActor @Sendable (Input) async throws -> AnyView

    public let render: Render

    public init(render: @escaping Render) {
        self.render = render
    }

    public static let toolName = "render_ai_stats"
    public static let toolDescription = """
        Render a KPI / metric dashboard as a grid of tiles. Each tile carries \
        a headline number, optional unit (e.g. '%', 'ms', 'k'), and optional \
        signed delta percent for period-over-period change.
        """

    public var name: String { Self.toolName }
    public var description: String { Self.toolDescription }

    @MainActor public func call(arguments input: Input) async throws -> AnyView {
        try await render(input)
    }
}
