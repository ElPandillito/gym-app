//
//  ISAKLengthsMeasurements.swift
//  GYM APP
//
//  Segment lengths and heights for ISAK Level 2 (Full Profile). All values in centimeters.

import SwiftData
import Foundation

@Model
final class ISAKLengthsMeasurements {
    @Attribute(.unique) var id: UUID

    // MARK: Segment lengths (6) — cm

    var acromialeRadiale: Double?               // Long. acromial-radial (upper arm)
    var radialeStylion: Double?                 // Long. radial-estilión (forearm)
    var midstylionDactylion: Double?            // Long. medioestilión-dactilión (hand)
    var trochanterionTibialeLaterale: Double?   // Long. trocánterea-tibial lat. (thigh)
    var tibialeLateraleSphyrionTibiale: Double? // Long. tibial lat.-sfirión tibial (lower leg)
    var footLength: Double?                     // Longitud del pie

    // MARK: Heights from floor (3) — cm

    var iliospinaleHeight: Double?              // Altura ilioespinal
    var trochanterionHeight: Double?            // Altura trocantérea
    var tibialeLateraleHeight: Double?          // Altura tibial lateral

    var createdAt: Date
    var updatedAt: Date

    var checkIn: CheckIn?

    init() {
        self.id        = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
