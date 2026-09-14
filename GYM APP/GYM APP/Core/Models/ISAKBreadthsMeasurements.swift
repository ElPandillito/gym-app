//
//  ISAKBreadthsMeasurements.swift
//  GYM APP
//
//  Breadth and depth measurements for ISAK Level 1 (3 sites) and Level 2 (9 sites).
//  All values in centimeters.
//
//  TEM architecture: each measured site has trial1 / trial2 companion fields.
//  The primary field stores the recorded (final) value.
//  TEM calculation and quality-control UI are deferred to a future phase.

import SwiftData
import Foundation

@Model
final class ISAKBreadthsMeasurements {
    @Attribute(.unique) var id: UUID

    // MARK: Level 1 breadths (3) — cm

    var humerusBiepicondylar: Double?   // Diám. biepicondilar húmero
    var humerusTrial1: Double?
    var humerusTrial2: Double?

    var femurBiepicondylar: Double?     // Diám. biepicondilar fémur
    var femurTrial1: Double?
    var femurTrial2: Double?

    // Third Level 1 breadth per ISAK course materials. Verify against ISAK manual.
    var footBreadth: Double?            // Anchura del pie
    var footTrial1: Double?
    var footTrial2: Double?

    // MARK: Level 2 additional breadths/depths (6) — cm

    var biacromialBreadth: Double?       // Diám. biacromial
    var bicristalBreadth: Double?        // Diám. bicristal
    var chestTransverseBreadth: Double?  // Diám. torácico transverso
    var chestDepthAP: Double?            // Prof. torácica anteroposterior
    var ankleBiepicondylar: Double?      // Diám. biepicondilar tobillo
    var wristBiepicondylar: Double?      // Diám. biepicondilar muñeca

    // MARK: Context

    var tester: String?
    var instrumentBrand: String?

    var createdAt: Date
    var updatedAt: Date

    var checkIn: CheckIn?

    init() {
        self.id        = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
