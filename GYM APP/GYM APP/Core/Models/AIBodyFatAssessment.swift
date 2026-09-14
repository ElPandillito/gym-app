//
//  AIBodyFatAssessment.swift
//  GYM APP
//

import SwiftData
import Foundation

@Model
final class AIBodyFatAssessment {
    @Attribute(.unique) var id: UUID

    /// Estimated body fat percentage (0–60 %).
    var estimatedBodyFatPct: Double

    /// Confidence score [0–1] from the service that produced this assessment.
    var confidenceScore: Double

    /// Raw value of `AssessmentBasis` — never expose the enum directly in SwiftData models
    /// to avoid migration pain if enum cases change.
    var assessmentBasisRaw: String

    /// JSON-encoded array of human-readable note strings.
    var notesJSON: String

    /// Number of photos that were passed to the service.
    var photoCount: Int

    var generatedAt: Date
    var createdAt: Date

    // Parent (cascade delete handled by CheckIn)
    var checkIn: CheckIn?

    init(
        estimatedBodyFatPct: Double,
        confidenceScore: Double,
        assessmentBasis: AssessmentBasis,
        notes: [String],
        photoCount: Int,
        generatedAt: Date
    ) {
        self.id                  = UUID()
        self.estimatedBodyFatPct = estimatedBodyFatPct
        self.confidenceScore     = confidenceScore
        self.assessmentBasisRaw  = assessmentBasis.rawValue
        self.notesJSON           = (try? String(data: JSONEncoder().encode(notes), encoding: .utf8)) ?? "[]"
        self.photoCount          = photoCount
        self.generatedAt         = generatedAt
        self.createdAt           = Date()
    }

    /// Decoded notes array.
    var notes: [String] {
        guard let data = notesJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return decoded
    }

    /// Decoded assessment basis.
    var assessmentBasis: AssessmentBasis {
        AssessmentBasis(rawValue: assessmentBasisRaw) ?? .stubDeterministic
    }
}
