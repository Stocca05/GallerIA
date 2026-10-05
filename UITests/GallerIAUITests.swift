import XCTest

final class GallerIAUITests: XCTestCase {
    func testOnboardingAndLibrary() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-onboarding"]
        app.launch()
        XCTAssertTrue(app.buttons["Crea la tua selezione"].waitForExistence(timeout: 10))
        capture("01-onboarding", app)
        app.buttons["Crea la tua selezione"].tap()
        XCTAssertTrue(app.tabBars.buttons["La tua libreria"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Scegli le tue foto"].exists)
        capture("02-library", app)
        app.tabBars.buttons["Seleziona"].tap()
        XCTAssertTrue(app.staticTexts["Partiamo dalle tue foto"].waitForExistence(timeout: 5))
        capture("03-selection-empty", app)
    }

    func testProAndPrivacyScreens() {
        let app = XCUIApplication()
        app.launchArguments = ["-hasSeenOnboarding", "YES"]
        app.launch()
        app.buttons["SCOPRI PRO"].tap()
        XCTAssertTrue(app.buttons["Ripristina acquisti"].waitForExistence(timeout: 5))
        capture("04-pro", app)
        app.buttons["Chiudi"].tap()
        app.tabBars.buttons["Impostazioni"].tap()
        app.buttons["Come vengono usati i tuoi dati"].tap()
        XCTAssertTrue(app.staticTexts["I tuoi ricordi, sotto il tuo controllo."].waitForExistence(timeout: 5))
        capture("05-privacy", app)
    }

    private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
