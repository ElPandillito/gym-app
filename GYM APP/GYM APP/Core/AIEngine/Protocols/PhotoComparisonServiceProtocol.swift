//
//  PhotoComparisonServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Contract for automatic visual comparison between two progress photos.
protocol PhotoComparisonServiceProtocol {
    func compare(
        beforePhotoPath: String,
        afterPhotoPath: String
    ) async throws -> PhotoComparisonResult
}

struct PhotoComparisonResult: Sendable {
    let overallChangeScore: Double      // -1 (worse) to +1 (better)
    let detectedChanges: [String]
    let highlightedRegions: [String]    // Identifiers for UI overlays
    let summary: String?
}
