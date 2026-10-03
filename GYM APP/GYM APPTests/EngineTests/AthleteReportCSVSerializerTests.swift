//
//  AthleteReportCSVSerializerTests.swift
//  GYM APPTests
//
//  Tests for AthleteReportSerializer.csv(from:) and the escaping helper.
//

import Testing
import SwiftData
import Foundation
@testable import GYM_APP

// MARK: - Fixtures

@MainActor
private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
        for: Schema(GYMAppSchemaV1.models),
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}

@MainActor
private func makeAthleteWithCheckIns(
    in context: ModelContext,
    count: Int,
    name: String = "CSV Test Athlete",
    birthDate: Date? = Calendar.current.date(byAdding: .year, value: -25, to: Date()),
    height: Double? = 172.0
) throws -> Athlete {
    let athlete = Athlete(name: name, gender: .male, birthDate: birthDate, height: height)
    context.insert(athlete)
    var date = Calendar.current.date(byAdding: .day, value: -count * 7, to: Date())!
    for i in 0..<count {
        let checkIn = CheckIn(date: date)
        let metrics = BodyMetrics()
        metrics.bodyWeight        = 80.0 - Double(i) * 0.3
        metrics.bodyFatPercentage = 18.0 - Double(i) * 0.1
        metrics.muscleMass        = 60.0 + Double(i) * 0.05
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
private func makeReport(
    athleteName: String = "CSV Test Athlete",
    checkInCount: Int = 4,
    withBirthDate: Bool = true,
    withHeight: Bool = true
) throws -> AthleteReport {
    let container = try makeContainer()
    let birthDate: Date? = withBirthDate
        ? Calendar.current.date(byAdding: .year, value: -25, to: Date())
        : nil
    let height: Double? = withHeight ? 172.0 : nil
    let athlete = try makeAthleteWithCheckIns(
        in: container.mainContext,
        count: checkInCount,
        name: athleteName,
        birthDate: birthDate,
        height: height
    )
    let snapshots = athlete.checkIns.sorted { $0.date < $1.date }.map(CheckInSnapshot.init)
    let stats     = StatisticsEngine.compute(athleteID: athlete.id, snapshots: snapshots)
    return AthleteReportBuilder()
        .setAthlete(AthleteSnapshot(from: athlete))
        .setStatistics(stats)
        .build()
}

// MARK: - esc() unit tests (RFC 4180 escaping)

@Suite("AthleteReportSerializer.esc — CSV field escaping")
struct CSVEscapingTests {

    @Test("plain field is returned unchanged")
    func esc_plainField() {
        #expect(AthleteReportSerializer.esc("hello") == "hello")
    }

    @Test("field containing comma is wrapped in quotes")
    func esc_commaField() {
        #expect(AthleteReportSerializer.esc("Smith, Jr.") == "\"Smith, Jr.\"")
    }

    @Test("interior double quotes are doubled inside quoted field")
    func esc_doubleQuoteField() {
        let input  = #"Alex "The Coach""#   // Alex "The Coach"
        let result = AthleteReportSerializer.esc(input)
        // RFC 4180: wrap in "...", double each interior " → "Alex ""The Coach"""
        #expect(result == #""Alex ""The Coach""""#)
    }

    @Test("field containing LF is wrapped in quotes")
    func esc_newlineField() {
        let result = AthleteReportSerializer.esc("line1\nline2")
        #expect(result == "\"line1\nline2\"")
    }

    @Test("field containing CR is wrapped in quotes")
    func esc_carriageReturnField() {
        let result = AthleteReportSerializer.esc("line1\rline2")
        #expect(result == "\"line1\rline2\"")
    }
}

// MARK: - csv(from:) integration tests

@Suite("AthleteReportSerializer.csv — full CSV output")
struct CSVOutputTests {

    @Test("csv produces non-empty output")
    @MainActor
    func csv_nonEmpty() throws {
        let report = try makeReport()
        #expect(!AthleteReportSerializer.csv(from: report).isEmpty)
    }

    @Test("csv first line is the column header")
    @MainActor
    func csv_headerRow() throws {
        let report    = try makeReport()
        let csv       = AthleteReportSerializer.csv(from: report)
        let firstLine = csv.components(separatedBy: "\r\n").first ?? ""
        #expect(firstLine == "key,value,unit")
    }

    @Test("csv contains the athlete name verbatim")
    @MainActor
    func csv_containsAthleteName() throws {
        let report = try makeReport(athleteName: "Carlos Ramírez")
        #expect(AthleteReportSerializer.csv(from: report).contains("Carlos Ramírez"))
    }

    @Test("csv preserves non-ASCII Unicode characters")
    @MainActor
    func csv_unicodePreserved() throws {
        let report = try makeReport(athleteName: "José García Müller")
        let csv    = AthleteReportSerializer.csv(from: report)
        #expect(csv.contains("José García Müller"))
    }

    @Test("csv uses dot as decimal separator in numeric fields")
    @MainActor
    func csv_dotDecimalSeparator() throws {
        let report = try makeReport()
        let csv    = AthleteReportSerializer.csv(from: report)
        // Slope rows: key has no comma → simple split gives value at index 1
        let slopeLines = csv.components(separatedBy: "\r\n")
            .filter { $0.contains("slope_per_day") }
        #expect(!slopeLines.isEmpty, "Expected at least one slope row in CSV")
        for line in slopeLines {
            let value = line.components(separatedBy: ",").dropFirst().first ?? ""
            #expect(value.contains("."),
                    "Slope value '\(value)' should use '.' decimal separator, not ','")
            #expect(!value.contains(","),
                    "Slope value '\(value)' must not embed a comma (would corrupt CSV structure)")
        }
    }

    @Test("csv omits rows for missing optional athlete fields")
    @MainActor
    func csv_missingOptionals_rowsAbsent() throws {
        let report = try makeReport(withBirthDate: false, withHeight: false)
        let csv    = AthleteReportSerializer.csv(from: report)
        #expect(!csv.contains("athlete.age_years"),
                "No age row expected when athlete has no birthDate")
        #expect(!csv.contains("athlete.height_cm"),
                "No height row expected when athlete has no height")
    }

    @Test("csv serializes minimal report (2 check-ins) without crash")
    @MainActor
    func csv_minimalReport_noCrash() throws {
        let report = try makeReport(checkInCount: 2)
        let csv    = AthleteReportSerializer.csv(from: report)
        #expect(!csv.isEmpty)
    }

    @Test("csv uses CRLF line endings (RFC 4180)")
    @MainActor
    func csv_crlfLineEndings() throws {
        let report = try makeReport()
        let csv    = AthleteReportSerializer.csv(from: report)
        #expect(csv.contains("\r\n"), "CSV must use CRLF line endings per RFC 4180")
    }

    @Test("csv with athlete name containing comma is properly escaped")
    @MainActor
    func csv_athleteNameWithComma_escaped() throws {
        let report = try makeReport(athleteName: "Smith, Jr.")
        let csv    = AthleteReportSerializer.csv(from: report)
        // "Smith, Jr." must appear quoted; raw unquoted "Smith, Jr." must not split the column
        #expect(csv.contains("\"Smith, Jr.\""),
                "Name with comma should be quoted in CSV output")
    }
}
