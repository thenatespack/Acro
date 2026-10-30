import Foundation

/// Shader code for every backend. Each backend uses the variant it understands.
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
/// Uniform blocks use std140 layout on Vulkan; in MSL use `float4`-based structs (or pad
/// `float3` to 16 bytes) so both agree. Uniform buffer and texture bindings persist across
/// draws until replaced, so a shader must only read the slots its pass has bound.
public struct ShaderSource: Sendable {
    /// Metal Shading Language source, compiled at pipeline creation.
    public var metalSource: String?
    /// SPIR-V for the Vulkan backend.
    public var spirvVertex: [UInt8]?
    public var spirvFragment: [UInt8]?

    public init(metalSource: String? = nil, spirvVertex: [UInt8]? = nil, spirvFragment: [UInt8]? = nil) {
        self.metalSource = metalSource
        self.spirvVertex = spirvVertex
        self.spirvFragment = spirvFragment
    }

    /// Loads `<name>.metal`, `<name>.vert.spv` and `<name>.frag.spv` from a bundle.
    /// Missing variants are left nil; the backend that needs them reports the error.
    public static func load(named name: String, bundle: Bundle, subdirectory: String? = "Shaders") throws -> ShaderSource {
        func url(_ ext: String) -> URL? {
            bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
        }
        var source = ShaderSource()
        if let metal = url("metal") {
            source.metalSource = try String(contentsOf: metal, encoding: .utf8)
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
}
