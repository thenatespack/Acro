import Foundation

/// Why a glTF file couldn't be read.
public enum GLTFError: Error, Equatable, CustomStringConvertible {
    /// The binary (.glb) container is malformed.
    case invalidGLB(String)
    /// The JSON doesn't parse or doesn't match the glTF schema.
    case invalidJSON(String)
    /// Not glTF 2.x.
    case unsupportedVersion(String)
    /// `extensionsRequired` lists extensions this reader doesn't implement.
    case unsupportedExtensions([String])
    /// A buffer or image file couldn't be loaded.
    case missingResource(String)
    /// An index, offset, count or type in the file is out of range or inconsistent.
    case invalidData(String)

    public var description: String {
        switch self {
        case .invalidGLB(let message): return "Invalid GLB: \(message)"
        case .invalidJSON(let message): return "Invalid glTF JSON: \(message)"
        case .unsupportedVersion(let version): return "Unsupported glTF version \(version) (only 2.x is supported)"
        case .unsupportedExtensions(let names): return "Unsupported required glTF extensions: \(names.joined(separator: ", "))"
        case .missingResource(let message): return "Missing glTF resource: \(message)"
        case .invalidData(let message): return "Invalid glTF data: \(message)"
        }
    }
}

/// Reads glTF 2.0 files (`.gltf` JSON with external or `data:` URI buffers and images, and
/// binary `.glb`) into an `ImportedModel`. CPU only and free of shared state, so it can run on
/// any thread.
///
/// ```swift
/// let model = try GLTFReader.read(contentsOf: url)
/// let handles = try model.register(with: sceneRenderer, keyPrefix: "helmet",
///                                  textures: model.makeTextures(device: device, decoder: decode).textures)
/// model.instantiate(in: world, handles: handles)
/// ```
///
/// Supported: buffers, buffer views with strides, accessors of every component type
/// (normalized or not) including sparse ones; triangle lists, strips and fans; `POSITION`,
/// `NORMAL`, `TANGENT`, `TEXCOORD_0`, `TEXCOORD_1`, `COLOR_0`; 8/16/32-bit or no indices;
/// metallic-roughness materials with all their textures, samplers, `KHR_texture_transform`,
/// `KHR_materials_unlit`, `KHR_materials_emissive_strength` and `KHR_mesh_quantization`;
/// node trees with TRS or matrix transforms; multiple scenes.
///
/// Ignored (with a warning where it matters): points and lines, skins, morph targets,
/// animations, cameras, lights, other extensions. Images are not decoded (see `ImportedImage`).
public enum GLTFReader {
    /// What to do for primitives without normals.
    public enum NormalGeneration: Sendable {
        /// One normal per triangle, as the glTF specification requires. Splits vertices.
        case flat
        /// Area-weighted average over the triangles sharing a vertex position.
        case smooth
    }

    public struct Options: Sendable {
        /// How to generate missing normals.
        public var normals: NormalGeneration
        /// The scene to select; nil uses the file's `scene`, else the first.
        public var scene: Int?

        public init(normals: NormalGeneration = .flat, scene: Int? = nil) {
            self.normals = normals
            self.scene = scene
        }
    }

    /// Extensions the reader implements (so files may require them).
    public static let supportedExtensions: Set<String> = [
        "KHR_texture_transform", "KHR_materials_unlit", "KHR_materials_emissive_strength", "KHR_mesh_quantization",
    ]

    /// Reads a `.gltf` or `.glb` file. External buffers and images are loaded relative to it.
    public static func read(contentsOf url: URL, options: Options = Options()) throws -> ImportedModel {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw GLTFError.missingResource("\(url.path): \(error.localizedDescription)")
        }
        return try read(data: data, baseURL: url.deletingLastPathComponent(), options: options)
    }

    /// Reads glTF from memory: a GLB container (detected by its magic) or glTF JSON.
    ///
    /// External URIs (buffers and images that aren't `data:` URIs or GLB-embedded) are
    /// resolved by `loadResource`, which gets the percent-decoded relative URI, or else
    /// relative to `baseURL`. Without either, such files throw `.missingResource`.
    public static func read(data: Data, baseURL: URL? = nil, options: Options = Options(),
                            loadResource: ((String) throws -> Data)? = nil) throws -> ImportedModel {
        let json: Data
        var binChunk: Data?
        if isGLB(data) {
            (json, binChunk) = try parseGLB(data)
        } else {
            json = data
        }
        let document: GLTFDocument
        do {
            document = try JSONDecoder().decode(GLTFDocument.self, from: json)
        } catch let error as DecodingError {
            throw GLTFError.invalidJSON(describe(error))
        } catch {
            throw GLTFError.invalidJSON(error.localizedDescription)
        }
        let resolver = ResourceResolver(baseURL: baseURL, load: loadResource)
        var parser = GLTFParser(document: document, binChunk: binChunk, resolver: resolver, options: options)
        return try parser.parse()
    }

    /// Whether `data` starts with the GLB magic (`glTF`).
    public static func isGLB(_ data: Data) -> Bool {
        data.count >= 4 && data.prefix(4).elementsEqual([0x67, 0x6C, 0x54, 0x46])
    }

    /// Splits a GLB container into its JSON chunk and optional BIN chunk.
    static func parseGLB(_ data: Data) throws -> (json: Data, bin: Data?) {
        let bytes = [UInt8](data)
        func u32(_ offset: Int) -> Int {
            Int(bytes[offset]) | Int(bytes[offset + 1]) << 8 | Int(bytes[offset + 2]) << 16 | Int(bytes[offset + 3]) << 24
        }
        guard bytes.count >= 12 else { throw GLTFError.invalidGLB("file is shorter than the 12-byte header") }
        guard u32(4) == 2 else { throw GLTFError.invalidGLB("container version \(u32(4)), expected 2") }
        let length = u32(8)
        guard length >= 12, length <= bytes.count else {
            throw GLTFError.invalidGLB("header length \(length) doesn't fit the \(bytes.count)-byte file")
        }
        var offset = 12
        var json: Data?
        var bin: Data?
        var chunkIndex = 0
        while offset + 8 <= length {
            let chunkLength = u32(offset), type = u32(offset + 4)
            let start = offset + 8
            guard chunkLength <= length - start else {
                throw GLTFError.invalidGLB("chunk \(chunkIndex) (\(chunkLength) bytes) runs past the end of the file")
            }
            let body = Data(bytes[start..<(start + chunkLength)])
            switch type {
            case 0x4E4F_534A:  // "JSON"
                guard chunkIndex == 0 else { throw GLTFError.invalidGLB("JSON chunk must come first") }
                json = body
            case 0x004E_4942:  // "BIN\0"
                guard chunkIndex == 1 else { throw GLTFError.invalidGLB("BIN chunk must be the second chunk") }
                bin = body
            default:
                guard chunkIndex > 0 else { throw GLTFError.invalidGLB("first chunk isn't JSON") }
            }
            offset = start + ((chunkLength + 3) & ~3)
            chunkIndex += 1
        }
        guard let json else { throw GLTFError.invalidGLB("no JSON chunk") }
        return (json, bin)
    }

    private static func describe(_ error: DecodingError) -> String {
        func path(_ context: DecodingError.Context) -> String {
            let p = context.codingPath.map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }.joined()
            return p.isEmpty ? "" : " at \(p)"
        }
        switch error {
        case .typeMismatch(_, let context), .valueNotFound(_, let context):
            return "\(context.debugDescription)\(path(context))"
        case .keyNotFound(let key, let context):
            return "missing \"\(key.stringValue)\"\(path(context))"
        case .dataCorrupted(let context):
            return "\(context.debugDescription)\(path(context))"
        @unknown default:
            return "\(error)"
        }
    }
}

