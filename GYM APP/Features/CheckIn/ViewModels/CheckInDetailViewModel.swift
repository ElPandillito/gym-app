//
//  CheckInDetailViewModel.swift
//  GYM APP
//

import SwiftUI

@MainActor @Observable
final class CheckInDetailViewModel {
    var isShowingEditSheet: Bool          = false
    var isShowingBodyMetricsForm: Bool    = false
    var isShowingCircumferencesForm: Bool = false
    var isShowingSkinfoldForm: Bool       = false
    var isShowingComparison: Bool         = false
    var isShowingNotesEdit: Bool          = false
}
