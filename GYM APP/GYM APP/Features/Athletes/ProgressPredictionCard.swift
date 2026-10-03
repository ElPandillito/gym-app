//
//  ProgressPredictionCard.swift
//  GYM APP
//
//  Shows OLS-based progress predictions for 30/60/90-day horizons.
//  Data comes from ProgressPredictionStub via AthleteOverviewViewModel.
//

import SwiftUI

struct ProgressPredictionCard: View {

    let horizons: [AthleteOverviewViewModel.PredictionHorizon]
    let isPredicting: Bool
    let currentMetrics: AthleteOverviewViewModel.CurrentMetrics?

    @State private var selectedDays: Int = 30
    @Environment(CoachPreferencesStore.self) private var prefsStore

    private var fmt: AppUnitFormatter { AppUnitFormatter(preferences: prefsStore.preferences) }

    private var selectedHorizon: AthleteOverviewViewModel.PredictionHorizon? {
        horizons.first { $0.daysAhead == selectedDays }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Predicción de Progreso", icon: "chart.line.uptrend.xyaxis")
            cardContent
        }
    }

    // MARK: - Content routing

    @ViewBuilder
    private var cardContent: some View {
        if isPredicting && horizons.isEmpty {
            loadingCard
        } else if horizons.isEmpty {
            insufficientDataCard
        } else if let horizon = selectedHorizon {
            VStack(spacing: AppSpacing.md) {
                horizonPicker
                metricsRow(horizon)
                confidenceFooter(horizon)
            }
            .padding(AppSpacing.base)
            .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        }
    }

    // MARK: - Loading / empty states

    private var loadingCard: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(.secondary)
                .padding(AppSpacing.xl)
            Spacer()
        }
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private var insufficientDataCard: some View {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: "Sin predicción disponible",
            message: "Se necesitan al menos 2 check-ins con datos de composición corporal."
        )
    }

    // MARK: - Horizon picker

    private var horizonPicker: some View {
        Picker("Horizonte", selection: $selectedDays) {
            Text("30 días").tag(30)
            Text("60 días").tag(60)
            Text("90 días").tag(90)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Metrics row

    private func metricsRow(_ horizon: AthleteOverviewViewModel.PredictionHorizon) -> some View {
        HStack(spacing: 0) {
            if let r = horizon.weight {
                predictionColumn(
                    label: "Peso",
                    value: fmt.weight(r.predictedValue),
                    intervalText: "± \(fmt.weight(r.confidenceInterval.upperBound - r.predictedValue))",
                    delta: currentMetrics?.weight.map { r.predictedValue - $0 },
                    sentiment: .neutral
                )
            }

            if horizon.weight != nil && horizon.bodyFat != nil { columnDivider }

            if let r = horizon.bodyFat {
                predictionColumn(
                    label: "% Grasa",
                    value: String(format: "%.1f %%", r.predictedValue),
                    intervalText: String(format: "± %.1f %%", r.confidenceInterval.upperBound - r.predictedValue),
                    delta: currentMetrics?.bodyFatPct.map { r.predictedValue - $0 },
                    sentiment: .positiveWhenDecreased
                )
            }

            if horizon.bodyFat != nil && horizon.muscleMass != nil { columnDivider }

            if let r = horizon.muscleMass {
                predictionColumn(
                    label: "Masa Magra",
                    value: fmt.weight(r.predictedValue),
                    intervalText: "± \(fmt.weight(r.confidenceInterval.upperBound - r.predictedValue))",
                    delta: currentMetrics?.muscleMass.map { r.predictedValue - $0 },
                    sentiment: .positiveWhenIncreased
                )
            }
        }
    }

    private func predictionColumn(
        label: String,
        value: String,
        intervalText: String,
        delta: Double?,
        sentiment: MetricSentiment
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.secondaryText)

            Text(value)
                .font(AppTypography.footnote.weight(.bold).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let delta {
                Text(deltaLabel(delta))
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(deltaColor(delta, sentiment: sentiment))
            }

            Text(intervalText)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var columnDivider: some View {
        Divider().frame(height: 48)
    }

    // MARK: - Confidence footer

    private func confidenceFooter(_ horizon: AthleteOverviewViewModel.PredictionHorizon) -> some View {
        let conf = horizon.averageConfidence
        return HStack(spacing: AppSpacing.xs) {
            Image(systemName: "info.circle")
                .font(.caption2)
                .foregroundStyle(AppColors.tertiaryText)
            Text("Confianza: ")
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.tertiaryText)
            Text(confidenceLabel(conf))
                .font(AppTypography.caption2.weight(.semibold))
                .foregroundStyle(confidenceColor(conf))
            Text("(\(Int(conf * 100))%) · OLS lineal")
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.tertiaryText)
            Spacer()
        }
    }

    // MARK: - Formatting helpers

    private func deltaLabel(_ delta: Double) -> String {
        let sign = delta >= 0 ? "↑ +" : "↓ "
        return "\(sign)\(String(format: "%.1f", delta))"
    }

    private func deltaColor(_ delta: Double, sentiment: MetricSentiment) -> Color {
        if abs(delta) < 0.05 { return AppColors.secondaryText }
        switch sentiment {
        case .neutral:               return AppColors.secondaryText
        case .positiveWhenDecreased: return delta < 0 ? AppColors.success : AppColors.error
        case .positiveWhenIncreased: return delta > 0 ? AppColors.success : AppColors.error
        }
    }

    private func confidenceLabel(_ confidence: Double) -> String {
        if confidence >= 0.6 { return "Alta" }
        if confidence >= 0.3 { return "Media" }
        return "Baja"
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.6 { return AppColors.success }
        if confidence >= 0.3 { return AppColors.warning }
        return AppColors.error
    }
}
