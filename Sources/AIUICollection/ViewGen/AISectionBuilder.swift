//
//  AISectionBuilder.swift
//  AIUICollection
//
//  Compact, chrome-less, NON-scrolling renderings of each template — the
//  CANONICAL per-template view bodies. They render as a section inside an
//  `AIScreen` composition AND as a standalone synthesized tile (LifeOS renders
//  each parallel-synthesis card through `AIViewBuilder.build(…, .section)`,
//  which routes here). The host supplies the title/chrome; a body here carries
//  no outer card and shows a bounded preview of its bound data.
//
//  RESPONSIVE: every body adapts to the width AND height it is given — a list
//  reflows into 2+ columns on a wide card instead of stranding the right half;
//  a chart grows to fill the card's height and its legend WRAPS; grids and stat
//  dashboards pack more tiles per row as the card widens. Native `.adaptive`
//  grids and a `FlowLayout` legend do the reflow with no geometry plumbing.
//
//  Theme-adaptive throughout (semantic fills + per-record accents) so the same
//  bodies read correctly in light and dark.
//

import Charts
import SwiftUI

/// A calm categorical palette for sector (donut) slices — every category record
/// would otherwise share one accent, flattening the breakdown into a single hue.
/// Public so a host can render and verify it. Wrapping and negative-safe.
public enum AISectionPalette {
    public static let colors: [Color] = [
        .blue, .orange, .green, .purple, .pink, .teal, .indigo, .yellow,
    ]

    public static func color(at index: Int) -> Color {
        let count = colors.count
        return colors[((index % count) + count) % count]
    }
}

enum AISectionBuilder {
    /// How many entities a section previews before it would get noisy. Numeric
    /// sections (chart, stats) show their full series.
    private static let entityPreviewLimit = 6

    @MainActor
    static func build(
        template: AIViewTemplate,
        records: [AIRecord],
        style: String?,
        entityLimit: Int? = nil
    ) -> AnyView {
        switch template {
        case .chart:
            return AnyView(SectionChart(
                items: records.map(AISeriesItem.init),
                kind: AIViewBuilder.chartKind(from: style)
            ))
        case .stats:
            return AnyView(SectionStats(items: capped(records, entityLimit).map(AIMetricItem.init)))
        case .grid:
            return AnyView(SectionGrid(items: capped(records, entityLimit).map(AIEntityItem.init)))
        case .list:
            return AnyView(SectionList(items: capped(records, entityLimit).map(AIEntityItem.init)))
        case .timeline:
            return AnyView(SectionTimeline(items: capped(records, entityLimit).map(AIEntityItem.init)))
        case .gallery:
            return AnyView(SectionGallery(items: capped(records, entityLimit).map(AIEntityItem.init)))
        }
    }

    /// Bound an entity section to its preview. A host that curates the record
    /// window itself (LifeOS's height-paged primary tile) passes an explicit
    /// `limit` so the section renders exactly that window; `nil` keeps the
    /// default bounded preview.
    static func capped(_ records: [AIRecord], _ limit: Int?) -> [AIRecord] {
        Array(records.prefix(max(0, limit ?? entityPreviewLimit)))
    }
}

// MARK: - Shared tokens

private extension ShapeStyle where Self == HierarchicalShapeStyle {
    /// The adaptive fill behind a tile/cell — subtle in both light and dark.
    static var tileFill: HierarchicalShapeStyle { .quaternary }
}

private let tileShape = RoundedRectangle(cornerRadius: 12, style: .continuous)

/// A wrapping row layout — chips flow onto the next line when they run out of
/// width, so a legend (or any chip row) never overflows or truncates on a narrow
/// card. Adapts purely to the proposed width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 12
    var rowSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                widest = max(widest, x - spacing)
                x = 0; y += rowHeight + rowSpacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        widest = max(widest, x - spacing)
        let width = maxWidth.isFinite ? maxWidth : max(0, widest)
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + rowSpacing; rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - List — reflows into columns on a wide card.

private struct SectionList: View {
    let items: [AIEntityItem]

    var body: some View {
        // A list cell needs ~240pt to read; the adaptive grid packs one column on
        // a narrow tile and two across a medium/wide card — so the content fills
        // the width instead of stranding the right half. (240 → 1 col under ~500pt,
        // 2 cols above, which covers a medium tile.)
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 240), spacing: 16, alignment: .top)],
            alignment: .leading, spacing: 4
        ) {
            ForEach(items) { item in
                EntityRow(item: item)
            }
        }
    }
}

