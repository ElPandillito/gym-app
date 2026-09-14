//
//  FoodSnapshot.swift
//  GYM APP
//

import Foundation

/// Immutable value-type mirror of Food and its recipe composition.
///
/// Architectural boundary:
///   Food (@Model, SwiftData)  →  FoodSnapshot (Codable, Sendable, no SwiftData)
///
/// Purposes:
///   1. Engine input: FoodMacrosCalculator accepts snapshots, never @Model objects.
///   2. Historical preservation: future MealItem / NutritionPlanEntry will store
///      a NutritionValues snapshot captured at assignment time.
///      Even if the underlying Food is edited later, the plan's historical values
///      remain unchanged unless explicitly refreshed.
///   3. Client App DTO: Codable conformance enables JSON serialization for future sync.
///
/// This file does NOT import SwiftData, SwiftUI, or any persistence layer.
struct FoodSnapshot: Codable, Sendable {
    let id: UUID
    let name: String
    let kind: FoodKind
    let category: FoodCategory
    let source: FoodSource
    let nutritionPer100g: NutritionValues
    let servingSize: Double?
    let servingUnit: FoodUnit?
    let brand: String?
    let tags: [String]
    /// Flat ingredient list. Empty for base ingredients; populated for recipes.
    let ingredients: [RecipeIngredientSnapshot]
    let createdAt: Date
}

// MARK: - RecipeIngredientSnapshot

/// Flat snapshot of one recipe component.
/// Intentionally stores ingredient data inline (not a nested FoodSnapshot)
/// to keep the structure non-recursive and easily serializable.
struct RecipeIngredientSnapshot: Codable, Sendable {
    let id: UUID
    let ingredientID: UUID
    let ingredientName: String
    let nutritionPer100g: NutritionValues
    let servingSize: Double?
    let servingUnit: FoodUnit?
    let amountGrams: Double
    let sortOrder: Int
}

// MARK: - Food → FoodSnapshot

extension Food {
    func snapshot() -> FoodSnapshot {
        let ingredientSnaps = ingredients
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { ri -> RecipeIngredientSnapshot? in
                guard let ing = ri.ingredient else { return nil }
                return RecipeIngredientSnapshot(
                    id:               ri.id,
                    ingredientID:     ing.id,
                    ingredientName:   ing.name,
                    nutritionPer100g: ing.nutritionPer100g,
                    servingSize:      ing.servingSize,
                    servingUnit:      ing.servingUnit,
                    amountGrams:      ri.amountGrams,
                    sortOrder:        ri.sortOrder
                )
            }
        return FoodSnapshot(
            id:               id,
            name:             name,
            kind:             kind,
            category:         category,
            source:           source,
            nutritionPer100g: nutritionPer100g,
            servingSize:      servingSize,
            servingUnit:      servingUnit,
            brand:            brand,
            tags:             tags,
            ingredients:      ingredientSnaps,
            createdAt:        createdAt
        )
    }
}
