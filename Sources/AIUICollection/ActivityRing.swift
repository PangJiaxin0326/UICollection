//
//  ActivityRing.swift
//  AIUICollection
//
//  Created by Jiaxin Pang on 2026/5/25.
//

import SwiftUI
import Observation

struct ActivityRing: View, @MainActor Animatable {
    var progress: Double                 // 1.0 == 100%, 1.15 == 115%
    var lineWidth: CGFloat = 28
    var colors: [Color]

    var trackOpacity: Double = 0.20
    var overflowShadowOpacity: Double = 0.48

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var value: Double {
        max(progress, 0)
    }

    private var baseProgress: Double {
        min(value, 1)
    }

    private var overflowProgress: Double {
        guard value > 1 else { return 0 }

        let remainder = value.truncatingRemainder(dividingBy: 1)
        return remainder.isAlmostZero ? 0 : remainder
    }

    private var palette: [Color] {
        colors.isEmpty ? [.accentColor] : colors
    }

    // Key fix:
    // The first color is repeated at the end, so the angular-gradient seam
    // is no longer a red/orange, green/cyan, etc. split under the start cap.
    private var seamSafePalette: [Color] {
        palette + [palette[0]]
    }

    private var ringGradient: AngularGradient {
        AngularGradient(
            colors: seamSafePalette,
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }

    private var trackColor: Color {
        palette[0].opacity(trackOpacity)
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let capProgress = overflowProgress > 0 ? overflowProgress : baseProgress
            let capPoint = point(at: capProgress, side: side)

            ZStack {
                Circle()
                    .stroke(
                        trackColor,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

                if value < 1 {
                    ringSegment(
                        to: baseProgress,
                        lineCap: .round
                    )
                } else {
                    // At 100% and above, draw the base as a closed circle.
                    // This avoids a visible doubled cap at the top.
                    Circle()
                        .stroke(
                            ringGradient,
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                lineCap: .butt,
                                lineJoin: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                }

                if overflowProgress > 0 {
                    // Extra lap: same ring path, but drawn above the full ring.
                    ringSegment(
                        to: overflowProgress,
                        lineCap: .round
                    )
                    .shadow(
                        color: .black.opacity(overflowShadowOpacity),
                        radius: lineWidth * 0.22,
                        x: 0,
                        y: lineWidth * 0.12
                    )
                }

                if shouldShowCapHighlight {
                    Circle()
                        .fill(.white.opacity(0.24))
                        .frame(
                            width: lineWidth * 0.34,
                            height: lineWidth * 0.34
                        )
                        .offset(
                            x: -lineWidth * 0.10,
                            y: -lineWidth * 0.12
                        )
                        .position(capPoint)
                        .blendMode(.screen)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: side, height: side)
            .position(
                x: proxy.size.width / 2,
                y: proxy.size.height / 2
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(aiUICollectionText("Activity ring"))
        .accessibilityValue(
            Text(value, format: .percent.precision(.fractionLength(0)))
        )
    }

    private var shouldShowCapHighlight: Bool {
        // Not showing cap highlight
        guard value < 0 else { return false }
        guard value > 0 else { return false }

        // Show the shiny moving cap for partial progress and overflow progress.
        // Hide it at exactly 100%, because the ring is now a clean closed circle.
        return value < 1 || overflowProgress > 0
    }

    private func ringSegment(
        to progress: Double,
        lineCap: CGLineCap
    ) -> some View {
        Circle()
            .trim(from: 0, to: CGFloat(progress.clamped(to: 0...1)))
            .stroke(
                ringGradient,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: lineCap,
                    lineJoin: .round
                )
            )
            .rotationEffect(.degrees(-90))
    }

    private func point(at progress: Double, side: CGFloat) -> CGPoint {
        let radius = (side - lineWidth) / 2
        let angle = progress * 2 * Double.pi - Double.pi / 2

        return CGPoint(
            x: side / 2 + CGFloat(cos(angle)) * radius,
            y: side / 2 + CGFloat(sin(angle)) * radius
        )
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension Double {
    var isAlmostZero: Bool {
        abs(self) < 0.000_001
    }
}

struct ActivityRings: View {
    var move: Double
    var exercise: Double
    var stand: Double

    var ringWidth: CGFloat = 28
    var spacing: CGFloat = 8

    var body: some View {
        ZStack {
            ActivityRing(
                progress: move,
                lineWidth: ringWidth,
                colors: [.red, .pink, .orange]
            )

            ActivityRing(
                progress: exercise,
                lineWidth: ringWidth,
                colors: [.green, .mint]
            )
            .padding(ringWidth + spacing)

            ActivityRing(
                progress: stand,
                lineWidth: ringWidth,
                colors: [.cyan, .blue]
            )
            .padding((ringWidth + spacing) * 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

@MainActor
@Observable
final class ActivityRingsModel {
    var move = 1.15
    var exercise = 0.87
    var stand = 0.42

    func randomize() {
        move = .random(in: 0.05...1.45)
        exercise = .random(in: 0.05...1.25)
        stand = .random(in: 0.05...1.15)
    }
}

@MainActor
struct ActivityRingsDemo: View {
    @State private var model = ActivityRingsModel()

    private let ringAnimation = Animation.smooth(
        duration: 0.85,
        extraBounce: 0.08
    )

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                ActivityRings(
                    move: model.move,
                    exercise: model.exercise,
                    stand: model.stand
                )
                .frame(width: 260, height: 260)

                VStack(spacing: 4) {
                    Text("MOVE")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(model.move, format: .percent.precision(.fractionLength(0)))
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
            }
            .padding(34)
            .background {
                RoundedRectangle(cornerRadius: 44, style: .continuous)
                    .fill(.black)
            }

            Button("Animate Rings") {
                withAnimation(ringAnimation) {
                    model.randomize()
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.title3)
        }
        .padding()
    }
}

#Preview {
    ActivityRingsDemo()
        .preferredColorScheme(.dark)
}