/// Loads external and `data:` URIs.
struct ResourceResolver {
    var baseURL: URL?
    var load: ((String) throws -> Data)?

    /// The bytes of `uri` and the MIME type of a `data:` URI.
    func data(for uri: String, what: String) throws -> (data: Data, mimeType: String?) {
        if uri.hasPrefix("data:") {
            guard let comma = uri.firstIndex(of: ",") else {
                throw GLTFError.invalidData("\(what): data URI without a comma")
            }
            let header = uri[uri.index(uri.startIndex, offsetBy: 5)..<comma]
            let payload = uri[uri.index(after: comma)...]
            let parts = header.split(separator: ";")
            let mime = parts.first.map(String.init).flatMap { $0.contains("/") ? $0 : nil }
            if parts.contains("base64") {
                guard let data = Data(base64Encoded: String(payload), options: .ignoreUnknownCharacters) else {
                    throw GLTFError.invalidData("\(what): invalid base64 in data URI")
                }
                return (data, mime)
            }
            guard let text = String(payload).removingPercentEncoding else {
                throw GLTFError.invalidData("\(what): invalid percent encoding in data URI")
            }
            return (Data(text.utf8), mime)
        }
        if let colon = uri.firstIndex(of: ":"), uri[..<colon].allSatisfy({ $0.isLetter || $0.isNumber || "+-.".contains($0) }),
           uri[..<colon].count > 1 {
            // A scheme (http:, file:, …). Single letters are Windows drive letters.
            throw GLTFError.missingResource("\(what): only relative and data: URIs are supported, got \(uri)")
        }
        let path = uri.removingPercentEncoding ?? uri
        if let load {
            do { return (try load(path), nil) } catch {
                throw GLTFError.missingResource("\(what) '\(path)': \(error)")
            }
        }
        guard let baseURL else {
            throw GLTFError.missingResource("\(what) '\(path)': no base URL or resource loader to resolve it")
        }
        let url = URL(fileURLWithPath: path, relativeTo: baseURL)
        do { return (try Data(contentsOf: url), nil) } catch {
            throw GLTFError.missingResource("\(what) '\(url.path)': \(error.localizedDescription)")
        }
    }
}

/// glTF accessor component types and element types.
enum ComponentType: Int {
    case byte = 5120, unsignedByte = 5121, short = 5122, unsignedShort = 5123, unsignedInt = 5125, float = 5126

    var size: Int {
        switch self {
        case .byte, .unsignedByte: return 1
        case .short, .unsignedShort: return 2
        case .unsignedInt, .float: return 4
        }
    }
}

enum ElementType: String {
    case scalar = "SCALAR", vec2 = "VEC2", vec3 = "VEC3", vec4 = "VEC4", mat2 = "MAT2", mat3 = "MAT3", mat4 = "MAT4"

    var components: Int {
        switch self {
        case .scalar: return 1
        case .vec2: return 2
        case .vec3: return 3
        case .vec4, .mat2: return 4
        case .mat3: return 9
        case .mat4: return 16
        }
    }
}

/// Turns a decoded document into an `ImportedModel`.
struct GLTFParser {
    let document: GLTFDocument
    let binChunk: Data?
    let resolver: ResourceResolver
    let options: GLTFReader.Options
    private var buffers: [[UInt8]?] = []
    private var warnings: [String] = []
    private var warned = Set<String>()

    /// Accessors without a buffer view are zero-filled; this caps how big they may claim to be.
    static let maxZeroFilledComponents = 1 << 28

    init(document: GLTFDocument, binChunk: Data?, resolver: ResourceResolver, options: GLTFReader.Options) {
        self.document = document
        self.binChunk = binChunk
        self.resolver = resolver
        self.options = options
        buffers = Array(repeating: nil, count: document.buffers?.count ?? 0)
    }

    private mutating func warn(_ message: String) {
        if warned.insert(message).inserted { warnings.append(message) }
    }

