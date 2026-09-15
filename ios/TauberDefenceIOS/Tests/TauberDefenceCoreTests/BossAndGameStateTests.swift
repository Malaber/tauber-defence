import XCTest
import TauberDefenceCore

final class BossAndGameStateTests: XCTestCase {
    func testDefaultSessionUsesSpecifiedEconomyAndCleanlinessValues() {
        let session = GameSession(level: TestFixtures.level())

        XCTAssertEqual(session.money, 300)
        XCTAssertEqual(session.cleanliness, 100)
        XCTAssertEqual(session.configuration.cleanlinessLossPerArrival, 10)
        XCTAssertEqual(session.phase, .preparing)
        XCTAssertNil(session.currentWaveNumber)
        XCTAssertFalse(session.isPaused)
    }

    func testRuedigerHasBossStatsAndAwardsFiveHundredEurosOnFlee() throws {
        XCTAssertEqual(PigeonType.ruediger.maxTolerance, 1_000)
        XCTAssertEqual(PigeonType.ruediger.speed, 0.7)
        XCTAssertEqual(PigeonType.ruediger.reward, 500)

        let sharedSpots = Array(repeating: Waypoint(x: 3, z: 0), count: 8)
        let level = TestFixtures.level(
            buildSpotPositions: sharedSpots,
            waves: [TestFixtures.wave(type: .ruediger)]
        )
        var simulation = GameSimulation(
            level: level,
            configuration: TestFixtures.configuration(money: 2_400)
        )
        for spotID in 1...8 {
            _ = try simulation.purchaseDefense(.falconer, at: spotID)
        }
        XCTAssertTrue(simulation.startNextWave())
        XCTAssertEqual(simulation.session.pigeons[0].type, .ruediger)
        XCTAssertEqual(simulation.session.pigeons[0].currentTolerance, 1_000)

        simulation.update(deltaTime: 0.6)
        XCTAssertEqual(simulation.session.pigeons[0].currentTolerance, 440)
        XCTAssertNotEqual(simulation.session.pigeons[0].state, .fleeing)

        simulation.update(deltaTime: 3)
        let ruediger = try XCTUnwrap(simulation.session.pigeons.first)
        XCTAssertEqual(ruediger.state, .fleeing)
        XCTAssertEqual(ruediger.currentTolerance, 0)
        XCTAssertEqual(simulation.session.money, 500)
        XCTAssertTrue(
            simulation.events.contains(
                .pigeonFled(id: ruediger.id, reward: 500, position: ruediger.position)
            )
        )
    }

    func testTenArrivalsReduceCleanlinessToZeroAndCauseDefeat() {
        let level = TestFixtures.level(
            path: TestFixtures.shortPath,
            waves: [TestFixtures.wave(count: 10)]
        )
        var simulation = GameSimulation(
            level: level,
            configuration: TestFixtures.configuration()
        )
        XCTAssertTrue(simulation.startNextWave())

        simulation.update(deltaTime: 0.2)

        XCTAssertEqual(simulation.session.cleanliness, 0)
        XCTAssertEqual(simulation.session.phase, .defeat)
        XCTAssertTrue(simulation.session.isGameOver)
        XCTAssertTrue(simulation.events.contains(.defeat))
        let arrivalEvents = simulation.events.filter {
            if case .pigeonReachedTarget = $0 { return true }
            return false
        }
        XCTAssertEqual(arrivalEvents.count, 10)
    }

    func testSurvivingFinalWaveCausesVictory() {
        let level = TestFixtures.level(path: TestFixtures.shortPath)
        var simulation = GameSimulation(
            level: level,
            configuration: TestFixtures.configuration()
        )
        XCTAssertTrue(simulation.startNextWave())

        simulation.update(deltaTime: 0.3)

        XCTAssertEqual(simulation.session.cleanliness, 90)
        XCTAssertEqual(simulation.session.phase, .victory)
        XCTAssertTrue(simulation.session.isGameOver)
        XCTAssertTrue(
            simulation.events.contains(
                .pigeonReachedTarget(id: 1, cleanlinessLoss: 10)
            )
        )
        XCTAssertTrue(
            simulation.events.contains(
                .cleanlinessChanged(delta: -10, total: 90)
            )
        )
        XCTAssertTrue(simulation.events.contains(.waveCompleted(number: 1)))
        XCTAssertTrue(simulation.events.contains(.victory))
    }

    func testPauseFreezesSimulationAndResetRestoresInitialState() throws {
        var simulation = GameSimulation(
            level: TestFixtures.level(),
            configuration: TestFixtures.configuration()
        )
        _ = try simulation.purchaseDefense(.plasticOwl, at: 1)
        XCTAssertTrue(simulation.startNextWave())
        simulation.update(deltaTime: 0.2)
        let beforePause = simulation.session

        simulation.setPaused(true)
        XCTAssertTrue(simulation.session.isPaused)
        simulation.update(deltaTime: 50)
        XCTAssertEqual(simulation.session.simulationTime, beforePause.simulationTime)
        XCTAssertEqual(simulation.session.pigeons, beforePause.pigeons)
        XCTAssertFalse(simulation.startNextWave())

        simulation.togglePause()
        XCTAssertFalse(simulation.session.isPaused)
        simulation.update(deltaTime: 0.1)
        XCTAssertGreaterThan(
            simulation.session.pigeons[0].distanceAlongPath,
            beforePause.pigeons[0].distanceAlongPath
        )

        simulation.reset()
        XCTAssertEqual(simulation.session.phase, .preparing)
        XCTAssertNil(simulation.session.currentWaveNumber)
        XCTAssertEqual(simulation.session.money, 300)
        XCTAssertEqual(simulation.session.cleanliness, 100)
        XCTAssertTrue(simulation.session.pigeons.isEmpty)
        XCTAssertTrue(simulation.session.defenses.isEmpty)
        XCTAssertFalse(simulation.session.buildSpots[0].isOccupied)
        XCTAssertEqual(simulation.events, [.sessionReset])
        XCTAssertEqual(try simulation.purchaseDefense(.plasticOwl, at: 1), 1)
    }

    func testPurchasesAreRejectedAfterGameEnds() {
        let level = TestFixtures.level(
            path: TestFixtures.shortPath,
            waves: [TestFixtures.wave(count: 10)]
        )
        var simulation = GameSimulation(
            level: level,
            configuration: TestFixtures.configuration()
        )
        XCTAssertTrue(simulation.startNextWave())
        simulation.update(deltaTime: 0.2)

        do {
            _ = try simulation.purchaseDefense(.plasticOwl, at: 1)
            XCTFail("Expected a completed game to reject purchases")
        } catch let error as PurchaseError {
            XCTAssertEqual(error, .gameEnded)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
