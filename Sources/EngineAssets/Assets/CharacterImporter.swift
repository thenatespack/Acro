import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// Imports `.character` files (a `CharacterBuild` as JSON):
/// - `mesh/body <region>` and `material/body <region>`: the skinned body, one mesh per color region;
/// - `mesh/<attachment> <part>` and `material/<attachment> <part>`: each attachment's mesh build parts;
/// - `clip/<name>`: the template's stock clips (`AnimationClip`s targeting the bones in order);
/// - the main `prefab/<file name>`: a root named after the file with an `Animator`, the bone
///   hierarchy (attachments under their bones) and the body meshes, each with a `Skin` bound to
///   the bones.
///
/// The prefab is a scene-file prefab (like a `.prefab` file), since the `Animator` is a component
/// node trees can't hold: it needs `Skin` and `Animator` registered with `ComponentRegistry`
/// (`SkeletalAnimation.registerComponents()`; the editor and game players do). Entities get
/// stable uids from their name paths, so placed copies keep their overrides across edits.
///
/// The `Animator` has one state per clip (named after it, looping for idle, walk and run), plus a
/// `locomotion` 1D blend of idle, walk and run on the float parameter `speed` (meters per second),
/// starting in `defaultClip`. Triggers `jump`, `attack` and `die` play those clips from any state;
/// jump and attack then return to locomotion. Its clip handles are the clips' reference text
/// ("asset:<id>#clip/walk"), which `World.addAssetAnimationSystem` loads from the asset database.
public struct CharacterImporter: AssetImporter {
    public init() {}

    public var name: String { "character" }
    public var fileExtensions: [String] { ["character"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let build: CharacterBuild
        do { build = try AssetJSON.decoder().decode(CharacterBuild.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a character: \(error)")
        }
        for problem in build.problems { context.warn(problem) }
        let stem = ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension
        let rig = build.rig
        var asset = ImportedAsset()
        var namer = SubAssetNamer()
        var scene = CharacterScene()

        // Root first: its Animator is filled in once the bones have ids.
        let root = scene.add(name: stem, transform: Transform(), parent: nil, path: stem)

        // Bones (depth first) with their attachments.
        var boneIDs = [Int](repeating: 0, count: rig.bones.count)
        var children: [Int: [Int]] = [:]
        for (i, bone) in rig.bones.enumerated() where bone.parent != nil { children[bone.parent!, default: []].append(i) }
        var attachmentsByBone: [Int: [CharacterAttachment]] = [:]
        for attachment in build.attachments {
            attachmentsByBone[rig.index(of: attachment.bone) ?? 0, default: []].append(attachment)
        }
        func addBone(_ i: Int, parent: Int, path: String) {
            let bone = rig.bones[i]
            let bonePath = path + "/" + bone.name
            let id = scene.add(name: bone.name, transform: Transform(position: bone.offset), parent: parent, path: bonePath)
            boneIDs[i] = id
            for child in children[i] ?? [] { addBone(child, parent: id, path: bonePath) }
            for attachment in attachmentsByBone[i] ?? [] {
                addAttachment(attachment, parent: id, path: bonePath, &context, &asset, &namer, &scene)
            }
        }
        addBone(0, parent: root, path: stem)

        // The skinned body.
        let skin: JSONValue = .object([
            "joints": .array(boneIDs.map { CharacterScene.entity($0) }),
            "inverseBindMatrices": try AssetJSON.value(rig.inverseBindMatrices),
        ])
        for (region, geometry) in rig.bodyMeshes(segments: build.segments, smooth: build.smooth) {
            let label = "body \(region.rawValue)"
            let meshID = namer.id(kind: "mesh", name: label, index: 0)
            asset.add(meshID, name: label, .mesh(geometry))
            let materialID = namer.id(kind: "material", name: label, index: 0)
            let color = MeshBuildColor.linear(fromSRGB: build.color(region))
            asset.add(materialID, name: label, .material(MaterialAsset(
                shading: .pbr, baseColor: Vec4(color.x, color.y, color.z, 1), metallic: 0, roughness: region == .eyes ? 0.2 : 0.75)))
            let renderer = MeshRenderer(mesh: MeshHandle(context.reference(meshID)), material: MaterialHandle(context.reference(materialID)))
            scene.add(name: "Body \(region.rawValue.capitalized)", transform: Transform(), parent: root, path: stem + "/" + label,
                      components: ["MeshRenderer": try AssetJSON.value(renderer), "Skin": skin])
        }

        // Clips and the Animator.
        var clipKeys: [String: String] = [:]
        for clip in CharacterClips.clips(build.clips, rig: rig) {
            let id = namer.id(kind: "clip", name: clip.name, index: 0)
            asset.add(id, name: clip.name, .animation(clip))
            clipKeys[clip.name] = context.reference(id).description
        }
        scene.records[root].components["Animator"] = Self.animator(build: build, rig: rig, clipKeys: clipKeys,
                                                                    targets: boneIDs)

        let prefabID = namer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefabID, name: stem, .prefab(PrefabAsset(scene: try scene.data())))
        asset.main = prefabID
        return asset
    }

    // MARK: Attachments

    private func addAttachment(_ attachment: CharacterAttachment, parent: Int, path: String, _ context: inout ImportContext,
                               _ asset: inout ImportedAsset, _ namer: inout SubAssetNamer, _ scene: inout CharacterScene) {
        let nodePath = path + "/" + attachment.name
        let node = scene.add(name: attachment.name, transform: attachment.transform, parent: parent, path: nodePath)
        guard let build = Self.meshBuild(attachment.asset, owner: attachment.name, &context) else { return }
        // Each part's transform relative to the model's root (part hierarchies flattened).
        var firstIndex: [String: Int] = [:]
        for (i, part) in build.parts.enumerated() where firstIndex[part.name] == nil { firstIndex[part.name] = i }
        func world(_ i: Int, _ depth: Int = 0) -> Mat4 {
            let part = build.parts[i]
            let local = part.transform.matrix
            guard depth < build.parts.count, !part.parent.isEmpty, let p = firstIndex[part.parent], p != i else { return local }
            return world(p, depth + 1) * local
        }
        var drew = false
        for (i, part) in build.parts.enumerated() {
            guard let geometry = part.geometry(), !geometry.indices.isEmpty else { continue }
            let label = "\(attachment.name) \(part.name)"
            let meshID = namer.id(kind: "mesh", name: label, index: i)
            asset.add(meshID, name: label, .mesh(geometry))
            var material: AssetReference?
            let materialPath = part.material.trimmingCharacters(in: .whitespaces)
            if attachment.color == nil, !materialPath.isEmpty {
                material = Self.reference(materialPath, kind: "material", &context)
                if material == nil { context.warn("attachment '\(attachment.name)', part '\(part.name)': no material '\(materialPath)'") }
            }
            if material == nil {
                var look = part
                if let color = attachment.color { look.color = color }
                let texture = part.texture.isEmpty ? nil : Self.reference(part.texture, kind: "texture", &context)
                let materialID = namer.id(kind: "material", name: label, index: i)
                asset.add(materialID, name: label, .material(MeshBuildImporter.material(for: look, texture: texture)))
                material = context.reference(materialID)
            }
            let renderer = MeshRenderer(mesh: MeshHandle(context.reference(meshID)), material: material.map { MaterialHandle($0) } ?? .default)
            scene.add(name: part.name, transform: Transform(matrix: world(i)), parent: node, path: nodePath + "/" + part.name + "#\(i)",
                      components: ["MeshRenderer": (try? AssetJSON.value(renderer)) ?? .null])
            drew = true
        }
        if !drew { context.warn("attachment '\(attachment.name)': '\(attachment.asset)' has no shapes") }
    }

    /// The asset `value` names: "asset:<id>[#object]" or a path under `Assets/`; a file gets `kind` as its object.
    static func reference(_ value: String, kind: String, _ context: inout ImportContext) -> AssetReference? {
        let value = value.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            return reference.subAsset == nil ? AssetReference(reference.asset, subAsset: kind) : reference
        }
        let path = value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
        return (context.assetsByPath[path] ?? context.asset(atRelativePath: path)).map { AssetReference($0, subAsset: kind) }
    }

