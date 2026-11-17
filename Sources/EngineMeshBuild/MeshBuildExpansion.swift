import Foundation
import EngineCore
import EngineScene
import EngineAssets

// Mirror and repeat: compact ways to write symmetric and repeated models. A part with `mirror`
// or `repeat` stands for several parts; `MeshBuild.expansion()` writes them all out (a pure step
// the importer, the editor and the checks share), so the file keeps the short form.
//
// ```json
// {"name": "Left Arm", "shape": "capsule", "parent": "Body", "position": [-0.5, 0.2, 0], "rotation": [0, 0, 20], "mirror": "x"},
// {"name": "Leg", "shape": "cylinder", "position": [0.4, -0.5, 0.4], "mirror": ["x", "z"]},
// {"name": "Post", "position": [-2, 0.5, 0], "repeat": {"count": 5, "offset": [1, 0, 0]}},
// {"name": "Spoke", "parent": "Wheel", "position": [0.3, 0, 0], "rotation": [0, 0, 90], "repeat": {"count": 8, "radial": {"axis": "y"}}}
// ```
//
// - `mirror` ("x", or several axes ["x", "z"]): a reflected copy of the part and its whole subtree
//   across the parent's plane through its origin (x = 0 for "x"). Several axes make every
//   combination ("x" and "z": 3 copies). The copy is a true mirror image: its transform is a
//   proper rotation (position negated on the axis, the other two Euler angles negated) and its
//   mesh is reflected on that axis (flipped winding and normals), so asymmetric shapes come
//   out right.
// - `repeat` ({count, offset, radial: {axis, radius, angle}}): `count` parts in all (the original
//   is the first). `offset` steps each copy along a line (parent space). `radial` turns copies
//   about the parent's `axis` through its origin, `angle` degrees in all (360, the default, is a
//   full ring of evenly spaced copies; less spreads them from 0 to `angle`, both ends included);
//   with `radius` the ring is centered on the part's own position instead, each copy `radius`
//   out (the first along +x, or +y when the axis is x). Copies turn with the ring. Both together
//   make a spiral.
// - Repeat comes first, then mirror: a repeated row with `mirror` gets a mirrored row.
// - Names: repeat copies are "<name> 2", "<name> 3"…; a mirror copy swaps a side word of the
//   mirror axis (x: Left↔Right, left↔right, L↔R; y: Top↔Bottom, Upper↔Lower; z: Front↔Back,
//   any case as written, whole words only: "Left Arm" → "Right Arm", "Arm.L" → "Arm.R"), and
//   when the name has none, gets " (mirror x)" (" (mirror xz)" for two axes). Descendants are
//   renamed the same way and hang from their parent's copy. Animations, `partColors` and
//   tracks can name copies.
// - Animation tracks of a part also play on its copies, mirrored (position offsets reflected,
//   rotations turned the other way) or turned with a ring.

/// A mesh build with every `mirror` and `repeat` written out (`MeshBuild.expansion()`).
public struct MeshBuildExpansion: Equatable, Sendable {
    /// The file's parts first (in file order, under their own names), then the copies; no part
    /// has `mirror` or `repeat`. Animations gain tracks for the copies.
    public var build: MeshBuild
    /// For each part of `build`, the name of the file part it comes from (itself for the file's own parts).
    public var sources: [String]
    /// Copies whose names clash with another part, repeat counts out of range, a model too big.
    public var warnings: [String]

    /// The file part `name` (a part of `build`) comes from; nil if there is no such part.
    public func source(of name: String) -> String? {
        build.parts.firstIndex { $0.name == name }.map { sources[$0] }
    }

    /// The names of the copies (parts not in the file), in order.
    public var copies: [String] {
        zip(build.parts, sources).filter { $0.0.name != $0.1 }.map(\.0.name)
    }
}

extension MeshBuild {
    /// A name not used by any part (or mirror / repeat copy): `base`, else "`base` 2", "`base` 3"…
    public func uniquePartName(_ base: String) -> String {
        let names = Set(parts.map(\.name) + (hasCopies ? expanded().parts.map(\.name) : []))
        guard names.contains(base) else { return base }
        var n = 2
        while names.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

    /// At most this many parts are made by mirror and repeat (the rest are left out, with a warning).
    public static let maxCopies = 4096

    /// Whether any part has `mirror` or `repeat`.
    public var hasCopies: Bool { parts.contains { $0.mirror != nil || $0.repetition != nil } }

    /// Every `mirror` / `repeat` written out as parts (see the notes at the top of
    /// MeshBuildExpansion.swift). Without any it is `self`.
    public func expanded() -> MeshBuild { expansion().build }

    /// The parts `expanded()` gives with their sources and warnings.
    public func expansion() -> MeshBuildExpansion {
        guard hasCopies else { return MeshBuildExpansion(build: self, sources: parts.map(\.name), warnings: []) }
        var expander = MeshBuildExpander(build: self)
        return expander.run()
    }
}

/// One part made by expansion, with how its source's animation tracks map onto it.
private struct MeshBuildInstance {
    var part: MeshBuildPart
    var source: Int
    var isOriginal: Bool
    /// Position track values become `trackSign * (trackTurn * value)`; rotation values are
    /// multiplied by `MeshBuildExpander.eulerFactors(trackSign)`.
    var trackTurn = Quat.identity
    var trackSign = Vec3(1, 1, 1)

