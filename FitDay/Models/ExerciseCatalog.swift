//
//  ExerciseCatalog.swift
//  FitDay
//
//  The built-in exercise list shown in the "Add Exercise" picker.
//  To add an exercise, type its name into the right category below.
//

import Foundation

/// A group of exercises, such as "Chest".
struct ExerciseCategory: Identifiable {
    let name: String
    let exercises: [String]
    var id: String { name }
}

enum ExerciseCatalog {
    static let categories: [ExerciseCategory] = [
        ExerciseCategory(name: "Chest", exercises: [
            "Bench Press",
            "Incline Bench Press",
            "Dumbbell Press",
            "Incline Dumbbell Press",
            "Chest Fly",
            "Cable Crossover",
            "Push-Up",
            "Dips",
        ]),
        ExerciseCategory(name: "Back", exercises: [
            "Pull-Up",
            "Chin-Up",
            "Lat Pulldown",
            "Barbell Row",
            "Dumbbell Row",
            "Seated Cable Row",
            "T-Bar Row",
            "Deadlift",
            "Back Extension",
        ]),
        ExerciseCategory(name: "Shoulders", exercises: [
            "Overhead Press",
            "Dumbbell Shoulder Press",
            "Arnold Press",
            "Lateral Raise",
            "Front Raise",
            "Rear Delt Fly",
            "Face Pull",
            "Shrug",
        ]),
        ExerciseCategory(name: "Arms", exercises: [
            "Barbell Curl",
            "Dumbbell Curl",
            "Hammer Curl",
            "Preacher Curl",
            "Cable Curl",
            "Tricep Pushdown",
            "Overhead Tricep Extension",
            "Skull Crusher",
            "Close-Grip Bench Press",
        ]),
        ExerciseCategory(name: "Legs", exercises: [
            "Squat",
            "Front Squat",
            "Goblet Squat",
            "Leg Press",
            "Lunge",
            "Bulgarian Split Squat",
            "Romanian Deadlift",
            "Leg Curl",
            "Leg Extension",
            "Hip Thrust",
            "Calf Raise",
        ]),
        ExerciseCategory(name: "Core", exercises: [
            "Plank",
            "Side Plank",
            "Crunch",
            "Sit-Up",
            "Russian Twist",
            "Hanging Leg Raise",
            "Mountain Climber",
            "Ab Wheel Rollout",
            "Cable Crunch",
        ]),
        ExerciseCategory(name: "Cardio", exercises: [
            "Treadmill Run",
            "Outdoor Run",
            "Walking",
            "Cycling",
            "Rowing Machine",
            "Stair Climber",
            "Elliptical",
            "Jump Rope",
            "Burpees",
        ]),
    ]
}
