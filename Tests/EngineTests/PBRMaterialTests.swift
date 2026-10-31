import Foundation
import Testing
@testable import Engine

/// PBR materials: `MaterialAsset`'s file format, the glTF mapping, tangent generation and the
/// alpha-mask flag reaching batching and pipeline choice.
@Suite struct PBRMaterialTests {
    private static func reference(_ n: UInt64, _ sub: String? = nil) -> AssetReference {
        AssetReference(AssetID(high: 0x1234, low: n), subAsset: sub)
    }

    // MARK: MaterialAsset Codable

    @Test func materialAssetRoundTripsEveryField() throws {
        let asset = MaterialAsset(
            shading: .pbr, baseColor: Vec4(0.1, 0.2, 0.3, 0.4), texture: Self.reference(1, "texture/a"), filter: .nearest,
            mipFilter: .none, addressMode: .mirrorRepeat, uvScale: Vec2(2, 3), uvOffset: Vec2(0.25, 0.5), uvRotation: 0.7,
            checker: true, emissive: 0.5, specular: 0.6, shininess: 12, metallic: 0.8, roughness: 0.3,
            metallicRoughnessTexture: Self.reference(2), normalTexture: Self.reference(3), normalScale: 0.9,
            occlusionTexture: Self.reference(4), occlusionStrength: 0.7, emissiveColor: Vec3(1, 0.5, 0.25),
            emissiveTexture: Self.reference(5), emissiveStrength: 4, alphaMode: .mask, alphaCutoff: 0.33, doubleSided: true)
        let data = try AssetJSON.encoder().encode(asset)
        #expect(try AssetJSON.decoder().decode(MaterialAsset.self, from: data) == asset)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"alphaMode\" : \"mask\"") && json.contains("\"shading\" : \"pbr\""))

        // Every default, including Blinn-Phong and the other alpha modes.
        for value in [MaterialAsset(), MaterialAsset(shading: .blinnPhong, alphaMode: .blend), MaterialAsset(alphaMode: .opaque)] {
            #expect(try AssetJSON.decoder().decode(MaterialAsset.self, from: AssetJSON.encoder().encode(value)) == value)
        }
    }

