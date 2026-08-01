//
//  DateRule.swift
//  GYM APP
//

import Foundation

/// Validates that a date is not in the future.
struct NotFutureDateRule: ValidationRule {
    let fieldName: String

    func validate(_ value: Date) -> ValidationResult {
        guard value <= Date() else {
            return .invalid(reason: "\(fieldName) no puede ser una fecha futura.", severity: .error)
        }
        return .valid
    }
}

/// Validates that a date is within a given closed range.
struct DateRangeRule: ValidationRule {
    let from: Date
    let to: Date
    let fieldName: String

    func validate(_ value: Date) -> ValidationResult {
        guard value >= from, value <= to else {
            return .invalid(reason: "\(fieldName) está fuera del rango permitido.", severity: .error)
        }
        return .valid
    }
}

/// Validates that a birth date implies a reasonable age.
struct BirthDateRule: ValidationRule {
    func validate(_ value: Date) -> ValidationResult {
        let age = Calendar.current.dateComponents([.year], from: value, to: Date()).year ?? 0
        if age < Int(PhysiologicalRanges.Age.min) {
            return .invalid(reason: "La edad mínima es \(Int(PhysiologicalRanges.Age.min)) años.", severity: .error)
        }
        if age > Int(PhysiologicalRanges.Age.max) {
            return .invalid(reason: "La edad máxima es \(Int(PhysiologicalRanges.Age.max)) años.", severity: .error)
        }
        return NotFutureDateRule(fieldName: "Fecha de nacimiento").validate(value)
    }
}
