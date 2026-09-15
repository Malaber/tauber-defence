import Foundation

public struct Pigeon: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let type: PigeonType
    public internal(set) var state: PigeonState
    public internal(set) var currentTolerance: Double
    public let maxTolerance: Double
    public let baseSpeed: Double
    public let reward: Int
    public internal(set) var distanceAlongPath: Double
    public internal(set) var position: Waypoint
    public internal(set) var flightHeight: Double
    public internal(set) var stateElapsedTime: Double
    internal var slowedUntil: Double

    public init(
        id: Int,
        type: PigeonType,
        state: PigeonState = .spawning,
        currentTolerance: Double? = nil,
        distanceAlongPath: Double = 0,
        position: Waypoint
    ) {
        self.id = id
        self.type = type
        self.state = state
        self.currentTolerance = currentTolerance ?? type.maxTolerance
        self.maxTolerance = type.maxTolerance
        self.baseSpeed = type.speed
        self.reward = type.reward
        self.distanceAlongPath = distanceAlongPath
        self.position = position
        self.flightHeight = 0
        self.stateElapsedTime = 0
        self.slowedUntil = 0
    }

    public var toleranceFraction: Double {
        guard maxTolerance > 0 else { return 0 }
        return min(max(currentTolerance / maxTolerance, 0), 1)
    }

    public var isTargetable: Bool {
        switch state {
        case .moving, .alert, .panicking: true
        case .spawning, .fleeing, .reachedTarget, .removed: false
        }
    }

    public func speedMultiplier(at simulationTime: Double) -> Double {
        simulationTime < slowedUntil ? 0.8 : 1.0
    }
}

public struct Defense: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let type: DefenseType
    public let buildSpotID: Int
    public let position: Waypoint
    public internal(set) var cooldownRemaining: Double
    public internal(set) var targetPigeonIDs: [Int]

    public init(
        id: Int,
        type: DefenseType,
        buildSpotID: Int,
        position: Waypoint,
        cooldownRemaining: Double = 0,
        targetPigeonIDs: [Int] = []
    ) {
        self.id = id
        self.type = type
        self.buildSpotID = buildSpotID
        self.position = position
        self.cooldownRemaining = max(0, cooldownRemaining)
        self.targetPigeonIDs = targetPigeonIDs
    }

    public var currentTargetID: Int? { targetPigeonIDs.first }

    /// Zero immediately after firing and one when the defense is ready.
    public var cooldownFraction: Double {
        guard type.cooldown > 0 else { return 1 }
        return min(max(1 - (cooldownRemaining / type.cooldown), 0), 1)
    }
}
