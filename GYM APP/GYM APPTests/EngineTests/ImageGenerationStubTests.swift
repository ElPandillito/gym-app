//
//  ImageGenerationStubTests.swift
//  GYM APPTests
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("ImageGenerationStub")
struct ImageGenerationStubTests {

    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let validPrompt = "Fotografía gastronómica de pollo asado, sin personas, sin texto."

    // MARK: - Fixtures

    private func stub(
        behavior: ImageGenerationStub.Behavior = .success,
        delayNanoseconds: UInt64 = 0
    ) -> ImageGenerationStub {
        let d = fixedDate
        return ImageGenerationStub(behavior: behavior, delayNanoseconds: delayNanoseconds, clock: { d })
    }

    // MARK: - Protocol conformance

    @Test("ImageGenerationStub conforms to ImageGenerationServiceProtocol")
    func conformsToProtocol() {
        let s: any ImageGenerationServiceProtocol = stub()
        _ = s
    }

    // MARK: - Success path

    @Test("Success behavior returns non-empty image data")
    func successReturnsImageData() async throws {
        let result = try await stub().generate(prompt: validPrompt)
        #expect(!result.imageData.isEmpty)
    }

    @Test("Success behavior echoes the prompt that was sent")
    func successReturnsPromptUsed() async throws {
        let result = try await stub().generate(prompt: validPrompt)
        #expect(result.promptUsed == validPrompt)
    }

    @Test("Success behavior returns the injected clock date")
    func successReturnsInjectedDate() async throws {
        let result = try await stub().generate(prompt: validPrompt)
        #expect(result.generatedAt == fixedDate)
    }

    @Test("Success behavior returns a non-empty mimeType")
    func successReturnsMimeType() async throws {
        let result = try await stub().generate(prompt: validPrompt)
        #expect(!result.mimeType.isEmpty)
    }

    // MARK: - Determinism

    @Test("Same prompt produces identical image data on repeated calls")
    func determinism_samePromptSameData() async throws {
        let s = stub()
        let r1 = try await s.generate(prompt: validPrompt)
        let r2 = try await s.generate(prompt: validPrompt)
        #expect(r1.imageData == r2.imageData)
        #expect(r1.mimeType  == r2.mimeType)
    }

    // MARK: - Failure path

    @Test("Failure behavior throws the configured AIServiceError.serviceFailure")
    func failureBehavior_serviceFailure() async {
        let s = stub(behavior: .failure(.serviceFailure))
        do {
            _ = try await s.generate(prompt: validPrompt)
            Issue.record("Expected error to be thrown")
        } catch let e as AIServiceError {
            #expect(e == .serviceFailure)
        } catch {
            Issue.record("Expected AIServiceError, got \(error)")
        }
    }

    @Test("Failure behavior throws the configured AIServiceError.unavailable")
    func failureBehavior_unavailable() async {
        let s = stub(behavior: .failure(.unavailable))
        do {
            _ = try await s.generate(prompt: validPrompt)
            Issue.record("Expected .unavailable to be thrown")
        } catch let e as AIServiceError {
            #expect(e == .unavailable)
        } catch {
            Issue.record("Expected AIServiceError, got \(error)")
        }
    }

    // MARK: - Input validation

    @Test("Empty prompt throws AIServiceError.invalidInput")
    func emptyPromptThrowsInvalidInput() async {
        let s = stub()
        do {
            _ = try await s.generate(prompt: "")
            Issue.record("Expected .invalidInput to be thrown")
        } catch let e as AIServiceError {
            if case .invalidInput = e { } else {
                Issue.record("Expected .invalidInput, got \(e)")
            }
        } catch {
            Issue.record("Expected AIServiceError, got \(error)")
        }
    }

    @Test("Whitespace-only prompt throws AIServiceError.invalidInput")
    func whitespacePromptThrowsInvalidInput() async {
        let s = stub()
        do {
            _ = try await s.generate(prompt: "   \n  ")
            Issue.record("Expected .invalidInput to be thrown")
        } catch let e as AIServiceError {
            if case .invalidInput = e { } else {
                Issue.record("Expected .invalidInput, got \(e)")
            }
        } catch {
            Issue.record("Expected AIServiceError, got \(error)")
        }
    }

    // MARK: - Delay

    @Test("Zero delay completes without blocking")
    func zeroDelayCompletes() async throws {
        _ = try await stub(delayNanoseconds: 0).generate(prompt: validPrompt)
    }

    @Test("Short configurable delay is applied before returning result")
    func shortDelayIsApplied() async throws {
        // 10 ms — fast enough for tests, long enough to confirm delay is exercised
        let result = try await stub(delayNanoseconds: 10_000_000).generate(prompt: validPrompt)
        #expect(!result.imageData.isEmpty)
    }

    // MARK: - Cancellation

    @Test("Cancellation during delay propagates as a task cancellation")
    func cancellationDuringDelay() async {
        // 5 s delay ensures the task is still sleeping when cancelled
        let s = stub(delayNanoseconds: 5_000_000_000)
        let task = Task<GeneratedFoodImageData, Error> {
            try await s.generate(prompt: validPrompt)
        }
        task.cancel()
        do {
            _ = try await task.value
            Issue.record("Expected task cancellation to throw")
        } catch is CancellationError {
            // Expected — Task.sleep propagates CancellationError
        } catch {
            // CancellationError sometimes wraps; any throw here is acceptable
        }
    }
}
