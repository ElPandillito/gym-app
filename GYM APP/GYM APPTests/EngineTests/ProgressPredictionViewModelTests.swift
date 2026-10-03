//
//  ProgressPredictionViewModelTests.swift
//  GYM APPTests
//
//  Tests AthleteOverviewViewModel.PredictionHorizon computation and
//  the async loadPredictions flow via a minimal athlete fixture.
//

import Testing
import SwiftData
import Foundation
@testable import GYM_APP

// MARK: - Fixtures

@MainActor
private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
        for: Schema(GYMAppSchemaV1.models),
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}

@MainActor
private func makeAthleteWithMetrics(in context: ModelContext, checkInCount: Int) throws -> Athlete {
    let athlete = Athlete(name: "Test Athlete", gender: .male)
    context.insert(athlete)

    var date = Calendar.current.date(byAdding: .day, value: -checkInCount * 7, to: Date())!
    for i in 0..<checkInCount {
        let checkIn = CheckIn(date: date)
        let metrics = BodyMetrics()
        metrics.bodyWeight          = 80.0 - Double(i) * 0.3  // slightly decreasing
        metrics.bodyFatPercentage   = 18.0 - Double(i) * 0.1
        metrics.muscleMass          = 60.0 + Double(i) * 0.05
        checkIn.bodyMetrics = metrics
        athlete.checkIns.append(checkIn)
        context.insert(checkIn)
        context.insert(metrics)
        date = Calendar.current.date(byAdding: .day, value: 7, to: date)!
    }
    try context.save()
    return athlete
}

// MARK: - PredictionHorizon unit tests (no async needed)

@Suite("AthleteOverviewViewModel.PredictionHorizon")
struct PredictionHorizonTests {

    @Test("averageConfidence returns 0 when all results are nil")
    func averageConfidence_allNil() {
        let h = AthleteOverviewViewModel.PredictionHorizon(
            daysAhead: 30, weight: nil, bodyFat: nil, muscleMass: nil
        )
        #expect(h.averageConfidence == 0)
    }

    @Test("averageConfidence averages available results")
    func averageConfidence_partial() {
        let r = PredictionResult(
            metric: .weight,
            predictedValue: 78,
            confidenceInterval: 77...79,
            targetDate: Date(),
            modelConfidence: 0.6
        )
        let h = AthleteOverviewViewModel.PredictionHorizon(
            daysAhead: 30, weight: r, bodyFat: nil, muscleMass: nil
        )
        #expect(h.averageConfidence == 0.6)
    }

    @Test("averageConfidence correctly averages three results")
    func averageConfidence_three() {
        func makeResult(confidence: Double) -> PredictionResult {
            PredictionResult(
                metric: .weight,
                predictedValue: 78,
                confidenceInterval: 77...79,
                targetDate: Date(),
                modelConfidence: confidence
            )
        }
        let h = AthleteOverviewViewModel.PredictionHorizon(
            daysAhead: 30,
            weight:    makeResult(confidence: 0.3),
            bodyFat:   makeResult(confidence: 0.6),
            muscleMass: makeResult(confidence: 0.9)
        )
        #expect(abs(h.averageConfidence - 0.6) < 0.001)
    }
}

// MARK: - Async prediction loading

@Suite("AthleteOverviewViewModel — prediction loading", .serialized)
struct PredictionLoadingTests {

    @Test("build() with 6 check-ins populates 3 prediction horizons")
    @MainActor
    func build_populatesThreeHorizons() async throws {
        let container = try makeContainer()
        let athlete   = try makeAthleteWithMetrics(in: container.mainContext, checkInCount: 6)

        let vm = AthleteOverviewViewModel()
        vm.build(from: athlete)

        // Give the async prediction task time to finish
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(vm.predictionHorizons.count == 3)
        #expect(vm.predictionHorizons.map(\.daysAhead) == [30, 60, 90])
        #expect(!vm.isPredicting)
    }

    @Test("each horizon has at least a weight prediction")
    @MainActor
    func build_eachHorizonHasWeight() async throws {
        let container = try makeContainer()
        let athlete   = try makeAthleteWithMetrics(in: container.mainContext, checkInCount: 4)

        let vm = AthleteOverviewViewModel()
        vm.build(from: athlete)

        try await Task.sleep(nanoseconds: 200_000_000)

        for horizon in vm.predictionHorizons {
            #expect(horizon.weight != nil, "Horizon \(horizon.daysAhead)d should have a weight prediction")
        }
    }

    @Test("build() with < 2 check-ins leaves predictionHorizons empty")
    @MainActor
    func build_oneCheckIn_noPredictions() async throws {
        let container = try makeContainer()
        let athlete   = try makeAthleteWithMetrics(in: container.mainContext, checkInCount: 1)

        let vm = AthleteOverviewViewModel()
        vm.build(from: athlete)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(vm.predictionHorizons.isEmpty)
    }

    @Test("90-day predicted weight is further from current than 30-day")
    @MainActor
    func build_longerHorizonFurtherFromCurrent() async throws {
        let container = try makeContainer()
        let athlete   = try makeAthleteWithMetrics(in: container.mainContext, checkInCount: 8)

        let vm = AthleteOverviewViewModel()
        vm.build(from: athlete)

        try await Task.sleep(nanoseconds: 200_000_000)

        guard let h30 = vm.predictionHorizons.first(where: { $0.daysAhead == 30 }),
              let h90 = vm.predictionHorizons.first(where: { $0.daysAhead == 90 }),
              let w30 = h30.weight?.predictedValue,
              let w90 = h90.weight?.predictedValue,
              let current = vm.currentMetrics?.weight
        else { return }

        // OLS trend is decreasing — 90d should be further below current than 30d
        let delta30 = abs(w30 - current)
        let delta90 = abs(w90 - current)
        #expect(delta90 >= delta30, "90-day prediction should be further from current than 30-day")
    }
}
