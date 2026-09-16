import Foundation
import TauberDefenceCore

/// Launch-only automation switches. Production launches always resolve to `.production`.
struct AutomationLaunchOptions: Equatable {
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

    let isUITesting: Bool
    let isMarketingScreenshot: Bool
    let fixture: Fixture

    static let production = AutomationLaunchOptions(
        isUITesting: false,
        isMarketingScreenshot: false,
        fixture: .default
    )

    static var current: AutomationLaunchOptions {
        #if DEBUG
        parse(arguments: ProcessInfo.processInfo.arguments)
        #else
        .production
        #endif
    }

    var isAutomatedLaunch: Bool {
        isUITesting || isMarketingScreenshot
    }

    var freezesSimulation: Bool {
        isMarketingScreenshot
    }

    static func parse(arguments: [String]) -> AutomationLaunchOptions {
        let isUITesting = arguments.contains("--ui-testing")
        let isMarketingScreenshot = arguments.contains("--marketing-screenshot")

        let fixture: Fixture
        if let flagIndex = arguments.firstIndex(of: "--ui-test-fixture"),
           arguments.indices.contains(flagIndex + 1),
           let parsed = Fixture(rawValue: arguments[flagIndex + 1]) {
            fixture = parsed
        } else {
            fixture = .default
        }

        guard isUITesting || isMarketingScreenshot else { return .production }
        return AutomationLaunchOptions(
            isUITesting: isUITesting,
            isMarketingScreenshot: isMarketingScreenshot,
            fixture: fixture
        )
    }
}

enum AutomationFixtureFactory {
    static func makeSimulation(for options: AutomationLaunchOptions) -> GameSimulation {
        guard options.isAutomatedLaunch else {
            return GameSimulation(level: .marketplace)
        }

        switch options.fixture {
        case .roster:
            let showcase = LevelDefinition(id: "ui-roster", name: "Field trials",
                path: LevelDefinition.marketplace.path, buildSpots: LevelDefinition.marketplace.buildSpots,
                waves: [WaveDefinition(number: 1, groups: PigeonType.allCases.map {
                    WaveGroup(pigeonType: $0, count: 1, spawnInterval: 0.4)
                })])
            var simulation = GameSimulation(level: showcase,
                configuration: automationConfiguration(startingMoney: 2_000))
            for (index, type) in DefenseType.allCases.dropFirst(3).enumerated() {
                try? simulation.purchaseDefense(type, at: index + 1)
            }
            simulation.startNextWave()
            simulation.update(deltaTime: 3.2)
            _ = simulation.consumeEvents()
            return simulation

        case .default, .menu:
            return GameSimulation(
                level: .marketplace,
                configuration: automationConfiguration()
            )

        case .lowBudget:
            return GameSimulation(
                level: .marketplace,
                configuration: automationConfiguration(startingMoney: 350)
            )

        case .battle:
            var simulation = GameSimulation(
                level: .marketplace,
                configuration: automationConfiguration()
            )
            installShowcaseDefenses(in: &simulation)
            _ = simulation.startNextWave()
            simulation.update(deltaTime: 1.25)
            _ = simulation.consumeEvents()
            return simulation

        case .boss:
            var simulation = GameSimulation(
                level: bossLevel,
                configuration: automationConfiguration()
            )
            installShowcaseDefenses(in: &simulation)
            advancePastEmptyWaves(in: &simulation, count: 4)
            _ = simulation.startNextWave()
            simulation.update(deltaTime: 1.15)
            _ = simulation.consumeEvents()
            return simulation

        case .victory:
            var simulation = GameSimulation(
                level: terminalLevel(id: "ui-victory", pigeonCount: 1),
                configuration: automationConfiguration(startingCleanliness: 100)
            )
            _ = simulation.startNextWave()
            simulation.update(deltaTime: 30)
            _ = simulation.consumeEvents()
            return simulation

        case .defeat:
            var simulation = GameSimulation(
                level: terminalLevel(id: "ui-defeat", pigeonCount: 3),
                configuration: automationConfiguration(startingCleanliness: 30)
            )
            _ = simulation.startNextWave()
            simulation.update(deltaTime: 30)
            _ = simulation.consumeEvents()
            return simulation
        }
    }

    private static func automationConfiguration(
        startingMoney: Int = 1_000,
        startingCleanliness: Int = 100
    ) -> SimulationConfiguration {
        SimulationConfiguration(
            startingMoney: startingMoney,
            startingCleanliness: startingCleanliness
        )
    }

    private static func installShowcaseDefenses(in simulation: inout GameSimulation) {
        try? simulation.purchaseDefense(.plasticOwl, at: 1)
        try? simulation.purchaseDefense(.sprinkler, at: 2)
        try? simulation.purchaseDefense(.falconer, at: 3)
    }

    private static func advancePastEmptyWaves(
        in simulation: inout GameSimulation,
        count: Int
    ) {
        for _ in 0..<count {
            _ = simulation.startNextWave()
            simulation.update(deltaTime: 0.1)
        }
    }

    private static let bossLevel = LevelDefinition(
        id: "ui-boss",
        name: LevelDefinition.marketplace.name,
        path: LevelDefinition.marketplace.path,
        buildSpots: LevelDefinition.marketplace.buildSpots,
        waves: [
            WaveDefinition(number: 1, groups: []),
            WaveDefinition(number: 2, groups: []),
            WaveDefinition(number: 3, groups: []),
            WaveDefinition(number: 4, groups: []),
            WaveDefinition(
                number: 5,
                groups: [WaveGroup(pigeonType: .ruediger, count: 1, spawnInterval: 1)]
            ),
        ]
    )

    private static func terminalLevel(id: String, pigeonCount: Int) -> LevelDefinition {
        LevelDefinition(
            id: id,
            name: LevelDefinition.marketplace.name,
            path: LevelDefinition.marketplace.path,
            buildSpots: LevelDefinition.marketplace.buildSpots,
            waves: [
                WaveDefinition(
                    number: 1,
                    groups: [
                        WaveGroup(
                            pigeonType: .normal,
                            count: pigeonCount,
                            spawnInterval: 0
                        ),
                    ]
                ),
            ]
        )
    }
}
