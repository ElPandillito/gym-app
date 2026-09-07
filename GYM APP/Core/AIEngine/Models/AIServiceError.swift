//
//  AIServiceError.swift
//  GYM APP
//

import Foundation

/// Domain-safe error type for all AI service contracts.
/// Never wraps provider-specific errors or raw NSError values.
enum AIServiceError: Error, Sendable, Equatable {
    /// The input data does not have enough points to produce a meaningful result.
    case insufficientData
    /// The service or provider is not yet available in this build.
    case unavailable
    /// The caller supplied an argument that violates the contract.
    case invalidInput(String)
    /// An unexpected internal failure occurred in the service layer.
    case serviceFailure

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.insufficientData, .insufficientData): return true
        case (.unavailable, .unavailable):           return true
        case (.serviceFailure, .serviceFailure):     return true
        case (.invalidInput(let a), .invalidInput(let b)): return a == b
        default: return false
        }
    }
}
