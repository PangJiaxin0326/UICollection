//
//  ProfileDashboardContent.swift
//  UICollection
//
//  Reusable metric/activity content for profile-style dashboards.
//

import Foundation
import SwiftUI

public struct ProfileDashboardMetric: Identifiable {
    public var id: String
    public var title: String
    public var value: String
    public var systemImage: String
    public var tint: Color
    public var accessibilityLabel: String?

    public init(
        id: String? = nil,
        title: String,
        value: String,
        systemImage: String,
        tint: Color = .blue,
        accessibilityLabel: String? = nil
    ) {
        self.id = id ?? "\(title)-\(systemImage)"
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.tint = tint
        self.accessibilityLabel = accessibilityLabel
    }
}

public enum ProfileMetricFormatter {
    public static func compactCount(_ value: Int) -> String {
        let sign = value < 0 ? "-" : ""
        let magnitude = Double(abs(value))
        let units: [(threshold: Double, suffix: String)] = [
            (1_000_000_000, "B"),
            (1_000_000, "M"),
            (1_000, "K"),
        ]

        guard let unit = units.first(where: { magnitude >= $0.threshold }) else {
            return "\(value)"
        }

        let scaled = magnitude / unit.threshold
        let rounded = (scaled * 10).rounded() / 10
        let text: String
        if rounded.rounded() == rounded {
            text = "\(Int(rounded))"
        } else {
            text = String(format: "%.1f", rounded)
        }
        return "\(sign)\(text)\(unit.suffix)"
    }
}

public struct ProfileDashboardContent: View {
    public var metrics: [ProfileDashboardMetric]
    public var activityDates: [Date]
    public var trackingStartDate: Date?
    public var showsActivity: Bool
    public var activityTitle: String
    public var trackingStartLabel: String

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    public init(
        metrics: [ProfileDashboardMetric],
        activityDates: [Date] = [],
        trackingStartDate: Date? = nil,
        showsActivity: Bool = true,
        activityTitle: String = "ACTIVITY",
        trackingStartLabel: String = "Tracking since"
    ) {
        self.metrics = metrics
        self.activityDates = activityDates
        self.trackingStartDate = trackingStartDate
        self.showsActivity = showsActivity
        self.activityTitle = activityTitle
        self.trackingStartLabel = trackingStartLabel
    }

    public var body: some View {
        VStack(spacing: 24) {
            if !metrics.isEmpty {
                metricsOverview
            }
            if showsActivity {
                activitySection
            }
            trackingSince
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 120)
    }

    private var metricsOverview: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(metrics) { metric in
                ProfileMetricCell(metric: metric)
            }
        }
        .padding(16)
        .dashboardCard()
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(activityTitle)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            ActivityHeatmap(activityDates: activityDates)
        }
        .padding(16)
        .dashboardCard()
    }

    @ViewBuilder
    private var trackingSince: some View {
        if let trackingStartDate {
            VStack(spacing: 4) {
                Text(trackingStartLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(trackingStartDate, format: .dateTime.month(.wide).year())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

private struct ProfileMetricCell: View {
    let metric: ProfileDashboardMetric

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: metric.systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(metric.tint)
                .frame(width: 30, height: 30)
                .background(metric.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(metric.title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(metric.value)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(metric.accessibilityLabel ?? "\(metric.title): \(metric.value)")
    }
}

#Preview {
    ProfileView(
        config: .init(
            userName: "Alex",
            userHandle: "Personal dashboard",
            headerButtons: [
                .init("Settings", systemImage: "gearshape", tint: .gray),
            ]
        )
    ) {
        ProfileDashboardContent(
            metrics: [
                .init(title: "Messages", value: "42", systemImage: "message.fill", tint: .blue),
                .init(title: "Total Tokens", value: "18.4K", systemImage: "text.word.spacing", tint: .indigo),
                .init(title: "Active Days", value: "12", systemImage: "calendar", tint: .green),
                .init(title: "Current Streak", value: "4", systemImage: "flame.fill", tint: .orange),
                .init(title: "Longest Streak", value: "9", systemImage: "trophy.fill", tint: .yellow),
                .init(title: "Peak Hour", value: "8 PM", systemImage: "clock.fill", tint: .purple),
            ],
            activityDates: [Date()],
            trackingStartDate: Date()
        )
    }
}
