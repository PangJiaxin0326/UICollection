//
//  AIKanban.swift
//  AIUICollection
//
//  Multi-column board — collection template. The LLM picks this when the
//  answer naturally groups items by stage or status (todo lists, project
//  pipelines, deal stages). Card chips reuse the inherited `badges` slot.
//

import SwiftUI

public protocol AIKanbanCardRepresentable: AIListRepresentable {
    /// 0 = none, higher = more urgent.
    var priority: Int { get }
}

extension AIKanbanCardRepresentable {
    public var priority: Int { 0 }
}

public struct AIKanbanColumn<Card: AIKanbanCardRepresentable>: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let accentColor: Color
    public let cards: [Card]

    public init(title: String, accentColor: Color, cards: [Card]) {
        self.title = title
        self.accentColor = accentColor
        self.cards = cards
    }
}

public struct AIKanban<Card: AIKanbanCardRepresentable>: View {
    public let columns: [AIKanbanColumn<Card>]

    public init(columns: [AIKanbanColumn<Card>]) {
        self.columns = columns
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(columns) { column(for: $0) }
            }
            .padding()
        }
    }

    private func column(for column: AIKanbanColumn<Card>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(column.accentColor).frame(width: 8, height: 8)
                Text(column.title).font(.subheadline.bold())
                Text("\(column.cards.count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.gray.opacity(0.15)))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(column.cards) { card($0, accent: column.accentColor) }
            }
        }
        .padding(12)
        .frame(width: 270, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.gray.opacity(0.06))
        )
    }

    private func card(_ card: Card, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: card.icon)
                    .foregroundStyle(accent)
                Spacer()
                if card.priority > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(card.priority, 3), id: \.self) { _ in
                            Image(systemName: "flag.fill")
                                .font(.caption2)
                                .foregroundStyle(card.priority >= 3 ? .red : .orange)
                        }
                    }
                }
            }
            Text(card.primaryDescription)
                .font(.subheadline.weight(.semibold))
            Text(card.secondaryDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if !card.badges.isEmpty {
                HStack(spacing: 4) {
                    ForEach(card.badges, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(accent.opacity(0.12)))
                            .foregroundStyle(accent)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        )
    }
}

private struct KanbanSample: AIKanbanCardRepresentable {
    let id = UUID()
    let icon: String
    let primaryDescription: String
    let secondaryDescription: String
    let badges: [String]
    let priority: Int
    var dateCreated: Date = .now
    var lastUpdated: Date = .now
}

#Preview("AIKanban — Sprint board") {
    AIKanban(columns: [
        AIKanbanColumn(title: "Backlog", accentColor: .gray, cards: [
            KanbanSample(icon: "doc.text", primaryDescription: "Migration plan v2", secondaryDescription: "Drafted Q3 schema migration outline.", badges: ["docs"], priority: 1),
            KanbanSample(icon: "bug.fill", primaryDescription: "Flaky login test", secondaryDescription: "Intermittent timeout on CI iOS-26 runner.", badges: ["test", "ios"], priority: 0),
        ]),
        AIKanbanColumn(title: "In progress", accentColor: .blue, cards: [
            KanbanSample(icon: "wand.and.stars", primaryDescription: "Onboarding redesign", secondaryDescription: "Glass cards + animated hero, design review Mon.", badges: ["design"], priority: 2),
            KanbanSample(icon: "lock.shield", primaryDescription: "Token rotation", secondaryDescription: "Rotate Anthropic API keys, owners notified.", badges: ["security"], priority: 3),
        ]),
        AIKanbanColumn(title: "In review", accentColor: .purple, cards: [
            KanbanSample(icon: "checkmark.shield", primaryDescription: "Guardrail audit", secondaryDescription: "PR #482 awaiting safety sign-off.", badges: ["pr"], priority: 2),
        ]),
        AIKanbanColumn(title: "Shipped", accentColor: .green, cards: [
            KanbanSample(icon: "sparkles", primaryDescription: "Voice mode v1", secondaryDescription: "Hands-free overlay landed in 1.4.0.", badges: ["voice", "ios"], priority: 0),
        ]),
    ])
}
