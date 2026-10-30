import Foundation
import Testing
@testable import Engine

// Rays, unprojection, intersections and ScenePicker.

private func perspectiveView(eye: Vec3, target: Vec3, reversedZ: Bool = false, size: Vec2 = Vec2(800, 600),
                             scale: Float = 1) -> ViewportProjection {
    let projection = reversedZ
        ? Mat4.perspective(fovY: .pi / 3, aspect: size.x / size.y, near: 500, far: 0.1)
        : Mat4.perspective(fovY: .pi / 3, aspect: size.x / size.y, near: 0.1, far: 500)
    return ViewportProjection(view: Mat4.lookAt(eye: eye, target: target), projection: projection, reversedZ: reversedZ,
                              size: size, pixelScale: scale)
}

private func distance(_ p: Vec3, to ray: Ray) -> Float {
    let t = dot(p - ray.origin, ray.direction)
    return length(ray.point(at: t) - p)
}

@Suite struct EditorToolsRayTests {
    @Test(arguments: [false, true]) func rayThroughProjectedPointPassesThroughIt(reversedZ: Bool) throws {
        let view = perspectiveView(eye: Vec3(4, 6, 12), target: Vec3(0, 1, 0), reversedZ: reversedZ)
        for p in [Vec3(0, 1, 0), Vec3(3, -2, 1), Vec3(-5, 4, -20), Vec3(1, 0.5, 9)] {
            let point = try #require(view.project(p))
            let ray = view.ray(through: point)
            #expect(distance(p, to: ray) < 1e-3 * max(length(p - view.eye), 1))
            #expect(dot(p - ray.origin, ray.direction) > 0)  // in front of the origin
            #expect(abs(length(ray.direction) - 1) < 1e-5)
        }
        // The origin lies on the near plane: 0.1 in front of the eye along the view axis.
        let center = view.ray(through: view.size / 2)
        #expect(abs(dot(center.origin - view.eye, view.forward) - 0.1) < 1e-4)
        #expect(length(center.direction - view.forward) < 1e-5)
    }

    @Test func unprojectInvertsProjectAtEveryDepth() throws {
        for reversedZ in [false, true] {
            let view = perspectiveView(eye: Vec3(0, 0, 5), target: .zero, reversedZ: reversedZ)
            let p = Vec3(0.7, -0.4, -3)
            let clip = view.clip(p)
            let point = try #require(view.project(p))
            let back = try #require(view.unproject(point, depth: clip.z / clip.w))
            #expect(length(back - p) < 1e-3)
        }
    }

    @Test func orthographicRaysAreParallelToTheViewAxis() {
        let view = ViewportProjection(view: Mat4.lookAt(eye: Vec3(0, 10, 0), target: .zero, up: Vec3(0, 0, -1)),
                                      projection: Mat4.orthographic(left: -8, right: 8, bottom: -6, top: 6, near: 0.5, far: 50),
                                      size: Vec2(800, 600))
        #expect(!view.isPerspective)
        let a = view.ray(through: Vec2(10, 20)), b = view.ray(through: Vec2(700, 500))
        #expect(length(a.direction - Vec3(0, -1, 0)) < 1e-5 && length(b.direction - Vec3(0, -1, 0)) < 1e-5)
        // Point (0, 0) is the top-left corner: x = -8, z = -6 (up is -z).
        let corner = view.ray(through: .zero)
        #expect(abs(corner.origin.x + 8) < 1e-4 && abs(corner.origin.z + 6) < 1e-4)
        #expect(view.directionToViewer(from: Vec3(3, 0, 3)) == Vec3(0, 1, 0))
    }

