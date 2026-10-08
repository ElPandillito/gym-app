//
//  BarcodeScannerViewModel.swift
//  GYM APP
//

import AVFoundation
import Foundation
import SwiftData

enum BarcodeScanResult {
    case foodFound(Food)
    case barcodeNotFound(String)
}

@Observable
@MainActor
final class BarcodeScannerViewModel {

    private(set) var isScanning = true
    var onResult: ((BarcodeScanResult) -> Void)?

    private let scanner: any BarcodeScannerServiceProtocol
    private let repository: FoodRepositoryProtocol
    private var hasResolved = false

    var captureSession: AVCaptureSession { scanner.captureSession }
    var isTorchAvailable: Bool { scanner.isTorchAvailable }
    var isTorchOn: Bool { scanner.isTorchOn }

    init(
        context: ModelContext,
        scanner: (any BarcodeScannerServiceProtocol)? = nil
    ) {
        self.repository = FoodRepository.make(context: context)
        self.scanner = scanner ?? BarcodeScannerService()
        self.scanner.onDetect = { [weak self] barcode in
            self?.handleDetection(barcode)
        }
    }

    func start() { scanner.start() }
    func stop() { scanner.stop() }
    func toggleTorch() { scanner.toggleTorch() }

    private func handleDetection(_ barcode: ScannedBarcode) {
        guard !hasResolved else { return }
        hasResolved = true
        isScanning = false
        scanner.stop()

        if let food = try? repository.fetch(barcode: barcode.payload) {
            onResult?(.foodFound(food))
        } else {
            onResult?(.barcodeNotFound(barcode.payload))
        }
    }
}
