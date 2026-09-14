//
//  AthleteDetailView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct AthleteDetailView: View {
    let athlete: Athlete
    @State private var selectedSection: AthleteSection = .overview
    @State private var isShowingComparisonPicker = false
    @State private var isShowingReport = false
    @State private var overviewViewModel = AthleteOverviewViewModel()
    @Environment(CoachPreferencesStore.self) private var prefsStore

    enum AthleteSection: String, CaseIterable {
        case overview   = "Resumen"
        case info       = "Info"
        case timeline   = "Timeline"
        case checkIns   = "Check Ins"
        case nutrition  = "Nutrición"
    }

    var body: some View {
        VStack(spacing: 0) {
            profileHeader
            sectionTabBar
            Divider()
            sectionContent
        }
        .navigationTitle(athlete.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isShowingComparisonPicker = true
                    } label: {
                        Label("Comparar Check-Ins", systemImage: "chart.bar.doc.horizontal")
                    }
                    .disabled(athlete.checkIns.count < 2)
                    Divider()
                    Button {
                        isShowingReport = true
                    } label: {
                        Label("Generar Reporte", systemImage: "doc.text.fill")
                    }
                    .disabled(overviewViewModel.statisticsReport == nil)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingComparisonPicker) {
            CheckInComparisonPickerView(athlete: athlete)
        }
        .sheet(isPresented: $isShowingReport) {
            AthleteReportSheet(
                athlete: athlete,
                statisticsReport: overviewViewModel.statisticsReport
            )
        }
        .onAppear {
            overviewViewModel.build(from: athlete, preferences: prefsStore.preferences)
        }
        .onChange(of: athlete.checkIns.count) { _, _ in
            overviewViewModel.build(from: athlete, preferences: prefsStore.preferences)
        }
        .onChange(of: latestCheckInUpdatedAt) { _, _ in
            overviewViewModel.build(from: athlete, preferences: prefsStore.preferences)
        }
        .onChange(of: prefsStore.preferences) { _, _ in
            overviewViewModel.build(from: athlete, preferences: prefsStore.preferences)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 60, height: 60)
                .overlay {
                    Text(initials)
                        .font(.title3.bold())
                        .foregroundStyle(Color.accentColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(athlete.name)
                    .font(.title3.bold())

                HStack(spacing: 6) {
                    Text(athlete.gender.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(athlete.phase.displayName, systemImage: athlete.phase.systemImage)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
    }

    // Triggers overview rebuild when any existing check-in's data changes.
    private var latestCheckInUpdatedAt: Date? {
        athlete.checkIns.max(by: { $0.updatedAt < $1.updatedAt })?.updatedAt
    }

    private var initials: String {
        athlete.name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }

    // MARK: - Section Tab Bar

    private var sectionTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(AthleteSection.allCases, id: \.self) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSection = section
                        }
                    } label: {
                        VStack(spacing: 0) {
                            Text(section.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedSection == section ? .semibold : .regular)
                                .foregroundStyle(selectedSection == section ? Color.accentColor : .secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)

                            Rectangle()
                                .fill(selectedSection == section ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .overview:
            AthleteOverviewSectionView(viewModel: overviewViewModel, athlete: athlete)
        case .info:
            AthleteInfoSectionView(athlete: athlete)
        case .timeline:
            AthleteTimelineView(athlete: athlete)
        case .checkIns:
            CheckInListView(athlete: athlete)
        case .nutrition:
            AthleteNutritionView(athlete: athlete)
        }
    }
}

// MARK: - Overview Section

private struct AthleteOverviewSectionView: View {
    let viewModel: AthleteOverviewViewModel
    let athlete: Athlete
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xl) {
                if let header = viewModel.header {
                    AthleteHeaderView(header: header, activity: viewModel.activityInfo)
                }

                if let metrics = viewModel.currentMetrics {
                    AthleteCurrentMetricsView(metrics: metrics)
                }

                AthleteProgressSummaryView(summary: viewModel.progressSummary)

                if let report = viewModel.statisticsReport {
                    AthleteTrendsSectionView(report: report)
                }

                if !viewModel.alerts.isEmpty {
                    AthleteAlertsView(alerts: viewModel.alerts)
                }

                AthleteNotesCardView(latestCheckIn: viewModel.latestCheckIn)

                if let activePlan = athlete.nutritionPlans.first(where: { $0.isActive }) {
                    AthleteActivePlanCard(plan: activePlan, athlete: athlete)
                }

                AthleteQuickActionsView(
                    athlete: athlete,
                    latestCheckIn: viewModel.latestCheckIn
                )
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.vertical, AppSpacing.base)
            .padding(.bottom, AppSpacing.xxxl)
        }
    }
}