    @Test func worldUnitsPerPointKeepsScreenSizeConstant() throws {
        let view = perspectiveView(eye: Vec3(0, 0, 10), target: .zero, scale: 2)
        for p in [Vec3(0, 0, 0), Vec3(1, 2, -30)] {
            let units = try #require(view.worldUnitsPerPoint(at: p))
            let a = try #require(view.project(p)), b = try #require(view.project(p + Vec3(0, 100 * units, 0)))
            #expect(abs(length(Vec3(a - b, 0)) - 100) < 0.05)
        }
        #expect(view.worldUnitsPerPoint(at: Vec3(0, 0, 20)) == nil)  // behind the eye
        #expect(view.pixelSize == (1600, 1200))
    }

    @Test func rectViewProjectionMapsTheRectangleToClipSpace() throws {
        let view = perspectiveView(eye: Vec3(0, 2, 10), target: .zero)
        let rect = UIRect(x: 100, y: 50, width: 200, height: 300)
        let m = view.viewProjection(restrictedTo: rect)
        // A world point under the rectangle's top-left corner maps to (-1, 1) in the cropped clip space.
        let p = view.ray(through: Vec2(100, 50)).point(at: 7)
        let clip = m * Vec4(p, 1)
        #expect(abs(clip.x / clip.w + 1) < 1e-4 && abs(clip.y / clip.w - 1) < 1e-4)
        let q = view.ray(through: Vec2(300, 350)).point(at: 3)
        let clipQ = m * Vec4(q, 1)
        #expect(abs(clipQ.x / clipQ.w - 1) < 1e-4 && abs(clipQ.y / clipQ.w + 1) < 1e-4)
    }

    @Test func rayBoxSlabTest() throws {
        let box = Bounds(center: Vec3(0, 0, -5), halfExtent: Vec3(1, 1, 1))
        let hit = try #require(Ray(origin: .zero, direction: Vec3(0, 0, -1)).intersect(box))
        #expect(abs(hit.enter - 4) < 1e-6 && abs(hit.exit - 6) < 1e-6)
        #expect(Ray(origin: .zero, direction: Vec3(0, 0, 1)).intersect(box) == nil)  // behind
        #expect(Ray(origin: Vec3(1.5, 0, 0), direction: Vec3(0, 0, -1)).intersect(box) == nil)  // parallel, outside the slab
        let inside = try #require(Ray(origin: Vec3(0, 0, -5), direction: Vec3(1, 0, 0)).intersect(box))
        #expect(inside.enter == 0 && abs(inside.exit - 1) < 1e-6)
        let diagonal = try #require(Ray(origin: Vec3(-3, -3, -5), direction: Vec3(1, 1, 0)).intersect(box))
        #expect(abs(diagonal.enter - 2 * Float(2).squareRoot()) < 1e-5)
        #expect(Ray(origin: Vec3(-3, -1.5, -5), direction: Vec3(1, 1, 0)).intersect(box) != nil)
        #expect(Ray(origin: Vec3(-3, 0.5, -5), direction: Vec3(1, 1, 0)).intersect(box) == nil)  // passes above the corner
    }

    @Test func rayTriangleMollerTrumbore() throws {
        let a = Vec3(0, 0, -2), b = Vec3(2, 0, -2), c = Vec3(0, 2, -2)
        let ray = Ray(origin: Vec3(0.5, 0.5, 0), direction: Vec3(0, 0, -1))
        #expect(try abs(#require(ray.intersect(a, b, c)) - 2) < 1e-6)
        let detail = try #require(Ray.intersectTriangle(origin: ray.origin, direction: ray.direction, a, b, c))
        #expect(abs(detail.u - 0.25) < 1e-6 && abs(detail.v - 0.25) < 1e-6)
        #expect(detail.frontFacing)  // counter-clockwise seen from +z
        #expect(Ray.intersectTriangle(origin: ray.origin, direction: ray.direction, a, c, b)?.frontFacing == false)
        #expect(Ray(origin: Vec3(1.5, 1.5, 0), direction: Vec3(0, 0, -1)).intersect(a, b, c) == nil)  // outside the hypotenuse
        #expect(Ray(origin: Vec3(0.5, 0.5, -3), direction: Vec3(0, 0, -1)).intersect(a, b, c) == nil)  // behind
        #expect(Ray(origin: Vec3(0.5, 0.5, -2), direction: Vec3(1, 0, 0)).intersect(a, b, c) == nil)  // in the plane
        // Edges and corners count.
        #expect(Ray(origin: Vec3(1, 0, 0), direction: Vec3(0, 0, -1)).intersect(a, b, c) != nil)
    }

