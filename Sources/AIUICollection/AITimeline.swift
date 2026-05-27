//
//  AITimeline.swift
//  AIUICollection
//
//  Vertical event timeline — collection template. The LLM picks this when
//  ordering is meaningful (history, changelog, itinerary, project
//  milestones).
//

import SwiftUI

public struct AITimeline<T: AIListRepresentable>: View {
    public let items: [T]

    public init(items: [T]) {
        self.items = items
    }

    private static var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MMM d · HH:mm"
        return df
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    row(for: item, isLast: idx == items.count - 1)
                }
            }
            .padding()
        }
    }

    private func row(for item: T, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(item.accentColor.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Image(systemName: item.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(item.accentColor)
                }
                if !isLast {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 6) {
                Text(Self.timeFormatter.string(from: item.dateCreated))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(item.primaryDescription)
                    .font(.headline)
                Text(item.secondaryDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.gray.opacity(0.12))
            )
            .padding(.bottom, isLast ? 0 : 14)
        }
    }
}

private struct TimelineSample: AIListRepresentable {
    let id = UUID()
    let icon: String
    let primaryDescription: String
    let secondaryDescription: String
    let dateCreated: Date
    var lastUpdated: Date
    let accentColor: Color
}

#Preview("AITimeline — Itinerary") {
    let now = Date()
    return AITimeline(items: [
        TimelineSample(
            icon: "airplane.departure",
            primaryDescription: "Depart SFO",
            secondaryDescription: "United UA837 · Gate 78 · Boarding 09:40",
            dateCreated: now,
            lastUpdated: now,
            accentColor: .blue
        ),
        TimelineSample(
            icon: "airplane.arrival",
            primaryDescription: "Arrive Narita (NRT)",
            secondaryDescription: "Terminal 1 · Train to Tokyo: Narita Express ~60 min",
            dateCreated: now.addingTimeInterval(60 * 60 * 11),
            lastUpdated: now,
            accentColor: .indigo
        ),
        TimelineSample(
            icon: "bed.double.fill",
            primaryDescription: "Check-in: Park Hyatt Tokyo",
            secondaryDescription: "Confirmation #PH-22841 · Quiet room facing Shinjuku Park",
            dateCreated: now.addingTimeInterval(60 * 60 * 14),
            lastUpdated: now,
            accentColor: .purple
        ),
        TimelineSample(
            icon: "fork.knife",
            primaryDescription: "Dinner: Den (Jimbocho)",
            secondaryDescription: "Reservation 19:30 · Tasting course · Walk from Shinjuku 22 min",
            dateCreated: now.addingTimeInterval(60 * 60 * 18),
            lastUpdated: now,
            accentColor: .pink
        ),
    ])
}
