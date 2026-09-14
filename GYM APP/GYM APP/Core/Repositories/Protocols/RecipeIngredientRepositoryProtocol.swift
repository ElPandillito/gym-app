//
//  RecipeIngredientRepositoryProtocol.swift
//  GYM APP
//

import Foundation

protocol RecipeIngredientRepositoryProtocol {

    /// Adds a RecipeIngredient linking `ingredient` into `recipe`.
    @discardableResult
    func add(
        ingredient: Food,
        to recipe: Food,
        amountGrams: Double,
        sortOrder: Int
    ) throws -> RecipeIngredient

    /// Updates the amount and position of an existing entry.
    func update(_ entry: RecipeIngredient, amountGrams: Double, sortOrder: Int) throws

    /// Removes a single ingredient entry from a recipe.
    func remove(_ entry: RecipeIngredient, from recipe: Food) throws

    /// Removes all ingredient entries from a recipe.
    func removeAll(from recipe: Food) throws

    /// Reassigns sortOrder for each entry based on its position in the provided array.
    func reorder(_ entries: [RecipeIngredient], in recipe: Food) throws
}
