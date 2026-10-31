import Foundation
import Testing
@testable import Engine
#if canImport(QuartzCore)
import QuartzCore
#endif

// Two-channel normal maps (BC5, two-channel ASTC 4x4): the BC5 codec, Z reconstruction, quality
// against BC7 / ASTC RGB on the BoomBox's normal map, the importers' role-aware compression
// (glTF textures, cached encodings), and the mesh shader reading them on every backend.

/// A bumpy tangent-space normal map: a smooth wave field plus a hard-edged raised square.
private func bumpyNormalMap(width: Int, height: Int) -> Image {
    var pixels = [UInt8](repeating: 255, count: width * height * 4)
    for y in 0..<height {
        for x in 0..<width {
            let u = Float(x) / Float(width), v = Float(y) / Float(height)
            var n = Vec3(0.45 * sinf(u * 17), 0.35 * cosf(v * 11 + u * 3), 1)
            if u > 0.6 && u < 0.8 && v > 0.2 && v < 0.4 { n = Vec3(-0.6, 0.5, 0.62) }
            n = normalize(n)
            let i = (y * width + x) * 4
            for c in 0..<3 { pixels[i + c] = UInt8(((n[c] * 0.5 + 0.5) * 255).rounded()) }
        }
    }
    return Image(width: width, height: height, pixels: pixels)
}

/// Mean and largest angle in degrees between the normals `reference` stands for (RGB, unit
/// length) and those a decoded `format` level stands for, as the mesh shader reads them.
private func angularError(reference: Image, decoded: Image, format: TextureFormat) -> (mean: Double, max: Double) {
    var total = 0.0, worst = 0.0
    let count = reference.width * reference.height
    for texel in 0..<count {
        let a = TextureCodec.normal(reference.pixels, at: texel, format: .rgba8Unorm)
        let b = TextureCodec.normal(decoded.pixels, at: texel, format: format)
        let angle = Double(acosf(min(max(dot(a, b), -1), 1))) * 180 / .pi
        total += angle
        worst = max(worst, angle)
    }
    return (total / Double(count), worst)
}

/// The Khronos BoomBox (Sources/Demo/Models, also used by the demo scenes).
private let boomBoxURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().appendingPathComponent("Sources/Demo/Models/BoomBox.glb")

private func boomBoxNormalMap() throws -> Image {
    let model = try GLTFReader.read(contentsOf: boomBoxURL)
    let texture = try #require(model.materials.first?.normalTexture?.texture)
    let image = try #require(model.textures[texture].image)
    return try ImageDecoder.decode(model.images[image].data)
}

@Suite struct TwoChannelNormalMapTests {
    // MARK: Formats

    @Test func twoChannelFormatsAndCompressionChoices() {
        for format in [TextureFormat.bc5Unorm, .astc4x4RG] {
            #expect(format.isCompressed && format.isTwoChannel && !format.isSRGB)
            #expect(format.blockSize == 4 && format.bytesPerBlock == 16 && format.byteCount(width: 8, height: 8) == 64)
            #expect(format.decompressedFormat == .rgba8Unorm)
            #expect(TextureFormat.compressedFormats.contains(format))
        }
        #expect(!TextureFormat.bc7Unorm.isTwoChannel && !TextureFormat.astc4x4Unorm.isTwoChannel)
        // Normal maps get two channels under auto, bc5 and astcRG; everything else stays RGB(A).
        #expect(TextureCompression.auto.format(srgb: false, normalMap: true)?.isTwoChannel == true)
        #expect(TextureCompression.auto.format(srgb: false)?.isTwoChannel == false)
        #expect(TextureCompression.bc5.format(srgb: false, normalMap: true) == .bc5Unorm)
        #expect(TextureCompression.bc5.format(srgb: true) == .bc7Srgb)
        #expect(TextureCompression.bc5.format(srgb: false) == .bc7Unorm)
        #expect(TextureCompression.astcRG.format(srgb: false, normalMap: true) == .astc4x4RG)
        #expect(TextureCompression.astcRG.format(srgb: true) == .astc4x4Srgb)
        #expect(TextureCompression.bc7.format(srgb: false, normalMap: true) == .bc7Unorm)
        #expect(TextureCompression.astc.format(srgb: false, normalMap: true) == .astc4x4Unorm)
        #expect(TextureCompression.none.format(srgb: false, normalMap: true) == nil)
    }

