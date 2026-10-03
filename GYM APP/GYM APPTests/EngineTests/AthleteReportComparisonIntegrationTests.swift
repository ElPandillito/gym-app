//
//  AthleteReportComparisonIntegrationTests.swift
//  GYM APPTests
//
//  Proves the Phase 46 composition — CheckInSnapshot -> CheckInComparisonEngine
//  -> AthleteReportBuilder.addComparisons -> AthleteReport — without
//  re-testing CheckInComparisonEngine's own internals (already covered
//  elsewhere) or duplicating the Phase 45 JSON serializer suite.
//

import Testing
import Foundation
@testable import GYM_APP

// MARK: - Fixtures

private let fixedDate = Calendar.current.date(
    from: DateComponents(year: 2026, month: 3, day: 1)
)!

private func makeSnapshot(daysOffset: Int, weight: Double) -> CheckInSnapshot {
    CheckInSnapshot(
        id: UUID(),
        date: Calendar.current.date(byAdding: .day, value: daysOffset, to: fixedDate)!,
        athleteID: UUID(),
        bodyMetrics: BodyMetricsSnapshot(bodyWeight: weight),
        circumferences: nil,
        skinfolds: nil,
        photoCount: 0,
        hasCoachNote: false,
        hasAthleteNote: false
    )
}

private func makeStats() -> AthleteStatisticsReport {
    AthleteStatisticsReport(
        athleteID: UUID(),
        period: nil,
        checkInCount: 2,
        averageDaysBetweenCheckIns: 14.0,
        weightTrend: .insufficient,
        bodyFatTrend: .insufficient,
        muscleMassTrend: .insufficient,
        lowestBodyFat: nil,
        highestBodyFat: nil,
        lowestWeight: nil,
        highestWeight: nil,
        peakMuscleMass: nil,
        timeSeries: [:]
    )
}

/// Builds an AthleteReport via the exact same composition used by
/// AthleteReportSheet.report: snapshots -> compareSeries -> addComparisons.
private func makeReport(from snapshots: [CheckInSnapshot]) -> AthleteReport {
    let comparisons = CheckInComparisonEngine.compareSeries(snapshots)
    return AthleteReportBuilder()
        .setAthlete(.mock())
        .setStatistics(makeStats())
        .addComparisons(comparisons)
        .build()
}

// MARK: - Tests

@Suite("AthleteReport <- CheckInComparisonEngine integration (Phase 46)")
struct AthleteReportComparisonIntegrationTests {

    @Test("multiple check-ins produce non-empty comparisons sourced from the real engine")
    func comparisons_populated_viaRealEngine() {
        let snapshots = [
            makeSnapshot(daysOffset: 0, weight: 80.0),
            makeSnapshot(daysOffset: 14, weight: 78.0)
        ]
        let report = makeReport(from: snapshots)

        #expect(report.comparisons.count == 1)
        #expect(report.comparisons.first?.weight.direction == .decreased)
        #expect(report.comparisons.first?.daysBetween == 14)
    }

    @Test("zero check-ins yield empty comparisons")
    func comparisons_zeroCheckIns_empty() {
        let report = makeReport(from: [])
        #expect(report.comparisons.isEmpty)
    }

    @Test("a single check-in yields empty comparisons (compareSeries' existing guard)")
    func comparisons_singleCheckIn_empty() {
        let report = makeReport(from: [makeSnapshot(daysOffset: 0, weight: 80.0)])
        #expect(report.comparisons.isEmpty)
    }

    @Test("json(from:) preserves comparisons produced by the real engine composition")
    func json_reflectsRealComparisons() throws {
        let snapshots = [
            makeSnapshot(daysOffset: 0, weight: 80.0),
            makeSnapshot(daysOffset: 14, weight: 78.0)
        ]
        let report = makeReport(from: snapshots)

        let data = try AthleteReportSerializer.json(from: report)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let jsonComparisons = obj?["comparisons"] as? [[String: Any]]

        #expect(jsonComparisons?.count == 1)
        let weight = jsonComparisons?.first?["weight"] as? [String: Any]
        #expect(weight?["direction"] as? String == "decreased")
    }
}
