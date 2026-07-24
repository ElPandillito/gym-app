//
//  BodySymmetryServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Contract for body symmetry analysis between left/right sides.
protocol BodySymmetryServiceProtocol {
    func analyzeSymmetry(
        leftPhotoPath: String,
        rightPhotoPath: String
    ) async throws -> SymmetryAnalysisResult
}

struct SymmetryAnalysisResult: Sendable {
    let overallScore: Double        // 0.0 – 1.0
    let imbalances: [SymmetryImbalance]
}

struct SymmetryImbalance: Sendable {
    let region: String
    let deviation: Double           // % difference
    let recommendation: String?
}
