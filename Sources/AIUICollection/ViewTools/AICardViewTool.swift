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
import FoundationModels
import SwiftUI

public struct AICardViewTool: ViewTool {
    @Generable
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

    public static let toolName = "render_ai_card"
    public static let toolDescription = """
        Render a hero feature card for a single rich entity worth pausing on \
        (a recipe, a recommended product, a flight option). Use when the \
        answer is one item, not a list.
        """

    public var name: String { Self.toolName }
    public var description: String { Self.toolDescription }

    @MainActor public func call(arguments input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