    /// Mirrored by the sign matrix `d` (D·T·D for its transform, D for its mesh).
    mutating func reflect(_ d: Vec3) {
        guard d != Vec3(1, 1, 1) else { return }
        part.position = MeshBuildExpander.tidy(part.position * d, 1e5)
        part.rotation = MeshBuildExpander.tidy(part.rotation * MeshBuildExpander.eulerFactors(d), 1e4)
        part.reflection *= d
        trackSign *= d
    }
}

private struct MeshBuildExpander {
    let build: MeshBuild
    var children: [Int: [Int]] = [:]
    var roots: [Int] = []
    var warnings: [String] = []
    var copiesMade = 0
    var truncated = false

    init(build: MeshBuild) {
        self.build = build
        // The same tree the importer builds: missing parents and loops hang from the root.
        let parts = build.parts
        var firstIndex: [String: Int] = [:]
        for (i, part) in parts.enumerated() where firstIndex[part.name] == nil { firstIndex[part.name] = i }
        for i in parts.indices {
            var parent: Int?
            if !parts[i].parent.isEmpty, let p = firstIndex[parts[i].parent], p != i {
                var seen: Set<Int> = [i], up: Int? = p, loops = false
                while let u = up {
                    if !seen.insert(u).inserted { loops = true; break }
                    let name = parts[u].parent
                    up = name.isEmpty ? nil : firstIndex[name]
                }
                parent = loops ? nil : p
            }
            if let parent { children[parent, default: []].append(i) } else { roots.append(i) }
        }
    }

    mutating func run() -> MeshBuildExpansion {
        for (i, part) in build.parts.enumerated() {
            if let r = part.repetition, r.count < 1 || r.count > MeshBuildRepeat.maxCount {
                warnings.append("part '\(build.parts[i].name)': repeat count \(r.count) is outside 1...\(MeshBuildRepeat.maxCount)")
            }
        }
        let all = roots.flatMap { subtree($0) }
        let originals = all.filter(\.isOriginal).sorted { $0.source < $1.source }
        let copies = all.filter { !$0.isOriginal }
        if truncated { warnings.append("mirror and repeat make more than \(MeshBuild.maxCopies) parts; the rest are left out") }

        var out = MeshBuild(parts: originals.map(\.part) + copies.map(\.part), animations: build.animations)
        var seen = Set(originals.map(\.part.name))
        for copy in copies where !seen.insert(copy.part.name).inserted {
            warnings.append("part '\(build.parts[copy.source].name)' makes a copy named '\(copy.part.name)', a name another part "
                            + "already has; parenting, animations and part colors use the first")
        }
        // Copies play their source's tracks, mirrored or turned like the copy.
        for a in out.animations.indices {
            let tracks = build.animations[a].allTracks
            for copy in copies {
                let source = build.parts[copy.source].name
                for track in tracks where track.part == source {
                    out.animations[a].tracks.append(Self.mapped(track, onto: copy))
                }
            }
        }
        return MeshBuildExpansion(build: out, sources: (originals + copies).map { build.parts[$0.source].name }, warnings: warnings)
    }

    /// The part `i` and everything below it, copies included, in the frame of its parent.
    private mutating func subtree(_ i: Int) -> [MeshBuildInstance] {
        var source = build.parts[i]
        source.mirror = nil
        source.repetition = nil
        let below = (children[i] ?? []).flatMap { subtree($0) }
        let repetition = build.parts[i].repetition
        let count = min(max(repetition?.count ?? 1, 1), MeshBuildRepeat.maxCount)
        let mirrorAxes = build.parts[i].mirror?.axes ?? []
        // Every combination of the mirror axes (none first), as x/y/z bit masks.
        let masks = (0..<8).filter { mask in MeshBuildAxis.allCases.enumerated().allSatisfy { bit, axis in
            mask & (1 << bit) == 0 || mirrorAxes.contains(axis) } }

        var out: [MeshBuildInstance] = []
        for k in 0..<count {
            for mask in masks {
                let isIdentity = k == 0 && mask == 0
                if !isIdentity {
                    guard copiesMade + 1 + below.count <= MeshBuild.maxCopies else {
                        truncated = true
                        continue
                    }
                    copiesMade += 1 + below.count
                }
                let axes = MeshBuildAxis.allCases.enumerated().filter { mask & (1 << $0.offset) != 0 }.map(\.element)
                let sign = Vec3(mask & 1 != 0 ? -1 : 1, mask & 2 != 0 ? -1 : 1, mask & 4 != 0 ? -1 : 1)
                func rename(_ name: String) -> String {
                    Self.mirrorName(k > 0 ? "\(name) \(k + 1)" : name, axes: axes)
                }
                var root = MeshBuildInstance(part: source, source: i, isOriginal: isIdentity)
                if let repetition { Self.place(&root, copy: k, of: count, repetition) }
                root.part.name = rename(source.name)
                root.reflect(sign)
                out.append(root)
                for instance in below {
                    var copy = instance
                    copy.part.name = rename(instance.part.name)
                    copy.part.parent = rename(instance.part.parent)
                    copy.isOriginal = instance.isOriginal && isIdentity
                    copy.reflect(sign)
                    out.append(copy)
                }
            }
        }
        return out
    }

