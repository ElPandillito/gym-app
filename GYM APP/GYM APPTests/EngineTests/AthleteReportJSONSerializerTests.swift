//
//  AthleteReportJSONSerializerTests.swift
//  GYM APPTests
//
//  Tests for AthleteReportSerializer.json(from:).
//

import Testing
import Foundation
@testable import GYM_APP

// MARK: - Fixtures

private let fixedDate = Calendar.current.date(
    from: DateComponents(year: 2026, month: 3, day: 15)
)!

private func makeStats(checkInCount: Int = 5) -> AthleteStatisticsReport {
    AthleteStatisticsReport(
        athleteID: UUID(),
        period: nil,
        checkInCount: checkInCount,
        averageDaysBetweenCheckIns: 14.0,
        weightTrend: .insufficient,
        bodyFatTrend: .insufficient,
        muscleMassTrend: .insufficient,
        lowestBodyFat: nil,
        highestBodyFat: nil,
        lowestWeight: nil,
        highestWeight: nil,
        peakMuscleMass: nil,
        timeSeries: [:]
    )
}

private func makeReport(
    athleteName: String = "Carlos Test",
    birthDate: Date? = nil,
    heightCm: Double? = nil,
    comparisons: [CheckInComparison] = []
) -> AthleteReport {
    let athlete = AthleteSnapshot(
        id: UUID(), name: athleteName, gender: .male, birthDate: birthDate, heightCm: heightCm
    )
    return AthleteReport(
        id: UUID(),
        type: .athlete,
        generatedAt: fixedDate,
        athlete: athlete,
        period: nil,
        statistics: makeStats(),
        comparisons: comparisons,
        metadata: ReportMetadata(
            generatedBy: "GYM APP",
            format: .pdf,
            includePhotos: true,
            includeNotes: true,
            language: "es"
        )
    )
}

/// A comparison with no body-metric data ("unavailable" diffs) — a real,
/// valid CheckInComparison value, not fabricated business data.
private func makeComparison() -> CheckInComparison {
    CheckInComparison(
        id: UUID(),
        checkInAID: UUID(),
        checkInBID: UUID(),
        dateA: fixedDate,
        dateB: fixedDate.addingTimeInterval(86_400 * 14),
        daysBetween: 14,
        weight: MetricDiff(before: 80, after: 78),
        bmi: MetricDiff(before: nil, after: nil),
        bodyFat: MetricDiff(before: 18, after: 17),
        muscleMass: MetricDiff(before: 60, after: 61),
        boneMass: MetricDiff(before: nil, after: nil),
        water: MetricDiff(before: nil, after: nil),
        visceralFat: MetricDiff(before: nil, after: nil),
        bmr: MetricDiff(before: nil, after: nil),
        circumferences: CircumferencesDiff(a: nil, b: nil),
        skinfoldBodyFat: MetricDiff(before: nil, after: nil),
        photosA: 2,
        photosB: 3,
        hasCoachNoteA: true,
        hasCoachNoteB: false
    )
}

private func decodeJSON(_ data: Data) throws -> [String: Any] {
    let obj = try JSONSerialization.jsonObject(with: data)
    return obj as? [String: Any] ?? [:]
}

// MARK: - Tests

@Suite("AthleteReportSerializer.json — JSON export")
struct AthleteReportJSONSerializerTests {

    @Test("ReportFormat.json has the expected MIME type and file extension")
    func reportFormat_json_metadata() {
        #expect(ReportFormat.json.mimeType == "application/json")
        #expect(ReportFormat.json.fileExtension == "json")
    }

    @Test("json(from:) produces valid, parseable JSON")
    func json_isValid() throws {
        let data = try AthleteReportSerializer.json(from: makeReport())
        let obj = try JSONSerialization.jsonObject(with: data)
        #expect(obj is [String: Any])
    }

    @Test("json(from:) is deterministic across repeated calls")
    func json_isDeterministic() throws {
        let report = makeReport()
        let first = try AthleteReportSerializer.json(from: report)
        let second = try AthleteReportSerializer.json(from: report)
        #expect(first == second)
    }

    @Test("json(from:) includes the top-level report fields")
    func json_containsRequiredFields() throws {
        let data = try AthleteReportSerializer.json(from: makeReport())
        let obj = try decodeJSON(data)
        for key in ["id", "type", "generatedAt", "athlete", "statistics", "metadata", "comparisons"] {
            #expect(obj[key] != nil, "Missing top-level key: \(key)")
        }
    }

    @Test("json(from:) serializes ReportMetadata fields verbatim")
    func json_metadataFields() throws {
        let data = try AthleteReportSerializer.json(from: makeReport())
        let obj = try decodeJSON(data)
        let metadata = obj["metadata"] as? [String: Any]
        #expect(metadata?["generatedBy"] as? String == "GYM APP")
        #expect(metadata?["format"] as? String == "pdf")
        #expect(metadata?["includePhotos"] as? Bool == true)
        #expect(metadata?["includeNotes"] as? Bool == true)
        #expect(metadata?["language"] as? String == "es")
    }

    @Test("json(from:) serializes the actual ReportType produced by the builder (athlete)")
    func json_reportType() throws {
        let data = try AthleteReportSerializer.json(from: makeReport())
        let obj = try decodeJSON(data)
        #expect(obj["type"] as? String == "athlete")
    }

    @Test("json(from:) serializes empty comparisons as an empty array when none are populated")
    func json_emptyComparisons() throws {
        let data = try AthleteReportSerializer.json(from: makeReport(comparisons: []))
        let obj = try decodeJSON(data)
        let comparisons = obj["comparisons"] as? [Any]
        #expect(comparisons?.isEmpty == true)
    }

    @Test("json(from:) preserves real comparison data when present")
    func json_populatedComparisons() throws {
        let data = try AthleteReportSerializer.json(from: makeReport(comparisons: [makeComparison()]))
        let obj = try decodeJSON(data)
        let comparisons = obj["comparisons"] as? [[String: Any]]
        #expect(comparisons?.count == 1)
        let first = comparisons?.first
        #expect(first?["daysBetween"] as? Int == 14)
        #expect(first?["photosA"] as? Int == 2)
        let weight = first?["weight"] as? [String: Any]
        #expect(weight?["direction"] as? String == "decreased")
    }

    @Test("json(from:) preserves non-ASCII Unicode characters")
    func json_unicodePreserved() throws {
        let data = try AthleteReportSerializer.json(from: makeReport(athleteName: "José García Müller"))
        let text = String(data: data, encoding: .utf8)
        #expect(text?.contains("José García Müller") == true)
    }

    @Test("json(from:) omits nil optional fields rather than fabricating values")
    func json_omitsNilOptionals() throws {
        let data = try AthleteReportSerializer.json(from: makeReport(birthDate: nil, heightCm: nil))
        let obj = try decodeJSON(data)
        let athlete = obj["athlete"] as? [String: Any]
        #expect(athlete?["birthDate"] == nil)
        #expect(athlete?["heightCm"] == nil)
        #expect(obj["period"] == nil)
    }

    @Test("json(from:) is UTF-8 encoded")
    func json_isUTF8() throws {
        let data = try AthleteReportSerializer.json(from: makeReport())
        #expect(String(data: data, encoding: .utf8) != nil)
    }
}
