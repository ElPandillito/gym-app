//
//  AthleteListViewModel.swift
//  GYM APP
//

import SwiftUI

enum AthleteSortOrder: String, CaseIterable {
    case nameAscending   = "Nombre (A–Z)"
    case nameDescending  = "Nombre (Z–A)"
    case newest          = "Más recientes"
    case oldest          = "Más antiguos"
}

@Observable
final class AthleteListViewModel {
    var searchText: String = ""
    var sortOrder: AthleteSortOrder = .nameAscending
    var isShowingForm: Bool = false
    var athleteToEdit: Athlete? = nil
    var athleteToDelete: Athlete? = nil
    var isShowingDeleteAlert: Bool = false

    func filtered(_ athletes: [Athlete]) -> [Athlete] {
        let searched = searchText.isEmpty
            ? athletes
            : athletes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        return searched.sorted { lhs, rhs in
            switch sortOrder {
            case .nameAscending:
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            case .nameDescending:
                return lhs.name.localizedCompare(rhs.name) == .orderedDescending
            case .newest:
                return lhs.createdAt > rhs.createdAt
            case .oldest:
                return lhs.createdAt < rhs.createdAt
            }
        }
    }

    func addAthlete() {
        athleteToEdit = nil
        isShowingForm = true
    }

    func editAthlete(_ athlete: Athlete) {
        athleteToEdit = athlete
        isShowingForm = true
    }

    func requestDelete(_ athlete: Athlete) {
        athleteToDelete = athlete
        isShowingDeleteAlert = true
    }

    func confirmDelete(using repository: AthleteRepository) {
        guard let athlete = athleteToDelete else { return }
        try? repository.delete(athlete)
        athleteToDelete = nil
    }

    func cancelDelete() {
        athleteToDelete = nil
        isShowingDeleteAlert = false
    }
}
