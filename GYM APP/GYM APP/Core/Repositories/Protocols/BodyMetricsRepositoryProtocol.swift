//
//  BodyMetricsRepositoryProtocol.swift
//  GYM APP
//

import Foundation

protocol BodyMetricsRepositoryProtocol {
    func save(_ metrics: BodyMetrics, for checkIn: CheckIn) throws
    func delete(_ metrics: BodyMetrics, from checkIn: CheckIn) throws
}
