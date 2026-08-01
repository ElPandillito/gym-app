//
//  DashboardViewModel.swift
//  GYM APP
//

import SwiftUI
import SwiftData
import OSLog

// MARK: - Supporting types

struct DashboardRecentCheckIn: Identifiable {
    let id: UUID
    let athleteID: UUID
    let athleteName: String
    let date: Date
    let weight: Double?
    let weightChangeDelta: Double?  // kg: negative = lost, positive = gained
    let photoCount: Int
}

/// DashboardAlert is the shared AthleteAlert type.
/// Alert rules and their single source of truth live in AthleteAlertEvaluator.
typealias DashboardAlert = AthleteAlert

struct DashboardProgressor: Identifiable {
    let id: UUID   // athleteID
    let athleteName: String
    let weightChangePct: Double?
    let bodyFatChangePts: Double?
    let periodDays: Int
}

struct DashboardPendingAction: Identifiable {

    enum Kind {
        case requestCheckIn
        case addMetrics
        case addPhotos
        case addSkinfold
    }

    let athleteID: UUID
    let athleteName: String
    let kind: Kind

    // Deterministic: same athlete + same action kind → same ID across reloads
    var id: String { athleteID.uuidString + "-" + kind.stableKey }

    var icon: String {
        switch kind {
        case .requestCheckIn: return "calendar.badge.plus"
        case .addMetrics:     return "scalemass"
        case .addPhotos:      return "camera.badge.plus"
        case .addSkinfold:    return "ruler"
        }
    }

    var description: String {
        switch kind {
        case .requestCheckIn: return "Solicitar nuevo check-in"
        case .addMetrics:     return "Registrar métricas corporales"
        case .addPhotos:      return "Actualizar fotografías"
        case .addSkinfold:    return "Registrar plicometría"
        }
    }
}

