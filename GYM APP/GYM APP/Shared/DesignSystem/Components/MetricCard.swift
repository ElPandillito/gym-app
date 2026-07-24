//
//  MetricCard.swift
//  GYM APP
//

import SwiftUI

/// Reusable card for displaying a single metric KPI.
struct MetricCard: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String?
    let tintColor: Color

    init(
        title: String,
        value: String,
        unit: String? = nil,
        icon: String? = nil,
        tintColor: Color = .accentColor
    ) {
        self.title     = title
        self.value     = value
        self.unit      = unit
        self.icon      = icon
        self.tintColor = tintColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(tintColor)
            }
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(AppTypography.metricValue)
                    .foregroundStyle(AppColors.primaryText)
                if let unit {
                    Text(unit)
                        .font(AppTypography.metricLabel)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            Text(title)
                .font(AppTypography.metricLabel)
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(AppSpacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(AppShadows.card)
    }
}

#Preview {
    MetricCard(title: "% Grasa", value: "14.2", unit: "%", icon: "flame.fill", tintColor: .orange)
        .padding()
}
