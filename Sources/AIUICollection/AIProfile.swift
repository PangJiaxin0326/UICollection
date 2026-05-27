//
//  AIProfile.swift
//  AIUICollection
//
//  Profile card — the LLM picks this when the answer is a single entity
//  with identity (a person, an agent, an org, a place). Single-item; built
//  on `AIRepresentable`.
//

import SwiftUI

public protocol AIProfileRepresentable: AIRepresentable {
    /// Bio / longer description.
    var bio: String { get }
    /// Stat pairs shown in a row (label, value).
    var statRow: [(label: String, value: String)] { get }
    /// Two-letter monogram fallback when there is no avatar.
    var monogram: String { get }
}

extension AIProfileRepresentable {
    public var bio: String { secondaryDescription }
    public var statRow: [(label: String, value: String)] { [] }
    public var monogram: String {
        primaryDescription
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }
}

public struct AIProfile<T: AIProfileRepresentable>: View {
    public let item: T

    public init(item: T) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            banner
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 14, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.gray.opacity(0.1))
        )
        .padding()
    }

    private var banner: some View {
        ZStack {
            LinearGradient(
                colors: [
                    item.accentColor.opacity(0.95),
                    item.accentColor.opacity(0.55),
                    item.accentColor.opacity(0.85),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: item.icon)
                .font(.system(size: 140, weight: .semibold))
                .foregroundStyle(.white.opacity(0.18))
                .rotationEffect(.degrees(-10))
                .offset(x: 90, y: -10)
        }
        .frame(height: 130)
        .clipped()
        .overlay(alignment: .bottomLeading) {
            avatar
                .padding(.leading, 20)
                .offset(y: 36)
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(.background)
                .frame(width: 84, height: 84)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
            Circle()
                .fill(item.accentColor.opacity(0.22))
                .frame(width: 72, height: 72)
            Text(item.monogram)
                .font(.title.bold())
                .foregroundStyle(item.accentColor)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.primaryDescription).font(.title3.bold())
                Text(item.secondaryDescription).font(.subheadline).foregroundStyle(.secondary)
            }

            if !item.badges.isEmpty {
                HStack(spacing: 6) {
                    ForEach(item.badges, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(item.accentColor.opacity(0.14)))
                            .foregroundStyle(item.accentColor)
                    }
                }
            }

            if !item.bio.isEmpty && item.bio != item.secondaryDescription {
                Text(item.bio)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !item.statRow.isEmpty {
                HStack(spacing: 0) {
                    ForEach(Array(item.statRow.enumerated()), id: \.offset) { idx, stat in
                        VStack(spacing: 2) {
                            Text(stat.value).font(.headline)
                            Text(stat.label).font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        if idx < item.statRow.count - 1 {
                            Divider().frame(height: 28)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .padding(.top, 36)
    }
}

private struct ProfileSample: AIProfileRepresentable {
    let id = UUID()
    let icon: String
    let primaryDescription: String
    let secondaryDescription: String
    let bio: String
    let statRow: [(label: String, value: String)]
    let badges: [String]
    let accentColor: Color
}

#Preview("AIProfile — Person") {
    AIProfile(item: ProfileSample(
        icon: "person.fill",
        primaryDescription: "Ada Lovelace",
        secondaryDescription: "Mathematician · London, 1843",
        bio: "Wrote the first published algorithm intended for Babbage's Analytical Engine. Often considered the first computer programmer.",
        statRow: [("Publications", "9"), ("Letters", "1,200+"), ("Engines", "1")],
        badges: ["Pioneer", "Algorithm", "Babbage"],
        accentColor: .indigo
    ))
}

#Preview("AIProfile — Agent") {
    AIProfile(item: ProfileSample(
        icon: "sparkles",
        primaryDescription: "Atlas Researcher",
        secondaryDescription: "Web-grounded research agent",
        bio: "Reads, synthesizes, and cites primary sources across 50+ domains. Outputs structured briefs and follow-up questions.",
        statRow: [("Tasks", "8.4k"), ("Sources", "120+"), ("Rating", "4.9")],
        badges: ["Research", "Cited", "Long-context"],
        accentColor: .teal
    ))
}
