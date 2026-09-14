//
//  FoodKind.swift
//  GYM APP
//

import Foundation

enum FoodKind: String, Codable, CaseIterable {
    case ingredient   = "ingredient"
    case preparedFood = "preparedFood"

    var displayName: String {
        switch self {
        case .ingredient:   return "Ingrediente"
        case .preparedFood: return "Alimento preparado"
        }
    }
}
