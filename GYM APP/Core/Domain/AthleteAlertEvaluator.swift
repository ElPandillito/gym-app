//
//  AthleteAlertEvaluator.swift
//  GYM APP
//
//  Pure evaluator — no SwiftUI, no SwiftData.
//  Accepts CheckInSnapshot value types and CoachPreferences thresholds.
//  Returns all applicable AthleteAlert items sorted by severity (highest first).
//

import Foundation

enum AthleteAlertEvaluator {

    /// Evaluates all applicable alerts for a single athlete.
    /// - Parameters:
    ///   - sortedCheckIns: Check-in snapshots sorted ascending by date.
    ///   - preferences:    Coach-configured thresholds and toggles.
    ///   - now:            Override for testability; defaults to current date.
    /// - Returns: All active alerts sorted by severity descending.
    static func evaluate(
        athleteID:      UUID,
        athleteName:    String,
        sortedCheckIns: [CheckInSnapshot],
        preferences:    CoachPreferences,
        now:            Date = Date()
    ) -> [AthleteAlert] {
        let calendar = Calendar.current
        var result: [AthleteAlert] = []

        // No check-ins — only an inactivity alert makes sense
        guard let latest = sortedCheckIns.last else {
            if preferences.showInactiveAlerts {
                result.append(AthleteAlert(
                    athleteID: athleteID, athleteName: athleteName,
                    kind: .inactive(days: 0)
                ))
            }
            return result
        }

        // Inactivity
        let daysSince = calendar.dateComponents([.day], from: latest.date, to: now).day ?? 0
        if preferences.showInactiveAlerts, daysSince >= preferences.inactivityThresholdDays {
            result.append(AthleteAlert(
                athleteID: athleteID, athleteName: athleteName,
                kind: .inactive(days: daysSince)
            ))
        }

        // Negative body fat trend (60-day window, ≥ 3 data points, > 1 pp projected rise)
        let trendCutoff = calendar.date(byAdding: .day, value: -preferences.trendWindowDays, to: now)!
        let bfPoints: [DataPoint] = sortedCheckIns
            .filter { $0.date >= trendCutoff }
            .compactMap { snap in
                (snap.bodyMetrics?.bodyFatPercentage ?? snap.skinfolds?.estimatedBodyFatPercentage)
                    .map { DataPoint(date: snap.date, value: $0) }
            }
        if bfPoints.count >= 3 {
            let trend    = Trend.compute(from: bfPoints)
            let spanDays = Double(
                calendar.dateComponents([.day], from: bfPoints.first!.date, to: bfPoints.last!.date).day ?? 1
            )
            if trend.direction == .rising, trend.slope * spanDays > 1.0 {
                result.append(AthleteAlert(
                    athleteID: athleteID, athleteName: athleteName,
                    kind: .negativeTrend
                ))
            }
        }

        // No progress photos
        if preferences.showPhotoAlerts, latest.photoCount == 0 {
            result.append(AthleteAlert(
                athleteID: athleteID, athleteName: athleteName,
                kind: .noPhotos
            ))
        }

        // Missing body weight
        if preferences.showMetricAlerts, latest.bodyMetrics?.bodyWeight == nil {
            result.append(AthleteAlert(
                athleteID: athleteID, athleteName: athleteName,
                kind: .incompleteMetrics
            ))
        }

        return result.sorted { $0.severity > $1.severity }
    }
}
