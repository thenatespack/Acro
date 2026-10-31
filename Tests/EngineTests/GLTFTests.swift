import Foundation
import Testing
@testable import Engine

// MARK: A tiny glTF writer for test files

/// Builds glTF documents in memory: binary data goes into one buffer, and the JSON is
/// assembled from dictionaries. Write it out as GLB, as .gltf with a base64 data URI, or as
/// .gltf plus an external .bin.
private struct GLTFBuilder {
    var bin: [UInt8] = []
    var json: [String: Any] = ["asset": ["version": "2.0", "generator": "GLTFTests"]]
    var bufferViews: [[String: Any]] = []
    var accessors: [[String: Any]] = []
    var meshes: [[String: Any]] = []
    var nodes: [[String: Any]] = []
    var materials: [[String: Any]] = []
    var textures: [[String: Any]] = []
    var images: [[String: Any]] = []
    var samplers: [[String: Any]] = []
    var scenes: [[String: Any]]? = nil
    var scene: Int? = nil

    /// Appends raw bytes (4-byte aligned) as a buffer view and returns its index.
    mutating func addView(_ bytes: [UInt8], stride: Int? = nil) -> Int {
        while bin.count % 4 != 0 { bin.append(0) }
        var view: [String: Any] = ["buffer": 0, "byteOffset": bin.count, "byteLength": bytes.count]
        if let stride { view["byteStride"] = stride }
        bin += bytes
        bufferViews.append(view)
        return bufferViews.count - 1
    }

    static func bytes<T: BitwiseCopyable>(_ values: [T]) -> [UInt8] {
        values.withUnsafeBytes { Array($0) }
    }

    mutating func addAccessor(view: Int?, offset: Int = 0, componentType: Int, count: Int, type: String,
                              normalized: Bool = false, extra: [String: Any] = [:]) -> Int {
        var accessor: [String: Any] = ["componentType": componentType, "count": count, "type": type]
        if let view { accessor["bufferView"] = view }
        if offset != 0 { accessor["byteOffset"] = offset }
        if normalized { accessor["normalized"] = true }
        accessor.merge(extra) { $1 }
        accessors.append(accessor)
        return accessors.count - 1
    }

