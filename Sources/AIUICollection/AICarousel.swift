//
//  AICarousel.swift
//  AIUICollection
//
//  Hero paging carousel — collection template. The LLM picks this when the
//  answer is a handful of premium options the user should swipe through
//  (featured apps, packages, recommendations).
//

import SwiftUI

public protocol AICarouselRepresentable: AIListRepresentable {
    /// Small ticker / eyebrow text above the title (e.g. "FEATURED").
    var eyebrow: String { get }
    /// Optional call-to-action label.
    var callToAction: String? { get }
}

extension AICarouselRepresentable {
    public var eyebrow: String { "FEATURED" }
    public var callToAction: String? { nil }
}

public struct AICarousel<T: AICarouselRepresentable>: View {
    public let title: String
    public let items: [T]

    @State private var scrolledID: T.ID?

    public init(title: String, items: [T]) {
        self.title = title
        self.items = items
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        card(for: item)
                            .containerRelativeFrame(.horizontal)
                            .id(item.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledID)
            .frame(height: 320)

            HStack(spacing: 6) {
                ForEach(items) { item in
                    Capsule()
                        .fill(item.id == (scrolledID ?? items.first?.id) ? Color.primary : .gray.opacity(0.25))
                        .frame(width: item.id == (scrolledID ?? items.first?.id) ? 22 : 8, height: 8)
                        .animation(.spring, value: scrolledID)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical)
    }

    private func card(for item: T) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [item.accentColor.opacity(0.95), item.accentColor.opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: item.icon)
                .font(.system(size: 180, weight: .semibold))
                .foregroundStyle(.white.opacity(0.18))
                .rotationEffect(.degrees(-12))
                .offset(x: 110, y: -30)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(item.eyebrow)
                    .font(.caption.bold())
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.85))
                Text(item.primaryDescription)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text(item.secondaryDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)

                if let cta = item.callToAction {
                    Text(cta)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white))
                        .foregroundStyle(item.accentColor)
                        .padding(.top, 6)
                }
            }
            .padding(22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 8)
    }
}

private struct CarouselSample: AICarouselRepresentable {
    let id = UUID()
    let icon: String
    let primaryDescription: String
    let secondaryDescription: String
    let accentColor: Color
    let eyebrow: String
    let callToAction: String?
    var dateCreated: Date = .now
    var lastUpdated: Date = .now
}

#Preview("AICarousel — Featured agents") {
    AICarousel(title: "For you", items: [
        CarouselSample(
            icon: "sparkles",
            primaryDescription: "Storyteller Pro",
            secondaryDescription: "Long-form fiction co-writer with a memory for character arcs and consistent voice.",
            accentColor: .purple,
            eyebrow: "FEATURED",
            callToAction: "Try free"
        ),
        CarouselSample(
            icon: "chart.bar.xaxis",
            primaryDescription: "Analyst",
            secondaryDescription: "Crunches CSVs, produces decks, and answers follow-ups grounded in your data.",
            accentColor: .blue,
            eyebrow: "NEW",
            callToAction: "Open"
        ),
        CarouselSample(
            icon: "leaf.fill",
            primaryDescription: "Garden Coach",
            secondaryDescription: "Weekly seasonal plans for your climate zone, USDA-grounded planting calendars.",
            accentColor: .green,
            eyebrow: "EDITORS' PICK",
            callToAction: "Get started"
        ),
    ])
}
