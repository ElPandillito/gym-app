//
//  ThumbnailServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Generates and persists thumbnail images from already-saved originals.
protocol ThumbnailServiceProtocol {

    /// Reads the original at `originalRelativePath`, generates a scaled-down JPEG,
    /// saves it via PhotoStorageService, and returns its relative path.
    func generateThumbnail(
        from originalRelativePath: String,
        photoID: UUID,
        athleteID: UUID,
        checkInID: UUID
    ) throws -> String
}
