#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

/// A value flowing along a visual script's data wires. Numbers convert into each other,
/// everything converts to text, and a pin of a given type gets its input through
/// `converted(to:)`, so graphs need no explicit conversion nodes.
public enum VisualScriptValue: Equatable, Sendable, CustomStringConvertible {
    case none
    case bool(Bool)
    case int(Int)
    case float(Double)
    case string(String)
    case vec2(Vec2)
    case vec3(Vec3)
    case vec4(Vec4)
    case quat(Quat)
    case entity(Entity)
    case array([VisualScriptValue])
    case map([String: VisualScriptValue])

    /// The zero value of `type` (0, "", false, zero vectors, identity rotation, no entity).
    public static func zero(_ type: VisualScriptType) -> VisualScriptValue {
        switch type {
        case .exec, .any: .none
        case .bool: .bool(false)
        case .int: .int(0)
        case .float: .float(0)
        case .string, .asset: .string("")
        case .vec2: .vec2(.zero)
        case .vec3: .vec3(.zero)
        case .vec4: .vec4(.zero)
        case .color: .vec4(Vec4(1, 1, 1, 1))
        case .quat: .quat(.identity)
        case .entity: .entity(.invalid)
        case .array: .array([])
        case .map: .map([:])
        }
    }

    /// The type this value naturally has.
    public var type: VisualScriptType {
        switch self {
        case .none: .any
        case .bool: .bool
        case .int: .int
        case .float: .float
        case .string: .string
        case .vec2: .vec2
        case .vec3: .vec3
        case .vec4: .vec4
        case .quat: .quat
        case .entity: .entity
        case .array: .array
        case .map: .map
        }
    }

    // MARK: Reading

    public var asDouble: Double {
        switch self {
        case .bool(let b): b ? 1 : 0
        case .int(let i): Double(i)
        case .float(let f): f
        case .string(let s): Double(s.trimmingCharacters(in: .whitespaces)) ?? 0
        case .vec2(let v): Double(v.x)
        case .vec3(let v): Double(v.x)
        case .vec4(let v): Double(v.x)
        case .array(let a): Double(a.count)
        default: 0
        }
    }

    public var asFloat: Float { Float(asDouble) }

    public var asInt: Int {
        switch self {
        case .int(let i): return i
        default:
            let d = asDouble
            guard d.isFinite else { return 0 }
            return Int(max(min(d.rounded(.towardZero), 9.0e18), -9.0e18))
        }
    }

    public var asBool: Bool {
        switch self {
        case .none: false
        case .bool(let b): b
        case .int(let i): i != 0
        case .float(let f): f != 0
        case .string(let s): !s.isEmpty && s != "false" && s != "0"
        case .entity(let e): e != .invalid
        case .array(let a): !a.isEmpty
        case .map(let m): !m.isEmpty
        default: true
        }
    }

    public var asString: String {
        switch self {
        case .none: ""
        case .bool(let b): b ? "true" : "false"
        case .int(let i): String(i)
        case .float(let f): Self.format(f)
        case .string(let s): s
        case .vec2(let v): "(\(Self.format(Double(v.x))), \(Self.format(Double(v.y))))"
        case .vec3(let v): "(\(Self.format(Double(v.x))), \(Self.format(Double(v.y))), \(Self.format(Double(v.z))))"
        case .vec4(let v): "(\(Self.format(Double(v.x))), \(Self.format(Double(v.y))), \(Self.format(Double(v.z))), \(Self.format(Double(v.w))))"
        case .quat(let q): "rotation" + VisualScriptValue.vec3(q.eulerDegrees).asString
        case .entity(let e): e == .invalid ? "none" : "entity \(e.index)"
        case .array(let a): "[" + a.map(\.asString).joined(separator: ", ") + "]"
        case .map(let m): "{" + m.keys.sorted().map { "\($0): \(m[$0]!.asString)" }.joined(separator: ", ") + "}"
        }
    }

    public var description: String { asString }

    static func format(_ d: Double) -> String {
        if d.isFinite, d == d.rounded(), abs(d) < 1e15 { return String(Int(d)) }
        let s = String(format: "%.4f", d)
        var trimmed = s
        while trimmed.hasSuffix("0") { trimmed.removeLast() }
        if trimmed.hasSuffix(".") { trimmed.removeLast() }
        return trimmed
    }

    public var asVec2: Vec2 {
        switch self {
        case .vec2(let v): v
        case .vec3(let v): Vec2(v.x, v.y)
        case .vec4(let v): Vec2(v.x, v.y)
        case .int, .float, .bool: Vec2(repeating: asFloat)
        case .array(let a): Vec2(a.count > 0 ? a[0].asFloat : 0, a.count > 1 ? a[1].asFloat : 0)
        default: .zero
        }
    }

