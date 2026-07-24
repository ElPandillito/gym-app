//
//  AthleteValidator.swift
//  GYM APP
//

import Foundation

/// Facade that centralizes all Athlete field validations.
enum AthleteValidator {

    static func validateName(_ name: String) -> ValidationResult {
        RequiredStringRule(fieldName: "Nombre", maxLength: 100).validate(name)
    }

    static func validateHeight(_ cm: Double?) -> ValidationResult {
        OptionalNumericRangeRule(
            min: PhysiologicalRanges.Height.min,
            max: PhysiologicalRanges.Height.max,
            fieldName: "Estatura"
        ).validate(cm)
    }

    static func validateBirthDate(_ date: Date?) -> ValidationResult {
        guard let date else { return .valid }
        return BirthDateRule().validate(date)
    }

    static func validate(name: String, heightCm: Double?, birthDate: Date?) -> ValidationReport {
        ValidationReport.collect {
            validateName(name)
            validateHeight(heightCm)
            validateBirthDate(birthDate)
        }
    }
}
