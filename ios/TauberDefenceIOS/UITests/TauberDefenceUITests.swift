import UIKit
import XCTest

@MainActor
class TauberDefenceUITestCase: XCTestCase {
    enum Language {
        case german
        case english

        var code: String {
            switch self {
            case .german: "de"
            case .english: "en"
            }
        }

        var localeIdentifier: String {
            switch self {
            case .german: "de_DE"
            case .english: "en_US"
            }
        }
    }

    enum Fixture: String {
        case `default`
        case menu
        case roster
        case lowBudget = "low-budget"
        case battle
        case boss
        case victory
        case defeat
    }

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 480
    }

    @discardableResult
    func launch(
        fixture: Fixture = .default,
        language: Language = .german,
        marketingScreenshot: Bool = false,
        preserveProgress: Bool = false
    ) -> XCUIApplication {
        XCUIDevice.shared.orientation = .landscapeLeft
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--ui-test-fixture", fixture.rawValue,
            "-AppleLanguages", "(\(language.code))",
            "-AppleLocale", language.localeIdentifier,
        ]
        if marketingScreenshot {
            app.launchArguments.append("--marketing-screenshot")
        }
        if preserveProgress { app.launchArguments.append("--preserve-progress") }
        app.launchEnvironment["TAUBERDEFENCE_UI_TEST_LANGUAGE"] = language.code
        app.launchEnvironment["TZ"] = "Europe/Berlin"
        app.launch()
        waitForExistence(element(fixture == .menu ? "menu.screen" : "game.city"), timeout: 20)
        if fixture != .menu { waitForExistence(element("board.ready"), timeout: 45) }
        return app
    }

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @discardableResult
    func waitForExistence(
        _ target: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        wait(
            for: NSPredicate(format: "exists == true"),
            on: target,
            timeout: timeout,
            message: "Element did not appear: \(target)",
            file: file,
            line: line
        )
    }

    @discardableResult
    func waitForDisappearance(
        _ target: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        wait(
            for: NSPredicate(format: "exists == false"),
            on: target,
            timeout: timeout,
            message: "Element remained visible: \(target)",
            file: file,
            line: line
        )
    }

    @discardableResult
    func waitForLabelToChange(
        from original: String,
        on target: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        wait(
            for: NSPredicate(format: "exists == true AND label != %@", original),
            on: target,
            timeout: timeout,
            message: "Label did not change from '\(original)'",
            file: file,
            line: line
        )
    }

    func tap(
        _ target: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitForExistence(target, timeout: timeout, file: file, line: line)
        XCTAssertTrue(target.isHittable, "Element is not hittable: \(target)", file: file, line: line)
        target.tap()
    }

    func openBuildMenu(at spot: Int, file: StaticString = #filePath, line: UInt = #line) {
        tap(app.buttons["board.spot.\(spot)"], file: file, line: line)
        waitForExistence(element("build.menu"), file: file, line: line)
    }

    func purchase(
        _ defenseIdentifier: String,
        at spot: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let money = element("hud.money")
        let originalMoney = money.label
        openBuildMenu(at: spot, file: file, line: line)
        let choice = app.buttons["build.\(defenseIdentifier)"]
        let catalog = app.scrollViews["build.catalog"]
        for _ in 0..<5 {
            // XCUITest can throw while asking hittability of off-screen SwiftUI buttons.
            // Scroll until the center is inside the catalog before requesting a hit point.
            let center = CGPoint(x: choice.frame.midX, y: choice.frame.midY)
            if catalog.frame.insetBy(dx: 12, dy: 0).contains(center) { break }
            catalog.swipeLeft()
        }
        tap(choice, file: file, line: line)
        waitForLabelToChange(from: originalMoney, on: money, file: file, line: line)
        waitForDisappearance(element("build.menu"), file: file, line: line)
    }

    func money(from element: XCUIElement) -> Int {
        let text = (element.value as? String) ?? element.label
        let leadingNumber = text
            .drop { $0.wholeNumberValue == nil }
            .prefix { $0.wholeNumberValue != nil || $0 == "." }
            .filter { $0.wholeNumberValue != nil }
        return Int(leadingNumber) ?? -1
    }

    func capture(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let normalizedImage = UIGraphicsImageRenderer(size: screenshot.image.size).image { _ in
            screenshot.image.draw(in: CGRect(origin: .zero, size: screenshot.image.size))
        }
        let attachment = XCTAttachment(image: normalizedImage)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertGreaterThan(
            normalizedImage.size.width,
            normalizedImage.size.height,
            "App Store screenshot must be landscape"
        )

        guard let artifactDirectory = ProcessInfo.processInfo.environment[
            "TAUBERDEFENCE_UI_TEST_ARTIFACT_DIR"
        ], !artifactDirectory.isEmpty else {
            return
        }

        let safeName = name.map { character in
            character.isLetter || character.isNumber || character == "-" ? character : "-"
        }
        let directory = URL(fileURLWithPath: artifactDirectory, isDirectory: true)
        let destination = directory.appendingPathComponent(String(safeName) + ".png")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            guard let png = normalizedImage.pngData() else {
                throw CocoaError(.fileWriteUnknown)
            }
            try png.write(to: destination, options: .atomic)
        } catch {
            XCTFail("Could not write screenshot artifact at \(destination.path): \(error)")
        }
    }

    func assertTownIsRendered() {
        // Native HUD/markers can remain visible even when RealityKit draws nothing.
        // The town's green ground and trees distinguish it from the blue backdrop.
        let rendered = NSPredicate { _, _ in
            guard let image = XCUIScreen.main.screenshot().image.cgImage else { return false }
            let side = 64
            var pixels = [UInt8](repeating: 0, count: side * side * 4)
            return pixels.withUnsafeMutableBytes { bytes in
                guard let context = CGContext(
                    data: bytes.baseAddress, width: side, height: side,
                    bitsPerComponent: 8, bytesPerRow: side * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ) else { return false }
                context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
                let channels = bytes.bindMemory(to: UInt8.self)
                let greenPixels = stride(from: 0, to: channels.count, by: 4).filter { index in
                    let red = Int(channels[index])
                    let green = Int(channels[index + 1])
                    let blue = Int(channels[index + 2])
                    return green > red + 8 && green > blue + 8
                }.count
                return greenPixels > side * side / 50
            }
        }
        let expectation = XCTNSPredicateExpectation(predicate: rendered, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 15), .completed,
                       "RealityKit town is missing; visible HUD alone is not a rendered game")
    }

    @discardableResult
    private func wait(
        for predicate: NSPredicate,
        on object: Any,
        timeout: TimeInterval,
        message: String,
        file: StaticString,
        line: UInt
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: object)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, message, file: file, line: line)
        return result == .completed
    }
}

