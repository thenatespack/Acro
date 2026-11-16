import Foundation
import EngineAudio
import EngineCore
import EnginePhysics
import EngineScene

// World nodes (entities, transforms, components), component get / set nodes generated from
// reflection, and engine nodes for features the VM can reach from here: sounds, effects,
// raycasts, forces, scenes, tweens and data tables.

/// Despawns its entity after `remaining` seconds, or once its `AudioEmitter` stops when
/// `untilSoundEnds` (one-shot sounds and effects spawned by visual scripts). Not saved.
public struct VisualScriptTimedDestroy: Component, Equatable, Sendable {
    public static let componentName = "VisualScriptTimedDestroy"
    public static var isSerialized: Bool { false }
    public var remaining: Float
    public var untilSoundEnds: Bool

    public init(remaining: Float, untilSoundEnds: Bool = false) {
        self.remaining = remaining
        self.untilSoundEnds = untilSoundEnds
    }
}

extension VisualScriptRuntime {
    /// Despawns timed entities whose time is up (run every update).
    func updateTimedDestroys() {
        guard world.count(of: VisualScriptTimedDestroy.self) > 0 else { return }
        let dt = world.time.delta
        var doomed: [Entity] = []
        world.queryMutating(VisualScriptTimedDestroy.self) { entity, timer in
            timer.remaining -= dt
            var done = timer.remaining <= 0
            // The emitter clears isPlaying when a non-looping sound ends.
            if timer.untilSoundEnds, let emitter = world.get(AudioEmitter.self, for: entity), !emitter.isPlaying { done = true }
            if done { doomed.append(entity) }
        }
        for entity in doomed where world.isAlive(entity) { world.despawn(entity) }
    }
}

@MainActor
enum VisualScriptWorldNodes {
    static func all() -> [VSDef] { world() + transforms() + components() + engine() }

    static let entity = VSPin("entity", .entity, doc: "Unconnected: this entity")

    // MARK: Entities

