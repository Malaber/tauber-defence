import XCTest
import TauberDefenceCore

final class EconomyAndDefenseSystemTests: XCTestCase {
    func testDefenseCatalogUsesVerticalSliceBalanceValues() {
        XCTAssertEqual(DefenseType.allCases, [.plasticOwl, .sprinkler, .falconer])

        XCTAssertEqual(DefenseType.plasticOwl.cost, 100)
        XCTAssertEqual(DefenseType.plasticOwl.range, 2.8)
        XCTAssertEqual(DefenseType.plasticOwl.cooldown, 1.8)
        XCTAssertEqual(DefenseType.plasticOwl.pressure, 25)
        XCTAssertEqual(DefenseType.plasticOwl.targetingMode, .single)

        XCTAssertEqual(DefenseType.sprinkler.cost, 150)
        XCTAssertEqual(DefenseType.sprinkler.range, 2.2)
        XCTAssertEqual(DefenseType.sprinkler.cooldown, 1.25)
        XCTAssertEqual(DefenseType.sprinkler.pressure, 10)
        XCTAssertEqual(DefenseType.sprinkler.targetingMode, .area)
        XCTAssertEqual(DefenseType.sprinkler.slowFraction, 0.2)

        XCTAssertEqual(DefenseType.falconer.cost, 300)
        XCTAssertEqual(DefenseType.falconer.range, 4.5)
        XCTAssertEqual(DefenseType.falconer.cooldown, 3)
        XCTAssertEqual(DefenseType.falconer.pressure, 70)
        XCTAssertEqual(DefenseType.falconer.targetingMode, .single)
        XCTAssertEqual(DefenseType.falconer.impactDelay, 0.5)
    }

    func testPurchasesDeductMoneyOccupySpotsAndAssignStableIDs() throws {
        let level = TestFixtures.level(buildSpotPositions: [
            Waypoint(x: 1, z: 0),
            Waypoint(x: 2, z: 0),
            Waypoint(x: 3, z: 0),
        ])
        var simulation = GameSimulation(
            level: level,
            configuration: TestFixtures.configuration(money: 550)
        )

        XCTAssertEqual(try simulation.purchaseDefense(.plasticOwl, at: 1), 1)
        XCTAssertEqual(try simulation.purchaseDefense(.sprinkler, at: 2), 2)
        XCTAssertEqual(try simulation.purchaseDefense(.falconer, at: 3), 3)
        XCTAssertEqual(simulation.session.money, 0)
        XCTAssertEqual(simulation.session.defenses.map(\.type), [.plasticOwl, .sprinkler, .falconer])
        XCTAssertEqual(simulation.session.buildSpots.map(\.occupiedByDefenseID), [1, 2, 3])
        XCTAssertTrue(simulation.session.buildSpots.allSatisfy { $0.isOccupied })
    }

    func testPurchaseRulesRejectInvalidOccupiedAndUnaffordableSpots() throws {
        var simulation = GameSimulation(
            level: TestFixtures.level(buildSpotPositions: [
                Waypoint(x: 1, z: 0),
                Waypoint(x: 2, z: 0),
            ]),
            configuration: TestFixtures.configuration(money: 100)
        )

        assertPurchaseError(.invalidBuildSpot(99)) {
            try simulation.purchaseDefense(.plasticOwl, at: 99)
        }
        XCTAssertEqual(try simulation.purchaseDefense(.plasticOwl, at: 1), 1)
        assertPurchaseError(.buildSpotOccupied(1)) {
            try simulation.purchaseDefense(.plasticOwl, at: 1)
        }
        assertPurchaseError(.insufficientFunds(required: 100, available: 0)) {
            try simulation.purchaseDefense(.plasticOwl, at: 2)
        }
        XCTAssertEqual(simulation.session.defenses.count, 1)
    }