    @Test func rayPlaneAndClosestPointOnLine() throws {
        let ray = Ray(origin: Vec3(0, 5, 0), direction: Vec3(1, -1, 0))
        let t = try #require(ray.intersectPlane(point: .zero, normal: Vec3(0, 1, 0)))
        #expect(length(ray.point(at: t) - Vec3(5, 0, 0)) < 1e-5)
        #expect(ray.intersectPlane(point: Vec3(0, 10, 0), normal: Vec3(0, 1, 0)) == nil)  // behind
        #expect(ray.intersectPlane(point: .zero, normal: Vec3(0, 0, 1)) == nil)  // parallel
        // A ray straight down at x = 3 is closest to the x axis at s = 3, the z axis at s = 0.
        let down = Ray(origin: Vec3(3, 4, 0), direction: Vec3(0, -1, 0))
        #expect(try abs(#require(down.closestParameter(onLine: Vec3(-1, 0, 0), direction: Vec3(1, 0, 0))) - 4) < 1e-5)
        #expect(try abs(#require(down.closestParameter(onLine: .zero, direction: Vec3(0, 0, 1)))) < 1e-5)
        #expect(down.closestParameter(onLine: .zero, direction: Vec3(0, 1, 0)) == nil)
    }

    @MainActor @Test func editorSelectionKeepsOrderAndPrimary() {
        let world = World()
        world.assignsEntityIDs = true
        let a = world.spawn(), b = world.spawn(), c = world.spawn()
        var selection = EditorSelection()
        selection.click(a, modifiers: [], in: world)
        selection.click(b, modifiers: .shift, in: world)
        selection.click(c, modifiers: .shift, in: world)
        #expect(selection.entities(in: world) == [a, b, c] && selection.primaryEntity(in: world) == c)
        selection.click(b, modifiers: .shift, in: world)  // toggles b off
        #expect(selection.entities(in: world) == [a, c])
        selection.click(a, modifiers: .shift, in: world)
        selection.click(a, modifiers: .shift, in: world)  // off, then on again as the primary
        #expect(selection.entities(in: world) == [c, a])
        world.despawn(c)
        #expect(selection.entities(in: world) == [a])
        selection.click(nil, modifiers: [], in: world)
        #expect(selection.isEmpty)
    }
}

@MainActor @Suite struct EditorToolsPickerTests {
    let world = World()
    let meshes = PickMeshLibrary()

    @discardableResult
    func spawn(_ mesh: MeshHandle = .cube, at position: Vec3, rotation: Quat = .identity, scale: Vec3 = .one,
               visible: Bool = true) -> Entity {
        world.spawn(Transform(position: position, rotation: rotation, scale: scale), MeshRenderer(mesh: mesh, isVisible: visible))
    }

    @Test func closestHitWins() throws {
        let far = spawn(at: Vec3(0, 0, -10))
        let near = spawn(at: Vec3(0, 0, -5))
        spawn(at: Vec3(3, 0, -2))  // off the ray
        world.propagateTransforms()
        let picker = ScenePicker(meshes: meshes)
        let hit = try #require(picker.pick(Ray(origin: Vec3(0.1, 0.2, 0), direction: Vec3(0, 0, -1)), in: world))
        #expect(hit.entity == near)
        #expect(abs(hit.distance - 4.5) < 1e-5)
        #expect(length(hit.point - Vec3(0.1, 0.2, -4.5)) < 1e-5)
        #expect(length(hit.normal - Vec3(0, 0, 1)) < 1e-5)
        #expect(picker.stats.entities == 3 && picker.stats.boundsHits == 2)
        #expect(picker.stats.meshTests == 1)  // the far cube's bounds start beyond the hit
        _ = far
    }

