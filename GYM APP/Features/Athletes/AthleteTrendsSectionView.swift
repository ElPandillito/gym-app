//
//  AthleteTrendsSectionView.swift
//  GYM APP
//

import SwiftUI

// MARK: - AthleteTrendsSectionView

struct AthleteTrendsSectionView: View {
    let report: AthleteStatisticsReport
    @Environment(CoachPreferencesStore.self) private var prefsStore

    private var fmt: AppUnitFormatter { AppUnitFormatter(preferences: prefsStore.preferences) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("Tendencias", icon: "chart.line.uptrend.xyaxis")

            if trendEntries.isEmpty {
                Text("Se necesitan al menos 2 check-ins para calcular tendencias.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(trendEntries.enumerated()), id: \.element.label) { idx, entry in
                        TrendRow(entry: entry)
                        if idx < trendEntries.count - 1 {
                            Divider().padding(.leading, AppSpacing.base)
                        }
                    }
                }
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
            }

            if !recordEntries.isEmpty {
                AppSectionHeader("Mejores Marcas", icon: "star.fill")
                VStack(spacing: 0) {
                    ForEach(Array(recordEntries.enumerated()), id: \.element.label) { idx, entry in
                        RecordRow(entry: entry)
                        if idx < recordEntries.count - 1 {
                            Divider().padding(.leading, AppSpacing.base)
                        }
                    }
                }
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
    }

    // MARK: - Data helpers

    fileprivate struct TrendEntry {
        let label: String
        let trend: Trend
        let rateLabel: String               // pre-formatted monthly rate, e.g. "+0.4 kg/mes"
        let positiveWhenIncreasing: Bool?   // nil = neutral (weight)
    }

    fileprivate struct RecordEntry {
        let label: String
        let value: String
        let date: Date
    }

    private var trendEntries: [TrendEntry] {
        var entries: [TrendEntry] = []
        if report.weightTrend.direction != .insufficient {
            entries.append(.init(
                label: "Peso",
                trend: report.weightTrend,
                rateLabel: fmt.weightSlopeMonthly(report.weightTrend.slope),
                positiveWhenIncreasing: nil
            ))
        }
        if report.bodyFatTrend.direction != .insufficient {
            let monthly = report.bodyFatTrend.slope * 30
            let sign    = monthly > 0 ? "+" : ""
            entries.append(.init(
                label: "Grasa Corporal",
                trend: report.bodyFatTrend,
                rateLabel: "\(sign)\(String(format: "%.1f", monthly)) %/mes",
                positiveWhenIncreasing: false
            ))
        }
        if report.muscleMassTrend.direction != .insufficient {
            entries.append(.init(
                label: "Masa Muscular",
                trend: report.muscleMassTrend,
                rateLabel: fmt.weightSlopeMonthly(report.muscleMassTrend.slope),
                positiveWhenIncreasing: true
            ))
        }
        return entries
    }

    private var recordEntries: [RecordEntry] {
        var entries: [RecordEntry] = []
        if let r = report.lowestBodyFat {
            entries.append(.init(label: "Mínima Grasa Corporal", value: String(format: "%.1f%%", r.value), date: r.date))
        }
        if let r = report.peakMuscleMass {
            entries.append(.init(label: "Máxima Masa Muscular", value: fmt.weight(r.value), date: r.date))
        }
        if let r = report.lowestWeight {
            entries.append(.init(label: "Mínimo Peso", value: fmt.weight(r.value), date: r.date))
        }
        if let r = report.highestWeight {
            entries.append(.init(label: "Máximo Peso", value: fmt.weight(r.value), date: r.date))
        }
        return entries
    }
}

// MARK: - TrendRow

private struct TrendRow: View {
    let entry: AthleteTrendsSectionView.TrendEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(entry.label)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.primaryText)
                Text(directionLabel)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: directionIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(directionColor)
                Text(entry.rateLabel)
                    .font(AppTypography.caption.monospacedDigit())
                    .foregroundStyle(directionColor)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private var directionLabel: String {
        switch entry.trend.direction {
        case .rising:       return "Tendencia al alza"
        case .falling:      return "Tendencia a la baja"
        case .flat:         return "Tendencia estable"
        case .insufficient: return "Datos insuficientes"
        }
    }

    private var directionIcon: String {
        switch entry.trend.direction {
        case .rising:       return "arrow.up.right"
        case .falling:      return "arrow.down.right"
        case .flat:         return "minus"
        case .insufficient: return "questionmark.circle"
        }
    }

    private var directionColor: Color {
        switch entry.trend.direction {
        case .flat, .insufficient:
            return AppColors.Trend.flat
        case .rising:
            guard let positive = entry.positiveWhenIncreasing else { return AppColors.Trend.flat }
            return positive ? AppColors.Trend.rising : AppColors.Trend.falling
        case .falling:
            guard let positive = entry.positiveWhenIncreasing else { return AppColors.Trend.flat }
            return positive ? AppColors.Trend.falling : AppColors.Trend.rising
        }
    }
}

// MARK: - RecordRow

private struct RecordRow: View {
    let entry: AthleteTrendsSectionView.RecordEntry

    var body: some View {
        HStack {
            Text(entry.label)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.primaryText)
            Spacer()
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text(entry.value)
                    .font(AppTypography.footnote.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                Text(entry.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}
