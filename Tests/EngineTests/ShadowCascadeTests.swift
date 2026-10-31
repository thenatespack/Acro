import Foundation
import Testing
@testable import Engine

private let toLight = normalize(Vec3(0.5, 0.75, 0.35))
private let projection = Mat4.perspective(fovY: .pi / 3, aspect: 16 / 9, near: 0.2, far: 500)

private func cascades(eye: Vec3, target: Vec3, projection: Mat4 = projection, count: Int = 4, blend: Float = 0.1)
    -> [ShadowCascades.Cascade] {
    ShadowCascades.fit(view: Mat4.lookAt(eye: eye, target: target), projection: projection, maxDistance: 150, count: count,
                       lambda: 0.75, blend: blend, toLight: toLight, casterDistance: 60, tileSize: 2048)!
}

/// The 8 world-space corners of the view slice between view depths `near` and `far`.
private func sliceCorners(eye: Vec3, target: Vec3, near: Float, far: Float, projection: Mat4 = projection) -> [Vec3] {
    let p = ShadowCascades.perspectiveParameters(projection)!
    let world = Mat4.lookAt(eye: eye, target: target).inverse
    var corners: [Vec3] = []
    for d in [near, far] {
        for sx: Float in [-1, 1] {
            for sy: Float in [-1, 1] {
                let v = world * Vec4(sx * p.tanX * d, sy * p.tanY * d, -d, 1)
                corners.append(Vec3(v.x, v.y, v.z))
            }
        }
    }
    return corners
}

// MARK: Splits

