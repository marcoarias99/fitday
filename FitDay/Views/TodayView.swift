//
//  TodayView.swift
//  FitDay
//
//  The Today tab: today's date, activity from Apple Health,
//  and the routines scheduled for today.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(HealthStore.self) private var health
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    /// Setting this opens the workout for that routine.
    @State private var activeRoutine: Routine?

    /// Set to `false` to hide the Health card. While hidden, the app never asks for Health access.
    private let showsHealthActivity = true

    /// 1 = Sunday ... 7 = Saturday
    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: .now)
    }

    private var todaysRoutines: [Routine] {
        routines.filter { $0.isScheduled(on: todayWeekday) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                if showsHealthActivity {
                    healthCard
                        .task { await health.refresh() }
                }
                workoutSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(item: $activeRoutine) { routine in
            WorkoutSessionView(routine: routine)
        }
    }

    /// "Today is Thursday" and the date.
    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Today is")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(Date.now, format: .dateTime.weekday(.wide))
                .font(.system(size: 42, weight: .bold, design: .rounded))
            Text(Date.now, format: .dateTime.month(.wide).day().year())
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    /// Steps, distance and calories from Apple Health. Hidden for now.
    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Activity", systemImage: "heart.fill")
                .font(.headline)
                .foregroundStyle(.pink)
            HStack(spacing: 12) {
                StatTile(
                    title: "Steps",
                    value: health.steps.map { $0.formatted(.number.precision(.fractionLength(0))) } ?? "—",
                    systemImage: "figure.walk",
                    color: .green
                )
                StatTile(
                    title: "Distance",
                    value: health.distanceMeters.map {
                        Measurement(value: $0, unit: UnitLength.meters)
                            .formatted(.measurement(width: .abbreviated, usage: .road))
                    } ?? "—",
                    systemImage: "location.fill",
                    color: .blue
                )
                StatTile(
                    title: "Energy",
                    value: health.activeEnergyKilocalories.map {
                        "\($0.formatted(.number.precision(.fractionLength(0)))) kcal"
                    } ?? "—",
                    systemImage: "flame.fill",
                    color: .orange
                )
            }
            if health.isUnavailable {
                Text("Health data isn't available on this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    /// A card per routine scheduled today, or "Rest Day" if none.
    private var workoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Workout", systemImage: "dumbbell.fill")
                .font(.headline)
                .foregroundStyle(.tint)

            if todaysRoutines.isEmpty {
                ContentUnavailableView(
                    "Rest Day",
                    systemImage: "moon.zzz.fill",
                    description: Text("No routine is scheduled for today. Create one in the Routines tab and assign it to a day.")
                )
                .padding(.vertical)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(todaysRoutines) { routine in
                    RoutineCard(routine: routine) {
                        activeRoutine = routine
                    }
                }
            }
        }
    }
}

/// One tile in the Health card: icon, number, label.
private struct StatTile: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// A routine's name, Start button, and exercises as "3 × 10  Bench Press".
private struct RoutineCard: View {
    let routine: Routine
    var onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(routine.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                Button(action: onStart) {
                    Label("Start", systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(routine.exercises.isEmpty)
            }
            Divider()
            ForEach(routine.sortedExercises) { exercise in
                HStack {
                    Text("\(exercise.sets) × \(exercise.reps)")
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.tint)
                        .frame(width: 64, alignment: .leading)
                    Text(exercise.name)
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TodayView()
        .environment(HealthStore())
        .modelContainer(for: Routine.self, inMemory: true)
}