    /// The mesh build an attachment names (read as a dependency, so editing it reimports the character).
    static func meshBuild(_ value: String, owner: String, _ context: inout ImportContext) -> MeshBuild? {
        let value = value.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        var path = value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            guard let found = context.assetsByPath.first(where: { $0.value == reference.asset })?.key else {
                context.warn("attachment '\(owner)': no asset '\(value)'")
                return nil
            }
            path = found
        }
        guard context.assetsByPath[path] != nil else {
            context.warn("attachment '\(owner)': no asset '\(value)'")
            return nil
        }
        let depth = context.assetPath.split(separator: "/").count - 1
        guard path.lowercased().hasSuffix(".meshbuild"),
              let data = try? context.readDependency(relativePath: String(repeating: "../", count: depth) + path),
              let build = try? AssetJSON.decoder().decode(MeshBuild.self, from: data) else {
            context.warn("attachment '\(owner)': '\(value)' isn't a readable .meshbuild")
            return nil
        }
        return build
    }

    // MARK: Animator

    /// Walking and running speeds (meters per second) the locomotion blend places walk and run at.
    public static func locomotionSpeeds(_ rig: CharacterRig) -> (walk: Float, run: Float) {
        let legs = rig.proportions.legs * rig.proportions.height
        switch rig.template {
        case .humanoid: return (1.4 * legs, 3.6 * legs)
        case .quadruped: return (1.2 * legs, 4.5 * legs)
        case .bird: return (0.6 * legs, 1.8 * legs)
        case .blob: return (1.0 * rig.proportions.height, 2.4 * rig.proportions.height)
        }
    }

    /// The `Animator` component as scene-file JSON (the encoding of `Animator` in EngineRendering,
    /// which this module can't name; `CharacterTests` checks the two agree).
    static func animator(build: CharacterBuild, rig: CharacterRig, clipKeys: [String: String], targets: [Int]) -> JSONValue {
        func clipMotion(_ key: String) -> JSONValue { .object(["clip": .object(["_0": .string(key)])]) }
        func number(_ v: Float) -> JSONValue { .double(Double(v)) }
        var states: [JSONValue] = []
        let names = build.clipNames
        for name in names {
            guard let key = clipKeys[name] else { continue }
            states.append(.object(["name": .string(name), "motion": clipMotion(key), "speed": number(1),
                                   "loops": .bool(CharacterClips.loops(name))]))
        }
        let speeds = locomotionSpeeds(rig)
        var entries: [JSONValue] = []
        for (name, position) in [("idle", Float(0)), ("walk", speeds.walk), ("run", speeds.run)] {
            if let key = clipKeys[name] { entries.append(.object(["clip": .string(key), "position": number(position)])) }
        }
        let hasLocomotion = entries.count >= 2
        if hasLocomotion {
            states.append(.object(["name": .string("locomotion"),
                                   "motion": .object(["blend1D": .object(["parameter": .string("speed"), "entries": .array(entries)])]),
                                   "speed": number(1), "loops": .bool(true)]))
        }
        let initial = names.contains(build.defaultClip) ? build.defaultClip : names.first
        var transitions: [JSONValue] = []
        for trigger in ["jump", "attack", "die"] where clipKeys[trigger] != nil {
            transitions.append(.object(["to": .string(trigger), "conditions": .array([.object(["parameter": .string(trigger),
                                                                                                  "test": .object(["triggered": .object([:])])])]),
                                        "duration": number(0.12), "canTransitionToSelf": .bool(true)]))
        }
        let back = hasLocomotion ? "locomotion" : initial
        for from in ["jump", "attack"] where clipKeys[from] != nil {
            if let back, back != from {
                transitions.append(.object(["from": .string(from), "to": .string(back), "conditions": .array([]),
                                            "exitTime": number(1), "duration": number(0.2), "canTransitionToSelf": .bool(false)]))
            }
        }
        var machine: [String: JSONValue] = ["states": .array(states), "transitions": .array(transitions)]
        if let initial { machine["initialState"] = .string(initial) }
        var parameters: [String: JSONValue] = [:]
        if hasLocomotion { parameters["speed"] = .object(["float": .object(["_0": number(0)])]) }
        for trigger in ["jump", "attack", "die"] where clipKeys[trigger] != nil {
            parameters[trigger] = .object(["trigger": .object(["_0": .bool(false)])])
        }
        return .object([
            "targets": .array(targets.map { CharacterScene.entity($0) }),
            "restPose": (try? AssetJSON.value(rig.restPose)) ?? .array([]),
            "stateMachine": .object(machine),
            "parameters": .object(parameters),
            "layers": .array([]),
            "speed": number(1),
            "isPlaying": .bool(true),
            "playbacks": .array([]),
            "fadeDuration": number(0),
            "fadeElapsed": number(0),
            "events": .array([]),
        ])
    }
}

