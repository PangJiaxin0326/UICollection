//
//  CXTabBar.swift
//  UICollection
//
//  Created by Jiaxin Pang on 2026/6/1.
//

import SwiftUI

#if os(iOS)
protocol FABTab: Hashable, CustomStringConvertible, CaseIterable, Identifiable {
    static var `default`: Self { get }
    var symbol: String { get }
}
struct CXTabBarPreview: View {
    enum AppTab: FABTab  {
        case home, saved, liked, account
        static let `default` = Self.home
        
        var description: String {
            switch self {
            case .home: "Home"
            case .saved: "Saved"
            case .liked: "Liked"
            case .account: "Account"
            }
        }
        
        var symbol: String {
            switch self {
            case .home: "house"
            case .saved: "bookmark"
            case .liked: "suit.heart"
            case .account: "person"
            }
        }
        var id: String { description }
    }
    @State private var activeTab: AppTab? = .default
    var body: some View {
        CXTabBar(selection: $activeTab) { tab in
            NavigationStack {
                List {
                    NavigationLink {
                        NavigationStack {
                            Text("Hello")
                                .navigationTitle("HELLO")
                        }
                    } label: {
                        Text(tab.description)
                    }
                }
            }
        } tabFabContent: { tab in
            Text(tab.symbol)
        } accessoryContent: {
            AccessoryView { _, _ in }
        }
    }
}
struct CXTabBar<T: FABTab, TabContent: View, TabFabContent: View, AccessoryContent: View>: View {
    
    @Binding var activeTab: T?
    @State private var isFABExpanded: Bool = false
    @State private var fabHeight: CGFloat = 220
    @State private var tabBar: UITabBar?
    @Namespace private var ns
    
    let tabContent: (T) -> TabContent
    let tabFabContent: (T) -> TabFabContent
    let accessoryContent: () -> AccessoryContent
    

    
    init(selection activeTab: Binding<T?>, tabContent: @escaping (T) -> TabContent, tabFabContent: @escaping (T) -> TabFabContent, accessoryContent: @escaping () -> AccessoryContent) {
        self._activeTab = activeTab
        self.tabContent = tabContent
        self.tabFabContent = tabFabContent
        self.accessoryContent = accessoryContent
    }

    var body: some View {
        TabView(selection: $activeTab) {
            ForEach(Array(T.allCases), id: \.description) { tab in
                Tab.init(tab.description, systemImage: tab.symbol, value: tab) {
                    tabContent(tab)
                        .tabOverlay(isPresented: isFABExpanded) {
                            tabFabContent(tab)
                                .frame(maxWidth: .infinity, maxHeight: fabHeight)
                                .contentShape(.rect)
                                .onTapGesture { fabHeight = 660 - fabHeight }
                        } onDismiss: {
                            isFABExpanded = false
                        }
                        .frame(maxWidth: .infinity, alignment: .bottom)
                        .animation(.smooth, value: fabHeight)
                }
            }
            Tab.init(value: .none, role: .search) {
            } label: {
                Image(systemName: "plus")
            }
        }
        .tabViewBottomAccessory {
            accessoryContent()
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .onChange(of: activeTab) { oldValue, newValue in
            if newValue == nil {
                activeTab = oldValue
                UITabBar.setAnimationsEnabled(false)
                Task { @MainActor in
                    UITabBar.setAnimationsEnabled(true)
                    isFABExpanded.toggle()
                }
            }
        }
        .background(TabBarExtractor { tabBar = $0 })
        .compositingGroup()
        .onChange(of: isFABExpanded) { oldValue, newValue in
            animateFABIcon()
        }
    }
    private func animateFABIcon() {
        let fabImageViews = (tabBar?.subviews(type: UIImageView.self) ?? []).filter({ $0.description.contains("plus") })
        
        for fabImageView in fabImageViews {
            let transform: CGAffineTransform = isFABExpanded ? .init(rotationAngle: 45 * .pi / 180) : .identity
            UIView.animate(withDuration: 0.2) {
                fabImageView.layer.setAffineTransform(transform)
            }
        }
    }
}

struct AccessoryView: View {
    var onPlacementChanged: (_ oldValue: TabViewBottomAccessoryPlacement?, _ newValue: TabViewBottomAccessoryPlacement?) -> ()
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    
    @State var test: String = ""
    var body: some View {
        VStack {
            Text("hello")
                .padding(.horizontal)
                .onChange(of: placement) { oldValue, newValue in
                    onPlacementChanged(oldValue, newValue)
                }
        }
    }
}

extension View {
    @ViewBuilder
    func tabOverlay<Content: View>(
        isPresented: Bool,
        @ViewBuilder content: @escaping () -> Content,
        onDismiss: @escaping () -> ()
    ) -> some View {
        self.modifier(TabOverlayModifier(isPresented: isPresented, viewContent: content, onDismiss: onDismiss))
    }
}

struct TabOverlayModifier<ViewContent: View>: ViewModifier {
    var isPresented: Bool
    @ViewBuilder var viewContent: ViewContent
    var onDismiss: () -> ()
    @State private var isViewAppearing: Bool = false
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                GlassEffectContainer {
                    if isPresented {
                        Rectangle()
                            .fill(.black.opacity(0.25))
                            .contentShape(.rect)
                            .onTapGesture {
                                onDismiss()
                            }
                            .ignoresSafeArea()
                            .transition(.opacity)
                    }
                    if isPresented {
                        viewContent
                            .clipShape(.rect(cornerRadius: 30))
                            .contentShape(.rect(cornerRadius: 30))
                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 30))
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .padding(.horizontal, 15)
                            .padding(.bottom, 10)
                        
                    }
                }
                .allowsHitTesting(isPresented)
                .animation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0), value: isPresented)
            }
            .onAppear {
                isViewAppearing = true
            }
            .onDisappear {
                isViewAppearing = false
            }
    }
}

struct TabBarExtractor: UIViewRepresentable {
    var result: (UITabBar) -> ()
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        Task { @MainActor in
            if let tbc = view.superview?.superview?.subviews.last?.subviews.first?.next as? UITabBarController {
                result(tbc.tabBar)
            }
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
}

fileprivate extension UIView {
    func subviews<T: UIView>(type: T.Type) -> [T] {
        subviews.compactMap { $0 as? T } +
        subviews.flatMap { $0.subviews(type: type) }
    }
}

#Preview {
    CXTabBarPreview()
}
#endif
