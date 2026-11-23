import Foundation
import EngineAssets
import EngineCore
import EngineScene

// A camera rig is a "virtual camera": a component that says how a camera should follow a target
// (orbit behind it, look through its eyes, look down on it, follow it from the side). Any number
// of rigs can be in a scene; the "cameraRigs" system (CameraRigSystem.swift) picks the live one by
// `priority`, works out where its camera goes and writes that into a real `Camera` entity's
// `Transform` (blending over `blendTime` when the live rig changes). Switching shots is changing
// which rig wins: `World.activateCameraRig(_:)`, the Visual Script node "Activate Camera Rig" or
// the `cameraRig.activate` tool raise a rig's priority above the others.
//
// Every setting is optional in scene files. Settings whose good value depends on the mode
// (distance, pitch and its limits, damping) are optional fields: nil uses the mode's default
// (`CameraRigMode.defaults`).

/// How a `CameraRig` places its camera.
public enum CameraRigMode: String, Codable, Sendable, CaseIterable {
    /// Behind and above the target, orbiting it (shoulder offset, zoom, auto-recenter).
    case thirdPerson
    /// At the target's eyes (`targetOffset`), looking around (head bob while it moves).
    case firstPerson
    /// High above, looking down at `pitch` from a fixed heading (`yaw`); orbit input turns it.
    case topDown
    /// From the side (`sideDirection`), following the target through a dead zone with look-ahead
    /// in its direction of travel.
    case sideScroller
    /// Where the rig's own entity is (a placed camera shot): blend to it like to any rig.
    case fixed

    /// The values the mode-dependent optional settings take when unset.
    public struct Defaults: Sendable {
        public var distance: Float
        public var pitch: Float
        public var minPitch: Float
        public var maxPitch: Float
        public var positionDamping: Vec3
        public var rotationDamping: Vec2
    }

    public var defaults: Defaults {
        switch self {
        case .thirdPerson: Defaults(distance: 4, pitch: 15, minPitch: -35, maxPitch: 70,
                                    positionDamping: Vec3(0.08, 0.15, 0.08), rotationDamping: Vec2(0.06, 0.06))
        case .firstPerson: Defaults(distance: 0, pitch: 0, minPitch: -80, maxPitch: 80, positionDamping: .zero, rotationDamping: .zero)
        case .topDown: Defaults(distance: 14, pitch: 60, minPitch: 30, maxPitch: 89,
                                positionDamping: Vec3(0.15, 0.15, 0.15), rotationDamping: Vec2(0.1, 0.1))
        case .sideScroller: Defaults(distance: 10, pitch: 5, minPitch: -30, maxPitch: 45,
                                     positionDamping: Vec3(0.12, 0.25, 0.12), rotationDamping: .zero)
        case .fixed: Defaults(distance: 0, pitch: 0, minPitch: -89, maxPitch: 89, positionDamping: .zero, rotationDamping: .zero)
        }
    }
}

