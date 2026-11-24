#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// The stock animation clips of the character templates, generated in code for a `CharacterRig`
/// so they always fit its skeleton and proportions (the stride follows the legs, the jump the
/// height). Channel targets are bone indices (`CharacterRig.bones`), which is also the order of
/// the character's `Animator.targets`.
///
/// Rotations are keyed on every animated bone; the root bone (bone 0) also gets a translation
/// channel (bob, jump, fall), and the blob squashes with scale. Events: `footstep` (walk, run),
/// `takeoff` and `land` (jump), `hit` (attack), `down` (die).
public enum CharacterClips {
    /// Every stock clip, in order.
    public static let stockNames = ["idle", "walk", "run", "jump", "attack", "die"]

    /// Whether the clip repeats (idle, walk, run); the others play once and hold their last pose.
    public static func loops(_ name: String) -> Bool { ["idle", "walk", "run"].contains(name) }

    /// Seconds per cycle (loops) or for the whole move.
    public static func duration(_ name: String, template: CharacterTemplate) -> Float {
        switch (name, template) {
        case ("idle", _): 2.4
        case ("walk", .blob): 0.7
        case ("walk", .bird): 0.8
        case ("walk", _): 1.0
        case ("run", .quadruped): 0.5
        case ("run", .blob): 0.45
        case ("run", .bird): 0.45
        case ("run", _): 0.64
        case ("jump", _): 1.0
        case ("attack", .bird), ("attack", .blob): 0.6
        case ("attack", _): 0.7
        case ("die", _): 1.2
        default: 1
        }
    }

    /// A pose at one moment: Euler degrees per bone (applied Z, then X, then Y), the root bone's
    /// offset from rest (template meters, scaled by the height) and scales per bone.
    struct Pose {
        var rotations: [String: Vec3] = [:]
        var move = Vec3.zero
        var scales: [String: Vec3] = [:]
    }

    /// The clip `name` (a stock name) for `rig`, nil for an unknown name.
    public static func clip(_ name: String, rig: CharacterRig) -> AnimationClip? {
        guard stockNames.contains(name) else { return nil }
        let template = rig.template
        let duration = duration(name, template: template)
        let looping = loops(name)
        let samples = looping ? 24 : 30
        let ts = (0...samples).map { Float($0) / Float(samples) }
        let poses = ts.map { t -> Pose in
            switch template {
            case .humanoid: humanoid(name, t, rig)
            case .quadruped: quadruped(name, t, rig)
            case .bird: bird(name, t, rig)
            case .blob: blob(name, t, rig)
            }
        }
        let times = ts.map { $0 * duration }
        let scale = rig.proportions.height
        var channels: [AnimationChannel] = []
        for (index, bone) in rig.bones.enumerated() {
            if index == 0 {
                let values = poses.flatMap { pose -> [Float] in
                    let p = bone.offset + pose.move * scale
                    return [p.x, p.y, p.z]
                }
                channels.append(AnimationChannel(target: index, path: .translation, sampler: AnimationSampler(times: times, values: values)))
            }
            if poses.contains(where: { $0.rotations[bone.name] != nil }) {
                var values: [Float] = []
                var previous: Quat?
                for pose in poses {
                    var q = rotation(pose.rotations[bone.name] ?? .zero)
                    // Keep neighbouring keys in one hemisphere so slerp takes the short way.
                    if let p = previous, (p.vector * q.vector).sum() < 0 { q = Quat(vector: -q.vector) }
                    previous = q
                    values += [q.x, q.y, q.z, q.w]
                }
                channels.append(AnimationChannel(target: index, path: .rotation, sampler: AnimationSampler(times: times, values: values)))
            }
            if poses.contains(where: { $0.scales[bone.name] != nil }) {
                let values = poses.flatMap { pose -> [Float] in
                    let s = pose.scales[bone.name] ?? Vec3(1, 1, 1)
                    return [s.x, s.y, s.z]
                }
                channels.append(AnimationChannel(target: index, path: .scale, sampler: AnimationSampler(times: times, values: values)))
            }
        }
        return AnimationClip(name: name, channels: channels, duration: duration, events: events(name, duration: duration))
    }

    /// Every clip in `names` that is a stock clip, in stock order.
    public static func clips(_ names: [String] = stockNames, rig: CharacterRig) -> [AnimationClip] {
        stockNames.filter { names.contains($0) }.compactMap { clip($0, rig: rig) }
    }

