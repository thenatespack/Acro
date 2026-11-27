#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore

/// Shader code for every backend. Each backend uses the variant it understands.
///
/// The engine's and the demo's shaders are written once, in GLSL. `Scripts/compile-shaders.sh`
/// compiles them to SPIR-V (`name.vert.spv`, `name.frag.spv`) and cross-compiles that SPIR-V to
/// MSL with SPIRV-Cross (`name.vert.metal`, `name.frag.metal`, one file per stage), following
/// the binding table below. Hand-written MSL (one `name.metal` with both entry points) works too.
/// For the WebGPU backend the script also translates the SPIR-V to WGSL with naga
/// (`name.vert.wgsl`, `name.frag.wgsl`, `name.comp.wgsl`, entry point `main`), and for the WebGL 2
/// backend to GLSL ES 3.00 with SPIRV-Cross (`name.vert.gles`, `name.frag.gles`; vertex and
/// fragment stages only, and only those whose active resources WebGL 2 has: no storage buffers or
/// images).
///
/// Conventions shared by all shaders:
/// - Vertex attributes come from buffer slot 0, `location n` ↔ `[[attribute(n)]]`.
/// - Push constants: GLSL `layout(push_constant) uniform`, MSL `constant T& [[buffer(16)]]`,
///   WGSL `@group(3) @binding(0) var<uniform>` (WebGPU has no push constants).
/// - Entry points: MSL `vertex_main` / `fragment_main`, GLSL and WGSL `main`.
///
/// Resource bindings. `n` is the `index` passed to the `RenderPass` call. WGSL bindings are
/// `@group(set) @binding(binding)` of the GLSL ones, except as noted:
///
/// | Resource (pass call) | Metal | Vulkan GLSL | WebGPU WGSL | WebGL 2 GLSL ES 3.00 |
/// |---|---|---|---|---|
/// | vertex buffers 0 / 1 | `[[stage_in]]` / `[[buffer(0)]]`, `[[buffer(1)]]` | `layout(location = ...) in` | `@location(...)` | `layout(location = ...) in` |
/// | `setUniformData(_:)` (per-frame block) | `constant T& [[buffer(15)]]` | `layout(set = 0, binding = 0, std140) uniform` | `@group(0) @binding(0) var<uniform>` | block `acro_vs_u0_0` / `acro_fs_u0_0`, binding point 0 |
/// | `setTexture(_:)` (shadow map) | `depth2d<float> [[texture(0)]]`, `sampler [[sampler(0)]]` | `layout(set = 1, binding = 0) uniform sampler2DShadow` | `@group(1) @binding(0) texture_depth_2d`, `@group(1) @binding(1) sampler_comparison` (split) | `sampler2DShadow acro_t1_0` (a comparison sampler object) |
/// | `setUniformBuffer` / `setUniformData(_:index:)`, n in 2...7 | `constant T& [[buffer(n)]]` | `layout(set = 2, binding = n, std140) uniform` | `@group(2) @binding(n) var<uniform>` | block `acro_vs_u2_n` / `acro_fs_u2_n`, binding point n |
/// | `setTexture(_:index:)`, n in 1...7 | `texture2d<float> [[texture(n)]]` | `layout(set = 2, binding = 8 + n) uniform texture2D` | `@group(2) @binding(8 + n) texture_2d<f32>` | `sampler2D acro_t2_<8 + n>_s2_<16 + m>`: texture n with sampler m, one texture unit each (`acro_t2_<8 + n>` without a sampler: texelFetch) |
/// | `setSampler(_:index:)`, n in 1...7 | `sampler [[sampler(n)]]` | `layout(set = 2, binding = 16 + n) uniform sampler` | `@group(2) @binding(16 + n) sampler` | a sampler object on the units of the textures it is combined with |
/// | `setPushConstants` (≤ 128 B) | `constant T& [[buffer(16)]]` | `layout(push_constant) uniform` | `@group(3) @binding(0) var<uniform>` (WGSL uniform layout rules apply) | block `acro_vs_push` / `acro_fs_push` (std140), binding point 1 |
/// | `setStorageBuffer`, n in 0...7 | `device T& [[buffer(20 + n)]]` | `layout(set = 2, binding = 24 + n, std430) buffer` | `@group(2) @binding(24 + n) var<storage>` | none (no .gles), except a std140 uniform block at the same set and binding (the material graph templates' GRAPH_VALUES_UNIFORM variant): block `acro_fs_u2_<24 + n>`, binding point 8 + n; or a `utexture2D` there (the probe-lit shaders' PROBE_DATA_TEXTURE variant): `usampler2D acro_t2_<24 + n>_s2_<16 + m>`, an RGBA32UI copy of the buffer, 1024 texels per row |
/// | `ComputePass.setStorageTexture`, n in 0...7 | `texture2d<float, access::read_write> [[texture(8 + n)]]` | `layout(set = 2, binding = 32 + n, rgba16f) uniform image2D` | `@group(2) @binding(32 + n) texture_storage_2d` | none |
///
/// GLSL ES 3.00 has no binding qualifiers, so `Scripts/spirv-to-gles.c` names every resource by its
/// set and binding as above, names varyings by location (`acro_v<n>`), and lists the uniform
/// blocks and samplers in a header after `#version 300 es` (`// acro-ubo <block> <set> <binding>`,
/// `// acro-sampler <name> <texture set> <binding> <sampler set> <binding> <shadow>`), which the
/// WebGL 2 device reads to bind blocks to binding points and samplers to texture units. Stages
/// whose active resources include storage buffers or images get no `.gles`.
///
/// Compute shaders (`name.comp` → `name.comp.spv`, `name.comp.metal` with `compute_main`,
/// `name.comp.wgsl`) use the same set 2 table and push constants; see `ComputePass`.
///
/// WebGPU only has the storage-texture formats and accesses the browser's adapter offers:
/// write-only `rgba16f`, `rgba8` and `r32f` everywhere, `r8`, `r16f` and `rg16f` with the
/// "texture-formats-tier1" feature, read-write `rgba16f` and `r8` with "texture-formats-tier2".
/// The backend refuses compute pipelines that need more (FSR 3 is unsupported there).
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
    /// MSL defining `compute_main` (a compute shader; the vertex and fragment fields stay nil).
    public var metalComputeSource: String?
    public var spirvCompute: [UInt8]?
    /// WGSL for the WebGPU backend, one module per stage (generated `<name>.vert.wgsl`,
    /// `.frag.wgsl`, `.comp.wgsl`; entry point `main`). nil when the shader has none (hand-written
    /// MSL, or SPIR-V naga can't translate): the WebGPU backend then refuses the pipeline.
    public var wgslVertex: String?
    public var wgslFragment: String?
    public var wgslCompute: String?
    /// GLSL ES 3.00 for the WebGL 2 backend (generated `<name>.vert.gles`, `.frag.gles`, with the
    /// binding header above). nil when the shader has none (hand-written MSL, or a stage that
    /// needs storage buffers or images): the WebGL 2 backend then refuses the pipeline.
    public var glesVertex: String?
    public var glesFragment: String?

    public init(metalSource: String? = nil, metalFragmentSource: String? = nil, metalFragmentColor0Source: String? = nil,
                spirvVertex: [UInt8]? = nil, spirvFragment: [UInt8]? = nil) {
        self.metalSource = metalSource
        self.metalFragmentSource = metalFragmentSource
        self.metalFragmentColor0Source = metalFragmentColor0Source
        self.spirvVertex = spirvVertex
        self.spirvFragment = spirvFragment
    }

    /// Loads the compute shader `<name>.comp.spv` and `<name>.comp.metal` (generated from
    /// `<name>.comp`), or a hand-written `<name>.metal` defining `compute_main`.
    public static func load(compute name: String, bundle: Bundle, subdirectory: String? = "Shaders") throws -> ShaderSource {
        func url(_ ext: String) -> URL? {
            bundle.engineResourceURL(name, withExtension: ext, subdirectory: subdirectory)
        }
        var source = ShaderSource()
        if let metal = url("metal") ?? url("comp.metal") {
            source.metalComputeSource = try String(contentsOf: metal, encoding: .utf8)
        }
        if let spirv = url("comp.spv") {
            source.spirvCompute = Array(try Data(contentsOf: spirv))
        }
        source.wgslCompute = try url("comp.wgsl").map { try String(contentsOf: $0, encoding: .utf8) }
        if source.metalComputeSource == nil && source.spirvCompute == nil && source.wgslCompute == nil {
            throw GraphicsError("No compute shader named '\(name)' found in \(bundle.bundlePath)")
        }
        return source
    }

    /// Loads `<name>.vert.spv` and `<name>.frag.spv` from a bundle, plus MSL: `<name>.metal`
    /// if it exists (hand-written, both stages), else the generated `<name>.vert.metal` and
    /// `<name>.frag.metal` (and `<name>.frag.color0.metal` when generated), WGSL (`<name>.vert.wgsl`, `<name>.frag.wgsl`) and GLSL ES
    /// (`<name>.vert.gles`, `<name>.frag.gles`). Missing variants are left nil; the backend that needs them reports
    /// the error.
    public static func load(named name: String, bundle: Bundle, subdirectory: String? = "Shaders") throws -> ShaderSource {
        func url(_ ext: String) -> URL? {
            bundle.engineResourceURL(name, withExtension: ext, subdirectory: subdirectory)
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
        source.wgslVertex = try url("vert.wgsl").map { try String(contentsOf: $0, encoding: .utf8) }
        source.wgslFragment = try url("frag.wgsl").map { try String(contentsOf: $0, encoding: .utf8) }
        source.glesVertex = try url("vert.gles").map { try String(contentsOf: $0, encoding: .utf8) }
        source.glesFragment = try url("frag.gles").map { try String(contentsOf: $0, encoding: .utf8) }
        if source.metalSource == nil && source.spirvVertex == nil && source.wgslVertex == nil && source.glesVertex == nil {
            throw GraphicsError("No shader named '\(name)' found in \(bundle.bundlePath)")
        }
        return source
    }

    /// The vertex stage of the generated shader `vertex` with the fragment stage of the
    /// generated `fragment` (`<fragment>.frag.spv`, `.frag.metal`, `.frag.color0.metal`, `.frag.wgsl`, `.frag.gles`), for
    /// fragment variants that share a vertex shader.
    public static func load(vertex: String, fragment: String, bundle: Bundle, subdirectory: String? = "Shaders") throws -> ShaderSource {
        var source = try load(named: vertex, bundle: bundle, subdirectory: subdirectory)
        func url(_ ext: String) -> URL? {
            bundle.engineResourceURL(fragment, withExtension: ext, subdirectory: subdirectory)
        }
        // Any of the variants will do: a web export ships only the WGSL and GLSL ES ones (GameExporterWeb.swift).
        source.spirvFragment = try url("frag.spv").map { Array(try Data(contentsOf: $0)) }
        source.metalFragmentSource = try url("frag.metal").map { try String(contentsOf: $0, encoding: .utf8) }
        source.metalFragmentColor0Source = try url("frag.color0.metal").map { try String(contentsOf: $0, encoding: .utf8) }
        source.wgslFragment = try url("frag.wgsl").map { try String(contentsOf: $0, encoding: .utf8) }
        source.glesFragment = try url("frag.gles").map { try String(contentsOf: $0, encoding: .utf8) }
        if source.spirvFragment == nil && source.metalFragmentSource == nil && source.wgslFragment == nil && source.glesFragment == nil {
            throw GraphicsError("No fragment shader named '\(fragment)' found in \(bundle.bundlePath)")
        }
        return source
    }
}
