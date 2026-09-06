//
//  NutritionPlanDetailView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct NutritionPlanDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let plan: NutritionPlan
    let athlete: Athlete

    @State private var viewModel: NutritionPlanDetailViewModel
    @State private var isShowingAddMeal = false
    @State private var newMealName = ""
    @State private var mealPickerTarget: Meal?
    @State private var isShowingEditPlan = false
    @State private var editingMeal: Meal?

    init(plan: NutritionPlan, athlete: Athlete, context: ModelContext) {
        self.plan    = plan
        self.athlete = athlete
        _viewModel = State(initialValue: NutritionPlanDetailViewModel(context: context))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                statusRow
                macrosGrid
                if plan.hasTargets {
                    progressSection
                }
                if let notes = plan.notes, !notes.isEmpty {
                    notesRow(notes)
                }
                mealsSection
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.vertical, AppSpacing.base)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .navigationTitle(plan.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isShowingEditPlan = true
                    } label: {
                        Label("Editar plan", systemImage: "pencil")
                    }
                    Button {
                        viewModel.activate(plan, for: athlete)
                    } label: {
                        Label(
                            plan.isActive ? "Plan activo" : "Activar plan",
                            systemImage: plan.isActive ? "checkmark.circle.fill" : "checkmark.circle"
                        )
                    }
                    .disabled(plan.isActive)
                    Divider()
                    Button {
                        isShowingAddMeal = true
                    } label: {
                        Label("Agregar comida", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingEditPlan) {
            NutritionPlanFormView(mode: .edit(plan), context: modelContext)
        }
        .sheet(item: $mealPickerTarget) { meal in
            MealItemPickerView(meal: meal) { food, amount in
                viewModel.addItem(food: food, amountGrams: amount, to: meal)
            }
        }
        .sheet(item: $editingMeal) { meal in
            MealEditSheet(meal: meal, context: modelContext)
        }
        .alert("Nueva comida", isPresented: $isShowingAddMeal) {
            TextField("Nombre (ej. Desayuno)", text: $newMealName)
            Button("Agregar") {
                let name = newMealName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { viewModel.addMeal(name: name, to: plan) }
                newMealName = ""
            }
            Button("Cancelar", role: .cancel) { newMealName = "" }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Status row

    private var statusRow: some View {
        HStack {
            if plan.isActive {
                Label("Activo", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12), in: Capsule())
            }
            Spacer()
            Text(plan.dateRangeText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Macros grid (MetricCard — planned / target)

    private var macrosGrid: some View {
        let total  = plan.totalMacros
        let target = plan.targetMacros
        let hasTarget = target.calories > 0 || target.protein > 0

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Macros diarios", icon: "chart.pie.fill")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppSpacing.sm),
                GridItem(.flexible(), spacing: AppSpacing.sm),
            ], spacing: AppSpacing.sm) {
                MetricCard(
                    title: "Calorías",
                    value: hasTarget
                        ? String(format: "%.0f / %.0f", total.calories, target.calories)
                        : String(format: "%.0f", total.calories),
                    unit: "kcal",
                    icon: "flame.fill",
                    tintColor: .orange
                )
                MetricCard(
                    title: "Proteína",
                    value: hasTarget
                        ? String(format: "%.0f / %.0f", total.protein, target.protein)
                        : String(format: "%.0f", total.protein),
                    unit: "g",
                    icon: "bolt.fill",
                    tintColor: .red
                )
                MetricCard(
                    title: "Carbohidratos",
                    value: hasTarget
                        ? String(format: "%.0f / %.0f", total.carbohydrates, target.carbohydrates)
                        : String(format: "%.0f", total.carbohydrates),
                    unit: "g",
                    icon: "bolt.fill",
                    tintColor: .yellow
                )
                MetricCard(
                    title: "Grasas",
                    value: hasTarget
                        ? String(format: "%.0f / %.0f", total.fat, target.fat)
                        : String(format: "%.0f", total.fat),
                    unit: "g",
                    icon: "drop.fill",
                    tintColor: .blue
                )
            }
        }
    }

    // MARK: - Progress bars (only shown when hasTargets)

    private var progressSection: some View {
        let total  = plan.totalMacros
        let target = plan.targetMacros

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Progreso diario", icon: "chart.bar.fill")

            VStack(spacing: AppSpacing.md) {
                MacroProgressRow(
                    title: "Calorías",
                    current: total.calories,
                    target: target.calories,
                    unit: "kcal",
                    color: .orange
                )
                MacroProgressRow(
                    title: "Proteína",
                    current: total.protein,
                    target: target.protein,
                    unit: "g",
                    color: .red
                )
                MacroProgressRow(
                    title: "Carbohidratos",
                    current: total.carbohydrates,
                    target: target.carbohydrates,
                    unit: "g",
                    color: .yellow
                )
                MacroProgressRow(
                    title: "Grasas",
                    current: total.fat,
                    target: target.fat,
                    unit: "g",
                    color: .blue
                )
            }
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .appShadow(AppShadows.card)
        }
    }

    // MARK: - Notes

    private func notesRow(_ notes: String) -> some View {
        Text(notes)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Meals section

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                AppSectionHeader("Comidas", icon: "fork.knife")
                Spacer()
                Button { isShowingAddMeal = true } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }

            if plan.sortedMeals.isEmpty {
                emptyMealsState
            } else {
                ForEach(plan.sortedMeals) { meal in
                    MealCard(
                        meal: meal,
                        onAddItem: { mealPickerTarget = meal },
                        onEdit: { editingMeal = meal },
                        onDelete: { viewModel.deleteMeal(meal) },
                        onDeleteItem: { item in viewModel.deleteItem(item) },
                        onUpdateItem: { item, amt in viewModel.updateItem(item, amountGrams: amt) }
                    )
                }
            }
        }
    }

    private var emptyMealsState: some View {
        Button { isShowingAddMeal = true } label: {
            Label("Agregar primera comida", systemImage: "plus.circle.fill")
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MealCard

private struct MealCard: View {
    let meal: Meal
    let onAddItem: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDeleteItem: (MealItem) -> Void
    let onUpdateItem: (MealItem, Double) -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mealHeader
            if isExpanded {
                Divider()
                itemsList
            }
        }
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        .appShadow(AppShadows.card)
    }

    private var mealHeader: some View {
        HStack(spacing: AppSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: AppSpacing.xs) {
                            Text(meal.name)
                                .font(.subheadline.weight(.semibold))
                            if let timeText = meal.timeText {
                                Text(timeText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        let macros = meal.totalMacros
                        if macros.calories > 0 {
                            Text(String(format: "%.0f kcal · P%.0fg · C%.0fg · G%.0fg",
                                        macros.calories, macros.protein,
                                        macros.carbohydrates, macros.fat))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Menu {
                Button { onAddItem() } label: { Label("Agregar alimento", systemImage: "plus") }
                Button { onEdit() } label: { Label("Editar comida", systemImage: "pencil") }
                Divider()
                Button(role: .destructive) { onDelete() } label: {
                    Label("Eliminar comida", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(AppSpacing.md)
    }

    private var itemsList: some View {
        VStack(spacing: 0) {
            if meal.sortedItems.isEmpty {
                Button(action: onAddItem) {
                    Label("Agregar alimento", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                }
                .buttonStyle(.plain)
            } else {
                ForEach(meal.sortedItems) { item in
                    MealItemRow(
                        item: item,
                        onDelete: { onDeleteItem(item) },
                        onUpdate: { amt in onUpdateItem(item, amt) }
                    )
                    if item.id != meal.sortedItems.last?.id {
                        Divider().padding(.leading, AppSpacing.md)
                    }
                }
                Divider()
                Button(action: onAddItem) {
                    Label("Agregar alimento", systemImage: "plus.circle")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(.plain)
                .padding(.bottom, AppSpacing.xs)
            }
        }
    }
}

// MARK: - MealItemRow

private struct MealItemRow: View {
    let item: MealItem
    let onDelete: () -> Void
    let onUpdate: (Double) -> Void

    @State private var amountText: String = ""
    @State private var isEditing = false

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.subheadline)
                let m = item.macros
                Text(String(format: "%.0f kcal · P%.0fg · C%.0fg · G%.0fg",
                            m.calories, m.protein, m.carbohydrates, m.fat))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isEditing {
                HStack(spacing: 4) {
                    TextField("g", text: $amountText)
                        .decimalKeyboard()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 50)
                    Text("g")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        if let val = Double(amountText), val > 0 { onUpdate(val) }
                        isEditing = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    amountText = String(format: "%.0f", item.amountGrams)
                    isEditing = true
                } label: {
                    HStack(spacing: 2) {
                        Text(String(format: "%.0fg", item.amountGrams))
                            .font(.caption.weight(.medium))
                        Image(systemName: "pencil")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .onAppear { amountText = String(format: "%.0f", item.amountGrams) }
    }
}

// MARK: - MealEditSheet

private struct MealEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let meal: Meal
    @State private var name: String
    @State private var notes: String
    @State private var hasTime: Bool
    @State private var time: Date
    @State private var saveError: String?
    private let repo: MealRepository

    init(meal: Meal, context: ModelContext) {
        self.meal = meal
        _name     = State(initialValue: meal.name)
        _notes    = State(initialValue: meal.notes ?? "")
        _hasTime  = State(initialValue: meal.time != nil)
        _time     = State(initialValue: meal.time ?? {
            var components = Calendar.current.dateComponents([.hour, .minute], from: Date())
            components.hour   = 8
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }())
        self.repo = MealRepository(context: context)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nombre") {
                    TextField("Nombre de la comida", text: $name)
                }
                Section("Horario") {
                    Toggle("Asignar horario", isOn: $hasTime)
                    if hasTime {
                        DatePicker(
                            "Hora",
                            selection: $time,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                Section("Notas") {
                    TextField("Notas (opcional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Editar comida")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        guard !n.isEmpty else { return }
                        let notesVal: String? = notes.trimmingCharacters(in: .whitespaces).isEmpty
                            ? nil : notes.trimmingCharacters(in: .whitespaces)
                        do {
                            try repo.update(meal, name: n, notes: notesVal, time: hasTime ? time : nil)
                            dismiss()
                        } catch {
                            saveError = "No se pudo guardar la comida. Inténtalo de nuevo."
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Error al guardar", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
        }
    }
}
