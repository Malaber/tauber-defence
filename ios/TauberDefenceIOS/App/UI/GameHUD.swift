import SwiftUI
import TauberDefenceCore

struct GameHUD: View {
    let session: GameSession
    let onPause: () -> Void
    let onHelp: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HUDMetric(
                value: "\(session.money) €",
                label: "STADTBUDGET",
                symbol: "eurosign.circle.fill",
                tint: GameTheme.yellow,
                identifier: "hud.money"
            )

            HUDMetric(
                value: "\(session.currentWaveNumber ?? 0)/\(session.level.waves.count)",
                label: "WELLE",
                symbol: "bird.fill",
                tint: GameTheme.blue,
                identifier: "hud.wave"
            )

            HUDMetric(
                value: "\(session.cleanliness) %",
                label: "SAUBERKEIT",
                symbol: "sparkles",
                tint: cleanlinessColor,
                identifier: "hud.cleanliness"
            )

            Spacer(minLength: 8)

            CircleButton(symbol: "questionmark", label: "Spielhilfe", action: onHelp)
            CircleButton(
                symbol: session.isPaused ? "play.fill" : "pause.fill",
                label: session.isPaused ? "Fortsetzen" : "Pause",
                action: onPause
            )
            .accessibilityIdentifier("game.pause")
        }
    }

    private var cleanlinessColor: Color {
        if session.cleanliness > 60 { return GameTheme.teal }
        if session.cleanliness > 30 { return GameTheme.yellow }
        return GameTheme.coral
    }
}

private struct HUDMetric: View {
    let value: String
    let label: String
    let symbol: String
    let tint: Color
    let identifier: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .contentTransition(.numericText())
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .tracking(0.7)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .gamePanel()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}

struct CircleButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .black))
                .frame(width: 43, height: 43)
                .foregroundStyle(GameTheme.cream)
                .gamePanel()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
