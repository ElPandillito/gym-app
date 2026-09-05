//
//  FoodDetailView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct FoodDetailView: View {
    let food: Food
    var onAdd: ((Food, Double, FoodUnit) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var amount: Double = 100
    @State private var selectedUnit: FoodUnit = .grams
    @State private var servings: Int = 1
    @State private var isShowingEditForm = false
    @State private var showDeleteConfirm = false
    @State private var showForceDeleteConfirm = false
    @State private var deleteError: String?

    private var snapshot: FoodSnapshot { food.snapshot() }

    private var availableUnits: [FoodUnit] {
        var units: [FoodUnit] = [.grams]
        if let unit = food.servingUnit, unit != .grams { units.append(unit) }
        return units
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                imageHeader
                switch food.kind {
                case .ingredient:
                    ingredientContent
                case .preparedFood:
                    preparedFoodContent
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .bottom) { addButton }
        .overlay(alignment: .topTrailing) { topTrailingButtons }
        .sheet(isPresented: $isShowingEditForm) {
            Group {
                if food.kind == .preparedFood {
                    PreparedFoodFormView(mode: .edit(food), context: modelContext)
                } else {
                    FoodFormView(mode: .edit(food), context: modelContext)
                }
            }
        }
        // Standard delete confirmation
        .confirmationDialog(
            "¿Eliminar \"\(food.name)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) { deleteFood() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
        // Force delete confirmation — shown when food is used in nutrition plans
        .confirmationDialog(
            "Eliminar \"\(food.name)\" de la biblioteca",
            isPresented: $showForceDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Eliminar de la biblioteca", role: .destructive) { forceDeleteFood() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Este alimento está siendo utilizado en planes nutricionales. Los planes existentes conservarán sus datos históricos gracias a los snapshots almacenados. Esta acción no se puede deshacer.")
        }
        // Generic error alert
        .alert("No se puede eliminar", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
        .onAppear {
            servings = food.servings ?? 1
        }
    }

    // MARK: - Image Header

    private var imageHeader: some View {
        ZStack(alignment: .bottomLeading) {
            if let imgPath = food.image?.originalPath {
                FoodAsyncImageView(relativePath: imgPath, contentMode: .fill)
                    .frame(height: 240)
                    .clipped()
            } else {
                FoodCategoryPlaceholderView(category: food.category)
                    .frame(height: 240)
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppSpacing.xs) {
                    Text(food.category.displayName.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))

                    if food.source == .system {
                        Text("SISTEMA")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.25), in: Capsule())
                    }

                    if food.kind == .preparedFood {
                        Image(systemName: "fork.knife")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.indigo.opacity(0.75), in: Capsule())
                    }
                }
                Text(food.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                if let brand = food.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(AppSpacing.base)
        }
        .frame(height: 240)
    }

    // MARK: - Ingredient content (kind == .ingredient)

    private var ingredientContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            baseMacrosSection
            portionSection
            calculatedMacrosSection
        }
        .padding(AppSpacing.base)
        .padding(.bottom, 88)
    }

    private var baseMacrosSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Por 100 g", icon: "chart.pie.fill")
            macrosGrid(nutrition: food.nutritionPer100g)
        }
    }

    private var portionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Porción", icon: "scalemass.fill")
            HStack(spacing: AppSpacing.sm) {
                Button { adjustAmount(-10) } label: {
                    Image(systemName: "minus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(AppColors.secondaryBg, in: Circle())
                }
                .buttonStyle(.plain)

                TextField("Cantidad", value: $amount, format: .number)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .decimalKeyboard()
                    .frame(minWidth: 80)

                Button { adjustAmount(+10) } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(AppColors.secondaryBg, in: Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                if availableUnits.count > 1 {
                    Picker("Unidad", selection: $selectedUnit) {
                        ForEach(availableUnits, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 140)
                } else {
                    Text(FoodUnit.grams.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var calculatedMacrosSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Macros calculados", icon: "function")
            macrosGrid(nutrition: FoodMacrosCalculator.macros(for: snapshot, amount: amount, unit: selectedUnit))
        }
    }

    // MARK: - Prepared food content (kind == .preparedFood)

    private var preparedFoodContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            if !food.ingredients.isEmpty {
                ingredientsListSection
            }
            totalMacrosSection
            preparedServingsSection
            perServingMacrosSection
        }
        .padding(AppSpacing.base)
        .padding(.bottom, 88)
    }

    private var ingredientsListSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Ingredientes", icon: "list.bullet")
            VStack(spacing: 0) {
                ForEach(food.ingredients.sorted { $0.sortOrder < $1.sortOrder }) { ri in
                    if let ing = ri.ingredient {
                        HStack(spacing: AppSpacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .fill(ing.category.color.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: ing.category.systemImage)
                                    .font(.caption)
                                    .foregroundStyle(ing.category.color)
                            }

                            Text(ing.name)
                                .font(.subheadline)

                            Spacer()

                            Text(String(format: ri.amountGrams.truncatingRemainder(dividingBy: 1) == 0
                                ? "%.0f g" : "%.1f g", ri.amountGrams))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.xs)

                        if ri.id != food.ingredients.sorted(by: { $0.sortOrder < $1.sortOrder }).last?.id {
                            Divider().padding(.leading, 44 + AppSpacing.sm)
                        }
                    }
                }
            }
            .padding(AppSpacing.sm)
            .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    private var totalMacros: NutritionValues {
        let snap = food.snapshot()
        return snap.ingredients.isEmpty
            ? food.nutritionPer100g
            : FoodMacrosCalculator.recipeMacros(for: snap)
    }

    private var perServingMacros: NutritionValues {
        guard servings > 0 else { return totalMacros }
        return totalMacros.scaled(by: 1.0 / Double(servings))
    }

    private var totalMacrosSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Total receta", icon: "chart.pie.fill")
            macrosGrid(nutrition: totalMacros)
        }
    }

    private var preparedServingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Porciones", icon: "person.2.fill")
            HStack(spacing: AppSpacing.sm) {
                Button {
                    if servings > 1 { servings -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(AppColors.secondaryBg, in: Circle())
                }
                .buttonStyle(.plain)

                Text("\(servings)")
                    .font(.title3.weight(.semibold))
                    .frame(minWidth: 44)
                    .multilineTextAlignment(.center)

                Button { servings += 1 } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(AppColors.secondaryBg, in: Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text("porción\(servings == 1 ? "" : "es")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var perServingMacrosSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Por porción", icon: "function")
            macrosGrid(nutrition: perServingMacros)
        }
    }

    // MARK: - Shared macros grid

    private func macrosGrid(nutrition: NutritionValues) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: AppSpacing.sm
        ) {
            MetricCard(title: "Calorías",      value: String(format: "%.0f", nutrition.calories),      unit: "kcal", icon: "flame.fill",  tintColor: .orange)
            MetricCard(title: "Proteína",      value: String(format: "%.1f", nutrition.protein),        unit: "g",    icon: "bolt.fill",   tintColor: .red)
            MetricCard(title: "Carbohidratos", value: String(format: "%.1f", nutrition.carbohydrates),  unit: "g",    icon: "bolt.fill",   tintColor: .yellow)
            MetricCard(title: "Grasa",         value: String(format: "%.1f", nutrition.fat),            unit: "g",    icon: "drop.fill",   tintColor: .blue)
        }
    }

    // MARK: - Add button

    private var addButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, AppColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            Button {
                onAdd?(food, amount, selectedUnit)
                dismiss()
            } label: {
                Label("Agregar a plan", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: AppRadius.lg))
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.bottom, AppSpacing.base)
            .background(AppColors.background)
        }
    }

    // MARK: - Top trailing buttons

    private var topTrailingButtons: some View {
        HStack(spacing: AppSpacing.xs) {
            if food.source != .system {
                Button { isShowingEditForm = true } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(AppSpacing.sm)
                        .background(.black.opacity(0.35), in: Circle())
                }

                Button { showDeleteConfirm = true } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(AppSpacing.sm)
                        .background(.black.opacity(0.35), in: Circle())
                }
            }

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(AppSpacing.sm)
                    .background(.black.opacity(0.35), in: Circle())
            }
        }
        .padding(.top, AppSpacing.base)
        .padding(.trailing, AppSpacing.base)
    }

    // MARK: - Actions

    private func adjustAmount(_ delta: Double) {
        amount = max(1, amount + delta)
    }

    private func deleteFood() {
        do {
            try FoodRepository.make(context: modelContext).delete(food)
            dismiss()
        } catch let foodErr as FoodError {
            if case .isUsedInNutritionPlans = foodErr {
                showForceDeleteConfirm = true
            } else {
                deleteError = foodErr.localizedDescription
            }
        } catch {
            deleteError = error.localizedDescription
        }
    }

    private func forceDeleteFood() {
        do {
            try FoodRepository.make(context: modelContext).forceDelete(food)
            dismiss()
        } catch {
            deleteError = error.localizedDescription
        }
    }
}
