import RealityKit
import TauberDefenceCore
import UIKit
import simd

/// Reconciles immutable simulation snapshots into a persistent RealityKit entity graph.
/// RealityKit never owns game truth: every visible transform is derived from `GameSession`.
@MainActor
final class GameRenderer {
    enum TapTarget: Equatable {
        case buildSpot(Int)
        case pigeon(Int)
    }

    let sceneRoot = Entity()
    let cameraEntity = Entity()

    private let environmentRoot = Entity()
    private let buildSpotRoot = Entity()
    private let defenseRoot = Entity()
    private let pigeonRoot = Entity()
    private let effectsRoot = Entity()

    private var pigeonTextures: [PigeonType: TextureResource] = [:]
    private var assetsArePrepared = false
    private var renderedLevelID: String?

    private var buildSpotVisuals: [Int: BuildSpotVisual] = [:]
    private var pigeonVisuals: [Int: PigeonVisual] = [:]
    private var defenseVisuals: [Int: DefenseVisual] = [:]

    init() {
        sceneRoot.name = "tauber-defence.scene"
        environmentRoot.name = "scene.environment"
        buildSpotRoot.name = "scene.build-spots"
        defenseRoot.name = "scene.defenses"
        pigeonRoot.name = "scene.pigeons"
        effectsRoot.name = "scene.effects"

        sceneRoot.addChild(environmentRoot)
        sceneRoot.addChild(buildSpotRoot)
        sceneRoot.addChild(defenseRoot)
        sceneRoot.addChild(pigeonRoot)
        sceneRoot.addChild(effectsRoot)

        var camera = OrthographicCameraComponent()
        camera.near = 0.1
        camera.far = 100
        camera.scale = 11.8
        camera.scaleDirection = .vertical
        cameraEntity.components.set(camera)
        cameraEntity.name = "camera.isometric"
        cameraEntity.look(
            at: SIMD3(0.55, 0.25, -0.1),
            from: SIMD3(11.5, 14.5, 14.5),
            relativeTo: nil
        )
    }

    func prepareAssets() async {
        guard !assetsArePrepared else { return }
        assetsArePrepared = true

        let options = TextureResource.CreateOptions(
            semantic: .color,
            compression: .default,
            mipmapsMode: .allocateAndGenerateAll
        )
        if let normal = try? await TextureResource(
            named: "PigeonNormal",
            in: .main,
            options: options
        ) {
            pigeonTextures[.normal] = normal
        }
        if let ruediger = try? await TextureResource(
            named: "PigeonRudiger",
            in: .main,
            options: options
        ) {
            pigeonTextures[.ruediger] = ruediger
        }
    }

    func updateCamera(_ pose: BoardCamera) {
        var camera = OrthographicCameraComponent()
        camera.near = 0.1
        camera.far = 100
        camera.scale = Float(pose.verticalSpan)
        camera.scaleDirection = .vertical
        cameraEntity.components.set(camera)
        cameraEntity.look(at: SIMD3<Float>(pose.target), from: SIMD3<Float>(pose.eye), relativeTo: nil)
    }

    func install(
        session: GameSession,
        selectedBuildSpotID: Int?,
        selectedPigeonID: Int?
    ) {
        rebuildEnvironmentIfNeeded(for: session.level)
        reconcile(
            session: session,
            selectedBuildSpotID: selectedBuildSpotID,
            selectedPigeonID: selectedPigeonID
        )
    }

    func reconcile(
        session: GameSession,
        selectedBuildSpotID: Int?,
        selectedPigeonID: Int?
    ) {
        rebuildEnvironmentIfNeeded(for: session.level)
        reconcileBuildSpots(
            session.buildSpots,
            selectedID: selectedBuildSpotID,
            simulationTime: session.simulationTime
        )
        reconcilePigeons(
            session.pigeons,
            selectedID: selectedPigeonID,
            simulationTime: session.simulationTime
        )
        reconcileDefenses(session.defenses, pigeons: session.pigeons, simulationTime: session.simulationTime)
    }

