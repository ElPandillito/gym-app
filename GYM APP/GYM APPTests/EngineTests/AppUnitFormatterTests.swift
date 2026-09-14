//
//  AppUnitFormatterTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("AppUnitFormatterTests")
@MainActor
struct AppUnitFormatterTests {

    // MARK: - Fixtures

    private let metricPrefs = CoachPreferences(preferredWeightUnit: .kg, preferredLengthUnit: .cm)
    private let imperialPrefs = CoachPreferences(preferredWeightUnit: .lb, preferredLengthUnit: .inches)

    private var metricFmt: AppUnitFormatter { AppUnitFormatter(preferences: metricPrefs) }
    private var imperialFmt: AppUnitFormatter { AppUnitFormatter(preferences: imperialPrefs) }

    // MARK: - Weight label

    @Test("weightLabel returns 'kg' for metric preferences")
    func weightLabelKg() {
        #expect(metricFmt.weightLabel == "kg")
    }

    @Test("weightLabel returns 'lb' for imperial preferences")
    func weightLabelLb() {
        #expect(imperialFmt.weightLabel == "lb")
    }

    // MARK: - Weight conversion

    @Test("convertedWeight returns identity for kg preferences")
    func weightIdentityKg() {
        #expect(metricFmt.convertedWeight(70.0) == 70.0)
    }

    @Test("convertedWeight multiplies by 2.20462 for lb preferences")
    func weightConversionLb() {
        let result = imperialFmt.convertedWeight(70.0)
        #expect(abs(result - 70.0 * 2.20462) < 0.001)
    }

    // MARK: - weight(_:) formatting

    @Test("weight() formats with 1 decimal and kg suffix")
    func weightFormatKg() {
        #expect(metricFmt.weight(70.5) == "70.5 kg")
    }

    @Test("weight() converts and formats with lb suffix")
    func weightFormatLb() {
        let result = imperialFmt.weight(70.0)
        #expect(result.hasSuffix(" lb"))
        #expect(result.contains("154"))
    }

    // MARK: - weightOptional(_:)

    @Test("weightOptional returns '—' for nil")
    func weightOptionalNil() {
        #expect(metricFmt.weightOptional(nil) == "—")
    }

    @Test("weightOptional formats non-nil value")
    func weightOptionalValue() {
        #expect(metricFmt.weightOptional(80.0) == "80.0 kg")
    }

    // MARK: - weightDelta(_:)

    @Test("weightDelta prefixes '+' for positive value")
    func weightDeltaPositive() {
        let result = metricFmt.weightDelta(2.5)
        #expect(result == "+2.5 kg")
    }

    @Test("weightDelta keeps '-' for negative value")
    func weightDeltaNegative() {
        let result = metricFmt.weightDelta(-1.3)
        #expect(result == "-1.3 kg")
    }

    @Test("weightDelta converts to lb for imperial preferences")
    func weightDeltaLb() {
        let result = imperialFmt.weightDelta(1.0)
        #expect(result.hasSuffix(" lb"))
        #expect(result.hasPrefix("+"))
    }

    // MARK: - weightSlopeMonthly(_:)

    @Test("weightSlopeMonthly multiplies slope by 30 for kg")
    func weightSlopeMonthlyKg() {
        let result = metricFmt.weightSlopeMonthly(0.05)
        #expect(result == "+1.5 kg/mes")
    }

    @Test("weightSlopeMonthly converts slope to lb/mes for imperial")
    func weightSlopeMonthlyLb() {
        let result = imperialFmt.weightSlopeMonthly(0.05)
        #expect(result.hasSuffix(" lb/mes"))
    }

    // MARK: - Length label

    @Test("lengthLabel returns 'cm' for metric preferences")
    func lengthLabelCm() {
        #expect(metricFmt.lengthLabel == "cm")
    }

    @Test("lengthLabel returns 'in' (not 'inches') for imperial preferences")
    func lengthLabelIn() {
        #expect(imperialFmt.lengthLabel == "in")
    }

    // MARK: - Length conversion

    @Test("convertedLength returns identity for cm preferences")
    func lengthIdentityCm() {
        #expect(metricFmt.convertedLength(100.0) == 100.0)
    }

    @Test("convertedLength multiplies by 0.393701 for inches preferences")
    func lengthConversionIn() {
        let result = imperialFmt.convertedLength(100.0)
        #expect(abs(result - 100.0 * 0.393701) < 0.0001)
    }

    // MARK: - length(_:) formatting

    @Test("length() formats with 1 decimal and cm suffix")
    func lengthFormatCm() {
        #expect(metricFmt.length(85.0) == "85.0 cm")
    }

    @Test("length() converts and formats with 'in' suffix")
    func lengthFormatIn() {
        let result = imperialFmt.length(100.0)
        #expect(result.hasSuffix(" in"))
        #expect(result.contains("39"))
    }

    // MARK: - lengthOptional(_:)

    @Test("lengthOptional returns '—' for nil")
    func lengthOptionalNil() {
        #expect(metricFmt.lengthOptional(nil) == "—")
    }

    @Test("lengthOptional formats non-nil value")
    func lengthOptionalValue() {
        #expect(metricFmt.lengthOptional(90.0) == "90.0 cm")
    }

    // MARK: - lengthDelta(_:)

    @Test("lengthDelta prefixes '+' for positive value in cm")
    func lengthDeltaPositiveCm() {
        let result = metricFmt.lengthDelta(3.0)
        #expect(result == "+3.0 cm")
    }

    @Test("lengthDelta converts and uses 'in' suffix for imperial")
    func lengthDeltaIn() {
        let result = imperialFmt.lengthDelta(10.0)
        #expect(result.hasSuffix(" in"))
        #expect(result.hasPrefix("+"))
    }

    // MARK: - lengthSlopeMonthly(_:)

    @Test("lengthSlopeMonthly multiplies slope by 30 for cm")
    func lengthSlopeMonthly() {
        let result = metricFmt.lengthSlopeMonthly(0.1)
        #expect(result == "+3.0 cm/mes")
    }

    // MARK: - height(_:)

    @Test("height() formats as integer cm for metric preferences")
    func heightCm() {
        #expect(metricFmt.height(178.0) == "178 cm")
    }

    @Test("height() formats as 1-decimal inches for imperial preferences")
    func heightIn() {
        let result = imperialFmt.height(180.0)
        #expect(result.hasSuffix(" in"))
        let value = Double(result.dropLast(3)) ?? 0
        #expect(abs(value - 180.0 * 0.393701) < 0.05)
    }

    // MARK: - heightOptional(_:)

    @Test("heightOptional returns '—' for nil")
    func heightOptionalNil() {
        #expect(metricFmt.heightOptional(nil) == "—")
    }

    @Test("heightOptional formats non-nil value as integer cm")
    func heightOptionalValue() {
        #expect(metricFmt.heightOptional(175.0) == "175 cm")
    }

    // MARK: - Static convenience

    @Test("AppUnitFormatter.metric uses default kg/cm preferences")
    func staticMetricConvenience() {
        let fmt = AppUnitFormatter.metric
        #expect(fmt.weightLabel == "kg")
        #expect(fmt.lengthLabel == "cm")
    }
}
