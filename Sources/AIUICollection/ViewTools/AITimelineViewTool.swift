//
//  AITimelineViewTool.swift
//  AIUICollection
//
//  Render a vertical event timeline — pick this when ordering is meaningful
//  (itinerary, changelog, project milestones). Each row's timestamp comes
//  from the item's `dateCreated`.
//

import AIToolKit
import SwiftUI

public struct AITimelineViewTool: ViewTool {
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

    public static let name = "render_ai_timeline"
    public static let description = """
        Render a vertical event timeline. Pick this when ordering is \
        meaningful and each entry has a timestamp (itineraries, changelogs, \
        project milestones).
        """

    public static let inputSchema: ToolSchema = .object(
        properties: [
            "model": .string(description: ViewToolDefaults.modelHelp),
        ],
        required: ["model"]
    )

    @MainActor public func call(_ input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