private extension DashboardPendingAction.Kind {
    var stableKey: String {
        switch self {
        case .requestCheckIn: return "requestCheckIn"
        case .addMetrics:     return "addMetrics"
        case .addPhotos:      return "addPhotos"
        case .addSkinfold:    return "addSkinfold"
        }
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - State

    var kpis: DashboardKPIs                      = .empty
    var checkInsThisWeek: Int                    = 0
    var recentCheckIns: [DashboardRecentCheckIn] = []
    var alerts: [DashboardAlert]                 = []
    var topProgressors: [DashboardProgressor]    = []
    var pendingActions: [DashboardPendingAction] = []
    var isLoading                                = false

    // MARK: - Thresholds

    private let inactivityDays     = 14
    private let trendWindowDays    = 60
    private let progressWindowDays = 30
    private let maxAlerts          = 10
    private let maxProgressors     = 5
    private let maxRecent          = 10
    private let maxActions         = 10

    // MARK: - Load

    func load(athletes: [Athlete], checkIns: [CheckIn]) {
        guard !athletes.isEmpty else { reset(); return }
        isLoading = true
        defer { isLoading = false }

        let ctx = buildContext(athletes: athletes, checkIns: checkIns)
        let (newKPIs, thisWeek) = buildKPIs(athletes: athletes, checkIns: checkIns, ctx: ctx)
        kpis             = newKPIs
        checkInsThisWeek = thisWeek
        recentCheckIns   = buildRecentActivity(checkIns: checkIns, ctx: ctx)
        alerts           = buildAlerts(athletes: athletes, ctx: ctx)
        topProgressors   = buildProgressors(athletes: athletes, ctx: ctx)
        pendingActions   = buildPendingActions(athletes: athletes, ctx: ctx)
    }

    // MARK: - Private: Shared context

    private struct LoadContext {
        let now: Date
        let calendar: Calendar
        let ciByAthlete: [UUID: [CheckIn]]
        let nameByID: [UUID: String]
        let latestSnapByID: [UUID: CheckInSnapshot]
        let latestCIByID: [UUID: CheckIn]
        /// Days since latest check-in per athlete — computed once, reused by alerts and actions.
        let daysSinceLatestByID: [UUID: Int]
    }

    private func buildContext(athletes: [Athlete], checkIns: [CheckIn]) -> LoadContext {
        let now      = Date()
        let calendar = Calendar.current

        // Index check-ins per athlete, sorted ascending
        var ciByAthlete: [UUID: [CheckIn]] = [:]
        for ci in checkIns {
            guard let aid = ci.athlete?.id else { continue }
            ciByAthlete[aid, default: []].append(ci)
        }
        for key in ciByAthlete.keys {
            ciByAthlete[key]!.sort { $0.date < $1.date }
        }

        let nameByID: [UUID: String] = Dictionary(uniqueKeysWithValues: athletes.map { ($0.id, $0.name) })

        // Latest check-in and snapshot per athlete
        var latestSnapByID: [UUID: CheckInSnapshot] = [:]
        var latestCIByID:   [UUID: CheckIn]         = [:]
        for athlete in athletes {
            if let ci = ciByAthlete[athlete.id]?.last {
                latestCIByID[athlete.id]   = ci
                latestSnapByID[athlete.id] = CheckInSnapshot(from: ci)
            }
        }

        // Days since latest check-in — single computation shared by alerts + actions
        var daysSinceLatestByID: [UUID: Int] = [:]
        for athlete in athletes {
            guard let latestDate = latestCIByID[athlete.id]?.date else { continue }
            daysSinceLatestByID[athlete.id] =
                calendar.dateComponents([.day], from: latestDate, to: now).day ?? 0
        }

        return LoadContext(
            now:                 now,
            calendar:            calendar,
            ciByAthlete:         ciByAthlete,
            nameByID:            nameByID,
            latestSnapByID:      latestSnapByID,
            latestCIByID:        latestCIByID,
            daysSinceLatestByID: daysSinceLatestByID
        )
    }

    // MARK: - Private: KPIs

    private func buildKPIs(
        athletes: [Athlete],
        checkIns: [CheckIn],
        ctx: LoadContext
    ) -> (DashboardKPIs, Int) {
        // Single pass over checkIns for both month and week counts
        var thisMonth = 0
        var thisWeek  = 0
        for ci in checkIns {
            if ci.date.isThisMonth { thisMonth += 1 }
            if ci.date.isThisWeek  { thisWeek  += 1 }
        }

        let latestSnaps = Array(ctx.latestSnapByID.values)
        let bodyFats    = latestSnaps.compactMap { $0.bodyMetrics?.bodyFatPercentage }
        let weights     = latestSnaps.compactMap { $0.bodyMetrics?.bodyWeight }
        let muscles     = latestSnaps.compactMap { $0.bodyMetrics?.muscleMass }

        let kpis = DashboardKPIs(
            totalAthletes:              athletes.count,
            totalCheckIns:              checkIns.count,
            checkInsThisMonth:          thisMonth,
            averageDaysBetweenCheckIns: nil,
            mostRecentCheckInDate:      checkIns.first?.date, // @Query delivers descending order
            averageBodyFat:             avg(bodyFats),
            averageWeight:              avg(weights),
            averageMuscleMass:          avg(muscles)
        )
        return (kpis, thisWeek)
    }

    // MARK: - Private: Recent Activity

    private func buildRecentActivity(
        checkIns: [CheckIn],
        ctx: LoadContext
    ) -> [DashboardRecentCheckIn] {
        // checkIns already sorted descending by @Query — no re-sort needed
        checkIns.prefix(maxRecent).compactMap { ci in
            guard let aid = ci.athlete?.id, let name = ctx.nameByID[aid] else { return nil }
            let prevCI = ctx.ciByAthlete[aid]?.last(where: { $0.date < ci.date })
            let w  = ci.bodyMetrics?.bodyWeight
            let pw = prevCI?.bodyMetrics?.bodyWeight
            return DashboardRecentCheckIn(
                id:                ci.id,
                athleteID:         aid,
                athleteName:       name,
                date:              ci.date,
                weight:            w,
                weightChangeDelta: w.flatMap { wv in pw.map { pv in wv - pv } },
                photoCount:        ci.photos.count
            )
        }
    }

    // MARK: - Private: Alerts

    private func buildAlerts(
        athletes: [Athlete],
        ctx: LoadContext
    ) -> [DashboardAlert] {
        var result: [DashboardAlert] = []
        let prefs = CoachPreferences.default

        for athlete in athletes {
            guard result.count < maxAlerts else { break }
            let snapshots = (ctx.ciByAthlete[athlete.id] ?? []).map(CheckInSnapshot.init)
            // Dashboard shows at most one alert per athlete (highest severity)
            if let alert = AthleteAlertEvaluator.evaluate(
                athleteID:      athlete.id,
                athleteName:    athlete.name,
                sortedCheckIns: snapshots,
                preferences:    prefs,
                now:            ctx.now
            ).first {
                result.append(alert)
            }
        }

        return result.sorted { $0.severity > $1.severity }
    }

    // MARK: - Private: Progressors

    private func buildProgressors(
        athletes: [Athlete],
        ctx: LoadContext
    ) -> [DashboardProgressor] {
        let progressCutoff = ctx.calendar.date(byAdding: .day, value: -progressWindowDays, to: ctx.now)!
        var result: [DashboardProgressor] = []

        for athlete in athletes {
            let sorted = ctx.ciByAthlete[athlete.id] ?? []
            guard sorted.count >= 2,
                  let latest = sorted.last,
                  latest.date >= progressCutoff else { continue }

            let base = sorted.last(where: { $0.date < progressCutoff }) ?? sorted.first!
            guard base.id != latest.id else { continue }

            let bw = base.bodyMetrics?.bodyWeight
            let lw = latest.bodyMetrics?.bodyWeight
            let weightPct: Double? = bw.flatMap { b in lw.map { l in ((l - b) / b) * 100 } }

            let bf = base.bodyMetrics?.bodyFatPercentage   ?? base.skinfolds?.estimatedBodyFatPercentage
            let lf = latest.bodyMetrics?.bodyFatPercentage ?? latest.skinfolds?.estimatedBodyFatPercentage
            let fatDelta: Double? = bf.flatMap { b in lf.map { l in l - b } }

            guard weightPct != nil || fatDelta != nil else { continue }

            let days = ctx.calendar.dateComponents([.day], from: base.date, to: latest.date).day ?? 1
            result.append(DashboardProgressor(
                id:               athlete.id,
                athleteName:      athlete.name,
                weightChangePct:  weightPct,
                bodyFatChangePts: fatDelta,
                periodDays:       days
            ))
        }

        return result
            .sorted { progressScore($0) > progressScore($1) }
            .prefix(maxProgressors)
            .map { $0 }
    }

    // MARK: - Private: Pending Actions

    private func buildPendingActions(
        athletes: [Athlete],
        ctx: LoadContext
    ) -> [DashboardPendingAction] {
        var result: [DashboardPendingAction] = []

        for athlete in athletes {
            guard result.count < maxActions else { break }

            guard let snap = ctx.latestSnapByID[athlete.id] else {
                // Athlete has never had a check-in
                result.append(.init(athleteID: athlete.id, athleteName: athlete.name,
                                    kind: .requestCheckIn))
                continue
            }

            // Reuse pre-computed daysSince (shared with buildAlerts)
            let daysSince = ctx.daysSinceLatestByID[athlete.id] ?? Int.max
            let sorted    = ctx.ciByAthlete[athlete.id] ?? []

            if daysSince >= inactivityDays {
                result.append(.init(athleteID: athlete.id, athleteName: athlete.name,
                                    kind: .requestCheckIn))
            } else if snap.bodyMetrics?.bodyWeight == nil {
                result.append(.init(athleteID: athlete.id, athleteName: athlete.name,
                                    kind: .addMetrics))
            } else if snap.photoCount == 0 {
                result.append(.init(athleteID: athlete.id, athleteName: athlete.name,
                                    kind: .addPhotos))
            } else if snap.skinfolds == nil {
                let prevSnap = sorted.dropLast().last.map(CheckInSnapshot.init)
                if prevSnap?.skinfolds == nil {
                    result.append(.init(athleteID: athlete.id, athleteName: athlete.name,
                                        kind: .addSkinfold))
                }
            }
        }

        return result
    }

    // MARK: - Private: Helpers

    private func progressScore(_ p: DashboardProgressor) -> Double {
        -(p.bodyFatChangePts ?? 0) * 10.0 + -(p.weightChangePct ?? 0)
    }

    private func avg(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func reset() {
        kpis             = .empty
        checkInsThisWeek = 0
        recentCheckIns   = []
        alerts           = []
        topProgressors   = []
        pendingActions   = []
    }
}