    @Test func oldMaterialFilesKeepBlinnPhong() throws {
        // A `.material` file from before PBR: no shading key, `isTransparent`, legacy fields.
        let old = #"{ "baseColor" : [0.8, 0.3, 0.2, 1], "specular" : 0.5, "shininess" : 20, "isTransparent" : true, "uvScale" : [2, 2] }"#
        let decoded = try AssetJSON.decoder().decode(MaterialAsset.self, from: Data(old.utf8))
        #expect(decoded.shading == .blinnPhong)
        #expect(decoded.alphaMode == .blend && decoded.isTransparent)
        #expect(decoded.specular == 0.5 && decoded.shininess == 20 && decoded.uvScale == Vec2(2, 2))
        // New keys take their defaults.
        let d = MaterialAsset()
        #expect(decoded.metallic == d.metallic && decoded.roughness == d.roughness && decoded.normalTexture == nil)
        #expect(decoded.emissiveColor == .zero && decoded.emissiveStrength == 1 && decoded.alphaCutoff == 0.5)
        #expect(decoded.uvOffset == .zero && decoded.uvRotation == 0 && decoded.occlusionStrength == 1)

        // An empty file is the default material, but Blinn-Phong; isTransparent false stays opaque.
        let empty = try AssetJSON.decoder().decode(MaterialAsset.self, from: Data("{}".utf8))
        var expected = MaterialAsset()
        expected.shading = .blinnPhong
        #expect(empty == expected)
        let opaque = try AssetJSON.decoder().decode(MaterialAsset.self, from: Data(#"{ "isTransparent" : false }"#.utf8))
        #expect(opaque.alphaMode == .opaque)
        // alphaMode wins over the old key; glTF spelling is accepted too.
        let both = try AssetJSON.decoder().decode(
            MaterialAsset.self, from: Data(#"{ "isTransparent" : true, "alphaMode" : "MASK", "shading" : "pbr" }"#.utf8))
        #expect(both.alphaMode == .mask && both.shading == .pbr)
    }

    @Test func materialAssetResolvesEveryTexture() {
        let asset = MaterialAsset(texture: Self.reference(1), metallicRoughnessTexture: Self.reference(2),
                                  normalTexture: Self.reference(3), occlusionTexture: Self.reference(4),
                                  emissiveTexture: Self.reference(5))
        #expect(asset.textureReferences.map(\.slot) == [.baseColor, .metallicRoughness, .normal, .occlusion, .emissive])
        var asked: [AssetReference] = []
        _ = asset.material(textures: { asked.append($0); return nil })
        #expect(asked == (1...5).map { Self.reference($0) })
    }

    // MARK: glTF mapping

    @Test func gltfMaterialMapsEveryField() {
        var m = ImportedMaterial(name: "Full")
        m.baseColorFactor = Vec4(0.5, 0.6, 0.7, 0.4)
        m.baseColorTexture = TextureReference(texture: 0, transform: TextureTransform(offset: Vec2(0.1, 0.2), rotation: 0.3, scale: Vec2(2, 4)))
        m.metallicFactor = 0.25
        m.roughnessFactor = 0.75
        m.metallicRoughnessTexture = TextureReference(texture: 1)
        m.normalTexture = TextureReference(texture: 2)
        m.normalScale = 0.8
        m.occlusionTexture = TextureReference(texture: 3)
        m.occlusionStrength = 0.6
        m.emissiveTexture = TextureReference(texture: 4)
        m.emissiveFactor = Vec3(1, 0.5, 0)
        m.emissiveStrength = 3
        m.alphaMode = .mask
        m.alphaCutoff = 0.4
        m.doubleSided = true

        let asset = m.materialAsset(textures: { Self.reference(UInt64($0.texture + 10)) },
                                    sampler: ImportedSampler(magFilter: .nearest, mipFilter: .nearest, wrapU: .clampToEdge))
        #expect(asset.shading == .pbr)
        #expect(asset.baseColor == Vec4(0.5, 0.6, 0.7, 0.4))  // mask keeps alpha for the cutoff
        #expect(asset.texture == Self.reference(10) && asset.metallicRoughnessTexture == Self.reference(11))
        #expect(asset.normalTexture == Self.reference(12) && asset.occlusionTexture == Self.reference(13))
        #expect(asset.emissiveTexture == Self.reference(14))
        #expect(asset.metallic == 0.25 && asset.roughness == 0.75 && asset.normalScale == 0.8 && asset.occlusionStrength == 0.6)
        #expect(asset.emissiveColor == Vec3(1, 0.5, 0) && asset.emissiveStrength == 3)
        #expect(asset.alphaMode == .mask && asset.alphaCutoff == 0.4 && asset.doubleSided)
        #expect(asset.uvScale == Vec2(2, 4) && asset.uvOffset == Vec2(0.1, 0.2) && asset.uvRotation == 0.3)
        #expect(asset.filter == .nearest && asset.mipFilter == .nearest && asset.addressMode == .clampToEdge)
        #expect(asset.emissive == 0)

        // Opaque forces alpha 1, blend keeps it, unlit sets the unlit amount.
        m.alphaMode = .opaque
        #expect(m.materialAsset().baseColor.w == 1)
        m.alphaMode = .blend
        m.unlit = true
        #expect(m.materialAsset().baseColor.w == 0.4 && m.materialAsset().isTransparent && m.materialAsset().emissive == 1)
        // The glTF default material: white, fully metallic and rough.
        let d = ImportedMaterial.gltfDefault.materialAsset()
        #expect(d.metallic == 1 && d.roughness == 1 && d.baseColor == Vec4(1, 1, 1, 1) && d.shading == .pbr)
    }

    @MainActor @Test func engineMaterialTakesTheSamplerAndTransform() {
        var m = ImportedMaterial()
        // No base color texture: the first texture in slot order decides the transform.
        m.normalTexture = TextureReference(texture: 0, transform: TextureTransform(scale: Vec2(3, 3)))
        let e = m.engineMaterial(sampler: ImportedSampler(magFilter: .nearest, minFilter: .linear))
        #expect(e.shading == .pbr && e.uvScale == Vec2(3, 3) && e.normalTexture == nil)
        #expect(e.sampler.magFilter == .nearest && e.sampler.minFilter == .linear)
    }

    @Test func uvTransformMatchesKHRTextureTransform() {
        var material = Material()
        material.uvScale = Vec2(2, 3)
        material.uvOffset = Vec2(0.5, 0.25)
        material.uvRotation = .pi / 2
        let (r0, r1) = material.uvTransformRows
        let uv = Vec2(0.2, 0.4)
        let out = Vec2(r0.x * uv.x + r0.y * uv.y + r0.z, r1.x * uv.x + r1.y * uv.y + r1.z)
        // offset + [cos sin; -sin cos] * (scale * uv) = (0.5 + 1.2, 0.25 - 0.4)
        #expect(abs(out.x - 1.7) < 1e-5 && abs(out.y + 0.15) < 1e-5)
    }

    // MARK: Tangents

    private func checkFrames(_ geometry: MeshGeometry) {
        for v in geometry.vertices {
            let t = Vec3(v.tangent.x, v.tangent.y, v.tangent.z)
            #expect(abs(length(t) - 1) < 1e-4)
            #expect(abs(dot(t, v.normal)) < 1e-4)
            #expect(v.tangent.w == 1 || v.tangent.w == -1)
        }
    }

    @Test func planeTangentsFollowU() {
        let plane = MeshGeometry.plane(size: 2, segments: 2).withTangents()
        #expect(plane.hasTangents)
        checkFrames(plane)
        for v in plane.vertices {
            // U grows along +X, V along +Z: the bitangent cross(n, t) * w = -Z points toward decreasing V.
            #expect(length(Vec3(v.tangent.x, v.tangent.y, v.tangent.z) - Vec3(1, 0, 0)) < 1e-5 && v.tangent.w == 1)
        }
    }

    @Test func gltfStyleQuadAndMirroredUVs() {
        // A quad facing +Z with glTF UVs (V down the image, so V grows toward -Y).
        let n = Vec3(0, 0, 1)
        var quad = MeshGeometry(vertices: [
            MeshVertex(position: Vec3(-1, 1, 0), normal: n, uv: Vec2(0, 0)),
            MeshVertex(position: Vec3(-1, -1, 0), normal: n, uv: Vec2(0, 1)),
            MeshVertex(position: Vec3(1, -1, 0), normal: n, uv: Vec2(1, 1)),
            MeshVertex(position: Vec3(1, 1, 0), normal: n, uv: Vec2(1, 0)),
        ], indices: [0, 1, 2, 0, 2, 3])
        quad.generateTangents()
        for v in quad.vertices {
            #expect(length(Vec3(v.tangent.x, v.tangent.y, v.tangent.z) - Vec3(1, 0, 0)) < 1e-5)
            // cross(+Z, +X) = +Y: up in the image, so the frame is right-handed.
            #expect(v.tangent.w == 1)
        }
        // Mirror U: the tangent flips to -X and the handedness to -1, so the bitangent stays +Y.
        for i in quad.vertices.indices { quad.vertices[i].uv.x = 1 - quad.vertices[i].uv.x }
        quad.generateTangents()
        for v in quad.vertices {
            #expect(length(Vec3(v.tangent.x, v.tangent.y, v.tangent.z) - Vec3(-1, 0, 0)) < 1e-5)
            #expect(v.tangent.w == -1)
            let b = cross(v.normal, Vec3(v.tangent.x, v.tangent.y, v.tangent.z)) * v.tangent.w
            #expect(length(b - Vec3(0, 1, 0)) < 1e-5)
        }
    }

    @Test func builtInMeshesGetOrthonormalFrames() {
        for geometry in [MeshGeometry.cube(), .sphere(), .plane()] {
            let withTangents = geometry.withTangents()
            #expect(!geometry.hasTangents && withTangents.hasTangents)
            checkFrames(withTangents)
        }
        // Sphere tangents point along increasing longitude (U): east, away from the poles.
        let sphere = MeshGeometry.sphere(segments: 16, rings: 8).withTangents()
        let equator = sphere.vertices[4 * 17]  // ring 4 of 8, segment 0: position (0, 0, 0.5)
        #expect(length(Vec3(equator.tangent.x, equator.tangent.y, equator.tangent.z) - Vec3(1, 0, 0)) < 1e-3)
    }

    @Test func degenerateUVsStillGetAFrame() {
        var flat = MeshGeometry(vertices: [
            MeshVertex(position: Vec3(0, 0, 0), normal: Vec3(0, 1, 0)),
            MeshVertex(position: Vec3(1, 0, 0), normal: Vec3(0, 1, 0)),
            MeshVertex(position: Vec3(0, 0, 1), normal: Vec3(0, 1, 0)),
        ], indices: [0, 2, 1])
        flat.generateTangents()
        checkFrames(flat)
    }

    @Test func existingTangentsAreKept() {
        var geometry = MeshGeometry.plane()
        for i in geometry.vertices.indices { geometry.vertices[i].tangent = Vec4(0, 0, 1, -1) }
        #expect(geometry.withTangents().vertices.allSatisfy { $0.tangent == Vec4(0, 0, 1, -1) })
    }

    // MARK: Alpha mask

    @MainActor @Test func alphaMaskChoosesTheAlphaTestedPipeline() {
        let masked = Material(alphaMode: .mask, alphaCutoff: 0.3)
        let opaque = Material()
        #expect(masked.alphaTested && !masked.blends && !masked.isTransparent)
        #expect(!opaque.alphaTested && !opaque.blends)
        #expect(Material(baseColor: Vec4(1, 1, 1, 0.5)).blends)
        #expect(!Material(baseColor: Vec4(1, 1, 1, 0.5), alphaMode: .mask).blends)  // mask never blends
        #expect(Material(alphaMode: .blend).blends)

        #expect(SceneRenderer.pipelineKey(for: masked, blending: false, reversedZ: false).alphaTested)
        #expect(SceneRenderer.pipelineKey(for: masked, blending: true, reversedZ: true).alphaTested)
        #expect(!SceneRenderer.pipelineKey(for: opaque, blending: false, reversedZ: false).alphaTested)
        #expect(SceneRenderer.pipelineKey(for: masked, blending: false, reversedZ: false)
            != SceneRenderer.pipelineKey(for: opaque, blending: false, reversedZ: false))

        // The uniforms carry the cutoff and the PBR flag.
        let uniforms = SceneRenderer.MaterialUniforms(masked)
        #expect(uniforms.flags.x == 0.3 && uniforms.emissive.w == 1)
        #expect(SceneRenderer.MaterialUniforms(Material(shading: .blinnPhong)).emissive.w == 0)
    }

    @MainActor @Test func alphaTestedFlagReachesShadowBatches() {
        let world = World()
        var prep = RenderPrep()
        prep.meshes.register(Bounds(center: .zero, halfExtent: Vec3(repeating: 0.5)), key: "cube")
        prep.materials.register(MaterialTraits(), key: "solid")
        prep.materials.register(MaterialTraits(alphaTested: true), key: "leaves")
        for (i, material) in ["solid", "leaves", "solid", "leaves"].enumerated() {
            _ = world.spawn(Transform(position: Vec3(Float(i) * 2, 0, 0)),
                            MeshRenderer(mesh: MeshHandle("cube"), material: MaterialHandle(material)))
        }
        world.propagateTransforms()
        prep.gather(world: world)
        #expect(prep.items.map(\.alphaTested) == [false, true, false, true])
        #expect(prep.items.allSatisfy { !$0.transparent })

        let viewProj = Mat4.perspective(fovY: .pi / 3, aspect: 1, near: 0.1, far: 100) * Mat4.lookAt(eye: Vec3(3, 5, 20), target: .zero)
        let lightViewProj = Mat4.orthographic(left: -20, right: 20, bottom: -20, top: 20, near: -50, far: 50)
            * Mat4.lookAt(eye: Vec3(0, 1, 0), target: .zero, up: Vec3(0, 0, 1))
        var list = RenderList()
        list.build(items: prep.items, view: Frustum(viewProjection: viewProj), cameraPosition: Vec3(3, 5, 20),
                   shadows: ShadowCasterCulling(lightFrustum: Frustum(viewProjection: lightViewProj), toLight: Vec3(0, 1, 0),
                                                receiverFloor: -10, maxSweep: 100))
        // One depth-only batch for the solid casters, one that keeps the alpha-tested material.
        #expect(list.shadow.count == 2)
        #expect(Set(list.shadow.map(\.material)) == [-1, 1])
        #expect(list.shadow.allSatisfy { $0.count == 2 })
    }
}
