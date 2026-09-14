//
//  MealRepositoryProtocol.swift
//  GYM APP
//

import Foundation

protocol MealRepositoryProtocol {
    func add(name: String, sortOrder: Int, time: Date?, to plan: NutritionPlan) throws -> Meal
    func update(_ meal: Meal, name: String, notes: String?, time: Date?) throws
    func reorder(_ meals: [Meal], in plan: NutritionPlan) throws
    func delete(_ meal: Meal) throws
}
