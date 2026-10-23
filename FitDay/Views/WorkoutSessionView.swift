//
//  WorkoutSessionView.swift
//  FitDay
//
//  The guided workout. Goes set by set: do the set, tap Complete Set, rest,
//  repeat. Ends with a summary. The screen stays on during the workout.
//

import SwiftUI

struct WorkoutSessionView: View {
    /// A copy of one exercise, so editing the routine can't change a workout in progress.
    struct Step: Identifiable {
        let id = UUID()
        let name: String
        let sets: Int
        let reps: Int
    }

    /// Which screen is showing.
    private enum Phase {
        case working
        case resting(until: Date)
        case finished
    }

    let routineName: String
    let steps: [Step]

    @Environment(\.dismiss) private var dismiss
    /// Rest between sets, in seconds. Remembered for next time.
    @AppStorage("restSeconds") private var restSeconds = 90

    @State private var exerciseIndex = 0
    @State private var currentSet = 1
    @State private var phase: Phase = .working
    @State private var completedSets = 0
    @State private var startedAt = Date.now
    @State private var finishedAt: Date?
    /// Changes when a rest ends on its own, to trigger the vibration.
    @State private var restEndedCount = 0
    @State private var confirmingEnd = false

    private let restOptions = [0, 30, 45, 60, 90, 120, 180]

    init(routine: Routine) {
        routineName = routine.name
        steps = routine.sortedExercises.map { Step(name: $0.name, sets: $0.sets, reps: $0.reps) }
    }

