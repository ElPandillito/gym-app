//
//  BodySymmetryStub.swift
//  GYM APP
//
//  Returns zero-score result — computer vision infrastructure not yet available.
//  Safe for previews and tests.
//

import Foundation

struct BodySymmetryStub: BodySymmetryServiceProtocol {
    func analyzeSymmetry(
        leftPhotoPath: String,
        rightPhotoPath: String
    ) async throws -> SymmetryAnalysisResult {
        SymmetryAnalysisResult(overallScore: 0.0, imbalances: [])
    }
}
