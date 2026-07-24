//
//  AthleteReportBuilder.swift
//  GYM APP
//

import Foundation

/// Concrete builder for AthleteReport. Follows the Builder pattern:
/// each setter returns `self` for fluent chaining.
final class AthleteReportBuilder: ReportBuilderProtocol {

    private var athlete: AthleteSnapshot?
    private var period: DateInterval?
    private var statistics: AthleteStatisticsReport?
    private var comparisons: [CheckInComparison] = []
    private var metadata: ReportMetadata = ReportMetadata(
        generatedBy: "GYM APP",
        format: .pdf,
        includePhotos: true,
        includeNotes: true,
        language: "es"
    )

    @discardableResult
    func setAthlete(_ athlete: AthleteSnapshot) -> Self {
        self.athlete = athlete; return self
    }

    @discardableResult
    func setPeriod(_ period: DateInterval) -> Self {
        self.period = period; return self
    }

    @discardableResult
    func setStatistics(_ stats: AthleteStatisticsReport) -> Self {
        self.statistics = stats; return self
    }

    @discardableResult
    func addComparisons(_ comparisons: [CheckInComparison]) -> Self {
        self.comparisons = comparisons; return self
    }

    @discardableResult
    func setMetadata(_ metadata: ReportMetadata) -> Self {
        self.metadata = metadata; return self
    }

    func build() -> AthleteReport {
        precondition(athlete != nil, "AthleteReportBuilder: athlete must be set before build()")
        precondition(statistics != nil, "AthleteReportBuilder: statistics must be set before build()")

        return AthleteReport(
            id:          UUID(),
            type:        .athlete,
            generatedAt: Date(),
            athlete:     athlete!,
            period:      period ?? statistics?.period,
            statistics:  statistics!,
            comparisons: comparisons,
            metadata:    metadata
        )
    }
}
