//
//  BarcodeScannerService.swift
//  GYM APP
//

import AVFoundation
import Foundation

// MARK: - Symbology

enum BarcodeSymbology: String, Sendable, CaseIterable {
    case ean13
    case ean8
    case upcA
    case qr
}

struct ScannedBarcode: Sendable, Equatable {
    let payload: String
    let symbology: BarcodeSymbology
}

extension BarcodeSymbology {
    /// AVFoundation never reports UPC-A as its own type — a UPC-A barcode is physically
    /// an EAN-13 with a leading "0", so it always surfaces as `.ean13`. We recover the
    /// distinction here from the payload shape instead.
    static func from(avType: AVMetadataObject.ObjectType, payload: String) -> BarcodeSymbology? {
        switch avType {
        case .ean13:
            return payload.count == 13 && payload.hasPrefix("0") ? .upcA : .ean13
        case .ean8:
            return .ean8
        case .qr:
            return .qr
        default:
            return nil
        }
    }
}

// MARK: - Protocol

@MainActor
protocol BarcodeScannerServiceProtocol: AnyObject {
    var onDetect: ((ScannedBarcode) -> Void)? { get set }
    var captureSession: AVCaptureSession { get }
    var isTorchAvailable: Bool { get }
    var isTorchOn: Bool { get }

    func start()
    func stop()
    func toggleTorch()
}

// MARK: - Concrete (AVFoundation)

@MainActor
final class BarcodeScannerService: NSObject, BarcodeScannerServiceProtocol {

    let captureSession = AVCaptureSession()
    var onDetect: ((ScannedBarcode) -> Void)?
    private(set) var isTorchOn = false

    var isTorchAvailable: Bool {
        AVCaptureDevice.default(for: .video)?.hasTorch ?? false
    }

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(output) else { return }
        captureSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean13, .ean8, .qr]
    }

    func start() {
        guard !captureSession.isRunning else { return }
        let session = captureSession
        Task.detached {
            session.startRunning()
        }
    }

    func stop() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
    }

    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = isTorchOn ? .off : .on
            device.unlockForConfiguration()
            isTorchOn.toggle()
        } catch {
            // Torch is a convenience affordance — failure to lock the device is not fatal.
        }
    }
}

extension BarcodeScannerService: AVCaptureMetadataOutputObjectsDelegate {
    // Delegate queue is pinned to .main in configureSession(), so this call is already
    // on the main thread even though the protocol itself isn't actor-isolated.
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutputMetadataObjects metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let payload = object.stringValue,
              let symbology = BarcodeSymbology.from(avType: object.type, payload: payload) else { return }

        MainActor.assumeIsolated {
            onDetect?(ScannedBarcode(payload: payload, symbology: symbology))
        }
    }
}

// MARK: - Stub

@MainActor
final class MockBarcodeScanner: BarcodeScannerServiceProtocol {

    let captureSession = AVCaptureSession()
    var onDetect: ((ScannedBarcode) -> Void)?
    let isTorchAvailable: Bool
    private(set) var isTorchOn = false

    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    init(isTorchAvailable: Bool = true) {
        self.isTorchAvailable = isTorchAvailable
    }

    func start() { startCallCount += 1 }
    func stop() { stopCallCount += 1 }

    func toggleTorch() {
        guard isTorchAvailable else { return }
        isTorchOn.toggle()
    }

    /// Test helper — simulates the camera detecting a code.
    func simulateDetection(_ barcode: ScannedBarcode) {
        onDetect?(barcode)
    }
}
