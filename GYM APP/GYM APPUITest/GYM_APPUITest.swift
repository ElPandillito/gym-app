//
//  GYM_APPUITest.swift
//  GYM APPUITest
//

import XCTest

final class GYM_APPUITest: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    // MARK: - Launch

    @MainActor
    func testAppLaunchesWithoutCrashing() {
        XCTAssertTrue(app.state == .runningForeground)
    }

    @MainActor
    func testRootViewAppearsAfterLaunch() {
        let rootExists = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
            || app.tabBars.firstMatch.waitForExistence(timeout: 5)
            || app.otherElements.firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(rootExists, "A root UI element should appear within 5 seconds of launch")
    }

    @MainActor
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