    func testOwlUsesNearestTargetAndHonorsRangeAndCooldown() throws {
        let level = TestFixtures.level(
            buildSpotPositions: [Waypoint(x: 2.7, z: 0)],
            waves: [TestFixtures.wave(count: 2)]
        )
        var simulation = GameSimulation(
            level: level,
            configuration: TestFixtures.configuration()
        )
        _ = try simulation.purchaseDefense(.plasticOwl, at: 1)
        XCTAssertTrue(simulation.startNextWave())

        simulation.update(deltaTime: 0.1)
        XCTAssertEqual(simulation.session.pigeons[0].currentTolerance, 75)
        XCTAssertEqual(simulation.session.pigeons[1].currentTolerance, 100)
        XCTAssertEqual(simulation.session.defenses[0].currentTargetID, 1)
        XCTAssertEqual(simulation.session.defenses[0].cooldownRemaining, 1.8, accuracy: 0.000_001)

        simulation.update(deltaTime: 1.7)
        XCTAssertEqual(simulation.session.pigeons[0].currentTolerance, 75)
        XCTAssertEqual(simulation.session.defenses[0].currentTargetID, 1)

        simulation.update(deltaTime: 0.1)
        XCTAssertEqual(simulation.session.pigeons[0].currentTolerance, 50)

        let farLevel = TestFixtures.level(
            buildSpotPositions: [Waypoint(x: 0, z: 10)]
        )
        var outOfRange = GameSimulation(
            level: farLevel,
            configuration: TestFixtures.configuration()
        )
        _ = try outOfRange.purchaseDefense(.plasticOwl, at: 1)
        XCTAssertTrue(outOfRange.startNextWave())
        _ = outOfRange.consumeEvents()
        outOfRange.update(deltaTime: 2)
        XCTAssertEqual(outOfRange.session.pigeons[0].currentTolerance, 100)
        XCTAssertFalse(outOfRange.events.contains { event in
            if case .defenseFired = event { return true }
            return false
        })
    }

    func testSprinklerAppliesAreaPressureAndTwentyPercentSlow() throws {
        let level = TestFixtures.level(
            buildSpotPositions: [Waypoint(x: 0, z: 0)],
            waves: [TestFixtures.wave(count: 2)]
        )
        var simulation = GameSimulation(
            level: level,
            configuration: TestFixtures.configuration()
        )
        _ = try simulation.purchaseDefense(.sprinkler, at: 1)
        XCTAssertTrue(simulation.startNextWave())
        simulation.update(deltaTime: 0.1)

        XCTAssertEqual(simulation.session.pigeons.map(\.currentTolerance), [90, 90])
        XCTAssertEqual(simulation.session.defenses[0].targetPigeonIDs, [1, 2])
        XCTAssertEqual(
            simulation.session.pigeons[0].speedMultiplier(at: simulation.session.simulationTime),
            0.8,
            accuracy: 0.000_001
        )

        simulation.update(deltaTime: 0.5)
        XCTAssertEqual(simulation.session.pigeons[0].distanceAlongPath, 0.4, accuracy: 0.000_001)
        XCTAssertEqual(simulation.session.pigeons[1].distanceAlongPath, 0.4, accuracy: 0.000_001)
        let slowEvents = simulation.events.filter {
            if case .slowApplied = $0 { return true }
            return false
        }
        XCTAssertEqual(slowEvents.count, 2)
        XCTAssertTrue(
            slowEvents.contains(
                .slowApplied(pigeonID: 1, fraction: 0.2, duration: 1.5)
            )
        )
    }

    func testFalconPressureArrivesAfterHalfSecondDelay() throws {
        let level = TestFixtures.level(buildSpotPositions: [Waypoint(x: 0, z: 0)])
        var simulation = GameSimulation(
            level: level,
            configuration: TestFixtures.configuration()
        )
        let defenseID = try simulation.purchaseDefense(.falconer, at: 1)
        XCTAssertTrue(simulation.startNextWave())
        simulation.update(deltaTime: 0.1)

        XCTAssertEqual(simulation.session.pigeons[0].currentTolerance, 100)
        XCTAssertEqual(simulation.session.defenses[0].currentTargetID, 1)
        XCTAssertTrue(
            simulation.events.contains(
                .falconLaunched(defenseID: defenseID, pigeonID: 1, impactDelay: 0.5)
            )
        )

        simulation.update(deltaTime: 0.4)
        XCTAssertEqual(simulation.session.pigeons[0].currentTolerance, 100)
        simulation.update(deltaTime: 0.1)
        XCTAssertEqual(simulation.session.pigeons[0].currentTolerance, 30)
        XCTAssertEqual(simulation.session.pigeons[0].state, .alert)
    }

    private func assertPurchaseError(
        _ expected: PurchaseError,
        operation: () throws -> Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            _ = try operation()
            XCTFail("Expected purchase to fail with \(expected)", file: file, line: line)
        } catch let error as PurchaseError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
