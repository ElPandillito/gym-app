//
//  AppEnvironment.swift
//  GYM APP
//

import Foundation

/// Runtime environment detection. Use this instead of #if DEBUG scattered across the codebase.
enum AppEnvironment {
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UITesting")
    }

    static var isUnitTesting: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    static var platform: Platform {
        #if os(iOS)
        return .iOS
        #elseif os(macOS)
        return .macOS
        #else
        return .other
        #endif
    }

    enum Platform { case iOS, macOS, other }
}