    func tapTarget(for hitEntity: Entity) -> TapTarget? {
        var candidate: Entity? = hitEntity
        while let entity = candidate {
            if let id = Self.id(in: entity.name, prefix: "build-spot:") {
                return .buildSpot(id)
            }
            if let id = Self.id(in: entity.name, prefix: "pigeon:") {
                return .pigeon(id)
            }
            candidate = entity.parent
        }
        return nil
    }

    private static func id(in name: String, prefix: String) -> Int? {
        guard name.hasPrefix(prefix) else { return nil }
        return Int(name.dropFirst(prefix.count))
    }

    private func rebuildEnvironmentIfNeeded(for level: LevelDefinition) {
        guard renderedLevelID != level.id else { return }
        renderedLevelID = level.id

        removeAllChildren(from: environmentRoot)
        environmentRoot.addChild(MarketplaceSceneBuilder.makeScene(for: level))

        removeAllChildren(from: buildSpotRoot)
        removeAllChildren(from: defenseRoot)
        removeAllChildren(from: pigeonRoot)
        removeAllChildren(from: effectsRoot)
        buildSpotVisuals.removeAll()
        defenseVisuals.removeAll()
        pigeonVisuals.removeAll()
    }

    // MARK: - Build spots

    private func reconcileBuildSpots(
        _ spots: [BuildSpot],
        selectedID: Int?,
        simulationTime: Double
    ) {
        let activeIDs = Set(spots.map(\.id))
        for id in Set(buildSpotVisuals.keys).subtracting(activeIDs) {
            buildSpotVisuals.removeValue(forKey: id)?.root.removeFromParent()
        }

        for spot in spots {
            let visual: BuildSpotVisual
            if let existing = buildSpotVisuals[spot.id] {
                visual = existing
            } else {
                visual = makeBuildSpotVisual(id: spot.id)
                buildSpotVisuals[spot.id] = visual
                buildSpotRoot.addChild(visual.root)
            }

            visual.root.position = spot.position.realityPosition
            // Native buttons are the visible markers and touch targets on iOS.
            visual.root.isEnabled = false
            visual.selection.isEnabled = selectedID == spot.id

            let isSelected = selectedID == spot.id
            let pulse = isSelected
                ? 1 + (sin(Float(simulationTime) * 5.5) * 0.045)
                : 1
            visual.root.scale = SIMD3(repeating: pulse)
        }
    }

    private func makeBuildSpotVisual(id: Int) -> BuildSpotVisual {
        let root = Entity()
        root.name = "build-spot:\(id)"
        root.components.set(InputTargetComponent(allowedInputTypes: .all))
        root.components.set(CollisionComponent(shapes: [
            ShapeResource.generateBox(width: 1.35, height: 0.44, depth: 1.35)
                .offsetBy(translation: SIMD3(0, 0.2, 0)),
        ]))

        let selection = makeCylinder(
            height: 0.035,
            radius: 0.78,
            color: RenderingPalette.teal.withAlphaComponent(0.62),
            position: SIMD3(0, 0.075, 0)
        )
        selection.name = "build-spot-selection:\(id)"
        selection.isEnabled = false
        root.addChild(selection)

        let pad = makeCylinder(
            height: 0.10,
            radius: 0.61,
            color: RenderingPalette.yellow.withAlphaComponent(0.9),
            position: SIMD3(0, 0.13, 0)
        )
        root.addChild(pad)

        let plus = Entity()
        plus.position = SIMD3(0, 0.205, 0)
        plus.addChild(makeBox(
            size: SIMD3(0.60, 0.08, 0.17),
            color: .white,
            cornerRadius: 0.06
        ))
        plus.addChild(makeBox(
            size: SIMD3(0.17, 0.08, 0.60),
            color: .white,
            cornerRadius: 0.06
        ))
        root.addChild(plus)

        return BuildSpotVisual(root: root, selection: selection)
    }

    // MARK: - Pigeons

