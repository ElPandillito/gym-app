//
//  AthleteRepositoryProtocol.swift
//  GYM APP
//

import Foundation

protocol AthleteRepositoryProtocol {
    func add(_ athlete: Athlete) throws
    func update(_ athlete: Athlete) throws
    func delete(_ athlete: Athlete) throws
}