    mutating func floats(_ values: [Float], type: String) -> Int {
        let components = ["SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4][type]!
        return addAccessor(view: addView(Self.bytes(values)), componentType: 5126, count: values.count / components, type: type)
    }

    mutating func vec3s(_ values: [Vec3]) -> Int { floats(values.flatMap { [$0.x, $0.y, $0.z] }, type: "VEC3") }
    mutating func vec2s(_ values: [Vec2]) -> Int { floats(values.flatMap { [$0.x, $0.y] }, type: "VEC2") }

    mutating func indices<T: FixedWidthInteger & BitwiseCopyable>(_ values: [T]) -> Int {
        let type = [1: 5121, 2: 5123, 4: 5125][MemoryLayout<T>.size]!
        return addAccessor(view: addView(Self.bytes(values)), componentType: type, count: values.count, type: "SCALAR")
    }

    /// Adds a mesh with the given primitives and returns its index.
    mutating func mesh(_ primitives: [[String: Any]], name: String? = nil) -> Int {
        var mesh: [String: Any] = ["primitives": primitives]
        if let name { mesh["name"] = name }
        meshes.append(mesh)
        return meshes.count - 1
    }

    mutating func node(_ properties: [String: Any]) -> Int {
        nodes.append(properties)
        return nodes.count - 1
    }

    func document(bufferURI: String?) -> [String: Any] {
        var doc = json
        func put(_ key: String, _ value: [[String: Any]]) { if !value.isEmpty { doc[key] = value } }
        put("bufferViews", bufferViews)
        put("accessors", accessors)
        put("meshes", meshes)
        put("nodes", nodes)
        put("materials", materials)
        put("textures", textures)
        put("images", images)
        put("samplers", samplers)
        if let scenes { doc["scenes"] = scenes } else if !nodes.isEmpty {
            let children = Set(nodes.flatMap { ($0["children"] as? [Int]) ?? [] })
            doc["scenes"] = [["nodes": nodes.indices.filter { !children.contains($0) }]]
        }
        if let scene { doc["scene"] = scene }
        if !bin.isEmpty {
            var buffer: [String: Any] = ["byteLength": bin.count]
            if let bufferURI { buffer["uri"] = bufferURI }
            doc["buffers"] = [buffer]
        }
        return doc
    }

    static func jsonData(_ object: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    /// .gltf JSON with the buffer embedded as a base64 data URI.
    func gltf() -> Data {
        Self.jsonData(document(bufferURI: "data:application/octet-stream;base64," + Data(bin).base64EncodedString()))
    }

    /// .gltf JSON referencing `binName`; returns the JSON and the .bin contents.
    func gltf(external binName: String) -> (json: Data, bin: Data) {
        (Self.jsonData(document(bufferURI: binName)), Data(bin))
    }

    /// A binary .glb container.
    func glb() -> Data {
        var json = [UInt8](Self.jsonData(document(bufferURI: nil)))
        while json.count % 4 != 0 { json.append(0x20) }
        var binChunk = bin
        while binChunk.count % 4 != 0 { binChunk.append(0) }
        var out: [UInt8] = []
        func u32(_ v: Int) { out += Self.bytes([UInt32(v).littleEndian]) }
        let total = 12 + 8 + json.count + (binChunk.isEmpty ? 0 : 8 + binChunk.count)
        out += Array("glTF".utf8); u32(2); u32(total)
        u32(json.count); out += Array("JSON".utf8); out += json
        if !binChunk.isEmpty { u32(binChunk.count); out += Array("BIN".utf8) + [0]; out += binChunk }
        return Data(out)
    }

    /// A unit quad in the XY plane facing +Z (two counter-clockwise triangles), with UVs whose
    /// origin is the top-left corner. Returns the primitive dictionary.
    mutating func quadPrimitive(normals: Bool = true, uvs: Bool = true, material: Int? = nil) -> [String: Any] {
        var attributes: [String: Any] = [
            "POSITION": vec3s([Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(1, 1, 0), Vec3(0, 1, 0)]),
        ]
        if normals { attributes["NORMAL"] = vec3s(Array(repeating: Vec3(0, 0, 1), count: 4)) }
        if uvs { attributes["TEXCOORD_0"] = vec2s([Vec2(0, 1), Vec2(1, 1), Vec2(1, 0), Vec2(0, 0)]) }
        var primitive: [String: Any] = ["attributes": attributes, "indices": indices([UInt16(0), 1, 2, 0, 2, 3])]
        if let material { primitive["material"] = material }
        return primitive
    }

    /// One node showing a quad mesh.
    static func quadModel(normals: Bool = true) -> GLTFBuilder {
        var b = GLTFBuilder()
        let mesh = b.mesh([b.quadPrimitive(normals: normals)], name: "Quad")
        _ = b.node(["mesh": mesh, "name": "QuadNode"])
        return b
    }
}

private func approx(_ a: Float, _ b: Float, _ eps: Float = 1e-5) -> Bool { abs(a - b) <= eps }
private func approx(_ a: Vec3, _ b: Vec3, _ eps: Float = 1e-4) -> Bool { length(a - b) <= eps }
private func approx(_ a: Vec4, _ b: Vec4, _ eps: Float = 1e-4) -> Bool { let d = a - b; return max(max(abs(d.x), abs(d.y)), max(abs(d.z), abs(d.w))) <= eps }
private func approx(_ a: Mat4, _ b: Mat4, _ eps: Float = 1e-4) -> Bool {
    approx(a.c0, b.c0, eps) && approx(a.c1, b.c1, eps) && approx(a.c2, b.c2, eps) && approx(a.c3, b.c3, eps)
}

private func resource(_ name: String) throws -> URL {
    try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Resources/glTF"))
}

/// Every triangle's winding normal points the same way as its vertex normals (true for
/// well-formed files, and what the engine's counter-clockwise front faces rely on).
private func windingMatchesNormals(_ geometry: MeshGeometry) -> Bool {
    let v = geometry.vertices, i = geometry.indices
    for t in stride(from: 0, to: i.count, by: 3) {
        let (a, b, c) = (v[Int(i[t])], v[Int(i[t + 1])], v[Int(i[t + 2])])
        let face = cross(b.position - a.position, c.position - a.position)
        if length(face) < 1e-9 { continue }
        if dot(face, a.normal + b.normal + c.normal) <= 0 { return false }
    }
    return true
}

private func quadGeometryIsUnchanged(_ model: ImportedModel) -> Bool {
    guard model.meshes.count == 1, let primitive = model.meshes[0].primitives.first else { return false }
    let g = primitive.geometry
    return g.indices == [0, 1, 2, 0, 2, 3]
        && g.vertices.map(\.position) == [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(1, 1, 0), Vec3(0, 1, 0)]
        && g.vertices.map(\.uv) == [Vec2(0, 1), Vec2(1, 1), Vec2(1, 0), Vec2(0, 0)]
        && g.vertices.allSatisfy { $0.normal == Vec3(0, 0, 1) }
}

@Suite struct GLTFTests {
    // MARK: Containers and URIs

    @Test func readsGLB() throws {
        let data = GLTFBuilder.quadModel().glb()
        #expect(GLTFReader.isGLB(data))
        let model = try GLTFReader.read(data: data)
        #expect(quadGeometryIsUnchanged(model))
        #expect(model.nodes.count == 1 && model.nodes[0].name == "QuadNode" && model.roots == [0])
        #expect(model.meshes[0].name == "Quad")
        #expect(model.generator == "GLTFTests")
        #expect(model.warnings.isEmpty)
    }

    @Test func readsGLTFWithDataURI() throws {
        let data = GLTFBuilder.quadModel().gltf()
        #expect(!GLTFReader.isGLB(data))
        #expect(quadGeometryIsUnchanged(try GLTFReader.read(data: data)))
    }

    @Test func readsGLTFWithExternalBufferFromLoaderAndFromDisk() throws {
        let (json, bin) = GLTFBuilder.quadModel().gltf(external: "quad data.bin")
        var requested: [String] = []
        let fromLoader = try GLTFReader.read(data: try #require(String(data: json, encoding: .utf8)?
            .replacingOccurrences(of: "quad data.bin", with: "quad%20data.bin").data(using: .utf8))) { uri in
            requested.append(uri)
            return bin
        }
        #expect(requested == ["quad data.bin"])  // percent-decoded
        #expect(quadGeometryIsUnchanged(fromLoader))

        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("gltf-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try json.write(to: dir.appendingPathComponent("quad.gltf"))
        try bin.write(to: dir.appendingPathComponent("quad data.bin"))
        #expect(quadGeometryIsUnchanged(try GLTFReader.read(contentsOf: dir.appendingPathComponent("quad.gltf"))))

        // Without a loader or base URL the buffer can't be found.
        #expect(throws: GLTFError.self) { try GLTFReader.read(data: json) }
        // A missing file is an error, not a crash.
        try FileManager.default.removeItem(at: dir.appendingPathComponent("quad data.bin"))
        #expect(throws: GLTFError.self) { try GLTFReader.read(contentsOf: dir.appendingPathComponent("quad.gltf")) }
    }

    @Test func rejectsRemoteURIs() throws {
        let (json, _) = GLTFBuilder.quadModel().gltf(external: "https://example.com/quad.bin")
        #expect(throws: GLTFError.self) { try GLTFReader.read(data: json, baseURL: URL(fileURLWithPath: "/tmp")) }
    }

    // MARK: Accessors

    @Test func allIndexTypesAndNonIndexedGiveTheSameTriangles() throws {
        let positions = [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(1, 1, 0), Vec3(0, 1, 0)]
        let order: [Int] = [0, 1, 2, 0, 2, 3]
        func model(_ makeIndices: (inout GLTFBuilder) -> Int?) throws -> MeshGeometry {
            var b = GLTFBuilder()
            var primitive: [String: Any] = ["attributes": ["POSITION": b.vec3s(positions),
                                                           "NORMAL": b.vec3s(Array(repeating: Vec3(0, 0, 1), count: 4))]]
            if let i = makeIndices(&b) { primitive["indices"] = i }
            _ = b.node(["mesh": b.mesh([primitive])])
            return try GLTFReader.read(data: b.glb()).meshes[0].primitives[0].geometry
        }
        let u8 = try model { $0.indices(order.map(UInt8.init)) }
        let u16 = try model { $0.indices(order.map(UInt16.init)) }
        let u32 = try model { $0.indices(order.map(UInt32.init)) }
        #expect(u8.indices == [0, 1, 2, 0, 2, 3] && u16.indices == u8.indices && u32.indices == u8.indices)
        #expect(u8.vertices.map(\.position) == positions)

        // Non-indexed: the triangles are the vertices in order.
        var b = GLTFBuilder()
        let soup = order.map { positions[$0] }
        _ = b.node(["mesh": b.mesh([["attributes": ["POSITION": b.vec3s(soup), "NORMAL": b.vec3s(Array(repeating: Vec3(0, 0, 1), count: 6))]]])])
        let g = try GLTFReader.read(data: b.glb()).meshes[0].primitives[0].geometry
        #expect(g.indices == [0, 1, 2, 3, 4, 5] && g.vertices.map(\.position) == soup)
    }

    @Test func largeUInt32IndicesStayExact() throws {
        // 2^24 + 1 isn't representable as a Float; indices must not go through one.
        var b = GLTFBuilder()
        let accessor = b.indices([UInt32(16_777_217), 3])
        _ = b.mesh([])
        var parser = GLTFParser(document: try JSONDecoder().decode(GLTFDocument.self, from: GLTFBuilder.jsonData(b.document(bufferURI: nil))),
                                binChunk: Data(b.bin), resolver: ResourceResolver(), options: .init())
        #expect(try parser.readIndices(accessor, what: "test") == [16_777_217, 3])
    }

    @Test func interleavedStridedAttributes() throws {
        // position (12 bytes), normal (12), uv (8) interleaved with a 36-byte stride (4 bytes padding).
        let positions = [Vec3(0, 0, 0), Vec3(2, 0, 0), Vec3(0, 3, 0)]
        let uvs = [Vec2(0, 1), Vec2(1, 1), Vec2(0, 0)]
        var bytes: [UInt8] = []
        for i in 0..<3 {
            bytes += GLTFBuilder.bytes([positions[i].x, positions[i].y, positions[i].z, 0, 0, 1, uvs[i].x, uvs[i].y, 99])
        }
        var b = GLTFBuilder()
        let view = b.addView(bytes, stride: 36)
        let pos = b.addAccessor(view: view, componentType: 5126, count: 3, type: "VEC3")
        let nrm = b.addAccessor(view: view, offset: 12, componentType: 5126, count: 3, type: "VEC3")
        let uv = b.addAccessor(view: view, offset: 24, componentType: 5126, count: 3, type: "VEC2")
        _ = b.node(["mesh": b.mesh([["attributes": ["POSITION": pos, "NORMAL": nrm, "TEXCOORD_0": uv]]])])
        let g = try GLTFReader.read(data: b.glb()).meshes[0].primitives[0].geometry
        #expect(g.vertices.map(\.position) == positions)
        #expect(g.vertices.map(\.uv) == uvs)
        #expect(g.vertices.allSatisfy { $0.normal == Vec3(0, 0, 1) })
    }

    @Test func normalizedIntegerAttributes() throws {
        var b = GLTFBuilder()
        let pos = b.vec3s([Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)])
        // Normals as normalized bytes (padded to 4 bytes per element, as the spec requires).
        let nrm = b.addAccessor(view: b.addView(GLTFBuilder.bytes([Int8(0), 0, 127, 0, 0, 0, -128, 0, 127, 0, 0, 0]), stride: 4),
                                componentType: 5120, count: 3, type: "VEC3", normalized: true)
        let uv = b.addAccessor(view: b.addView(GLTFBuilder.bytes([UInt16(0), 65535, 65535, 65535, 0, 0])),
                               componentType: 5123, count: 3, type: "VEC2", normalized: true)
        let uv1 = b.addAccessor(view: b.addView(GLTFBuilder.bytes([UInt8(0), 255, 7, 7, 255, 255, 7, 7, 0, 0, 7, 7]), stride: 4),
                                componentType: 5121, count: 3, type: "VEC2", normalized: true)
        let color = b.addAccessor(view: b.addView(GLTFBuilder.bytes([UInt8(255), 0, 0, 255, 0, 255, 0, 128, 0, 0, 255, 0])),
                                  componentType: 5121, count: 3, type: "VEC4", normalized: true)
        let tangent = b.addAccessor(view: b.addView(GLTFBuilder.bytes([Int16(32767), 0, 0, -32767, 0, 32767, 0, 32767, 0, 0, 32767, 32767])),
                                    componentType: 5122, count: 3, type: "VEC4", normalized: true)
        _ = b.node(["mesh": b.mesh([["attributes": ["POSITION": pos, "NORMAL": nrm, "TEXCOORD_0": uv, "TEXCOORD_1": uv1,
                                                    "COLOR_0": color, "TANGENT": tangent]]])])
        let p = try GLTFReader.read(data: b.glb()).meshes[0].primitives[0]
        #expect(p.geometry.vertices.map(\.normal) == [Vec3(0, 0, 1), Vec3(0, 0, -1), Vec3(1, 0, 0)])
        #expect(p.geometry.vertices.map(\.uv) == [Vec2(0, 1), Vec2(1, 1), Vec2(0, 0)])
        #expect(p.texCoords1 == [Vec2(0, 1), Vec2(1, 1), Vec2(0, 0)])
        let colors = try #require(p.colors)
        #expect(approx(colors[0], Vec4(1, 0, 0, 1)) && approx(colors[1], Vec4(0, 1, 0, 128.0 / 255)) && approx(colors[2], Vec4(0, 0, 1, 0)))
        #expect(p.tangents == [Vec4(1, 0, 0, -1), Vec4(0, 1, 0, 1), Vec4(0, 0, 1, 1)])
        #expect(!p.generatedNormals)
    }

    @Test func rgbVertexColorsGetOpaqueAlpha() throws {
        var b = GLTFBuilder()
        let pos = b.vec3s([Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)])
        let color = b.floats([1, 0, 0, 0, 1, 0, 0, 0, 1], type: "VEC3")
        _ = b.node(["mesh": b.mesh([["attributes": ["POSITION": pos, "COLOR_0": color]]])])
        let p = try GLTFReader.read(data: b.glb()).meshes[0].primitives[0]
        #expect(p.colors == [Vec4(1, 0, 0, 1), Vec4(0, 1, 0, 1), Vec4(0, 0, 1, 1)])
    }