/// A camera rig: how a camera follows `target` (see the notes at the top of this file). Put it on
/// the `Camera` entity itself, or on its own entity to drive the scene's camera (`camera`).
///
/// Which camera it moves: `camera` if set, else its own entity if that has a `Camera`, else the
/// active camera with the lowest entity index (the one the renderer would use). Needs
/// `World.addCameraRigs(input:)` (the editor's play mode, `ScenePlayback`, GameRunner and
/// exported games add it), which runs in `.lateUpdate`.
public struct CameraRig: Component, Equatable, Sendable {
    public static let componentName = "CameraRig"
    public static var fieldHints: [String: FieldHints] {
        ["mode": FieldHints(tooltip: "thirdPerson, firstPerson, topDown, sideScroller or fixed (the rig entity's own pose)"),
         "enabled": FieldHints(tooltip: "Disabled rigs never go live"),
         "priority": FieldHints(range: -1000...1000, step: 1, tooltip: "The enabled rig with the highest priority is live (ties: lowest entity)"),
         "target": FieldHints(tooltip: "What it follows (none: the rig entity itself)"),
         "targetOffset": FieldHints(tooltip: "The followed point above the target's origin (world space): shoulders, eyes"),
         "camera": FieldHints(tooltip: "The Camera it moves (none: its own, else the scene's active camera)"),
         "fieldOfView": FieldHints(range: 5...150, step: 1, tooltip: "Degrees (vertical); unset keeps the camera's"),
         "blendTime": FieldHints(range: 0...10, step: 0.05, tooltip: "Seconds to blend to this rig when it goes live (0: cut)"),
         "blendCurve": FieldHints(tooltip: "Easing of the blend"),
         "distance": FieldHints(range: 0...200, step: 0.1, tooltip: "From the followed point (unset: the mode's)"),
         "minDistance": FieldHints(range: 0...200, step: 0.1, tooltip: "Closest zoom"),
         "maxDistance": FieldHints(range: 0...200, step: 0.1, tooltip: "Farthest zoom"),
         "shoulderOffset": FieldHints(tooltip: "Third person: camera-space offset (right, up, back) of the camera and its aim"),
         "yaw": FieldHints(range: -360...360, step: 1, tooltip: "Starting heading in degrees (0 looks along -Z); unset: behind the target"),
         "pitch": FieldHints(range: -89...89, step: 1, tooltip: "Starting pitch in degrees, positive looks down (unset: the mode's)"),
         "minPitch": FieldHints(range: -89...89, step: 1, tooltip: "Highest look up, degrees (negative is up)"),
         "maxPitch": FieldHints(range: -89...89, step: 1, tooltip: "Lowest look down, degrees"),
         "autoRecenter": FieldHints(tooltip: "Swing back behind the moving target after recenterDelay without orbit input"),
         "recenterDelay": FieldHints(range: 0...30, step: 0.1, tooltip: "Seconds without orbit input before recentering"),
         "recenterTime": FieldHints(range: 0...10, step: 0.05, tooltip: "Smoothing time of the swing back (seconds)"),
         "headBob": FieldHints(range: 0...0.5, step: 0.005, tooltip: "First person: bob height in meters at a run (0: off)"),
         "headBobFrequency": FieldHints(range: 0...5, step: 0.05, tooltip: "First person: bobs per meter walked"),
         "rotateTarget": FieldHints(tooltip: "First person: turn the target to the camera's heading"),
         "sideDirection": FieldHints(tooltip: "Side scroller: from the target toward the camera"),
         "deadZone": FieldHints(tooltip: "Side scroller: half-size (horizontal, vertical) of the box the target moves in without the camera following"),
         "lookAhead": FieldHints(range: 0...20, step: 0.1, tooltip: "Side scroller: meters the view leads in the direction of travel"),
         "lookAheadTime": FieldHints(range: 0...5, step: 0.05, tooltip: "Side scroller: smoothing time of the look-ahead"),
         "collision": FieldHints(tooltip: "Keep walls from coming between the target and the camera (sphere cast)"),
         "collisionRadius": FieldHints(range: 0...2, step: 0.01, tooltip: "Radius of the cast sphere"),
         "collisionMask": FieldHints(tooltip: "Layers that block the camera"),
         "pullInTime": FieldHints(range: 0...2, step: 0.01, tooltip: "Smoothing time when a wall pushes the camera in (small: fast)"),
         "easeOutTime": FieldHints(range: 0...5, step: 0.05, tooltip: "Smoothing time when the camera moves back out"),
         "positionDamping": FieldHints(tooltip: "Smoothing time per world axis (x, y, z) of the followed point, seconds; unset: the mode's"),
         "rotationDamping": FieldHints(tooltip: "Smoothing time of (yaw, pitch), seconds; unset: the mode's"),
         "inputEnabled": FieldHints(tooltip: "Orbit, zoom and recenter from input while live"),
         "orbitAction": FieldHints(tooltip: "Input vector action that orbits (default bindings: right stick)"),
         "zoomAction": FieldHints(tooltip: "Input axis action that zooms, positive in (default: d-pad up / down); the scroll wheel zooms too"),
         "recenterAction": FieldHints(tooltip: "Input button action that recenters (default: right stick click, middle mouse)"),
         "mouseOrbit": FieldHints(tooltip: "Mouse motion orbits while the mouse is captured or the right button is held"),
         "orbitSpeed": FieldHints(range: 0...1000, step: 5, tooltip: "Degrees per second at full stick"),
         "mouseSensitivity": FieldHints(range: 0...5, step: 0.01, tooltip: "Degrees per point of mouse motion"),
         "zoomSpeed": FieldHints(range: 0...100, step: 0.1, tooltip: "Meters per second at full zoom axis"),
         "isLive": FieldHints(readOnly: true, tooltip: "Written by the system: this rig drives the camera"),
         "blendWeight": FieldHints(readOnly: true, tooltip: "Written by the system: how far the blend to this rig is (1: done)"),
         "cameraPosition": FieldHints(readOnly: true, tooltip: "Written by the system: this rig's camera position (before blending)"),
         "probeStart": FieldHints(readOnly: true, tooltip: "Written by the system: where the collision cast starts (the followed point)"),
         "probeEnd": FieldHints(readOnly: true, tooltip: "Written by the system: where the camera wants to be"),
         "probeHit": FieldHints(readOnly: true, tooltip: "Written by the system: a wall is between the target and probeEnd")]
    }

