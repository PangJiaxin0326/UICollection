//
//  AIViewInstructions.swift
//  AIUICollection
//
//  The two instruction texts the view-generation `WorkflowProfile` runs on.
//  Kept short on purpose — the catalogue (rendered by the profile) and the
//  data-source advertisement carry the specifics.
//

import Foundation
import AIToolKit

public enum AIViewInstructions {
    /// Scope step: route to the best-fitting template. Tool calling is
    /// disallowed here; the profile appends the template catalogue.
    public static func scope() -> String {
        """
        You are the UI router for an assistant that answers with native views, \
        in step ONE of a two-step workflow. Choose the view template whose \
        SHAPE best fits the user's request — usually exactly ONE. Selecting \
        the template is your ONLY job; do not build or configure anything in \
        this step, and the templates cannot be called here.

        Prefer the simplest template that conveys the answer, and prefer a \
        VISUAL template when the data has structure: a chart or stats for \
        numbers, a timeline when order/time matters, a gallery for images, a \
        grid for equal options. Fall back to a plain list only for a set of \
        entities the user will skim and tap. Reply with the needed template \
        tool name(s), exactly as listed.
        """
    }

    /// Work step: build the view by calling the selected template tool once,
    /// naming a data source. The sources are advertised by KEY only — the
    /// model never sees rows.
    public static func work(sources: [any AIDataSource]) -> String {
        let catalogue = sources
            .map { "- \($0.key): \($0.description) [\($0.nature.label)]" }
            .joined(separator: "\n")
        return """
        You are the view builder, step TWO. Build the view the user asked for \
        by calling the selected template tool EXACTLY ONCE. Set `dataSource` \
        to the key of the source that holds the answer. You never see the \
        rows — the app binds the real data for you — so never restate, \
        summarize, or invent data, and never write the data into the title.

        Keep it minimal: omit `title` or keep it to a few words and let the \
        data speak; set `style` only when it clearly helps (chart: bar, line, \
        area, point, sector; grid: 2 or 3 columns).

        Available data sources (reference one by its key):
        \(catalogue)

        Pick the single source that matches the request and call the tool now.
        """
    }

    // MARK: - Progressive workflow

    /// Plan step: choose an ordered set of components for a composite screen.
    public static func progressivePlan() -> String {
        """
        You are planning a composite screen for an assistant that answers with \
        native views, in step ONE of a progressive workflow. Choose an ORDERED \
        list of 2 to 4 components that TOGETHER answer the request — the most \
        important first (it renders first, while the rest are still building). \
        Each component is one of the listed component tools; you may repeat a \
        component type when two of them show different data (e.g. two charts). \
        Planning is your ONLY job here — nothing is built in this step. Reply \
        with the ordered component tool names.
        """
    }

    /// Build step: construct exactly one component of the planned composite.
    public static func progressiveStep(
        intent: String,
        plan: [String],
        index: Int,
        sources: [any AIDataSource],
        usedSourceKeys: [String]
    ) -> String {
        let catalogue = sources
            .map { "- \($0.key): \($0.description) [\($0.nature.label)]" }
            .joined(separator: "\n")
        let component = index < plan.count ? plan[index] : "component"
        let used = usedSourceKeys.isEmpty
            ? "none yet"
            : usedSourceKeys.joined(separator: ", ")
        return """
        You are building a composite screen, component \(index + 1) of \
        \(plan.count), for this request: "\(intent)".

        The agreed plan, in order, is: \(plan.joined(separator: ", ")).

        Build component \(index + 1) NOW — a \(component) — by calling its tool \
        exactly once. Set `dataSource` to the source that fits THIS component; \
        do NOT reuse a source already shown on the screen. You never see the \
        rows; the app binds the real data. Keep `title` short or omit it, and \
        set `style` only when it clearly helps.

        Already shown on the screen: \(used).

        Available data sources (reference one by its key):
        \(catalogue)
        """
    }
}
