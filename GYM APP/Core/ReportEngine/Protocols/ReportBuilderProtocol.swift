//
//  ReportBuilderProtocol.swift
//  GYM APP
//

import Foundation

/// Builder pattern contract for constructing reports step-by-step.
protocol ReportBuilderProtocol {
    associatedtype Output

    func setAthlete(_ athlete: AthleteSnapshot) -> Self
    func setPeriod(_ period: DateInterval) -> Self
    func setStatistics(_ stats: AthleteStatisticsReport) -> Self
    func addComparisons(_ comparisons: [CheckInComparison]) -> Self
    func setMetadata(_ metadata: ReportMetadata) -> Self
    func build() -> Output
}

/// Contract for pluggable report sections (Open/Closed extension point).
protocol ReportSectionProtocol {
    var title: String { get }
    func render(from report: AthleteReport) -> String   // Plain text; renderers transform it
}
