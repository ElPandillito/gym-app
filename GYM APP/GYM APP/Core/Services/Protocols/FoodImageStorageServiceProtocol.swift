//
//  FoodImageStorageServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Handles all FileManager interactions for food images.
/// SwiftData stores only the relative paths returned by this service.
///
/// Directory layout (relative to Documents/):
///   Foods/{foodID}/original/image.jpg
///   Foods/{foodID}/thumbnail/image.jpg
protocol FoodImageStorageServiceProtocol {

    /// Persists raw image data as the original. Returns the relative path from Documents/.
    func saveOriginal(data: Data, foodID: UUID) throws -> String

    /// Persists thumbnail data. Returns the relative path from Documents/.
    func saveThumbnail(data: Data, foodID: UUID) throws -> String

    /// Reads the original at `originalRelativePath`, generates a 300 px thumbnail,
    /// persists it, and returns its relative path.
    func generateAndSaveThumbnail(from originalRelativePath: String, foodID: UUID) throws -> String

    /// Converts a stored relative path to its absolute URL on disk.
    func absoluteURL(for relativePath: String) -> URL

    /// Loads raw bytes for the file at the given relative path.
    func loadData(for relativePath: String) throws -> Data

    /// Deletes a single file by its relative path. No-op if the file is absent.
    func delete(relativePath: String) throws

    /// Removes the entire Foods/{foodID}/ directory recursively.
    func deleteFoodDirectory(foodID: UUID) throws
}
