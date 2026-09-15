import XCTest

@MainActor
class TauberDefenceUITestCase: XCTestCase {
    enum Fixture: String {
        case `default`
        case battle
        case boss
        case victory
        case defeat
    }

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 180
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    @discardableResult
    func launch(
        fixture: Fixture = .default,
        marketingScreenshot: Bool = false
    ) -> XCUIApplication {
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--ui-test-fixture", fixture.rawValue,
            "-AppleLanguages", "(de)",
            "-AppleLocale", "de_DE",
        ]
        if marketingScreenshot {
            app.launchArguments.append("--marketing-screenshot")
        }
        app.launchEnvironment["TZ"] = "Europe/Berlin"
        app.launch()
        waitForExistence(element("game.city"), timeout: 12)
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
        tap(app.buttons["ui-test.spot.\(spot)"], file: file, line: line)
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
        tap(app.buttons["build.\(defenseIdentifier)"], file: file, line: line)
        waitForLabelToChange(from: originalMoney, on: money, file: file, line: line)
        waitForDisappearance(element("build.menu"), file: file, line: line)
    }

    func money(from label: String) -> Int {
        let leadingNumber = label
            .drop { $0.wholeNumberValue == nil }
            .prefix { $0.wholeNumberValue != nil || $0 == "." }
            .filter { $0.wholeNumberValue != nil }
        return Int(leadingNumber) ?? -1
    }

    func capture(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertGreaterThan(
            screenshot.image.size.width,
            screenshot.image.size.height,
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
            try screenshot.pngRepresentation.write(to: destination, options: .atomic)
        } catch {
            XCTFail("Could not write screenshot artifact at \(destination.path): \(error)")
        }
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
    func testLaunchShowsPlayableEconomyAndLevel() {
        launch()

        XCTAssertTrue(element("hud.money").exists)
        XCTAssertTrue(element("hud.wave").exists)
        XCTAssertTrue(element("hud.cleanliness").exists)
        XCTAssertGreaterThanOrEqual(money(from: element("hud.money").label), 300)
        XCTAssertTrue(app.buttons["wave.start"].exists)
    }

    func testEveryDefenseTypeCanBePurchased() {
        for defense in ["plastic-owl", "sprinkler", "falconer"] {
            launch()
            purchase(defense, at: 1)
            XCTAssertTrue(element("game.toast").waitForExistence(timeout: 2))
            app.terminate()
        }
    }

    func testInsufficientFundsPreservesBudgetAndShowsFeedback() {
        launch()

        let moneyMetric = element("hud.money")
        var availableMoney = money(from: moneyMetric.label)
        var spot = 1
        while availableMoney >= 100, spot <= 7 {
            let defense: String
            if availableMoney >= 300 {
                defense = "falconer"
            } else if availableMoney >= 150 {
                defense = "sprinkler"
            } else {
                defense = "plastic-owl"
            }
            purchase(defense, at: spot)
            availableMoney = money(from: moneyMetric.label)
            spot += 1
        }
        XCTAssertLessThan(availableMoney, 100, "Fixture must permit exhausting city budget")

        let exhaustedLabel = moneyMetric.label
        openBuildMenu(at: spot)
        tap(app.buttons["build.plastic-owl"])
        XCTAssertEqual(moneyMetric.label, exhaustedLabel)
        XCTAssertTrue(element("game.toast").waitForExistence(timeout: 2))
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
        XCTAssertGreaterThan(money(from: element("hud.money").label), -1)
        XCTAssertFalse(
            app.buttons["ui-test.spot.1"].exists && app.buttons["ui-test.spot.1"].isEnabled,
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
        XCTAssertTrue(app.staticTexts["TAUBENFREIE ZONE!"].exists)
        tap(app.buttons["NOCH EINE RUNDE"])
        waitForDisappearance(result)
        waitForExistence(app.buttons["wave.start"])
    }

    func testDefeatFixtureShowsGameOver() {
        launch(fixture: .defeat)

        let result = element("game.result")
        waitForExistence(result, timeout: 8)
        XCTAssertTrue(app.staticTexts["CAFÉ ÜBERGURRT"].exists)
    }
}

@MainActor
final class TauberDefenceMarketingScreenshots: TauberDefenceUITestCase {
    func testAppStoreMarketingScreenshots() {
        snapshot(.default, indicator: "wave.start", name: "marketing-01-marktplatz")
        snapshot(.battle, indicator: "wave.running", name: "marketing-02-abwehr-in-aktion")
        snapshot(.boss, indicator: "wave.running", name: "marketing-03-ruediger")
        snapshot(.victory, indicator: "game.result", name: "marketing-04-sieg")
        snapshot(.defeat, indicator: "game.result", name: "marketing-05-niederlage")
    }

    private func snapshot(_ fixture: Fixture, indicator: String, name: String) {
        launch(fixture: fixture, marketingScreenshot: true)
        waitForExistence(element(indicator), timeout: 8)
        capture(name)
        app.terminate()
    }
}
