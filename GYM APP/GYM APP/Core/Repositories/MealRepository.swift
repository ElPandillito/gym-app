//
//  MealRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct MealRepository: MealRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(name: String, sortOrder: Int, time: Date? = nil, to plan: NutritionPlan) throws -> Meal {
        let meal = Meal(name: name, sortOrder: sortOrder, time: time)
        meal.nutritionPlan = plan
        plan.meals.append(meal)
        plan.updatedAt = Date()
        context.insert(meal)
        try context.save()
        return meal
    }

    func update(_ meal: Meal, name: String, notes: String?, time: Date?) throws {
        meal.name      = name
        meal.notes     = notes
        meal.time      = time
        meal.updatedAt = Date()
        meal.nutritionPlan?.updatedAt = Date()
        try context.save()
    }

    func reorder(_ meals: [Meal], in plan: NutritionPlan) throws {
        for (index, meal) in meals.enumerated() {
            meal.sortOrder = index
            meal.updatedAt = Date()
        }
        plan.updatedAt = Date()
        try context.save()
    }

    func delete(_ meal: Meal) throws {
        meal.nutritionPlan?.updatedAt = Date()
        context.delete(meal)
        try context.save()
    }
}