    mutating func parse() throws -> ImportedModel {
        try checkAssetAndExtensions()

        var model = ImportedModel()
        model.generator = document.asset.generator
        model.copyright = document.asset.copyright
        model.images = try (document.images ?? []).indices.map { try image($0) }
        model.textures = try (document.textures ?? []).enumerated().map { try texture($0.offset, $0.element) }
        model.materials = try (document.materials ?? []).enumerated().map { try material($0.offset, $0.element) }
        for material in model.materials {
            for (slot, reference) in material.textureReferences {
                model.textures[reference.texture].slots.insert(slot)
            }
        }
        for (i, texture) in model.textures.enumerated()
        where texture.slots.contains(where: { $0.colorSpace == .sRGB }) && texture.slots.contains(where: { $0.colorSpace == .linear }) {
            warn("Texture \(i) is used both as color and as data; it is treated as sRGB")
        }
        model.meshes = try (document.meshes ?? []).enumerated().map { try mesh($0.offset, $0.element, materialCount: model.materials.count) }
        try buildNodes(into: &model)
        flipMirroredMeshes(&model)
        if document.nodes?.contains(where: { $0.skin != nil }) == true { warn("Skins are not supported and were ignored") }
        if document.nodes?.contains(where: { $0.camera != nil }) == true { warn("Cameras are not imported") }
        model.warnings = warnings
        return model
    }

    private mutating func checkAssetAndExtensions() throws {
        let version = document.asset.version
        guard version.split(separator: ".").first == "2" else { throw GLTFError.unsupportedVersion(version) }
        if let minVersion = document.asset.minVersion, minVersion != "2.0" {
            throw GLTFError.unsupportedVersion("\(version) (minVersion \(minVersion))")
        }
        let unsupported = (document.extensionsRequired ?? []).filter { !GLTFReader.supportedExtensions.contains($0) }
        if !unsupported.isEmpty { throw GLTFError.unsupportedExtensions(unsupported) }
        for name in document.extensionsUsed ?? [] where !GLTFReader.supportedExtensions.contains(name) {
            warn("Extension \(name) is not supported and was ignored")
        }
    }

    // MARK: Buffers and accessors

    private mutating func buffer(_ index: Int) throws -> [UInt8] {
        guard let desc = document.buffers?[safe: index] else { throw GLTFError.invalidData("buffer \(index) doesn't exist") }
        if let cached = buffers[index] { return cached }
        let data: Data
        if let uri = desc.uri {
            data = try resolver.data(for: uri, what: "buffer \(index)").data
        } else if index == 0, let binChunk {
            data = binChunk
        } else {
            throw GLTFError.missingResource("buffer \(index) has no URI and isn't the GLB BIN chunk")
        }
        guard desc.byteLength >= 0, data.count >= desc.byteLength else {
            throw GLTFError.invalidData("buffer \(index) has \(data.count) bytes, but byteLength is \(desc.byteLength)")
        }
        let bytes = [UInt8](data.prefix(desc.byteLength))
        buffers[index] = bytes
        return bytes
    }

    /// The bytes of buffer view `index`, bounds-checked against its buffer.
    private mutating func bufferView(_ index: Int) throws -> (bytes: ArraySlice<UInt8>, stride: Int?) {
        guard let view = document.bufferViews?[safe: index] else { throw GLTFError.invalidData("buffer view \(index) doesn't exist") }
        let bytes = try buffer(view.buffer)
        let offset = view.byteOffset ?? 0
        guard offset >= 0, view.byteLength >= 0, offset <= bytes.count, view.byteLength <= bytes.count - offset else {
            throw GLTFError.invalidData("buffer view \(index) (offset \(offset), length \(view.byteLength)) is outside buffer \(view.buffer) (\(bytes.count) bytes)")
        }
        if let stride = view.byteStride, !(4...252).contains(stride) {
            throw GLTFError.invalidData("buffer view \(index) has byteStride \(stride), outside 4...252")
        }
        return (bytes[offset..<(offset + view.byteLength)], view.byteStride)
    }

    /// Reads `count` elements of `components` components each from `bytes` (bounds-checked
    /// before anything is allocated) and returns them converted and flattened.
    private func gather<T>(_ bytes: ArraySlice<UInt8>, offset: Int, stride: Int?, count: Int, components: Int,
                           type: ComponentType, what: String, _ convert: (UnsafeRawPointer) -> T) throws -> [T] {
        let elementSize = components * type.size
        let stride = stride ?? elementSize
        guard stride >= elementSize else {
            throw GLTFError.invalidData("\(what): byteStride \(stride) is smaller than an element (\(elementSize) bytes)")
        }
        guard offset >= 0, count >= 0 else { throw GLTFError.invalidData("\(what): negative offset or count") }
        if count == 0 { return [] }
        let (span, overflow) = stride.multipliedReportingOverflow(by: count - 1)
        guard !overflow, offset <= bytes.count, span <= bytes.count - offset, elementSize <= bytes.count - offset - span else {
            throw GLTFError.invalidData("\(what): \(count) elements of \(elementSize) bytes (stride \(stride), offset \(offset)) don't fit its \(bytes.count)-byte buffer view")
        }
        var out: [T] = []
        out.reserveCapacity(count * components)
        bytes.withUnsafeBytes { raw in
            let base = raw.baseAddress! + offset
            for i in 0..<count {
                let element = base + i * stride
                for c in 0..<components { out.append(convert(element + c * type.size)) }
            }
        }
        return out
    }

