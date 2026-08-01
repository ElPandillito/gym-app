//
//  AthleteProgressSummaryView.swift
//  GYM APP
//

import SwiftUI

struct AthleteProgressSummaryView: View {
    let summary: AthleteOverviewViewModel.ProgressSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Progreso Reciente", icon: "arrow.up.right.circle.fill")

            if let summary = summary {
                comparisonCard(summary)
            } else {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Sin comparación disponible",
                    message: "Se necesitan al menos 2 check-ins para mostrar el progreso."
                )
            }
        }
    }

    // MARK: - Comparison card

    private func comparisonCard(_ summary: AthleteOverviewViewModel.ProgressSummary) -> some View {
        NavigationLink {
            ComparisonView(checkInA: summary.earlierCheckIn, checkInB: summary.laterCheckIn)
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                periodLabel(summary)

                HStack(spacing: 0) {
                    deltaColumn(
                        label: "Peso",
                        diff: summary.weightDiff,
                        unit: "kg",
                        sentiment: .neutral
                    )
                    columnDivider
                    deltaColumn(
                        label: "% Grasa",
                        diff: summary.bodyFatDiff,
                        unit: "%",
                        sentiment: .positiveWhenDecreased
                    )
                    columnDivider
                    deltaColumn(
                        label: "Cintura",
                        diff: summary.waistDiff,
                        unit: "cm",
                        sentiment: .positiveWhenDecreased
                    )
                }

                HStack {
                    Spacer()
                    Label("Ver comparación completa", systemImage: "chevron.right")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(AppSpacing.base)
            .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        }
        .buttonStyle(.plain)
    }

    private func periodLabel(_ summary: AthleteOverviewViewModel.ProgressSummary) -> some View {
        HStack {
            Text(summary.earlierCheckIn.date.formatted(.dateTime.day().month(.abbreviated).year()))
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(AppColors.tertiaryText)
            Text(summary.laterCheckIn.date.formatted(.dateTime.day().month(.abbreviated).year()))
            Spacer()
            Text("\(summary.daysBetween) días")
                .foregroundStyle(AppColors.tertiaryText)
        }
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.secondaryText)
    }

    // MARK: - Delta column

    private func deltaColumn(
        label: String,
        diff: MetricDiff,
        unit: String,
        sentiment: MetricSentiment
    ) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(label)
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.secondaryText)

            Text(deltaText(diff: diff, unit: unit))
                .font(AppTypography.footnote.weight(.semibold).monospacedDigit())
                .foregroundStyle(deltaColor(diff: diff, sentiment: sentiment))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var columnDivider: some View {
        Divider().frame(height: 36)
    }

    // MARK: - Formatting helpers

    private func deltaText(diff: MetricDiff, unit: String) -> String {
        guard let delta = diff.absoluteChange, diff.direction != .unavailable else { return "—" }
        if diff.direction == .unchanged { return "=" }
        let sign = delta > 0 ? "+" : ""
        switch unit {
        case "kg":  return "\(sign)\(String(format: "%.1f", delta)) kg"
        case "%":   return "\(sign)\(String(format: "%.1f", delta))%"
        case "cm":  return "\(sign)\(String(format: "%.1f", delta)) cm"
        default:    return "\(sign)\(String(format: "%.1f", delta)) \(unit)"
        }
    }

    private func deltaColor(diff: MetricDiff, sentiment: MetricSentiment) -> Color {
        switch diff.direction {
        case .unchanged, .unavailable: return AppColors.secondaryText
        case .decreased:
            switch sentiment {
            case .positiveWhenDecreased: return AppColors.success
            case .positiveWhenIncreased: return AppColors.error
            case .neutral:               return AppColors.secondaryText
            }
        case .increased:
            switch sentiment {
            case .positiveWhenDecreased: return AppColors.error
            case .positiveWhenIncreased: return AppColors.success
            case .neutral:               return AppColors.secondaryText
            }
        }
    }
}
