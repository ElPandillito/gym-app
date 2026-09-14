//
//  NutritionPlanRepositoryProtocol.swift
//  GYM APP
//

import Foundation
import SwiftData

protocol NutritionPlanRepositoryProtocol {
    func add(name: String, startDate: Date, to athlete: Athlete) throws -> NutritionPlan
    func update(_ plan: NutritionPlan, name: String, startDate: Date, endDate: Date?,
                notes: String?, targetCalories: Double?, targetProtein: Double?,
                targetCarbohydrates: Double?, targetFat: Double?, targetFiber: Double?) throws
    func activate(_ plan: NutritionPlan) throws
    func deactivate(_ plan: NutritionPlan) throws
    func delete(_ plan: NutritionPlan) throws
    func duplicate(_ plan: NutritionPlan, for athlete: Athlete) throws -> NutritionPlan
    func fetchAll(for athlete: Athlete) throws -> [NutritionPlan]
}
