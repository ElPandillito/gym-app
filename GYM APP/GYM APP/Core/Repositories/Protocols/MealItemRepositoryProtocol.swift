//
//  MealItemRepositoryProtocol.swift
//  GYM APP
//

import Foundation

protocol MealItemRepositoryProtocol {
    @discardableResult
    func add(food: Food, amountGrams: Double, sortOrder: Int, to meal: Meal) throws -> MealItem
    func update(_ item: MealItem, amountGrams: Double) throws
    func reorder(_ items: [MealItem], in meal: Meal) throws
    func delete(_ item: MealItem) throws
    func removeAll(from meal: Meal) throws
}