    // Selection and output.
    public var mode: CameraRigMode
    public var enabled: Bool
    public var priority: Int
    public var target: EntityRef
    public var targetOffset: Vec3
    public var camera: EntityRef
    /// Vertical field of view in degrees; nil keeps the camera's.
    public var fieldOfView: Float?
    /// Seconds to blend to this rig when it goes live (0 cuts).
    public var blendTime: Float
    public var blendCurve: Easing

    // Framing (nil: the mode's default).
    public var distance: Float?
    public var minDistance: Float
    public var maxDistance: Float
    /// Third person: camera-space offset (right, up, back) of both the camera and its aim point.
    public var shoulderOffset: Vec3
    /// Starting heading in degrees (0 looks along -Z, 90 along -X); nil: behind the target
    /// (third and first person) or 0 (top-down).
    public var yaw: Float?
    /// Starting pitch in degrees, positive looking down.
    public var pitch: Float?
    public var minPitch: Float?
    public var maxPitch: Float?
    public var autoRecenter: Bool
    public var recenterDelay: Float
    public var recenterTime: Float

    // First person.
    public var headBob: Float
    public var headBobFrequency: Float
    public var rotateTarget: Bool

    // Side scroller.
    public var sideDirection: Vec3
    public var deadZone: Vec2
    public var lookAhead: Float
    public var lookAheadTime: Float

    // Collision.
    public var collision: Bool
    public var collisionRadius: Float
    public var collisionMask: UInt32
    public var pullInTime: Float
    public var easeOutTime: Float

    // Damping (nil: the mode's default).
    public var positionDamping: Vec3?
    public var rotationDamping: Vec2?

    // Input.
    public var inputEnabled: Bool
    public var orbitAction: String
    public var zoomAction: String
    public var recenterAction: String
    public var mouseOrbit: Bool
    public var orbitSpeed: Float
    public var mouseSensitivity: Float
    public var zoomSpeed: Float
    public var invertX: Bool
    public var invertY: Bool

    // State, written by the system.
    public var isLive: Bool
    public var blendWeight: Float
    public var cameraPosition: Vec3
    public var probeStart: Vec3
    public var probeEnd: Vec3
    public var probeHit: Bool

    /// What the system keeps between frames (not saved).
    var runtime = CameraRigRuntime()

