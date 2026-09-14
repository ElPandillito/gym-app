//
//  AIBodyFatAssessmentRepository.swift
//  GYM APP
//

import SwiftData

struct AIBodyFatAssessmentRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Persists a new assessment, replacing any previous assessment for this check-in.
    func save(_ assessment: AIBodyFatAssessment, for checkIn: CheckIn) throws {
        // Remove any previous assessment for this check-in
        if let existing = checkIn.aiBodyFatAssessment {
            context.delete(existing)
        }
        assessment.checkIn = checkIn
        context.insert(assessment)
        try context.save()
    }
}
