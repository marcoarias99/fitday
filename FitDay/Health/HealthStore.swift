//  Reads today's steps, distance and calories from Apple Health (read-only).
//  Shown in activity card.
//

import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class HealthStore {
    // Today's totals. `nil` until loaded.
    var steps: Double?
    var distanceMeters: Double?
    var activeEnergyKilocalories: Double?
    // True when Health isn't available on this device or permission failed.
    var isUnavailable = false

    private let store = HKHealthStore()
    private var hasRequestedAuthorization = false

    /// Asks for permission the first time, then loads today's totals.
    func refresh() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            isUnavailable = true
            return
        }

        let stepType = HKQuantityType(.stepCount)
        let distanceType = HKQuantityType(.distanceWalkingRunning)
        let energyType = HKQuantityType(.activeEnergyBurned)

        if !hasRequestedAuthorization {
            do {
                // `toShare: []` means read-only; the app never writes to Health.
                try await store.requestAuthorization(toShare: [], read: [stepType, distanceType, energyType])
                hasRequestedAuthorization = true
            } catch {
                isUnavailable = true
                return
            }
        }

        steps = await todaySum(of: stepType, unit: .count())
        distanceMeters = await todaySum(of: distanceType, unit: .meter())
        activeEnergyKilocalories = await todaySum(of: energyType, unit: .kilocalorie())
    }

    // Adds up everything recorded since midnight. Returns 0 if there's no data.
    private func todaySum(of type: HKQuantityType, unit: HKUnit) async -> Double? {
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }
}
