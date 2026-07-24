//
//  KeychainServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Contract for storing and retrieving secrets from the system keychain.
protocol KeychainServiceProtocol {
    func save(_ data: Data, forKey key: String) throws
    func load(forKey key: String) throws -> Data
    func delete(forKey key: String) throws
    func exists(forKey key: String) -> Bool
}

enum KeychainError: LocalizedError {
    case itemNotFound
    case duplicateItem
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:             return "El elemento no existe en el keychain."
        case .duplicateItem:            return "El elemento ya existe en el keychain."
        case .unexpectedStatus(let s):  return "Error de keychain: \(s)."
        }
    }
}
