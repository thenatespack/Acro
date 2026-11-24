#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

// Compiles a `MaterialGraph` into a variant of the lit mesh shader, for both backends, without
// any shader compiler at run time:
//
// 1. The graph becomes straight-line code over float/float2/float3/float4 (`IR`): built-in
//    inputs, texture samples, arithmetic and GLSL.std.450 functions. Noise, triplanar mapping,
//    UV motion and blend modes are expanded into those operations. Every constant the author
//    typed becomes a slot of `MaterialGraphProgram.values` (uploaded as a storage buffer), so
//    changing a number doesn't change the code.
// 2. mesh_graph.frag (mesh_surface.glsl with MATERIAL_GRAPH, compiled unoptimized so its
//    `graphSurface()` function survives) is the template. For Vulkan the IR is emitted as SPIR-V
//    and replaces the body of `graphSurface` in the template's SPIR-V; for Metal it is emitted as
//    MSL and replaces the same function's body in the template's MSL (SPIRV-Cross output, where
//    the function keeps its name and gets the globals it uses as parameters).
// 3. The same body goes into mesh_graph_depth.frag (material_graph.glsl's declarations, a
//    discard below the cutoff and no color), the depth-only fragment stage masked graphs cast
//    shadows and fill the depth prepass with (`metalDepthFragment` / `spirvDepthFragment`), and
//    into decal_graph.frag, which decals with a graph material draw with (`metalDecalFragment`).
//
// The program's `key` is a hash of the generated code: materials whose graphs differ only in
// constants share pipelines.

/// A compiled material graph: the fragment shader for each backend, its values and textures.
public struct MaterialGraphProgram: Sendable, Equatable {
    /// Identifies the generated code (equal keys: same shaders).
    public var key: String
    /// mesh_graph's fragment stage in MSL with the graph's code (and the color-0-only variant).
    public var metalFragment: String
    public var metalFragmentColor0: String?
    /// mesh_graph's fragment stage in SPIR-V with the graph's code.
    public var spirvFragment: [UInt8]
    /// The fragment stage in WGSL, for the WebGPU backend: only for programs with fixed shaders
    /// (`TerrainSplat`); compiled graphs have none, so WebGPU can't draw them.
    public var wgslFragment: String? = nil
    /// mesh_graph_depth's fragment stage with the graph's code, in MSL and in SPIR-V: discards
    /// where the graph's opacity is below push constant `params.z`, writes no color. Draw it
    /// after mesh_shadow_graph.vert (or mesh_shadow_graph_skinned.vert) in a depth-only
    /// pipeline (`depthOnlyFragment`), with the program's values in storage buffer 0, its
    /// textures in slots 1-5 with sampler 1, and push constants
    /// `(time, 1, cutoff, 0), (camera position, 0)` (see `SceneRenderer.drawShadows`).
    /// Optional (programs built in code may leave them out): without both, a masked material
    /// with this program casts its whole shape (`Material.masksDepth` is false).
    public var metalDepthFragment: String? = nil
    public var spirvDepthFragment: [UInt8]? = nil
    /// decal_graph's fragment stage with the graph's code, in MSL and in SPIR-V: a `Decal` whose
    /// `material` has this program paints the graph's surface (see `DecalRenderer`). Draw it
    /// after decal.vert with the program's values in storage buffer 0, its textures in slots
    /// 1-5 with sampler 1, the depth prepass in texture slot 7 and push constants `(time, 0, 0, 0)`.
    /// Optional, as the depth variant: without both, such decals draw their own texture and tint.
    public var metalDecalFragment: String? = nil
    public var spirvDecalFragment: [UInt8]? = nil
    /// The graph's constants, the shader's `graphValues.values` (at least one).
    public var values: [Vec4]
    /// The textures in shader slots 1-5, in order.
    public var textures: [AssetReference]
    /// Whether the code reads the time (the renderer then keeps animating the material).
    public var usesTime: Bool
    /// The generated MSL of `graphSurface` (what `materialGraph.get {code: true}` shows).
    public var code: String

    public static func == (a: MaterialGraphProgram, b: MaterialGraphProgram) -> Bool {
        a.key == b.key && a.values == b.values && a.textures == b.textures
    }
}

/// The result of `MaterialGraphCompiler.compile`: a program (nil if the template is unavailable)
/// and problems found in the graph, which compiles anyway with defaults in their place.
public struct MaterialGraphCompilation: Sendable {
    public var program: MaterialGraphProgram?
    public var warnings: [String]
}

public enum MaterialGraphCompiler {
    /// Texture slots available to a graph (shader textures 1-5).
    public static let maxTextures = 5
    /// The template's texture names, by slot - 1.
    static let textureNames = ["baseColorMap", "metallicRoughnessMap", "normalMap", "occlusionMap", "emissiveMap"]
    static let outputVariables = ["baseColor": "gBaseColor", "opacity": "gOpacity", "normal": "gNormalTS",
                                  "metallic": "gMetallic", "roughness": "gRoughness", "emissive": "gEmissive",
                                  "occlusion": "gOcclusion"]

