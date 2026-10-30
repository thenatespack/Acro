import Foundation
import Testing

/// The MSL under Sources/*/Shaders is generated from the SPIR-V by Scripts/compile-shaders.sh,
/// which records a hash of the SPIR-V in each file. A mismatch means the GLSL was recompiled
/// without regenerating the MSL (or the MSL was edited by hand).
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
        #expect(header.hasPrefix("// Generated from \(spv.deletingPathExtension().lastPathComponent) by Scripts/compile-shaders.sh"))

        // Fragment shaders with outputs beyond color 0 need the color-0-only variant
        // (see ShaderSource.metalFragmentColor0Source), generated from the same SPIR-V.
        let color0 = spv.deletingPathExtension().appendingPathExtension("color0.metal")
        let hasExtraOutputs = (1...7).contains { header.contains("[[color(\($0))]]") }
        #expect(FileManager.default.fileExists(atPath: color0.path) == hasExtraOutputs,
                "\(color0.lastPathComponent) missing or unneeded: rerun Scripts/compile-shaders.sh")
        if hasExtraOutputs {
            let variant = try String(contentsOf: color0, encoding: .utf8)
            #expect(variant.contains(expected), "\(color0.lastPathComponent) is stale: rerun Scripts/compile-shaders.sh")
            #expect(!(1...7).contains { variant.contains("[[color(\($0))]]") })
        }
    }
}

private extension String {
    func leftPadding(to length: Int) -> String {
        String(repeating: "0", count: max(0, length - count)) + self
    }
}
