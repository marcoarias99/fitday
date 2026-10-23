//
//  RoutineEditorView.swift
//  FitDay
//
//  The sheet for creating or editing a routine: name, days and exercises.
//  Nothing is saved until you tap Save.
//

import SwiftUI
import SwiftData

struct RoutineEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// The routine being edited, or `nil` for a new one.
    let routine: Routine?

    // Draft copy of the routine; written back only in `save()`.
    @State private var name: String
    @State private var selectedDays: Set<Int>
    @State private var exercises: [DraftExercise]
    @State private var showingExercisePicker = false

    /// An editable exercise that isn't saved yet.
    struct DraftExercise: Identifiable {
        let id = UUID()
        var name: String
        var sets: Int
        var reps: Int
    }

    init(routine: Routine?) {
        self.routine = routine
        _name = State(initialValue: routine?.name ?? "")
        _selectedDays = State(initialValue: Set(routine?.weekdays ?? []))
        _exercises = State(initialValue: routine?.sortedExercises.map {
            DraftExercise(name: $0.name, sets: $0.sets, reps: $0.reps)
        } ?? [])
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Push Day, Leg Day", text: $name)
                }

                Section {
                    WeekdayPicker(selection: $selectedDays)
                } header: {
                    Text("Days")
                } footer: {
                    Text("This routine will show up on the Today screen on the days you select.")
                }

                Section("Exercises") {
                    ForEach($exercises) { $exercise in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.name)
                                .font(.headline)
                            Stepper("Sets: \(exercise.sets)", value: $exercise.sets, in: 1...12)
                            Stepper("Reps: \(exercise.reps)", value: $exercise.reps, in: 1...50)
                        }
                        .padding(.vertical, 2)
                    }
                    // Swipe left to remove; long-press and drag to reorder.
                    .onDelete { exercises.remove(atOffsets: $0) }
                    .onMove { exercises.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle(routine == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedName.isEmpty || exercises.isEmpty)
                }
            }
            // New exercises start at 3 sets of 10 reps.
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exerciseName in
                    exercises.append(DraftExercise(name: exerciseName, sets: 3, reps: 10))
                }
            }
        }
    }

    /// Saves the draft to the database and closes the sheet.
    private func save() {
        let target = routine ?? Routine(name: trimmedName)
        target.name = trimmedName
        target.weekdays = selectedDays.sorted()
        if routine == nil {
            context.insert(target)
        }
        // Replace the old exercises with the draft, remembering their order.
        for old in target.exercises {
            context.delete(old)
        }
        target.exercises = exercises.enumerated().map { index, draft in
            RoutineExercise(name: draft.name, sets: draft.sets, reps: draft.reps, order: index)
        }
        dismiss()
    }
}

/// Seven round day buttons (S M T W T F S). Tap to turn a day on or off.
struct WeekdayPicker: View {
    /// Selected weekdays, 1 = Sunday ... 7 = Saturday.
    @Binding var selection: Set<Int>
    private let calendar = Calendar.current

    /// Weekdays in display order, starting on the region's first day of the week.
    private var orderedWeekdays: [Int] {
        let first = calendar.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(orderedWeekdays, id: \.self) { day in
                let isSelected = selection.contains(day)
                Button {
                    if isSelected {
                        selection.remove(day)
                    } else {
                        selection.insert(day)
                    }
                } label: {
                    Text(calendar.veryShortWeekdaySymbols[day - 1])
                        .font(.body.weight(.semibold))
                        .frame(width: 38, height: 38)
                        .background(
                            isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(Color(.systemGray5)),
                            in: Circle()
                        )
                        .foregroundStyle(isSelected ? .white : .primary)
                        // Spread the seven circles evenly across the row.
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: isSelected)
                // VoiceOver says "Thursday" instead of "T".
                .accessibilityLabel(calendar.weekdaySymbols[day - 1])
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RoutineEditorView(routine: nil)
        .modelContainer(for: Routine.self, inMemory: true)
}
