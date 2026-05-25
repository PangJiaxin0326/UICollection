//
//  DetailRow.swift
//  UICollection
//
//  Tinted-icon, label, value row used inside the profile detail cards.
//  Either SF Symbol or arbitrary text (zodiac glyph, currency symbol…) can
//  go in the icon slot.
//

import SwiftUI

public struct DetailRow: View {
    public let icon: String
    public let tint: Color
    public let label: String
    public let value: String?
    public let isSystemImage: Bool

    public init(
        icon: String,
        tint: Color,
        label: String,
        value: String?,
        isSystemImage: Bool = true
    ) {
        self.icon = icon
        self.tint = tint
        self.label = label
        self.value = value
        self.isSystemImage = isSystemImage
    }

    public var body: some View {
        HStack(spacing: 14) {
            Group {
                if isSystemImage {
                    Image(systemName: icon)
                } else {
                    Text(icon)
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 30, height: 30)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            Text(label)
                .font(.subheadline)

            Spacer()

            Text(value ?? "Not set")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(value == nil ? .tertiary : .secondary)
        }
        .padding(.vertical, 12)
    }
}

/// Row variant used inside the profile category breakdown grid: tinted icon
/// chip, name on the leading side, trailing value text. Same visual language
/// as `DetailRow` but compacted for a two-column LazyVGrid.
public struct CategoryStatRow: View {
    public let icon: String
    public let tint: Color
    public let title: String
    public let trailing: String

    public init(icon: String, tint: Color, title: String, trailing: String) {
        self.icon = icon
        self.tint = tint
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

            Text(title)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            Text(trailing)
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
