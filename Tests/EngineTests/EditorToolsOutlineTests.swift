import Testing
@testable import Engine

// The CPU side of the selection outline, and DebugDraw's filled shapes.

private typealias Texel = SelectionOutline.MaskTexel

@MainActor @Suite struct EditorToolsOutlineTests {
    @Test func outlinedEntitiesIncludeDescendantsAndInheritThePrimaryFlag() {
        let world = World()
        let parent = world.spawn(Transform()), child = world.spawn(Transform()), grandchild = world.spawn(Transform())
        let other = world.spawn(Transform()), otherChild = world.spawn(Transform()), dead = world.spawn()
        world.setParent(child, to: parent)
        world.setParent(grandchild, to: child)
        world.setParent(otherChild, to: other)
        world.despawn(dead)
        let outlined = SelectionOutline.outlinedEntities(selection: [other, parent, dead], primary: parent, includesDescendants: true,
                                                         in: world)
        #expect(outlined == [parent: true, child: true, grandchild: true, other: false, otherChild: false])
        // A selected descendant keeps its own flag.
        let mixed = SelectionOutline.outlinedEntities(selection: [parent, child], primary: child, includesDescendants: true, in: world)
        #expect(mixed == [parent: false, child: true, grandchild: true])
        #expect(SelectionOutline.outlinedEntities(selection: [parent], primary: nil, includesDescendants: false, in: world) == [parent: false])
    }

    private func item(_ index: UInt32, mesh: Int, material: Int = 0, at x: Float, transparent: Bool = false) -> RenderItem {
        let model = Mat4.translation(Vec3(x, 0, -10))
        return RenderItem(entity: Entity(index: index, generation: 0), mesh: mesh, material: material,
                          instance: MeshInstance(model: model, previousModel: model, color: Vec4(repeating: 1), params: .zero),
                          bounds: Bounds(center: Vec3(x, 0, -10), halfExtent: Vec3(repeating: 0.5)), castsShadows: true,
                          transparent: transparent)
    }

    @Test func maskDrawsSplitOccludersFromSelectedBatches() {
        let frustum = Frustum(viewProjection: Mat4.perspective(fovY: .pi / 2, aspect: 1, near: 0.1, far: 100))
        let items = [
            item(0, mesh: 0, at: 0), item(1, mesh: 1, material: 1, at: 1), item(2, mesh: 0, at: -1),
            item(3, mesh: 0, at: 2, transparent: true),  // not an occluder
            item(4, mesh: 1, at: 500),  // outside the frustum
            item(5, mesh: 0, at: 3), item(6, mesh: 1, at: -2), item(7, mesh: 0, at: 4),
        ]
        let entity = { (i: UInt32) in Entity(index: i, generation: 0) }
        let outlined: [Entity: Bool] = [entity(5): true, entity(6): false, entity(7): false, entity(4): true]
        let draws = SelectionOutline.draws(items: items, outlined: outlined, frustum: frustum, occlusion: true,
                                           doubleSided: { $0 == 1 })
        #expect(draws.occluders.map(\.mesh) == [0, 1] && draws.occluders.map(\.count) == [2, 1])
        #expect(draws.occluders.map(\.doubleSided) == [false, true])
        // Secondary batches first (mesh 1 then 0, in order of appearance), then the primary.
        #expect(draws.selected.map(\.mesh) == [1, 0, 0] && draws.selected.map(\.primary) == [false, false, true])
        #expect(draws.selected.map(\.first) == [3, 4, 5] && draws.instances.count == 6)
        #expect(draws.instances[5].model.c3.x == 3)
        #expect(draws.selectedBounds.count == 3)
        let noOcclusion = SelectionOutline.draws(items: items, outlined: outlined, frustum: frustum, occlusion: false,
                                                 doubleSided: { _ in false })
        #expect(noOcclusion.occluders.isEmpty && noOcclusion.instances.count == 3)
    }

