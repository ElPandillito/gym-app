//
//  MealItemRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct MealItemRepository: MealItemRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func add(food: Food, amountGrams: Double, sortOrder: Int, to meal: Meal) throws -> MealItem {
        let item = MealItem(food: food, amountGrams: amountGrams, sortOrder: sortOrder)
        item.meal = meal
        meal.items.append(item)
        meal.updatedAt = Date()
        meal.nutritionPlan?.updatedAt = Date()
        context.insert(item)
        try context.save()
        return item
    }

    func update(_ item: MealItem, amountGrams: Double) throws {
        item.amountGrams = max(1, amountGrams)
        item.updatedAt   = Date()
        item.meal?.updatedAt = Date()
        item.meal?.nutritionPlan?.updatedAt = Date()
        try context.save()
    }

    func reorder(_ items: [MealItem], in meal: Meal) throws {
        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
        meal.updatedAt = Date()
        try context.save()
    }

    func delete(_ item: MealItem) throws {
        item.meal?.updatedAt = Date()
        context.delete(item)
        try context.save()
    }

    func removeAll(from meal: Meal) throws {
        for item in meal.items { context.delete(item) }
        meal.items     = []
        meal.updatedAt = Date()
        try context.save()
    }
}
