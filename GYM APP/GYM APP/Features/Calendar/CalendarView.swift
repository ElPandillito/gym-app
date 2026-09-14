//
//  CalendarView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \CheckIn.date) private var allCheckIns: [CheckIn]
    @State private var displayedMonth: Date = Date()
    @State private var selectedDay: Date?

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            weekdayHeader
            Divider()
            monthGrid
            Divider()
            dayDetailPanel
        }
        .navigationTitle("Calendario")
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(monthTitle)
                .font(.title3.weight(.semibold))
            Spacer()
            Button { shiftMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
    }

    private var orderedWeekdaySymbols: [String] {
        let cal    = Calendar.current
        let syms   = cal.veryShortStandaloneWeekdaySymbols
        let first  = cal.firstWeekday - 1  // convert 1-indexed to 0-indexed
        return Array(syms[first...] + syms[..<first])
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        let days      = daysInGrid
        let ciByDay   = checkInsByDay

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
            spacing: 4
        ) {
            ForEach(days.indices, id: \.self) { idx in
                if let date = days[idx] {
                    let key        = dayKey(date)
                    let count      = ciByDay[key]?.count ?? 0
                    let isSel      = selectedDay.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                    CalendarDayCell(
                        date:       date,
                        checkInCount: count,
                        isSelected: isSel,
                        isToday:    Calendar.current.isDateInToday(date)
                    ) {
                        selectedDay = isSel ? nil : date
                    }
                } else {
                    Color.clear.frame(height: 48)
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Day Detail Panel

    @ViewBuilder
    private var dayDetailPanel: some View {
        if let day = selectedDay {
            let checkIns = checkInsByDay[dayKey(day)] ?? []
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(day.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                        .font(.headline)
                        .padding(.horizontal, AppSpacing.base)
                        .padding(.top, AppSpacing.md)

                    if checkIns.isEmpty {
                        Text("Sin check-ins este día.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, AppSpacing.base)
                    } else {
                        ForEach(checkIns) { checkIn in
                            if let athlete = checkIn.athlete {
                                NavigationLink(destination: AthleteDetailView(athlete: athlete)) {
                                    CalendarCheckInRow(checkIn: checkIn)
                                }
                                .buttonStyle(.plain)
                            } else {
                                CalendarCheckInRow(checkIn: checkIn)
                            }
                        }
                    }
                }
                .padding(.bottom, AppSpacing.xxxl)
            }
        } else {
            ContentUnavailableView {
                Label("Selecciona un día", systemImage: "calendar.badge.clock")
            } description: {
                Text("Toca cualquier día para ver los check-ins registrados.")
            }
        }
    }

    // MARK: - Helpers

    private var daysInGrid: [Date?] {
        let cal = Calendar.current
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)),
              let range      = cal.range(of: .day, in: .month, for: monthStart) else {
            return []
        }
        let firstWeekday    = cal.component(.weekday, from: monthStart)
        let leadingEmpties  = (firstWeekday - cal.firstWeekday + 7) % 7
        var days: [Date?]   = Array(repeating: nil, count: leadingEmpties)
        for offset in 0..<range.count {
            days.append(cal.date(byAdding: .day, value: offset, to: monthStart))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private var checkInsByDay: [String: [CheckIn]] {
        var map: [String: [CheckIn]] = [:]
        for ci in allCheckIns {
            map[dayKey(ci.date), default: []].append(ci)
        }
        return map
    }

    private func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    private func shiftMonth(by months: Int) {
        displayedMonth = Calendar.current.date(
            byAdding: .month, value: months, to: displayedMonth
        ) ?? displayedMonth
        // Clear selection when navigating away from its month
        if let sel = selectedDay,
           !Calendar.current.isDate(sel, equalTo: displayedMonth, toGranularity: .month) {
            selectedDay = nil
        }
    }
}

// MARK: - CalendarDayCell

private struct CalendarDayCell: View {
    let date:         Date
    let checkInCount: Int
    let isSelected:   Bool
    let isToday:      Bool
    let onTap:        () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle().fill(Color.accentColor).frame(width: 34, height: 34)
                    } else if isToday {
                        Circle().strokeBorder(Color.accentColor, lineWidth: 1.5).frame(width: 34, height: 34)
                    }
                    Text(dayText)
                        .font(.callout.weight(isToday || isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected ? .white :
                            isToday    ? Color.accentColor :
                            Color.primary
                        )
                }
                .frame(width: 34, height: 34)

                // Dot row — up to 3 dots for multiple check-ins
                HStack(spacing: 2) {
                    ForEach(0..<min(checkInCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.8) : Color.accentColor)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }

    private var dayText: String {
        "\(Calendar.current.component(.day, from: date))"
    }
}

// MARK: - CalendarCheckInRow

private struct CalendarCheckInRow: View {
    let checkIn: CheckIn

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(checkIn.athlete?.name ?? "Atleta")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: AppSpacing.sm) {
                    if let weight = checkIn.bodyMetrics?.bodyWeight {
                        Label(String(format: "%.1f kg", weight), systemImage: "scalemass.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if checkIn.photos.count > 0 {
                        Label("\(checkIn.photos.count)", systemImage: "camera.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .padding(.horizontal, AppSpacing.base)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CalendarView()
    }
    .modelContainer(for: [CheckIn.self, Athlete.self], inMemory: true)
}
