import SwiftUI
import Combine
import Foundation

enum GamePhase {
    case idle, playing, over
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("highScore") private var highScore = 0
    @State private var lastTapAt: Date?
    @State private var multiplier = 1
    @State private var tapsThisRound = 0
    @State private var score = 0
    @State private var timeRemaining = 10
    @State private var roundProgress = 1.0
    @State private var phase: GamePhase = .idle
    @State private var roundDeadline: Date?
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common)
        .autoconnect()

    private let background = Color(red: 13 / 255, green: 15 / 255, blue: 17 / 255)
    private let green = Color(red: 87 / 255, green: 185 / 255, blue: 122 / 255)
    private let muted = Color(red: 111 / 255, green: 119 / 255, blue: 139 / 255)
    private let amber = Color(red: 232 / 255, green: 171 / 255, blue: 63 / 255)

    private var buttonSize: CGFloat {
        max(90, 200 - CGFloat(tapsThisRound) * 4)
    }

    private var statusText: String {
        switch phase {
        case .idle: return "tap to start"
        case .playing: return "\(timeRemaining)s left"
        case .over: return "0s left"
        }
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            GeometryReader { geometry in
                ZStack {
                    ScrollView {
                        VStack(spacing: 0) {
                            Text("Tap Frenzy")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .tracking(-0.5)
                                .foregroundStyle(Color(white: 0.9))
                                .accessibilityAddTraits(.isHeader)

                            VStack(spacing: 14) {
                                scoreLabel("SCORE")
                                scoreNumber
                                    .overlay(alignment: .trailing) {
                                        if phase == .playing && multiplier > 1 {
                                            Text("×\(multiplier)")
                                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                                .foregroundStyle(amber)
                                                .offset(x: 36)
                                        }
                                    }
                            }
                            .padding(.top, 32)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Score")
                            .accessibilityValue("\(score)")

                            countdownBar
                                .padding(.top, 24)

                            Text(statusText)
                                .font(.system(.subheadline, design: .monospaced))
                                .tracking(0.6)
                                .foregroundStyle(muted)
                                .padding(.top, 20)

                            Spacer(minLength: 64)

                            tapButton
                                .opacity(phase == .over ? 0 : 1)

                            Spacer(minLength: 48)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                        .frame(maxWidth: 460)
                        .frame(minHeight: geometry.size.height)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollIndicators(.hidden)
                    .allowsHitTesting(phase != .over)
                    .accessibilityHidden(phase == .over)

                    if phase == .over {
                        background.opacity(0.94)
                            .ignoresSafeArea()
                        resultsView(height: geometry.size.height)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(timer) { now in
            updateTimer(now)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { updateTimer(Date()) }
        }
    }

    private func scoreLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption2, design: .monospaced))
            .tracking(2)
            .foregroundStyle(muted)
    }

    private var scoreNumber: some View {
        Text("\(score)")
            .font(.system(size: 76, weight: .black, design: .rounded))
            .fontWidth(.expanded)
            .monospacedDigit()
            .foregroundStyle(green)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }

    private var countdownBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.05))
                Capsule()
                    .fill(timeRemaining <= 3 ? Color(red: 0.85, green: 0.36, blue: 0.39) : green)
                    .frame(width: geometry.size.width * roundProgress)
            }
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Time remaining")
        .accessibilityValue("\(timeRemaining) seconds")
    }

    private var tapButton: some View {
        Button(action: handleTap) {
            Text("TAP")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .fontWidth(.expanded)
                .tracking(1)
                .foregroundStyle(background)
                .frame(width: buttonSize, height: buttonSize)
                .background(green, in: Circle())
                .contentShape(Circle())
                .shadow(color: green.opacity(0.15), radius: 24)
        }
        .buttonStyle(.plain)
        .frame(width: 220, height: 220)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: tapsThisRound)
        .accessibilityLabel(phase == .idle ? "Start game and tap" : "Tap")
    }

    private func resultsView(height: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Time's up")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color(white: 0.9))
                    .accessibilityAddTraits(.isHeader)

                scoreLabel("YOUR SCORE")
                    .padding(.top, 22)

                scoreNumber
                    .padding(.top, 18)
                    .accessibilityLabel("Final score: \(score)")

                HStack(spacing: 8) {
                    Text("Best:")
                        .foregroundStyle(muted)
                    Text("\(highScore)")
                        .fontWeight(.semibold)
                        .foregroundStyle(amber)
                }
                .font(.system(.subheadline, design: .monospaced))
                .padding(.top, 12)
                .accessibilityElement(children: .combine)

                Button(action: resetRound) {
                    Text("Play Again")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(background)
                        .padding(.horizontal, 30)
                        .frame(minHeight: 52)
                        .background(green, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 40)
            }
            .padding(.horizontal, 30)
            .padding(.top, 24)
            .padding(.bottom, max(24, height * 0.16))
            .frame(maxWidth: .infinity)
            .frame(minHeight: height)
        }
        .scrollIndicators(.hidden)
        .accessibilityAddTraits(.isModal)
    }

    private func handleTap() {
        let now = Date()

        if phase == .idle {
            roundDeadline = now.addingTimeInterval(10)
            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                .autoconnect()
            phase = .playing
        }

        guard phase == .playing, let deadline = roundDeadline else { return }
        guard now < deadline else {
            finishRound()
            return
        }
        if let previous = lastTapAt,
           now.timeIntervalSince(previous) <= 0.3 {
            multiplier = min(multiplier + 1, 3)
        } else {
            multiplier = 1
        }
        lastTapAt = now
        score += multiplier
        tapsThisRound += 1
    }

    private func updateTimer(_ now: Date) {
        guard phase == .playing, let deadline = roundDeadline else { return }
        let secondsLeft = deadline.timeIntervalSince(now)
        roundProgress = min(1, max(0, secondsLeft / 10))
        timeRemaining = min(10, max(0, Int(ceil(secondsLeft))))
        if secondsLeft <= 0 { finishRound() }
    }

    private func finishRound() {
        guard phase == .playing else { return }
        timeRemaining = 0
        roundProgress = 0
        phase = .over
        highScore = max(highScore, score)
    }

    private func resetRound() {
        lastTapAt = nil
        multiplier = 1
        tapsThisRound = 0
        score = 0
        timeRemaining = 10
        roundProgress = 1
        roundDeadline = nil
        phase = .idle
    }
}
