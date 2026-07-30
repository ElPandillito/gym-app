//
//  AthleteTimelineViewModel.swift
//  GYM APP
//

import Foundation

@Observable
@MainActor
final class AthleteTimelineViewModel {

    // MARK: - State

    private(set) var sections: [(date: Date, items: [TimelineItem])] = []
    var selectedNavigationTarget: NavigationTarget?

    // MARK: - Derived

    var isEmpty: Bool { sections.isEmpty }
    var totalItemCount: Int { sections.reduce(0) { $0 + $1.items.count } }

    // MARK: - Build

    func build(from checkIns: [CheckIn]) {
        let all = TimelineBuilder.build(from: checkIns)
        sections = groupByDay(all)
    }

    // MARK: - Navigation

    func select(_ item: TimelineItem) {
        selectedNavigationTarget = item.navigationTarget
    }

    // MARK: - Private

    private func groupByDay(_ items: [TimelineItem]) -> [(date: Date, items: [TimelineItem])] {
        let calendar = Calendar.current
        var groups: [(date: Date, items: [TimelineItem])] = []
        var currentDay: Date?
        var currentItems: [TimelineItem] = []

        for item in items {
            let day = calendar.startOfDay(for: item.date)
            if day == currentDay {
                currentItems.append(item)
            } else {
                if let d = currentDay, !currentItems.isEmpty {
                    groups.append((date: d, items: currentItems))
                }
                currentDay = day
                currentItems = [item]
            }
        }

        if let d = currentDay, !currentItems.isEmpty {
            groups.append((date: d, items: currentItems))
        }

        return groups
    }
}
