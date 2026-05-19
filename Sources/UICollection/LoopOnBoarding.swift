//
//  LoopOnBoarding.swift
//  UICollection
//
//  Created by Jiaxin Pang on 2026/5/16.
//

import SwiftUI

struct LoopOnBoarding: View {
    var config: Config = .init()
    var phases: [Phase]
    var onButtonClick: () -> ()
    
    @State private var startDate: Date = .now
    var body: some View {
        ZStack {
            /// With Respect to PhaseAfter Update Count
            let timelineDuration = CGFloat(config.phaseUpdateAfter) * 3.0
            /// Animating Icon View
            TimelineView(.periodic(from: startDate, by: timelineDuration)) { ctx in
                let diff = Int(startDate.distance(to: ctx.date)) / (config.phaseUpdateAfter * 3)
                let index = diff % phases.count
                ZStack {
                    Image(systemName: phases[index].symbol)
                        .font(.system(size: config.iconSize - 20))
                        .foregroundStyle(config.tint.gradient)
                        .contentTransition(.symbolEffect(.replace.downUp))
                        .frame(width: config.iconSize, height: config.iconSize)
                        /// Bounce Animation Using Keyframes
                        .keyframeAnimator(initialValue: 1.0, repeating: true) { content, scale in
                            content.scaleEffect(scale)
                        } keyframes: { _ in
                            let scale = config.iconScale
                            
                            /// 3 Times bounces to match with 3 Pulse Ring
                            /// Max Duration Combined: 3.0s
                            MoveKeyframe(1)
                            SpringKeyframe(1, duration: 0.25)
                            SpringKeyframe(scale, duration: 0.25)
                            SpringKeyframe(1, duration: 0.25)
                            SpringKeyframe(scale, duration: 0.25)
                            SpringKeyframe(1, duration: 0.25)
                            SpringKeyframe(scale, duration: 0.25)
                            SpringKeyframe(1, duration: 0.25)
                            CubicKeyframe(1, duration: 1.25)
                        }
                        .padding(.bottom, 130)
                    /// Text Contents
                    ZStack {
                        ForEach(phases.indices, id: \.self) { phaseIndex in
                            if phaseIndex == index {
                                TextContent(phase: phases[phaseIndex])
                                    .transition(
                                        .asymmetric(
                                            insertion: .push(from: .bottom),
                                            removal: .push(from: .bottom)
                                        )
                                        .combined(with: AnyTransition(.blurReplace))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, config.showButtons ? 75 : 10)
                    .animation(.bouncy(duration: 0.8), value: index)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    ZStack {
                        PulseRing(delay: 0, wait: 1)
                        PulseRing(delay: 0.5, wait: 0.5)
                        PulseRing(delay: 1, wait: 0)
                    }
                }
                .padding(.bottom, 130)
        }
        .overlay(alignment: .bottom) {
            /// Button
            if config.showButtons {
                Button(action: onButtonClick) {
                    Text(config.buttonTitle)
                        .font(.title3)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(config.tint)
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
            }
        }
        .background {
            Circle()
                .fill(config.tint.gradient)
                .visualEffect { content, proxy in
                    content
                        .offset(y: proxy.size.height * 1.07)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .blur(radius: 90)
        }
        .animation(.bouncy(duration: 0.8), value: config.showButtons)
    }
    @ViewBuilder
    private func PulseRing(delay: CGFloat, wait: CGFloat) -> some View {
        let size = config.iconSize / 2
        KeyframeAnimator(initialValue: Pulse(), repeating: true) { pulse in
            Circle()
                .stroke(config.pulseTint, lineWidth: config.pulseWidth)
                .frame(width: size * pulse.scale, height: size * pulse.scale)
                .opacity((pulse.scale - 1.0) / 3.0)
                .opacity(pulse.opacity)
        } keyframes: { _ in
            let scale = config.pulseScale
            
            MoveKeyframe(Pulse())
            LinearKeyframe(Pulse(), duration: delay)
            LinearKeyframe(Pulse(scale: scale, opacity: 0), duration: 2)
            LinearKeyframe(Pulse(scale: scale, opacity: 0), duration: wait)
        }
    }
    
    /// Text Content
    @ViewBuilder
    private func TextContent(phase: Phase) -> some View {
        VStack(alignment: .center, spacing: 12) {
            Text(phase.title)
                .font(.title2.bold())
                .lineLimit(1)
            
            Text(phase.description)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.gray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(height: 130)
    }
    
    @Animatable
    struct Pulse {
        var scale: CGFloat = 1
        var opacity: CGFloat = 1
    }

    /// Config
    struct Config {
        var tint: Color = .blue
        var pulseTint: Color = .blue.opacity(0.65)
        var pulseWidth: CGFloat = 1.3
        var pulseScale: CGFloat = 12
        var iconSize: CGFloat = 100
        var iconScale: CGFloat = 1.25
        /// Update Phase After Successfully Completing Current Time in n Times
        var phaseUpdateAfter: Int  = 1
        var buttonTitle: String = "Continue"
        var showButtons: Bool = true
    }
    /// Phase
    struct Phase: Identifiable {
        private(set) var id: String = UUID().uuidString
        var symbol: String
        var title: String
        var description: String
    }
}

struct LoopOnBoardingPreview: View {
    @State private var showButton: Bool = true
    let phaseData: [LoopOnBoarding.Phase] = [
        .init(symbol: "network.badge.shield.half.filled", title: "Secure Network Protection", description: "Protects your connection with advanced\nsecurity and encrypted network traffic."),
        .init(symbol: "faceid", title: "Fast Face ID Access", description: "Unlock and authenticate instantly\nusing secure Face ID verification"),
        .init(symbol: "key.icloud.fill", title: "iCloud Key Security", description: "Safely store and sync passwords\nacross all your Apple devices.")
    ]
    var body: some View {
        LoopOnBoarding(config: .init(showButtons: showButton), phases: phaseData) {
            print("Continue")
        } .onTapGesture {
            showButton.toggle()
        }
    }
}
#Preview {
    LoopOnBoardingPreview()
}
