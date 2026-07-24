//
//  ProgressPhoto.swift
//  GYM APP
//

import SwiftData
import Foundation

@Model
final class ProgressPhoto {
    @Attribute(.unique) var id: UUID
    var poseType: PoseType
    var originalPath: String        // Relative path in FileManager
    var thumbnailPath: String?      // Relative path — generated asynchronously
    var capturedAt: Date
    var notes: String?
    var sortOrder: Int
    var isProcessed: Bool           // false until thumbnail is generated
    var createdAt: Date

    // Parent
    var checkIn: CheckIn?

    init(
        poseType: PoseType,
        originalPath: String,
        sortOrder: Int = 0,
        capturedAt: Date = Date()
    ) {
        self.id           = UUID()
        self.poseType     = poseType
        self.originalPath = originalPath
        self.sortOrder    = sortOrder
        self.capturedAt   = capturedAt
        self.isProcessed  = false
        self.createdAt    = Date()
    }
}
