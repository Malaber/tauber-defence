import RealityKit
import SwiftUI
import TauberDefenceCore

/// The SwiftUI/RealityKit boundary for the game board.
///
/// `session` is a value snapshot. SwiftUI drives reconciliation whenever it changes,
/// while the renderer retains and updates its RealityKit entities by stable core IDs.
@MainActor
struct GameRealityView: View {
    let session: GameSession
    let selectedBuildSpotID: Int?
    let selectedPigeonID: Int?
    let onBuildSpotTapped: (Int) -> Void
    let onPigeonTapped: (Int) -> Void

    @State private var renderer: GameRenderer

    init(
        session: GameSession,
        selectedBuildSpotID: Int?,
        selectedPigeonID: Int?,
        onBuildSpotTapped: @escaping (Int) -> Void,
        onPigeonTapped: @escaping (Int) -> Void
    ) {
        self.session = session
        self.selectedBuildSpotID = selectedBuildSpotID
        self.selectedPigeonID = selectedPigeonID
        self.onBuildSpotTapped = onBuildSpotTapped
        self.onPigeonTapped = onPigeonTapped
        _renderer = State(initialValue: GameRenderer())
    }

    var body: some View {
        RealityView { content in
            await renderer.prepareAssets()
            renderer.install(
                session: session,
                selectedBuildSpotID: selectedBuildSpotID,
                selectedPigeonID: selectedPigeonID
            )

            content.add(renderer.sceneRoot)
            content.add(renderer.cameraEntity)
            content.camera = .virtual
            content.cameraTarget = renderer.cameraEntity
        } update: { content in
            content.camera = .virtual
            content.cameraTarget = renderer.cameraEntity
            renderer.reconcile(
                session: session,
                selectedBuildSpotID: selectedBuildSpotID,
                selectedPigeonID: selectedPigeonID
            )
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    switch renderer.tapTarget(for: value.entity) {
                    case let .buildSpot(id):
                        onBuildSpotTapped(id)
                    case let .pigeon(id):
                        onPigeonTapped(id)
                    case nil:
                        break
                    }
                }
        )
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.56, green: 0.79, blue: 0.91),
                    Color(red: 0.82, green: 0.91, blue: 0.93),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
