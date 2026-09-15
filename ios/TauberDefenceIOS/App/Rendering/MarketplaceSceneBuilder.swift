import RealityKit
import TauberDefenceCore
import UIKit
import simd

/// Builds the deliberately toy-like, low-poly marketplace used by the vertical slice.
/// The level definition owns the route; this renderer only gives it a visual treatment.
@MainActor
enum MarketplaceSceneBuilder {
    static func makeScene(for level: LevelDefinition) -> Entity {
        let root = Entity()
        root.name = "marketplace.environment"

        addGround(to: root)
        addRoad(level.path, to: root)
        addHouses(to: root)
        addCafe(at: level.path.end, to: root)
        addFountain(to: root)
        addStatue(to: root)
        addStreetFurniture(to: root)
        addTrees(to: root)
        addSpawnMarker(at: level.path.start, to: root)
        addLighting(to: root)

        return root
    }

    private static func addGround(to root: Entity) {
        root.addChild(makeBox(
            size: SIMD3(19.5, 0.22, 12.5),
            color: RenderingPalette.grass,
            position: SIMD3(0.4, -0.14, 0),
            cornerRadius: 0.22
        ))

        root.addChild(makeBox(
            size: SIMD3(11.0, 0.06, 7.0),
            color: RenderingPalette.plaza,
            position: SIMD3(0.6, 0.005, 0),
            cornerRadius: 0.3
        ))
    }

    private static func addRoad(_ path: PathDefinition, to root: Entity) {
        for (index, pair) in zip(path.waypoints, path.waypoints.dropFirst()).enumerated() {
            let start = pair.0
            let end = pair.1
            let dx = Float(end.x - start.x)
            let dz = Float(end.z - start.z)
            let length = max(hypot(dx, dz), 0.01)
            let center = SIMD3(
                Float((start.x + end.x) * 0.5),
                0.055,
                Float((start.z + end.z) * 0.5)
            )

            let curb = makeBox(
                size: SIMD3(1.52, 0.055, length + 0.35),
                color: RenderingPalette.roadEdge,
                position: center,
                cornerRadius: 0.18
            )
            curb.orientation = simd_quatf(angle: atan2(dx, dz), axis: SIMD3(0, 1, 0))
            curb.name = "road.curb.\(index)"
            root.addChild(curb)

            let road = makeBox(
                size: SIMD3(1.25, 0.065, length + 0.38),
                color: RenderingPalette.road,
                position: center + SIMD3(0, 0.035, 0),
                cornerRadius: 0.16
            )
            road.orientation = curb.orientation
            road.name = "road.segment.\(index)"
            root.addChild(road)
        }

        for (index, waypoint) in path.waypoints.enumerated() {
            let joint = makeCylinder(
                height: 0.07,
                radius: 0.64,
                color: RenderingPalette.road,
                position: SIMD3(Float(waypoint.x), 0.105, Float(waypoint.z))
            )
            joint.name = "road.joint.\(index)"
            root.addChild(joint)
        }
    }

    private static func addHouses(to root: Entity) {
        let houses: [(SIMD3<Float>, SIMD3<Float>, UIColor, UIColor)] = [
            (SIMD3(-7.0, 0, 3.6), SIMD3(2.0, 2.5, 1.65), UIColor(red: 0.88, green: 0.52, blue: 0.48, alpha: 1), RenderingPalette.roof),
            (SIMD3(-3.7, 0, 4.5), SIMD3(2.35, 2.15, 1.55), UIColor(red: 0.92, green: 0.77, blue: 0.42, alpha: 1), UIColor(red: 0.40, green: 0.25, blue: 0.20, alpha: 1)),
            (SIMD3(2.8, 0, 4.55), SIMD3(2.0, 2.65, 1.5), UIColor(red: 0.65, green: 0.77, blue: 0.88, alpha: 1), UIColor(red: 0.22, green: 0.34, blue: 0.49, alpha: 1)),
            (SIMD3(7.0, 0, 3.75), SIMD3(2.05, 2.25, 1.75), UIColor(red: 0.75, green: 0.60, blue: 0.83, alpha: 1), UIColor(red: 0.35, green: 0.23, blue: 0.42, alpha: 1)),
            (SIMD3(-7.0, 0, -3.7), SIMD3(2.1, 2.0, 1.65), UIColor(red: 0.68, green: 0.82, blue: 0.62, alpha: 1), UIColor(red: 0.28, green: 0.43, blue: 0.25, alpha: 1)),
            (SIMD3(-3.25, 0, -4.55), SIMD3(2.25, 2.45, 1.55), UIColor(red: 0.92, green: 0.68, blue: 0.53, alpha: 1), RenderingPalette.roof),
            (SIMD3(2.0, 0, -4.6), SIMD3(2.15, 2.2, 1.55), UIColor(red: 0.87, green: 0.84, blue: 0.70, alpha: 1), UIColor(red: 0.32, green: 0.34, blue: 0.36, alpha: 1)),
        ]

        for (index, house) in houses.enumerated() {
            root.addChild(makeHouse(
                position: house.0,
                size: house.1,
                facade: house.2,
                roof: house.3,
                index: index
            ))
        }
    }

