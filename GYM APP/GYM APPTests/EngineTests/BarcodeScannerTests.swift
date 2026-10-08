//
//  BarcodeScannerTests.swift
//  GYM APPTests
//

import AVFoundation
import Foundation
import SwiftData
import Testing
@testable import GYM_APP

// MARK: - Symbology mapping

@Suite("BarcodeSymbology — AVFoundation mapping")
struct BarcodeSymbologyMappingTests {

    @Test("EAN-13 payload maps to .ean13")
    func ean13MapsToEan13() {
        let symbology = BarcodeSymbology.from(avType: .ean13, payload: "7501234567897")
        #expect(symbology == .ean13)
    }

    @Test("EAN-13 payload with 13 digits starting with 0 maps to .upcA")
    func ean13WithLeadingZeroMapsToUpcA() {
        let symbology = BarcodeSymbology.from(avType: .ean13, payload: "0012345678905")
        #expect(symbology == .upcA)
    }

    @Test("EAN-8 payload maps to .ean8")
    func ean8MapsToEan8() {
        let symbology = BarcodeSymbology.from(avType: .ean8, payload: "12345670")
        #expect(symbology == .ean8)
    }

    @Test("QR payload maps to .qr")
    func qrMapsToQr() {
        let symbology = BarcodeSymbology.from(avType: .qr, payload: "https://example.com")
        #expect(symbology == .qr)
    }

    @Test("Unsupported AVFoundation type maps to nil")
    func unsupportedTypeMapsToNil() {
        let symbology = BarcodeSymbology.from(avType: .code128, payload: "ABC123")
        #expect(symbology == nil)
    }
}

// MARK: - MockBarcodeScanner

@Suite("MockBarcodeScanner")
@MainActor
struct MockBarcodeScannerTests {

    @Test("Conforms to BarcodeScannerServiceProtocol")
    func conformsToProtocol() {
        let s: any BarcodeScannerServiceProtocol = MockBarcodeScanner()
        _ = s
    }

    @Test("start() increments the start call counter")
    func startIncrementsCounter() {
        let scanner = MockBarcodeScanner()
        scanner.start()
        scanner.start()
        #expect(scanner.startCallCount == 2)
    }

    @Test("stop() increments the stop call counter")
    func stopIncrementsCounter() {
        let scanner = MockBarcodeScanner()
        scanner.stop()
        #expect(scanner.stopCallCount == 1)
    }

    @Test("toggleTorch() flips isTorchOn when torch is available")
    func toggleTorchFlipsStateWhenAvailable() {
        let scanner = MockBarcodeScanner(isTorchAvailable: true)
        #expect(scanner.isTorchOn == false)
        scanner.toggleTorch()
        #expect(scanner.isTorchOn == true)
        scanner.toggleTorch()
        #expect(scanner.isTorchOn == false)
    }

    @Test("toggleTorch() is a no-op when torch is unavailable")
    func toggleTorchNoOpWhenUnavailable() {
        let scanner = MockBarcodeScanner(isTorchAvailable: false)
        scanner.toggleTorch()
        #expect(scanner.isTorchOn == false)
    }

    @Test("simulateDetection invokes onDetect with the given barcode")
    func simulateDetectionInvokesCallback() {
        let scanner = MockBarcodeScanner()
        var received: ScannedBarcode?
        scanner.onDetect = { received = $0 }

        let barcode = ScannedBarcode(payload: "7501234567897", symbology: .ean13)
        scanner.simulateDetection(barcode)

        #expect(received == barcode)
    }
}

// MARK: - FoodRepository barcode lookup

@Suite("FoodRepository — barcode lookup", .serialized)
struct FoodRepositoryBarcodeTests {

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(GYMAppSchemaV1.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @MainActor
    private func makeRepo(context: ModelContext) -> FoodRepository {
        FoodRepository.make(context: context)
    }

    @Test("fetch(barcode:) returns the matching food")
    @MainActor
    func fetchBarcode_returnsMatch() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repo = makeRepo(context: context)

        let food = try repo.add(name: "Yogurt natural", kind: .ingredient, category: .lacteos, source: .coach)
        try repo.update(
            food, name: food.name, kind: food.kind, category: food.category,
            calories: 59, protein: 10, carbohydrates: 3.6, fat: 0.4, fiber: nil,
            servingSize: nil, servingUnit: nil, brand: nil, tags: [], barcode: "7501234567897"
        )

        let result = try repo.fetch(barcode: "7501234567897")
        #expect(result?.id == food.id)
    }

    @Test("fetch(barcode:) returns nil when no food matches")
    @MainActor
    func fetchBarcode_returnsNilWhenNoMatch() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repo = makeRepo(context: context)

        _ = try repo.add(name: "Pechuga de pollo", kind: .ingredient, category: .proteinas, source: .coach)

        let result = try repo.fetch(barcode: "0000000000000")
        #expect(result == nil)
    }

    @Test("update(barcode:) persists nil when the barcode is cleared")
    @MainActor
    func updateBarcode_canClearExistingValue() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repo = makeRepo(context: context)

        let food = try repo.add(name: "Avena", kind: .ingredient, category: .cereales, source: .coach)
        try repo.update(
            food, name: food.name, kind: food.kind, category: food.category,
            calories: nil, protein: nil, carbohydrates: nil, fat: nil, fiber: nil,
            servingSize: nil, servingUnit: nil, brand: nil, tags: [], barcode: "123456"
        )
        #expect(food.barcode == "123456")

        try repo.update(
            food, name: food.name, kind: food.kind, category: food.category,
            calories: nil, protein: nil, carbohydrates: nil, fat: nil, fiber: nil,
            servingSize: nil, servingUnit: nil, brand: nil, tags: [], barcode: nil
        )
        #expect(food.barcode == nil)
    }
}
