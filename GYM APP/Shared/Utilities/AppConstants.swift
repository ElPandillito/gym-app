//
//  AppConstants.swift
//  GYM APP
//

import Foundation

enum AppConstants {
    enum App {
        static let name    = "GYM APP"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    enum Storage {
        static let athletesDirectory = "Athletes"
        static let checkInsDirectory = "CheckIns"
        static let originalDirectory = "original"
        static let thumbnailDirectory = "thumbnail"
    }

    enum Pagination {
        static let defaultPageSize = 20
        static let maxPageSize     = 100
    }

    enum Limits {
        static let maxPhotosPerCheckIn  = PhotoValidator.maxPhotosPerCheckIn
        static let maxPhotoFileSizeBytes = PhotoValidator.maxFileSizeBytes
        static let maxAthleteNameLength = 100
        static let maxNoteLength        = 2_000
    }
}
