import Foundation
import XCTest
import TauberDefenceCore

final class WaveSystemTests: XCTestCase {
    func testMarketplaceContainsRequiredMapAndFiveDataDrivenWaves() {
        let level = LevelDefinition.marketplace

        XCTAssertEqual(level.id, "marketplace")
        XCTAssertEqual(level.buildSpots.count, 8)
        XCTAssertEqual(level.waves.map(\.number), [1, 2, 3, 4, 5])
        XCTAssertEqual(level.waves.map(\.pigeonCount), [5, 10, 15, 20, 1])
        XCTAssertEqual(level.waves[0].groups[0].spawnInterval, 1.0)
        XCTAssertEqual(level.waves[1].groups[0].spawnInterval, 1.0)
        XCTAssertEqual(level.waves[2].groups[0].spawnInterval, 0.9)
        XCTAssertEqual(level.waves[3].groups[0].spawnInterval, 0.8)
        XCTAssertEqual(level.waves[4].groups[0].pigeonType, .ruediger)
    }

    func testWaveSpawnsGroupsAtTheirScheduledIntervals() {
        let level = TestFixtures.level(
            waves: [TestFixtures.wave(count: 3, interval: 1)]
        )
        var simulation = GameSimulation(
            level: level,
            configuration: TestFixtures.configuration()
        )

        XCTAssertTrue(simulation.startNextWave())
        XCTAssertEqual(simulation.session.pigeons.count, 1)

        simulation.update(deltaTime: 0.9)
        XCTAssertEqual(simulation.session.pigeons.count, 1)

        simulation.update(deltaTime: 0.1)
        XCTAssertEqual(simulation.session.pigeons.count, 2)
        XCTAssertEqual(simulation.session.pigeons[1].state, .spawning)

        simulation.update(deltaTime: 1)
        XCTAssertEqual(simulation.session.pigeons.count, 3)
        XCTAssertEqual(simulation.session.pigeons.map(\.id), [1, 2, 3])
    }

    func testWaveDefinitionDecodesPlanJSONSchema() throws {
        let json = Data(
            #"{"wave":1,"groups":[{"pigeon":"normal","count":10,"spawnInterval":1.0}]}"#.utf8
        )

        let wave = try JSONDecoder().decode(WaveDefinition.self, from: json)

        XCTAssertEqual(wave.number, 1)
        XCTAssertEqual(wave.groups.count, 1)
        XCTAssertEqual(wave.groups[0].pigeonType, .normal)
        XCTAssertEqual(wave.groups[0].count, 10)
        XCTAssertEqual(wave.groups[0].spawnInterval, 1)
        XCTAssertEqual(wave.groups[0].initialDelay, 0)
        let encoded = try JSONEncoder().encode(wave)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        XCTAssertEqual(object["wave"] as? Int, 1)
        XCTAssertNil(object["id"])
    }

    func testSimultaneousGroupsPreserveDefinitionOrder() {
        let wave = WaveDefinition(
            number: 1,
            groups: [
                WaveGroup(pigeonType: .ruediger, count: 1, spawnInterval: 0),
                WaveGroup(pigeonType: .normal, count: 1, spawnInterval: 0),
            ]
        )
        var simulation = GameSimulation(
            level: TestFixtures.level(waves: [wave]),
            configuration: TestFixtures.configuration()
        )

        XCTAssertTrue(simulation.startNextWave())

        XCTAssertEqual(simulation.session.pigeons.map(\.id), [1, 2])
        XCTAssertEqual(simulation.session.pigeons.map(\.type), [.ruediger, .normal])
    }

    func testAllFiveWavesAdvanceInOrderAndFinalWaveWins() {
        let level = TestFixtures.level(
            path: TestFixtures.shortPath,
            buildSpotPositions: LevelDefinition.marketplace.buildSpots.map(\.position),
            waves: LevelDefinition.marketplace.waves
        )
        var simulation = GameSimulation(
            level: level,
            configuration: TestFixtures.configuration(cleanliness: 10_000)
        )

        for expectedWave in 1...5 {
            XCTAssertTrue(simulation.startNextWave())
            XCTAssertEqual(simulation.session.currentWaveNumber, expectedWave)
            XCTAssertFalse(simulation.startNextWave())

            simulation.update(deltaTime: 30)
            XCTAssertEqual(
                simulation.session.phase,
                expectedWave == 5 ? .victory : .waveComplete
            )

            let events = simulation.consumeEvents()
            let spawnedCount = events.filter {
                if case .pigeonSpawned = $0 { return true }
                return false
            }.count
            XCTAssertEqual(spawnedCount, level.waves[expectedWave - 1].pigeonCount)
            XCTAssertTrue(events.contains(.waveCompleted(number: expectedWave)))
        }

        XCTAssertEqual(simulation.session.cleanliness, 9_490)
        XCTAssertFalse(simulation.startNextWave())
        XCTAssertTrue(simulation.events.isEmpty)
    }
}
