//
//  ViewToolSupport.swift
//  AIUICollection
//
//  Tiny shared surface for the per-view `ViewTool`s. The interesting work
//  happens in each tool file; this file just declares the standard schema
//  fragment for the `model` selector so descriptions stay consistent.
//

import AIToolKit

enum ViewToolDefaults {
    /// One-liner used in every render tool's description to remind the host
    /// to inject the list of available model names via system context.
    static let modelHelp =
        "Name of the model to render. The host advertises which model keys are valid via system context."
}