@MainActor
final class TauberDefenceUITests: TauberDefenceUITestCase {
    func testMenuStartsClassicAndExperimentalModes() {
        launch(fixture: .menu)
        XCTAssertEqual(element("menu.xp").label, "0 XP")
        tap(app.buttons["menu.classic"])
        XCTAssertEqual(money(from: element("hud.money")), 300)
        tap(app.buttons["game.pause"])
        tap(app.buttons["pause.menu"])
        waitForExistence(element("menu.screen"))
        tap(app.buttons["menu.trials"])
        XCTAssertEqual(money(from: element("hud.money")), 1_200)
        XCTAssertTrue(element("hud.wave").label.contains("6"))
        purchase("decoy", at: 3)
        tap(app.buttons["wave.start"])
        waitForExistence(element("wave.running"))
    }

    func testExperiencePersistsWithoutDuplicateResultRewards() {
        launch(fixture: .victory)
        XCTAssertTrue(element("result.xp").label.contains("150"))
        tap(app.buttons["result.menu"])
        XCTAssertEqual(element("menu.xp").label, "150 XP")
        app.terminate()
        launch(fixture: .menu, preserveProgress: true)
        XCTAssertEqual(element("menu.xp").label, "150 XP")
        tap(app.buttons["menu.classic"])
        tap(app.buttons["game.pause"])
        tap(app.buttons["pause.menu"])
        XCTAssertEqual(element("menu.xp").label, "150 XP")
    }

    func testExperimentalDefensesCanBePurchasedThroughRealMarkers() {
        for type in ["windowCD", "flutterTape", "broomOfficer", "speaker", "paperwork", "decoy"] {
            launch()
            purchase(type, at: 3)
            XCTAssertFalse(app.buttons["board.spot.3"].exists)
            app.terminate()
        }
    }

    func testPinchAndTwistUpdateCamera() {
        launch()
        let reset = app.buttons["camera.reset"]
        let initial = reset.value as? String
        element("game.city").pinch(withScale: 1.4, velocity: 1)
        XCTAssertNotEqual(reset.value as? String, initial)
        let zoomed = reset.value as? String
        element("game.city").rotate(.pi / 4, withVelocity: 1)
        XCTAssertNotEqual(reset.value as? String, zoomed)
        tap(reset)
        XCTAssertEqual(reset.value as? String, initial)
    }

    func testRealMarkersRemainAlignedAfterCameraChanges() {
        launch()
        let original = app.buttons["board.spot.3"].frame
        tap(app.buttons["camera.in"])
        tap(app.buttons["camera.rotate"])
        XCTAssertNotEqual(app.buttons["board.spot.3"].frame, original)
        purchase("plastic-owl", at: 3)
        XCTAssertFalse(app.buttons["board.spot.3"].exists)
        tap(app.buttons["camera.reset"])
        purchase("sprinkler", at: 2)
        capture("real-marker-purchases")
    }

