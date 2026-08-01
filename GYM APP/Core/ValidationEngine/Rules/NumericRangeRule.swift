//
//  NumericRangeRule.swift
//  GYM APP
//

import Foundation

/// Validates that a numeric value falls within [min, max].
struct NumericRangeRule: ValidationRule {
    let min: Double
    let max: Double
    let fieldName: String
    let severity: ValidationSeverity

    init(min: Double, max: Double, fieldName: String, severity: ValidationSeverity = .error) {
        self.min       = min
        self.max       = max
        self.fieldName = fieldName
        self.severity  = severity
    }

    func validate(_ value: Double) -> ValidationResult {
        guard value >= min, value <= max else {
            return .invalid(
                reason: "\(fieldName) debe estar entre \(formatted(min)) y \(formatted(max)).",
                severity: severity
            )
        }
        return .valid
    }

    private func formatted(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v)
            : String(format: "%.1f", v)
    }
}

/// Validates an optional Double — returns .valid when nil (field not filled in).
struct OptionalNumericRangeRule: ValidationRule {
    private let inner: NumericRangeRule

    init(min: Double, max: Double, fieldName: String, severity: ValidationSeverity = .error) {
        inner = NumericRangeRule(min: min, max: max, fieldName: fieldName, severity: severity)
    }

    func validate(_ value: Double?) -> ValidationResult {
        guard let v = value else { return .valid }
        return inner.validate(v)
    }
}