@Test func cascadeSplitsBlendUniformAndLogarithmic() {
    let uniform = ShadowCascades.splitDistances(near: 1, far: 101, count: 4, lambda: 0)
    #expect(zip(uniform, [26, 51, 76, 101] as [Float]).allSatisfy { abs($0 - $1) < 1e-3 })
    let logarithmic = ShadowCascades.splitDistances(near: 1, far: 1000, count: 3, lambda: 1)
    #expect(zip(logarithmic, [10, 100, 1000] as [Float]).allSatisfy { abs($0 - $1) / $1 < 1e-3 })
    let practical = ShadowCascades.splitDistances(near: 0.2, far: 150, count: 4, lambda: 0.75)
    #expect(practical.last == 150)
    for i in practical.indices.dropFirst() { #expect(practical[i] > practical[i - 1]) }
    // Between the two schemes.
    let u = ShadowCascades.splitDistances(near: 0.2, far: 150, count: 4, lambda: 0)
    let l = ShadowCascades.splitDistances(near: 0.2, far: 150, count: 4, lambda: 1)
    for i in 0..<3 { #expect(practical[i] > l[i] && practical[i] < u[i]) }
    #expect(ShadowCascades.splitDistances(near: 0.1, far: 50, count: 1, lambda: 0.5) == [50])
}

@Test func perspectiveParametersReadStandardAndReversedProjections() throws {
    for m in [Mat4.perspective(fovY: 1, aspect: 2, near: 0.5, far: 300), Mat4.perspective(fovY: 1, aspect: 2, near: 300, far: 0.5)] {
        let p = try #require(ShadowCascades.perspectiveParameters(m))
        #expect(abs(p.near - 0.5) < 1e-3 && abs(p.far - 300) / 300 < 1e-3)
        #expect(abs(p.tanY - tanf(0.5)) < 1e-5 && abs(p.tanX - 2 * tanf(0.5)) < 1e-5)
    }
    #expect(ShadowCascades.perspectiveParameters(.orthographic(left: -1, right: 1, bottom: -1, top: 1, near: 0, far: 10)) == nil)
}

// MARK: Fitting

@Test func cascadesContainTheirFrustumSlices() {
    let eye = Vec3(3, 8, 20), target = Vec3(-10, 0, -30)
    let fitted = cascades(eye: eye, target: target)
    #expect(fitted.count == 4)
    #expect(fitted[0].start == 0.2 && fitted.last!.end == 150)
    for (i, cascade) in fitted.enumerated() {
        // The next cascade starts where this one starts blending, so blend bands are covered twice.
        if i + 1 < fitted.count { #expect(fitted[i + 1].start == cascade.blendStart) }
        #expect(cascade.blendStart < cascade.end && cascade.blendStart > cascade.start)
        for corner in sliceCorners(eye: eye, target: target, near: cascade.start, far: cascade.end) {
            #expect(length(corner - cascade.center) <= cascade.radius * 1.0001)
            let clip = cascade.viewProjection * Vec4(corner, 1)
            // Inside the square with the margin left free, and in front of the far plane.
            let margin = 1 - 2 * Float(ShadowCascades.marginTexels - 1) / 2048
            #expect(abs(clip.x) < margin && abs(clip.y) < margin, "cascade \(i) corner \(corner) -> \(clip)")
            #expect(clip.z > 0 && clip.z < 1)
        }
    }
    // Later cascades are coarser.
    for i in 1..<fitted.count { #expect(fitted[i].texelSize > fitted[i - 1].texelSize) }
}

@Test func boundingSphereOfWideSliceSitsOnTheFarCap() {
    let s = ShadowCascades.boundingSphere(near: 1, far: 2, tan: 3)
    #expect(s.depth == 2 && abs(s.radius - 6) < 1e-5)
    let narrow = ShadowCascades.boundingSphere(near: 10, far: 50, tan: 0.5)
    #expect(narrow.depth > 10 && narrow.depth < 50)
}

// MARK: Stability

@Test func cascadesDontMoveForSubTexelCameraMoves() {
    let target = Vec3(0, 0, -40)
    // Light-space texel coordinates of a fixed world point, per cascade.
    func texelCoordinates(_ eye: Vec3) -> [Vec2] {
        cascades(eye: eye, target: eye + target).map { c in
            let p = c.viewProjection * Vec4(5, 0, -12, 1)
            return Vec2(p.x, p.y) * 1024
        }
    }
    let base = texelCoordinates(Vec3(1, 6, 2))
    var unchanged = 0
    for k in 1...40 {
        // Moves of a fraction of the finest cascade's texel.
        let eye = Vec3(1, 6, 2) + Vec3(0.0003, 0.0001, -0.0002) * Float(k)
        let moved = texelCoordinates(eye)
        if moved == base { unchanged += 1 }
        for (a, b) in zip(base, moved) {
            // The projection moves only in whole texels.
            let d = b - a
            #expect(abs(d.x - d.x.rounded()) < 2e-3 && abs(d.y - d.y.rounded()) < 2e-3, "\(d)")
        }
    }
    #expect(unchanged > 0)
    // Exactly the same eye gives exactly the same matrices.
    #expect(cascades(eye: Vec3(1, 6, 2), target: Vec3(1, 6, -38)) == cascades(eye: Vec3(1, 6, 2), target: Vec3(1, 6, -38)))
}

@Test func cascadeSizeDoesNotChangeWhenTheCameraTurns() {
    let eye = Vec3(4, 5, 6)
    let reference = cascades(eye: eye, target: eye + Vec3(0, -0.2, -1))
    for angle in stride(from: Float(0.1), to: 6.2, by: 0.7) {
        let turned = cascades(eye: eye, target: eye + Vec3(sinf(angle), -0.2, -cosf(angle)))
        for (a, b) in zip(reference, turned) {
            #expect(a.texelSize == b.texelSize && a.extent == b.extent)
            // Same scale in the light-space projection.
            #expect(a.viewProjection.c0.x == b.viewProjection.c0.x || abs(a.viewProjection.c0.x - b.viewProjection.c0.x) < 1e-7)
        }
    }
}

// MARK: Atlas

@Test func atlasTilesDontOverlapAndFit() {
    for tile in [256, 1024, 2048] {
        for count in 1...4 {
            for local in [false, true] {
                let layout = ShadowAtlasLayout(tileSize: tile, cascades: count, localShadows: local)
                var rects = layout.cascadeRects + layout.spotRects
                for block in layout.pointRects {
                    for face in 0..<6 {
                        rects.append(ShadowRect(x: block.x + face % 3 * layout.faceSize, y: block.y + face / 3 * layout.faceSize,
                                                width: layout.faceSize, height: layout.faceSize))
                    }
                    #expect(block.width == 3 * layout.faceSize && block.height == 2 * layout.faceSize)
                }
                #expect(layout.cascadeRects.count == count)
                #expect(layout.spotRects.count == (local ? ShadowAtlasLayout.maxSpotShadows : 0))
                #expect(layout.pointRects.count == (local ? ShadowAtlasLayout.maxPointShadows : 0))
                for (i, a) in rects.enumerated() {
                    #expect(a.x >= 0 && a.y >= 0 && a.x + a.width <= layout.width && a.y + a.height <= layout.height)
                    for b in rects[(i + 1)...] { #expect(!a.intersects(b), "\(a) overlaps \(b)") }
                }
                // Cascade c sits at column c % 2, row c / 2, as the shader assumes.
                for (c, rect) in layout.cascadeRects.enumerated() {
                    #expect(rect == ShadowRect(x: c % 2 * tile, y: c / 2 * tile, width: tile, height: tile))
                }
            }
        }
    }
    // 4 cascades of 2048 with local shadows: 4096 wide, cascades plus two 512-texel shelves.
    let layout = ShadowAtlasLayout(tileSize: 2048, cascades: 4, localShadows: true)
    #expect(layout.width == 4096 && layout.height == 4096 + 1024)
}

@Test func clipTransformMapsTheFullTargetOntoTheTile() {
    let layout = ShadowAtlasLayout(tileSize: 1024, cascades: 3, localShadows: true)
    let rect = layout.spotRects[3]
    let m = layout.clipTransform(onto: rect)
    // Clip corners (-1, 1) (top left) and (1, -1) (bottom right) land on the rectangle's corners.
    func pixel(_ x: Float, _ y: Float) -> Vec2 {
        let c = m * Vec4(x, y, 0.5, 1)
        return Vec2((c.x + 1) / 2 * Float(layout.width), (1 - c.y) / 2 * Float(layout.height))
    }
    let tl = pixel(-1, 1), br = pixel(1, -1)
    #expect(abs(tl.x - Float(rect.x)) < 1e-2 && abs(tl.y - Float(rect.y)) < 1e-2)
    #expect(abs(br.x - Float(rect.x + rect.width)) < 1e-2 && abs(br.y - Float(rect.y + rect.height)) < 1e-2)
    // Depth is untouched, and w scales the offset (perspective projections stay correct).
    let c = m * Vec4(0, 0, 0.3, 2)
    #expect(c.z == 0.3 && c.w == 2)
}

// MARK: Local lights

private func spot(at position: Vec3, toward target: Vec3, range: Float = 10, shadows: Bool = true) -> PunctualLight {
    var light = PunctualLight(spot: SpotLight(range: range, castsShadows: shadows), position: position, direction: target - position)
    light.castsShadows = shadows
    return light
}

private func point(at position: Vec3, range: Float = 5, shadows: Bool = true) -> PunctualLight {
    PunctualLight(point: PointLight(range: range, castsShadows: shadows), position: position)
}

@Test func shadowedLightsArePickedByScreenInfluence() {
    var lights: [PunctualLight] = []
    for k in 0..<12 { lights.append(spot(at: Vec3(1, 3, -10 - Float(k) * 4), toward: Vec3(1, 0, -10 - Float(k) * 4))) }
    for k in 0..<6 { lights.append(point(at: Vec3(0, 1, -Float(k) * 6 - 5))) }
    lights.append(point(at: Vec3(0, 1, -3), shadows: false))       // doesn't ask for shadows
    lights.append(point(at: Vec3(0, 1, 50)))                       // behind the camera
    let view = Frustum(viewProjection: projection * Mat4.lookAt(eye: .zero, target: Vec3(0, 0, -1)))
    ShadowedLights.select(&lights, eye: .zero, view: view)

    let spots = lights.indices.filter { lights[$0].isSpot && lights[$0].shadowSlot >= 0 }
    let points = lights.indices.filter { !lights[$0].isSpot && lights[$0].shadowSlot >= 0 }
    #expect(spots.count == ShadowAtlasLayout.maxSpotShadows && points.count == ShadowAtlasLayout.maxPointShadows)
    // The nearest spots and points win, slots in priority order.
    #expect(Set(spots) == Set(0..<8))
    #expect(points == [12, 13, 14, 15] && points.map { lights[$0].shadowSlot } == [0, 1, 2, 3])
    #expect(lights[18].shadowSlot == -1 && lights[19].shadowSlot == -1)
    #expect(Set(spots.map { lights[$0].shadowSlot }) == Set(0..<8))
}

@Test func shadowedLightsComeFirstInTheClusterList() {
    var lights = [point(at: Vec3(0, 0, -30), shadows: false), point(at: Vec3(2, 0, -20)),
                  spot(at: Vec3(-2, 3, -15), toward: Vec3(-2, 0, -15)), point(at: Vec3(0, 0, -8), shadows: false)]
    lights[1].shadowSlot = 0
    lights[2].shadowSlot = 0
    var clusters = LightClusters()
    clusters.build(lights: lights, view: .identity, projection: projection)
    #expect(clusters.shadowedSpots == 1 && clusters.shadowedPoints == 1)
    #expect(clusters.lights.map(\.position) == [lights[2].position, lights[1].position, lights[3].position, lights[0].position])
}

@Test func pointFaceProjectionMatchesTheShaderFormula() {
    let light = point(at: Vec3(1, 2, 3), range: 8)
    let size = 256
    let k = LocalLightShadows.borderScale(size: size)
    let (a, b) = LocalLightShadows.pointDepth(range: 8)
    for (face, (forward, up)) in LocalLightShadows.faces.enumerated() {
        let m = LocalLightShadows.pointFace(light, face: face, size: size)
        let d = forward * 3 + up * 0.7 + cross(forward, up) * -1.1
        let clip = m * Vec4(light.position + d, 1)
        // As shadows.glsl computes it: major axis distance 3.
        #expect(abs(clip.w - 3) < 1e-4)
        #expect(abs(clip.x / clip.w - (-1.1) / (3 * k)) < 1e-4 && abs(clip.y / clip.w - 0.7 / (3 * k)) < 1e-4)
        #expect(abs(clip.z / clip.w - (a + b / 3)) < 1e-5)
    }
    // Depth runs from 0 at the near plane to 1 at the range.
    #expect(abs(a + b / LocalLightShadows.near(range: 8)) < 1e-5 && abs(a + b / 8 - 1) < 1e-5)
}

@Test func spotShadowCoversItsCone() {
    let light = spot(at: Vec3(0, 5, 0), toward: Vec3(1, 0, 0.5), range: 12)
    let (viewProjection, _) = LocalLightShadows.spot(light, size: 512)
    let frustum = Frustum(viewProjection: viewProjection)
    // Points on the cone's rim, at a few distances, are inside the map.
    let axis = light.direction
    let side = normalize(cross(axis, Vec3(0, 1, 0))), up = cross(side, axis)
    let sinOuter = (1 - light.cosOuter * light.cosOuter).squareRoot()
    for d: Float in [1, 5, 11.5] {
        for phi in stride(from: Float(0), to: 6.28, by: 0.5) {
            let dir = axis * light.cosOuter + (side * cosf(phi) + up * sinf(phi)) * sinOuter
            let p = light.position + dir * d
            let clip = viewProjection * Vec4(p, 1)
            #expect(abs(clip.x / clip.w) < 1 && abs(clip.y / clip.w) < 1)
            #expect(frustum.intersects(center: p, halfExtent: Vec3(repeating: 0.001)))
        }
    }
}

// MARK: Casters

@Test func casterBatchesArePerTile() {
    func item(_ i: Int, mesh: Int, at p: Vec3) -> RenderItem {
        RenderItem(entity: Entity(index: UInt32(i), generation: 0), mesh: mesh, material: 0,
                   instance: MeshInstance(model: .translation(p), previousModel: .translation(p), color: Vec4(1, 1, 1, Float(i)), params: Vec4(1, 0, 0, 0)),
                   bounds: Bounds(center: p, halfExtent: Vec3(repeating: 0.5)), castsShadows: true, transparent: false)
    }
    let items = [item(0, mesh: 0, at: Vec3(0, 0, 0)), item(1, mesh: 1, at: Vec3(20, 0, 0)), item(2, mesh: 0, at: Vec3(1, 0, 0))]
    let tiles = [
        ShadowTileCulling(frustum: Frustum(viewProjection: .orthographic(left: -5, right: 5, bottom: -5, top: 5, near: -5, far: 5))),
        ShadowTileCulling(frustum: Frustum(viewProjection: .orthographic(left: -50, right: 50, bottom: -5, top: 5, near: -5, far: 5)),
                          sphere: (Vec3(20, 0, 0), 2)),
    ]
    var batches = ShadowCasterBatches()
    batches.build(items: items, tiles: tiles)
    #expect(batches.tileBatches.count == 2)
    let first = batches.batches[batches.tileBatches[0]], second = batches.batches[batches.tileBatches[1]]
    #expect(first.map(\.mesh) == [0] && first.first!.count == 2)
    #expect(second.map(\.mesh) == [1] && second.first!.count == 1)
    #expect(batches.instances.map { Int($0.color.w) } == [0, 2, 1])
    #expect(second.first!.first == 2 && batches.drawn == 3 && batches.culled == 3)
}

// MARK: Serialization

@Test func newLightFieldsRoundTripAndDefaultWhenMissing() throws {
    let sun = DirectionalLight(cascadeCount: 3, shadowMaxDistance: 90, cascadeSplitLambda: 0.6, cascadeBlend: 0.2, shadowNormalOffset: 2)
    #expect(try JSONDecoder().decode(DirectionalLight.self, from: JSONEncoder().encode(sun)) == sun)
    let point = PointLight(intensity: 3, castsShadows: true), spot = SpotLight(range: 4, castsShadows: true)
    #expect(try JSONDecoder().decode(PointLight.self, from: JSONEncoder().encode(point)) == point)
    #expect(try JSONDecoder().decode(SpotLight.self, from: JSONEncoder().encode(spot)) == spot)

    // Files from before these fields existed still load, with the defaults.
    let oldSun = #"{"color":[1,1,1],"intensity":2,"castsShadows":true,"shadowExtent":30,"shadowDistance":60,"shadowBias":0.0005}"#
    let decoded = try JSONDecoder().decode(DirectionalLight.self, from: Data(oldSun.utf8))
    #expect(decoded == DirectionalLight(intensity: 2))
    let oldPoint = try JSONDecoder().decode(PointLight.self, from: Data(#"{"color":[1,0,0],"intensity":5,"range":10}"#.utf8))
    #expect(oldPoint == PointLight(color: Vec3(1, 0, 0)) && !oldPoint.castsShadows)
    let oldSpot = try JSONDecoder().decode(
        SpotLight.self, from: Data(#"{"color":[1,1,1],"intensity":10,"range":15,"innerConeAngle":0.35,"outerConeAngle":0.5}"#.utf8))
    #expect(oldSpot == SpotLight())
}

@MainActor @Test func lightShadowFieldsShowInTheInspector() throws {
    let world = World()
    let spot = world.spawn(Transform(), SpotLight(castsShadows: true))
    let sun = world.spawn(Transform(), DirectionalLight())
    let spotFields = try #require(world.fields(of: "SpotLight", for: spot))
    #expect(spotFields.contains { $0.name == "castsShadows" && $0.value == .bool(true) })
    let sunFields = try #require(world.fields(of: "DirectionalLight", for: sun))
    #expect(sunFields.contains { $0.name == "cascadeBlend" } && sunFields.contains { $0.name == "cascadeCount" })
    try world.setField("castsShadows", of: "SpotLight", for: spot, to: .bool(false))
    #expect(world.get(SpotLight.self, for: spot)?.castsShadows == false)
}
