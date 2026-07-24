//
//  CircumferenceMeasurementsViewModel.swift
//  GYM APP
//

import SwiftUI

@Observable
final class CircumferenceMeasurementsViewModel {

    // Torso
    var neckText: String      = ""
    var shouldersText: String = ""
    var chestText: String     = ""

    // Arms
    var rightArmText: String     = ""
    var leftArmText: String      = ""
    var rightForearmText: String = ""
    var leftForearmText: String  = ""

    // Trunk
    var waistText: String   = ""
    var abdomenText: String = ""
    var hipsText: String    = ""

    // Legs
    var rightThighText: String = ""
    var leftThighText: String  = ""
    var rightCalfText: String  = ""
    var leftCalfText: String   = ""

    private let existingMeasurements: CircumferenceMeasurements?

    var isEditing: Bool { existingMeasurements != nil }

    // At least one measurement must be entered to save
    var canSave: Bool {
        allTexts.contains { parseDouble($0) != nil }
    }

    private var allTexts: [String] {
        [neckText, shouldersText, chestText,
         rightArmText, leftArmText, rightForearmText, leftForearmText,
         waistText, abdomenText, hipsText,
         rightThighText, leftThighText, rightCalfText, leftCalfText]
    }

    init(measurements: CircumferenceMeasurements? = nil) {
        self.existingMeasurements = measurements
        guard let m = measurements else { return }

        neckText          = m.neck.map          { String(format: "%.1f", $0) } ?? ""
        shouldersText     = m.shoulders.map     { String(format: "%.1f", $0) } ?? ""
        chestText         = m.chest.map         { String(format: "%.1f", $0) } ?? ""
        rightArmText      = m.rightArm.map      { String(format: "%.1f", $0) } ?? ""
        leftArmText       = m.leftArm.map       { String(format: "%.1f", $0) } ?? ""
        rightForearmText  = m.rightForearm.map  { String(format: "%.1f", $0) } ?? ""
        leftForearmText   = m.leftForearm.map   { String(format: "%.1f", $0) } ?? ""
        waistText         = m.waist.map         { String(format: "%.1f", $0) } ?? ""
        abdomenText       = m.abdomen.map       { String(format: "%.1f", $0) } ?? ""
        hipsText          = m.hips.map          { String(format: "%.1f", $0) } ?? ""
        rightThighText    = m.rightThigh.map    { String(format: "%.1f", $0) } ?? ""
        leftThighText     = m.leftThigh.map     { String(format: "%.1f", $0) } ?? ""
        rightCalfText     = m.rightCalf.map     { String(format: "%.1f", $0) } ?? ""
        leftCalfText      = m.leftCalf.map      { String(format: "%.1f", $0) } ?? ""
    }

    // Returns true on success. Creates a new CircumferenceMeasurements if none exists yet.
    func save(for checkIn: CheckIn, using repository: CircumferenceMeasurementsRepository) -> Bool {
        guard canSave else { return false }
        let measurements = existingMeasurements ?? CircumferenceMeasurements()

        measurements.neck         = parseDouble(neckText)
        measurements.shoulders    = parseDouble(shouldersText)
        measurements.chest        = parseDouble(chestText)
        measurements.rightArm     = parseDouble(rightArmText)
        measurements.leftArm      = parseDouble(leftArmText)
        measurements.rightForearm = parseDouble(rightForearmText)
        measurements.leftForearm  = parseDouble(leftForearmText)
        measurements.waist        = parseDouble(waistText)
        measurements.abdomen      = parseDouble(abdomenText)
        measurements.hips         = parseDouble(hipsText)
        measurements.rightThigh   = parseDouble(rightThighText)
        measurements.leftThigh    = parseDouble(leftThighText)
        measurements.rightCalf    = parseDouble(rightCalfText)
        measurements.leftCalf     = parseDouble(leftCalfText)

        try? repository.save(measurements, for: checkIn)
        return true
    }

    private func parseDouble(_ text: String) -> Double? {
        let cleaned = text.trimmingCharacters(in: .whitespaces)
                         .replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty, let val = Double(cleaned), val > 0 else { return nil }
        return val
    }
}