    /// Compiles `graph`. Texture settings are read as `asset:<id>[#sub]` references, or through
    /// `resolveTexture` when given (the importer passes one that also takes paths).
    public static func compile(_ graph: MaterialGraph, resolveTexture: ((String) -> AssetReference?)? = nil) -> MaterialGraphCompilation {
        var builder = GraphBuilder(graph: graph, resolveTexture: resolveTexture ?? { AssetReference($0) })
        builder.build()
        let msl = MSLEmitter.body(builder.ir, outputs: builder.outputs)
        let key = String(fnv1a64(Array(msl.utf8)), radix: 16)
        var warnings = builder.warnings
        let shaders: Shaders
        do {
            shaders = try cachedShaders(key: key) { template in
                Shaders(metal: try template.metal.replacingFunctionBody("graphSurface", with: msl),
                        metalColor0: try template.metalColor0.map { try $0.replacingFunctionBody("graphSurface", with: msl) },
                        spirv: try SPIRVSplicer(template.spirv).replacingGraphSurface(builder.ir, outputs: builder.outputs),
                        metalDepth: try template.metalDepth.replacingFunctionBody("graphSurface", with: msl),
                        spirvDepth: try SPIRVSplicer(template.spirvDepth).replacingGraphSurface(builder.ir, outputs: builder.outputs),
                        metalDecal: try template.metalDecal.replacingFunctionBody("graphSurface", with: msl),
                        spirvDecal: try SPIRVSplicer(template.spirvDecal).replacingGraphSurface(builder.ir, outputs: builder.outputs))
            }
        } catch {
            warnings.append("the material graph shader couldn't be built: \(error)")
            return MaterialGraphCompilation(program: nil, warnings: warnings)
        }
        var values = builder.ir.values
        if values.isEmpty { values = [.zero] }
        let program = MaterialGraphProgram(
            key: key, metalFragment: shaders.metal, metalFragmentColor0: shaders.metalColor0, spirvFragment: shaders.spirv,
            metalDepthFragment: shaders.metalDepth, spirvDepthFragment: shaders.spirvDepth,
            metalDecalFragment: shaders.metalDecal, spirvDecalFragment: shaders.spirvDecal,
            values: values, textures: builder.textures, usesTime: builder.ir.ops.contains { $0.kind == .input("gTime") }, code: msl)
        return MaterialGraphCompilation(program: program, warnings: warnings)
    }

    // MARK: Template and cache

    struct Template {
        var metal: String
        var metalColor0: String?
        var spirv: [UInt32]
        /// mesh_graph_depth.frag's.
        var metalDepth: String
        var spirvDepth: [UInt32]
        /// decal_graph.frag's.
        var metalDecal: String
        var spirvDecal: [UInt32]
    }

    struct Shaders {
        var metal: String
        var metalColor0: String?
        var spirv: [UInt8]
        var metalDepth: String
        var spirvDepth: [UInt8]
        var metalDecal: String
        var spirvDecal: [UInt8]
    }

    struct CompileError: Error, CustomStringConvertible {
        var description: String
        init(_ description: String) { self.description = description }
    }

    static let template: Result<Template, CompileError> = {
        let bundle = Bundle.engineResources
        func url(_ name: String, _ ext: String) -> URL? { bundle.engineResourceURL(name, withExtension: ext, subdirectory: "Shaders") }
        func load(_ name: String) -> (metal: String, spirv: [UInt32])? {
            guard let metalURL = url(name, "frag.metal"), let spirvURL = url(name, "frag.spv"),
                  let metal = try? String(contentsOf: metalURL, encoding: .utf8), let data = try? Data(contentsOf: spirvURL),
                  data.count % 4 == 0 else { return nil }
            return (metal, data.withUnsafeBytes { Array($0.bindMemory(to: UInt32.self)) })
        }
        guard let lit = load("mesh_graph"), let depth = load("mesh_graph_depth"), let decal = load("decal_graph") else {
            return .failure(CompileError("mesh_graph / mesh_graph_depth / decal_graph .frag.metal / .spv missing from the engine's resources"))
        }
        let color0 = url("mesh_graph", "frag.color0.metal").flatMap { try? String(contentsOf: $0, encoding: .utf8) }
        return .success(Template(metal: lit.metal, metalColor0: color0, spirv: lit.spirv, metalDepth: depth.metal, spirvDepth: depth.spirv,
                                 metalDecal: decal.metal, spirvDecal: decal.spirv))
    }()

    private static let cacheLock = NSLock()
    nonisolated(unsafe) private static var cache: [String: Shaders] = [:]

    private static func cachedShaders(key: String, make: (Template) throws -> Shaders) throws -> Shaders {
        cacheLock.lock()
        if let shaders = cache[key] {
            cacheLock.unlock()
            return shaders
        }
        cacheLock.unlock()
        let shaders = try make(try template.get())
        cacheLock.lock()
        if cache.count > 256 { cache.removeAll() }
        cache[key] = shaders
        cacheLock.unlock()
        return shaders
    }

    static func fnv1a64(_ bytes: [UInt8]) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 0x100_0000_01b3
        }
        return hash
    }
}

// MARK: - IR

/// Straight-line code: each op defines one value of 1-4 floats.
struct MaterialIR {
    enum Kind: Hashable {
        case constant([Float])
        /// `graphValues.values[slot]`, the first `size` components.
        case uniform(Int)
        /// A template global ("gUV", "gTime", …).
        case input(String)
        /// Samples texture slot n (0-based) at args[0]; size 4.
        case texture(Int)
        case add, subtract, multiply, divide, negate
        /// GLSL.std.450 function by name (sin, min, mix, …), args of the result's size.
        case function(String)
        /// dot(args[0], args[1]): size 1.
        case dot
        /// length(args[0]): size 1.
        case length
        case swizzle([Int])
        /// A vector built from args (scalars and vectors).
        case construct
    }

    struct Op: Hashable {
        var kind: Kind
        var size: Int
        var args: [Int]
    }

    var ops: [Op] = []
    var values: [Vec4] = []
    private var lookup: [Op: Int] = [:]

    mutating func add(_ kind: Kind, size: Int, _ args: [Int] = []) -> Int {
        let op = Op(kind: kind, size: size, args: args)
        if let id = lookup[op] { return id }
        ops.append(op)
        lookup[op] = ops.count - 1
        return ops.count - 1
    }

    /// A new value slot (never shared, so each constant stays editable on its own).
    mutating func addUniform(_ floats: [Float]) -> Int {
        var v = Vec4.zero
        for (i, f) in floats.prefix(4).enumerated() { v[i] = f.isFinite ? f : 0 }
        values.append(v)
        return values.count - 1
    }
}

