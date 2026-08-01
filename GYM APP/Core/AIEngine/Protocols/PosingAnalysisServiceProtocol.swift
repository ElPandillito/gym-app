//
//  PosingAnalysisServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Contract for future posing analysis (CoreML / FoundationModels / API).
protocol PosingAnalysisServiceProtocol {
    /// Analyzes a single photo identified by its relative path.
    /// Returns a confidence score [0–1] and detected pose type.
    func analyzePose(photoPath: String) async throws -> PoseAnalysisResult
}

struct PoseAnalysisResult: Sendable {
    let detectedPose: PoseType?
    let confidence: Double          // 0.0 – 1.0
    let symmetryScore: Double?      // 0.0 – 1.0
    let notes: [String]
}
