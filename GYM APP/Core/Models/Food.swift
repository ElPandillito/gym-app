//
//  Food.swift
//  GYM APP
//

import SwiftData
import Foundation

/// Universal food entity: represents both individual ingredients and composed prepared foods.
///
/// FoodKind.ingredient   — a base food (egg, chicken, rice) with manually entered macros.
/// FoodKind.preparedFood — a composed recipe whose macros are computed from its ingredients
///                         via FoodMacrosCalculator and stored on save/update.
///
/// Delete rules:
///   image:       .cascade — deleting Food deletes its FoodImage record (and files via repo).
///   ingredients: .cascade — deleting a recipe deletes its RecipeIngredient records.
///   RecipeIngredient.ingredient references are nullified by SwiftData default,
///   but FoodRepository.delete(_:) prevents deletion if the food is used anywhere.
@Model
final class Food {
    @Attribute(.unique) var id: UUID
    var name: String

    // Enum raw values stored as String for forward-compatible migrations.
    // Access via computed properties: kind, category, source, servingUnit.
    var kindRaw: String
    var categoryRaw: String
    var sourceRaw: String

    // Macros per 100 g. Nil = not yet measured / not applicable.
    var calories: Double?
    var protein: Double?
    var carbohydrates: Double?
    var fat: Double?
    var fiber: Double?

    // Serving reference — used by FoodMacrosCalculator for countable units.
    var servingSize: Double?
    var servingUnitRaw: String?

    // Optional metadata
    var brand: String?
    var tags: [String]

    // Future-ready fields: populated when integrating external databases or barcode scanner.
    var externalID: String?
    var barcode: String?

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    /// Cascade: deleting this Food (as recipe) removes its ingredient composition.
    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient]

    /// Cascade: deleting this Food removes its associated FoodImage.
    @Relationship(deleteRule: .cascade, inverse: \FoodImage.food)
    var image: FoodImage?

    // MARK: - Init

    init(
        name: String,
        kind: FoodKind,
        category: FoodCategory,
        source: FoodSource = .coach
    ) {
        self.id          = UUID()
        self.name        = name
        self.kindRaw     = kind.rawValue
        self.categoryRaw = category.rawValue
        self.sourceRaw   = source.rawValue
        self.tags        = []
        self.ingredients = []
        self.createdAt   = Date()
        self.updatedAt   = Date()
    }
}

// MARK: - Computed accessors

extension Food {

    var kind: FoodKind {
        get { FoodKind(rawValue: kindRaw) ?? .ingredient }
        set { kindRaw = newValue.rawValue }
    }

    var category: FoodCategory {
        get { FoodCategory(rawValue: categoryRaw) }
        set { categoryRaw = newValue.rawValue }
    }

    var source: FoodSource {
        get { FoodSource(rawValue: sourceRaw) ?? .coach }
        set { sourceRaw = newValue.rawValue }
    }

    var servingUnit: FoodUnit? {
        get { servingUnitRaw.flatMap(FoodUnit.init(rawValue:)) }
        set { servingUnitRaw = newValue?.rawValue }
    }

    /// Macros as a NutritionValues (nils treated as 0).
    /// For recipes, this should reflect the last calculated total — call
    /// FoodMacrosCalculator.recipeMacros(for: snapshot()) to get the live value.
    var nutritionPer100g: NutritionValues {
        NutritionValues(
            calories:      calories      ?? 0,
            protein:       protein       ?? 0,
            carbohydrates: carbohydrates ?? 0,
            fat:           fat           ?? 0,
            fiber:         fiber         ?? 0
        )
    }
}
