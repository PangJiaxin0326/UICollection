//
//  AIViewCatalog.swift
//  AIUICollection
//
//  Assembles one view-generation surface: the data sources (bindings), the six
//  view-creator finishing tools wired to those sources and a shared stage, and
//  a ready sample dataset. The model only ever sees the finishing tools and
//  the source keys; `sources` hold the real rows behind `fetch()`.
//

import Foundation
import AIToolKit

@MainActor
public final class AIViewCatalog {
    private var isRunning = false
    public let stage: AIViewStage
    public let sources: [any AIDataSource]
    public let finishing: [AIViewCreatorTool]

    public init(sources: [any AIDataSource], stage: AIViewStage = AIViewStage()) {
        self.stage = stage
        self.sources = sources
        self.finishing = AIViewTemplate.allCases.map {
            AIViewCreatorTool(template: $0, sources: sources, stage: stage)
        }
    }

    /// Runners sharing a catalog also share its stage; admit only one run.
    func beginRun() -> Bool {
        guard !isRunning else { return false }
        isRunning = true
        return true
    }

    func endRun() { isRunning = false }

    public var finishingTools: [any FinishingTool] { finishing }

    /// Clear the stage so a run is scored on its own output.
    public func resetStage() { stage.reset() }

    /// The specs created so far, snapshotted off the main-actor stage.
    public func producedSpecs() -> [AIViewSpec] { stage.renders.map(\.spec) }

    /// The experiment / demo surface: 12 sources spanning entities and numeric
    /// data, paired with the six templates.
    public static func sample(stage: AIViewStage = AIViewStage()) -> AIViewCatalog {
        AIViewCatalog(sources: AISampleData.sources, stage: stage)
    }
}

