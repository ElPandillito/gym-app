//
//  FoodSource.swift
//  GYM APP
//

import Foundation

enum FoodSource: String, Codable, CaseIterable {
    case system   = "system"
    case coach    = "coach"
    case external = "external"
    case custom   = "custom"

    var displayName: String {
        switch self {
        case .system:   return "Sistema"
        case .coach:    return "Coach"
        case .external: return "Externo"
        case .custom:   return "Personalizado"
        }
    }
}
