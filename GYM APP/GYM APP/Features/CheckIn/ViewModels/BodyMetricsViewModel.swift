//
//  BodyMetricsViewModel.swift
//  GYM APP
//

import SwiftUI

@Observable
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

    private let existingMetrics: BodyMetrics?
    private let athleteHeight: Double?      // centimeters

    var isEditing: Bool { existingMetrics != nil }

    var canSave: Bool { weightText.asPositiveDouble != nil }

    // BMI auto-calculated from weight + athlete height; never entered manually
    var bmi: Double? {
        guard let weight = weightText.asPositiveDouble,
              let hcm = athleteHeight, hcm > 0 else { return nil }
        let hm = hcm / 100.0
        return weight / (hm * hm)
    }

    var bmiFormatted: String {
        guard let b = bmi else { return "—" }
        return String(format: "%.1f", b)
    }

    var heightFormatted: String {
        guard let h = athleteHeight else { return "No configurada" }
        return String(format: "%.1f cm", h)
    }

    init(metrics: BodyMetrics? = nil, athleteHeight: Double? = nil) {
        self.existingMetrics = metrics
        self.athleteHeight   = athleteHeight

        guard let m = metrics else { return }
        weightText             = m.bodyWeight.map          { String(format: "%.2f", $0) } ?? ""
        fatPercentageText      = m.bodyFatPercentage.map   { String(format: "%.1f", $0) } ?? ""
        muscleMassText         = m.muscleMass.map          { String(format: "%.2f", $0) } ?? ""
        boneMassText           = m.boneMass.map            { String(format: "%.2f", $0) } ?? ""
        waterPercentageText    = m.waterPercentage.map     { String(format: "%.1f", $0) } ?? ""
        visceralFatText        = m.visceralFatLevel.map    { String(format: "%.0f", $0) } ?? ""
        basalMetabolicRateText = m.basalMetabolicRate.map  { String(format: "%.0f", $0) } ?? ""
    }

    // Returns true on success. Creates a new BodyMetrics if none exists yet.
    func save(for checkIn: CheckIn, using repository: BodyMetricsRepository) -> Bool {
        guard canSave else { return false }
        let metrics = existingMetrics ?? BodyMetrics()

        metrics.bodyWeight         = weightText.asPositiveDouble
        metrics.bmi                = bmi
        metrics.bodyFatPercentage  = fatPercentageText.asPositiveDouble
        metrics.muscleMass         = muscleMassText.asPositiveDouble
        metrics.boneMass           = boneMassText.asPositiveDouble
        metrics.waterPercentage    = waterPercentageText.asPositiveDouble
        metrics.visceralFatLevel   = visceralFatText.asPositiveDouble
        metrics.basalMetabolicRate = basalMetabolicRateText.asPositiveDouble

        try? repository.save(metrics, for: checkIn)
        return true
    }
}
