//
//  AppLogger.swift
//  GYM APP
//

import Foundation
import OSLog

/// Centralized structured logger using os.Logger.
/// Import this wherever logging is needed — never use print() in production code.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.gymapp"

    static let app        = Logger(subsystem: subsystem, category: "App")
    static let repository = Logger(subsystem: subsystem, category: "Repository")
    static let storage    = Logger(subsystem: subsystem, category: "Storage")
    static let engine     = Logger(subsystem: subsystem, category: "Engine")
    static let ui         = Logger(subsystem: subsystem, category: "UI")
    static let ai         = Logger(subsystem: subsystem, category: "AI")
}
