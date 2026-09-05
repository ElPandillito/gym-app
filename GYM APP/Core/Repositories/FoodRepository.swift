//
//  FoodRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct FoodRepository: FoodRepositoryProtocol {

    private let context: ModelContext
    private let imageStorage: FoodImageStorageServiceProtocol

    init(context: ModelContext, imageStorage: FoodImageStorageServiceProtocol) {
        self.context      = context
        self.imageStorage = imageStorage
    }

    /// Convenience factory that wires the default concrete services.
    static func make(context: ModelContext) -> FoodRepository {
        FoodRepository(context: context, imageStorage: FoodImageStorageService())
    }

    // MARK: - Add (standard — inserts + saves immediately)

    func add(
        name: String,
        kind: FoodKind,
        category: FoodCategory,
        source: FoodSource
    ) throws -> Food {
        let food = Food(name: name, kind: kind, category: category, source: source)
        context.insert(food)
        try context.save()
        return food
    }

    // MARK: - Update

    func update(
        _ food: Food,
        name: String,
        kind: FoodKind,
        category: FoodCategory,
        calories: Double?,
        protein: Double?,
        carbohydrates: Double?,
        fat: Double?,
        fiber: Double?,
        servingSize: Double?,
        servingUnit: FoodUnit?,
        brand: String?,
        tags: [String]
    ) throws {
        food.name          = name
        food.kind          = kind
        food.category      = category
        food.calories      = calories
        food.protein       = protein
        food.carbohydrates = carbohydrates
        food.fat           = fat
        food.fiber         = fiber
        food.servingSize   = servingSize
        food.servingUnit   = servingUnit
        food.brand         = brand
        food.tags          = tags
        food.updatedAt     = Date()
        try context.save()
    }

    // MARK: - Delete

    /// Deletes the food after verifying it is not used as an ingredient in any recipe
    /// or referenced by any MealItem in a nutrition plan.
    ///
    /// - Throws: `FoodError.isUsedAsIngredient` if in a recipe — remove it first.
    /// - Throws: `FoodError.isUsedInNutritionPlans` if referenced by MealItems.
    ///   Use `forceDelete(_:)` to proceed; snapshots preserve historical integrity.
    func delete(_ food: Food) throws {
        let allIngredients = try context.fetch(FetchDescriptor<RecipeIngredient>())
        let ingredientUsages = allIngredients.filter { $0.ingredient?.id == food.id }
        guard ingredientUsages.isEmpty else {
            throw FoodError.isUsedAsIngredient(recipeCount: ingredientUsages.count)
        }

        let allItems = try context.fetch(FetchDescriptor<MealItem>())
        let planIDs = Set(
            allItems
                .filter { $0.food?.id == food.id }
                .compactMap { $0.meal?.nutritionPlan?.id }
        )
        guard planIDs.isEmpty else {
            throw FoodError.isUsedInNutritionPlans(planCount: planIDs.count)
        }

        try removeImageFiles(from: food)
        context.delete(food)
        try context.save()
    }

    /// Removes the food from the library unconditionally.
    ///
    /// MealItem.food uses SwiftData nullify — the relationship becomes nil on deletion.
    /// Existing plans retain their historical macros via per-100g snapshot fields.
    func forceDelete(_ food: Food) throws {
        // Recipe ingredient check still applies — removing a base food from a recipe
        // would break its composition. This is not protected by snapshots.
        let allIngredients = try context.fetch(FetchDescriptor<RecipeIngredient>())
        let ingredientUsages = allIngredients.filter { $0.ingredient?.id == food.id }
        guard ingredientUsages.isEmpty else {
            throw FoodError.isUsedAsIngredient(recipeCount: ingredientUsages.count)
        }

        // MealItem usages are safe to ignore — snapshot values survive food deletion.
        try removeImageFiles(from: food)
        context.delete(food)
        try context.save()
    }

    // MARK: - Fetch

    func fetch(id: UUID) throws -> Food? {
        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func fetchAll() throws -> [Food] {
        let descriptor = FetchDescriptor<Food>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func fetch(kind: FoodKind) throws -> [Food] {
        let raw = kind.rawValue
        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { $0.kindRaw == raw },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func fetch(category: FoodCategory) throws -> [Food] {
        let raw = category.rawValue
        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { $0.categoryRaw == raw },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Image (standard — inserts + saves immediately)

    func setImage(data: Data, for food: Food) throws {
        if let existing = food.image {
            try? imageStorage.delete(relativePath: existing.originalPath)
            if let thumbPath = existing.thumbnailPath {
                try? imageStorage.delete(relativePath: thumbPath)
            }
            context.delete(existing)
        }

        let path  = try imageStorage.saveOriginal(data: data, foodID: food.id)
        let image = FoodImage(originalPath: path)
        image.food = food
        food.image = image
        food.updatedAt = Date()
        context.insert(image)
        try context.save()
    }

    func generateThumbnailIfNeeded(for food: Food) throws {
        guard let image = food.image, !image.isProcessed else { return }
        image.thumbnailPath = try imageStorage.generateAndSaveThumbnail(
            from: image.originalPath,
            foodID: food.id
        )
        image.isProcessed = true
        try context.save()
    }

    func removeImage(from food: Food) throws {
        guard let image = food.image else { return }
        try? imageStorage.delete(relativePath: image.originalPath)
        if let thumbPath = image.thumbnailPath {
            try? imageStorage.delete(relativePath: thumbPath)
        }
        context.delete(image)
        food.image     = nil
        food.updatedAt = Date()
        try context.save()
    }

    // MARK: - Insert-only variants (used by PreparedFoodFormViewModel two-phase creation)
    //
    // These methods perform partial work without calling context.save().
    // The orchestrator (PreparedFoodFormViewModel) controls the single final commit
    // so that context.rollback() can undo all insertions if any phase fails.

    /// Writes the image file to disk only. No SwiftData operation.
    /// Caller appends the returned path to its rollback journal immediately.
    func prepareImageFile(data: Data, foodID: UUID) throws -> String {
        return try imageStorage.saveOriginal(data: data, foodID: foodID)
    }

    /// Inserts the Food into context without saving.
    func insertNew(_ food: Food) {
        context.insert(food)
    }

    /// Inserts a FoodImage record into context without saving.
    func insertFoodImage(_ image: FoodImage) {
        context.insert(image)
    }

    // MARK: - Private helpers

    private func removeImageFiles(from food: Food) throws {
        if let image = food.image {
            try? imageStorage.delete(relativePath: image.originalPath)
            if let thumbPath = image.thumbnailPath {
                try? imageStorage.delete(relativePath: thumbPath)
            }
        }
    }
}

// MARK: - Errors

enum FoodError: LocalizedError {
    case isUsedAsIngredient(recipeCount: Int)
    case isUsedInNutritionPlans(planCount: Int)

    var errorDescription: String? {
        switch self {
        case .isUsedAsIngredient(let count):
            let plural = count == 1 ? "receta" : "recetas"
            return "Este alimento se usa en \(count) \(plural). Elimínalo de todas las recetas antes de borrarlo."
        case .isUsedInNutritionPlans(let count):
            let plural = count == 1 ? "plan nutricional" : "planes nutricionales"
            return "Este alimento aparece en \(count) \(plural)."
        }
    }
}
