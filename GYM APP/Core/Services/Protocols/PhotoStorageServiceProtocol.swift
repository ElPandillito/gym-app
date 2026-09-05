//
//  PhotoStorageServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Handles all FileManager interactions for progress photos.
/// SwiftData stores only the relative paths returned by this service.
///
/// Directory layout (relative to Documents/):
///   Athletes/{athleteID}/CheckIns/{checkInID}/original/{photoID}.jpg
///   Athletes/{athleteID}/CheckIns/{checkInID}/thumbnail/{photoID}.jpg
protocol PhotoStorageServiceProtocol {

    /// Persists raw image data as the original. Returns the relative path from Documents/.
    func saveOriginal(data: Data, athleteID: UUID, checkInID: UUID, photoID: UUID) throws -> String

    /// Persists thumbnail data. Returns the relative path from Documents/.
    func saveThumbnail(data: Data, athleteID: UUID, checkInID: UUID, photoID: UUID) throws -> String

    /// Converts a stored relative path to its absolute URL on disk.
    func absoluteURL(for relativePath: String) -> URL

    /// Loads raw bytes for the file at the given relative path.
    func loadData(for relativePath: String) throws -> Data

    /// Deletes a single file by its relative path. No-op if the file is absent.
    func delete(relativePath: String) throws

    /// Removes the entire CheckIn folder (original/ + thumbnail/) recursively.
    func deleteCheckInDirectory(athleteID: UUID, checkInID: UUID) throws

    /// Deletes any file inside original/ and thumbnail/ whose UUID stem is NOT in `keepingIDs`.
    func deleteOrphans(athleteID: UUID, checkInID: UUID, keepingIDs: Set<UUID>) throws

    /// Global orphan sweep: enumerates every .jpg file under the Athletes/ root and
    /// deletes any whose relative path is NOT in `knownRelativePaths`.
    ///
    /// Safety contract:
    ///   - Only deletes files within the Athletes/ subdirectory of Documents/.
    ///   - Only deletes .jpg files; directories and other file types are never touched.
    ///   - A file whose path IS in `knownRelativePaths` is always preserved.
    ///   - Individual removal errors are swallowed; the sweep continues for other files.
    ///
    /// Returns the count of successfully removed files.
    @discardableResult
    func sweepOrphanFiles(knownRelativePaths: Set<String>) -> Int
}
