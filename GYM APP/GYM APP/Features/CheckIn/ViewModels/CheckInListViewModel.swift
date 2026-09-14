//
//  CheckInListViewModel.swift
//  GYM APP
//

import SwiftUI
import OSLog

@MainActor @Observable
final class CheckInListViewModel {
    var isShowingCreateSheet: Bool = false
    var checkInToEdit: CheckIn?   = nil
    var isShowingEditSheet: Bool  = false
    var checkInToDelete: CheckIn? = nil
    var isShowingDeleteAlert: Bool = false
    var deleteError: String?      = nil

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
        isShowingDeleteAlert = false
        deleteError = nil
        do {
            try repository.delete(checkIn)
        } catch {
            deleteError = "No se pudo eliminar el check in. Inténtalo de nuevo."
            AppLogger.persistence.error("CheckIn delete failed")
        }
        checkInToDelete = nil
    }

    func cancelDelete() {
        checkInToDelete      = nil
        isShowingDeleteAlert = false
    }
}