/// A value of the graph being built: an op id and its size.
struct GraphValue {
    var id: Int
    var size: Int
}

// MARK: - Graph → IR

struct GraphBuilder {
    let graph: MaterialGraph
    let resolveTexture: (String) -> AssetReference?
    var ir = MaterialIR()
    var warnings: [String] = []
    var textures: [AssetReference] = []
    /// PBR input variable → value.
    var outputs: [(variable: String, value: GraphValue)] = []
    private var memo: [String: GraphValue] = [:]
    private var visiting: Set<String> = []
    private var reportedTextureLimit = false

    init(graph: MaterialGraph, resolveTexture: @escaping (String) -> AssetReference?) {
        self.graph = graph
        self.resolveTexture = resolveTexture
    }

    mutating func build() {
        var seen: Set<String> = []
        for node in graph.nodes {
            if node.id.isEmpty { warnings.append("a \(node.type) node has no id") }
            else if !seen.insert(node.id).inserted { warnings.append("duplicate node id '\(node.id)': the first one is used") }
            if MaterialGraphNodeType.catalog[node.type] == nil { warnings.append("node '\(node.id)': unknown type '\(node.type)'") }
        }
        let known = Set(MaterialGraph.outputs.map(\.name))
        for key in graph.output.keys.sorted() where !known.contains(key) {
            warnings.append("unknown output '\(key)' (outputs: \(MaterialGraph.outputs.map(\.name).joined(separator: ", ")))")
        }
        for output in MaterialGraph.outputs {
            let value = evaluate(graph.output[output.name], size: output.size, defaultValue: output.defaultValue,
                                 defaultLink: nil, context: "output '\(output.name)'")
            outputs.append((MaterialGraphCompiler.outputVariables[output.name]!, value))
        }
    }

    // MARK: Values

    mutating func constant(_ floats: Float...) -> GraphValue {
        GraphValue(id: ir.add(.constant(floats), size: floats.count), size: floats.count)
    }

    mutating func uniform(_ floats: [Float]) -> GraphValue {
        let size = max(1, min(floats.count, 4))
        let slot = ir.addUniform(floats)
        return GraphValue(id: ir.add(.uniform(slot), size: size), size: size)
    }

    mutating func input(_ name: String, _ size: Int) -> GraphValue {
        GraphValue(id: ir.add(.input(name), size: size), size: size)
    }

    /// `v` converted to `size` components: a scalar fills them, extra ones are dropped, missing
    /// ones are 0 (the fourth 1).
    mutating func convert(_ v: GraphValue, to size: Int) -> GraphValue {
        if v.size == size || size == 0 { return v }
        if v.size == 1 { return GraphValue(id: ir.add(.construct, size: size, Array(repeating: v.id, count: size)), size: size) }
        if size < v.size { return swizzle(v, Array(0..<size)) }
        var args = [v.id]
        for i in v.size..<size { args.append(constant(i == 3 ? 1 : 0).id) }
        return GraphValue(id: ir.add(.construct, size: size, args), size: size)
    }

    mutating func swizzle(_ v: GraphValue, _ indices: [Int]) -> GraphValue {
        if v.size == 1 { return convert(v, to: indices.count) }
        if indices == Array(0..<v.size) { return v }
        if indices.count == 1 { return GraphValue(id: ir.add(.swizzle(indices), size: 1, [v.id]), size: 1) }
        return GraphValue(id: ir.add(.swizzle(indices), size: indices.count, [v.id]), size: indices.count)
    }

    mutating func binary(_ kind: MaterialIR.Kind, _ a: GraphValue, _ b: GraphValue) -> GraphValue {
        let size = max(a.size, b.size)
        let a = convert(a, to: size), b = convert(b, to: size)
        return GraphValue(id: ir.add(kind, size: size, [a.id, b.id]), size: size)
    }

    mutating func function(_ name: String, _ args: GraphValue..., size: Int? = nil) -> GraphValue {
        let size = size ?? args.map(\.size).max() ?? 1
        let ids = args.map { convert($0, to: size).id }
        return GraphValue(id: ir.add(.function(name), size: size, ids), size: size)
    }

    mutating func add(_ a: GraphValue, _ b: GraphValue) -> GraphValue { binary(.add, a, b) }
    mutating func sub(_ a: GraphValue, _ b: GraphValue) -> GraphValue { binary(.subtract, a, b) }
    mutating func mul(_ a: GraphValue, _ b: GraphValue) -> GraphValue { binary(.multiply, a, b) }
    mutating func div(_ a: GraphValue, _ b: GraphValue) -> GraphValue { binary(.divide, a, b) }

    mutating func dot(_ a: GraphValue, _ b: GraphValue) -> GraphValue {
        let size = max(a.size, b.size)
        if size == 1 { return mul(a, b) }
        let a = convert(a, to: size), b = convert(b, to: size)
        return GraphValue(id: ir.add(.dot, size: 1, [a.id, b.id]), size: 1)
    }

    mutating func length(_ a: GraphValue) -> GraphValue {
        if a.size == 1 { return function("abs", a) }
        return GraphValue(id: ir.add(.length, size: 1, [a.id]), size: 1)
    }

    mutating func construct(_ parts: [GraphValue]) -> GraphValue {
        let size = parts.reduce(0) { $0 + $1.size }
        return GraphValue(id: ir.add(.construct, size: size, parts.map(\.id)), size: size)
    }

    mutating func oneMinus(_ a: GraphValue) -> GraphValue { sub(constant(1), a) }
    mutating func saturate(_ a: GraphValue) -> GraphValue { function("clamp", a, constant(0), constant(1)) }

    // MARK: Inputs and links

    /// The built-in value a link names when no node has that id.
    mutating func builtin(_ name: String) -> GraphValue? {
        switch name {
        case "uv": input("gUV", 2)
        case "position": input("gPosition", 3)
        case "normal": input("gNormal", 3)
        case "viewDir": input("gView", 3)
        case "vertexColor": input("gVertexColor", 4)
        case "time": input("gTime", 1)
        default: nil
        }
    }

