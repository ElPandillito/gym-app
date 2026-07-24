//
//  ValidationResult.swift
//  GYM APP
//

import Foundation

// MARK: - ValidationResult

enum ValidationResult: Equatable {
    case valid
    case invalid(reason: String, severity: ValidationSeverity)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var isInvalid: Bool { !isValid }

    var reason: String? {
        if case .invalid(let r, _) = self { return r }
        return nil
    }

    var severity: ValidationSeverity? {
        if case .invalid(_, let s) = self { return s }
        return nil
    }
}

// MARK: - ValidationSeverity

enum ValidationSeverity: Equatable {
    case error      // Blocks saving
    case warning    // Informational; does not block saving
}

// MARK: - ValidationRule

/// Strategy pattern: each rule encapsulates one validation concern.
protocol ValidationRule {
    associatedtype Value
    func validate(_ value: Value) -> ValidationResult
}

// MARK: - ValidationReport

/// Collects multiple results from a composite validation pass.
struct ValidationReport {
    let results: [ValidationResult]

    var isValid: Bool { results.allSatisfy { $0.isValid } }
    var hasWarnings: Bool { results.contains { $0.severity == .warning } }
    var errors: [String] { results.compactMap { r in r.severity == .error ? r.reason : nil } }
    var warnings: [String] { results.compactMap { r in r.severity == .warning ? r.reason : nil } }

    static func collect(@ValidationResultBuilder _ build: () -> [ValidationResult]) -> ValidationReport {
        ValidationReport(results: build())
    }
}

// MARK: - Result Builder

@resultBuilder
enum ValidationResultBuilder {
    static func buildBlock(_ components: ValidationResult...) -> [ValidationResult] { components }
    static func buildOptional(_ component: [ValidationResult]?) -> [ValidationResult] { component ?? [] }
    static func buildArray(_ components: [[ValidationResult]]) -> [ValidationResult] { components.flatMap { $0 } }
}
