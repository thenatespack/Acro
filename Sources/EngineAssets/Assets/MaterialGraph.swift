import Foundation
import EngineCore
import EngineScene

// A material's node graph: the `graph` key of a `.material` file (JSON, every key optional).
// `MaterialFileImporter` resolves its textures and compiles it (`MaterialGraphCompiler`) into a
// variant of the lit mesh shader for Metal and Vulkan; the material's own fixed PBR fields are
// then ignored apart from `alphaMode`, `alphaCutoff`, `doubleSided`, the sampler settings and
// `emissive` (unlit amount).
//
// ```json
// {
//   "shading": "pbr",
//   "graph": {
//     "nodes": [
//       {"id": "flow", "type": "scrollUV", "speed": [0.05, 0.02]},
//       {"id": "n", "type": "noise", "kind": "fbm", "uv": "flow", "scale": 6, "octaves": 4},
//       {"id": "hot", "type": "color", "value": [4, 1.2, 0.1, 1]},
//       {"id": "glow", "type": "math", "op": "multiply", "a": "hot", "b": "n"}
//     ],
//     "output": {"baseColor": [0.05, 0.02, 0.02], "emissive": "glow.rgb", "roughness": 0.8}
//   }
// }
// ```
//
// A node is an object with an `id`, a `type` and that type's keys (see
// `MaterialGraphNodeType.catalog`). An input key holds either a constant (a number or an array
// of 2-4 numbers) or a link: "nodeId", optionally with a swizzle ("tex.rgb", "n.x"). Values of
// a different size convert as in GLSL: a scalar fills every component, extra components are
// dropped, missing ones are 0 (alpha 1). Constants are uploaded as data, so changing one doesn't
// recompile the shader. `output` maps the PBR inputs (`MaterialGraph.outputs`) the same way.

/// A material's node graph (see the file comment above).
public struct MaterialGraph: Equatable, Sendable, Codable {
    public var nodes: [MaterialGraphNode]
    /// PBR input name ("baseColor", "normal", …) → link or constant. Missing ones take
    /// `MaterialGraph.outputs`' defaults.
    public var output: [String: JSONValue]

    public init(nodes: [MaterialGraphNode] = [], output: [String: JSONValue] = [:]) {
        self.nodes = nodes
        self.output = output
    }

    /// The PBR inputs a graph can drive, in order, with their sizes and defaults.
    public static let outputs: [(name: String, size: Int, defaultValue: [Float])] = [
        ("baseColor", 3, [0.8, 0.8, 0.8]),
        ("opacity", 1, [1]),
        ("normal", 3, [0, 0, 1]),
        ("metallic", 1, [0]),
        ("roughness", 1, [0.5]),
        ("emissive", 3, [0, 0, 0]),
        ("occlusion", 1, [1]),
    ]

    /// The node with `id`.
    public func node(_ id: String) -> MaterialGraphNode? { nodes.first { $0.id == id } }

    public func index(of id: String) -> Int? { nodes.firstIndex { $0.id == id } }

    /// An id not used by any node: `base`, else `base2`, `base3`, …
    public func uniqueID(_ base: String) -> String {
        let base = base.isEmpty ? "node" : base
        if node(base) == nil { return base }
        var n = 2
        while node("\(base)\(n)") != nil { n += 1 }
        return "\(base)\(n)"
    }

    private enum CodingKeys: String, CodingKey { case nodes, output }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nodes = try c.decodeIfPresent([MaterialGraphNode].self, forKey: .nodes) ?? []
        output = try c.decodeIfPresent([String: JSONValue].self, forKey: .output) ?? [:]
    }
}

/// One node: `id`, `type`, an optional editor `position` and the type's other keys in `fields`.
public struct MaterialGraphNode: Equatable, Sendable, Codable {
    public var id: String
    public var type: String
    /// Where the node sits on the Material Builder's canvas (nil: laid out automatically).
    public var position: Vec2?
    /// Inputs (constants or links) and settings, by key.
    public var fields: [String: JSONValue]

    public init(id: String, type: String, position: Vec2? = nil, fields: [String: JSONValue] = [:]) {
        self.id = id
        self.type = type
        self.position = position
        self.fields = fields
    }

    public subscript(key: String) -> JSONValue? {
        get { fields[key] }
        set { fields[key] = newValue }
    }

