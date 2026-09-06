//
//  DashboardFilterTests.swift
//  GYM APPTests
//

import Testing
import SwiftData
import Foundation
@testable import GYM_APP

@Suite("DashboardFilterTests")
@MainActor
struct DashboardFilterTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(GYMAppSchemaV1.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private var prefs: CoachPreferences { CoachPreferences.default }

    // MARK: - .all

    @Test(".all returns every athlete regardless of phase")
    func allReturnsEveryone() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let a1 = Athlete(name: "A1", gender: .male)
        let a2 = Athlete(name: "A2", gender: .female)
        ctx.insert(a1); ctx.insert(a2)
        try ctx.save()

        let result = DashboardFilter.all.apply(to: [a1, a2], checkIns: [], preferences: prefs)
        #expect(result.count == 2)
    }

    @Test(".all on empty list returns empty list")
    func allEmptyList() throws {
        let result = DashboardFilter.all.apply(to: [], checkIns: [], preferences: prefs)
        #expect(result.isEmpty)
    }

    // MARK: - Phase filters

    @Test(".competition returns only contestPrep and peakWeek athletes")
    func competitionFilter() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let prep = Athlete(name: "Prep", gender: .male)
        let peak = Athlete(name: "Peak", gender: .female)
        let off  = Athlete(name: "Off",  gender: .male)
        prep.phase = .contestPrep
        peak.phase = .peakWeek
        off.phase  = .offSeason
        ctx.insert(prep); ctx.insert(peak); ctx.insert(off)
        try ctx.save()

        let result = DashboardFilter.competition.apply(to: [prep, peak, off], checkIns: [], preferences: prefs)
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.phase.isCompetitionPhase })
    }

    @Test(".competition excludes maintenance athletes")
    func competitionExcludesMaintenance() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let m = Athlete(name: "Maint", gender: .male)
        m.phase = .maintenance
        ctx.insert(m)
        try ctx.save()

        let result = DashboardFilter.competition.apply(to: [m], checkIns: [], preferences: prefs)
        #expect(result.isEmpty)
    }

    @Test(".bulk returns only offSeason and leanBulk athletes")
    func bulkFilter() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let off  = Athlete(name: "Off",  gender: .male)
        let lean = Athlete(name: "Lean", gender: .male)
        let cut  = Athlete(name: "Cut",  gender: .female)
        off.phase  = .offSeason
        lean.phase = .leanBulk
        cut.phase  = .miniCut
        ctx.insert(off); ctx.insert(lean); ctx.insert(cut)
        try ctx.save()

        let result = DashboardFilter.bulk.apply(to: [off, lean, cut], checkIns: [], preferences: prefs)
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.phase.isBulkPhase })
    }

    @Test(".cut returns only miniCut and reverseDiet athletes")
    func cutFilter() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let mini = Athlete(name: "Mini", gender: .male)
        let rev  = Athlete(name: "Rev",  gender: .female)
        let bulk = Athlete(name: "Bulk", gender: .male)
        mini.phase = .miniCut
        rev.phase  = .reverseDiet
        bulk.phase = .offSeason
        ctx.insert(mini); ctx.insert(rev); ctx.insert(bulk)
        try ctx.save()

        let result = DashboardFilter.cut.apply(to: [mini, rev, bulk], checkIns: [], preferences: prefs)
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.phase.isCutPhase })
    }

    // MARK: - Active / Inactive

    @Test(".active includes athlete with check-in within threshold")
    func activeIncludesRecentCheckIn() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let athlete = Athlete(name: "Recent", gender: .male)
        ctx.insert(athlete)
        let date = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let ci = CheckIn(date: date)
        ctx.insert(ci)
        ci.athlete = athlete
        try ctx.save()

        let result = DashboardFilter.active.apply(to: [athlete], checkIns: [ci], preferences: prefs)
        #expect(result.count == 1)
    }

    @Test(".active excludes athlete with no check-ins")
    func activeExcludesNoCheckIns() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let athlete = Athlete(name: "NoCI", gender: .male)
        ctx.insert(athlete)
        try ctx.save()

        let result = DashboardFilter.active.apply(to: [athlete], checkIns: [], preferences: prefs)
        #expect(result.isEmpty)
    }

    @Test(".inactive includes athlete with stale check-in")
    func inactiveIncludesStaleCheckIn() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let athlete = Athlete(name: "Stale", gender: .male)
        ctx.insert(athlete)
        let staleDate = Calendar.current.date(byAdding: .day, value: -(prefs.inactivityThresholdDays + 5), to: Date())!
        let ci = CheckIn(date: staleDate)
        ctx.insert(ci)
        ci.athlete = athlete
        try ctx.save()

        let result = DashboardFilter.inactive.apply(to: [athlete], checkIns: [ci], preferences: prefs)
        #expect(result.count == 1)
    }

    @Test(".inactive excludes athlete with recent check-in")
    func inactiveExcludesRecentCheckIn() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let athlete = Athlete(name: "Active", gender: .male)
        ctx.insert(athlete)
        let ci = CheckIn(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!)
        ctx.insert(ci)
        ci.athlete = athlete
        try ctx.save()

        let result = DashboardFilter.inactive.apply(to: [athlete], checkIns: [ci], preferences: prefs)
        #expect(result.isEmpty)
    }

    // MARK: - Custom

    @Test(".custom is a passthrough returning all athletes")
    func customPassthrough() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let a1 = Athlete(name: "A1", gender: .male)
        let a2 = Athlete(name: "A2", gender: .female)
        ctx.insert(a1); ctx.insert(a2)
        try ctx.save()

        let result = DashboardFilter.custom.apply(to: [a1, a2], checkIns: [], preferences: prefs)
        #expect(result.count == 2)
    }
}
