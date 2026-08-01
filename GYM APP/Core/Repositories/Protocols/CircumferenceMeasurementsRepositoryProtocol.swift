//
//  CircumferenceMeasurementsRepositoryProtocol.swift
//  GYM APP
//

import Foundation

protocol CircumferenceMeasurementsRepositoryProtocol {
    func save(_ measurements: CircumferenceMeasurements, for checkIn: CheckIn) throws
    func delete(_ measurements: CircumferenceMeasurements, from checkIn: CheckIn) throws
}
