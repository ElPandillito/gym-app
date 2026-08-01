//
//  SkinfoldMeasurementsViewModel.swift
//  GYM APP
//

import SwiftUI

@Observable
final class SkinfoldMeasurementsViewModel {

    // MARK: - Method & context

    var method: PlicometryMethod
    var testerText: String       = ""
    var caliperBrandText: String = ""

    // MARK: - Site text fields (mm)

    var chestText: String       = ""
    var midaxillaryText: String = ""
    var tricepText: String      = ""
    var subscapularText: String = ""
    var abdomenText: String     = ""
    var suprailiacText: String  = ""
    var thighText: String       = ""
    var calfText: String        = ""
    var bicepText: String       = ""
    var lowerBackText: String   = ""

    // MARK: - Private

    private let existingMeasurements: SkinfoldMeasurements?
    private let gender: Gender
    private let age: Double          // years
    private let bodyWeightKg: Double?

    var isEditing: Bool { existingMeasurements != nil }

    // MARK: - Init

    init(
        measurements: SkinfoldMeasurements?,
        gender: Gender,
        age: Double,
        bodyWeightKg: Double?
    ) {
        self.existingMeasurements = measurements
        self.gender               = gender
        self.age                  = age
        self.bodyWeightKg         = bodyWeightKg
        self.method               = measurements?.method ?? .jacksonPollockSeven

        guard let m = measurements else { return }
        chestText       = m.chest.map       { format($0) } ?? ""
        midaxillaryText = m.midaxillary.map { format($0) } ?? ""
        tricepText      = m.tricep.map      { format($0) } ?? ""
        subscapularText = m.subscapular.map { format($0) } ?? ""
        abdomenText     = m.abdomen.map     { format($0) } ?? ""
        suprailiacText  = m.suprailiac.map  { format($0) } ?? ""
        thighText       = m.thigh.map       { format($0) } ?? ""
        calfText        = m.calf.map        { format($0) } ?? ""
        bicepText       = m.bicep.map       { format($0) } ?? ""
        lowerBackText   = m.lowerBack.map   { format($0) } ?? ""
        testerText      = m.tester ?? ""
        caliperBrandText = m.caliperBrand ?? ""
    }

    // MARK: - Required sites per method

    /// Labels for sites required by the current method + gender combination.
    var requiredSiteLabels: [(label: String, binding: WritableKeyPath<SkinfoldMeasurementsViewModel, String>)] {
        switch method {
        case .jacksonPollockThree:
            if gender == .female {
                return [("Trícep", \.tricepText), ("Suprailíaco", \.suprailiacText), ("Muslo", \.thighText)]
            } else {
                return [("Pecho", \.chestText), ("Abdomen", \.abdomenText), ("Muslo", \.thighText)]
            }
        case .jacksonPollockSeven:
            return [
                ("Pecho",        \.chestText),
                ("Axilar medio", \.midaxillaryText),
                ("Trícep",       \.tricepText),
                ("Subescapular", \.subscapularText),
                ("Abdomen",      \.abdomenText),
                ("Suprailíaco",  \.suprailiacText),
                ("Muslo",        \.thighText)
            ]
        case .durninWomersley:
            return [
                ("Bícep",        \.bicepText),
                ("Trícep",       \.tricepText),
                ("Subescapular", \.subscapularText),
                ("Suprailíaco",  \.suprailiacText)
            ]
        case .parrillo:
            return [
                ("Pecho",        \.chestText),
                ("Abdomen",      \.abdomenText),
                ("Muslo",        \.thighText),
                ("Bícep",        \.bicepText),
                ("Trícep",       \.tricepText),
                ("Subescapular", \.subscapularText),
                ("Suprailíaco",  \.suprailiacText),
                ("Lumbar",       \.lowerBackText),
                ("Pantorrilla",  \.calfText)
            ]
        case .custom:
            return []
        }
    }

    // MARK: - Live calculation

    var calculationResult: SkinfoldCalculator.Result? {
        SkinfoldCalculator.calculate(
            method: method,
            gender: gender,
            age: age,
            inputs: currentInputs,
            bodyWeightKg: bodyWeightKg
        )
    }

    var canSave: Bool {
        calculationResult != nil
    }

    // MARK: - Save

    func save(for checkIn: CheckIn, using repository: SkinfoldMeasurementsRepository) -> Bool {
        guard let result = calculationResult else { return false }

        let m = existingMeasurements ?? SkinfoldMeasurements(method: method)
        m.method       = method
        m.chest        = chestText.asPositiveDouble
        m.midaxillary  = midaxillaryText.asPositiveDouble
        m.tricep       = tricepText.asPositiveDouble
        m.subscapular  = subscapularText.asPositiveDouble
        m.abdomen      = abdomenText.asPositiveDouble
        m.suprailiac   = suprailiacText.asPositiveDouble
        m.thigh        = thighText.asPositiveDouble
        m.calf         = calfText.asPositiveDouble
        m.bicep        = bicepText.asPositiveDouble
        m.lowerBack    = lowerBackText.asPositiveDouble
        m.tester       = testerText.isEmpty ? nil : testerText
        m.caliperBrand = caliperBrandText.isEmpty ? nil : caliperBrandText

        // Store immutable calculated results
        m.bodyDensity               = result.bodyDensity
        m.estimatedBodyFatPercentage = result.bodyFatPercentage

        try? repository.save(m, for: checkIn)
        return true
    }

    // MARK: - Helpers

    private var currentInputs: SkinfoldInputs {
        var i = SkinfoldInputs()
        i.chest       = chestText.asPositiveDouble
        i.midaxillary = midaxillaryText.asPositiveDouble
        i.tricep      = tricepText.asPositiveDouble
        i.subscapular = subscapularText.asPositiveDouble
        i.abdomen     = abdomenText.asPositiveDouble
        i.suprailiac  = suprailiacText.asPositiveDouble
        i.thigh       = thighText.asPositiveDouble
        i.calf        = calfText.asPositiveDouble
        i.bicep       = bicepText.asPositiveDouble
        i.lowerBack   = lowerBackText.asPositiveDouble
        return i
    }

    private func format(_ v: Double) -> String { String(format: "%.1f", v) }
}
