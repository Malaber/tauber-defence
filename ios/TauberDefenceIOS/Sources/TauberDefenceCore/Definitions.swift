import Foundation

public enum PigeonType: String, CaseIterable, Codable, Hashable, Sendable {
    case normal
    case ruediger

    public var displayName: String {
        switch self {
        case .normal: "Stadttaube"
        case .ruediger: "Rüdiger"
        }
    }

    public var iconName: String {
        switch self {
        case .normal: "PigeonNormal"
        case .ruediger: "PigeonRudiger"
        }
    }

    public var maxTolerance: Double {
        switch self {
        case .normal: 100
        case .ruediger: 1_000
        }
    }

    public var speed: Double {
        switch self {
        case .normal: 1.0
        case .ruediger: 0.7
        }
    }

    public var reward: Int {
        switch self {
        case .normal: 10
        case .ruediger: 500
        }
    }
}

public enum PigeonState: String, CaseIterable, Codable, Hashable, Sendable {
    case spawning
    case moving
    case alert
    case panicking
    case fleeing
    case reachedTarget
    case removed
}

public enum DefenseTargetingMode: String, Codable, Hashable, Sendable {
    case single
    case area
}

public enum DefenseType: String, CaseIterable, Codable, Hashable, Sendable {
    case plasticOwl
    case sprinkler
    case falconer

    public var displayName: String {
        switch self {
        case .plasticOwl: "Plastik-Uhu"
        case .sprinkler: "Rasensprenger"
        case .falconer: "Falkner"
        }
    }

    public var iconName: String {
        switch self {
        case .plasticOwl: "eye.fill"
        case .sprinkler: "drop.fill"
        case .falconer: "bird.fill"
        }
    }

    public var tagline: String {
        switch self {
        case .plasticOwl: "Starrt einzelne Tauben streng an."
        case .sprinkler: "Duscht und bremst ganze Gruppen."
        case .falconer: "Schickt einen Falken mit Nachdruck."
        }
    }

    public var cost: Int {
        switch self {
        case .plasticOwl: 100
        case .sprinkler: 150
        case .falconer: 300
        }
    }

    public var range: Double {
        switch self {
        case .plasticOwl: 2.8
        case .sprinkler: 2.2
        case .falconer: 4.5
        }
    }

    public var cooldown: Double {
        switch self {
        case .plasticOwl: 1.8
        case .sprinkler: 1.25
        case .falconer: 3.0
        }
    }

    public var pressure: Double {
        switch self {
        case .plasticOwl: 25
        case .sprinkler: 10
        case .falconer: 70
        }
    }

    public var targetingMode: DefenseTargetingMode {
        switch self {
        case .plasticOwl, .falconer: .single
        case .sprinkler: .area
        }
    }

    public var impactDelay: Double {
        switch self {
        case .falconer: 0.5
        case .plasticOwl, .sprinkler: 0
        }
    }

    /// `0.2` means movement is reduced by twenty percent.
    public var slowFraction: Double {
        switch self {
        case .sprinkler: 0.2
        case .plasticOwl, .falconer: 0
        }
    }
}

public struct WaveGroup: Codable, Hashable, Sendable {
    public let pigeonType: PigeonType
    public let count: Int
    public let spawnInterval: Double
    public let initialDelay: Double

    public init(
        pigeonType: PigeonType,
        count: Int,
        spawnInterval: Double,
        initialDelay: Double = 0
    ) {
        precondition(count >= 0, "Wave group count cannot be negative")
        precondition(spawnInterval >= 0, "Spawn interval cannot be negative")
        precondition(initialDelay >= 0, "Initial delay cannot be negative")
        self.pigeonType = pigeonType
        self.count = count
        self.spawnInterval = spawnInterval
        self.initialDelay = initialDelay
    }

