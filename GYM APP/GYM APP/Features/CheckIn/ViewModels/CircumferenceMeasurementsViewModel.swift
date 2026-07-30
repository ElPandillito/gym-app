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
        allTexts.contains { $0.asPositiveDouble != nil }
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

        measurements.neck         = neckText.asPositiveDouble
        measurements.shoulders    = shouldersText.asPositiveDouble
        measurements.chest        = chestText.asPositiveDouble
        measurements.rightArm     = rightArmText.asPositiveDouble
        measurements.leftArm      = leftArmText.asPositiveDouble
        measurements.rightForearm = rightForearmText.asPositiveDouble
        measurements.leftForearm  = leftForearmText.asPositiveDouble
        measurements.waist        = waistText.asPositiveDouble
        measurements.abdomen      = abdomenText.asPositiveDouble
        measurements.hips         = hipsText.asPositiveDouble
        measurements.rightThigh   = rightThighText.asPositiveDouble
        measurements.leftThigh    = leftThighText.asPositiveDouble
        measurements.rightCalf    = rightCalfText.asPositiveDouble
        measurements.leftCalf     = leftCalfText.asPositiveDouble

        try? repository.save(measurements, for: checkIn)
        return true
    }
}