    static func world() -> [VSDef] {
        [
            VSNode.pure("world.self", "Self", "World", "The entity this script runs on.", [], [VSPin("entity", .entity)]) { c in
                c.set("entity", .entity(c.entity))
            },
            VSNode.action("world.spawn", "Spawn Entity", "World", "Creates an empty entity named `name` at `position`.",
                          [VSPin("name", .string, default: .string("Entity")), VSPin("position", .vec3)], [VSPin("entity", .entity)]) { c in
                let spawned = c.world.spawn(Transform(position: try c.vec3("position")), Name(try c.string("name")))
                c.set("entity", .entity(spawned))
                return .next
            },
            VSNode.action("world.spawnPrefab", "Spawn Prefab", "World",
                          "Spawns a copy of `prefab` (a .prefab, model, mesh build or .vfx: asset:<id> or path under Assets/) at `position`.",
                          [VSPin("prefab", .asset, required: true), VSPin("position", .vec3), VSPin("rotation", .vec3, doc: "Euler degrees")],
                          [VSPin("entity", .entity)]) { c in
                let spawned = try spawnPrefab(c, try c.string("prefab"), at: try c.vec3("position"), rotation: Quat(eulerDegrees: try c.vec3("rotation")))
                c.set("entity", .entity(spawned))
                return .next
            },
            VSNode.action("world.destroy", "Destroy", "World", "Removes `entity` (and its children). Unconnected: this entity.",
                          [entity, VSPin("delay", .float, doc: "Seconds to wait first (0: now)")]) { c in
                let target = try c.entity("entity")
                guard c.world.isAlive(target) else { return .next }
                let delay = try c.float("delay")
                if delay > 0 { c.world.add(VisualScriptTimedDestroy(remaining: delay), to: target) } else { c.world.despawn(target) }
                return .next
            },
            VSNode.pure("world.findByName", "Find by Name", "World", "The first entity named `name`.",
                        [VSPin("name", .string)], [VSPin("entity", .entity), VSPin("found", .bool)]) { c in
                let name = try c.string("name")
                var found: Entity?
                c.world.query(Name.self) { entity, n in if found == nil, n.value == name { found = entity } }
                c.set("entity", .entity(found ?? .invalid))
                c.set("found", .bool(found != nil))
            },
            VSNode.pure("world.findAllByName", "Find All by Name", "World", "Every entity named `name`, as an array.",
                        [VSPin("name", .string)], [VSPin("entities", .array)]) { c in
                let name = try c.string("name")
                var found: [VSValue] = []
                c.world.query(Name.self) { entity, n in if n.value == name { found.append(.entity(entity)) } }
                c.set("entities", .array(found))
            },
            VSNode.pure("world.findByTag", "Find by Tag", "World", "The first entity tagged `tag` (its Tag component lists it).",
                        [VSPin("tag", .string)], [VSPin("entity", .entity), VSPin("found", .bool)]) { c in
                let found = c.world.firstEntity(taggedWith: try c.string("tag"))
                c.set("entity", .entity(found ?? .invalid))
                c.set("found", .bool(found != nil))
            },
            VSNode.pure("world.findAllByTag", "Find All by Tag", "World", "Every entity tagged `tag`, as an array.",
                        [VSPin("tag", .string)], [VSPin("entities", .array)]) { c in
                c.set("entities", .array(c.world.entities(taggedWith: try c.string("tag")).map { .entity($0) }))
            },
            VSNode.pure("world.hasTag", "Has Tag", "World", "Whether `entity` is tagged `tag`.", [entity, VSPin("tag", .string)],
                        [VSPin("result", .bool)]) { c in
                c.set("result", .bool(c.world.hasTag(try c.string("tag"), try c.entity("entity"))))
            },
            VSNode.pure("world.getTags", "Get Tags", "World", "`entity`'s tags, as an array of text.", [entity], [VSPin("tags", .array)]) { c in
                c.set("tags", .array((c.world.get(Tags.self, for: try c.entity("entity"))?.tags ?? []).map { .string($0) }))
            },
            VSNode.action("world.addTag", "Add Tag", "World", "Tags `entity` with `tag` (adding a Tag component if needed). Unconnected: this entity.",
                          [entity, VSPin("tag", .string, required: true)]) { c in
                c.world.addTag(try c.string("tag"), to: try c.liveEntity("entity"))
                return .next
            },
            VSNode.action("world.removeTag", "Remove Tag", "World", "Removes `tag` from `entity` (and the Tag component once it is empty).",
                          [entity, VSPin("tag", .string, required: true)]) { c in
                c.world.removeTag(try c.string("tag"), from: try c.entity("entity"))
                return .next
            },
            VSNode.pure("world.isValid", "Is Valid", "World", "Whether `entity` exists.", [VSPin("entity", .entity)], [VSPin("valid", .bool)]) { c in
                c.set("valid", .bool(c.world.isAlive(try c.entity("entity"))))
            },
            VSNode.pure("world.getName", "Get Name", "World", "`entity`'s name.", [entity], [VSPin("name", .string)]) { c in
                c.set("name", .string(c.world.get(Name.self, for: try c.entity("entity"))?.value ?? ""))
            },
            VSNode.pure("world.parent", "Get Parent", "World", "`entity`'s parent (none for a root).", [entity], [VSPin("parent", .entity)]) { c in
                c.set("parent", .entity(c.world.parent(of: try c.entity("entity")) ?? .invalid))
            },
            VSNode.action("world.setParent", "Set Parent", "World", "Moves `entity` under `parent` (unconnected parent: to the root), keeping where it is.",
                          [entity, VSPin("parent", .entity)]) { c in
                let child = try c.liveEntity("entity")
                let parent: Entity? = c.isConnected("parent") ? try c.entity("parent") : nil
                c.world.setParent(child, to: parent.flatMap { c.world.isAlive($0) ? $0 : nil }, keepWorldTransform: true)
                return .next
            },
        ]
    }

