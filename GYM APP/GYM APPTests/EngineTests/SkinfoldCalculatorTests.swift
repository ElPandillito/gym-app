//
//  SkinfoldCalculatorTests.swift
//  GYM APPTests
//

import Testing
@testable import GYM_APP

@Suite("SkinfoldCalculator")
struct SkinfoldCalculatorTests {

    // MARK: - Jackson-Pollock 3 (Male)

    @Test("JP3 male returns non-nil for valid chest/abdomen/thigh")
    func jp3MaleReturnsResult() {
        var inputs = SkinfoldInputs()
        inputs.chest = 10; inputs.abdomen = 20; inputs.thigh = 30
        let result = SkinfoldCalculator.calculate(
            method: .jacksonPollockThree, gender: .male, age: 30, inputs: inputs
        )
        #expect(result != nil)
    }

    @Test("JP3 male body fat is clamped between 1 and 60")
    func jp3MaleBodyFatClamped() throws {
        var inputs = SkinfoldInputs()
        inputs.chest = 10; inputs.abdomen = 20; inputs.thigh = 30
        let result = try #require(
            SkinfoldCalculator.calculate(method: .jacksonPollockThree, gender: .male, age: 30, inputs: inputs)
        )
        #expect(result.bodyFatPercentage >= 1)
        #expect(result.bodyFatPercentage <= 60)
    }

    @Test("JP3 male sum=60 age=30 produces approximately 17-20 pct body fat")
    func jp3MaleApproximateValue() throws {
        // bd = 1.10938 - 0.0008267×60 + 0.0000016×3600 - 0.0002574×30 ≈ 1.0578
        // fat% = (495/1.0578) - 450 ≈ 18%
        var inputs = SkinfoldInputs()
        inputs.chest = 10; inputs.abdomen = 20; inputs.thigh = 30
        let result = try #require(
            SkinfoldCalculator.calculate(method: .jacksonPollockThree, gender: .male, age: 30, inputs: inputs)
        )
        #expect(result.bodyFatPercentage > 15)
        #expect(result.bodyFatPercentage < 22)
    }

    @Test("JP3 male missing required site returns nil")
    func jp3MaleMissingSiteReturnsNil() {
        var inputs = SkinfoldInputs()
        inputs.chest = 10 // abdomen and thigh missing
        let result = SkinfoldCalculator.calculate(
            method: .jacksonPollockThree, gender: .male, age: 30, inputs: inputs
        )
        #expect(result == nil)
    }

    // MARK: - Jackson-Pollock 3 (Female)

    @Test("JP3 female returns non-nil for valid tricep/suprailiac/thigh")
    func jp3FemaleReturnsResult() throws {
        var inputs = SkinfoldInputs()
        inputs.tricep = 15; inputs.suprailiac = 12; inputs.thigh = 20
        let result = try #require(
            SkinfoldCalculator.calculate(method: .jacksonPollockThree, gender: .female, age: 25, inputs: inputs)
        )
        #expect(result.bodyFatPercentage >= 1)
        #expect(result.bodyFatPercentage <= 60)
    }

    // MARK: - Jackson-Pollock 7

    @Test("JP7 returns non-nil for all 7 sites")
    func jp7ReturnsResult() throws {
        var inputs = SkinfoldInputs()
        inputs.chest = 10; inputs.midaxillary = 8; inputs.tricep = 12
        inputs.subscapular = 10; inputs.abdomen = 20; inputs.suprailiac = 12; inputs.thigh = 25
        let result = try #require(
            SkinfoldCalculator.calculate(method: .jacksonPollockSeven, gender: .male, age: 28, inputs: inputs)
        )
        #expect(result.bodyFatPercentage >= 1)
        #expect(result.bodyFatPercentage <= 60)
    }

    // MARK: - Durnin-Womersley

    @Test("Durnin-Womersley returns non-nil for 4 required sites")
    func durninWomersleyReturnsResult() {
        var inputs = SkinfoldInputs()
        inputs.bicep = 8; inputs.tricep = 12; inputs.subscapular = 14; inputs.suprailiac = 10
        let result = SkinfoldCalculator.calculate(
            method: .durninWomersley, gender: .female, age: 30, inputs: inputs
        )
        #expect(result != nil)
    }

    // MARK: - Parrillo

    @Test("Parrillo returns nil when bodyWeightKg is not provided")
    func parrilloWithoutBodyWeightReturnsNil() {
        var inputs = SkinfoldInputs()
        inputs.chest = 10; inputs.abdomen = 15; inputs.thigh = 20
        inputs.tricep = 10; inputs.bicep = 8; inputs.subscapular = 12
        inputs.suprailiac = 10; inputs.lowerBack = 15; inputs.calf = 12
        let result = SkinfoldCalculator.calculate(
            method: .parrillo, gender: .male, age: 30, inputs: inputs, bodyWeightKg: nil
        )
        #expect(result == nil)
    }

    @Test("Parrillo returns non-nil with bodyWeightKg provided")
    func parrilloWithBodyWeightReturnsResult() throws {
        var inputs = SkinfoldInputs()
        inputs.chest = 10; inputs.abdomen = 15; inputs.thigh = 20
        inputs.tricep = 10; inputs.bicep = 8; inputs.subscapular = 12
        inputs.suprailiac = 10; inputs.lowerBack = 15; inputs.calf = 12
        let result = try #require(
            SkinfoldCalculator.calculate(method: .parrillo, gender: .male, age: 30, inputs: inputs, bodyWeightKg: 80)
        )
        #expect(result.bodyFatPercentage >= 1)
        #expect(result.bodyFatPercentage <= 60)
    }

    // MARK: - Custom

    @Test("custom method always returns nil")
    func customMethodReturnsNil() {
        var inputs = SkinfoldInputs()
        inputs.chest = 10; inputs.abdomen = 20; inputs.thigh = 30
        let result = SkinfoldCalculator.calculate(
            method: .custom, gender: .male, age: 30, inputs: inputs
        )
        #expect(result == nil)
    }
}
