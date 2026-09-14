//
//  Meal.swift
//  GYM APP
//

import SwiftData
import Foundation

/// A named meal (e.g. "Desayuno", "Comida") belonging to a NutritionPlan.
///
/// Delete rules:
///   nutritionPlan: owned by NutritionPlan.meals (.cascade) — plan deletion removes meals.
///   items:         .cascade — deleting this meal deletes its MealItems.
@Model
final class Meal {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    var notes: String?
    /// Optional wall-clock reference for display (e.g. "08:00").
    /// Only the hour/minute components are displayed. Never used in calculations.
    var time: Date?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    var nutritionPlan: NutritionPlan?

    @Relationship(deleteRule: .cascade, inverse: \MealItem.meal)
    var items: [MealItem]

    // MARK: - Init

    init(name: String, sortOrder: Int = 0, time: Date? = nil) {
        self.id        = UUID()
        self.name      = name
        self.sortOrder = sortOrder
        self.time      = time
        self.items     = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Computed helpers

extension Meal {

    var totalMacros: NutritionValues {
        items.reduce(.zero) { $0 + $1.macros }
    }

    var sortedItems: [MealItem] {
        items.sorted { $0.sortOrder < $1.sortOrder }
    }

    var timeText: String? {
        guard let t = time else { return nil }
        return t.formatted(.dateTime.hour().minute())
    }
}
