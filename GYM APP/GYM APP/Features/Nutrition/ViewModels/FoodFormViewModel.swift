//
//  FoodFormViewModel.swift
//  GYM APP
//

import Foundation
import SwiftData

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@Observable
@MainActor
final class FoodFormViewModel {

    // MARK: - Mode

    enum Mode {
        case create
        case edit(Food)
    }

    // MARK: - Form fields

    var name: String = ""
    var kind: FoodKind = .ingredient
    var category: FoodCategory = .proteinas
    var brand: String = ""
    var tagsText: String = ""

    // Macros per 100 g (stored as text for TextField binding)
    var caloriesText: String = ""
    var proteinText: String = ""
    var carbsText: String = ""
    var fatText: String = ""
    var fiberText: String = ""

    // Portion
    var servingUnit: FoodUnit = .grams
    var servingSizeText: String = ""

    // Image
    var pendingImageData: Data? = nil
    var previewImage: PlatformImage? = nil
    var existingImagePath: String? = nil
    var hasExistingImage: Bool = false
    var shouldRemoveImage: Bool = false

    // State
    var isSaving: Bool = false
    var validationErrors: [String] = []

    // MARK: - Computed

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    // MARK: - Private

    private let mode: Mode
    private let repository: FoodRepository

    // MARK: - Init

    init(mode: Mode, context: ModelContext) {
        self.mode = mode
        self.repository = FoodRepository.make(context: context)

        if case .edit(let food) = mode {
            loadFields(from: food)
        }
    }

    // MARK: - Load existing food (edit mode)

    private func loadFields(from food: Food) {
        name     = food.name
        kind     = food.kind
        category = food.category
        brand    = food.brand ?? ""
        tagsText = food.tags.joined(separator: ", ")

        caloriesText = food.calories.map      { fmt($0) } ?? ""
        proteinText  = food.protein.map       { fmt($0) } ?? ""
        carbsText    = food.carbohydrates.map { fmt($0) } ?? ""
        fatText      = food.fat.map           { fmt($0) } ?? ""
        fiberText    = food.fiber.map         { fmt($0) } ?? ""

        if let size = food.servingSize { servingSizeText = fmt(size) }
        servingUnit = food.servingUnit ?? .grams

        let imgPath = food.image?.thumbnailPath ?? food.image?.originalPath
        if let path = imgPath {
            existingImagePath = path
            hasExistingImage  = true
            if let cached = PhotoImageCache.shared.image(for: path) {
                previewImage = cached
            }
        }
    }

    private func fmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v)
            : String(format: "%.1f", v)
    }

    // MARK: - Save (create or edit)

    /// Validates all fields. Sets `validationErrors` and returns without throwing if invalid.
    /// Throws only for repository-level failures (disk, SwiftData).
    func save() throws {
        let errors = FoodValidator.validate(
            name: name,
            calories: Double(caloriesText),
            protein: Double(proteinText),
            carbohydrates: Double(carbsText),
            fat: Double(fatText),
            fiber: Double(fiberText),
            servingSize: servingUnit.requiresServingSize ? Double(servingSizeText) : nil
        )
        validationErrors = errors
        guard errors.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        let calories = Double(caloriesText)
        let protein  = Double(proteinText)
        let carbs    = Double(carbsText)
        let fat      = Double(fatText)
        let fiber    = Double(fiberText)
        let size: Double?   = servingUnit.requiresServingSize ? Double(servingSizeText) : nil
        let unit: FoodUnit? = servingUnit
        let tags    = tagsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let brandVal: String? = brand.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil
            : brand.trimmingCharacters(in: .whitespaces)

        switch mode {
        case .create:
            let food = try repository.add(name: name, kind: kind, category: category, source: .coach)
            try repository.update(
                food, name: name, kind: kind, category: category,
                calories: calories, protein: protein, carbohydrates: carbs,
                fat: fat, fiber: fiber, servingSize: size,
                servingUnit: unit, brand: brandVal, tags: tags
            )
            if let imageData = pendingImageData {
                try repository.setImage(data: imageData, for: food)
                try? repository.generateThumbnailIfNeeded(for: food)
            }

        case .edit(let food):
            try repository.update(
                food, name: name, kind: kind, category: category,
                calories: calories, protein: protein, carbohydrates: carbs,
                fat: fat, fiber: fiber, servingSize: size,
                servingUnit: unit, brand: brandVal, tags: tags
            )
            if let imageData = pendingImageData {
                try repository.setImage(data: imageData, for: food)
                try? repository.generateThumbnailIfNeeded(for: food)
            } else if shouldRemoveImage {
                try repository.removeImage(from: food)
            }
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
}