// MARK: - Active Nutrition Plan Card

private struct AthleteActivePlanCard: View {
    let plan: NutritionPlan
    let athlete: Athlete
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Plan Nutricional Activo", icon: "fork.knife.circle.fill")

            NavigationLink {
                NutritionPlanDetailView(plan: plan, athlete: athlete, context: modelContext)
            } label: {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text(plan.name)
                        .font(AppTypography.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.primaryText)

                    if plan.hasTargets {
                        macroGrid
                    }

                    HStack {
                        Spacer()
                        Label("Ver plan completo", systemImage: "chevron.right")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.accent)
                    }
                }
                .padding(AppSpacing.base)
                .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
            }
            .buttonStyle(.plain)
        }
    }

    private var macroColumns: [(value: String, label: String)] {
        let t = plan.targetMacros
        var cols: [(value: String, label: String)] = []
        if t.calories      > 0 { cols.append((String(format: "%.0f",  t.calories),      "kcal"))  }
        if t.protein       > 0 { cols.append((String(format: "%.0fg", t.protein),       "Prot"))  }
        if t.carbohydrates > 0 { cols.append((String(format: "%.0fg", t.carbohydrates), "Carbs")) }
        if t.fat           > 0 { cols.append((String(format: "%.0fg", t.fat),           "Grasa")) }
        return cols
    }

    @ViewBuilder
    private var macroGrid: some View {
        let cols = macroColumns
        if !cols.isEmpty {
            HStack(spacing: 0) {
                ForEach(cols.indices, id: \.self) { idx in
                    if idx > 0 { Divider().frame(height: 28) }
                    VStack(spacing: 2) {
                        Text(cols[idx].value)
                            .font(AppTypography.footnote.weight(.semibold).monospacedDigit())
                            .foregroundStyle(AppColors.primaryText)
                        Text(cols[idx].label)
                            .font(AppTypography.caption2)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Info Section

private struct AthleteInfoSectionView: View {
    let athlete: Athlete
    @Environment(CoachPreferencesStore.self) private var prefsStore

    var body: some View {
        List {
            Section("Información Personal") {
                InfoRow(label: "Nombre completo", value: athlete.name)
                InfoRow(label: "Género", value: athlete.gender.displayName)
                InfoRow(label: "Fase", value: athlete.phase.displayName)
                InfoRow(label: "Fecha de nacimiento", value: birthDateText)
                InfoRow(label: "Estatura", value: heightText)
            }

            Section("Estadísticas") {
                InfoRow(label: "Total de Check Ins", value: "\(athlete.checkIns.count)")
                InfoRow(label: "Último Check In", value: lastCheckInText)
                InfoRow(label: "Miembro desde", value: athlete.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }

    private var birthDateText: String {
        guard let date = athlete.birthDate else { return "—" }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private var heightText: String {
        guard let h = athlete.height else { return "—" }
        return AppUnitFormatter(preferences: prefsStore.preferences).height(h)
    }

    private var lastCheckInText: String {
        guard let last = athlete.checkIns.max(by: { $0.date < $1.date }) else { return "—" }
        let date: Date = last.date
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("iPhone 16") {
    let athlete = Athlete(name: "Carlos Ramírez", gender: .male, birthDate: Date(), height: 178)
    NavigationStack {
        AthleteDetailView(athlete: athlete)
    }
    .modelContainer(for: Athlete.self, inMemory: true)
    .environment(CoachPreferencesStore())
    .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