/// A scene file written by hand (the importer can't use a `World`: imports run off the main
/// thread). Entities are added parents first; ids count up from 0 as the format requires.
struct CharacterScene {
    struct Record {
        var parent: Int?
        var uid: EntityID
        var components: [String: JSONValue]
    }

    var records: [Record] = []

    /// Adds an entity with a `Name` and `Transform` and returns its file id. `path` (unique)
    /// seeds its uid.
    @discardableResult
    mutating func add(name: String, transform: Transform, parent: Int?, path: String, components: [String: JSONValue] = [:]) -> Int {
        var all = components
        all["Name"] = (try? AssetJSON.value(Name(name))) ?? .null
        all["Transform"] = (try? AssetJSON.value(transform)) ?? .null
        records.append(Record(parent: parent, uid: Self.uid(path), components: all))
        return records.count - 1
    }

    /// A reference to the entity with file id `id`.
    static func entity(_ id: Int) -> JSONValue { .object(["$entity": .int(Int64(id))]) }

    /// A stable uid from a name path (two FNV-1a hashes).
    static func uid(_ path: String) -> EntityID {
        func fnv(_ seed: UInt64) -> UInt64 {
            var h = seed
            for b in path.utf8 { h = (h ^ UInt64(b)) &* 0x100_0000_01b3 }
            return h == 0 ? 1 : h
        }
        return EntityID(high: fnv(0xcbf2_9ce4_8422_2325), low: fnv(0x8422_2325_cbf2_9ce4))
    }

    func data() throws -> Data {
        var entities: [JSONValue] = []
        for (id, record) in records.enumerated() {
            var fields: [String: JSONValue] = ["id": .int(Int64(id)), "uid": .string(record.uid.description),
                                               "components": .object(record.components)]
            if let parent = record.parent { fields["parent"] = .int(Int64(parent)) }
            entities.append(.object(fields))
        }
        let file: JSONValue = .object(["format": .string(SceneFile.format), "version": .int(Int64(SceneFile.currentVersion)),
                                       "entities": .array(entities)])
        return try AssetJSON.encode(file)
    }
}
