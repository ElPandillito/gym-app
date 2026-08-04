//
//  RecipeIngredientRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct RecipeIngredientRepository: RecipeIngredientRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Add

    func add(
        ingredient: Food,
        to recipe: Food,
        amountGrams: Double,
        sortOrder: Int
    ) throws -> RecipeIngredient {
        let entry        = RecipeIngredient(amountGrams: amountGrams, sortOrder: sortOrder)
        entry.ingredient = ingredient
        entry.recipe     = recipe
        recipe.ingredients.append(entry)
        recipe.updatedAt = Date()
        context.insert(entry)
        try context.save()
        return entry
    }

    // MARK: - Update

    func update(_ entry: RecipeIngredient, amountGrams: Double, sortOrder: Int) throws {
        entry.amountGrams       = amountGrams
        entry.sortOrder         = sortOrder
        entry.recipe?.updatedAt = Date()
        try context.save()
    }

    // MARK: - Remove

    func remove(_ entry: RecipeIngredient, from recipe: Food) throws {
        recipe.ingredients.removeAll { $0.id == entry.id }
        recipe.updatedAt = Date()
        context.delete(entry)
        try context.save()
    }

    func removeAll(from recipe: Food) throws {
        for entry in recipe.ingredients { context.delete(entry) }
        recipe.ingredients = []
        recipe.updatedAt   = Date()
        try context.save()
    }

    // MARK: - Reorder

    func reorder(_ entries: [RecipeIngredient], in recipe: Food) throws {
        for (index, entry) in entries.enumerated() {
            entry.sortOrder = index
        }
        recipe.updatedAt = Date()
        try context.save()
    }
}
