//
//  StatCell.swift
//  UICollection
//
//  Vertical "value over label" cell sized for an HStack with two-to-three
//  siblings.
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
