import Foundation
import Testing
@testable import EngineBackends

/// The GLSL ES 3.00 that Scripts/compile-shaders.sh generates for the WebGL 2 backend
/// (Scripts/spirv-to-gles.c, from the SPIR-V) and the binding header the backend reads.
@Suite struct WebGL2ShaderTests {
    /// Vertex and fragment stages that read storage buffers (probes, material graphs, GPU particles,
    /// a test shader): no .gles, and the WebGL 2 backend refuses their pipelines.
    static let untranslatable: Set<String> = [
        "decal_graph.frag", "mesh_graph.frag", "mesh_graph_depth.frag", "mesh_terrain.frag", "mesh_probes.frag",
        "mesh_mask_probes.frag", "mesh_paint_probes.frag", "mesh_paint_mask_probes.frag", "probe_debug.frag",
        "particle.vert", "particle_lit.vert", "test_storage_draw.vert",
    ]

    @Test func webGL2EveryShaderHasCurrentGLSLES() throws {
        let files = WebGPUShaderTests.spirvFiles().filter { $0.deletingPathExtension().pathExtension != "comp" }
        #expect(files.count >= 70)
        for spv in files {
            let glsl = spv.deletingPathExtension()
            let gles = glsl.appendingPathExtension("gles")
            guard !Self.untranslatable.contains(glsl.lastPathComponent) else {
                #expect(!FileManager.default.fileExists(atPath: gles.path), "\(gles.lastPathComponent) should not exist")
                continue
            }
            let source = try String(contentsOf: gles, encoding: .utf8)
            // WebGL wants the version on the very first line.
            #expect(source.hasPrefix("#version 300 es\n// Generated from \(glsl.lastPathComponent) by Scripts/compile-shaders.sh"))
            #expect(source.contains("// spirv-fnv1a64: " + WebGPUShaderTests.fnv1a64(try Data(contentsOf: spv))),
                    "\(gles.lastPathComponent) is stale: rerun Scripts/compile-shaders.sh")
            #expect(source.contains("// glsl-fnv1a64: " + WebGPUShaderTests.fnv1a64(try Data(contentsOf: glsl).filter { $0 != UInt8(ascii: "\r") })),
                    "\(spv.lastPathComponent) is stale against \(glsl.lastPathComponent): rerun Scripts/compile-shaders.sh")
            #expect(!source.contains(" buffer ") && !source.contains("image2D"), "\(gles.lastPathComponent)")
            // Every block and sampler the stage declares is in the header, inside the binding table.
            let interface = GLESInterface(source: source)
            for block in interface.uniformBlocks {
                #expect(block.bindingPoint != nil, "\(gles.lastPathComponent): \(block)")
                #expect(source.contains("uniform \(block.name)\n"), "\(gles.lastPathComponent): \(block.name)")
            }
            for sampler in interface.samplers {
                #expect(sampler.textureSlot != nil, "\(gles.lastPathComponent): \(sampler)")
                #expect(sampler.samplerSet == nil || sampler.samplerSlot != nil, "\(gles.lastPathComponent): \(sampler)")
            }
            let declaredBlocks = source.components(separatedBy: "uniform acro_").count - 1
            let declaredSamplers = source.components(separatedBy: "sampler2D").count - 1
            #expect(declaredBlocks + declaredSamplers == interface.uniformBlocks.count + interface.samplers.count, "\(gles.lastPathComponent)")
        }
    }

    /// Varyings link by name: a vertex stage's outputs and the fragment stage's inputs are named by location.
    @Test func webGL2VaryingsAreNamedByLocation() throws {
        let shaders = WebGPUShaderTests.root.appendingPathComponent("Sources/EngineCore/Shaders")
        let vertex = try String(contentsOf: shaders.appendingPathComponent("mesh.vert.gles"), encoding: .utf8)
        let fragment = try String(contentsOf: shaders.appendingPathComponent("mesh.frag.gles"), encoding: .utf8)
        #expect(vertex.contains("out vec3 acro_v0;") || vertex.contains("out highp vec3 acro_v0;"))
        #expect(fragment.contains(" acro_v0;"))
        #expect(!vertex.contains("gl_InstanceIndex") && !vertex.contains("SPIRV_Cross_BaseInstance"))
        // Clip-space z from Vulkan's 0...1 to GL's -1...1.
        #expect(vertex.contains("gl_Position.z = 2.0 * gl_Position.z - gl_Position.w;"))
    }

    @Test func webGL2InterfaceReadsTheHeader() {
        let source = """
        #version 300 es
        // Generated from x.frag by Scripts/compile-shaders.sh — do not edit.
        // acro-ubo acro_fs_u0_0 0 0
        // acro-ubo acro_fs_u2_3 2 3
        // acro-ubo acro_fs_push -1 -1
        // acro-sampler acro_t2_9_s2_17 2 9 2 17 0
        // acro-sampler acro_t2_10 2 10 -1 -1 0
        // acro-sampler acro_t1_0 1 0 1 0 1
        precision highp float;
        // acro-ubo ignored 2 4
        """
        let interface = GLESInterface(source: source)
        #expect(interface.uniformBlocks.map(\.name) == ["acro_fs_u0_0", "acro_fs_u2_3", "acro_fs_push"])
        #expect(interface.uniformBlocks.map(\.bindingPoint) == [0, 3, 1])
        #expect(interface.samplers == [
            GLESInterface.Sampler(name: "acro_t2_9_s2_17", textureSet: 2, textureBinding: 9, samplerSet: 2, samplerBinding: 17, shadow: false),
            GLESInterface.Sampler(name: "acro_t2_10", textureSet: 2, textureBinding: 10, samplerSet: nil, samplerBinding: nil, shadow: false),
            GLESInterface.Sampler(name: "acro_t1_0", textureSet: 1, textureBinding: 0, samplerSet: 1, samplerBinding: 0, shadow: true),
        ])
        #expect(interface.samplers.map(\.textureSlot) == [1, 2, 0])
        #expect(interface.samplers.map(\.samplerSlot) == [1, nil, 0])
    }

    /// The shadow map is a sampler2DShadow at set 1; the mesh shader's samplers combine set 2's textures and samplers.
    @Test func webGL2MeshShaderLayout() throws {
        let shaders = WebGPUShaderTests.root.appendingPathComponent("Sources/EngineCore/Shaders")
        let fragment = GLESInterface(source: try String(contentsOf: shaders.appendingPathComponent("mesh.frag.gles"), encoding: .utf8))
        #expect(fragment.samplers.contains { $0.name == "acro_t1_0" && $0.shadow })
        #expect(fragment.samplers.contains { $0.name == "acro_t2_9_s2_17" && !$0.shadow })
        #expect(fragment.uniformBlocks.contains { $0.name == "acro_fs_u0_0" })
        let blit = GLESInterface(source: try String(contentsOf: shaders.appendingPathComponent("blit.frag.gles"), encoding: .utf8))
        #expect(blit.uniformBlocks.map(\.name) == ["acro_fs_push"])
        #expect(blit.samplers.map(\.name) == ["acro_t1_0"])
    }
}
