//
//  AICarouselViewTool.swift
//  AIUICollection
//
//  Render a hero paging carousel — pick this for a handful of premium
//  options the user should swipe through (featured agents, packages,
//  recommendations).
//

import AIToolKit
import FoundationModels
import SwiftUI

public struct AICarouselViewTool: ViewTool {
    @Generable
    public struct Input: Codable, Sendable {
        public let model: String
        public let title: String

        public init(model: String, title: String) {
            self.model = model
            self.title = title
        }
    }

    public typealias Render = @MainActor @Sendable (Input) async throws -> AnyView

    public let render: Render

    public init(render: @escaping Render) {
        self.render = render
    }

    public static let toolName = "render_ai_carousel"
    public static let toolDescription = """
        Render a hero paging carousel for a small set of premium options the \
        user should swipe through (featured agents, packages, \
        recommendations). Each card supports an eyebrow ticker and optional \
        CTA via the host's render closure.
        """

    public var name: String { Self.toolName }
    public var description: String { Self.toolDescription }

    @MainActor public func call(arguments input: Input) async throws -> AnyView {
        try await render(input)
    }
}