    /// An input or output value: a link, a constant, or the default. `size` 0 keeps the value's own size.
    mutating func evaluate(_ field: JSONValue?, size: Int, defaultValue: [Float], defaultLink: String?, context: String) -> GraphValue {
        var value: GraphValue?
        switch field {
        case .string(let text)?:
            if let link = MaterialGraphLink(text) { value = resolve(link, context: context) }
            else if let defaultLink { value = builtin(defaultLink) }
        case .some(let json):
            if let floats = Self.floats(json), !floats.isEmpty, floats.count <= 4 {
                value = uniform(floats)
            } else if json != .null {
                warnings.append("\(context): expected a number, 2-4 numbers or a link, got \(json)")
            }
        case nil:
            if let defaultLink { value = builtin(defaultLink) }
        }
        let resolved = value ?? uniform(defaultValue)
        return convert(resolved, to: size)
    }

    static func floats(_ json: JSONValue) -> [Float]? {
        switch json {
        case .int(let i): return [Float(i)]
        case .double(let d): return [Float(d)]
        case .bool(let b): return [b ? 1 : 0]
        case .array(let items):
            var out: [Float] = []
            for item in items {
                switch item {
                case .int(let i): out.append(Float(i))
                case .double(let d): out.append(Float(d))
                default: return nil
                }
            }
            return out
        default: return nil
        }
    }

    mutating func resolve(_ link: MaterialGraphLink, context: String) -> GraphValue? {
        var value: GraphValue
        if graph.node(link.node) != nil {
            guard let v = node(link.node) else { return nil }
            value = v
        } else if let v = builtin(link.node) {
            value = v
        } else {
            warnings.append("\(context): no node '\(link.node)'")
            return nil
        }
        if let swizzle = link.swizzle {
            if value.size > 1, let bad = swizzle.first(where: { $0 >= value.size }) {
                warnings.append("\(context): '\(link.description)' reads component \(bad) of a \(value.size)-component value")
                return nil
            }
            value = self.swizzle(value, swizzle)
        }
        return value
    }

    /// The value of node `id` (nil for a cycle).
    mutating func node(_ id: String) -> GraphValue? {
        if let value = memo[id] { return value }
        guard let node = graph.node(id) else { return nil }
        if visiting.contains(id) {
            warnings.append("node '\(id)' is part of a cycle; the link is ignored")
            return nil
        }
        visiting.insert(id)
        defer { visiting.remove(id) }
        let value = evaluateNode(node)
        memo[id] = value
        return value
    }

    mutating func inputValue(_ node: MaterialGraphNode, _ name: String) -> GraphValue {
        let spec = MaterialGraphNodeType.catalog[node.type]?.input(name)
        return evaluate(node[name], size: spec?.size ?? 0, defaultValue: spec?.defaultValue ?? [0],
                        defaultLink: spec?.defaultLink, context: "node '\(node.id)' input '\(name)'")
    }

    func setting(_ node: MaterialGraphNode, _ name: String) -> JSONValue? {
        node[name] ?? MaterialGraphNodeType.catalog[node.type]?.setting(name)?.defaultValue
    }

    func string(_ node: MaterialGraphNode, _ name: String) -> String {
        if case .string(let s)? = setting(node, name) { return s }
        return ""
    }

    // MARK: Nodes

