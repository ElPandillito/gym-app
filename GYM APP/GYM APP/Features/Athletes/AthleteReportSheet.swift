//
//  AthleteReportSheet.swift
//  GYM APP
//

import SwiftUI

struct AthleteReportSheet: View {
    let athlete: Athlete
    let statisticsReport: AthleteStatisticsReport?

    @Environment(\.dismiss) private var dismiss
    @Environment(CoachPreferencesStore.self) private var prefsStore

    private var fmt: AppUnitFormatter { AppUnitFormatter(preferences: prefsStore.preferences) }

    private var report: AthleteReport? {
        guard let stats = statisticsReport else { return nil }
        return AthleteReportBuilder()
            .setAthlete(AthleteSnapshot(from: athlete))
            .setStatistics(stats)
            .build()
    }

    var body: some View {
        NavigationStack {
            Group {
                if let r = report {
                    reportContent(r)
                } else {
                    ContentUnavailableView {
                        Label("Datos insuficientes", systemImage: "chart.bar.xaxis")
                    } description: {
                        Text("Se necesitan al menos 2 check-ins con métricas para generar un reporte.")
                    }
                }
            }
            .navigationTitle("Reporte del Atleta")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                if let r = report {
                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(
                            item: AthleteReportSerializer.text(from: r, preferences: prefsStore.preferences),
                            preview: SharePreview(
                                "Reporte del atleta",
                                icon: Image(systemName: "doc.text.fill")
                            )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Report content

    @ViewBuilder
    private func reportContent(_ report: AthleteReport) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                headerSection(report)
                statsSection(report.statistics)
                trendsSection(report.statistics)
                recordsSection(report.statistics)
            }
            .padding(AppSpacing.base)
            .padding(.bottom, AppSpacing.xxxl)
        }
    }

    // MARK: - Sections

    private func headerSection(_ report: AthleteReport) -> some View {
        let a = report.athlete
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Atleta", icon: "person.fill")
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                labelRow("Género", a.gender.displayName)
                if let age = a.ageYears {
                    labelRow("Edad", "\(Int(age)) años")
                }
                if let h = a.heightCm {
                    labelRow("Estatura", fmt.height(h))
                }
                labelRow(
                    "Generado",
                    report.generatedAt.formatted(.dateTime.month(.abbreviated).day().year())
                )
            }
            .cardStyle()
        }
    }

    private func statsSection(_ stats: AthleteStatisticsReport) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Estadísticas", icon: "chart.bar.fill")
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                labelRow("Check-ins", "\(stats.checkInCount)")
                if let p = stats.period {
                    labelRow("Período", periodText(p))
                }
                if let avg = stats.averageDaysBetweenCheckIns {
                    labelRow("Frecuencia", String(format: "%.0f días promedio", avg))
                }
            }
            .cardStyle()
        }
    }

    private func trendsSection(_ stats: AthleteStatisticsReport) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Tendencias", icon: "chart.line.uptrend.xyaxis")
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                trendRow("Peso",          stats.weightTrend,     metric: .weight)
                trendRow("% Grasa",       stats.bodyFatTrend,    metric: .percentage)
                trendRow("Masa muscular", stats.muscleMassTrend, metric: .weight)
            }
            .cardStyle()
        }
    }

    @ViewBuilder
    private func recordsSection(_ stats: AthleteStatisticsReport) -> some View {
        let raw: [(String, MetricRecord?, Bool)] = [
            ("Menor % grasa",      stats.lowestBodyFat,  false),
            ("Mayor % grasa",      stats.highestBodyFat, false),
            ("Menor peso",         stats.lowestWeight,   true),
            ("Mayor peso",         stats.highestWeight,  true),
            ("Pico masa muscular", stats.peakMuscleMass, true),
        ]
        let available = raw.compactMap { (label, record, isWeight) -> (String, MetricRecord, Bool)? in
            guard let r = record else { return nil }
            return (label, r, isWeight)
        }

        if !available.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                AppSectionHeader("Marcas Personales", icon: "trophy.fill")
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(Array(available.enumerated()), id: \.offset) { _, tuple in
                        recordRow(tuple.0, tuple.1, isWeight: tuple.2)
                    }
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Row builders

    private func labelRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            Text(value)
                .font(AppTypography.subheadline.weight(.medium))
                .foregroundStyle(AppColors.primaryText)
        }
    }

    private enum TrendMetric { case weight, percentage }

    private func trendRow(_ label: String, _ trend: Trend, metric: TrendMetric) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            trendBadge(trend, metric: metric)
        }
    }

    @ViewBuilder
    private func trendBadge(_ trend: Trend, metric: TrendMetric) -> some View {
        switch trend.direction {
        case .rising:
            let rate: String = metric == .weight
                ? String(format: "+%.2f \(fmt.weightLabel)/mes", fmt.convertedWeight(trend.slope * 30))
                : String(format: "+%.2f %%/mes", trend.slope * 30)
            Label(rate, systemImage: "arrow.up.right")
                .font(AppTypography.caption.weight(.medium))
                .foregroundStyle(AppColors.Trend.rising)
        case .falling:
            let rate: String = metric == .weight
                ? String(format: "%.2f \(fmt.weightLabel)/mes", fmt.convertedWeight(trend.slope * 30))
                : String(format: "%.2f %%/mes", trend.slope * 30)
            Label(rate, systemImage: "arrow.down.right")
                .font(AppTypography.caption.weight(.medium))
                .foregroundStyle(AppColors.Trend.falling)
        case .flat:
            Label("Estable", systemImage: "minus")
                .font(AppTypography.caption.weight(.medium))
                .foregroundStyle(AppColors.Trend.flat)
        case .insufficient:
            Text("—")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    private func recordRow(_ label: String, _ record: MetricRecord, isWeight: Bool) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(isWeight ? fmt.weight(record.value) : String(format: "%.1f", record.value))
                    .font(AppTypography.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)
                Text(record.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }

    // MARK: - Helpers

    private func periodText(_ interval: DateInterval) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale    = Locale(identifier: "es_MX")
        return "\(f.string(from: interval.start)) – \(f.string(from: interval.end))"
    }
}

// MARK: - View modifier

private extension View {
    func cardStyle() -> some View {
        self
            .padding(AppSpacing.base)
            .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}
