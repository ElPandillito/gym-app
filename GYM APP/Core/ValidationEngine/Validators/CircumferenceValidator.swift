//
//  CircumferenceValidator.swift
//  GYM APP
//

import Foundation

/// Facade for circumference measurement validations.
enum CircumferenceValidator {

    static func validateSite(_ cm: Double?, name: String) -> ValidationResult {
        OptionalNumericRangeRule(
            min: PhysiologicalRanges.Circumference.min,
            max: PhysiologicalRanges.Circumference.max,
            fieldName: name
        ).validate(cm)
    }

    static func validateAll(
        neck: Double?, shoulders: Double?, chest: Double?,
        rightArm: Double?, leftArm: Double?,
        rightForearm: Double?, leftForearm: Double?,
        waist: Double?, abdomen: Double?, hips: Double?,
        rightThigh: Double?, leftThigh: Double?,
        rightCalf: Double?, leftCalf: Double?
    ) -> ValidationReport {
        let sites: [(Double?, String)] = [
            (neck, "Cuello"), (shoulders, "Hombros"), (chest, "Pecho"),
            (rightArm, "Brazo derecho"), (leftArm, "Brazo izquierdo"),
            (rightForearm, "Antebrazo derecho"), (leftForearm, "Antebrazo izquierdo"),
            (waist, "Cintura"), (abdomen, "Abdomen"), (hips, "Cadera"),
            (rightThigh, "Muslo derecho"), (leftThigh, "Muslo izquierdo"),
            (rightCalf, "Pantorrilla derecha"), (leftCalf, "Pantorrilla izquierda")
        ]
        let results = sites.map { validateSite($0.0, name: $0.1) }
        let hasAny = sites.contains { $0.0 != nil }
        if !hasAny {
            return ValidationReport(results: [.invalid(reason: "Ingresa al menos una medida.", severity: .error)])
        }
        return ValidationReport(results: results)
    }
}