    public static func events(_ name: String, duration d: Float) -> [AnimationEvent] {
        switch name {
        case "walk", "run": [AnimationEvent(time: 0.25 * d, name: "footstep"), AnimationEvent(time: 0.75 * d, name: "footstep")]
        case "jump": [AnimationEvent(time: 0.28 * d, name: "takeoff"), AnimationEvent(time: 0.78 * d, name: "land")]
        case "attack": [AnimationEvent(time: 0.45 * d, name: "hit")]
        case "die": [AnimationEvent(time: 0.75 * d, name: "down")]
        default: []
        }
    }

    /// Euler degrees as a rotation: about Z, then X, then Y (parent space).
    static func rotation(_ degrees: Vec3) -> Quat {
        let r = degrees * (.pi / 180)
        var q = Quat.identity
        if r.z != 0 { q = Quat(angle: r.z, axis: Vec3(0, 0, 1)) }
        if r.x != 0 { q = Quat(angle: r.x, axis: Vec3(1, 0, 0)) * q }
        if r.y != 0 { q = Quat(angle: r.y, axis: Vec3(0, 1, 0)) * q }
        return q.normalized
    }

    /// Smoothly interpolated keys (time, value), times ascending in 0...1.
    static func curve(_ t: Float, _ keys: [(Float, Float)]) -> Float {
        guard let first = keys.first else { return 0 }
        if t <= first.0 { return first.1 }
        for i in 1..<keys.count where t <= keys[i].0 {
            let a = keys[i - 1], b = keys[i]
            let u = b.0 > a.0 ? (t - a.0) / (b.0 - a.0) : 1
            return a.1 + (b.1 - a.1) * u * u * (3 - 2 * u)
        }
        return keys[keys.count - 1].1
    }

    /// A 0→1→0 arc between `start` and `end` (0 outside).
    static func arc(_ t: Float, _ start: Float, _ end: Float) -> Float {
        guard t > start, t < end else { return 0 }
        return sinf(.pi * (t - start) / (end - start))
    }

    /// Conventions: for a bone hanging down, forward swing is negative X; for a bone pointing up,
    /// positive X leans it forward. On the character's left (+X), positive Z raises an arm
    /// sideways; on the right, negative Z.

    // MARK: Humanoid

