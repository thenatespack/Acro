import Foundation
import Testing
@testable import EngineCore
@testable import EngineAssets

// Compressed blobs in asset packs (PackMeshCodec.swift, AssetPack.swift): the mesh codec's error
// bounds, what it refuses, damaged payloads, and how packs record and check encodings.

/// A UV sphere of `radius` around `center` with tangents (w carrying baked AO), so every stream
/// has varied values.
private func sphere(radius: Float = 20, center: Vec3 = Vec3(100, -3, 40), rings: Int = 24, segments: Int = 48) -> MeshGeometry {
    var vertices: [MeshVertex] = []
    for r in 0...rings {
        let theta = Float(r) / Float(rings) * .pi
        for s in 0...segments {
            let phi = Float(s) / Float(segments) * 2 * .pi
            let n = Vec3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi))
            let t = Vec3(-sin(phi), 0, cos(phi))
            let ao: Float = 0.25 + 0.75 * Float((r + s) % 7) / 6
            vertices.append(MeshVertex(position: center + n * radius, normal: n,
                                       uv: Vec2(Float(s) / Float(segments) * 8, Float(r) / Float(rings) * 4),
                                       tangent: Vec4(t.x, t.y, t.z, (s % 2 == 0 ? 1 : -1) * ao)))
        }
    }
    var indices: [UInt32] = []
    let row = UInt32(segments + 1)
    for r in 0..<UInt32(rings) {
        for s in 0..<UInt32(segments) {
            let a = r * row + s, b = a + row
            indices += [a, b, a + 1, a + 1, b, b + 1]
        }
    }
    return MeshGeometry(vertices: vertices, indices: indices)
}

/// The Library's raw file for `geometry` and its manifest entry's counts.
private func rawFile(_ geometry: MeshGeometry) -> (data: Data, vertexCount: Int, indexCount: Int, skinned: Bool, painted: Bool) {
    let asset = ImportedAsset(objects: [ImportedObject(id: "mesh/Test", name: "Test", value: .mesh(geometry))])
    let (manifest, files) = AssetArtifacts.encode(asset)
    let object = manifest.objects[0]
    return (files[object.file!]!, object.vertexCount!, object.indexCount!, object.skinned == true, object.painted == true)
}

/// `geometry` through the codec and back, read as `AssetArtifacts` reads a mesh file.
private func roundTrip(_ geometry: MeshGeometry) throws -> MeshGeometry {
    let raw = rawFile(geometry)
    let payload = try #require(PackMeshCodec.encode(raw.data, vertexCount: raw.vertexCount, indexCount: raw.indexCount,
                                                    skinned: raw.skinned, painted: raw.painted))
    let decoded = try #require(PackMeshCodec.decode(payload, size: raw.data.count))
    #expect(decoded.count == raw.data.count)
    let asset = ImportedAsset(objects: [ImportedObject(id: "mesh/Test", name: "Test", value: .mesh(geometry))])
    let manifest = AssetArtifacts.encode(asset).manifest
    let read = try #require(AssetArtifacts.decode(manifest) { _ in Data(decoded) })
    guard case .mesh(let mesh)? = read.objects.first?.value else { throw CancellationError() }
    return mesh
}

/// The largest componentwise difference.
func largestDifference<V: SIMD>(_ a: V, _ b: V) -> V.Scalar where V.Scalar: FloatingPoint {
    let d = a - b
    return max(d.max(), -d.min())
}

private func angle(_ a: Vec3, _ b: Vec3) -> Float {
    acos(min(max(dot(normalize(a), normalize(b)), -1), 1)) * 180 / .pi
}

@Suite struct PackMeshCodecTests {
    @Test func quantizationStaysWithinItsBounds() throws {
        let original = sphere()
        let mesh = try roundTrip(original)
        #expect(mesh.indices == original.indices)
        // Extent 40: 16 bits would be 40 / 65535 = 6.1e-4, rounded up to a power of two: 2^-10.
        let step: Float = 1.0 / 1024
        var worst = (position: Float(0), normal: Float(0), tangent: Float(0), uv: Float(0), w: Float(0))
        for (a, b) in zip(original.vertices, mesh.vertices) {
            worst.position = max(worst.position, largestDifference(a.position, b.position))
            worst.normal = max(worst.normal, angle(a.normal, b.normal))
            worst.tangent = max(worst.tangent, angle(Vec3(a.tangent.x, a.tangent.y, a.tangent.z), Vec3(b.tangent.x, b.tangent.y, b.tangent.z)))
            worst.uv = max(worst.uv, largestDifference(a.uv, b.uv))
            worst.w = max(worst.w, abs(a.tangent.w - b.tangent.w))
            #expect((a.tangent.w < 0) == (b.tangent.w < 0))
            #expect(abs(length(b.normal) - 1) < 1e-5)
        }
        #expect(worst.position <= step / 2 + 1e-5)
        #expect(worst.normal < 0.05)
        #expect(worst.tangent < 0.05)
        #expect(worst.uv <= 1.0 / 32768)
        #expect(worst.w <= 0.5 / 32767 + 1e-6)
    }

