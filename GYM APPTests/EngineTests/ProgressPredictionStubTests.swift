//
//  ProgressPredictionStubTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("ProgressPredictionStubTests")
@MainActor
struct ProgressPredictionStubTests {

    // MARK: - Fixtures

    private let epoch   = Date(timeIntervalSince1970: 0)
    private let oneDay: TimeInterval = 86_400

    private let stub = ProgressPredictionStub()

    private func makeSnapshot(daysAfterEpoch: Double, weight: Double) -> CheckInSnapshot {
        let date = Date(timeIntervalSince1970: daysAfterEpoch * 86_400)
        return CheckInSnapshot(
            id:           UUID(),
            date:         date,
            athleteID:    UUID(),
            bodyMetrics:  BodyMetricsSnapshot(bodyWeight: weight),
            circumferences: nil,
            skinfolds:    nil,
            photoCount:   0,
            hasCoachNote: false,
            hasAthleteNote: false
        )
    }

    // MARK: - Protocol conformance

    @Test("ProgressPredictionStub conforms to ProgressPredictionServiceProtocol")
    func conformsToProtocol() {
        let s: any ProgressPredictionServiceProtocol = stub
        _ = s
    }

    // MARK: - Invalid input

    @Test("daysAhead == 0 throws .invalidInput")
    func zeroDaysAheadThrows() async {
        let snaps = [makeSnapshot(daysAfterEpoch: 0, weight: 80),
                     makeSnapshot(daysAfterEpoch: 7, weight: 80.5)]
        do {
            _ = try await stub.predict(metric: .weight, snapshots: snaps, daysAhead: 0)
            Issue.record("Expected throw for daysAhead == 0")
        } catch let e as AIServiceError {
            if case .invalidInput = e { } else {
                Issue.record("Expected .invalidInput, got \(e)")
            }
        } catch {
            Issue.record("Expected AIServiceError, got \(error)")
        }
    }

    // MARK: - Insufficient data

    @Test("empty snapshot array throws .insufficientData")
    func emptySnapshotsThrows() async {
        do {
            _ = try await stub.predict(metric: .weight, snapshots: [], daysAhead: 30)
            Issue.record("Expected throw for empty snapshots")
        } catch let e as AIServiceError {
            #expect(e == .insufficientData)
        } catch {
            Issue.record("Expected AIServiceError, got \(error)")
        }
    }

    @Test("single snapshot throws .insufficientData")
    func singleSnapshotThrows() async {
        let snaps = [makeSnapshot(daysAfterEpoch: 0, weight: 80)]
        do {
            _ = try await stub.predict(metric: .weight, snapshots: snaps, daysAhead: 30)
            Issue.record("Expected throw for single snapshot")
        } catch let e as AIServiceError {
            #expect(e == .insufficientData)
        } catch {
            Issue.record("Expected AIServiceError, got \(error)")
        }
    }

    @Test("snapshots with no weight data for requested metric throws .insufficientData")
    func noDataForMetricThrows() async {
        // Snapshots have weight but we request .bodyFat which is nil
        let snaps = [makeSnapshot(daysAfterEpoch: 0, weight: 80),
                     makeSnapshot(daysAfterEpoch: 7, weight: 81)]
        do {
            _ = try await stub.predict(metric: .bodyFat, snapshots: snaps, daysAhead: 30)
            Issue.record("Expected throw: bodyFat is nil in all snapshots")
        } catch let e as AIServiceError {
            #expect(e == .insufficientData)
        } catch {
            Issue.record("Expected AIServiceError, got \(error)")
        }
    }

    // MARK: - Rising trend

    @Test("rising weight trend predicts a higher value at future date")
    func risingTrendPredictesHigher() async throws {
        // Weight rises +1 kg every 7 days
        let snaps = [
            makeSnapshot(daysAfterEpoch:  0, weight: 80.0),
            makeSnapshot(daysAfterEpoch:  7, weight: 81.0),
            makeSnapshot(daysAfterEpoch: 14, weight: 82.0),
            makeSnapshot(daysAfterEpoch: 21, weight: 83.0),
        ]
        let result = try await stub.predict(metric: .weight, snapshots: snaps, daysAhead: 7)
        #expect(result.predictedValue > 83.0)
    }

    // MARK: - Falling trend

