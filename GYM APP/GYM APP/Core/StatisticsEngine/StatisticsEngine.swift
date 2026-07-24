//
//  StatisticsEngine.swift
//  GYM APP
//

import Foundation

/// Pure-function statistics engine. All inputs are value-type snapshots; no SwiftData dependency.
enum StatisticsEngine {

    // MARK: - Athlete Report

    static func compute(athleteID: UUID, snapshots: [CheckInSnapshot]) -> AthleteStatisticsReport {
        guard !snapshots.isEmpty else { return .empty(athleteID: athleteID) }
        let sorted = snapshots.sorted { $0.date < $1.date }

        let period = DateInterval(start: sorted.first!.date, end: sorted.last!.date)
        let avgInterval = averageDaysBetween(sorted)

        return AthleteStatisticsReport(
            athleteID:                   athleteID,
            period:                      period,
            checkInCount:                sorted.count,
            averageDaysBetweenCheckIns:  avgInterval,
            weightTrend:                 trend(for: .weight,      in: sorted),
            bodyFatTrend:                trend(for: .bodyFat,     in: sorted),
            muscleMassTrend:             trend(for: .muscleMass,  in: sorted),
            lowestBodyFat:               minimum(for: .bodyFat,   in: sorted),
            highestBodyFat:              maximum(for: .bodyFat,   in: sorted),
            lowestWeight:                minimum(for: .weight,    in: sorted),
            highestWeight:               maximum(for: .weight,    in: sorted),
            peakMuscleMass:              maximum(for: .muscleMass, in: sorted),
            timeSeries:                  buildTimeSeries(sorted)
        )
    }

    // MARK: - Dashboard KPIs

    static func dashboardKPIs(
        athletes: [AthleteSnapshot],
        allSnapshots: [CheckInSnapshot]
    ) -> DashboardKPIs {
        let now   = Date()
        let month = Calendar.current.dateInterval(of: .month, for: now)

        let thisMonth = allSnapshots.filter { s in
            month?.contains(s.date) ?? false
        }.count

        // Latest check-in per athlete for global averages
        let latestPerAthlete: [CheckInSnapshot] = athletes.compactMap { athlete in
            allSnapshots
                .filter { $0.athleteID == athlete.id }
                .sorted { $0.date > $1.date }
                .first
        }

        let bodyFats    = latestPerAthlete.compactMap { $0.bodyMetrics?.bodyFatPercentage }
        let weights     = latestPerAthlete.compactMap { $0.bodyMetrics?.bodyWeight }
        let muscles     = latestPerAthlete.compactMap { $0.bodyMetrics?.muscleMass }

        return DashboardKPIs(
            totalAthletes:               athletes.count,
            totalCheckIns:               allSnapshots.count,
            checkInsThisMonth:           thisMonth,
            averageDaysBetweenCheckIns:  averageDaysBetween(allSnapshots.sorted { $0.date < $1.date }),
            mostRecentCheckInDate:       allSnapshots.map { $0.date }.max(),
            averageBodyFat:              average(bodyFats),
            averageWeight:               average(weights),
            averageMuscleMass:           average(muscles)
        )
    }

    // MARK: - Change percentage helper

    static func percentageChange(from before: Double, to after: Double) -> Double? {
        guard before != 0 else { return nil }
        return (after - before) / before * 100
    }

    // MARK: - Private helpers

    private static func value(for key: MetricKey, in snapshot: CheckInSnapshot) -> Double? {
        let m = snapshot.bodyMetrics
        switch key {
        case .weight:           return m?.bodyWeight
        case .bmi:              return m?.bmi
        case .bodyFat:          return m?.bodyFatPercentage
        case .muscleMass:       return m?.muscleMass
        case .boneMass:         return m?.boneMass
        case .water:            return m?.waterPercentage
        case .visceralFat:      return m?.visceralFatLevel
        case .bmr:              return m?.basalMetabolicRate
        case .skinfoldBodyFat:  return snapshot.skinfolds?.estimatedBodyFatPercentage
        }
    }

    private static func points(for key: MetricKey, in snapshots: [CheckInSnapshot]) -> [DataPoint] {
        snapshots.compactMap { s in
            value(for: key, in: s).map { DataPoint(date: s.date, value: $0) }
        }
    }

    private static func trend(for key: MetricKey, in snapshots: [CheckInSnapshot]) -> Trend {
        Trend.compute(from: points(for: key, in: snapshots))
    }

    private static func minimum(for key: MetricKey, in snapshots: [CheckInSnapshot]) -> MetricRecord? {
        points(for: key, in: snapshots)
            .min(by: { $0.value < $1.value })
            .map { MetricRecord(value: $0.value, date: $0.date, checkInID: snapshot(at: $0.date, in: snapshots)?.id ?? UUID()) }
    }

    private static func maximum(for key: MetricKey, in snapshots: [CheckInSnapshot]) -> MetricRecord? {
        points(for: key, in: snapshots)
            .max(by: { $0.value < $1.value })
            .map { MetricRecord(value: $0.value, date: $0.date, checkInID: snapshot(at: $0.date, in: snapshots)?.id ?? UUID()) }
    }

    private static func snapshot(at date: Date, in snapshots: [CheckInSnapshot]) -> CheckInSnapshot? {
        snapshots.first { $0.date == date }
    }

    private static func averageDaysBetween(_ sorted: [CheckInSnapshot]) -> Double? {
        guard sorted.count > 1 else { return nil }
        let intervals = zip(sorted, sorted.dropFirst())
            .map { $1.date.timeIntervalSince($0.date) / 86_400 }
        return intervals.reduce(0, +) / Double(intervals.count)
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func buildTimeSeries(_ snapshots: [CheckInSnapshot]) -> [MetricKey: [DataPoint]] {
        Dictionary(uniqueKeysWithValues: MetricKey.allCases.map { key in
            (key, points(for: key, in: snapshots))
        }).filter { !$0.value.isEmpty }
    }
}