    public var asVec3: Vec3 {
        switch self {
        case .vec3(let v): v
        case .vec2(let v): Vec3(v.x, v.y, 0)
        case .vec4(let v): Vec3(v.x, v.y, v.z)
        case .quat(let q): q.eulerDegrees
        case .int, .float, .bool: Vec3(repeating: asFloat)
        case .array(let a): Vec3(a.count > 0 ? a[0].asFloat : 0, a.count > 1 ? a[1].asFloat : 0, a.count > 2 ? a[2].asFloat : 0)
        default: .zero
        }
    }

    public var asVec4: Vec4 {
        switch self {
        case .vec4(let v): v
        case .vec3(let v): Vec4(v.x, v.y, v.z, 1)
        case .vec2(let v): Vec4(v.x, v.y, 0, 1)
        case .quat(let q): q.vector
        case .int, .float, .bool: Vec4(repeating: asFloat)
        case .array(let a):
            Vec4(a.count > 0 ? a[0].asFloat : 0, a.count > 1 ? a[1].asFloat : 0, a.count > 2 ? a[2].asFloat : 0, a.count > 3 ? a[3].asFloat : 1)
        case .string(let s): Self.color(hex: s) ?? Vec4(1, 1, 1, 1)
        default: .zero
        }
    }

    /// A rotation; a vec3 is read as Euler degrees.
    public var asQuat: Quat {
        switch self {
        case .quat(let q): q
        case .vec3(let v): Quat(eulerDegrees: v)
        case .vec4(let v): Quat(vector: v)
        case .array(let a) where a.count == 3: Quat(eulerDegrees: asVec3)
        default: .identity
        }
    }

    public var asEntity: Entity {
        if case .entity(let e) = self { return e }
        return .invalid
    }

    public var asArray: [VisualScriptValue] {
        switch self {
        case .array(let a): a
        case .none: []
        case .map(let m): m.keys.sorted().map { m[$0]! }
        default: [self]
        }
    }

    public var asMap: [String: VisualScriptValue] {
        if case .map(let m) = self { return m }
        return [:]
    }

    /// This value as a pin of type `type` reads it.
    public func converted(to type: VisualScriptType) -> VisualScriptValue {
        switch type {
        case .exec, .any: self
        case .bool: .bool(asBool)
        case .int: .int(asInt)
        case .float: .float(asDouble)
        case .string, .asset: .string(asString)
        case .vec2: .vec2(asVec2)
        case .vec3: .vec3(asVec3)
        case .vec4, .color: .vec4(asVec4)
        case .quat: .quat(asQuat)
        case .entity: .entity(asEntity)
        case .array: .array(asArray)
        case .map: .map(asMap)
        }
    }

    /// "#RRGGBB" or "#RRGGBBAA" as 0...1 components.
    static func color(hex: String) -> Vec4? {
        var s = hex.trimmingCharacters(in: .whitespaces)
        guard s.hasPrefix("#") else { return nil }
        s.removeFirst()
        guard s.count == 6 || s.count == 8, let v = UInt32(s, radix: 16) else { return nil }
        let full = s.count == 6 ? (v << 8) | 0xFF : v
        return Vec4(Float((full >> 24) & 0xFF) / 255, Float((full >> 16) & 0xFF) / 255, Float((full >> 8) & 0xFF) / 255,
                    Float(full & 0xFF) / 255)
    }

    // MARK: JSON

    /// A literal from a file (a node's `inputs`, a variable's default), read as `type`: numbers,
    /// strings, booleans, `[x, y, z]` vectors, "#RRGGBB" colors, Euler degrees for rotations.
    /// nil when it doesn't fit (`isLiteral(_:of:)` tells validation).
    public init?(json: JSONValue, as type: VisualScriptType) {
        switch (json, type) {
        case (.null, _): return nil
        case (_, .exec): return nil
        case (_, .entity): return nil
        case (.bool(let b), .bool), (.bool(let b), .any): self = .bool(b)
        case (.int(let i), .int): self = .int(Int(i))
        case (.int(let i), .float): self = .float(Double(i))
        case (.double(let d), .float): self = .float(d)
        case (.double(let d), .int): self = .int(Int(d))
        case (.int(let i), .any): self = .int(Int(i))
        case (.double(let d), .any): self = .float(d)
        case (.int, .bool), (.double, .bool): self = .bool(Self.number(json) != 0)
        case (.string(let s), .string), (.string(let s), .asset), (.string(let s), .any): self = .string(s)
        case (.int, .string), (.double, .string), (.bool, .string): self = .string(Self.fromJSON(json).asString)
        case (.string(let s), .color), (.string(let s), .vec4):
            guard let c = Self.color(hex: s) else { return nil }
            self = .vec4(c)
        case (.array(let items), .vec2), (.array(let items), .vec3), (.array(let items), .vec4), (.array(let items), .color),
             (.array(let items), .quat):
            let numbers = items.compactMap(Self.numberOrNil)
            guard numbers.count == items.count, !numbers.isEmpty else { return nil }
            let f = numbers.map { Float($0) }
            func at(_ i: Int, _ fallback: Float) -> Float { i < f.count ? f[i] : fallback }
            switch type {
            case .vec2: self = .vec2(Vec2(at(0, 0), at(1, 0)))
            case .vec3: self = .vec3(Vec3(at(0, 0), at(1, 0), at(2, 0)))
            case .quat: self = f.count == 4 ? .quat(Quat(at(0, 0), at(1, 0), at(2, 0), at(3, 1))) : .quat(Quat(eulerDegrees: Vec3(at(0, 0), at(1, 0), at(2, 0))))
            default: self = .vec4(Vec4(at(0, 0), at(1, 0), at(2, 0), at(3, 1)))
            }
        case (.int, .vec2), (.double, .vec2): self = .vec2(Vec2(repeating: Float(Self.number(json))))
        case (.int, .vec3), (.double, .vec3): self = .vec3(Vec3(repeating: Float(Self.number(json))))
        case (.array(let items), .array): self = .array(items.map(Self.fromJSON))
        case (.array(let items), .any): self = .array(items.map(Self.fromJSON))
        case (.object(let fields), .map), (.object(let fields), .any): self = .map(fields.mapValues(Self.fromJSON))
        default: return nil
        }
    }

