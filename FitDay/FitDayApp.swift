//
//  FitDayApp.swift
//  FitDay
//
//  Where the app starts. Sets up routine storage and the three tabs.
//

import SwiftUI
import SwiftData

@main
struct FitDayApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        // Saves routines (and their exercises) on the phone.
        .modelContainer(for: Routine.self)
    }
}

/// The tab bar: Today, Routines and Timer.
struct RootView: View {
    /// Reads Apple Health data; shared with every tab.
    @State private var health = HealthStore()

    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max.fill") {
                TodayView()
            }
            Tab("Routines", systemImage: "dumbbell.fill") {
                RoutinesView()
            }
            Tab("Timer", systemImage: "timer") {
                TimerView()
            }
        }
        .environment(health)
    }
}
