//
//  ComparisonMetricCard.swift
//  GYM APP
//

import SwiftUI

struct ComparisonMetricCard: View {
    let row: ComparisonRow

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(row.label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: AppSpacing.sm) {
                valueColumn(label: "Antes", value: formatted(row.diff.before))
                    .frame(maxWidth: .infinity)

                deltaBadge
                    .frame(maxWidth: .infinity)

                valueColumn(label: "Después", value: formatted(row.diff.after))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(AppSpacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Subviews

    private var deltaBadge: some View {
        Text(deltaText)
            .font(.caption.weight(.semibold))
            .foregroundStyle(badgeColor)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func valueColumn(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    // MARK: - Color logic (View layer decides good/bad, not the model)

    private var badgeColor: Color {
        switch row.diff.direction {
        case .unchanged, .unavailable:
            return .secondary
        case .increased:
            switch row.sentiment {
            case .positiveWhenIncreased: return .green
            case .positiveWhenDecreased: return .red
            case .neutral:               return .secondary
            }
        case .decreased:
            switch row.sentiment {
            case .positiveWhenDecreased: return .green
            case .positiveWhenIncreased: return .red
            case .neutral:               return .secondary
            }
        }
    }

    // MARK: - Formatting

    private var deltaText: String {
        guard let delta = row.diff.absoluteChange, row.diff.direction != .unchanged else {
            return row.diff.direction == .unchanged ? "=" : "—"
        }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(formatNumber(delta, for: row.unit))\(unitSuffix)"
    }

    private func formatted(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return "\(formatNumber(v, for: row.unit))\(unitSuffix)"
    }

    private func formatNumber(_ v: Double, for unit: String) -> String {
        switch unit {
        case "kcal", "":  return String(format: "%.0f", v)
        case "%":          return String(format: "%.1f", v)
        default:           return String(format: "%.2f", v)
        }
    }

    private var unitSuffix: String {
        switch row.unit {
        case "":     return ""
        case "%":    return "%"
        default:     return " \(row.unit)"
        }
    }
}