    private func reconcilePigeons(
        _ pigeons: [Pigeon],
        selectedID: Int?,
        simulationTime: Double
    ) {
        let activeIDs = Set(pigeons.filter { $0.state != .removed }.map(\.id))
        for id in Set(pigeonVisuals.keys).subtracting(activeIDs) {
            pigeonVisuals.removeValue(forKey: id)?.root.removeFromParent()
        }

        for pigeon in pigeons where pigeon.state != .removed {
            let visual: PigeonVisual
            if let existing = pigeonVisuals[pigeon.id], existing.type == pigeon.type {
                visual = existing
            } else {
                if let existing = pigeonVisuals.removeValue(forKey: pigeon.id) {
                    existing.root.removeFromParent()
                }
                visual = makePigeonVisual(pigeon)
                pigeonVisuals[pigeon.id] = visual
                pigeonRoot.addChild(visual.root)
            }
            updatePigeonVisual(
                visual,
                from: pigeon,
                selected: selectedID == pigeon.id,
                simulationTime: simulationTime
            )
        }
    }

    private func makePigeonVisual(_ pigeon: Pigeon) -> PigeonVisual {
        let isBoss = pigeon.type == .ruediger
        let width: Float = isBoss ? 2.20 : (pigeon.type == .dieter ? 1.8 : pigeon.type == .sabine ? 0.95 : 1.34)
        let height: Float = isBoss ? 1.97 : (pigeon.type == .dieter ? 1.4 : pigeon.type == .sabine ? 0.85 : 1.12)

        let root = Entity()
        root.name = "pigeon-visual:\(pigeon.id)"

        let shadow = makeCylinder(
            height: 0.022,
            radius: isBoss ? 0.72 : 0.43,
            color: UIColor.black.withAlphaComponent(0.24),
            position: SIMD3(0, 0.045, 0)
        )
        shadow.name = "pigeon-shadow:\(pigeon.id)"
        root.addChild(shadow)

        let selection = makeCylinder(
            height: 0.028,
            radius: isBoss ? 0.92 : 0.62,
            color: RenderingPalette.yellow.withAlphaComponent(0.52),
            position: SIMD3(0, 0.062, 0)
        )
        selection.name = "pigeon-selection:\(pigeon.id)"
        selection.isEnabled = false
        root.addChild(selection)

        let bird = Entity()
        bird.name = "pigeon:\(pigeon.id)"
        bird.components.set(InputTargetComponent(allowedInputTypes: .all))
        bird.components.set(CollisionComponent(shapes: [
            ShapeResource.generateBox(width: width, height: height + 0.35, depth: 0.32)
                .offsetBy(translation: SIMD3(0, (height + 0.35) * 0.5, 0)),
        ]))
        root.addChild(bird)

        let spriteBillboard = Entity()
        spriteBillboard.name = "pigeon-billboard:\(pigeon.id)"
        spriteBillboard.components.set(BillboardComponent())
        bird.addChild(spriteBillboard)

        let spriteMaterial: UnlitMaterial
        if let texture = pigeonTextures[pigeon.type] ?? pigeonTextures[.normal] {
            var material = UnlitMaterial(texture: texture)
            material.faceCulling = .none
            material.opacityThreshold = 0.018
            material.readsDepth = true
            material.writesDepth = true
            spriteMaterial = material
        } else {
            spriteMaterial = makeUnlitMaterial(
                isBoss
                    ? UIColor(red: 0.27, green: 0.21, blue: 0.33, alpha: 1)
                    : UIColor(red: 0.38, green: 0.43, blue: 0.50, alpha: 1)
            )
        }

        let sprite = ModelEntity(
            mesh: .generatePlane(width: width, height: height),
            materials: [spriteMaterial]
        )
        sprite.name = "pigeon-sprite:\(pigeon.id)"
        sprite.position = SIMD3(0, (height * 0.5) + 0.11, 0)
        spriteBillboard.addChild(sprite)
        addPigeonAccessory(type: pigeon.type, height: height, to: spriteBillboard)

        if [.ingo, .gurrmann, .coalition].contains(pigeon.type) {
            let aura = makeCylinder(height: 0.018, radius: pigeon.type == .coalition ? 0.8 : 1.1,
                color: (pigeon.type == .gurrmann ? RenderingPalette.coral : RenderingPalette.teal).withAlphaComponent(0.2),
                position: SIMD3(0, 0.035, 0))
            aura.name = "confidence-aura"
            root.addChild(aura)
        }

        let barRoot = Entity()
        barRoot.name = "pigeon-tolerance:\(pigeon.id)"
        barRoot.components.set(BillboardComponent())
        barRoot.position = SIMD3(0, height + 0.34, 0)
        bird.addChild(barRoot)

        let barWidth: Float = isBoss ? 1.82 : 1.02
        let barHeight: Float = isBoss ? 0.18 : 0.13
        let barBackground = ModelEntity(
            mesh: .generatePlane(width: barWidth + 0.10, height: barHeight + 0.08, cornerRadius: barHeight * 0.5),
            materials: [makeUnlitMaterial(UIColor.black.withAlphaComponent(0.68))]
        )
        barRoot.addChild(barBackground)

        let barFill = ModelEntity(
            mesh: .generatePlane(width: barWidth, height: barHeight, cornerRadius: barHeight * 0.46),
            materials: [makeUnlitMaterial(RenderingPalette.teal)]
        )
        barFill.position.z = 0.006
        barRoot.addChild(barFill)

        return PigeonVisual(
            root: root,
            bird: bird,
            sprite: sprite,
            shadow: shadow,
            selection: selection,
            toleranceBar: barRoot,
            toleranceFill: barFill,
            barWidth: barWidth,
            type: pigeon.type
        )
    }

