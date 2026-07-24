//
//  PhotoSource.swift
//  GYM APP
//

import Foundation

/// Identifies how an image was acquired.
/// The UI layer is responsible for availability checks and presenting the correct picker.
enum PhotoSource {
    case camera
    case photoLibrary
    #if os(macOS)
    case dragDrop
    #endif

    var displayName: String {
        switch self {
        case .camera:       return "Cámara"
        case .photoLibrary: return "Galería de fotos"
        #if os(macOS)
        case .dragDrop:     return "Arrastrar y soltar"
        #endif
        }
    }
}