    static func humanoid(_ name: String, _ t: Float, _ rig: CharacterRig) -> Pose {
        var p = Pose()
        let c = 2 * Float.pi * t
        let s = sinf(c), co = cosf(c)
        func arms(out: Float, swing: Float, elbow: Float) {
            p.rotations["upperArm.L"] = Vec3(swing, 0, out)
            p.rotations["upperArm.R"] = Vec3(-swing, 0, -out)
            p.rotations["lowerArm.L"] = Vec3(-elbow, 0, 0)
            p.rotations["lowerArm.R"] = Vec3(-elbow, 0, 0)
        }
        switch name {
        case "idle":
            p.rotations["spine"] = Vec3(1.5 * s, 0, 0)
            p.rotations["chest"] = Vec3(1.5 * s, 0, 0)
            p.rotations["head"] = Vec3(-1.5 * s, 6 * sinf(c + 0.8), 0)
            arms(out: 5 + 2 * s, swing: 2 * s, elbow: 8)
            p.move = Vec3(0, 0.006 * s, 0)
        case "walk", "run":
            let run = name == "run"
            let leg: Float = run ? 45 : 28, knee: Float = run ? 75 : 40, arm: Float = run ? 40 : 20
            p.rotations["upperLeg.L"] = Vec3(-leg * s, 0, 0)
            p.rotations["upperLeg.R"] = Vec3(leg * s, 0, 0)
            p.rotations["lowerLeg.L"] = Vec3((run ? 20 : 6) + knee * max(0, co), 0, 0)
            p.rotations["lowerLeg.R"] = Vec3((run ? 20 : 6) + knee * max(0, -co), 0, 0)
            p.rotations["foot.L"] = Vec3(-12 * max(0, -co) + 8 * max(0, co), 0, 0)
            p.rotations["foot.R"] = Vec3(-12 * max(0, co) + 8 * max(0, -co), 0, 0)
            p.rotations["upperArm.L"] = Vec3(arm * s, 0, 5)
            p.rotations["upperArm.R"] = Vec3(-arm * s, 0, -5)
            p.rotations["lowerArm.L"] = Vec3(-(run ? 80 : 15) - 10 * max(0, -s), 0, 0)
            p.rotations["lowerArm.R"] = Vec3(-(run ? 80 : 15) - 10 * max(0, s), 0, 0)
            p.rotations["spine"] = Vec3(run ? 12 : 3, 4 * s, 0)
            p.rotations["chest"] = Vec3(0, -7 * s, 0)
            p.rotations["head"] = Vec3(run ? -8 : -2, 3 * s, 0)
            p.move = Vec3(0, (run ? 0.045 : 0.02) * cosf(2 * c) - (run ? 0.03 : 0.01), 0)
        case "jump":
            let crouch = curve(t, [(0, 0), (0.18, 1), (0.3, 0), (0.7, 0), (0.82, 0.8), (1, 0)])
            let air = arc(t, 0.28, 0.78)
            p.move = Vec3(0, -0.18 * crouch + 0.45 * air, 0)
            for side in ["L", "R"] {
                p.rotations["upperLeg.\(side)"] = Vec3(-50 * crouch - 30 * air, 0, 0)
                p.rotations["lowerLeg.\(side)"] = Vec3(95 * crouch + 55 * air, 0, 0)
                p.rotations["foot.\(side)"] = Vec3(-45 * crouch + 20 * air, 0, 0)
            }
            p.rotations["spine"] = Vec3(25 * crouch - 6 * air, 0, 0)
            p.rotations["head"] = Vec3(-12 * crouch, 0, 0)
            arms(out: 6 + 14 * air, swing: 35 * crouch - 120 * air, elbow: 20)
        case "attack":
            let env = curve(t, [(0, 0), (0.2, 1), (0.8, 1), (1, 0)])
            let swing = curve(t, [(0, 0), (0.3, 150), (0.5, -20), (0.75, -20), (1, 0)])
            p.rotations["upperArm.R"] = Vec3(-swing, 0, -6)
            p.rotations["lowerArm.R"] = Vec3(-curve(t, [(0, 10), (0.3, 60), (0.5, 5), (1, 10)]), 0, 0)
            p.rotations["upperArm.L"] = Vec3(-35 * env, 0, 10 * env)
            p.rotations["lowerArm.L"] = Vec3(-70 * env, 0, 0)
            p.rotations["spine"] = Vec3(curve(t, [(0, 0), (0.3, -8), (0.5, 15), (0.75, 10), (1, 0)]),
                                        curve(t, [(0, 0), (0.3, -25), (0.5, 20), (1, 0)]), 0)
            p.rotations["upperLeg.L"] = Vec3(-18 * env, 0, 0)
            p.rotations["upperLeg.R"] = Vec3(14 * env, 0, 0)
            p.rotations["lowerLeg.L"] = Vec3(22 * env, 0, 0)
            p.rotations["lowerLeg.R"] = Vec3(10 * env, 0, 0)
            p.move = Vec3(0, -0.05 * env, 0)
        case "die":
            let buckle = curve(t, [(0, 0), (0.25, 1), (0.6, 0.6), (1, 0.3)])
            let fall = curve(t, [(0, 0), (0.2, 0), (0.72, 1), (0.82, 0.93), (1, 1)])
            let restY = rig.bones[0].position.y / max(rig.proportions.height, 0.01)
            p.rotations["hips"] = Vec3(-85 * fall, 0, 0)
            p.move = Vec3(0, (0.14 - restY) * fall - 0.15 * buckle * (1 - fall), -0.25 * fall)
            for side in ["L", "R"] {
                p.rotations["upperLeg.\(side)"] = Vec3(-40 * buckle, 0, 0)
                p.rotations["lowerLeg.\(side)"] = Vec3(60 * buckle, 0, 0)
            }
            arms(out: 10 + 65 * fall, swing: -20 * buckle, elbow: 25)
            p.rotations["spine"] = Vec3(15 * buckle * (1 - fall) - 5 * fall, 0, 0)
            p.rotations["head"] = Vec3(-10 * buckle + 15 * fall, 25 * fall, 0)
        default: break
        }
        return p
    }

    // MARK: Quadruped

