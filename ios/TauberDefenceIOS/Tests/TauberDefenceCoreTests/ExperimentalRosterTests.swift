import XCTest
@testable import TauberDefenceCore

final class ExperimentalRosterTests: XCTestCase {
    func testCatalogAndTrialWavesIncludeEveryPrototype() throws {
        XCTAssertEqual(PigeonType.allCases.count, 8)
        XCTAssertEqual(DefenseType.allCases.count, 9)
        XCTAssertEqual(Set(LevelDefinition.fieldTrials.waves.flatMap(\.groups).map(\.pigeonType)), Set(PigeonType.allCases))
        for type in PigeonType.allCases {
            XCTAssertGreaterThan(type.maxTolerance, 0)
            XCTAssertGreaterThan(type.speed, 0)
            XCTAssertGreaterThan(type.reward, 0)
            XCTAssertFalse(type.iconName.isEmpty)
            XCTAssertEqual(try JSONDecoder().decode(PigeonType.self, from: JSONEncoder().encode(type)), type)
        }
        for type in DefenseType.allCases {
            XCTAssertGreaterThan(type.cost, 0)
            XCTAssertGreaterThan(type.range, 0)
            XCTAssertGreaterThan(type.cooldown, 0)
            XCTAssertFalse(type.iconName.isEmpty)
            XCTAssertGreaterThanOrEqual(type.impactDelay, 0)
            XCTAssertGreaterThanOrEqual(type.disruptionDuration, 0)
        }
    }

    func testEveryDefenseFiresWithItsDeclaredTargetingAndEffect() throws {
        for type in DefenseType.allCases {
            var sim = GameSimulation(level: TestFixtures.level(buildSpotPositions: [.init(x: 0, z: 0)],
                waves: [TestFixtures.wave(type: .dieter, count: 2)]), configuration: TestFixtures.configuration(money: 2_000))
            try sim.purchaseDefense(type, at: 1)
            XCTAssertEqual(sim.session.money, 2_000 - type.cost)
            sim.startNextWave()
            sim.update(deltaTime: 0.7)
            let hitCount = type.targetingMode == .area ? 2 : 1
            XCTAssertEqual(sim.session.defenses[0].targetPigeonIDs.count, hitCount, "\(type)")
            XCTAssertEqual(sim.session.pigeons[0].currentTolerance, 280 - type.pressure, accuracy: 0.001, "\(type)")
            if type.slowFraction > 0 {
                XCTAssertEqual(sim.session.pigeons[0].speedMultiplier(at: sim.session.simulationTime), 1 - type.slowFraction, accuracy: 0.001)
            }
            if type.disruptionDuration > 0 {
                XCTAssertGreaterThan(sim.session.pigeons[0].disruptedUntil, sim.session.simulationTime)
            }
        }
    }

    func testVeteranAdaptsButMixedPressureRecovers() {
        var veteran = bird(.volker)
        veteran.lastPressureCategory = .visual
        XCTAssertEqual(veteran.pressureMultiplier(category: .visual, nearby: [], at: 3), 0.55)
        XCTAssertEqual(veteran.pressureMultiplier(category: .water, nearby: [], at: 3), 1)
        XCTAssertEqual(veteran.pressureMultiplier(category: .sound, nearby: [], at: 3), 1.3)
        veteran.lastPressureCategory = .sound
        XCTAssertEqual(veteran.pressureMultiplier(category: .sound, nearby: [], at: 3), 0.385, accuracy: 0.001)
    }

    func testFlockProtectionHasRangeTimingAndDisruptionCounters() {
        var target = bird(.coalition)
        var ingo = bird(.ingo, id: 2)
        let coalition = bird(.coalition, id: 3)
        let director = bird(.gurrmann, id: 4)
        XCTAssertEqual(target.pressureMultiplier(category: .water, nearby: [ingo, coalition, director], at: 1), 0.28, accuracy: 0.001)
        XCTAssertEqual(target.pressureMultiplier(category: .water, nearby: [director], at: 3), 1)
        target.disruptedUntil = 5
        XCTAssertEqual(target.pressureMultiplier(category: .water, nearby: [ingo, coalition, director], at: 1), 1)
        target.disruptedUntil = 0
        ingo.disruptedUntil = 5
        XCTAssertEqual(target.pressureMultiplier(category: .water, nearby: [ingo], at: 1), 1)
        ingo.disruptedUntil = 0
        ingo.position = .init(x: 20, z: 0)
        XCTAssertEqual(target.pressureMultiplier(category: .water, nearby: [ingo], at: 1), 1)
        XCTAssertEqual(director.pressureMultiplier(category: .water, nearby: [], at: 1), 0.5)
    }

    func testTapeDisruptsProtectionBeforeApplyingPressure() throws {
        var sim = GameSimulation(level: TestFixtures.level(buildSpotPositions: [.init(x: 0, z: 0)],
            waves: [TestFixtures.wave(type: .gurrmann)]), configuration: TestFixtures.configuration())
        try sim.purchaseDefense(.flutterTape, at: 1)
        sim.startNextWave()
        sim.update(deltaTime: 0.1)
        XCTAssertEqual(sim.session.pigeons[0].currentTolerance, 394)
    }

    func testStrongSlowIsNotReplacedByWeakerSlowAndExpires() throws {
        var sim = GameSimulation(level: TestFixtures.level(buildSpotPositions: [.init(x: 0, z: 0), .init(x: 0, z: 0)]),
            configuration: TestFixtures.configuration(money: 500))
        try sim.purchaseDefense(.decoy, at: 1)
        try sim.purchaseDefense(.sprinkler, at: 2)
        sim.startNextWave()
        sim.update(deltaTime: 0.1)
        XCTAssertEqual(sim.session.pigeons[0].speedMultiplier(at: 0.1), 0.35, accuracy: 0.001)
        XCTAssertEqual(sim.session.pigeons[0].speedMultiplier(at: 10), 1)
        XCTAssertEqual(sim.session.pigeons[0].currentTolerance, 90)
    }

    private func bird(_ type: PigeonType, id: Int = 1) -> Pigeon {
        Pigeon(id: id, type: type, state: .moving, position: .init(x: 0, z: 0))
    }
}
