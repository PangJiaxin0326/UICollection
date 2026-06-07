//
//  ProfileView.swift
//  UICollection
//
//  Created by Jiaxin Pang on 2026/5/19.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public protocol ProfileViewSnapshot {
    var sessionCount: Int { get }
    var messageCount: Int { get }
    var totalTokenUsage: Int { get }
    var streakDays: Int { get }
    var longestStreakDays: Int { get }
    var activeDayCount: Int { get }
    var activityDates: [Date] { get }
    var activeSinceDate: Date? { get }
}

public struct ProfileView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLargeHeader: Bool = false
    @State private var topInset: CGFloat = 0.0
    @State private var scrollPhase: ScrollPhase = .idle

    public var config: Config
    let content: () -> Content

    public init(config: Config = .init(), @ViewBuilder content: @escaping () -> Content) {
        self.config = config
        self.content = content
    }

    public init(config: Config = .init()) where Content == EmptyView {
        self.config = config
        self.content = { EmptyView() }
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    if let snapshot = config.snapshot {
                        ProfileSnapshotView(snapshot: snapshot)
                    }
                    content()
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    Header
                }
            }
            .background {
                config.backgroundStyle.view
            }
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentInsets.top
            } action: { _, newValue in
                topInset = newValue
            }
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { _, newValue in
                if scrollPhase == .interacting {
                    withAnimation(.snappy(duration: 0.2, extraBounce: 0)) {
                        isLargeHeader = newValue < -10 || (isLargeHeader && newValue < 0)
                    }
                }
            }
            .onScrollPhaseChange { _, newPhase in
                scrollPhase = newPhase
            }
        }
    }

    public struct Config {
        public enum BackgroundStyle {
            case grouped
            case tertiaryFill
            case clear
            case color(Color)
        }

        public struct HeaderActionButton: Identifiable {
            public var id: String
            public var title: String
            public var systemImage: String
            public var tint: Color
            public var action: () -> ()

            public init(
                _ title: String,
                systemImage: String,
                tint: Color = .blue,
                action: @escaping () -> () = {}
            ) {
                self.id = "\(title)-\(systemImage)"
                self.title = title
                self.systemImage = systemImage
                self.tint = tint
                self.action = action
            }

        }

        public var avatarURL: URL
        public var userName: String
        public var userHandle: String
        public var headerButtons: [HeaderActionButton]
        public var placeholderSystemImage: String
        public var backgroundStyle: BackgroundStyle
        public var snapshot: (any ProfileViewSnapshot)?

        public init(
            avatarURL: URL = URL(string: "placeholder")!,
            userName: String = "User Nickname",
            userHandle: String = "User Handle",
            headerButtons: [HeaderActionButton] = [],
            placeholderSystemImage: String = "person.crop.circle.fill",
            backgroundStyle: BackgroundStyle = .grouped,
            snapshot: (any ProfileViewSnapshot)? = nil
        ) {
            self.avatarURL = avatarURL
            self.userName = userName
            self.userHandle = userHandle
            self.headerButtons = headerButtons
            self.placeholderSystemImage = placeholderSystemImage
            self.backgroundStyle = backgroundStyle
            self.snapshot = snapshot
        }
    }
}

private struct ProfileSnapshotView: View {
    let snapshot: any ProfileViewSnapshot

    var body: some View {
        VStack(spacing: 24) {
            statsOverview
            activitySection
            activeSince
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 120)
    }

