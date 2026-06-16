//
//  AIComposition.swift
//  AIUICollection
//
//  The composite the progressive workflow builds: a screen of stacked
//  sections, each a generated component. Hierarchy is carried by typography
//  and whitespace — a large screen title, a semibold section title, a
//  secondary caption — not by nested boxes, so a multi-component screen reads
//  as one clean page rather than a pile of cards.
//

import SwiftUI

/// One section of an `AIScreen`: a labeled component body.
public struct AIScreenSection: Identifiable {
    public let id: UUID
    public let title: String
    public let subtitle: String?
    public let content: AnyView

    public init(id: UUID = UUID(), title: String, subtitle: String? = nil, content: AnyView) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }
}

/// A vertical composition of generated components. `isStreaming` shows a
/// "composing" footer while more sections are still arriving (progressive).
public struct AIScreen: View {
    public let title: String
    public let sections: [AIScreenSection]
    public let isStreaming: Bool

    public init(title: String, sections: [AIScreenSection], isStreaming: Bool = false) {
        self.title = title
        self.sections = sections
        self.isStreaming = isStreaming
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(title)
                    .font(.largeTitle.bold())
                    .padding(.bottom, 2)

                ForEach(sections) { section in
                    AISectionView(section: section)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                if isStreaming {
                    streamingFooter
                        .transition(.opacity)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var streamingFooter: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Composing…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

/// One section: header (typography only) above its component body.
struct AISectionView: View {
    let section: AIScreenSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.title3.weight(.semibold))
                if let subtitle = section.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            section.content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
