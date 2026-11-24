import Foundation
import Testing
@testable import EngineBackends

/// The WGSL that Scripts/compile-shaders.sh generates for the WebGPU backend (naga, from the SPIR-V)
/// and the reflection the backend builds its bind group layouts from.
@Suite struct WebGPUShaderTests {
    /// Shaders naga can't translate (see compile-shaders.sh): no .wgsl, and the WebGPU backend
    /// refuses their pipelines. fsr3_clear writes a storage image without a format.
    static let untranslatable: Set<String> = ["fsr3_clear.comp"]

    static var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    /// Every generated SPIR-V module under Sources/ and Tests/ (the GLSL path is the .spv without its extension).
    static func spirvFiles() -> [URL] {
        ["Sources", "Tests"].flatMap { directory in
            FileManager.default.enumerator(at: root.appendingPathComponent(directory), includingPropertiesForKeys: nil)!
                .compactMap { $0 as? URL }.filter { $0.pathExtension == "spv" }
        }
    }

    static func fnv1a64(_ bytes: some Sequence<UInt8>) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 0x100_0000_01b3
        }
        let hex = String(hash, radix: 16)
        return String(repeating: "0", count: 16 - hex.count) + hex
    }

    @Test func webGPUEveryShaderHasCurrentWGSL() throws {
        let files = Self.spirvFiles()
        #expect(files.count >= 100)
        for spv in files {
            let glsl = spv.deletingPathExtension()
            let wgsl = glsl.appendingPathExtension("wgsl")
            guard !Self.untranslatable.contains(glsl.lastPathComponent) else {
                #expect(!FileManager.default.fileExists(atPath: wgsl.path), "\(wgsl.lastPathComponent) should not exist")
                continue
            }
            let source = try String(contentsOf: wgsl, encoding: .utf8)
            #expect(source.hasPrefix("// Generated from \(glsl.lastPathComponent) by Scripts/compile-shaders.sh"))
            #expect(source.contains("// spirv-fnv1a64: " + Self.fnv1a64(try Data(contentsOf: spv))),
                    "\(wgsl.lastPathComponent) is stale: rerun Scripts/compile-shaders.sh")
            #expect(source.contains("// glsl-fnv1a64: " + Self.fnv1a64(try Data(contentsOf: glsl).filter { $0 != UInt8(ascii: "\r") })),
                    "\(spv.lastPathComponent) is stale against \(glsl.lastPathComponent): rerun Scripts/compile-shaders.sh")
            #expect(source.contains("diagnostic(off, derivative_uniformity);"))
            // WebGPU has no push constants: they must have become a uniform buffer.
            #expect(!source.contains("var<immediate>") && !source.contains("var<push_constant>"), "\(wgsl.lastPathComponent)")
            #expect(!source.contains("340282350000000000000000000000000000000f"), "\(wgsl.lastPathComponent): inexact FLT_MAX")
        }
    }

    /// Every binding of every generated module is in the table of `ShaderSource` (WGSL column).
    @Test func webGPUBindingsFollowTheTable() throws {
        for spv in Self.spirvFiles() {
            let wgsl = spv.deletingPathExtension().appendingPathExtension("wgsl")
            guard let source = try? String(contentsOf: wgsl, encoding: .utf8) else { continue }
            for binding in WGSLReflection.bindings(source) {
                let ok: Bool
                switch (binding.group, binding.kind) {
                case (0, .uniformBuffer): ok = binding.binding == 0
                case (1, .texture): ok = binding.binding == 0
                case (1, .sampler): ok = binding.binding == 1
                case (2, .uniformBuffer): ok = (2...7).contains(binding.binding)
                case (2, .texture): ok = (9...15).contains(binding.binding)
                case (2, .sampler(comparison: false)): ok = (17...23).contains(binding.binding)
                case (2, .storageBuffer): ok = (24...31).contains(binding.binding)
                case (2, .storageTexture): ok = (32...39).contains(binding.binding)
                case (3, .uniformBuffer): ok = binding.binding == 0
                default: ok = false
                }
                #expect(ok, "\(wgsl.lastPathComponent): \(binding) is outside the binding table")
            }
        }
    }

    @Test func webGPUReflectionReadsBindingsAndOutputs() {
        let source = """
        struct Block { member: vec4<f32>, }
        struct FragmentOutput {
            @location(0) member: vec4<f32>,
            @location(1) member_1: vec2<f32>,
        }
        @group(0) @binding(0)
        var<uniform> global: Block;
        @group(2) @binding(9)
        var global_1: texture_2d<f32>;
        @group(2) @binding(10)
        var global_10: texture_2d<f32>;
        @group(2) @binding(11)
        var unused: texture_2d<f32>;
        @group(2) @binding(17)
        var global_2: sampler;
        @group(2) @binding(25)
        var<storage, read_write> global_3: Block;
        @group(2) @binding(33)
        var global_4: texture_storage_2d<r16float,write>;
        @group(1) @binding(0)
        var global_5: texture_depth_2d;
        @group(3) @binding(0)
        var<uniform> global_6: Block;

        @fragment
        fn main() -> FragmentOutput {
            let a = textureSample(global_1, global_2, global.member.xy);
            let b = textureLoad(global_10, vec2<i32>(0i), 0i);
            let c = textureLoad(global_5, vec2<i32>(0i), 0i) + global_6.member.x;
            global_3.member = a;
            textureStore(global_4, vec2<i32>(0i), b);
            return FragmentOutput(a, vec2(c));
        }
        """
        let bindings = WGSLReflection.bindings(source)
        #expect(bindings == [
            WGSLBinding(group: 0, binding: 0, kind: .uniformBuffer),
            WGSLBinding(group: 1, binding: 0, kind: .texture(.depth)),
            WGSLBinding(group: 2, binding: 9, kind: .texture(.float)),
            WGSLBinding(group: 2, binding: 10, kind: .texture(.unfilterableFloat)),
            WGSLBinding(group: 2, binding: 17, kind: .sampler(comparison: false)),
            WGSLBinding(group: 2, binding: 25, kind: .storageBuffer(readOnly: false)),
            WGSLBinding(group: 2, binding: 33, kind: .storageTexture(format: "r16float", access: "write-only")),
            WGSLBinding(group: 3, binding: 0, kind: .uniformBuffer),
        ])
        #expect(WGSLReflection.fragmentOutputs(source) == [0, 1])
        #expect(WGSLReflection.fragmentOutputs("@fragment\nfn main() -> @location(0) vec4<f32> { return vec4(1f); }") == [0])
    }

    /// The generated mesh shaders: the shadow map is split into a depth texture and a comparison
    /// sampler, and push constants live at group 3.
    @Test func webGPUMeshShaderLayout() throws {
        let shaders = Self.root.appendingPathComponent("Sources/EngineCore/Shaders")
        let fragment = WGSLReflection.bindings(try String(contentsOf: shaders.appendingPathComponent("mesh.frag.wgsl"), encoding: .utf8))
        #expect(fragment.contains(WGSLBinding(group: 1, binding: 0, kind: .texture(.depth))))
        #expect(fragment.contains(WGSLBinding(group: 1, binding: 1, kind: .sampler(comparison: true))))
        let blit = try String(contentsOf: shaders.appendingPathComponent("blit.frag.wgsl"), encoding: .utf8)
        #expect(WGSLReflection.bindings(blit).contains(WGSLBinding(group: 3, binding: 0, kind: .uniformBuffer)))
    }
}
