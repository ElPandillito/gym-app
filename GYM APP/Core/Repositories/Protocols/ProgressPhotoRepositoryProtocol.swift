//
//  ProgressPhotoRepositoryProtocol.swift
//  GYM APP
//

import Foundation

protocol ProgressPhotoRepositoryProtocol {

    /// Saves `data` to disk, inserts a ProgressPhoto record into SwiftData, and returns it.
    /// The original is persisted immediately; thumbnail generation is intentionally deferred.
    func add(
        data: Data,
        poseType: PoseType,
        sortOrder: Int,
        capturedAt: Date,
        notes: String?,
        for checkIn: CheckIn
    ) throws -> ProgressPhoto

    /// If `data` is non-nil, replaces the existing image file and resets thumbnail state.
    /// Always updates poseType and notes.
    func update(_ photo: ProgressPhoto, data: Data?, poseType: PoseType, notes: String?) throws

    /// Deletes the SwiftData record and both the original and thumbnail files.
    func delete(_ photo: ProgressPhoto, from checkIn: CheckIn) throws

    /// Deletes every photo record and the entire CheckIn directory on disk.
    func deleteAll(from checkIn: CheckIn) throws

    /// Generates and stores a thumbnail for `photo` if one does not yet exist,
    /// then sets isProcessed = true.
    func generateThumbnailIfNeeded(for photo: ProgressPhoto) throws

    /// Deletes files on disk inside the CheckIn directory whose UUID filename
    /// does not match any known ProgressPhoto record.
    func deleteOrphanedFiles(for checkIn: CheckIn) throws
}
