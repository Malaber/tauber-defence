import Foundation

/// Local, cosmetic progression. Every experimental unit stays available at every rank.
public struct PlayerProgress: Codable, Equatable, Sendable {
    public private(set) var experience = 0
    public private(set) var wins = 0
    public private(set) var runs = 0
    public private(set) var bestWave = 0
    public private(set) var pigeonsShooed = 0
    private var recentRunIDs: [UUID] = []

    public init() {}
    public var rank: Int { experience / 250 + 1 }
    public var rankProgress: Double { Double(experience % 250) / 250 }

    @discardableResult
    public mutating func record(runID: UUID, fled: Int, completedWaves: Int, victory: Bool) -> Int {
        guard !recentRunIDs.contains(runID) else { return 0 }
        let birds = max(0, fled)
        let waves = max(0, completedWaves)
        let earned = birds * 5 + waves * 25 + (victory ? 150 : 0)
        experience += earned
        pigeonsShooed += birds
        bestWave = max(bestWave, waves)
        wins += victory ? 1 : 0
        runs += 1
        recentRunIDs.append(runID)
        recentRunIDs = Array(recentRunIDs.suffix(100))
        return earned
    }
}
