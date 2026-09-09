//
//  BodyFatAssessmentStubTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("BodyFatAssessmentStubTests")
@MainActor
struct BodyFatAssessmentStubTests {

    // MARK: - Fixtures

    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func stub() -> BodyFatAssessmentStub {
        let d = fixedDate
        return BodyFatAssessmentStub(clock: { d })
    }

    private func noPhotos() -> [PhotoPathEntry] { [] }

    private func threePhotos() -> [PhotoPathEntry] {
        [
            PhotoPathEntry(relativePath: "front.jpg", poseType: .frontRelaxed),
            PhotoPathEntry(relativePath: "back.jpg",  poseType: .backRelaxed),
            PhotoPathEntry(relativePath: "side.jpg",  poseType: .sideChestLeft),
        ]
    }

    private func onePhoto() -> [PhotoPathEntry] {
        [PhotoPathEntry(relativePath: "front.jpg", poseType: .frontRelaxed)]
    }

    private func emptyContext() -> BodyFatAssessmentContext {
        BodyFatAssessmentContext(
            bodyWeightKg: nil, heightCm: nil,
            bioimpedanceBodyFatPct: nil, skinfoldBodyFatPct: nil,
            waistCm: nil, hipCm: nil, neckCm: nil,
            gender: nil, ageYears: nil
        )
    }

    private func skinfoldContext(_ pct: Double) -> BodyFatAssessmentContext {
        BodyFatAssessmentContext(
            bodyWeightKg: nil, heightCm: nil,
            bioimpedanceBodyFatPct: nil, skinfoldBodyFatPct: pct,
            waistCm: nil, hipCm: nil, neckCm: nil,
            gender: nil, ageYears: nil
        )
    }

    private func bioContext(_ pct: Double) -> BodyFatAssessmentContext {
        BodyFatAssessmentContext(
            bodyWeightKg: nil, heightCm: nil,
            bioimpedanceBodyFatPct: pct, skinfoldBodyFatPct: nil,
            waistCm: nil, hipCm: nil, neckCm: nil,
            gender: nil, ageYears: nil
        )
    }

    // MARK: - Protocol conformance

    @Test("BodyFatAssessmentStub conforms to BodyFatAssessmentServiceProtocol")
    func conformsToProtocol() {
        let s: any BodyFatAssessmentServiceProtocol = stub()
        _ = s
    }

    // MARK: - Insufficient data

    @Test("Empty context throws insufficientData")
    func emptyContextThrowsInsufficientData() async {
        do {
            _ = try await stub().estimate(photos: noPhotos(), context: emptyContext())
            Issue.record("Expected .insufficientData to be thrown")
        } catch let e as AIServiceError {
            #expect(e == .insufficientData)
        } catch {
            Issue.record("Expected AIServiceError, got \(error)")
        }
    }

    // MARK: - Skinfold path

    @Test("Skinfold path returns exact skinfold value")
    func skinfoldPath_returnsValue() async throws {
        let result = try await stub().estimate(photos: noPhotos(), context: skinfoldContext(15.0))
        #expect(result.estimatedBodyFatPct == 15.0)
    }

    @Test("Skinfold path confidence is 0.55 with no photos")
    func skinfoldPath_confidence() async throws {
        let result = try await stub().estimate(photos: noPhotos(), context: skinfoldContext(20.0))
        #expect(result.confidenceScore == 0.55)
    }

    @Test("Skinfold path basis is stubDeterministic")
    func skinfoldPath_basis() async throws {
        let result = try await stub().estimate(photos: noPhotos(), context: skinfoldContext(12.0))
        #expect(result.assessmentBasis == .stubDeterministic)
    }

    // MARK: - Bioimpedance path

    @Test("Bioimpedance path returns bioimpedance value when no skinfold")
    func bioimpedancePath_returnsValue() async throws {
        let result = try await stub().estimate(photos: noPhotos(), context: bioContext(22.0))
        #expect(result.estimatedBodyFatPct == 22.0)
    }

    @Test("Bioimpedance path confidence is 0.50 with no photos")
    func bioimpedancePath_confidence() async throws {
        let result = try await stub().estimate(photos: noPhotos(), context: bioContext(18.0))
        #expect(result.confidenceScore == 0.50)
    }

    // MARK: - U.S. Navy circumference path

    @Test("Navy path produces physiological result with full data")
    func navyPath_fullData() async throws {
        let ctx = BodyFatAssessmentContext(
            bodyWeightKg: nil, heightCm: 175.0,
            bioimpedanceBodyFatPct: nil, skinfoldBodyFatPct: nil,
            waistCm: 82.0, hipCm: 96.0, neckCm: 38.0,
            gender: .male, ageYears: nil
        )
        let result = try await stub().estimate(photos: noPhotos(), context: ctx)
        #expect((3.0...60.0).contains(result.estimatedBodyFatPct))
        #expect(result.confidenceScore == 0.40)
    }

