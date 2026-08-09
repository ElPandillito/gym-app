//
//  PreparedFoodFormViewModel.swift
//  GYM APP
//

import Foundation
import SwiftUI
import SwiftData

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@Observable
@MainActor
final class PreparedFoodFormViewModel {

    // MARK: - Mode

    enum Mode {
        case create
        case edit(Food)
    }

    // MARK: - In-memory ingredient entry

    struct IngredientEntry: Identifiable {
        let id: UUID
        let food: Food
        var amountGrams: Double
        var sortOrder: Int
    }

    // MARK: - Form fields

    var name: String = ""
    var category: FoodCategory = .preparaciones
    var brand: String = ""
    var tagsText: String = ""
    var servings: Int = 1

    // MARK: - Ingredients

    var pendingIngredients: [IngredientEntry] = []

    // MARK: - Image

    var pendingImageData: Data? = nil
    var previewImage: PlatformImage? = nil
    var existingImagePath: String? = nil
    var hasExistingImage: Bool = false
    var shouldRemoveImage: Bool = false

    // MARK: - State

    var isSaving: Bool = false
    var validationErrors: [String] = []

    // MARK: - Computed nutrition

    var totalMacros: NutritionValues {
        pendingIngredients.reduce(.zero) { acc, entry in
            acc + FoodMacrosCalculator.macros(
                for: entry.food.snapshot(),
                amount: entry.amountGrams,
                unit: .grams
            )
        }
    }

    var perServingMacros: NutritionValues {
        guard servings > 0 else { return totalMacros }
        return totalMacros.scaled(by: 1.0 / Double(servings))
    }

    // MARK: - Computed state

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && !pendingIngredients.isEmpty
        && !isSaving
    }

    // MARK: - Private

    private let mode: Mode
    private let foodRepository: FoodRepository
    private let ingredientRepository: RecipeIngredientRepository

    // MARK: - Init

    init(mode: Mode, context: ModelContext) {
        self.mode = mode
        self.foodRepository = FoodRepository.make(context: context)
        self.ingredientRepository = RecipeIngredientRepository(context: context)

        if case .edit(let food) = mode {
            loadFields(from: food)
        }
    }

    // MARK: - Ingredient management

    func addIngredient(_ food: Food, amountGrams: Double) {
        let entry = IngredientEntry(
            id: UUID(),
            food: food,
            amountGrams: max(1, amountGrams),
            sortOrder: pendingIngredients.count
        )
        pendingIngredients.append(entry)
    }

    func removeIngredients(at offsets: IndexSet) {
        pendingIngredients.remove(atOffsets: offsets)
        for (i, _) in pendingIngredients.enumerated() {
            pendingIngredients[i].sortOrder = i
        }
    }

    func updateAmount(for id: UUID, amountGrams: Double) {
        guard amountGrams > 0,
              let idx = pendingIngredients.firstIndex(where: { $0.id == id }) else { return }
        pendingIngredients[idx].amountGrams = amountGrams
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        pendingIngredients.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (i, _) in pendingIngredients.enumerated() {
            pendingIngredients[i].sortOrder = i
        }
    }

    // MARK: - Image management

    func applyImageData(_ data: Data) {
        pendingImageData  = data
        shouldRemoveImage = false
        hasExistingImage  = false
        existingImagePath = nil
        #if os(iOS)
        previewImage = UIImage(data: data)
        #elseif os(macOS)
        previewImage = NSImage(data: data)
        #endif
    }

    func removeImage() {
        pendingImageData  = nil
        previewImage      = nil
        existingImagePath = nil
        hasExistingImage  = false
        shouldRemoveImage = true
    }

    // MARK: - Save

    func save() throws {
        var errors: [String] = []
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty { errors.append("El nombre del platillo es requerido.") }
        if pendingIngredients.isEmpty { errors.append("Agrega al menos un ingrediente.") }
        if servings < 1 { errors.append("El número de porciones debe ser al menos 1.") }
        validationErrors = errors
        guard errors.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        let total = totalMacros
        let tags = tagsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let brandVal: String? = brand.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : brand.trimmingCharacters(in: .whitespaces)

        switch mode {
        case .create:
            let food = try foodRepository.add(name: trimmedName, kind: .preparedFood, category: category, source: .coach)
            food.servings = servings
            try foodRepository.update(
                food, name: trimmedName, kind: .preparedFood, category: category,
                calories: total.calories, protein: total.protein,
                carbohydrates: total.carbohydrates, fat: total.fat, fiber: total.fiber,
                servingSize: nil, servingUnit: nil, brand: brandVal, tags: tags
            )
            for (i, entry) in pendingIngredients.enumerated() {
                _ = try ingredientRepository.add(
                    ingredient: entry.food, to: food,
                    amountGrams: entry.amountGrams, sortOrder: i
                )
            }
            if let imageData = pendingImageData {
                try foodRepository.setImage(data: imageData, for: food)
                try? foodRepository.generateThumbnailIfNeeded(for: food)
            }

        case .edit(let food):
            food.servings = servings
            try foodRepository.update(
                food, name: trimmedName, kind: .preparedFood, category: category,
                calories: total.calories, protein: total.protein,
                carbohydrates: total.carbohydrates, fat: total.fat, fiber: total.fiber,
                servingSize: nil, servingUnit: nil, brand: brandVal, tags: tags
            )
            try ingredientRepository.removeAll(from: food)
            for (i, entry) in pendingIngredients.enumerated() {
                _ = try ingredientRepository.add(
                    ingredient: entry.food, to: food,
                    amountGrams: entry.amountGrams, sortOrder: i
                )
            }
            if let imageData = pendingImageData {
                try foodRepository.setImage(data: imageData, for: food)
                try? foodRepository.generateThumbnailIfNeeded(for: food)
            } else if shouldRemoveImage {
                try foodRepository.removeImage(from: food)
            }
        }
    }

    // MARK: - Load existing food (edit mode)

    private func loadFields(from food: Food) {
        name     = food.name
        category = food.category
        brand    = food.brand ?? ""
        tagsText = food.tags.joined(separator: ", ")
        servings = food.servings ?? 1

        let sorted = food.ingredients.sorted { $0.sortOrder < $1.sortOrder }
        pendingIngredients = sorted.compactMap { ri in
            guard let ing = ri.ingredient else { return nil }
            return IngredientEntry(
                id: UUID(),
                food: ing,
                amountGrams: ri.amountGrams,
                sortOrder: ri.sortOrder
            )
        }

        let imgPath = food.image?.thumbnailPath ?? food.image?.originalPath
        if let path = imgPath {
            existingImagePath = path
            hasExistingImage  = true
            if let cached = PhotoImageCache.shared.image(for: path) {
                previewImage = cached
            }
        }
    }
}
