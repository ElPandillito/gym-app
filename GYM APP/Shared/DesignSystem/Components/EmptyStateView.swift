//
//  EmptyStateView.swift
//  GYM APP
//

import SwiftUI

/// Reusable empty state component for lists and detail sections.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppColors.tertiaryText)

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.primaryText)
                Text(message)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
            }
        }
        .padding(AppSpacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "person.2",
        title: "Sin atletas",
        message: "Registra tu primer atleta para comenzar.",
        actionTitle: "Nuevo atleta",
        action: {}
    )
}
