import XCTest
import TauberDefenceCore

final class MovementSystemTests: XCTestCase {
    func testPathInterpolatesAcrossSegmentsAndClampsAtEnds() {
        let path = PathDefinition(waypoints: [
            Waypoint(x: 0, z: 0),
            Waypoint(x: 3, z: 0),
            Waypoint(x: 3, z: 4),
        ])

        XCTAssertEqual(path.totalLength, 7, accuracy: 0.000_001)
        XCTAssertEqual(path.position(atDistance: -1), Waypoint(x: 0, z: 0))
        XCTAssertEqual(path.position(atDistance: 1.5), Waypoint(x: 1.5, z: 0))
        XCTAssertEqual(path.position(atDistance: 5), Waypoint(x: 3, z: 2))
        XCTAssertEqual(path.position(atDistance: 50), Waypoint(x: 3, z: 4))
    }

    func testPigeonMovesAtConstantSpeedAfterSpawning() throws {
        var simulation = GameSimulation(
            level: TestFixtures.level(),
            configuration: TestFixtures.configuration()
        )

        XCTAssertTrue(simulation.startNextWave())
        XCTAssertEqual(simulation.session.pigeons.count, 1)
        XCTAssertEqual(simulation.session.pigeons[0].state, .spawning)

        simulation.update(deltaTime: 0.1)
        XCTAssertEqual(simulation.session.pigeons[0].state, .moving)
        XCTAssertEqual(simulation.session.pigeons[0].distanceAlongPath, 0, accuracy: 0.000_001)

        simulation.update(deltaTime: 0.5)
        let pigeon = try XCTUnwrap(simulation.session.pigeons.first)
        XCTAssertEqual(pigeon.distanceAlongPath, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(pigeon.position.x, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(pigeon.position.z, 0, accuracy: 0.000_001)
    }

    func testFixedStepProducesSameStateForChunkedAndBatchedUpdates() throws {
        let level = TestFixtures.level()
        let configuration = TestFixtures.configuration()
        var batched = GameSimulation(level: level, configuration: configuration)
        var chunked = GameSimulation(level: level, configuration: configuration)
        XCTAssertTrue(batched.startNextWave())
        XCTAssertTrue(chunked.startNextWave())

        batched.update(deltaTime: 0.6)
        for _ in 0..<6 {
            chunked.update(deltaTime: 0.1)
        }

        let batchedPigeon = try XCTUnwrap(batched.session.pigeons.first)
        let chunkedPigeon = try XCTUnwrap(chunked.session.pigeons.first)
        XCTAssertEqual(batchedPigeon, chunkedPigeon)
        XCTAssertEqual(batched.session.simulationTime, chunked.session.simulationTime, accuracy: 0.000_001)
        XCTAssertEqual(batched.session.waveElapsedTime, chunked.session.waveElapsedTime, accuracy: 0.000_001)
        XCTAssertEqual(batched.events, chunked.events)
    }
}
