//
//  AIRecord.swift
//  AIUICollection
//
//  The single real-data record the view-generation workflow binds into a
//  view. ONE record type carries every field any template needs; per-template
//  adapter wrappers project it onto the collection protocols (`AIList`,
//  `AIChart`, `AIStats`, `AIGallery`) — which is necessary because
//  `AIChartRepresentable.value` is `Double` while `AIStatRepresentable.value`
//  is `String`, so a single type cannot satisfy both directly.
//
//  `AIRecord` is the *bound data*: the host fetches it (see `AIDataSource`)
//  and the view-creator tool wraps it for rendering. It NEVER leaves the host
//  for the model — the LLM only ever names a data-source key.
//

import Foundation
import SwiftUI

/// A small, Sendable accent token so a record can pin a color without storing
/// a non-deterministic `Color` literal at the data layer.
public enum AIAccent: String, CaseIterable, Sendable, Codable {
    case blue, green, orange, red, purple, pink, teal, indigo, yellow, mint, cyan, gray

    public var color: Color {
        switch self {
        case .blue: .blue
        case .green: .green
        case .orange: .orange
        case .red: .red
        case .purple: .purple
        case .pink: .pink
        case .teal: .teal
        case .indigo: .indigo
        case .yellow: .yellow
        case .mint: .mint
        case .cyan: .cyan
        case .gray: .gray
        }
    }
}

/// One row of bound data. Holds the superset of fields the templates read; a
/// template only uses what it needs (a list ignores `value`, a chart ignores
/// `subtitle`).
public struct AIRecord: Identifiable, Sendable {
    public let id: UUID
    public var icon: String
    public var title: String
    public var subtitle: String
    /// Numeric magnitude — drives chart marks and stat headlines.
    public var value: Double
    /// Unit suffix for the stat headline ("%", "k", "ms"); `nil` = none.
    public var unit: String?
    /// Period-over-period delta percent for the stat pill; `nil` = none.
    public var deltaPercent: Double?
    public var accent: AIAccent
    public var badges: [String]
    public var date: Date

    public init(
        id: UUID = UUID(),
        icon: String,
        title: String,
        subtitle: String,
        value: Double = 0,
        unit: String? = nil,
        deltaPercent: Double? = nil,
        accent: AIAccent = .blue,
        badges: [String] = [],
        date: Date = .now
    ) {
        self.id = id
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.unit = unit
        self.deltaPercent = deltaPercent
        self.accent = accent
        self.badges = badges
        self.date = date
    }
}

// MARK: - Per-template adapters

/// Entity adapter: list / grid / gallery / timeline.
public struct AIEntityItem: AIListRepresentable, AIGalleryRepresentable {
    public let id: UUID
    public let icon: String
    public let primaryDescription: String
    public let secondaryDescription: String
    public let accentColor: Color
    public let badges: [String]
    public let dateCreated: Date
    public var lastUpdated: Date

    public init(_ r: AIRecord) {
        id = r.id
        icon = r.icon
        primaryDescription = r.title
        secondaryDescription = r.subtitle
        accentColor = r.accent.color
        badges = r.badges
        dateCreated = r.date
        lastUpdated = r.date
    }
}

/// Series adapter: chart (`value` is the mark magnitude).
public struct AISeriesItem: AIChartRepresentable {
    public let id: UUID
    public let icon: String
    public let primaryDescription: String
    public let secondaryDescription: String
    public let accentColor: Color
    public let value: Double
    public let dateCreated: Date
    public var lastUpdated: Date

    public init(_ r: AIRecord) {
        id = r.id
        icon = r.icon
        primaryDescription = r.title
        secondaryDescription = r.subtitle
        accentColor = r.accent.color
        value = r.value
        dateCreated = r.date
        lastUpdated = r.date
    }
}

/// Metric adapter: stats (`value` is the formatted headline string).
public struct AIMetricItem: AIStatRepresentable {
    public let id: UUID
    public let icon: String
    public let primaryDescription: String
    public let secondaryDescription: String
    public let accentColor: Color
    public let value: String
    public let unit: String?
    public let deltaPercent: Double?
    public let dateCreated: Date
    public var lastUpdated: Date

    public init(_ r: AIRecord) {
        id = r.id
        icon = r.icon
        primaryDescription = r.title
        secondaryDescription = r.subtitle
        accentColor = r.accent.color
        value = Self.headline(r.value)
        unit = r.unit
        deltaPercent = r.deltaPercent
        dateCreated = r.date
        lastUpdated = r.date
    }

    /// Compact headline: 1.2k for thousands, whole number otherwise.
    private static func headline(_ v: Double) -> String {
        if abs(v) >= 1_000 { return String(format: "%.1fk", v / 1_000) }
        if v == v.rounded() { return String(format: "%.0f", v) }
        return String(format: "%.1f", v)
    }
}