    @Test func positionsUseAnAbsoluteGrid() throws {
        // Two meshes of similar size that share a vertex position round it the same way, so
        // the seam between them doesn't open.
        var a = sphere(radius: 10, center: Vec3(0, 0, 0)), b = sphere(radius: 11, center: Vec3(20.123, 0.4567, -0.333))
        let shared = Vec3(10.123456, 0.987654, -0.333333)
        a.vertices[5].position = shared
        b.vertices[7].position = shared
        let ra = try roundTrip(a), rb = try roundTrip(b)
        #expect(ra.vertices[5].position == rb.vertices[7].position)
        // Large meshes get no coarser than 2^-10.
        let big = try roundTrip(sphere(radius: 2000, center: Vec3(5000, 0, 0)))
        let error = zip(sphere(radius: 2000, center: Vec3(5000, 0, 0)).vertices, big.vertices).map { largestDifference($0.position, $1.position) }.max()!
        #expect(error <= 1.0 / 2048 + 1.0 / 4096)  // plus half a Float ulp at 7000
    }

    @Test func tangentsSkinAndPaintSurvive() throws {
        // No tangents (w = 0) stays none, so the renderer still generates them.
        var plain = sphere()
        for i in plain.vertices.indices { plain.vertices[i].tangent = .zero }
        #expect(!(try roundTrip(plain)).hasTangents)
        #expect(try roundTrip(sphere()).hasTangents)
        // Skin joints exactly, weights within 16 bits; paint bit for bit.
        var skinned = sphere()
        skinned.skin = skinned.vertices.indices.map { i in
            let w = Float(i % 5) / 8
            return SkinInfluence(joints: SIMD4(UInt16(i % 60), UInt16(i % 3), 65535, 0), weights: Vec4(1 - w, w, 0, 0))
        }
        skinned.paint = skinned.vertices.indices.map { i in VertexPaint(color: Vec4(Float(i) * 0.001, 0.5, 1, 1), surface: Vec4(1, 0.3, 0.7, 2.5)) }
        let mesh = try roundTrip(skinned)
        let skin = try #require(mesh.skin)
        #expect(skin.map(\.joints) == skinned.skin!.map(\.joints))
        #expect(zip(skin, skinned.skin!).allSatisfy { largestDifference($0.weights, $1.weights) <= 0.5 / 65535 + 1e-7 })
        #expect(mesh.paint == skinned.paint)
    }

    /// Streams whose values are all equal take no bytes; one at the very end of the payload (one
    /// influence per vertex and no paint, as generated characters have) must still decode.
    @Test func constantStreamsAtTheEndDecode() throws {
        var skinned = sphere()
        skinned.skin = skinned.vertices.indices.map { i in SkinInfluence(joints: SIMD4(UInt16(i % 7), 0, 0, 0), weights: Vec4(1, 0, 0, 0)) }
        let skin = try #require(try roundTrip(skinned).skin)
        #expect(skin.map(\.joints) == skinned.skin!.map(\.joints))
        #expect(skin.map(\.weights) == skinned.skin!.map(\.weights))
    }

