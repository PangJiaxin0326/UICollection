//
//  FlexibleTabBar.swift
//  UICollection
//
//  Created by Jiaxin Pang on 2026/5/17.
//

#if os(iOS)
import SwiftUI

struct FlexibleTabBar: View {
    var tabs: [TabItem]
    @Binding var config: Config
    @State private var isGlassInteractionEnabled: Bool = true
    var body: some View {
        GlassEffectContainer(spacing: 10) {
            let isMorphed = config.isMorphed
            let tabActions = config.tabActions
            let mainActionShape = tabActions?.mainActionShape ?? .capsule
            let mainActionBackground = tabActions?.mainActionBackground ?? .clear
            let layout: AnyLayout = isMorphed ? AnyLayout(HStackLayout(spacing: 10)) : AnyLayout(ZStackLayout())
            layout {
                if let leadingAction = tabActions?.leadingAction {
                    ActionItemView(leadingAction)

                    if config.flexibility == .flexible {
                        Spacer(minLength: 0)
                    }
                }
                let morphWidth: CGFloat = mainActionShape == .capsule ? 110 : 45
                let morphHeight: CGFloat = mainActionShape == .capsule ? 50 : 45
                CustomTabBar(tabs: tabs, activeTab: $config.activeTab)
                    .opacity(isMorphed ? 0 : 1)
                    .allowsHitTesting(!isMorphed)
                    .frame(width: CGFloat(tabs.count) * 60, height: 45)
                    .frame(width: isMorphed ? morphWidth : nil, height: isMorphed ? morphHeight : nil)
                    .overlay {
                        if let mainAction = tabActions?.mainAction {
                            Image(systemName: mainAction.symbol)
                                .font(mainActionShape == .circle ? .title3 : .title2)
                                .fontWeight(.medium)
                                .foregroundStyle(tabActions?.mainActionForeground ?? .primary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(.capsule)
                                .onTapGesture {
                                    mainAction.action()
                                }
                                .opacity(isMorphed ? 1 : 0)
                                .blur(radius: isMorphed ? 0 : 6)
                                .allowsHitTesting(isMorphed)
                        }
                    }
                    .clipShape(.capsule)
                    .glassEffect(.regular.interactive().tint(mainActionBackground.opacity(isMorphed ? 1 : 0)), in: .capsule)
                if let trailingAction = tabActions?.trailingAction {
                    if config.flexibility == .flexible {
                        Spacer(minLength: 0)
                    }
                    ActionItemView(trailingAction)
                }
            }
        }
        .animation(config.morphAnimation, value: config.isMorphed)
        .onChange(of: config.isMorphed) { oldValue, newValue in
            isGlassInteractionEnabled = false
            Task { @MainActor in
                isGlassInteractionEnabled = true
            }
        }
        .padding(.horizontal, 15)
    }

    @ViewBuilder
    private func ActionItemView(_ item: Config.ActionItem) -> some View {
        ZStack {
            if config.isMorphed {
                Image(systemName: item.symbol)
                    .font(.title3)
                    .foregroundStyle(Color.primary)
                    .transition(.blurReplace.combined(with: .opacity))
            }
        }
        .frame(width: 45, height: 45)
        .contentShape(.circle)
        .glassEffect(.regular.interactive(config.isMorphed), in: .circle)
        .onTapGesture {
            item.action()
        }
        .allowsHitTesting(config.isMorphed)
    }

    struct Config {
        var activeTab: Int
        var flexibility: Flexibility = .fixed
        var isMorphed: Bool = false
        var tabActions: TabActions?
        var morphAnimation: Animation = .smooth

        struct TabActions {
            var mainActionShape: MainActionShape = .capsule
            var mainActionForeground: Color = .white
            var mainActionBackground: Color = .red
            var mainAction: ActionItem
            var leadingAction: ActionItem?
            var trailingAction: ActionItem?
        }
        struct ActionItem {
            var symbol: String
            var action: () -> ()
        }
        enum Flexibility: String, CaseIterable {
            case fixed = "Fixed"
            case flexible = "Flexible"
        }
        enum MainActionShape: String, CaseIterable {
            case circle = "Circle"
            case capsule = "Capsule"
        }
    }
    struct TabItem {
        var symbol: String
    }
}

fileprivate struct CustomTabBar: UIViewRepresentable {
    var tabs: [FlexibleTabBar.TabItem]
    @Binding var activeTab: Int

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: tabs.compactMap({ $0.symbol }))
        let font = UIFont.preferredFont(forTextStyle: .body)
        for (index, item) in tabs.enumerated() {
            let image = UIImage(
                systemName: item.symbol,
                withConfiguration: UIImage.SymbolConfiguration(font: font)
            )
            control.setImage(image, forSegmentAt: index)
        }
        control.selectedSegmentTintColor = UIColor(Color.gray.opacity(0.25))

        /// Remove Background Color
        Task { @MainActor in
            for subview in control.subviews.dropLast() {
                if subview is UIImageView {
                    subview.alpha = 0
                }
            }
        }
        control.addTarget(context.coordinator, action: #selector(Coordinator.didItemChanged(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        if uiView.selectedSegmentIndex != activeTab {
            uiView.selectedSegmentIndex = activeTab
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISegmentedControl, context: Context) -> CGSize? {
        return .init(width: proposal.width ?? 0, height: proposal.height ?? 0)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject {
        var parent: CustomTabBar
        init(parent: CustomTabBar) {
            self.parent = parent
        }

        @MainActor @objc
        func didItemChanged(_ control: UISegmentedControl) {
            parent.activeTab = control.selectedSegmentIndex
        }
    }
}


struct FlexibleTabBarPreview: View {
    @State private var tabConfig: FlexibleTabBar.Config = .init(activeTab: 0)
    var body: some View {
        TabView(selection: $tabConfig.activeTab) {
            Tab.init(value: 0) {
                Button("Morph") {
                    tabConfig.tabActions = .init(
                        mainAction: .init(symbol: "suit.heart.fill") {},
                        leadingAction: .init(symbol: "hand.thumbsup") {},
                        trailingAction: .init(symbol: "hand.thumbsdown") {},
                    )
                    Task {
                        tabConfig.isMorphed.toggle()
                    }
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab.init(value: 1) {
                Text("Notifications")
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab.init(value: 2) {
                Text("Account")
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab.init(value: 3) {
                Text("nothing")
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        FlexibleTabBar(tabs: [
            .init(symbol: "house.fill"),
            .init(symbol: "bell.fill"),
            .init(symbol: "person.fill"),
            .init(symbol: "xmark")
        ], config: $tabConfig)
    }
}
#Preview {
    FlexibleTabBarPreview()
}

#endif
