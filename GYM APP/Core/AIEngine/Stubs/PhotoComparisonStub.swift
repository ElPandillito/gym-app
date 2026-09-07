//
//  PhotoComparisonStub.swift
//  GYM APP
//
//  Returns neutral zero-score result — computer vision infrastructure not yet available.
//  Safe for previews and tests.
//

import Foundation

struct PhotoComparisonStub: PhotoComparisonServiceProtocol {
    func compare(
        beforePhotoPath: String,
        afterPhotoPath: String
    ) async throws -> PhotoComparisonResult {
        PhotoComparisonResult(
            overallChangeScore:  0.0,
            detectedChanges:     [],
            highlightedRegions:  [],
            summary:             nil
        )
    }
}
