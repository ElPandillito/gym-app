//
//  InputConversionTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("InputConversionTests")
@MainActor
struct InputConversionTests {

    private let metricPrefs   = CoachPreferences(preferredWeightUnit: .kg, preferredLengthUnit: .cm)
    private let imperialPrefs = CoachPreferences(preferredWeightUnit: .lb, preferredLengthUnit: .inches)

    private var metricFmt:   AppUnitFormatter { AppUnitFormatter(preferences: metricPrefs) }
    private var imperialFmt: AppUnitFormatter { AppUnitFormatter(preferences: imperialPrefs) }

    // MARK: - Weight canonical (metric)

    @Test("toCanonicalWeight is identity for kg preferences")
    func canonicalWeightIdentityKg() {
        #expect(metricFmt.toCanonicalWeight(80.0) == 80.0)
    }

    @Test("toCanonicalWeight preserves zero for kg preferences")
    func canonicalWeightZeroKg() {
        #expect(metricFmt.toCanonicalWeight(0.0) == 0.0)
    }

    // MARK: - Weight canonical (imperial)

    @Test("toCanonicalWeight converts 176.4 lb to approximately 80.0 kg")
    func lbToKg176() {
        let kg = imperialFmt.toCanonicalWeight(176.4)
        #expect(abs(kg - 80.0) < 0.05)
    }

    @Test("toCanonicalWeight converts 154.323 lb to approximately 70.0 kg")
    func lbToKg154() {
        let kg = imperialFmt.toCanonicalWeight(154.323)
        #expect(abs(kg - 70.0) < 0.01)
    }

    @Test("toCanonicalWeight is inverse of convertedWeight for lb")
    func weightRoundTripLb() {
        let original = 82.5
        let displayed = imperialFmt.convertedWeight(original)
        let canonical = imperialFmt.toCanonicalWeight(displayed)
        #expect(abs(canonical - original) < 0.0001)
    }

    @Test("weight round-trip holds for multiple values")
    func weightRoundTripMultiple() {
        for kg in [50.0, 75.0, 100.0, 120.5, 55.2] {
            let canonical = imperialFmt.toCanonicalWeight(imperialFmt.convertedWeight(kg))
            #expect(abs(canonical - kg) < 0.0001)
        }
    }

    @Test("toCanonicalWeight preserves zero for lb preferences")
    func canonicalWeightZeroLb() {
        #expect(imperialFmt.toCanonicalWeight(0.0) == 0.0)
    }

    // MARK: - Length canonical (metric)

    @Test("toCanonicalLength is identity for cm preferences")
    func canonicalLengthIdentityCm() {
        #expect(metricFmt.toCanonicalLength(90.0) == 90.0)
    }

    @Test("toCanonicalLength preserves zero for cm preferences")
    func canonicalLengthZeroCm() {
        #expect(metricFmt.toCanonicalLength(0.0) == 0.0)
    }

    // MARK: - Length canonical (imperial)

    @Test("toCanonicalLength converts 39.3701 in to approximately 100.0 cm")
    func inToCm39() {
        let cm = imperialFmt.toCanonicalLength(39.3701)
        #expect(abs(cm - 100.0) < 0.01)
    }

    @Test("toCanonicalLength converts 35.433 in to approximately 90.0 cm")
    func inToCm35() {
        let cm = imperialFmt.toCanonicalLength(35.433)
        #expect(abs(cm - 90.0) < 0.01)
    }

    @Test("toCanonicalLength is inverse of convertedLength for inches")
    func lengthRoundTripIn() {
        let original = 85.0
        let displayed = imperialFmt.convertedLength(original)
        let canonical = imperialFmt.toCanonicalLength(displayed)
        #expect(abs(canonical - original) < 0.0001)
    }

    @Test("length round-trip holds for multiple values")
    func lengthRoundTripMultiple() {
        for cm in [60.0, 80.0, 100.0, 120.0, 74.5] {
            let canonical = imperialFmt.toCanonicalLength(imperialFmt.convertedLength(cm))
            #expect(abs(canonical - cm) < 0.0001)
        }
    }

    @Test("toCanonicalLength preserves zero for inches preferences")
    func canonicalLengthZeroIn() {
        #expect(imperialFmt.toCanonicalLength(0.0) == 0.0)
    }

    // MARK: - Cross-consistency (metric ≠ imperial result)

    @Test("toCanonicalWeight kg and lb paths give different results for same non-zero input")
    func weightPathsDiffer() {
        let input = 100.0
        let kg = metricFmt.toCanonicalWeight(input)
        let lb = imperialFmt.toCanonicalWeight(input)
        #expect(abs(kg - lb) > 0.1)
    }

    @Test("toCanonicalLength cm and in paths give different results for same non-zero input")
    func lengthPathsDiffer() {
        let input = 40.0
        let cm = metricFmt.toCanonicalLength(input)
        let inches = imperialFmt.toCanonicalLength(input)
        #expect(abs(cm - inches) > 0.1)
    }
}
