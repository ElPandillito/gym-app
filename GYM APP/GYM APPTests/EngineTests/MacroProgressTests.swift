//
//  MacroProgressTests.swift
//  GYM APPTests
//

import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import GYM_APP

// MARK: - NutritionPlan macro totals (sum across Meals / MealItems)

@Suite("NutritionPlan — macro totals", .serialized)
struct NutritionPlanMacroTotalsTests {

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(GYMAppSchemaV1.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @MainActor
    private func makeFood(
        _ context: ModelContext,
        name: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) -> Food {
        let food = Food(name: name, kind: .ingredient, category: .proteinas, source: .coach)
        food.calories = calories
        food.protein = protein
        food.carbohydrates = carbs
        food.fat = fat
        context.insert(food)
        return food
    }

    @Test("totalMacros sums a single MealItem correctly")
    @MainActor
    func totalMacros_singleItem() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let plan = NutritionPlan(name: "Plan", startDate: Date())
        context.insert(plan)
        let mealRepo = MealRepository(context: context)
        let itemRepo = MealItemRepository(context: context)

        let meal = try mealRepo.add(name: "Desayuno", sortOrder: 0, to: plan)
        let food = makeFood(context, name: "Huevo", calories: 155, protein: 13, carbs: 1.1, fat: 11)
        try itemRepo.add(food: food, amountGrams: 100, sortOrder: 0, to: meal)

        #expect(plan.totalMacros.calories == 155)
        #expect(plan.totalMacros.protein == 13)
    }

    @Test("totalMacros sums multiple MealItems across multiple Meals")
    @MainActor
    func totalMacros_multipleMealsAndItems() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let plan = NutritionPlan(name: "Plan", startDate: Date())
        context.insert(plan)
        let mealRepo = MealRepository(context: context)
        let itemRepo = MealItemRepository(context: context)

        let breakfast = try mealRepo.add(name: "Desayuno", sortOrder: 0, to: plan)
        let lunch = try mealRepo.add(name: "Comida", sortOrder: 1, to: plan)

        let eggs = makeFood(context, name: "Huevo", calories: 155, protein: 13, carbs: 1.1, fat: 11)
        let rice = makeFood(context, name: "Arroz", calories: 130, protein: 2.7, carbs: 28, fat: 0.3)
        let chicken = makeFood(context, name: "Pollo", calories: 165, protein: 31, carbs: 0, fat: 3.6)

        try itemRepo.add(food: eggs, amountGrams: 100, sortOrder: 0, to: breakfast)
        try itemRepo.add(food: rice, amountGrams: 200, sortOrder: 0, to: lunch)
        try itemRepo.add(food: chicken, amountGrams: 150, sortOrder: 1, to: lunch)

        // eggs: 155 cal; rice@200g: 260 cal; chicken@150g: 247.5 cal
        let expectedCalories = 155.0 + 260.0 + 247.5
        #expect(abs(plan.totalMacros.calories - expectedCalories) < 0.01)
    }

    @Test("totalMacros is zero for a plan with no meals")
    @MainActor
    func totalMacros_emptyPlan() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let plan = NutritionPlan(name: "Plan vacío", startDate: Date())
        context.insert(plan)

        #expect(plan.totalMacros == .zero)
    }

    @Test("targetMacros treats nil target fields as zero")
    @MainActor
    func targetMacros_nilFieldsAreZero() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let plan = NutritionPlan(name: "Plan", startDate: Date())
        plan.targetCalories = 2000
        context.insert(plan)

        #expect(plan.targetMacros.calories == 2000)
        #expect(plan.targetMacros.protein == 0)
    }
}

// MARK: - MacroProgressRow progress logic (pure, no rendering needed)

@Suite("MacroProgressRow — progress logic")
struct MacroProgressRowLogicTests {

    @Test("target <= 0 yields zero ratio and zero percentage")
    func noTarget_zeroRatio() {
        let row = MacroProgressRow(title: "Calorías", current: 500, target: 0, unit: "kcal", color: .orange)
        #expect(row.ratio == 0)
        #expect(row.percentage == 0)
    }

    @Test("target <= 0 uses the tertiary (neutral) bar color")
    func noTarget_neutralColor() {
        let row = MacroProgressRow(title: "Calorías", current: 500, target: 0, unit: "kcal", color: .orange)
        #expect(row.barColor == AppColors.tertiaryText)
    }

    @Test("50/100 yields 50% progress")
    func halfProgress_fiftyPercent() {
        let row = MacroProgressRow(title: "Proteína", current: 50, target: 100, unit: "g", color: .red)
        #expect(row.ratio == 0.5)
        #expect(row.percentage == 50)
    }

