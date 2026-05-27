//
//  AIRepresentable.swift
//  AIUICollection
//
//  The two foundational protocols for AI-synthesized UI.
//
//  • `AIRepresentable` — anything an LLM can render at all. Carries the
//    minimum surface (icon + two descriptions) plus supplementary visual
//    affordances (accent color, badges) with sensible defaults so case-
//    specific item types only declare what they need to override.
//
//  • `AIListRepresentable` — sibling layer on top: anything that can also be
//    a *member of a collection*. Adds creation / update timestamps and a
//    sort comparator. Every collection-style template (AIList, AIGrid,
//    AIGallery, AITimeline, AIKanban, AICarousel, AIChart, AIStats,
//    AIComparison) takes items conforming to this.
//

import SwiftUI

public protocol AIRepresentable: Identifiable, Sendable {
    // Required: minimum visual surface.
    var icon: String { get }
    var primaryDescription: String { get }
    var secondaryDescription: String { get }

    // Supplementary: defaulted, override when the answer benefits from it.
    var accentColor: Color { get }
    var badges: [String] { get }
}

extension AIRepresentable {
    public var accentColor: Color { .accentColor }
    public var badges: [String] { [] }
}

/// Default sort options driven by the timestamps every `AIListRepresentable`
/// already provides. Items can substitute their own `SortOption` type when
/// they need a richer set of orderings.
public enum AISortOption: String, CaseIterable, Equatable, CustomStringConvertible, Sendable, Codable {
    case dateDescending = "Most recent"
    case dateAscending = "Oldest first"
    case nameAscending = "A–Z"
    case nameDescending = "Z–A"

    public var description: String { rawValue }
}

public protocol AIListRepresentable: AIRepresentable {
    var dateCreated: Date { get }
    var lastUpdated: Date { get set }

    associatedtype SortOption: Equatable, CustomStringConvertible = AISortOption
    static func comparator(for sortOption: SortOption) -> (Self, Self) -> Bool
}

extension AIListRepresentable where SortOption == AISortOption {
    public static func comparator(for sortOption: AISortOption) -> (Self, Self) -> Bool {
        { lhs, rhs in
            switch sortOption {
            case .dateDescending: return lhs.dateCreated > rhs.dateCreated
            case .dateAscending: return lhs.dateCreated < rhs.dateCreated
            case .nameAscending: return lhs.primaryDescription < rhs.primaryDescription
            case .nameDescending: return lhs.primaryDescription > rhs.primaryDescription
            }
        }
    }
}
