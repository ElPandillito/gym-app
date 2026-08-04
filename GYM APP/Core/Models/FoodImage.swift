//
//  FoodImage.swift
//  GYM APP
//

import SwiftData
import Foundation

/// Stores file-system paths for a Food's photograph.
/// Follows the same pattern as ProgressPhoto: SwiftData holds relative paths only.
/// Actual bytes live on disk, managed by FoodImageStorageService.
///
/// Path layout (relative to Documents/):
///   Foods/{foodID}/original/image.jpg
///   Foods/{foodID}/thumbnail/image.jpg
///
/// Delete rule: FoodImage is owned by Food via Food.image (.cascade).
/// Deleting Food cascades to FoodImage; deleting FoodImage does NOT affect Food.
@Model
final class FoodImage {
    @Attribute(.unique) var id: UUID
    var originalPath: String
    var thumbnailPath: String?
    var isProcessed: Bool      // false until thumbnail has been generated
    var createdAt: Date

    var food: Food?            // parent — managed by Food.image cascade rule

    init(originalPath: String) {
        self.id           = UUID()
        self.originalPath = originalPath
        self.isProcessed  = false
        self.createdAt    = Date()
    }
}
