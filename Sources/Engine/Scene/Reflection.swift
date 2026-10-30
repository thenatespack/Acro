import Foundation

// Component reflection for the editor inspector: enumerate a component's fields (names,
// kinds, current values, display hints) and set one by path, with no per-component code.
//
// ```swift
// for field in world.fields(of: "Light", for: entity) ?? [] {
//     // field.name "intensity", field.path "intensity", field.kind .float,
//     // field.value .float(2.5), field.hints.range 0...10
// }
// try world.setField("intensity", of: "Light", for: entity, to: .float(3))
// try world.setField("points.2", of: "Path", for: entity, to: .vec3(Vec3(1, 0, 0)))
// ```
//
// ## How: Codable, not a macro or Mirror
//
// Every component is already `Codable` (scene files need it), so reflection reuses that:
// - Reading runs the component's `encode(to:)` into a reflecting `Encoder`. Each field
//   arrives through a generic `encode<T>(_:forKey:)`, so the encoder knows its static type
//   and can tell a `Vec3` or `Quat` from an array of floats, an `Entity` from a struct, and a
//   `CaseIterable` enum (whose cases it lists) from a string, and nil optionals still report
//   their type through `encodeIfPresent`.
// - Writing encodes the component to an untyped JSON tree (`JSONValue`), replaces the value
//   at the path and decodes the component back, so it goes through the component's own
//   `init(from:)` and can't produce a value the type couldn't decode.
//
// Alternatives considered:
// - A `@Component` / `@Reflectable` macro generating field descriptors and typed setters.
//   It would be the fastest at runtime and could read hints from attributes, but needs a
//   macro target depending on swift-syntax: a package fetched from the network on the first
//   build (and on every clean CI build) and a large compile (minutes from source; prebuilt
//   only on some toolchains and hosts), plus another moving part on Linux and Windows. It
//   also wouldn't cover components that aren't annotated, which Codable does by construction.
// - `Mirror` for reading: no setter, no static types (a nil optional is just `nil`), and it
//   sees stored properties rather than the coded shape, so it can disagree with what files
//   store. Reading through Codable stays consistent with serialization by construction.
//
// Cost (release, M-series): reading builds a small tree, about a microsecond per field
// (50 µs for a 40-field component), fine for an inspector refreshing the selection every
// frame. Writing is a few JSON encodes and decodes of the component (~0.3 ms for the same
// one): fine for edits, even one per frame while dragging a slider, not for game logic.
//
// Paths are field names joined with "." and array indices as numbers (`"points.2.x"`), so
// field names can't contain ".". Descriptors are plain data (no closures), so the inspector
// can diff them between frames, bind widgets by path and record undo steps as
// (entity, component name, path, old value, new value).

/// What kind of value a field holds, which decides the inspector widget.
public enum FieldKind: Equatable, Sendable, CustomStringConvertible {
    case bool
    /// Any integer type. Values outside the field's type's range fail to set.
    case int
    /// `Float` or `Double`.
    case float
    case string
    case vec2
    case vec3
    case vec4
    /// A rotation. Show it as Euler angles with `Quat.eulerDegrees` / `Quat(eulerDegrees:)`.
    case quat
    /// A reference to another entity.
    case entity
    /// A `CaseIterable` enum without associated values; `cases` are the Swift case names.
    case enumeration(cases: [String])
    /// A nested struct (or a dictionary with string keys); its fields are the children.
    case structure(typeName: String)
    /// An array (or set); the elements are the children, named by index.
    case array
    /// A nil optional whose type can't be described without a value.
    case unknown

    public var description: String {
        switch self {
        case .bool: "bool"
        case .int: "int"
        case .float: "float"
        case .string: "string"
        case .vec2: "vec2"
        case .vec3: "vec3"
        case .vec4: "vec4"
        case .quat: "quat"
        case .entity: "entity"
        case .enumeration(let cases): "one of \(cases.joined(separator: ", "))"
        case .structure(let name): name
        case .array: "array"
        case .unknown: "unknown"
        }
    }
}

