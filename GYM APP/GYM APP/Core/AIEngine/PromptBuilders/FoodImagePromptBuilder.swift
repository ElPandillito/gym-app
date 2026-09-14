//
//  FoodImagePromptBuilder.swift
//  GYM APP
//
//  Pure struct that converts a FoodSnapshot into a visual text prompt
//  suitable for an image generation service.
//
//  Constraints:
//    - Input: FoodSnapshot only. No athlete, plan, or personal data.
//    - Output: deterministic String given the same FoodSnapshot.
//    - No network calls, no SwiftData access, no SwiftUI imports.
//    - Does not calculate macros or modify nutritional values.
//    - Never invents ingredients absent from the snapshot.
//

import Foundation

struct FoodImagePromptBuilder {

    // MARK: - Public

    /// Builds a visual food photography prompt from a `FoodSnapshot`.
    ///
    /// - Parameter food: Snapshot of the food or recipe. Must not contain personal data.
    /// - Returns: A deterministic prompt string safe to send to an image generation service.
    func makePrompt(for food: FoodSnapshot) -> String {
        var parts: [String] = []
        parts.append(foodDescription(food))
        if let line = ingredientLine(food) {
            parts.append(line)
        }
        parts.append(presentationGuidelines)
        parts.append(visualRestrictions)
        return parts.joined(separator: " ")
    }

    // MARK: - Private helpers

    private func foodDescription(_ food: FoodSnapshot) -> String {
        let kindLabel = food.kind == .preparedFood ? "platillo preparado" : "alimento"
        return "Fotografía gastronómica profesional y realista de \(food.name), un \(kindLabel)."
    }

    /// Returns a sentence listing ingredients only for prepared foods with at least one ingredient.
    /// Ingredients are sorted by sortOrder to ensure a deterministic order.
    /// Amounts are formatted as whole numbers when possible ("150 g") or one decimal ("1.5 g").
    private func ingredientLine(_ food: FoodSnapshot) -> String? {
        guard food.kind == .preparedFood, !food.ingredients.isEmpty else { return nil }
        let sorted = food.ingredients.sorted { $0.sortOrder < $1.sortOrder }
        let names = sorted.map { formattedIngredient($0) }.joined(separator: ", ")
        return "Preparación elaborada con \(names)."
    }

    private func formattedIngredient(_ item: RecipeIngredientSnapshot) -> String {
        let grams = item.amountGrams
        guard grams > 0 else { return item.ingredientName }
        let isWhole = grams.truncatingRemainder(dividingBy: 1) == 0
        let formatted = isWhole ? String(Int(grams)) : String(format: "%.1f", grams)
        return "\(item.ingredientName) (\(formatted) g)"
    }

    private let presentationGuidelines =
        "Porción saludable servida en un plato limpio, iluminación natural, fondo neutro, presentación apetitosa."

    private let visualRestrictions =
        "Sin personas, sin texto, sin logotipos, sin empaques, sin utensilios de cocina prominentes."
}
