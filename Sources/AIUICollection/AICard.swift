//
//  AICard.swift
//  AIUICollection
//
//  Hero feature card — the LLM picks this when the answer is a single rich
//  entity worth pausing on (a recipe, a recommended product, a flight
//  option). Single-item; built on `AIRepresentable`.
//

import SwiftUI

public protocol AICardRepresentable: AIRepresentable {
    /// Optional footer metric pairs (label, value).
    var stats: [(label: String, value: String)] { get }
}

extension AICardRepresentable {
    public var stats: [(label: String, value: String)] { [] }
}

public struct AICard<T: AICardRepresentable>: View {
    public let item: T

    public init(item: T) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            hero
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 16, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.gray.opacity(0.12))
        )
        .padding()
    }

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [item.accentColor.opacity(0.85), item.accentColor.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: item.icon)
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 160)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.primaryDescription)
                .font(.title2.bold())
            Text(item.secondaryDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            if !item.badges.isEmpty {
                HStack(spacing: 6) {
                    ForEach(item.badges, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(item.accentColor.opacity(0.12)))
                            .foregroundStyle(item.accentColor)
                    }
                }
            }

            if !item.stats.isEmpty {
                Divider()
                HStack(spacing: 0) {
                    ForEach(Array(item.stats.enumerated()), id: \.offset) { idx, stat in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.value).font(.headline)
                            Text(stat.label).font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if idx < item.stats.count - 1 {
                            Divider().frame(height: 28)
                        }
                    }
                }
            }
        }
        .padding(20)
    }
}

private struct CardSample: AICardRepresentable {
    let id = UUID()
    let icon: String
    let primaryDescription: String
    let secondaryDescription: String
    let badges: [String]
    let accentColor: Color
    let stats: [(label: String, value: String)]
}

#Preview("AICard — Recipe") {
    AICard(item: CardSample(
        icon: "fork.knife",
        primaryDescription: "Truffle Mushroom Risotto",
        secondaryDescription: "Creamy arborio rice slow-cooked with sautéed cremini, parmesan, and a finishing drizzle of white truffle oil.",
        badges: ["Italian", "Vegetarian", "30 min"],
        accentColor: .orange,
        stats: [("Calories", "520"), ("Protein", "18g"), ("Rating", "4.8")]
    ))
}

#Preview("AICard — Travel") {
    AICard(item: CardSample(
        icon: "airplane.departure",
        primaryDescription: "Tokyo, Japan",
        secondaryDescription: "Spring cherry-blossom forecast peaks late March. Direct flights from SFO from $812.",
        badges: ["Sakura", "Direct"],
        accentColor: .pink,
        stats: [("Flight", "11h"), ("From", "$812"), ("Visa", "Free")]
    ))
}