    /// The node ids this node's inputs link to.
    public var links: [String] {
        let inputs = MaterialGraphNodeType.catalog[type].map { Set($0.inputs.map(\.name)) }
        return fields.compactMap { key, value in
            if let inputs, !inputs.contains(key) { return nil }
            guard case .string(let s) = value else { return nil }
            return MaterialGraphLink(s)?.node
        }.sorted()
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: NodeKey.self)
        var fields: [String: JSONValue] = [:]
        var id = "", type = ""
        var position: Vec2?
        for key in c.allKeys {
            switch key.stringValue {
            case "id": id = (try? c.decode(String.self, forKey: key)) ?? ""
            case "type": type = (try? c.decode(String.self, forKey: key)) ?? ""
            case "position": position = try? c.decode(Vec2.self, forKey: key)
            default: fields[key.stringValue] = try c.decode(JSONValue.self, forKey: key)
            }
        }
        self.init(id: id, type: type, position: position, fields: fields)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: NodeKey.self)
        try c.encode(id, forKey: NodeKey("id"))
        try c.encode(type, forKey: NodeKey("type"))
        try c.encodeIfPresent(position, forKey: NodeKey("position"))
        for (key, value) in fields where !["id", "type", "position"].contains(key) {
            try c.encode(value, forKey: NodeKey(key))
        }
    }
}

private struct NodeKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

/// A link to a node's output: "nodeId" or "nodeId.swizzle" (1-4 of xyzw or rgba).
public struct MaterialGraphLink: Equatable, Sendable {
    public var node: String
    /// Component indices (nil: the whole output).
    public var swizzle: [Int]?

    public init(node: String, swizzle: [Int]? = nil) {
        self.node = node
        self.swizzle = swizzle
    }

    /// Parses a link string; nil for an empty one. A suffix that isn't a swizzle is part of the id.
    public init?(_ string: String) {
        let s = string.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }
        if let dot = s.lastIndex(of: "."), let swizzle = Self.parseSwizzle(String(s[s.index(after: dot)...])) {
            node = String(s[..<dot])
            self.swizzle = swizzle
        } else {
            node = s
            swizzle = nil
        }
    }

    static func parseSwizzle(_ s: String) -> [Int]? {
        guard (1...4).contains(s.count) else { return nil }
        let xyzw = "xyzw", rgba = "rgba"
        var result: [Int] = []
        for ch in s {
            if let i = xyzw.firstIndex(of: ch) { result.append(xyzw.distance(from: xyzw.startIndex, to: i)) }
            else if let i = rgba.firstIndex(of: ch) { result.append(rgba.distance(from: rgba.startIndex, to: i)) }
            else { return nil }
        }
        return result
    }

    public var description: String {
        guard let swizzle else { return node }
        return node + "." + String(swizzle.map { Array("xyzw")[$0] })
    }
}

/// What the Material Builder and the compiler know about a node type.
public struct MaterialGraphNodeType: Sendable {
    /// An input: a link or a constant of `size` components.
    public struct Input: Sendable {
        public var name: String
        /// 1-4, or 0 when it takes the size of whatever is connected (math, blend).
        public var size: Int
        public var defaultValue: [Float]
        /// Linked by default to this built-in (`uv`, `normal`) when unset, instead of `defaultValue`.
        public var defaultLink: String?
        public var tooltip: String
        public init(_ name: String, size: Int, _ defaultValue: [Float], defaultLink: String? = nil, tooltip: String = "") {
            self.name = name
            self.size = size
            self.defaultValue = defaultValue
            self.defaultLink = defaultLink
            self.tooltip = tooltip
        }
    }

    /// A setting: a choice from `options`, an asset path, a whole number or a flag.
    public struct Setting: Sendable {
        public enum Kind: Sendable { case choice([String]), texture, integer(ClosedRange<Int>), flag }
        public var name: String
        public var kind: Kind
        public var defaultValue: JSONValue
        public var tooltip: String
        public init(_ name: String, _ kind: Kind, _ defaultValue: JSONValue, tooltip: String = "") {
            self.name = name
            self.kind = kind
            self.defaultValue = defaultValue
            self.tooltip = tooltip
        }
    }

