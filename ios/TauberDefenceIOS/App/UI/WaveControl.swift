import SwiftUI
import TauberDefenceCore

struct WaveControl: View {
    let session: GameSession
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if session.phase == .waveRunning {
                HStack(spacing: 9) {
                    ProgressView()
                        .tint(GameTheme.yellow)
                    Text(session.currentWaveNumber == session.level.waves.count ? "RÜDIGER IST UNTERWEGS" : "TAUBEN IM ANFLUG")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(0.6)
                }
                .padding(.horizontal, 18)
                .frame(height: 48)
                .gamePanel()
                .accessibilityIdentifier("wave.running")
            } else if session.phase == .preparing || session.phase == .waveComplete {
                Button(action: onStart) {
                    Label(buttonTitle, systemImage: session.currentWaveNumber == 4 ? "exclamationmark.triangle.fill" : "play.fill")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(0.5)
                        .padding(.horizontal, 22)
                        .frame(height: 50)
                        .foregroundStyle(GameTheme.ink)
                        .background(GameTheme.yellow, in: Capsule())
                        .shadow(color: GameTheme.yellow.opacity(0.35), radius: 12, y: 5)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("wave.start")
            }
        }
    }

    private var buttonTitle: String {
        if session.currentWaveNumber == 0 { return "ERSTE WELLE STARTEN" }
        if session.currentWaveNumber == 4 { return "RÜDIGER RUFEN" }
        return "NÄCHSTE WELLE"
    }
}
