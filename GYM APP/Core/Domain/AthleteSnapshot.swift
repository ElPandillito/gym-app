//
//  AthleteSnapshot.swift
//  GYM APP
//

import Foundation

/// Immutable value-type mirror of Athlete — free of SwiftData dependencies.
/// Used by Engines so they remain testable without a ModelContainer.
struct AthleteSnapshot: Sendable {
    let id: UUID
    let name: String
    let gender: Gender
    let birthDate: Date?
    let heightCm: Double?

    init(id: UUID, name: String, gender: Gender, birthDate: Date?, heightCm: Double?) {
        self.id        = id
        self.name      = name
        self.gender    = gender
        self.birthDate = birthDate
        self.heightCm  = heightCm
    }

    init(from athlete: Athlete) {
        id        = athlete.id
        name      = athlete.name
        gender    = athlete.gender
        birthDate = athlete.birthDate
        heightCm  = athlete.height
    }

    var ageYears: Double? {
        guard let bd = birthDate else { return nil }
        let years = Calendar.current.dateComponents([.year], from: bd, to: Date()).year ?? 0
        return Double(years)
    }
}

#if DEBUG
extension AthleteSnapshot {
    static func mock(
        id: UUID = UUID(),
        name: String = "Carlos López",
        gender: Gender = .male,
        birthDate: Date? = Calendar.current.date(byAdding: .year, value: -28, to: Date()),
        heightCm: Double? = 175.0
    ) -> AthleteSnapshot {
        AthleteSnapshot(id: id, name: name, gender: gender, birthDate: birthDate, heightCm: heightCm)
    }
}
#endif