    @Test func sparseAccessors() throws {
        var b = GLTFBuilder()
        let base = b.vec3s([Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(5, 5, 5)])
        // Replace vertex 3 and 1 (indices needn't be in order in this reader).
        let sparseIndices = b.addView(GLTFBuilder.bytes([UInt16(1), 3]))
        let sparseValues = b.addView(GLTFBuilder.bytes([Float(2), 0, 0, 0, 0, 7]))
        b.accessors[base]["sparse"] = ["count": 2, "indices": ["bufferView": sparseIndices, "componentType": 5123],
                                       "values": ["bufferView": sparseValues]]
        // A sparse accessor without a buffer view starts out as zeros.
        let zeroIndices = b.addView([2])
        let zeroValues = b.addView(GLTFBuilder.bytes([Float(0), 0, -1]))
        let normals = b.addAccessor(view: nil, componentType: 5126, count: 4, type: "VEC3", extra: [
            "sparse": ["count": 1, "indices": ["bufferView": zeroIndices, "componentType": 5121], "values": ["bufferView": zeroValues]],
        ])
        _ = b.node(["mesh": b.mesh([["attributes": ["POSITION": base, "NORMAL": normals], "indices": b.indices([UInt8(0), 1, 2])]])])
        let g = try GLTFReader.read(data: b.glb()).meshes[0].primitives[0].geometry
        #expect(g.vertices.map(\.position) == [Vec3(0, 0, 0), Vec3(2, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 7)])
        // Only the sparse normal is set; the others stay zero.
        #expect(g.vertices[2].normal == Vec3(0, 0, -1))
    }