    static func spawnPrefab(_ c: VSContext, _ value: String, at position: Vec3, rotation: Quat = .identity) throws -> Entity {
        guard let assets = c.host.assets() else { throw VisualScriptError("no asset database to load '\(value)' from") }
        var reference: AssetReference?
        if let parsed = AssetReference(value), parsed.subAsset != nil { reference = parsed }
        if reference == nil, let id = assets.assetID(forScriptValue: value.split(separator: "#").first.map(String.init) ?? value) {
            reference = assets.asset(id)?.main.map { AssetReference(id, subAsset: $0) }
                ?? assets.references(of: .prefab).first { $0.asset == id }
        }
        guard let reference, let prefab = assets.prefab(reference) else { throw VisualScriptError("'\(value)' isn't a prefab, model or effect") }
        let name = (assets.path(of: reference.asset).map { (($0 as NSString).lastPathComponent as NSString).deletingPathExtension }) ?? "Prefab"
        let root = c.world.spawn(Transform(position: position, rotation: rotation), Name(name))
        if let template = try? prefab.template(prefabs: { assets.prefab($0) }), prefab.variant != nil {
            _ = try? c.world.load(template.data, under: root, ids: .regenerate)
        } else {
            c.world.instantiate(prefab, under: root)
        }
        return root
    }

    // MARK: Transforms

    static func transforms() -> [VSDef] {
        func transform(_ c: VSContext, _ e: Entity) -> Transform { c.world.get(Transform.self, for: e) ?? Transform() }
        func edit(_ c: VSContext, _ e: Entity, _ body: (inout Transform) -> Void) throws {
            guard c.world.isAlive(e) else { throw VisualScriptError("entity: no entity") }
            if c.world.modify(Transform.self, for: e, body) == nil {
                var t = Transform()
                body(&t)
                c.world.add(t, to: e)
            }
        }
        return [
            VSNode.pure("transform.getPosition", "Get Position", "Transform", "`entity`'s position (relative to its parent).",
                        [entity], [VSPin("position", .vec3)]) { c in
                c.set("position", .vec3(transform(c, try c.entity("entity")).position))
            },
            VSNode.pure("transform.getWorldPosition", "Get World Position", "Transform", "`entity`'s position in the world.",
                        [entity], [VSPin("position", .vec3)]) { c in
                let e = try c.entity("entity")
                let m = c.world.isAlive(e) ? c.world.worldMatrix(of: e) : .identity
                c.set("position", .vec3(Vec3(m.c3.x, m.c3.y, m.c3.z)))
            },
            VSNode.action("transform.setPosition", "Set Position", "Transform", "Moves `entity` to `position` (relative to its parent).",
                          [entity, VSPin("position", .vec3)]) { c in
                let p = try c.vec3("position")
                try edit(c, try c.entity("entity")) { $0.position = p }
                return .next
            },
            VSNode.action("transform.translate", "Translate", "Transform", "Moves `entity` by `offset` (in its parent's space; `local` in its own).",
                          [entity, VSPin("offset", .vec3), VSPin("local", .bool)]) { c in
                let offset = try c.vec3("offset"), local = try c.bool("local")
                try edit(c, try c.entity("entity")) { $0.position += local ? $0.rotation * offset : offset }
                return .next
            },
            VSNode.pure("transform.getRotation", "Get Rotation", "Transform", "`entity`'s rotation as Euler degrees.",
                        [entity], [VSPin("rotation", .vec3)]) { c in
                c.set("rotation", .vec3(transform(c, try c.entity("entity")).rotation.eulerDegrees))
            },
            VSNode.action("transform.setRotation", "Set Rotation", "Transform", "Sets `entity`'s rotation from Euler degrees.",
                          [entity, VSPin("rotation", .vec3)]) { c in
                let r = Quat(eulerDegrees: try c.vec3("rotation"))
                try edit(c, try c.entity("entity")) { $0.rotation = r }
                return .next
            },
            VSNode.action("transform.rotate", "Rotate", "Transform", "Turns `entity` by `degrees` around `axis` (its parent's space).",
                          [entity, VSPin("axis", .vec3, default: .vec3(Vec3(0, 1, 0))), VSPin("degrees", .float)]) { c in
                let axis = try c.vec3("axis"), degrees = try c.float("degrees")
                guard length(axis) > 1e-6 else { return .next }
                try edit(c, try c.entity("entity")) { $0.rotation = (Quat(angle: degrees * .pi / 180, axis: normalize(axis)) * $0.rotation).normalized }
                return .next
            },
            VSNode.action("transform.lookAt", "Look At", "Transform", "Turns `entity` so its forward (-Z) points at `target` (a position).",
                          [entity, VSPin("target", .vec3)]) { c in
                let target = try c.vec3("target")
                try edit(c, try c.entity("entity")) { t in
                    let direction = target - t.position
                    guard length(direction) > 1e-6 else { return }
                    let f = normalize(direction)
                    let yaw = atan2f(-f.x, -f.z), pitch = asinf(max(-1, min(1, f.y)))
                    t.rotation = Quat(angle: yaw, axis: Vec3(0, 1, 0)) * Quat(angle: pitch, axis: Vec3(1, 0, 0))
                }
                return .next
            },
            VSNode.pure("transform.forward", "Forward", "Transform", "The direction `entity` faces (-Z), in its parent's space.",
                        [entity], [VSPin("forward", .vec3)]) { c in
                c.set("forward", .vec3(transform(c, try c.entity("entity")).rotation * Vec3(0, 0, -1)))
            },
            VSNode.pure("transform.getScale", "Get Scale", "Transform", "`entity`'s scale.", [entity], [VSPin("scale", .vec3)]) { c in
                c.set("scale", .vec3(transform(c, try c.entity("entity")).scale))
            },
            VSNode.action("transform.setScale", "Set Scale", "Transform", "Sets `entity`'s scale.",
                          [entity, VSPin("scale", .vec3, default: .vec3(.one))]) { c in
                let s = try c.vec3("scale")
                try edit(c, try c.entity("entity")) { $0.scale = s }
                return .next
            },
        ]
    }