    private func updatePigeonVisual(
        _ visual: PigeonVisual,
        from pigeon: Pigeon,
        selected: Bool,
        simulationTime: Double
    ) {
        var x = Float(pigeon.position.x)
        var z = Float(pigeon.position.z)
        if pigeon.state == .fleeing {
            let fleeTime = Float(pigeon.stateElapsedTime)
            let side: Float = pigeon.id.isMultiple(of: 2) ? 1 : -1
            x += side * fleeTime * 1.7
            z -= fleeTime * 0.7
        }
        visual.root.position = SIMD3(x, 0, z)
        if let aura = visual.root.findEntity(named: "confidence-aura") {
            aura.isEnabled = pigeon.isTargetable && simulationTime >= pigeon.disruptedUntil &&
                (pigeon.type != .gurrmann || simulationTime.truncatingRemainder(dividingBy: 6) < 2.2)
        }

        let energy: (frequency: Float, amplitude: Float)
        switch pigeon.state {
        case .panicking, .fleeing:
            energy = (11.0, 0.075)
        case .alert:
            energy = (7.0, 0.045)
        case .spawning, .moving:
            energy = (4.4, 0.025)
        case .reachedTarget, .removed:
            energy = (2.0, 0)
        }

        let phase = Float(simulationTime) * energy.frequency + Float(pigeon.id) * 0.91
        let bob = sin(phase) * energy.amplitude
        visual.bird.position = SIMD3(0, Float(pigeon.flightHeight) + bob, 0)

        let squash = sin(phase * 0.82) * energy.amplitude * 0.7
        visual.sprite.scale = SIMD3(1 + squash, 1 - squash, 1)

        let tolerance = Float(min(max(pigeon.toleranceFraction, 0), 1))
        visual.toleranceFill.scale = SIMD3(max(tolerance, 0.001), 1, 1)
        visual.toleranceFill.position.x = -visual.barWidth * (1 - tolerance) * 0.5

        switch pigeon.state {
        case .moving, .alert, .panicking:
            visual.toleranceBar.isEnabled = true
        case .spawning, .fleeing, .reachedTarget, .removed:
            visual.toleranceBar.isEnabled = selected && pigeon.state != .removed
        }

        let shadowScale = max(0.25, 1 - (Float(pigeon.flightHeight) * 0.23))
        visual.shadow.scale = SIMD3(shadowScale, 1, shadowScale)
        setOpacity(max(0.08, 0.32 * shadowScale), on: visual.shadow)

        visual.selection.isEnabled = selected
        let selectionScale = 1 + (sin(Float(simulationTime) * 6) * 0.05)
        visual.selection.scale = SIMD3(selectionScale, 1, selectionScale)

        switch pigeon.state {
        case .spawning:
            setOpacity(min(1, Float(pigeon.stateElapsedTime) * 6), on: visual.bird)
        case .reachedTarget:
            setOpacity(max(0, 1 - Float(pigeon.stateElapsedTime) * 7), on: visual.bird)
        case .removed:
            setOpacity(0, on: visual.bird)
        case .moving, .alert, .panicking, .fleeing:
            setOpacity(1, on: visual.bird)
        }
    }

