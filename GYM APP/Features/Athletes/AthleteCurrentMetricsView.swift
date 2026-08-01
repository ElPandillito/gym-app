//
//  AthleteCurrentMetricsView.swift
//  GYM APP
//

import SwiftUI

struct AthleteCurrentMetricsView: View {
    let metrics: AthleteOverviewViewModel.CurrentMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Estado Actual", icon: "scalemass.fill")
            metricsGrid
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: AppSpacing.sm
        ) {
            if let w = metrics.weight {
                MetricCard(
                    title: "Peso",
                    value: String(format: "%.1f", w),
                    unit: "kg",
                    icon: "scalemass.fill",
                    tintColor: AppColors.accent
                )
            }

            if let bf = metrics.bodyFatPct {
                MetricCard(
                    title: "% Grasa",
                    value: String(format: "%.1f", bf),
                    unit: "%",
                    icon: "flame.fill",
                    tintColor: AppColors.BodyFat.color(for: bf)
                )
            }

            if let mm = metrics.muscleMass {
                MetricCard(
                    title: "Masa Magra",
                    value: String(format: "%.1f", mm),
                    unit: "kg",
                    icon: "figure.strengthtraining.traditional",
                    tintColor: AppColors.success
                )
            }

            if let bmi = metrics.bmi {
                MetricCard(
                    title: "IMC",
                    value: String(format: "%.1f", bmi),
                    unit: "kg/m²",
                    icon: "chart.bar.fill",
                    tintColor: AppColors.info
                )
            }
        }
    }
}
