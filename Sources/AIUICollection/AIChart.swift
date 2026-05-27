//
//  AIChart.swift
//  AIUICollection
//
//  Chart card — collection template. The LLM picks this when the answer is
//  comparative numerical data across labeled categories (sales by week,
//  votes by option, share of total). The `Kind` parameter lets the LLM
//  choose the most suitable encoding for the data: bars for discrete
//  categories, line/area for ordered series, point for scatter-style
//  emphasis, sector for part-of-whole.
//

import Charts
import SwiftUI

public protocol AIChartRepresentable: AIListRepresentable {
    /// The numeric value driving the mark's magnitude.
    var value: Double { get }
}

public struct AIChart<T: AIChartRepresentable>: View {
    public enum Kind: Sendable, CaseIterable {
        case bar
        case line
        case area
        case point
        case sector
    }

    public let title: String
    public let subtitle: String
    public let kind: Kind
    public let items: [T]

    public init(title: String, subtitle: String, kind: Kind = .bar, items: [T]) {
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
        self.items = items
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title3.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            chart
                .frame(height: 220)

            Divider().padding(.vertical, 4)

            legend
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.gray.opacity(0.12))
        )
        .padding()
    }

    @ViewBuilder
    private var chart: some View {
        switch kind {
        case .bar:
            Chart(items) { item in
                BarMark(
                    x: .value("Category", item.primaryDescription),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(item.accentColor.gradient)
                .cornerRadius(6)
                .annotation(position: .top, alignment: .center, spacing: 4) {
                    Text(format(item.value))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        case .line:
            Chart(items) { item in
                LineMark(
                    x: .value("Category", item.primaryDescription),
                    y: .value("Value", item.value)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .foregroundStyle(seriesColor)

                PointMark(
                    x: .value("Category", item.primaryDescription),
                    y: .value("Value", item.value)
                )
                .symbolSize(70)
                .foregroundStyle(item.accentColor)
            }
        case .area:
            Chart(items) { item in
                AreaMark(
                    x: .value("Category", item.primaryDescription),
                    y: .value("Value", item.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [seriesColor.opacity(0.55), seriesColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Category", item.primaryDescription),
                    y: .value("Value", item.value)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .foregroundStyle(seriesColor)
            }
        case .point:
            Chart(items) { item in
                PointMark(
                    x: .value("Category", item.primaryDescription),
                    y: .value("Value", item.value)
                )
                .symbolSize(140)
                .foregroundStyle(item.accentColor.gradient)
            }
        case .sector:
            Chart(items) { item in
                SectorMark(
                    angle: .value("Value", item.value),
                    innerRadius: .ratio(0.58),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(item.accentColor)
                .annotation(position: .overlay) {
                    Text(format(item.value))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var legend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items) { item in
                    HStack(spacing: 6) {
                        Circle().fill(item.accentColor).frame(width: 8, height: 8)
                        Text(item.primaryDescription).font(.caption)
                    }
                }
            }
        }
    }

    /// Single-series marks (line, area) use the first item's accent so the
    /// stroke reads as one continuous series rather than flickering colors.
    private var seriesColor: Color {
        items.first?.accentColor ?? .accentColor
    }

    private func format(_ v: Double) -> String {
        if v >= 1_000 { return String(format: "%.1fk", v / 1000) }
        return String(format: "%.0f", v)
    }
}

private struct ChartSample: AIChartRepresentable {
    let id = UUID()
    let icon: String = "chart.bar.fill"
    let primaryDescription: String
    let secondaryDescription: String
    let value: Double
    let accentColor: Color
    var dateCreated: Date = .now
    var lastUpdated: Date = .now
}

private let weeklyRevenue: [ChartSample] = [
    ChartSample(primaryDescription: "Mon", secondaryDescription: "Mon", value: 1200, accentColor: .blue),
    ChartSample(primaryDescription: "Tue", secondaryDescription: "Tue", value: 1840, accentColor: .blue),
    ChartSample(primaryDescription: "Wed", secondaryDescription: "Wed", value: 2200, accentColor: .blue),
    ChartSample(primaryDescription: "Thu", secondaryDescription: "Thu", value: 1700, accentColor: .blue),
    ChartSample(primaryDescription: "Fri", secondaryDescription: "Fri", value: 3100, accentColor: .indigo),
    ChartSample(primaryDescription: "Sat", secondaryDescription: "Sat", value: 2750, accentColor: .indigo),
    ChartSample(primaryDescription: "Sun", secondaryDescription: "Sun", value: 980, accentColor: .indigo),
]

private let trafficShare: [ChartSample] = [
    ChartSample(primaryDescription: "Organic", secondaryDescription: "SEO", value: 42, accentColor: .green),
    ChartSample(primaryDescription: "Direct", secondaryDescription: "Bookmarks", value: 23, accentColor: .blue),
    ChartSample(primaryDescription: "Referral", secondaryDescription: "Partners", value: 18, accentColor: .purple),
    ChartSample(primaryDescription: "Social", secondaryDescription: "X, LinkedIn", value: 11, accentColor: .pink),
    ChartSample(primaryDescription: "Paid", secondaryDescription: "Ads", value: 6, accentColor: .orange),
]

#Preview("AIChart — Bar") {
    AIChart(title: "Weekly revenue", subtitle: "Last 7 days · USD", kind: .bar, items: weeklyRevenue)
}

#Preview("AIChart — Line") {
    AIChart(title: "Weekly revenue", subtitle: "Last 7 days · USD", kind: .line, items: weeklyRevenue)
}

#Preview("AIChart — Area") {
    AIChart(title: "Weekly revenue", subtitle: "Last 7 days · USD", kind: .area, items: weeklyRevenue)
}

#Preview("AIChart — Point") {
    AIChart(title: "Weekly revenue", subtitle: "Last 7 days · USD", kind: .point, items: weeklyRevenue)
}

#Preview("AIChart — Sector") {
    AIChart(title: "Traffic mix", subtitle: "Share of sessions · %", kind: .sector, items: trafficShare)
}
