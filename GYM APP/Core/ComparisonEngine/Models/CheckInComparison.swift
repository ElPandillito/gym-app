//
//  CheckInComparison.swift
//  GYM APP
//

import Foundation

/// Complete diff model between two CheckIns. Pure value type, no SwiftData or UI dependencies.
struct CheckInComparison: Equatable {
    let id: UUID
    let checkInAID: UUID
    let checkInBID: UUID
    let dateA: Date
    let dateB: Date
    let daysBetween: Int

    // Body composition diffs
    let weight: MetricDiff
    let bmi: MetricDiff
    let bodyFat: MetricDiff
    let muscleMass: MetricDiff
    let boneMass: MetricDiff
    let water: MetricDiff
    let visceralFat: MetricDiff
    let bmr: MetricDiff

    // Section diffs
    let circumferences: CircumferencesDiff
    let skinfoldBodyFat: MetricDiff     // estimatedBodyFatPercentage

    // Presence flags (UI decides what to show)
    let photosA: Int
    let photosB: Int
    let hasCoachNoteA: Bool
    let hasCoachNoteB: Bool
}

// MARK: - BodyMetricsDiff helpers

extension CheckInComparison {
    var weightedProgressScore: Double? {
        // Simple heuristic: averages % changes of key metrics (ignoring unavailable ones)
        let diffs: [MetricDiff] = [bodyFat, muscleMass, weight]
        let available = diffs.compactMap { $0.percentageChange }
        guard !available.isEmpty else { return nil }
        return available.reduce(0, +) / Double(available.count)
    }
}
