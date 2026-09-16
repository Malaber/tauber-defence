import Foundation

/// Shared orthographic camera math for rendering and native, accessible board controls.
public struct BoardCamera: Equatable, Sendable {
    public private(set) var zoom = 1.0
    public private(set) var yaw = 0.644
    public let elevation = 0.663
    public let target = SIMD3<Double>(0.55, 0.25, -0.1)

    public init() {}

    public var verticalSpan: Double { 11.8 / zoom }
    public var eye: SIMD3<Double> {
        target + SIMD3(sin(yaw) * cos(elevation), sin(elevation), cos(yaw) * cos(elevation)) * 23.2
    }

    public mutating func setZoom(_ value: Double) {
        guard value.isFinite else { return }
        zoom = min(2.4, max(0.7, value))
    }

    public mutating func setYaw(_ value: Double) {
        guard value.isFinite else { return }
        yaw = value.remainder(dividingBy: .pi * 2)
    }

    /// Screen coordinates use a top-left origin, in the same viewport as RealityView.
    public func project(_ point: SIMD3<Double>, width: Double, height: Double) -> SIMD2<Double> {
        let offset = point - target
        let right = SIMD3(cos(yaw), 0, -sin(yaw))
        let up = SIMD3(-sin(yaw) * sin(elevation), cos(elevation), -cos(yaw) * sin(elevation))
        let x = offset.x * right.x + offset.y * right.y + offset.z * right.z
        let y = offset.x * up.x + offset.y * up.y + offset.z * up.z
        return SIMD2(width / 2 + x * height / verticalSpan, height / 2 - y * height / verticalSpan)
    }
}