    public var name: String
    public var category: String
    public var summary: String
    public var inputs: [Input]
    public var settings: [Setting]
    /// The output's size, or 0 for "the widest input" (math, blend).
    public var outputSize: Int

    public func input(_ name: String) -> Input? { inputs.first { $0.name == name } }
    public func setting(_ name: String) -> Setting? { settings.first { $0.name == name } }

    public static let mathOps = ["add", "subtract", "multiply", "divide", "min", "max", "power", "mod", "step", "dot",
                                 "length", "normalize", "sin", "cos", "abs", "floor", "fract", "sqrt", "oneMinus",
                                 "negate", "saturate", "clamp", "lerp", "smoothstep"]
    public static let blendModes = ["mix", "multiply", "add", "subtract", "screen", "overlay"]
    public static let noiseKinds = ["value", "fbm", "cells"]

    /// Every node type, by name.
    public static let catalog: [String: MaterialGraphNodeType] = Dictionary(uniqueKeysWithValues: all.map { ($0.name, $0) })

    /// Every node type, in menu order.
    public static let all: [MaterialGraphNodeType] = [
        // Inputs
        .init(name: "color", category: "Input", summary: "A constant linear RGBA color",
              inputs: [Input("value", size: 4, [1, 1, 1, 1])], settings: [], outputSize: 4),
        .init(name: "value", category: "Input", summary: "A constant number",
              inputs: [Input("value", size: 1, [0])], settings: [], outputSize: 1),
        .init(name: "vector", category: "Input", summary: "A constant vector (x, y, z, w)",
              inputs: [Input("value", size: 4, [0, 0, 0, 0])], settings: [], outputSize: 4),
        .init(name: "uv", category: "Input", summary: "The mesh's texture coordinates x scale + offset",
              inputs: [Input("scale", size: 2, [1, 1]), Input("offset", size: 2, [0, 0])], settings: [], outputSize: 2),
        .init(name: "position", category: "Input", summary: "World-space position (meters)", inputs: [], settings: [], outputSize: 3),
        .init(name: "normal", category: "Input", summary: "World-space surface normal", inputs: [], settings: [], outputSize: 3),
        .init(name: "viewDir", category: "Input", summary: "World-space direction from the surface to the camera",
              inputs: [], settings: [], outputSize: 3),
        .init(name: "vertexColor", category: "Input", summary: "Vertex color x the MeshRenderer's tint (already applied to baseColor)",
              inputs: [], settings: [], outputSize: 4),
        .init(name: "time", category: "Input", summary: "Seconds of play time x speed",
              inputs: [Input("speed", size: 1, [1])], settings: [], outputSize: 1),
        // Textures
        .init(name: "texture", category: "Texture", summary: "Samples an image or .proctex (RGBA; normal maps unpacked to -1...1)",
              inputs: [Input("uv", size: 2, [0, 0], defaultLink: "uv")],
              settings: [Setting("texture", .texture, .string(""), tooltip: "An image or .proctex under Assets/, or asset:<id>"),
                         Setting("normalMap", .flag, .bool(false), tooltip: "Unpack RGB from 0...1 to a -1...1 tangent-space normal")],
              outputSize: 4),
        .init(name: "triplanar", category: "Texture", summary: "Projects a texture along the world X, Y and Z axes, blended by the normal",
              inputs: [Input("scale", size: 1, [0.5], tooltip: "Repeats per meter"),
                       Input("sharpness", size: 1, [4], tooltip: "Higher: harder transitions between the projections")],
              settings: [Setting("texture", .texture, .string(""), tooltip: "An image or .proctex under Assets/, or asset:<id>")],
              outputSize: 4),
        .init(name: "noise", category: "Texture", summary: "Procedural noise 0...1: value, fractal (fbm) or cells (Voronoi distance)",
              inputs: [Input("uv", size: 2, [0, 0], defaultLink: "uv"), Input("scale", size: 1, [8])],
              settings: [Setting("kind", .choice(noiseKinds), .string("value")),
                         Setting("octaves", .integer(1...8), .int(4), tooltip: "Layers of fbm noise")],
              outputSize: 1),
        // UV
        .init(name: "scrollUV", category: "UV", summary: "UV + speed x time",
              inputs: [Input("uv", size: 2, [0, 0], defaultLink: "uv"), Input("speed", size: 2, [0.1, 0])], settings: [], outputSize: 2),
        .init(name: "rotateUV", category: "UV", summary: "UV rotated about center by angle + speed x time (radians)",
              inputs: [Input("uv", size: 2, [0, 0], defaultLink: "uv"), Input("angle", size: 1, [0]), Input("speed", size: 1, [0]),
                       Input("center", size: 2, [0.5, 0.5])], settings: [], outputSize: 2),
        // Math
        .init(name: "math", category: "Math", summary: "a (op) b; clamp, lerp and smoothstep also use c",
              inputs: [Input("a", size: 0, [0]), Input("b", size: 0, [0]), Input("c", size: 0, [0])],
              settings: [Setting("op", .choice(mathOps), .string("add"))], outputSize: 0),
        .init(name: "blend", category: "Math", summary: "Blends b over a with a mode, by factor",
              inputs: [Input("a", size: 0, [0.5, 0.5, 0.5]), Input("b", size: 0, [0.5, 0.5, 0.5]), Input("factor", size: 1, [1])],
              settings: [Setting("mode", .choice(blendModes), .string("mix"))], outputSize: 0),
        .init(name: "fresnel", category: "Math", summary: "(1 - N·V)^power: bright at grazing angles",
              inputs: [Input("power", size: 1, [5]), Input("normal", size: 3, [0, 0, 1], defaultLink: "normal")],
              settings: [], outputSize: 1),
        .init(name: "combine", category: "Math", summary: "Builds a vector from x, y, z, w",
              inputs: [Input("x", size: 1, [0]), Input("y", size: 1, [0]), Input("z", size: 1, [0]), Input("w", size: 1, [1])],
              settings: [], outputSize: 4),
        .init(name: "remap", category: "Math", summary: "Maps value from inMin...inMax to outMin...outMax",
              inputs: [Input("value", size: 0, [0]), Input("inMin", size: 1, [0]), Input("inMax", size: 1, [1]),
                       Input("outMin", size: 1, [0]), Input("outMax", size: 1, [1])],
              settings: [], outputSize: 0),
    ]
}

