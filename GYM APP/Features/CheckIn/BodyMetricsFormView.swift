//
//  BodyMetricsFormView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct BodyMetricsFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let checkIn: CheckIn

    @State private var viewModel: BodyMetricsViewModel

    init(checkIn: CheckIn) {
        self.checkIn = checkIn
        _viewModel = State(initialValue: BodyMetricsViewModel(
            metrics:       checkIn.bodyMetrics,
            athleteHeight: checkIn.athlete?.height
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    MetricInputRow(label: "Peso", text: $viewModel.weightText, unit: "kg")

                    HStack {
                        Text("IMC")
                        Spacer()
                        Text(viewModel.bmiFormatted)
                            .foregroundStyle(.secondary)
                        if viewModel.bmi != nil {
                            Text("kg/m²")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }

                    HStack {
                        Text("Estatura (referencia)")
                        Spacer()
                        Text(viewModel.heightFormatted)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Peso Corporal")
                } footer: {
                    Text("El IMC se calcula automáticamente con la estatura registrada del atleta.")
                }

                Section("Composición Corporal") {
                    MetricInputRow(label: "% Grasa corporal",  text: $viewModel.fatPercentageText,    unit: "%")
                    MetricInputRow(label: "Masa muscular",     text: $viewModel.muscleMassText,        unit: "kg")
                    MetricInputRow(label: "Agua corporal",     text: $viewModel.waterPercentageText,   unit: "%")
                    MetricInputRow(label: "Masa ósea",         text: $viewModel.boneMassText,          unit: "kg")
                }

                Section("Otros") {
                    MetricInputRow(label: "Grasa visceral",    text: $viewModel.visceralFatText,        unit: "nivel")
                    MetricInputRow(label: "Metabolismo basal", text: $viewModel.basalMetabolicRateText, unit: "kcal")
                }
            }
            .navigationTitle(viewModel.isEditing ? "Editar Métricas" : "Registrar Peso")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let repository = BodyMetricsRepository(context: context)
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
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .leading)
        }
    }
}

#Preview("iPhone 16") {
    let checkIn = CheckIn(date: .now)
    BodyMetricsFormView(checkIn: checkIn)
        .modelContainer(for: [CheckIn.self, BodyMetrics.self], inMemory: true)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