    private static func makeHouse(
        position: SIMD3<Float>,
        size: SIMD3<Float>,
        facade: UIColor,
        roof: UIColor,
        index: Int
    ) -> Entity {
        let root = Entity()
        root.name = "house.\(index)"
        root.position = position

        let body = makeBox(
            size: size,
            color: facade,
            position: SIMD3(0, size.y * 0.5, 0),
            cornerRadius: 0.06
        )
        root.addChild(body)

        root.addChild(makeBox(
            size: SIMD3(size.x + 0.22, 0.34, size.z + 0.24),
            color: roof,
            position: SIMD3(0, size.y + 0.14, 0),
            cornerRadius: 0.1
        ))

        let frontZ = size.z * 0.5 + 0.015
        let windowY = size.y * 0.58
        for x in [-size.x * 0.25, size.x * 0.25] {
            root.addChild(makeBox(
                size: SIMD3(size.x * 0.22, size.y * 0.25, 0.035),
                color: RenderingPalette.window,
                position: SIMD3(x, windowY, frontZ),
                cornerRadius: 0.025
            ))
        }
        root.addChild(makeBox(
            size: SIMD3(size.x * 0.22, size.y * 0.36, 0.05),
            color: RenderingPalette.wood,
            position: SIMD3(0, size.y * 0.18, frontZ + 0.012),
            cornerRadius: 0.025
        ))

        return root
    }

    private static func addCafe(at destination: Waypoint, to root: Entity) {
        let cafe = Entity()
        cafe.name = "cafe.target"
        cafe.position = SIMD3(Float(destination.x) + 1.25, 0, Float(destination.z))

        cafe.addChild(makeBox(
            size: SIMD3(2.35, 2.45, 2.1),
            color: RenderingPalette.cafe,
            position: SIMD3(0, 1.225, 0),
            cornerRadius: 0.08
        ))
        cafe.addChild(makeBox(
            size: SIMD3(2.62, 0.32, 2.35),
            color: UIColor(red: 0.35, green: 0.18, blue: 0.17, alpha: 1),
            position: SIMD3(0, 2.53, 0),
            cornerRadius: 0.1
        ))

        let frontZ: Float = 1.07
        cafe.addChild(makeBox(
            size: SIMD3(0.65, 1.25, 0.05),
            color: UIColor(red: 0.22, green: 0.16, blue: 0.13, alpha: 1),
            position: SIMD3(0.54, 0.63, frontZ),
            cornerRadius: 0.025
        ))
        cafe.addChild(makeBox(
            size: SIMD3(0.9, 0.88, 0.045),
            color: RenderingPalette.window,
            position: SIMD3(-0.55, 1.28, frontZ + 0.01),
            cornerRadius: 0.035
        ))

        // A striped awning makes the goal readable without requiring 3D text.
        for stripe in -3...3 {
            let stripeColor = stripe.isMultiple(of: 2) ? RenderingPalette.cream : RenderingPalette.coral
            cafe.addChild(makeBox(
                size: SIMD3(0.34, 0.12, 0.78),
                color: stripeColor,
                position: SIMD3(Float(stripe) * 0.335, 1.92, 1.23),
                cornerRadius: 0.02
            ))
        }

        let cup = Entity()
        cup.position = SIMD3(0, 2.96, 0)
        cup.addChild(makeCylinder(height: 0.38, radius: 0.26, color: .white))
        cup.addChild(makeCylinder(
            height: 0.05,
            radius: 0.32,
            color: RenderingPalette.coral,
            position: SIMD3(0, -0.22, 0)
        ))
        cafe.addChild(cup)

        root.addChild(cafe)
    }

    private static func addFountain(to root: Entity) {
        let fountain = Entity()
        fountain.name = "fountain"
        fountain.position = SIMD3(0.1, 0, -3.25)
        fountain.addChild(makeCylinder(height: 0.18, radius: 1.0, color: RenderingPalette.stone, position: SIMD3(0, 0.09, 0)))
        fountain.addChild(makeCylinder(height: 0.12, radius: 0.78, color: RenderingPalette.water, position: SIMD3(0, 0.21, 0)))
        fountain.addChild(makeCylinder(height: 0.92, radius: 0.16, color: RenderingPalette.stone, position: SIMD3(0, 0.58, 0)))
        fountain.addChild(makeCylinder(height: 0.12, radius: 0.48, color: RenderingPalette.stone, position: SIMD3(0, 1.02, 0)))

        for angle in stride(from: Float.zero, to: Float.pi * 2, by: Float.pi / 3) {
            let droplet = makeSphere(
                radius: 0.08,
                color: RenderingPalette.water,
                position: SIMD3(cos(angle) * 0.36, 1.22, sin(angle) * 0.36)
            )
            fountain.addChild(droplet)
        }
        root.addChild(fountain)
    }