    mutating func evaluateNode(_ node: MaterialGraphNode) -> GraphValue {
        switch node.type {
        case "color", "vector":
            return convert(inputValue(node, "value"), to: 4)
        case "value":
            return convert(inputValue(node, "value"), to: 1)
        case "uv":
            return add(mul(self.input("gUV", 2), inputValue(node, "scale")), inputValue(node, "offset"))
        case "position", "normal", "viewDir", "vertexColor":
            return builtin(node.type)!
        case "time":
            return mul(self.input("gTime", 1), inputValue(node, "speed"))
        case "texture":
            let uv = inputValue(node, "uv")
            guard let slot = textureSlot(node) else { return constant(1, 1, 1, 1) }
            let sample = GraphValue(id: ir.add(.texture(slot), size: 4, [uv.id]), size: 4)
            if case .bool(true)? = setting(node, "normalMap") {
                let xyz = sub(mul(swizzle(sample, [0, 1, 2]), constant(2)), constant(1))
                return construct([xyz, constant(1)])
            }
            return sample
        case "triplanar":
            let scale = inputValue(node, "scale"), sharpness = inputValue(node, "sharpness")
            guard let slot = textureSlot(node) else { return constant(1, 1, 1, 1) }
            let n = self.input("gNormal", 3)
            var w = function("pow", function("max", function("abs", n), constant(1e-4)), sharpness, size: 3)
            w = div(w, dot(w, constant(1, 1, 1)))
            let p = mul(self.input("gPosition", 3), scale)
            func sample(_ b: inout GraphBuilder, _ uv: [Int]) -> GraphValue {
                let coord = b.swizzle(p, uv)
                return GraphValue(id: b.ir.add(.texture(slot), size: 4, [coord.id]), size: 4)
            }
            let x = mul(sample(&self, [2, 1]), swizzle(w, [0]))
            let y = mul(sample(&self, [0, 2]), swizzle(w, [1]))
            let z = mul(sample(&self, [0, 1]), swizzle(w, [2]))
            return add(add(x, y), z)
        case "noise":
            let p = mul(inputValue(node, "uv"), inputValue(node, "scale"))
            switch string(node, "kind") {
            case "fbm":
                var octaves = 4
                if case .int(let n)? = setting(node, "octaves") { octaves = Int(n) }
                else if case .double(let d)? = setting(node, "octaves") { octaves = Int(d) }
                octaves = max(1, min(octaves, 8))
                var sum = constant(0)
                var amplitude: Float = 0.5, frequency: Float = 1, total: Float = 0
                for i in 0..<octaves {
                    let q = add(mul(p, constant(frequency)), constant(Float(i) * 17.31, Float(i) * 9.13))
                    sum = add(sum, mul(valueNoise(q), constant(amplitude)))
                    total += amplitude
                    amplitude *= 0.5
                    frequency *= 2
                }
                return mul(sum, constant(1 / total))
            case "cells":
                return cellNoise(p)
            case "value", "":
                return valueNoise(p)
            case let other:
                warnings.append("node '\(node.id)': unknown noise kind '\(other)' (kinds: \(MaterialGraphNodeType.noiseKinds.joined(separator: ", ")))")
                return valueNoise(p)
            }
        case "scrollUV":
            return add(inputValue(node, "uv"), mul(inputValue(node, "speed"), self.input("gTime", 1)))
        case "rotateUV":
            let uv = inputValue(node, "uv"), center = inputValue(node, "center")
            let angle = add(inputValue(node, "angle"), mul(inputValue(node, "speed"), self.input("gTime", 1)))
            let c = function("cos", angle), s = function("sin", angle)
            let d = sub(uv, center)
            let dx = swizzle(d, [0]), dy = swizzle(d, [1])
            let rotated = construct([sub(mul(c, dx), mul(s, dy)), add(mul(s, dx), mul(c, dy))])
            return add(rotated, center)
        case "math":
            return math(node)
        case "blend":
            let a = inputValue(node, "a"), b = inputValue(node, "b"), factor = convert(inputValue(node, "factor"), to: 1)
            let size = max(a.size, b.size)
            let x = convert(a, to: size), y = convert(b, to: size)
            let blended: GraphValue
            switch string(node, "mode") {
            case "multiply": blended = mul(x, y)
            case "add": blended = add(x, y)
            case "subtract": blended = sub(x, y)
            case "screen": blended = oneMinus(mul(oneMinus(x), oneMinus(y)))
            case "overlay":
                let low = mul(mul(x, y), constant(2))
                let high = oneMinus(mul(mul(oneMinus(x), oneMinus(y)), constant(2)))
                blended = function("mix", low, high, function("step", constant(0.5), x, size: size))
            case "mix", "": blended = y
            case let other:
                warnings.append("node '\(node.id)': unknown blend mode '\(other)' (modes: \(MaterialGraphNodeType.blendModes.joined(separator: ", ")))")
                blended = y
            }
            return function("mix", x, blended, factor, size: size)
        case "fresnel":
            let n = function("normalize", inputValue(node, "normal"))
            let facing = saturate(dot(n, self.input("gView", 3)))
            return function("pow", function("max", oneMinus(facing), constant(0)), inputValue(node, "power"))
        case "combine":
            return construct(["x", "y", "z", "w"].map { inputValue(node, $0) })
        case "remap":
            let value = inputValue(node, "value")
            let inMin = inputValue(node, "inMin"), inMax = inputValue(node, "inMax")
            let outMin = inputValue(node, "outMin"), outMax = inputValue(node, "outMax")
            let t = div(sub(value, inMin), sub(inMax, inMin))
            return add(outMin, mul(t, sub(outMax, outMin)))
        default:
            return constant(0)
        }
    }

    mutating func math(_ node: MaterialGraphNode) -> GraphValue {
        let op = string(node, "op")
        let a = inputValue(node, "a")
        func b(_ s: inout GraphBuilder) -> GraphValue { s.inputValue(node, "b") }
        func c(_ s: inout GraphBuilder) -> GraphValue { s.inputValue(node, "c") }
        switch op {
        case "add", "": return add(a, b(&self))
        case "subtract": return sub(a, b(&self))
        case "multiply": return mul(a, b(&self))
        case "divide": return div(a, b(&self))
        case "min": return function("min", a, b(&self))
        case "max": return function("max", a, b(&self))
        case "power": return function("pow", function("max", a, constant(0)), b(&self))
        case "mod":
            let y = b(&self)
            return sub(a, mul(y, function("floor", div(a, y))))
        case "step": return function("step", a, b(&self))
        case "dot": return dot(a, b(&self))
        case "length": return length(a)
        case "normalize": return a.size == 1 ? constant(1) : function("normalize", a)
        case "sin", "cos", "abs", "floor", "fract", "sqrt": return function(op, a)
        case "oneMinus": return oneMinus(a)
        case "negate": return GraphValue(id: ir.add(.negate, size: a.size, [a.id]), size: a.size)
        case "saturate": return saturate(a)
        case "clamp": return function("clamp", a, b(&self), c(&self))
        case "lerp":
            let y = b(&self), t = c(&self)
            let size = max(a.size, y.size)
            return function("mix", a, y, t.size == 1 ? t : convert(t, to: size), size: size)
        case "smoothstep":
            let edge0 = a, edge1 = b(&self), x = c(&self)
            return function("smoothstep", edge0, edge1, x, size: max(edge0.size, edge1.size, x.size))
        default:
            warnings.append("node '\(node.id)': unknown math op '\(op)' (ops: \(MaterialGraphNodeType.mathOps.joined(separator: ", ")))")
            return a
        }
    }