/// A field's value, and what `setField` takes.
public enum FieldValue: Equatable, Sendable {
    /// A nil optional (setting it makes the optional nil).
    case null
    case bool(Bool)
    case int(Int)
    case float(Double)
    case string(String)
    case vec2(Vec2)
    case vec3(Vec3)
    case vec4(Vec4)
    case quat(Quat)
    case entity(Entity)
    /// An enum case, by Swift case name.
    case enumCase(String)
}

/// How the inspector should present a field. Declared per component type in
/// `Component.fieldHints`; every property is optional.
public struct FieldHints: Equatable, Sendable {
    /// Bounds for a slider or a clamped number field.
    public var range: ClosedRange<Double>?
    /// Increment for dragging or stepping a number.
    public var step: Double?
    /// Show but don't allow editing (derived data, debugging values).
    public var readOnly: Bool
    /// Don't show the field.
    public var hidden: Bool
    /// Edit a `vec3` / `vec4` with a color picker (linear RGB(A)).
    public var color: Bool
    /// Label to show instead of the field name.
    public var displayName: String?
    /// Help text.
    public var tooltip: String?

    public init(range: ClosedRange<Double>? = nil, step: Double? = nil, readOnly: Bool = false, hidden: Bool = false,
                color: Bool = false, displayName: String? = nil, tooltip: String? = nil) {
        self.range = range
        self.step = step
        self.readOnly = readOnly
        self.hidden = hidden
        self.color = color
        self.displayName = displayName
        self.tooltip = tooltip
    }
}

/// One field of a component, with its current value.
public struct FieldDescriptor: Equatable, Sendable {
    /// The field's coding key, or its index in an array.
    public var name: String
    /// Names from the component down to this field, joined with "." (what `setField` takes).
    public var path: String
    public var kind: FieldKind
    /// The current value; nil for structures and arrays (see `children`).
    public var value: FieldValue?
    /// Whether the field is an optional (it can be set to `.null`).
    public var isOptional: Bool
    public var hints: FieldHints
    /// Fields of a structure, elements of an array.
    public var children: [FieldDescriptor]
}

extension Component {
    /// The component's fields, in coding order, with their current values.
    public func fields() -> [FieldDescriptor] {
        guard let root = try? ReflectionNode.reflect(self) else { return [] }
        return root.childDescriptors(path: "", hints: Self.fieldHints)
    }

    /// The field at `path` (`"position"`, `"points.2"`, `"settings.tint"`), or nil.
    public func field(at path: String) -> FieldDescriptor? {
        var fields = fields()
        var found: FieldDescriptor?
        for key in path.split(separator: ".", omittingEmptySubsequences: false) {
            guard let next = fields.first(where: { $0.name == key }) else { return nil }
            found = next
            fields = next.children
        }
        return found
    }

    /// Sets the field at `path` to `value` by re-decoding the component, so the result is
    /// always a value `init(from:)` accepts. `.int` and `.float` convert into each other
    /// (an `.int` field needs a whole number); an enum takes `.enumCase` or `.string`.
    /// Setting a field inside a nil optional struct isn't possible (there's no value to
    /// edit); set a leaf optional to a value directly. Throws `SceneError.noSuchField`,
    /// `SceneError.typeMismatch` or the `DecodingError` from decoding.
    public mutating func setField(_ path: String, to value: FieldValue) throws {
        let keys = path.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        let root = try ReflectionNode.reflect(self)
        guard let node = root.node(at: keys[...]) else { throw SceneError.noSuchField(path) }
        let replacement = try node.json(for: value, path: path)
        var json = try JSONValue.encoding(self)
        guard json.replace(at: keys[...], with: replacement) else { throw SceneError.noSuchField(path) }
        self = try json.decode(Self.self)
    }
}

extension World {
    /// `entity`'s component whose type has `componentName` `name`, or nil.
    public func component(named name: String, of entity: Entity) -> (any Component)? {
        guard isAlive(entity) else { return nil }
        return storeOrder.first { $0.componentType.componentName == name }?.component(of: entity)
    }