    // MARK: Components

    /// The leaf fields of a component (nested paths included), for get / set nodes.
    static func leafFields(of component: any Component) -> [FieldDescriptor] {
        var result: [FieldDescriptor] = []
        func walk(_ fields: [FieldDescriptor]) {
            for field in fields where !field.hints.hidden {
                switch field.kind {
                case .structure: walk(field.children)
                case .array, .unknown: continue
                default: result.append(field)
                }
            }
        }
        walk(component.fields())
        return result
    }

    static func fieldType(_ context: VisualScriptSignatureContext) -> VisualScriptType {
        guard let name = context.node.configString("component"), let path = context.node.configString("field"),
              let component = VisualScriptNodes.defaultComponent(named: name), let field = component.field(at: path) else { return .any }
        return VisualScriptValue.type(for: field.kind, color: field.hints.color) ?? .any
    }

    static func checkComponent(_ context: VisualScriptSignatureContext, needsField: Bool) -> [String] {
        guard let name = context.node.configString("component"), !name.isEmpty else { return ["no component chosen (config.component)"] }
        guard ComponentRegistry.type(named: name) != nil else { return ["component '\(name)' isn't registered (is its game module loaded?)"] }
        guard needsField else { return [] }
        guard let path = context.node.configString("field"), !path.isEmpty else { return ["no field chosen (config.field)"] }
        if let component = VisualScriptNodes.defaultComponent(named: name), component.field(at: path) == nil {
            return ["\(name) has no field '\(path)'"]
        }
        return []
    }

