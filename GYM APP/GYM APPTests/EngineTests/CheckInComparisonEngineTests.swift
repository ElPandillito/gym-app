//
//  CheckInComparisonEngineTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("CheckInComparisonEngine")
struct CheckInComparisonEngineTests {

    // Fixed dates for deterministic tests
    private var dateA: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
    }
    private var dateB: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 31))!
    }

    private func makeSnapshot(
        date: Date,
        weight: Double? = nil,
        bodyFat: Double? = nil
    ) -> CheckInSnapshot {
        let bm: BodyMetricsSnapshot? = (weight != nil || bodyFat != nil)
            ? BodyMetricsSnapshot(bodyWeight: weight, bodyFatPercentage: bodyFat)
            : nil
        return CheckInSnapshot(
            id: UUID(), date: date, athleteID: UUID(),
            anthropometryProfile: .standard,
            bodyMetrics: bm, circumferences: nil, skinfolds: nil,
            photoCount: 0, hasCoachNote: false, hasAthleteNote: false
        )
    }

    // MARK: - compare

    @Test("compare returns correct daysBetween")
    func compareDaysBetween() {
        let comparison = CheckInComparisonEngine.compare(
            makeSnapshot(date: dateA, weight: 80),
            makeSnapshot(date: dateB, weight: 78)
        )
        #expect(comparison.daysBetween == 30)
    }

    @Test("compare weight MetricDiff has correct before/after")
    func compareWeightDiff() {
        let a = makeSnapshot(date: dateA, weight: 80)
        let b = makeSnapshot(date: dateB, weight: 75)
        let comparison = CheckInComparisonEngine.compare(a, b)
        #expect(comparison.weight.before == 80)
        #expect(comparison.weight.after  == 75)
    }

    @Test("compare assigns correct checkInAID and checkInBID")
    func compareIDsAreCorrect() {
        let a = makeSnapshot(date: dateA)
        let b = makeSnapshot(date: dateB)
        let comparison = CheckInComparisonEngine.compare(a, b)
        #expect(comparison.checkInAID == a.id)
        #expect(comparison.checkInBID == b.id)
    }

    @Test("compare with nil metrics gives nil weight diff values")
    func compareNilMetricsGivesNilDiff() {
        let comparison = CheckInComparisonEngine.compare(
            makeSnapshot(date: dateA),
            makeSnapshot(date: dateB)
        )
        #expect(comparison.weight.before == nil)
        #expect(comparison.weight.after  == nil)
    }

    @Test("compare dates are assigned correctly")
    func compareDatesAreCorrect() {
        let comparison = CheckInComparisonEngine.compare(
            makeSnapshot(date: dateA, weight: 80),
            makeSnapshot(date: dateB, weight: 78)
        )
        #expect(comparison.dateA == dateA)
        #expect(comparison.dateB == dateB)
    }

    // MARK: - compareSeries

    @Test("compareSeries empty input returns empty array")
    func compareSeriesEmpty() {
        #expect(CheckInComparisonEngine.compareSeries([]).isEmpty)
    }

    @Test("compareSeries single snapshot returns empty array")
    func compareSeriesSingle() {
        let result = CheckInComparisonEngine.compareSeries([makeSnapshot(date: dateA, weight: 80)])
        #expect(result.isEmpty)
    }

    @Test("compareSeries three snapshots returns two comparisons sorted chronologically")
    func compareSeriesThreeSnapshots() {
        let d1 = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let d2 = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let d3 = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 30))!
        // Deliberately pass out of order to test sorting
        let result = CheckInComparisonEngine.compareSeries([
            makeSnapshot(date: d2, weight: 79),
            makeSnapshot(date: d1, weight: 80),
            makeSnapshot(date: d3, weight: 78),
        ])
        #expect(result.count == 2)
        #expect(result[0].dateA == d1)
        #expect(result[1].dateA == d2)
    }
}
