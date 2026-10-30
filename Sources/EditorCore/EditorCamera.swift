import Engine
import Foundation

/// The viewport's camera, separate from the scene's `Camera` entities: an orbit camera around
/// `pivot` (yaw / pitch / distance) that can also fly (look around from the eye, move the eye).
public struct EditorCamera: Equatable, Sendable {
    public var pivot: Vec3
    /// Radians about +Y; 0 looks down -Z.
    public var yaw: Float
    /// Radians; positive looks down at the pivot.
    public var pitch: Float
    public var distance: Float
    public var fovY: Float = .pi / 3.4
    public var near: Float = 0.05
    public var far: Float = 1000

    public static let pitchLimit: Float = 1.54
    public static let distanceRange: ClosedRange<Float> = 0.2...2000

    public init(pivot: Vec3 = Vec3(0, 0.5, 0), yaw: Float = -0.6, pitch: Float = 0.5, distance: Float = 15) {
        self.pivot = pivot
        self.yaw = yaw
        self.pitch = pitch
        self.distance = distance
    }

    /// The camera position.
    public var eye: Vec3 { pivot - forward * distance }

    /// The view direction (unit length).
    public var forward: Vec3 {
        -Vec3(cosf(pitch) * sinf(yaw), sinf(pitch), cosf(pitch) * cosf(yaw))
    }

    public var right: Vec3 { normalize(cross(forward, Vec3(0, 1, 0))) }
    public var up: Vec3 { cross(right, forward) }

    public var viewMatrix: Mat4 { Mat4.lookAt(eye: eye, target: pivot) }

    public func projection(aspect: Float) -> Mat4 {
        Mat4.perspective(fovY: fovY, aspect: aspect, near: near, far: far)
    }

    public func sceneView(aspect: Float, clearColor: Vec4) -> SceneView {
        SceneView(view: viewMatrix, projection: projection(aspect: aspect), clearColor: clearColor)
    }

    /// Orbits around the pivot by a pointer movement in points.
    public mutating func orbit(by delta: Vec2) {
        yaw -= delta.x * 0.008
        pitch = min(max(pitch + delta.y * 0.008, -Self.pitchLimit), Self.pitchLimit)
    }

    /// Slides the camera and pivot so the point under the pointer follows it (`viewportHeight` in points).
    public mutating func pan(by delta: Vec2, viewportHeight: Float) {
        let worldPerPoint = 2 * distance * tanf(fovY / 2) / max(viewportHeight, 1)
        pivot += (-right * delta.x + up * delta.y) * worldPerPoint
    }

    /// Wheel zoom: positive `scroll` (wheel up) moves in, proportionally to the distance.
    public mutating func zoom(scroll: Float) {
        distance = min(max(distance * expf(-scroll * 0.01), Self.distanceRange.lowerBound), Self.distanceRange.upperBound)
    }

    /// Fly mode: turns the view around the eye (the pivot moves, the eye stays) by a raw mouse delta.
    public mutating func look(by delta: Vec2) {
        let eye = self.eye
        yaw -= delta.x * 0.004
        pitch = min(max(pitch - delta.y * 0.004, -Self.pitchLimit), Self.pitchLimit)
        pivot = eye + forward * distance
    }

    /// Fly mode: moves eye and pivot by `move` (x right, y world up, z forward) * `speed` * `dt`.
    public mutating func fly(_ move: Vec3, speed: Float, dt: Float) {
        guard move != .zero else { return }
        pivot += (right * move.x + Vec3(0, 1, 0) * move.y + forward * move.z) * (speed * dt)
    }

    /// Moves the pivot to `bounds`' center and backs off until the box fits the view.
    public mutating func frame(_ bounds: Bounds) {
        let radius = max(length(bounds.halfExtent), 0.25)
        pivot = bounds.center
        distance = min(max(radius / sinf(fovY / 2) * 1.15, Self.distanceRange.lowerBound), Self.distanceRange.upperBound)
    }
}