    @Test func boundsAloneDontCount() throws {
        // The ray passes through the corner of the sphere's bounds but misses the sphere, then hits the cube.
        let sphere = spawn(.sphere, at: Vec3(0, 0, -4), scale: Vec3(repeating: 2))
        let cube = spawn(at: Vec3(0.9, 0.9, -10))
        world.propagateTransforms()
        let picker = ScenePicker(meshes: meshes)
        let hit = try #require(picker.pick(Ray(origin: Vec3(0.9, 0.9, 0), direction: Vec3(0, 0, -1)), in: world))
        #expect(hit.entity == cube && picker.stats.boundsHits == 2 && picker.stats.meshTests == 2)
        #expect(picker.pick(Ray(origin: Vec3(0, 0, 0), direction: Vec3(0, 0, -1)), in: world)?.entity == sphere)
    }

    @Test func skipsInvisibleUnpickableAndFiltered() {
        let hidden = spawn(at: Vec3(0, 0, -3), visible: false)
        let helper = spawn(at: Vec3(0, 0, -5))
        world.add(Unpickable(), to: helper)
        let locked = spawn(at: Vec3(0, 0, -7))
        let target = spawn(at: Vec3(0, 0, -9))
        world.propagateTransforms()
        let picker = ScenePicker(meshes: meshes)
        picker.filter = { $0 != locked }
        let ray = Ray(origin: .zero, direction: Vec3(0, 0, -1))
        #expect(picker.pick(ray, in: world)?.entity == target)
        world.modify(MeshRenderer.self, for: hidden) { $0.isVisible = true }
        world.add(MeshRenderer(mesh: MeshHandle("unknown")), to: helper)
        #expect(picker.pick(ray, in: world)?.entity == hidden)
    }

    @Test func pickIsExactUnderParentsAndNonUniformScale() throws {
        let parent = world.spawn(Transform(position: Vec3(2, 0, -6), rotation: Quat(angle: .pi / 4, axis: Vec3(0, 1, 0)),
                                           scale: Vec3(2, 1, 1)))
        let child = spawn(at: Vec3(0, 1, 0), rotation: Quat(angle: 0.3, axis: Vec3(1, 0, 0)), scale: Vec3(0.5, 2, 1))
        world.setParent(child, to: parent)
        world.propagateTransforms()
        let model = world.worldMatrix(of: child)
        // Aim at the center of the child's +x face, from outside along its world normal.
        let faceCenter4 = model * Vec4(0.5, 0, 0, 1)
        let faceCenter = Vec3(faceCenter4.x, faceCenter4.y, faceCenter4.z)
        let n4 = model.inverse
        let normal = normalize(Vec3(n4.c0.x, n4.c1.x, n4.c2.x))  // inverse-transpose times (1, 0, 0)
        let picker = ScenePicker(meshes: meshes)
        let hit = try #require(picker.pick(Ray(origin: faceCenter + normal * 3, direction: -normal), in: world))
        #expect(hit.entity == child)
        #expect(length(hit.point - faceCenter) < 1e-4)
        #expect(abs(hit.distance - 3) < 1e-4)
        #expect(length(hit.normal - normal) < 1e-4)
    }

    @Test func backFacesCountUnlessCulled() {
        let floor = spawn(.plane, at: Vec3(0, -1, 0), scale: Vec3(10, 1, 10))
        world.propagateTransforms()
        let picker = ScenePicker(meshes: meshes)
        let fromBelow = Ray(origin: Vec3(0, -5, 0), direction: Vec3(0, 1, 0))
        #expect(picker.pick(fromBelow, in: world)?.entity == floor)
        picker.cullsBackFaces = true
        #expect(picker.pick(fromBelow, in: world) == nil)
        #expect(picker.pick(Ray(origin: Vec3(0, 5, 0), direction: Vec3(0, -1, 0)), in: world)?.entity == floor)
        // A mirroring scale flips the winding, so the renderer culls the other side.
        world.add(Transform(position: Vec3(0, -1, 0), scale: Vec3(-10, 1, 10)), to: floor)
        world.propagateTransforms()
        #expect(picker.pick(Ray(origin: Vec3(0, 5, 0), direction: Vec3(0, -1, 0)), in: world) == nil)
        #expect(picker.pick(fromBelow, in: world)?.entity == floor)
    }