    // MARK: - Defenses

    private func reconcileDefenses(
        _ defenses: [Defense],
        pigeons: [Pigeon],
        simulationTime: Double
    ) {
        let activeIDs = Set(defenses.map(\.id))
        for id in Set(defenseVisuals.keys).subtracting(activeIDs) {
            if let removed = defenseVisuals.removeValue(forKey: id) {
                removed.root.removeFromParent()
                removed.attackEffect.removeFromParent()
            }
        }

        let pigeonsByID = Dictionary(uniqueKeysWithValues: pigeons.map { ($0.id, $0) })
        for defense in defenses {
            let visual: DefenseVisual
            if let existing = defenseVisuals[defense.id], existing.type == defense.type {
                visual = existing
            } else {
                if let old = defenseVisuals.removeValue(forKey: defense.id) {
                    old.root.removeFromParent()
                    old.attackEffect.removeFromParent()
                }
                visual = makeDefenseVisual(defense)
                defenseVisuals[defense.id] = visual
                defenseRoot.addChild(visual.root)
                effectsRoot.addChild(visual.attackEffect)
            }

            updateDefenseVisual(
                visual,
                from: defense,
                target: defense.currentTargetID.flatMap { pigeonsByID[$0] },
                simulationTime: simulationTime
            )
        }
    }

    private func makeDefenseVisual(_ defense: Defense) -> DefenseVisual {
        let root = Entity()
        root.name = "defense:\(defense.id)"
        root.position = defense.position.realityPosition

        root.addChild(makeCylinder(
            height: 0.16,
            radius: 0.52,
            color: RenderingPalette.stone,
            position: SIMD3(0, 0.08, 0)
        ))

        let aimRoot = Entity()
        aimRoot.name = "defense-aim:\(defense.id)"
        root.addChild(aimRoot)

        let activity = Entity()
        activity.name = "defense-activity:\(defense.id)"
        aimRoot.addChild(activity)

        switch defense.type {
        case .plasticOwl:
            makeOwl(on: aimRoot, activity: activity)
        case .sprinkler:
            makeSprinkler(on: aimRoot, activity: activity)
        case .falconer:
            makeFalconer(on: aimRoot, activity: activity)
        default:
            makeExperimentalDefense(defense.type, on: aimRoot, activity: activity)
        }

        let beamColor: UIColor
        switch defense.type {
        case .plasticOwl: beamColor = RenderingPalette.yellow.withAlphaComponent(0.88)
        case .sprinkler: beamColor = RenderingPalette.water
        case .falconer: beamColor = RenderingPalette.coral.withAlphaComponent(0.9)
        default: beamColor = RenderingPalette.teal
        }
        let attackEffect = ModelEntity(
            mesh: .generateBox(size: SIMD3(0.055, 0.055, 1), cornerRadius: 0.025),
            materials: [makeUnlitMaterial(beamColor)]
        )
        attackEffect.name = "defense-attack:\(defense.id)"
        attackEffect.isEnabled = false

        return DefenseVisual(
            root: root,
            aimRoot: aimRoot,
            activity: activity,
            attackEffect: attackEffect,
            type: defense.type
        )
    }