    private func accessorDescription(_ index: Int) throws -> (GLTFDocument.Accessor, ComponentType, ElementType) {
        guard let accessor = document.accessors?[safe: index] else { throw GLTFError.invalidData("accessor \(index) doesn't exist") }
        guard let componentType = ComponentType(rawValue: accessor.componentType) else {
            throw GLTFError.invalidData("accessor \(index) has unknown componentType \(accessor.componentType)")
        }
        guard let elementType = ElementType(rawValue: accessor.type) else {
            throw GLTFError.invalidData("accessor \(index) has unknown type \(accessor.type)")
        }
        guard accessor.count >= 0 else { throw GLTFError.invalidData("accessor \(index) has a negative count") }
        return (accessor, componentType, elementType)
    }

    /// Reads accessor `index` as floats (normalized integers mapped to [0, 1] or [-1, 1], other
    /// integers converted as is), flattened: `count * components` values.
    mutating func readFloats(_ index: Int, allowed: Set<ElementType>, what: String) throws -> (values: [Float], components: Int) {
        let (accessor, componentType, elementType) = try accessorDescription(index)
        guard allowed.contains(elementType) else {
            throw GLTFError.invalidData("\(what) (accessor \(index)) has type \(elementType.rawValue), expected \(allowed.map(\.rawValue).sorted().joined(separator: " or "))")
        }
        guard ![.mat2, .mat3, .mat4].contains(elementType) || componentType == .float else {
            throw GLTFError.invalidData("\(what): integer matrix accessors are not supported")
        }
        let components = elementType.components
        let normalized = accessor.normalized ?? false
        if normalized && (componentType == .float || componentType == .unsignedInt) {
            throw GLTFError.invalidData("accessor \(index): normalized \(componentType) is not allowed")
        }
        let convert = Self.floatConverter(componentType, normalized: normalized)
        var values: [Float]
        if let viewIndex = accessor.bufferView {
            let (bytes, stride) = try bufferView(viewIndex)
            values = try gather(bytes, offset: accessor.byteOffset ?? 0, stride: stride, count: accessor.count,
                                components: components, type: componentType, what: "accessor \(index)", convert)
        } else {
            guard accessor.count <= Self.maxZeroFilledComponents / components else {
                throw GLTFError.invalidData("accessor \(index) without a buffer view claims \(accessor.count) elements")
            }
            values = [Float](repeating: 0, count: accessor.count * components)
        }
        if let sparse = accessor.sparse {
            let targets = try sparseIndices(sparse, accessorIndex: index, count: accessor.count)
            let (bytes, _) = try bufferView(sparse.values.bufferView)
            let replacements = try gather(bytes, offset: sparse.values.byteOffset ?? 0, stride: nil, count: targets.count,
                                          components: components, type: componentType,
                                          what: "sparse values of accessor \(index)", convert)
            for (k, target) in targets.enumerated() {
                for c in 0..<components { values[target * components + c] = replacements[k * components + c] }
            }
        }
        return (values, components)
    }

    /// Reads a SCALAR unsigned-integer accessor (indices) exactly.
    mutating func readIndices(_ index: Int, what: String) throws -> [UInt32] {
        let (accessor, componentType, elementType) = try accessorDescription(index)
        guard elementType == .scalar, [.unsignedByte, .unsignedShort, .unsignedInt].contains(componentType) else {
            throw GLTFError.invalidData("\(what) (accessor \(index)) must be SCALAR unsigned byte, short or int")
        }
        var values: [UInt32]
        if let viewIndex = accessor.bufferView {
            let (bytes, stride) = try bufferView(viewIndex)
            values = try gather(bytes, offset: accessor.byteOffset ?? 0, stride: stride, count: accessor.count, components: 1,
                                type: componentType, what: "accessor \(index)") { Self.readUInt($0, componentType) }
        } else {
            guard accessor.count <= Self.maxZeroFilledComponents else {
                throw GLTFError.invalidData("accessor \(index) without a buffer view claims \(accessor.count) elements")
            }
            values = [UInt32](repeating: 0, count: accessor.count)
        }
        if let sparse = accessor.sparse {
            let targets = try sparseIndices(sparse, accessorIndex: index, count: accessor.count)
            let (bytes, _) = try bufferView(sparse.values.bufferView)
            let replacements = try gather(bytes, offset: sparse.values.byteOffset ?? 0, stride: nil, count: targets.count,
                                          components: 1, type: componentType,
                                          what: "sparse values of accessor \(index)") { Self.readUInt($0, componentType) }
            for (k, target) in targets.enumerated() { values[target] = replacements[k] }
        }
        return values
    }

    private mutating func sparseIndices(_ sparse: GLTFDocument.Accessor.Sparse, accessorIndex: Int, count: Int) throws -> [Int] {
        guard sparse.count >= 1, sparse.count <= count else {
            throw GLTFError.invalidData("accessor \(accessorIndex): sparse count \(sparse.count) outside 1...\(count)")
        }
        guard let type = ComponentType(rawValue: sparse.indices.componentType),
              [.unsignedByte, .unsignedShort, .unsignedInt].contains(type) else {
            throw GLTFError.invalidData("accessor \(accessorIndex): sparse indices must be unsigned byte, short or int")
        }
        let (bytes, _) = try bufferView(sparse.indices.bufferView)
        let targets = try gather(bytes, offset: sparse.indices.byteOffset ?? 0, stride: nil, count: sparse.count, components: 1,
                                 type: type, what: "sparse indices of accessor \(accessorIndex)") { Int(Self.readUInt($0, type)) }
        if targets.contains(where: { $0 >= count }) {
            throw GLTFError.invalidData("accessor \(accessorIndex): sparse index out of range")
        }
        return targets
    }

    private static func readUInt(_ p: UnsafeRawPointer, _ type: ComponentType) -> UInt32 {
        switch type {
        case .unsignedByte: return UInt32(p.load(as: UInt8.self))
        case .unsignedShort: return UInt32(UInt16(littleEndian: p.loadUnaligned(as: UInt16.self)))
        default: return UInt32(littleEndian: p.loadUnaligned(as: UInt32.self))
        }
    }

