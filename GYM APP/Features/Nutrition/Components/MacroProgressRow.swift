//
//  MacroProgressRow.swift
//  GYM APP
//

import SwiftUI

/// Visual progress bar for a single macro against its daily target.
///
/// Color coding:
///   < 90%      → AppColors.error   (deficit)
///   90–105%    → AppColors.success (on target)
///   > 105%     → AppColors.warning (excess)
///
/// When target <= 0 the bar is hidden and no percentage is shown.
struct MacroProgressRow: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color

    private var ratio: Double {
        guard target > 0 else { return 0 }
        return current / target
    }

    private var percentage: Double { ratio * 100 }

    private var barColor: Color {
        guard target > 0 else { return AppColors.tertiaryText }
        switch percentage {
        case ..<90:    return AppColors.error
        case 90...105: return AppColors.success
        default:       return AppColors.warning
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(AppTypography.footnote.weight(.medium))
                    .foregroundStyle(AppColors.primaryText)

                Spacer()

                if target > 0 {
                    Text(String(format: "%.0f / %.0f %@", current, target, unit))
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)

                    Text(String(format: "%.0f%%", percentage))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(barColor)
                        .frame(minWidth: 38, alignment: .trailing)
                } else {
                    Text(String(format: "%.0f %@", current, unit))
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }

            if target > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(barColor.opacity(0.15))
                            .frame(height: 5)
                        Capsule()
                            .fill(barColor)
                            // cap at full width visually; percentage text shows the excess
                            .frame(width: min(geo.size.width, geo.size.width * ratio), height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
    }
}
