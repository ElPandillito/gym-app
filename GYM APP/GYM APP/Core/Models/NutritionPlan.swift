//
//  NutritionPlan.swift
//  GYM APP
//

import SwiftData
import Foundation

/// A coach-created nutrition plan assigned to an Athlete.
///
/// Delete rules:
///   athlete:  The plan is owned by Athlete.nutritionPlans (.cascade).
///             Deleting an Athlete also deletes all its NutritionPlans.
///   meals:    .cascade — deleting this plan deletes its Meals.
///
/// Historical integrity:
///   Macro totals are computed from MealItem.macros, which uses frozen per-100g
///   snapshot values. Editing a Food after plan creation does not retroactively
///   change plan totals.
@Model
final class NutritionPlan {
    @Attribute(.unique) var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var notes: String?

    // Daily targets (all optional — coach may set any subset)
    var targetCalories: Double?
    var targetProtein: Double?
    var targetCarbohydrates: Double?
    var targetFat: Double?
    var targetFiber: Double?

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    var athlete: Athlete?

    @Relationship(deleteRule: .cascade, inverse: \Meal.nutritionPlan)
    var meals: [Meal]

    // MARK: - Init

    init(name: String, startDate: Date) {
        self.id        = UUID()
        self.name      = name
        self.startDate = startDate
        self.isActive  = false
        self.meals     = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Computed helpers

extension NutritionPlan {

    var targetMacros: NutritionValues {
        NutritionValues(
            calories:      targetCalories      ?? 0,
            protein:       targetProtein       ?? 0,
            carbohydrates: targetCarbohydrates ?? 0,
            fat:           targetFat           ?? 0,
            fiber:         targetFiber         ?? 0
        )
    }

    var totalMacros: NutritionValues {
        meals.reduce(.zero) { acc, meal in
            acc + meal.items.reduce(.zero) { $0 + $1.macros }
        }
    }

    var sortedMeals: [Meal] {
        meals.sorted { $0.sortOrder < $1.sortOrder }
    }

    var hasTargets: Bool {
        (targetCalories ?? 0) > 0 || (targetProtein ?? 0) > 0
    }

    var dateRangeText: String {
        let fmt = Date.FormatStyle().month(.abbreviated).day().year()
        if let end = endDate {
            return "\(startDate.formatted(fmt)) – \(end.formatted(fmt))"
        }
        return "Desde \(startDate.formatted(fmt))"
    }
}