    private static func floatConverter(_ type: ComponentType, normalized: Bool) -> (UnsafeRawPointer) -> Float {
        switch (type, normalized) {
        case (.float, _): return { Float(bitPattern: UInt32(littleEndian: $0.loadUnaligned(as: UInt32.self))) }
        case (.byte, false): return { Float($0.load(as: Int8.self)) }
        case (.byte, true): return { max(Float($0.load(as: Int8.self)) / 127, -1) }
        case (.unsignedByte, false): return { Float($0.load(as: UInt8.self)) }
        case (.unsignedByte, true): return { Float($0.load(as: UInt8.self)) / 255 }
        case (.short, false): return { Float(Int16(littleEndian: $0.loadUnaligned(as: Int16.self))) }
        case (.short, true): return { max(Float(Int16(littleEndian: $0.loadUnaligned(as: Int16.self))) / 32767, -1) }
        case (.unsignedShort, false): return { Float(UInt16(littleEndian: $0.loadUnaligned(as: UInt16.self))) }
        case (.unsignedShort, true): return { Float(UInt16(littleEndian: $0.loadUnaligned(as: UInt16.self))) / 65535 }
        case (.unsignedInt, _): return { Float(UInt32(littleEndian: $0.loadUnaligned(as: UInt32.self))) }
        }
    }

    // MARK: Images, textures, materials

    private mutating func image(_ index: Int) throws -> ImportedImage {
        let desc = document.images![index]
        let what = "image \(index)"
        if let uri = desc.uri {
            let (data, dataMime) = try resolver.data(for: uri, what: what)
            let shownURI = uri.hasPrefix("data:") ? String(uri.prefix(while: { $0 != "," })) : uri
            let mime = desc.mimeType ?? dataMime ?? Self.mimeType(extension: (uri as NSString).pathExtension) ?? Self.sniffMimeType(data)
            return ImportedImage(name: desc.name, mimeType: mime, uri: shownURI, data: data)
        }
        guard let view = desc.bufferView else { throw GLTFError.invalidData("\(what) has neither a uri nor a bufferView") }
        let bytes = try bufferView(view).bytes
        let data = Data(bytes)
        return ImportedImage(name: desc.name, mimeType: desc.mimeType ?? Self.sniffMimeType(data), uri: nil, data: data)
    }

    static func mimeType(extension ext: String) -> String? {
        switch ext.lowercased() {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "webp": return "image/webp"
        case "ktx2": return "image/ktx2"
        default: return nil
        }
    }

    static func sniffMimeType(_ data: Data) -> String? {
        let b = [UInt8](data.prefix(12))
        if b.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
        if b.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
        if b.count >= 12, b.starts(with: Array("RIFF".utf8)), Array(b[8..<12]) == Array("WEBP".utf8) { return "image/webp" }
        if b.starts(with: [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x32, 0x30]) { return "image/ktx2" }
        return nil
    }

    private mutating func texture(_ index: Int, _ desc: GLTFDocument.Texture) throws -> ImportedTexture {
        var sampler = ImportedSampler()
        if let samplerIndex = desc.sampler {
            guard let s = document.samplers?[safe: samplerIndex] else {
                throw GLTFError.invalidData("texture \(index) uses sampler \(samplerIndex), which doesn't exist")
            }
            sampler = try Self.sampler(s, index: samplerIndex)
            if sampler.wrapU != sampler.wrapV {
                warn("Sampler \(samplerIndex) has different U and V wrap modes; the engine uses the U mode for both")
            }
        }
        if let source = desc.source, source < 0 || source >= (document.images?.count ?? 0) {
            throw GLTFError.invalidData("texture \(index) uses image \(source), which doesn't exist")
        }
        if desc.source == nil { warn("Texture \(index) has no supported image source") }
        return ImportedTexture(name: desc.name, image: desc.source, sampler: sampler)
    }

    static func sampler(_ s: GLTFDocument.Sampler, index: Int) throws -> ImportedSampler {
        func wrap(_ value: Int?) throws -> SamplerAddressMode {
            switch value {
            case nil, 10497: return .repeat
            case 33071: return .clampToEdge
            case 33648: return .mirrorRepeat
            case let v?: throw GLTFError.invalidData("sampler \(index) has unknown wrap mode \(v)")
            }
        }
        var result = ImportedSampler(wrapU: try wrap(s.wrapS), wrapV: try wrap(s.wrapT))
        switch s.magFilter {
        case nil, 9729: result.magFilter = .linear
        case 9728: result.magFilter = .nearest
        case let v?: throw GLTFError.invalidData("sampler \(index) has unknown magFilter \(v)")
        }
        switch s.minFilter {
        case nil: (result.minFilter, result.mipFilter) = (.linear, .linear)
        case 9728: (result.minFilter, result.mipFilter) = (.nearest, .none)
        case 9729: (result.minFilter, result.mipFilter) = (.linear, .none)
        case 9984: (result.minFilter, result.mipFilter) = (.nearest, .nearest)  // NEAREST_MIPMAP_NEAREST
        case 9985: (result.minFilter, result.mipFilter) = (.linear, .nearest)   // LINEAR_MIPMAP_NEAREST
        case 9986: (result.minFilter, result.mipFilter) = (.nearest, .linear)   // NEAREST_MIPMAP_LINEAR
        case 9987: (result.minFilter, result.mipFilter) = (.linear, .linear)    // LINEAR_MIPMAP_LINEAR
        case let v?: throw GLTFError.invalidData("sampler \(index) has unknown minFilter \(v)")
        }
        return result
    }

