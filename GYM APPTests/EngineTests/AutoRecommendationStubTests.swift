//
//  AutoRecommendationStubTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("AutoRecommendationStubTests")
@MainActor
struct AutoRecommendationStubTests {

    // MARK: - Fixtures

    private let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)
    private let athleteID = UUID()

    private func stub() -> AutoRecommendationStub {
        let now = fixedNow
        return AutoRecommendationStub(clock: { now })
    }

    private func athlete() -> AthleteSnapshot {
        AthleteSnapshot(id: athleteID, name: "Atleta Test", gender: .male, birthDate: nil, heightCm: 175)
    }

    private func statistics(
        checkInCount: Int,
        bodyFatTrend: Trend? = nil,
        muscleMassTrend: Trend? = nil,
        weightTrend: Trend? = nil,
        avgDays: Double? = nil
    ) -> AthleteStatisticsReport {
        AthleteStatisticsReport(
            athleteID:                  athleteID,
            period:                     nil,
            checkInCount:               checkInCount,
            averageDaysBetweenCheckIns: avgDays,
            weightTrend:                weightTrend ?? .insufficient,
            bodyFatTrend:               bodyFatTrend ?? .insufficient,
            muscleMassTrend:            muscleMassTrend ?? .insufficient,
            lowestBodyFat:              nil,
            highestBodyFat:             nil,
            lowestWeight:               nil,
            highestWeight:              nil,
            peakMuscleMass:             nil,
            timeSeries:                 [:]
        )
    }

    private func risingFatTrend(slopePerDay: Double = 0.02) -> Trend {
        Trend(slope: slopePerDay, intercept: 15.0, dataPointCount: 5, direction: .rising)
    }

    private func fallingMuscleTrend(slopePerDay: Double = -0.01) -> Trend {
        Trend(slope: slopePerDay, intercept: 70.0, dataPointCount: 5, direction: .falling)
    }

    // MARK: - Protocol conformance

    @Test("AutoRecommendationStub conforms to AutoRecommendationServiceProtocol")
    func conformsToProtocol() {
        let s: any AutoRecommendationServiceProtocol = stub()
        _ = s
    }

    // MARK: - Insufficient data

    @Test("checkInCount == 0 returns empty array")
    func noCheckInsReturnsEmpty() async throws {
        let result = try await stub().generateRecommendations(
            athlete: athlete(),
            statistics: statistics(checkInCount: 0)
        )
        #expect(result.isEmpty)
    }

    @Test("checkInCount == 1 returns empty array")
    func oneCheckInReturnsEmpty() async throws {
        let result = try await stub().generateRecommendations(
            athlete: athlete(),
            statistics: statistics(checkInCount: 1)
        )
        #expect(result.isEmpty)
    }

    @Test("checkInCount >= 2 with no signals returns empty array")
    func sufficientDataNoSignalsReturnsEmpty() async throws {
        let result = try await stub().generateRecommendations(
            athlete: athlete(),
            statistics: statistics(checkInCount: 5, avgDays: 10)
        )
        #expect(result.isEmpty)
    }

    // MARK: - Body composition signals

    @Test("rising fat trend with slope > 0.01/day triggers bodyComposition recommendation")
    func risingFatTrendTriggersRecommendation() async throws {
        let stats = statistics(checkInCount: 5, bodyFatTrend: risingFatTrend(slopePerDay: 0.02))
        let result = try await stub().generateRecommendations(athlete: athlete(), statistics: stats)

        let bodyComp = result.filter { $0.category == .bodyComposition }
        #expect(!bodyComp.isEmpty)
        #expect(bodyComp.first?.priority == .high)
    }

    @Test("small rising fat slope (< 0.01/day) does NOT trigger bodyComposition recommendation")
    func smallFatSlopeNoRecommendation() async throws {
        let tinySlope = Trend(slope: 0.005, intercept: 15.0, dataPointCount: 5, direction: .rising)
        let stats = statistics(checkInCount: 5, bodyFatTrend: tinySlope)
        let result = try await stub().generateRecommendations(athlete: athlete(), statistics: stats)

        let bodyComp = result.filter { $0.category == .bodyComposition }
        #expect(bodyComp.isEmpty)
    }

    @Test("falling muscle trend with slope < -0.007/day triggers bodyComposition recommendation")
    func fallingMuscleTriggers() async throws {
        let stats = statistics(checkInCount: 5, muscleMassTrend: fallingMuscleTrend(slopePerDay: -0.01))
        let result = try await stub().generateRecommendations(athlete: athlete(), statistics: stats)

        let bodyComp = result.filter { $0.category == .bodyComposition }
        #expect(!bodyComp.isEmpty)
    }

    // MARK: - Check-in frequency signal

    @Test("avgDays > 21 triggers checkInFrequency recommendation at medium priority")
    func highAvgDaysTriggersFrequencyRecommendation() async throws {
        let stats = statistics(checkInCount: 4, avgDays: 28)
        let result = try await stub().generateRecommendations(athlete: athlete(), statistics: stats)

        let freq = result.filter { $0.category == .checkInFrequency }
        #expect(!freq.isEmpty)
        #expect(freq.first?.priority == .medium)
    }

    @Test("avgDays == 14 does NOT trigger checkInFrequency recommendation")
    func lowAvgDaysNoFrequencyRecommendation() async throws {
        let stats = statistics(checkInCount: 4, avgDays: 14)
        let result = try await stub().generateRecommendations(athlete: athlete(), statistics: stats)

        let freq = result.filter { $0.category == .checkInFrequency }
        #expect(freq.isEmpty)
    }

    // MARK: - Ordering

    @Test("results are sorted by priority descending")
    func resultsSortedByPriority() async throws {
        let stats = statistics(
            checkInCount: 6,
            bodyFatTrend: risingFatTrend(),
            avgDays: 30   // triggers medium priority
        )
        let result = try await stub().generateRecommendations(athlete: athlete(), statistics: stats)
        #expect(result.count >= 2)
        let priorities = result.map { $0.priority.rawValue }
        #expect(priorities == priorities.sorted(by: >))
    }

    // MARK: - Determinism

    @Test("same input produces same recommendation IDs (determinism)")
    func deterministicOutput() async throws {
        let stats = statistics(checkInCount: 5, bodyFatTrend: risingFatTrend(), avgDays: 30)
        let r1 = try await stub().generateRecommendations(athlete: athlete(), statistics: stats)
        let r2 = try await stub().generateRecommendations(athlete: athlete(), statistics: stats)

        #expect(r1.map(\.id) == r2.map(\.id))
        #expect(r1.map(\.category.rawValue) == r2.map(\.category.rawValue))
        #expect(r1.map(\.priority) == r2.map(\.priority))
    }

    // MARK: - Metadata

    @Test("generatedAt matches the injected clock")
    func generatedAtMatchesClock() async throws {
        let stats = statistics(checkInCount: 5, bodyFatTrend: risingFatTrend())
        let result = try await stub().generateRecommendations(athlete: athlete(), statistics: stats)

        for rec in result {
            #expect(rec.generatedAt == fixedNow)
        }
    }
}