    /// The fields of `entity`'s component named `name`, or nil if it has none.
    public func fields(of name: String, for entity: Entity) -> [FieldDescriptor]? {
        component(named: name, of: entity)?.fields()
    }

    /// Sets a field of `entity`'s component named `name` (see `Component.setField`). The
    /// component is replaced immediately, also during queries.
    public func setField(_ path: String, of name: String, for entity: Entity, to value: FieldValue) throws {
        guard var component = component(named: name, of: entity) else { throw SceneError.noSuchComponent(name) }
        try component.setField(path, to: value)
        add(component, to: entity)
    }
}

// MARK: Euler angles for display

extension Quat {
    /// Rotation by `degrees.x` around X, then `degrees.y` around Y, then `degrees.z` around Z
    /// (fixed axes), the usual order for editing rotations as three numbers.
    public init(eulerDegrees degrees: Vec3) {
        let r = degrees * (Float.pi / 180)
        self = Quat(angle: r.z, axis: Vec3(0, 0, 1)) * Quat(angle: r.y, axis: Vec3(0, 1, 0)) * Quat(angle: r.x, axis: Vec3(1, 0, 0))
    }

    /// The angles `init(eulerDegrees:)` takes; y is in [-90, 90]. At y = ±90 (gimbal lock)
    /// x and z turn the same axis, and z is reported as 0.
    public var eulerDegrees: Vec3 {
        let m = normalized.matrix
        // Row-major names: rRC = row R, column C = m.cC[R].
        let r20 = m.c0.z, r21 = m.c1.z, r22 = m.c2.z, r10 = m.c0.y, r00 = m.c0.x
        let y = asinf(max(-1, min(1, -r20)))
        let x: Float, z: Float
        if abs(r20) < 0.99999 {
            x = atan2f(r21, r22)
            z = atan2f(r10, r00)
        } else {
            x = atan2f(-m.c2.y, m.c1.y)
            z = 0
        }
        return Vec3(x, y, z) * (180 / Float.pi)
    }
}

// MARK: Reflecting encoder

/// One field while reflecting: a leaf value, or a structure / array of children.
final class ReflectionNode {
    var kind: FieldKind = .unknown
    var value: FieldValue?
    var isOptional = false
    var children: [(key: String, node: ReflectionNode)] = []
    /// For enums: the cases, to encode the one `setField` picks.
    var enumValues: [any Encodable] = []

    static func reflect<T: Encodable>(_ value: T) throws -> ReflectionNode {
        let node = ReflectionNode()
        try node.fill(value)
        return node
    }

    func child(_ key: String) -> ReflectionNode {
        let node = ReflectionNode()
        children.append((key, node))
        return node
    }

    func fill<T: Encodable>(_ value: T) throws {
        if let (kind, leaf) = Self.leaf(value) {
            self.kind = kind
            self.value = leaf
        } else if let (names, values) = Self.enumCases(of: T.self) {
            kind = .enumeration(cases: names)
            self.value = .enumCase(String(describing: value))
            enumValues = values
        } else {
            kind = .structure(typeName: String(describing: T.self))
            try value.encode(to: ReflectionEncoder(node: self))
        }
    }

    /// A nil optional of type `T`.
    func fillNil<T>(_: T.Type) {
        isOptional = true
        value = .null
        if let kind = Self.leafKind(T.self) {
            self.kind = kind
        } else if let (names, values) = Self.enumCases(of: T.self) {
            kind = .enumeration(cases: names)
            enumValues = values
        } else {
            kind = .unknown
        }
    }

    func fillOptional<T: Encodable>(_ value: T?) throws {
        if let value { try fill(value) } else { fillNil(T.self) }
        isOptional = true
    }

