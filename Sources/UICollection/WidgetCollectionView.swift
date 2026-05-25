//
//  WidgetCollectionView.swift
//  UICollection
//
//  Created by Codex on 2026/5/21.
//

import SwiftUI

/// Semantic widget sizes expressed as row * column spans in the collection grid.
public enum WidgetBlockSize: String, CaseIterable, Identifiable, Sendable {
    case rows1Columns4 = "1x4"
    case rows2Columns2 = "2x2"
    case rows2Columns4 = "2x4"
    case rows4Columns4 = "4x4"

    public var id: Self { self }

    public var rows: Int {
        switch self {
        case .rows1Columns4:
            return 1
        case .rows2Columns2, .rows2Columns4:
            return 2
        case .rows4Columns4:
            return 4
        }
    }

    public var columns: Int {
        switch self {
        case .rows2Columns2:
            return 2
        case .rows1Columns4, .rows2Columns4, .rows4Columns4:
            return 4
        }
    }
}

/// A fixed-size widget board inspired by the iPhone Home Screen.
public struct WidgetCollectionView<Content: View>: View {
    public var config: Config
    private let content: (WidgetBlockConfiguration) -> Content

    public init(
        config: Config,
        @ViewBuilder content: @escaping (WidgetBlockConfiguration) -> Content
    ) {
        self.config = config
        self.content = content
    }

    public var body: some View {
        WidgetBoardLayout(config: config.layoutConfiguration) {
            ForEach(config.blocks) { block in
                let blockConfig = block.blockConfig(
                    cornerRadius: config.standard.cornerRadius,
                    contentPadding: config.standard.contentPadding
                )

                WidgetBlockView(config: blockConfig) { resolvedConfig in
                    content(resolvedConfig)
                }
                .contentShape(.rect)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(block.accessibilityLabel)
            }
        }
        .animation(config.animation, value: config.blocks.map(\.layoutSignature))
    }
}

extension WidgetCollectionView {
    public struct Config {
        public var standard: Standard
        public var blocks: [Block]
        public var animation: Animation

        public init(
            standard: Standard = .iphoneLike,
            blocks: [Block],
            animation: Animation = .smooth(duration: 0.35)
        ) {
            self.standard = standard
            self.blocks = blocks
            self.animation = animation
        }

        fileprivate var layoutConfiguration: WidgetLayoutConfiguration {
            .init(
                columns: standard.columns,
                spacing: standard.spacing,
                topInset: standard.contentInsets.top,
                leadingInset: standard.contentInsets.leading,
                bottomInset: standard.contentInsets.bottom,
                trailingInset: standard.contentInsets.trailing,
                fallbackCellLength: standard.fallbackCellLength,
                blocks: blocks.map { block in
                    .init(
                        size: block.size
                    )
                }
            )
        }

        /// Defines the internal measurement standard used to turn semantic sizes into point sizes.
        public struct Standard {
            public var columns: Int
            public var spacing: CGFloat
            public var contentInsets: EdgeInsets
            public var fallbackCellLength: CGFloat
            public var cornerRadius: CGFloat
            public var contentPadding: CGFloat

            public init(
                columns: Int = 4,
                spacing: CGFloat = 12,
                contentInsets: EdgeInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12),
                fallbackCellLength: CGFloat = 78,
                cornerRadius: CGFloat = 24,
                contentPadding: CGFloat = 14
            ) {
                self.columns = max(columns, 1)
                self.spacing = max(spacing, 0)
                self.contentInsets = contentInsets
                self.fallbackCellLength = max(fallbackCellLength, 1)
                self.cornerRadius = max(cornerRadius, 0)
                self.contentPadding = max(contentPadding, 0)
            }

            public static var iphoneLike: Standard {
                .init()
            }

            /// The default standard: 1x4, 2x2, 2x4, and 4x4 in row * column spans.
            public func span(for size: WidgetBlockSize) -> GridSpan {
                .init(columns: size.columns, rows: size.rows)
            }

