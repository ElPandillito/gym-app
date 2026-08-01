//
//  PhotoStorageService.swift
//  GYM APP
//

import Foundation

struct PhotoStorageService: PhotoStorageServiceProtocol {

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Save

    func saveOriginal(data: Data, athleteID: UUID, checkInID: UUID, photoID: UUID) throws -> String {
        let dir = originalDirectory(athleteID: athleteID, checkInID: checkInID)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(photoID.uuidString).jpg")
        try data.write(to: file, options: .atomic)
        return relativePath(for: file)
    }

    func saveThumbnail(data: Data, athleteID: UUID, checkInID: UUID, photoID: UUID) throws -> String {
        let dir = thumbnailDirectory(athleteID: athleteID, checkInID: checkInID)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(photoID.uuidString).jpg")
        try data.write(to: file, options: .atomic)
        return relativePath(for: file)
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

    func deleteCheckInDirectory(athleteID: UUID, checkInID: UUID) throws {
        let dir = checkInDirectory(athleteID: athleteID, checkInID: checkInID)
        guard fileManager.fileExists(atPath: dir.path) else { return }
        try fileManager.removeItem(at: dir)
    }

    func deleteOrphans(athleteID: UUID, checkInID: UUID, keepingIDs: Set<UUID>) throws {
        for subdirectory in ["original", "thumbnail"] {
            let dir = checkInDirectory(athleteID: athleteID, checkInID: checkInID)
                .appendingPathComponent(subdirectory)
            guard fileManager.fileExists(atPath: dir.path) else { continue }
            let files = try fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            for file in files {
                let stem = file.deletingPathExtension().lastPathComponent
                if let id = UUID(uuidString: stem), !keepingIDs.contains(id) {
                    try fileManager.removeItem(at: file)
                }
            }
        }
    }

    // MARK: - Path helpers

    private func checkInDirectory(athleteID: UUID, checkInID: UUID) -> URL {
        documentsURL
            .appendingPathComponent("Athletes")
            .appendingPathComponent(athleteID.uuidString)
            .appendingPathComponent("CheckIns")
            .appendingPathComponent(checkInID.uuidString)
    }

    private func originalDirectory(athleteID: UUID, checkInID: UUID) -> URL {
        checkInDirectory(athleteID: athleteID, checkInID: checkInID)
            .appendingPathComponent("original")
    }

    private func thumbnailDirectory(athleteID: UUID, checkInID: UUID) -> URL {
        checkInDirectory(athleteID: athleteID, checkInID: checkInID)
            .appendingPathComponent("thumbnail")
    }

    private func relativePath(for absolute: URL) -> String {
        let docPath  = documentsURL.standardizedFileURL.path
        let filePath = absolute.standardizedFileURL.path
        guard filePath.hasPrefix(docPath) else { return filePath }
        let rel = String(filePath.dropFirst(docPath.count))
        return rel.hasPrefix("/") ? String(rel.dropFirst()) : rel
    }
}
