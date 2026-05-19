//
//  File.swift
//  UICollection
//
//  Created by Jiaxin Pang on 2026/5/17.
//

import SwiftUI

struct TestView: View {
    @State private var isExpanded: Bool = false
    var body: some View {
        Group {
            HStack(spacing: 0) {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(.white)
                    .padding()
                    .contentShape(.circle)
                    .onTapGesture {
                        isExpanded.toggle()
                    }

                if isExpanded {
                    Text("hello")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(isExpanded ? 1 : 0)
                    Spacer()
                    Image(systemName: "xmark")
                        .padding(.horizontal)
                }
            }
            .glassEffect(.regular.interactive().tint(.gray.opacity(0.3)), in: .capsule)
            .animation(.smooth, value: isExpanded)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    TestView()
}
