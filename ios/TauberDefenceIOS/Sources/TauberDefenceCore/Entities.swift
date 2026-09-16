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
    internal var appliedSlowFraction = 0.2
    public internal(set) var disruptedUntil = 0.0
    public internal(set) var lastPressureCategory: PressureCategory?

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
        simulationTime < slowedUntil ? 1 - appliedSlowFraction : 1.0
    }

    public func pressureMultiplier(category: PressureCategory, nearby: [Pigeon], at time: Double) -> Double {
        var multiplier = 1.0
        if type == .volker && lastPressureCategory == category { multiplier *= 0.55 }
        if category == .sound && lastPressureCategory == .sound { multiplier *= 0.7 }
        if category == .sound && lastPressureCategory != nil && lastPressureCategory != .sound { multiplier *= 1.3 }
        guard time >= disruptedUntil else { return multiplier }
        let allies = nearby.filter {
            $0.id != id && $0.isTargetable && time >= $0.disruptedUntil && $0.position.distance(to: position) <= 2.5
        }
        if allies.contains(where: { $0.type == .ingo }) { multiplier *= 0.8 }
        if type == .coalition && allies.contains(where: { $0.type == .coalition }) { multiplier *= 0.7 }
        if time.truncatingRemainder(dividingBy: 6) < 2.2 &&
            (type == .gurrmann || allies.contains(where: { $0.type == .gurrmann })) { multiplier *= 0.5 }
        return multiplier
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
