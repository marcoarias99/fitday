//
//  RoutinesView.swift
//  FitDay
//
//  The Routines tab. Tap + to add, tap a routine to edit,
//  swipe right to start a workout, swipe left to delete.
//

import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    // Setting one of these opens the matching screen.
    @State private var editingRoutine: Routine?
    @State private var showingNewRoutine = false
    @State private var activeRoutine: Routine?

    var body: some View {
        NavigationStack {
            List {
                ForEach(routines) { routine in
                    Button {
                        editingRoutine = routine
                    } label: {
                        RoutineRow(routine: routine)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .leading) {
                        Button("Start Workout", systemImage: "play.fill") {
                            activeRoutine = routine
                        }
                        .tint(.green)
                    }
                }
                .onDelete(perform: deleteRoutines)
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Routine", systemImage: "plus") {
                        showingNewRoutine = true
                    }
                }
            }
            .overlay {
                if routines.isEmpty {
                    ContentUnavailableView(
                        "No Routines Yet",
                        systemImage: "dumbbell",
                        description: Text("Tap + to create your first routine. Pick exercises, set your sets and reps, and choose the days you train.")
                    )
                }
            }
            .sheet(isPresented: $showingNewRoutine) {
                RoutineEditorView(routine: nil)
            }
            .sheet(item: $editingRoutine) { routine in
                RoutineEditorView(routine: routine)
            }
            .fullScreenCover(item: $activeRoutine) { routine in
                WorkoutSessionView(routine: routine)
            }
        }
    }

    private func deleteRoutines(at offsets: IndexSet) {
        for index in offsets {
            context.delete(routines[index])
        }
    }
}

/// Routine name, its days, and how many exercises it has.
private struct RoutineRow: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(routine.name)
                .font(.headline)
            Text(routine.weekdaySummary)
                .font(.subheadline)
                .foregroundStyle(.tint)
            // `inflect: true` writes "1 exercise" or "3 exercises" correctly.
            Text("^[\(routine.exercises.count) exercise](inflect: true)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview {
    RoutinesView()
        .modelContainer(for: Routine.self, inMemory: true)
}