    private static func leaf(_ value: Any) -> (FieldKind, FieldValue)? {
        switch value {
        case let v as Bool: (.bool, .bool(v))
        case let v as String: (.string, .string(v))
        case let v as Float: (.float, .float(Double(v)))
        case let v as Double: (.float, .float(v))
        case let v as any BinaryInteger: (.int, .int(clampedInt(v)))
        case let v as Vec2: (.vec2, .vec2(v))
        case let v as Vec3: (.vec3, .vec3(v))
        case let v as Vec4: (.vec4, .vec4(v))
        case let v as Quat: (.quat, .quat(v))
        case let v as Entity: (.entity, .entity(v))
        default: nil
        }
    }

    private static func clampedInt<I: BinaryInteger>(_ v: I) -> Int { Int(clamping: v) }

    private static func leafKind(_ type: Any.Type) -> FieldKind? {
        switch type {
        case is Bool.Type: .bool
        case is String.Type: .string
        case is Float.Type, is Double.Type: .float
        case is any BinaryInteger.Type: .int
        case is Vec2.Type: .vec2
        case is Vec3.Type: .vec3
        case is Vec4.Type: .vec4
        case is Quat.Type: .quat
        case is Entity.Type: .entity
        default: nil
        }
    }

    private static func enumCases(of type: Any.Type) -> ([String], [any Encodable])? {
        guard let iterable = type as? any CaseIterable.Type else { return nil }
        let values = allCases(iterable)
        let encodable = values.compactMap { $0 as? any Encodable }
        guard !values.isEmpty, encodable.count == values.count else { return nil }
        return (values.map { String(describing: $0) }, encodable)
    }

    private static func allCases<E: CaseIterable>(_: E.Type) -> [Any] { E.allCases.map { $0 } }

    // MARK: Descriptors and setting

    func childDescriptors(path: String, hints: [String: FieldHints]) -> [FieldDescriptor] {
        children.map { key, node in
            let childPath = path.isEmpty ? key : path + "." + key
            return FieldDescriptor(
                name: key, path: childPath, kind: node.kind,
                value: node.value, isOptional: node.isOptional,
                hints: Self.hints(for: childPath, in: hints),
                children: node.childDescriptors(path: childPath, hints: hints))
        }
    }

    private static func hints(for path: String, in hints: [String: FieldHints]) -> FieldHints {
        if hints.isEmpty { return FieldHints() }
        if let exact = hints[path] { return exact }
        let wildcard = path.split(separator: ".").map { $0.allSatisfy(\.isNumber) ? "*" : String($0) }.joined(separator: ".")
        return hints[wildcard] ?? FieldHints()
    }

    func node(at keys: ArraySlice<String>) -> ReflectionNode? {
        guard let key = keys.first else { return self }
        return children.first { $0.key == key }?.node.node(at: keys.dropFirst())
    }

    /// `value` as the JSON `init(from:)` expects for this field.
    func json(for value: FieldValue, path: String) throws -> JSONValue {
        let mismatch = SceneError.typeMismatch(path: path, expected: (isOptional ? "optional " : "") + kind.description)
        func floats(_ scalars: [Float]) -> JSONValue { .array(scalars.map { .double(Double($0)) }) }
        switch (kind, value) {
        case (_, .null): guard isOptional else { throw mismatch }; return .null
        case (.bool, .bool(let b)): return .bool(b)
        case (.int, .int(let i)): return .int(Int64(i))
        case (.int, .float(let d)):
            guard let i = Int64(exactly: d) else { throw mismatch }
            return .int(i)
        case (.float, .float(let d)): return .double(d)
        case (.float, .int(let i)): return .double(Double(i))
        case (.string, .string(let s)): return .string(s)
        case (.vec2, .vec2(let v)): return floats([v.x, v.y])
        case (.vec3, .vec3(let v)): return floats([v.x, v.y, v.z])
        case (.vec4, .vec4(let v)): return floats([v.x, v.y, v.z, v.w])
        case (.quat, .quat(let q)): return floats([q.x, q.y, q.z, q.w])
        case (.entity, .entity(let e)): return .entity(e)
        case (.enumeration(let cases), .enumCase(let name)), (.enumeration(let cases), .string(let name)):
            guard let i = cases.firstIndex(of: name) else { throw mismatch }
            return try JSONValue.encoding(enumValues[i])
        default: throw mismatch
        }
    }
}

