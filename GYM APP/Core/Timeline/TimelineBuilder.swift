//
//  TimelineBuilder.swift
//  GYM APP
//

import Foundation

/// Pure O(n) transformation — no SwiftData queries, no SwiftUI imports.
/// Converts a flat array of CheckIns into a sorted array of TimelineItems.
enum TimelineBuilder {

    static func build(from checkIns: [CheckIn]) -> [TimelineItem] {
        var items: [TimelineItem] = []
        items.reserveCapacity(checkIns.count * 4)

        for checkIn in checkIns {
            appendItems(for: checkIn, into: &items)
        }

        items.sort { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date > rhs.date }
            return lhs.type.displayPriority < rhs.type.displayPriority
        }

        return items
    }

    // MARK: - Private

    private static func appendItems(for checkIn: CheckIn, into items: inout [TimelineItem]) {
        let ciID = checkIn.id.uuidString

        // Root check-in item
        let photoCount = checkIn.photos.count
        let hasNotes   = hasAnyNote(checkIn)
        items.append(TimelineItem(
            id: "\(ciID)-\(TimelineItemType.checkIn.rawValue)",
            type: .checkIn,
            date: checkIn.date,
            title: "Check-In",
            subtitle: checkInSummary(checkIn),
            payload: .checkIn(
                weight:      checkIn.bodyMetrics?.bodyWeight,
                bodyFat:     checkIn.bodyMetrics?.bodyFatPercentage,
                muscleMass:  checkIn.bodyMetrics?.muscleMass,
                photoCount:  photoCount,
                hasNotes:    hasNotes
            ),
            navigationTarget: .checkIn(id: checkIn.id)
        ))

        // Body metrics
        if let m = checkIn.bodyMetrics {
            items.append(TimelineItem(
                id: "\(ciID)-\(TimelineItemType.bodyMetrics.rawValue)",
                type: .bodyMetrics,
                date: checkIn.date,
                title: "Métricas corporales",
                subtitle: bodyMetricsSubtitle(m),
                payload: .bodyMetrics(
                    weight:     m.bodyWeight,
                    bmi:        m.bmi,
                    bodyFat:    m.bodyFatPercentage,
                    muscleMass: m.muscleMass
                ),
                navigationTarget: .bodyMetrics(checkInID: checkIn.id)
            ))
        }

        // Circumferences
        if let c = checkIn.circumferences {
            let count = circumferenceCount(c)
            items.append(TimelineItem(
                id: "\(ciID)-\(TimelineItemType.circumference.rawValue)",
                type: .circumference,
                date: checkIn.date,
                title: "Medidas corporales",
                subtitle: circumferenceSubtitle(c, count: count),
                payload: .circumference(
                    waist:            c.waist,
                    hips:             c.hips,
                    chest:            c.chest,
                    measurementCount: count
                ),
                navigationTarget: .circumferences(checkInID: checkIn.id)
            ))
        }

        // Skinfolds
        if let sf = checkIn.skinfolds {
            items.append(TimelineItem(
                id: "\(ciID)-\(TimelineItemType.skinfolds.rawValue)",
                type: .skinfolds,
                date: checkIn.date,
                title: "Plicometría",
                subtitle: skinfoldSubtitle(sf),
                payload: .skinfolds(method: sf.method, bodyFat: sf.estimatedBodyFatPercentage),
                navigationTarget: .skinfolds(checkInID: checkIn.id)
            ))
        }

        // Photo session
        if photoCount > 0 {
            let poses = uniquePoses(from: checkIn.photos)
            items.append(TimelineItem(
                id: "\(ciID)-\(TimelineItemType.photoSession.rawValue)",
                type: .photoSession,
                date: checkIn.date,
                title: "Sesión de fotos",
                subtitle: photoSubtitle(count: photoCount, poses: poses),
                payload: .photoSession(count: photoCount, poses: poses),
                navigationTarget: .photos(checkInID: checkIn.id)
            ))
        }

        // Coach note
        if let note = checkIn.coachNote {
            let text = note.text.trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                items.append(TimelineItem(
                    id: "\(ciID)-\(TimelineItemType.coachNote.rawValue)",
                    type: .coachNote,
                    date: checkIn.date,
                    title: "Nota del coach",
                    subtitle: String(text.prefix(120)),
                    payload: .coachNote(text: text),
                    navigationTarget: .coachNote(checkInID: checkIn.id)
                ))
            }
        }

        // Athlete note
        if let note = checkIn.athleteNote {
            let text = note.text.trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                items.append(TimelineItem(
                    id: "\(ciID)-\(TimelineItemType.athleteNote.rawValue)",
                    type: .athleteNote,
                    date: checkIn.date,
                    title: "Nota del atleta",
                    subtitle: String(text.prefix(120)),
                    payload: .athleteNote(text: text),
                    navigationTarget: .athleteNote(checkInID: checkIn.id)
                ))
            }
        }
    }

    // MARK: - Subtitle helpers

    private static func hasAnyNote(_ checkIn: CheckIn) -> Bool {
        let coachText   = checkIn.coachNote?.text.trimmingCharacters(in: .whitespaces) ?? ""
        let athleteText = checkIn.athleteNote?.text.trimmingCharacters(in: .whitespaces) ?? ""
        return !coachText.isEmpty || !athleteText.isEmpty
    }

    private static func checkInSummary(_ checkIn: CheckIn) -> String? {
        var parts: [String] = []
        if let w = checkIn.bodyMetrics?.bodyWeight {
            parts.append(String(format: "%.1f kg", w))
        }
        if checkIn.photos.count > 0 {
            let n = checkIn.photos.count
            parts.append("\(n) \(n == 1 ? "foto" : "fotos")")
        }
        if checkIn.circumferences != nil { parts.append("medidas") }
        if checkIn.skinfolds != nil      { parts.append("plicometría") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func bodyMetricsSubtitle(_ m: BodyMetrics) -> String? {
        var parts: [String] = []
        if let w = m.bodyWeight          { parts.append(String(format: "%.1f kg", w)) }
        if let f = m.bodyFatPercentage   { parts.append(String(format: "%.1f%% grasa", f)) }
        if let mm = m.muscleMass         { parts.append(String(format: "%.1f kg músculo", mm)) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func circumferenceCount(_ c: CircumferenceMeasurements) -> Int {
        [c.neck, c.shoulders, c.chest, c.rightArm, c.leftArm,
         c.rightForearm, c.leftForearm, c.waist, c.abdomen, c.hips,
         c.rightThigh, c.leftThigh, c.rightCalf, c.leftCalf]
            .compactMap { $0 }.count
    }

    private static func circumferenceSubtitle(_ c: CircumferenceMeasurements, count: Int) -> String? {
        var parts: [String] = []
        if let v = c.waist { parts.append(String(format: "Cintura %.0f cm", v)) }
        if let v = c.hips  { parts.append(String(format: "Cadera %.0f cm",  v)) }
        if parts.isEmpty {
            return count > 0 ? "\(count) medidas registradas" : nil
        }
        if count > parts.count {
            parts.append("+\(count - parts.count) más")
        }
        return parts.joined(separator: " · ")
    }

    private static func skinfoldSubtitle(_ sf: SkinfoldMeasurements) -> String? {
        var parts: [String] = [sf.method.displayName]
        if let f = sf.estimatedBodyFatPercentage {
            parts.append(String(format: "%.1f%% grasa", f))
        }
        return parts.joined(separator: " · ")
    }

    private static func uniquePoses(from photos: [ProgressPhoto]) -> [PoseType] {
        var seen: Set<String> = []
        var result: [PoseType] = []
        for photo in photos {
            if seen.insert(photo.poseType.rawValue).inserted {
                result.append(photo.poseType)
            }
        }
        return result.sorted { $0.rawValue < $1.rawValue }
    }

    private static func photoSubtitle(count: Int, poses: [PoseType]) -> String? {
        let countLabel = "\(count) \(count == 1 ? "foto" : "fotos")"
        if poses.isEmpty { return countLabel }
        let poseNames = poses.prefix(3).map { $0.displayName }.joined(separator: ", ")
        let extra = poses.count > 3 ? " +\(poses.count - 3)" : ""
        return "\(countLabel) · \(poseNames)\(extra)"
    }
}
