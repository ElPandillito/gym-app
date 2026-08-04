//
//  FoodRepositoryProtocol.swift
//  GYM APP
//

import Foundation

protocol FoodRepositoryProtocol {

    /// Creates and persists a new Food record.
    @discardableResult
    func add(
        name: String,
        kind: FoodKind,
        category: FoodCategory,
        source: FoodSource
    ) throws -> Food

    /// Updates all mutable fields on an existing Food and saves.
    func update(
        _ food: Food,
        name: String,
        kind: FoodKind,
        category: FoodCategory,
        calories: Double?,
        protein: Double?,
        carbohydrates: Double?,
        fat: Double?,
        fiber: Double?,
        servingSize: Double?,
        servingUnit: FoodUnit?,
        brand: String?,
        tags: [String]
    ) throws

    /// Deletes a Food and its associated image.
    ///
    /// - Throws: `FoodError.isUsedAsIngredient` if the food appears as an ingredient
    ///   in any recipe. Remove it from all recipes before deleting.
    func delete(_ food: Food) throws

    /// Fetches a Food by its UUID.
    func fetch(id: UUID) throws -> Food?

    /// Fetches all Foods sorted by name.
    func fetchAll() throws -> [Food]

    /// Fetches Foods of a given kind, sorted by name.
    func fetch(kind: FoodKind) throws -> [Food]

    /// Fetches Foods in a given category, sorted by name.
    func fetch(category: FoodCategory) throws -> [Food]

    /// Saves raw image data to disk, creates a FoodImage, and links it to the food.
    /// Replaces any existing image.
    func setImage(data: Data, for food: Food) throws

    /// Generates and stores a thumbnail for the food's image if not yet processed.
    func generateThumbnailIfNeeded(for food: Food) throws

    /// Removes the food's image from disk and deletes the FoodImage record.
    func removeImage(from food: Food) throws
}