    private static func addStatue(to root: Entity) {
        let statue = Entity()
        statue.name = "statue"
        statue.position = SIMD3(-0.7, 0, 4.25)
        statue.addChild(makeBox(size: SIMD3(0.85, 0.45, 0.85), color: RenderingPalette.stone, position: SIMD3(0, 0.225, 0)))
        statue.addChild(makeCylinder(height: 1.15, radius: 0.23, color: RenderingPalette.stone, position: SIMD3(0, 0.98, 0)))
        statue.addChild(makeSphere(radius: 0.28, color: RenderingPalette.metal, position: SIMD3(0, 1.67, 0)))
        statue.addChild(makeCone(height: 0.38, radius: 0.19, color: RenderingPalette.metal, position: SIMD3(0.27, 1.66, 0)))
        root.addChild(statue)
    }

    private static func addStreetFurniture(to root: Entity) {
        for (index, position) in [SIMD3<Float>(-2.0, 0, 2.8), SIMD3<Float>(3.1, 0, -3.0), SIMD3<Float>(5.0, 0, 3.8)].enumerated() {
            let bench = Entity()
            bench.name = "bench.\(index)"
            bench.position = position
            bench.addChild(makeBox(size: SIMD3(1.15, 0.14, 0.42), color: RenderingPalette.wood, position: SIMD3(0, 0.48, 0)))
            bench.addChild(makeBox(size: SIMD3(1.15, 0.48, 0.12), color: RenderingPalette.wood, position: SIMD3(0, 0.73, -0.18)))
            for x in [-0.42 as Float, 0.42] {
                bench.addChild(makeBox(size: SIMD3(0.12, 0.48, 0.12), color: RenderingPalette.metal, position: SIMD3(x, 0.24, 0), metallic: true))
            }
            root.addChild(bench)
        }

        for (index, position) in [SIMD3<Float>(-5.5, 0, 1.65), SIMD3<Float>(4.8, 0, 0.8), SIMD3<Float>(6.1, 0, -2.15)].enumerated() {
            let bin = Entity()
            bin.name = "trash-bin.\(index)"
            bin.position = position
            bin.addChild(makeCylinder(height: 0.68, radius: 0.28, color: RenderingPalette.metal, position: SIMD3(0, 0.34, 0), metallic: true))
            bin.addChild(makeCylinder(height: 0.1, radius: 0.33, color: UIColor(red: 0.20, green: 0.23, blue: 0.25, alpha: 1), position: SIMD3(0, 0.72, 0), metallic: true))
            root.addChild(bin)
        }
    }

    private static func addTrees(to root: Entity) {
        let positions: [SIMD3<Float>] = [
            SIMD3(-8.2, 0, 0.6), SIMD3(-5.5, 0, 4.7), SIMD3(-5.9, 0, -4.7),
            SIMD3(0.0, 0, 5.0), SIMD3(4.8, 0, 4.8), SIMD3(4.8, 0, -4.7),
            SIMD3(8.6, 0, 2.2), SIMD3(8.5, 0, -3.5),
        ]

        for (index, position) in positions.enumerated() {
            let tree = Entity()
            tree.name = "tree.\(index)"
            tree.position = position
            tree.addChild(makeCylinder(height: 1.15, radius: 0.15, color: RenderingPalette.wood, position: SIMD3(0, 0.575, 0)))
            tree.addChild(makeSphere(radius: 0.72, color: RenderingPalette.grassDark, position: SIMD3(0, 1.35, 0)))
            tree.addChild(makeSphere(radius: 0.5, color: UIColor(red: 0.27, green: 0.62, blue: 0.32, alpha: 1), position: SIMD3(0.38, 1.55, 0.12)))
            root.addChild(tree)
        }
    }

    private static func addSpawnMarker(at spawn: Waypoint, to root: Entity) {
        let marker = Entity()
        marker.name = "spawn.marker"
        marker.position = spawn.realityPosition
        marker.addChild(makeCylinder(height: 0.08, radius: 0.78, color: RenderingPalette.coral.withAlphaComponent(0.55), position: SIMD3(0, 0.12, 0)))
        marker.addChild(makeBox(size: SIMD3(0.12, 1.25, 0.12), color: RenderingPalette.coral, position: SIMD3(-0.62, 0.66, 0)))
        marker.addChild(makeBox(size: SIMD3(0.12, 1.25, 0.12), color: RenderingPalette.coral, position: SIMD3(0.62, 0.66, 0)))
        marker.addChild(makeBox(size: SIMD3(1.36, 0.14, 0.14), color: RenderingPalette.coral, position: SIMD3(0, 1.25, 0)))
        root.addChild(marker)
    }

    private static func addLighting(to root: Entity) {
        let light = Entity()
        light.name = "marketplace.sun"
        light.components.set(DirectionalLightComponent(color: .white, intensity: 2_850))
        light.components.set(DirectionalLightComponent.Shadow(
            shadowProjection: .automatic(maximumDistance: 30),
            depthBias: 1.5
        ))
        light.look(
            at: SIMD3(0, 0, 0),
            from: SIMD3(-7, 13, 9),
            relativeTo: root
        )
        root.addChild(light)
    }
}
