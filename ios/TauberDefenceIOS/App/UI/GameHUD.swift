import SwiftUI
import TauberDefenceCore

struct GameHUD: View {
    @EnvironmentObject private var localization: AppLocalization
    let session: GameSession
    let onPause: () -> Void
    let onHelp: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HUDMetric(
                value: localization.t(
                    "hud.money_value",
                    ["amount": localization.format(number: session.money)]
                ),
                label: localization.t("hud.city_budget"),
                symbol: "eurosign.circle.fill",
                tint: GameTheme.yellow,
                identifier: "hud.money",
                accessibilityValue: String(session.money)
            )

            HUDMetric(
                value: localization.t(
                    "hud.wave_value",
                    [
                        "current": session.currentWaveNumber ?? 0,
                        "total": session.level.waves.count,
                    ]
                ),
                label: localization.t("hud.wave"),
                symbol: "bird.fill",
                tint: GameTheme.blue,
                identifier: "hud.wave"
            )

            HUDMetric(
                value: localization.t(
                    "hud.cleanliness_value",
                    ["value": localization.format(number: session.cleanliness)]
                ),
                label: localization.t("hud.cleanliness"),
                symbol: "sparkles",
                tint: cleanlinessColor,
                identifier: "hud.cleanliness"
            )

            Spacer(minLength: 8)

            CircleButton(
                symbol: "questionmark",
                label: localization.t("hud.help"),
                action: onHelp
            )
            CircleButton(
                symbol: session.isPaused ? "play.fill" : "pause.fill",
                label: localization.t(session.isPaused ? "hud.resume" : "hud.pause"),
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
    var accessibilityValue: String? = nil

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
        .accessibilityValue(accessibilityValue ?? value)
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