    public init(mode: CameraRigMode = .thirdPerson, target: EntityRef = .none, priority: Int = 0, enabled: Bool = true,
                targetOffset: Vec3 = Vec3(0, 1.6, 0), camera: EntityRef = .none, fieldOfView: Float? = nil,
                blendTime: Float = 0.6, blendCurve: Easing = .cubicInOut,
                distance: Float? = nil, minDistance: Float = 1, maxDistance: Float = 30, shoulderOffset: Vec3 = Vec3(0.5, 0.15, 0),
                yaw: Float? = nil, pitch: Float? = nil, minPitch: Float? = nil, maxPitch: Float? = nil,
                autoRecenter: Bool = true, recenterDelay: Float = 1.5, recenterTime: Float = 0.5,
                headBob: Float = 0.04, headBobFrequency: Float = 1.4, rotateTarget: Bool = false,
                sideDirection: Vec3 = Vec3(0, 0, 1), deadZone: Vec2 = Vec2(1, 0.75), lookAhead: Float = 2, lookAheadTime: Float = 0.6,
                collision: Bool = true, collisionRadius: Float = 0.2, collisionMask: UInt32 = .max,
                pullInTime: Float = 0.04, easeOutTime: Float = 0.5,
                positionDamping: Vec3? = nil, rotationDamping: Vec2? = nil,
                inputEnabled: Bool = true, orbitAction: String = "look", zoomAction: String = "zoom", recenterAction: String = "recenter",
                mouseOrbit: Bool = true, orbitSpeed: Float = 150, mouseSensitivity: Float = 0.2, zoomSpeed: Float = 4,
                invertX: Bool = false, invertY: Bool = false) {
        self.mode = mode
        self.target = target
        self.priority = priority
        self.enabled = enabled
        self.targetOffset = targetOffset
        self.camera = camera
        self.fieldOfView = fieldOfView
        self.blendTime = blendTime
        self.blendCurve = blendCurve
        self.distance = distance
        self.minDistance = minDistance
        self.maxDistance = maxDistance
        self.shoulderOffset = shoulderOffset
        self.yaw = yaw
        self.pitch = pitch
        self.minPitch = minPitch
        self.maxPitch = maxPitch
        self.autoRecenter = autoRecenter
        self.recenterDelay = recenterDelay
        self.recenterTime = recenterTime
        self.headBob = headBob
        self.headBobFrequency = headBobFrequency
        self.rotateTarget = rotateTarget
        self.sideDirection = sideDirection
        self.deadZone = deadZone
        self.lookAhead = lookAhead
        self.lookAheadTime = lookAheadTime
        self.collision = collision
        self.collisionRadius = collisionRadius
        self.collisionMask = collisionMask
        self.pullInTime = pullInTime
        self.easeOutTime = easeOutTime
        self.positionDamping = positionDamping
        self.rotationDamping = rotationDamping
        self.inputEnabled = inputEnabled
        self.orbitAction = orbitAction
        self.zoomAction = zoomAction
        self.recenterAction = recenterAction
        self.mouseOrbit = mouseOrbit
        self.orbitSpeed = orbitSpeed
        self.mouseSensitivity = mouseSensitivity
        self.zoomSpeed = zoomSpeed
        self.invertX = invertX
        self.invertY = invertY
        isLive = false
        blendWeight = 0
        cameraPosition = .zero
        probeStart = .zero
        probeEnd = .zero
        probeHit = false
    }

    /// Forgets what the rig smoothed and zoomed: next frame it starts over from its settings,
    /// settled on the target (no damping).
    public mutating func restart() { runtime = CameraRigRuntime() }

    /// This frame's pose (nil before the system evaluated the rig).
    public var currentPose: CameraPose? { runtime.pose }

    // MARK: Resolved settings

    /// `distance`, else the mode's, within the zoom limits.
    public var resolvedDistance: Float {
        let d = distance ?? mode.defaults.distance
        return min(max(d, min(minDistance, maxDistance)), max(maxDistance, minDistance))
    }
    public var resolvedPitch: Float { min(max(pitch ?? mode.defaults.pitch, resolvedMinPitch), resolvedMaxPitch) }
    public var resolvedMinPitch: Float { min(max(minPitch ?? mode.defaults.minPitch, -89), 89) }
    public var resolvedMaxPitch: Float { max(min(maxPitch ?? mode.defaults.maxPitch, 89), resolvedMinPitch) }
    public var resolvedPositionDamping: Vec3 { positionDamping ?? mode.defaults.positionDamping }
    public var resolvedRotationDamping: Vec2 { rotationDamping ?? mode.defaults.rotationDamping }

    // MARK: Coding

    private enum CodingKeys: String, CodingKey {
        case mode, enabled, priority, target, targetOffset, camera, fieldOfView, blendTime, blendCurve
        case distance, minDistance, maxDistance, shoulderOffset, yaw, pitch, minPitch, maxPitch, autoRecenter, recenterDelay, recenterTime
        case headBob, headBobFrequency, rotateTarget, sideDirection, deadZone, lookAhead, lookAheadTime
        case collision, collisionRadius, collisionMask, pullInTime, easeOutTime, positionDamping, rotationDamping
        case inputEnabled, orbitAction, zoomAction, recenterAction, mouseOrbit, orbitSpeed, mouseSensitivity, zoomSpeed, invertX, invertY
        case isLive, blendWeight, cameraPosition, probeStart, probeEnd, probeHit
    }

