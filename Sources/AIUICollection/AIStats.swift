//
//  AIStats.swift
//  AIUICollection
//
//  Metric dashboard — a specialization of `AIGrid` that swaps the default
//  tile for one that surfaces a headline number, an optional unit, and a
//  signed delta pill.
//

import SwiftUI

public protocol AIStatRepresentable: AIListRepresentable {
    /// The headline number (formatted).
    var value: String { get }
    /// Optional unit suffix shown smaller after the value (e.g. "%", "ms").
    var unit: String? { get }
    /// Optional period-over-period delta percent. Positive = up, negative = down.
    var deltaPercent: Double? { get }
}

extension AIStatRepresentable {
    public var unit: String? { nil }
    public var deltaPercent: Double? { nil }
}

public struct AIStats<T: AIStatRepresentable>: View {
    public let title: String
    public let items: [T]
    public let columns: Int

    public init(title: String, items: [T], columns: Int = 2) {
        self.title = title
        self.items = items
        self.columns = columns
    }

    public var body: some View {
        AIGrid(title: title, items: items, columns: columns) { item in
            AIStatTile(item: item)
        }
    }
}

public struct AIStatTile<T: AIStatRepresentable>: View {
    public let item: T

    public init(item: T) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(item.accentColor.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: item.icon)
                        .foregroundStyle(item.accentColor)
                }
                Spacer()
                if let delta = item.deltaPercent {
                    deltaPill(delta)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(item.value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let unit = item.unit {
                        Text(unit).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                    }
                }
                Text(item.primaryDescription)
                    .font(.subheadline.weight(.semibold))
                Text(item.secondaryDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.gray.opacity(0.12))
        )
    }

    private func deltaPill(_ delta: Double) -> some View {
        let positive = delta >= 0
        let color: Color = positive ? .green : .red
        return HStack(spacing: 2) {
            Image(systemName: positive ? "arrow.up.right" : "arrow.down.right")
            Text(String(format: "%.1f%%", abs(delta)))
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.15)))
        .foregroundStyle(color)
    }
}

private struct StatSample: AIStatRepresentable {
    let id = UUID()
    let icon: String
    let primaryDescription: String
    let secondaryDescription: String
    let value: String
    let unit: String?
    let deltaPercent: Double?
    let accentColor: Color
    var dateCreated: Date = .now
    var lastUpdated: Date = .now
}

#Preview("AIStats — Product KPIs") {
    AIStats(title: "This week", items: [
        StatSample(icon: "person.2.fill", primaryDescription: "Active users", secondaryDescription: "Daily average", value: "12.4", unit: "k", deltaPercent: 8.2, accentColor: .blue),
        StatSample(icon: "cart.fill", primaryDescription: "Revenue", secondaryDescription: "Subscriptions + IAP", value: "$48.9", unit: "k", deltaPercent: -2.4, accentColor: .green),
        StatSample(icon: "bolt.fill", primaryDescription: "Retention D7", secondaryDescription: "Last cohort vs. previous", value: "42", unit: "%", deltaPercent: 4.1, accentColor: .orange),
        StatSample(icon: "exclamationmark.triangle.fill", primaryDescription: "Crash rate", secondaryDescription: "iOS, all versions", value: "0.18", unit: "%", deltaPercent: -12.0, accentColor: .red),
    ])
}
