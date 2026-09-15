import TauberDefenceCore

enum TestFixtures {
    static let longPath = PathDefinition(waypoints: [
        Waypoint(x: 0, z: 0),
        Waypoint(x: 100, z: 0),
    ])

    static let shortPath = PathDefinition(waypoints: [
        Waypoint(x: 0, z: 0),
        Waypoint(x: 0.1, z: 0),
    ])

    static func wave(
        number: Int = 1,
        type: PigeonType = .normal,
        count: Int = 1,
        interval: Double = 0
    ) -> WaveDefinition {
        WaveDefinition(
            number: number,
            groups: [
                WaveGroup(
                    pigeonType: type,
                    count: count,
                    spawnInterval: interval
                ),
            ]
        )
    }

    static func level(
        path: PathDefinition? = nil,
        buildSpotPositions: [Waypoint] = [Waypoint(x: 2.7, z: 0)],
        waves: [WaveDefinition]? = nil
    ) -> LevelDefinition {
        LevelDefinition(
            id: "test-level",
            name: "Test Level",
            path: path ?? longPath,
            buildSpots: buildSpotPositions.enumerated().map { index, position in
                BuildSpot(id: index + 1, position: position)
            },
            waves: waves ?? [wave()]
        )
    }

    static func configuration(
        money: Int = 300,
        cleanliness: Int = 100,
        cleanlinessLoss: Int = 10,
        fixedTimeStep: Double = 0.1,
        slowDuration: Double = 1.5,
        fleeDuration: Double = 0.75,
        reachedTargetRemovalDelay: Double = 0.1,
        fleeHeight: Double = 3
    ) -> SimulationConfiguration {
        SimulationConfiguration(
            startingMoney: money,
            startingCleanliness: cleanliness,
            cleanlinessLossPerArrival: cleanlinessLoss,
            fixedTimeStep: fixedTimeStep,
            sprinklerSlowDuration: slowDuration,
            fleeDuration: fleeDuration,
            reachedTargetRemovalDelay: reachedTargetRemovalDelay,
            fleeHeight: fleeHeight
        )
    }
}
