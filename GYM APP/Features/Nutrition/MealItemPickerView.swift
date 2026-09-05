//
//  MealItemPickerView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

/// Food picker for adding items to a Meal. Shows all foods (ingredients + prepared).
/// Reuses NutritionFoodLibraryViewModel + FoodCardView.
struct MealItemPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let meal: Meal
    let onAdd: (Food, Double) -> Void

    @Query(sort: \Food.name) private var allFoods: [Food]
    @State private var libraryVM = NutritionFoodLibraryViewModel()
    @State private var selectedFood: Food?

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inlineSearchBar
                FoodCategoryFilterView(selectedCategory: $libraryVM.selectedCategory)
                Divider()
                content
            }
            .navigationTitle("Agregar alimento")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(item: $selectedFood) { food in
                MealItemAmountView(food: food) { amountGrams in
                    onAdd(food, amountGrams)
                    dismiss()
                }
            }
        }
        .onChange(of: allFoods) { _, newFoods in
            libraryVM.update(foods: newFoods)
        }
        .onAppear {
            libraryVM.update(foods: allFoods)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if libraryVM.filteredFoods.isEmpty {
            ScrollView {
                EmptyStateView(
                    icon: "fork.knife",
                    title: "Sin alimentos",
                    message: "No hay alimentos que coincidan con tu búsqueda."
                )
                .padding(.top, AppSpacing.xxxl)
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                    ForEach(libraryVM.filteredFoods) { food in
                        FoodCardView(food: food) {
                            selectedFood = food
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.base)
                .padding(.vertical, AppSpacing.base)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
    }

    // MARK: - Inline search bar

    private var inlineSearchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Buscar alimento...", text: $libraryVM.searchText)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
            if !libraryVM.searchText.isEmpty {
                Button {
                    libraryVM.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
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
}

// MARK: - Amount entry sheet

private struct MealItemAmountView: View {
    @Environment(\.dismiss) private var dismiss

    let food: Food
    let onConfirm: (Double) -> Void

    @State private var amountText: String = "100"

    private var amount: Double? { Double(amountText) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(food.name)
                            .font(.headline)
                        Spacer()
                        if food.kind == .preparedFood {
                            Image(systemName: "fork.knife")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }

                Section("Cantidad") {
                    HStack {
                        TextField("100", text: $amountText)
                            .decimalKeyboard()
                        Text("gramos")
                            .foregroundStyle(.secondary)
                    }
                }

                if let amt = amount, amt > 0 {
                    let snap = food.snapshot()
                    let macros = FoodMacrosCalculator.macros(for: snap, amount: amt, unit: .grams)
                    Section("Aporte nutricional") {
                        macroRow("Calorías", value: macros.calories, unit: "kcal")
                        macroRow("Proteínas", value: macros.protein, unit: "g")
                        macroRow("Carbohidratos", value: macros.carbohydrates, unit: "g")
                        macroRow("Grasas", value: macros.fat, unit: "g")
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
                        if let amt = amount, amt > 0 { onConfirm(amt) }
                    }
                    .disabled(amount == nil || (amount ?? 0) <= 0)
                }
            }
        }
    }

    private func macroRow(_ label: String, value: Double, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(String(format: "%.1f %@", value, unit))
                .foregroundStyle(.secondary)
        }
    }
}
