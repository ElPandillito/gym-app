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
    @State private var overviewViewModel = AthleteOverviewViewModel()

    enum AthleteSection: String, CaseIterable {
        case overview   = "Resumen"
        case info       = "Info"
        case timeline   = "Timeline"
        case checkIns   = "Check Ins"
        case nutrition  = "Nutrición"
        case routines   = "Rutinas"
        case files      = "Archivos"
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
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingComparisonPicker) {
            CheckInComparisonPickerView(athlete: athlete)
        }
        .onAppear {
            overviewViewModel.build(from: athlete)
        }
        .onChange(of: athlete.checkIns.count) { _, _ in
            overviewViewModel.build(from: athlete)
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

            VStack(alignment: .leading, spacing: 3) {
                Text(athlete.name)
                    .font(.title3.bold())
                Text(athlete.gender.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
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
            PlaceholderSectionView(
                title: "Nutrición",
                icon: "fork.knife",
                description: "El plan nutricional del atleta aparecerá aquí."
            )
        case .routines:
            PlaceholderSectionView(
                title: "Rutinas",
                icon: "dumbbell.fill",
                description: "Las rutinas de entrenamiento aparecerán aquí."
            )
        case .files:
            PlaceholderSectionView(
                title: "Archivos",
                icon: "folder.fill",
                description: "Los archivos del atleta aparecerán aquí."
            )
        }
    }
}

// MARK: - Overview Section

private struct AthleteOverviewSectionView: View {
    let viewModel: AthleteOverviewViewModel
    let athlete: Athlete

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

                if !viewModel.alerts.isEmpty {
                    AthleteAlertsView(alerts: viewModel.alerts)
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

// MARK: - Info Section

private struct AthleteInfoSectionView: View {
    let athlete: Athlete

    var body: some View {
        List {
            Section("Información Personal") {
                InfoRow(label: "Nombre completo", value: athlete.name)
                InfoRow(label: "Género", value: athlete.gender.displayName)
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
        return String(format: "%.1f cm", h)
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
    .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
