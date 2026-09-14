//
//  FoodCategory.swift
//  GYM APP
//

import Foundation

/// Extensible food category backed by a String raw value.
///
/// Use the static constants for the 12 standard categories.
/// Create custom categories via `FoodCategory(rawValue: "my_category")`.
/// Stored in SwiftData via the `Food.categoryRaw: String` field (not this type directly)
/// so that adding new categories never requires a SwiftData migration.
struct FoodCategory: RawRepresentable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - Standard categories

extension FoodCategory {
    static let proteinas     = FoodCategory(rawValue: "proteinas")
    static let carbohidratos = FoodCategory(rawValue: "carbohidratos")
    static let frutas        = FoodCategory(rawValue: "frutas")
    static let verduras      = FoodCategory(rawValue: "verduras")
    static let grasas        = FoodCategory(rawValue: "grasas")
    static let lacteos       = FoodCategory(rawValue: "lacteos")
    static let cereales      = FoodCategory(rawValue: "cereales")
    static let legumbres     = FoodCategory(rawValue: "legumbres")
    static let snacks        = FoodCategory(rawValue: "snacks")
    static let bebidas       = FoodCategory(rawValue: "bebidas")
    static let preparaciones = FoodCategory(rawValue: "preparaciones")
    static let otros         = FoodCategory(rawValue: "otros")

    static let all: [FoodCategory] = [
        .proteinas, .carbohidratos, .frutas, .verduras, .grasas,
        .lacteos, .cereales, .legumbres, .snacks, .bebidas,
        .preparaciones, .otros
    ]

    var displayName: String {
        switch rawValue {
        case "proteinas":     return "Proteínas"
        case "carbohidratos": return "Carbohidratos"
        case "frutas":        return "Frutas"
        case "verduras":      return "Verduras"
        case "grasas":        return "Grasas"
        case "lacteos":       return "Lácteos"
        case "cereales":      return "Cereales"
        case "legumbres":     return "Legumbres"
        case "snacks":        return "Snacks"
        case "bebidas":       return "Bebidas"
        case "preparaciones": return "Preparaciones"
        case "otros":         return "Otros"
        default:              return rawValue.capitalized
        }
    }
}

// MARK: - Codable (encodes as plain String, not {"rawValue":"..."})

extension FoodCategory: Codable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }
}
