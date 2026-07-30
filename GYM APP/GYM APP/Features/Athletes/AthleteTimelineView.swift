//
//  AthleteTimelineView.swift
//  GYM APP
//

import SwiftUI

struct AthleteTimelineView: View {
    let athlete: Athlete

    @State private var viewModel = AthleteTimelineViewModel()

    @State private var bodyMetricsCheckIn:     CheckIn?
    @State private var circumferencesCheckIn:  CheckIn?
    @State private var skinfoldsCheckIn:       CheckIn?

    var body: some View {
        Group {
            if viewModel.isEmpty {
                emptyState
            } else {
                timeline
            }
        }
        .navigationTitle("Timeline")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            viewModel.build(from: athlete.checkIns)
        }
        .onChange(of: athlete.checkIns.count) { _, _ in
            viewModel.build(from: athlete.checkIns)
        }
        .sheet(item: $bodyMetricsCheckIn)    { BodyMetricsFormView(checkIn: $0) }
        .sheet(item: $circumferencesCheckIn) { CircumferenceMeasurementsFormView(checkIn: $0) }
        .sheet(item: $skinfoldsCheckIn)      { SkinfoldMeasurementsFormView(checkIn: $0) }
    }

    // MARK: - Timeline

    private var timeline: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(viewModel.sections, id: \.date) { section in
                    Section {
                        VStack(spacing: AppSpacing.xxs) {
                            ForEach(section.items) { item in
                                makeCell(for: item)
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, AppSpacing.sm)
                    } header: {
                        dayHeader(for: section.date)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.bottom, AppSpacing.xxxl)
        }
    }

    // MARK: - Cell routing

    @ViewBuilder
    private func makeCell(for item: TimelineItem) -> some View {
        if let nav = item.navigationTarget {
            switch nav {
            case .checkIn(let id):
                if let ci = resolve(id) {
                    NavigationLink {
                        CheckInDetailView(checkIn: ci)
                    } label: {
                        TimelineEventCell(item: item)
                    }
                } else {
                    TimelineEventCell(item: item)
                }

            case .photos(let id):
                if let ci = resolve(id) {
                    NavigationLink {
                        ProgressPhotoGridView(checkIn: ci)
                    } label: {
                        TimelineEventCell(item: item)
                    }
                } else {
                    TimelineEventCell(item: item)
                }

            case .bodyMetrics(let id):
                Button { bodyMetricsCheckIn = resolve(id) } label: {
                    TimelineEventCell(item: item)
                }

            case .circumferences(let id):
                Button { circumferencesCheckIn = resolve(id) } label: {
                    TimelineEventCell(item: item)
                }

            case .skinfolds(let id):
                Button { skinfoldsCheckIn = resolve(id) } label: {
                    TimelineEventCell(item: item)
                }

            case .coachNote(let id):
                if let ci = resolve(id) {
                    NavigationLink {
                        CheckInDetailView(checkIn: ci)
                    } label: {
                        TimelineEventCell(item: item)
                    }
                } else {
                    TimelineEventCell(item: item)
                }

            case .athleteNote(let id):
                if let ci = resolve(id) {
                    NavigationLink {
                        CheckInDetailView(checkIn: ci)
                    } label: {
                        TimelineEventCell(item: item)
                    }
                } else {
                    TimelineEventCell(item: item)
                }
            }
        } else {
            TimelineEventCell(item: item)
        }
    }

    // MARK: - Day header

    private func dayHeader(for date: Date) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(date.formatted(.dateTime.weekday(.wide)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(date.formatted(.dateTime.day().month(.wide).year()))
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }
            Spacer()
            Text("\(viewModel.sections.first(where: { $0.date == date })?.items.count ?? 0) eventos")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, AppSpacing.xs)
        .padding(.top, AppSpacing.md)
        .background(.background)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Sin actividad registrada")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Los check-ins y mediciones de \(athlete.name) aparecerán aquí.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func resolve(_ id: UUID) -> CheckIn? {
        athlete.checkIns.first { $0.id == id }
    }
}

// MARK: - Event Cell

private struct TimelineEventCell: View {
    let item: TimelineItem

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            iconView
            contentView
            Spacer(minLength: 0)
            timeLabel
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var iconView: some View {
        Image(systemName: item.type.timelineIcon)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(item.type.timelineColor)
            .frame(width: 38, height: 38)
            .background(item.type.timelineColor.opacity(0.13))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var timeLabel: some View {
        Text(item.date, format: .dateTime.hour().minute())
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
}

// MARK: - TimelineItemType + presentation

private extension TimelineItemType {
    var timelineColor: Color {
        switch self {
        case .checkIn:       return .accentColor
        case .bodyMetrics:   return .orange
        case .circumference: return .purple
        case .skinfolds:     return .teal
        case .photoSession:  return .pink
        case .coachNote:     return .indigo
        case .athleteNote:   return .mint
        default:             return .secondary
        }
    }

    var timelineIcon: String {
        switch self {
        case .checkIn:       return "checkmark.circle.fill"
        case .bodyMetrics:   return "scalemass.fill"
        case .circumference: return "arrow.left.and.right.circle.fill"
        case .skinfolds:     return "ruler.fill"
        case .photoSession:  return "camera.fill"
        case .coachNote:     return "note.text"
        case .athleteNote:   return "person.text.rectangle.fill"
        default:             return "circle.fill"
        }
    }
}
