//
//  NutritionPlanListViewModel.swift
//  GYM APP
//

import Foundation
import SwiftData

/// Coordinates mutations on NutritionPlan records.
/// The UI reads the live list via `athlete.nutritionPlans` directly from SwiftData.
@Observable
@MainActor
final class NutritionPlanListViewModel {

    var errorMessage: String?

    private let repository: NutritionPlanRepository

    init(context: ModelContext) {
        self.repository = NutritionPlanRepository(context: context)
    }

    func activate(_ plan: NutritionPlan) {
        do {
            try repository.activate(plan)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deactivate(_ plan: NutritionPlan) {
        do {
            try repository.deactivate(plan)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ plan: NutritionPlan) {
        do {
            try repository.delete(plan)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func duplicate(_ plan: NutritionPlan, for athlete: Athlete) {
        do {
            try repository.duplicate(plan, for: athlete)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
