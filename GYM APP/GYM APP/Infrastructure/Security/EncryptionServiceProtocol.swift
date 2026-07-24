//
//  EncryptionServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Contract for encrypting/decrypting sensitive data at rest.
protocol EncryptionServiceProtocol {
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ data: Data) throws -> Data
}
