//
//  DistributionBar.swift
//  UICollection
//
//  Single-row proportional bar. Each segment's width is its share of the total.
//

import SwiftUI

public struct DistributionSegment: Identifiable {
    public let id: AnyHashable
    public let value: Double
    public let color: Color

    public init<ID: Hashable>(id: ID, value: Double, color: Color) {
        self.id = AnyHashable(id)
        self.value = value
        self.color = color
    }
}

public struct DistributionBar: View {
    public let segments: [DistributionSegment]
    public let spacing: CGFloat
    public let cornerRadius: CGFloat

    public init(
        segments: [DistributionSegment],
        spacing: CGFloat = 2,
        cornerRadius: CGFloat = 4
    ) {
        self.segments = segments
        self.spacing = spacing
        self.cornerRadius = cornerRadius
    }

    private var total: Double {
        let sum = segments.reduce(0) { $0 + $1.value }
        return max(sum, 0.0001)
    }

    public var body: some View {
        GeometryReader { geo in
            let active = segments.count
            let usable = geo.size.width - CGFloat(max(active - 1, 0)) * spacing
            HStack(spacing: spacing) {
                ForEach(segments) { segment in
                    let fraction = CGFloat(segment.value / total)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(segment.color.gradient)
                        .frame(width: max(usable * fraction, 4))
                }
            }
        }
    }
}