    func testLaunchShowsPlayableEconomyAndLevel() {
        launch()

        XCTAssertTrue(element("hud.money").exists)
        XCTAssertTrue(element("hud.wave").exists)
        XCTAssertTrue(element("hud.cleanliness").exists)
        XCTAssertGreaterThanOrEqual(money(from: element("hud.money")), 300)
        XCTAssertTrue(app.buttons["wave.start"].exists)
    }

    func testEveryDefenseTypeCanBePurchased() {
        for defense in ["plastic-owl", "sprinkler", "falconer"] {
            launch()
            purchase(defense, at: 1)
            app.terminate()
        }
    }

    func testInsufficientFundsPreservesBudgetAndShowsFeedback() {
        launch(fixture: .lowBudget)

        let moneyMetric = element("hud.money")
        XCTAssertEqual(money(from: moneyMetric), 350)
        purchase("falconer", at: 1)
        XCTAssertEqual(money(from: moneyMetric), 50)

        let exhaustedLabel = moneyMetric.label
        openBuildMenu(at: 2)
        tap(app.buttons["build.plastic-owl"])
        let error = element("build.error")
        waitForExistence(error)
        XCTAssertTrue(error.label.contains("50"), "Feedback must show the missing budget")
        XCTAssertEqual(moneyMetric.label, exhaustedLabel)
        XCTAssertTrue(element("build.menu").exists)
    }

    func testWaveStartsPausesAndResumes() {
        launch()

        tap(app.buttons["wave.start"])
        waitForExistence(element("wave.running"), timeout: 4)
        tap(app.buttons["game.pause"])
        waitForExistence(element("pause.overlay"))
        tap(app.buttons["pause.resume"])
        waitForDisappearance(element("pause.overlay"))
        XCTAssertTrue(element("wave.running").exists)
    }

    func testBattleFixtureHasLiveDefensesAndPigeons() {
        launch(fixture: .battle)

        waitForExistence(element("wave.running"))
        XCTAssertGreaterThan(money(from: element("hud.money")), -1)
        XCTAssertFalse(
            app.buttons["board.spot.1"].exists,
            "Battle fixture must start with its first defense already built"
        )
    }

    func testBossFixtureRunsRuedigerWave() {
        launch(fixture: .boss)

        let wave = element("wave.running")
        waitForExistence(wave)
        let ruedigerText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'RÜDIGER'")
        ).firstMatch
        XCTAssertTrue(
            ruedigerText.waitForExistence(timeout: 4) || element("pigeon.detail").exists,
            "Boss fixture must visibly identify Rüdiger"
        )
    }

    func testVictoryFixtureCanRestartGame() {
        launch(fixture: .victory)

        let result = element("game.result")
        waitForExistence(result, timeout: 8)
        tap(app.buttons["result.restart"])
        waitForDisappearance(result)
        waitForExistence(app.buttons["wave.start"])
    }

    func testDefeatFixtureShowsGameOver() {
        launch(fixture: .defeat)

        let result = element("game.result")
        waitForExistence(result, timeout: 8)
        XCTAssertTrue(result.exists)
    }

    func testEnglishLocalization() {
        launch(fixture: .menu, language: .english)
        XCTAssertTrue(app.buttons["menu.trials"].label.contains("START FIELD TRIALS"))
        tap(app.buttons["menu.guide"])
        XCTAssertTrue(app.staticTexts["The usual suspects"].waitForExistence(timeout: 5))
        app.terminate()
        launch(language: .english)

        XCTAssertEqual(app.buttons["wave.start"].label, "START FIRST WAVE")
        XCTAssertTrue(element("hud.money").label.contains("CITY BUDGET"))
        app.terminate()

        launch(fixture: .victory, language: .english)

        let result = element("game.result")
        waitForExistence(result, timeout: 8)
        XCTAssertEqual(result.label, "PIGEON-FREE ZONE!")
        XCTAssertEqual(app.buttons["result.restart"].label, "ONE MORE ROUND")
    }
}

@MainActor
final class TauberDefenceMarketingScreenshots: TauberDefenceUITestCase {
    func testAppStoreMarketingScreenshots() {
        snapshot(.menu, indicator: "menu.screen", name: "marketing-00-headquarters")
        snapshot(.default, indicator: "wave.start", name: "marketing-01-marketplace")
        snapshot(.battle, indicator: "wave.running", name: "marketing-02-defense-in-action")
        snapshot(.boss, indicator: "wave.running", name: "marketing-03-ruediger")
        snapshot(.victory, indicator: "game.result", name: "marketing-04-victory")
        snapshot(.defeat, indicator: "game.result", name: "marketing-05-defeat")
        snapshot(.roster, indicator: "wave.running", name: "marketing-06-field-trials")
    }

    private func snapshot(_ fixture: Fixture, indicator: String, name: String) {
        launch(fixture: fixture, marketingScreenshot: true)
        waitForExistence(element(indicator), timeout: 8)
        if fixture == .default { assertTownIsRendered() }
        capture(name)
        app.terminate()
    }
}
