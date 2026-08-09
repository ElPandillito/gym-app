//
//  FoodSeeder.swift
//  GYM APP
//

import SwiftData
import Foundation

enum FoodSeeder {

    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { $0.sourceRaw == "system" }
        )
        guard let count = try? context.fetchCount(descriptor), count == 0 else { return }

        makeFoods().forEach { context.insert($0) }
        try? context.save()
    }

    // MARK: - Private

    private static func ingredient(
        name: String,
        category: FoodCategory,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double = 0,
        servingSize: Double? = nil,
        servingUnit: FoodUnit? = nil,
        tags: [String] = []
    ) -> Food {
        let f = Food(name: name, kind: .ingredient, category: category, source: .system)
        f.calories      = calories
        f.protein       = protein
        f.carbohydrates = carbs
        f.fat           = fat
        f.fiber         = fiber
        f.servingSize   = servingSize
        f.servingUnit   = servingUnit
        f.tags          = tags
        return f
    }

    private static func prepared(
        name: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double = 0,
        servingSize: Double,
        tags: [String] = []
    ) -> Food {
        let f = Food(name: name, kind: .preparedFood, category: .preparaciones, source: .system)
        f.calories      = calories
        f.protein       = protein
        f.carbohydrates = carbs
        f.fat           = fat
        f.fiber         = fiber
        f.servingSize   = servingSize
        f.servingUnit   = .grams
        f.tags          = tags
        return f
    }

    private static func makeFoods() -> [Food] {
        [
            // MARK: Proteínas
            ingredient(name: "Pechuga de Pollo",
                       category: .proteinas,
                       calories: 165, protein: 31, carbs: 0, fat: 3.6,
                       servingSize: 100, servingUnit: .grams,
                       tags: ["pollo", "carne", "proteína"]),

            ingredient(name: "Carne Molida 90%",
                       category: .proteinas,
                       calories: 176, protein: 20, carbs: 0, fat: 10,
                       tags: ["carne", "res", "proteína"]),

            ingredient(name: "Atún en Agua",
                       category: .proteinas,
                       calories: 116, protein: 26, carbs: 0, fat: 0.5,
                       servingSize: 140, servingUnit: .grams,
                       tags: ["pescado", "lata", "proteína"]),

            ingredient(name: "Salmón",
                       category: .proteinas,
                       calories: 208, protein: 20, carbs: 0, fat: 13,
                       tags: ["pescado", "omega3", "proteína"]),

            ingredient(name: "Huevo Entero",
                       category: .proteinas,
                       calories: 155, protein: 13, carbs: 1.1, fat: 11,
                       servingSize: 50, servingUnit: .piece,
                       tags: ["huevo", "proteína"]),

            // MARK: Cereales
            ingredient(name: "Arroz Blanco Cocido",
                       category: .cereales,
                       calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4,
                       tags: ["arroz", "cereal"]),

            ingredient(name: "Avena",
                       category: .cereales,
                       calories: 389, protein: 17, carbs: 66, fat: 7, fiber: 10,
                       servingSize: 40, servingUnit: .grams,
                       tags: ["avena", "cereal"]),

            ingredient(name: "Pan Integral",
                       category: .cereales,
                       calories: 247, protein: 13, carbs: 41, fat: 4.2, fiber: 6,
                       servingSize: 30, servingUnit: .piece,
                       tags: ["pan", "integral"]),

            ingredient(name: "Tortilla de Maíz",
                       category: .cereales,
                       calories: 218, protein: 5.7, carbs: 46, fat: 2.5, fiber: 4.1,
                       servingSize: 25, servingUnit: .piece,
                       tags: ["tortilla", "maíz"]),

            // MARK: Carbohidratos
            ingredient(name: "Papa",
                       category: .carbohidratos,
                       calories: 77, protein: 2, carbs: 17, fat: 0.1, fiber: 2.2,
                       servingSize: 150, servingUnit: .piece,
                       tags: ["papa", "tubérculo"]),

            // MARK: Frutas
            ingredient(name: "Manzana",
                       category: .frutas,
                       calories: 52, protein: 0.3, carbs: 14, fat: 0.2, fiber: 2.4,
                       servingSize: 150, servingUnit: .piece,
                       tags: ["fruta", "manzana"]),

            ingredient(name: "Plátano",
                       category: .frutas,
                       calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6,
                       servingSize: 120, servingUnit: .piece,
                       tags: ["plátano", "fruta"]),

            ingredient(name: "Fresa",
                       category: .frutas,
                       calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3, fiber: 2,
                       tags: ["fresa", "fruta"]),

            // MARK: Verduras
            ingredient(name: "Espinaca",
                       category: .verduras,
                       calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2,
                       tags: ["espinaca", "verdura"]),

            ingredient(name: "Brócoli",
                       category: .verduras,
                       calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6,
                       tags: ["brócoli", "verdura"]),

            // MARK: Lácteos
            ingredient(name: "Leche Entera",
                       category: .lacteos,
                       calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3,
                       servingSize: 240, servingUnit: .milliliters,
                       tags: ["leche", "lácteo"]),

            ingredient(name: "Yogur Griego 0%",
                       category: .lacteos,
                       calories: 59, protein: 10, carbs: 3.6, fat: 0.4,
                       servingSize: 150, servingUnit: .grams,
                       tags: ["yogur", "lácteo"]),

            ingredient(name: "Queso Cottage",
                       category: .lacteos,
                       calories: 98, protein: 11, carbs: 3.4, fat: 4.3,
                       tags: ["queso", "lácteo"]),

            // MARK: Grasas
            ingredient(name: "Aceite de Oliva",
                       category: .grasas,
                       calories: 884, protein: 0, carbs: 0, fat: 100,
                       servingSize: 14, servingUnit: .tablespoon,
                       tags: ["aceite", "grasa"]),

            ingredient(name: "Aguacate",
                       category: .grasas,
                       calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7,
                       servingSize: 150, servingUnit: .piece,
                       tags: ["aguacate", "grasa"]),

            // MARK: Snacks / Legumbres
            ingredient(name: "Almendras",
                       category: .snacks,
                       calories: 579, protein: 21, carbs: 22, fat: 50, fiber: 12.5,
                       servingSize: 28, servingUnit: .grams,
                       tags: ["almendra", "nuez", "snack"]),

            ingredient(name: "Frijoles Negros Cocidos",
                       category: .legumbres,
                       calories: 132, protein: 8.9, carbs: 24, fat: 0.5, fiber: 8.7,
                       tags: ["frijol", "legumbre"]),

            // MARK: Prepared Foods
            prepared(name: "Arroz con Pollo",
                     calories: 180, protein: 20, carbs: 18, fat: 4.5, fiber: 0.8,
                     servingSize: 300,
                     tags: ["receta", "pollo", "arroz"]),

            prepared(name: "Bowl de Avena con Fruta",
                     calories: 220, protein: 10, carbs: 40, fat: 4, fiber: 5,
                     servingSize: 250,
                     tags: ["desayuno", "avena", "receta"]),

            prepared(name: "Ensalada de Atún",
                     calories: 150, protein: 22, carbs: 5, fat: 5, fiber: 2,
                     servingSize: 200,
                     tags: ["ensalada", "atún", "receta"]),
        ]
    }
}