            public func resolvedCellLength(for proposedWidth: CGFloat?) -> CGFloat {
                guard let proposedWidth else { return fallbackCellLength }

                let horizontalInsets = contentInsets.leading + contentInsets.trailing
                let totalSpacing = CGFloat(columns - 1) * spacing
                let availableWidth = max(proposedWidth - horizontalInsets - totalSpacing, 1)

                return max(1, floor(availableWidth / CGFloat(columns)))
            }

            /// Returns the actual point size for a block at the given collection width.
            public func resolvedSize(for size: WidgetBlockSize, proposedWidth: CGFloat?) -> CGSize {
                let cellLength = resolvedCellLength(for: proposedWidth)
                let span = span(for: size)

                return .init(
                    width: CGFloat(span.columns) * cellLength + CGFloat(span.columns - 1) * spacing,
                    height: CGFloat(span.rows) * cellLength + CGFloat(span.rows - 1) * spacing
                )
            }
        }

        public struct GridSpan {
            public var columns: Int
            public var rows: Int

            public init(columns: Int, rows: Int) {
                self.columns = max(columns, 1)
                self.rows = max(rows, 1)
            }
        }

        /// A block that inhabits the collection. The array order defines its flow placement.
        public struct Block: Identifiable {
            public var id: String
            public var size: WidgetBlockSize
            public var title: String
            public var subtitle: String?
            public var systemImage: String?
            public var tint: Color
            public var background: Color?

            public init(
                id: String,
                size: WidgetBlockSize,
                title: String,
                subtitle: String? = nil,
                systemImage: String? = nil,
                tint: Color = .blue,
                background: Color? = nil
            ) {
                self.id = id
                self.size = size
                self.title = title
                self.subtitle = subtitle
                self.systemImage = systemImage
                self.tint = tint
                self.background = background
            }

            fileprivate var layoutSignature: String {
                "\(id)-\(size.rawValue)"
            }

            fileprivate var accessibilityLabel: String {
                if let subtitle, subtitle.isEmpty == false {
                    return "\(title), \(subtitle), \(size.rawValue)"
                }

                return "\(title), \(size.rawValue)"
            }

            fileprivate func blockConfig(cornerRadius: CGFloat, contentPadding: CGFloat) -> WidgetBlockConfiguration {
                .init(
                    id: id,
                    size: size,
                    title: title,
                    subtitle: subtitle,
                    systemImage: systemImage,
                    tint: tint,
                    background: background,
                    cornerRadius: cornerRadius,
                    contentPadding: contentPadding
                )
            }
        }
    }
}

/// The visual container for one widget block.
public struct WidgetBlockView<Content: View>: View {
    public var config: WidgetBlockConfiguration
    private let content: (WidgetBlockConfiguration) -> Content