// MARK: - Presets

extension MaterialGraph {
    /// The presets `materialGraph.new {preset}` and the Material Builder offer.
    public static let presetNames = ["basic", "lava", "water", "hologram", "stone", "pulse"]

    /// A starting graph (nil for an unknown name).
    public static func preset(_ name: String) -> MaterialGraph? {
        func node(_ id: String, _ type: String, _ fields: [String: JSONValue] = [:]) -> MaterialGraphNode {
            MaterialGraphNode(id: id, type: type, fields: fields)
        }
        // Whole numbers as ints, as they read back from a file.
        func n(_ f: Float) -> JSONValue { f == f.rounded() && abs(f) < 1e9 ? .int(Int64(f)) : .double(Double(f)) }
        func v(_ values: Float...) -> JSONValue { values.count == 1 ? n(values[0]) : .array(values.map(n)) }
        func l(_ link: String) -> JSONValue { .string(link) }
        switch name.lowercased() {
        case "basic":
            return MaterialGraph(nodes: [node("base", "color", ["value": v(0.8, 0.8, 0.8, 1)])],
                                 output: ["baseColor": l("base.rgb"), "roughness": v(0.5), "metallic": v(0)])
        case "lava":
            return MaterialGraph(nodes: [
                node("flow", "scrollUV", ["speed": v(0.03, 0.015)]),
                node("heat", "noise", ["kind": .string("fbm"), "uv": l("flow"), "scale": v(5), "octaves": .int(5)]),
                node("cracks", "math", ["op": .string("smoothstep"), "a": v(0.45), "b": v(0.75), "c": l("heat")]),
                node("crust", "color", ["value": v(0.06, 0.035, 0.03, 1)]),
                node("hot", "color", ["value": v(6, 1.6, 0.15, 1)]),
                node("glow", "math", ["op": .string("multiply"), "a": l("hot"), "b": l("cracks")]),
                node("rough", "math", ["op": .string("lerp"), "a": v(0.9), "b": v(0.4), "c": l("cracks")]),
            ], output: ["baseColor": l("crust.rgb"), "emissive": l("glow.rgb"), "roughness": l("rough")])
        case "water":
            return MaterialGraph(nodes: [
                node("flowA", "scrollUV", ["speed": v(0.04, 0.02)]),
                node("flowB", "scrollUV", ["speed": v(-0.03, 0.035)]),
                node("waveA", "noise", ["kind": .string("fbm"), "uv": l("flowA"), "scale": v(10), "octaves": .int(3)]),
                node("waveB", "noise", ["kind": .string("fbm"), "uv": l("flowB"), "scale": v(10), "octaves": .int(3)]),
                node("nx", "remap", ["value": l("waveA"), "outMin": v(-0.35), "outMax": v(0.35)]),
                node("ny", "remap", ["value": l("waveB"), "outMin": v(-0.35), "outMax": v(0.35)]),
                node("bump", "combine", ["x": l("nx"), "y": l("ny"), "z": v(1)]),
                node("rim", "fresnel", ["power": v(4)]),
                node("deep", "color", ["value": v(0.01, 0.08, 0.12, 1)]),
                node("shallow", "color", ["value": v(0.05, 0.35, 0.4, 1)]),
                node("tint", "blend", ["mode": .string("mix"), "a": l("deep"), "b": l("shallow"), "factor": l("rim")]),
                node("alpha", "math", ["op": .string("lerp"), "a": v(0.7), "b": v(1), "c": l("rim")]),
            ], output: ["baseColor": l("tint.rgb"), "normal": l("bump.xyz"), "roughness": v(0.05), "metallic": v(0),
                        "opacity": l("alpha")])
        case "hologram":
            return MaterialGraph(nodes: [
                node("rim", "fresnel", ["power": v(2.5)]),
                node("pos", "position"),
                node("t", "time", ["speed": v(1.5)]),
                node("lines", "math", ["op": .string("add"), "a": l("pos.y"), "b": l("t")]),
                node("scaled", "math", ["op": .string("multiply"), "a": l("lines"), "b": v(40)]),
                node("wave", "math", ["op": .string("sin"), "a": l("scaled")]),
                node("scan", "remap", ["value": l("wave"), "inMin": v(-1), "inMax": v(1), "outMin": v(0.3), "outMax": v(1)]),
                node("glowAmount", "math", ["op": .string("multiply"), "a": l("rim"), "b": l("scan")]),
                node("cyan", "color", ["value": v(0.2, 1.4, 2.0, 1)]),
                node("glow", "math", ["op": .string("multiply"), "a": l("cyan"), "b": l("glowAmount")]),
                node("alpha", "math", ["op": .string("add"), "a": l("glowAmount"), "b": v(0.15)]),
            ], output: ["baseColor": v(0, 0, 0), "emissive": l("glow.rgb"), "opacity": l("alpha"), "roughness": v(1)])
        case "stone":
            return MaterialGraph(nodes: [
                node("cells", "noise", ["kind": .string("cells"), "scale": v(6)]),
                node("grain", "noise", ["kind": .string("fbm"), "scale": v(24), "octaves": .int(4)]),
                node("dark", "color", ["value": v(0.18, 0.17, 0.16, 1)]),
                node("light", "color", ["value": v(0.52, 0.5, 0.46, 1)]),
                node("mixed", "blend", ["mode": .string("mix"), "a": l("dark"), "b": l("light"), "factor": l("cells")]),
                node("detail", "blend", ["mode": .string("overlay"), "a": l("mixed"), "b": l("grain"), "factor": v(0.6)]),
                node("ao", "remap", ["value": l("cells"), "outMin": v(0.55), "outMax": v(1)]),
            ], output: ["baseColor": l("detail.rgb"), "roughness": v(0.85), "occlusion": l("ao")])
        case "pulse":
            return MaterialGraph(nodes: [
                node("t", "time", ["speed": v(3)]),
                node("wave", "math", ["op": .string("sin"), "a": l("t")]),
                node("amount", "remap", ["value": l("wave"), "inMin": v(-1), "inMax": v(1), "outMin": v(0.2), "outMax": v(1)]),
                node("energy", "color", ["value": v(3, 0.4, 2.4, 1)]),
                node("glow", "math", ["op": .string("multiply"), "a": l("energy"), "b": l("amount")]),
            ], output: ["baseColor": v(0.1, 0.05, 0.1), "emissive": l("glow.rgb"), "metallic": v(0.2), "roughness": v(0.35)])
        default:
            return nil
        }
    }
}