    // MARK: Codec

    @Test func bc5RoundTripKeepsRedAndGreen() throws {
        // 13x7: edge blocks repeat the last column / row.
        let image = bumpyNormalMap(width: 13, height: 7)
        let level = try #require(try TextureCodec.encode(image, format: .bc5Unorm, mipmaps: false).first)
        #expect(level.pixels.count == 4 * 2 * 16)
        let decoded = try TextureCodec.decode(level, format: .bc5Unorm)
        var worst = 0
        for i in stride(from: 0, to: image.pixels.count, by: 4) {
            worst = max(worst, abs(Int(image.pixels[i]) - Int(decoded.pixels[i])), abs(Int(image.pixels[i + 1]) - Int(decoded.pixels[i + 1])))
            #expect(decoded.pixels[i + 2] == 0 && decoded.pixels[i + 3] == 255)
        }
        #expect(worst <= 8, "worst red / green error \(worst)")

        // Flat blocks, and blocks of only 0 and 255 (the six-value mode's constants), are exact.
        var pixels = [UInt8](repeating: 0, count: 8 * 4 * 4)
        for x in 0..<8 {
            for y in 0..<4 {
                let i = (y * 8 + x) * 4
                pixels[i] = x < 4 ? 77 : ((x + y) % 2 == 0 ? 0 : 255)
                pixels[i + 1] = x < 4 ? 200 : 255
            }
        }
        let exact = Image(width: 8, height: 4, pixels: pixels)
        let flat = try TextureCodec.decode(try TextureCodec.encode(exact, format: .bc5Unorm, mipmaps: false)[0], format: .bc5Unorm)
        for i in stride(from: 0, to: pixels.count, by: 4) {
            #expect(flat.pixels[i] == pixels[i] && flat.pixels[i + 1] == pixels[i + 1])
        }

        // Deterministic, and better with more effort.
        let big = bumpyNormalMap(width: 64, height: 64)
        let levels = try TextureCodec.encode(big, format: .bc5Unorm, quality: .normal)
        #expect(levels.count == 7)
        #expect(try TextureCodec.encode(big, format: .bc5Unorm, quality: .normal).map(\.pixels) == levels.map(\.pixels))
        func error(_ quality: TextureCompressionQuality) throws -> Int {
            let decoded = try TextureCodec.decode(try TextureCodec.encode(big, format: .bc5Unorm, mipmaps: false, quality: quality)[0],
                                                  format: .bc5Unorm)
            return stride(from: 0, to: big.pixels.count, by: 4).reduce(0) { sum, i in
                let r = Int(big.pixels[i]) - Int(decoded.pixels[i]), g = Int(big.pixels[i + 1]) - Int(decoded.pixels[i + 1])
                return sum + r * r + g * g
            }
        }
        let (fast, normal, high) = (try error(.fast), try error(.normal), try error(.high))
        #expect(high <= normal && normal <= fast, "squared error fast \(fast), normal \(normal), high \(high)")
    }

    @Test func twoChannelASTCStoresXAsLuminanceAndYAsAlpha() throws {
        let image = bumpyNormalMap(width: 32, height: 32)
        let level = try TextureCodec.encode(image, format: .astc4x4RG, mipmaps: false)[0]
        let decoded = try TextureCodec.decode(level, format: .astc4x4RG)
        var worst = 0
        for i in stride(from: 0, to: image.pixels.count, by: 4) {
            #expect(decoded.pixels[i] == decoded.pixels[i + 1] && decoded.pixels[i] == decoded.pixels[i + 2])
            worst = max(worst, abs(Int(image.pixels[i]) - Int(decoded.pixels[i])), abs(Int(image.pixels[i + 1]) - Int(decoded.pixels[i + 3])))
        }
        #expect(worst <= 12, "worst x / y error \(worst)")
    }

