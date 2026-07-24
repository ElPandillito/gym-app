//
//  DashboardView.swift
//  GYM APP
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Stats row
                HStack(spacing: 12) {
                    DashboardStatCard(
                        title: "Atletas",
                        value: "—",
                        icon: "person.2.fill",
                        color: .blue
                    )
                    DashboardStatCard(
                        title: "Este Mes",
                        value: "—",
                        icon: "checkmark.seal.fill",
                        color: .green
                    )
                    DashboardStatCard(
                        title: "Pendientes",
                        value: "—",
                        icon: "clock.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)

                // Recent check-ins
                VStack(alignment: .leading, spacing: 12) {
                    Text("Check Ins Recientes")
                        .font(.headline)
                        .padding(.horizontal)

                    ContentUnavailableView {
                        Label("Sin actividad reciente", systemImage: "checkmark.circle")
                    } description: {
                        Text("Los check ins de tus atletas aparecerán aquí.")
                    }
                    .frame(height: 200)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Athletes overview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mis Atletas")
                        .font(.headline)
                        .padding(.horizontal)

                    ContentUnavailableView {
                        Label("Sin atletas", systemImage: "person.2")
                    } description: {
                        Text("Agrega tu primer atleta para comenzar.")
                    }
                    .frame(height: 160)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Dashboard")
    }
}

// MARK: - Stat Card

private struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("iPhone 16") {
    NavigationStack {
        DashboardView()
    }
    .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
