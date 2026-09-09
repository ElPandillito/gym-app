//
//  ComparisonViewModel.swift
//  GYM APP
//

import Foundation

// MARK: - MetricSentiment

enum MetricSentiment {
    case positiveWhenDecreased
    case positiveWhenIncreased
    case neutral
}

// MARK: - ComparisonRow

struct ComparisonRow: Identifiable {
    var id: String { label }
    let label: String
    let diff: MetricDiff
    let sentiment: MetricSentiment
    let unit: String
    // Pre-converted display values (may differ from diff.before/after when unit != canonical)
    let displayBefore: Double?
    let displayAfter: Double?
    let displayAbsoluteChange: Double?
}

// MARK: - ComparisonSection

struct ComparisonSection: Identifiable {
    var id: String { title }
    let title: String
    let systemImage: String
    let rows: [ComparisonRow]
}

// MARK: - ComparisonInsight
// Raw typed data — the View decides formatting, colors, and icons.

enum ComparisonInsight {
    case improvement(label: String, absoluteChange: Double, unit: String)
    case regression(label: String, absoluteChange: Double, unit: String)
    case change(label: String, absoluteChange: Double, unit: String)
    case photosAdded(count: Int)
    case photosRemoved(count: Int)
    case noteAdded(isCoach: Bool)
}

// MARK: - PhotoComparison

struct PhotoComparison {
    let photosA: [ProgressPhoto]
    let photosB: [ProgressPhoto]
    let dateA: Date
    let dateB: Date

    var hasAny: Bool      { !photosA.isEmpty || !photosB.isEmpty }
    var hasBothSides: Bool { !photosA.isEmpty && !photosB.isEmpty }
}

// MARK: - ComparisonSummary

struct ComparisonSummary {
    let athleteName: String
    let dateA: Date
    let dateB: Date
    let daysBetween: Int
    let insights: [ComparisonInsight]
    var aiInsights: [String] = []   // Phase 13+ hook — not implemented
}

// MARK: - ComparisonViewModel

@Observable
@MainActor
final class ComparisonViewModel {

    // MARK: - Outputs

    private(set) var sections:        [ComparisonSection] = []
    private(set) var summary:          ComparisonSummary?
    private(set) var photoComparison:  PhotoComparison?
    private(set) var earlierCheckIn:   CheckIn?
    private(set) var laterCheckIn:     CheckIn?
    /// Exposed for future ReportBuilder / PDF consumption — never recalculated.
    private(set) var rawComparison:    CheckInComparison?

    private var preferences: CoachPreferences = .default

    // MARK: - Derived

    var isEmpty: Bool { sections.isEmpty && photoComparison?.hasAny != true }

    var hasNotes: Bool {
        let texts: [String?] = [
            earlierCheckIn?.coachNote?.text,
            laterCheckIn?.coachNote?.text,
            earlierCheckIn?.athleteNote?.text,
            laterCheckIn?.athleteNote?.text
        ]
        return texts.contains { ($0?.trimmingCharacters(in: .whitespaces) ?? "").isEmpty == false }
    }

    // MARK: - Configure (call exactly once per pair; pass preferences for display units)

    func configure(checkInA: CheckIn, checkInB: CheckIn, preferences: CoachPreferences = .default) {
        self.preferences = preferences
        let (earlier, later) = checkInA.date <= checkInB.date
            ? (checkInA, checkInB)
            : (checkInB, checkInA)

        earlierCheckIn = earlier
        laterCheckIn   = later

        // Build snapshots and run engine once — results reused for all outputs.
        let snapshotA = CheckInSnapshot(from: earlier)
        let snapshotB = CheckInSnapshot(from: later)
        let result    = CheckInComparisonEngine.compare(snapshotA, snapshotB)

        rawComparison   = result
        sections        = buildSections(result)
        photoComparison = buildPhotoComparison(earlier: earlier, later: later)
        summary         = buildSummary(result, earlier: earlier, later: later)
    }

    /// Rebuilds sections and summary with new preferences without re-running the comparison engine.
    func reconfigure(preferences: CoachPreferences) {
        self.preferences = preferences
        guard let c = rawComparison, let earlier = earlierCheckIn, let later = laterCheckIn else { return }
        sections = buildSections(c)
        summary  = buildSummary(c, earlier: earlier, later: later)
    }

    // MARK: - Sections