    @Test func zIsRebuiltFromXAndY() throws {
        let n = normalize(Vec3(0.5, -0.3, 0.6))
        let byte = { (v: Float) in UInt8(((v * 0.5 + 0.5) * 255).rounded()) }
        // As BC5 decodes (x, y, 0, 1) and two-channel ASTC (x, x, x, y).
        let bc5: [UInt8] = [byte(n.x), byte(n.y), 0, 255]
        let astc: [UInt8] = [byte(n.x), byte(n.x), byte(n.x), byte(n.y)]
        for (pixels, format) in [(bc5, TextureFormat.bc5Unorm), (astc, .astc4x4RG)] {
            let m = TextureCodec.normal(pixels, at: 0, format: format)
            #expect(abs(length(m) - 1) < 1e-5 && dot(m, n) > 0.9999, "\(format): \(m)")
            // The RGBA8 fallback is a full normal map: (x, y, z, 1).
            let expanded = TextureCodec.expandTwoChannel(Image(width: 1, height: 1, pixels: pixels), format: format)
            #expect(expanded.pixels == [byte(n.x), byte(n.y), byte(m.z), 255], "\(format)")
        }
        // Past the unit circle (rounding), Z clamps to 0.
        #expect(TextureCodec.normal([255, 255, 0, 255], at: 0, format: .bc5Unorm).z == 0)
        // Normalizing before encoding: unit vectors, alpha kept.
        let long = TextureCodec.normalized(normalMap: Image(width: 1, height: 1, pixels: [255, 128, 200, 77]))
        let v = TextureCodec.normal(long.pixels, at: 0, format: .rgba8Unorm)
        #expect(long.pixels[3] == 77 && v.x > 0.8 && abs(v.y) < 0.02)
    }

    /// The acceptance numbers: on the BoomBox's normal map, two channels (more bits for X and Y,
    /// Z rebuilt) beat BC7 / ASTC RGB in mean angular error.
    @Test func twoChannelsBeatRGBOnTheBoomBoxNormalMap() throws {
        let source = try boomBoxNormalMap()
        let reference = TextureCodec.normalized(normalMap: source)
        var results: [TextureFormat: (mean: Double, max: Double)] = [:]
        for format in [TextureFormat.bc7Unorm, .bc5Unorm, .astc4x4Unorm, .astc4x4RG] {
            let level = try TextureCodec.encode(format.isTwoChannel ? reference : source, format: format, mipmaps: false)[0]
            results[format] = angularError(reference: reference, decoded: try TextureCodec.decode(level, format: format), format: format)
        }
        let report = results.sorted { $0.key.rawValue < $1.key.rawValue }
            .map { String(format: "%@ mean %.3f° max %.2f°", $0.key.rawValue, $0.value.mean, $0.value.max) }
        print("BoomBox normal map (\(source.width)x\(source.height)) angular error: " + report.joined(separator: ", "))
        #expect(results[.bc5Unorm]!.mean < results[.bc7Unorm]!.mean, "\(report)")
        #expect(results[.astc4x4RG]!.mean < results[.astc4x4Unorm]!.mean, "\(report)")
        #expect(results[.bc5Unorm]!.mean < 1 && results[.astc4x4RG]!.mean < 1.5, "\(report)")
    }

    // MARK: Importers

