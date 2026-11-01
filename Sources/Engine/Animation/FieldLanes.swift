import Foundation

/// One animatable float of a component: a `Float` field or one lane of a `Vec2`/`Vec3`/`Vec4`.
/// `FieldAnimator` resolves each track's `target` to a lane once and caches it.
public struct FieldLane {
    public var get: @MainActor (World, Entity) -> Float?
    public var set: @MainActor (World, Entity, Float) -> Void
    /// 0, 1 or 2 for `Transform.rotation` (euler degrees, applied by the animator); nil otherwise.
    public var rotationAxis: Int?

    public init(get: @escaping @MainActor (World, Entity) -> Float?, set: @escaping @MainActor (World, Entity, Float) -> Void,
                rotationAxis: Int? = nil) {
        self.get = get
        self.set = set
        self.rotationAxis = rotationAxis
    }
}

/// Resolves `"Component.field.lane"` strings to `FieldLane`s. The engine's common render and
/// transform fields have typed fast paths (a key path read and write, no reflection); every
/// other registered component's float and vector fields work through the reflection system
/// (about 0.3 ms per write: fine for a few entities, not hundreds). Games register fast paths
/// for their own components with `register`.
@MainActor
public enum FieldLanes {
    private static var table: [String: FieldLane] = [:]
    private static var cache: [String: FieldLane?] = [:]
    private static var registeredBuiltins = false

    /// Fast path for a `Float` field: target `"<Component>.<field>"`.
    public static func register<C: Component>(_ type: C.Type, field: String, _ keyPath: WritableKeyPath<C, Float>) {
        table[C.componentName + "." + field] = lane(C.self, keyPath)
        cache.removeAll()
    }

    /// Fast path for a `Vec2` / `Vec3` / `Vec4` field: targets `"<Component>.<field>.x"` ... (and `.r` ...).
    public static func register<C: Component>(_ type: C.Type, field: String, _ keyPath: WritableKeyPath<C, Vec2>) {
        for (names, path) in [(["x", "r"], keyPath.appending(path: \Vec2.x)), (["y", "g"], keyPath.appending(path: \Vec2.y))] {
            for name in names { table[C.componentName + "." + field + "." + name] = lane(C.self, path) }
        }
        cache.removeAll()
    }

    public static func register<C: Component>(_ type: C.Type, field: String, _ keyPath: WritableKeyPath<C, Vec3>) {
        let paths = [keyPath.appending(path: \Vec3.x), keyPath.appending(path: \Vec3.y), keyPath.appending(path: \Vec3.z)]
        for (i, name) in ["x", "y", "z"].enumerated() { table[C.componentName + "." + field + "." + name] = lane(C.self, paths[i]) }
        for (i, name) in ["r", "g", "b"].enumerated() { table[C.componentName + "." + field + "." + name] = lane(C.self, paths[i]) }
        cache.removeAll()
    }

    public static func register<C: Component>(_ type: C.Type, field: String, _ keyPath: WritableKeyPath<C, Vec4>) {
        let paths = [keyPath.appending(path: \Vec4.x), keyPath.appending(path: \Vec4.y), keyPath.appending(path: \Vec4.z),
                     keyPath.appending(path: \Vec4.w)]
        for (i, name) in ["x", "y", "z", "w"].enumerated() { table[C.componentName + "." + field + "." + name] = lane(C.self, paths[i]) }
        for (i, name) in ["r", "g", "b", "a"].enumerated() { table[C.componentName + "." + field + "." + name] = lane(C.self, paths[i]) }
        cache.removeAll()
    }

    private static func lane<C: Component>(_: C.Type, _ keyPath: WritableKeyPath<C, Float>) -> FieldLane {
        FieldLane(get: { world, entity in world.get(C.self, for: entity)?[keyPath: keyPath] },
                  set: { world, entity, value in world.modify(C.self, for: entity) { $0[keyPath: keyPath] = value } })
    }

    /// The lane for `target` (cached), or nil if it is malformed.
    public static func lane(for target: String) -> FieldLane? {
        if let cached = cache[target] { return cached }
        registerBuiltins()
        let resolved = table[target] ?? reflected(target)
        cache[target] = resolved
        return resolved
    }

