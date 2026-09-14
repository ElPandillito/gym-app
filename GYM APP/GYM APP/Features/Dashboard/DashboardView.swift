//
//  DashboardView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Athlete.name)       private var athletes:   [Athlete]
    @Query(sort: \CheckIn.date, order: .reverse) private var checkIns: [CheckIn]

    @State   private var viewModel  = DashboardViewModel()
    @Environment(CoachPreferencesStore.self) private var prefsStore

    private var fmt: AppUnitFormatter { AppUnitFormatter(preferences: prefsStore.preferences) }

    private let filterCases: [DashboardFilter] = [.all, .active, .inactive, .competition, .bulk, .cut]

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.xl) {
                    summarySection
                    recentActivitySection
                    alertsSection
                    progressorsSection
                    pendingActionsSection
                }
                .padding(.horizontal, AppSpacing.base)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("Dashboard")
        .onAppear     { reload() }
        .onChange(of: athletes)               { reload() }
        .onChange(of: checkIns)               { reload() }
        .onChange(of: viewModel.activeFilter) { reload() }
        .onChange(of: prefsStore.preferences) { reload() }
    }

    private func reload() {
        viewModel.load(athletes: athletes, checkIns: checkIns, preferences: prefsStore.preferences)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(filterCases) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: viewModel.activeFilter == filter
                    ) {
                        viewModel.activeFilter = filter
                    }
                }
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    // MARK: - Athlete lookup

    private func findAthlete(_ id: UUID) -> Athlete? {
        athletes.first { $0.id == id }
    }

    // MARK: - 1. Resumen General

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("Resumen General", icon: "chart.bar.fill")

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: AppSpacing.sm
            ) {
                MetricCard(
                    title: "Atletas",
                    value: "\(viewModel.kpis.totalAthletes)",
                    icon: "person.2.fill",
                    tintColor: AppColors.info
                )
                MetricCard(
                    title: "Check Ins Totales",
                    value: "\(viewModel.kpis.totalCheckIns)",
                    icon: "checkmark.seal.fill",
                    tintColor: AppColors.success
                )
                MetricCard(
                    title: "Este Mes",
                    value: "\(viewModel.kpis.checkInsThisMonth)",
                    icon: "calendar",
                    tintColor: AppColors.accent
                )
                MetricCard(
                    title: "Esta Semana",
                    value: "\(viewModel.checkInsThisWeek)",
                    icon: "calendar.badge.checkmark",
                    tintColor: .purple
                )
                MetricCard(
                    title: "Peso Prom.",
                    value: viewModel.kpis.averageWeight.map { String(format: "%.1f", fmt.convertedWeight($0)) } ?? "—",
                    unit: viewModel.kpis.averageWeight != nil ? fmt.weightLabel : nil,
                    icon: "scalemass.fill",
                    tintColor: AppColors.warning
                )
                MetricCard(
                    title: "IGC Prom.",
                    value: viewModel.kpis.averageBodyFat.map { String(format: "%.1f", $0) } ?? "—",
                    unit: viewModel.kpis.averageBodyFat != nil ? "%" : nil,
                    icon: "flame.fill",
                    tintColor: AppColors.error
                )
            }
        }
    }

    // MARK: - 2. Actividad Reciente

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Actividad Reciente", icon: "clock.fill")

            if viewModel.recentCheckIns.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "Sin actividad",
                    message: "Los check ins de tus atletas aparecerán aquí."
                )
            } else {
                cardContainer {
                    ForEach(viewModel.recentCheckIns) { item in
                        if let athlete = findAthlete(item.athleteID) {
                            NavigationLink(destination: AthleteDetailView(athlete: athlete)) {
                                RecentCheckInRow(item: item)
                            }
                            .buttonStyle(.plain)
                        } else {
                            RecentCheckInRow(item: item)
                        }
                        if item.id != viewModel.recentCheckIns.last?.id {
                            Divider().padding(.leading, AppSpacing.sm)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 3. Alertas

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader(
                "Alertas",
                icon: "exclamationmark.triangle.fill",
                actionTitle: viewModel.alerts.isEmpty ? nil : "\(viewModel.alerts.count)"
            )

            if viewModel.alerts.isEmpty {
                if !athletes.isEmpty {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.success)
                        Text("Todos los atletas al día")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.secondaryBg,
                                in: RoundedRectangle(cornerRadius: AppRadius.md))
                }
            } else {
                cardContainer {
                    ForEach(viewModel.alerts) { alert in
                        if let athlete = findAthlete(alert.athleteID) {
                            NavigationLink(destination: AthleteDetailView(athlete: athlete)) {
                                AlertRow(alert: alert)
                            }
                            .buttonStyle(.plain)
                        } else {
                            AlertRow(alert: alert)
                        }
                        if alert.id != viewModel.alerts.last?.id {
                            Divider().padding(.leading, AppSpacing.xl + AppSpacing.sm)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 4. Mejores Progresos

    private var progressorsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Mejores Progresos", icon: "trophy.fill")

            if viewModel.topProgressors.isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Sin datos suficientes",
                    message: "Se necesitan al menos 2 check ins por atleta en los últimos 30 días."
                )
            } else {
                cardContainer {
                    ForEach(Array(viewModel.topProgressors.enumerated()), id: \.element.id) { index, prog in
                        if let athlete = findAthlete(prog.id) {
                            NavigationLink(destination: AthleteDetailView(athlete: athlete)) {
                                ProgressorRow(progressor: prog, rank: index + 1)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ProgressorRow(progressor: prog, rank: index + 1)
                        }
                        if index < viewModel.topProgressors.count - 1 {
                            Divider().padding(.leading, AppSpacing.xl + AppSpacing.xs)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 5. Próximas Acciones

    private var pendingActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Próximas Acciones", icon: "list.bullet.clipboard.fill")

            if viewModel.pendingActions.isEmpty {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.success)
                    Text("Sin acciones pendientes")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(AppColors.secondaryBg,
                            in: RoundedRectangle(cornerRadius: AppRadius.md))
            } else {
                cardContainer {
                    ForEach(viewModel.pendingActions) { action in
                        if let athlete = findAthlete(action.athleteID) {
                            NavigationLink(destination: AthleteDetailView(athlete: athlete)) {
                                PendingActionRow(action: action)
                            }
                            .buttonStyle(.plain)
                        } else {
                            PendingActionRow(action: action)
                        }
                        if action.id != viewModel.pendingActions.last?.id {
                            Divider().padding(.leading, AppSpacing.xl + AppSpacing.sm)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared card wrapper

    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}

// MARK: - Row: Recent Check In

private struct RecentCheckInRow: View {
    let item: DashboardRecentCheckIn
    @Environment(CoachPreferencesStore.self) private var prefsStore

    private var fmt: AppUnitFormatter { AppUnitFormatter(preferences: prefsStore.preferences) }

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(item.athleteName)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                Text(item.date.formatted(.dateTime.day().month(.abbreviated).year()))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()

            HStack(spacing: AppSpacing.md) {
                if item.photoCount > 0 {
                    Label("\(item.photoCount)", systemImage: "camera")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
                if let w = item.weight {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(fmt.weight(w))
                            .font(AppTypography.footnote.weight(.medium))
                            .foregroundStyle(AppColors.primaryText)
                        if let delta = item.weightChangeDelta {
                            Text(deltaLabel(delta))
                                .font(AppTypography.caption2)
                                .foregroundStyle(deltaColor(delta))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private func deltaLabel(_ d: Double) -> String {
        return fmt.weightDelta(d)
    }

    private func deltaColor(_ d: Double) -> Color {
        guard abs(d) >= 0.1 else { return AppColors.secondaryText }
        return d < 0 ? AppColors.success : AppColors.error
    }
}

// MARK: - Row: Alert

private struct AlertRow: View {
    let alert: DashboardAlert

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: iconName)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(alert.athleteName)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                Text(alertDescription)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private var iconName: String {
        switch alert.kind {
        case .inactive:          return "clock.badge.exclamationmark"
        case .negativeTrend:     return "arrow.up.right.circle.fill"
        case .noPhotos:          return "camera.badge.ellipsis"
        case .incompleteMetrics: return "exclamationmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch alert.kind {
        case .inactive:          return AppColors.error
        case .negativeTrend:     return AppColors.warning
        case .noPhotos:          return AppColors.info
        case .incompleteMetrics: return AppColors.warning
        }
    }

    private var alertDescription: String {
        switch alert.kind {
        case .inactive(let d):   return "Sin check-in hace \(d) día\(d == 1 ? "" : "s")"
        case .negativeTrend:     return "Tendencia de grasa corporal al alza (+1 pp en 60 días)"
        case .noPhotos:          return "Sin fotografías en el último check-in"
        case .incompleteMetrics: return "Sin peso registrado en el último check-in"
        }
    }
}

// MARK: - Row: Progressor

private struct ProgressorRow: View {
    let progressor: DashboardProgressor
    let rank: Int

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(medal)
                .font(.title3)

            Text(progressor.athleteName)
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                if let fat = progressor.bodyFatChangePts {
                    Text(fatLabel(fat))
                        .font(AppTypography.footnote.weight(.semibold))
                        .foregroundStyle(fat <= 0 ? AppColors.success : AppColors.error)
                }
                if let pct = progressor.weightChangePct {
                    Text(weightLabel(pct))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private var medal: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }

    private func fatLabel(_ d: Double) -> String {
        let sign = d > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", d)) pp IGC"
    }

    private func weightLabel(_ pct: Double) -> String {
        let sign = pct > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))% peso"
    }
}

// MARK: - Row: Pending Action

private struct PendingActionRow: View {
    let action: DashboardPendingAction

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: action.icon)
                .font(.body)
                .foregroundStyle(AppColors.accent)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(action.athleteName)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                Text(action.description)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let filter: DashboardFilter
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Label(filter.rawValue, systemImage: filter.systemImage)
                .font(.caption.weight(.medium))
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.12),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("iPhone 16") {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [Athlete.self, CheckIn.self], inMemory: true)
    .environment(CoachPreferencesStore())
    .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
