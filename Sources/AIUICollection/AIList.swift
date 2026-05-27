//
//  AIList.swift
//  AIUICollection
//
//  The prototype AI-faced UI: a vertical, sortable list of items. Other
//  collection templates (AIGrid, AIGallery, AITimeline, ...) extend this
//  same `AIListRepresentable` contract — see AIRepresentable.swift.
//

import SwiftUI

public struct AIList<T: AIListRepresentable, Content: View>: View {
    @State var items: [T] = []
    @State private var sortOption: T.SortOption
    let onTap: (T) -> Content

    @State private var selectedItem: T? = nil

    public init(items: [T], sortedBy sortOption: T.SortOption, onTap: @escaping (T) -> Content) {
        self.items = items
        self._sortOption = .init(initialValue: sortOption)
        self.onTap = onTap
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(items) { item in
                    AIListRow(for: item)
                    Divider().padding(.horizontal)
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ZStack {
                Rectangle().fill(LinearGradient(colors: (0..<6).reversed().map({ .white.opacity(Double($0)/5) }), startPoint: .top, endPoint: .bottom))
                    .ignoresSafeArea()
                HStack {
                    Text(sortOption.description)
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 5)
                        .padding(.horizontal)
                        .glassEffect(.clear.tint(.gray.opacity(0.1)), in: .capsule)
                    Spacer()
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
        }
        .sheet(item: $selectedItem) { item in
            onTap(item)
        }
    }

    private func AIListRow(for item: T) -> some View {
        ZStack(alignment: .leading) {
            HStack {
                Image(systemName: item.icon)
                    .padding(.horizontal)
                    .font(.title)
                    .foregroundStyle(item.accentColor)
                    .frame(width: 50)

                VStack(alignment: .leading) {
                    Text(item.primaryDescription)
                        .font(.headline.bold())
                    Text(item.secondaryDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .contentShape(.rect)
            .onTapGesture {
                selectedItem = item
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

private struct Item: AIListRepresentable {
    var id: UUID = .init()
    var icon: String = "apple.logo"
    var primaryDescription: String = "Apple Inc"
    var secondaryDescription: String = "Cupertino, California"
    var dateCreated: Date = .now
    var lastUpdated: Date = .now
}

private struct ItemDetailView<T: AIListRepresentable>: View {
    @State var item: T
    var body: some View {
        VStack {
            Image(systemName: item.icon)
            Text(item.primaryDescription)
            Text(item.secondaryDescription)
        }
    }
}

#Preview {
    AIList(items: [
        Item(),
        Item(icon: "g.circle", primaryDescription: "Google Inc"),
        Item(icon: "m.circle", primaryDescription: "Microsoft Inc"),
        Item(icon: "n.circle", primaryDescription: "Nvidia Inc"),
        Item(icon: "i.circle", primaryDescription: "Intel Inc"),
    ], sortedBy: .dateDescending) { item in
        ItemDetailView(item: item)
    }
}
