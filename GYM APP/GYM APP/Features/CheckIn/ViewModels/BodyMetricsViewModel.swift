//
//  BodyMetricsViewModel.swift
//  GYM APP
//

import SwiftUI

@MainActor @Observable
final class BodyMetricsViewModel {

    // Required
    var weightText: String = ""

    // Optional fields
    var fatPercentageText: String      = ""
    var muscleMassText: String         = ""
    var boneMassText: String           = ""
    var waterPercentageText: String    = ""
    var visceralFatText: String        = ""
    var basalMetabolicRateText: String = ""

    // ISAK base measurements (Level 1 + 2) — always canonical cm
    var sittingHeightText: String = ""
    var armSpanText: String       = ""

    private let existingMetrics: BodyMetrics?
    private let athleteHeight: Double?      // centimeters
    private var preferences: CoachPreferences = .default

    var isEditing: Bool { existingMetrics != nil }

    var canSave: Bool { weightText.asPositiveDouble != nil }

    // BMI auto-calculated from weight + athlete height.
    // weightText is in display units; convert to canonical kg for the formula.
    var bmi: Double? {
        guard let displayWeight = weightText.asPositiveDouble,
              let hcm = athleteHeight, hcm > 0 else { return nil }
        let fmt = AppUnitFormatter(preferences: preferences)
        let canonicalKg = fmt.toCanonicalWeight(displayWeight)
        let hm = hcm / 100.0
        return canonicalKg / (hm * hm)
    }

    var bmiFormatted: String {
        guard let b = bmi else { return "—" }
        return String(format: "%.1f", b)
    }

    var heightFormatted: String {
        guard let h = athleteHeight else { return "No configurada" }
        return AppUnitFormatter(preferences: preferences).height(h)
    }

    init(metrics: BodyMetrics? = nil, athleteHeight: Double? = nil) {
        self.existingMetrics = metrics
        self.athleteHeight   = athleteHeight

        guard let m = metrics else { return }
        // Initialize with canonical values; apply(preferences:) will re-format to display units.
        weightText             = m.bodyWeight.map          { String(format: "%.2f", $0) } ?? ""
        fatPercentageText      = m.bodyFatPercentage.map   { String(format: "%.1f", $0) } ?? ""
        muscleMassText         = m.muscleMass.map          { String(format: "%.2f", $0) } ?? ""
        boneMassText           = m.boneMass.map            { String(format: "%.2f", $0) } ?? ""
        waterPercentageText    = m.waterPercentage.map     { String(format: "%.1f", $0) } ?? ""
        visceralFatText        = m.visceralFatLevel.map    { String(format: "%.0f", $0) } ?? ""
        basalMetabolicRateText = m.basalMetabolicRate.map  { String(format: "%.0f", $0) } ?? ""
        sittingHeightText      = m.sittingHeight.map       { String(format: "%.1f", $0) } ?? ""
        armSpanText            = m.armSpan.map             { String(format: "%.1f", $0) } ?? ""
    }

    // MARK: - Apply preferences (call once from onAppear)

    /// Stores preferences and re-formats weight/mass text fields from canonical to display units.
    /// For new check-ins (no existing metrics) this only stores preferences for use at save time.
    func apply(preferences: CoachPreferences) {
        self.preferences = preferences
        guard let m = existingMetrics else { return }
        let fmt = AppUnitFormatter(preferences: preferences)
        weightText     = m.bodyWeight.map { String(format: "%.2f", fmt.convertedWeight($0)) } ?? ""
        muscleMassText = m.muscleMass.map { String(format: "%.2f", fmt.convertedWeight($0)) } ?? ""
        boneMassText   = m.boneMass.map   { String(format: "%.2f", fmt.convertedWeight($0)) } ?? ""
    }

    // MARK: - Save (standalone form — commits immediately)

    @discardableResult
    func save(for checkIn: CheckIn, using repository: BodyMetricsRepository) throws -> Bool {
        guard canSave else { return false }
        let metrics = existingMetrics ?? BodyMetrics()
        applyFields(to: metrics)
        try repository.save(metrics, for: checkIn)
        return true
    }

    // MARK: - Insert-only (workflow creation path — no commit)

    @discardableResult
    func insertRecord(for checkIn: CheckIn, using repository: BodyMetricsRepository) -> Bool {
        guard canSave else { return false }
        let metrics = existingMetrics ?? BodyMetrics()
        applyFields(to: metrics)
        repository.insertNew(metrics, for: checkIn)
        return true
    }

    // MARK: - Helpers

    private func applyFields(to metrics: BodyMetrics) {
        let fmt = AppUnitFormatter(preferences: preferences)
        metrics.bodyWeight         = weightText.asPositiveDouble.map        { fmt.toCanonicalWeight($0) }
        metrics.bmi                = bmi
        metrics.bodyFatPercentage  = fatPercentageText.asPositiveDouble
        metrics.muscleMass         = muscleMassText.asPositiveDouble.map    { fmt.toCanonicalWeight($0) }
        metrics.boneMass           = boneMassText.asPositiveDouble.map      { fmt.toCanonicalWeight($0) }
        metrics.waterPercentage    = waterPercentageText.asPositiveDouble
        metrics.visceralFatLevel   = visceralFatText.asPositiveDouble
        metrics.basalMetabolicRate = basalMetabolicRateText.asPositiveDouble
        metrics.sittingHeight      = sittingHeightText.asPositiveDouble     // ISAK — always cm
        metrics.armSpan            = armSpanText.asPositiveDouble            // ISAK — always cm
    }
}
