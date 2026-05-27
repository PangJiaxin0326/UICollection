//
//  AIComparison.swift
//  AIUICollection
//
//  Side-by-side comparison — collection template. The LLM picks this when
//  the answer is a small set of options (≤4) the user is deciding between
//  (pricing tiers, competing products, plan upgrades).
//

import SwiftUI

public protocol AIComparisonOptionRepresentable: AIListRepresentable {
    /// Feature row entries (label, value or "✓"/"—").
    var features: [(label: String, value: String)] { get }
    /// Short price / headline number, shown big.
    var headline: String { get }
    /// E.g. "/mo".
    var headlineSuffix: String? { get }
    /// Marks this option as "recommended" — gets highlighted styling.
    var isRecommended: Bool { get }
}

extension AIComparisonOptionRepresentable {
    public var headlineSuffix: String? { nil }
    public var isRecommended: Bool { false }
}

public struct AIComparison<T: AIComparisonOptionRepresentable>: View {
    public let title: String
    public let options: [T]

    public init(title: String, options: [T]) {
        self.title = title
        self.options = options
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.title2.bold()).padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(options) { column(for: $0) }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func column(for option: T) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if option.isRecommended {
                Text("RECOMMENDED")
                    .font(.caption2.bold())
                    .tracking(1.2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(option.accentColor))
                    .foregroundStyle(.white)
            }

            HStack {
                Image(systemName: option.icon)
                    .font(.title3)
                    .foregroundStyle(option.accentColor)
                Text(option.primaryDescription)
                    .font(.title3.bold())
            }

            Text(option.secondaryDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(option.headline)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                if let suffix = option.headlineSuffix {
                    Text(suffix).font(.subheadline).foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(option.features.enumerated()), id: \.offset) { _, feature in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: feature.value == "—" ? "minus" : "checkmark.circle.fill")
                            .foregroundStyle(feature.value == "—" ? .secondary : option.accentColor)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(feature.label).font(.subheadline)
                            if feature.value != "✓" && feature.value != "—" {
                                Text(feature.value).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(width: 240, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(option.isRecommended ? option.accentColor : .gray.opacity(0.18),
                              lineWidth: option.isRecommended ? 2 : 1)
        )
        .shadow(color: option.isRecommended ? option.accentColor.opacity(0.2) : .clear,
                radius: 12, y: 4)
    }
}

private struct ComparisonSample: AIComparisonOptionRepresentable {
    let id = UUID()
    let icon: String
    let primaryDescription: String
    let secondaryDescription: String
    let features: [(label: String, value: String)]
    let headline: String
    let headlineSuffix: String?
    let accentColor: Color
    let isRecommended: Bool
    var dateCreated: Date = .now
    var lastUpdated: Date = .now
}

#Preview("AIComparison — Plans") {
    AIComparison(title: "Pick a plan", options: [
        ComparisonSample(
            icon: "sparkle",
            primaryDescription: "Free",
            secondaryDescription: "Get started with the basics.",
            features: [
                ("100 messages / day", "✓"),
                ("Sonnet model", "✓"),
                ("Voice mode", "—"),
                ("Long-term memory", "—"),
            ],
            headline: "$0",
            headlineSuffix: "/mo",
            accentColor: .gray,
            isRecommended: false
        ),
        ComparisonSample(
            icon: "star.fill",
            primaryDescription: "Pro",
            secondaryDescription: "For daily creators and developers.",
            features: [
                ("Unlimited messages", "✓"),
                ("Opus + Sonnet", "✓"),
                ("Voice mode", "✓"),
                ("Long-term memory", "30 days"),
            ],
            headline: "$20",
            headlineSuffix: "/mo",
            accentColor: .blue,
            isRecommended: true
        ),
        ComparisonSample(
            icon: "crown.fill",
            primaryDescription: "Team",
            secondaryDescription: "Shared workspaces & admin controls.",
            features: [
                ("Unlimited messages", "✓"),
                ("All models", "✓"),
                ("Voice mode", "✓"),
                ("Long-term memory", "Unlimited"),
            ],
            headline: "$60",
            headlineSuffix: "/seat",
            accentColor: .purple,
            isRecommended: false
        ),
    ])
}
