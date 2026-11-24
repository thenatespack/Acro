#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EngineRendering
import EngineScene

// Visual script nodes for camera rigs (CameraRig.swift): switch the live rig (with a blend), point
// a rig at another target and read which rig is live.

@MainActor
enum VisualScriptCameraNodes {
    static func register() {
        VisualScriptNodes.addProvider("engine.cameraRigs") {
            for definition in definitions() { VisualScriptNodes.register(definition) }
        }
    }

    static func definitions() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let rigPin = VisualScriptPin("rig", .entity, doc: "Unconnected: this entity (or the first child that has a CameraRig)")
        return [
            S.action("cameraRig.activate", "Activate Camera Rig", "Camera",
                     "Makes `rig` the live camera rig: enables it and raises its priority above the other rigs', so the camera blends to it over `blendTime` seconds (negative: the rig's own blendTime; 0 cuts).",
                     [rigPin, VisualScriptPin("blendTime", .float, default: .float(-1))]) { c in
                let rig = try c.entity("rig", with: CameraRig.self)
                let time = try c.float("blendTime")
                c.world.activateCameraRig(rig, blendTime: time < 0 ? nil : time)
                return .next
            },
            S.action("cameraRig.setTarget", "Set Camera Rig Target", "Camera",
                     "Points `rig` at `target` (what it follows: a character, a vehicle). Unconnected target: this entity.",
                     [rigPin, VisualScriptPin("target", .entity, doc: "Unconnected: this entity")]) { c in
                let rig = try c.entity("rig", with: CameraRig.self)
                let target = try c.liveEntity("target")
                let ref = c.world.ref(to: target)
                c.world.modify(CameraRig.self, for: rig) { $0.target = ref }
                return .next
            },
            S.action("cameraRig.setMode", "Set Camera Rig Mode", "Camera",
                     "Changes `rig`'s mode: thirdPerson, firstPerson, topDown, sideScroller or fixed. The rig starts over from the target (no blend; use two rigs and Activate Camera Rig for a blend).",
                     [rigPin, VisualScriptPin("mode", .string, default: .string("thirdPerson"))]) { c in
                let rig = try c.entity("rig", with: CameraRig.self)
                let name = try c.string("mode")
                guard let mode = CameraRigMode(rawValue: name) else {
                    throw VisualScriptError("unknown camera rig mode '\(name)' (\(CameraRigMode.allCases.map(\.rawValue).joined(separator: ", ")))")
                }
                c.world.modify(CameraRig.self, for: rig) {
                    if $0.mode != mode {
                        $0.mode = mode
                        $0.restart()
                    }
                }
                return .next
            },
            S.pure("cameraRig.live", "Live Camera Rig", "Camera",
                   "The camera rig driving the camera now, its mode, and whether a blend to it is still running (`weight` 0 to 1).",
                   [],
                   [VisualScriptPin("rig", .entity), VisualScriptPin("mode", .string), VisualScriptPin("blending", .bool),
                    VisualScriptPin("weight", .float)]) { c in
                let live = c.world.liveCameraRig
                let rig = live.flatMap { c.world.get(CameraRig.self, for: $0) }
                c.set("rig", .entity(live ?? .invalid))
                c.set("mode", .string(rig?.mode.rawValue ?? ""))
                c.set("blending", .bool(c.world.cameraRigs?.isBlending ?? false))
                c.set("weight", .float(Double(c.world.cameraRigs?.blendWeight ?? (live == nil ? 0 : 1))))
            },
        ]
    }
}
