//
//  FoodMacrosCalculator.swift
//  GYM APP
//

import Foundation

/// Pure calculation engine for nutritional values.
///
/// Accepts FoodSnapshot / RecipeIngredientSnapshot only.
/// Does NOT import SwiftData, SwiftUI, repositories, or FileManager.
/// All inputs are value types — the engine is deterministic and testeable.
enum FoodMacrosCalculator {

    // MARK: - Single food item

    /// Returns the nutrition provided by `amount` (in `unit`) of a given food.
    ///
    /// Example:
    ///   macros(for: eggSnapshot, amount: 2, unit: .piece)
    ///   → nutrition for 2 eggs using egg.servingSize as grams-per-piece
    static func macros(
        for food: FoodSnapshot,
        amount: Double,
        unit: FoodUnit
    ) -> NutritionValues {
        let grams = toGrams(amount: amount, unit: unit, servingSize: food.servingSize)
        return food.nutritionPer100g.scaled(by: grams / 100.0)
    }

    // MARK: - Recipe

    /// Sums the nutritional contribution of every ingredient in a recipe snapshot.
    ///
    /// If the recipe has no ingredients (base food or fixed-macro prepared food),
    /// returns the food's stored nutritionPer100g unchanged.
    ///
    /// Example:
    ///   recipeMacros(for: huevosSnapshot)
    ///   → sum of (huevo × 2 + jitomate × 80g + …)
    static func recipeMacros(for recipe: FoodSnapshot) -> NutritionValues {
        guard !recipe.ingredients.isEmpty else {
            return recipe.nutritionPer100g
        }
        return recipe.ingredients.reduce(.zero) { acc, entry in
            let scaled = entry.nutritionPer100g.scaled(by: entry.amountGrams / 100.0)
            return acc + scaled
        }
    }

    // MARK: - Unit conversion

    /// Converts a given amount and unit to grams.
    ///
    /// - Weight (g, kg): direct factor conversion.
    /// - Volume (ml, l): 1 ml ≈ 1 g (water-density approximation, adequate for most foods).
    /// - Countable (piece, portion, tablespoon, etc.): amount × servingSize.
    ///   Falls back to 100 g if servingSize is nil to avoid silent zero-calorie results.
    static func toGrams(amount: Double, unit: FoodUnit, servingSize: Double?) -> Double {
        switch unit {
        case .grams:       return amount
        case .kilograms:   return amount * 1_000.0
        case .milliliters: return amount
        case .liters:      return amount * 1_000.0
        default:
            return amount * (servingSize ?? 100.0)
        }
    }
}