    @MainActor @Test func gltfTexturesCompressByRoleAndReimportsReuseTheEncodings() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("TwoChannelNormalMapTests-\(UUID().uuidString)")
        let project = try Project.create(at: url, name: "Compression")
        defer { try? FileManager.default.removeItem(at: project.root) }
        try FileManager.default.copyItem(at: boomBoxURL, to: project.assetsURL.appendingPathComponent("BoomBox.glb"))
        let database = AssetDatabase(project: project)
        database.refresh()
        let id = try #require(database.id(forPath: "BoomBox.glb"))
        let materialObject = try #require(database.asset(id)?.objects.first { $0.kind == .material })
        let material = try #require(database.material(AssetReference(id, subAsset: materialObject.id)))
        func format(_ reference: AssetReference?) -> TextureFormat? { reference.flatMap { database.texture($0)?.format } }
        #expect(format(material.texture) == .rgba8Srgb && format(material.normalTexture) == .rgba8Unorm)
        // Sidecars from before the setting decode with compression off.
        let old = try JSONDecoder().decode(GLTFImporter.Settings.self, from: Data(#"{"smoothNormals": true}"#.utf8))
        #expect(old == GLTFImporter.Settings(smoothNormals: true, compression: .none))

        try database.setSettings(GLTFImporter.Settings(compression: .bc5, compressionQuality: .fast), for: id)
        let compressed = try #require(database.material(AssetReference(id, subAsset: materialObject.id)))
        #expect(format(compressed.texture) == .bc7Srgb)
        #expect(format(compressed.emissiveTexture) == .bc7Srgb)
        #expect(format(compressed.metallicRoughnessTexture) == .bc7Unorm)
        #expect(format(compressed.normalTexture) == .bc5Unorm)
        let normal = try #require(compressed.normalTexture.flatMap { database.texture($0) })
        let levels = try #require(normal.compressedLevels)
        #expect(normal.generatesMipmaps && levels.count == MipChain.levelCount(width: normal.width, height: normal.height))

        // The Library keeps the compressed chains; the encodings are also cached per texture
        // (source hash, format, quality, mipmaps), so a forced reimport reads them: a marked
        // copy of the cached normal map comes back.
        let reopened = AssetDatabase(project: project)
        reopened.scan()
        #expect(reopened.texture(compressed.normalTexture!)?.compressedLevels?.map(\.pixels) == levels.map(\.pixels))
        let cache = database.artifactsURL(id).appendingPathComponent("cache")
        let files = try FileManager.default.contentsOfDirectory(atPath: cache.path).sorted()
        let normalFile = try #require(files.first { $0.hasSuffix("-bc5Unorm.bin") }, "\(files)")
        #expect(files.contains { $0.hasSuffix("-bc7Srgb.bin") } && files.contains { $0.hasSuffix("-bc7Unorm.bin") }, "\(files)")
        var cached = try Data(contentsOf: cache.appendingPathComponent(normalFile))
        cached[cached.count - 1] ^= 0xFF
        try cached.write(to: cache.appendingPathComponent(normalFile))
        let start = Date()
        database.reimport(id)
        let seconds = Date().timeIntervalSince(start)
        let reimported = try #require(database.material(AssetReference(id, subAsset: materialObject.id))?.normalTexture
            .flatMap { database.texture($0)?.compressedLevels })
        #expect(reimported.last?.pixels.last == levels.last!.pixels.last! ^ 0xFF)
        print("BoomBox reimport with cached encodings: \(Int(seconds * 1000)) ms")

        // ASTC: two-channel normals, four-channel color.
        try database.setSettings(GLTFImporter.Settings(compression: .astcRG, compressionQuality: .fast), for: id)
        let astc = try #require(database.material(AssetReference(id, subAsset: materialObject.id)))
        #expect(format(astc.normalTexture) == .astc4x4RG && format(astc.texture) == .astc4x4Srgb)
    }