    private func buildSections(_ c: CheckInComparison) -> [ComparisonSection] {
        var result: [ComparisonSection] = []

        let bodyRows = bodyMetricRows(c)
        if !bodyRows.isEmpty {
            result.append(ComparisonSection(
                title: "Composición Corporal",
                systemImage: "scalemass.fill",
                rows: bodyRows
            ))
        }

        let circRows = circumferenceRows(c.circumferences)
        if !circRows.isEmpty {
            result.append(ComparisonSection(
                title: "Medidas Corporales",
                systemImage: "arrow.left.and.right.circle.fill",
                rows: circRows
            ))
        }

        if c.skinfoldBodyFat.direction != .unavailable {
            let sf = c.skinfoldBodyFat
            result.append(ComparisonSection(
                title: "Plicometría",
                systemImage: "ruler.fill",
                rows: [ComparisonRow(
                    label:                 "Grasa (Plicometría)",
                    diff:                  sf,
                    sentiment:             .positiveWhenDecreased,
                    unit:                  "%",
                    displayBefore:         sf.before,
                    displayAfter:          sf.after,
                    displayAbsoluteChange: sf.absoluteChange
                )]
            ))
        }

        return result
    }

    private func bodyMetricRows(_ c: CheckInComparison) -> [ComparisonRow] {
        let fmt = AppUnitFormatter(preferences: preferences)
        // Sentiments based on bodybuilding context, not generic fitness.
        // Weight is neutral: could be fat loss (good) or muscle loss (bad) or bulk (intended).
        typealias Entry = (MetricDiff, String, MetricSentiment, String, (Double) -> Double)
        let candidates: [Entry] = [
            (c.weight,      "Peso",           .neutral,               fmt.weightLabel, fmt.convertedWeight),
            (c.bmi,         "IMC",            .neutral,               "kg/m²",         { $0 }),
            (c.bodyFat,     "Grasa corporal", .positiveWhenDecreased, "%",             { $0 }),
            (c.muscleMass,  "Masa muscular",  .positiveWhenIncreased, fmt.weightLabel, fmt.convertedWeight),
            (c.boneMass,    "Masa ósea",      .neutral,               fmt.weightLabel, fmt.convertedWeight),
            (c.water,       "Agua corporal",  .neutral,               "%",             { $0 }),
            (c.visceralFat, "Grasa visceral", .positiveWhenDecreased, "",              { $0 }),
            (c.bmr,         "TMB",            .positiveWhenIncreased, "kcal",          { $0 }),
        ]
        return candidates
            .filter { $0.0.direction != .unavailable }
            .map { diff, label, sentiment, unit, convert in
                ComparisonRow(
                    label: label, diff: diff, sentiment: sentiment, unit: unit,
                    displayBefore:         diff.before.map         { convert($0) },
                    displayAfter:          diff.after.map          { convert($0) },
                    displayAbsoluteChange: diff.absoluteChange.map { convert($0) }
                )
            }
    }

    private func circumferenceRows(_ c: CircumferencesDiff) -> [ComparisonRow] {
        let fmt = AppUnitFormatter(preferences: preferences)
        let unit = fmt.lengthLabel
        let convert: (Double) -> Double = fmt.convertedLength
        let candidates: [(MetricDiff, String, MetricSentiment)] = [
            (c.neck,         "Cuello",                .neutral),
            (c.shoulders,    "Hombros",               .neutral),
            (c.chest,        "Pecho",                 .neutral),
            (c.rightArm,     "Brazo derecho",         .positiveWhenIncreased),
            (c.leftArm,      "Brazo izquierdo",       .positiveWhenIncreased),
            (c.rightForearm, "Antebrazo derecho",     .neutral),
            (c.leftForearm,  "Antebrazo izquierdo",   .neutral),
            (c.waist,        "Cintura",               .positiveWhenDecreased),
            (c.abdomen,      "Abdomen",               .positiveWhenDecreased),
            (c.hips,         "Cadera / Glúteos",      .neutral),
            (c.rightThigh,   "Muslo derecho",         .neutral),
            (c.leftThigh,    "Muslo izquierdo",       .neutral),
            (c.rightCalf,    "Pantorrilla derecha",   .neutral),
            (c.leftCalf,     "Pantorrilla izquierda", .neutral),
        ]
        return candidates
            .filter { $0.0.direction != .unavailable }
            .map { diff, label, sentiment in
                ComparisonRow(
                    label: label, diff: diff, sentiment: sentiment, unit: unit,
                    displayBefore:         diff.before.map         { convert($0) },
                    displayAfter:          diff.after.map          { convert($0) },
                    displayAbsoluteChange: diff.absoluteChange.map { convert($0) }
                )
            }
    }

