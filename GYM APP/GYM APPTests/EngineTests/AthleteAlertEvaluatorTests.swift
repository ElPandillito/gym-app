//
//  AthleteAlertEvaluatorTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("AthleteAlertEvaluatorTests")
struct AthleteAlertEvaluatorTests {

    // MARK: - Helpers

    private let athleteID   = UUID()
    private let athleteName = "Test Athlete"
    private let prefs       = CoachPreferences.default

    /// Fixed "now" for deterministic tests.
    private var now: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 1))!
    }

    private func date(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!
    }

    private func snapshot(
        daysAgo: Int,
        weight: Double? = 80.0,
        bodyFat: Double? = nil,
        photoCount: Int = 1
    ) -> CheckInSnapshot {
        let bm: BodyMetricsSnapshot? = weight.map {
            BodyMetricsSnapshot(bodyWeight: $0, bodyFatPercentage: bodyFat)
        }
        return CheckInSnapshot(
            id:           UUID(),
            date:         date(daysAgo: daysAgo),
            athleteID:    athleteID,
            bodyMetrics:  bm,
            circumferences: nil,
            skinfolds:    nil,
            photoCount:   photoCount,
            hasCoachNote: false,
            hasAthleteNote: false
        )
    }

    // MARK: - Inactivity

    @Test("no check-ins produces inactivity alert")
    func noCheckInsProducesInactivityAlert() {
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [],
            preferences:    prefs,
            now:            now
        )
        #expect(alerts.count == 1)
        if case .inactive = alerts.first?.kind { } else {
            Issue.record("Expected .inactive alert, got \(String(describing: alerts.first?.kind))")
        }
    }

    @Test("check-in within threshold produces no inactivity alert")
    func recentCheckInNoInactivity() {
        let snap = snapshot(daysAgo: 5)
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap],
            preferences:    prefs,
            now:            now
        )
        let hasInactive = alerts.contains { if case .inactive = $0.kind { return true }; return false }
        #expect(!hasInactive)
    }

    @Test("check-in beyond threshold produces inactivity alert")
    func staleCheckInProducesInactivity() {
        let snap = snapshot(daysAgo: prefs.inactivityThresholdDays + 1)
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap],
            preferences:    prefs,
            now:            now
        )
        let hasInactive = alerts.contains { if case .inactive = $0.kind { return true }; return false }
        #expect(hasInactive)
    }

    @Test("inactivity alert carries correct day count")
    func inactivityAlertDayCount() {
        let daysAgo = prefs.inactivityThresholdDays + 3
        let snap = snapshot(daysAgo: daysAgo)
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap],
            preferences:    prefs,
            now:            now
        )
        if case .inactive(let d) = alerts.first?.kind {
            #expect(d == daysAgo)
        } else {
            Issue.record("Expected .inactive alert with day count")
        }
    }

    // MARK: - Photos

    @Test("latest check-in with zero photos produces noPhotos alert")
    func noPhotosAlert() {
        let snap = snapshot(daysAgo: 3, photoCount: 0)
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap],
            preferences:    prefs,
            now:            now
        )
        let hasNoPhotos = alerts.contains { if case .noPhotos = $0.kind { return true }; return false }
        #expect(hasNoPhotos)
    }

    @Test("latest check-in with photos produces no noPhotos alert")
    func photosPresent_noAlert() {
        let snap = snapshot(daysAgo: 3, photoCount: 2)
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap],
            preferences:    prefs,
            now:            now
        )
        let hasNoPhotos = alerts.contains { if case .noPhotos = $0.kind { return true }; return false }
        #expect(!hasNoPhotos)
    }

    // MARK: - Incomplete metrics

    @Test("latest check-in missing body weight produces incompleteMetrics alert")
    func missingWeightAlert() {
        let snap = CheckInSnapshot(
            id:           UUID(),
            date:         date(daysAgo: 3),
            athleteID:    athleteID,
            bodyMetrics:  nil,
            circumferences: nil,
            skinfolds:    nil,
            photoCount:   1,
            hasCoachNote: false,
            hasAthleteNote: false
        )
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap],
            preferences:    prefs,
            now:            now
        )
        let hasMissing = alerts.contains {
            if case .incompleteMetrics = $0.kind { return true }; return false
        }
        #expect(hasMissing)
    }

    @Test("latest check-in with body weight produces no incompleteMetrics alert")
    func weightPresent_noIncompleteMetrics() {
        let snap = snapshot(daysAgo: 3, weight: 75.0)
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap],
            preferences:    prefs,
            now:            now
        )
        let hasMissing = alerts.contains {
            if case .incompleteMetrics = $0.kind { return true }; return false
        }
        #expect(!hasMissing)
    }

    // MARK: - Severity ordering

    @Test("alerts are sorted severity descending — inactivity before noPhotos")
    func alertsSortedBySeverity() {
        let staleSnap = CheckInSnapshot(
            id:           UUID(),
            date:         date(daysAgo: prefs.inactivityThresholdDays + 5),
            athleteID:    athleteID,
            bodyMetrics:  BodyMetricsSnapshot(bodyWeight: 80),
            circumferences: nil,
            skinfolds:    nil,
            photoCount:   0,   // triggers noPhotos
            hasCoachNote: false,
            hasAthleteNote: false
        )
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [staleSnap],
            preferences:    prefs,
            now:            now
        )
        #expect(alerts.count >= 2)
        let severities = alerts.map { $0.severity }
        #expect(severities == severities.sorted(by: >))
    }

    // MARK: - Multiple check-ins

    @Test("evaluator uses most recent check-in for photo and metric alerts")
    func evaluatorUsesLatestCheckIn() {
        let old  = snapshot(daysAgo: 30, weight: nil,  photoCount: 0) // missing metrics + no photos
        let recent = snapshot(daysAgo: 5, weight: 80.0, photoCount: 3) // all good
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [old, recent],
            preferences:    prefs,
            now:            now
        )
        let hasNoPhotos  = alerts.contains { if case .noPhotos      = $0.kind { return true }; return false }
        let hasMissing   = alerts.contains { if case .incompleteMetrics = $0.kind { return true }; return false }
        #expect(!hasNoPhotos)
        #expect(!hasMissing)
    }

    // MARK: - Negative trend

    @Test("rising bf trend over 3+ data points triggers negativeTrend alert")
    func risingBfTrendAlert() {
        // BF rising ~4% over 35 days → slope * span > 1.0
        let snap1 = snapshot(daysAgo: 40, weight: 80.0, bodyFat: 15.0)
        let snap2 = snapshot(daysAgo: 20, weight: 80.0, bodyFat: 17.0)
        let snap3 = snapshot(daysAgo: 5,  weight: 80.0, bodyFat: 19.0)
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap1, snap2, snap3],
            preferences:    prefs,
            now:            now
        )
        let hasNeg = alerts.contains { if case .negativeTrend = $0.kind { return true }; return false }
        #expect(hasNeg)
    }

    @Test("fewer than 3 bf data points produces no negativeTrend alert")
    func insufficientBfPointsNoNegativeTrend() {
        let snap1 = snapshot(daysAgo: 30, weight: 80.0, bodyFat: 15.0)
        let snap2 = snapshot(daysAgo: 5,  weight: 80.0, bodyFat: 19.0)
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap1, snap2],
            preferences:    prefs,
            now:            now
        )
        let hasNeg = alerts.contains { if case .negativeTrend = $0.kind { return true }; return false }
        #expect(!hasNeg)
    }

    // MARK: - Alert toggle preferences

    @Test("showInactiveAlerts=false suppresses inactive alert")
    func disabledInactiveAlertToggle() {
        var customPrefs = CoachPreferences.default
        customPrefs.showInactiveAlerts = false
        let snap = snapshot(daysAgo: prefs.inactivityThresholdDays + 5)
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap],
            preferences:    customPrefs,
            now:            now
        )
        let hasInactive = alerts.contains { if case .inactive = $0.kind { return true }; return false }
        #expect(!hasInactive)
    }

    @Test("showPhotoAlerts=false suppresses noPhotos alert")
    func disabledPhotoAlertToggle() {
        var customPrefs = CoachPreferences.default
        customPrefs.showPhotoAlerts = false
        let snap = snapshot(daysAgo: 3, photoCount: 0)
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap],
            preferences:    customPrefs,
            now:            now
        )
        let hasNoPhotos = alerts.contains { if case .noPhotos = $0.kind { return true }; return false }
        #expect(!hasNoPhotos)
    }

    @Test("showMetricAlerts=false suppresses incompleteMetrics alert")
    func disabledMetricAlertToggle() {
        var customPrefs = CoachPreferences.default
        customPrefs.showMetricAlerts = false
        let snap = CheckInSnapshot(
            id:             UUID(),
            date:           date(daysAgo: 3),
            athleteID:      athleteID,
            bodyMetrics:    nil,
            circumferences: nil,
            skinfolds:      nil,
            photoCount:     1,
            hasCoachNote:   false,
            hasAthleteNote: false
        )
        let alerts = AthleteAlertEvaluator.evaluate(
            athleteID:      athleteID,
            athleteName:    athleteName,
            sortedCheckIns: [snap],
            preferences:    customPrefs,
            now:            now
        )
        let hasMissing = alerts.contains { if case .incompleteMetrics = $0.kind { return true }; return false }
        #expect(!hasMissing)
    }
}
