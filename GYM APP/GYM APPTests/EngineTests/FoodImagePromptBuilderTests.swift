//
//  FoodImagePromptBuilderTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("FoodImagePromptBuilder")
struct FoodImagePromptBuilderTests {

    private let builder = FoodImagePromptBuilder()
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Fixtures

    private func makeIngredient(
        name: String,
        amountGrams: Double,
        sortOrder: Int = 0
    ) -> RecipeIngredientSnapshot {
        RecipeIngredientSnapshot(
            id: UUID(),
            ingredientID: UUID(),
            ingredientName: name,
            nutritionPer100g: NutritionValues(calories: 100, protein: 10, carbohydrates: 15, fat: 5, fiber: 2),
            servingSize: nil,
            servingUnit: nil,
            amountGrams: amountGrams,
            sortOrder: sortOrder
        )
    }

    private func makeIngredientFood(name: String = "Pechuga de Pollo") -> FoodSnapshot {
        FoodSnapshot(
            id: UUID(), name: name,
            kind: .ingredient, category: .proteinas, source: .coach,
            nutritionPer100g: NutritionValues(calories: 165, protein: 31, carbohydrates: 0, fat: 3.6, fiber: 0),
            servingSize: nil, servingUnit: nil,
            brand: nil, tags: [],
            ingredients: [],
            createdAt: fixedDate
        )
    }

    private func makePreparedFood(
        name: String = "Bowl de Pollo con Arroz",
        ingredients: [RecipeIngredientSnapshot] = []
    ) -> FoodSnapshot {
        FoodSnapshot(
            id: UUID(), name: name,
            kind: .preparedFood, category: .preparaciones, source: .coach,
            nutritionPer100g: NutritionValues(calories: 200, protein: 18, carbohydrates: 22, fat: 5, fiber: 1),
            servingSize: 350, servingUnit: .grams,
            brand: nil, tags: [],
            ingredients: ingredients,
            createdAt: fixedDate
        )
    }

    // MARK: - Food name is present

    @Test("Prompt includes food name for an ingredient")
    func promptContainsFoodName_ingredient() {
        let food = makeIngredientFood(name: "Salmón al horno")
        let prompt = builder.makePrompt(for: food)
        #expect(prompt.contains("Salmón al horno"))
    }

    @Test("Prompt includes food name for a prepared food")
    func promptContainsFoodName_preparedFood() {
        let food = makePreparedFood(name: "Ensalada César")
        let prompt = builder.makePrompt(for: food)
        #expect(prompt.contains("Ensalada César"))
    }

    // MARK: - Ingredient listing

    @Test("Prompt contains ingredient names for prepared food")
    func promptContainsIngredientNames() {
        let ingredients = [
            makeIngredient(name: "Pollo", amountGrams: 150, sortOrder: 0),
            makeIngredient(name: "Arroz integral", amountGrams: 100, sortOrder: 1),
        ]
        let food = makePreparedFood(ingredients: ingredients)
        let prompt = builder.makePrompt(for: food)
        #expect(prompt.contains("Pollo"))
        #expect(prompt.contains("Arroz integral"))
    }

    @Test("Prompt includes gram amounts for ingredients with amount > 0")
    func promptContainsGramAmounts() {
        let ingredients = [makeIngredient(name: "Atún", amountGrams: 120)]
        let food = makePreparedFood(ingredients: ingredients)
        let prompt = builder.makePrompt(for: food)
        #expect(prompt.contains("120"))
        #expect(prompt.contains("g"))
    }

    @Test("Prompt formats non-integer gram amounts with one decimal")
    func promptFormatsDecimalGrams() {
        let ingredients = [makeIngredient(name: "Aceite de oliva", amountGrams: 7.5)]
        let food = makePreparedFood(ingredients: ingredients)
        let prompt = builder.makePrompt(for: food)
        #expect(prompt.contains("7.5"))
    }

