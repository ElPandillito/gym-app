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

    // MARK: - Add (standard — inserts + saves immediately)

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

    // MARK: - Prepare-only (used by CheckInWorkflowViewModel two-phase save)
    //
    // Writes the image file and creates the ProgressPhoto record in memory.
    // Does NOT insert into context. Does NOT call context.save().
    //
    // The caller (CheckInWorkflowViewModel) must:
    //   1. Append the returned relativePath to its rollback journal immediately.
    //   2. Later set photo.checkIn and call context.insert(photo) in Phase C.
    //   3. Call context.save() once as the single final commit.
    //
    // If any subsequent phase fails, the caller deletes the written file using
    // the relativePath and calls context.rollback() to undo pending inserts.
    func prepareNewPhoto(
        data: Data,
        poseType: PoseType,
        sortOrder: Int,
        capturedAt: Date,
        notes: String?,
        athleteID: UUID,
        checkInID: UUID
    ) throws -> (photo: ProgressPhoto, relativePath: String) {
        let photo = ProgressPhoto(
            poseType: poseType,
            originalPath: "",
            sortOrder: sortOrder,
            capturedAt: capturedAt
        )
        photo.notes = notes

        let relativePath = try storage.saveOriginal(
            data: data,
            athleteID: athleteID,
            checkInID: checkInID,
            photoID: photo.id
        )
        photo.originalPath = relativePath
        return (photo, relativePath)
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