    @Test("below 90% uses the deficit (error) color")
    func belowNinety_errorColor() {
        let row = MacroProgressRow(title: "Proteína", current: 80, target: 100, unit: "g", color: .red)
        #expect(row.barColor == AppColors.error)
    }

    @Test("between 90% and 105% uses the on-target (success) color")
    func onTarget_successColor() {
        let row = MacroProgressRow(title: "Proteína", current: 95, target: 100, unit: "g", color: .red)
        #expect(row.barColor == AppColors.success)
    }

    @Test("exactly 105% is still within the on-target band")
    func exactUpperBound_successColor() {
        let row = MacroProgressRow(title: "Proteína", current: 105, target: 100, unit: "g", color: .red)
        #expect(row.barColor == AppColors.success)
    }

    @Test("above 105% uses the excess (warning) color")
    func aboveOneOhFive_warningColor() {
        let row = MacroProgressRow(title: "Proteína", current: 120, target: 100, unit: "g", color: .red)
        #expect(row.barColor == AppColors.warning)
        #expect(row.percentage == 120)
    }
}

// MARK: - NutritionPlanRepository target persistence

@Suite("NutritionPlanRepository — target persistence", .serialized)
struct NutritionPlanRepositoryTargetTests {

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(GYMAppSchemaV1.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test("update persists all target fields")
    @MainActor
    func update_persistsAllTargets() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let athlete = Athlete(name: "Atleta de prueba")
        context.insert(athlete)
        let repo = NutritionPlanRepository(context: context)

        let plan = try repo.add(name: "Plan de volumen", startDate: Date(), to: athlete)
        try repo.update(
            plan, name: plan.name, startDate: plan.startDate, endDate: nil, notes: nil,
            targetCalories: 2800, targetProtein: 180, targetCarbohydrates: 300,
            targetFat: 90, targetFiber: 30
        )

        #expect(plan.targetCalories == 2800)
        #expect(plan.targetProtein == 180)
        #expect(plan.targetCarbohydrates == 300)
        #expect(plan.targetFat == 90)
        #expect(plan.targetFiber == 30)
    }

    @Test("fetchAll returns the plan with targets intact")
    @MainActor
    func fetchAll_returnsTargetsIntact() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let athlete = Athlete(name: "Atleta de prueba")
        context.insert(athlete)
        let repo = NutritionPlanRepository(context: context)

        let plan = try repo.add(name: "Plan", startDate: Date(), to: athlete)
        try repo.update(
            plan, name: plan.name, startDate: plan.startDate, endDate: nil, notes: nil,
            targetCalories: 2200, targetProtein: 150, targetCarbohydrates: nil,
            targetFat: nil, targetFiber: nil
        )

        let fetched = try repo.fetchAll(for: athlete)
        #expect(fetched.first?.targetCalories == 2200)
        #expect(fetched.first?.targetProtein == 150)
        #expect(fetched.first?.targetCarbohydrates == nil)
    }

    @Test("update can clear a previously set target back to nil")
    @MainActor
    func update_canClearTargetToNil() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let athlete = Athlete(name: "Atleta de prueba")
        context.insert(athlete)
        let repo = NutritionPlanRepository(context: context)

        let plan = try repo.add(name: "Plan", startDate: Date(), to: athlete)
        try repo.update(
            plan, name: plan.name, startDate: plan.startDate, endDate: nil, notes: nil,
            targetCalories: 2500, targetProtein: nil, targetCarbohydrates: nil,
            targetFat: nil, targetFiber: nil
        )
        #expect(plan.targetCalories == 2500)

        try repo.update(
            plan, name: plan.name, startDate: plan.startDate, endDate: nil, notes: nil,
            targetCalories: nil, targetProtein: nil, targetCarbohydrates: nil,
            targetFat: nil, targetFiber: nil
        )
        #expect(plan.targetCalories == nil)
    }

    @Test("duplicate carries over all target fields to the copy")
    @MainActor
    func duplicate_carriesOverTargets() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let athlete = Athlete(name: "Atleta de prueba")
        context.insert(athlete)
        let repo = NutritionPlanRepository(context: context)

        let plan = try repo.add(name: "Plan original", startDate: Date(), to: athlete)
        try repo.update(
            plan, name: plan.name, startDate: plan.startDate, endDate: nil, notes: nil,
            targetCalories: 1900, targetProtein: 120, targetCarbohydrates: 200,
            targetFat: 60, targetFiber: 25
        )

        let copy = try repo.duplicate(plan, for: athlete)

        #expect(copy.targetCalories == 1900)
        #expect(copy.targetProtein == 120)
        #expect(copy.targetCarbohydrates == 200)
        #expect(copy.targetFat == 60)
        #expect(copy.targetFiber == 25)
    }
}
