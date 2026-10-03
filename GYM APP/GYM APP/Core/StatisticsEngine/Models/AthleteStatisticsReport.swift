//
//  AthleteStatisticsReport.swift
//  GYM APP
//

import Foundation

/// Full statistical summary for a single athlete over a set of check-ins.
struct AthleteStatisticsReport: Sendable, Encodable {
    let athleteID: UUID
    let period: DateInterval?
    let checkInCount: Int
    let averageDaysBetweenCheckIns: Double?

    // Trends (OLS linear regression over time)
    let weightTrend: Trend
    let bodyFatTrend: Trend
    let muscleMassTrend: Trend

    // Personal records
    let lowestBodyFat: MetricRecord?
    let highestBodyFat: MetricRecord?
    let lowestWeight: MetricRecord?
    let highestWeight: MetricRecord?
    let peakMuscleMass: MetricRecord?

    // Time-series data per metric (for future charts)
    // Not part of the JSON report output — see CodingKeys below.
    let timeSeries: [MetricKey: [DataPoint]]

    /// `timeSeries` is intentionally excluded from JSON: it's an internal
    /// chart-data cache, not part of the athlete report's semantic content
    /// (PDF/CSV/text also never surface it).
    enum CodingKeys: String, CodingKey {
        case athleteID, period, checkInCount, averageDaysBetweenCheckIns
        case weightTrend, bodyFatTrend, muscleMassTrend
        case lowestBodyFat, highestBodyFat, lowestWeight, highestWeight, peakMuscleMass
    }

    static func empty(athleteID: UUID) -> AthleteStatisticsReport {
        AthleteStatisticsReport(
            athleteID: athleteID,
            period: nil,
            checkInCount: 0,
            averageDaysBetweenCheckIns: nil,
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
}