    /// The texture slot (0-based) of a texture or triplanar node's `texture`; nil without one.
    mutating func textureSlot(_ node: MaterialGraphNode) -> Int? {
        let text = string(node, "texture").trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            warnings.append("node '\(node.id)' has no texture")
            return nil
        }
        guard let reference = resolveTexture(text) else {
            warnings.append("node '\(node.id)': no texture '\(text)'")
            return nil
        }
        if let i = textures.firstIndex(of: reference) { return i }
        guard textures.count < MaterialGraphCompiler.maxTextures else {
            if !reportedTextureLimit {
                warnings.append("more than \(MaterialGraphCompiler.maxTextures) different textures; node '\(node.id)' and later ones draw white")
                reportedTextureLimit = true
            }
            return nil
        }
        textures.append(reference)
        return textures.count - 1
    }

    // MARK: Noise

    /// A hash of a 2D point to 0...1 without sine (Dave Hoskins' "hash without sine", so every
    /// GPU gets the same result).
    mutating func hash12(_ p: GraphValue) -> GraphValue {
        var p3 = function("fract", mul(swizzle(p, [0, 1, 0]), constant(0.1031)))
        p3 = add(p3, dot(p3, add(swizzle(p3, [1, 2, 0]), constant(33.33))))
        return function("fract", mul(add(swizzle(p3, [0]), swizzle(p3, [1])), swizzle(p3, [2])))
    }

    mutating func hash22(_ p: GraphValue) -> GraphValue {
        var p3 = function("fract", mul(swizzle(p, [0, 1, 0]), constant(0.1031, 0.1030, 0.0973)))
        p3 = add(p3, dot(p3, add(swizzle(p3, [1, 2, 0]), constant(33.33))))
        return function("fract", mul(add(swizzle(p3, [0, 0]), swizzle(p3, [1, 2])), swizzle(p3, [2, 1])))
    }

    /// Smooth value noise 0...1.
    mutating func valueNoise(_ p: GraphValue) -> GraphValue {
        let i = function("floor", p), f = function("fract", p)
        let u = mul(mul(f, f), sub(constant(3), mul(f, constant(2))))
        let a = hash12(i), b = hash12(add(i, constant(1, 0)))
        let c = hash12(add(i, constant(0, 1))), d = hash12(add(i, constant(1, 1)))
        let ux = swizzle(u, [0]), uy = swizzle(u, [1])
        return function("mix", function("mix", a, b, ux), function("mix", c, d, ux), uy)
    }

    /// Distance to the nearest of one jittered point per cell (Voronoi F1), 0...1.
    mutating func cellNoise(_ p: GraphValue) -> GraphValue {
        let i = function("floor", p), f = function("fract", p)
        var nearest = constant(8)
        for y in -1...1 {
            for x in -1...1 {
                let g = constant(Float(x), Float(y))
                let r = sub(add(g, hash22(add(i, g))), f)
                nearest = function("min", nearest, dot(r, r))
            }
        }
        return function("min", function("sqrt", nearest), constant(1))
    }
}

// MARK: - MSL

enum MSLEmitter {
    static let typeNames = ["", "float", "float2", "float3", "float4"]

    static func literal(_ f: Float) -> String {
        guard f.isFinite else { return "0.0" }
        var s = String(format: "%.9g", Double(f))
        if !s.contains(".") && !s.contains("e") && !s.contains("n") { s += ".0" }
        return s
    }

    static func swizzleText(_ indices: [Int]) -> String { String(indices.map { Array("xyzw")[$0] }) }

    /// The statements of `graphSurface`'s body.
    static func body(_ ir: MaterialIR, outputs: [(variable: String, value: GraphValue)]) -> String {
        var lines: [String] = []
        func t(_ id: Int) -> String { "t\(id)" }
        for (id, op) in ir.ops.enumerated() {
            let a = op.args.map(t)
            let expr: String
            switch op.kind {
            case .constant(let floats):
                expr = floats.count == 1 ? literal(floats[0]) : "\(typeNames[op.size])(\(floats.map(literal).joined(separator: ", ")))"
            case .uniform(let slot):
                expr = "graphValues.values[\(slot)]" + (op.size == 4 ? "" : "." + swizzleText(Array(0..<op.size)))
            case .input(let name):
                expr = name
            case .texture(let slot):
                expr = "\(MaterialGraphCompiler.textureNames[slot]).sample(materialSampler, \(a[0]))"
            case .add: expr = "\(a[0]) + \(a[1])"
            case .subtract: expr = "\(a[0]) - \(a[1])"
            case .multiply: expr = "\(a[0]) * \(a[1])"
            case .divide: expr = "\(a[0]) / \(a[1])"
            case .negate: expr = "-\(a[0])"
            case .function(let name):
                expr = "\(name)(\(a.joined(separator: ", ")))"
            case .dot: expr = "dot(\(a[0]), \(a[1]))"
            case .length: expr = "length(\(a[0]))"
            case .swizzle(let indices): expr = "\(a[0]).\(swizzleText(indices))"
            case .construct: expr = "\(typeNames[op.size])(\(a.joined(separator: ", ")))"
            }
            lines.append("    \(typeNames[op.size]) \(t(id)) = \(expr);")
        }
        for (variable, value) in outputs {
            lines.append("    \(variable) = \(t(value.id));")
        }
        return lines.joined(separator: "\n")
    }
}

extension String {
    /// This MSL with the body of function `name` replaced by `body`.
    func replacingFunctionBody(_ name: String, with body: String) throws -> String {
        guard let signature = range(of: "void \(name)(") else {
            throw MaterialGraphCompiler.CompileError("no function \(name) in the template MSL")
        }
        guard let open = self[signature.upperBound...].firstIndex(of: "{") else {
            throw MaterialGraphCompiler.CompileError("no body for \(name) in the template MSL")
        }
        var depth = 0
        var close: String.Index?
        var i = open
        while i < endIndex {
            if self[i] == "{" { depth += 1 }
            if self[i] == "}" {
                depth -= 1
                if depth == 0 { close = i; break }
            }
            i = index(after: i)
        }
        guard let close else { throw MaterialGraphCompiler.CompileError("unbalanced braces in \(name)") }
        let parameters = self[signature.upperBound..<open]
        for needed in ["graphValues", "materialSampler", "gUV", "gTime", "gBaseColor", "gOcclusion"] + MaterialGraphCompiler.textureNames
        where !parameters.contains(needed) {
            throw MaterialGraphCompiler.CompileError("\(name) in the template MSL doesn't take \(needed)")
        }
        return String(self[..<index(after: open)]) + "\n" + body + "\n" + String(self[close...])
    }
}

