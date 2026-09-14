//
//  MealItem.swift
//  GYM APP
//

import SwiftData
import Foundation

/// A single food entry in a Meal.
///
/// Snapshot strategy: macro values per-100g are copied from Food at assignment time.
/// This preserves historical accuracy — editing Food later does not alter existing plans.
/// Changing amountGrams recalculates macros instantly via the computed property.
///
/// Delete rules:
///   meal:  owned by Meal.items (.cascade) — meal deletion removes items.
///   food:  nullify (SwiftData default) — Food can be deleted; snapshot values survive.
@Model
final class MealItem {
    @Attribute(.unique) var id: UUID
    var sortOrder: Int
    var amountGrams: Double

    // Historical snapshot — per 100 g at assignment time
    var snapshotCaloriesPer100g: Double
    var snapshotProteinPer100g: Double
    var snapshotCarbsPer100g: Double
    var snapshotFatPer100g: Double
    var snapshotFiberPer100g: Double

    // Display name preserved in case Food is later deleted
    var snapshotFoodName: String

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    var meal: Meal?
    var food: Food?

    // MARK: - Init (new item from Food)

    init(food: Food, amountGrams: Double, sortOrder: Int = 0) {
        self.id        = UUID()
        self.food      = food
        self.amountGrams = max(1, amountGrams)
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()

        // Snapshot per-100g values from Food at creation time
        self.snapshotFoodName          = food.name
        self.snapshotCaloriesPer100g   = food.calories      ?? 0
        self.snapshotProteinPer100g    = food.protein       ?? 0
        self.snapshotCarbsPer100g      = food.carbohydrates ?? 0
        self.snapshotFatPer100g        = food.fat           ?? 0
        self.snapshotFiberPer100g      = food.fiber         ?? 0
    }

    // MARK: - Init (deep copy — preserves snapshots without re-fetching Food)

    init(copying source: MealItem) {
        self.id          = UUID()
        self.food        = source.food
        self.amountGrams = source.amountGrams
        self.sortOrder   = source.sortOrder
        self.createdAt   = Date()
        self.updatedAt   = Date()

        self.snapshotFoodName        = source.snapshotFoodName
        self.snapshotCaloriesPer100g = source.snapshotCaloriesPer100g
        self.snapshotProteinPer100g  = source.snapshotProteinPer100g
        self.snapshotCarbsPer100g    = source.snapshotCarbsPer100g
        self.snapshotFatPer100g      = source.snapshotFatPer100g
        self.snapshotFiberPer100g    = source.snapshotFiberPer100g
    }
}

// MARK: - Computed macros

extension MealItem {

    /// Live macros based on current amountGrams × frozen snapshot per-100g values.
    var macros: NutritionValues {
        let factor = amountGrams / 100.0
        return NutritionValues(
            calories:      snapshotCaloriesPer100g * factor,
            protein:       snapshotProteinPer100g  * factor,
            carbohydrates: snapshotCarbsPer100g    * factor,
            fat:           snapshotFatPer100g      * factor,
            fiber:         snapshotFiberPer100g    * factor
        )
    }

    var displayName: String {
        food?.name ?? snapshotFoodName
    }
}