    @Test("Ingredient kind prompt does not include ingredient-list sentence")
    func ingredientKindHasNoIngredientListSentence() {
        let food = makeIngredientFood()
        let prompt = builder.makePrompt(for: food)
        #expect(!prompt.contains("elaborada con"))
    }

    @Test("Prepared food without ingredients generates valid prompt without ingredient list")
    func preparedFoodWithoutIngredients_validPrompt() {
        let food = makePreparedFood(ingredients: [])
        let prompt = builder.makePrompt(for: food)
        #expect(!prompt.isEmpty)
        #expect(prompt.contains(food.name))
        #expect(!prompt.contains("elaborada con"))
    }

    // MARK: - Determinism

    @Test("Same FoodSnapshot produces identical prompt on repeated calls")
    func determinism_sameInputSameOutput() {
        let ingredients = [makeIngredient(name: "Carne de Res", amountGrams: 100)]
        let food = makePreparedFood(name: "Tacos de Res", ingredients: ingredients)
        let p1 = builder.makePrompt(for: food)
        let p2 = builder.makePrompt(for: food)
        #expect(p1 == p2)
    }

    // MARK: - No personal data

    @Test("Prompt does not contain personal data keywords")
    func noPersonalDataKeywords() {
        let food = makeIngredientFood()
        let prompt = builder.makePrompt(for: food)
        let forbidden = ["atleta", "cliente", "paciente", "nombre", "diagnóstico"]
        for word in forbidden {
            #expect(
                !prompt.lowercased().contains(word),
                "Prompt must not contain personal keyword: \(word)"
            )
        }
    }

    // MARK: - Visual restrictions present

    @Test("Prompt contains 'sin personas'")
    func containsNoPersons() {
        let prompt = builder.makePrompt(for: makeIngredientFood())
        #expect(prompt.lowercased().contains("sin personas"))
    }

    @Test("Prompt contains 'sin texto'")
    func containsNoText() {
        let prompt = builder.makePrompt(for: makeIngredientFood())
        #expect(prompt.lowercased().contains("sin texto"))
    }

    @Test("Prompt contains 'sin logotipos'")
    func containsNoLogos() {
        let prompt = builder.makePrompt(for: makeIngredientFood())
        #expect(prompt.lowercased().contains("sin logotipos"))
    }

    @Test("Prompt contains 'sin empaques'")
    func containsNoPackaging() {
        let prompt = builder.makePrompt(for: makeIngredientFood())
        #expect(prompt.lowercased().contains("sin empaques"))
    }

    // MARK: - Ingredient sort order

    @Test("Ingredients appear in ascending sortOrder sequence")
    func ingredientSortOrder_respected() {
        let ingredients = [
            makeIngredient(name: "Zanahoria", amountGrams: 50, sortOrder: 2),
            makeIngredient(name: "Espinaca",  amountGrams: 30, sortOrder: 0),
            makeIngredient(name: "Betabel",   amountGrams: 40, sortOrder: 1),
        ]
        let food = makePreparedFood(ingredients: ingredients)
        let prompt = builder.makePrompt(for: food)
        let espinacaIdx  = prompt.range(of: "Espinaca")!.lowerBound
        let betabelIdx   = prompt.range(of: "Betabel")!.lowerBound
        let zanahoriaIdx = prompt.range(of: "Zanahoria")!.lowerBound
        #expect(espinacaIdx < betabelIdx)
        #expect(betabelIdx  < zanahoriaIdx)
    }

    // MARK: - No invented ingredients

    @Test("Prompt does not invent ingredients absent from the snapshot")
    func noInventedIngredients() {
        let food = makePreparedFood(
            name: "Omelette",
            ingredients: [makeIngredient(name: "Huevo", amountGrams: 100)]
        )
        let prompt = builder.makePrompt(for: food)
        #expect(!prompt.lowercased().contains("queso"))
        #expect(!prompt.lowercased().contains("jamón"))
        #expect(!prompt.lowercased().contains("tomate"))
    }
}
