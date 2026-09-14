//
//  NutritionPlanFormView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct NutritionPlanFormView: View {
    @Environment(\.dismiss) private var dismiss

    let mode: NutritionPlanFormViewModel.Mode
    @State private var viewModel: NutritionPlanFormViewModel

    init(mode: NutritionPlanFormViewModel.Mode, context: ModelContext) {
        self.mode = mode
        _viewModel = State(initialValue: NutritionPlanFormViewModel(mode: mode, context: context))
    }

    var body: some View {
        NavigationStack {
            Form {
                infoSection
                targetsSection
                datesSection
                notesSection

                if !viewModel.validationErrors.isEmpty {
                    Section {
                        ForEach(viewModel.validationErrors, id: \.self) { error in
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Editar Plan" : "Nuevo Plan")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { handleSave() }
                        .disabled(!viewModel.canSave)
                }
            }
        }
    }

    // MARK: - Sections

    private var infoSection: some View {
        Section("Información") {
            TextField("Nombre del plan", text: $viewModel.name)
        }
    }

    private var targetsSection: some View {
        Section("Metas diarias (opcional)") {
            macroRow(label: "Calorías", unit: "kcal", text: $viewModel.targetCaloriesText)
            macroRow(label: "Proteínas", unit: "g", text: $viewModel.targetProteinText)
            macroRow(label: "Carbohidratos", unit: "g", text: $viewModel.targetCarbsText)
            macroRow(label: "Grasas", unit: "g", text: $viewModel.targetFatText)
            macroRow(label: "Fibra", unit: "g", text: $viewModel.targetFiberText)
        }
    }

    private var datesSection: some View {
        Section("Fechas") {
            DatePicker("Inicio", selection: $viewModel.startDate, displayedComponents: .date)
            Toggle("Fecha de fin", isOn: $viewModel.hasEndDate)
            if viewModel.hasEndDate {
                DatePicker("Fin", selection: Binding(
                    get: { viewModel.endDate ?? Date() },
                    set: { viewModel.endDate = $0 }
                ), in: viewModel.startDate..., displayedComponents: .date)
            }
        }
    }

    private var notesSection: some View {
        Section("Notas") {
            TextField("Notas (opcional)", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private func macroRow(label: String, unit: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .leading)
        }
    }

    // MARK: - Save

    private func handleSave() {
        do {
            try viewModel.save()
            if viewModel.validationErrors.isEmpty { dismiss() }
        } catch {
            viewModel.validationErrors = [error.localizedDescription]
        }
    }
}
