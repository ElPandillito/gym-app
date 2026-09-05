//
//  FoodSeeder.swift
//  GYM APP
//

import SwiftData
import Foundation
import OSLog

enum FoodSeeder {

    /// Incrementally inserts any catalog food whose externalID is not yet stored.
    /// Safe to call on every launch — skips foods that already exist.
    static func seedIfNeeded(context: ModelContext) {
        let catalog = makeFoods()

        let systemDescriptor = FetchDescriptor<Food>(
            predicate: #Predicate { $0.sourceRaw == "system" }
        )
        let existing: [Food]
        do {
            existing = try context.fetch(systemDescriptor)
        } catch {
            AppLogger.app.error("seedIfNeeded: fetch failed — \(error.localizedDescription, privacy: .private). Seeder aborted.")
            return
        }

        let existingIDs = Set(existing.compactMap { $0.externalID })

        var inserted = 0
        for food in catalog {
            guard let extID = food.externalID, !existingIDs.contains(extID) else { continue }
            context.insert(food)
            inserted += 1
        }

        guard inserted > 0 else {
            AppLogger.app.debug("seedIfNeeded: catalog up to date (\(existing.count) system foods).")
            return
        }

        do {
            try context.save()
            AppLogger.app.debug("seedIfNeeded: inserted \(inserted) foods. Total system=\(existing.count + inserted).")
        } catch {
            AppLogger.app.error("seedIfNeeded: save failed — \(error.localizedDescription, privacy: .private). \(inserted) foods NOT persisted.")
        }
    }

    // MARK: - Private helpers

