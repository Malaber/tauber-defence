import SwiftUI
import TauberDefenceCore

struct PigeonDetailCard: View {
    let pigeon: Pigeon
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(pigeon.type == .ruediger ? "RÜDIGER" : "STADTTAUBE")
                        .font(.system(.title3, design: .rounded, weight: .black))
                    Text(pigeon.type == .ruediger ? "Veteran Pigeon" : "Gelegenheitsgurrer")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .black))
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("NERVEN")
                    Spacer()
                    Text("\(Int(pigeon.currentTolerance.rounded())) / \(Int(pigeon.maxTolerance.rounded()))")
                        .contentTransition(.numericText())
                }
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.7)

                ProgressView(value: pigeon.toleranceFraction)
                    .tint(GameTheme.teal)
            }

            Label(statusText, systemImage: statusSymbol)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
        }
        .padding(14)
        .frame(width: 260)
        .gamePanel()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("pigeon.detail")
    }

    private var statusText: String {
        switch pigeon.state {
        case .spawning: "landet ungebeten"
        case .moving: pigeon.toleranceFraction > 0.7 ? "absolut unbeeindruckt" : "mildly concerned"
        case .alert: "wird misstrauisch"
        case .panicking: "kennt plötzlich Angst"
        case .fleeing: "verliert die Nerven"
        case .reachedTarget: "hat Hausverbot"
        case .removed: "schon weg"
        }
    }

    private var statusSymbol: String {
        pigeon.toleranceFraction < 0.3 ? "exclamationmark.triangle.fill" : "eye.fill"
    }

    private var statusColor: Color {
        pigeon.toleranceFraction < 0.3 ? GameTheme.coral : GameTheme.cream
    }
}
