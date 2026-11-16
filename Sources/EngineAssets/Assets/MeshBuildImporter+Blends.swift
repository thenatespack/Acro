import Foundation
import EngineCore
import EngineScene

// The mesh build importer's sculpt look blending (MeshBuildSculptBlend.swift): once every part has
// its material, the group weights in the sculpt pieces' paint become real vertex paint (the mix of
// the same-textured looks' material values) and the blend layers get their opacity.

extension MeshBuildSculptPieces {
    /// A blend layer: its look's piece (whose texture coordinates it shares) and the other looks'
    /// pieces (the surface it lies on).
    struct Layer {
        var piece: Int
        var surfaces: [Int]
    }

    /// Each blend layer by index.
    var layerSurfaces: [Int: Layer] {
        var result: [Int: Layer] = [:]
        for blend in blends.values {
            for (g, layer) in blend.layers.enumerated() {
                guard let layer, let piece = blend.pieces[g] else { continue }
                result[layer] = Layer(piece: piece, surfaces: blend.pieces.compactMap { $0 }.filter { $0 != piece })
            }
        }
        return result
    }
}

extension MeshBuildAO {
    /// The occlusion of each vertex of `geometry` copied from `surfaces`' vertices at the same
    /// position (1 where none is).
    static func copied(to geometry: MeshGeometry, from surfaces: [MeshGeometry]) -> [Float] {
        var byPosition: [SIMD3<UInt32>: Float] = [:]
        for surface in surfaces {
            for v in surface.vertices {
                let p = v.position
                byPosition[SIMD3(p.x.bitPattern, p.y.bitPattern, p.z.bitPattern)] = abs(v.tangent.w) > 0 ? min(abs(v.tangent.w), 1) : 1
            }
        }
        return geometry.vertices.map { v in
            let p = v.position
            return byPosition[SIMD3(p.x.bitPattern, p.y.bitPattern, p.z.bitPattern)] ?? 1
        }
    }
}

extension MeshBuildImporter {
    /// A look's material values that blend in vertex paint.
    struct BlendValues {
        var color: Vec3
        var roughness: Float
        var metallic: Float
        var emission: Vec3

        init(_ m: MaterialAsset) {
            color = Vec3(m.baseColor.x, m.baseColor.y, m.baseColor.z)
            roughness = m.roughness
            metallic = m.metallic
            emission = m.emissiveColor * m.emissiveStrength
        }

        init(color: Vec3, roughness: Float, metallic: Float, emission: Vec3) {
            (self.color, self.roughness, self.metallic, self.emission) = (color, roughness, metallic, emission)
        }

        static func * (v: BlendValues, k: Float) -> BlendValues {
            BlendValues(color: v.color * k, roughness: v.roughness * k, metallic: v.metallic * k, emission: v.emission * k)
        }

        static func + (a: BlendValues, b: BlendValues) -> BlendValues {
            BlendValues(color: a.color + b.color, roughness: a.roughness + b.roughness, metallic: a.metallic + b.metallic,
                        emission: a.emission + b.emission)
        }
    }

    /// Turns the split sculpts' group weights into vertex paint and adjusts their materials (see
    /// the notes at the top of MeshBuildSculptBlend.swift). Pieces with nothing to blend lose
    /// their paint (no paint stream).
    static func finishBlends(_ pieces: MeshBuildSculptPieces, _ geometries: inout [MeshGeometry?], _ materials: inout [MaterialAsset?]) {
        for blend in pieces.blends.values {
            let values: [BlendValues?] = blend.pieces.map { $0.flatMap { materials[$0] }.map(BlendValues.init) }
            for (o, piece) in blend.pieces.enumerated() {
                guard let piece, var g = geometries[piece] else { continue }
                defer { geometries[piece] = g }
                guard let weights = g.paint, var material = materials[piece], let own = values[o] else {
                    g.paint = nil
                    continue
                }
                let others = values.indices.filter { values[$0] != nil && blend.paints($0, into: o) }
                // Each vertex's mix of the looks' values.
                var mixed: [BlendValues] = []
                mixed.reserveCapacity(weights.count)
                var blends = false
                for w in weights {
                    var sum: Float = 0
                    var acc = BlendValues(color: .zero, roughness: 0, metallic: 0, emission: .zero)
                    for h in others {
                        let weight = MeshBuildSculptBlend.weight(w, group: h)
                        guard weight > 0 else { continue }
                        sum += weight
                        acc = acc + values[h]! * weight
                    }
                    if sum > 1 { acc = acc * (1 / sum); sum = 1 }
                    if sum > 0 { blends = true }
                    mixed.append(own * (1 - sum) + acc)
                }
                guard blends else {
                    g.paint = nil
                    continue
                }
                // The material holds the largest values, the paint the factor down to each vertex's.
                var top = BlendValues(color: .zero, roughness: 0, metallic: 0, emission: .zero)
                var brightest: Float = 0
                for m in mixed {
                    top.color = pointwiseMax(top.color, m.color)
                    top.roughness = max(top.roughness, m.roughness)
                    top.metallic = max(top.metallic, m.metallic)
                    let l = luminance(m.emission)
                    if l > brightest { (brightest, top.emission) = (l, m.emission) }
                }
                func ratio(_ a: Float, _ b: Float) -> Float { b > 0 ? a / b : 0 }
                g.paint = mixed.map { m in
                    VertexPaint(color: Vec4(ratio(m.color.x, top.color.x), ratio(m.color.y, top.color.y), ratio(m.color.z, top.color.z), 1),
                                surface: Vec4(ratio(m.roughness, top.roughness), ratio(m.metallic, top.metallic),
                                              ratio(luminance(m.emission), brightest), 0))
                }
                material.baseColor = Vec4(top.color.x, top.color.y, top.color.z, material.baseColor.w)
                material.roughness = top.roughness
                material.metallic = top.metallic
                let strength = max(top.emission.x, top.emission.y, top.emission.z)
                if strength > 0 {
                    material.emissiveColor = top.emission / strength
                    material.emissiveStrength = strength
                }
                materials[piece] = material
            }
            // Blend layers: their look at the group's weight as opacity, alpha blended, unworn.
            for (gIndex, layer) in blend.layers.enumerated() {
                guard let layer, var g = geometries[layer], let weights = g.paint, var material = materials[layer] else { continue }
                g.paint = weights.map { VertexPaint(color: Vec4(1, 1, 1, MeshBuildSculptBlend.weight($0, group: gIndex)), surface: Vec4(1, 1, 1, 0)) }
                material.alphaMode = .blend
                material.edgeWear = nil
                geometries[layer] = g
                materials[layer] = material
            }
        }
    }

    private static func luminance(_ c: Vec3) -> Float { c.x * 0.2126 + c.y * 0.7152 + c.z * 0.0722 }
}
