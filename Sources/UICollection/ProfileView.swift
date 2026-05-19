//
//  ProfileView.swift
//  UICollection
//
//  Created by Jiaxin Pang on 2026/5/19.
//

import Foundation
import SwiftUI

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

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                content()
                .safeAreaInset(edge: .top, spacing: 0) {
                    Header
                }
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
        public var avatarURL: URL
        public var userName: String
        public var userHandle: String

        public init(
            avatarURL: URL = URL(string: "placeholder")!,
            userName: String = "User Nickname",
            userHandle: String = "User Handle"
        ) {
            self.avatarURL = avatarURL
            self.userName = userName
            self.userHandle = userHandle
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
                Rectangle().fill(.teal.gradient)
            } else {
                Circle()
                    .fill(.teal.gradient)
                    .frame(width: 100, height: 100)
                    .blur(radius: 0.5)
            }

            Image(systemName: "apple.logo")
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

#Preview {
    ProfileView {
        Text("something else ")
    }
}
