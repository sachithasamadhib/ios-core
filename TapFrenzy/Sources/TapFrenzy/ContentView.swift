import SwiftUI
import Combine
import Foundation

enum GamePhase {
    case idle, playing, over
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("highScore") private var highScore = 0
    @State private var tapsThisRound = 0
    @State private var score = 0
    @State private var timeRemaining = 10
    @State private var phase: GamePhase = .idle
    @State private var roundDeadline: Date?
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()

    private var buttonSize: CGFloat {
        max(90, 200 - CGFloat(tapsThisRound) * 4)
    }

    private var statusText: String {
        switch phase {
        case .idle: return "Tap to start · 10 seconds"
        case .playing: return "Time: \(timeRemaining)s"
        case .over: return "Time's up!"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    Text("Tap Frenzy")
                        .font(.largeTitle.bold())
                    Text("Score")
                        .font(.headline)
                    Text("\(score)")
                        .font(.system(size: 80, weight: .heavy))
                        .monospacedDigit()
                    Text(statusText)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)

                    switch phase {
                    case .idle, .playing:
                        Button(action: handleTap) {
                            Text("TAP")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                                .frame(width: buttonSize, height: buttonSize)
                                .background(.blue, in: Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .frame(width: 220, height: 220)
                    case .over:
                        VStack(spacing: 16) {
                            Text("Final score: \(score)")
                                .font(.title2.bold())
                            Text("Best: \(highScore)")
                                .font(.headline)
                            Button("Play Again", action: resetRound)
                                .buttonStyle(.borderedProminent)
                        }
                        .frame(width: 220, height: 220)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
        }
        .onReceive(timer) { now in
            updateTimer(now)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { updateTimer(Date()) }
        }
    }

    private func handleTap() {
        let now = Date()

        if phase == .idle {
            roundDeadline = now.addingTimeInterval(10)
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
            phase = .playing
        }

        guard phase == .playing, let deadline = roundDeadline else { return }
        guard now < deadline else {
            finishRound()
            return
        }
        score += 1
        tapsThisRound += 1
    }

    private func updateTimer(_ now: Date) {
        guard phase == .playing, let deadline = roundDeadline else { return }
        let secondsLeft = deadline.timeIntervalSince(now)
        timeRemaining = min(10, max(0, Int(ceil(secondsLeft))))
        if secondsLeft <= 0 { finishRound() }
    }

    private func finishRound() {
        guard phase == .playing else { return }
        timeRemaining = 0
        phase = .over
        highScore = max(highScore, score)
    }

    private func resetRound() {
        tapsThisRound = 0
        score = 0
        timeRemaining = 10
        roundDeadline = nil
        phase = .idle
    }
}