    static func quadruped(_ name: String, _ t: Float, _ rig: CharacterRig) -> Pose {
        var p = Pose()
        let c = 2 * Float.pi * t
        let s = sinf(c)
        func leg(_ prefix: String, _ side: String, phase: Float, swing: Float, knee: Float) {
            let a = c + phase
            p.rotations["\(prefix)Upper.\(side)"] = Vec3(-swing * sinf(a), 0, 0)
            p.rotations["\(prefix)Lower.\(side)"] = Vec3(knee * max(0, cosf(a)), 0, 0)
        }
        switch name {
        case "idle":
            p.rotations["tail"] = Vec3(-10, 15 * s, 0)
            p.rotations["tailTip"] = Vec3(0, 20 * sinf(c - 0.6), 0)
            p.rotations["neck"] = Vec3(3 * s, 0, 0)
            p.rotations["head"] = Vec3(-3 * s, 10 * sinf(c + 1), 0)
            p.rotations["spine"] = Vec3(1 * s, 0, 0)
            p.move = Vec3(0, 0.004 * s, 0)
        case "walk":
            leg("front", "L", phase: 0, swing: 22, knee: 35)
            leg("back", "R", phase: 0, swing: 22, knee: 35)
            leg("front", "R", phase: .pi, swing: 22, knee: 35)
            leg("back", "L", phase: .pi, swing: 22, knee: 35)
            p.rotations["neck"] = Vec3(4 * cosf(2 * c), 0, 0)
            p.rotations["tail"] = Vec3(-15, 8 * s, 0)
            p.rotations["spine"] = Vec3(0, 3 * s, 0)
            p.move = Vec3(0, 0.012 * cosf(2 * c), 0)
        case "run":
            leg("front", "L", phase: 0, swing: 42, knee: 60)
            leg("front", "R", phase: 0.5, swing: 42, knee: 60)
            leg("back", "L", phase: .pi, swing: 40, knee: 55)
            leg("back", "R", phase: .pi + 0.5, swing: 40, knee: 55)
            p.rotations["spine"] = Vec3(8 * s, 0, 0)
            p.rotations["chest"] = Vec3(-6 * s, 0, 0)
            p.rotations["neck"] = Vec3(10 - 6 * s, 0, 0)
            p.rotations["tail"] = Vec3(-30 + 10 * s, 0, 0)
            p.move = Vec3(0, 0.05 * abs(sinf(c + 0.8)) - 0.02, 0)
        case "jump":
            let crouch = curve(t, [(0, 0), (0.18, 1), (0.3, 0), (0.7, 0), (0.82, 0.8), (1, 0)])
            let air = arc(t, 0.28, 0.78)
            p.move = Vec3(0, -0.1 * crouch + 0.4 * air, 0)
            p.rotations["hips"] = Vec3(curve(t, [(0, 0), (0.25, -15), (0.5, 0), (0.7, 12), (0.85, 0), (1, 0)]), 0, 0)
            for side in ["L", "R"] {
                p.rotations["frontUpper.\(side)"] = Vec3(-30 * crouch - 40 * air, 0, 0)
                p.rotations["frontLower.\(side)"] = Vec3(50 * crouch + 70 * air, 0, 0)
                p.rotations["backUpper.\(side)"] = Vec3(35 * crouch + 35 * air, 0, 0)
                p.rotations["backLower.\(side)"] = Vec3(-40 * crouch - 40 * air, 0, 0)
            }
            p.rotations["tail"] = Vec3(-30 * air, 0, 0)
        case "attack":
            p.rotations["neck"] = Vec3(curve(t, [(0, 0), (0.3, -25), (0.5, 35), (0.7, 30), (1, 0)]), 0, 0)
            p.rotations["head"] = Vec3(curve(t, [(0, 0), (0.3, -15), (0.5, 20), (1, 0)]), 0, 0)
            p.move = Vec3(0, 0, curve(t, [(0, 0), (0.3, -0.06), (0.5, 0.15), (0.7, 0.12), (1, 0)]))
            let reach = curve(t, [(0, 0), (0.3, 20), (0.5, -15), (1, 0)])
            p.rotations["frontUpper.L"] = Vec3(-reach, 0, 0)
            p.rotations["frontUpper.R"] = Vec3(-reach, 0, 0)
            p.rotations["tail"] = Vec3(-20 * curve(t, [(0, 0), (0.3, 1), (0.8, 1), (1, 0)]), 0, 0)
        case "die":
            let fall = curve(t, [(0, 0), (0.25, 0.05), (0.72, 1), (0.82, 0.93), (1, 1)])
            let restY = rig.bones[0].position.y / max(rig.proportions.height, 0.01)
            p.rotations["hips"] = Vec3(0, 0, 85 * fall)
            p.move = Vec3(0, (0.17 - restY) * fall, 0)
            p.rotations["neck"] = Vec3(35 * fall, 0, 0)
            p.rotations["head"] = Vec3(15 * fall, 0, 0)
            p.rotations["tail"] = Vec3(20 * fall, 0, 0)
            for side in ["L", "R"] {
                p.rotations["frontUpper.\(side)"] = Vec3(-15 * fall, 0, 0)
                p.rotations["backUpper.\(side)"] = Vec3(15 * fall, 0, 0)
            }
        default: break
        }
        return p
    }