// MARK: - SPIR-V

/// Replaces the body of `graphSurface` in the template's SPIR-V with code emitted from the IR.
struct SPIRVSplicer {
    struct Instruction {
        var opcode: UInt32
        var words: [UInt32]
    }

    enum Op {
        static let name: UInt32 = 5, extInstImport: UInt32 = 11, extInst: UInt32 = 12
        static let typeInt: UInt32 = 21, typeFloat: UInt32 = 22, typeVector: UInt32 = 23
        static let typeSampledImage: UInt32 = 27, typePointer: UInt32 = 32
        static let constant: UInt32 = 43, constantComposite: UInt32 = 44
        static let function: UInt32 = 54, functionEnd: UInt32 = 56, variable: UInt32 = 59
        static let load: UInt32 = 61, store: UInt32 = 62, accessChain: UInt32 = 65, decorate: UInt32 = 71
        static let memberDecorate: UInt32 = 72, memberName: UInt32 = 6
        static let vectorShuffle: UInt32 = 79, compositeConstruct: UInt32 = 80, compositeExtract: UInt32 = 81
        static let sampledImage: UInt32 = 86, imageSampleImplicitLod: UInt32 = 87
        static let fNegate: UInt32 = 127, fAdd: UInt32 = 129, fSub: UInt32 = 131, fMul: UInt32 = 133, fDiv: UInt32 = 136
        static let dot: UInt32 = 148, label: UInt32 = 248, `return`: UInt32 = 253
    }

    /// GLSL.std.450 instruction numbers.
    static let glsl: [String: UInt32] = [
        "abs": 4, "floor": 8, "fract": 10, "sin": 13, "cos": 14, "pow": 26, "exp2": 29, "sqrt": 31, "min": 37, "max": 40,
        "clamp": 43, "mix": 46, "step": 48, "smoothstep": 49, "length": 66, "normalize": 69,
    ]

    var header: [UInt32]
    var instructions: [Instruction]

    init(_ words: [UInt32]) throws {
        guard words.count > 5, words[0] == 0x0723_0203 else { throw MaterialGraphCompiler.CompileError("not SPIR-V") }
        header = Array(words[0..<5])
        instructions = []
        var i = 5
        while i < words.count {
            let count = Int(words[i] >> 16)
            guard count > 0, i + count <= words.count else { throw MaterialGraphCompiler.CompileError("malformed SPIR-V") }
            instructions.append(Instruction(opcode: words[i] & 0xFFFF, words: Array(words[i..<i + count])))
            i += count
        }
    }

    static func string(_ words: ArraySlice<UInt32>) -> String {
        var bytes: [UInt8] = []
        outer: for word in words {
            for shift in stride(from: 0, to: 32, by: 8) {
                let byte = UInt8((word >> UInt32(shift)) & 0xFF)
                if byte == 0 { break outer }
                bytes.append(byte)
            }
        }
        return String(decoding: bytes, as: UTF8.self)
    }