    private static func ingredient(
        id: String,
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
        f.externalID    = id
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
        id: String,
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
        f.externalID    = id
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

    // MARK: - Catalog (values per 100 g, USDA-approximate)

    private static func makeFoods() -> [Food] {
        [
            // MARK: Proteínas
            ingredient(id: "system_pechuga_de_pollo",
                       name: "Pechuga de Pollo",
                       category: .proteinas,
                       calories: 165, protein: 31, carbs: 0, fat: 3.6,
                       servingSize: 100, servingUnit: .grams,
                       tags: ["pollo", "carne", "proteína"]),

            ingredient(id: "system_muslo_de_pollo",
                       name: "Muslo de Pollo",
                       category: .proteinas,
                       calories: 209, protein: 26, carbs: 0, fat: 11,
                       tags: ["pollo", "carne", "proteína"]),

            ingredient(id: "system_carne_molida_90",
                       name: "Carne Molida 90%",
                       category: .proteinas,
                       calories: 176, protein: 20, carbs: 0, fat: 10,
                       tags: ["carne", "res", "proteína"]),

            ingredient(id: "system_carne_molida_80",
                       name: "Carne Molida 80%",
                       category: .proteinas,
                       calories: 215, protein: 17, carbs: 0, fat: 15,
                       tags: ["carne", "res", "proteína"]),

            ingredient(id: "system_bistec_de_res",
                       name: "Bistec de Res",
                       category: .proteinas,
                       calories: 198, protein: 22, carbs: 0, fat: 12,
                       tags: ["carne", "res", "proteína"]),

            ingredient(id: "system_atun_en_agua",
                       name: "Atún en Agua",
                       category: .proteinas,
                       calories: 116, protein: 26, carbs: 0, fat: 0.5,
                       servingSize: 140, servingUnit: .grams,
                       tags: ["pescado", "lata", "proteína"]),

            ingredient(id: "system_atun_en_aceite",
                       name: "Atún en Aceite",
                       category: .proteinas,
                       calories: 198, protein: 26, carbs: 0, fat: 10,
                       servingSize: 140, servingUnit: .grams,
                       tags: ["pescado", "lata", "proteína"]),

            ingredient(id: "system_salmon",
                       name: "Salmón",
                       category: .proteinas,
                       calories: 208, protein: 20, carbs: 0, fat: 13,
                       tags: ["pescado", "omega3", "proteína"]),

            ingredient(id: "system_sardina_en_agua",
                       name: "Sardina en Agua",
                       category: .proteinas,
                       calories: 108, protein: 20, carbs: 0, fat: 2.5,
                       tags: ["pescado", "lata", "proteína"]),

            ingredient(id: "system_tilapia",
                       name: "Tilapia",
                       category: .proteinas,
                       calories: 96, protein: 20, carbs: 0, fat: 2,
                       tags: ["pescado", "proteína"]),

            ingredient(id: "system_huevo_entero",
                       name: "Huevo Entero",
                       category: .proteinas,
                       calories: 155, protein: 13, carbs: 1.1, fat: 11,
                       servingSize: 50, servingUnit: .piece,
                       tags: ["huevo", "proteína"]),

            ingredient(id: "system_clara_de_huevo",
                       name: "Clara de Huevo",
                       category: .proteinas,
                       calories: 52, protein: 11, carbs: 0.7, fat: 0.2,
                       tags: ["huevo", "proteína"]),

            ingredient(id: "system_cerdo_lomo",
                       name: "Lomo de Cerdo",
                       category: .proteinas,
                       calories: 143, protein: 20, carbs: 0, fat: 6,
                       tags: ["cerdo", "carne", "proteína"]),

            ingredient(id: "system_pavo_molido",
                       name: "Pavo Molido",
                       category: .proteinas,
                       calories: 149, protein: 19, carbs: 0, fat: 8,
                       tags: ["pavo", "carne", "proteína"]),

            ingredient(id: "system_camaron",
                       name: "Camarón",
                       category: .proteinas,
                       calories: 99, protein: 24, carbs: 0, fat: 0.3,
                       tags: ["mariscos", "proteína"]),

            ingredient(id: "system_jamon_de_pavo",
                       name: "Jamón de Pavo",
                       category: .proteinas,
                       calories: 107, protein: 17, carbs: 2, fat: 4,
                       servingSize: 30, servingUnit: .piece,
                       tags: ["pavo", "procesado", "proteína"]),

            ingredient(id: "system_proteina_whey",
                       name: "Proteína Whey",
                       category: .proteinas,
                       calories: 372, protein: 76, carbs: 8, fat: 5,
                       servingSize: 30, servingUnit: .grams,
                       tags: ["suplemento", "whey", "proteína"]),

            ingredient(id: "system_caseina",
                       name: "Caseína",
                       category: .proteinas,
                       calories: 360, protein: 80, carbs: 4, fat: 2,
                       servingSize: 30, servingUnit: .grams,
                       tags: ["suplemento", "proteína", "nocturna"]),

            // MARK: Cereales
            ingredient(id: "system_arroz_blanco_cocido",
                       name: "Arroz Blanco Cocido",
                       category: .cereales,
                       calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4,
                       tags: ["arroz", "cereal"]),

            ingredient(id: "system_arroz_integral_cocido",
                       name: "Arroz Integral Cocido",
                       category: .cereales,
                       calories: 123, protein: 2.7, carbs: 26, fat: 0.9, fiber: 1.8,
                       tags: ["arroz", "integral", "cereal"]),

            ingredient(id: "system_avena",
                       name: "Avena",
                       category: .cereales,
                       calories: 389, protein: 17, carbs: 66, fat: 7, fiber: 10,
                       servingSize: 40, servingUnit: .grams,
                       tags: ["avena", "cereal"]),

            ingredient(id: "system_pan_integral",
                       name: "Pan Integral",
                       category: .cereales,
                       calories: 247, protein: 13, carbs: 41, fat: 4.2, fiber: 6,
                       servingSize: 30, servingUnit: .piece,
                       tags: ["pan", "integral"]),

            ingredient(id: "system_pan_blanco",
                       name: "Pan Blanco",
                       category: .cereales,
                       calories: 265, protein: 9, carbs: 49, fat: 3, fiber: 2.7,
                       servingSize: 25, servingUnit: .piece,
                       tags: ["pan", "cereal"]),

            ingredient(id: "system_tortilla_de_maiz",
                       name: "Tortilla de Maíz",
                       category: .cereales,
                       calories: 218, protein: 5.7, carbs: 46, fat: 2.5, fiber: 4.1,
                       servingSize: 25, servingUnit: .piece,
                       tags: ["tortilla", "maíz"]),

            ingredient(id: "system_tortilla_de_trigo",
                       name: "Tortilla de Trigo",
                       category: .cereales,
                       calories: 312, protein: 8.9, carbs: 49, fat: 8, fiber: 3.3,
                       servingSize: 35, servingUnit: .piece,
                       tags: ["tortilla", "trigo"]),

            ingredient(id: "system_pasta_cocida",
                       name: "Pasta Cocida",
                       category: .cereales,
                       calories: 158, protein: 5.8, carbs: 31, fat: 0.9, fiber: 1.8,
                       tags: ["pasta", "cereal"]),

            ingredient(id: "system_quinoa_cocida",
                       name: "Quinoa Cocida",
                       category: .cereales,
                       calories: 120, protein: 4.4, carbs: 22, fat: 1.9, fiber: 2.8,
                       tags: ["quinoa", "cereal", "completo"]),

            ingredient(id: "system_granola",
                       name: "Granola",
                       category: .cereales,
                       calories: 471, protein: 10, carbs: 64, fat: 20, fiber: 5,
                       servingSize: 40, servingUnit: .grams,
                       tags: ["granola", "cereal", "desayuno"]),

            ingredient(id: "system_cereal_de_avena",
                       name: "Cereal de Avena",
                       category: .cereales,
                       calories: 367, protein: 13, carbs: 66, fat: 7, fiber: 9,
                       servingSize: 40, servingUnit: .grams,
                       tags: ["cereal", "avena", "desayuno"]),

            // MARK: Carbohidratos
            ingredient(id: "system_papa",
                       name: "Papa",
                       category: .carbohidratos,
                       calories: 77, protein: 2, carbs: 17, fat: 0.1, fiber: 2.2,
                       servingSize: 150, servingUnit: .piece,
                       tags: ["papa", "tubérculo"]),

            ingredient(id: "system_camote",
                       name: "Camote",
                       category: .carbohidratos,
                       calories: 86, protein: 1.6, carbs: 20, fat: 0.1, fiber: 3,
                       servingSize: 130, servingUnit: .piece,
                       tags: ["camote", "tubérculo", "boniato"]),

            ingredient(id: "system_yuca",
                       name: "Yuca",
                       category: .carbohidratos,
                       calories: 160, protein: 1.4, carbs: 38, fat: 0.3, fiber: 1.8,
                       tags: ["yuca", "tubérculo"]),

            ingredient(id: "system_elote",
                       name: "Elote",
                       category: .carbohidratos,
                       calories: 86, protein: 3.3, carbs: 19, fat: 1.4, fiber: 2,
                       servingSize: 90, servingUnit: .piece,
                       tags: ["maíz", "elote", "cereal"]),

            ingredient(id: "system_platano_macho",
                       name: "Plátano Macho",
                       category: .carbohidratos,
                       calories: 122, protein: 1.3, carbs: 32, fat: 0.4, fiber: 2.3,
                       tags: ["plátano", "tubérculo"]),

            ingredient(id: "system_zanahoria",
                       name: "Zanahoria",
                       category: .carbohidratos,
                       calories: 41, protein: 0.9, carbs: 10, fat: 0.2, fiber: 2.8,
                       tags: ["zanahoria", "verdura"]),

            ingredient(id: "system_remolacha",
                       name: "Remolacha",
                       category: .carbohidratos,
                       calories: 43, protein: 1.6, carbs: 10, fat: 0.2, fiber: 2.8,
                       tags: ["remolacha", "betabel"]),

            ingredient(id: "system_chicharo",
                       name: "Chícharo",
                       category: .carbohidratos,
                       calories: 81, protein: 5.4, carbs: 14, fat: 0.4, fiber: 5.7,
                       tags: ["chícharo", "guisante", "legumbre"]),

            // MARK: Frutas
            ingredient(id: "system_manzana",
                       name: "Manzana",
                       category: .frutas,
                       calories: 52, protein: 0.3, carbs: 14, fat: 0.2, fiber: 2.4,
                       servingSize: 150, servingUnit: .piece,
                       tags: ["fruta", "manzana"]),

            ingredient(id: "system_platano",
                       name: "Plátano",
                       category: .frutas,
                       calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6,
                       servingSize: 120, servingUnit: .piece,
                       tags: ["plátano", "fruta"]),

            ingredient(id: "system_fresa",
                       name: "Fresa",
                       category: .frutas,
                       calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3, fiber: 2,
                       tags: ["fresa", "fruta"]),

            ingredient(id: "system_naranja",
                       name: "Naranja",
                       category: .frutas,
                       calories: 47, protein: 0.9, carbs: 12, fat: 0.1, fiber: 2.4,
                       servingSize: 150, servingUnit: .piece,
                       tags: ["naranja", "fruta", "vitamina c"]),

            ingredient(id: "system_mango",
                       name: "Mango",
                       category: .frutas,
                       calories: 60, protein: 0.8, carbs: 15, fat: 0.4, fiber: 1.6,
                       tags: ["mango", "fruta"]),

            ingredient(id: "system_sandia",
                       name: "Sandía",
                       category: .frutas,
                       calories: 30, protein: 0.6, carbs: 7.6, fat: 0.2, fiber: 0.4,
                       tags: ["sandía", "fruta"]),

            ingredient(id: "system_pina",
                       name: "Piña",
                       category: .frutas,
                       calories: 50, protein: 0.5, carbs: 13, fat: 0.1, fiber: 1.4,
                       tags: ["piña", "fruta"]),

            ingredient(id: "system_uva",
                       name: "Uva",
                       category: .frutas,
                       calories: 69, protein: 0.7, carbs: 18, fat: 0.2, fiber: 0.9,
                       tags: ["uva", "fruta"]),

            ingredient(id: "system_pera",
                       name: "Pera",
                       category: .frutas,
                       calories: 57, protein: 0.4, carbs: 15, fat: 0.1, fiber: 3.1,
                       servingSize: 160, servingUnit: .piece,
                       tags: ["pera", "fruta"]),

            ingredient(id: "system_kiwi",
                       name: "Kiwi",
                       category: .frutas,
                       calories: 61, protein: 1.1, carbs: 15, fat: 0.5, fiber: 3,
                       servingSize: 70, servingUnit: .piece,
                       tags: ["kiwi", "fruta", "vitamina c"]),

            ingredient(id: "system_melon",
                       name: "Melón",
                       category: .frutas,
                       calories: 34, protein: 0.8, carbs: 8.2, fat: 0.2, fiber: 0.9,
                       tags: ["melón", "fruta"]),

            ingredient(id: "system_papaya",
                       name: "Papaya",
                       category: .frutas,
                       calories: 43, protein: 0.5, carbs: 11, fat: 0.3, fiber: 1.7,
                       tags: ["papaya", "fruta"]),

            ingredient(id: "system_arandano",
                       name: "Arándano",
                       category: .frutas,
                       calories: 57, protein: 0.7, carbs: 14, fat: 0.3, fiber: 2.4,
                       tags: ["arándano", "fruta", "antioxidante"]),

            // MARK: Verduras
            ingredient(id: "system_espinaca",
                       name: "Espinaca",
                       category: .verduras,
                       calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2,
                       tags: ["espinaca", "verdura"]),

            ingredient(id: "system_brocoli",
                       name: "Brócoli",
                       category: .verduras,
                       calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6,
                       tags: ["brócoli", "verdura"]),

            ingredient(id: "system_pepino",
                       name: "Pepino",
                       category: .verduras,
                       calories: 15, protein: 0.7, carbs: 3.6, fat: 0.1, fiber: 0.5,
                       tags: ["pepino", "verdura"]),

            ingredient(id: "system_tomate",
                       name: "Tomate",
                       category: .verduras,
                       calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, fiber: 1.2,
                       tags: ["tomate", "verdura"]),

            ingredient(id: "system_lechuga",
                       name: "Lechuga",
                       category: .verduras,
                       calories: 15, protein: 1.4, carbs: 2.9, fat: 0.2, fiber: 1.3,
                       tags: ["lechuga", "verdura"]),

            ingredient(id: "system_pimiento_rojo",
                       name: "Pimiento Rojo",
                       category: .verduras,
                       calories: 31, protein: 1, carbs: 7, fat: 0.3, fiber: 2.1,
                       tags: ["pimiento", "verdura", "vitamina c"]),

            ingredient(id: "system_calabacita",
                       name: "Calabacita",
                       category: .verduras,
                       calories: 17, protein: 1.2, carbs: 3.1, fat: 0.3, fiber: 1,
                       tags: ["calabacita", "verdura", "calabaza"]),

            ingredient(id: "system_champinon",
                       name: "Champiñón",
                       category: .verduras,
                       calories: 22, protein: 3.1, carbs: 3.3, fat: 0.3, fiber: 1,
                       tags: ["champiñón", "hongo", "verdura"]),

            ingredient(id: "system_cebolla",
                       name: "Cebolla",
                       category: .verduras,
                       calories: 40, protein: 1.1, carbs: 9.3, fat: 0.1, fiber: 1.7,
                       tags: ["cebolla", "verdura"]),

            ingredient(id: "system_apio",
                       name: "Apio",
                       category: .verduras,
                       calories: 16, protein: 0.7, carbs: 3, fat: 0.2, fiber: 1.6,
                       tags: ["apio", "verdura"]),

            ingredient(id: "system_ejotes",
                       name: "Ejotes",
                       category: .verduras,
                       calories: 31, protein: 1.8, carbs: 7, fat: 0.2, fiber: 2.7,
                       tags: ["ejotes", "vainitas", "verdura"]),

            ingredient(id: "system_coliflor",
                       name: "Coliflor",
                       category: .verduras,
                       calories: 25, protein: 1.9, carbs: 5, fat: 0.3, fiber: 2,
                       tags: ["coliflor", "verdura"]),

            ingredient(id: "system_kale",
                       name: "Kale",
                       category: .verduras,
                       calories: 49, protein: 4.3, carbs: 9, fat: 0.9, fiber: 3.6,
                       tags: ["kale", "verdura", "antioxidante"]),

            // MARK: Lácteos
            ingredient(id: "system_leche_entera",
                       name: "Leche Entera",
                       category: .lacteos,
                       calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3,
                       servingSize: 240, servingUnit: .milliliters,
                       tags: ["leche", "lácteo"]),

            ingredient(id: "system_leche_descremada",
                       name: "Leche Descremada",
                       category: .lacteos,
                       calories: 35, protein: 3.4, carbs: 4.9, fat: 0.1,
                       servingSize: 240, servingUnit: .milliliters,
                       tags: ["leche", "descremada", "lácteo"]),

            ingredient(id: "system_yogur_griego_0",
                       name: "Yogur Griego 0%",
                       category: .lacteos,
                       calories: 59, protein: 10, carbs: 3.6, fat: 0.4,
                       servingSize: 150, servingUnit: .grams,
                       tags: ["yogur", "lácteo", "proteína"]),

            ingredient(id: "system_yogur_griego_2",
                       name: "Yogur Griego 2%",
                       category: .lacteos,
                       calories: 73, protein: 8.5, carbs: 3.9, fat: 2,
                       servingSize: 150, servingUnit: .grams,
                       tags: ["yogur", "lácteo"]),

            ingredient(id: "system_queso_cottage",
                       name: "Queso Cottage",
                       category: .lacteos,
                       calories: 98, protein: 11, carbs: 3.4, fat: 4.3,
                       tags: ["queso", "lácteo", "proteína"]),

            ingredient(id: "system_queso_panela",
                       name: "Queso Panela",
                       category: .lacteos,
                       calories: 267, protein: 18, carbs: 2.4, fat: 20,
                       servingSize: 30, servingUnit: .piece,
                       tags: ["queso", "lácteo"]),

            ingredient(id: "system_queso_oaxaca",
                       name: "Queso Oaxaca",
                       category: .lacteos,
                       calories: 360, protein: 22, carbs: 2, fat: 29,
                       servingSize: 30, servingUnit: .piece,
                       tags: ["queso", "lácteo"]),

            ingredient(id: "system_crema_acida",
                       name: "Crema Ácida",
                       category: .lacteos,
                       calories: 181, protein: 2.4, carbs: 4.6, fat: 17,
                       servingSize: 30, servingUnit: .tablespoon,
                       tags: ["crema", "lácteo"]),

            // MARK: Grasas
            ingredient(id: "system_aceite_de_oliva",
                       name: "Aceite de Oliva",
                       category: .grasas,
                       calories: 884, protein: 0, carbs: 0, fat: 100,
                       servingSize: 14, servingUnit: .tablespoon,
                       tags: ["aceite", "grasa"]),

            ingredient(id: "system_aceite_de_coco",
                       name: "Aceite de Coco",
                       category: .grasas,
                       calories: 862, protein: 0, carbs: 0, fat: 100,
                       servingSize: 14, servingUnit: .tablespoon,
                       tags: ["aceite", "coco", "grasa"]),

            ingredient(id: "system_aguacate",
                       name: "Aguacate",
                       category: .grasas,
                       calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7,
                       servingSize: 150, servingUnit: .piece,
                       tags: ["aguacate", "grasa"]),

            ingredient(id: "system_almendras",
                       name: "Almendras",
                       category: .grasas,
                       calories: 579, protein: 21, carbs: 22, fat: 50, fiber: 12.5,
                       servingSize: 28, servingUnit: .grams,
                       tags: ["almendra", "nuez", "snack", "grasa"]),

            ingredient(id: "system_nuez",
                       name: "Nuez",
                       category: .grasas,
                       calories: 654, protein: 15, carbs: 14, fat: 65, fiber: 6.7,
                       servingSize: 28, servingUnit: .grams,
                       tags: ["nuez", "omega3", "grasa"]),

            ingredient(id: "system_mantequilla_de_mani",
                       name: "Mantequilla de Maní",
                       category: .grasas,
                       calories: 588, protein: 25, carbs: 20, fat: 50, fiber: 6,
                       servingSize: 32, servingUnit: .tablespoon,
                       tags: ["maní", "cacahuate", "grasa"]),

            ingredient(id: "system_semillas_de_chia",
                       name: "Semillas de Chía",
                       category: .grasas,
                       calories: 486, protein: 17, carbs: 42, fat: 31, fiber: 34,
                       servingSize: 28, servingUnit: .grams,
                       tags: ["chía", "semilla", "omega3", "grasa"]),

            ingredient(id: "system_semillas_de_girasol",
                       name: "Semillas de Girasol",
                       category: .grasas,
                       calories: 584, protein: 21, carbs: 20, fat: 51, fiber: 8.6,
                       servingSize: 28, servingUnit: .grams,
                       tags: ["girasol", "semilla", "grasa"]),

            ingredient(id: "system_linaza",
                       name: "Linaza",
                       category: .grasas,
                       calories: 534, protein: 18, carbs: 29, fat: 42, fiber: 27,
                       servingSize: 15, servingUnit: .tablespoon,
                       tags: ["linaza", "semilla", "omega3", "grasa"]),

            // MARK: Legumbres
            ingredient(id: "system_frijoles_negros",
                       name: "Frijoles Negros Cocidos",
                       category: .legumbres,
                       calories: 132, protein: 8.9, carbs: 24, fat: 0.5, fiber: 8.7,
                       tags: ["frijol", "legumbre"]),

            ingredient(id: "system_frijoles_pintos",
                       name: "Frijoles Pintos Cocidos",
                       category: .legumbres,
                       calories: 143, protein: 9, carbs: 27, fat: 0.6, fiber: 9,
                       tags: ["frijol", "legumbre"]),

            ingredient(id: "system_lentejas",
                       name: "Lentejas Cocidas",
                       category: .legumbres,
                       calories: 116, protein: 9, carbs: 20, fat: 0.4, fiber: 7.9,
                       tags: ["lenteja", "legumbre"]),

            ingredient(id: "system_garbanzos",
                       name: "Garbanzos Cocidos",
                       category: .legumbres,
                       calories: 164, protein: 8.9, carbs: 27, fat: 2.6, fiber: 7.6,
                       tags: ["garbanzo", "legumbre"]),

            ingredient(id: "system_edamame",
                       name: "Edamame",
                       category: .legumbres,
                       calories: 122, protein: 11, carbs: 10, fat: 5, fiber: 5.2,
                       tags: ["edamame", "soya", "legumbre"]),

            ingredient(id: "system_soya_texturizada",
                       name: "Soya Texturizada",
                       category: .legumbres,
                       calories: 338, protein: 52, carbs: 35, fat: 1, fiber: 13,
                       tags: ["soya", "proteína vegetal", "legumbre"]),

            // MARK: Snacks
            ingredient(id: "system_palomitas_light",
                       name: "Palomitas Light",
                       category: .snacks,
                       calories: 387, protein: 13, carbs: 78, fat: 4, fiber: 15,
                       servingSize: 15, servingUnit: .grams,
                       tags: ["palomitas", "snack"]),

            ingredient(id: "system_tortitas_de_arroz",
                       name: "Tortitas de Arroz",
                       category: .snacks,
                       calories: 392, protein: 8.2, carbs: 82, fat: 3, fiber: 2.3,
                       servingSize: 9, servingUnit: .piece,
                       tags: ["tortita", "arroz", "snack"]),

            ingredient(id: "system_barra_proteina",
                       name: "Barra de Proteína",
                       category: .snacks,
                       calories: 370, protein: 30, carbs: 35, fat: 10, fiber: 3,
                       servingSize: 60, servingUnit: .piece,
                       tags: ["barra", "snack", "proteína"]),

            ingredient(id: "system_datil",
                       name: "Dátil",
                       category: .snacks,
                       calories: 277, protein: 1.8, carbs: 75, fat: 0.2, fiber: 6.7,
                       servingSize: 24, servingUnit: .piece,
                       tags: ["dátil", "fruta seca", "snack"]),

            ingredient(id: "system_pasas",
                       name: "Pasas",
                       category: .snacks,
                       calories: 299, protein: 3.1, carbs: 79, fat: 0.5, fiber: 3.7,
                       servingSize: 30, servingUnit: .grams,
                       tags: ["pasa", "fruta seca", "snack"]),

            // MARK: Bebidas
            ingredient(id: "system_agua_de_coco",
                       name: "Agua de Coco",
                       category: .bebidas,
                       calories: 19, protein: 0.7, carbs: 3.7, fat: 0.2, fiber: 1.1,
                       servingSize: 240, servingUnit: .milliliters,
                       tags: ["agua", "coco", "bebida", "electrolitos"]),

            ingredient(id: "system_leche_almendra",
                       name: "Leche de Almendra",
                       category: .bebidas,
                       calories: 17, protein: 0.6, carbs: 1.3, fat: 1.1,
                       servingSize: 240, servingUnit: .milliliters,
                       tags: ["almendra", "bebida", "sin lactosa"]),

            ingredient(id: "system_leche_avena",
                       name: "Leche de Avena",
                       category: .bebidas,
                       calories: 47, protein: 1, carbs: 9, fat: 1.5,
                       servingSize: 240, servingUnit: .milliliters,
                       tags: ["avena", "bebida", "sin lactosa"]),

            ingredient(id: "system_jugo_naranja",
                       name: "Jugo de Naranja",
                       category: .bebidas,
                       calories: 45, protein: 0.7, carbs: 10, fat: 0.2, fiber: 0.2,
                       servingSize: 240, servingUnit: .milliliters,
                       tags: ["naranja", "jugo", "bebida", "vitamina c"]),

            // MARK: Preparaciones
            prepared(id: "system_prep_arroz_con_pollo",
                     name: "Arroz con Pollo",
                     calories: 180, protein: 20, carbs: 18, fat: 4.5, fiber: 0.8,
                     servingSize: 300,
                     tags: ["receta", "pollo", "arroz"]),

            prepared(id: "system_prep_bowl_avena",
                     name: "Bowl de Avena con Fruta",
                     calories: 220, protein: 10, carbs: 40, fat: 4, fiber: 5,
                     servingSize: 250,
                     tags: ["desayuno", "avena", "receta"]),

            prepared(id: "system_prep_ensalada_atun",
                     name: "Ensalada de Atún",
                     calories: 150, protein: 22, carbs: 5, fat: 5, fiber: 2,
                     servingSize: 200,
                     tags: ["ensalada", "atún", "receta"]),

            prepared(id: "system_prep_omelette_claras",
                     name: "Omelette de Claras",
                     calories: 80, protein: 15, carbs: 1, fat: 2, fiber: 0.5,
                     servingSize: 150,
                     tags: ["desayuno", "huevo", "receta"]),

            prepared(id: "system_prep_batido_proteina",
                     name: "Batido de Proteína",
                     calories: 190, protein: 25, carbs: 15, fat: 4, fiber: 1,
                     servingSize: 350,
                     tags: ["suplemento", "batido", "receta"]),

            prepared(id: "system_prep_pollo_verduras",
                     name: "Pollo al Vapor con Verduras",
                     calories: 140, protein: 24, carbs: 8, fat: 2, fiber: 3,
                     servingSize: 350,
                     tags: ["pollo", "verduras", "receta", "light"]),

            prepared(id: "system_prep_wrap_pollo",
                     name: "Wrap de Pollo",
                     calories: 280, protein: 22, carbs: 28, fat: 8, fiber: 3,
                     servingSize: 250,
                     tags: ["pollo", "wrap", "receta"]),
        ]
    }
}
