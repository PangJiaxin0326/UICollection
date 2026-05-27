//
//  AIGrid.swift
//  AIUICollection
//
//  Bento-style adaptive grid. Generic over its `Tile` so specialized
//  templates (e.g. `AIStats`) can reuse the grid shell with their own
//  cell rendering. Falls back to `AIDefaultGridTile` when no builder is
//  supplied — icon-on-gradient with title + subtitle, the standard look.
//

import SwiftUI

public struct AIGrid<T: AIListRepresentable, Tile: View>: View {
    public let title: String?
    public let items: [T]
    public let columns: Int
    public let tile: (T) -> Tile

    public init(
        title: String? = nil,
        items: [T],
        columns: Int = 2,
        @ViewBuilder tile: @escaping (T) -> Tile
    ) {
        self.title = title
        self.items = items
        self.columns = max(1, columns)
        self.tile = tile
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let title {
                    Text(title)
                        .font(.title2.bold())
                        .padding(.horizontal)
                }
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(items) { tile($0) }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

extension AIGrid where Tile == AIDefaultGridTile<T> {
    public init(title: String? = nil, items: [T], columns: Int = 2) {
        self.init(title: title, items: items, columns: columns) {
            AIDefaultGridTile(item: $0)
        }
    }
}

/// The standard tile rendering used when callers don't supply their own.
public struct AIDefaultGridTile<T: AIRepresentable>: View {
    public let item: T

    public init(item: T) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(
                        colors: [item.accentColor.opacity(0.25), item.accentColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Image(systemName: item.icon)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(item.accentColor)
            }
            .frame(height: 64)

            Text(item.primaryDescription)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Text(item.secondaryDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.gray.opacity(0.12))
        )
    }
}

private struct GridItemSample: AIListRepresentable {
    let id = UUID()
    let icon: String
    let primaryDescription: String
    let secondaryDescription: String
    let accentColor: Color
    var dateCreated: Date = .now
    var lastUpdated: Date = .now
}

#Preview("AIGrid — 2 columns") {
    AIGrid(title: "What would you like to do?", items: [
        GridItemSample(icon: "sparkles", primaryDescription: "Summarize", secondaryDescription: "Compress long text into bullets", accentColor: .purple),
        GridItemSample(icon: "wand.and.stars", primaryDescription: "Rewrite", secondaryDescription: "Adjust tone and style", accentColor: .pink),
        GridItemSample(icon: "text.magnifyingglass", primaryDescription: "Extract", secondaryDescription: "Pull structured data", accentColor: .blue),
        GridItemSample(icon: "globe", primaryDescription: "Translate", secondaryDescription: "120+ languages", accentColor: .teal),
        GridItemSample(icon: "chart.bar.fill", primaryDescription: "Analyze", secondaryDescription: "Numeric & sentiment", accentColor: .orange),
        GridItemSample(icon: "photo.on.rectangle.angled", primaryDescription: "Describe", secondaryDescription: "Vision captioning", accentColor: .green),
    ])
}

#Preview("AIGrid — 3 columns") {
    AIGrid(items: (0..<9).map { idx in
        GridItemSample(
            icon: ["star.fill", "bolt.fill", "heart.fill", "leaf.fill", "flame.fill", "drop.fill", "moon.fill", "sun.max.fill", "cloud.fill"][idx],
            primaryDescription: "Tile \(idx + 1)",
            secondaryDescription: "Short description",
            accentColor: [.yellow, .indigo, .red, .green, .orange, .blue, .purple, .yellow, .cyan][idx]
        )
    }, columns: 3)
}
