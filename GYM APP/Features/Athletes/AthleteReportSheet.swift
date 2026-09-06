//
//  AthleteReportSheet.swift
//  GYM APP
//

import SwiftUI

struct AthleteReportSheet: View {
    let athlete: Athlete
    let statisticsReport: AthleteStatisticsReport?

    @Environment(\.dismiss) private var dismiss

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
                            item: AthleteReportSerializer.text(from: r),
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
                    labelRow("Estatura", String(format: "%.0f cm", h))
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
                trendRow("Peso",          stats.weightTrend,     unit: "kg")
                trendRow("% Grasa",       stats.bodyFatTrend,    unit: "%")
                trendRow("Masa muscular", stats.muscleMassTrend, unit: "kg")
            }
            .cardStyle()
        }
    }

    @ViewBuilder
    private func recordsSection(_ stats: AthleteStatisticsReport) -> some View {
        let available: [(String, MetricRecord)] = [
            ("Menor % grasa",      stats.lowestBodyFat),
            ("Mayor % grasa",      stats.highestBodyFat),
            ("Menor peso",         stats.lowestWeight),
            ("Mayor peso",         stats.highestWeight),
            ("Pico masa muscular", stats.peakMuscleMass),
        ].compactMap { pair in pair.1.map { (pair.0, $0) } }

        if !available.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                AppSectionHeader("Marcas Personales", icon: "trophy.fill")
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(Array(available.enumerated()), id: \.offset) { _, pair in
                        recordRow(pair.0, pair.1)
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

    private func trendRow(_ label: String, _ trend: Trend, unit: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            trendBadge(trend, unit: unit)
        }
    }

    @ViewBuilder
    private func trendBadge(_ trend: Trend, unit: String) -> some View {
        switch trend.direction {
        case .rising:
            Label(String(format: "+%.2f %@/mes", trend.slope * 30, unit), systemImage: "arrow.up.right")
                .font(AppTypography.caption.weight(.medium))
                .foregroundStyle(AppColors.Trend.rising)
        case .falling:
            Label(String(format: "%.2f %@/mes", trend.slope * 30, unit), systemImage: "arrow.down.right")
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

    private func recordRow(_ label: String, _ record: MetricRecord) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", record.value))
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
