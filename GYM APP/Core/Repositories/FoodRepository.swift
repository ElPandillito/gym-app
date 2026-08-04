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

    // MARK: - Add

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

    /// Deletes the food after verifying it is not used as an ingredient in any recipe.
    ///
    /// Business rule: deleting a base food that is part of a recipe would silently
    /// invalidate the recipe's composition. Callers must remove the food from all
    /// recipes via RecipeIngredientRepository before deleting.
    func delete(_ food: Food) throws {
        let allEntries = try context.fetch(FetchDescriptor<RecipeIngredient>())
        let usages = allEntries.filter { $0.ingredient?.id == food.id }
        guard usages.isEmpty else {
            throw FoodError.isUsedAsIngredient(recipeCount: usages.count)
        }

        // Remove image files before SwiftData cascade-deletes the FoodImage record.
        if let image = food.image {
            try? imageStorage.delete(relativePath: image.originalPath)
            if let thumbPath = image.thumbnailPath {
                try? imageStorage.delete(relativePath: thumbPath)
            }
        }

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

    // MARK: - Image

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
}

// MARK: - Errors

enum FoodError: LocalizedError {
    case isUsedAsIngredient(recipeCount: Int)

    var errorDescription: String? {
        switch self {
        case .isUsedAsIngredient(let count):
            let plural = count == 1 ? "receta" : "recetas"
            return "Este alimento se usa en \(count) \(plural). Elimínalo de todas las recetas antes de borrarlo."
        }
    }
}
