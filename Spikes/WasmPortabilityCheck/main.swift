// Checks that the parts of the engine with C dependencies or layout-sensitive data give the same
// results on wasm32 as natively: the texture codecs (BC7, BC5, BC6H, ASTC LDR/RG/HDR encode and
// decode), PNG writing (vendored zlib on WASI) and zlib round trips, and the sizes of types
// written to packs and caches. Prints one line per check with an FNV-1a hash of the output;
// the lines must match between the two builds:
//
//   ENGINE_WASM_CHECK=1 swift run -c release WasmPortabilityCheck /tmp/native.png > native.txt
//   ENGINE_WASM=1 swift build -c release --swift-sdk swift-6.4.2-RELEASE_wasm --scratch-path .build-wasm \
//       --product WasmPortabilityCheck
//   wasmkit run --dir /tmp .build-wasm/.../WasmPortabilityCheck.wasm /tmp/wasm.png > wasm.txt
//   diff native.txt wasm.txt
//
// (See docs/wasm-spike.md, "Size".)
import CZlib
import Engine
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif

func fnv(_ bytes: some Sequence<UInt8>) -> String {
    var h: UInt64 = 0xcbf2_9ce4_8422_2325
    for b in bytes { h = (h ^ UInt64(b)) &* 0x100_0000_01b3 }
    let s = String(h, radix: 16)
    return String(repeating: "0", count: 16 - s.count) + s
}

func fnvFloats(_ values: [Float]) -> String { fnv(values.flatMap { withUnsafeBytes(of: $0.bitPattern.littleEndian, Array.init) }) }

/// A deterministic 40x24 test image (not a multiple of 4 high, to cover edge blocks): gradients,
/// a hard edge and noise, with varying alpha.
func testImage(width: Int = 40, height: Int = 22) -> Image {
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    var state: UInt32 = 12345
    for y in 0..<height {
        for x in 0..<width {
            state = state &* 1_664_525 &+ 1_013_904_223
            let noise = UInt8(truncatingIfNeeded: state >> 24) / 8
            let i = (y * width + x) * 4
            pixels[i] = UInt8(x * 255 / (width - 1)) &+ noise
            pixels[i + 1] = UInt8(y * 255 / (height - 1))
            pixels[i + 2] = x > width / 2 ? 230 : 20
            pixels[i + 3] = UInt8(255 - (x + y) * 2)
        }
    }
    return Image(width: width, height: height, pixels: pixels)
}

nonisolated(unsafe) var failed = false
func check(_ name: String, _ body: () throws -> String) {
    do {
        print("\(name): \(try body())")
    } catch {
        print("\(name): FAILED \(error)")
        failed = true
    }
}

let image = testImage()

// Layouts of types stored in packs and caches (AssetCache writes raw MeshVertex / VertexPaint arrays).
check("layout") {
    "MeshVertex \(MemoryLayout<MeshVertex>.stride), VertexPaint \(MemoryLayout<VertexPaint>.stride), "
        + "SkinInfluence \(MemoryLayout<SkinInfluence>.stride), Vec3 \(MemoryLayout<Vec3>.stride), Mat4 \(MemoryLayout<Mat4>.stride)"
}

for format in [TextureFormat.bc7Unorm, .bc7Srgb, .bc5Unorm, .astc4x4Unorm, .astc4x4Srgb, .astc4x4RG] {
    check("\(format) encode+decode") {
        let levels = try TextureCodec.encode(image, format: format, mipmaps: true, quality: .fast)
        let decoded = try TextureCodec.decode(levels[0], format: format)
        return "levels \(levels.count), blocks \(fnv(levels.flatMap(\.pixels))), decoded \(fnv(decoded.pixels))"
    }
}

check("bc7Unorm normal-quality encode") {
    fnv(try TextureCodec.encode(image, format: .bc7Unorm, mipmaps: false, quality: .normal)[0].pixels)
}

let hdr = FloatImage(width: 16, height: 12, pixels: (0..<(16 * 12 * 4)).map { i in Float(i % 37) * 0.37 + Float(i / 64) * 0.05 })
for format in [TextureFormat.bc6hUfloat, .astc4x4HDR] {
    check("\(format) encode+decode") {
        let levels = try TextureCodec.encode(hdr, format: format, mipmaps: false, quality: .fast)
        let decoded = try TextureCodec.decodeFloat(levels[0], format: format)
        return "blocks \(fnv(levels[0].pixels)), decoded \(fnvFloats(decoded.pixels))"
    }
}

check("png encode") {
    let png = image.pngData()
    let back = try ImageDecoder.decode(png)
    guard back.width == image.width, back.height == image.height, back.pixels == image.pixels else {
        throw GraphicsError("the PNG decodes to different pixels")
    }
    return "\(png.count) bytes, \(fnv(png)), round trip ok"
}

if CommandLine.arguments.count > 1 {
    let url = URL(fileURLWithPath: CommandLine.arguments[1])
    check("png file") {
        try image.writePNG(to: url)
        let back = try ImageDecoder.decode(contentsOf: url)
        guard back.pixels == image.pixels else { throw GraphicsError("\(url.path) decodes to different pixels") }
        return "\(url.lastPathComponent) written and read back"
    }
}

check("zlib round trip") {
    let input = [UInt8]((0..<5000).map { UInt8(truncatingIfNeeded: $0 * 7 / 13) })
    var bound = compressBound(uLong(input.count))
    var packed = [UInt8](repeating: 0, count: Int(bound))
    guard compress2(&packed, &bound, input, uLong(input.count), 6) == Z_OK else { throw GraphicsError("compress2") }
    packed.removeLast(packed.count - Int(bound))
    var length = uLong(input.count)
    var unpacked = [UInt8](repeating: 0, count: input.count)
    guard uncompress(&unpacked, &length, packed, uLong(packed.count)) == Z_OK, unpacked == input else { throw GraphicsError("uncompress") }
    return "\(packed.count) bytes, \(fnv(packed))"
}

if failed { exit(1) }
