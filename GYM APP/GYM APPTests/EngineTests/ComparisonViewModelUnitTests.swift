//
//  ComparisonViewModelUnitTests.swift
//  GYM APPTests
//

import Testing
import Foundation
import SwiftData
@testable import GYM_APP

@Suite("ComparisonViewModelUnitTests")
@MainActor
struct ComparisonViewModelUnitTests {

    // MARK: - Fixtures

    private let metricPrefs   = CoachPreferences(preferredWeightUnit: .kg, preferredLengthUnit: .cm)
    private let imperialPrefs = CoachPreferences(preferredWeightUnit: .lb, preferredLengthUnit: .inches)

    private static func makeContainer() throws -> ModelContainer {
        let schema = Schema(GYMAppSchemaV1.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    /// Creates two linked CheckIn+BodyMetrics pairs inside an in-memory container.
    private static func makePair(
        weightA: Double, weightB: Double,
        muscleMassA: Double? = nil, muscleMassB: Double? = nil
    ) throws -> (ciA: CheckIn, ciB: CheckIn, container: ModelContainer) {
        let container = try makeContainer()
        let ctx = ModelContext(container)

        let ciA = CheckIn(date: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        let ciB = CheckIn(date: Date())
        ctx.insert(ciA)
        ctx.insert(ciB)

        let bmA = BodyMetrics()
        bmA.bodyWeight  = weightA
        bmA.muscleMass  = muscleMassA
        bmA.checkIn     = ciA
        ctx.insert(bmA)

        let bmB = BodyMetrics()
        bmB.bodyWeight  = weightB
        bmB.muscleMass  = muscleMassB
        bmB.checkIn     = ciB
        ctx.insert(bmB)

        return (ciA, ciB, container)
    }

    // MARK: - Unit label in rows

    @Test("bodyMetric weight row uses 'kg' unit for metric preferences")
    func weightRowUnitKg() throws {
        let (ciA, ciB, _) = try Self.makePair(weightA: 80.0, weightB: 82.0)
        let vm = ComparisonViewModel()
        vm.configure(checkInA: ciA, checkInB: ciB, preferences: metricPrefs)
        let row = vm.sections.flatMap(\.rows).first { $0.label == "Peso" }
        #expect(row?.unit == "kg")
    }

    @Test("bodyMetric weight row uses 'lb' unit for imperial preferences")
    func weightRowUnitLb() throws {
        let (ciA, ciB, _) = try Self.makePair(weightA: 80.0, weightB: 82.0)
        let vm = ComparisonViewModel()
        vm.configure(checkInA: ciA, checkInB: ciB, preferences: imperialPrefs)
        let row = vm.sections.flatMap(\.rows).first { $0.label == "Peso" }
        #expect(row?.unit == "lb")
    }

    // MARK: - Display values

    @Test("weight displayBefore equals canonical value for metric preferences")
    func weightDisplayBeforeKg() throws {
        let (ciA, ciB, _) = try Self.makePair(weightA: 80.0, weightB: 82.0)
        let vm = ComparisonViewModel()
        vm.configure(checkInA: ciA, checkInB: ciB, preferences: metricPrefs)
        let row = vm.sections.flatMap(\.rows).first { $0.label == "Peso" }
        guard let before = row?.displayBefore else {
            Issue.record("displayBefore is nil")
            return
        }
        #expect(abs(before - 80.0) < 0.01)
    }

    @Test("weight displayBefore is converted to lb for imperial preferences")
    func weightDisplayBeforeLb() throws {
        let (ciA, ciB, _) = try Self.makePair(weightA: 80.0, weightB: 82.0)
        let vm = ComparisonViewModel()
        vm.configure(checkInA: ciA, checkInB: ciB, preferences: imperialPrefs)
        let row = vm.sections.flatMap(\.rows).first { $0.label == "Peso" }
        guard let before = row?.displayBefore else {
            Issue.record("displayBefore is nil")
            return
        }
        // 80 kg × 2.20462 ≈ 176.37 lb
        #expect(abs(before - 176.37) < 0.1)
    }

    @Test("displayAbsoluteChange is in lb for imperial preferences")
    func weightDeltaLb() throws {
        let (ciA, ciB, _) = try Self.makePair(weightA: 80.0, weightB: 82.0)
        let vm = ComparisonViewModel()
        vm.configure(checkInA: ciA, checkInB: ciB, preferences: imperialPrefs)
        let row = vm.sections.flatMap(\.rows).first { $0.label == "Peso" }
        guard let delta = row?.displayAbsoluteChange else {
            Issue.record("displayAbsoluteChange is nil")
            return
        }
        // 2 kg × 2.20462 ≈ 4.41 lb
        #expect(abs(abs(delta) - 4.41) < 0.1)
    }

    // MARK: - reconfigure updates display values

    @Test("reconfigure changes unit label from kg to lb")
    func reconfigureChangesUnit() throws {
        let (ciA, ciB, _) = try Self.makePair(weightA: 80.0, weightB: 82.0)
        let vm = ComparisonViewModel()
        vm.configure(checkInA: ciA, checkInB: ciB, preferences: metricPrefs)

        let rowBefore = vm.sections.flatMap(\.rows).first { $0.label == "Peso" }
        #expect(rowBefore?.unit == "kg")

        vm.reconfigure(preferences: imperialPrefs)

        let rowAfter = vm.sections.flatMap(\.rows).first { $0.label == "Peso" }
        #expect(rowAfter?.unit == "lb")
    }

    @Test("reconfigure does not re-run comparison engine (rawComparison unchanged)")
    func reconfigureKeepsRawComparison() throws {
        let (ciA, ciB, _) = try Self.makePair(weightA: 80.0, weightB: 82.0)
        let vm = ComparisonViewModel()
        vm.configure(checkInA: ciA, checkInB: ciB, preferences: metricPrefs)
        let rawBefore = vm.rawComparison

        vm.reconfigure(preferences: imperialPrefs)

        // rawComparison should be the same object (engine not re-run)
        #expect(vm.rawComparison?.daysBetween == rawBefore?.daysBetween)
    }
}