    private mutating func textureReference(_ info: GLTFDocument.TextureInfo?, material: Int, slot: String) throws -> TextureReference? {
        guard let info else { return nil }
        guard info.index >= 0, info.index < (document.textures?.count ?? 0) else {
            throw GLTFError.invalidData("material \(material) \(slot) uses texture \(info.index), which doesn't exist")
        }
        var reference = TextureReference(texture: info.index, texCoord: info.texCoord ?? 0)
        if let t = info.extensions?.KHR_texture_transform {
            let offset = try Self.vector(t.offset, count: 2, what: "KHR_texture_transform offset") ?? [0, 0]
            let scale = try Self.vector(t.scale, count: 2, what: "KHR_texture_transform scale") ?? [1, 1]
            reference.transform = TextureTransform(offset: Vec2(offset[0], offset[1]), rotation: t.rotation ?? 0,
                                                   scale: Vec2(scale[0], scale[1]), texCoord: t.texCoord)
        }
        let set = reference.transform?.texCoord ?? reference.texCoord
        if set > 1 { warn("Material \(material) \(slot) uses TEXCOORD_\(set); only TEXCOORD_0 and TEXCOORD_1 are imported") }
        return reference
    }

    private mutating func material(_ index: Int, _ desc: GLTFDocument.Material) throws -> ImportedMaterial {
        var m = ImportedMaterial(name: desc.name)
        if let pbr = desc.pbrMetallicRoughness {
            if let c = try Self.vector(pbr.baseColorFactor, count: 4, what: "material \(index) baseColorFactor") {
                m.baseColorFactor = Vec4(c[0], c[1], c[2], c[3])
            }
            m.baseColorTexture = try textureReference(pbr.baseColorTexture, material: index, slot: "baseColorTexture")
            m.metallicFactor = pbr.metallicFactor ?? 1
            m.roughnessFactor = pbr.roughnessFactor ?? 1
            m.metallicRoughnessTexture = try textureReference(pbr.metallicRoughnessTexture, material: index, slot: "metallicRoughnessTexture")
        }
        m.normalTexture = try textureReference(desc.normalTexture, material: index, slot: "normalTexture")
        m.normalScale = desc.normalTexture?.scale ?? 1
        m.occlusionTexture = try textureReference(desc.occlusionTexture, material: index, slot: "occlusionTexture")
        m.occlusionStrength = desc.occlusionTexture?.strength ?? 1
        m.emissiveTexture = try textureReference(desc.emissiveTexture, material: index, slot: "emissiveTexture")
        if let e = try Self.vector(desc.emissiveFactor, count: 3, what: "material \(index) emissiveFactor") {
            m.emissiveFactor = Vec3(e[0], e[1], e[2])
        }
        m.emissiveStrength = desc.extensions?.KHR_materials_emissive_strength?.emissiveStrength ?? 1
        if let mode = desc.alphaMode {
            guard let alphaMode = AlphaMode(rawValue: mode) else {
                throw GLTFError.invalidData("material \(index) has unknown alphaMode \(mode)")
            }
            m.alphaMode = alphaMode
        }
        m.alphaCutoff = desc.alphaCutoff ?? 0.5
        m.doubleSided = desc.doubleSided ?? false
        m.unlit = desc.extensions?.KHR_materials_unlit != nil
        return m
    }

    private static func vector(_ values: [Float]?, count: Int, what: String) throws -> [Float]? {
        guard let values else { return nil }
        guard values.count == count else { throw GLTFError.invalidData("\(what) has \(values.count) values, expected \(count)") }
        return values
    }

    // MARK: Meshes

    private mutating func mesh(_ index: Int, _ desc: GLTFDocument.Mesh, materialCount: Int) throws -> ImportedMesh {
        var primitives: [ImportedPrimitive] = []
        for (p, primitive) in desc.primitives.enumerated() {
            if let converted = try self.primitive(primitive, what: "mesh \(index) primitive \(p)", materialCount: materialCount) {
                primitives.append(converted)
            }
        }
        return ImportedMesh(name: desc.name, primitives: primitives)
    }

