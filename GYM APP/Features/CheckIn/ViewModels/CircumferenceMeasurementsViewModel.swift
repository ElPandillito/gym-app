//
//  CircumferenceMeasurementsViewModel.swift
//  GYM APP
//

import SwiftUI

@MainActor @Observable
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

    // ISAK Level 1 girth (arm flexed and tensed)
    var armFlexedTensedText: String = ""

    // ISAK Level 2 additional girths
    var headGirthText: String   = ""
    var wristGirthText: String  = ""
    var ankleGirthText: String  = ""
    var midThighGirthText: String = ""
    // g_neck → existing neckText; g_chest → existing chestText; g_forearm_max → existing rightForearmText

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
         rightThighText, leftThighText, rightCalfText, leftCalfText,
         armFlexedTensedText, headGirthText, wristGirthText, ankleGirthText, midThighGirthText]
    }

    init(measurements: CircumferenceMeasurements? = nil) {
        self.existingMeasurements = measurements
        guard let m = measurements else { return }

        neckText           = m.neck.map            { String(format: "%.1f", $0) } ?? ""
        shouldersText      = m.shoulders.map       { String(format: "%.1f", $0) } ?? ""
        chestText          = m.chest.map           { String(format: "%.1f", $0) } ?? ""
        rightArmText       = m.rightArm.map        { String(format: "%.1f", $0) } ?? ""
        leftArmText        = m.leftArm.map         { String(format: "%.1f", $0) } ?? ""
        rightForearmText   = m.rightForearm.map    { String(format: "%.1f", $0) } ?? ""
        leftForearmText    = m.leftForearm.map     { String(format: "%.1f", $0) } ?? ""
        waistText          = m.waist.map           { String(format: "%.1f", $0) } ?? ""
        abdomenText        = m.abdomen.map         { String(format: "%.1f", $0) } ?? ""
        hipsText           = m.hips.map            { String(format: "%.1f", $0) } ?? ""
        rightThighText     = m.rightThigh.map      { String(format: "%.1f", $0) } ?? ""
        leftThighText      = m.leftThigh.map       { String(format: "%.1f", $0) } ?? ""
        rightCalfText      = m.rightCalf.map       { String(format: "%.1f", $0) } ?? ""
        leftCalfText       = m.leftCalf.map        { String(format: "%.1f", $0) } ?? ""
        armFlexedTensedText = m.armFlexedTensed.map { String(format: "%.1f", $0) } ?? ""
        headGirthText      = m.headGirth.map       { String(format: "%.1f", $0) } ?? ""
        wristGirthText     = m.wristGirth.map      { String(format: "%.1f", $0) } ?? ""
        ankleGirthText     = m.ankleGirth.map      { String(format: "%.1f", $0) } ?? ""
        midThighGirthText  = m.midThighGirth.map   { String(format: "%.1f", $0) } ?? ""
    }

    // MARK: - Save (standalone form — commits immediately)

    // Returns true on success. Creates a new CircumferenceMeasurements if none exists yet.
    // Throws on repository failure so the caller (CheckInWorkflowViewModel) can handle it.
    @discardableResult
    func save(for checkIn: CheckIn, using repository: CircumferenceMeasurementsRepository) throws -> Bool {
        guard canSave else { return false }
        let measurements = existingMeasurements ?? CircumferenceMeasurements()
        applyFields(to: measurements)
        try repository.save(measurements, for: checkIn)
        return true
    }

    // MARK: - Insert-only (workflow creation path — no commit)

    @discardableResult
    func insertRecord(for checkIn: CheckIn, using repository: CircumferenceMeasurementsRepository) -> Bool {
        guard canSave else { return false }
        let measurements = existingMeasurements ?? CircumferenceMeasurements()
        applyFields(to: measurements)
        repository.insertNew(measurements, for: checkIn)
        return true
    }

    // MARK: - Helpers

    private func applyFields(to m: CircumferenceMeasurements) {
        m.neck           = neckText.asPositiveDouble
        m.shoulders      = shouldersText.asPositiveDouble
        m.chest          = chestText.asPositiveDouble
        m.rightArm       = rightArmText.asPositiveDouble
        m.leftArm        = leftArmText.asPositiveDouble
        m.rightForearm   = rightForearmText.asPositiveDouble
        m.leftForearm    = leftForearmText.asPositiveDouble
        m.waist          = waistText.asPositiveDouble
        m.abdomen        = abdomenText.asPositiveDouble
        m.hips           = hipsText.asPositiveDouble
        m.rightThigh     = rightThighText.asPositiveDouble
        m.leftThigh      = leftThighText.asPositiveDouble
        m.rightCalf      = rightCalfText.asPositiveDouble
        m.leftCalf       = leftCalfText.asPositiveDouble
        m.armFlexedTensed = armFlexedTensedText.asPositiveDouble
        m.headGirth      = headGirthText.asPositiveDouble
        m.wristGirth     = wristGirthText.asPositiveDouble
        m.ankleGirth     = ankleGirthText.asPositiveDouble
        m.midThighGirth  = midThighGirthText.asPositiveDouble
    }
}
