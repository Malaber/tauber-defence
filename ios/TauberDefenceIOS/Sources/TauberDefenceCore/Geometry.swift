import Foundation

/// A point in the horizontal X/Z plane of the rendered world.
public struct Waypoint: Codable, Hashable, Sendable {
    public let x: Double
    public let z: Double

    public init(x: Double, z: Double) {
        self.x = x
        self.z = z
    }

    public func distance(to other: Waypoint) -> Double {
        hypot(other.x - x, other.z - z)
    }

    public func interpolated(to other: Waypoint, fraction: Double) -> Waypoint {
        let clampedFraction = min(max(fraction, 0), 1)
        return Waypoint(
            x: x + ((other.x - x) * clampedFraction),
            z: z + ((other.z - z) * clampedFraction)
        )
    }
}

public struct PathDefinition: Codable, Hashable, Sendable {
    public let waypoints: [Waypoint]

    public init(waypoints: [Waypoint]) {
        precondition(waypoints.count >= 2, "A pigeon path needs at least two waypoints")
        self.waypoints = waypoints
    }

    public var start: Waypoint { waypoints[0] }
    public var end: Waypoint { waypoints[waypoints.count - 1] }

    public var totalLength: Double {
        zip(waypoints, waypoints.dropFirst()).reduce(0) { partialResult, pair in
            partialResult + pair.0.distance(to: pair.1)
        }
    }

    public func position(atDistance requestedDistance: Double) -> Waypoint {
        guard requestedDistance > 0 else { return start }

        var remainingDistance = requestedDistance
        for (start, end) in zip(waypoints, waypoints.dropFirst()) {
            let segmentLength = start.distance(to: end)
            guard segmentLength > 0 else { continue }

            if remainingDistance <= segmentLength {
                return start.interpolated(
                    to: end,
                    fraction: remainingDistance / segmentLength
                )
            }
            remainingDistance -= segmentLength
        }

        return end
    }
}
