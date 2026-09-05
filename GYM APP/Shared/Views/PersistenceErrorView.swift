//
//  PersistenceErrorView.swift
//  GYM APP
//
//  Shown when the SwiftData ModelContainer cannot initialize.
//  Does NOT expose technical error details or file paths.
//  Data is preserved on disk — the error is a configuration or migration issue.

import SwiftUI

struct PersistenceErrorView: View {
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.orange)

            VStack(spacing: AppSpacing.sm) {
                Text("No se pudo abrir la base de datos")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Ocurrió un problema al iniciar el almacenamiento de GYM APP. Tus datos están intactos en el dispositivo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Label("No elimines la aplicación — perderías todos los datos.", systemImage: "exclamationmark.triangle.fill")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.orange)

                Label("Cierra completamente la app y vuelve a abrirla.", systemImage: "arrow.counterclockwise.circle")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Label("Si el problema persiste, contacta soporte técnico.", systemImage: "envelope.circle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(AppSpacing.base)
            .background(.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: AppRadius.md))
            .padding(.horizontal, AppSpacing.xl)

            Spacer()
            Spacer()
        }
        .padding(AppSpacing.base)
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 380)
        #endif
    }
}
