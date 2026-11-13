import SwiftUI
import Combine
import Foundation

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var score = 0
    @State private var timeRemaining = 10
    @State private var isPlaying = false
    @State private var roundDeadline: Date?
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()

    private var statusText: String {
        if timeRemaining == 0 { return "Time's up!" }
        if isPlaying { return "Time: \(timeRemaining)s" }
        return "Tap to start · 10 seconds"
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

                    Button(action: handleTap) {
                        Text("TAP")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .frame(width: 200, height: 200)
                            .background(.blue, in: Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(timeRemaining == 0)
                    .frame(width: 220, height: 220)
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
        guard timeRemaining > 0 else { return }
        let now = Date()

        if !isPlaying {
            roundDeadline = now.addingTimeInterval(10)
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
            isPlaying = true
        }

        guard let deadline = roundDeadline else { return }
        guard now < deadline else {
            timeRemaining = 0
            isPlaying = false
            return
        }
        score += 1
    }

    private func updateTimer(_ now: Date) {
        guard isPlaying, let deadline = roundDeadline else { return }
        let secondsLeft = deadline.timeIntervalSince(now)
        timeRemaining = min(10, max(0, Int(ceil(secondsLeft))))
        if secondsLeft <= 0 { isPlaying = false }
    }
}