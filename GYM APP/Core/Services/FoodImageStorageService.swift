//
//  FoodImageStorageService.swift
//  GYM APP
//

import Foundation
import ImageIO
import CoreGraphics

/// Manages food image files on disk, following the same conventions as PhotoStorageService.
/// Thumbnail generation (300 px, 0.8 JPEG quality) uses CoreGraphics — no UIKit dependency.
/// In-memory caching is shared via PhotoImageCache.shared.
struct FoodImageStorageService: FoodImageStorageServiceProtocol {

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Save

    func saveOriginal(data: Data, foodID: UUID) throws -> String {
        let dir = originalDirectory(foodID: foodID)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("image.jpg")
        try data.write(to: file, options: .atomic)
        return relativePath(for: file)
    }

    func saveThumbnail(data: Data, foodID: UUID) throws -> String {
        let dir = thumbnailDirectory(foodID: foodID)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("image.jpg")
        try data.write(to: file, options: .atomic)
        return relativePath(for: file)
    }

    // MARK: - Thumbnail generation

    func generateAndSaveThumbnail(from originalRelativePath: String, foodID: UUID) throws -> String {
        let originalURL = absoluteURL(for: originalRelativePath)

        guard let source = CGImageSourceCreateWithURL(originalURL as CFURL, nil) else {
            throw FoodImageError.sourceCreationFailed
        }

        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: 300,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw FoodImageError.thumbnailGenerationFailed
        }

        let buffer = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            buffer, "public.jpeg" as CFString, 1, nil
        ) else {
            throw FoodImageError.encodingFailed
        }
        let encodeOptions: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.8]
        CGImageDestinationAddImage(destination, cgThumb, encodeOptions as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw FoodImageError.encodingFailed
        }

        return try saveThumbnail(data: buffer as Data, foodID: foodID)
    }

    // MARK: - Read

    func absoluteURL(for relativePath: String) -> URL {
        documentsURL.appendingPathComponent(relativePath)
    }

    func loadData(for relativePath: String) throws -> Data {
        try Data(contentsOf: absoluteURL(for: relativePath))
    }

    // MARK: - Delete

    func delete(relativePath: String) throws {
        let url = absoluteURL(for: relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    func deleteFoodDirectory(foodID: UUID) throws {
        let dir = foodDirectory(foodID: foodID)
        guard fileManager.fileExists(atPath: dir.path) else { return }
        try fileManager.removeItem(at: dir)
    }

    // MARK: - Path helpers

    private func foodDirectory(foodID: UUID) -> URL {
        documentsURL
            .appendingPathComponent("Foods")
            .appendingPathComponent(foodID.uuidString)
    }

    private func originalDirectory(foodID: UUID) -> URL {
        foodDirectory(foodID: foodID).appendingPathComponent("original")
    }

    private func thumbnailDirectory(foodID: UUID) -> URL {
        foodDirectory(foodID: foodID).appendingPathComponent("thumbnail")
    }

    private func relativePath(for absolute: URL) -> String {
        let docPath  = documentsURL.standardizedFileURL.path
        let filePath = absolute.standardizedFileURL.path
        guard filePath.hasPrefix(docPath) else { return filePath }
        let rel = String(filePath.dropFirst(docPath.count))
        return rel.hasPrefix("/") ? String(rel.dropFirst()) : rel
    }
}

// MARK: - Errors

enum FoodImageError: LocalizedError {
    case sourceCreationFailed
    case thumbnailGenerationFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .sourceCreationFailed:      return "No se pudo leer la imagen del alimento."
        case .thumbnailGenerationFailed: return "No se pudo generar el thumbnail."
        case .encodingFailed:            return "No se pudo codificar el thumbnail."
        }
    }
}
