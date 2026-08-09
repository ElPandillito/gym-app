//
//  RecipeIngredientPickerView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct RecipeIngredientPickerView: View {
    let onAdd: (Food, Double) -> Void

    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Food> { $0.kindRaw == "ingredient" }, sort: \Food.name)
    private var foods: [Food]

    @State private var searchText: String = ""
    @State private var selectedCategory: FoodCategory? = nil
    @State private var selectedFood: Food? = nil

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md),
    ]

    private var filteredFoods: [Food] {
        var result = foods
        if let cat = selectedCategory {
            result = result.filter { $0.categoryRaw == cat.rawValue }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.tags.contains { $0.lowercased().contains(query) }
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inlineSearchBar
                FoodCategoryFilterView(selectedCategory: $selectedCategory)
                Divider()
                libraryContent
            }
            .navigationTitle("Elegir ingrediente")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .sheet(item: $selectedFood) { food in
            IngredientAmountView(food: food) { amountGrams in
                onAdd(food, amountGrams)
                selectedFood = nil
                dismiss()
            }
        }
    }

    // MARK: - Search bar

    private var inlineSearchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Buscar alimento...", text: $searchText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .padding(.horizontal, AppSpacing.base)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
    }

    // MARK: - Library content

    @ViewBuilder
    private var libraryContent: some View {
        if filteredFoods.isEmpty {
            ScrollView {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Sin resultados",
                    message: "No hay alimentos que coincidan con tu búsqueda."
                )
                .padding(.top, AppSpacing.xxxl)
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                    ForEach(filteredFoods) { food in
                        FoodCardView(food: food) { selectedFood = food }
                    }
                }
                .padding(.horizontal, AppSpacing.base)
                .padding(.vertical, AppSpacing.base)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
    }
}

// MARK: - Amount entry sheet

private struct IngredientAmountView: View {
    let food: Food
    let onConfirm: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String = "100"
    @State private var selectedUnit: FoodUnit = .grams

    private var availableUnits: [FoodUnit] {
        var units: [FoodUnit] = [.grams]
        if let u = food.servingUnit, u != .grams { units.append(u) }
        return units
    }

    private var amount: Double { Double(amountText) ?? 0 }

    private var amountGrams: Double {
        FoodMacrosCalculator.toGrams(amount: amount, unit: selectedUnit, servingSize: food.servingSize)
    }

    private var previewMacros: NutritionValues {
        FoodMacrosCalculator.macros(for: food.snapshot(), amount: amount, unit: selectedUnit)
    }

    private var canConfirm: Bool { amountGrams > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(food.name).font(.headline)
                            Text(food.category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                Section("Cantidad") {
                    HStack {
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                        if availableUnits.count == 1 {
                            Text(FoodUnit.grams.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if availableUnits.count > 1 {
                        Picker("Unidad", selection: $selectedUnit) {
                            ForEach(availableUnits, id: \.self) { u in
                                Text(u.displayName).tag(u)
                            }
                        }
                    }
                }

                if canConfirm {
                    Section("Vista previa") {
                        HStack {
                            Text(String(format: "%.0f kcal", previewMacros.calories))
                                .fontWeight(.medium)
                            Spacer()
                            Text(String(
                                format: "%.1fP · %.1fC · %.1fG",
                                previewMacros.protein,
                                previewMacros.carbohydrates,
                                previewMacros.fat
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Cantidad")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Agregar") {
                        onConfirm(amountGrams)
                        dismiss()
                    }
                    .disabled(!canConfirm)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
