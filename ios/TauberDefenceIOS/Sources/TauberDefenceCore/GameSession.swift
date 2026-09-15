import Foundation

public struct SimulationConfiguration: Codable, Hashable, Sendable {
    public let startingMoney: Int
    public let startingCleanliness: Int
    public let cleanlinessLossPerArrival: Int
    public let fixedTimeStep: Double
    public let sprinklerSlowDuration: Double
    public let fleeDuration: Double
    public let reachedTargetRemovalDelay: Double
    public let fleeHeight: Double

    public init(
        startingMoney: Int = 300,
        startingCleanliness: Int = 100,
        cleanlinessLossPerArrival: Int = 10,
        fixedTimeStep: Double = 1.0 / 60.0,
        sprinklerSlowDuration: Double = 1.5,
        fleeDuration: Double = 0.75,
        reachedTargetRemovalDelay: Double = 0.1,
        fleeHeight: Double = 3.0
    ) {
        precondition(startingMoney >= 0)
        precondition(startingCleanliness > 0)
        precondition(cleanlinessLossPerArrival > 0)
        precondition(fixedTimeStep > 0)
        precondition(sprinklerSlowDuration >= 0)
        precondition(fleeDuration > 0)
        precondition(reachedTargetRemovalDelay >= 0)
        precondition(fleeHeight >= 0)
        self.startingMoney = startingMoney
        self.startingCleanliness = startingCleanliness
        self.cleanlinessLossPerArrival = cleanlinessLossPerArrival
        self.fixedTimeStep = fixedTimeStep
        self.sprinklerSlowDuration = sprinklerSlowDuration
        self.fleeDuration = fleeDuration
        self.reachedTargetRemovalDelay = reachedTargetRemovalDelay
        self.fleeHeight = fleeHeight
    }
}

public enum GamePhase: String, CaseIterable, Codable, Hashable, Sendable {
    case preparing
    case waveRunning
    case waveComplete
    case victory
    case defeat
}

public enum MoneyChangeReason: String, Codable, Hashable, Sendable {
    case defensePurchase
    case pigeonReward
}

public enum PurchaseError: Error, Equatable, Sendable {
    case invalidBuildSpot(Int)
    case buildSpotOccupied(Int)
    case insufficientFunds(required: Int, available: Int)
    case gameEnded
}

extension PurchaseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidBuildSpot(id):
            "Build spot \(id) does not exist."
        case let .buildSpotOccupied(id):
            "Build spot \(id) is already occupied."
        case let .insufficientFunds(required, available):
            "This defense costs €\(required), but only €\(available) is available."
        case .gameEnded:
            "Defenses cannot be purchased after the game has ended."
        }
    }
}

public enum GameEvent: Equatable, Sendable {
    case waveStarted(number: Int)
    case waveCompleted(number: Int)
    case pigeonSpawned(id: Int, type: PigeonType, position: Waypoint)
    case pigeonStateChanged(id: Int, from: PigeonState, to: PigeonState)
    case defensePurchased(id: Int, type: DefenseType, buildSpotID: Int, cost: Int)
    case defenseFired(id: Int, type: DefenseType, targetIDs: [Int])
    case falconLaunched(defenseID: Int, pigeonID: Int, impactDelay: Double)
    case pressureApplied(pigeonID: Int, amount: Double, remainingTolerance: Double, defenseID: Int)
    case slowApplied(pigeonID: Int, fraction: Double, duration: Double)
    case pigeonFled(id: Int, reward: Int, position: Waypoint)
    case shooCombo(count: Int)
    case pigeonReachedTarget(id: Int, cleanlinessLoss: Int)
    case pigeonRemoved(id: Int)
    case moneyChanged(delta: Int, total: Int, reason: MoneyChangeReason)
    case cleanlinessChanged(delta: Int, total: Int)
    case phaseChanged(from: GamePhase, to: GamePhase)
    case victory
    case defeat
    case pauseChanged(isPaused: Bool)
    case sessionReset
}

public struct GameSession: Codable, Hashable, Sendable {
    public let configuration: SimulationConfiguration
    public let level: LevelDefinition
    public internal(set) var money: Int
    public internal(set) var cleanliness: Int
    public internal(set) var phase: GamePhase
    public internal(set) var currentWaveNumber: Int?
    public internal(set) var pigeons: [Pigeon]
    public internal(set) var defenses: [Defense]
    public internal(set) var buildSpots: [BuildSpot]
    public internal(set) var isPaused: Bool
    public internal(set) var simulationTime: Double
    public internal(set) var waveElapsedTime: Double

    public init(
        level: LevelDefinition = .marketplace,
        configuration: SimulationConfiguration = .init()
    ) {
        self.configuration = configuration
        self.level = level
        self.money = configuration.startingMoney
        self.cleanliness = configuration.startingCleanliness
        self.phase = .preparing
        self.currentWaveNumber = nil
        self.pigeons = []
        self.defenses = []
        self.buildSpots = level.buildSpots.map {
            BuildSpot(id: $0.id, position: $0.position)
        }
        self.isPaused = false
        self.simulationTime = 0
        self.waveElapsedTime = 0
    }

    public var currentWave: WaveDefinition? {
        guard let currentWaveNumber else { return nil }
        return level.waves.first { $0.number == currentWaveNumber }
    }

    public var nextWave: WaveDefinition? {
        let nextIndex: Int
        if let currentWaveNumber,
           let currentIndex = level.waves.firstIndex(where: { $0.number == currentWaveNumber }) {
            nextIndex = level.waves.index(after: currentIndex)
        } else {
            nextIndex = level.waves.startIndex
        }
        guard level.waves.indices.contains(nextIndex) else { return nil }
        return level.waves[nextIndex]
    }

    public var isGameOver: Bool { phase == .victory || phase == .defeat }
}
