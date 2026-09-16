import SwiftUI
import TauberDefenceCore

struct GameRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var localization: AppLocalization
    @State private var model: GameViewModel

    init(localization: AppLocalization) {
        _model = State(initialValue: GameViewModel(localization: localization))
    }

    var body: some View {
        Group {
            if model.isShowingMenu {
                MainMenu(progress: model.progress, onPlay: model.startGame,
                         onGuide: { model.isShowingGuide = true })
            } else {
                battlefield
            }
        }
        .sheet(isPresented: $model.isShowingGuide) { FieldGuide() }
    }

    private var battlefield: some View {
        ZStack {
            GameRealityView(
                session: model.session,
                selectedBuildSpotID: model.selectedBuildSpotID,
                selectedPigeonID: model.selectedPigeonID,
                onBuildSpotTapped: model.selectBuildSpot,
                onPigeonTapped: model.selectPigeon
            )
            .ignoresSafeArea()

            Color.black.opacity(model.session.isPaused ? 0.28 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 12) {
                GameHUD(
                    session: model.session,
                    onPause: model.togglePause,
                    onHelp: { model.isShowingHelp = true }
                )

                Spacer(minLength: 8)

                if let pigeon = model.selectedPigeon {
                    HStack {
                        Spacer()
                        PigeonDetailCard(pigeon: pigeon) {
                            model.selectedPigeonID = nil
                        }
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }

                if model.selectedBuildSpot != nil {
                    BuildMenu(
                        session: model.session,
                        purchaseError: model.purchaseError,
                        onPurchase: model.purchase,
                        onClose: model.dismissSelection
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    WaveControl(session: model.session, onStart: model.startNextWave)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            if let toast = model.toast {
                GameToastView(toast: toast)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .allowsHitTesting(false)
            }

            if model.session.isPaused {
                PauseOverlay(onResume: model.togglePause, onRestart: model.reset, onMenu: model.returnToMenu)
            }

            switch model.session.phase {
            case .victory:
                ResultOverlay(
                    title: localization.t("result.victory_title"),
                    message: localization.t("result.victory_message"),
                    symbol: "trophy.fill",
                    tint: GameTheme.yellow,
                    onRestart: model.reset,
                    onMenu: model.returnToMenu,
                    experience: model.earnedExperience
                )
            case .defeat:
                ResultOverlay(
                    title: localization.t("result.defeat_title"),
                    message: localization.t("result.defeat_message"),
                    symbol: "cup.and.saucer.fill",
                    tint: GameTheme.coral,
                    onRestart: model.reset,
                    onMenu: model.returnToMenu,
                    experience: model.earnedExperience
                )
            case .preparing, .waveRunning, .waveComplete:
                EmptyView()
            }

        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: model.selectedBuildSpotID)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: model.selectedPigeonID)
        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: model.toast)
        .task { await model.runLoop() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                model.pauseIfNeeded()
            }
        }
        .sheet(isPresented: $model.isShowingHelp) {
            HowToPlayView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}
