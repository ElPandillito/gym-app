//
//  PermissionServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Contract for requesting and checking system permissions.
protocol PermissionServiceProtocol {
    func requestCameraPermission() async -> PermissionStatus
    func requestPhotoLibraryPermission() async -> PermissionStatus
    func cameraPermissionStatus() -> PermissionStatus
    func photoLibraryPermissionStatus() -> PermissionStatus
}

enum PermissionStatus: Equatable {
    case granted
    case denied
    case restricted
    case notDetermined
}
