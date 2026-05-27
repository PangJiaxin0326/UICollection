//
//  AIGalleryViewTool.swift
//  AIUICollection
//
//  Render a featured-photo gallery — hero tile up top, 3-column thumbnail
//  grid below. Pick this when the answer is a visual set (memories,
//  generated images, search results, product photos).
//

import AIToolKit
import SwiftUI

public struct AIGalleryViewTool: ViewTool {
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

    public static let name = "render_ai_gallery"
    public static let description = """
        Render a featured-photo gallery. The first item becomes the hero \
        tile; the rest fill a 3-column thumbnail grid below.
        """

    public static let schema: ToolSchema = .object(
        properties: [
            "model": .string(description: ViewToolDefaults.modelHelp),
            "title": .string(description: "Gallery title."),
        ],
        required: ["model", "title"]
    )

    public func makeView(_ input: Input, in context: ToolContext) async throws -> AnyView {
        try await render(input, context)
    }
}
