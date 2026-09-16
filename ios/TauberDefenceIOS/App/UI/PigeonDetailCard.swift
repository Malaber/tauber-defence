import SwiftUI
import TauberDefenceCore

struct PigeonDetailCard: View {
    @EnvironmentObject private var localization: AppLocalization
    let pigeon: Pigeon
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(pigeon.type.localizedName(using: localization).uppercased())
                        .font(.system(.title3, design: .rounded, weight: .black))
                    Text(pigeon.type.localizedSubtitle(using: localization))
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
                .accessibilityLabel(localization.t("accessibility.pigeon_close"))
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(localization.t("pigeon.nerve"))
                    Spacer()
                    Text(
                        localization.t(
                            "pigeon.tolerance_value",
                            [
                                "current": Int(pigeon.currentTolerance.rounded()),
                                "maximum": Int(pigeon.maxTolerance.rounded()),
                            ]
                        )
                    )
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
        case .spawning: localization.t("pigeon.status.spawning")
        case .moving:
            localization.t(
                pigeon.toleranceFraction > 0.7
                    ? "pigeon.status.unimpressed"
                    : "pigeon.status.concerned"
            )
        case .alert: localization.t("pigeon.status.alert")
        case .panicking: localization.t("pigeon.status.panicking")
        case .fleeing: localization.t("pigeon.status.fleeing")
        case .reachedTarget: localization.t("pigeon.status.reached_target")
        case .removed: localization.t("pigeon.status.removed")
        }
    }

    private var statusSymbol: String {
        pigeon.toleranceFraction < 0.3 ? "exclamationmark.triangle.fill" : "eye.fill"
    }

    private var statusColor: Color {
        pigeon.toleranceFraction < 0.3 ? GameTheme.coral : GameTheme.cream
    }
}
