//
//  AIGallery.swift
//  AIUICollection
//
//  Featured-photo gallery — collection template. The LLM picks this when
//  the answer is a set of visual artifacts the user wants to browse
//  (memories, generated images, search results, product photos).
//

import SwiftUI

public protocol AIGalleryRepresentable: AIListRepresentable {
    /// Caption shown over the featured tile.
    var caption: String { get }
}

extension AIGalleryRepresentable {
    public var caption: String { primaryDescription }
}

public struct AIGallery<T: AIGalleryRepresentable>: View {
    public let title: String
    public let items: [T]

    private let thumbColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    public init(title: String, items: [T]) {
        self.title = title
        self.items = items
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(.title2.bold()).padding(.horizontal)

                if let featured = items.first {
                    featuredTile(featured)
                        .padding(.horizontal)
                }

                if items.count > 1 {
                    LazyVGrid(columns: thumbColumns, spacing: 8) {
                        ForEach(items.dropFirst()) { thumbnail(for: $0) }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func featuredTile(_ item: T) -> some View {
        ZStack(alignment: .bottomLeading) {
            placeholder(for: item, height: 240)
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .bottom,
                endPoint: .center
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(item.caption)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(item.secondaryDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func thumbnail(for item: T) -> some View {
        ZStack(alignment: .bottomLeading) {
            placeholder(for: item, height: 110)
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func placeholder(for item: T, height: CGFloat) -> some View {
        LinearGradient(
            colors: [item.accentColor.opacity(0.95), item.accentColor.opacity(0.45)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}

private struct GallerySample: AIGalleryRepresentable {
    let id = UUID()
    let icon: String
    let primaryDescription: String
    let secondaryDescription: String
    let accentColor: Color
    var dateCreated: Date = .now
    var lastUpdated: Date = .now
}

#Preview("AIGallery — Generated images") {
    AIGallery(title: "Studio Ghibli concept art", items: [
        GallerySample(icon: "sparkles", primaryDescription: "Spirited forest", secondaryDescription: "Cinematic · 4K · 16:9", accentColor: .green),
        GallerySample(icon: "leaf.fill", primaryDescription: "Mossy ruins", secondaryDescription: "Painterly", accentColor: .mint),
        GallerySample(icon: "moon.stars.fill", primaryDescription: "Lantern night", secondaryDescription: "Painterly", accentColor: .purple),
        GallerySample(icon: "cloud.fill", primaryDescription: "Floating isles", secondaryDescription: "Watercolor", accentColor: .blue),
        GallerySample(icon: "drop.fill", primaryDescription: "Rain village", secondaryDescription: "Watercolor", accentColor: .teal),
        GallerySample(icon: "flame.fill", primaryDescription: "Fox shrine", secondaryDescription: "Painterly", accentColor: .red),
        GallerySample(icon: "wind", primaryDescription: "Sky pass", secondaryDescription: "Cinematic", accentColor: .cyan),
    ])
}