    func replacingGraphSurface(_ ir: MaterialIR, outputs: [(variable: String, value: GraphValue)]) throws -> [UInt8] {
        func fail(_ message: String) -> MaterialGraphCompiler.CompileError { .init("template SPIR-V: \(message)") }
        // Names and declarations.
        var names: [String: UInt32] = [:]
        var functionID: UInt32?
        for inst in instructions where inst.opcode == Op.name {
            let name = Self.string(inst.words[2...])
            if name.hasPrefix("graphSurface(") { functionID = inst.words[1] }
            else if names[name] == nil { names[name] = inst.words[1] }
        }
        guard let functionID else { throw fail("no graphSurface function") }
        var floatType: UInt32?, intType: UInt32?, glslImport: UInt32?
        var vectorTypes: [Int: UInt32] = [:]
        var pointers: [UInt32: (storage: UInt32, pointee: UInt32)] = [:]
        var variableTypes: [UInt32: UInt32] = [:]
        var sampledImageTypes: [UInt32: UInt32] = [:]
        var samplerType: UInt32?
        for inst in instructions {
            let w = inst.words
            switch inst.opcode {
            case Op.typeFloat where w[2] == 32: floatType = w[1]
            case Op.typeInt where w[2] == 32 && w[3] == 1: intType = w[1]
            case Op.typeVector where w[2] == floatType: vectorTypes[Int(w[3])] = w[1]
            case Op.typePointer: pointers[w[1]] = (w[2], w[3])
            case Op.variable: variableTypes[w[2]] = w[1]
            case Op.typeSampledImage: sampledImageTypes[w[2]] = w[1]
            case 26: samplerType = w[1]  // OpTypeSampler
            case Op.extInstImport where Self.string(w[2...]) == "GLSL.std.450": glslImport = w[1]
            default: break
            }
        }
        guard let floatType, let intType, let glslImport, let samplerType,
              let v2 = vectorTypes[2], let v3 = vectorTypes[3], let v4 = vectorTypes[4] else { throw fail("missing types") }
        let types = [0, floatType, v2, v3, v4]
        guard let storagePointer = pointers.first(where: { $0.value.storage == 12 && $0.value.pointee == v4 })?.key else {
            throw fail("no StorageBuffer vec4 pointer")
        }
        func variable(_ name: String) throws -> UInt32 {
            guard let id = names[name], variableTypes[id] != nil else { throw fail("no variable \(name)") }
            return id
        }
        func pointee(_ variable: UInt32) throws -> UInt32 {
            guard let pointer = variableTypes[variable], let pointee = pointers[pointer]?.pointee else { throw fail("untyped variable") }
            return pointee
        }

        var bound = header[3]
        func newID() -> UInt32 { defer { bound += 1 }; return bound }
        var globals: [UInt32] = []
        var body: [UInt32] = []
        func emit(_ into: inout [UInt32], _ opcode: UInt32, _ operands: [UInt32]) {
            into.append(UInt32(operands.count + 1) << 16 | opcode)
            into.append(contentsOf: operands)
        }
        var floatConstants: [UInt32: UInt32] = [:]
        func floatConstant(_ f: Float) -> UInt32 {
            let bits = (f.isFinite ? f : 0).bitPattern
            if let id = floatConstants[bits] { return id }
            let id = newID()
            emit(&globals, Op.constant, [floatType, id, bits])
            floatConstants[bits] = id
            return id
        }
        var intConstants: [Int: UInt32] = [:]
        func intConstant(_ i: Int) -> UInt32 {
            if let id = intConstants[i] { return id }
            let id = newID()
            emit(&globals, Op.constant, [intType, id, UInt32(bitPattern: Int32(i))])
            intConstants[i] = id
            return id
        }

        let valuesVariable = try variable("graphValues")
        let samplerVariable = try variable("materialSampler")
        var ids: [UInt32] = []
        emit(&body, Op.label, [newID()])
        for op in ir.ops {
            let type = types[op.size]
            let a = op.args.map { ids[$0] }
            let id: UInt32
            switch op.kind {
            case .constant(let floats):
                if floats.count == 1 { id = floatConstant(floats[0]) } else {
                    let parts = floats.map(floatConstant)
                    id = newID()
                    emit(&globals, Op.constantComposite, [type, id] + parts)
                }
            case .uniform(let slot):
                let pointer = newID()
                emit(&body, Op.accessChain, [storagePointer, pointer, valuesVariable, intConstant(0), intConstant(slot)])
                let vector = newID()
                emit(&body, Op.load, [v4, vector, pointer])
                if op.size == 4 { id = vector } else if op.size == 1 {
                    id = newID()
                    emit(&body, Op.compositeExtract, [floatType, id, vector, 0])
                } else {
                    id = newID()
                    emit(&body, Op.vectorShuffle, [type, id, vector, vector] + (0..<op.size).map { UInt32($0) })
                }
            case .input(let name):
                id = newID()
                emit(&body, Op.load, [type, id, try variable(name)])
            case .texture(let slot):
                let textureVariable = try variable(MaterialGraphCompiler.textureNames[slot])
                let imageType = try pointee(textureVariable)
                guard let sampledType = sampledImageTypes[imageType] else { throw fail("no sampled image type") }
                let image = newID(), sampler = newID(), combined = newID()
                emit(&body, Op.load, [imageType, image, textureVariable])
                emit(&body, Op.load, [samplerType, sampler, samplerVariable])
                emit(&body, Op.sampledImage, [sampledType, combined, image, sampler])
                id = newID()
                emit(&body, Op.imageSampleImplicitLod, [v4, id, combined, a[0]])
            case .add, .subtract, .multiply, .divide:
                let opcode: UInt32 = switch op.kind {
                case .add: Op.fAdd
                case .subtract: Op.fSub
                case .multiply: Op.fMul
                default: Op.fDiv
                }
                id = newID()
                emit(&body, opcode, [type, id, a[0], a[1]])
            case .negate:
                id = newID()
                emit(&body, Op.fNegate, [type, id, a[0]])
            case .function(let name):
                guard let number = Self.glsl[name] else { throw fail("no GLSL.std.450 function \(name)") }
                id = newID()
                emit(&body, Op.extInst, [type, id, glslImport, number] + a)
            case .dot:
                id = newID()
                emit(&body, Op.dot, [floatType, id, a[0], a[1]])
            case .length:
                id = newID()
                emit(&body, Op.extInst, [floatType, id, glslImport, Self.glsl["length"]!, a[0]])
            case .swizzle(let indices):
                id = newID()
                if indices.count == 1 {
                    emit(&body, Op.compositeExtract, [floatType, id, a[0], UInt32(indices[0])])
                } else {
                    emit(&body, Op.vectorShuffle, [type, id, a[0], a[0]] + indices.map { UInt32($0) })
                }
            case .construct:
                id = newID()
                emit(&body, Op.compositeConstruct, [type, id] + a)
            }
            ids.append(id)
        }
        for (name, value) in outputs {
            emit(&body, Op.store, [try variable(name), ids[value.id]])
        }
        emit(&body, Op.return, [])

        // Splice: drop the old body (and debug names / decorations of what it defined), add the
        // new constants before the first function.
        guard let start = instructions.firstIndex(where: { $0.opcode == Op.function && $0.words[2] == functionID }),
              let end = instructions[start...].firstIndex(where: { $0.opcode == Op.functionEnd }) else {
            throw fail("graphSurface has no body")
        }
        let noResult: Set<UInt32> = [Op.store, Op.return, 254, 249, 250, 247, 246, 252, 8, 317, 251, 255, 63, 99]
        var removed: Set<UInt32> = []
        for inst in instructions[(start + 1)..<end] where !noResult.contains(inst.opcode) {
            if inst.opcode == Op.label { removed.insert(inst.words[1]) } else if inst.words.count > 2 { removed.insert(inst.words[2]) }
        }
        guard let firstFunction = instructions.firstIndex(where: { $0.opcode == Op.function }) else { throw fail("no functions") }
        var out = header
        out[3] = bound
        for (index, inst) in instructions.enumerated() {
            if index == firstFunction { out.append(contentsOf: globals) }
            if index > start && index < end { continue }
            if [Op.name, Op.decorate, Op.memberName, Op.memberDecorate].contains(inst.opcode) && removed.contains(inst.words[1]) { continue }
            out.append(contentsOf: inst.words)
            if index == start { out.append(contentsOf: body) }
        }
        return out.withUnsafeBufferPointer { Array(UnsafeRawBufferPointer($0)) }
    }
}

extension MaterialGraph {
    /// The numbers of a constant input (a number or an array of numbers); nil for anything else.
    public static func numbers(_ json: JSONValue) -> [Float]? { GraphBuilder.floats(json) }
}
