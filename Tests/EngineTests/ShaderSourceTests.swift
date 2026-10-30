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
    }
}

private extension String {
    func leftPadding(to length: Int) -> String {
        String(repeating: "0", count: max(0, length - count)) + self
    }
}
