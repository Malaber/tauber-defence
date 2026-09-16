import XCTest
@testable import TauberDefenceCore

final class PlayerProgressTests: XCTestCase {
    func testProgressRewardsRankAndDeduplication() throws {
        var progress = PlayerProgress()
        let run = UUID()
        XCTAssertEqual(progress.rank, 1)
        XCTAssertEqual(progress.record(runID: run, fled: 10, completedWaves: 5, victory: true), 325)
        XCTAssertEqual(progress.experience, 325)
        XCTAssertEqual(progress.rank, 2)
        XCTAssertEqual(progress.rankProgress, 0.3)
        XCTAssertEqual(progress.wins, 1)
        XCTAssertEqual(progress.runs, 1)
        XCTAssertEqual(progress.bestWave, 5)
        XCTAssertEqual(progress.pigeonsShooed, 10)
        XCTAssertEqual(progress.record(runID: run, fled: 10, completedWaves: 5, victory: true), 0)
        let decoded = try JSONDecoder().decode(PlayerProgress.self, from: JSONEncoder().encode(progress))
        XCTAssertEqual(decoded, progress)
    }

    func testAbandonedRunsKeepEarnedExperienceWithoutWin() {
        var progress = PlayerProgress()
        XCTAssertEqual(progress.record(runID: UUID(), fled: 2, completedWaves: 1, victory: false), 35)
        XCTAssertEqual(progress.wins, 0)
        XCTAssertEqual(progress.bestWave, 1)
        XCTAssertEqual(progress.record(runID: UUID(), fled: -10, completedWaves: -5, victory: false), 0)
        XCTAssertEqual(progress.experience, 35)
    }
}
