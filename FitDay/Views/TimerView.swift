//
//  TimerView.swift
//  FitDay
//
//  The Timer tab: a standalone rest timer with presets, pause and +15s.
//

import SwiftUI

struct TimerView: View {
    /// Full length of the countdown, in seconds.
    @State private var totalSeconds = 60
    @State private var remaining: Double = 60
    /// When the countdown ends. `nil` means paused or stopped.
    /// Keeping an end time (instead of counting down) stays accurate in the background.
    @State private var endDate: Date?
    /// Changes when a countdown finishes, to trigger the vibration.
    @State private var finishCount = 0

    private let presets: [(label: String, seconds: Int)] = [
        ("0:30", 30), ("1:00", 60), ("1:30", 90),
        ("2:00", 120), ("3:00", 180), ("5:00", 300),
    ]
    /// Refreshes the display every 0.1 seconds.
    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var isRunning: Bool { endDate != nil }
    /// How full the ring is: 1 = full time left, 0 = done.
    private var progress: Double {
        totalSeconds > 0 ? remaining / Double(totalSeconds) : 0
    }

    /// Time left as "M:SS".
    private var timeString: String {
        let seconds = max(0, Int(remaining.rounded(.up)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Countdown ring with the time in the middle.
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(.tint, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)
                    VStack(spacing: 4) {
                        Text(timeString)
                            .font(.system(size: 56, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                        Text(isRunning ? "Resting…" : "Rest Timer")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 260, height: 260)

                HStack(spacing: 16) {
                    Button {
                        reset()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        isRunning ? pause() : start()
                    } label: {
                        Label(isRunning ? "Pause" : "Start",
                              systemImage: isRunning ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(remaining <= 0 && !isRunning)

                    Button {
                        addSeconds(15)
                    } label: {
                        Label("+15s", systemImage: "goforward.15")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets")
                        .font(.headline)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                        ForEach(presets, id: \.seconds) { preset in
                            Button(preset.label) {
                                setDuration(preset.seconds)
                            }
                            .font(.headline.monospacedDigit())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                totalSeconds == preset.seconds
                                    ? AnyShapeStyle(.tint.opacity(0.18))
                                    : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                                in: Capsule()
                            )
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Timer")
            .background(Color(.systemGroupedBackground))
            // Update the time left, and stop when it reaches zero.
            .onReceive(tick) { _ in
                guard let endDate else { return }
                let left = endDate.timeIntervalSinceNow
                if left <= 0 {
                    remaining = 0
                    self.endDate = nil
                    finishCount += 1
                } else {
                    remaining = left
                }
            }
            .sensoryFeedback(.success, trigger: finishCount)
        }
    }

    /// Starts or resumes. Starts over if the last countdown already finished.
    private func start() {
        if remaining <= 0 { remaining = Double(totalSeconds) }
        endDate = .now.addingTimeInterval(remaining)
    }

    private func pause() {
        if let endDate {
            remaining = max(0, endDate.timeIntervalSinceNow)
        }
        endDate = nil
    }

    private func reset() {
        endDate = nil
        remaining = Double(totalSeconds)
    }

    /// Picks a preset length and stops the timer.
    private func setDuration(_ seconds: Int) {
        totalSeconds = seconds
        endDate = nil
        remaining = Double(seconds)
    }

    /// Adds time, whether running or paused.
    private func addSeconds(_ seconds: Int) {
        remaining += Double(seconds)
        totalSeconds = max(totalSeconds, Int(remaining.rounded(.up)))
        if let endDate {
            self.endDate = endDate.addingTimeInterval(Double(seconds))
        }
    }
}

#Preview {
    TimerView()
}