    private func makeOwl(on aimRoot: Entity, activity: Entity) {
        aimRoot.addChild(makeBox(size: SIMD3(0.12, 0.58, 0.12), color: RenderingPalette.wood, position: SIMD3(-0.16, 0.43, 0)))
        aimRoot.addChild(makeBox(size: SIMD3(0.12, 0.58, 0.12), color: RenderingPalette.wood, position: SIMD3(0.16, 0.43, 0)))
        aimRoot.addChild(makeCone(height: 0.92, radius: 0.39, color: UIColor(red: 0.48, green: 0.29, blue: 0.14, alpha: 1), position: SIMD3(0, 0.85, 0)))
        aimRoot.addChild(makeSphere(radius: 0.38, color: UIColor(red: 0.55, green: 0.34, blue: 0.17, alpha: 1), position: SIMD3(0, 1.32, 0)))
        for x in [-0.15 as Float, 0.15] {
            aimRoot.addChild(makeSphere(radius: 0.12, color: RenderingPalette.yellow, position: SIMD3(x, 1.39, 0.31)))
            aimRoot.addChild(makeSphere(radius: 0.055, color: .black, position: SIMD3(x, 1.39, 0.41)))
        }
        let beak = makeCone(height: 0.30, radius: 0.12, color: RenderingPalette.coral, position: SIMD3(0, 1.24, 0.43))
        beak.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
        aimRoot.addChild(beak)

        let glare = makeSphere(radius: 0.18, color: RenderingPalette.yellow.withAlphaComponent(0.38), position: SIMD3(0, 1.38, 0.50))
        activity.addChild(glare)
    }

    private func makeSprinkler(on aimRoot: Entity, activity: Entity) {
        aimRoot.addChild(makeCylinder(height: 0.56, radius: 0.11, color: RenderingPalette.metal, position: SIMD3(0, 0.45, 0), metallic: true))

        let pipe = makeCylinder(height: 0.86, radius: 0.085, color: RenderingPalette.metal, position: SIMD3(0, 0.76, 0), metallic: true)
        pipe.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
        aimRoot.addChild(pipe)
        aimRoot.addChild(makeSphere(radius: 0.16, color: RenderingPalette.metal, position: SIMD3(0, 0.76, 0), metallic: true))

        for direction in [-1 as Float, 1] {
            let nozzle = makeBox(
                size: SIMD3(0.16, 0.16, 0.25),
                color: RenderingPalette.water,
                position: SIMD3(0, 0.76, direction * 0.48),
                cornerRadius: 0.06
            )
            aimRoot.addChild(nozzle)
        }

        for index in 0..<8 {
            let angle = Float(index) * (.pi * 2 / 8)
            activity.addChild(makeSphere(
                radius: 0.065,
                color: RenderingPalette.water,
                position: SIMD3(cos(angle) * 0.7, 0.82 + sin(angle * 2) * 0.18, sin(angle) * 0.7)
            ))
        }
    }

    private func makeFalconer(on aimRoot: Entity, activity: Entity) {
        aimRoot.addChild(makeCylinder(height: 0.82, radius: 0.25, color: UIColor(red: 0.18, green: 0.38, blue: 0.55, alpha: 1), position: SIMD3(0, 0.62, 0)))
        aimRoot.addChild(makeSphere(radius: 0.23, color: UIColor(red: 0.80, green: 0.61, blue: 0.43, alpha: 1), position: SIMD3(0, 1.18, 0)))
        aimRoot.addChild(makeCylinder(height: 0.14, radius: 0.34, color: RenderingPalette.wood, position: SIMD3(0, 1.39, 0)))
        aimRoot.addChild(makeBox(size: SIMD3(0.76, 0.10, 0.10), color: RenderingPalette.wood, position: SIMD3(0.38, 0.94, 0.05)))

        let falcon = Entity()
        falcon.position = SIMD3(0.78, 1.17, 0.04)
        falcon.addChild(makeSphere(radius: 0.18, color: UIColor(red: 0.28, green: 0.23, blue: 0.20, alpha: 1)))
        falcon.addChild(makeCone(height: 0.24, radius: 0.1, color: RenderingPalette.yellow, position: SIMD3(0, 0, 0.22)))
        let leftWing = makeBox(size: SIMD3(0.36, 0.06, 0.22), color: UIColor(red: 0.20, green: 0.17, blue: 0.15, alpha: 1), position: SIMD3(-0.22, 0, 0))
        leftWing.orientation = simd_quatf(angle: -0.38, axis: SIMD3(0, 0, 1))
        falcon.addChild(leftWing)
        let rightWing = makeBox(size: SIMD3(0.36, 0.06, 0.22), color: UIColor(red: 0.20, green: 0.17, blue: 0.15, alpha: 1), position: SIMD3(0.22, 0, 0))
        rightWing.orientation = simd_quatf(angle: 0.38, axis: SIMD3(0, 0, 1))
        falcon.addChild(rightWing)
        aimRoot.addChild(falcon)

        let launchFlash = makeSphere(radius: 0.25, color: RenderingPalette.coral.withAlphaComponent(0.45), position: SIMD3(0.8, 1.18, 0.15))
        activity.addChild(launchFlash)
    }

