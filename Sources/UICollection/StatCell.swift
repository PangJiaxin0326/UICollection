//
//  StatCell.swift
//  UICollection
//
//  Vertical "value over label" cell used inside the stats overview row on
//  the profile dashboard. Sized for an HStack with two-to-three siblings.
//

import SwiftUI

public struct StatCell: View {
    public let value: String
    public let label: String
    public let valueFont: Font

    public init(
        value: String,
        label: String,
        valueFont: Font = .title3.weight(.semibold).monospacedDigit()
    ) {
        self.value = value
        self.label = label
        self.valueFont = valueFont
    }

    public var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(valueFont)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
}

/// Stat cell variant for a tracking streak. Green when today is part of the
/// run, red when it isn't (yesterday's count) so users can see a broken
/// streak at a glance.
public struct StreakStatCell: View {
    public let days: Int
    public let includesToday: Bool
    public let valueFont: Font

    public init(
        days: Int,
        includesToday: Bool,
        valueFont: Font = .title3.weight(.semibold).monospacedDigit()
    ) {
        self.days = days
        self.includesToday = includesToday
        self.valueFont = valueFont
    }

    private var tint: Color { includesToday ? .green : .red }

    public var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                Text("\(days)")
                    .font(valueFont)
                    .foregroundStyle(tint)
            }
            Text("Streak")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            includesToday
                ? "Streak: \(days) consecutive days, including today"
                : "Streak broken: \(days) consecutive days, ending yesterday"
        )
    }
}
