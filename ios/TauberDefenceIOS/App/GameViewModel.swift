import Foundation
import Observation
import TauberDefenceCore

@MainActor
@Observable
final class GameViewModel {
    private var simulation: GameSimulation
    private let feedback: GameFeedback
    private let localization: AppLocalization
    let launchOptions: AutomationLaunchOptions

    private(set) var session: GameSession
    var selectedBuildSpotID: Int?
    var selectedPigeonID: Int?
    var toast: GameToast?
    private(set) var purchaseError: String?
    var isShowingHelp = false

    init(
        localization: AppLocalization,
        launchOptions: AutomationLaunchOptions = .current
    ) {
        self.localization = localization
        self.launchOptions = launchOptions
        let simulation = AutomationFixtureFactory.makeSimulation(for: launchOptions)
        self.simulation = simulation
        feedback = GameFeedback(enabled: !launchOptions.isAutomatedLaunch)
        session = simulation.session

        if launchOptions.fixture == .boss {
            selectedPigeonID = simulation.session.pigeons.first?.id
        }
    }

    var selectedPigeon: Pigeon? {
        guard let selectedPigeonID else { return nil }
        return session.pigeons.first { $0.id == selectedPigeonID }
    }

    var selectedBuildSpot: BuildSpot? {
        guard let selectedBuildSpotID else { return nil }
        return session.buildSpots.first { $0.id == selectedBuildSpotID }
    }

    func runLoop() async {
        guard !launchOptions.freezesSimulation else { return }

        let clock = ContinuousClock()
        var previous = clock.now

        while !Task.isCancelled {
            do {
                try await clock.sleep(for: .milliseconds(16))
            } catch {
                return
            }

            let now = clock.now
            let duration = previous.duration(to: now)
            previous = now
            let components = duration.components
            let delta = Double(components.seconds)
                + Double(components.attoseconds) / 1_000_000_000_000_000_000
            advance(by: min(delta, 0.1))
        }
    }

    func startNextWave() {
        guard simulation.startNextWave() else {
            showToast(localization.t("toast.wave_already_running"), symbol: "bird.fill")
            return
        }
        commitSnapshot()
    }

    func purchase(_ type: DefenseType) {
        guard let selectedBuildSpotID else {
            showToast(localization.t("toast.pick_spot_first"), symbol: "hand.tap.fill")
            return
        }

        do {
            _ = try simulation.purchaseDefense(type, at: selectedBuildSpotID)
            purchaseError = nil
            self.selectedBuildSpotID = nil
            commitSnapshot()
            showToast(
                localization.t(
                    "toast.defense_ready",
                    ["defense": type.localizedName(using: localization)]
                ),
                symbol: type.iconName
            )
        } catch {
            purchaseError = purchaseMessage(for: type)
        }
    }

    func selectBuildSpot(_ id: Int) {
        guard let spot = session.buildSpots.first(where: { $0.id == id }) else { return }
        purchaseError = nil
        selectedPigeonID = nil
        if spot.isOccupied {
            showToast(localization.t("toast.spot_occupied"), symbol: "exclamationmark.triangle.fill")
            selectedBuildSpotID = nil
        } else {
            selectedBuildSpotID = id
        }
    }

    func selectPigeon(_ id: Int) {
        guard session.pigeons.contains(where: { $0.id == id }) else { return }
        purchaseError = nil
        selectedBuildSpotID = nil
        selectedPigeonID = selectedPigeonID == id ? nil : id
    }

    func selectFirstPigeon() {
        guard let id = session.pigeons.first?.id else { return }
        selectedBuildSpotID = nil
        selectedPigeonID = id
    }

    func dismissSelection() {
        purchaseError = nil
        selectedBuildSpotID = nil
        selectedPigeonID = nil
    }

    func togglePause() {
        simulation.togglePause()
        commitSnapshot()
    }

    func pauseIfNeeded() {
        guard !session.isPaused else { return }
        simulation.setPaused(true)
        commitSnapshot()
    }

    func reset() {
        simulation.reset()
        selectedBuildSpotID = nil
        selectedPigeonID = nil
        toast = nil
        purchaseError = nil
        commitSnapshot()
    }

    private func advance(by deltaTime: Double) {
        simulation.update(deltaTime: deltaTime)
        commitSnapshot()
    }

    private func commitSnapshot() {
        let previous = session
        let updated = simulation.session
        let events = simulation.consumeEvents()
        session = updated

        if let selectedPigeonID,
           !updated.pigeons.contains(where: { $0.id == selectedPigeonID }) {
            self.selectedPigeonID = nil
        }

        presentImportantChanges(from: previous, to: updated)
        feedback.handle(events)
    }

    private func presentImportantChanges(from previous: GameSession, to updated: GameSession) {
        let previousByID = Dictionary(uniqueKeysWithValues: previous.pigeons.map { ($0.id, $0) })
        let newlyFleeing = updated.pigeons.filter { pigeon in
            pigeon.state == .fleeing && previousByID[pigeon.id]?.state != .fleeing
        }

        if newlyFleeing.count >= 10 {
            showToast(localization.t("toast.mass_panic"), symbol: "wind")
        } else if newlyFleeing.count >= 2 {
            showToast(
                localization.t("toast.combo", ["count": newlyFleeing.count]),
                symbol: "sparkles"
            )
        } else if let pigeon = newlyFleeing.first {
            showToast(
                localization.t(
                    "toast.reward",
                    ["reward": localization.format(euros: pigeon.reward)]
                ),
                symbol: "eurosign.circle.fill"
            )
        }

        let previousIDs = Set(previous.pigeons.map(\.id))
        if updated.pigeons.contains(where: { $0.type == .ruediger && !previousIDs.contains($0.id) }) {
            showToast(localization.t("toast.boss_warning"), symbol: "exclamationmark.triangle.fill")
        }

        if previous.phase != updated.phase {
            switch updated.phase {
            case .waveComplete:
                showToast(localization.t("toast.wave_complete"), symbol: "checkmark.seal.fill")
            case .victory:
                showToast(localization.t("toast.victory"), symbol: "trophy.fill")
            case .defeat:
                showToast(localization.t("toast.defeat"), symbol: "cup.and.saucer.fill")
            case .preparing, .waveRunning:
                break
            }
        }
    }

    private func purchaseMessage(for type: DefenseType) -> String {
        if session.money < type.cost {
            return localization.t(
                "toast.funds_needed",
                ["remaining": localization.format(euros: type.cost - session.money)]
            )
        }
        return localization.t(
            "toast.cannot_build",
            ["defense": type.localizedName(using: localization)]
        )
    }

    private func showToast(_ message: String, symbol: String) {
        let item = GameToast(message: message, symbol: symbol)
        toast = item

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.2))
            guard let self, self.toast?.id == item.id else { return }
            self.toast = nil
        }
    }
}

struct GameToast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let symbol: String
}
