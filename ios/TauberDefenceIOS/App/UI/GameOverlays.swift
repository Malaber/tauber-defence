import SwiftUI

struct GameToastView: View {
    let toast: GameToast

    var body: some View {
        Label(toast.message, systemImage: toast.symbol)
            .font(.system(.headline, design: .rounded, weight: .black))
            .foregroundStyle(GameTheme.ink)
            .padding(.horizontal, 18)
            .frame(minHeight: 48)
            .background(GameTheme.yellow, in: Capsule())
            .shadow(color: .black.opacity(0.25), radius: 14, y: 7)
            .accessibilityIdentifier("game.toast")
    }
}

struct PauseOverlay: View {
    let onResume: () -> Void
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(GameTheme.yellow)
            Text("KURZE GURR-PAUSE")
                .font(.system(.title2, design: .rounded, weight: .black))
                .accessibilityIdentifier("pause.overlay")

            HStack(spacing: 10) {
                Button("Neu starten", action: onRestart)
                    .buttonStyle(SecondaryGameButtonStyle())
                Button("Weiter", action: onResume)
                    .buttonStyle(PrimaryGameButtonStyle())
                    .accessibilityIdentifier("pause.resume")
            }
        }
        .padding(24)
        .gamePanel()
    }
}

struct ResultOverlay: View {
    let title: String
    let message: String
    let symbol: String
    let tint: Color
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("game.result")
            Text(message)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.center)
            Button("NOCH EINE RUNDE", action: onRestart)
                .buttonStyle(PrimaryGameButtonStyle())
                .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: 440)
        .gamePanel()
    }
}

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HelpRow(symbol: "hand.tap.fill", title: "Bauplatz wählen", text: "Tippe einen gelben Kreis auf dem Marktplatz an.")
                    HelpRow(symbol: "shield.fill", title: "Abwehr aufstellen", text: "Uhu, Sprinkler und Falkner erzeugen Pressure und kosten Stadtbudget.")
                    HelpRow(symbol: "bird.fill", title: "Nerven statt Trefferpunkte", text: "Sinkt die Toleranz auf null, fliegt die Taube davon. Keine Taube kommt zu Schaden.")
                    HelpRow(symbol: "cup.and.saucer.fill", title: "Café sauber halten", text: "Jede Taube am Ziel kostet Sauberkeit. Überstehe fünf Wellen und Rüdiger.")

                    Divider()
                        .overlay(.white.opacity(0.16))

                    HStack(spacing: 18) {
                        Link("Support", destination: URL(string: "https://tauber-defence.malaber.de/support/")!)
                        Link("Datenschutz", destination: URL(string: "https://tauber-defence.malaber.de/privacy/")!)
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(GameTheme.yellow)
                }
                .padding(22)
            }
            .background(GameTheme.ink)
            .navigationTitle("So wird verscheucht")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Verstanden") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct HelpRow: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(GameTheme.yellow)
                .frame(width: 38, height: 38)
                .background(GameTheme.yellow.opacity(0.14), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Text(text)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.66))
            }
        }
    }
}

struct PrimaryGameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .black, design: .rounded))
            .padding(.horizontal, 18)
            .frame(height: 43)
            .foregroundStyle(GameTheme.ink)
            .background(GameTheme.yellow.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

struct SecondaryGameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .padding(.horizontal, 18)
            .frame(height: 43)
            .background(.white.opacity(configuration.isPressed ? 0.06 : 0.11), in: Capsule())
    }
}