    // MARK: Bird

    static func bird(_ name: String, _ t: Float, _ rig: CharacterRig) -> Pose {
        var p = Pose()
        let c = 2 * Float.pi * t
        let s = sinf(c), co = cosf(c)
        /// Folds the wings back by `fold` (0 spread, 1 tucked) and raises them by `flap` degrees.
        func wings(fold: Float, flap: Float) {
            p.rotations["wing.L"] = Vec3(0, 80 * fold, flap - 10 * fold)
            p.rotations["wing.R"] = Vec3(0, -80 * fold, -flap + 10 * fold)
            p.rotations["wingTip.L"] = Vec3(0, 15 * fold, flap * 0.4)
            p.rotations["wingTip.R"] = Vec3(0, -15 * fold, -flap * 0.4)
        }
        func legs(swing: Float, knee: Float) {
            p.rotations["leg.L"] = Vec3(-swing * s, 0, 0)
            p.rotations["leg.R"] = Vec3(swing * s, 0, 0)
            p.rotations["shin.L"] = Vec3(knee * max(0, co), 0, 0)
            p.rotations["shin.R"] = Vec3(knee * max(0, -co), 0, 0)
        }
        switch name {
        case "idle":
            wings(fold: 1, flap: 2 * max(0, sinf(3 * c)))
            p.rotations["neck"] = Vec3(4 * s, 0, 0)
            p.rotations["head"] = Vec3(0, curve(t, [(0, 0), (0.2, 0), (0.3, 35), (0.55, 35), (0.65, -25), (0.85, -25), (1, 0)]), 0)
            p.rotations["tail"] = Vec3(6 * sinf(2 * c), 0, 0)
            p.move = Vec3(0, 0.004 * s, 0)
        case "walk":
            wings(fold: 1, flap: 0)
            legs(swing: 28, knee: 35)
            p.rotations["neck"] = Vec3(12 * sinf(2 * c), 0, 0)
            p.rotations["body"] = Vec3(0, 0, 4 * s)
            p.rotations["tail"] = Vec3(0, 6 * s, 0)
            p.move = Vec3(0, 0.01 * cosf(2 * c), 0)
        case "run":
            wings(fold: 0.45, flap: 15 + 12 * sinf(2 * c))
            legs(swing: 42, knee: 55)
            p.rotations["body"] = Vec3(14, 0, 3 * s)
            p.rotations["neck"] = Vec3(-12 + 6 * sinf(2 * c), 0, 0)
            p.move = Vec3(0, 0.02 * cosf(2 * c), 0)
        case "jump":
            let crouch = curve(t, [(0, 0), (0.18, 1), (0.3, 0), (0.7, 0), (0.82, 0.7), (1, 0)])
            let air = arc(t, 0.28, 0.78)
            let open = curve(t, [(0, 0), (0.15, 0.6), (0.3, 1), (0.75, 1), (0.9, 0.3), (1, 0)])
            wings(fold: 1 - open, flap: open * 50 * sinf(2 * .pi * 3 * t))
            p.move = Vec3(0, -0.06 * crouch + 0.5 * air, 0)
            for side in ["L", "R"] {
                p.rotations["leg.\(side)"] = Vec3(-40 * crouch - 30 * air, 0, 0)
                p.rotations["shin.\(side)"] = Vec3(70 * crouch + 60 * air, 0, 0)
            }
            p.rotations["tail"] = Vec3(-20 * air, 0, 0)
        case "attack":
            let open = curve(t, [(0, 0), (0.3, 1), (0.7, 1), (1, 0)])
            wings(fold: 1 - open, flap: open * (20 + 20 * sinf(2 * .pi * 2 * t)))
            p.rotations["neck"] = Vec3(curve(t, [(0, 0), (0.3, -20), (0.45, 50), (0.6, 45), (1, 0)]), 0, 0)
            p.rotations["head"] = Vec3(curve(t, [(0, 0), (0.3, -10), (0.45, 25), (1, 0)]), 0, 0)
            p.rotations["body"] = Vec3(curve(t, [(0, 0), (0.3, -10), (0.45, 15), (1, 0)]), 0, 0)
        case "die":
            let fall = curve(t, [(0, 0), (0.25, 0.05), (0.72, 1), (0.82, 0.93), (1, 1)])
            let restY = rig.bones[0].position.y / max(rig.proportions.height, 0.01)
            wings(fold: 1 - 0.6 * fall, flap: -10 * fall)
            p.rotations["body"] = Vec3(0, 0, -88 * fall)
            p.move = Vec3(0, (0.12 - restY) * fall, 0)
            p.rotations["neck"] = Vec3(45 * fall, 0, 0)
            for side in ["L", "R"] { p.rotations["leg.\(side)"] = Vec3(-30 * fall, 0, 0) }
        default: break
        }
        return p
    }