    static func components() -> [VSDef] {
        let componentKey = VisualScriptConfigKey("component", doc: "A component name (Light, RigidBody, your game's)")
        let fieldKey = VisualScriptConfigKey("field", doc: "A field path (\"intensity\", \"spatial.minDistance\")")
        return [
            VSDef(id: "component.get", title: "Get Field", category: "Components",
                  doc: "Reads a field of `entity`'s component (config component + field). Generated for every reflected field: see vscript.nodes.",
                  kind: .pure, config: [componentKey, fieldKey],
                  signature: { context in
                      VisualScriptSignature(inputs: [entity], outputs: [VSPin("value", fieldType(context)), VSPin("found", .bool)])
                  },
                  check: { checkComponent($0, needsField: true) },
                  run: { c in
                      let name = c.configString("component") ?? "", path = c.configString("field") ?? ""
                      let field = c.world.component(named: name, of: try c.entity("entity"))?.field(at: path)
                      c.set("value", field?.value.map(VisualScriptValue.init(field:)) ?? .none)
                      c.set("found", .bool(field != nil))
                      return .stop
                  }),
            VSDef(id: "component.set", title: "Set Field", category: "Components",
                  doc: "Sets a field of `entity`'s component (config component + field). Generated for every reflected field: see vscript.nodes.",
                  kind: .action, config: [componentKey, fieldKey],
                  signature: { context in
                      VisualScriptSignature(inputs: [.exec("in"), entity, VSPin("value", fieldType(context))], outputs: [.exec("out")])
                  },
                  check: { checkComponent($0, needsField: true) },
                  run: { c in
                      let name = c.configString("component") ?? "", path = c.configString("field") ?? ""
                      let target = try c.liveEntity("entity")
                      guard let field = c.world.component(named: name, of: target)?.field(at: path) else {
                          throw VisualScriptError("the entity has no \(name).\(path)")
                      }
                      do {
                          try c.world.setField(path, of: name, for: target, to: try c.input("value").fieldValue(for: field.kind))
                      } catch {
                          throw VisualScriptError("\(name).\(path): \(error)")
                      }
                      return .next
                  }),
            VSDef(id: "component.has", title: "Has Component", category: "Components", doc: "Whether `entity` has the component (config).",
                  kind: .pure, config: [componentKey],
                  signature: { _ in VisualScriptSignature(inputs: [entity], outputs: [VSPin("result", .bool)]) },
                  check: { checkComponent($0, needsField: false) },
                  run: { c in
                      c.set("result", .bool(c.world.component(named: c.configString("component") ?? "", of: try c.entity("entity")) != nil))
                      return .stop
                  }),
            VSDef(id: "component.add", title: "Add Component", category: "Components",
                  doc: "Adds the component (config) with its default values to `entity` (kept when it has one).",
                  kind: .action, config: [componentKey],
                  signature: { _ in VisualScriptSignature(inputs: [.exec("in"), entity], outputs: [.exec("out")]) },
                  check: { checkComponent($0, needsField: false) },
                  run: { c in
                      let name = c.configString("component") ?? ""
                      let target = try c.liveEntity("entity")
                      guard c.world.component(named: name, of: target) == nil else { return .next }
                      guard let component = VisualScriptNodes.defaultComponent(named: name) else {
                          throw VisualScriptError("can't make a default \(name)")
                      }
                      c.world.add(component, to: target)
                      return .next
                  }),
            VSDef(id: "component.remove", title: "Remove Component", category: "Components", doc: "Removes the component (config) from `entity`.",
                  kind: .action, config: [componentKey],
                  signature: { _ in VisualScriptSignature(inputs: [.exec("in"), entity], outputs: [.exec("out")]) },
                  check: { checkComponent($0, needsField: false) },
                  run: { c in
                      let target = try c.entity("entity")
                      if c.world.isAlive(target), let type = ComponentRegistry.type(named: c.configString("component") ?? "") {
                          c.world.remove(type, from: target)
                      }
                      return .next
                  }),
        ]
    }

    // MARK: Engine

