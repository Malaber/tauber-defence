import SwiftUI
import TauberDefenceCore

struct BuildMenu: View {
    @EnvironmentObject private var localization: AppLocalization
    let session: GameSession
    let onPurchase: (DefenseType) -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.t("build.agency"))
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(GameTheme.yellow)
                    .tracking(1)
                    .accessibilityIdentifier("build.menu")
                Text(localization.t("build.title"))
                    .font(.system(.headline, design: .rounded, weight: .bold))
            }
            .frame(minWidth: 138, alignment: .leading)

            ForEach(DefenseType.allCases, id: \.self) { type in
                DefensePurchaseButton(
                    type: type,
                    affordable: session.money >= type.cost,
                    action: { onPurchase(type) }
                )
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localization.t("build.close"))
        }
        .padding(12)
        .gamePanel()
        .frame(maxWidth: 760)
    }
}

private struct DefensePurchaseButton: View {
    @EnvironmentObject private var localization: AppLocalization
    let type: DefenseType
    let affordable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: type.iconName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(affordable ? type.tint : .gray)
                    .frame(width: 34, height: 34)
                    .background(type.tint.opacity(affordable ? 0.18 : 0.06), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 1) {
                    Text(type.localizedName(using: localization))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .lineLimit(1)
                    Text(
                        localization.t(
                            "build.price_tagline",
                            [
                                "price": localization.format(euros: type.cost),
                                "tagline": type.localizedTagline(using: localization),
                            ]
                        )
                    )
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(affordable ? .white.opacity(0.65) : GameTheme.coral)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(affordable ? 0.09 : 0.035), in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            localization.t(
                "build.accessibility",
                [
                    "defense": type.localizedName(using: localization),
                    "price": localization.format(euros: type.cost),
                ]
            )
        )
        .accessibilityIdentifier("build.\(type.accessibilityName)")
    }
}

private extension DefenseType {
    var tint: Color {
        switch self {
        case .plasticOwl: GameTheme.yellow
        case .sprinkler: GameTheme.blue
        case .falconer: GameTheme.coral
        }
    }

    var accessibilityName: String {
        switch self {
        case .plasticOwl: "plastic-owl"
        case .sprinkler: "sprinkler"
        case .falconer: "falconer"
        }
    }
}
