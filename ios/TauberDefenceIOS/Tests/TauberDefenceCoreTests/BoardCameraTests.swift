import XCTest
@testable import TauberDefenceCore

final class BoardCameraTests: XCTestCase {
    func testProjectionTracksZoomAndRotation() {
        var camera = BoardCamera()
        XCTAssertEqual(camera.verticalSpan, 23.6)
        XCTAssertEqual(camera.project(camera.target, width: 800, height: 400), SIMD2(400, 200))
        let point = SIMD3<Double>(3, 0.2, 2)
        let initial = camera.project(point, width: 800, height: 400)
        camera.setZoom(2)
        let zoomed = camera.project(point, width: 800, height: 400)
        XCTAssertEqual(zoomed.x - 400, (initial.x - 400) * 2, accuracy: 0.0001)
        camera.setYaw(camera.yaw + .pi)
        XCTAssertEqual(camera.project(point, width: 800, height: 400).x - 400, -(zoomed.x - 400), accuracy: 0.0001)
        XCTAssertGreaterThan(camera.eye.y, camera.target.y)
    }

    func testCameraBoundsAndInvalidGestures() {
        var camera = BoardCamera()
        camera.setZoom(99)
        XCTAssertEqual(camera.zoom, 2.4)
        camera.setZoom(-1)
        XCTAssertEqual(camera.zoom, 0.7)
        camera.setZoom(.nan)
        XCTAssertEqual(camera.zoom, 0.7)
        let yaw = camera.yaw
        camera.setYaw(.infinity)
        XCTAssertEqual(camera.yaw, yaw)
        camera.setYaw(.pi * 10)
        XCTAssertEqual(camera.yaw, 0, accuracy: 0.0001)
    }
}
