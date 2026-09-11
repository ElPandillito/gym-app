//
//  TrendChartView.swift
//  GYM APP
//

import SwiftUI
import Charts

// MARK: - TrendChartView

/// Renders a time-series line chart for a single body-composition metric.
/// Receives DataPoints from the caller; computes OLS Trend internally via Trend.compute.
/// Contains no business logic — only presentation and formatting.
struct TrendChartView: View {
    let points: [DataPoint]
    let metricKey: MetricKey
    let preferences: CoachPreferences

    @State private var selectedDate: Date?

    private var presenter: TrendChartPresenter {
        TrendChartPresenter(metricKey: metricKey, preferences: preferences)
    }

    private var trend: Trend {
        Trend.compute(from: points)
    }

    private var displayPoints: [ChartDisplayPoint] {
        points
            .sorted { $0.date < $1.date }
            .map { ChartDisplayPoint(date: $0.date,
                                    displayValue: presenter.displayValue(for: $0.value)) }
    }

    private var trendLinePoints: [ChartDisplayPoint] {
        guard trend.direction != .insufficient,
              let first  = displayPoints.first,
              let last   = displayPoints.last,
              let origin = points.min(by: { $0.date < $1.date })?.date
        else { return [] }
        let startRaw = trend.projected(at: first.date, origin: origin)
        let endRaw   = trend.projected(at: last.date,  origin: origin)
        return [
            ChartDisplayPoint(date: first.date, displayValue: presenter.displayValue(for: startRaw)),
            ChartDisplayPoint(date: last.date,  displayValue: presenter.displayValue(for: endRaw)),
        ]
    }

    private var selectedPoint: ChartDisplayPoint? {
        guard let selectedDate else { return nil }
        return displayPoints.min(by: {
            abs($0.date.timeIntervalSince(selectedDate)) <
            abs($1.date.timeIntervalSince(selectedDate))
        })
    }

    // MARK: - Body

    var body: some View {
        if displayPoints.count < 2 {
            insufficientDataView
        } else {
            chartContent
        }
    }

    // MARK: - Chart Content

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            headerRow
            chartBody
                .frame(height: 180)
                .animation(.easeInOut(duration: 0.15), value: selectedDate)
        }
        .padding(AppSpacing.base)
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    @ViewBuilder
    private var headerRow: some View {
        if let selected = selectedPoint {
            calloutRow(selected)
                .transition(.opacity)
        } else {
            summaryRow
        }
    }

    private var summaryRow: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            if let last = displayPoints.last {
                Text(presenter.formattedValue(last.displayValue))
                    .font(AppTypography.metricValue)
                    .foregroundStyle(AppColors.primaryText)
                Text(presenter.unitLabel)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
            Spacer()
            trendBadge
        }
    }

    private func calloutRow(_ point: ChartDisplayPoint) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(presenter.formattedValue(point.displayValue))
                .font(AppTypography.metricValue)
                .foregroundStyle(AppColors.primaryText)
            Text(presenter.unitLabel)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            Text(point.date.formatted(.dateTime.day().month(.abbreviated).year()))
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    private var trendBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: trend.direction.chartIcon)
                .font(.caption.weight(.semibold))
            Text(presenter.trendRateText(slope: trend.slope, direction: trend.direction))
                .font(.caption.weight(.medium).monospacedDigit())
        }
        .foregroundStyle(trend.direction.chartColor)
    }

    // MARK: - Chart

    private var chartBody: some View {
        Chart {
            // Historical data line + selectable points
            ForEach(displayPoints) { point in
                LineMark(
                    x: .value("Fecha", point.date),
                    y: .value(metricKey.displayName, point.displayValue)
                )
                .foregroundStyle(Color.accentColor)
                .interpolationMethod(.monotone)

                PointMark(
                    x: .value("Fecha", point.date),
                    y: .value(metricKey.displayName, point.displayValue)
                )
                .foregroundStyle(Color.accentColor)
                .symbolSize(selectedPoint?.id == point.id ? 70 : 22)
                .accessibilityLabel(
                    Text(point.date.formatted(.dateTime.day().month(.abbreviated).year()))
                )
                .accessibilityValue(
                    Text("\(presenter.formattedValue(point.displayValue)) \(presenter.unitLabel)")
                )
            }

            // OLS trend line (dashed overlay)
            if trend.direction != .insufficient {
                ForEach(trendLinePoints) { point in
                    LineMark(
                        x: .value("Fecha", point.date),
                        y: .value("Tendencia", point.displayValue)
                    )
                    .foregroundStyle(trend.direction.chartColor.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .interpolationMethod(.linear)
                    .accessibilityHidden(true)
                }
            }

            // Vertical rule at the selected point
            if let selected = selectedPoint {
                RuleMark(x: .value("Seleccionado", selected.date))
                    .foregroundStyle(Color.secondary.opacity(0.2))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .accessibilityHidden(true)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: xAxisStride)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                AxisValueLabel(format: .dateTime.month(.abbreviated), centered: false)
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(presenter.formattedAxisValue(v))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXSelection(value: $selectedDate)
    }

    // MARK: - Empty State

    private var insufficientDataView: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title3)
                .foregroundStyle(AppColors.tertiaryText)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Historial insuficiente")
                    .font(AppTypography.subheadline.weight(.medium))
                    .foregroundStyle(AppColors.primaryText)
                Text(points.isEmpty
                     ? "Sin datos para este indicador."
                     : "Se necesitan al menos 2 registros para mostrar la gráfica.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(AppSpacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    // MARK: - Helpers

    private var xAxisStride: Int {
        guard let first = displayPoints.first?.date,
              let last  = displayPoints.last?.date else { return 1 }
        let months = Calendar.current
            .dateComponents([.month], from: first, to: last).month ?? 0
        switch months {
        case ..<3:  return 1
        case ..<9:  return 2
        default:    return 3
        }
    }
}

// MARK: - Trend.TrendDirection presentation helpers (scoped to this file)

private extension Trend.TrendDirection {
    var chartIcon: String {
        switch self {
        case .rising:       return "arrow.up.right"
        case .falling:      return "arrow.down.right"
        case .flat:         return "minus"
        case .insufficient: return "questionmark"
        }
    }

    var chartColor: Color {
        switch self {
        case .rising:              return Color.accentColor
        case .falling:             return AppColors.error
        case .flat, .insufficient: return AppColors.Trend.flat
        }
    }
}

// MARK: - ChartDisplayPoint

private struct ChartDisplayPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let displayValue: Double
}
