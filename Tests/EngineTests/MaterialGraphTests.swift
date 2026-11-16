import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// Material graphs: the .material `graph` format, the compiler (IR, MSL and SPIR-V splicing),
// the importer, and the shader variant rendered on every backend.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MaterialGraphTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "MaterialGraph")
}

private func graph(_ json: String) throws -> MaterialGraph {
    try AssetJSON.decoder().decode(MaterialGraph.self, from: Data(json.utf8))
}

/// Runs spirv-val on `spirv` when it is installed (nil when it isn't): its output on failure, "" when valid.
private func spirvValidation(_ spirv: [UInt8]) -> String? {
    let candidates = ["/opt/homebrew/bin/spirv-val", "/usr/local/bin/spirv-val", "/usr/bin/spirv-val"]
    guard let tool = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else { return nil }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MaterialGraphTests-\(UUID().uuidString).spv")
    defer { try? FileManager.default.removeItem(at: url) }
    guard (try? Data(spirv).write(to: url)) != nil else { return nil }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: tool)
    process.arguments = ["--target-env", "vulkan1.1", url.path]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    guard (try? process.run()) != nil else { return nil }
    process.waitUntilExit()
    let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    return process.terminationStatus == 0 ? "" : output
}

@MainActor @Suite struct MaterialGraphTests {
    @Test func nodesFlattenTheirFieldsAndRoundTrip() throws {
        let g = try graph(#"""
        {"nodes": [{"id": "n", "type": "noise", "kind": "fbm", "scale": 4, "uv": "flow", "position": [10, 20]},
                   {"id": "flow", "type": "scrollUV", "speed": [0.1, 0]}],
         "output": {"baseColor": "n.xxx", "roughness": 0.3}}
        """#)
        #expect(g.nodes.count == 2 && g.nodes[0].type == "noise" && g.nodes[0].position == Vec2(10, 20))
        #expect(g.nodes[0]["kind"] == .string("fbm") && g.nodes[0]["scale"] == .int(4) && g.nodes[0].links == ["flow"])
        #expect(try AssetJSON.decoder().decode(MaterialGraph.self, from: AssetJSON.encode(g)) == g)
        #expect(try graph("{}") == MaterialGraph())
        // The graph rides along in .material files; files without one are unchanged.
        var material = MaterialAsset(alphaMode: .blend)
        material.graph = g
        #expect(try AssetJSON.decoder().decode(MaterialAsset.self, from: AssetJSON.encode(material)) == material)
        #expect(try AssetJSON.decoder().decode(MaterialAsset.self, from: AssetJSON.encode(MaterialAsset())).graph == nil)
    }

    @Test func linksParseSwizzles() {
        #expect(MaterialGraphLink("tex.rgb") == MaterialGraphLink(node: "tex", swizzle: [0, 1, 2]))
        #expect(MaterialGraphLink("n.x") == MaterialGraphLink(node: "n", swizzle: [0]))
        #expect(MaterialGraphLink("my.node") == MaterialGraphLink(node: "my.node"))
        #expect(MaterialGraphLink("noise") == MaterialGraphLink(node: "noise"))
        #expect(MaterialGraphLink("  ") == nil)
        #expect(MaterialGraphLink("a.wzyx")?.description == "a.wzyx")
    }

    @Test func everyPresetCompilesToValidShaders() throws {
        for name in MaterialGraph.presetNames {
            let preset = try #require(MaterialGraph.preset(name))
            let result = MaterialGraphCompiler.compile(preset)
            #expect(result.warnings.isEmpty, "\(name): \(result.warnings)")
            let program = try #require(result.program, "\(name)")
            #expect(program.metalFragment.contains(program.code) && program.metalFragment.contains("fragment_main"))
            #expect(program.metalFragmentColor0?.contains(program.code) == true)
            #expect(!program.metalFragment.contains("float4 a = baseColorMap.sample"), "\(name): placeholder body left in")
            #expect(program.spirvFragment.count % 4 == 0 && program.spirvFragment.count > 1000)
            if let validation = spirvValidation(program.spirvFragment) {
                #expect(validation.isEmpty, "\(name): \(validation)")
            }
            // The depth-only variant (masked graphs in shadows and the depth prepass).
            let depthMetal = try #require(program.metalDepthFragment, "\(name)")
            let depthSPIRV = try #require(program.spirvDepthFragment, "\(name)")
            #expect(depthMetal.contains(program.code) && depthMetal.contains("discard_fragment"), "\(name)")
            #expect(!depthMetal.contains("float4 a = baseColorMap.sample"), "\(name): placeholder body left in")
            #expect(depthSPIRV.count % 4 == 0 && depthSPIRV.count > 500)
            if let validation = spirvValidation(depthSPIRV) {
                #expect(validation.isEmpty, "\(name) depth: \(validation)")
            }
        }
        #expect(MaterialGraph.preset("nope") == nil)
    }

    @Test func constantsDontChangeTheShader() throws {
        let a = try graph(#"{"nodes": [{"id": "c", "type": "color", "value": [1, 0, 0, 1]}], "output": {"baseColor": "c.rgb", "roughness": 0.2}}"#)
        let b = try graph(#"{"nodes": [{"id": "c", "type": "color", "value": [0, 1, 0, 1]}], "output": {"baseColor": "c.rgb", "roughness": 0.9}}"#)
        let c = try graph(#"{"nodes": [{"id": "c", "type": "color", "value": [0, 1, 0, 1]}], "output": {"emissive": "c.rgb"}}"#)
        let pa = try #require(MaterialGraphCompiler.compile(a).program)
        let pb = try #require(MaterialGraphCompiler.compile(b).program)
        let pc = try #require(MaterialGraphCompiler.compile(c).program)
        #expect(pa.key == pb.key && pa.values != pb.values && pa != pb)
        #expect(pa.key != pc.key)
        #expect(pa.values.contains(Vec4(1, 0, 0, 1)) && pb.values.contains(Vec4(0.9, 0, 0, 0)))
        #expect(!pa.usesTime)
        let lava = try #require(MaterialGraph.preset("lava"))
        #expect(MaterialGraphCompiler.compile(lava).program?.usesTime == true)
    }

    @Test func problemsAreReportedAndCompileWithDefaults() throws {
        let g = try graph(#"""
        {"nodes": [{"id": "a", "type": "math", "op": "add", "a": "b", "b": 1},
                   {"id": "b", "type": "math", "op": "multiply", "a": "a"},
                   {"id": "x", "type": "wobble"},
                   {"id": "x", "type": "value"},
                   {"id": "m", "type": "math", "op": "frobnicate"},
                   {"id": "t", "type": "texture"},
                   {"id": "s", "type": "value", "value": 2}],
         "output": {"baseColor": "missing", "roughness": "s.z", "glow": 1, "metallic": "a", "opacity": "m", "emissive": "t.rgb"}}
        """#)
        let result = MaterialGraphCompiler.compile(g)
        let text = result.warnings.joined(separator: "\n")
        #expect(text.contains("cycle"))
        #expect(text.contains("unknown type 'wobble'"))
        #expect(text.contains("duplicate node id 'x'"))
        #expect(text.contains("unknown math op 'frobnicate'"))
        #expect(text.contains("node 't' has no texture"))
        #expect(text.contains("no node 'missing'"))
        #expect(text.contains("unknown output 'glow'"))
        #expect(result.program != nil, "problems fall back to defaults instead of failing")
        // "s.z" on a scalar splats; no warning for that.
        #expect(!text.contains("'s.z'"))
    }

    @Test func texturesTakeSlotsInOrderUpToFive() throws {
        func ref(_ n: UInt64) -> String { AssetReference(AssetID(high: 1, low: n)).description }
        var nodes: [String] = []
        for i in 1...7 { nodes.append(#"{"id": "t\#(i)", "type": "texture", "texture": "\#(ref(UInt64(i % 6 + 1)))"}"#) }
        nodes.append(#"{"id": "tri", "type": "triplanar", "texture": "\#(ref(2))"}"#)
        let g = try graph(#"{"nodes": [\#(nodes.joined(separator: ","))], "output": {"baseColor": "t1.rgb", "emissive": "t2.rgb", "normal": "tri.xyz", "metallic": "t5.r", "roughness": "t6.g", "occlusion": "t3.b", "opacity": "t4.a"}}"#)
        let result = MaterialGraphCompiler.compile(g)
        let program = try #require(result.program)
        #expect(program.textures.count == 5)
        #expect(result.warnings.contains { $0.contains("more than 5 different textures") })
        if let validation = spirvValidation(program.spirvFragment) { #expect(validation.isEmpty, "\(validation)") }
    }

    @Test func templateIsTheUnoptimizedGraphShader() throws {
        let template = try MaterialGraphCompiler.template.get()
        #expect(template.metal.contains("void graphSurface("))
        let splicer = try SPIRVSplicer(template.spirv)
        #expect(splicer.instructions.contains { $0.opcode == SPIRVSplicer.Op.name && SPIRVSplicer.string($0.words[2...]) == "graphSurface(" })
    }

    // MARK: Importer

    @Test func importerResolvesTexturesAndReportsWarnings() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        try database.createProceduralTexture(ProceduralTexture(generator: .noise, width: 8, height: 8), at: "Textures/n.proctex")
        let texture = try #require(database.id(forPath: "Textures/n.proctex"))
        var material = MaterialAsset(alphaMode: .mask)
        material.graph = try graph(#"""
        {"nodes": [{"id": "t", "type": "texture", "texture": "Textures/n.proctex"},
                   {"id": "bad", "type": "texture", "texture": "Textures/none.png"}],
         "output": {"baseColor": "t.rgb", "opacity": "bad.a"}}
        """#)
        let id = try database.createMaterial(material, at: "Materials/graph.material")
        let imported = try #require(database.material(AssetReference(id)))
        #expect(imported.texture == AssetReference(texture) && imported.normalTexture == nil && imported.shading == .pbr)
        #expect(imported.graph?.node("t")?["texture"] == .string(AssetReference(texture).description))
        #expect(imported.alphaMode == .mask)
        // The file keeps the author's path.
        #expect(database.materialFile(of: id)?.graph?.node("t")?["texture"] == .string("Textures/n.proctex"))
        // Writing reports the problems and reimports (placed copies update).
        let revision = database.revision(of: id)
        var edited = try #require(database.materialFile(of: id))
        edited.graph?.output["roughness"] = .string("nothing")
        let warnings = try database.writeMaterialFile(edited, to: id)
        #expect(warnings.contains { $0.contains("no texture 'Textures/none.png'") })
        #expect(warnings.contains { $0.contains("no node 'nothing'") })
        #expect(database.revision(of: id) > revision)
        #expect(database.materialGraphWarnings(edited).contains { $0.contains("no node 'nothing'") })
        // The runtime material carries the program and the graph's texture in slot 1.
        let engineMaterial = try #require(database.material(AssetReference(id))).material(textures: { _ in nil })
        #expect(engineMaterial.graph != nil && engineMaterial.shading == .pbr && !engineMaterial.alphaTested)
        // Masked: its shadow and depth prepass run the graph's depth variant.
        #expect(engineMaterial.masksDepth)
        var codeBuilt = engineMaterial
        codeBuilt.graph?.metalDepthFragment = nil  // a program built in code without the depth variant
        #expect(!codeBuilt.masksDepth)
    }

    // MARK: GPU

    /// Renders a plane facing the camera with `material` and returns the center pixel.
    private func centerPixel(_ material: Material, renderer: SceneRenderer, device: RenderDevice, frames: TestFrames,
                                        target: RenderTarget, elapsed: Double = 0) throws -> [UInt8] {
        try renderer.registerMaterial(material, key: "MaterialGraphTests")
        let world = World()
        world.time.elapsed = elapsed
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -normalize(Vec3(0.3, 0.6, 0.7)))), DirectionalLight(intensity: 1))
        _ = world.spawn(Transform(rotation: Quat(angle: .pi / 2, axis: Vec3(1, 0, 0)), scale: Vec3(4, 1, 4)),
                        MeshRenderer(mesh: .plane, material: MaterialHandle("MaterialGraphTests")))
        world.propagateTransforms()
        let view = SceneView(view: Mat4.lookAt(eye: Vec3(0, 0, 3), target: .zero),
                             projection: Mat4.perspective(fovY: 0.6, aspect: 1, near: 0.1, far: 10))
        var pixels: Image?
        try frames.run { frame in
            renderer.beginViews(world: world, frame: frame)
            renderer.renderView(view, into: target, frame: frame)
            device.readBack(target.gpu) { pixels = $0 }
        }
        let image = try #require(pixels)
        let i = (16 * image.width + 16) * 4
        return Array(image.pixels[i..<i + 4])
    }

    /// The graph's output drives the lit shader on Metal and on Vulkan: an unlit emissive color
    /// comes out as that color, changing a constant (same shader) changes the pixel, time moves
    /// UVs, and every preset builds a pipeline that draws something.
    @Test func graphShaderRendersOnEveryBackend() throws {
        let emissive = try graph(#"""
        {"nodes": [{"id": "c", "type": "color", "value": [0.25, 0.5, 0.75, 1]}],
         "output": {"baseColor": [0, 0, 0], "emissive": "c.rgb", "roughness": 1, "occlusion": 0}}
        """#)
        let striped = try graph(#"""
        {"nodes": [{"id": "s", "type": "scrollUV", "speed": [0.25, 0]},
                   {"id": "f", "type": "math", "op": "fract", "a": "s.x"},
                   {"id": "x", "type": "math", "op": "step", "a": 0.5, "b": "f"}],
         "output": {"baseColor": [0, 0, 0], "emissive": "x", "occlusion": 0}}
        """#)
        var results: [String: [String: [UInt8]]] = [:]
        try TestDevices.forEachBackend { device, frames in
            let renderer = try SceneRenderer(device: device, quality: .low)
            let target = try RenderTarget(device: device, width: 32, height: 32, multisampled: false)
            @MainActor func render(_ g: MaterialGraph, elapsed: Double = 0) throws -> [UInt8] {
                var asset = MaterialAsset()
                asset.graph = g
                return try centerPixel(asset.material(textures: { _ in nil }), renderer: renderer, device: device, frames: frames,
                                       target: target, elapsed: elapsed)
            }
            var colors: [String: [UInt8]] = [:]
            colors["emissive"] = try render(emissive)
            var brighter = emissive
            brighter.nodes[0]["value"] = .array([1, 0, 0, 1].map { JSONValue.double($0) })
            colors["red"] = try render(brighter)
            // uv.x is about 0.5 at the center; scrolled by 0.25 / s: 0.75 after 1 s (lit), 1.25 → 0.25 after 3 s (dark).
            colors["stripe1"] = try render(striped, elapsed: 1)
            colors["stripe3"] = try render(striped, elapsed: 3)
            for name in MaterialGraph.presetNames {
                let preset = try #require(MaterialGraph.preset(name))
                colors[name] = try render(preset)
            }
            colors["background"] = try centerPixel(Material(baseColor: Vec4(0, 0, 0, 0), alphaMode: .blend), renderer: renderer,
                                                   device: device, frames: frames, target: target)
            results["\(device.backend)"] = colors
        }
        for (backend, colors) in results {
            let label = "\(backend): \(colors.sorted { $0.key < $1.key })"
            let e = try #require(colors["emissive"])
            // Linear 0.25, 0.5, 0.75 in an sRGB (or linear) target; just check the ordering and hue.
            #expect(e[0] < e[1] && e[1] < e[2] && e[2] > 100, "\(label)")
            let red = try #require(colors["red"])
            #expect(red[0] > 200 && red[1] < 30 && red[2] < 30, "\(label)")
            #expect(colors["stripe1"]![0] > 200 && colors["stripe3"]![0] < 80, "\(label)")
            for name in MaterialGraph.presetNames {
                #expect(colors[name] != colors["background"], "\(name) drew nothing, \(label)")
            }
        }
        if let metal = results["metal"], let vulkan = results["vulkan"] {
            for (name, color) in metal {
                let other = try #require(vulkan[name])
                #expect(zip(color, other).allSatisfy { abs(Int($0) - Int($1)) <= 3 }, "\(name): metal \(color) vulkan \(other)")
            }
        }
    }

    /// A masked graph's cut-outs are cut out of its shadow and of the depth prepass, on Metal and
    /// on Vulkan. A 2x2 plane at y = 1 keeps only its +x half (uv.x >= 0.5) over a ground plane;
    /// the sun travels along (2, -1, 0), so the shadow of caster x lands on the ground at x + 2,
    /// clear of the caster seen from above. A decal on the ground (it paints what the depth
    /// prepass holds) shows through the hole only when the prepass is cut out too.
    @Test func maskedGraphCutsOutShadowsAndDepth() throws {
        let halfCut = try graph(#"""
        {"nodes": [{"id": "keep", "type": "math", "op": "step", "a": 0.5, "b": "uv.x"}],
         "output": {"baseColor": [0, 0, 0], "emissive": [1, 0, 0], "opacity": "keep", "occlusion": 0}}
        """#)
        let eye = Vec3(1, 8, 0)
        let view = SceneView(view: Mat4.lookAt(eye: eye, target: Vec3(1, 0, 0), up: Vec3(0, 0, -1)),
                             projection: Mat4.perspective(fovY: 0.9, aspect: 1, near: 1, far: 20))
        let size = 64
        func pixel(_ image: Image, _ p: Vec3) -> [UInt8] {
            let clip = view.viewProjection * Vec4(p, 1)
            let x = Int((clip.x / clip.w * 0.5 + 0.5) * Float(size)), y = Int((0.5 - clip.y / clip.w * 0.5) * Float(size))
            let i = (min(max(y, 0), size - 1) * image.width + min(max(x, 0), size - 1)) * 4
            return Array(image.pixels[i..<i + 4])
        }
        // Ground points: lit, under the cut half's shadow, under the kept half's shadow, seen
        // through the hole, and the caster's kept half.
        let points: [String: Vec3] = ["lit": Vec3(-2, 0, 0), "cutShadow": Vec3(1.5, 0, 0), "keptShadow": Vec3(2.5, 0, 0),
                                      "hole": Vec3(-0.5, 0, 0), "caster": Vec3(0.5, 1, 0)]
        var results: [String: [String: [UInt8]]] = [:]
        try TestDevices.forEachBackend { device, frames in
            let renderer = try SceneRenderer(device: device, quality: .low)
            let target = try RenderTarget(device: device, width: size, height: size, multisampled: false)
            try renderer.registerMaterial(Material(baseColor: Vec4(0.3, 0.3, 0.3, 1), roughness: 1), key: "MaterialGraphTests.ground")
            @MainActor func render(_ alphaMode: AlphaMode, decal: Bool) throws -> [String: [UInt8]] {
                var asset = MaterialAsset(alphaMode: alphaMode)
                asset.graph = halfCut
                try renderer.registerMaterial(asset.material(textures: { _ in nil }), key: "MaterialGraphTests.caster")
                let world = World()
                _ = world.spawn(Transform(), DirectionalLight(intensity: 1, direction: normalize(Vec3(2, -1, 0))))
                _ = world.spawn(Transform(scale: Vec3(12, 1, 12)), MeshRenderer(mesh: .plane, material: MaterialHandle("MaterialGraphTests.ground")))
                _ = world.spawn(Transform(position: Vec3(0, 1, 0), scale: Vec3(2, 1, 2)),
                                MeshRenderer(mesh: .plane, material: MaterialHandle("MaterialGraphTests.caster")))
                if decal {
                    _ = world.spawn(Transform(rotation: Quat(angle: -.pi / 2, axis: Vec3(1, 0, 0)), scale: Vec3(12, 12, 0.5)),
                                    Decal(tint: Vec3(0, 0, 1), emissive: 2))
                }
                world.propagateTransforms()
                var pixels: Image?
                try frames.run { frame in
                    renderer.beginViews(world: world, frame: frame, shadowFocus: view)
                    renderer.renderView(view, into: target, frame: frame)
                    device.readBack(target.gpu) { pixels = $0 }
                }
                let image = try #require(pixels)
                return points.mapValues { pixel(image, $0) }
            }
            var colors: [String: [UInt8]] = [:]
            for (name, color) in try render(.mask, decal: false) { colors["mask." + name] = color }
            for (name, color) in try render(.opaque, decal: false) { colors["opaque." + name] = color }
            for (name, color) in try render(.mask, decal: true) { colors["decal." + name] = color }
            results["\(device.backend)"] = colors
        }
        func brightness(_ c: [UInt8]?) -> Int { c.map { Int($0[0]) + Int($0[1]) + Int($0[2]) } ?? -1 }
        for (backend, colors) in results {
            let label = "\(backend): \(colors.sorted { $0.key < $1.key })"
            let lit = brightness(colors["mask.lit"])
            #expect(lit > 150, "\(label)")
            // The kept half (red) is drawn; the opaque graph shades both shadow points.
            #expect(colors["mask.caster"]![0] > 200 && colors["mask.caster"]![2] < 80, "\(label)")
            #expect(brightness(colors["opaque.cutShadow"]) < lit * 3 / 4 && brightness(colors["opaque.keptShadow"]) < lit * 3 / 4, "\(label)")
            // Masked: only the kept half casts a shadow.
            #expect(brightness(colors["mask.keptShadow"]) < lit * 3 / 4, "\(label)")
            #expect(abs(brightness(colors["mask.cutShadow"]) - lit) < 12, "\(label)")
            // The ground seen through the hole is lit ground, and the decal paints it.
            #expect(abs(brightness(colors["mask.hole"]) - lit) < 12, "\(label)")
            let hole = colors["decal.hole"]!, outside = colors["decal.lit"]!
            #expect(hole[2] > 150 && hole[0] < 60 && outside[2] > 150 && outside[0] < 60, "\(label)")
        }
        if let metal = results["metal"], let vulkan = results["vulkan"] {
            for (name, color) in metal {
                let other = try #require(vulkan[name])
                #expect(zip(color, other).allSatisfy { abs(Int($0) - Int($1)) <= 3 }, "\(name): metal \(color) vulkan \(other)")
            }
        }
    }
}