extension JSONValue {
    /// Replaces the value at `keys` (object keys and array indices), adding a missing key to
    /// an object (an omitted nil optional). False if the path doesn't exist.
    mutating func replace(at keys: ArraySlice<String>, with value: JSONValue) -> Bool {
        guard let key = keys.first else {
            self = value
            return true
        }
        switch self {
        case .object(var object):
            var child = object[key] ?? .null
            guard child.replace(at: keys.dropFirst(), with: value) else { return false }
            object[key] = child
            self = .object(object)
            return true
        case .array(var array):
            guard let i = Int(key), array.indices.contains(i), array[i].replace(at: keys.dropFirst(), with: value) else { return false }
            self = .array(array)
            return true
        default:
            return false
        }
    }
}

/// Encoder that records what it's given into a `ReflectionNode` tree.
private struct ReflectionEncoder: Encoder {
    let node: ReflectionNode
    var codingPath: [any CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key: CodingKey>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        if case .structure = node.kind {} else { node.kind = .structure(typeName: "") }
        return KeyedEncodingContainer(KeyedReflection<Key>(node: node))
    }

    func unkeyedContainer() -> any UnkeyedEncodingContainer {
        node.kind = .array
        return UnkeyedReflection(node: node)
    }

    func singleValueContainer() -> any SingleValueEncodingContainer {
        SingleValueReflection(node: node)
    }
}

private struct KeyedReflection<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let node: ReflectionNode
    var codingPath: [any CodingKey] { [] }

    mutating func encodeNil(forKey key: Key) throws { node.child(key.stringValue).fillNil(Never.self) }
    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: Bool, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: String, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: Double, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: Float, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: Int, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: Int8, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: Int16, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: Int32, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: Int64, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: UInt, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: UInt8, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: UInt16, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: UInt32, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }
    mutating func encode(_ value: UInt64, forKey key: Key) throws { try node.child(key.stringValue).fill(value) }

    // Nil optionals are reported (with their type) instead of being skipped.
    mutating func encodeIfPresent<T: Encodable>(_ value: T?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: Bool?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: String?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: Double?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: Float?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: Int8?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: Int16?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: Int32?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: Int64?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: UInt?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }
    mutating func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws { try node.child(key.stringValue).fillOptional(value) }

    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let child = node.child(key.stringValue)
        child.kind = .structure(typeName: "")
        return KeyedEncodingContainer(KeyedReflection<NestedKey>(node: child))
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
        let child = node.child(key.stringValue)
        child.kind = .array
        return UnkeyedReflection(node: child)
    }

    mutating func superEncoder() -> any Encoder { ReflectionEncoder(node: node.child("super")) }
    mutating func superEncoder(forKey key: Key) -> any Encoder { ReflectionEncoder(node: node.child(key.stringValue)) }
}

private struct UnkeyedReflection: UnkeyedEncodingContainer {
    let node: ReflectionNode
    var codingPath: [any CodingKey] { [] }
    var count: Int { node.children.count }

    private func next() -> ReflectionNode { node.child(String(node.children.count)) }

    mutating func encodeNil() throws { next().fillNil(Never.self) }
    mutating func encode<T: Encodable>(_ value: T) throws { try next().fill(value) }

    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        let child = next()
        child.kind = .structure(typeName: "")
        return KeyedEncodingContainer(KeyedReflection<NestedKey>(node: child))
    }

    mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
        let child = next()
        child.kind = .array
        return UnkeyedReflection(node: child)
    }

    mutating func superEncoder() -> any Encoder { ReflectionEncoder(node: next()) }
}

private struct SingleValueReflection: SingleValueEncodingContainer {
    let node: ReflectionNode
    var codingPath: [any CodingKey] { [] }

    mutating func encodeNil() throws { node.fillNil(Never.self) }
    mutating func encode<T: Encodable>(_ value: T) throws { try node.fill(value) }
}
