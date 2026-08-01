//
//  CircumferenceMeasurementsFormView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct CircumferenceMeasurementsFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let checkIn: CheckIn

    @State private var viewModel: CircumferenceMeasurementsViewModel

    init(checkIn: CheckIn) {
        self.checkIn = checkIn
        _viewModel = State(initialValue: CircumferenceMeasurementsViewModel(
            measurements: checkIn.circumferences
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Torso") {
                    MetricInputRow(label: "Cuello",   text: $viewModel.neckText,      unit: "cm")
                    MetricInputRow(label: "Hombros",  text: $viewModel.shouldersText,  unit: "cm")
                    MetricInputRow(label: "Pecho",    text: $viewModel.chestText,      unit: "cm")
                }

                Section("Brazos") {
                    MetricInputRow(label: "Brazo derecho",       text: $viewModel.rightArmText,     unit: "cm")
                    MetricInputRow(label: "Brazo izquierdo",     text: $viewModel.leftArmText,      unit: "cm")
                    MetricInputRow(label: "Antebrazo derecho",   text: $viewModel.rightForearmText, unit: "cm")
                    MetricInputRow(label: "Antebrazo izquierdo", text: $viewModel.leftForearmText,  unit: "cm")
                }

                Section("Tronco") {
                    MetricInputRow(label: "Cintura",          text: $viewModel.waistText,   unit: "cm")
                    MetricInputRow(label: "Abdomen",          text: $viewModel.abdomenText, unit: "cm")
                    MetricInputRow(label: "Cadera / Glúteos", text: $viewModel.hipsText,    unit: "cm")
                }

                Section("Piernas") {
                    MetricInputRow(label: "Muslo derecho",         text: $viewModel.rightThighText, unit: "cm")
                    MetricInputRow(label: "Muslo izquierdo",       text: $viewModel.leftThighText,  unit: "cm")
                    MetricInputRow(label: "Pantorrilla derecha",   text: $viewModel.rightCalfText,  unit: "cm")
                    MetricInputRow(label: "Pantorrilla izquierda", text: $viewModel.leftCalfText,   unit: "cm")
                }
            }
            .navigationTitle(viewModel.isEditing ? "Editar Medidas" : "Registrar Medidas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let repository = CircumferenceMeasurementsRepository(context: context)
                        if viewModel.save(for: checkIn, using: repository) { dismiss() }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

// MARK: - Input Row

private struct MetricInputRow: View {
    let label: String
    @Binding var text: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: $text)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .frame(width: 72)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .leading)
        }
    }
}

#Preview("iPhone 16") {
    let checkIn = CheckIn(date: .now)
    CircumferenceMeasurementsFormView(checkIn: checkIn)
        .modelContainer(for: [CheckIn.self, CircumferenceMeasurements.self], inMemory: true)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
