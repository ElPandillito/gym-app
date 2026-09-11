//
//  TrendChartPresenterTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("TrendChartPresenter")
struct TrendChartPresenterTests {

    // MARK: - displayValue

    @Test("weight displayValue returns value unchanged when unit is kg")
    func weightDisplayValueKg() {
        let p = TrendChartPresenter(metricKey: .weight, preferences: .default)
        #expect(abs(p.displayValue(for: 80.0) - 80.0) < 0.001)
    }

    @Test("weight displayValue converts to lb when unit is lb")
    func weightDisplayValueLb() {
        var prefs = CoachPreferences.default
        prefs.preferredWeightUnit = .lb
        let p = TrendChartPresenter(metricKey: .weight, preferences: prefs)
        #expect(abs(p.displayValue(for: 80.0) - 176.370) < 0.01)
    }

    @Test("muscleMass displayValue applies weight conversion")
    func muscleMassDisplayValueLb() {
        var prefs = CoachPreferences.default
        prefs.preferredWeightUnit = .lb
        let p = TrendChartPresenter(metricKey: .muscleMass, preferences: prefs)
        #expect(abs(p.displayValue(for: 40.0) - 88.185) < 0.01)
    }

    @Test("bodyFat displayValue returns raw value without conversion")
    func bodyFatDisplayValueRaw() {
        let p = TrendChartPresenter(metricKey: .bodyFat, preferences: .default)
        #expect(abs(p.displayValue(for: 15.5) - 15.5) < 0.001)
    }

    @Test("bmi displayValue returns raw value without conversion")
    func bmiDisplayValueRaw() {
        let p = TrendChartPresenter(metricKey: .bmi, preferences: .default)
        #expect(abs(p.displayValue(for: 22.3) - 22.3) < 0.001)
    }

    @Test("bmr displayValue returns raw value without conversion")
    func bmrDisplayValueRaw() {
        let p = TrendChartPresenter(metricKey: .bmr, preferences: .default)
        #expect(abs(p.displayValue(for: 1800.0) - 1800.0) < 0.001)
    }

    // MARK: - unitLabel

    @Test("weight unitLabel is kg by default")
    func weightUnitLabelKg() {
        let p = TrendChartPresenter(metricKey: .weight, preferences: .default)
        #expect(p.unitLabel == "kg")
    }

    @Test("weight unitLabel is lb when preferred")
    func weightUnitLabelLb() {
        var prefs = CoachPreferences.default
        prefs.preferredWeightUnit = .lb
        let p = TrendChartPresenter(metricKey: .weight, preferences: prefs)
        #expect(p.unitLabel == "lb")
    }

    @Test("bodyFat unitLabel is percent")
    func bodyFatUnitLabel() {
        let p = TrendChartPresenter(metricKey: .bodyFat, preferences: .default)
        #expect(p.unitLabel == "%")
    }

    @Test("water unitLabel is percent")
    func waterUnitLabel() {
        let p = TrendChartPresenter(metricKey: .water, preferences: .default)
        #expect(p.unitLabel == "%")
    }

    @Test("skinfoldBodyFat unitLabel is percent")
    func skinfoldBodyFatUnitLabel() {
        let p = TrendChartPresenter(metricKey: .skinfoldBodyFat, preferences: .default)
        #expect(p.unitLabel == "%")
    }

    @Test("bmi unitLabel is kg/m²")
    func bmiUnitLabel() {
        let p = TrendChartPresenter(metricKey: .bmi, preferences: .default)
        #expect(p.unitLabel == "kg/m²")
    }

    @Test("visceralFat unitLabel is nivel")
    func visceralFatUnitLabel() {
        let p = TrendChartPresenter(metricKey: .visceralFat, preferences: .default)
        #expect(p.unitLabel == "nivel")
    }

    @Test("bmr unitLabel is kcal")
    func bmrUnitLabel() {
        let p = TrendChartPresenter(metricKey: .bmr, preferences: .default)
        #expect(p.unitLabel == "kcal")
    }

    // MARK: - formattedValue

