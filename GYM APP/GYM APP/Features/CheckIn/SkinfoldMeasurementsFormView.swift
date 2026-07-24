//
//  SkinfoldMeasurementsFormView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct SkinfoldMeasurementsFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let checkIn: CheckIn

    @State private var viewModel: SkinfoldMeasurementsViewModel

    init(checkIn: CheckIn) {
        self.checkIn = checkIn
        let athlete       = checkIn.athlete
        let gender        = athlete?.gender ?? .other
        let age           = athlete?.birthDate.map { ageInYears(from: $0) } ?? 25.0
        let bodyWeight    = checkIn.bodyMetrics?.bodyWeight
        _viewModel = State(initialValue: SkinfoldMeasurementsViewModel(
            measurements: checkIn.skinfolds,
            gender: gender,
            age: age,
            bodyWeightKg: bodyWeight
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                methodSection
                sitesSection
                resultSection
                contextSection
            }
            .navigationTitle(viewModel.isEditing ? "Editar Plicometría" : "Registrar Plicometría")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let repo = SkinfoldMeasurementsRepository(context: context)
                        if viewModel.save(for: checkIn, using: repo) { dismiss() }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }

    // MARK: - Method

    private var methodSection: some View {
        Section("Método") {
            Picker("Protocolo", selection: $viewModel.method) {
                ForEach(PlicometryMethod.allCases.filter { $0 != .custom }, id: \.self) { m in
                    Text(m.displayName).tag(m)
                }
            }
            .pickerStyle(.menu)

            if viewModel.method == .parrillo {
                if let bw = checkIn.bodyMetrics?.bodyWeight {
                    HStack {
                        Text("Peso corporal")
                        Spacer()
                        Text(String(format: "%.2f kg", bw))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Parrillo requiere peso corporal registrado en este check-in.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Sites

    private var sitesSection: some View {
        Section("Pliegues cutáneos (mm)") {
            ForEach(viewModel.requiredSiteLabels, id: \.label) { site in
                SkinfoldInputRow(label: site.label, text: binding(for: site.binding))
            }
        }
    }

    // MARK: - Live Result

    @ViewBuilder
    private var resultSection: some View {
        if let result = viewModel.calculationResult {
            Section {
                HStack {
                    Text("% Grasa corporal")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(String(format: "%.1f %%", result.bodyFatPercentage))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(fatColor(result.bodyFatPercentage))
                }
                HStack {
                    Text("Densidad corporal")
                    Spacer()
                    Text(String(format: "%.4f g/mL", result.bodyDensity))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Resultado calculado", systemImage: "chart.bar.fill")
            } footer: {
                Text("Calculado con el método \(viewModel.method.displayName) · Fórmula de Siri (1956)")
                    .font(.caption2)
            }
        }
    }

    // MARK: - Context

    private var contextSection: some View {
        Section("Datos del evaluador (opcional)") {
            HStack {
                Text("Evaluador")
                Spacer()
                TextField("Nombre", text: $viewModel.testerText)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Plicómetro")
                Spacer()
                TextField("Marca / modelo", text: $viewModel.caliperBrandText)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func binding(for keyPath: WritableKeyPath<SkinfoldMeasurementsViewModel, String>) -> Binding<String> {
        Binding(
            get: { viewModel[keyPath: keyPath] },
            set: { viewModel[keyPath: keyPath] = $0 }
        )
    }

    private func fatColor(_ fat: Double) -> Color {
        switch fat {
        case ..<10: return .blue
        case 10..<18: return .green
        case 18..<25: return .yellow
        case 25..<32: return .orange
        default: return .red
        }
    }
}

// MARK: - Input Row

private struct SkinfoldInputRow: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0.0", text: $text)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .frame(width: 64)
            Text("mm")
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)
        }
    }
}

// MARK: - Utilities

private func ageInYears(from birthDate: Date) -> Double {
    let calendar = Calendar.current
    let comps = calendar.dateComponents([.year], from: birthDate, to: Date())
    return Double(comps.year ?? 25)
}

#Preview("iPhone 16") {
    let checkIn = CheckIn(date: .now)
    SkinfoldMeasurementsFormView(checkIn: checkIn)
        .modelContainer(for: [CheckIn.self, SkinfoldMeasurements.self], inMemory: true)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
