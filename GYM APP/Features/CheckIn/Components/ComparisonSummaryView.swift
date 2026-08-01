//
//  ComparisonSummaryView.swift
//  GYM APP
//

import SwiftUI

struct ComparisonSummaryView: View {
    let summary: ComparisonSummary

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header
            if !summary.insights.isEmpty {
                Divider()
                insightsList
            }
        }
        .padding(AppSpacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !summary.athleteName.isEmpty {
                Text(summary.athleteName)
                    .font(.headline)
            }
            HStack(spacing: AppSpacing.xs) {
                Text(summary.dateA.formatted(.dateTime.day().month(.abbreviated).year()))
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(summary.dateB.formatted(.dateTime.day().month(.abbreviated).year()))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text("\(summary.daysBetween) días entre check-ins")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Insights

    private var insightsList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(summary.insights.indices, id: \.self) { i in
                insightRow(for: summary.insights[i])
            }
        }
    }

    @ViewBuilder
    private func insightRow(for insight: ComparisonInsight) -> some View {
        switch insight {
        case .improvement(let label, let delta, let unit):
            row(icon: "arrow.up.circle.fill", color: .green,
                text: "\(label): \(formattedDelta(delta, unit: unit))")

        case .regression(let label, let delta, let unit):
            row(icon: "arrow.down.circle.fill", color: .red,
                text: "\(label): \(formattedDelta(delta, unit: unit))")

        case .change(let label, let delta, let unit):
            row(icon: "arrow.left.arrow.right.circle.fill", color: .secondary,
                text: "\(label): \(formattedDelta(delta, unit: unit))")

        case .photosAdded(let count):
            row(icon: "camera.fill", color: .pink,
                text: "\(count) foto\(count == 1 ? "" : "s") añadida\(count == 1 ? "" : "s")")

        case .photosRemoved(let count):
            row(icon: "camera.fill", color: .secondary,
                text: "\(count) foto\(count == 1 ? "" : "s") eliminada\(count == 1 ? "" : "s")")

        case .noteAdded(let isCoach):
            row(icon: isCoach ? "note.text" : "person.text.rectangle.fill",
                color: isCoach ? .indigo : .mint,
                text: isCoach ? "Nota del coach añadida" : "Nota del atleta añadida")
        }
    }

    private func row(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 18)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Formatting

    private func formattedDelta(_ delta: Double, unit: String) -> String {
        let sign = delta >= 0 ? "+" : ""
        switch unit {
        case "kg":   return "\(sign)\(String(format: "%.2f", delta)) kg"
        case "%":    return "\(sign)\(String(format: "%.1f", delta))%"
        case "cm":   return "\(sign)\(String(format: "%.1f", delta)) cm"
        case "kcal": return "\(sign)\(String(format: "%.0f", delta)) kcal"
        case "":     return "\(sign)\(String(format: "%.0f", delta))"
        default:     return "\(sign)\(String(format: "%.1f", delta)) \(unit)"
        }
    }
}