    @MainActor @Test func textureImporterNormalMapSetting() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("TwoChannelNormalMapTests-\(UUID().uuidString)")
        let project = try Project.create(at: url, name: "Compression")
        defer { try? FileManager.default.removeItem(at: project.root) }
        try bumpyNormalMap(width: 24, height: 16).pngData().write(to: project.assetsURL.appendingPathComponent("bumps.png"))
        let database = AssetDatabase(project: project)
        database.refresh()
        let id = try #require(database.id(forPath: "bumps.png"))
        let reference = AssetReference(id, subAsset: "texture")
        let old = try JSONDecoder().decode(TextureImporter.Settings.self, from: Data(#"{"sRGB": false, "compression": "bc7"}"#.utf8))
        #expect(!old.normalMap)
        try database.setSettings(TextureImporter.Settings(sRGB: false, compression: .auto, normalMap: true), for: id)
        #expect(database.texture(reference)?.format == TextureCodec.autoNormalMapFormat)
        try database.setSettings(TextureImporter.Settings(sRGB: false, compression: .bc5, normalMap: true), for: id)
        #expect(database.texture(reference)?.format == .bc5Unorm)
        try database.setSettings(TextureImporter.Settings(sRGB: false, compression: .bc5), for: id)
        #expect(database.texture(reference)?.format == .bc7Unorm)
    }

    // MARK: GPU

    /// The mesh shader rebuilds Z for two-channel normal maps: a plane with a tilted normal map
    /// lights the same whether the map is RGBA8, BC5 or two-channel ASTC (or their RGBA8
    /// fallbacks), and differently from no map at all, on every backend.
    @MainActor @Test func meshShaderReadsTwoChannelNormalMapsOnEveryBackend() throws {
        let n = normalize(Vec3(0.55, 0.25, 0.8))
        let texel = [n.x, n.y, n.z].map { UInt8((($0 * 0.5 + 0.5) * 255).rounded()) } + [255]
        let image = Image(width: 16, height: 16, pixels: Array([[UInt8]](repeating: texel, count: 256).joined()))
        try TestDevices.forEachBackend { device, frames in
            let renderer = try SceneRenderer(device: device, quality: .low)
            let target = try RenderTarget(device: device, width: 32, height: 32, multisampled: false)
            var textures: [(String, GPUTexture?)] = [("none", nil), ("rgba8", try device.makeTexture(image: image, srgb: false))]
            for format in [TextureFormat.bc5Unorm, .astc4x4RG] {
                let levels = try TextureCodec.encode(image, format: format)
                textures.append(("\(format)", try device.makeTexture(compressedLevels: levels, format: format)))
                // A GPU without the format gets the RGBA8 fallback; check that one everywhere too.
                textures.append(("\(format) fallback", try device.makeTexture(levels: TextureCodec.decode(levels: levels, format: format).map {
                    let expanded = TextureCodec.expandTwoChannel(Image(width: $0.width, height: $0.height, pixels: $0.pixels), format: format)
                    return TextureMipLevel(width: expanded.width, height: expanded.height, pixels: expanded.pixels)
                }, format: .rgba8Unorm)))
            }
            var colors: [String: [UInt8]] = [:]
            for (name, texture) in textures {
                try renderer.registerMaterial(Material(baseColor: Vec4(0.4, 0.4, 0.4, 1), roughness: 0.9, normalTexture: texture),
                                              key: "test")
                let world = World()
                _ = world.spawn(Transform(rotation: .lookRotation(forward: -normalize(Vec3(0.7, 0.2, 0.7)))), DirectionalLight(intensity: 0.6))
                // The plane faces +Y; turned to face the camera on +Z.
                _ = world.spawn(Transform(rotation: Quat(angle: .pi / 2, axis: Vec3(1, 0, 0)), scale: Vec3(4, 1, 4)),
                            MeshRenderer(mesh: .plane, material: MaterialHandle("test")))
                world.propagateTransforms()
                let view = SceneView(view: Mat4.lookAt(eye: Vec3(0, 0, 3), target: .zero),
                                     projection: Mat4.perspective(fovY: 0.6, aspect: 1, near: 0.1, far: 10))
                var pixels: Image?
                try frames.run { frame in
                    renderer.beginViews(world: world, frame: frame)
                    renderer.renderView(view, into: target, frame: frame)
                    device.readBack(target.gpu) { pixels = $0 }
                }
                let rendered = try #require(pixels)
                let i = (16 * rendered.width + 16) * 4
                colors[name] = Array(rendered.pixels[i..<i + 4])
            }
            let label = "\(device.backend): \(colors.sorted { $0.key < $1.key })"
            let reference = try #require(colors["rgba8"])
            #expect(abs(Int(reference[0]) - Int(colors["none"]![0])) > 10, "\(label)")
            for (name, color) in colors where name != "none" {
                #expect(zip(color, reference).allSatisfy { abs(Int($0) - Int($1)) <= 2 }, "\(name) vs rgba8, \(label)")
            }
        }
    }
}