    /// Whether `json` is a valid literal for a pin of `type`.
    public static func isLiteral(_ json: JSONValue, of type: VisualScriptType) -> Bool {
        if case .null = json { return true }
        return VisualScriptValue(json: json, as: type) != nil
    }

    /// A value from untyped JSON (arrays and objects become arrays and maps).
    public static func fromJSON(_ json: JSONValue) -> VisualScriptValue {
        switch json {
        case .null: .none
        case .bool(let b): .bool(b)
        case .int(let i): .int(Int(i))
        case .double(let d): .float(d)
        case .string(let s): .string(s)
        case .array(let a): .array(a.map(fromJSON))
        case .object(let o): .map(o.mapValues(fromJSON))
        case .entity(let e): .entity(e)
        }
    }

    /// The value as JSON (vectors as arrays, entities as null).
    public var json: JSONValue {
        func arr(_ f: [Float]) -> JSONValue { .array(f.map { .double(Double($0)) }) }
        switch self {
        case .none, .entity: return .null
        case .bool(let b): return .bool(b)
        case .int(let i): return .int(Int64(i))
        case .float(let d): return .double(d)
        case .string(let s): return .string(s)
        case .vec2(let v): return arr([v.x, v.y])
        case .vec3(let v): return arr([v.x, v.y, v.z])
        case .vec4(let v): return arr([v.x, v.y, v.z, v.w])
        case .quat(let q): return arr([q.eulerDegrees.x, q.eulerDegrees.y, q.eulerDegrees.z])
        case .array(let a): return .array(a.map(\.json))
        case .map(let m): return .object(m.mapValues(\.json))
        }
    }

    private static func numberOrNil(_ json: JSONValue) -> Double? {
        switch json {
        case .int(let i): Double(i)
        case .double(let d): d
        default: nil
        }
    }

    private static func number(_ json: JSONValue) -> Double { numberOrNil(json) ?? 0 }

    // MARK: Reflection

    /// A component field's value (see `FieldValue`).
    public init(field: FieldValue) {
        switch field {
        case .null: self = .none
        case .bool(let b): self = .bool(b)
        case .int(let i): self = .int(i)
        case .float(let d): self = .float(d)
        case .string(let s): self = .string(s)
        case .vec2(let v): self = .vec2(v)
        case .vec3(let v): self = .vec3(v)
        case .vec4(let v): self = .vec4(v)
        case .quat(let q): self = .quat(q)
        case .entity(let e): self = .entity(e)
        case .enumCase(let c): self = .string(c)
        }
    }

    /// The `FieldValue` a field of `kind` takes from this value.
    public func fieldValue(for kind: FieldKind) -> FieldValue {
        switch kind {
        case .bool: .bool(asBool)
        case .int: .int(asInt)
        case .float: .float(asDouble)
        case .string: .string(asString)
        case .vec2: .vec2(asVec2)
        case .vec3: .vec3(asVec3)
        case .vec4: .vec4(asVec4)
        case .quat: .quat(asQuat)
        case .entity: .entity(asEntity)
        case .enumeration: .enumCase(asString)
        default: self == .none ? .null : .string(asString)
        }
    }

    /// The pin type for a reflected field of `kind`.
    public static func type(for kind: FieldKind, color: Bool = false) -> VisualScriptType? {
        switch kind {
        case .bool: .bool
        case .int: .int
        case .float: .float
        case .string, .enumeration: .string
        case .vec2: .vec2
        case .vec3: color ? .color : .vec3
        case .vec4: color ? .color : .vec4
        case .quat: .quat
        case .entity: .entity
        default: nil
        }
    }
}
