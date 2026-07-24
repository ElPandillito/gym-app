//
//  SkinfoldMeasurementsRepositoryProtocol.swift
//  GYM APP
//

import Foundation

protocol SkinfoldMeasurementsRepositoryProtocol {
    func save(_ measurements: SkinfoldMeasurements, for checkIn: CheckIn) throws
    func delete(_ measurements: SkinfoldMeasurements, from checkIn: CheckIn) throws
}