    private func updateDefenseVisual(
        _ visual: DefenseVisual,
        from defense: Defense,
        target: Pigeon?,
        simulationTime: Double
    ) {
        visual.root.position = defense.position.realityPosition

        if defense.type == .sprinkler {
            visual.aimRoot.orientation = simd_quatf(
                angle: Float(simulationTime) * 2.4,
                axis: SIMD3(0, 1, 0)
            )
        } else if let target {
            visual.aimRoot.orientation = simd_quatf(
                angle: yaw(from: defense.position, to: target.position),
                axis: SIMD3(0, 1, 0)
            )
        }

        let justFired = defense.currentTargetID != nil && defense.cooldownFraction < attackWindow(for: defense.type)
        visual.activity.isEnabled = justFired
        if justFired {
            let pulse = 0.82 + (sin(Float(simulationTime) * 25) * 0.14)
            visual.activity.scale = SIMD3(repeating: pulse)
        }

        guard justFired, let target else {
            visual.attackEffect.isEnabled = false
            return
        }

        let startHeight: Float
        switch defense.type {
        case .plasticOwl: startHeight = 1.35
        case .sprinkler: startHeight = 0.80
        case .falconer: startHeight = 1.20
        default: startHeight = 1
        }
        let start = SIMD3(Float(defense.position.x), startHeight, Float(defense.position.z))
        let end = SIMD3(
            Float(target.position.x),
            Float(target.flightHeight) + (target.type == .ruediger ? 1.05 : 0.65),
            Float(target.position.z)
        )
        let midpoint = (start + end) * 0.5
        let distance = max(simd_distance(start, end), 0.01)

        visual.attackEffect.isEnabled = true
        visual.attackEffect.look(at: end, from: midpoint, relativeTo: effectsRoot)
        // Apply length after `look` so the orientation helper cannot replace it.
        visual.attackEffect.scale = SIMD3(1, 1, distance)

        let flash = 0.72 + (sin(Float(simulationTime) * 32) * 0.2)
        setOpacity(flash, on: visual.attackEffect)
    }

    private func attackWindow(for type: DefenseType) -> Double {
        switch type {
        case .plasticOwl: 0.13
        case .sprinkler: 0.18
        case .falconer: 0.22
        default: 0.2
        }
    }

    private func addPigeonAccessory(type: PigeonType, height: Float, to root: Entity) {
        switch type {
        case .normal, .ruediger: break
        case .dieter:
            root.addChild(makeBox(size: SIMD3(0.75, 0.14, 0.1), color: RenderingPalette.yellow,
                position: SIMD3(0, height * 0.4, 0.04)))
        case .sabine:
            root.addChild(makeBox(size: SIMD3(0.3, 0.38, 0.15), color: RenderingPalette.coral,
                position: SIMD3(-0.3, height * 0.55, 0.04), cornerRadius: 0.06))
        case .volker:
            root.addChild(makeBox(size: SIMD3(0.65, 0.17, 0.15), color: RenderingPalette.window,
                position: SIMD3(0.1, height, 0.04)))
        case .ingo:
            root.addChild(makeBox(size: SIMD3(0.25, 0.42, 0.09), color: RenderingPalette.teal,
                position: SIMD3(0.55, height * 0.6, 0.04), cornerRadius: 0.035))
        case .gurrmann:
            root.addChild(makeBox(size: SIMD3(0.47, 0.56, 0.09), color: .white,
                position: SIMD3(0.45, height * 0.5, 0.04)))
            root.addChild(makeBox(size: SIMD3(0.3, 0.09, 0.12), color: RenderingPalette.coral,
                position: SIMD3(0.45, height * 0.55, 0.1)))
        case .coalition:
            for x: Float in [-0.23, 0, 0.23] {
                root.addChild(makeSphere(radius: 0.1, color: RenderingPalette.teal,
                    position: SIMD3(x, height + 0.07, 0.04)))
            }
        }
    }

