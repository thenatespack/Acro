import Foundation

/// Shader code for every backend. Each backend uses the variant it understands.
///
/// The engine's and the demo's shaders are written once, in GLSL. `Scripts/compile-shaders.sh`
/// compiles them to SPIR-V (`name.vert.spv`, `name.frag.spv`) and cross-compiles that SPIR-V to
/// MSL with SPIRV-Cross (`name.vert.metal`, `name.frag.metal`, one file per stage), following
/// the binding table below. Hand-written MSL (one `name.metal` with both entry points) works too.
///
/// Conventions shared by all shaders:
/// - Vertex attributes come from buffer slot 0, `location n` ↔ `[[attribute(n)]]`.
/// - Push constants: GLSL `layout(push_constant) uniform`, MSL `constant T& [[buffer(16)]]`.
/// - Entry points: MSL `vertex_main` / `fragment_main`, GLSL `main`.
///
/// Resource bindings. `n` is the `index` passed to the `RenderPass` call:
///
/// | Resource (pass call) | Metal | Vulkan GLSL |
/// |---|---|---|
/// | vertex buffers 0 / 1 | `[[stage_in]]` / `[[buffer(0)]]`, `[[buffer(1)]]` | `layout(location = ...) in` |
/// | `setUniformData(_:)` (per-frame block) | `constant T& [[buffer(15)]]` | `layout(set = 0, binding = 0, std140) uniform` |
/// | `setTexture(_:)` (shadow map) | `depth2d<float> [[texture(0)]]`, `sampler [[sampler(0)]]` | `layout(set = 1, binding = 0) uniform sampler2DShadow` |
/// | `setUniformBuffer` / `setUniformData(_:index:)`, n in 2...7 | `constant T& [[buffer(n)]]` | `layout(set = 2, binding = n, std140) uniform` |
/// | `setTexture(_:index:)`, n in 1...7 | `texture2d<float> [[texture(n)]]` | `layout(set = 2, binding = 8 + n) uniform texture2D` |
/// | `setSampler(_:index:)`, n in 1...7 | `sampler [[sampler(n)]]` | `layout(set = 2, binding = 16 + n) uniform sampler` |
/// | `setPushConstants` (≤ 128 B) | `constant T& [[buffer(16)]]` | `layout(push_constant) uniform` |
///
/// On Vulkan, textures and samplers are separate descriptors (combine them in the shader with
/// `texture(sampler2D(tex, samp), uv)`), matching Metal where either can be mixed freely.
/// Uniform blocks use std140 layout on Vulkan; in hand-written MSL use `float4`-based structs
/// (or pad `float3` to 16 bytes) so both agree. Uniform buffer and texture bindings persist
/// across draws until replaced, so a shader must only read the slots its pass has bound.
public struct ShaderSource: Sendable {
    /// Metal Shading Language source defining `vertex_main`, compiled at pipeline creation.
    /// It also defines `fragment_main` unless `metalFragmentSource` is set.
    public var metalSource: String?
    /// MSL defining `fragment_main`, when the fragment stage is a separate file (as generated
    /// shaders are: SPIRV-Cross emits one per stage).
    public var metalFragmentSource: String?
    /// `metalFragmentSource` with every output but `[[color(0)]]` dropped, for pipelines whose
    /// pass has no attachment for the others (generated as `<name>.frag.color0.metal`). Apple's
    /// compiler treats color 0 differently when unconsumed outputs exist, which changes how
    /// blending rounds; MoltenVK drops them too, so this keeps Metal and Vulkan bit-identical.
    public var metalFragmentColor0Source: String?
    /// SPIR-V for the Vulkan backend.
    public var spirvVertex: [UInt8]?
    public var spirvFragment: [UInt8]?

    public init(metalSource: String? = nil, metalFragmentSource: String? = nil, metalFragmentColor0Source: String? = nil,
                spirvVertex: [UInt8]? = nil, spirvFragment: [UInt8]? = nil) {
        self.metalSource = metalSource
        self.metalFragmentSource = metalFragmentSource
        self.metalFragmentColor0Source = metalFragmentColor0Source
        self.spirvVertex = spirvVertex
        self.spirvFragment = spirvFragment
    }

    /// Loads `<name>.vert.spv` and `<name>.frag.spv` from a bundle, plus MSL: `<name>.metal`
    /// if it exists (hand-written, both stages), else the generated `<name>.vert.metal` and
    /// `<name>.frag.metal` (and `<name>.frag.color0.metal` when generated). Missing variants are left nil; the backend that needs them reports
    /// the error.
    public static func load(named name: String, bundle: Bundle, subdirectory: String? = "Shaders") throws -> ShaderSource {
        func url(_ ext: String) -> URL? {
            bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
        }
        var source = ShaderSource()
        if let metal = url("metal") {
            source.metalSource = try String(contentsOf: metal, encoding: .utf8)
        } else if let vertex = url("vert.metal") {
            source.metalSource = try String(contentsOf: vertex, encoding: .utf8)
            if let fragment = url("frag.metal") {
                source.metalFragmentSource = try String(contentsOf: fragment, encoding: .utf8)
            }
            if let color0 = url("frag.color0.metal") {
                source.metalFragmentColor0Source = try String(contentsOf: color0, encoding: .utf8)
            }
        }
        if let vert = url("vert.spv") {
            source.spirvVertex = Array(try Data(contentsOf: vert))
        }
        if let frag = url("frag.spv") {
            source.spirvFragment = Array(try Data(contentsOf: frag))
        }
        if source.metalSource == nil && source.spirvVertex == nil {
            throw GraphicsError("No shader named '\(name)' found in \(bundle.bundlePath)")
        }
        return source
    }

    /// The vertex stage of the generated shader `vertex` with the fragment stage of the
    /// generated `fragment` (`<fragment>.frag.spv`, `.frag.metal`, `.frag.color0.metal`), for
    /// fragment variants that share a vertex shader.
    public static func load(vertex: String, fragment: String, bundle: Bundle, subdirectory: String? = "Shaders") throws -> ShaderSource {
        var source = try load(named: vertex, bundle: bundle, subdirectory: subdirectory)
        func url(_ ext: String) -> URL? {
            bundle.url(forResource: fragment, withExtension: ext, subdirectory: subdirectory)
        }
        guard let spirv = url("frag.spv") else {
            throw GraphicsError("No fragment shader named '\(fragment)' found in \(bundle.bundlePath)")
        }
        source.spirvFragment = Array(try Data(contentsOf: spirv))
        source.metalFragmentSource = try url("frag.metal").map { try String(contentsOf: $0, encoding: .utf8) }
        source.metalFragmentColor0Source = try url("frag.color0.metal").map { try String(contentsOf: $0, encoding: .utf8) }
        return source
    }
}