    private enum CodingKeys: String, CodingKey {
        case pigeonType = "pigeon"
        case count
        case spawnInterval
        case initialDelay
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            pigeonType: try container.decode(PigeonType.self, forKey: .pigeonType),
            count: try container.decode(Int.self, forKey: .count),
            spawnInterval: try container.decode(Double.self, forKey: .spawnInterval),
            initialDelay: try container.decodeIfPresent(Double.self, forKey: .initialDelay) ?? 0
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pigeonType, forKey: .pigeonType)
        try container.encode(count, forKey: .count)
        try container.encode(spawnInterval, forKey: .spawnInterval)
        if initialDelay != 0 {
            try container.encode(initialDelay, forKey: .initialDelay)
        }
    }
}

public struct WaveDefinition: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let groups: [WaveGroup]

    public init(number: Int, groups: [WaveGroup]) {
        precondition(number > 0, "Wave numbers start at one")
        self.id = number
        self.groups = groups
    }

    public var number: Int { id }
    public var pigeonCount: Int { groups.reduce(0) { $0 + $1.count } }

    private enum CodingKeys: String, CodingKey {
        case id = "wave"
        case groups
    }
}

public struct BuildSpot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let position: Waypoint
    public internal(set) var occupiedByDefenseID: Int?

    public init(id: Int, position: Waypoint, occupiedByDefenseID: Int? = nil) {
        self.id = id
        self.position = position
        self.occupiedByDefenseID = occupiedByDefenseID
    }

    public var isOccupied: Bool { occupiedByDefenseID != nil }
}

public struct LevelDefinition: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let path: PathDefinition
    public let buildSpots: [BuildSpot]
    public let waves: [WaveDefinition]

    public init(
        id: String,
        name: String,
        path: PathDefinition,
        buildSpots: [BuildSpot],
        waves: [WaveDefinition]
    ) {
        precondition(Set(buildSpots.map(\.id)).count == buildSpots.count, "Build spot IDs must be unique")
        precondition(Set(waves.map(\.number)).count == waves.count, "Wave numbers must be unique")
        self.id = id
        self.name = name
        self.path = path
        self.buildSpots = buildSpots
        self.waves = waves.sorted { $0.number < $1.number }
    }

    public static let marketplace = LevelDefinition(
        id: "marketplace",
        name: "Marktplatz",
        path: PathDefinition(waypoints: [
            Waypoint(x: -6, z: 0),
            Waypoint(x: -3, z: 0),
            Waypoint(x: -1, z: 1),
            Waypoint(x: 2, z: 1),
            Waypoint(x: 4, z: -1),
            Waypoint(x: 7, z: -1),
        ]),
        buildSpots: [
            BuildSpot(id: 1, position: Waypoint(x: -4.5, z: -2)),
            BuildSpot(id: 2, position: Waypoint(x: -4, z: 2)),
            BuildSpot(id: 3, position: Waypoint(x: -1.5, z: -1.5)),
            BuildSpot(id: 4, position: Waypoint(x: 0, z: 3)),
            BuildSpot(id: 5, position: Waypoint(x: 2, z: -1.5)),
            BuildSpot(id: 6, position: Waypoint(x: 3.5, z: 2)),
            BuildSpot(id: 7, position: Waypoint(x: 5, z: -3)),
            BuildSpot(id: 8, position: Waypoint(x: 6, z: 1.5)),
        ],
        waves: [
            WaveDefinition(
                number: 1,
                groups: [WaveGroup(pigeonType: .normal, count: 5, spawnInterval: 1.0)]
            ),
            WaveDefinition(
                number: 2,
                groups: [WaveGroup(pigeonType: .normal, count: 10, spawnInterval: 1.0)]
            ),
            WaveDefinition(
                number: 3,
                groups: [WaveGroup(pigeonType: .normal, count: 15, spawnInterval: 0.9)]
            ),
            WaveDefinition(
                number: 4,
                groups: [WaveGroup(pigeonType: .normal, count: 20, spawnInterval: 0.8)]
            ),
            WaveDefinition(
                number: 5,
                groups: [WaveGroup(pigeonType: .ruediger, count: 1, spawnInterval: 1.0)]
            ),
        ]
    )
}