    private func makeExperimentalDefense(_ type: DefenseType, on root: Entity, activity: Entity) {
        switch type {
        case .windowCD:
            root.addChild(makeBox(size: SIMD3(0.08, 1.4, 0.08), color: RenderingPalette.wood, position: SIMD3(0, 0.8, 0)))
            let disc = makeCylinder(height: 0.045, radius: 0.38, color: RenderingPalette.metal,
                position: SIMD3(0, 1.15, 0.05), metallic: true)
            disc.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
            root.addChild(disc)
        case .flutterTape:
            for x: Float in [-0.42, 0.42] {
                root.addChild(makeBox(size: SIMD3(0.07, 1.1, 0.07), color: RenderingPalette.wood, position: SIMD3(x, 0.7, 0)))
            }
            root.addChild(makeBox(size: SIMD3(1.0, 0.25, 0.07), color: RenderingPalette.yellow, position: SIMD3(0, 1.1, 0)))
        case .broomOfficer:
            root.addChild(makeCylinder(height: 0.85, radius: 0.24, color: RenderingPalette.coral, position: SIMD3(0, 0.6, 0)))
            root.addChild(makeSphere(radius: 0.22, color: RenderingPalette.cream, position: SIMD3(0, 1.23, 0)))
            root.addChild(makeBox(size: SIMD3(0.08, 1.3, 0.08), color: RenderingPalette.wood, position: SIMD3(0.4, 0.8, 0)))
            root.addChild(makeBox(size: SIMD3(0.55, 0.2, 0.25), color: RenderingPalette.yellow, position: SIMD3(0.4, 0.23, 0)))
        case .speaker:
            root.addChild(makeBox(size: SIMD3(0.65, 0.9, 0.4), color: RenderingPalette.metal, position: SIMD3(0, 0.7, 0), cornerRadius: 0.09))
            for y: Float in [0.5, 0.9] {
                root.addChild(makeSphere(radius: 0.18, color: .black, position: SIMD3(0, y, 0.2)))
            }
        case .paperwork:
            root.addChild(makeBox(size: SIMD3(0.7, 0.6, 0.6), color: RenderingPalette.wood, position: SIMD3(0, 0.5, 0)))
            for index in 0..<5 {
                root.addChild(makeBox(size: SIMD3(0.58, 0.045, 0.45), color: .white,
                    position: SIMD3(Float(index % 2) * 0.07, 0.85 + Float(index) * 0.055, 0)))
            }
        case .decoy:
            root.addChild(makeCylinder(height: 0.1, radius: 0.5, color: RenderingPalette.teal, position: SIMD3(0, 0.23, 0)))
            for index in 0..<7 {
                let angle = Float(index) * 0.9
                root.addChild(makeSphere(radius: 0.09, color: RenderingPalette.yellow,
                    position: SIMD3(cos(angle) * 0.3, 0.36, sin(angle) * 0.3)))
            }
        default: break
        }
        activity.addChild(makeSphere(radius: 0.2, color: RenderingPalette.teal.withAlphaComponent(0.5), position: SIMD3(0, 1.3, 0)))
    }
}

@MainActor
private struct BuildSpotVisual {
    let root: Entity
    let selection: Entity
}

@MainActor
private struct PigeonVisual {
    let root: Entity
    let bird: Entity
    let sprite: ModelEntity
    let shadow: ModelEntity
    let selection: ModelEntity
    let toleranceBar: Entity
    let toleranceFill: ModelEntity
    let barWidth: Float
    let type: PigeonType
}

@MainActor
private struct DefenseVisual {
    let root: Entity
    let aimRoot: Entity
    let activity: Entity
    let attackEffect: ModelEntity
    let type: DefenseType
}
