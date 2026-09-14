//
//  NutritionPlanRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct NutritionPlanRepository: NutritionPlanRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(name: String, startDate: Date, to athlete: Athlete) throws -> NutritionPlan {
        let plan = NutritionPlan(name: name, startDate: startDate)
        plan.athlete = athlete
        athlete.nutritionPlans.append(plan)
        context.insert(plan)
        try context.save()
        return plan
    }

    func update(
        _ plan: NutritionPlan,
        name: String,
        startDate: Date,
        endDate: Date?,
        notes: String?,
        targetCalories: Double?,
        targetProtein: Double?,
        targetCarbohydrates: Double?,
        targetFat: Double?,
        targetFiber: Double?
    ) throws {
        plan.name                 = name
        plan.startDate            = startDate
        plan.endDate              = endDate
        plan.notes                = notes
        plan.targetCalories       = targetCalories
        plan.targetProtein        = targetProtein
        plan.targetCarbohydrates  = targetCarbohydrates
        plan.targetFat            = targetFat
        plan.targetFiber          = targetFiber
        plan.updatedAt            = Date()
        try context.save()
    }

    /// Activates a plan and deactivates all other plans for the same athlete.
    func activate(_ plan: NutritionPlan) throws {
        if let athlete = plan.athlete {
            for other in athlete.nutritionPlans where other.id != plan.id {
                other.isActive  = false
                other.updatedAt = Date()
            }
        }
        plan.isActive  = true
        plan.updatedAt = Date()
        try context.save()
    }

    func deactivate(_ plan: NutritionPlan) throws {
        plan.isActive  = false
        plan.updatedAt = Date()
        try context.save()
    }

    func delete(_ plan: NutritionPlan) throws {
        context.delete(plan)
        try context.save()
    }

    /// Deep-copies a plan with all its meals and items.
    /// Snapshot fields are carried over as-is — no re-fetch from Food.
    func duplicate(_ plan: NutritionPlan, for athlete: Athlete) throws -> NutritionPlan {
        let copy = NutritionPlan(name: "Copia de \(plan.name)", startDate: plan.startDate)
        copy.endDate             = plan.endDate
        copy.notes               = plan.notes
        copy.targetCalories      = plan.targetCalories
        copy.targetProtein       = plan.targetProtein
        copy.targetCarbohydrates = plan.targetCarbohydrates
        copy.targetFat           = plan.targetFat
        copy.targetFiber         = plan.targetFiber
        copy.isActive            = false
        copy.athlete             = athlete
        athlete.nutritionPlans.append(copy)
        context.insert(copy)

        for meal in plan.sortedMeals {
            let mealCopy = Meal(name: meal.name, sortOrder: meal.sortOrder, time: meal.time)
            mealCopy.notes        = meal.notes
            mealCopy.nutritionPlan = copy
            copy.meals.append(mealCopy)
            context.insert(mealCopy)

            for item in meal.sortedItems {
                let itemCopy = MealItem(copying: item)
                itemCopy.meal = mealCopy
                mealCopy.items.append(itemCopy)
                context.insert(itemCopy)
            }
        }

        try context.save()
        return copy
    }

    func fetchAll(for athlete: Athlete) throws -> [NutritionPlan] {
        let id = athlete.id
        let descriptor = FetchDescriptor<NutritionPlan>(
            predicate: #Predicate { $0.athlete?.id == id },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
