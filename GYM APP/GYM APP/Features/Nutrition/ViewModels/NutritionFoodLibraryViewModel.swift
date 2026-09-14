//
//  NutritionFoodLibraryViewModel.swift
//  GYM APP
//

import Foundation

@Observable
@MainActor
final class NutritionFoodLibraryViewModel {

    private(set) var filteredFoods: [Food] = []
    private var allFoods: [Food] = []

    var searchText: String = "" {
        didSet { applyFilters() }
    }

    var selectedCategory: FoodCategory? {
        didSet { applyFilters() }
    }

    var selectedKind: FoodKind? {
        didSet { applyFilters() }
    }

    func update(foods: [Food]) {
        allFoods = foods
        applyFilters()
    }

    private func applyFilters() {
        var result = allFoods

        if let kind = selectedKind {
            result = result.filter { $0.kindRaw == kind.rawValue }
        }

        if let category = selectedCategory {
            result = result.filter { $0.categoryRaw == category.rawValue }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { food in
                food.name.lowercased().contains(query) ||
                food.tags.contains { $0.lowercased().contains(query) }
            }
        }

        filteredFoods = result
    }
}
