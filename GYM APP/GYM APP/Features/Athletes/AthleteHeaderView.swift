//
//  AthleteHeaderView.swift
//  GYM APP
//

import SwiftUI

struct AthleteHeaderView: View {
    let header: AthleteOverviewViewModel.Header
    let activity: AthleteOverviewViewModel.ActivityInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            bioRow
            Divider()
            statsRow
        }
        .padding(AppSpacing.base)
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    // MARK: - Bio row

    private var bioRow: some View {
        HStack(spacing: AppSpacing.base) {
            bioChip(value: header.ageText,    fallback: "—",     icon: "calendar.circle")
            bioChip(value: header.heightText, fallback: "—",     icon: "ruler")
            bioChip(value: header.gender,     icon: "person.fill")
        }
    }

    private func bioChip(value: String?, fallback: String = "—", icon: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
            Text(value ?? fallback)
                .font(AppTypography.caption)
                .foregroundStyle(value != nil ? AppColors.primaryText : AppColors.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statColumn(
                value: "\(header.checkInCount)",
                label: "Check Ins"
            )
            statDivider
            statColumn(
                value: "\(header.totalPhotos)",
                label: "Fotos"
            )
            statDivider
            statColumn(
                value: lastCheckInText,
                label: "Último CI"
            )
        }
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTypography.footnote.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Divider()
            .frame(height: 28)
    }

    private var lastCheckInText: String {
        guard let date = activity?.lastCheckInDate else { return "—" }
        if let days = activity?.daysSinceLastCheckIn {
            return days == 0 ? "Hoy" : "Hace \(days)d"
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}