    @Test func meshesItCantQuantizeAreRefused() {
        var zeroNormal = sphere()
        zeroNormal.vertices[3].normal = .zero
        var nan = sphere()
        nan.vertices[0].position.x = .nan
        var heavy = sphere()
        heavy.skin = heavy.vertices.map { _ in SkinInfluence(joints: .zero, weights: Vec4(2, 0, 0, 0)) }
        for geometry in [zeroNormal, nan, heavy] {
            let raw = rawFile(geometry)
            #expect(PackMeshCodec.encode(raw.data, vertexCount: raw.vertexCount, indexCount: raw.indexCount,
                                         skinned: raw.skinned, painted: raw.painted) == nil)
        }
    }

    @Test func damagedPayloadsDontDecode() throws {
        let raw = rawFile(sphere())
        let payload = try #require(PackMeshCodec.encode(raw.data, vertexCount: raw.vertexCount, indexCount: raw.indexCount,
                                                        skinned: false, painted: false))
        #expect(PackMeshCodec.decode(payload, size: raw.data.count + 4) == nil)  // another size
        #expect(PackMeshCodec.decode(Array(payload.dropLast(10)), size: raw.data.count) == nil)  // truncated
        #expect(PackMeshCodec.decode(payload + [0], size: raw.data.count) == nil)  // trailing bytes
        #expect(PackMeshCodec.decode(Array(payload.prefix(17)), size: raw.data.count) == nil)
        var badMagic = payload
        badMagic[0] = 0
        #expect(PackMeshCodec.decode(badMagic, size: raw.data.count) == nil)
        var huge = payload  // a vertex count the payload can't hold
        huge[7] = 0x7F
        #expect(PackMeshCodec.decode(huge, size: raw.data.count) == nil)
    }

    @Test func packsRecordAndCheckEncodings() throws {
        let geometry = sphere()
        let raw = rawFile(geometry)
        func pack(_ edit: (inout AssetPackManifest) -> Void = { _ in }, compression: AssetPackFormat.Compression) throws -> Data {
            let writer = AssetPackFormat.Writer()
            let blob = writer.add(raw.data, compression: compression)
            let scene = writer.add(Data(String(repeating: "{\"entities\": []}\n", count: 100).utf8), compression: .deflate)
            var manifest = AssetPackManifest(name: "T", platform: .linux, textureFamily: .bc, vertexStride: MemoryLayout<MeshVertex>.stride,
                                             scenes: [.init(path: "Main.scene", blob: scene)], assets: [])
            manifest.navigation = ["mesh": blob]  // any blob table will do
            edit(&manifest)
            return try writer.finish(manifest)
        }
        func version(_ data: Data) -> UInt32 { data.withUnsafeBytes { UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: 8, as: UInt32.self)) } }

        // Compressed: version 2, the mesh as mesh1 (about a fifth of its raw size here), the scene deflated.
        let compressed = try pack(compression: .mesh(vertexCount: raw.vertexCount, indexCount: raw.indexCount, skinned: false, painted: false))
        #expect(version(compressed) == 2)
        let opened = try AssetPack(data: compressed, name: "T.pack")
        let blob = try #require(opened.manifest.navigation?["mesh"])
        #expect(blob.encoding == "mesh1" && blob.rawSize == UInt64(raw.data.count) && blob.size * 4 < blob.decodedSize)
        #expect(opened.manifest.scenes[0].blob.encoding == "deflate")
        #expect(try opened.scene() == Data(String(repeating: "{\"entities\": []}\n", count: 100).utf8))
        #expect(try opened.bytes(of: blob).count == raw.data.count)

        // Deflate alone is lossless; nothing compressed is version 1, which older engines read.
        let deflated = try AssetPack(data: try pack(compression: .deflate), name: "T.pack")
        #expect(try deflated.bytes(of: deflated.manifest.navigation!["mesh"]!) == raw.data)
        let plain = try pack(compression: .none)
        #expect(try AssetPack(data: plain, name: "T.pack").manifest.navigation?["mesh"]?.encoding == nil)
        let plainScene = try { () throws -> Data in
            let writer = AssetPackFormat.Writer()
            let scene = writer.add(Data("{}".utf8))
            return try writer.finish(AssetPackManifest(name: "T", platform: .linux, textureFamily: .bc, vertexStride: MemoryLayout<MeshVertex>.stride,
                                                       scenes: [.init(path: "Main.scene", blob: scene)], assets: []))
        }()
        #expect(version(plainScene) == 1)

        // An encoding this engine doesn't know fails when the pack opens, a newer version too.
        let unknown = try pack({ $0.navigation?["mesh"]?.encoding = "zstd" }, compression: .deflate)
        #expect {
            try AssetPack(data: unknown, name: "T.pack")
        } throws: { error in
            guard case AssetPackError.incompatible(let message) = error else { return false }
            return message.contains("zstd")
        }
        var newer = compressed
        newer[8] = 3
        #expect(throws: AssetPackError.unsupportedVersion(3)) { try AssetPack(data: newer, name: "T.pack") }
        // A flipped byte in a compressed blob fails its hash.
        var damaged = compressed
        damaged[Int(blob.offset) + 40] ^= 0xFF
        #expect(throws: AssetPackError.self) { try AssetPack(data: damaged, name: "T.pack").bytes(of: blob) }
        // Unchecked, it fails to decode instead of drawing garbage... or decodes to the right size.
        let unchecked = try AssetPack(data: damaged, name: "T.pack", verifiesBlobs: false)
        if let bytes = try? unchecked.bytes(of: blob) { #expect(bytes.count == raw.data.count) }
    }
}