    /// Every key is optional.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        func read<T: Decodable>(_ key: CodingKeys, _ value: inout T) throws {
            if let v = try c.decodeIfPresent(T.self, forKey: key) { value = v }
        }
        func readOptional<T: Decodable>(_ key: CodingKeys, _ value: inout T?) throws {
            if let v = try c.decodeIfPresent(T.self, forKey: key) { value = v }
        }
        try read(.mode, &mode); try read(.enabled, &enabled); try read(.priority, &priority); try read(.target, &target)
        try read(.targetOffset, &targetOffset); try read(.camera, &camera); try readOptional(.fieldOfView, &fieldOfView)
        try read(.blendTime, &blendTime); try read(.blendCurve, &blendCurve)
        try readOptional(.distance, &distance); try read(.minDistance, &minDistance); try read(.maxDistance, &maxDistance)
        try read(.shoulderOffset, &shoulderOffset); try readOptional(.yaw, &yaw); try readOptional(.pitch, &pitch)
        try readOptional(.minPitch, &minPitch); try readOptional(.maxPitch, &maxPitch); try read(.autoRecenter, &autoRecenter)
        try read(.recenterDelay, &recenterDelay); try read(.recenterTime, &recenterTime)
        try read(.headBob, &headBob); try read(.headBobFrequency, &headBobFrequency); try read(.rotateTarget, &rotateTarget)
        try read(.sideDirection, &sideDirection); try read(.deadZone, &deadZone); try read(.lookAhead, &lookAhead)
        try read(.lookAheadTime, &lookAheadTime)
        try read(.collision, &collision); try read(.collisionRadius, &collisionRadius); try read(.collisionMask, &collisionMask)
        try read(.pullInTime, &pullInTime); try read(.easeOutTime, &easeOutTime)
        try readOptional(.positionDamping, &positionDamping); try readOptional(.rotationDamping, &rotationDamping)
        try read(.inputEnabled, &inputEnabled); try read(.orbitAction, &orbitAction); try read(.zoomAction, &zoomAction)
        try read(.recenterAction, &recenterAction); try read(.mouseOrbit, &mouseOrbit); try read(.orbitSpeed, &orbitSpeed)
        try read(.mouseSensitivity, &mouseSensitivity); try read(.zoomSpeed, &zoomSpeed); try read(.invertX, &invertX)
        try read(.invertY, &invertY)
        try read(.isLive, &isLive); try read(.blendWeight, &blendWeight); try read(.cameraPosition, &cameraPosition)
        try read(.probeStart, &probeStart); try read(.probeEnd, &probeEnd); try read(.probeHit, &probeHit)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(mode, forKey: .mode); try c.encode(enabled, forKey: .enabled); try c.encode(priority, forKey: .priority)
        try c.encode(target, forKey: .target); try c.encode(targetOffset, forKey: .targetOffset); try c.encode(camera, forKey: .camera)
        try c.encodeIfPresent(fieldOfView, forKey: .fieldOfView); try c.encode(blendTime, forKey: .blendTime)
        try c.encode(blendCurve, forKey: .blendCurve)
        try c.encodeIfPresent(distance, forKey: .distance); try c.encode(minDistance, forKey: .minDistance)
        try c.encode(maxDistance, forKey: .maxDistance); try c.encode(shoulderOffset, forKey: .shoulderOffset)
        try c.encodeIfPresent(yaw, forKey: .yaw); try c.encodeIfPresent(pitch, forKey: .pitch)
        try c.encodeIfPresent(minPitch, forKey: .minPitch); try c.encodeIfPresent(maxPitch, forKey: .maxPitch)
        try c.encode(autoRecenter, forKey: .autoRecenter); try c.encode(recenterDelay, forKey: .recenterDelay)
        try c.encode(recenterTime, forKey: .recenterTime)
        try c.encode(headBob, forKey: .headBob); try c.encode(headBobFrequency, forKey: .headBobFrequency)
        try c.encode(rotateTarget, forKey: .rotateTarget)
        try c.encode(sideDirection, forKey: .sideDirection); try c.encode(deadZone, forKey: .deadZone)
        try c.encode(lookAhead, forKey: .lookAhead); try c.encode(lookAheadTime, forKey: .lookAheadTime)
        try c.encode(collision, forKey: .collision); try c.encode(collisionRadius, forKey: .collisionRadius)
        try c.encode(collisionMask, forKey: .collisionMask); try c.encode(pullInTime, forKey: .pullInTime)
        try c.encode(easeOutTime, forKey: .easeOutTime)
        try c.encodeIfPresent(positionDamping, forKey: .positionDamping); try c.encodeIfPresent(rotationDamping, forKey: .rotationDamping)
        try c.encode(inputEnabled, forKey: .inputEnabled); try c.encode(orbitAction, forKey: .orbitAction)
        try c.encode(zoomAction, forKey: .zoomAction); try c.encode(recenterAction, forKey: .recenterAction)
        try c.encode(mouseOrbit, forKey: .mouseOrbit); try c.encode(orbitSpeed, forKey: .orbitSpeed)
        try c.encode(mouseSensitivity, forKey: .mouseSensitivity); try c.encode(zoomSpeed, forKey: .zoomSpeed)
        try c.encode(invertX, forKey: .invertX); try c.encode(invertY, forKey: .invertY)
        try c.encode(isLive, forKey: .isLive); try c.encode(blendWeight, forKey: .blendWeight)
        try c.encode(cameraPosition, forKey: .cameraPosition); try c.encode(probeStart, forKey: .probeStart)
        try c.encode(probeEnd, forKey: .probeEnd); try c.encode(probeHit, forKey: .probeHit)
    }
}