/// One entity row: accent chip + title/subtitle, content pushed to fill its cell.
private struct EntityRow: View {
    let item: AIEntityItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(item.accentColor)
                .frame(width: 28, height: 28)
                .background(item.accentColor.opacity(0.14),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(item.primaryDescription)
                    .font(.subheadline.weight(.semibold)).lineLimit(1)
                if !item.secondaryDescription.isEmpty {
                    Text(item.secondaryDescription)
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Timeline — linear (time order), trailing date fills the width.

private struct SectionTimeline: View {
    let items: [AIEntityItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        Circle().fill(item.accentColor).frame(width: 9, height: 9).padding(.top, 4)
                        if index < items.count - 1 {
                            Rectangle().fill(.secondary.opacity(0.25)).frame(width: 1.5)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 9)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.primaryDescription)
                            .font(.subheadline.weight(.semibold)).lineLimit(1)
                        if !item.secondaryDescription.isEmpty {
                            Text(item.secondaryDescription)
                                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                    Spacer(minLength: 12)
                    // The date anchors the right edge, so the row spans the card.
                    Text(item.dateCreated.formatted(.relative(presentation: .named)))
                        .font(.caption2).foregroundStyle(.tertiary)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.bottom, index < items.count - 1 ? 14 : 0)
            }
        }
    }
}

// MARK: - Grid — adaptive tile count.

private struct SectionGrid: View {
    let items: [AIEntityItem]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 150), spacing: 10)],
            alignment: .leading, spacing: 10
        ) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: item.icon)
                        .font(.system(size: 16)).foregroundStyle(item.accentColor)
                    Text(item.primaryDescription)
                        .font(.subheadline.weight(.medium)).lineLimit(2)
                    if !item.secondaryDescription.isEmpty {
                        Text(item.secondaryDescription)
                            .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.tileFill, in: tileShape)
            }
        }
    }
}

// MARK: - Stats — adaptive KPI tile count.

private struct SectionStats: View {
    let items: [AIMetricItem]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 150), spacing: 10)],
            alignment: .leading, spacing: 10
        ) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.primaryDescription)
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(item.value)
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .foregroundStyle(.primary)
                        if let unit = item.unit {
                            Text(unit).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if let delta = item.deltaPercent {
                        deltaPill(delta)
                    } else if !item.secondaryDescription.isEmpty {
                        Text(item.secondaryDescription)
                            .font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.tileFill, in: tileShape)
            }
        }
    }

    private func deltaPill(_ delta: Double) -> some View {
        let up = delta >= 0
        return Label(
            String(format: "%@%.1f%%", up ? "+" : "", delta),
            systemImage: up ? "arrow.up.right" : "arrow.down.right"
        )
        .font(.caption2.weight(.semibold))
        .foregroundStyle(up ? Color.green : Color.red)
        .labelStyle(.titleAndIcon)
    }
}

// MARK: - Gallery — featured item over an adaptive thumbnail row.

private struct SectionGallery: View {
    let items: [AIEntityItem]

    var body: some View {
        VStack(spacing: 8) {
            if let featured = items.first {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(featured.accentColor.opacity(0.18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 130)
                        .overlay(
                            Image(systemName: featured.icon)
                                .font(.system(size: 34))
                                .foregroundStyle(featured.accentColor.opacity(0.65))
                        )
                    Text(featured.primaryDescription)
                        .font(.headline).lineLimit(1).padding(12)
                }
            }
            if items.count > 1 {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 96), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(items.dropFirst()) { item in
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.tileFill)
                            .frame(height: 64)
                            .overlay(
                                Image(systemName: item.icon)
                                    .font(.system(size: 15))
                                    .foregroundStyle(item.accentColor)
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Chart — fills the card's height; legend wraps.

private struct SectionChart: View {
    let items: [AISeriesItem]
    let kind: AIChart<AISeriesItem>.Kind

    private var isSector: Bool { kind == .sector }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            chart
            if isSector { legend }
        }
    }

    @ViewBuilder private var chart: some View {
        Chart(Array(items.enumerated()), id: \.element.id) { index, item in
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
                    .cornerRadius(4).foregroundStyle(AISectionPalette.color(at: index))
            }
        }
        .chartLegend(.hidden)
        .chartXAxis {
            if !isSector {
                AxisMarks { _ in
                    // Greedy collision resolution DROPS labels that would overlap,
                    // so a narrow tile shows a legible subset instead of a smear of
                    // crowded category names; a wide card shows them all.
                    AxisValueLabel(collisionResolution: .greedy)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartYAxis {
            if !isSector {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.18))
                    AxisValueLabel().font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        // A bar/line chart grows to fill the card's height; a donut stays a
        // sensible size (a tall frame would just inflate the ring).
        .frame(minHeight: isSector ? 150 : 160,
               maxHeight: isSector ? 240 : .infinity)
        .frame(maxWidth: .infinity)
    }

    private var legend: some View {
        FlowLayout(spacing: 14, rowSpacing: 6) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 5) {
                    Circle().fill(AISectionPalette.color(at: index)).frame(width: 7, height: 7)
                    Text(item.primaryDescription).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var series: Color { items.first?.accentColor ?? .accentColor }
}