    private static let laneNames: [String: Int] = ["x": 0, "y": 1, "z": 2, "w": 3, "r": 0, "g": 1, "b": 2, "a": 3]

    /// Reflection fallback: reads `path` as a float, or the lane named by its last segment of
    /// the vector at the rest of the path. A field that doesn't exist reads nil and writes nothing.
    private static func reflected(_ target: String) -> FieldLane? {
        let parts = target.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 2, !parts.contains("") else { return nil }
        let component = parts[0]
        let path = parts.dropFirst().joined(separator: ".")
        let laneIndex = parts.count >= 3 ? laneNames[parts[parts.count - 1]] : nil
        let parent = parts.dropFirst().dropLast().joined(separator: ".")

        func read(_ world: World, _ entity: Entity) -> (value: FieldValue, vector: Bool)? {
            guard let c = world.component(named: component, of: entity) else { return nil }
            if laneIndex != nil, let field = c.field(at: parent), let value = field.value {
                switch value {
                case .vec2, .vec3, .vec4: return (value, true)
                default: break
                }
            }
            guard let value = c.field(at: path)?.value else { return nil }
            return (value, false)
        }
        return FieldLane(
            get: { world, entity in
                guard let (value, vector) = read(world, entity) else { return nil }
                switch (value, vector, laneIndex ?? 0) {
                case (.float(let d), false, _): return Float(d)
                case (.int(let i), false, _): return Float(i)
                case (.vec2(let v), true, let i) where i < 2: return v[i]
                case (.vec3(let v), true, let i) where i < 3: return v[i]
                case (.vec4(let v), true, let i): return v[i]
                default: return nil
                }
            },
            set: { world, entity, newValue in
                guard let (value, vector) = read(world, entity) else { return }
                let i = laneIndex ?? 0
                switch (value, vector) {
                case (.float, false), (.int, false):
                    try? world.setField(path, of: component, for: entity, to: .float(Double(newValue)))
                case (.vec2(var v), true) where i < 2:
                    v[i] = newValue
                    try? world.setField(parent, of: component, for: entity, to: .vec2(v))
                case (.vec3(var v), true) where i < 3:
                    v[i] = newValue
                    try? world.setField(parent, of: component, for: entity, to: .vec3(v))
                case (.vec4(var v), true):
                    v[i] = newValue
                    try? world.setField(parent, of: component, for: entity, to: .vec4(v))
                default: break
                }
            })
    }

    private static func registerBuiltins() {
        guard !registeredBuiltins else { return }
        registeredBuiltins = true
        register(Transform.self, field: "position", \Transform.position)
        register(Transform.self, field: "scale", \Transform.scale)
        for (axis, name) in ["x", "y", "z"].enumerated() {
            table["Transform.rotation." + name] = FieldLane(get: { _, _ in nil }, set: { _, _, _ in }, rotationAxis: axis)
        }
        register(PointLight.self, field: "intensity", \PointLight.intensity)
        register(PointLight.self, field: "range", \PointLight.range)
        register(PointLight.self, field: "color", \PointLight.color)
        register(SpotLight.self, field: "intensity", \SpotLight.intensity)
        register(SpotLight.self, field: "range", \SpotLight.range)
        register(SpotLight.self, field: "innerConeAngle", \SpotLight.innerConeAngle)
        register(SpotLight.self, field: "outerConeAngle", \SpotLight.outerConeAngle)
        register(SpotLight.self, field: "color", \SpotLight.color)
        register(DirectionalLight.self, field: "intensity", \DirectionalLight.intensity)
        register(DirectionalLight.self, field: "color", \DirectionalLight.color)
        register(MeshRenderer.self, field: "tint", \MeshRenderer.tint)
        register(MeshRenderer.self, field: "opacity", \MeshRenderer.opacity)
        register(Camera.self, field: "fovY", \Camera.fovY)
        register(SceneEnvironment.self, field: "ambientIntensity", \SceneEnvironment.ambientIntensity)
        register(SceneEnvironment.self, field: "fogDensity", \SceneEnvironment.fogDensity)
        register(SceneEnvironment.self, field: "skyColor", \SceneEnvironment.skyColor)
        register(SceneEnvironment.self, field: "groundColor", \SceneEnvironment.groundColor)
        register(SceneEnvironment.self, field: "fogColor", \SceneEnvironment.fogColor)
    }
}