    // MARK: - Photo comparison

    private func buildPhotoComparison(earlier: CheckIn, later: CheckIn) -> PhotoComparison {
        PhotoComparison(
            photosA: earlier.photos.sorted { $0.sortOrder < $1.sortOrder },
            photosB: later.photos.sorted   { $0.sortOrder < $1.sortOrder },
            dateA:   earlier.date,
            dateB:   later.date
        )
    }

    // MARK: - Summary

    private func buildSummary(
        _ c: CheckInComparison,
        earlier: CheckIn,
        later: CheckIn
    ) -> ComparisonSummary {
        let fmt = AppUnitFormatter(preferences: preferences)
        var insights: [ComparisonInsight] = []

        // Key body metrics
        addInsight(into: &insights, diff: c.weight,    label: "Peso",          unit: fmt.weightLabel,
                   sentiment: .neutral,               convert: fmt.convertedWeight)
        if c.bodyFat.direction != .unavailable {
            addInsight(into: &insights, diff: c.bodyFat, label: "Grasa corporal", unit: "%", sentiment: .positiveWhenDecreased)
        } else {
            addInsight(into: &insights, diff: c.skinfoldBodyFat, label: "IGC",    unit: "%", sentiment: .positiveWhenDecreased)
        }
        addInsight(into: &insights, diff: c.muscleMass, label: "Masa muscular", unit: fmt.weightLabel,
                   sentiment: .positiveWhenIncreased, convert: fmt.convertedWeight)

        // Key circumferences
        addInsight(into: &insights, diff: c.circumferences.waist,      label: "Cintura", unit: fmt.lengthLabel,
                   sentiment: .positiveWhenDecreased, convert: fmt.convertedLength)
        addInsight(into: &insights, diff: c.circumferences.abdomen,    label: "Abdomen", unit: fmt.lengthLabel,
                   sentiment: .positiveWhenDecreased, convert: fmt.convertedLength)
        addInsight(into: &insights, diff: c.circumferences.rightArm,   label: "Brazo",   unit: fmt.lengthLabel,
                   sentiment: .positiveWhenIncreased, convert: fmt.convertedLength)
        addInsight(into: &insights, diff: c.circumferences.rightThigh, label: "Muslo",   unit: fmt.lengthLabel,
                   sentiment: .neutral,               convert: fmt.convertedLength)

        // Photos count change
        let photoDelta = c.photosB - c.photosA
        if photoDelta > 0      { insights.append(.photosAdded(count: photoDelta)) }
        else if photoDelta < 0 { insights.append(.photosRemoved(count: abs(photoDelta))) }

        // Notes added (coach note from engine; athlete note resolved from model)
        if !c.hasCoachNoteA && c.hasCoachNoteB { insights.append(.noteAdded(isCoach: true)) }

        let hadAthleteNote = !(earlier.athleteNote?.text.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        let hasAthleteNote = !(later.athleteNote?.text.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        if !hadAthleteNote && hasAthleteNote { insights.append(.noteAdded(isCoach: false)) }

        return ComparisonSummary(
            athleteName: earlier.athlete?.name ?? "",
            dateA:       earlier.date,
            dateB:       later.date,
            daysBetween: c.daysBetween,
            insights:    insights
        )
    }

    private func addInsight(
        into insights: inout [ComparisonInsight],
        diff: MetricDiff,
        label: String,
        unit: String,
        sentiment: MetricSentiment,
        convert: ((Double) -> Double)? = nil
    ) {
        guard let rawDelta = diff.absoluteChange, diff.direction != .unchanged else { return }
        let delta = convert.map { $0(rawDelta) } ?? rawDelta

        switch sentiment {
        case .positiveWhenDecreased:
            insights.append(diff.direction == .decreased
                ? .improvement(label: label, absoluteChange: delta, unit: unit)
                : .regression( label: label, absoluteChange: delta, unit: unit))
        case .positiveWhenIncreased:
            insights.append(diff.direction == .increased
                ? .improvement(label: label, absoluteChange: delta, unit: unit)
                : .regression( label: label, absoluteChange: delta, unit: unit))
        case .neutral:
            insights.append(.change(label: label, absoluteChange: delta, unit: unit))
        }
    }
}
