//
//  AthleteReportPDFRendererTests.swift
//  GYM APPTests
//
//  Unit tests for AthleteReportPDFRenderer.
//  On iOS: verifies that render() returns valid PDF bytes.
//  On macOS: verifies that render() returns nil (text fallback expected).
//

import Testing
import SwiftData
import Foundation
@testable import GYM_APP

// MARK: - Fixtures (local copies — helpers are private in other test files)

@MainActor
private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
        for: Schema(GYMAppSchemaV1.models),
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}

@MainActor
private func makeAthleteWithCheckIns(in context: ModelContext, count: Int) throws -> Athlete {
    let athlete = Athlete(name: "PDF Test Athlete", gender: .female,
                          birthDate: Calendar.current.date(byAdding: .year, value: -28, to: Date()),
                          height: 165)
    context.insert(athlete)

    var date = Calendar.current.date(byAdding: .day, value: -count * 7, to: Date())!
    for i in 0..<count {
        let checkIn = CheckIn(date: date)
        let metrics = BodyMetrics()
        metrics.bodyWeight        = 65.0 - Double(i) * 0.2
        metrics.bodyFatPercentage = 22.0 - Double(i) * 0.1
        metrics.muscleMass        = 48.0 + Double(i) * 0.05
        checkIn.bodyMetrics = metrics
        athlete.checkIns.append(checkIn)
        context.insert(checkIn)
        context.insert(metrics)
        date = Calendar.current.date(byAdding: .day, value: 7, to: date)!
    }
    try context.save()
    return athlete
}

@MainActor
private func makeReport(checkInCount: Int = 6,
                        preferences: CoachPreferences = .default) throws -> AthleteReport {
    let container = try makeContainer()
    let athlete   = try makeAthleteWithCheckIns(in: container.mainContext, count: checkInCount)
    let snapshots = athlete.checkIns.sorted { $0.date < $1.date }.map(CheckInSnapshot.init)
    let stats     = StatisticsEngine.compute(athleteID: athlete.id, snapshots: snapshots)
    return AthleteReportBuilder()
        .setAthlete(AthleteSnapshot(from: athlete))
        .setStatistics(stats)
        .build()
}

// MARK: - Tests

@Suite("AthleteReportPDFRenderer")
struct AthleteReportPDFRendererTests {

    @Test("render returns non-nil data on iOS, nil on macOS")
    @MainActor
    func render_platformBehavior() throws {
        let report = try makeReport()
        let data   = AthleteReportPDFRenderer.render(report)
#if os(iOS)
        #expect(data != nil)
#else
        #expect(data == nil, "macOS must return nil so the caller uses text fallback")
#endif
    }

    @Test("render output starts with the PDF magic bytes")
    @MainActor
    func render_hasPDFHeader() throws {
#if os(iOS)
        let report = try makeReport()
        let data   = try #require(AthleteReportPDFRenderer.render(report))
        let header = String(bytes: data.prefix(4), encoding: .ascii)
        #expect(header == "%PDF", "Expected PDF magic bytes at offset 0, got \(header ?? "nil")")
#endif
    }

    @Test("render produces non-trivial output (> 1 KB)")
    @MainActor
    func render_hasMinimumSize() throws {
#if os(iOS)
        let report = try makeReport()
        let data   = try #require(AthleteReportPDFRenderer.render(report))
        #expect(data.count > 1_024,
                "PDF should have meaningful content; got \(data.count) bytes")
#endif
    }

    @Test("render succeeds with minimum valid data (2 check-ins)")
    @MainActor
    func render_withMinimalData() throws {
#if os(iOS)
        let report = try makeReport(checkInCount: 2)
        let data   = AthleteReportPDFRenderer.render(report)
        #expect(data != nil)
#endif
    }
}
