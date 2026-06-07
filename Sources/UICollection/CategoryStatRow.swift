//
//  CategoryStatRow.swift
//  UICollection
//
//  Compact tinted-icon row for two-column category breakdown grids.
//

import SwiftUI

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
