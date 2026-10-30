import Foundation
import Testing

/// The SPIR-V and MSL under Sources/*/Shaders are generated from the GLSL by
/// Scripts/compile-shaders.sh, which records hashes of the SPIR-V and of the GLSL in each .metal.
/// A SPIR-V mismatch means the MSL wasn't regenerated (or was edited by hand); a GLSL mismatch
/// means the GLSL was edited without rerunning the script, so both backends run stale code.
@Test func generatedMetalMatchesSPIRV() throws {
    let sources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources")
    let files = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)!
        .compactMap { $0 as? URL }
        .filter { $0.pathExtension == "spv" && $0.deletingLastPathComponent().lastPathComponent == "Shaders" }
    #expect(files.count >= 15)
    for spv in files {
        let metal = spv.deletingPathExtension().appendingPathExtension("metal")
        let header = try String(contentsOf: metal, encoding: .utf8)
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in try Data(contentsOf: spv) {
            hash ^= UInt64(byte)
            hash = hash &* 0x100_0000_01b3
        }
        let expected = "// spirv-fnv1a64: " + String(hash, radix: 16).leftPadding(to: 16)
        #expect(header.contains(expected), "\(metal.lastPathComponent) is stale: rerun Scripts/compile-shaders.sh")
        var sourceHash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in try Data(contentsOf: spv.deletingPathExtension()) where byte != UInt8(ascii: "\r") {
            sourceHash ^= UInt64(byte)
            sourceHash = sourceHash &* 0x100_0000_01b3
        }
        let expectedSource = "// glsl-fnv1a64: " + String(sourceHash, radix: 16).leftPadding(to: 16)
        #expect(header.contains(expectedSource),
                "\(spv.lastPathComponent) is stale against \(spv.deletingPathExtension().lastPathComponent): rerun Scripts/compile-shaders.sh")
        #expect(header.hasPrefix("// Generated from \(spv.deletingPathExtension().lastPathComponent) by Scripts/compile-shaders.sh"))

        // Fragment shaders with outputs beyond color 0 need the color-0-only variant
        // (see ShaderSource.metalFragmentColor0Source), generated from the same SPIR-V.
        let color0 = spv.deletingPathExtension().appendingPathExtension("color0.metal")
        let hasExtraOutputs = (1...7).contains { header.contains("[[color(\($0))]]") }
        #expect(FileManager.default.fileExists(atPath: color0.path) == hasExtraOutputs,
                "\(color0.lastPathComponent) missing or unneeded: rerun Scripts/compile-shaders.sh")
        if hasExtraOutputs {
            let variant = try String(contentsOf: color0, encoding: .utf8)
            #expect(variant.contains(expected) && variant.contains(expectedSource),
                    "\(color0.lastPathComponent) is stale: rerun Scripts/compile-shaders.sh")
            #expect(!(1...7).contains { variant.contains("[[color(\($0))]]") })
        }
    }
}

private extension String {
    func leftPadding(to length: Int) -> String {
        String(repeating: "0", count: max(0, length - count)) + self
    }
}