    @Test func pickAtViewportPoint() throws {
        let view = perspectiveView(eye: Vec3(0, 3, 8), target: .zero, reversedZ: true)
        let cube = spawn(at: Vec3(2, 0.5, 0))
        spawn(at: Vec3(-2, 0.5, 0))
        world.propagateTransforms()
        let picker = ScenePicker(meshes: meshes)
        let point = try #require(view.project(Vec3(2, 0.5, 0.5)))  // the front face's center
        let hit = try #require(picker.pick(at: point, in: view, world: world))
        #expect(hit.entity == cube && length(hit.point - Vec3(2, 0.5, 0.5)) < 1e-3)
        #expect(picker.pick(at: Vec2(400, 20), in: view, world: world) == nil)
    }

    @Test func marqueeSelectsEntitiesWhoseBoxesOverlapTheRectangle() throws {
        let view = perspectiveView(eye: Vec3(0, 10, 10), target: .zero)
        let a = spawn(at: Vec3(-3, 0, 0)), b = spawn(at: Vec3(3, 0, 0)), behind = spawn(at: Vec3(0, 12, 14))
        let rotated = spawn(at: Vec3(0, 0, -3), rotation: Quat(angle: .pi / 4, axis: Vec3(0, 1, 0)), scale: Vec3(4, 1, 0.2))
        world.propagateTransforms()
        let picker = ScenePicker(meshes: meshes)
        let pa = try #require(view.project(Vec3(-3, 0, 0)))
        let small = UIRect(x: pa.x - 5, y: pa.y - 5, width: 10, height: 10)
        #expect(picker.entities(in: small, view: view, world: world) == [a])
        let all = picker.entities(in: UIRect(x: 0, y: 0, width: 800, height: 600), view: view, world: world)
        #expect(Set(all) == [a, b, rotated] && !all.contains(behind))
        #expect(picker.entities(in: UIRect(x: 0, y: 0, width: 0, height: 10), view: view, world: world).isEmpty)
    }

    /// Picks into 10k entities (run in release for meaningful timings: see the report).
    @Test func pickingAmong10kEntities() throws {
        var seed: UInt64 = 7
        func random() -> Float {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Float(seed >> 40) / Float(1 << 24)
        }
        for i in 0..<10_000 {
            let p = Vec3(Float(i % 100) - 50, random() * 4, Float(i / 100) - 50)
            spawn(i % 2 == 0 ? .cube : .sphere, at: p, rotation: Quat(angle: random() * 6, axis: Vec3(0, 1, 0)),
                  scale: Vec3(repeating: 0.4 + random() * 0.5))
        }
        world.propagateTransforms()
        let view = perspectiveView(eye: Vec3(0, 40, 70), target: .zero, size: Vec2(1600, 900))
        let picker = ScenePicker(meshes: meshes)
        let clock = ContinuousClock()
        var best = Duration.seconds(10), hits = 0
        var stats = PickStats()
        for k in 0..<20 {
            let point = Vec2(400 + Float(k) * 40, 300 + Float(k % 5) * 60)
            let start = clock.now
            if picker.pick(at: point, in: view, world: world) != nil { hits += 1 }
            best = min(best, clock.now - start)
            stats = picker.stats
        }
        #expect(hits > 10)
        let start = clock.now
        let marquee = picker.entities(in: UIRect(x: 600, y: 300, width: 400, height: 300), view: view, world: world)
        let marqueeTime = clock.now - start
        print("pick among 10k entities: best \(best) per pick, last \(stats); marquee \(marquee.count) entities in \(marqueeTime)")
    }
}
