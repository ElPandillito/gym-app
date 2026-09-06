//
//  AthleteReportSerializerTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("AthleteReportSerializerTests")
struct AthleteReportSerializerTests {

    // MARK: - Helpers

    private let fixedDate = Calendar.current.date(
        from: DateComponents(year: 2026, month: 3, day: 15)
    )!

    private func makeReport(
        athleteName: String = "Carlos Test",
        checkInCount: Int = 5,
        weightTrend: Trend = .insufficient,
        bodyFatTrend: Trend = .insufficient,
        muscleMassTrend: Trend = .insufficient,
        lowestBodyFat: MetricRecord? = nil,
        lowestWeight: MetricRecord? = nil,
        peakMuscleMass: MetricRecord? = nil
    ) -> AthleteReport {
        let athleteID = UUID()
        let stats = AthleteStatisticsReport(
            athleteID: athleteID,
            period: nil,
            checkInCount: checkInCount,
            averageDaysBetweenCheckIns: 14.0,
            weightTrend: weightTrend,
            bodyFatTrend: bodyFatTrend,
            muscleMassTrend: muscleMassTrend,
            lowestBodyFat: lowestBodyFat,
            highestBodyFat: nil,
            lowestWeight: lowestWeight,
            highestWeight: nil,
            peakMuscleMass: peakMuscleMass,
            timeSeries: [:]
        )
        let athlete = AthleteSnapshot(
            id: athleteID,
            name: athleteName,
            gender: .male,
            birthDate: nil,
            heightCm: 178.0
        )
        return AthleteReport(
            id: UUID(),
            type: .athlete,
            generatedAt: fixedDate,
            athlete: athlete,
            period: nil,
            statistics: stats,
            comparisons: [],
            metadata: ReportMetadata(
                generatedBy: "GYM APP",
                format: .pdf,
                includePhotos: true,
                includeNotes: true,
                language: "es"
            )
        )
    }

    // MARK: - Header

    @Test("output contains REPORTE DEL ATLETA header")
    func containsHeader() {
        let text = AthleteReportSerializer.text(from: makeReport())
        #expect(text.contains("REPORTE DEL ATLETA"))
    }

    @Test("output contains athlete name")
    func containsAthleteName() {
        let text = AthleteReportSerializer.text(from: makeReport(athleteName: "Luis Pérez"))
        #expect(text.contains("Luis Pérez"))
    }

    @Test("output contains check-in count")
    func containsCheckInCount() {
        let text = AthleteReportSerializer.text(from: makeReport(checkInCount: 7))
        #expect(text.contains("7"))
    }

    @Test("output contains GYM APP footer")
    func containsFooter() {
        let text = AthleteReportSerializer.text(from: makeReport())
        #expect(text.contains("GYM APP"))
    }

    // MARK: - Trends

    @Test("rising trend contains ↑ symbol")
    func risingTrendSymbol() {
        let risingTrend = Trend(slope: 0.05, intercept: 70, dataPointCount: 5, direction: .rising)
        let text = AthleteReportSerializer.text(from: makeReport(weightTrend: risingTrend))
        #expect(text.contains("↑"))
    }

    @Test("falling trend contains ↓ symbol")
    func fallingTrendSymbol() {
        let fallingTrend = Trend(slope: -0.05, intercept: 70, dataPointCount: 5, direction: .falling)
        let text = AthleteReportSerializer.text(from: makeReport(bodyFatTrend: fallingTrend))
        #expect(text.contains("↓"))
    }

    @Test("flat trend contains → symbol")
    func flatTrendSymbol() {
        let flatTrend = Trend(slope: 0, intercept: 70, dataPointCount: 5, direction: .flat)
        let text = AthleteReportSerializer.text(from: makeReport(muscleMassTrend: flatTrend))
        #expect(text.contains("→"))
    }

    @Test("insufficient trend contains — symbol")
    func insufficientTrendSymbol() {
        let text = AthleteReportSerializer.text(from: makeReport(weightTrend: .insufficient))
        #expect(text.contains("—"))
    }

    // MARK: - Records

    @Test("output contains 'Sin datos suficientes' when no records are available")
    func noRecordsMessage() {
        let text = AthleteReportSerializer.text(from: makeReport())
        #expect(text.contains("Sin datos suficientes"))
    }

    @Test("output contains record value when lowestBodyFat is set")
    func lowestBodyFatRecordPresent() {
        let record = MetricRecord(value: 11.5, date: fixedDate, checkInID: UUID())
        let text = AthleteReportSerializer.text(from: makeReport(lowestBodyFat: record))
        #expect(text.contains("11.5"))
        #expect(text.contains("Menor % grasa"))
        #expect(!text.contains("Sin datos suficientes"))
    }
}
