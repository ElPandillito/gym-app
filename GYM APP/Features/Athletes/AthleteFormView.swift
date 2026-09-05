//
//  AthleteFormView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct AthleteFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: AthleteFormViewModel

    init(athlete: Athlete? = nil) {
        _viewModel = State(initialValue: AthleteFormViewModel(athlete: athlete))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos personales") {
                    TextField("Nombre completo", text: $viewModel.name)
                        .onChange(of: viewModel.name) { _, _ in viewModel.validateName() }

                    if let error = viewModel.nameError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Picker("Género", selection: $viewModel.gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                }

                Section("Fase de entrenamiento") {
                    Picker("Fase", selection: $viewModel.phase) {
                        ForEach(AthletePhase.allCases, id: \.self) { phase in
                            Label(phase.displayName, systemImage: phase.systemImage).tag(phase)
                        }
                    }
                }

                Section("Medidas") {
                    HStack {
                        TextField("Estatura (cm)", text: $viewModel.heightText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .onChange(of: viewModel.heightText) { _, _ in viewModel.validateHeight() }
                        Text("cm")
                            .foregroundStyle(.secondary)
                    }

                    if let error = viewModel.heightError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Toggle("Fecha de nacimiento", isOn: $viewModel.hasBirthDate)

                    if viewModel.hasBirthDate {
                        DatePicker(
                            "Fecha",
                            selection: $viewModel.birthDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle(viewModel.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let repository = AthleteRepository(context: context)
                        if viewModel.save(using: repository) { dismiss() }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .alert("Error al guardar", isPresented: Binding(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            )) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(viewModel.saveError ?? "")
            }
        }
    }
}

#Preview("iPhone 16") {
    AthleteFormView()
        .modelContainer(for: Athlete.self, inMemory: true)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
