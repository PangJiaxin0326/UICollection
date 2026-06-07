//
//  ActivityHeatmap.swift
//  UICollection
//
//  GitHub-style 7×N contribution heatmap for day-level activity. The view is
//  pure SwiftUI: callers hand in dates and the grid colours its cells by
//  per-day count.
//

import SwiftUI

public struct ActivityHeatmap: View {
    public let activityDates: [Date]
    public let rows: Int
    public let weeks: Int
    public let spacing: CGFloat
    public let calendar: Calendar

    public init(
        activityDates: [Date],
        rows: Int = 7,
        weeks: Int = 17,
        spacing: CGFloat = 3.5,
        calendar: Calendar = .current
    ) {
        self.activityDates = activityDates
        self.rows = rows
        self.weeks = weeks
        self.spacing = spacing
        self.calendar = calendar
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                let cellSize = (geo.size.width - spacing * CGFloat(weeks - 1)) / CGFloat(weeks)
                HStack(spacing: spacing) {
                    ForEach(0..<weeks, id: \.self) { week in
                        VStack(spacing: spacing) {
                            ForEach(0..<rows, id: \.self) { day in
                                let date = dateFor(week: week, day: day)
                                let count = activityMap[calendar.startOfDay(for: date), default: 0]
                                RoundedRectangle(cornerRadius: cellSize * 0.25)
                                    .fill(fillColor(for: count, date: date))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .aspectRatio(CGFloat(weeks) / CGFloat(rows), contentMode: .fit)

            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                ForEach(0..<4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(levelColor(level))
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var activityMap: [Date: Int] {
        var map: [Date: Int] = [:]
        for date in activityDates {
            let day = calendar.startOfDay(for: date)
            map[day, default: 0] += 1
        }
        return map
    }

    private func dateFor(week: Int, day: Int) -> Date {
        let today = calendar.startOfDay(for: Date())
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysBack = (weeks - 1 - week) * 7 + (todayWeekday - 1 - day)
        return calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today
    }

    private func fillColor(for count: Int, date: Date) -> Color {
        if date > Date() { return .clear }
        if count == 0 { return .primary.opacity(0.06) }
        return levelColor(min(count, 3))
    }

    private func levelColor(_ level: Int) -> Color {
        switch level {
        case 0: .primary.opacity(0.06)
        case 1: Color.accentColor.opacity(0.3)
        case 2: Color.accentColor.opacity(0.6)
        default: Color.accentColor
        }
    }
}
