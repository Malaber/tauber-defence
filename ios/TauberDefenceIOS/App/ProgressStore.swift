import Foundation
import TauberDefenceCore

/// One versioned local record; no account, analytics, or network service.
@MainActor
struct ProgressStore {
    private let defaults: UserDefaults
    private let key = "player-progress-v1"

    init(options: AutomationLaunchOptions) {
        if options.isAutomatedLaunch {
            defaults = UserDefaults(suiteName: "de.malaber.tauber-defence.ui-tests")!
            if !ProcessInfo.processInfo.arguments.contains("--preserve-progress") {
                defaults.removeObject(forKey: key)
            }
        } else {
            defaults = .standard
        }
    }

    func load() -> PlayerProgress {
        guard let data = defaults.data(forKey: key),
              let progress = try? JSONDecoder().decode(PlayerProgress.self, from: data) else {
            return PlayerProgress()
        }
        return progress
    }

    func save(_ progress: PlayerProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key)
    }
}
