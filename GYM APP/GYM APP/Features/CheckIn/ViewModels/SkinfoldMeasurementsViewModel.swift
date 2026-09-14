//
//  SkinfoldMeasurementsViewModel.swift
//  GYM APP
//

import SwiftUI

@MainActor @Observable
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

    // ISAK-specific sites (anatomically distinct from suprailiac above)
    var iliacCrestText: String  = ""   // Cresta ilíaca ISAK
    var supraspinaleText: String = ""  // Supraespinal ISAK

    // MARK: - Private

    private let existingMeasurements: SkinfoldMeasurements?
    private let gender: Gender
    private let age: Double          // years
    var bodyWeightKg: Double?        // updatable so workflow can sync body weight for Parrillo

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
        chestText        = m.chest.map        { format($0) } ?? ""
        midaxillaryText  = m.midaxillary.map  { format($0) } ?? ""
        tricepText       = m.tricep.map       { format($0) } ?? ""
        subscapularText  = m.subscapular.map  { format($0) } ?? ""
        abdomenText      = m.abdomen.map      { format($0) } ?? ""
        suprailiacText   = m.suprailiac.map   { format($0) } ?? ""
        thighText        = m.thigh.map        { format($0) } ?? ""
        calfText         = m.calf.map         { format($0) } ?? ""
        bicepText        = m.bicep.map        { format($0) } ?? ""
        lowerBackText    = m.lowerBack.map    { format($0) } ?? ""
        iliacCrestText   = m.iliacCrest.map   { format($0) } ?? ""
        supraspinaleText = m.supraspinale.map { format($0) } ?? ""
        testerText       = m.tester ?? ""
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

    // MARK: - ISAK 8-site labels (separate from formula-based requiredSiteLabels)

    var requiredISAKSiteLabels: [(label: String, binding: WritableKeyPath<SkinfoldMeasurementsViewModel, String>)] {
        [
            ("Tríceps",            \.tricepText),
            ("Subescapular",       \.subscapularText),
            ("Bíceps",             \.bicepText),
            ("Cresta ilíaca",      \.iliacCrestText),
            ("Supraespinal",       \.supraspinaleText),
            ("Abdominal",          \.abdomenText),
            ("Muslo anterior",     \.thighText),
            ("Pantorrilla medial", \.calfText),
        ]
    }

    var hasISAKSkinfolds: Bool {
        requiredISAKSiteLabels.contains { $0.binding != \.iliacCrestText && $0.binding != \.supraspinaleText
            ? self[keyPath: $0.binding].asPositiveDouble != nil
            : true
        } && (iliacCrestText.asPositiveDouble != nil || supraspinaleText.asPositiveDouble != nil)
    }

    var filledISAKSiteCount: Int {
        requiredISAKSiteLabels.compactMap { self[keyPath: $0.binding].asPositiveDouble }.count
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

    // MARK: - Save (standalone form — commits immediately)

    // Returns true on success.
    // Throws on repository failure so the caller (CheckInWorkflowViewModel) can handle it.
    @discardableResult
    func save(for checkIn: CheckIn, using repository: SkinfoldMeasurementsRepository) throws -> Bool {
        guard let result = calculationResult else { return false }
        let m = existingMeasurements ?? SkinfoldMeasurements(method: method)
        applyFields(to: m, result: result)
        try repository.save(m, for: checkIn)
        return true
    }

    // MARK: - Insert-only (workflow creation path — no commit)

    // allowWithoutFormula: pass true for ISAK profiles, where calculationResult is nil
    // because ISAK site sets don't map to any supported formula. The raw site measurements
    // must still be persisted; bodyDensity/estimatedBodyFatPercentage remain nil.
    @discardableResult
    func insertRecord(
        for checkIn: CheckIn,
        using repository: SkinfoldMeasurementsRepository,
        allowWithoutFormula: Bool = false
    ) -> Bool {
        let result = calculationResult
        guard result != nil || allowWithoutFormula else { return false }
        let m = existingMeasurements ?? SkinfoldMeasurements(method: method)
        applyFields(to: m, result: result)
        repository.insertNew(m, for: checkIn)
        return true
    }

    // MARK: - Helpers

    private func applyFields(to m: SkinfoldMeasurements, result: SkinfoldCalculator.Result?) {
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
        m.iliacCrest   = iliacCrestText.asPositiveDouble
        m.supraspinale = supraspinaleText.asPositiveDouble
        m.tester       = testerText.isEmpty ? nil : testerText
        m.caliperBrand = caliperBrandText.isEmpty ? nil : caliperBrandText
        m.bodyDensity               = result?.bodyDensity
        m.estimatedBodyFatPercentage = result?.bodyFatPercentage
    }

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
