//
//  AthleteAlertsView.swift
//  GYM APP
//

import SwiftUI

struct AthleteAlertsView: View {
    let alerts: [AthleteAlert]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader(
                "Alertas",
                icon: "exclamationmark.triangle.fill",
                actionTitle: alerts.isEmpty ? nil : "\(alerts.count)"
            )

            if alerts.isEmpty {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.success)
                    Text("Sin alertas activas")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
            } else {
                alertList
            }
        }
    }

    private var alertList: some View {
        VStack(spacing: 0) {
            ForEach(alerts) { alert in
                AthleteAlertRow(alert: alert)
                if alert.id != alerts.last?.id {
                    Divider().padding(.leading, AppSpacing.xl + AppSpacing.sm)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}

// MARK: - Alert Row

private struct AthleteAlertRow: View {
    let alert: AthleteAlert

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: iconName)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 22)

            Text(description)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.primaryText)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private var iconName: String {
        switch alert.kind {
        case .inactive:          return "clock.badge.exclamationmark"
        case .negativeTrend:     return "arrow.up.right.circle.fill"
        case .noPhotos:          return "camera.badge.ellipsis"
        case .incompleteMetrics: return "exclamationmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch alert.kind {
        case .inactive:          return AppColors.error
        case .negativeTrend:     return AppColors.warning
        case .noPhotos:          return AppColors.info
        case .incompleteMetrics: return AppColors.warning
        }
    }

    private var description: String {
        switch alert.kind {
        case .inactive(let d):   return "Sin check-in hace \(d) día\(d == 1 ? "" : "s")"
        case .negativeTrend:     return "Tendencia de grasa al alza (+1 pp en 60 días)"
        case .noPhotos:          return "Sin fotografías en el último check-in"
        case .incompleteMetrics: return "Sin peso registrado en el último check-in"
        }
    }
}
