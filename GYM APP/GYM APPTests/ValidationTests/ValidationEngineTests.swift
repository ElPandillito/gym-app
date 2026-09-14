//
//  ValidationEngineTests.swift
//  GYM APPTests
//

import Testing
@testable import GYM_APP

@Suite("ValidationEngine")
struct ValidationEngineTests {

    // MARK: - AthleteValidator

    @Suite("AthleteValidator")
    struct AthleteValidatorTests {

        @Test("empty name is invalid error")
        func emptyNameIsError() {
            let result = AthleteValidator.validateName("")
            #expect(result.isInvalid)
            #expect(result.severity == .error)
        }

        @Test("whitespace-only name is invalid")
        func whitespaceNameIsInvalid() {
            let result = AthleteValidator.validateName("   ")
            #expect(result.isInvalid)
        }

        @Test("valid name passes")
        func validNamePasses() {
            let result = AthleteValidator.validateName("Carlos López")
            #expect(result.isValid)
        }

        @Test("nil height is valid — optional field")
        func nilHeightIsValid() {
            #expect(AthleteValidator.validateHeight(nil).isValid)
        }

        @Test("height 10 cm is below 50 cm minimum — invalid")
        func heightBelowMinIsInvalid() {
            #expect(AthleteValidator.validateHeight(10).isInvalid)
        }

        @Test("height 175 cm is valid")
        func heightInRangeIsValid() {
            #expect(AthleteValidator.validateHeight(175).isValid)
        }

        @Test("height 300 cm is above 250 cm maximum — invalid")
        func heightAboveMaxIsInvalid() {
            #expect(AthleteValidator.validateHeight(300).isInvalid)
        }

        @Test("nil birthDate is valid")
        func nilBirthDateIsValid() {
            #expect(AthleteValidator.validateBirthDate(nil).isValid)
        }

        @Test("composite validate collects all results")
        func compositeValidateCollectsResults() {
            let report = AthleteValidator.validate(
                name: "Ana", heightCm: 165, birthDate: nil
            )
            #expect(report.isValid)
        }
    }

    // MARK: - BodyMetricsValidator

    @Suite("BodyMetricsValidator")
    struct BodyMetricsValidatorTests {

        @Test("nil weight returns error")
        func nilWeightIsError() {
            let result = BodyMetricsValidator.validateWeight(nil)
            #expect(result.isInvalid)
            #expect(result.severity == .error)
        }

        @Test("weight 10 kg is below 20 kg minimum — invalid")
        func weightBelowMinIsInvalid() {
            #expect(BodyMetricsValidator.validateWeight(10).isInvalid)
        }

        @Test("weight 75 kg is valid")
        func validWeightPasses() {
            #expect(BodyMetricsValidator.validateWeight(75).isValid)
        }

        @Test("nil bodyFat is valid — optional")
        func nilBodyFatIsValid() {
            #expect(BodyMetricsValidator.validateBodyFat(nil).isValid)
        }

        @Test("bodyFat 1 pct is below 2 pct minimum — invalid")
        func bodyFatBelowMinIsInvalid() {
            #expect(BodyMetricsValidator.validateBodyFat(1.0).isInvalid)
        }

        @Test("bodyFat 70 pct is above 65 pct maximum — invalid")
        func bodyFatAboveMaxIsInvalid() {
            #expect(BodyMetricsValidator.validateBodyFat(70).isInvalid)
        }

        @Test("bodyFat 15 pct is valid")
        func bodyFatInRangeIsValid() {
            #expect(BodyMetricsValidator.validateBodyFat(15).isValid)
        }
    }

    // MARK: - ValidationReport

    @Suite("ValidationReport")
    struct ValidationReportTests {

        @Test("all valid results → isValid true and no errors")
        func allValidIsValid() {
            let report = ValidationReport.collect {
                ValidationResult.valid
                ValidationResult.valid
            }
            #expect(report.isValid)
            #expect(report.errors.isEmpty)
        }

        @Test("one error result → isValid false with one error")
        func oneErrorMakesInvalid() {
            let report = ValidationReport.collect {
                ValidationResult.valid
                ValidationResult.invalid(reason: "Fallo", severity: .error)
            }
            #expect(!report.isValid)
            #expect(report.errors.count == 1)
            #expect(report.errors.first == "Fallo")
        }

        @Test("warning result → hasWarnings true but report.isValid false")
        func warningPresence() {
            let report = ValidationReport.collect {
                ValidationResult.invalid(reason: "Aviso", severity: .warning)
            }
            #expect(report.hasWarnings)
            #expect(!report.isValid)
            #expect(report.warnings == ["Aviso"])
        }
    }
}
