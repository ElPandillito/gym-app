//
//  MetricDiff.swift
//  GYM APP
//

import Foundation

/// The delta between one metric value in two check-ins.
struct MetricDiff: Equatable {
    let before: Double?
    let after: Double?
    let absoluteChange: Double?         // after - before
    let percentageChange: Double?       // (after - before) / before * 100
    let direction: ChangeDirection

    init(before: Double?, after: Double?) {
        self.before = before
        self.after  = after

        if let b = before, let a = after {
            let delta = a - b
            absoluteChange   = delta
            percentageChange = b != 0 ? (delta / b) * 100 : nil
            if abs(delta) < 0.001 {
                direction = .unchanged
            } else {
                direction = delta > 0 ? .increased : .decreased
            }
        } else {
            absoluteChange   = nil
            percentageChange = nil
            direction        = .unavailable
        }
    }
}

// MARK: - CircumferencesDiff

struct CircumferencesDiff: Equatable {
    let neck: MetricDiff
    let shoulders: MetricDiff
    let chest: MetricDiff
    let rightArm: MetricDiff
    let leftArm: MetricDiff
    let rightForearm: MetricDiff
    let leftForearm: MetricDiff
    let waist: MetricDiff
    let abdomen: MetricDiff
    let hips: MetricDiff
    let rightThigh: MetricDiff
    let leftThigh: MetricDiff
    let rightCalf: MetricDiff
    let leftCalf: MetricDiff

    init(a: CircumferencesSnapshot?, b: CircumferencesSnapshot?) {
        neck         = MetricDiff(before: a?.neck,         after: b?.neck)
        shoulders    = MetricDiff(before: a?.shoulders,    after: b?.shoulders)
        chest        = MetricDiff(before: a?.chest,        after: b?.chest)
        rightArm     = MetricDiff(before: a?.rightArm,     after: b?.rightArm)
        leftArm      = MetricDiff(before: a?.leftArm,      after: b?.leftArm)
        rightForearm = MetricDiff(before: a?.rightForearm, after: b?.rightForearm)
        leftForearm  = MetricDiff(before: a?.leftForearm,  after: b?.leftForearm)
        waist        = MetricDiff(before: a?.waist,        after: b?.waist)
        abdomen      = MetricDiff(before: a?.abdomen,      after: b?.abdomen)
        hips         = MetricDiff(before: a?.hips,         after: b?.hips)
        rightThigh   = MetricDiff(before: a?.rightThigh,   after: b?.rightThigh)
        leftThigh    = MetricDiff(before: a?.leftThigh,    after: b?.leftThigh)
        rightCalf    = MetricDiff(before: a?.rightCalf,    after: b?.rightCalf)
        leftCalf     = MetricDiff(before: a?.leftCalf,     after: b?.leftCalf)
    }
}
