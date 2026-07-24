//
//  CheckInComparisonEngine.swift
//  GYM APP
//

import Foundation

/// Pure-function engine that compares two CheckIn snapshots.
/// No SwiftData, no SwiftUI — fully unit-testable with mock snapshots.
enum CheckInComparisonEngine {

    /// Compare snapshot A (earlier) against snapshot B (later).
    static func compare(_ a: CheckInSnapshot, _ b: CheckInSnapshot) -> CheckInComparison {
        let days = Calendar.current.dateComponents([.day], from: a.date, to: b.date).day ?? 0

        let ma = a.bodyMetrics
        let mb = b.bodyMetrics

        return CheckInComparison(
            id:           UUID(),
            checkInAID:   a.id,
            checkInBID:   b.id,
            dateA:        a.date,
            dateB:        b.date,
            daysBetween:  days,
            weight:       MetricDiff(before: ma?.bodyWeight,         after: mb?.bodyWeight),
            bmi:          MetricDiff(before: ma?.bmi,                after: mb?.bmi),
            bodyFat:      MetricDiff(before: ma?.bodyFatPercentage,  after: mb?.bodyFatPercentage),
            muscleMass:   MetricDiff(before: ma?.muscleMass,         after: mb?.muscleMass),
            boneMass:     MetricDiff(before: ma?.boneMass,           after: mb?.boneMass),
            water:        MetricDiff(before: ma?.waterPercentage,    after: mb?.waterPercentage),
            visceralFat:  MetricDiff(before: ma?.visceralFatLevel,   after: mb?.visceralFatLevel),
            bmr:          MetricDiff(before: ma?.basalMetabolicRate, after: mb?.basalMetabolicRate),
            circumferences: CircumferencesDiff(a: a.circumferences, b: b.circumferences),
            skinfoldBodyFat: MetricDiff(
                before: a.skinfolds?.estimatedBodyFatPercentage,
                after:  b.skinfolds?.estimatedBodyFatPercentage
            ),
            photosA:       a.photoCount,
            photosB:       b.photoCount,
            hasCoachNoteA: a.hasCoachNote,
            hasCoachNoteB: b.hasCoachNote
        )
    }

    /// Compare a chronologically ordered array of snapshots pairwise (n-1 comparisons).
    static func compareSeries(_ snapshots: [CheckInSnapshot]) -> [CheckInComparison] {
        guard snapshots.count > 1 else { return [] }
        let sorted = snapshots.sorted { $0.date < $1.date }
        return zip(sorted, sorted.dropFirst()).map { compare($0, $1) }
    }
}