    static func engine() -> [VSDef] {
        let ease = VisualScriptConfigKey("ease", options: Easing.allCases.map(\.rawValue), doc: "Default cubicInOut")
        return [
            VSNode.action("audio.play", "Play Sound", "Audio",
                          "Plays `sound` (an audio file or .sfx) once at `position` (unconnected: this entity's), as a temporary entity.",
                          [VSPin("sound", .asset, required: true), VSPin("position", .vec3), VSPin("volume", .float, default: .float(1)),
                           VSPin("pitch", .float, default: .float(1))],
                          [VSPin("entity", .entity)]) { c in
                let value = try c.string("sound")
                guard let assets = c.host.assets(), let id = assets.assetID(forScriptValue: value) else {
                    throw VisualScriptError("no sound '\(value)'")
                }
                var position = try c.vec3("position")
                if !c.isConnected("position"), c.config("position") == nil, c.world.isAlive(c.entity) {
                    let m = c.world.worldMatrix(of: c.entity)
                    position = Vec3(m.c3.x, m.c3.y, m.c3.z)
                }
                AudioSystem.registerComponents()
                let emitter = AudioEmitter(clip: AssetReference(id).description, volume: try c.float("volume"), pitch: try c.float("pitch"),
                                           loop: false, isPlaying: true)
                let spawned = c.world.spawn(Transform(position: position), Name("Sound"), emitter,
                                            VisualScriptTimedDestroy(remaining: 30, untilSoundEnds: true))
                c.set("entity", .entity(spawned))
                return .next
            },
            VSNode.action("vfx.spawn", "Spawn Effect", "Effects",
                          "Spawns the effect `effect` (.vfx, or any prefab) at `position`; removed after `lifetime` seconds (0: kept).",
                          [VSPin("effect", .asset, required: true), VSPin("position", .vec3), VSPin("lifetime", .float, default: .float(5))],
                          [VSPin("entity", .entity)]) { c in
                let spawned = try spawnPrefab(c, try c.string("effect"), at: try c.vec3("position"))
                let lifetime = try c.float("lifetime")
                if lifetime > 0 { c.world.add(VisualScriptTimedDestroy(remaining: lifetime), to: spawned) }
                c.set("entity", .entity(spawned))
                return .next
            },
            VSNode.action("physics.raycast", "Raycast", "Physics",
                          "Casts a ray from `origin` along `direction` up to `distance` (3D colliders; this entity's own body is skipped).",
                          [VSPin("origin", .vec3), VSPin("direction", .vec3, default: .vec3(Vec3(0, 0, -1))),
                           VSPin("distance", .float, default: .float(100))],
                          [VSPin("hit", .bool), VSPin("entity", .entity), VSPin("point", .vec3), VSPin("normal", .vec3), VSPin("hitDistance", .float)]) { c in
                guard let physics = c.host.physics() else { throw VisualScriptError("no 3D physics in this scene (add a collider)") }
                let direction = try c.vec3("direction")
                guard length(direction) > 1e-6 else { throw VisualScriptError("direction is zero") }
                let own = physics.body(for: c.entity).map { [$0] } ?? []
                let hit = physics.raycast(Ray(origin: try c.vec3("origin"), direction: direction), maxDistance: try c.float("distance"),
                                          filter: QueryFilter(excluding: own))
                c.set("hit", .bool(hit != nil))
                c.set("entity", .entity(hit?.entity ?? .invalid))
                c.set("point", .vec3(hit?.point ?? .zero))
                c.set("normal", .vec3(hit?.normal ?? .zero))
                c.set("hitDistance", .float(Double(hit?.distance ?? 0)))
                return .next
            },
            VSNode.action("physics.applyForce", "Apply Force", "Physics",
                          "Pushes `entity`'s rigid body: `mode` impulse (a kick, default), force (call every fixed update) or velocity (sets it).",
                          config: [VisualScriptConfigKey("mode", options: ["impulse", "force", "velocity"])],
                          [entity, VSPin("force", .vec3)]) { c in
                let target = try c.liveEntity("entity")
                let force = try c.vec3("force")
                let mode = c.configString("mode") ?? "impulse"
                if let physics = c.host.physics(), let body = physics.body(for: target), mode != "velocity" {
                    if mode == "force" { physics.applyForce(body, force) } else { physics.applyImpulse(body, force) }
                    physics.wake(body)
                } else if c.world.has(RigidBody.self, for: target) {
                    c.world.modify(RigidBody.self, for: target) { body in
                        body.linearVelocity = mode == "velocity" ? force : body.linearVelocity + force * (mode == "force" ? c.dt : 1)
                    }
                } else if c.world.has(RigidBody2D.self, for: target) {
                    c.world.modify(RigidBody2D.self, for: target) { body in
                        let f = Vec2(force.x, force.y)
                        body.linearVelocity = mode == "velocity" ? f : body.linearVelocity + f * (mode == "force" ? c.dt : 1)
                    }
                } else {
                    throw VisualScriptError("the entity has no RigidBody")
                }
                return .next
            },
            VSNode.action("scene.load", "Load Scene", "Scene", "Switches to the scene at `path` (relative to Assets/) after this frame.",
                          [VSPin("path", .string, required: true)]) { c in
                guard let load = c.host.loadScene else { throw VisualScriptError("this host can't switch scenes") }
                load(try c.string("path"))
                return .next
            },
            VSNode.action("scene.reload", "Reload Scene", "Scene", "Starts the current scene over after this frame.") { c in
                guard let reload = c.host.reloadScene else { throw VisualScriptError("this host can't reload scenes") }
                reload()
                return .next
            },
            VSNode.action("tween.transform", "Tween", "Tween",
                          "Animates `entity`'s `property` (config: position, rotation (Euler degrees) or scale) to `to` over `duration` seconds. `out` continues now, `done` when it ends.",
                          config: [VisualScriptConfigKey("property", options: ["position", "rotation", "scale"]), ease],
                          [entity, VSPin("to", .vec3), VSPin("duration", .float, default: .float(1))],
                          [.exec("out"), .exec("done")]) { c in
                let target = try c.liveEntity("entity")
                let to = try c.vec3("to"), duration = max(try c.float("duration"), 0)
                let property = c.configString("property") ?? "position"
                let easing = c.configString("ease").flatMap(Easing.init(rawValue:)) ?? .cubicInOut
                let world = c.world
                let start = world.get(Transform.self, for: target) ?? Transform()
                let goal = Quat(eulerDegrees: to)
                var elapsed: Float = 0
                c.every(frame: { dt in
                    guard world.isAlive(target) else { return true }
                    elapsed += dt
                    let t = duration > 0 ? min(elapsed / duration, 1) : 1
                    let k = easing(t)
                    world.modify(Transform.self, for: target) { transform in
                        switch property {
                        case "rotation": transform.rotation = Quat.slerp(start.rotation, goal, k)
                        case "scale": transform.scale = start.scale + (to - start.scale) * k
                        default: transform.position = start.position + (to - start.position) * k
                        }
                    }
                    return t >= 1
                }, then: "done")
                return .next
            },
            VSNode.pure("table.value", "Table Value", "Data",
                        "A cell of a data table: `table` (asset), row id `row`, column `column`; `value` has the column's type.",
                        [VSPin("table", .asset, required: true), VSPin("row", .string), VSPin("column", .string)],
                        [VSPin("value", .any), VSPin("number", .float), VSPin("text", .string), VSPin("found", .bool)]) { c in
                let tableValue = try c.string("table")
                guard let assets = c.host.assets(), let id = assets.assetID(forScriptValue: tableValue), let reader = assets.dataTable(id) else {
                    throw VisualScriptError("no data table '\(tableValue)'")
                }
                let column = try c.string("column")
                let row = reader.row(try c.string("row"))
                let type = reader.columns.first { $0.name == column }?.type
                var value = VSValue.none
                if let row, let type {
                    switch type {
                    case .number: value = row.number(column).map { .float($0) } ?? .none
                    case .bool: value = row.bool(column).map { .bool($0) } ?? .none
                    case .color: value = row.color(column).map { .vec4($0) } ?? .none
                    default: value = row.text(column).map { .string($0) } ?? .none
                    }
                }
                c.set("value", value)
                c.set("number", .float(row?.number(column) ?? value.asDouble))
                c.set("text", .string(row?.text(column) ?? ""))
                c.set("found", .bool(row != nil && type != nil))
            },
            VSNode.pure("table.rows", "Table Rows", "Data", "The row ids of a data table, in file order (for For Each).",
                        [VSPin("table", .asset, required: true)], [VSPin("ids", .array)]) { c in
                let tableValue = try c.string("table")
                guard let assets = c.host.assets(), let id = assets.assetID(forScriptValue: tableValue), let reader = assets.dataTable(id) else {
                    throw VisualScriptError("no data table '\(tableValue)'")
                }
                c.set("ids", .array(reader.ids.map { .string($0) }))
            },
        ]
    }
}