    public init(
        config: WidgetBlockConfiguration,
        @ViewBuilder content: @escaping (WidgetBlockConfiguration) -> Content
    ) {
        self.config = config
        self.content = content
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
                .fill(config.resolvedBackground)

            RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(config.materialOpacity)

            content(config)
                .padding(config.contentPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(.rect(cornerRadius: config.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }
}

extension WidgetBlockView {
    public typealias Config = WidgetBlockConfiguration
}

/// State passed into a block so its content can switch between the predefined row * column sizes.
public struct WidgetBlockConfiguration: Identifiable {
    public var id: String
    public var size: WidgetBlockSize
    public var title: String
    public var subtitle: String?
    public var systemImage: String?
    public var tint: Color
    public var background: Color?
    public var cornerRadius: CGFloat
    public var contentPadding: CGFloat

    public init(
        id: String,
        size: WidgetBlockSize,
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        tint: Color = .blue,
        background: Color? = nil,
        cornerRadius: CGFloat = 24,
        contentPadding: CGFloat = 14
    ) {
        self.id = id
        self.size = size
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.background = background
        self.cornerRadius = cornerRadius
        self.contentPadding = contentPadding
    }

    fileprivate var resolvedBackground: Color {
        background ?? tint.opacity(0.18)
    }

    fileprivate var materialOpacity: Double {
        switch background {
        case .none:
            return 1
        case .some:
            return 0.58
        }
    }
}

private struct WidgetLayoutConfiguration: Sendable {
    var columns: Int
    var spacing: CGFloat
    var topInset: CGFloat
    var leadingInset: CGFloat
    var bottomInset: CGFloat
    var trailingInset: CGFloat
    var fallbackCellLength: CGFloat
    var blocks: [WidgetLayoutBlock]

    var horizontalInsets: CGFloat {
        leadingInset + trailingInset
    }

    var verticalInsets: CGFloat {
        topInset + bottomInset
    }

    func span(for size: WidgetBlockSize) -> WidgetLayoutSpan {
        .init(columns: min(size.columns, columns), rows: size.rows)
    }

    func resolvedCellLength(for proposedWidth: CGFloat?) -> CGFloat {
        guard let proposedWidth else { return fallbackCellLength }

        let totalSpacing = CGFloat(columns - 1) * spacing
        let availableWidth = max(proposedWidth - horizontalInsets - totalSpacing, 1)

        return max(1, floor(availableWidth / CGFloat(columns)))
    }
}

private struct WidgetLayoutBlock: Sendable {
    var size: WidgetBlockSize
}

private struct WidgetLayoutSpan: Sendable {
    var columns: Int
    var rows: Int
}

private struct WidgetBoardLayout: Layout {
    var config: WidgetLayoutConfiguration

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let proposedWidth = proposal.width
        let cellLength = config.resolvedCellLength(for: proposedWidth)
        let width = proposedWidth ?? fallbackWidth(cellLength: cellLength)
        let height = resolvedFrames(cellLength: cellLength).reduce(config.verticalInsets) { partialResult, frame in
            max(partialResult, frame.maxY + config.bottomInset)
        }

        return .init(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let cellLength = config.resolvedCellLength(for: bounds.width)
        let frames = resolvedFrames(cellLength: cellLength)

        for (index, subview) in subviews.enumerated() {
            guard frames.indices.contains(index) else { continue }

            let frame = frames[index]
                .offsetBy(dx: bounds.minX, dy: bounds.minY)

            subview.place(
                at: frame.origin,
                anchor: .topLeading,
                proposal: .init(width: frame.width, height: frame.height)
            )
        }
    }

    private func fallbackWidth(cellLength: CGFloat) -> CGFloat {
        let spacing = CGFloat(config.columns - 1) * config.spacing

        return CGFloat(config.columns) * cellLength + spacing + config.horizontalInsets
    }

    private func resolvedFrames(cellLength: CGFloat) -> [CGRect] {
        var occupiedCells = Set<WidgetGridCell>()

        return config.blocks.map { block in
            let span = config.span(for: block.size)
            let origin = firstAvailableOrigin(for: span, occupiedCells: occupiedCells)
            let frame = blockFrame(origin: origin, span: span, cellLength: cellLength)

            occupy(span: span, at: origin, in: &occupiedCells)

            return frame
        }
    }

    private func firstAvailableOrigin(
        for span: WidgetLayoutSpan,
        occupiedCells: Set<WidgetGridCell>
    ) -> WidgetGridCell {
        var row = 0

        while row < Int.max {
            let lastColumn = max(config.columns - span.columns, 0)

            for column in 0...lastColumn {
                let origin = WidgetGridCell(row: row, column: column)

                if canPlace(span: span, at: origin, occupiedCells: occupiedCells) {
                    return origin
                }
            }

            row += 1
        }

        return .init(row: 0, column: 0)
    }

    private func canPlace(
        span: WidgetLayoutSpan,
        at origin: WidgetGridCell,
        occupiedCells: Set<WidgetGridCell>
    ) -> Bool {
        guard origin.column + span.columns <= config.columns else { return false }

        for row in origin.row..<(origin.row + span.rows) {
            for column in origin.column..<(origin.column + span.columns) {
                if occupiedCells.contains(.init(row: row, column: column)) {
                    return false
                }
            }
        }

        return true
    }

    private func occupy(
        span: WidgetLayoutSpan,
        at origin: WidgetGridCell,
        in occupiedCells: inout Set<WidgetGridCell>
    ) {
        for row in origin.row..<(origin.row + span.rows) {
            for column in origin.column..<(origin.column + span.columns) {
                occupiedCells.insert(.init(row: row, column: column))
            }
        }
    }

    private func blockFrame(
        origin: WidgetGridCell,
        span: WidgetLayoutSpan,
        cellLength: CGFloat
    ) -> CGRect {
        let originX = config.leadingInset + CGFloat(origin.column) * (cellLength + config.spacing)
        let originY = config.topInset + CGFloat(origin.row) * (cellLength + config.spacing)
        let width = CGFloat(span.columns) * cellLength + CGFloat(span.columns - 1) * config.spacing
        let height = CGFloat(span.rows) * cellLength + CGFloat(span.rows - 1) * config.spacing

        return .init(x: originX, y: originY, width: width, height: height)
    }
}

private struct WidgetGridCell: Hashable {
    var row: Int
    var column: Int
}

private struct WidgetCollectionPreview: View {
    private let config = WidgetCollectionView<WidgetPreviewContent>.Config(
        blocks: [
            .init(
                id: "weather",
                size: .rows1Columns4,
                title: "Weather",
                subtitle: "Shanghai",
                systemImage: "cloud.sun.fill",
                tint: .cyan,
                background: .cyan.opacity(0.20)
            ),
            .init(
                id: "activity",
                size: .rows2Columns2,
                title: "Move",
                subtitle: "72%",
                systemImage: "figure.walk",
                tint: .green,
                background: .green.opacity(0.20)
            ),
            .init(
                id: "calendar",
                size: .rows2Columns4,
                title: "Calendar",
                subtitle: "Today",
                systemImage: "calendar",
                tint: .red,
                background: .red.opacity(0.18)
            ),
            .init(
                id: "battery",
                size: .rows2Columns2,
                title: "Battery",
                subtitle: "84%",
                systemImage: "battery.75percent",
                tint: .yellow,
                background: .yellow.opacity(0.20)
            ),
            .init(
                id: "summary",
                size: .rows4Columns4,
                title: "Summary",
                subtitle: "Week",
                systemImage: "chart.bar.xaxis",
                tint: .indigo,
                background: .indigo.opacity(0.18)
            )
        ]
    )

    var body: some View {
        ScrollView {
            WidgetCollectionView(config: config) { block in
                WidgetPreviewContent(config: block)
            }
            .padding(12)
        }
        .background(.fill.tertiary)
    }
}

private struct WidgetPreviewContent: View {
    var config: WidgetBlockConfiguration

    var body: some View {
        switch config.size {
        case .rows1Columns4:
            HStack(spacing: 12) {
                previewHeader
                Spacer(minLength: 0)
                Text(config.subtitle ?? config.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

        case .rows2Columns2:
            VStack(alignment: .leading, spacing: 8) {
                previewHeader
                Spacer(minLength: 0)
                Text(config.subtitle ?? config.size.rawValue)
                    .font(.title.bold())
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        case .rows2Columns4:
            HStack(alignment: .top, spacing: 14) {
                previewIcon

                VStack(alignment: .leading, spacing: 8) {
                    Text(config.title)
                        .font(.title3.bold())
                    Text(config.subtitle ?? config.size.rawValue)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { index in
                            Capsule()
                                .fill(config.tint.opacity(index < 3 ? 0.85 : 0.22))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        case .rows4Columns4:
            VStack(alignment: .leading, spacing: 14) {
                previewHeader
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 8) {
                    Text(config.title)
                        .font(.title2.bold())
                    Text(config.subtitle ?? config.size.rawValue)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        VStack(spacing: 6) {
                            Text("\((index + 1) * 12)")
                                .font(.headline)
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(config.tint.opacity(index < 3 ? 0.85 : 0.22))
                                .frame(height: CGFloat(24 + (index * 14)))
                                .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 130, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var previewHeader: some View {
        HStack(spacing: 8) {
            previewIcon

            Text(config.title)
                .font(.headline)
                .lineLimit(1)
        }
    }

    private var previewIcon: some View {
        Image(systemName: config.systemImage ?? "square.grid.2x2.fill")
            .font(.title3)
            .foregroundStyle(config.tint)
            .frame(width: 30, height: 30)
            .background(config.tint.opacity(0.15), in: .circle)
    }
}

#Preview {
    WidgetCollectionPreview()
}
