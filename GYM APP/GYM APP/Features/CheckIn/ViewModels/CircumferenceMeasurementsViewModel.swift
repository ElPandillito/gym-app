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
    private var preferences: CoachPreferences = .default

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

    // MARK: - Apply preferences (call once from onAppear)

    /// Stores preferences and re-formats all circumference fields from canonical cm to display units.
    /// For new check-ins (no existing measurements) this only stores preferences for use at save time.
    func apply(preferences: CoachPreferences) {
        self.preferences = preferences
        guard let m = existingMeasurements else { return }
        let fmt = AppUnitFormatter(preferences: preferences)
        neckText            = m.neck.map            { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        shouldersText       = m.shoulders.map       { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        chestText           = m.chest.map           { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        rightArmText        = m.rightArm.map        { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        leftArmText         = m.leftArm.map         { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        rightForearmText    = m.rightForearm.map    { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        leftForearmText     = m.leftForearm.map     { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        waistText           = m.waist.map           { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        abdomenText         = m.abdomen.map         { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        hipsText            = m.hips.map            { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        rightThighText      = m.rightThigh.map      { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        leftThighText       = m.leftThigh.map       { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        rightCalfText       = m.rightCalf.map       { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        leftCalfText        = m.leftCalf.map        { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        armFlexedTensedText = m.armFlexedTensed.map { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        headGirthText       = m.headGirth.map       { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        wristGirthText      = m.wristGirth.map      { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        ankleGirthText      = m.ankleGirth.map      { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
        midThighGirthText   = m.midThighGirth.map   { String(format: "%.1f", fmt.convertedLength($0)) } ?? ""
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
        let fmt = AppUnitFormatter(preferences: preferences)
        m.neck            = neckText.asPositiveDouble.map            { fmt.toCanonicalLength($0) }
        m.shoulders       = shouldersText.asPositiveDouble.map       { fmt.toCanonicalLength($0) }
        m.chest           = chestText.asPositiveDouble.map           { fmt.toCanonicalLength($0) }
        m.rightArm        = rightArmText.asPositiveDouble.map        { fmt.toCanonicalLength($0) }
        m.leftArm         = leftArmText.asPositiveDouble.map         { fmt.toCanonicalLength($0) }
        m.rightForearm    = rightForearmText.asPositiveDouble.map    { fmt.toCanonicalLength($0) }
        m.leftForearm     = leftForearmText.asPositiveDouble.map     { fmt.toCanonicalLength($0) }
        m.waist           = waistText.asPositiveDouble.map           { fmt.toCanonicalLength($0) }
        m.abdomen         = abdomenText.asPositiveDouble.map         { fmt.toCanonicalLength($0) }
        m.hips            = hipsText.asPositiveDouble.map            { fmt.toCanonicalLength($0) }
        m.rightThigh      = rightThighText.asPositiveDouble.map      { fmt.toCanonicalLength($0) }
        m.leftThigh       = leftThighText.asPositiveDouble.map       { fmt.toCanonicalLength($0) }
        m.rightCalf       = rightCalfText.asPositiveDouble.map       { fmt.toCanonicalLength($0) }
        m.leftCalf        = leftCalfText.asPositiveDouble.map        { fmt.toCanonicalLength($0) }
        m.armFlexedTensed = armFlexedTensedText.asPositiveDouble.map { fmt.toCanonicalLength($0) }
        m.headGirth       = headGirthText.asPositiveDouble.map       { fmt.toCanonicalLength($0) }
        m.wristGirth      = wristGirthText.asPositiveDouble.map      { fmt.toCanonicalLength($0) }
        m.ankleGirth      = ankleGirthText.asPositiveDouble.map      { fmt.toCanonicalLength($0) }
        m.midThighGirth   = midThighGirthText.asPositiveDouble.map   { fmt.toCanonicalLength($0) }
    }
}
