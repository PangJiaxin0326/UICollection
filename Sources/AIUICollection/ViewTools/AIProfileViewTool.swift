//
//  AIProfileViewTool.swift
//  AIUICollection
//
//  Render an identity card for a single entity (a person, an agent, an
//  org, a place). Single-item — pair `model` with an optional `id` when the
//  host's model exposes more than one candidate.
//

import AIToolKit
import FoundationModels
import SwiftUI

public struct AIProfileViewTool: ViewTool {
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

    public static let toolName = "render_ai_profile"
    public static let toolDescription = """
        Render an identity card for a single entity (a person, an agent, an \
        org, a place). Includes a hero banner, avatar/monogram, bio, and an \
        optional stat row.
        """

    public var name: String { Self.toolName }
    public var description: String { Self.toolDescription }

    @MainActor public func call(arguments input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
