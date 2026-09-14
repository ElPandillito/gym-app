//
//  PosingAnalysisStub.swift
//  GYM APP
//
//  Returns empty/zero results — computer vision infrastructure not yet available.
//  Safe for previews and tests; never throws so callers can render gracefully.
//

import Foundation

struct PosingAnalysisStub: PosingAnalysisServiceProtocol {
    func analyzePose(photoPath: String) async throws -> PoseAnalysisResult {
        PoseAnalysisResult(
            detectedPose:   nil,
            confidence:     0.0,
            symmetryScore: nil,
            notes:          []
        )
    }
}
