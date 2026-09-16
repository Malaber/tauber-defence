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
    @EnvironmentObject private var localization: AppLocalization
    @State private var camera = BoardCamera()
    @State private var gestureZoom: Double?
    @State private var gestureYaw: Double?
    @State private var isReady = false

    @StateObject private var renderer: GameRenderer

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
        _renderer = StateObject(wrappedValue: GameRenderer())
    }

    var body: some View {
        GeometryReader { geometry in
        ZStack {
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
            renderer.updateCamera(camera)
            isReady = true
        } update: { content in
            content.camera = .virtual
            content.cameraTarget = renderer.cameraEntity
            renderer.updateCamera(camera)
            renderer.reconcile(
                session: session,
                selectedBuildSpotID: selectedBuildSpotID,
                selectedPigeonID: selectedPigeonID
            )
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .accessibilityIdentifier("game.city")
        .gesture(
            SpatialTapGesture()
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
        .contentShape(Rectangle())
        .simultaneousGesture(MagnifyGesture().onChanged { value in
            if gestureZoom == nil { gestureZoom = camera.zoom }
            camera.setZoom((gestureZoom ?? 1) * value.magnification)
        }.onEnded { _ in gestureZoom = nil })
        .simultaneousGesture(RotateGesture().onChanged { value in
            if gestureYaw == nil { gestureYaw = camera.yaw }
            camera.setYaw((gestureYaw ?? 0) - value.rotation.radians)
        }.onEnded { _ in gestureYaw = nil })
        .simultaneousGesture(DragGesture(minimumDistance: 12).onChanged { value in
            if gestureYaw == nil { gestureYaw = camera.yaw }
            camera.setYaw((gestureYaw ?? 0) - value.translation.width / 180)
        }.onEnded { _ in gestureYaw = nil })

        ForEach(session.buildSpots.filter { !$0.isOccupied && isReady }) { spot in
            let point = camera.project(SIMD3(spot.position.x, 0.2, spot.position.z),
                                       width: geometry.size.width, height: geometry.size.height)
            Button { onBuildSpotTapped(spot.id) } label: {
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(GameTheme.ink)
                    .frame(width: 32, height: 32)
                    .background(selectedBuildSpotID == spot.id ? GameTheme.teal : GameTheme.yellow, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localization.t("board.spot", ["id": spot.id]))
            .accessibilityIdentifier("board.spot.\(spot.id)")
            .position(x: point.x, y: point.y)
        }

        VStack {
            Spacer()
            HStack(spacing: 4) {
                cameraButton("minus.magnifyingglass", key: "out") { camera.setZoom(camera.zoom / 1.2) }
                cameraButton("plus.magnifyingglass", key: "in") { camera.setZoom(camera.zoom * 1.2) }
                cameraButton("rotate.right", key: "rotate") { camera.setYaw(camera.yaw + .pi / 4) }
                cameraButton("viewfinder", key: "reset") { camera = BoardCamera() }
                Spacer()
            }
            .padding(.bottom, 76)
            .padding(.leading, 20)
        }
        if isReady {
            Text(" ").frame(width: 1, height: 1)
                .accessibilityLabel(localization.t("board.ready"))
                .accessibilityIdentifier("board.ready")
                .allowsHitTesting(false)
        }
        }
        }
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

    private func cameraButton(_ symbol: String, key: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).frame(width: 44, height: 44)
                .background(GameTheme.ink.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(localization.t("camera.\(key)"))
        .accessibilityIdentifier("camera.\(key)")
        .accessibilityValue(String(format: "%.2f/%.2f", camera.zoom, camera.yaw))
    }
}
