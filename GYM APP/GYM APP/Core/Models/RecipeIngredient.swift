//
//  RecipeIngredient.swift
//  GYM APP
//

import SwiftData
import Foundation

/// Junction record linking a composed Food (recipe) to one of its component Foods (ingredient).
///
/// Delete rules:
///   recipe: Food?     — back-reference to the parent recipe.
///                       Food.ingredients is declared with .cascade, so deleting
///                       a recipe also deletes all its RecipeIngredient records.
///   ingredient: Food? — the base food used in this recipe.
///                       SwiftData default (.nullify) would set this to nil if the
///                       base food were deleted, but FoodRepository.delete(_:) prevents
///                       that scenario by throwing FoodError.isUsedAsIngredient.
@Model
final class RecipeIngredient {
    @Attribute(.unique) var id: UUID
    var amountGrams: Double
    var sortOrder: Int
    var createdAt: Date

    var recipe: Food?      // parent recipe
    var ingredient: Food?  // base food

    init(amountGrams: Double, sortOrder: Int = 0) {
        self.id          = UUID()
        self.amountGrams = amountGrams
        self.sortOrder   = sortOrder
        self.createdAt   = Date()
    }
}
