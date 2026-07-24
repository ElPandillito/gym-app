//
//  BodyMetricsValidator.swift
//  GYM APP
//

import Foundation

/// Facade for all BodyMetrics field validations.
enum BodyMetricsValidator {

    static func validateWeight(_ kg: Double?) -> ValidationResult {
        guard let kg else { return .invalid(reason: "El peso corporal es obligatorio.", severity: .error) }
        return NumericRangeRule(
            min: PhysiologicalRanges.Weight.min,
            max: PhysiologicalRanges.Weight.max,
            fieldName: "Peso corporal"
        ).validate(kg)
    }

    static func validateBodyFat(_ pct: Double?) -> ValidationResult {
        OptionalNumericRangeRule(
            min: PhysiologicalRanges.BodyFat.min,
            max: PhysiologicalRanges.BodyFat.max,
            fieldName: "% Grasa corporal"
        ).validate(pct)
    }

    static func validateMuscleMass(_ kg: Double?) -> ValidationResult {
        OptionalNumericRangeRule(
            min: PhysiologicalRanges.MuscleMass.min,
            max: PhysiologicalRanges.MuscleMass.max,
            fieldName: "Masa muscular"
        ).validate(kg)
    }

    static func validateBoneMass(_ kg: Double?) -> ValidationResult {
        OptionalNumericRangeRule(
            min: PhysiologicalRanges.BoneMass.min,
            max: PhysiologicalRanges.BoneMass.max,
            fieldName: "Masa ósea"
        ).validate(kg)
    }

    static func validateWater(_ pct: Double?) -> ValidationResult {
        OptionalNumericRangeRule(
            min: PhysiologicalRanges.WaterPercentage.min,
            max: PhysiologicalRanges.WaterPercentage.max,
            fieldName: "Agua corporal"
        ).validate(pct)
    }

    static func validateVisceralFat(_ level: Double?) -> ValidationResult {
        OptionalNumericRangeRule(
            min: PhysiologicalRanges.VisceralFat.min,
            max: PhysiologicalRanges.VisceralFat.max,
            fieldName: "Grasa visceral"
        ).validate(level)
    }

    static func validateBMR(_ kcal: Double?) -> ValidationResult {
        OptionalNumericRangeRule(
            min: PhysiologicalRanges.BasalMetabolicRate.min,
            max: PhysiologicalRanges.BasalMetabolicRate.max,
            fieldName: "TMB"
        ).validate(kcal)
    }

    static func validate(
        weight: Double?,
        bodyFat: Double?,
        muscleMass: Double?,
        boneMass: Double?,
        water: Double?,
        visceralFat: Double?,
        bmr: Double?
    ) -> ValidationReport {
        ValidationReport.collect {
            validateWeight(weight)
            validateBodyFat(bodyFat)
            validateMuscleMass(muscleMass)
            validateBoneMass(boneMass)
            validateWater(water)
            validateVisceralFat(visceralFat)
            validateBMR(bmr)
        }
    }
}
