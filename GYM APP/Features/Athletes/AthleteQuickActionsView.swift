//
//  AthleteQuickActionsView.swift
//  GYM APP
//

import SwiftUI

struct AthleteQuickActionsView: View {
    let athlete: Athlete
    let latestCheckIn: CheckIn?

    @State private var showNewCheckIn     = false
    @State private var showBodyMetrics    = false
    @State private var showCircumferences = false
    @State private var showSkinfolds      = false
    @State private var showComparePicker  = false

    private var hasCheckIn: Bool { latestCheckIn != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Acciones Rápidas", icon: "bolt.fill")
            actionsGrid
        }
        .sheet(isPresented: $showNewCheckIn) {
            CheckInFormView(athlete: athlete)
        }
        .sheet(isPresented: $showBodyMetrics) {
            if let ci = latestCheckIn { BodyMetricsFormView(checkIn: ci) }
        }
        .sheet(isPresented: $showCircumferences) {
            if let ci = latestCheckIn { CircumferenceMeasurementsFormView(checkIn: ci) }
        }
        .sheet(isPresented: $showSkinfolds) {
            if let ci = latestCheckIn { SkinfoldMeasurementsFormView(checkIn: ci) }
        }
        .sheet(isPresented: $showComparePicker) {
            CheckInComparisonPickerView(athlete: athlete)
        }
    }

    // MARK: - Grid

    private var actionsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: AppSpacing.sm
        ) {
            actionButton(
                label: "Nuevo Check In",
                icon: "plus.circle.fill",
                color: AppColors.accent,
                disabled: false
            ) {
                showNewCheckIn = true
            }

            actionButton(
                label: "Comparar",
                icon: "chart.bar.doc.horizontal",
                color: AppColors.info,
                disabled: athlete.checkIns.count < 2
            ) {
                showComparePicker = true
            }

            actionButton(
                label: "Métricas",
                icon: "scalemass.fill",
                color: AppColors.warning,
                disabled: !hasCheckIn
            ) {
                showBodyMetrics = true
            }

            actionButton(
                label: "Circunferencias",
                icon: "arrow.left.and.right.circle.fill",
                color: .purple,
                disabled: !hasCheckIn
            ) {
                showCircumferences = true
            }

            actionButton(
                label: "Plicometría",
                icon: "ruler.fill",
                color: .teal,
                disabled: !hasCheckIn
            ) {
                showSkinfolds = true
            }

            if let ci = latestCheckIn {
                NavigationLink {
                    ProgressPhotoGridView(checkIn: ci)
                } label: {
                    actionLabel(label: "Fotografías", icon: "camera.fill", color: .pink, disabled: false)
                }
                .buttonStyle(.plain)
            } else {
                actionLabel(label: "Fotografías", icon: "camera.fill", color: .pink, disabled: true)
            }
        }
    }

    // MARK: - Action button

    private func actionButton(
        label: String,
        icon: String,
        color: Color,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            actionLabel(label: label, icon: icon, color: color, disabled: disabled)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func actionLabel(label: String, icon: String, color: Color, disabled: Bool) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(disabled ? AppColors.tertiaryText : color)
                .frame(width: 22)
            Text(label)
                .font(AppTypography.footnote.weight(.medium))
                .foregroundStyle(disabled ? AppColors.tertiaryText : AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
    }
}