    /// Converts one primitive to an indexed triangle list, or nil (with a warning) for modes
    /// the engine can't draw.
    private mutating func primitive(_ desc: GLTFDocument.Primitive, what: String, materialCount: Int) throws -> ImportedPrimitive? {
        let mode = desc.mode ?? 4
        switch mode {
        case 4, 5, 6: break
        case 0...3:
            warn("\(what): \(["points", "lines", "line loops", "line strips"][mode]) are not supported and were skipped")
            return nil
        default:
            throw GLTFError.invalidData("\(what) has unknown mode \(mode)")
        }
        if let material = desc.material, material < 0 || material >= materialCount {
            throw GLTFError.invalidData("\(what) uses material \(material), which doesn't exist")
        }
        guard let positionAccessor = desc.attributes["POSITION"] else {
            warn("\(what) has no POSITION attribute and was skipped")
            return nil
        }
        let positions = try readFloats(positionAccessor, allowed: [.vec3], what: "\(what) POSITION").values
        let vertexCount = positions.count / 3
        guard vertexCount <= Int(UInt32.max) else { throw GLTFError.invalidData("\(what) has too many vertices") }

        func attribute(_ name: String, _ allowed: Set<ElementType>) throws -> (values: [Float], components: Int)? {
            guard let accessor = desc.attributes[name] else { return nil }
            let result = try readFloats(accessor, allowed: allowed, what: "\(what) \(name)")
            guard result.values.count / result.components == vertexCount else {
                throw GLTFError.invalidData("\(what) \(name) has \(result.values.count / result.components) elements, POSITION has \(vertexCount)")
            }
            return result
        }
        let normals = try attribute("NORMAL", [.vec3])
        let uv0 = try attribute("TEXCOORD_0", [.vec2])
        let uv1 = try attribute("TEXCOORD_1", [.vec2])
        let tangents = try attribute("TANGENT", [.vec4])
        let colors = try attribute("COLOR_0", [.vec3, .vec4])
        if desc.attributes.keys.contains(where: { $0.hasPrefix("JOINTS_") || $0.hasPrefix("WEIGHTS_") }) {
            warn("Skinning attributes (JOINTS_n / WEIGHTS_n) are ignored")
        }

        var indices: [UInt32]
        if let indexAccessor = desc.indices {
            indices = try readIndices(indexAccessor, what: "\(what) indices")
            if let bad = indices.first(where: { Int($0) >= vertexCount }) {
                throw GLTFError.invalidData("\(what) index \(bad) is out of range (\(vertexCount) vertices)")
            }
        } else {
            indices = (0..<UInt32(vertexCount)).map { $0 }
        }
        indices = Self.triangulate(indices, mode: mode)
        if indices.count % 3 != 0 {
            warn("\(what): index count isn't a multiple of 3; the extra indices were dropped")
            indices.removeLast(indices.count % 3)
        }

        var vertices = (0..<vertexCount).map { i in
            MeshVertex(position: Vec3(positions[i * 3], positions[i * 3 + 1], positions[i * 3 + 2]), normal: .zero,
                       uv: uv0.map { Vec2($0.values[i * 2], $0.values[i * 2 + 1]) } ?? .zero)
        }
        var extraTangents = tangents.map { t in (0..<vertexCount).map { Vec4(t.values[$0 * 4], t.values[$0 * 4 + 1], t.values[$0 * 4 + 2], t.values[$0 * 4 + 3]) } }
        var extraUV1 = uv1.map { t in (0..<vertexCount).map { Vec2(t.values[$0 * 2], t.values[$0 * 2 + 1]) } }
        var extraColors = colors.map { c in
            (0..<vertexCount).map { i in
                c.components == 4
                    ? Vec4(c.values[i * 4], c.values[i * 4 + 1], c.values[i * 4 + 2], c.values[i * 4 + 3])
                    : Vec4(c.values[i * 3], c.values[i * 3 + 1], c.values[i * 3 + 2], 1)
            }
        }

        if let normals {
            for i in 0..<vertexCount {
                vertices[i].normal = normalize(Vec3(normals.values[i * 3], normals.values[i * 3 + 1], normals.values[i * 3 + 2]))
            }
            // The file's tangents count only with its normals (glTF: generated normals ignore them).
            if let extraTangents {
                for i in 0..<vertexCount {
                    let t = extraTangents[i]
                    let xyz = Vec3(t.x, t.y, t.z), len = length(xyz)
                    if len > 0 && len.isFinite { vertices[i].tangent = Vec4(xyz / len, t.w < 0 ? -1 : 1) }
                }
            }
        } else if options.normals == .flat {
            // Unweld: each triangle gets its own three vertices and its face normal.
            func unweld<T>(_ values: [T]?) -> [T]? { values.map { v in indices.map { v[Int($0)] } } }
            vertices = indices.map { vertices[Int($0)] }
            extraTangents = unweld(extraTangents)
            extraUV1 = unweld(extraUV1)
            extraColors = unweld(extraColors)
            indices = (0..<UInt32(vertices.count)).map { $0 }
            for t in stride(from: 0, to: vertices.count, by: 3) {
                let n = Self.faceNormal(vertices[t].position, vertices[t + 1].position, vertices[t + 2].position)
                for k in t..<(t + 3) { vertices[k].normal = n }
            }
        } else {
            Self.smoothNormals(&vertices, indices: indices)
        }

        return ImportedPrimitive(
            geometry: MeshGeometry(vertices: vertices, indices: indices), tangents: extraTangents, texCoords1: extraUV1,
            colors: extraColors, material: desc.material, generatedNormals: normals == nil)
    }

    /// Triangle strips and fans to a triangle list, keeping counter-clockwise winding.
    static func triangulate(_ indices: [UInt32], mode: Int) -> [UInt32] {
        guard indices.count >= 3 else { return mode == 4 ? indices : [] }
        switch mode {
        case 5:  // Strip: odd triangles swap their first two vertices.
            var out: [UInt32] = []
            out.reserveCapacity((indices.count - 2) * 3)
            for i in 0..<(indices.count - 2) {
                if i % 2 == 0 { out += [indices[i], indices[i + 1], indices[i + 2]] }
                else { out += [indices[i + 1], indices[i], indices[i + 2]] }
            }
            return out
        case 6:  // Fan around the first vertex.
            var out: [UInt32] = []
            out.reserveCapacity((indices.count - 2) * 3)
            for i in 1..<(indices.count - 1) { out += [indices[i], indices[i + 1], indices[0]] }
            return out
        default:
            return indices
        }
    }

    /// The unit normal of a counter-clockwise triangle (+Y for degenerate ones).
    static func faceNormal(_ a: Vec3, _ b: Vec3, _ c: Vec3) -> Vec3 {
        let n = cross(b - a, c - a)
        let len = length(n)
        return len > 0 && len.isFinite ? n / len : Vec3(0, 1, 0)
    }

    /// Area-weighted vertex normals, shared by all vertices at the same position (so seams
    /// from split UVs don't show).
    static func smoothNormals(_ vertices: inout [MeshVertex], indices: [UInt32]) {
        var slot: [SIMD3<UInt32>: Int] = [:]
        var group = [Int](repeating: 0, count: vertices.count)
        for i in vertices.indices {
            let p = vertices[i].position
            let key = SIMD3(p.x.bitPattern, p.y.bitPattern, p.z.bitPattern)
            if let s = slot[key] { group[i] = s } else { group[i] = slot.count; slot[key] = slot.count }
        }
        var sums = [Vec3](repeating: .zero, count: slot.count)
        for t in stride(from: 0, to: indices.count, by: 3) {
            let (a, b, c) = (Int(indices[t]), Int(indices[t + 1]), Int(indices[t + 2]))
            // The unnormalized cross product weights by area.
            let n = cross(vertices[b].position - vertices[a].position, vertices[c].position - vertices[a].position)
            for v in [a, b, c] { sums[group[v]] += n }
        }
        for i in vertices.indices {
            let n = sums[group[i]]
            let len = length(n)
            vertices[i].normal = len > 0 && len.isFinite ? n / len : Vec3(0, 1, 0)
        }
    }

