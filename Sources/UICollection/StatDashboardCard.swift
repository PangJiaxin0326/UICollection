//
//  StatDashboardCard.swift
//  UICollection
//
//  Compact, two-column dashboard card used by both Journal and ExpenseTracker
//  stats screens. Tinted icon chip + uppercased caption label + headline value.
//

import SwiftUI

public struct StatDashboardCard: View {
    public let label: String
    public let tint: Color
    public let icon: String
    public let value: String
    public let valueColor: Color

    public init(
        label: String,
        tint: Color,
        icon: String,
        value: String,
        valueColor: Color = .primary
    ) {
        self.label = label
        self.tint = tint
        self.icon = icon
        self.value = value
        self.valueColor = valueColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 26, height: 26)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 7))
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .dashboardCard(cornerRadius: 14)
    }
}

/// Two-up footer card showing the first/last item dates in a range window.
public struct WindowCell: View {
    public let label: String
    public let date: Date

    public init(label: String, date: Date) {
        self.label = label
        self.date = date
    }

    public var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(date.formatted(.dateTime.month().day().year()))
                .font(.subheadline.weight(.medium))
        }
        .frame(maxWidth: .infinity)
    }
}

/// Tinted capsule badge used in dashboard hero cards (trend up/down, streak
/// on/off, …).
public struct TrendBadge: View {
    public let label: String
    public let systemImage: String
    public let tint: Color

    public init(label: String, systemImage: String, tint: Color) {
        self.label = label
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        Label(label, systemImage: systemImage)
            .font(.caption2.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 0.5))
    }
}
