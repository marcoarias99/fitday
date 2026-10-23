//
//  ExercisePickerView.swift
//  FitDay
//
//  The "Add Exercise" sheet. Tap an exercise to add it, or search for a name
//  that isn't listed to add it as a custom exercise. A short banner confirms each add.
//

import SwiftUI

struct ExercisePickerView: View {
    /// Called with each exercise name the user adds.
    var onAdd: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    /// How many times each exercise was added; shows the checkmark and "×2".
    @State private var addedCounts: [String: Int] = [:]
    /// Name shown in the "added" banner. `nil` hides it.
    @State private var lastAdded: String?
    /// Changes on every add, to trigger the vibration and restart the banner timer.
    @State private var addEvents = 0

    /// Exercises matching the search, grouped by category.
    private var filteredCategories: [ExerciseCategory] {
        guard !searchText.isEmpty else { return ExerciseCatalog.categories }
        return ExerciseCatalog.categories.compactMap { category in
            let matches = category.exercises.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }
            return matches.isEmpty ? nil : ExerciseCategory(name: category.name, exercises: matches)
        }
    }

    /// The search text, if it isn't already a built-in exercise.
    private var customName: String? {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let exists = ExerciseCatalog.categories.contains { category in
            category.exercises.contains { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        }
        return exists ? nil : trimmed
    }

    var body: some View {
        NavigationStack {
            List {
                if let customName {
                    Section("Custom") {
                        Button {
                            add(customName)
                            // Clearing the search hides the button, so it can't be added twice by accident.
                            searchText = ""
                        } label: {
                            Label("Add “\(customName)”", systemImage: "plus.circle.fill")
                        }
                    }
                }
                ForEach(filteredCategories) { category in
                    Section(category.name) {
                        ForEach(category.exercises, id: \.self) { exercise in
                            Button {
                                add(exercise)
                            } label: {
                                HStack {
                                    Text(exercise)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if let count = addedCounts[exercise] {
                                        if count > 1 {
                                            Text("×\(count)")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if filteredCategories.isEmpty && customName == nil {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .overlay(alignment: .top) {
                if let lastAdded {
                    AddedToast(name: lastAdded)
                        .padding(.top, 8)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            // Hide the banner 2 seconds after the latest add.
            .task(id: addEvents) {
                guard lastAdded != nil else { return }
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                withAnimation { lastAdded = nil }
            }
            .sensoryFeedback(.success, trigger: addEvents)
        }
    }

    /// Adds the exercise to the routine and shows the confirmation.
    private func add(_ name: String) {
        onAdd(name)
        addedCounts[name, default: 0] += 1
        withAnimation(.snappy) { lastAdded = name }
        addEvents += 1
        AccessibilityNotification.Announcement("\(name) added to routine").post()
    }
}

/// The "✓ Bench Press added to routine" banner.
private struct AddedToast: View {
    let name: String

    var body: some View {
        Label {
            Text("\(name) added to routine")
                .lineLimit(1)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }
}

#Preview {
    ExercisePickerView { _ in }
}
