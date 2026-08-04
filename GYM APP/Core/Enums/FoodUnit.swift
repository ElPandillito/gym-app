//
//  FoodUnit.swift
//  GYM APP
//

import Foundation

enum FoodUnit: String, Codable, CaseIterable {
    case grams       = "g"
    case kilograms   = "kg"
    case milliliters = "ml"
    case liters      = "l"
    case piece       = "pieza"
    case portion     = "porción"
    case tablespoon  = "cda"
    case teaspoon    = "cdita"
    case cup         = "taza"

    var displayName: String {
        switch self {
        case .grams:       return "g"
        case .kilograms:   return "kg"
        case .milliliters: return "ml"
        case .liters:      return "L"
        case .piece:       return "pieza"
        case .portion:     return "porción"
        case .tablespoon:  return "cda"
        case .teaspoon:    return "cdita"
        case .cup:         return "taza"
        }
    }

    /// True for units directly convertible to grams via a constant factor.
    var isWeightBased: Bool {
        self == .grams || self == .kilograms
    }

    /// True for volume units — macro conversion assumes density ≈ water (1 ml = 1 g).
    var isVolumeBased: Bool {
        self == .milliliters || self == .liters
    }

    /// True for countable units that require the food's servingSize for gram conversion.
    var requiresServingSize: Bool {
        !isWeightBased && !isVolumeBased
    }
}