    @Test("falling weight trend predicts a lower value at future date")
    func fallingTrendPredictesLower() async throws {
        let snaps = [
            makeSnapshot(daysAfterEpoch:  0, weight: 84.0),
            makeSnapshot(daysAfterEpoch:  7, weight: 83.0),
            makeSnapshot(daysAfterEpoch: 14, weight: 82.0),
            makeSnapshot(daysAfterEpoch: 21, weight: 81.0),
        ]
        let result = try await stub.predict(metric: .weight, snapshots: snaps, daysAhead: 7)
        #expect(result.predictedValue < 81.0)
    }

    // MARK: - Flat trend

    @Test("flat weight trend predicts approximately the same value")
    func flatTrendPredictesConstant() async throws {
        let snaps = [
            makeSnapshot(daysAfterEpoch:  0, weight: 80.0),
            makeSnapshot(daysAfterEpoch:  7, weight: 80.0),
            makeSnapshot(daysAfterEpoch: 14, weight: 80.0),
        ]
        let result = try await stub.predict(metric: .weight, snapshots: snaps, daysAhead: 30)
        // Flat OLS → predicted ≈ 80.0 (within 0.01 for exact duplicates)
        #expect(abs(result.predictedValue - 80.0) < 0.01)
    }

    // MARK: - Confidence interval

    @Test("confidence interval contains the predicted value")
    func ciContainsPrediction() async throws {
        let snaps = [
            makeSnapshot(daysAfterEpoch:  0, weight: 80.0),
            makeSnapshot(daysAfterEpoch:  7, weight: 80.5),
            makeSnapshot(daysAfterEpoch: 14, weight: 81.0),
        ]
        let result = try await stub.predict(metric: .weight, snapshots: snaps, daysAhead: 30)
        #expect(result.confidenceInterval.contains(result.predictedValue))
    }

    @Test("model confidence is in [0.0, 0.80]")
    func confidenceIsCapped() async throws {
        let snaps = (0..<20).map { i in makeSnapshot(daysAfterEpoch: Double(i * 7), weight: 80 + Double(i) * 0.5) }
        let result = try await stub.predict(metric: .weight, snapshots: snaps, daysAhead: 30)
        #expect(result.modelConfidence >= 0.0)
        #expect(result.modelConfidence <= 0.80)
    }

    // MARK: - Result metadata

    @Test("result carries the requested metric")
    func resultCarriesMetric() async throws {
        let snaps = [
            makeSnapshot(daysAfterEpoch: 0, weight: 80),
            makeSnapshot(daysAfterEpoch: 7, weight: 81),
        ]
        let result = try await stub.predict(metric: .weight, snapshots: snaps, daysAhead: 14)
        #expect(result.metric == .weight)
    }

    @Test("targetDate is approximately daysAhead from latest snapshot")
    func targetDateIsCorrect() async throws {
        let latestDay: Double = 14
        let snaps = [
            makeSnapshot(daysAfterEpoch:  0, weight: 80),
            makeSnapshot(daysAfterEpoch:  7, weight: 80.5),
            makeSnapshot(daysAfterEpoch: latestDay, weight: 81),
        ]
        let daysAhead = 30
        let result = try await stub.predict(metric: .weight, snapshots: snaps, daysAhead: daysAhead)

        let latestDate   = Date(timeIntervalSince1970: latestDay * 86_400)
        let expectedDate = latestDate.addingTimeInterval(Double(daysAhead) * 86_400)
        #expect(abs(result.targetDate.timeIntervalSince(expectedDate)) < 1.0)
    }

    // MARK: - Determinism

    @Test("same input produces same predicted value (determinism)")
    func deterministicOutput() async throws {
        let snaps = [
            makeSnapshot(daysAfterEpoch:  0, weight: 80.0),
            makeSnapshot(daysAfterEpoch:  7, weight: 80.5),
            makeSnapshot(daysAfterEpoch: 14, weight: 81.0),
        ]
        let r1 = try await stub.predict(metric: .weight, snapshots: snaps, daysAhead: 30)
        let r2 = try await stub.predict(metric: .weight, snapshots: snaps, daysAhead: 30)
        #expect(r1.predictedValue == r2.predictedValue)
        #expect(r1.modelConfidence == r2.modelConfidence)
    }
}
