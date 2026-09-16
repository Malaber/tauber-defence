import SwiftUI
import TauberDefenceCore

struct MainMenu: View {
    @EnvironmentObject private var localization: AppLocalization
    let progress: PlayerProgress
    let onPlay: (Bool) -> Void
    let onGuide: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack(alignment: .center, spacing: 28) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(localization.t("menu.agency"), systemImage: "building.2.fill")
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .foregroundStyle(GameTheme.yellow)
                        Text("TAUBER\nDEFENCE")
                            .font(.system(size: geometry.size.height < 450 ? 38 : 56, weight: .black, design: .rounded))
                            .lineSpacing(-8)
                            .accessibilityIdentifier("menu.screen")
                        Text(localization.t("menu.tagline"))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Button(localization.t("menu.guide"), action: onGuide)
                            .buttonStyle(SecondaryGameButtonStyle())
                            .accessibilityIdentifier("menu.guide")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localization.t("menu.rank", ["rank": progress.rank]))
                                .font(.system(.headline, design: .rounded, weight: .black))
                            ProgressView(value: progress.rankProgress).tint(GameTheme.yellow)
                            Text(localization.t("menu.xp", ["xp": progress.experience]))
                                .accessibilityIdentifier("menu.xp")
                            Text(localization.t("menu.stats", ["wins": progress.wins, "wave": progress.bestWave, "birds": progress.pigeonsShooed]))
                                .foregroundStyle(.white.opacity(0.65))
                                .font(.system(.caption, design: .rounded))
                        }
                        .padding(16).gamePanel()
                        Button { onPlay(true) } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Label(localization.t("menu.trials"), systemImage: "flask.fill")
                                Text(localization.t("menu.trials_detail"))
                                    .font(.system(size: 11, weight: .semibold))
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PrimaryGameButtonStyle())
                        .accessibilityIdentifier("menu.trials")
                        Button(localization.t("menu.classic")) { onPlay(false) }
                            .buttonStyle(SecondaryGameButtonStyle())
                            .accessibilityIdentifier("menu.classic")
                        Text(localization.t("menu.local"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(28)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(LinearGradient(colors: [GameTheme.ink, Color(red: 0.08, green: 0.22, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

struct FieldGuide: View {
    @EnvironmentObject private var localization: AppLocalization
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(localization.t("guide.pigeons")) {
                    ForEach(PigeonType.allCases, id: \.self) { type in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(type.localizedName(using: localization)).bold()
                            Text(type.localizedSubtitle(using: localization)).font(.subheadline)
                            Text(localization.t("guide.bird_stats", ["nerve": Int(type.maxTolerance), "speed": String(format: "%.2f", type.speed), "reward": type.reward]))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section(localization.t("guide.defenses")) {
                    ForEach(DefenseType.allCases, id: \.self) { type in
                        VStack(alignment: .leading, spacing: 4) {
                            Label(type.localizedName(using: localization), systemImage: type.iconName).bold()
                            Text(type.localizedTagline(using: localization)).font(.subheadline)
                            Text(localization.t("guide.defense_stats", ["cost": type.cost, "pressure": Int(type.pressure), "range": String(format: "%.1f", type.range)]))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section(localization.t("camera.title")) {
                    Text(localization.t("camera.help"))
                }
            }
            .navigationTitle(localization.t("menu.guide"))
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(localization.t("help.done")) { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}
