//
//  CapsuleSegmentedPicker.swift
//  UICollection
//
//  Horizontal scrolling capsule picker used as the range selector on the
//  stats dashboards. Generic over any `Hashable & Identifiable` value;
//  callers supply a label closure.
//

import SwiftUI

public struct CapsuleSegmentedPicker<Value: Hashable>: View {
    public let values: [Value]
    @Binding public var selection: Value
    public let label: (Value) -> String

    public init(
        values: [Value],
        selection: Binding<Value>,
        label: @escaping (Value) -> String
    ) {
        self.values = values
        self._selection = selection
        self.label = label
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(values, id: \.self) { value in
                    let isActive = selection == value
                    Button {
                        selection = value
                    } label: {
                        Text(label(value))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isActive ? Color.white : Color.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(background(isActive: isActive))
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isActive ? AnyShapeStyle(Color.clear) : AnyShapeStyle(.quaternary),
                                        lineWidth: 0.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    @ViewBuilder
    private func background(isActive: Bool) -> some View {
        if isActive {
            Capsule().fill(Color.accentColor.gradient)
        } else {
            Capsule().fill(.background.secondary)
        }
    }
}
