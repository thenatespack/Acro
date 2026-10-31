import Foundation

/// The glTF 2.0 JSON document, decoded with `Codable`. Only the parts the importer reads are
/// modelled; unknown properties (cameras, `extras`, unknown extensions) are ignored by the
/// decoder. Field names follow the specification.
struct GLTFDocument: Decodable {
    struct Asset: Decodable {
        var version: String
        var minVersion: String?
        var generator: String?
        var copyright: String?
    }

    struct Buffer: Decodable {
        var uri: String?
        var byteLength: Int
        var name: String?
    }

    struct BufferView: Decodable {
        var buffer: Int
        var byteOffset: Int?
        var byteLength: Int
        var byteStride: Int?
        var name: String?
    }

    struct Accessor: Decodable {
        struct Sparse: Decodable {
            struct Indices: Decodable {
                var bufferView: Int
                var byteOffset: Int?
                var componentType: Int
            }
            struct Values: Decodable {
                var bufferView: Int
                var byteOffset: Int?
            }
            var count: Int
            var indices: Indices
            var values: Values
        }
        var bufferView: Int?
        var byteOffset: Int?
        var componentType: Int
        var normalized: Bool?
        var count: Int
        var type: String
        var sparse: Sparse?
        var name: String?
    }

    struct Primitive: Decodable {
        var attributes: [String: Int]
        var indices: Int?
        var material: Int?
        var mode: Int?
        /// Morph targets (not imported; only their presence is noted).
        var targets: [[String: Int]]?
    }

    struct Mesh: Decodable {
        var primitives: [Primitive]
        var name: String?
    }

    struct Node: Decodable {
        var name: String?
        var children: [Int]?
        var mesh: Int?
        var matrix: [Float]?
        var translation: [Float]?
        var rotation: [Float]?
        var scale: [Float]?
        var camera: Int?
        var skin: Int?
    }

    struct Skin: Decodable {
        var inverseBindMatrices: Int?
        var joints: [Int]
        var skeleton: Int?
        var name: String?
    }

    struct Animation: Decodable {
        struct Target: Decodable {
            var node: Int?
            var path: String
        }
        struct Channel: Decodable {
            var sampler: Int
            var target: Target
        }
        struct Sampler: Decodable {
            var input: Int
            var output: Int
            var interpolation: String?
        }
        var channels: [Channel]
        var samplers: [Sampler]
        var name: String?
    }

    struct Scene: Decodable {
        var name: String?
        var nodes: [Int]?
    }

    struct TextureTransform: Decodable {
        var offset: [Float]?
        var rotation: Float?
        var scale: [Float]?
        var texCoord: Int?
    }

    struct TextureInfoExtensions: Decodable {
        var KHR_texture_transform: TextureTransform?
    }

    /// `textureInfo`, `normalTextureInfo` (`scale`) and `occlusionTextureInfo` (`strength`) in one.
    struct TextureInfo: Decodable {
        var index: Int
        var texCoord: Int?
        var scale: Float?
        var strength: Float?
        var extensions: TextureInfoExtensions?
    }

    struct PBRMetallicRoughness: Decodable {
        var baseColorFactor: [Float]?
        var baseColorTexture: TextureInfo?
        var metallicFactor: Float?
        var roughnessFactor: Float?
        var metallicRoughnessTexture: TextureInfo?
    }

    struct Empty: Decodable {}

    struct EmissiveStrength: Decodable {
        var emissiveStrength: Float?
    }

    struct MaterialExtensions: Decodable {
        var KHR_materials_unlit: Empty?
        var KHR_materials_emissive_strength: EmissiveStrength?
    }

    struct Material: Decodable {
        var name: String?
        var pbrMetallicRoughness: PBRMetallicRoughness?
        var normalTexture: TextureInfo?
        var occlusionTexture: TextureInfo?
        var emissiveTexture: TextureInfo?
        var emissiveFactor: [Float]?
        var alphaMode: String?
        var alphaCutoff: Float?
        var doubleSided: Bool?
        var extensions: MaterialExtensions?
    }

    struct Texture: Decodable {
        var sampler: Int?
        var source: Int?
        var name: String?
    }

    struct Image: Decodable {
        var uri: String?
        var mimeType: String?
        var bufferView: Int?
        var name: String?
    }

    struct Sampler: Decodable {
        var magFilter: Int?
        var minFilter: Int?
        var wrapS: Int?
        var wrapT: Int?
        var name: String?
    }

    var asset: Asset
    var extensionsUsed: [String]?
    var extensionsRequired: [String]?
    var scene: Int?
    var scenes: [Scene]?
    var nodes: [Node]?
    var meshes: [Mesh]?
    var accessors: [Accessor]?
    var bufferViews: [BufferView]?
    var buffers: [Buffer]?
    var materials: [Material]?
    var textures: [Texture]?
    var images: [Image]?
    var samplers: [Sampler]?
    var skins: [Skin]?
    var animations: [Animation]?
}
