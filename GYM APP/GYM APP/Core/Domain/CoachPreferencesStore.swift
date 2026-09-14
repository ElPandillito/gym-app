//
//  CoachPreferencesStore.swift
//  GYM APP
//
//  Observable store for CoachPreferences backed by UserDefaults.
//  Inject at root via .environment(CoachPreferencesStore()); read with
//  @Environment(CoachPreferencesStore.self).
//

import SwiftUI

@MainActor @Observable
final class CoachPreferencesStore {

    // MARK: - Stored preferences (UserDefaults-backed)

    var inactivityThresholdDays: Int = 14 {
        didSet { UserDefaults.standard.set(inactivityThresholdDays, forKey: Keys.inactivityDays) }
    }

    var trendWindowDays: Int = 60 {
        didSet { UserDefaults.standard.set(trendWindowDays, forKey: Keys.trendWindowDays) }
    }

    var progressWindowDays: Int = 30 {
        didSet { UserDefaults.standard.set(progressWindowDays, forKey: Keys.progressWindowDays) }
    }

    var maxAlertsShown: Int = 10 {
        didSet { UserDefaults.standard.set(maxAlertsShown, forKey: Keys.maxAlertsShown) }
    }

    var showInactiveAlerts: Bool = true {
        didSet { UserDefaults.standard.set(showInactiveAlerts, forKey: Keys.showInactive) }
    }

    var showPhotoAlerts: Bool = true {
        didSet { UserDefaults.standard.set(showPhotoAlerts, forKey: Keys.showPhoto) }
    }

    var showMetricAlerts: Bool = true {
        didSet { UserDefaults.standard.set(showMetricAlerts, forKey: Keys.showMetric) }
    }

    var preferredWeightUnit: WeightUnit = .kg {
        didSet { UserDefaults.standard.set(preferredWeightUnit.rawValue, forKey: Keys.weightUnit) }
    }

    var preferredLengthUnit: LengthUnit = .cm {
        didSet { UserDefaults.standard.set(preferredLengthUnit.rawValue, forKey: Keys.lengthUnit) }
    }

    // MARK: - Computed CoachPreferences snapshot

    var preferences: CoachPreferences {
        CoachPreferences(
            inactivityThresholdDays: inactivityThresholdDays,
            trendWindowDays:         trendWindowDays,
            progressWindowDays:      progressWindowDays,
            maxAlertsShown:          maxAlertsShown,
            showInactiveAlerts:      showInactiveAlerts,
            showPhotoAlerts:         showPhotoAlerts,
            showMetricAlerts:        showMetricAlerts,
            preferredWeightUnit:     preferredWeightUnit,
            preferredLengthUnit:     preferredLengthUnit,
            dashboardFilter:         .all
        )
    }

    // MARK: - Init (reads from UserDefaults)

    init() {
        let d = UserDefaults.standard
        if let v = d.object(forKey: Keys.inactivityDays)    as? Int    { inactivityThresholdDays = v }
        if let v = d.object(forKey: Keys.trendWindowDays)   as? Int    { trendWindowDays = v }
        if let v = d.object(forKey: Keys.progressWindowDays) as? Int   { progressWindowDays = v }
        if let v = d.object(forKey: Keys.maxAlertsShown)    as? Int    { maxAlertsShown = v }
        if let v = d.object(forKey: Keys.showInactive)      as? Bool   { showInactiveAlerts = v }
        if let v = d.object(forKey: Keys.showPhoto)         as? Bool   { showPhotoAlerts = v }
        if let v = d.object(forKey: Keys.showMetric)        as? Bool   { showMetricAlerts = v }
        if let raw = d.string(forKey: Keys.weightUnit),
           let unit = WeightUnit(rawValue: raw)                         { preferredWeightUnit = unit }
        if let raw = d.string(forKey: Keys.lengthUnit),
           let unit = LengthUnit(rawValue: raw)                        { preferredLengthUnit = unit }
    }

    // MARK: - Reset to defaults

    func resetToDefaults() {
        inactivityThresholdDays = 14
        trendWindowDays         = 60
        progressWindowDays      = 30
        maxAlertsShown          = 10
        showInactiveAlerts      = true
        showPhotoAlerts         = true
        showMetricAlerts        = true
        preferredWeightUnit     = .kg
        preferredLengthUnit     = .cm
    }

    // MARK: - UserDefaults keys

    private enum Keys {
        static let inactivityDays     = "pref_inactivityDays"
        static let trendWindowDays    = "pref_trendWindowDays"
        static let progressWindowDays = "pref_progressWindowDays"
        static let maxAlertsShown     = "pref_maxAlertsShown"
        static let showInactive       = "pref_showInactiveAlerts"
        static let showPhoto          = "pref_showPhotoAlerts"
        static let showMetric         = "pref_showMetricAlerts"
        static let weightUnit         = "pref_weightUnit"
        static let lengthUnit         = "pref_lengthUnit"
    }
}
