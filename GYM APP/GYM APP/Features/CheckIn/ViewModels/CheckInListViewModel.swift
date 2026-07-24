//
//  CheckInListViewModel.swift
//  GYM APP
//

import SwiftUI

@Observable
final class CheckInListViewModel {
    var isShowingCreateSheet: Bool = false
    var checkInToEdit: CheckIn?   = nil
    var isShowingEditSheet: Bool  = false
    var checkInToDelete: CheckIn? = nil
    var isShowingDeleteAlert: Bool = false

    func sorted(_ checkIns: [CheckIn]) -> [CheckIn] {
        checkIns.sorted { $0.date > $1.date }
    }

    func requestCreate() {
        isShowingCreateSheet = true
    }

    func requestEdit(_ checkIn: CheckIn) {
        checkInToEdit    = checkIn
        isShowingEditSheet = true
    }

    func requestDelete(_ checkIn: CheckIn) {
        checkInToDelete      = checkIn
        isShowingDeleteAlert = true
    }

    func confirmDelete(using repository: CheckInRepository) {
        guard let checkIn = checkInToDelete else { return }
        try? repository.delete(checkIn)
        checkInToDelete = nil
    }

    func cancelDelete() {
        checkInToDelete      = nil
        isShowingDeleteAlert = false
    }
}
