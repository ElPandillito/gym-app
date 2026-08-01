//
//  ReportFormat.swift
//  GYM APP
//

import Foundation

enum ReportFormat: String, CaseIterable {
    case pdf  = "pdf"
    case csv  = "csv"
    case json = "json"

    var mimeType: String {
        switch self {
        case .pdf:  return "application/pdf"
        case .csv:  return "text/csv"
        case .json: return "application/json"
        }
    }

    var fileExtension: String { rawValue }
    var displayName: String { rawValue.uppercased() }
}

enum ReportType: String, CaseIterable {
    case athlete       = "athlete"
    case progress      = "progress"
    case comparison    = "comparison"
    case competition   = "competition"
    case global        = "global"
}
