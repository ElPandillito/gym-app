//
//  ThumbnailService.swift
//  GYM APP
//

import Foundation
import ImageIO
import CoreGraphics

struct ThumbnailService: ThumbnailServiceProtocol {

    /// Maximum dimension (width or height) of a generated thumbnail in pixels.
    static let maxDimension = 300

    private let storage: PhotoStorageServiceProtocol

    init(storage: PhotoStorageServiceProtocol) {
        self.storage = storage
    }

    func generateThumbnail(
        from originalRelativePath: String,
        photoID: UUID,
        athleteID: UUID,
        checkInID: UUID
    ) throws -> String {
        let originalURL = storage.absoluteURL(for: originalRelativePath)

        guard let source = CGImageSourceCreateWithURL(originalURL as CFURL, nil) else {
            throw ThumbnailError.sourceCreationFailed
        }

        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: Self.maxDimension,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true  // Respect EXIF orientation
        ]

        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ThumbnailError.thumbnailGenerationFailed
        }

        let buffer = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            buffer,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            throw ThumbnailError.encodingFailed
        }

        let encodeOptions: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.8]
        CGImageDestinationAddImage(destination, cgThumb, encodeOptions as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ThumbnailError.encodingFailed
        }

        return try storage.saveThumbnail(
            data: buffer as Data,
            athleteID: athleteID,
            checkInID: checkInID,
            photoID: photoID
        )
    }
}

// MARK: - Errors

enum ThumbnailError: LocalizedError {
    case sourceCreationFailed
    case thumbnailGenerationFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .sourceCreationFailed:      return "No se pudo leer la imagen original."
        case .thumbnailGenerationFailed: return "No se pudo generar el thumbnail."
        case .encodingFailed:            return "No se pudo codificar el thumbnail."
        }
    }
}