/// Fixed stand-in data. In a real app these would be HealthKit, Contacts, a
/// query result — here, deterministic rows so a run can be scored. None of it
/// reaches the model; it is bound into the view host-side.
public enum AISampleData {
    public static let sources: [any AIDataSource] = [
        // MARK: entities
        AIStaticDataSource(
            key: "contacts",
            description: "People you have saved.",
            nature: .entities,
            records: [
                AIRecord(icon: "person.crop.circle", title: "Alex Chen", subtitle: "Product · San Francisco", accent: .blue, date: day(-2)),
                AIRecord(icon: "person.crop.circle", title: "Mia Rivera", subtitle: "Design · New York", accent: .pink, date: day(-1)),
                AIRecord(icon: "person.crop.circle", title: "Sam Okoye", subtitle: "Engineering · London", accent: .teal, date: day(-5)),
                AIRecord(icon: "person.crop.circle", title: "Priya Nair", subtitle: "Research · Bengaluru", accent: .purple, date: day(-3)),
            ]
        ),
        AIStaticDataSource(
            key: "apps",
            description: "Apps installed on this device.",
            nature: .entities,
            records: [
                AIRecord(icon: "message.fill", title: "Messages", subtitle: "Chat", accent: .green),
                AIRecord(icon: "map.fill", title: "Maps", subtitle: "Navigation", accent: .blue),
                AIRecord(icon: "camera.fill", title: "Camera", subtitle: "Photos & video", accent: .gray),
                AIRecord(icon: "music.note", title: "Music", subtitle: "Listening", accent: .pink),
                AIRecord(icon: "calendar", title: "Calendar", subtitle: "Schedule", accent: .red),
                AIRecord(icon: "wallet.pass.fill", title: "Wallet", subtitle: "Cards & passes", accent: .orange),
            ]
        ),
        AIStaticDataSource(
            key: "trip_photos",
            description: "Photos from your last trip.",
            nature: .entities,
            records: [
                AIRecord(icon: "mountain.2.fill", title: "Sunrise ridge", subtitle: "Kyoto · 6:14 AM", accent: .orange),
                AIRecord(icon: "leaf.fill", title: "Bamboo grove", subtitle: "Arashiyama", accent: .green),
                AIRecord(icon: "building.columns.fill", title: "Old shrine", subtitle: "Fushimi Inari", accent: .red),
                AIRecord(icon: "fork.knife", title: "Night market", subtitle: "Nishiki", accent: .yellow),
                AIRecord(icon: "moon.stars.fill", title: "Lantern walk", subtitle: "Gion", accent: .purple),
            ]
        ),
        AIStaticDataSource(
            key: "saved_articles",
            description: "Articles you saved to read later.",
            nature: .entities,
            records: [
                AIRecord(icon: "doc.richtext", title: "The case for small models", subtitle: "12 min · AI", accent: .indigo),
                AIRecord(icon: "doc.richtext", title: "Designing calm software", subtitle: "8 min · Design", accent: .mint),
                AIRecord(icon: "doc.richtext", title: "How memory works", subtitle: "15 min · Science", accent: .blue),
            ]
        ),
        AIStaticDataSource(
            key: "order_history",
            description: "Your past orders, newest first.",
            nature: .entities,
            records: [
                AIRecord(icon: "shippingbox.fill", title: "Desk lamp", subtitle: "Delivered", accent: .orange, date: day(-1)),
                AIRecord(icon: "shippingbox.fill", title: "USB-C cable", subtitle: "Delivered", accent: .gray, date: day(-4)),
                AIRecord(icon: "shippingbox.fill", title: "Running shoes", subtitle: "Delivered", accent: .green, date: day(-9)),
                AIRecord(icon: "shippingbox.fill", title: "Coffee beans", subtitle: "Delivered", accent: .brownish, date: day(-14)),
            ]
        ),
        // MARK: numeric
        AIStaticDataSource(
            key: "revenue_by_week",
            description: "Daily revenue for the last 7 days, in USD.",
            nature: .numeric,
            records: [
                AIRecord(icon: "dollarsign.circle", title: "Mon", subtitle: "USD", value: 1200, accent: .blue),
                AIRecord(icon: "dollarsign.circle", title: "Tue", subtitle: "USD", value: 1840, accent: .blue),
                AIRecord(icon: "dollarsign.circle", title: "Wed", subtitle: "USD", value: 2200, accent: .blue),
                AIRecord(icon: "dollarsign.circle", title: "Thu", subtitle: "USD", value: 1700, accent: .blue),
                AIRecord(icon: "dollarsign.circle", title: "Fri", subtitle: "USD", value: 3100, accent: .indigo),
                AIRecord(icon: "dollarsign.circle", title: "Sat", subtitle: "USD", value: 2750, accent: .indigo),
                AIRecord(icon: "dollarsign.circle", title: "Sun", subtitle: "USD", value: 980, accent: .indigo),
            ]
        ),
        AIStaticDataSource(
            key: "sales_by_month",
            description: "Monthly sales for the last 6 months.",
            nature: .numeric,
            records: [
                AIRecord(icon: "chart.line.uptrend.xyaxis", title: "Jan", subtitle: "units", value: 320, accent: .green),
                AIRecord(icon: "chart.line.uptrend.xyaxis", title: "Feb", subtitle: "units", value: 410, accent: .green),
                AIRecord(icon: "chart.line.uptrend.xyaxis", title: "Mar", subtitle: "units", value: 380, accent: .green),
                AIRecord(icon: "chart.line.uptrend.xyaxis", title: "Apr", subtitle: "units", value: 520, accent: .green),
                AIRecord(icon: "chart.line.uptrend.xyaxis", title: "May", subtitle: "units", value: 610, accent: .green),
                AIRecord(icon: "chart.line.uptrend.xyaxis", title: "Jun", subtitle: "units", value: 700, accent: .green),
            ]
        ),
        AIStaticDataSource(
            key: "traffic_sources",
            description: "Share of website traffic by source, in percent.",
            nature: .numeric,
            records: [
                AIRecord(icon: "magnifyingglass", title: "Organic", subtitle: "SEO", value: 42, accent: .green),
                AIRecord(icon: "arrow.right.circle", title: "Direct", subtitle: "Bookmarks", value: 23, accent: .blue),
                AIRecord(icon: "link", title: "Referral", subtitle: "Partners", value: 18, accent: .purple),
                AIRecord(icon: "bubble.left.and.bubble.right", title: "Social", subtitle: "X, LinkedIn", value: 11, accent: .pink),
                AIRecord(icon: "megaphone", title: "Paid", subtitle: "Ads", value: 6, accent: .orange),
            ]
        ),
        AIStaticDataSource(
            key: "expenses_by_category",
            description: "This month's spending by category, in USD.",
            nature: .numeric,
            records: [
                AIRecord(icon: "house.fill", title: "Rent", subtitle: "USD", value: 1800, accent: .indigo),
                AIRecord(icon: "cart.fill", title: "Groceries", subtitle: "USD", value: 540, accent: .green),
                AIRecord(icon: "car.fill", title: "Transport", subtitle: "USD", value: 220, accent: .blue),
                AIRecord(icon: "fork.knife", title: "Dining", subtitle: "USD", value: 310, accent: .orange),
                AIRecord(icon: "bolt.fill", title: "Utilities", subtitle: "USD", value: 160, accent: .yellow),
            ]
        ),
        AIStaticDataSource(
            key: "product_kpis",
            description: "Key product metrics with week-over-week change.",
            nature: .numeric,
            records: [
                AIRecord(icon: "person.2.fill", title: "Active users", subtitle: "Daily average", value: 12400, deltaPercent: 8.2, accent: .blue),
                AIRecord(icon: "cart.fill", title: "Revenue", subtitle: "Subscriptions + IAP", value: 48900, deltaPercent: -2.4, accent: .green),
                AIRecord(icon: "bolt.fill", title: "Retention D7", subtitle: "Last cohort", value: 42, unit: "%", deltaPercent: 4.1, accent: .orange),
                AIRecord(icon: "exclamationmark.triangle.fill", title: "Crash rate", subtitle: "All versions", value: 0.18, unit: "%", deltaPercent: -12.0, accent: .red),
            ]
        ),
        AIStaticDataSource(
            key: "health_today",
            description: "Today's health vitals.",
            nature: .numeric,
            records: [
                AIRecord(icon: "figure.walk", title: "Steps", subtitle: "Goal 10,000", value: 8200, deltaPercent: 6.0, accent: .green),
                AIRecord(icon: "heart.fill", title: "Resting HR", subtitle: "bpm", value: 58, unit: "bpm", deltaPercent: -3.0, accent: .red),
                AIRecord(icon: "bed.double.fill", title: "Sleep", subtitle: "hours", value: 7.4, unit: "h", deltaPercent: 2.0, accent: .indigo),
                AIRecord(icon: "flame.fill", title: "Active energy", subtitle: "kcal", value: 540, unit: "kcal", deltaPercent: 11.0, accent: .orange),
            ]
        ),
        AIStaticDataSource(
            key: "poll_results",
            description: "Votes per option in the team lunch poll.",
            nature: .numeric,
            records: [
                AIRecord(icon: "fork.knife", title: "Ramen", subtitle: "votes", value: 14, accent: .red),
                AIRecord(icon: "fork.knife", title: "Tacos", subtitle: "votes", value: 11, accent: .orange),
                AIRecord(icon: "fork.knife", title: "Salad", subtitle: "votes", value: 6, accent: .green),
                AIRecord(icon: "fork.knife", title: "Pizza", subtitle: "votes", value: 9, accent: .yellow),
            ]
        ),
    ]

    private static func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: .now) ?? .now
    }
}

private extension AIAccent {
    /// A warm brown stand-in (the palette has no literal brown).
    static var brownish: AIAccent { .orange }
}
