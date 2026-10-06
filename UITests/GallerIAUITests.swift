import XCTest

final class GallerIAUITests: XCTestCase {
    func testOnboardingAndLibrary() {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .photos)
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

    func testEditorAdjustmentsAndReset() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-editor"]
        app.launch()
        XCTAssertTrue(app.sliders["Luminosità"].waitForExistence(timeout: 8))
        app.sliders["Luminosità"].adjust(toNormalizedSliderPosition: 0.7)
        app.buttons["Prima delle regolazioni"].tap()
        app.buttons["Modificata"].tap()
        app.swipeUp()
        let reset = app.buttons["Ripristina regolazioni"]
        XCTAssertTrue(reset.isEnabled)
        reset.tap()
        XCTAssertFalse(reset.isEnabled)
        let save = app.buttons["Salva una copia in Foto"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        let ready = NSPredicate(format: "enabled == true")
        expectation(for: ready, evaluatedWith: save)
        waitForExpectations(timeout: 5)
        capture("06-editor", app)
    }

    private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
