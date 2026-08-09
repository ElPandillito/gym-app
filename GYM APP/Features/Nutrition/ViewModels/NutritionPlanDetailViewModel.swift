//
//  NutritionPlanDetailViewModel.swift
//  GYM APP
//

import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class NutritionPlanDetailViewModel {

    var errorMessage: String?

    private let mealRepo: MealRepository
    private let itemRepo: MealItemRepository
    private let planRepo: NutritionPlanRepository

    init(context: ModelContext) {
        self.mealRepo = MealRepository(context: context)
        self.itemRepo = MealItemRepository(context: context)
        self.planRepo = NutritionPlanRepository(context: context)
    }

    // MARK: - Meal actions

    func addMeal(name: String, to plan: NutritionPlan) {
        do {
            let order = plan.meals.count
            try mealRepo.add(name: name, sortOrder: order, to: plan)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMeal(_ meal: Meal) {
        do {
            try mealRepo.delete(meal)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveMeals(fromOffsets: IndexSet, toOffset: Int, in plan: NutritionPlan) {
        var sorted = plan.sortedMeals
        sorted.move(fromOffsets: fromOffsets, toOffset: toOffset)
        do {
            try mealRepo.reorder(sorted, in: plan)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Item actions

    func addItem(food: Food, amountGrams: Double, to meal: Meal) {
        do {
            let order = meal.items.count
            try itemRepo.add(food: food, amountGrams: amountGrams, sortOrder: order, to: meal)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateItem(_ item: MealItem, amountGrams: Double) {
        do {
            try itemRepo.update(item, amountGrams: amountGrams)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(_ item: MealItem) {
        do {
            try itemRepo.delete(item)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveItems(fromOffsets: IndexSet, toOffset: Int, in meal: Meal) {
        var sorted = meal.sortedItems
        sorted.move(fromOffsets: fromOffsets, toOffset: toOffset)
        do {
            try itemRepo.reorder(sorted, in: meal)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Plan actions

    func activate(_ plan: NutritionPlan, for athlete: Athlete) {
        do {
            try planRepo.activate(plan)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
