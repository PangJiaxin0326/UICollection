//
//  AIViewBuilder.swift
//  AIUICollection
//
//  Turns a template + bound records into a real SwiftUI view. This is the
//  host-side render path: it runs only when a created view is actually shown
//  (the deferred thunk on `AIRenderedView`), so the headless experiment never
//  pays for SwiftUI instantiation while still proving the data binding
//  resolved (the record count rides in `AIViewSpec`).
//
//  Two presentations:
//  • `.standalone` — the full-screen view (its own ScrollView), for a single
//    generated component that fills the canvas.
//  • `.section` — a compact, chrome-less, NON-scrolling body for embedding in
//    an `AIScreen` composition (progressive workflow), where the outer screen
//    scrolls and a section header supplies the label.
//

import SwiftUI

/// How a generated component is presented.
public enum AIComponentPresentation: Sendable {
    case standalone
    case section
}

/// The six templates this experiment routes between. Each maps to one
/// `create_*` finishing tool and one `AIUICollection` view.
public enum AIViewTemplate: String, CaseIterable, Sendable {
    case list, grid, gallery, chart, stats, timeline

    /// The finishing-tool name the router selects.
    public var toolName: String { "create_\(rawValue)" }

    /// The data shape this template reads best — used to advertise fit, not to
    /// gate (the router may still choose any source).
    public var nature: AIDataNature {
        switch self {
        case .chart, .stats: .numeric
        case .list, .grid, .gallery, .timeline: .entities
        }
    }

    /// Terse routing hint shown in the scope catalogue. Less text, by design:
    /// one line that says *when* to reach for this template.
    public var routingHint: String {
        switch self {
        case .list:
            "A scrollable list of entities to skim and tap into (contacts, files, messages)."
        case .grid:
            "A bento grid of equal tiles (apps, shortcuts, categories, options)."
        case .gallery:
            "A visual gallery led by one featured image, then thumbnails (photos, artwork)."
        case .chart:
            "A chart of numeric values across categories or over time (revenue, votes, trend)."
        case .stats:
            "A dashboard of headline KPI numbers with up/down deltas (metrics, vitals)."
        case .timeline:
            "A vertical timeline where order or time is the point (history, itinerary, log)."
        }
    }

    /// User-facing progress text the host shows while the work step runs.
    public var progressText: String {
        switch self {
        case .list: "Building list…"
        case .grid: "Laying out grid…"
        case .gallery: "Composing gallery…"
        case .chart: "Drawing chart…"
        case .stats: "Assembling dashboard…"
        case .timeline: "Tracing timeline…"
        }
    }
}

public enum AIViewBuilder {
    @MainActor
    public static func build(
        template: AIViewTemplate,
        records: [AIRecord],
        title: String?,
        style: String?,
        presentation: AIComponentPresentation = .standalone
    ) -> AnyView {
        switch presentation {
        case .standalone:
            standalone(template: template, records: records, title: title, style: style)
        case .section:
            AISectionBuilder.build(template: template, records: records, style: style)
        }
    }

    @MainActor
    private static func standalone(
        template: AIViewTemplate,
        records: [AIRecord],
        title: String?,
        style: String?
    ) -> AnyView {
        switch template {
        case .list:
            let items = records.map(AIEntityItem.init)
            return AnyView(
                AIList(items: items, sortedBy: .dateDescending) { item in
                    AIEntityDetailView(item: item)
                }
            )
        case .grid:
            let items = records.map(AIEntityItem.init)
            return AnyView(AIGrid(title: title, items: items, columns: columns(from: style)))
        case .gallery:
            let items = records.map(AIEntityItem.init)
            return AnyView(AIGallery(title: title ?? "Gallery", items: items))
        case .chart:
            let items = records.map(AISeriesItem.init)
            return AnyView(
                AIChart(
                    title: title ?? "",
                    subtitle: "",
                    kind: chartKind(from: style),
                    items: items
                )
            )
        case .stats:
            let items = records.map(AIMetricItem.init)
            return AnyView(AIStats(title: title ?? "", items: items))
        case .timeline:
            let items = records.map(AIEntityItem.init)
            return AnyView(AITimeline(items: items))
        }
    }

    static func columns(from style: String?) -> Int {
        guard let style, let n = Int(style.filter(\.isNumber)) else { return 2 }
        return min(max(n, 1), 3)
    }

    static func chartKind(from style: String?) -> AIChart<AISeriesItem>.Kind {
        switch style?.lowercased() {
        case "line": .line
        case "area": .area
        case "point": .point
        case "sector", "pie": .sector
        default: .bar
        }
    }
}

/// Minimal detail shown when a list row is tapped. Kept deliberately spare —
/// the list itself is the answer; the detail is a courtesy.
struct AIEntityDetailView: View {
    let item: AIEntityItem

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.largeTitle)
                .foregroundStyle(item.accentColor)
            Text(item.primaryDescription).font(.headline)
            Text(item.secondaryDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
