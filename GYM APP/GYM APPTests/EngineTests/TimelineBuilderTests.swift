//
//  TimelineBuilderTests.swift
//  GYM APPTests
//

import Testing
import SwiftData
import Foundation
@testable import GYM_APP

@Suite("TimelineBuilderTests")
@MainActor
struct TimelineBuilderTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(GYMAppSchemaV1.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeCheckIn(date: Date, in context: ModelContext) -> CheckIn {
        let ci = CheckIn(date: date)
        context.insert(ci)
        return ci
    }

    private var refDate: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
    }

    // MARK: - Empty

    @Test("empty check-ins returns no items")
    func emptyInput() {
        let items = TimelineBuilder.build(from: [])
        #expect(items.isEmpty)
    }

    // MARK: - Root check-in item

    @Test("check-in with no data produces exactly one item of type checkIn")
    func checkInNoDataOneItem() throws {
        let container = try makeContainer()
        let ci        = makeCheckIn(date: refDate, in: container.mainContext)

        let items = TimelineBuilder.build(from: [ci])
        #expect(items.count == 1)
        #expect(items[0].type == .checkIn)
    }

    // MARK: - Body metrics

    @Test("check-in with body metrics produces checkIn + bodyMetrics items")
    func checkInWithBodyMetrics() throws {
        let container = try makeContainer()
        let context   = container.mainContext
        let ci        = makeCheckIn(date: refDate, in: context)
        let bm        = BodyMetrics()
        bm.bodyWeight  = 80.0
        bm.checkIn     = ci
        ci.bodyMetrics = bm
        context.insert(bm)

        let items = TimelineBuilder.build(from: [ci])
        let types = Set(items.map { $0.type })
        #expect(types.contains(.checkIn))
        #expect(types.contains(.bodyMetrics))
        #expect(items.count == 2)
    }

    // MARK: - Photo session

    @Test("check-in with one photo produces checkIn + photoSession items")
    func checkInWithPhoto() throws {
        let container = try makeContainer()
        let context   = container.mainContext
        let ci        = makeCheckIn(date: refDate, in: context)
        let photo     = ProgressPhoto(poseType: .frontRelaxed,
                                      originalPath: "athletes/test/photo.jpg")
        photo.checkIn = ci
        ci.photos     = [photo]
        context.insert(photo)

        let items = TimelineBuilder.build(from: [ci])
        let types = Set(items.map { $0.type })
        #expect(types.contains(.photoSession))
        #expect(items.count == 2)
    }

    // MARK: - Coach note

    @Test("check-in with non-empty coach note produces coachNote item")
    func checkInWithCoachNote() throws {
        let container = try makeContainer()
        let context   = container.mainContext
        let ci        = makeCheckIn(date: refDate, in: context)
        let note      = CoachNote(text: "Excelente semana de entreno.")
        note.checkIn  = ci
        ci.coachNote  = note
        context.insert(note)

        let items = TimelineBuilder.build(from: [ci])
        let types = Set(items.map { $0.type })
        #expect(types.contains(.coachNote))
    }

    @Test("check-in with whitespace-only coach note does NOT produce coachNote item")
    func emptyCoachNoteIgnored() throws {
        let container = try makeContainer()
        let context   = container.mainContext
        let ci        = makeCheckIn(date: refDate, in: context)
        let note      = CoachNote(text: "   ")
        note.checkIn  = ci
        ci.coachNote  = note
        context.insert(note)

        let items = TimelineBuilder.build(from: [ci])
        let types = Set(items.map { $0.type })
        #expect(!types.contains(.coachNote))
    }

    // MARK: - Athlete note

    @Test("check-in with athlete note produces athleteNote item")
    func checkInWithAthleteNote() throws {
        let container = try makeContainer()
        let context   = container.mainContext
        let ci        = makeCheckIn(date: refDate, in: context)
        let note      = AthleteNote(text: "Me sentí muy bien esta semana.")
        note.checkIn  = ci
        ci.athleteNote = note
        context.insert(note)

        let items = TimelineBuilder.build(from: [ci])
        let types = Set(items.map { $0.type })
        #expect(types.contains(.athleteNote))
    }

    // MARK: - Sort order

    @Test("items from multiple check-ins are sorted newest first")
    func itemsSortedNewestFirst() throws {
        let container = try makeContainer()
        let context   = container.mainContext
        let earlier   = makeCheckIn(date: refDate, in: context)
        let laterDate = Calendar.current.date(byAdding: .day, value: 10, to: refDate)!
        let later     = makeCheckIn(date: laterDate, in: context)

        let items = TimelineBuilder.build(from: [earlier, later])
        #expect(items.first?.date == laterDate)
        #expect(items.last?.date  == refDate)
    }

    // MARK: - Navigation target

    @Test("check-in item carries navigationTarget .checkIn with correct ID")
    func checkInItemNavigationTarget() throws {
        let container = try makeContainer()
        let ci        = makeCheckIn(date: refDate, in: container.mainContext)

        let items  = TimelineBuilder.build(from: [ci])
        let ciItem = items.first { $0.type == .checkIn }

        if let target = ciItem?.navigationTarget,
           case .checkIn(let id) = target {
            #expect(id == ci.id)
        } else {
            Issue.record("Expected .checkIn navigation target with correct ID")
        }
    }
}
