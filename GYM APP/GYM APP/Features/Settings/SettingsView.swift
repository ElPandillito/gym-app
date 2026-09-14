//
//  SettingsView.swift
//  GYM APP
//

import SwiftUI

struct SettingsView: View {
    @Environment(CoachPreferencesStore.self) private var prefs
    @State private var showResetAlert = false

    var body: some View {
        @Bindable var prefs = prefs
        List {

            // MARK: - Profile header
            Section {
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 54, height: 54)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                        }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Entrenador")
                            .font(.headline)
                        Text("Configurar perfil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 6)
            }

            // MARK: - Alert thresholds
            Section {
                Stepper(
                    "Inactividad: \(prefs.inactivityThresholdDays) días",
                    value: $prefs.inactivityThresholdDays,
                    in: 7...90
                )
                Stepper(
                    "Ventana de tendencias: \(prefs.trendWindowDays) días",
                    value: $prefs.trendWindowDays,
                    in: 14...180,
                    step: 7
                )
                Stepper(
                    "Máx. alertas visibles: \(prefs.maxAlertsShown)",
                    value: $prefs.maxAlertsShown,
                    in: 1...30
                )
            } header: {
                Label("Umbrales de alertas", systemImage: "slider.horizontal.3")
            } footer: {
                Text("Días sin check-in antes de marcar un atleta como inactivo.")
            }

            // MARK: - Alert toggles
            Section {
                Toggle("Alertas de inactividad",     isOn: $prefs.showInactiveAlerts)
                Toggle("Alertas sin fotografías",    isOn: $prefs.showPhotoAlerts)
                Toggle("Alertas de datos incompletos", isOn: $prefs.showMetricAlerts)
            } header: {
                Label("Tipos de alerta", systemImage: "bell.badge.fill")
            }

            // MARK: - Units
            Section {
                Picker("Unidad de peso", selection: $prefs.preferredWeightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                Picker("Unidad de medida", selection: $prefs.preferredLengthUnit) {
                    ForEach(LengthUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
            } header: {
                Label("Unidades", systemImage: "ruler.fill")
            }

            // MARK: - App section (stubs)
            Section("Aplicación") {
                SettingsRowView(icon: "bell.fill",   color: .red,  label: "Notificaciones")
                SettingsRowView(icon: "icloud.fill", color: .blue, label: "Sincronización")
                SettingsRowView(icon: "lock.fill",   color: .gray, label: "Privacidad y seguridad")
            }

            Section("Soporte") {
                SettingsRowView(icon: "questionmark.circle.fill", color: .orange, label: "Ayuda")
                SettingsRowView(icon: "star.fill",                color: .yellow, label: "Calificar la app")
                SettingsRowView(icon: "envelope.fill",           color: .green,  label: "Contacto")
            }

            // MARK: - Reset
            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Label("Restablecer preferencias", systemImage: "arrow.counterclockwise")
                }
            }

            // MARK: - Version
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("GYM APP")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text("Versión 1.0.0")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Configuración")
        .alert("Restablecer preferencias", isPresented: $showResetAlert) {
            Button("Restablecer", role: .destructive) { prefs.resetToDefaults() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Todos los umbrales y toggles volverán a sus valores por defecto.")
        }
    }
}

// MARK: - Settings Row

private struct SettingsRowView: View {
    let icon: String
    let color: Color
    let label: String

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: icon)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }

                Text(label)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview("iPhone 16") {
    NavigationStack {
        SettingsView()
    }
    .environment(CoachPreferencesStore())
    .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
