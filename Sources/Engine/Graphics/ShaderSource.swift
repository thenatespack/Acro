import Foundation

/// Shader code for every backend. Each backend uses the variant it understands.
///
/// Conventions shared by all shaders:
/// - Vertex attributes come from buffer slot 0, `location n` ↔ `[[attribute(n)]]`.
/// - Push constants: GLSL `layout(push_constant) uniform`, MSL `constant T& [[buffer(16)]]`.
/// - Entry points: MSL `vertex_main` / `fragment_main`, GLSL `main`.
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
