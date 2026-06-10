//
//  AIComparisonViewTool.swift
//  AIUICollection
//
//  Render side-by-side option columns. Pick when the answer is a small (≤4)
//  set the user is deciding between (pricing tiers, competing products,
//  plan upgrades).
//

import AIToolKit
import FoundationModels
import SwiftUI

public struct AIComparisonViewTool: ViewTool {
    @Generable
    public struct Input: Codable, Sendable {
        public let model: String
        public let title: String

        public init(model: String, title: String) {
            self.model = model
            self.title = title
        }
    }

    public typealias Render = @MainActor @Sendable (Input, ToolContext) async throws -> AnyView

    public let render: Render

    public init(render: @escaping Render) {
        self.render = render
    }

    public static let toolName = "render_ai_comparison"
    public static let toolDescription = """
        Render a side-by-side comparison of a small set of options (≤4) the \
        user is deciding between — pricing tiers, competing products, plan \
        upgrades.
        """

    public var name: String { Self.toolName }
    public var description: String { Self.toolDescription }

    @MainActor public func call(arguments input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
