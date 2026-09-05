//
//  AnthropometryExtendedViewModel.swift
//  GYM APP
//
//  Handles ISAK breadth/depth (Level 1 + 2) and length/height (Level 2) measurements.
//  ISAK-specific extensions to existing measurements (iliacCrest, supraspinale, armFlexedTensed,
//  sittingHeight, armSpan) live in their respective existing ViewModels, not here.

import SwiftUI

@MainActor @Observable
final class AnthropometryExtendedViewModel {

    // MARK: - Breadths / Depths (cm) — Level 1 (3 sites)

    var humerusText: String = ""   // Diám. biepicondilar húmero
    var femurText: String   = ""   // Diám. biepicondilar fémur
    var footText: String    = ""   // Anchura del pie (Level 1, 3rd breadth)

    // MARK: - Breadths / Depths (cm) — Level 2 additional (6 sites)

    var biacromialText: String        = ""
    var bicristalText: String         = ""
    var chestTransverseText: String   = ""
    var chestDepthText: String        = ""
    var ankleText: String             = ""
    var wristBreadthText: String      = ""

    // MARK: - Lengths / Heights (cm) — Level 2 only (9 sites)

    var acromialeRadialeText: String      = ""
    var radialeStylionText: String        = ""
    var midstylionDactylionText: String   = ""
    var iliospinaleHeightText: String     = ""
    var trochanterionHeightText: String   = ""
    var trochTibLatText: String           = ""
    var tibialeLateraleHeightText: String = ""
    var tibSphyrionText: String           = ""
    var footLengthText: String            = ""

    // MARK: - Init

    init(
        existingBreadths: ISAKBreadthsMeasurements? = nil,
        existingLengths: ISAKLengthsMeasurements? = nil
    ) {
        if let b = existingBreadths {
            humerusText        = b.humerusBiepicondylar.map { fmt($0) } ?? ""
            femurText          = b.femurBiepicondylar.map   { fmt($0) } ?? ""
            footText           = b.footBreadth.map           { fmt($0) } ?? ""
            biacromialText     = b.biacromialBreadth.map     { fmt($0) } ?? ""
            bicristalText      = b.bicristalBreadth.map      { fmt($0) } ?? ""
            chestTransverseText = b.chestTransverseBreadth.map { fmt($0) } ?? ""
            chestDepthText     = b.chestDepthAP.map          { fmt($0) } ?? ""
            ankleText          = b.ankleBiepicondylar.map    { fmt($0) } ?? ""
            wristBreadthText   = b.wristBiepicondylar.map    { fmt($0) } ?? ""
        }
        if let l = existingLengths {
            acromialeRadialeText      = l.acromialeRadiale.map               { fmt($0) } ?? ""
            radialeStylionText        = l.radialeStylion.map                 { fmt($0) } ?? ""
            midstylionDactylionText   = l.midstylionDactylion.map            { fmt($0) } ?? ""
            iliospinaleHeightText     = l.iliospinaleHeight.map              { fmt($0) } ?? ""
            trochanterionHeightText   = l.trochanterionHeight.map            { fmt($0) } ?? ""
            trochTibLatText           = l.trochanterionTibialeLaterale.map   { fmt($0) } ?? ""
            tibialeLateraleHeightText = l.tibialeLateraleHeight.map          { fmt($0) } ?? ""
            tibSphyrionText           = l.tibialeLateraleSphyrionTibiale.map { fmt($0) } ?? ""
            footLengthText            = l.footLength.map                     { fmt($0) } ?? ""
        }
    }

    // MARK: - Completion

    var hasBreadths: Bool {
        [humerusText, femurText, footText].contains { $0.asPositiveDouble != nil }
    }

    var hasLengths: Bool {
        [acromialeRadialeText, radialeStylionText, midstylionDactylionText,
         iliospinaleHeightText, trochanterionHeightText, trochTibLatText,
         tibialeLateraleHeightText, tibSphyrionText, footLengthText
        ].contains { $0.asPositiveDouble != nil }
    }

    var filledLevel1BreadthCount: Int {
        [humerusText, femurText, footText].compactMap { $0.asPositiveDouble }.count
    }

    var filledLevel2BreadthCount: Int {
        [biacromialText, bicristalText, chestTransverseText,
         chestDepthText, ankleText, wristBreadthText
        ].compactMap { $0.asPositiveDouble }.count
    }

    var filledLengthCount: Int {
        [acromialeRadialeText, radialeStylionText, midstylionDactylionText,
         iliospinaleHeightText, trochanterionHeightText, trochTibLatText,
         tibialeLateraleHeightText, tibSphyrionText, footLengthText
        ].compactMap { $0.asPositiveDouble }.count
    }

    // MARK: - Save (standalone form — commits immediately)

    // Throws on repository failure so CheckInWorkflowViewModel can handle it.
    func saveBreadths(for checkIn: CheckIn, using repository: ISAKBreadthsRepository) throws {
        guard hasBreadths else { return }
        let b = ISAKBreadthsMeasurements()
        applyBreadthFields(to: b)
        try repository.save(b, for: checkIn)
    }

    func saveLengths(for checkIn: CheckIn, using repository: ISAKLengthsRepository) throws {
        guard hasLengths else { return }
        let l = ISAKLengthsMeasurements()
        applyLengthFields(to: l)
        try repository.save(l, for: checkIn)
    }

    // MARK: - Insert-only (workflow creation path — no commit)

    func insertBreadths(for checkIn: CheckIn, using repository: ISAKBreadthsRepository) {
        guard hasBreadths else { return }
        let b = ISAKBreadthsMeasurements()
        applyBreadthFields(to: b)
        repository.insertNew(b, for: checkIn)
    }

    func insertLengths(for checkIn: CheckIn, using repository: ISAKLengthsRepository) {
        guard hasLengths else { return }
        let l = ISAKLengthsMeasurements()
        applyLengthFields(to: l)
        repository.insertNew(l, for: checkIn)
    }

    // MARK: - Helpers

    private func applyBreadthFields(to b: ISAKBreadthsMeasurements) {
        b.humerusBiepicondylar    = humerusText.asPositiveDouble
        b.femurBiepicondylar      = femurText.asPositiveDouble
        b.footBreadth             = footText.asPositiveDouble
        b.biacromialBreadth       = biacromialText.asPositiveDouble
        b.bicristalBreadth        = bicristalText.asPositiveDouble
        b.chestTransverseBreadth  = chestTransverseText.asPositiveDouble
        b.chestDepthAP            = chestDepthText.asPositiveDouble
        b.ankleBiepicondylar      = ankleText.asPositiveDouble
        b.wristBiepicondylar      = wristBreadthText.asPositiveDouble
    }

    private func applyLengthFields(to l: ISAKLengthsMeasurements) {
        l.acromialeRadiale               = acromialeRadialeText.asPositiveDouble
        l.radialeStylion                 = radialeStylionText.asPositiveDouble
        l.midstylionDactylion            = midstylionDactylionText.asPositiveDouble
        l.iliospinaleHeight              = iliospinaleHeightText.asPositiveDouble
        l.trochanterionHeight            = trochanterionHeightText.asPositiveDouble
        l.trochanterionTibialeLaterale   = trochTibLatText.asPositiveDouble
        l.tibialeLateraleHeight          = tibialeLateraleHeightText.asPositiveDouble
        l.tibialeLateraleSphyrionTibiale = tibSphyrionText.asPositiveDouble
        l.footLength                     = footLengthText.asPositiveDouble
    }

    private func fmt(_ v: Double) -> String { String(format: "%.2f", v) }
}