extension VisualScriptNodes {
    /// One addable node: a type with its config filled in (component get / set nodes come once
    /// per reflected field).
    public struct CatalogEntry: Codable, Equatable, Sendable {
        public struct Pin: Codable, Equatable, Sendable {
            public var name: String
            public var type: VisualScriptType
            public var required: Bool?
            public var defaultValue: JSONValue?
        }
        public struct Setting: Codable, Equatable, Sendable {
            public var name: String
            public var type: VisualScriptType
            public var options: [String]?
            public var doc: String?
        }

        public var type: String
        public var title: String
        public var category: String
        public var kind: VisualScriptNodeKind
        public var doc: String
        public var config: [String: JSONValue]?
        public var settings: [Setting]?
        public var inputs: [Pin]
        public var outputs: [Pin]
    }

    /// Every addable node whose type, title, category or doc contains `search` (all words, any
    /// case), with pins as a node with that config has them. `graph` gives variables and
    /// functions their pins. `pinType` keeps nodes with a pin that takes (`input`) or gives that type.
    public static func catalog(search: String = "", graph: VisualScriptGraph = VisualScriptGraph(), pinType: VisualScriptType? = nil,
                               includeComponentFields: Bool = true, limit: Int = .max) -> [CatalogEntry] {
        let words = search.lowercased().split(separator: " ").map(String.init)
        func matches(_ text: String) -> Bool { words.allSatisfy { text.lowercased().contains($0) } }
        var entries: [CatalogEntry] = []
        func add(_ definition: VisualScriptNodeDefinition, config: [String: JSONValue] = [:], title: String? = nil) {
            let node = VisualScriptNode(id: "n", type: definition.id, config: config)
            let signature = definition.signature(for: node, in: graph)
            let title = title ?? definition.title
            let text = "\(definition.id) \(title) \(definition.category) \(definition.doc) " + config.values.map { "\($0)" }.joined(separator: " ")
            guard matches(text) else { return }
            if let pinType, !(signature.inputs + signature.outputs).contains(where: { $0.type == pinType || ($0.type == .any && pinType != .exec) }) {
                return
            }
            func pins(_ list: [VisualScriptPin]) -> [CatalogEntry.Pin] {
                list.map { CatalogEntry.Pin(name: $0.name, type: $0.type, required: $0.required ? true : nil, defaultValue: $0.defaultValue?.json) }
            }
            entries.append(CatalogEntry(
                type: definition.id, title: title, category: definition.category, kind: definition.kind, doc: definition.doc,
                config: config.isEmpty ? nil : config,
                settings: definition.config.isEmpty ? nil : definition.config.map { .init(name: $0.name, type: $0.type, options: $0.options, doc: $0.doc) },
                inputs: pins(signature.inputs), outputs: pins(signature.outputs)))
        }
        for definition in all {
            switch definition.id {
            case "var.get", "var.set":
                if graph.variables.isEmpty { add(definition) }
                for variable in graph.variables {
                    add(definition, config: ["variable": .string(variable.name)], title: "\(definition.id == "var.get" ? "Get" : "Set") \(variable.name)")
                }
            case "function.call":
                if graph.functions.isEmpty { add(definition) }
                for function in graph.functions { add(definition, config: ["function": .string(function.name)], title: "Call \(function.name)") }
            case "component.get", "component.set":
                add(definition)
                guard includeComponentFields else { continue }
                for name in ComponentRegistry.names where name != VisualScript.componentName && name != VisualScriptTimedDestroy.componentName {
                    guard let component = defaultComponent(named: name) else { continue }
                    for field in VisualScriptWorldNodes.leafFields(of: component) {
                        if definition.id == "component.set", field.hints.readOnly { continue }
                        add(definition, config: ["component": .string(name), "field": .string(field.path)],
                            title: "\(definition.id == "component.get" ? "Get" : "Set") \(name).\(field.path)")
                    }
                }
            default:
                add(definition)
            }
            if entries.count >= limit { break }
        }
        return Array(entries.prefix(limit))
    }
}