    /// Moves `instance` to the `k`th place of `repetition` (0 keeps its place unless a ring has a radius).
    private static func place(_ instance: inout MeshBuildInstance, copy k: Int, of count: Int, _ repetition: MeshBuildRepeat) {
        var position = instance.part.position
        if let radial = repetition.radial {
            let turn = Quat(angle: repetition.angle(of: k, count: count) * .pi / 180, axis: radial.axis.unit)
            if let radius = radial.radius {
                position += turn * ((radial.axis == .x ? Vec3(0, 1, 0) : Vec3(1, 0, 0)) * radius)
            } else {
                position = turn * position
            }
            if k > 0 {
                instance.part.rotation = tidy((turn * Quat(eulerDegrees: instance.part.rotation)).eulerDegrees, 1e4)
                instance.trackTurn = turn
            }
        }
        instance.part.position = tidy(position + repetition.offset * Float(k), 1e5)
    }

    /// How a rotation's Euler angles change when it is mirrored by the sign matrix `d`
    /// (D·R·D): a turn about an axis keeps its angle times det(D) times that axis's sign. For a
    /// single mirror axis that negates the other two angles.
    static func eulerFactors(_ d: Vec3) -> Vec3 { Vec3(d.y * d.z, d.x * d.z, d.x * d.y) }

    /// `v` rounded to 1/`scale` (no float noise in the written-out values), without -0.
    static func tidy(_ v: Vec3, _ scale: Float) -> Vec3 {
        func f(_ x: Float) -> Float {
            let r = (x * scale).rounded() / scale
            return r == 0 ? 0 : r
        }
        return Vec3(f(v.x), f(v.y), f(v.z))
    }

    /// `track` of a part played on `copy` of it.
    private static func mapped(_ track: MeshBuildTrack, onto copy: MeshBuildInstance) -> MeshBuildTrack {
        var out = track
        out.part = copy.part.name
        let factors = eulerFactors(copy.trackSign)
        for k in out.keys.indices {
            let v = out.keys[k].value
            switch track.property {
            case .position: out.keys[k].value = tidy(copy.trackSign * (copy.trackTurn * v), 1e5)
            case .rotation: out.keys[k].value = tidy(v * factors, 1e4)
            case .scale: break
            }
        }
        return out
    }

    // MARK: Names

    /// Side words a mirror on each axis swaps, as pairs.
    static let sideWords: [MeshBuildAxis: [(String, String)]] = [
        .x: [("Left", "Right"), ("left", "right"), ("LEFT", "RIGHT"), ("L", "R")],
        .y: [("Top", "Bottom"), ("top", "bottom"), ("TOP", "BOTTOM"), ("Upper", "Lower"), ("upper", "lower"), ("UPPER", "LOWER")],
        .z: [("Front", "Back"), ("front", "back"), ("FRONT", "BACK")],
    ]

    /// `name` mirrored across `axes`: each axis swaps its side words, and axes the name has no
    /// word for are listed in a " (mirror …)" suffix.
    static func mirrorName(_ name: String, axes: [MeshBuildAxis]) -> String {
        guard !axes.isEmpty else { return name }
        // Runs of letters and runs of everything else.
        var runs: [String] = []
        for ch in name {
            if let last = runs.last, last.last?.isLetter == ch.isLetter { runs[runs.count - 1].append(ch) } else { runs.append(String(ch)) }
        }
        var unnamed: [MeshBuildAxis] = []
        for axis in axes {
            var swapped = false
            for i in runs.indices {
                for (a, b) in sideWords[axis] ?? [] {
                    if runs[i] == a { runs[i] = b; swapped = true; break }
                    if runs[i] == b { runs[i] = a; swapped = true; break }
                }
            }
            if !swapped { unnamed.append(axis) }
        }
        let base = runs.joined()
        return unnamed.isEmpty ? base : "\(base) (mirror \(unnamed.map(\.rawValue).joined()))"
    }
}
