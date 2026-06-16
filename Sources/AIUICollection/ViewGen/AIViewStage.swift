//
//  AIViewStage.swift
//  AIUICollection
//
//  The host sink the view-creator finishing tool writes to. A finishing tool's
//  `Output` must be prompt-representable (a `String`), so the *view* it creates
//  is a side effect recorded here — exactly the pattern the workflow's
//  `WorkTurnMonitor` host-stop is built around (a finishing output landed).
//
//  Two faces:
//  • `AIViewSpec` — a Sendable description (template, bound source, item count)
//    that crosses actor/process boundaries for scoring and progress UI.
//  • `AIRenderedView` — the spec plus a `@MainActor` thunk that builds the
//    real SwiftUI view. The app renders it; the headless experiment never has
//    to instantiate SwiftUI to score a run.
//

import Foundation
import SwiftUI

/// A Sendable record of one created view: enough to score and to drive a
/// progress label, with NO bound data in it (only the item *count*).
public struct AIViewSpec: Sendable, Equatable {
    public let template: String
    public let dataSourceKey: String
    public let title: String?
    public let style: String?
    public let itemCount: Int

    public init(
        template: String,
        dataSourceKey: String,
        title: String?,
        style: String?,
        itemCount: Int
    ) {
        self.template = template
        self.dataSourceKey = dataSourceKey
        self.title = title
        self.style = style
        self.itemCount = itemCount
    }
}

/// A created view: its spec plus the deferred builder for the real SwiftUI
/// view, which can render in either presentation (`.standalone` full screen or
/// `.section` for an `AIScreen` composition). Main-actor-bound because view
/// construction is.
@MainActor
public final class AIRenderedView: Identifiable {
    public let id = UUID()
    public let spec: AIViewSpec
    public let makeView: (AIComponentPresentation) -> AnyView

    public init(spec: AIViewSpec, makeView: @escaping (AIComponentPresentation) -> AnyView) {
        self.spec = spec
        self.makeView = makeView
    }
}

/// The process-local stage of created views. The finishing tool appends; the
/// host observes `latest` to render, and a run is scored against `latest.spec`.
@MainActor
@Observable
public final class AIViewStage {
    public private(set) var renders: [AIRenderedView] = []

    public init() {}

    /// The most recently created view, or `nil` before any run.
    public var latest: AIRenderedView? { renders.last }

    /// Record a created view. Called from the finishing tool's `call`.
    public func record(spec: AIViewSpec, makeView: @escaping (AIComponentPresentation) -> AnyView) {
        renders.append(AIRenderedView(spec: spec, makeView: makeView))
    }

    /// Clear between runs so each run is scored on its own output.
    public func reset() {
        renders.removeAll()
    }
}
