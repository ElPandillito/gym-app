//
//  FoodMacrosCalculatorTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("FoodMacrosCalculator")
struct FoodMacrosCalculatorTests {

    private func makeFood(
        calories: Double = 200, protein: Double = 20,
        carbs: Double = 25, fat: Double = 10, fiber: Double = 2,
        servingSize: Double? = nil, servingUnit: FoodUnit? = nil,
        ingredients: [RecipeIngredientSnapshot] = []
    ) -> FoodSnapshot {
        FoodSnapshot(
            id: UUID(), name: "TestFood",
            kind: .ingredient, category: .preparaciones, source: .coach,
            nutritionPer100g: NutritionValues(
                calories: calories, protein: protein,
                carbohydrates: carbs, fat: fat, fiber: fiber
            ),
            servingSize: servingSize, servingUnit: servingUnit,
            brand: nil, tags: [], ingredients: ingredients,
            createdAt: .distantPast
        )
    }

    // MARK: - macros(for:amount:unit:)

    @Test("50 g returns half the per-100 g values")
    func macrosFor50Grams() {
        let result = FoodMacrosCalculator.macros(
            for: makeFood(calories: 200, protein: 20, carbs: 25, fat: 10, fiber: 2),
            amount: 50, unit: .grams
        )
        #expect(abs(result.calories      - 100)  < 0.001)
        #expect(abs(result.protein       - 10)   < 0.001)
        #expect(abs(result.carbohydrates - 12.5) < 0.001)
        #expect(abs(result.fat           - 5)    < 0.001)
        #expect(abs(result.fiber         - 1)    < 0.001)
    }

    @Test("100 g returns per-100 g values unchanged")
    func macrosFor100Grams() {
        let result = FoodMacrosCalculator.macros(
            for: makeFood(calories: 400, protein: 30),
            amount: 100, unit: .grams
        )
        #expect(abs(result.calories - 400) < 0.001)
        #expect(abs(result.protein  - 30)  < 0.001)
    }

    @Test("0 g returns all zeros")
    func macrosForZeroGrams() {
        let result = FoodMacrosCalculator.macros(for: makeFood(), amount: 0, unit: .grams)
        #expect(result.calories == 0)
        #expect(result.protein  == 0)
    }

    @Test("1 kg converts to 1000 g before scaling")
    func macrosForOneKilogram() {
        let result = FoodMacrosCalculator.macros(
            for: makeFood(calories: 200, protein: 20),
            amount: 1, unit: .kilograms
        )
        #expect(abs(result.calories - 2000) < 0.001)
        #expect(abs(result.protein  - 200)  < 0.001)
    }

    @Test("1 l converts to 1000 ml before scaling")
    func macrosForOneLiter() {
        let result = FoodMacrosCalculator.macros(
            for: makeFood(calories: 100),
            amount: 1, unit: .liters
        )
        #expect(abs(result.calories - 1000) < 0.001)
    }

    // MARK: - toGrams

    @Test("toGrams is identity for .grams")
    func toGramsGramsUnit() {
        let g = FoodMacrosCalculator.toGrams(amount: 150, unit: .grams, servingSize: nil)
        #expect(abs(g - 150) < 0.001)
    }

    @Test("toGrams multiplies by 1000 for .kilograms")
    func toGramsKilogramsUnit() {
        let g = FoodMacrosCalculator.toGrams(amount: 0.5, unit: .kilograms, servingSize: nil)
        #expect(abs(g - 500) < 0.001)
    }

    @Test("toGrams multiplies by 1000 for .liters")
    func toGramsLitersUnit() {
        let g = FoodMacrosCalculator.toGrams(amount: 2, unit: .liters, servingSize: nil)
        #expect(abs(g - 2000) < 0.001)
    }

    @Test("toGrams uses servingSize for non-metric units")
    func toGramsWithServingSize() {
        let g = FoodMacrosCalculator.toGrams(amount: 2, unit: .piece, servingSize: 40)
        #expect(abs(g - 80) < 0.001)
    }

    @Test("toGrams defaults to 100 when servingSize is nil for non-metric units")
    func toGramsServingSizeNilFallsBackTo100() {
        let g = FoodMacrosCalculator.toGrams(amount: 2, unit: .piece, servingSize: nil)
        #expect(abs(g - 200) < 0.001)
    }

    // MARK: - recipeMacros

    @Test("recipeMacros with no ingredients returns nutritionPer100g")
    func recipeMacrosNoIngredients() {
        let result = FoodMacrosCalculator.recipeMacros(for: makeFood(calories: 350, protein: 25))
        #expect(abs(result.calories - 350) < 0.001)
        #expect(abs(result.protein  - 25)  < 0.001)
    }

    @Test("recipeMacros sums scaled ingredient nutrition")
    func recipeMacrosWithOneIngredient() {
        let ingredient = RecipeIngredientSnapshot(
            id: UUID(), ingredientID: UUID(), ingredientName: "Pollo",
            nutritionPer100g: NutritionValues(
                calories: 165, protein: 31, carbohydrates: 0, fat: 3.6, fiber: 0
            ),
            servingSize: nil, servingUnit: nil,
            amountGrams: 200, sortOrder: 0
        )
        let recipe = makeFood(
            calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0,
            ingredients: [ingredient]
        )
        let result = FoodMacrosCalculator.recipeMacros(for: recipe)
        // 165 × (200/100) = 330 kcal; 31 × (200/100) = 62 g protein
        #expect(abs(result.calories - 330) < 0.5)
        #expect(abs(result.protein  - 62)  < 0.5)
    }
}
