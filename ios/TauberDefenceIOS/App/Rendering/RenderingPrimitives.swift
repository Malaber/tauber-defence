import RealityKit
import TauberDefenceCore
import UIKit
import simd

@MainActor
enum RenderingPalette {
    static let grass = UIColor(red: 0.47, green: 0.70, blue: 0.47, alpha: 1)
    static let grassDark = UIColor(red: 0.34, green: 0.57, blue: 0.37, alpha: 1)
    static let plaza = UIColor(red: 0.83, green: 0.78, blue: 0.66, alpha: 1)
    static let road = UIColor(red: 0.42, green: 0.43, blue: 0.42, alpha: 1)
    static let roadEdge = UIColor(red: 0.69, green: 0.66, blue: 0.58, alpha: 1)
    static let cafe = UIColor(red: 0.91, green: 0.58, blue: 0.40, alpha: 1)
    static let teal = UIColor(red: 0.10, green: 0.82, blue: 0.75, alpha: 1)
    static let yellow = UIColor(red: 1.00, green: 0.79, blue: 0.20, alpha: 1)
    static let coral = UIColor(red: 0.96, green: 0.38, blue: 0.31, alpha: 1)
    static let water = UIColor(red: 0.20, green: 0.70, blue: 0.92, alpha: 0.82)
    static let wood = UIColor(red: 0.42, green: 0.25, blue: 0.14, alpha: 1)
    static let metal = UIColor(red: 0.34, green: 0.38, blue: 0.42, alpha: 1)
    static let stone = UIColor(red: 0.62, green: 0.64, blue: 0.63, alpha: 1)
    static let roof = UIColor(red: 0.48, green: 0.19, blue: 0.18, alpha: 1)
    static let cream = UIColor(red: 0.96, green: 0.91, blue: 0.77, alpha: 1)
    static let window = UIColor(red: 0.30, green: 0.68, blue: 0.82, alpha: 1)
}

extension Waypoint {
    var realityPosition: SIMD3<Float> {
        SIMD3(Float(x), 0, Float(z))
    }
}

@MainActor
func makeLitMaterial(
    _ color: UIColor,
    roughness: Float = 0.82,
    metallic: Bool = false
) -> SimpleMaterial {
    SimpleMaterial(color: color, roughness: .float(roughness), isMetallic: metallic)
}

@MainActor
func makeUnlitMaterial(_ color: UIColor) -> UnlitMaterial {
    var material = UnlitMaterial(color: color)
    material.faceCulling = .none
    return material
}

@MainActor
func makeBox(
    size: SIMD3<Float>,
    color: UIColor,
    position: SIMD3<Float> = .zero,
    cornerRadius: Float = 0.04,
    metallic: Bool = false
) -> ModelEntity {
    let model = ModelEntity(
        mesh: .generateBox(size: size, cornerRadius: cornerRadius),
        materials: [makeLitMaterial(color, metallic: metallic)]
    )
    model.position = position
    return model
}

@MainActor
func makeCylinder(
    height: Float,
    radius: Float,
    color: UIColor,
    position: SIMD3<Float> = .zero,
    metallic: Bool = false
) -> ModelEntity {
    let model = ModelEntity(
        mesh: .generateCylinder(height: height, radius: radius),
        materials: [makeLitMaterial(color, metallic: metallic)]
    )
    model.position = position
    return model
}

@MainActor
func makeSphere(
    radius: Float,
    color: UIColor,
    position: SIMD3<Float> = .zero,
    metallic: Bool = false
) -> ModelEntity {
    let model = ModelEntity(
        mesh: .generateSphere(radius: radius),
        materials: [makeLitMaterial(color, metallic: metallic)]
    )
    model.position = position
    return model
}

@MainActor
func makeCone(
    height: Float,
    radius: Float,
    color: UIColor,
    position: SIMD3<Float> = .zero,
    metallic: Bool = false
) -> ModelEntity {
    let model = ModelEntity(
        mesh: .generateCone(height: height, radius: radius),
        materials: [makeLitMaterial(color, metallic: metallic)]
    )
    model.position = position
    return model
}

@MainActor
func setOpacity(_ opacity: Float, on entity: Entity) {
    entity.components.set(OpacityComponent(opacity: min(max(opacity, 0), 1)))
}

@MainActor
func removeAllChildren(from entity: Entity) {
    for child in Array(entity.children) {
        child.removeFromParent()
    }
}

func yaw(from source: Waypoint, to target: Waypoint) -> Float {
    atan2(Float(target.x - source.x), Float(target.z - source.z))
}
