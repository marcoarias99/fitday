//
//  Models.swift
//  FitDay
//
//  The data saved on the phone: routines and their exercises.
//

import Foundation
import SwiftData

/// A workout plan, like "Push Day", scheduled on certain weekdays.
@Model
final class Routine {
    var name: String
    /// Calendar weekday numbers: 1 = Sunday ... 7 = Saturday
    var weekdays: [Int]
    var createdAt: Date
    /// Deleting a routine also deletes its exercises.
    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    var exercises: [RoutineExercise]

    init(name: String, weekdays: [Int] = [], exercises: [RoutineExercise] = []) {
        self.name = name
        self.weekdays = weekdays
        self.createdAt = .now
        self.exercises = exercises
    }

    /// Exercises in the order the user arranged them.
    var sortedExercises: [RoutineExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    func isScheduled(on weekday: Int) -> Bool {
        weekdays.contains(weekday)
    }

    /// Readable list of days, such as "Mon · Wed · Fri" or "Every day".
    var weekdaySummary: String {
        guard !weekdays.isEmpty else { return "No days set" }
        if weekdays.count == 7 { return "Every day" }
        let calendar = Calendar.current
        let first = calendar.firstWeekday
        // Start the week on the region's first day (Sunday in the US, Monday elsewhere).
        let ordered = (0..<7).map { (first - 1 + $0) % 7 + 1 }.filter { weekdays.contains($0) }
        return ordered.map { calendar.shortWeekdaySymbols[$0 - 1] }.joined(separator: " · ")
    }
}

/// One exercise in a routine, like "Bench Press, 3 × 10".
@Model
final class RoutineExercise {
    var name: String
    var sets: Int
    var reps: Int
    /// Position in the routine (0 = first). The database doesn't keep list order on its own.
    var order: Int
    var routine: Routine?

    init(name: String, sets: Int = 3, reps: Int = 10, order: Int = 0) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.order = order
    }
}