    // MARK: Blob

    static func blob(_ name: String, _ t: Float, _ rig: CharacterRig) -> Pose {
        var p = Pose()
        let c = 2 * Float.pi * t
        let s = sinf(c)
        func squash(_ amount: Float) {
            // Keeps the volume about the same: wider as it gets shorter.
            p.scales["body"] = Vec3(1 + amount * 0.6, 1 - amount, 1 + amount * 0.6)
        }
        func arms(_ raise: Float, forward: Float = 0) {
            p.rotations["arm.L"] = Vec3(0, -forward, raise)
            p.rotations["arm.R"] = Vec3(0, forward, -raise)
        }
        switch name {
        case "idle":
            squash(0.04 * s)
            p.rotations["top"] = Vec3(0, 0, 3 * sinf(c + 0.5))
            arms(10 * s)
        case "walk", "run":
            let run = name == "run"
            let hop: Float = run ? 0.18 : 0.12
            p.move = Vec3(0, hop * sinf(.pi * t), 0)
            squash(curve(t, [(0, 0.22), (0.12, 0), (0.5, -0.1), (0.88, 0), (1, 0.22)]) * (run ? 1.2 : 1))
            p.rotations["body"] = Vec3(run ? 12 : 4, 0, 0)
            p.rotations["top"] = Vec3(curve(t, [(0, 6), (0.5, -4), (1, 6)]), 0, 0)
            arms(run ? -20 : 25 * sinf(.pi * t), forward: run ? -30 : 0)
        case "jump":
            let sq = curve(t, [(0, 0), (0.2, 0.4), (0.3, -0.25), (0.5, -0.1), (0.75, 0), (0.82, 0.35), (1, 0)])
            squash(sq)
            p.move = Vec3(0, 0.6 * arc(t, 0.28, 0.78), 0)
            arms(curve(t, [(0, 0), (0.2, -20), (0.3, 60), (0.75, 40), (0.85, -10), (1, 0)]))
        case "attack":
            let a = curve(t, [(0, 0), (0.3, -0.3), (0.5, 1), (0.7, 0.8), (1, 0)])
            p.move = Vec3(0, 0, 0.2 * max(a, 0) - 0.05 * max(-a, 0))
            p.scales["body"] = Vec3(1 + 0.1 * max(-a, 0), 1 - 0.15 * a, 1 + 0.35 * max(a, 0))
            p.rotations["top"] = Vec3(20 * max(a, 0), 0, 0)
            arms(10, forward: 60 * max(a, 0))
        case "die":
            let f = curve(t, [(0, 0), (0.3, -0.15), (0.75, 1), (0.85, 0.9), (1, 1)])
            p.scales["body"] = Vec3(1 + 0.5 * f, max(1 - 0.82 * f, 0.1), 1 + 0.5 * f)
            p.rotations["top"] = Vec3(25 * max(f, 0), 0, 0)
            arms(-30 * max(f, 0))
        default: break
        }
        return p
    }
}
