//
//  StatisticsEngineTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("StatisticsEngine")
struct StatisticsEngineTests {

    private let athleteID = UUID()

    private func makeSnapshot(
        daysAgo: Int,
        weight: Double? = nil,
        bodyFat: Double? = nil
    ) -> CheckInSnapshot {
        let bm: BodyMetricsSnapshot? = (weight != nil || bodyFat != nil)
            ? BodyMetricsSnapshot(bodyWeight: weight, bodyFatPercentage: bodyFat)
            : nil
        let refDate = Calendar.current.date(
            from: DateComponents(year: 2026, month: 1, day: 1)
        )!
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: refDate)!
        return CheckInSnapshot(
            id: UUID(),
            date: date,
            athleteID: athleteID,
            anthropometryProfile: .standard,
            bodyMetrics: bm,
            circumferences: nil,
            skinfolds: nil,
            photoCount: 0,
            hasCoachNote: false,
            hasAthleteNote: false
        )
    }

    // MARK: - empty input

    @Test("empty snapshots returns report with checkInCount 0")
    func emptySnapshotsReturnsEmptyReport() {
        let report = StatisticsEngine.compute(athleteID: athleteID, snapshots: [])
        #expect(report.checkInCount == 0)
        #expect(report.athleteID == athleteID)
    }

    // MARK: - checkInCount

    @Test("single snapshot gives checkInCount of 1")
    func singleSnapshotCount() {
        let report = StatisticsEngine.compute(
            athleteID: athleteID,
            snapshots: [makeSnapshot(daysAgo: 0, weight: 80)]
        )
        #expect(report.checkInCount == 1)
    }

    @Test("three snapshots give checkInCount of 3")
    func threeSnapshotsCount() {
        let report = StatisticsEngine.compute(
            athleteID: athleteID,
            snapshots: [
                makeSnapshot(daysAgo: 30, weight: 80),
                makeSnapshot(daysAgo: 20, weight: 79),
                makeSnapshot(daysAgo: 10, weight: 78),
            ]
        )
        #expect(report.checkInCount == 3)
    }

    // MARK: - averageDaysBetweenCheckIns

    @Test("single snapshot gives nil average interval")
    func singleSnapshotNilAverageInterval() {
        let report = StatisticsEngine.compute(
            athleteID: athleteID,
            snapshots: [makeSnapshot(daysAgo: 0, weight: 80)]
        )
        #expect(report.averageDaysBetweenCheckIns == nil)
    }

    @Test("two snapshots 10 days apart gives average of 10")
    func twoSnapshotsTenDaysApart() throws {
        let report = StatisticsEngine.compute(
            athleteID: athleteID,
            snapshots: [
                makeSnapshot(daysAgo: 10, weight: 80),
                makeSnapshot(daysAgo: 0,  weight: 79),
            ]
        )
        let avg = try #require(report.averageDaysBetweenCheckIns)
        #expect(abs(avg - 10) < 0.1)
    }

    // MARK: - percentageChange

    @Test("percentageChange from 100 to 110 is 10 pct")
    func percentageChangePositive() throws {
        let pct = try #require(StatisticsEngine.percentageChange(from: 100, to: 110))
        #expect(abs(pct - 10) < 0.001)
    }

    @Test("percentageChange from 80 to 60 is -25 pct")
    func percentageChangeNegative() throws {
        let pct = try #require(StatisticsEngine.percentageChange(from: 80, to: 60))
        #expect(abs(pct - (-25)) < 0.001)
    }

    @Test("percentageChange from 0 returns nil")
    func percentageChangeFromZeroReturnsNil() {
        let pct = StatisticsEngine.percentageChange(from: 0, to: 10)
        #expect(pct == nil)
    }

    // MARK: - dashboardKPIs

    @Test("dashboardKPIs totalAthletes matches input count")
    func dashboardKPIsTotalAthletes() {
        let athletes = [
            AthleteSnapshot(id: UUID(), name: "A", gender: .male,   birthDate: nil, heightCm: nil),
            AthleteSnapshot(id: UUID(), name: "B", gender: .female, birthDate: nil, heightCm: nil),
        ]
        let kpis = StatisticsEngine.dashboardKPIs(athletes: athletes, allSnapshots: [])
        #expect(kpis.totalAthletes == 2)
        #expect(kpis.totalCheckIns == 0)
    }

    @Test("dashboardKPIs averageBodyFat ignores athletes with no data")
    func dashboardKPIsAverageBodyFatNilWhenNoData() {
        let athletes = [AthleteSnapshot(id: UUID(), name: "A", gender: .male, birthDate: nil, heightCm: nil)]
        let kpis = StatisticsEngine.dashboardKPIs(athletes: athletes, allSnapshots: [])
        #expect(kpis.averageBodyFat == nil)
    }
}