    // MARK: Primitives and normals

    @Test func stripsAndFansBecomeCounterClockwiseLists() throws {
        // A strip and a fan over the same four corners of a quad facing +Z.
        func geometry(mode: Int, order: [Vec3]) throws -> MeshGeometry {
            var b = GLTFBuilder()
            _ = b.node(["mesh": b.mesh([["attributes": ["POSITION": b.vec3s(order)], "mode": mode]])])
            return try GLTFReader.read(data: b.glb(), options: .init(normals: .smooth)).meshes[0].primitives[0].geometry
        }
        let strip = try geometry(mode: 5, order: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(1, 1, 0)])
        #expect(strip.indices == [0, 1, 2, 2, 1, 3])
        let fan = try geometry(mode: 6, order: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(1, 1, 0), Vec3(0, 1, 0)])
        #expect(fan.indices == [1, 2, 0, 2, 3, 0])
        for g in [strip, fan] {
            #expect(g.vertices.allSatisfy { approx($0.normal, Vec3(0, 0, 1)) })
        }
    }

    @Test func pointsAndLinesAreSkippedWithAWarning() throws {
        var b = GLTFBuilder()
        let pos = b.vec3s([Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)])
        _ = b.node(["mesh": b.mesh([["attributes": ["POSITION": pos], "mode": 1], ["attributes": ["POSITION": pos], "mode": 0],
                                    ["attributes": ["POSITION": pos]]])])
        let model = try GLTFReader.read(data: b.glb())
        #expect(model.meshes[0].primitives.count == 1)
        #expect(model.warnings.contains { $0.contains("lines") } && model.warnings.contains { $0.contains("points") })
    }

    @Test func missingNormalsAreGeneratedFlatOrSmooth() throws {
        let b = GLTFBuilder.quadModel(normals: false)
        let flat = try GLTFReader.read(data: b.glb()).meshes[0].primitives[0]
        #expect(flat.generatedNormals)
        // Flat: split into 2 x 3 vertices, each with its face normal (+Z for a counter-clockwise quad in XY).
        #expect(flat.geometry.vertices.count == 6 && flat.geometry.indices == [0, 1, 2, 3, 4, 5])
        #expect(flat.geometry.vertices.allSatisfy { approx($0.normal, Vec3(0, 0, 1)) })
        #expect(flat.geometry.vertices.map(\.uv) == [Vec2(0, 1), Vec2(1, 1), Vec2(1, 0), Vec2(0, 1), Vec2(1, 0), Vec2(0, 0)])

        let smooth = try GLTFReader.read(data: b.glb(), options: .init(normals: .smooth)).meshes[0].primitives[0]
        #expect(smooth.geometry.vertices.count == 4 && smooth.geometry.indices == [0, 1, 2, 0, 2, 3])
        #expect(smooth.geometry.vertices.allSatisfy { approx($0.normal, Vec3(0, 0, 1)) })
    }

    @Test func smoothNormalsAverageAcrossSplitVertices() throws {
        // Two triangles of a roof meeting at the ridge, with separate (unwelded) ridge vertices.
        var b = GLTFBuilder()
        let pos = b.vec3s([Vec3(-1, 0, 0), Vec3(0, 1, 1), Vec3(0, 1, -1), Vec3(1, 0, 0), Vec3(0, 1, -1), Vec3(0, 1, 1)])
        _ = b.node(["mesh": b.mesh([["attributes": ["POSITION": pos]]])])
        let g = try GLTFReader.read(data: b.glb(), options: .init(normals: .smooth)).meshes[0].primitives[0].geometry
        #expect(approx(g.vertices[1].normal, Vec3(0, 1, 0)) && approx(g.vertices[5].normal, Vec3(0, 1, 0)))
        #expect(approx(g.vertices[0].normal, normalize(Vec3(-1, 1, 0))))
        #expect(windingMatchesNormals(g))
    }

    // MARK: Meshes, materials, nodes

    @Test func multiPrimitiveMeshes() throws {
        var b = GLTFBuilder()
        b.materials = [["name": "Red", "pbrMetallicRoughness": ["baseColorFactor": [1, 0, 0, 1]]],
                       ["name": "Blue", "pbrMetallicRoughness": ["baseColorFactor": [0, 0, 1, 1]]]]
        let first = b.quadPrimitive(material: 0)
        let second = b.quadPrimitive(material: 1)
        let third = b.quadPrimitive()
        let mesh = b.mesh([first, second, third], name: "Parts")
        _ = b.node(["mesh": mesh, "name": "Multi"])
        let model = try GLTFReader.read(data: b.glb())
        #expect(model.meshes[0].primitives.map(\.material) == [0, 1, nil])
        #expect(model.material(of: model.meshes[0].primitives[2]) == .gltfDefault)
    }

    @MainActor @Test func instantiateBuildsTheHierarchy() throws {
        var b = GLTFBuilder()
        b.materials = [["name": "A"], ["name": "B"]]
        let single = b.mesh([b.quadPrimitive(material: 0)], name: "Single")
        let multi = b.mesh([b.quadPrimitive(material: 0), b.quadPrimitive(material: 1)], name: "Multi")
        let leaf = b.node(["name": "Leaf", "mesh": multi, "translation": [0, 0, -2]])
        let rotated = Quat(angle: .pi / 2, axis: Vec3(0, 1, 0))
        let middle = b.node(["name": "Middle", "mesh": single, "children": [leaf],
                             "rotation": [rotated.x, rotated.y, rotated.z, rotated.w], "scale": [2, 2, 2]])
        // Translate by (1, 2, 3) as a column-major matrix.
        let root = b.node(["name": "Root", "children": [middle], "matrix": [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 2, 3, 1]])
        _ = b.node(["mesh": single])  // a second root, unnamed
        b.scenes = [["nodes": [root, 3]]]
        let model = try GLTFReader.read(data: b.glb())
        #expect(model.roots == [root, 3])
        #expect(model.nodes[leaf].parent == middle && model.nodes[middle].parent == root && model.nodes[root].parent == nil)

        let world = World()
        let holder = world.spawn(Transform(position: Vec3(10, 0, 0)))
        let handles = ModelHandles(meshes: [[MeshHandle("single")], [MeshHandle("multi0"), MeshHandle("multi1")]],
                                   materials: [MaterialHandle("a"), MaterialHandle("b")])
        let result = model.instantiate(in: world, under: holder, handles: handles)
        #expect(result.roots.count == 2 && world.children(of: holder) == result.roots)
        let rootEntity = try #require(result.nodes[root]), middleEntity = try #require(result.nodes[middle])
        let leafEntity = try #require(result.nodes[leaf])
        #expect(world.get(Name.self, for: rootEntity)?.value == "Root")
        #expect(world.get(Name.self, for: result.roots[1])?.value == "Node 3")
        #expect(world.parent(of: middleEntity) == rootEntity && world.parent(of: leafEntity) == middleEntity)
        // Single-primitive meshes render on the node entity itself.
        #expect(world.get(MeshRenderer.self, for: middleEntity)?.mesh == MeshHandle("single"))
        #expect(world.get(MeshRenderer.self, for: middleEntity)?.material == MaterialHandle("a"))
        // Multi-primitive meshes get one child per primitive.
        #expect(world.get(MeshRenderer.self, for: leafEntity) == nil)
        let parts = world.children(of: leafEntity)
        #expect(parts.count == 2)
        #expect(parts.map { world.get(MeshRenderer.self, for: $0)?.mesh } == [MeshHandle("multi0"), MeshHandle("multi1")])
        #expect(parts.map { world.get(MeshRenderer.self, for: $0)?.material } == [MaterialHandle("a"), MaterialHandle("b")])
        #expect(parts.map { world.get(Name.self, for: $0)?.value } == ["Multi [0]", "Multi [1]"])
        #expect(result.renderers.count == 4)

        // World transform of the leaf: holder * root(translate) * middle(rotate, scale 2) * leaf(translate -2 z).
        world.propagateTransforms()
        let leafWorld = try #require(world.get(GlobalTransform.self, for: leafEntity)).matrix
        // Local -2 Z, scaled by 2 and turned 90° about Y, is -4 X; then + (1, 2, 3) + (10, 0, 0).
        #expect(approx(Vec3(leafWorld.c3.x, leafWorld.c3.y, leafWorld.c3.z), Vec3(7, 2, 3)))
        #expect(approx(world.get(Transform.self, for: middleEntity)!.scale, Vec3(2, 2, 2)))
    }

    @Test func matrixNodesDecompose() throws {
        let rotation = Quat(angle: 0.7, axis: normalize(Vec3(1, 2, 3)))
        let m = Mat4(translation: Vec3(4, -5, 6), rotation: rotation, scale: Vec3(1, 2, 3))
        var b = GLTFBuilder()
        _ = b.node(["matrix": [m.c0, m.c1, m.c2, m.c3].flatMap { [$0.x, $0.y, $0.z, $0.w] }])
        let transform = try GLTFReader.read(data: b.glb()).nodes[0].transform
        #expect(approx(transform.matrix, m))
        #expect(approx(transform.scale, Vec3(1, 2, 3)) && approx(transform.position, Vec3(4, -5, 6)))
    }

    @Test func mirroredNodesGetAFlippedMeshCopy() throws {
        var b = GLTFBuilder()
        let mesh = b.mesh([b.quadPrimitive()], name: "Quad")
        let plain = b.node(["mesh": mesh])
        let mirrored = b.node(["mesh": mesh, "scale": [-1, 1, 1]])
        let parent = b.node(["scale": [1, 1, -2], "children": [b.node(["mesh": mesh, "scale": [1, -1, 1]])]])  // two flips
        let mirroredAgain = b.node(["mesh": mesh, "matrix": [1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]])
        b.scenes = [["nodes": [plain, mirrored, parent, mirroredAgain]]]
        let model = try GLTFReader.read(data: b.glb())
        #expect(model.meshes.count == 2 && model.meshes[1].name == "Quad (mirrored)")
        #expect(model.nodes[plain].mesh == 0 && model.nodes[mirrored].mesh == 1 && model.nodes[mirroredAgain].mesh == 1)
        #expect(model.nodes[model.nodes[parent].children[0]].mesh == 0)
        #expect(model.meshes[1].primitives[0].geometry.indices == [0, 2, 1, 0, 3, 2])
    }

    @Test func sceneSelection() throws {
        var b = GLTFBuilder()
        let a = b.node(["name": "A"]), c = b.node(["name": "C"])
        b.scenes = [["name": "First", "nodes": [a]], ["name": "Second", "nodes": [c]]]
        #expect(try GLTFReader.read(data: b.glb()).roots == [a])
        b.scene = 1
        let second = try GLTFReader.read(data: b.glb())
        #expect(second.roots == [c] && second.sceneIndex == 1 && second.scenes.map(\.name) == ["First", "Second"])
        #expect(try GLTFReader.read(data: b.glb(), options: .init(scene: 0)).roots == [a])
        #expect(throws: GLTFError.self) { try GLTFReader.read(data: b.glb(), options: .init(scene: 5)) }
        // No scenes at all: every parentless node is a root.
        b.scenes = []
        b.scene = nil
        var noScenes = b.document(bufferURI: nil)
        noScenes["scenes"] = nil
        let model = try GLTFReader.read(data: GLTFBuilder.jsonData(noScenes))
        #expect(model.sceneIndex == nil && model.roots == [a, c])
    }

    @Test func materialsKeepEveryParameter() throws {
        var b = GLTFBuilder()
        b.images = [["uri": "albedo.png"], ["uri": "data.jpg"]]
        b.samplers = [["magFilter": 9728, "minFilter": 9986, "wrapS": 33071, "wrapT": 33648]]
        b.textures = [["source": 0, "sampler": 0], ["source": 1], ["source": 1], ["source": 0]]
        b.json["extensionsUsed"] = ["KHR_texture_transform", "KHR_materials_unlit", "KHR_materials_emissive_strength", "EXT_unknown"]
        b.materials = [[
            "name": "Full",
            "pbrMetallicRoughness": [
                "baseColorFactor": [0.5, 0.25, 1, 0.5],
                "baseColorTexture": ["index": 0, "extensions": ["KHR_texture_transform": ["scale": [2, 3]]]],
                "metallicFactor": 0.2, "roughnessFactor": 0.4,
                "metallicRoughnessTexture": ["index": 1, "texCoord": 1],
            ],
            "normalTexture": ["index": 2, "scale": 0.5],
            "occlusionTexture": ["index": 1, "strength": 0.7],
            "emissiveTexture": ["index": 3,
                                "extensions": ["KHR_texture_transform": ["offset": [0.5, 0], "rotation": 1.5, "texCoord": 1]]],
            "emissiveFactor": [1, 0.5, 0],
            "alphaMode": "BLEND", "alphaCutoff": 0.3, "doubleSided": true,
            "extensions": ["KHR_materials_unlit": [:], "KHR_materials_emissive_strength": ["emissiveStrength": 4]],
        ], ["alphaMode": "MASK"]]
        let model = try GLTFReader.read(data: GLTFBuilder.jsonData(b.document(bufferURI: nil))) { uri in
            uri == "albedo.png" ? Image(width: 1, height: 1, pixels: [255, 0, 0, 255]).pngData() : Data([0xFF, 0xD8, 0xFF, 0xE0])
        }
        let m = model.materials[0]
        #expect(m.name == "Full" && m.baseColorFactor == Vec4(0.5, 0.25, 1, 0.5))
        #expect(m.baseColorTexture == TextureReference(texture: 0, transform: TextureTransform(scale: Vec2(2, 3))))
        #expect(m.metallicFactor == 0.2 && m.roughnessFactor == 0.4)
        #expect(m.metallicRoughnessTexture == TextureReference(texture: 1, texCoord: 1))
        #expect(m.normalTexture?.texture == 2 && m.normalScale == 0.5)
        #expect(m.occlusionTexture?.texture == 1 && m.occlusionStrength == 0.7)
        #expect(m.emissiveTexture?.transform == TextureTransform(offset: Vec2(0.5, 0), rotation: 1.5, texCoord: 1))
        #expect(m.emissiveFactor == Vec3(1, 0.5, 0) && m.emissiveStrength == 4)
        #expect(m.alphaMode == .blend && m.alphaCutoff == 0.3 && m.doubleSided && m.unlit)
        let defaults = model.materials[1]
        #expect(defaults.alphaMode == .mask && defaults.alphaCutoff == 0.5 && defaults.metallicFactor == 1 && defaults.roughnessFactor == 1)
        #expect(defaults.baseColorFactor == Vec4(1, 1, 1, 1) && !defaults.doubleSided && !defaults.unlit)

        // Color spaces follow the slots that use each texture.
        #expect(model.textures[0].slots == [.baseColor] && model.textures[0].colorSpace == .sRGB)
        #expect(model.textures[1].slots == [.metallicRoughness, .occlusion] && model.textures[1].colorSpace == .linear)
        #expect(model.textures[2].colorSpace == .linear && model.textures[3].colorSpace == .sRGB)
        // Samplers: explicit and the glTF default.
        #expect(model.textures[0].sampler == ImportedSampler(magFilter: .nearest, minFilter: .nearest, mipFilter: .linear,
                                                            wrapU: .clampToEdge, wrapV: .mirrorRepeat))
        #expect(model.textures[1].sampler == ImportedSampler())
        #expect(model.warnings.contains { $0.contains("EXT_unknown") })
        #expect(model.warnings.contains { $0.contains("wrap") })
        // Images: bytes as stored, MIME type from the extension.
        #expect(model.images.map(\.mimeType) == ["image/png", "image/jpeg"])
        #expect(model.images.map(\.uri) == ["albedo.png", "data.jpg"])
    }

    @MainActor @Test func engineMaterialMapping() {
        var m = ImportedMaterial(name: "x")
        m.baseColorFactor = Vec4(0.2, 0.4, 0.6, 0.5)
        m.baseColorTexture = TextureReference(texture: 0, transform: TextureTransform(scale: Vec2(4, 2)))
        m.roughnessFactor = 0.2
        m.metallicFactor = 1
        m.doubleSided = true
        // Opaque ignores alpha (the engine would otherwise blend it).
        var e = m.engineMaterial()
        #expect(e.baseColor == Vec4(0.2, 0.4, 0.6, 1) && !e.isTransparent && e.doubleSided && e.uvScale == Vec2(4, 2))
        m.alphaMode = .blend
        e = m.engineMaterial()
        #expect(e.baseColor.w == 0.5 && e.isTransparent)
        // PBR: metallic and roughness carry over; Blinn-Phong's specular/shininess are unused.
        let smooth = m.engineMaterial()
        #expect(smooth.shading == .pbr && smooth.metallic == 1 && abs(smooth.roughness - 0.2) < 1e-6)
        var rough = m
        rough.unlit = true
        #expect(rough.engineMaterial().emissive == 1)
        // The whole texture transform carries over.
        m.baseColorTexture?.transform?.offset = Vec2(0.5, 0)
        #expect(m.engineMaterial().uvScale == Vec2(4, 2) && m.engineMaterial().uvOffset == Vec2(0.5, 0))
    }

    @Test func imagesFromBufferViewsAndDataURIsAreReturnedEncoded() throws {
        let png = Image(width: 2, height: 1, pixels: [255, 0, 0, 255, 0, 0, 255, 255]).pngData()
        var b = GLTFBuilder()
        let view = b.addView([UInt8](png))
        b.images = [["bufferView": view, "mimeType": "image/png", "name": "embedded"],
                    ["uri": "data:image/png;base64," + png.base64EncodedString()],
                    ["bufferView": view]]
        b.textures = [["source": 0], ["source": 1], ["source": 2]]
        let model = try GLTFReader.read(data: b.glb())
        #expect(model.images.allSatisfy { $0.data == png && $0.mimeType == "image/png" })
        #expect(model.images[0].name == "embedded" && model.images[0].uri == nil && model.images[1].uri == "data:image/png;base64")
        // Decoding is up to the caller; a stub stands in for a real decoder here.
        var calls: [String?] = []
        let decoded = model.decodeImages { data, mime in
            calls.append(mime)
            if data.count < 8 { throw GLTFError.invalidData("short") }
            return Image(width: 1, height: 1, pixels: [1, 2, 3, 4])
        }
        #expect(calls == ["image/png", "image/png", "image/png"])
        #expect(decoded.allSatisfy { (try? $0.get())?.pixels == [1, 2, 3, 4] })
    }

    // MARK: Coordinate conventions

    @Test func coordinatesWindingAndUVsPassThroughUnchanged() throws {
        // glTF and the engine agree: right-handed, +Y up, counter-clockwise front faces, UV
        // origin at the image's top-left. So a +Z-facing quad keeps positions, order and UVs,
        // and its winding (cross product of the edges) matches its normal.
        let model = try GLTFReader.read(data: GLTFBuilder.quadModel().glb())
        #expect(quadGeometryIsUnchanged(model))
        #expect(windingMatchesNormals(model.meshes[0].primitives[0].geometry))
        // The same holds for MeshGeometry's own primitives, which the renderer draws front-facing.
        #expect(windingMatchesNormals(.cube()) && windingMatchesNormals(.sphere()) && windingMatchesNormals(.plane()))
        // UV (0, 0) is the top of the image: a cube face's top edge has v = 0, like the quad's top edge here.
        let cube = MeshGeometry.cube()
        let front = cube.vertices[16..<20]  // +Z face
        #expect(front.filter { $0.position.y > 0 }.allSatisfy { $0.uv.y == 0 })
    }

    // MARK: Errors

    @Test func malformedFilesThrowInsteadOfCrashing() throws {
        let glb = GLTFBuilder.quadModel().glb()
        // Every truncation of a valid GLB.
        for length in stride(from: 0, to: glb.count, by: 1) {
            _ = try? GLTFReader.read(data: glb.prefix(length))
        }
        #expect(throws: GLTFError.self) { try GLTFReader.read(data: glb.prefix(30)) }
        // Bit flips in the header, the chunk headers and the binary data.
        for position in [4, 8, 12, 16, glb.count - 20, glb.count - 1] {
            var corrupt = glb
            corrupt[position] ^= 0xFF
            _ = try? GLTFReader.read(data: corrupt)
        }
        #expect(throws: GLTFError.self) { try GLTFReader.read(data: Data("not json".utf8)) }
        #expect(throws: GLTFError.self) { try GLTFReader.read(data: Data("{}".utf8)) }  // no asset
        #expect(throws: GLTFError.self) { try GLTFReader.read(data: Data(#"{"asset":{"version":"1.0"}}"#.utf8)) }
        #expect(throws: GLTFError.self) { try GLTFReader.read(data: Data(#"{"asset":{"version":"2.0","minVersion":"2.1"}}"#.utf8)) }
        #expect(throws: GLTFError.self) { try GLTFReader.read(data: Data(#"{"asset":{"version":2}}"#.utf8)) }
        #expect(throws: GLTFError.self) { try GLTFReader.read(data: Data("glTF\u{2}\0\0\0\u{FF}\0\0\0".utf8)) }
    }

    @Test func unsupportedRequiredExtensionsAreErrors() throws {
        var b = GLTFBuilder.quadModel()
        b.json["extensionsRequired"] = ["KHR_texture_transform", "KHR_draco_mesh_compression"]
        #expect(throws: GLTFError.unsupportedExtensions(["KHR_draco_mesh_compression"])) { try GLTFReader.read(data: b.glb()) }
        b.json["extensionsRequired"] = ["KHR_mesh_quantization"]
        #expect(throws: Never.self) { try GLTFReader.read(data: b.glb()) }
    }

    @Test func inconsistentDataIsAnError() throws {
        func expectInvalid(_ edit: (inout GLTFBuilder) -> Void, sourceLocation: SourceLocation = #_sourceLocation) {
            var b = GLTFBuilder.quadModel()
            edit(&b)
            #expect(throws: GLTFError.self, sourceLocation: sourceLocation) { try GLTFReader.read(data: b.glb()) }
        }
        expectInvalid { $0.accessors[0]["count"] = 5 }                         // past the end of its view
        expectInvalid { $0.accessors[0]["count"] = Int.max / 2 }              // overflowing
        expectInvalid { $0.accessors[0]["byteOffset"] = -4 }
        expectInvalid { $0.accessors[0]["type"] = "VEC2" }                    // POSITION must be VEC3
        expectInvalid { $0.accessors[0]["componentType"] = 1234 }
        expectInvalid { $0.accessors[0]["bufferView"] = 99 }
        expectInvalid { $0.accessors[0]["normalized"] = true }                // float can't be normalized
        expectInvalid { $0.accessors[1]["count"] = 3 }                        // NORMAL count differs
        expectInvalid { $0.bufferViews[0]["byteLength"] = 10_000 }            // past the end of the buffer
        expectInvalid { $0.bufferViews[0]["byteStride"] = 2 }
        expectInvalid { $0.bufferViews[0]["byteStride"] = 8 }                 // smaller than a VEC3
        expectInvalid { $0.accessors.removeAll() }
        expectInvalid { $0.nodes[0]["mesh"] = 3 }
        expectInvalid { $0.nodes[0]["children"] = [0] }                       // own child
        expectInvalid { $0.nodes[0]["matrix"] = [1, 0, 0] }
        expectInvalid { $0.nodes[0]["translation"] = [1, 0] }
        expectInvalid { $0.meshes[0]["primitives"] = [["attributes": ["POSITION": 0], "material": 0]] }
        expectInvalid { $0.meshes[0]["primitives"] = [["attributes": ["POSITION": 0], "mode": 9]] }
        expectInvalid { $0.scenes = [["nodes": [7]]] }
        expectInvalid { b in                                                   // out-of-range index
            b.meshes[0]["primitives"] = [["attributes": ["POSITION": 0], "indices": b.indices([UInt16(0), 1, 9])]]
        }
        expectInvalid { b in                                                   // no buffer view, absurd count
            b.accessors[0] = ["componentType": 5126, "count": 1 << 40, "type": "VEC3"]
        }
        expectInvalid { b in                                                   // a cycle
            _ = b.node(["children": [2]])
            _ = b.node(["children": [1]])
        }
        expectInvalid { b in                                                   // two parents
            let child = b.node([:])
            _ = b.node(["children": [child]])
            _ = b.node(["children": [child]])
        }
        expectInvalid { b in                                                   // sparse index out of range
            let indices = b.addView(GLTFBuilder.bytes([UInt16(9)]))
            let values = b.addView(GLTFBuilder.bytes([Float(1), 2, 3]))
            b.accessors[0]["sparse"] = ["count": 1, "indices": ["bufferView": indices, "componentType": 5123],
                                        "values": ["bufferView": values]]
        }
        expectInvalid { b in
            b.materials = [["pbrMetallicRoughness": ["baseColorTexture": ["index": 0]]]]
        }
        expectInvalid { b in
            b.materials = [["alphaMode": "SOMETIMES"]]
        }
        expectInvalid { b in
            b.images = [["uri": "data:image/png;base64,@@@"]]
        }
    }

    // MARK: Khronos sample models

    @Test func khronosBox() throws {
        let model = try GLTFReader.read(contentsOf: try resource("Box.glb"))
        #expect(model.meshes.count == 1 && model.meshes[0].primitives.count == 1)
        let g = model.meshes[0].primitives[0].geometry
        #expect(g.vertices.count == 24 && g.indices.count == 36)
        #expect(approx(g.bounds.halfExtent, Vec3(0.5, 0.5, 0.5)) && approx(g.bounds.center, .zero))
        #expect(windingMatchesNormals(g))
        // Every face winds counter-clockwise seen from outside.
        for t in stride(from: 0, to: g.indices.count, by: 3) {
            let (a, b, c) = (g.vertices[Int(g.indices[t])].position, g.vertices[Int(g.indices[t + 1])].position,
                             g.vertices[Int(g.indices[t + 2])].position)
            #expect(dot(cross(b - a, c - a), (a + b + c) / 3) > 0)
        }
        #expect(model.materials.count == 1 && model.materials[0].name == "Red")
        #expect(approx(model.materials[0].baseColorFactor, Vec4(0.8, 0, 0, 1)) && model.materials[0].metallicFactor == 0)
        // The root's Z-up-to-Y-up matrix: -90° about X.
        #expect(model.roots == [0] && model.nodes[0].children == [1] && model.nodes[1].mesh == 0)
        #expect(approx(model.nodes[0].transform.matrix, Mat4.rotation(angle: -.pi / 2, axis: Vec3(1, 0, 0))))
        #expect(model.warnings.isEmpty)
    }

    @Test func khronosBoxInterleavedMatchesBox() throws {
        let interleaved = try GLTFReader.read(contentsOf: try resource("BoxInterleaved.gltf"))
        let box = try GLTFReader.read(contentsOf: try resource("Box.glb"))
        let a = interleaved.meshes[0].primitives[0].geometry, b = box.meshes[0].primitives[0].geometry
        #expect(a.indices == b.indices)
        #expect(a.vertices == b.vertices)
    }

    @Test func khronosSimpleSparseAccessor() throws {
        let url = try resource("SimpleSparseAccessor.gltf")
        let g = try GLTFReader.read(contentsOf: url, options: .init(normals: .smooth)).meshes[0].primitives[0].geometry
        // A 7x2 grid of vertices; the sparse accessor moves vertices 8, 10 and 12 up.
        #expect(g.vertices.count == 14 && g.indices.count == 36)
        #expect(g.vertices[8].position == Vec3(1, 2, 0) && g.vertices[10].position == Vec3(3, 3, 0)
                && g.vertices[12].position == Vec3(5, 4, 0))
        #expect(g.vertices[9].position == Vec3(2, 1, 0))
        #expect(approx(g.bounds.halfExtent * 2, Vec3(6, 4, 0)))
        // No normals in the file: flat ones by default, which split the vertices.
        let flat = try GLTFReader.read(contentsOf: url).meshes[0].primitives[0]
        #expect(flat.generatedNormals && flat.geometry.vertices.count == 36)
        #expect(windingMatchesNormals(flat.geometry))
    }

    @Test func khronosOrientationTest() throws {
        let model = try GLTFReader.read(contentsOf: try resource("OrientationTest.glb"))
        #expect(model.nodes.count == 13 && model.roots.count == 13 && model.meshes.count == 13 && model.materials.count == 7)
        #expect(model.meshes.allSatisfy { mesh in mesh.primitives.allSatisfy { windingMatchesNormals($0.geometry) } })
        // ArrowX1 sits at +5 X with a TRS rotation about X; ArrowX2 at -5 X from a matrix.
        let x1 = try #require(model.nodes.first { $0.name == "ArrowX1" })
        let x2 = try #require(model.nodes.first { $0.name == "ArrowX2" })
        #expect(approx(x1.transform.position, Vec3(5, 0, 0)) && approx(x2.transform.position, Vec3(-5, 0, 0)))
        #expect(approx(x2.transform.rotation * Vec3(0, 1, 0), Vec3(0, 0.9961947, 0.0871557)))
        let bounds = try #require(model.sceneBounds)
        #expect(bounds.halfExtent.x > 5 && bounds.halfExtent.y > 5 && bounds.halfExtent.z > 5)
    }

    @Test func khronosTextureCoordinateTest() throws {
        let model = try GLTFReader.read(contentsOf: try resource("TextureCoordinateTest.glb"))
        #expect(model.images.count == 1 && model.images[0].mimeType == "image/png")
        #expect(model.images[0].data.prefix(4).elementsEqual([0x89, 0x50, 0x4E, 0x47]))
        #expect(model.textures.count == 1 && model.textures[0].colorSpace == .sRGB && model.textures[0].sampler == ImportedSampler())
        #expect(model.materials.allSatisfy { $0.doubleSided })
        let named = Dictionary(uniqueKeysWithValues: model.nodes.compactMap { n in n.name.map { ($0, n) } })
        // TopLeftObj is at the top left (+Y, -X) with its UVs near (0, 0): glTF's UV origin is the
        // image's top-left, which matches the engine, so nothing is flipped.
        let topLeft = try #require(named["TopLeftObj"]?.mesh)
        let g = model.meshes[topLeft].primitives[0].geometry
        let center = g.bounds.center
        #expect(center.x < 0 && center.y > 0)
        let meanUV = g.vertices.reduce(Vec2.zero) { $0 + $1.uv } / Float(g.vertices.count)
        #expect(meanUV.x < 0.5 && meanUV.y < 0.5)
    }
}