    @Test("Navy path uses reduced confidence without neck measurement")
    func navyPath_reducedConfidenceWithoutNeck() async throws {
        let ctx = BodyFatAssessmentContext(
            bodyWeightKg: nil, heightCm: 175.0,
            bioimpedanceBodyFatPct: nil, skinfoldBodyFatPct: nil,
            waistCm: 82.0, hipCm: 96.0, neckCm: nil,
            gender: .male, ageYears: nil
        )
        let result = try await stub().estimate(photos: noPhotos(), context: ctx)
        #expect(result.confidenceScore == 0.32)
    }

    // MARK: - Deurenberg BMI path

    @Test("Deurenberg path produces physiological result with weight and height only")
    func deurenbergPath_basicData() async throws {
        let ctx = BodyFatAssessmentContext(
            bodyWeightKg: 80.0, heightCm: 175.0,
            bioimpedanceBodyFatPct: nil, skinfoldBodyFatPct: nil,
            waistCm: nil, hipCm: nil, neckCm: nil,
            gender: .male, ageYears: 30.0
        )
        let result = try await stub().estimate(photos: noPhotos(), context: ctx)
        #expect((3.0...60.0).contains(result.estimatedBodyFatPct))
        #expect(result.confidenceScore == 0.30)
    }

    // MARK: - Input validation

    @Test("Out-of-range skinfold throws invalidInput")
    func outOfRangeSkinfold_throwsInvalidInput() async {
        do {
            _ = try await stub().estimate(photos: noPhotos(), context: skinfoldContext(100.0))
            Issue.record("Expected .invalidInput to be thrown")
        } catch let e as AIServiceError {
            if case .invalidInput = e { } else {
                Issue.record("Expected .invalidInput, got \(e)")
            }
        } catch {
            Issue.record("Expected AIServiceError, got \(error)")
        }
    }

    @Test("Below-range bioimpedance throws invalidInput")
    func belowRangeBioimpedance_throwsInvalidInput() async {
        do {
            _ = try await stub().estimate(photos: noPhotos(), context: bioContext(1.0))
            Issue.record("Expected .invalidInput to be thrown")
        } catch let e as AIServiceError {
            if case .invalidInput = e { } else {
                Issue.record("Expected .invalidInput, got \(e)")
            }
        } catch {
            Issue.record("Expected AIServiceError, got \(error)")
        }
    }

    // MARK: - Photo bonus

    @Test("Three-coverage photos raise confidence above no-photo baseline")
    func photoBonus_threePhotosRaisesConfidence() async throws {
        let ctx = bioContext(20.0)
        let baseline = try await stub().estimate(photos: noPhotos(), context: ctx)
        let boosted  = try await stub().estimate(photos: threePhotos(), context: ctx)
        #expect(boosted.confidenceScore > baseline.confidenceScore)
    }

    @Test("Single photo adds 0.01 confidence bonus to bioimpedance base")
    func photoBonus_singlePhotoAdds0_01() async throws {
        let ctx = bioContext(20.0)
        let baseline  = try await stub().estimate(photos: noPhotos(), context: ctx)
        let withPhoto = try await stub().estimate(photos: onePhoto(), context: ctx)
        #expect(abs(withPhoto.confidenceScore - (baseline.confidenceScore + 0.01)) < 0.001)
    }

    // MARK: - Confidence cap

    @Test("Confidence never exceeds 0.55 regardless of inputs")
    func confidenceNeverExceeds0_55() async throws {
        let ctx = bioContext(18.0)
        let result = try await stub().estimate(photos: threePhotos(), context: ctx)
        #expect(result.confidenceScore <= 0.55)
    }

    // MARK: - Determinism

    @Test("Same input produces identical results on repeated calls")
    func determinism_sameInputSameOutput() async throws {
        let ctx = BodyFatAssessmentContext(
            bodyWeightKg: 75.0, heightCm: 170.0,
            bioimpedanceBodyFatPct: nil, skinfoldBodyFatPct: 18.5,
            waistCm: 80.0, hipCm: 95.0, neckCm: 37.0,
            gender: .male, ageYears: 28.0
        )
        let r1 = try await stub().estimate(photos: noPhotos(), context: ctx)
        let r2 = try await stub().estimate(photos: noPhotos(), context: ctx)
        #expect(r1.estimatedBodyFatPct == r2.estimatedBodyFatPct)
        #expect(r1.confidenceScore     == r2.confidenceScore)
        #expect(r1.assessmentBasis     == r2.assessmentBasis)
        #expect(r1.notes               == r2.notes)
    }
}
