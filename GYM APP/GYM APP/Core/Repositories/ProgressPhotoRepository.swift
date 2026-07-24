//
//  ProgressPhotoRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct ProgressPhotoRepository: ProgressPhotoRepositoryProtocol {

    private let context: ModelContext
    private let storage: PhotoStorageServiceProtocol
    private let thumbnails: ThumbnailServiceProtocol

    init(
        context: ModelContext,
        storage: PhotoStorageServiceProtocol,
        thumbnails: ThumbnailServiceProtocol
    ) {
        self.context    = context
        self.storage    = storage
        self.thumbnails = thumbnails
    }

    /// Convenience factory that wires the default concrete services.
    static func make(context: ModelContext) -> ProgressPhotoRepository {
        let storage = PhotoStorageService()
        return ProgressPhotoRepository(
            context: context,
            storage: storage,
            thumbnails: ThumbnailService(storage: storage)
        )
    }

    // MARK: - Add

    func add(
        data: Data,
        poseType: PoseType,
        sortOrder: Int,
        capturedAt: Date,
        notes: String?,
        for checkIn: CheckIn
    ) throws -> ProgressPhoto {
        guard let athleteID = checkIn.athlete?.id else {
            throw PhotoError.missingAthlete
        }
        // Create the record first to reuse its UUID as the filename.
        let photo = ProgressPhoto(
            poseType: poseType,
            originalPath: "",           // Filled in next line
            sortOrder: sortOrder,
            capturedAt: capturedAt
        )
        photo.notes = notes

        let originalPath = try storage.saveOriginal(
            data: data,
            athleteID: athleteID,
            checkInID: checkIn.id,
            photoID: photo.id
        )
        photo.originalPath = originalPath
        photo.checkIn      = checkIn
        context.insert(photo)
        checkIn.updatedAt = Date()
        try context.save()
        return photo
    }

    // MARK: - Update

    func update(_ photo: ProgressPhoto, data: Data?, poseType: PoseType, notes: String?) throws {
        if let newData = data,
           let athleteID = photo.checkIn?.athlete?.id,
           let checkInID = photo.checkIn?.id {
            // Remove old files and persist the replacement.
            try storage.delete(relativePath: photo.originalPath)
            if let thumbPath = photo.thumbnailPath {
                try storage.delete(relativePath: thumbPath)
            }
            photo.originalPath  = try storage.saveOriginal(
                data: newData,
                athleteID: athleteID,
                checkInID: checkInID,
                photoID: photo.id
            )
            photo.thumbnailPath = nil
            photo.isProcessed   = false
        }
        photo.poseType           = poseType
        photo.notes              = notes
        photo.checkIn?.updatedAt = Date()
        try context.save()
    }

    // MARK: - Delete

    func delete(_ photo: ProgressPhoto, from checkIn: CheckIn) throws {
        try storage.delete(relativePath: photo.originalPath)
        if let thumbPath = photo.thumbnailPath {
            try storage.delete(relativePath: thumbPath)
        }
        context.delete(photo)
        checkIn.updatedAt = Date()
        try context.save()
    }

    func deleteAll(from checkIn: CheckIn) throws {
        if let athleteID = checkIn.athlete?.id {
            try storage.deleteCheckInDirectory(athleteID: athleteID, checkInID: checkIn.id)
        }
        for photo in checkIn.photos { context.delete(photo) }
        checkIn.updatedAt = Date()
        try context.save()
    }

    // MARK: - Thumbnail

    func generateThumbnailIfNeeded(for photo: ProgressPhoto) throws {
        guard !photo.isProcessed,
              let athleteID = photo.checkIn?.athlete?.id,
              let checkInID = photo.checkIn?.id else { return }

        photo.thumbnailPath = try thumbnails.generateThumbnail(
            from: photo.originalPath,
            photoID: photo.id,
            athleteID: athleteID,
            checkInID: checkInID
        )
        photo.isProcessed = true
        try context.save()
    }

    // MARK: - Orphan cleanup

    func deleteOrphanedFiles(for checkIn: CheckIn) throws {
        guard let athleteID = checkIn.athlete?.id else { return }
        let knownIDs = Set(checkIn.photos.map { $0.id })
        try storage.deleteOrphans(
            athleteID: athleteID,
            checkInID: checkIn.id,
            keepingIDs: knownIDs
        )
    }
}

// MARK: - Errors

enum PhotoError: LocalizedError {
    case missingAthlete

    var errorDescription: String? {
        switch self {
        case .missingAthlete:
            return "El check-in no tiene un atleta asignado. No se puede guardar la foto."
        }
    }
}
