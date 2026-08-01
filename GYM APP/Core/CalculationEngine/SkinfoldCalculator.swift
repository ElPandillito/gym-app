//
//  SkinfoldCalculator.swift
//  GYM APP
//

import Foundation

/// Pure-function body composition calculation engine.
/// All skinfold values are in millimeters; age in years; weight in kilograms.
enum SkinfoldCalculator {

    struct Result {
        let bodyDensity: Double          // g/mL
        let bodyFatPercentage: Double    // %
    }

    // MARK: - Public API

    static func calculate(
        method: PlicometryMethod,
        gender: Gender,
        age: Double,
        inputs: SkinfoldInputs,
        bodyWeightKg: Double? = nil
    ) -> Result? {
        switch method {
        case .jacksonPollockThree:  return jp3(gender: gender, age: age, inputs: inputs)
        case .jacksonPollockSeven:  return jp7(gender: gender, age: age, inputs: inputs)
        case .durninWomersley:      return durninWomersley(gender: gender, age: age, inputs: inputs)
        case .parrillo:
            guard let bw = bodyWeightKg, bw > 0 else { return nil }
            return parrillo(inputs: inputs, bodyWeightKg: bw)
        case .custom:
            return nil
        }
    }

    // MARK: - Jackson-Pollock 3

    private static func jp3(gender: Gender, age: Double, inputs: SkinfoldInputs) -> Result? {
        let bd: Double
        switch gender {
        case .male, .other:
            guard let chest   = inputs.chest,
                  let abdomen = inputs.abdomen,
                  let thigh   = inputs.thigh else { return nil }
            let s = chest + abdomen + thigh
            bd = 1.10938 - (0.0008267 * s) + (0.0000016 * s * s) - (0.0002574 * age)
        case .female:
            guard let tricep   = inputs.tricep,
                  let suprailiac = inputs.suprailiac,
                  let thigh   = inputs.thigh else { return nil }
            let s = tricep + suprailiac + thigh
            bd = 1.0994921 - (0.0009929 * s) + (0.0000023 * s * s) - (0.0001392 * age)
        }
        return siri(bodyDensity: bd)
    }

    // MARK: - Jackson-Pollock 7

    private static func jp7(gender: Gender, age: Double, inputs: SkinfoldInputs) -> Result? {
        guard let chest      = inputs.chest,
              let mid        = inputs.midaxillary,
              let tricep     = inputs.tricep,
              let sub        = inputs.subscapular,
              let abdomen    = inputs.abdomen,
              let suprailiac = inputs.suprailiac,
              let thigh      = inputs.thigh else { return nil }

        let s = chest + mid + tricep + sub + abdomen + suprailiac + thigh
        let bd: Double
        switch gender {
        case .male, .other:
            bd = 1.112 - (0.00043499 * s) + (0.00000055 * s * s) - (0.00028826 * age)
        case .female:
            bd = 1.097 - (0.00046971 * s) + (0.00000056 * s * s) - (0.00012828 * age)
        }
        return siri(bodyDensity: bd)
    }

    // MARK: - Durnin-Womersley 4

    private static func durninWomersley(gender: Gender, age: Double, inputs: SkinfoldInputs) -> Result? {
        guard let bicep      = inputs.bicep,
              let tricep     = inputs.tricep,
              let sub        = inputs.subscapular,
              let suprailiac = inputs.suprailiac else { return nil }

        let s = bicep + tricep + sub + suprailiac
        guard s > 0 else { return nil }
        let logS = log10(s)

        // Constants from Durnin & Womersley (1974) table
        struct K { let c: Double; let m: Double }
        let k: K
        let isMale = (gender != .female)
        if isMale {
            if      age < 30 { k = K(c: 1.1631, m: 0.0632) }
            else if age < 40 { k = K(c: 1.1422, m: 0.0544) }
            else if age < 50 { k = K(c: 1.1620, m: 0.0700) }
            else              { k = K(c: 1.1715, m: 0.0779) }
        } else {
            if      age < 30 { k = K(c: 1.1549, m: 0.0678) }
            else if age < 40 { k = K(c: 1.1423, m: 0.0632) }
            else if age < 50 { k = K(c: 1.1333, m: 0.0612) }
            else              { k = K(c: 1.1339, m: 0.0645) }
        }
        let bd = k.c - (k.m * logS)
        return siri(bodyDensity: bd)
    }

    // MARK: - Parrillo 9

    private static func parrillo(inputs: SkinfoldInputs, bodyWeightKg: Double) -> Result? {
        guard let chest      = inputs.chest,
              let abdomen    = inputs.abdomen,
              let thigh      = inputs.thigh,
              let bicep      = inputs.bicep,
              let tricep     = inputs.tricep,
              let sub        = inputs.subscapular,
              let suprailiac = inputs.suprailiac,
              let lower      = inputs.lowerBack,
              let calf       = inputs.calf else { return nil }

        let sum = chest + abdomen + thigh + bicep + tricep + sub + suprailiac + lower + calf
        let bodyWeightLbs = bodyWeightKg * 2.20462
        let fatPct = (sum * 27.0) / bodyWeightLbs
        let clampedFat = min(max(fatPct, 1.0), 60.0)
        // Back-calculate density via Siri so we have a consistent Result shape
        let bd = 495.0 / (clampedFat + 450.0)
        return Result(bodyDensity: bd, bodyFatPercentage: clampedFat)
    }

    // MARK: - Siri (1956): BD → %BF

    private static func siri(bodyDensity bd: Double) -> Result {
        let fat = min(max((495.0 / bd) - 450.0, 1.0), 60.0)
        return Result(bodyDensity: bd, bodyFatPercentage: fat)
    }
}

// MARK: - SkinfoldInputs

/// Lightweight value type holding raw skinfold readings (mm) for the calculator.
struct SkinfoldInputs {
    var chest: Double?
    var midaxillary: Double?
    var tricep: Double?
    var subscapular: Double?
    var abdomen: Double?
    var suprailiac: Double?
    var thigh: Double?
    var calf: Double?
    var bicep: Double?
    var lowerBack: Double?

    init() {}

    init(from m: SkinfoldMeasurements) {
        chest       = m.chest
        midaxillary = m.midaxillary
        tricep      = m.tricep
        subscapular = m.subscapular
        abdomen     = m.abdomen
        suprailiac  = m.suprailiac
        thigh       = m.thigh
        calf        = m.calf
        bicep       = m.bicep
        lowerBack   = m.lowerBack
    }
}
