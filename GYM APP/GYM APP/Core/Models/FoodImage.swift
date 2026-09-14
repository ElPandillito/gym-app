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
///
/// Phase 37B additions (both Optional for lightweight migration):
///   imageOriginRaw      — nil for records created before Phase 37B
///   aiGenerationStateRaw — nil when origin is not aiGenerated
@Model
final class FoodImage {
    @Attribute(.unique) var id: UUID
    var originalPath: String
    var thumbnailPath: String?
    var isProcessed: Bool               // false until thumbnail has been generated
    var createdAt: Date
    var imageOriginRaw: String?         // nil for pre-Phase 37B records
    var aiGenerationStateRaw: String?   // nil when origin is not aiGenerated
    var promptUsed: String?             // nil for pre-Phase 39 records; stores the prompt sent to the provider

    var food: Food?                     // parent — managed by Food.image cascade rule

    // MARK: - Typed accessors

    var imageOrigin: FoodImageOrigin? {
        get { imageOriginRaw.flatMap(FoodImageOrigin.init(rawValue:)) }
        set { imageOriginRaw = newValue?.rawValue }
    }

    var aiGenerationState: FoodImageGenerationState? {
        get { aiGenerationStateRaw.flatMap(FoodImageGenerationState.init(rawValue:)) }
        set { aiGenerationStateRaw = newValue?.rawValue }
    }

    // MARK: - Init

    init(originalPath: String) {
        self.id                   = UUID()
        self.originalPath         = originalPath
        self.isProcessed          = false
        self.createdAt            = Date()
        self.imageOriginRaw       = nil
        self.aiGenerationStateRaw = nil
        self.promptUsed           = nil
    }
}
