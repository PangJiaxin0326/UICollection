//
//  CardStyle.swift
//  UICollection
//
//  Shared "secondary card" surface used across dashboards, profile sheets,
//  and stat groupings in both Journal and ExpenseTracker. Centralises the
//  `.background(.background.secondary, in: RoundedRectangle…) + .overlay
//  RoundedRectangle.stroke(.quaternary, lineWidth: 0.5)` recipe.
//

import SwiftUI

public extension View {
    /// Applies the shared dashboard card surface: a secondary-background
    /// rounded rectangle with a hairline quaternary stroke.
    func dashboardCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(DashboardCardBackground(cornerRadius: cornerRadius))
    }
}

private struct DashboardCardBackground: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(.quaternary, lineWidth: 0.5))
    }
}
