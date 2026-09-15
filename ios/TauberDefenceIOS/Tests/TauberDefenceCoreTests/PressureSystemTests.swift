import XCTest
import TauberDefenceCore

final class PressureSystemTests: XCTestCase {
    func testOwlPressureTransitionsPigeonToAlertPanicAndFlee() throws {
        var simulation = GameSimulation(
            level: TestFixtures.level(),
            configuration: TestFixtures.configuration()
        )
        XCTAssertEqual(try simulation.purchaseDefense(.plasticOwl, at: 1), 1)
        XCTAssertTrue(simulation.startNextWave())

        simulation.update(deltaTime: 0.1)
        var pigeon = try XCTUnwrap(simulation.session.pigeons.first)
        XCTAssertEqual(pigeon.currentTolerance, 75, accuracy: 0.000_001)
        XCTAssertEqual(pigeon.state, .moving)

        simulation.update(deltaTime: 1.8)
        pigeon = try XCTUnwrap(simulation.session.pigeons.first)
        XCTAssertEqual(pigeon.currentTolerance, 50, accuracy: 0.000_001)
        XCTAssertEqual(pigeon.state, .alert)

        simulation.update(deltaTime: 1.8)
        pigeon = try XCTUnwrap(simulation.session.pigeons.first)
        XCTAssertEqual(pigeon.currentTolerance, 25, accuracy: 0.000_001)
        XCTAssertEqual(pigeon.state, .panicking)

        simulation.update(deltaTime: 1.8)
        pigeon = try XCTUnwrap(simulation.session.pigeons.first)
        XCTAssertEqual(pigeon.currentTolerance, 0, accuracy: 0.000_001)
        XCTAssertEqual(pigeon.state, .fleeing)
        XCTAssertEqual(simulation.session.money, 210)

        let pressureEvents = simulation.events.filter {
            if case .pressureApplied = $0 { return true }
            return false
        }
        XCTAssertEqual(pressureEvents.count, 4)
        XCTAssertTrue(simulation.events.contains(.pigeonFled(id: 1, reward: 10, position: pigeon.position)))
        XCTAssertTrue(
            simulation.events.contains(
                .moneyChanged(delta: 10, total: 210, reason: .pigeonReward)
            )
        )
    }

    func testFleeingPigeonRisesThenIsRemovedWithoutCleanlinessLoss() throws {
        var simulation = GameSimulation(
            level: TestFixtures.level(),
            configuration: TestFixtures.configuration()
        )
        _ = try simulation.purchaseDefense(.plasticOwl, at: 1)
        XCTAssertTrue(simulation.startNextWave())
        simulation.update(deltaTime: 5.5)
        XCTAssertEqual(try XCTUnwrap(simulation.session.pigeons.first).state, .fleeing)

        simulation.update(deltaTime: 0.4)
        let ascendingPigeon = try XCTUnwrap(simulation.session.pigeons.first)
        XCTAssertEqual(ascendingPigeon.state, .fleeing)
        XCTAssertGreaterThan(ascendingPigeon.flightHeight, 0)
        XCTAssertLessThan(ascendingPigeon.flightHeight, 3)

        simulation.update(deltaTime: 0.4)
        XCTAssertTrue(simulation.session.pigeons.isEmpty)
        XCTAssertEqual(simulation.session.cleanliness, 100)
        XCTAssertEqual(simulation.session.phase, .victory)
        XCTAssertTrue(simulation.events.contains(.pigeonRemoved(id: 1)))
    }

    func testSimultaneousFleesEmitComboEvent() throws {
        let sharedSpots = Array(repeating: Waypoint(x: 2.7, z: 0), count: 8)
        let level = TestFixtures.level(
            buildSpotPositions: sharedSpots,
            waves: [TestFixtures.wave(count: 2)]
        )
        var simulation = GameSimulation(
            level: level,
            configuration: TestFixtures.configuration(money: 1_000)
        )
        for spotID in 1...8 {
            _ = try simulation.purchaseDefense(.plasticOwl, at: spotID)
        }
        XCTAssertTrue(simulation.startNextWave())

        simulation.update(deltaTime: 0.1)

        XCTAssertEqual(simulation.session.pigeons.map(\.state), [.fleeing, .fleeing])
        XCTAssertEqual(simulation.session.money, 220)
        XCTAssertTrue(simulation.events.contains(.shooCombo(count: 2)))
    }
}
