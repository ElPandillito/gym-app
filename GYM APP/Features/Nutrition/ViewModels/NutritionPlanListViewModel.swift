//
//  NutritionPlanListViewModel.swift
//  GYM APP
//

import Foundation
import SwiftData

@Observable
@MainActor
final class NutritionPlanListViewModel {

    var plans: [NutritionPlan] = []
    var errorMessage: String?

    private let repository: NutritionPlanRepository

    init(context: ModelContext) {
        self.repository = NutritionPlanRepository(context: context)
    }

    func load(for athlete: Athlete) {
        do {
            plans = try repository.fetchAll(for: athlete)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func activate(_ plan: NutritionPlan, for athlete: Athlete) {
        do {
            try repository.activate(plan)
            load(for: athlete)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deactivate(_ plan: NutritionPlan, for athlete: Athlete) {
        do {
            try repository.deactivate(plan)
            load(for: athlete)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ plan: NutritionPlan, for athlete: Athlete) {
        do {
            try repository.delete(plan)
            load(for: athlete)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
