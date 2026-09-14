//
//  NutritionValues.swift
//  GYM APP
//

import Foundation

/// Nutritional content expressed as absolute amounts (not per-100g unless stated).
/// Consumed by FoodMacrosCalculator and future NutritionPlan snapshot logic.
/// All macros in grams; calories in kcal.
struct NutritionValues: Codable, Sendable, Equatable {
    let calories: Double       // kcal
    let protein: Double        // g
    let carbohydrates: Double  // g
    let fat: Double            // g
    let fiber: Double          // g

    static let zero = NutritionValues(
        calories: 0, protein: 0, carbohydrates: 0, fat: 0, fiber: 0
    )

    static func + (lhs: NutritionValues, rhs: NutritionValues) -> NutritionValues {
        NutritionValues(
            calories:      lhs.calories      + rhs.calories,
            protein:       lhs.protein       + rhs.protein,
            carbohydrates: lhs.carbohydrates + rhs.carbohydrates,
            fat:           lhs.fat           + rhs.fat,
            fiber:         lhs.fiber         + rhs.fiber
        )
    }

    /// Returns a new NutritionValues scaled by `factor`.
    /// Used to compute macros for an arbitrary gram amount from per-100g values.
    func scaled(by factor: Double) -> NutritionValues {
        NutritionValues(
            calories:      calories      * factor,
            protein:       protein       * factor,
            carbohydrates: carbohydrates * factor,
            fat:           fat           * factor,
            fiber:         fiber         * factor
        )
    }
}