/// A camera position, rotation and field of view (radians; nil: keep the camera's).
public struct CameraPose: Equatable, Sendable {
    public var position: Vec3
    public var rotation: Quat
    public var fovY: Float?

    public init(position: Vec3, rotation: Quat, fovY: Float? = nil) {
        self.position = position
        self.rotation = rotation
        self.fovY = fovY
    }

    /// The direction it looks in (its -Z).
    public var forward: Vec3 { rotation * Vec3(0, 0, -1) }

    /// `a` toward `b` by `t` (position lerped, rotation slerped, field of view lerped when both have one).
    public static func blend(_ a: CameraPose, _ b: CameraPose, _ t: Float) -> CameraPose {
        let fov: Float? = switch (a.fovY, b.fovY) {
        case let (x?, y?): x + (y - x) * t
        case let (nil, y?): y
        case let (x?, nil): x
        default: nil
        }
        return CameraPose(position: a.position + (b.position - a.position) * t, rotation: Quat.slerp(a.rotation, b.rotation, t).normalized, fovY: fov)
    }
}

/// What a rig keeps between frames.
struct CameraRigRuntime: Equatable, Sendable {
    var started = false
    /// Degrees: current (damped) and wanted heading and pitch.
    var yaw: Float = 0
    var pitch: Float = 0
    var wantedYaw: Float = 0
    var wantedPitch: Float = 0
    /// Current zoom distance.
    var distance: Float = 0
    /// The damped followed point.
    var pivot: Vec3 = .zero
    var lastTarget: Vec3 = .zero
    /// The target's smoothed velocity.
    var velocity: Vec3 = .zero
    /// Seconds since the last orbit input.
    var idleTime: Float = 0
    /// The recenter action was pressed: swinging back.
    var recentering = false
    /// How far collision pulled the camera in toward the followed point.
    var pull: Float = 0
    var bobPhase: Float = 0
    /// Side scroller: the dead zone's center and the current look-ahead (meters along the view's right).
    var focus: Vec3 = .zero
    var lookAhead: Float = 0
    /// Fixed rigs on their own output camera: the pose it was placed at.
    var fixedPose: CameraPose?
    /// The pose this frame.
    var pose: CameraPose?
    /// The collision probe: hit point this frame (nil: clear).
    var probeHitPoint: Vec3?
}
