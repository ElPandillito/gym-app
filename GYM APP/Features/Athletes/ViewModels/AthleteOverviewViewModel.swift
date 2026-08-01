//
//  AthleteOverviewViewModel.swift
//  GYM APP
//

import SwiftUI

@Observable
@MainActor
final class AthleteOverviewViewModel {

    // MARK: - Nested data types

    struct Header {
        let ageText: String?        // "25 años"
        let gender: String
        let heightText: String?     // "178 cm"
        let memberSince: Date
        let checkInCount: Int
        let totalPhotos: Int
    }

    struct CurrentMetrics {
        let weight: Double?
        let bodyFatPct: Double?     // bio-impedance preferred; skinfold fallback
        let muscleMass: Double?
        let bmi: Double?
    }

    struct ProgressSummary {
        let earlierCheckIn: CheckIn
        let laterCheckIn: CheckIn
        let daysBetween: Int
        let weightDiff: MetricDiff
        let bodyFatDiff: MetricDiff
        let waistDiff: MetricDiff
    }

    struct ActivityInfo {
        let lastCheckInDate: Date?
        let daysSinceLastCheckIn: Int?
        let totalPhotos: Int
        let lastSkinfoldDate: Date?
    }

    // MARK: - Published state

    private(set) var header: Header?
    private(set) var currentMetrics: CurrentMetrics?
    private(set) var progressSummary: ProgressSummary?
    private(set) var activityInfo: ActivityInfo?
    private(set) var alerts: [AthleteAlert] = []

    /// Exposed for Quick Actions and direct comparison navigation.
    private(set) var latestCheckIn: CheckIn?
    private(set) var previousCheckIn: CheckIn?

    // MARK: - Build (called once per athlete change)

    func build(from athlete: Athlete) {
        let now     = Date()
        let sorted  = athlete.checkIns.sorted { $0.date < $1.date }
        let latest  = sorted.last
        let previous = sorted.dropLast().last

        latestCheckIn  = latest
        previousCheckIn = previous

        let daysSince: Int? = latest.map {
            Calendar.current.dateComponents([.day], from: $0.date, to: now).day ?? 0
        }

        header = Header(
            ageText:      athlete.birthDate.map { ageText(from: $0, to: now) },
            gender:       athlete.gender.displayName,
            heightText:   athlete.height.map { String(format: "%.0f cm", $0) },
            memberSince:  athlete.createdAt,
            checkInCount: sorted.count,
            totalPhotos:  sorted.reduce(0) { $0 + $1.photos.count }
        )

        if let latest = latest {
            let snap = CheckInSnapshot(from: latest)
            let bioFat      = snap.bodyMetrics?.bodyFatPercentage
            let skinfoldFat = snap.skinfolds?.estimatedBodyFatPercentage
            currentMetrics = CurrentMetrics(
                weight:     snap.bodyMetrics?.bodyWeight,
                bodyFatPct: bioFat ?? skinfoldFat,
                muscleMass: snap.bodyMetrics?.muscleMass,
                bmi:        snap.bodyMetrics?.bmi
            )
            activityInfo = ActivityInfo(
                lastCheckInDate:     latest.date,
                daysSinceLastCheckIn: daysSince,
                totalPhotos:         sorted.reduce(0) { $0 + $1.photos.count },
                lastSkinfoldDate:    sorted.last(where: { $0.skinfolds != nil })?.date
            )
        } else {
            currentMetrics = nil
            activityInfo   = ActivityInfo(
                lastCheckInDate:      nil,
                daysSinceLastCheckIn: nil,
                totalPhotos:          0,
                lastSkinfoldDate:     nil
            )
        }

        if let earlier = previous, let later = latest {
            let snapA      = CheckInSnapshot(from: earlier)
            let snapB      = CheckInSnapshot(from: later)
            let comparison = CheckInComparisonEngine.compare(snapA, snapB)
            let days       = Calendar.current
                .dateComponents([.day], from: earlier.date, to: later.date).day ?? 0
            // Prefer bio-impedance body fat; fall back to skinfold estimate
            let bfDiff = comparison.bodyFat.direction != .unavailable
                ? comparison.bodyFat
                : comparison.skinfoldBodyFat
            progressSummary = ProgressSummary(
                earlierCheckIn: earlier,
                laterCheckIn:   later,
                daysBetween:    days,
                weightDiff:     comparison.weight,
                bodyFatDiff:    bfDiff,
                waistDiff:      comparison.circumferences.waist
            )
        } else {
            progressSummary = nil
        }

        // Alert evaluation — all rules in one shared evaluator
        let snapshots = sorted.map(CheckInSnapshot.init)
        alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athlete.id,
            athleteName:    athlete.name,
            sortedCheckIns: snapshots,
            preferences:    CoachPreferences.default,
            now:            now
        )
    }

    // MARK: - Helpers

    private func ageText(from birthDate: Date, to now: Date) -> String {
        let years = Calendar.current.dateComponents([.year], from: birthDate, to: now).year ?? 0
        return "\(years) años"
    }
}
