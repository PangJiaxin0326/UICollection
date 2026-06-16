//
//  AISectionBuilder.swift
//  AIUICollection
//
//  Compact, chrome-less, NON-scrolling renderings of each template, for
//  embedding as a section inside an `AIScreen` composition (the progressive
//  workflow). The outer screen scrolls; a section header (typography, no box)
//  supplies the label — so each section here carries no title and no outer
//  card, and shows a bounded preview of its bound data.
//

import Charts
import SwiftUI

enum AISectionBuilder {
    /// How many entities a section previews before it would get noisy. Numeric
    /// sections (chart, stats) show their full series.
    private static let entityPreviewLimit = 6

    @MainActor
    static func build(
        template: AIViewTemplate,
        records: [AIRecord],
        style: String?
    ) -> AnyView {
        switch template {
        case .chart:
            return AnyView(SectionChart(
                items: records.map(AISeriesItem.init),
                kind: AIViewBuilder.chartKind(from: style)
            ))
        case .stats:
            return AnyView(SectionStats(items: records.map(AIMetricItem.init)))
        case .grid:
            return AnyView(SectionGrid(
                items: capped(records).map(AIEntityItem.init),
                columns: AIViewBuilder.columns(from: style)
            ))
        case .list:
            return AnyView(SectionList(items: capped(records).map(AIEntityItem.init)))
        case .timeline:
            return AnyView(SectionTimeline(items: capped(records).map(AIEntityItem.init)))
        case .gallery:
            return AnyView(SectionGallery(items: capped(records).map(AIEntityItem.init)))
        }
    }

    private static func capped(_ records: [AIRecord]) -> [AIRecord] {
        Array(records.prefix(entityPreviewLimit))
    }
}

// MARK: - Section bodies

private struct SectionChart: View {
    let items: [AISeriesItem]
    let kind: AIChart<AISeriesItem>.Kind

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Chart(items) { item in
                switch kind {
                case .bar:
                    BarMark(x: .value("c", item.primaryDescription), y: .value("v", item.value))
                        .foregroundStyle(item.accentColor.gradient).cornerRadius(5)
                case .line:
                    LineMark(x: .value("c", item.primaryDescription), y: .value("v", item.value))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .foregroundStyle(series)
                    PointMark(x: .value("c", item.primaryDescription), y: .value("v", item.value))
                        .foregroundStyle(item.accentColor)
                case .area:
                    AreaMark(x: .value("c", item.primaryDescription), y: .value("v", item.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(LinearGradient(
                            colors: [series.opacity(0.5), series.opacity(0.04)],
                            startPoint: .top, endPoint: .bottom))
                case .point:
                    PointMark(x: .value("c", item.primaryDescription), y: .value("v", item.value))
                        .symbolSize(120).foregroundStyle(item.accentColor.gradient)
                case .sector:
                    SectorMark(angle: .value("v", item.value), innerRadius: .ratio(0.6), angularInset: 1.5)
                        .cornerRadius(4).foregroundStyle(item.accentColor)
                }
            }
            .frame(height: 180)

            if kind == .sector {
                legend
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach(items) { item in
                HStack(spacing: 5) {
                    Circle().fill(item.accentColor).frame(width: 7, height: 7)
                    Text(item.primaryDescription).font(.caption2)
                }
            }
        }
    }

    private var series: Color { items.first?.accentColor ?? .accentColor }
}

private struct SectionStats: View {
    let items: [AIMetricItem]
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items) { AIStatTile(item: $0) }
        }
    }
}

private struct SectionGrid: View {
    let items: [AIEntityItem]
    let columns: Int

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: max(columns, 1)),
            spacing: 10
        ) {
            ForEach(items) { AIDefaultGridTile(item: $0) }
        }
    }
}

private struct SectionList: View {
    let items: [AIEntityItem]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.title3)
                        .foregroundStyle(item.accentColor)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.primaryDescription).font(.subheadline.weight(.semibold))
                        Text(item.secondaryDescription).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                if index < items.count - 1 {
                    Divider().opacity(0.4)
                }
            }
        }
    }
}

private struct SectionTimeline: View {
    let items: [AIEntityItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        Circle().fill(item.accentColor).frame(width: 9, height: 9)
                        if index < items.count - 1 {
                            Rectangle().fill(.gray.opacity(0.25)).frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 9)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.primaryDescription).font(.subheadline.weight(.semibold))
                        Text(item.secondaryDescription).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.bottom, index < items.count - 1 ? 14 : 0)
                    Spacer()
                }
            }
        }
    }
}

private struct SectionGallery: View {
    let items: [AIEntityItem]
    private let thumbs = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        VStack(spacing: 8) {
            if let featured = items.first {
                ZStack(alignment: .bottomLeading) {
                    gradient(featured, height: 150)
                    Text(featured.primaryDescription)
                        .font(.headline).foregroundStyle(.white).padding(12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            if items.count > 1 {
                LazyVGrid(columns: thumbs, spacing: 8) {
                    ForEach(items.dropFirst().prefix(3)) { item in
                        ZStack(alignment: .bottomLeading) {
                            gradient(item, height: 80)
                            Image(systemName: item.icon)
                                .foregroundStyle(.white).padding(8)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    private func gradient(_ item: AIEntityItem, height: CGFloat) -> some View {
        LinearGradient(
            colors: [item.accentColor.opacity(0.95), item.accentColor.opacity(0.45)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}
