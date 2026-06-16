//
//  AIDataSource.swift
//  AIUICollection
//
//  Data-fetching tools, modeled as the toolkit's native `AssistiveTool`, that
//  are PASSED AS BINDINGS to the view-creator finishing tool — never exposed
//  to the model as a data payload.
//
//  The contract that makes "never expose the real data to the LLM" structural:
//
//  • The real, typed rows are reachable only through `fetch()`, a host-side
//    `@MainActor` accessor the finishing tool calls when it builds the view.
//  • The inherited `AssistiveTool.call` returns ONLY a shape descriptor
//    (row count + nature), never a value — so even if a source were ever
//    surfaced to the model, nothing sensitive could cross.
//  • The view-creator does NOT register these as callable assistive tools
//    (`registeredAssistiveTools` stays empty); the model picks a source by
//    *key*, advertised in the work instructions, and the host binds the data.
//

import Foundation
import FoundationModels
import AIToolKit

/// Whether a source holds browsable *entities* or *numeric* measurements — the
/// one bit the router needs to pick a fitting template, safe to advertise.
public enum AIDataNature: String, Sendable, Codable {
    case entities
    case numeric

    public var label: String {
        switch self {
        case .entities: "entities"
        case .numeric: "numeric"
        }
    }
}

/// A data-fetching binding provider. It IS an `AssistiveTool` (the toolkit's
/// data-tool currency), refined so the host can pull typed rows without ever
/// routing them through the model.
public protocol AIDataSource: AssistiveTool where Arguments == EmptyArguments {
    /// The stable key the model references in `AIViewRequest.dataSource`.
    var key: String { get }
    /// Entities vs. numeric — advertised to the router, no values leaked.
    var nature: AIDataNature { get }
    /// The real rows. Host-side only — the bound data the view renders.
    @MainActor func fetch() async -> [AIRecord]
}

public extension AIDataSource {
    /// The assistive-tool name is the source key.
    var name: String { key }

    /// Shape only — count and nature. Deliberately carries NO row values, so
    /// the "never expose real data" guarantee holds even on the off chance a
    /// source is surfaced to the model.
    func call(arguments: EmptyArguments) async throws -> String {
        let count = await fetch().count
        return "\(key): \(count) \(nature.label) rows (data bound host-side)"
    }
}

/// The concrete source used throughout the experiment: a fixed table of
/// records standing in for a real provider (Contacts, HealthKit, a query).
/// The records are private; only `fetch()` exposes them, host-side.
public struct AIStaticDataSource: AIDataSource {
    public let key: String
    public let description: String
    public let nature: AIDataNature
    private let records: [AIRecord]

    public init(
        key: String,
        description: String,
        nature: AIDataNature,
        records: [AIRecord]
    ) {
        self.key = key
        self.description = description
        self.nature = nature
        self.records = records
    }

    @MainActor public func fetch() async -> [AIRecord] { records }
}
