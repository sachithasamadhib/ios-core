import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    Text("Tap Frenzy")
                        .font(.largeTitle.bold())
                    Text("Score")
                        .font(.headline)
                    Text("0")
                        .font(.system(size: 80, weight: .heavy))
                        .monospacedDigit()
                    Text("Tap to start · 10 seconds")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Button {
                        // Scoring comes in the next stage.
                    } label: {
                        Text("TAP")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .frame(width: 200, height: 200)
                            .background(.blue, in: Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: 220, height: 220)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
        }
    }
}