    // MARK: Nodes and scenes

    private mutating func buildNodes(into model: inout ImportedModel) throws {
        let docNodes = document.nodes ?? []
        var nodes: [ImportedNode] = []
        nodes.reserveCapacity(docNodes.count)
        for (i, node) in docNodes.enumerated() {
            if let mesh = node.mesh, mesh < 0 || mesh >= model.meshes.count {
                throw GLTFError.invalidData("node \(i) uses mesh \(mesh), which doesn't exist")
            }
            nodes.append(ImportedNode(name: node.name, transform: try Self.transform(node, index: i), mesh: node.mesh,
                                      children: node.children ?? []))
        }
        for i in nodes.indices {
            for child in nodes[i].children {
                guard child >= 0, child < nodes.count else { throw GLTFError.invalidData("node \(i) has child \(child), which doesn't exist") }
                guard nodes[child].parent == nil, child != i else {
                    throw GLTFError.invalidData("node \(child) has more than one parent")
                }
                nodes[child].parent = i
            }
        }
        // With at most one parent each, a cycle shows up as a parent chain longer than the node count.
        for i in nodes.indices {
            var current = i, steps = 0
            while let parent = nodes[current].parent {
                current = parent
                steps += 1
                if steps > nodes.count { throw GLTFError.invalidData("the node hierarchy has a cycle through node \(i)") }
            }
        }
        model.nodes = nodes

        model.scenes = try (document.scenes ?? []).enumerated().map { s, scene in
            let roots = scene.nodes ?? []
            for root in roots where root < 0 || root >= nodes.count {
                throw GLTFError.invalidData("scene \(s) lists node \(root), which doesn't exist")
            }
            for root in roots where nodes[root].parent != nil {
                warn("Scene \(s) lists node \(root), which isn't a root node; it was skipped")
            }
            return ImportedSceneInfo(name: scene.name, roots: roots.filter { nodes[$0].parent == nil })
        }
        let selected = options.scene ?? document.scene ?? (model.scenes.isEmpty ? nil : 0)
        if let selected {
            guard selected >= 0, selected < model.scenes.count else {
                throw GLTFError.invalidData("scene \(selected) doesn't exist (\(model.scenes.count) scenes)")
            }
            model.sceneIndex = selected
            model.roots = model.scenes[selected].roots
        } else {
            model.roots = nodes.indices.filter { nodes[$0].parent == nil }
        }
    }

    /// A node whose world matrix mirrors (negative determinant) turns its triangles clockwise
    /// on screen, so back-face culling would show it inside out. glTF says to flip the winding
    /// there: such nodes get a copy of their mesh with reversed triangles (shared between all
    /// mirrored users of that mesh). Only the selected scene is checked.
    private func flipMirroredMeshes(_ model: inout ImportedModel) {
        var flipped: [Int: Int] = [:]
        var stack = model.roots.map { ($0, Mat4.identity) }
        while let (index, parentMatrix) = stack.popLast() {
            let matrix = parentMatrix * model.nodes[index].transform.matrix
            stack += model.nodes[index].children.map { ($0, matrix) }
            guard let mesh = model.nodes[index].mesh else { continue }
            let c0 = Vec3(matrix.c0.x, matrix.c0.y, matrix.c0.z), c1 = Vec3(matrix.c1.x, matrix.c1.y, matrix.c1.z)
            let c2 = Vec3(matrix.c2.x, matrix.c2.y, matrix.c2.z)
            guard dot(cross(c0, c1), c2) < 0 else { continue }
            if flipped[mesh] == nil {
                var copy = model.meshes[mesh]
                copy.name = copy.name.map { "\($0) (mirrored)" }
                for p in copy.primitives.indices {
                    var indices = copy.primitives[p].geometry.indices
                    for t in stride(from: 0, to: indices.count - 2, by: 3) { indices.swapAt(t + 1, t + 2) }
                    copy.primitives[p].geometry.indices = indices
                }
                model.meshes.append(copy)
                flipped[mesh] = model.meshes.count - 1
            }
            model.nodes[index].mesh = flipped[mesh]
        }
    }

    static func transform(_ node: GLTFDocument.Node, index: Int) throws -> Transform {
        if let m = node.matrix {
            guard m.count == 16 else { throw GLTFError.invalidData("node \(index) matrix has \(m.count) values, expected 16") }
            if node.translation != nil || node.rotation != nil || node.scale != nil {
                throw GLTFError.invalidData("node \(index) has both a matrix and TRS properties")
            }
            // Column-major, like Mat4.
            return Transform(matrix: Mat4(Vec4(m[0], m[1], m[2], m[3]), Vec4(m[4], m[5], m[6], m[7]),
                                          Vec4(m[8], m[9], m[10], m[11]), Vec4(m[12], m[13], m[14], m[15])))
        }
        let t = try vector(node.translation, count: 3, what: "node \(index) translation") ?? [0, 0, 0]
        let r = try vector(node.rotation, count: 4, what: "node \(index) rotation") ?? [0, 0, 0, 1]
        let s = try vector(node.scale, count: 3, what: "node \(index) scale") ?? [1, 1, 1]
        // glTF quaternions are (x, y, z, w), like Quat.
        return Transform(position: Vec3(t[0], t[1], t[2]), rotation: Quat(r[0], r[1], r[2], r[3]).normalized,
                         scale: Vec3(s[0], s[1], s[2]))
    }
}

fileprivate extension Array {
    /// The element at `index`, or nil when it's out of range.
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