    private var totalSets: Int { steps.reduce(0) { $0 + $1.sets } }
    private var currentStep: Step? { steps.indices.contains(exerciseIndex) ? steps[exerciseIndex] : nil }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .working:
                    workingView
                case .resting(let until):
                    restingView(until: until)
                case .finished:
                    finishedView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(routineName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        // Ends the rest when its time is up. Restarts if the rest is changed with ±15s.
        .task(id: restDeadline) {
            guard let restDeadline else { return }
            try? await Task.sleep(for: .seconds(max(0, restDeadline.timeIntervalSinceNow)))
            guard !Task.isCancelled else { return }
            restEndedCount += 1
            phase = .working
        }
        .sensoryFeedback(.success, trigger: restEndedCount)
        // Keep the screen from locking during the workout.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .confirmationDialog("End this workout?", isPresented: $confirmingEnd, titleVisibility: .visible) {
            Button("End Workout", role: .destructive) { dismiss() }
        } message: {
            Text("You've completed \(completedSets) of \(totalSets) sets.")
        }
    }

    private var restDeadline: Date? {
        if case .resting(let until) = phase { return until }
        return nil
    }

    private var isFinished: Bool {
        if case .finished = phase { return true }
        return false
    }

    /// End (X) and the rest-length menu. Hidden on the summary screen.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !isFinished {
            ToolbarItem(placement: .cancellationAction) {
                Button("End", systemImage: "xmark") {
                    // Only ask for confirmation if a set was already done.
                    if completedSets == 0 { dismiss() } else { confirmingEnd = true }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                restMenu
            }
        }
    }

    private var restMenu: some View {
        Menu {
            Picker("Rest Between Sets", selection: $restSeconds) {
                ForEach(restOptions, id: \.self) { seconds in
                    Text(seconds == 0 ? "No Rest" : Self.clock(seconds)).tag(seconds)
                }
            }
        } label: {
            Label("Rest \(Self.clock(restSeconds))", systemImage: "timer")
                .labelStyle(.titleAndIcon)
        }
    }

    // MARK: - Working

    /// Exercise name, set number, target reps, and the Complete Set button.
    private var workingView: some View {
        VStack(spacing: 24) {
            progressHeader

            Spacer()

            if let step = currentStep {
                VStack(spacing: 12) {
                    Text("Exercise \(exerciseIndex + 1) of \(steps.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(step.name)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text("Set \(currentSet) of \(step.sets)")
                        .font(.headline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.tint.opacity(0.15), in: Capsule())
                        .foregroundStyle(.tint)
                }

                VStack(spacing: 0) {
                    Text("\(step.reps)")
                        .font(.system(size: 96, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("reps")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                SetDots(total: step.sets, done: currentSet - 1)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    completeSet()
                } label: {
                    Label("Complete Set", systemImage: "checkmark")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip Exercise", systemImage: "forward.end") {
                    advanceExercise()
                }
                .disabled(currentStep == nil)
            }
        }
        .padding()
    }

    /// Progress bar, "3 of 8 sets" and elapsed time.
    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: Double(completedSets), total: Double(max(totalSets, 1)))
            HStack {
                Text("\(completedSets) of \(totalSets) sets")
                Spacer()
                Text(startedAt, style: .timer)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Resting

    /// Countdown ring, ±15s, what's up next, and Skip Rest.
    private func restingView(until: Date) -> some View {
        VStack(spacing: 28) {
            progressHeader

            Spacer()

            Text("Rest")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)

            // Redraws 4 times a second to update the countdown.
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                let remaining = max(0, until.timeIntervalSince(context.date))
                let fraction = restSeconds > 0 ? remaining / Double(restSeconds) : 0
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: min(1, fraction))
                        .stroke(.tint, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.25), value: fraction)
                    Text(Self.clock(Int(remaining.rounded(.up))))
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                .frame(width: 240, height: 240)
            }

            HStack(spacing: 16) {
                Button("−15s") { adjustRest(by: -15, until: until) }
                    .buttonStyle(.bordered)
                Button("+15s") { adjustRest(by: 15, until: until) }
                    .buttonStyle(.bordered)
            }
            .controlSize(.large)
            .font(.headline.monospacedDigit())

            if let step = currentStep {
                VStack(spacing: 4) {
                    Text("Up next")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text("\(step.name) · Set \(currentSet) of \(step.sets) · \(step.reps) reps")
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            Button {
                phase = .working
            } label: {
                Label("Skip Rest", systemImage: "forward.fill")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    // MARK: - Finished

    /// "Workout Complete!" with total time, sets and exercises.
    private var finishedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 88))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: finishedAt)
            Text("Workout Complete!")
                .font(.largeTitle.bold())
            Text(routineName)
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                SummaryTile(title: "Time", value: Self.clock(Int((finishedAt ?? .now).timeIntervalSince(startedAt))))
                SummaryTile(title: "Sets", value: "\(completedSets)")
                SummaryTile(title: "Exercises", value: "\(steps.count)")
            }
            .padding(.top, 8)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    // MARK: - Flow

    /// Moves to the next set or exercise (with a rest), or finishes after the last set.
    private func completeSet() {
        guard let step = currentStep else { return }
        completedSets += 1
        if currentSet < step.sets {
            currentSet += 1
            startRest()
        } else if exerciseIndex < steps.count - 1 {
            exerciseIndex += 1
            currentSet = 1
            startRest()
        } else {
            finish()
        }
    }

    /// Jumps to the next exercise without resting.
    private func advanceExercise() {
        if exerciseIndex < steps.count - 1 {
            exerciseIndex += 1
            currentSet = 1
            phase = .working
        } else {
            finish()
        }
    }

    private func startRest() {
        phase = restSeconds > 0 ? .resting(until: .now.addingTimeInterval(Double(restSeconds))) : .working
    }

    /// Makes the current rest longer or shorter. Ends it if no time is left.
    private func adjustRest(by seconds: Int, until: Date) {
        let newEnd = until.addingTimeInterval(Double(seconds))
        phase = newEnd > .now ? .resting(until: newEnd) : .working
    }

    private func finish() {
        finishedAt = .now
        phase = .finished
    }

    /// Seconds as "M:SS", for example 90 → "1:30".
    private static func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

/// One dot per set; finished sets are filled in.
private struct SetDots: View {
    let total: Int
    let done: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < done ? AnyShapeStyle(.tint) : AnyShapeStyle(Color(.systemGray4)))
                    .frame(width: 12, height: 12)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(done) of \(total) sets done")
    }
}

/// A number with a label, used on the summary screen.
private struct SummaryTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    WorkoutSessionView(routine: Routine(name: "Push Day", weekdays: [3], exercises: [
        RoutineExercise(name: "Bench Press", sets: 3, reps: 8, order: 0),
        RoutineExercise(name: "Lateral Raise", sets: 3, reps: 12, order: 1),
    ]))
    .modelContainer(for: Routine.self, inMemory: true)
}