    private var statsOverview: some View {
        let valueFont: Font = .title3.weight(.semibold).monospacedDigit()
        return VStack(spacing: 14) {
            HStack(spacing: 0) {
                StatCell(value: "\(snapshot.sessionCount)", label: "Sessions", valueFont: valueFont)
                StatCell(value: "\(snapshot.messageCount)", label: "Messages", valueFont: valueFont)
                StatCell(
                    value: ProfileSnapshotMetricFormat.compact(snapshot.totalTokenUsage),
                    label: "Tokens",
                    valueFont: valueFont
                )
            }

            HStack(spacing: 0) {
                StatCell(value: "\(snapshot.streakDays)", label: "Streak", valueFont: valueFont)
                StatCell(value: "\(snapshot.longestStreakDays)", label: "Max Streak", valueFont: valueFont)
                StatCell(value: "\(snapshot.activeDayCount)", label: "Active", valueFont: valueFont)
            }
        }
        .padding(.vertical, 16)
        .dashboardCard()
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ACTIVITY")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            ActivityHeatmap(activityDates: snapshot.activityDates)
        }
        .padding(16)
        .dashboardCard()
    }

    @ViewBuilder
    private var activeSince: some View {
        if let activeSinceDate = snapshot.activeSinceDate {
            VStack(spacing: 4) {
                Text("Active since")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(activeSinceDate, format: .dateTime.month(.wide).year())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

private enum ProfileSnapshotMetricFormat {
    static func compact(_ value: Int) -> String {
        let sign = value < 0 ? "-" : ""
        let absolute = abs(Double(value))
        let units: [(threshold: Double, suffix: String)] = [
            (1_000_000_000, "B"),
            (1_000_000, "M"),
            (1_000, "K"),
        ]

        guard let unit = units.first(where: { absolute >= $0.threshold }) else {
            return value.formatted(.number)
        }

        let scaled = absolute / unit.threshold
        let rounded = (scaled * 10).rounded() / 10
        return sign + String(format: "%.1f", rounded) + unit.suffix
    }
}

private extension ProfileView.Config.BackgroundStyle {
    @ViewBuilder
    var view: some View {
        switch self {
        case .grouped:
            #if canImport(UIKit)
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            #elseif canImport(AppKit)
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            #else
            Color.clear
                .ignoresSafeArea()
            #endif
        case .tertiaryFill:
            Rectangle()
                .fill(.fill.tertiary)
                .ignoresSafeArea()
        case .clear:
            Color.clear
                .ignoresSafeArea()
        case .color(let color):
            color
                .ignoresSafeArea()
        }
    }
}

extension ProfileView {
    @ViewBuilder
    private var Header: some View {
        VStack(spacing: 0) {
            Rectangle()
                .foregroundStyle(.clear)
                .frame(width: 100, height: isLargeHeader ? 300 : 100)
                .clipShape(.circle)

            VStack(spacing: 20) {
                HeaderNavigationBar()
                    .foregroundStyle(isLargeHeader ? .white : .primary)
                    .padding(.horizontal, 15)
                
                if !config.headerButtons.isEmpty {
                    HeaderActionButtonRow()
                        .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 10)
        .background(alignment: .top) {
            GeometryReader {
                let size = $0.size
                let minY = $0.frame(in: .global).minY
                let topOffset = isLargeHeader ? minY : 0
                LogoView(for: config.avatarURL)
                    .frame(
                        width: size.width,
                        height: size.height + topOffset
                    )
                    .clipShape(.rect(cornerRadius: isLargeHeader ? 0 : 50))
                    .offset(y: -topOffset)
            }
            .frame(
                width: isLargeHeader ? nil : 100,
                height: isLargeHeader ? nil : 100
            )

        }
        .padding(.top, 15)
    }

    @ViewBuilder
    private func LogoView(for url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                AvatarPlaceholder()
            case .empty:
                ProgressView()
            @unknown default:
                AvatarPlaceholder()
            }
        }
    }

    @ViewBuilder
    private func AvatarPlaceholder() -> some View {
        ZStack {
            if isLargeHeader {
                Rectangle().fill(.black)
            } else {
                Circle()
                    .fill(.black)
                    .frame(width: 100, height: 100)
                    .blur(radius: 0.5)
            }

            Image(systemName: config.placeholderSystemImage)
                .font(isLargeHeader ? .system(size: 44, weight: .black, design: .rounded) : .system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, isLargeHeader ? 24 : 10)
                .padding(.vertical, isLargeHeader ? 12 : 6)
                .glassEffect(.clear.tint(.black.opacity(0.18)), in: .circle)
                .offset(y: isLargeHeader ? 0 : 5)
        }
    }

    @ViewBuilder
    private func HeaderNavigationBar() -> some View {
        VStack(alignment: isLargeHeader ? .leading : .center, spacing: 12) {
            VStack(alignment: isLargeHeader ? .leading : .center, spacing: 6) {
                Text(config.userName)
                    .font(.title)
                    .fontWeight(.semibold)
                    .onTapGesture {
                        // Switch Account Sheet
                    }

                Text(config.userHandle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

        }
        .frame(maxWidth: .infinity, alignment:  isLargeHeader ? .leading : .center)
        .visualEffect { content, proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let progress = max(min(minY / 50, 1), 0)
            return content
                .scaleEffect(0.7 + (0.3 * progress))
                .offset(y: minY < 0 ? -minY : 0)
        }
        .background(NavigationBarBackground())
        .zIndex(10)
    }

    @ViewBuilder
    private func HeaderActionButtonRow() -> some View {
        HStack(spacing: 10) {
            ForEach(config.headerButtons) { button in
                HeaderActionButton(button)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func HeaderActionButton(_ button: Config.HeaderActionButton) -> some View {
        Button(action: button.action) {
            HStack(spacing: 8) {
                Image(systemName: button.systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(button.tint)
                    .frame(width: 24, height: 24)
                    .background(button.tint.opacity(0.12), in: Circle())

                Text(button.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 96, maxWidth: .infinity, minHeight: 40)
            .background {
                HeaderActionButtonSurface(tint: button.tint)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(ProfileHeaderActionButtonStyle())
        .accessibilityLabel(button.title)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func HeaderActionButtonSurface(tint: Color) -> some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay {
                Capsule()
                    .fill(tint.opacity(colorScheme == .dark ? 0.10 : 0.07))
            }
            .overlay {
                Capsule()
                    .stroke(
                        .white.opacity(colorScheme == .dark ? 0.16 : 0.55),
                        lineWidth: 0.5
                    )
            }
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.22 : 0.08),
                radius: 12,
                x: 0,
                y: 6
            )
    }

    @ViewBuilder
    private func NavigationBarBackground() -> some View {
        GeometryReader {
            let minY = $0.frame(in: .scrollView(axis: .vertical)).minY
            let opacity: CGFloat = 1.0 - max(min(minY / 50, 1), 0)
            let tint: Color = colorScheme == .dark ? Color.black : Color.white

            ZStack {
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.clear.tint(tint.opacity(0.8)), in: .rect)
                    .mask {
                        LinearGradient(colors: [
                            .black,
                            .black,
                            .black,
                            .black.opacity(0.9),
                            .black.opacity(0.4),
                            .clear
                        ], startPoint: .top, endPoint: .bottom)
                    }
            }
            .padding(-20)
            .padding(.bottom, -40)
            .padding(.top, -topInset)
            .offset(y: -minY)
            .opacity(opacity)
        }
        .allowsHitTesting(false)
    }

}

private struct ProfileHeaderActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.snappy(duration: 0.16, extraBounce: 0), value: configuration.isPressed)
    }
}

#Preview {
    ProfileView {
        Text("something else ")
    }
}