    @Test("weight formattedValue shows one decimal")
    func weightFormattedValue() {
        let p = TrendChartPresenter(metricKey: .weight, preferences: .default)
        #expect(p.formattedValue(72.3) == "72.3")
    }

    @Test("bodyFat formattedValue shows one decimal")
    func bodyFatFormattedValue() {
        let p = TrendChartPresenter(metricKey: .bodyFat, preferences: .default)
        #expect(p.formattedValue(14.55) == "14.6")
    }

    @Test("bmr formattedValue shows zero decimals")
    func bmrFormattedValue() {
        let p = TrendChartPresenter(metricKey: .bmr, preferences: .default)
        #expect(p.formattedValue(1823.7) == "1824")
    }

    @Test("visceralFat formattedValue shows zero decimals")
    func visceralFatFormattedValue() {
        let p = TrendChartPresenter(metricKey: .visceralFat, preferences: .default)
        #expect(p.formattedValue(8.9) == "9")
    }

    // MARK: - trendRateText

    @Test("insufficient direction returns dash")
    func trendRateTextInsufficient() {
        let p = TrendChartPresenter(metricKey: .weight, preferences: .default)
        #expect(p.trendRateText(slope: 0, direction: .insufficient) == "—")
    }

    @Test("flat direction returns Estable")
    func trendRateTextFlat() {
        let p = TrendChartPresenter(metricKey: .weight, preferences: .default)
        #expect(p.trendRateText(slope: 0.0001, direction: .flat) == "Estable")
    }

    @Test("weight rising trend shows positive kg/mes rate")
    func trendRateTextWeightRising() {
        let p = TrendChartPresenter(metricKey: .weight, preferences: .default)
        // slope = 0.2 kg/day → 6.0 kg/mes
        let text = p.trendRateText(slope: 0.2, direction: .rising)
        #expect(text.contains("+"))
        #expect(text.contains("kg/mes"))
        #expect(text.contains("6.0"))
    }

    @Test("weight falling trend shows negative kg/mes rate")
    func trendRateTextWeightFalling() {
        let p = TrendChartPresenter(metricKey: .weight, preferences: .default)
        // slope = -0.1 kg/day → -3.0 kg/mes
        let text = p.trendRateText(slope: -0.1, direction: .falling)
        #expect(text.contains("-"))
        #expect(text.contains("kg/mes"))
        #expect(text.contains("3.0"))
    }

    @Test("weight slope converts to lb/mes when preferred unit is lb")
    func trendRateTextWeightLb() {
        var prefs = CoachPreferences.default
        prefs.preferredWeightUnit = .lb
        let p = TrendChartPresenter(metricKey: .weight, preferences: prefs)
        // slope = 0.1 kg/day → 3.0 kg/mes → 6.6 lb/mes
        let text = p.trendRateText(slope: 0.1, direction: .rising)
        #expect(text.contains("lb/mes"))
    }

    @Test("bodyFat rising trend shows percent per month")
    func trendRateTextBodyFatRising() {
        let p = TrendChartPresenter(metricKey: .bodyFat, preferences: .default)
        // slope = 0.05 %/day → +1.5 %/mes
        let text = p.trendRateText(slope: 0.05, direction: .rising)
        #expect(text == "+1.5%/mes")
    }

    @Test("bodyFat falling trend shows negative percent per month")
    func trendRateTextBodyFatFalling() {
        let p = TrendChartPresenter(metricKey: .bodyFat, preferences: .default)
        // slope = -0.1 %/day → -3.0 %/mes
        let text = p.trendRateText(slope: -0.1, direction: .falling)
        #expect(text == "-3.0%/mes")
    }

    @Test("bmi trend shows two-decimal rate per month")
    func trendRateTextBmi() {
        let p = TrendChartPresenter(metricKey: .bmi, preferences: .default)
        let text = p.trendRateText(slope: 0.01, direction: .rising)
        #expect(text.contains("0.30/mes"))
    }

    @Test("bmr trend shows rate per month without unit suffix")
    func trendRateTextBmr() {
        let p = TrendChartPresenter(metricKey: .bmr, preferences: .default)
        let text = p.trendRateText(slope: 1.0, direction: .rising)
        #expect(text.contains("+30.0/mes"))
    }
}
