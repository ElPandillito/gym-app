//
//  RequiredStringRule.swift
//  GYM APP
//

import Foundation

/// Validates that a string is non-empty after trimming whitespace.
struct RequiredStringRule: ValidationRule {
    let fieldName: String
    let maxLength: Int?

    init(fieldName: String, maxLength: Int? = nil) {
        self.fieldName = fieldName
        self.maxLength = maxLength
    }

    func validate(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return .invalid(reason: "\(fieldName) es obligatorio.", severity: .error)
        }
        if let max = maxLength, trimmed.count > max {
            return .invalid(reason: "\(fieldName) no puede exceder \(max) caracteres.", severity: .error)
        }
        return .valid
    }
}
