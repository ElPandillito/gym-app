//
//  BodyFatAssessmentServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Contract for estimating body fat percentage from progress photos and available context.
///
/// Implementations may range from deterministic rule-based stubs (no vision) to
/// CoreML / Vision framework models or multimodal LLMs. The `assessmentBasis`
/// field on the result always communicates which approach was used.
protocol BodyFatAssessmentServiceProtocol {
    /// Estimates body fat percentage using available photo paths and anthropometric context.
    /// - Parameter photos: One or more photo path entries from a single check-in.
    /// - Parameter context: Anthropometric data for cross-validation or proxy estimation.
    /// - Returns: A `BodyFatAssessmentResult` with estimate, confidence, and provenance.
    /// - Throws: `AIServiceError.insufficientData` when neither photos nor context provide
    ///   enough signal. `AIServiceError.invalidInput` for out-of-range values.
    func estimate(
        photos: [PhotoPathEntry],
        context: BodyFatAssessmentContext
    ) async throws -> BodyFatAssessmentResult
}

// MARK: - Input types

/// A single photo identified by its relative path and pose type.
struct PhotoPathEntry: Sendable {
    let relativePath: String
    let poseType: PoseType
}

/// Anthropometric data available for the check-in being assessed.
/// All fields are optional — the service should degrade gracefully with less data.
struct BodyFatAssessmentContext: Sendable {
    /// Body weight in canonical kg.
    let bodyWeightKg: Double?
    /// Athlete height in canonical cm.
    let heightCm: Double?
    /// Body fat % measured by bioimpedance scale (from BodyMetrics).
    let bioimpedanceBodyFatPct: Double?
    /// Body fat % measured by skinfold plicometry.
    let skinfoldBodyFatPct: Double?
    /// Waist circumference in canonical cm.
    let waistCm: Double?
    /// Hip circumference in canonical cm.
    let hipCm: Double?
    /// Neck circumference in canonical cm (optional, improves Navy formula accuracy).
    let neckCm: Double?
    let gender: Gender?
    /// Athlete age in years (used for Deurenberg BMI-based BF% formula).
    let ageYears: Double?
}

// MARK: - Result types

struct BodyFatAssessmentResult: Sendable {
    /// Estimated body fat percentage (0–60 %).
    let estimatedBodyFatPct: Double
    /// Confidence in the estimate [0–1]. Stubs are always capped at 0.55.
    let confidenceScore: Double
    /// How the estimate was derived.
    let assessmentBasis: AssessmentBasis
    /// Human-readable explanations of the signals used.
    let notes: [String]
    let generatedAt: Date
}

/// Describes how the body fat estimate was produced — always persisted for traceability.
enum AssessmentBasis: String, Sendable, Codable {
    /// Pure vision analysis from photo data (e.g. CoreML, multimodal LLM). Not yet implemented.
    case visionOnly
    /// Vision analysis cross-validated with anthropometric measurements.
    case visionWithContext
    /// Rule-based estimate from anthropometric data (no actual vision). Used by all current stubs.
    case stubDeterministic
}
