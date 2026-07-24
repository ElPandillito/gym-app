//
//  AthleteReport.swift
//  GYM APP
//

import Foundation

/// Fully serializable report model. The ReportEngine builds this;
/// a future rendering service (PDF, CSV) consumes it.
struct AthleteReport: Sendable {
    let id: UUID
    let type: ReportType
    let generatedAt: Date
    let athlete: AthleteSnapshot
    let period: DateInterval?
    let statistics: AthleteStatisticsReport
    let comparisons: [CheckInComparison]
    let metadata: ReportMetadata
}

struct ReportMetadata: Sendable {
    let generatedBy: String         // App name/version
    let format: ReportFormat
    let includePhotos: Bool
    let includeNotes: Bool
    let language: String            // e.g. "es", "en"
}
