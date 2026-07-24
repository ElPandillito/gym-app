//
//  SettingsView.swift
//  GYM APP
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
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

            Section("Aplicación") {
                SettingsRowView(icon: "bell.fill",    color: .red,    label: "Notificaciones")
                SettingsRowView(icon: "icloud.fill",  color: .blue,   label: "Sincronización")
                SettingsRowView(icon: "lock.fill",    color: .gray,   label: "Privacidad y seguridad")
            }

            Section("Soporte") {
                SettingsRowView(icon: "questionmark.circle.fill", color: .orange, label: "Ayuda")
                SettingsRowView(icon: "star.fill",                color: .yellow, label: "Calificar la app")
                SettingsRowView(icon: "envelope.fill",           color: .green,  label: "Contacto")
            }

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
    .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