    @Test func compositeScissorCoversTheProjectedSelection() throws {
        let viewProjection = Mat4.perspective(fovY: .pi / 2, aspect: 2, near: 0.1, far: 100)
        // A box at the center, 2 wide and 2 high at depth 10: ±0.1 in NDC x/2, ±0.1 in y.
        let box = Bounds(center: Vec3(0, 0, -10), halfExtent: Vec3(1, 1, 0))
        let rect = try #require(SelectionOutline.scissor(for: [box], viewProjection: viewProjection, width: 400, height: 200, radius: 3))
        // x: (±0.05 + 1) / 2 * 400 = 190...210; y: (±0.1 + 1) / 2 * 200 = 90...110; grown by 4 (±1 for rounding).
        #expect(abs(rect.x - 186) <= 1 && abs(rect.y - 86) <= 1 && abs(rect.width - 28) <= 2 && abs(rect.height - 28) <= 2)
        let behind = Bounds(center: Vec3(0, 0, 1), halfExtent: Vec3(repeating: 2))
        #expect(SelectionOutline.scissor(for: [box, behind], viewProjection: viewProjection, width: 400, height: 200, radius: 3)
            == ScissorRect(x: 0, y: 0, width: 400, height: 200))
        let offscreen = Bounds(center: Vec3(500, 0, -10), halfExtent: Vec3(repeating: 1))
        #expect(SelectionOutline.scissor(for: [offscreen], viewProjection: viewProjection, width: 400, height: 200, radius: 3) == nil)
        #expect(SelectionOutline.scissor(for: [], viewProjection: viewProjection, width: 400, height: 200, radius: 3) == nil)
    }

    /// A `size` x `size` mask with a filled block.
    private func mask(size: Int, block: ClosedRange<Int>, _ texel: Texel) -> [Texel] {
        var mask = [Texel](repeating: [], count: size * size)
        for y in block { for x in block { mask[y * size + x] = texel } }
        return mask
    }

    @Test func outlineHasAConstantPixelWidthAroundTheSilhouette() throws {
        let style = SelectionOutlineStyle(width: 2, hiddenOpacity: 0.3)
        let m = mask(size: 20, block: 8...11, [.selected, .visible, .primary])
        func alpha(_ x: Int, _ y: Int, scale: Float = 1) -> Float {
            SelectionOutline.coverage(mask: m, width: 20, x: x, y: y, style: style, pixelScale: scale)?.w ?? 0
        }
        #expect(alpha(9, 9) == 0)  // inside: no outline
        #expect(alpha(12, 9) == 1 && alpha(13, 9) == 1 && alpha(14, 9) == 0)  // two pixels wide along an edge
        #expect(alpha(7, 10) == 1 && alpha(6, 10) == 1 && alpha(5, 10) == 0)
        // Diagonal from the corner: distance √2 is covered, √8 partly (2 + 1 - 2.83), √18 not.
        #expect(alpha(12, 12) == 1 && abs(alpha(13, 13) - (3 - Float(8).squareRoot())) < 1e-6 && alpha(14, 14) == 0)
        // At 2x pixel scale the outline is twice as many pixels wide.
        #expect(alpha(15, 9, scale: 2) == 1 && alpha(16, 9, scale: 2) == 0)
        let color = try #require(SelectionOutline.coverage(mask: m, width: 20, x: 12, y: 9, style: style))
        #expect(Vec3(color.x, color.y, color.z) == Vec3(style.primaryColor.x, style.primaryColor.y, style.primaryColor.z))
    }

    @Test func hiddenPartsAreDimmedAndSecondaryColorsUsed() throws {
        let style = SelectionOutlineStyle(width: 1, hiddenOpacity: 0.25)
        var m = mask(size: 16, block: 4...7, [.selected])  // hidden behind an occluder
        for y in 4...7 { m[y * 16 + 7] = [.selected, .visible] }  // its right column is visible
        let hidden = try #require(SelectionOutline.coverage(mask: m, width: 16, x: 3, y: 5, style: style))
        #expect(hidden.w == 0.25 && hidden.x == style.secondaryColor.x)
        #expect(SelectionOutline.coverage(mask: m, width: 16, x: 8, y: 5, style: style)?.w == 1)
        // Next to a primary texel the primary color wins; the edge of the mask clips the search.
        m[5 * 16 + 4].insert(.primary)
        #expect(SelectionOutline.coverage(mask: m, width: 16, x: 3, y: 5, style: style)?.x == style.primaryColor.x)
        let edge = mask(size: 4, block: 0...0, [.selected, .visible])
        #expect(SelectionOutline.coverage(mask: edge, width: 4, x: 1, y: 0, style: style)?.w == 1)
        #expect(SelectionOutline.coverage(mask: edge, width: 4, x: 3, y: 3, style: style) == nil)
        // Without dimming (opacity 1) hidden parts look like visible ones.
        let full = SelectionOutlineStyle(width: 1, hiddenOpacity: 1)
        #expect(SelectionOutline.coverage(mask: mask(size: 8, block: 2...3, [.selected]), width: 8, x: 1, y: 2, style: full)?.w == 1)
    }
}

@Suite struct EditorToolsDebugFillTests {
    @Test func filledShapesBecomeTrianglesPerDepthMode() {
        let debug = DebugDraw()
        #expect(debug.isEmpty)
        debug.triangle(.zero, Vec3(1, 0, 0), Vec3(0, 1, 0), color: Vec4(1, 0, 0, 1))
        #expect(!debug.isEmpty && debug.triangleCount == 1 && debug.segmentCount == 0)
        debug.quad(.zero, Vec3(1, 0, 0), Vec3(1, 1, 0), Vec3(0, 1, 0), color: Vec4(1, 0, 0, 1), depth: .onTop)
        debug.disc(center: .zero, normal: Vec3(0, 1, 0), radius: 2, color: Vec4(1, 1, 1, 1), segments: 12, depth: .onTop)
        debug.cone(base: .zero, tip: Vec3(0, 0, 3), radius: 1, color: Vec4(0, 1, 0, 1), segments: 8, depth: .onTop)
        debug.solidBox(.identity, color: Vec4(0, 0, 1, 1), depth: .onTop)
        #expect(debug.triangles[.tested]?.count == 1)
        #expect(debug.triangles[.onTop]?.count == 2 + 12 + 16 + 12)
        // Disc corners lie on the circle; cone side triangles meet at the tip.
        let disc = debug.triangles[.onTop]![2..<14]
        #expect(disc.allSatisfy { abs(length(Vec3($0.b.x, $0.b.y, $0.b.z)) - 2) < 1e-5 })
        let cone = debug.triangles[.onTop]![14..<30]
        #expect(cone.filter { $0.c.z == 3 }.count == 8)
        // A box's 12 triangles cover its 6 faces: every corner is at ±1.
        let box = debug.triangles[.onTop]![30...]
        #expect(box.allSatisfy { t in [t.a, t.b, t.c].allSatisfy { abs($0.x) == 1 && abs($0.y) == 1 && abs($0.z) == 1 } })
        debug.beginFrame(dt: 1 / 60)
        #expect(debug.isEmpty)
        debug.triangle(.zero, .zero, .zero, color: Vec4(repeating: 1), duration: 1)
        debug.beginFrame(dt: 0.5)
        #expect(debug.triangleCount == 1)
        debug.removeAll()
        #expect(debug.triangleCount == 0)
    }
}
