# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

A Swift package of pre-defined UI, shipped as two library products:

- **UICollection** — traditional, human-designed SwiftUI components (tab bars, onboarding, OTP login, profile views, stat dashboards, …). No dependencies.
- **AIUICollection** — AI-faced UI templates. The idea is for an LLM to select appropriate UI components, layouts, and action buttons at runtime based on user intent, via Apple's FoundationModels tool-calling.

## Commands

```sh
swift build                                # build both targets
swift test                                 # run all tests (Swift Testing, not XCTest)
swift test --filter <testFunctionName>     # run a single test
```

Tests live in `Tests/UICollectionTests/` and use Swift Testing (`@Test`, `#expect`).

## Constraints

- Swift tools 6.3, language mode v6; the AIUICollection target additionally enables `StrictConcurrency`. Everything public there must be `Sendable`-correct.
- Platforms: iOS / macOS / visionOS **27.0** — use current-release APIs freely (e.g. `glassEffect`, Swift Charts, FoundationModels).
- Depends on the sibling local package `../AIToolKit` (path dependency), which defines the `ViewTool` protocol and `GenericToolError`. Changes to the tool-calling contract may need edits there too.

## AIUICollection architecture

Three layers, all of which must stay in sync when adding or changing a template:

1. **Representable contract** ([AIRepresentable.swift](Sources/AIUICollection/AIRepresentable.swift)) — `AIRepresentable` is the minimum surface an LLM can render (icon + primary/secondary description, defaulted accent color and badges). `AIListRepresentable` adds timestamps and a sort comparator; every collection template (AIList, AIGrid, AIGallery, AITimeline, AIKanban, AICarousel, AIChart, AIStats, AIComparison) takes items conforming to it. Host apps adopt these protocols on their own data types.

2. **Template views** (`Sources/AIUICollection/*.swift`) — generic SwiftUI views over the representable protocols. Some templates extend the contract (e.g. `AIChartRepresentable` adds `value: Double`). Each file's header comment states when the LLM should pick that template — keep those accurate, they document the selection intent.

3. **ViewTools** (`Sources/AIUICollection/ViewTools/`) — one `ViewTool` per template, the LLM-facing entry point. The pattern, consistent across all of them:
   - a `@Generable` `Input` struct (the wire schema), always carrying a `model: String` key;
   - static `toolName` (`render_ai_*`) and `toolDescription` written *for the LLM* to choose among tools;
   - `call(arguments:)` delegates to a host-injected `render` closure — the host resolves the `model` key into actual items and detail views; the tool only declares schema and routes.
   - Enums on the wire (e.g. `AIChartViewKind`, `AISortOption`) mirror the view-layer enum and implement `Generable` by hand via `DynamicGenerationSchema(name:anyOf:)` over raw values. Follow that idiom for new constrained-choice parameters.
   - `ViewToolDefaults.modelHelp` is the shared description for the `model` parameter — reuse it.

## Localization

User-facing strings in both targets go through the per-module helpers (`uiCollectionText(_:)` / `aiUICollectionText(_:)` or `*Localization.string(_:)`), which resolve against the target's `Resources/Localizable.xcstrings` with `bundle: .module`. Never use bare `Text("...")` for displayable copy; add new strings to the corresponding `.xcstrings` catalog.
