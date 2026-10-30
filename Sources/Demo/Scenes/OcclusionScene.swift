import Engine
import Foundation

/// A city grid seen from street level. Every intersection holds a cluster of 125 animated
/// cubes; most clusters are hidden behind buildings. Each frame the scene skips clusters
/// outside the view frustum, draws the buildings, then only the clusters whose last
/// occlusion query came back visible, then one invisible bounding-box query per cluster
/// in view for the next frames to use.
/// O toggles culling, B shows the occlusion-culled clusters' boxes through the walls.
///
/// Results arrive a few frames late, so a cluster coming into view can pop in briefly;
/// the proxy boxes are padded to hide most of that. The shadow pass skips only clusters
/// whose shadow can't reach the view (an occluded cluster can still cast a visible shadow).
/// The cubes are animated by the vertex shader, so they sit in a static buffer.
final class OcclusionScene: DemoScene {
    static let name = "occlusion"
    static let summary = "frustum + occlusion culling with hardware queries on bounding-box proxies"

    private struct Cluster {
        var center: Vec3
        var halfExtent: Vec3
    }

    private enum Visibility {
        case drawn, outsideView, occluded
    }

    private static let blocks = 12
    private static let pitch: Float = 8
    private static let latticeSize = 5
    private static let cubesPerCluster = latticeSize * latticeSize * latticeSize
    /// Added to each side of a cluster's bounds for its query proxy.
    private static let proxyPadding: Float = 0.3

    private let renderer: Renderer
    private let buildings: GPUBuffer
    private let buildingCount: Int
    private var clusters: [Cluster] = []
    /// One padded bounding box per cluster, in cluster order.
    private let proxies: GPUBuffer
    /// Every cluster's cubes (rest poses), cluster c at `c * cubesPerCluster`.
    private let cubes: GPUBuffer
    private var visibility: [Visibility] = []
    /// Whether each cluster's shadow can fall inside the view this frame.
    private var castsIntoView: [Bool] = []
    private let queries: OcclusionQuerySet
    private var culling = true
    private var xray = false

    init(renderer: Renderer) throws {
        self.renderer = renderer
        var rng = SplitMix64(state: 7)
        let n = Self.blocks
        let half = Float(n) / 2

        var buildingInstances = [floorInstance(halfSize: 60)]
        for bz in 0..<n {
            for bx in 0..<n {
                let center = Vec2(Float(bx) - half + 0.5, Float(bz) - half + 0.5) * Self.pitch
                let height: Float = 6 + rng.next() * 14
                buildingInstances.append(Instance(
                    .trs(Vec3(center.x, height / 2, center.y), scale: Vec3(2.3, height / 2, 2.3)),
                    color: hsv(0.08 + rng.next() * 0.05, 0.12 + rng.next() * 0.1, 0.55 + rng.next() * 0.25)))
            }
        }
        buildings = try renderer.device.makeBuffer(buildingInstances, usage: .vertex)
        buildingCount = buildingInstances.count

        for iz in 0...n {
            for ix in 0...n {
                let center = Vec2(Float(ix) - half, Float(iz) - half) * Self.pitch
                // Lattice spans ±1 horizontally (plus rotated cube corners) and bobs between y≈0 and 2.9.
                clusters.append(Cluster(center: Vec3(center.x, 1.45, center.y), halfExtent: Vec3(1.35, 1.5, 1.35)))
            }
        }
        proxies = try renderer.device.makeBuffer(clusters.map(Self.proxy), usage: .vertex)
        cubes = try renderer.device.makeBuffer(clusters.enumerated().flatMap(Self.cubes), usage: .vertex)
        visibility = Array(repeating: .drawn, count: clusters.count)
        castsIntoView = Array(repeating: true, count: clusters.count)
        queries = OcclusionQuerySet(count: clusters.count)
    }

    var initialView: OrbitView { OrbitView(yaw: 0.35, pitch: 0.08, distance: 26, target: Vec3(0, 3, 0)) }
    var lighting: Lighting { Lighting(direction: Vec3(0.45, 0.8, 0.3), shadowExtent: 62) }

    var status: String {
        guard culling else { return "culling off: \(clusters.count) clusters" + (xray ? ", x-ray" : "") }
        let drawn = visibility.count { $0 == .drawn }
        let outside = visibility.count { $0 == .outsideView }
        let casters = castsIntoView.count { $0 }
        return "culling on: \(drawn)/\(clusters.count) clusters drawn, \(outside) outside view, "
            + "\(clusters.count - drawn - outside) occluded, \(casters) shadow casters" + (xray ? ", x-ray" : "")
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        ViewCamera(eye: orbitEye, target: target, far: 250)
    }

    func update(input: Input, dt: Float, time: Float) {
        if input.wasPressed(.o) {
            culling.toggle()
            queries.reset()  // stale results would hide clusters for a few frames
        }
        if input.wasPressed(.b) { xray.toggle() }
    }

    /// A cluster's 5×5×5 lattice in its rest pose; the shader adds the spin and bob.
    private static func cubes(_ c: Int, _ cluster: Cluster) -> [Instance] {
        let n = latticeSize
        let spacing: Float = 0.5
        let offset = Float(n - 1) / 2
        let hue = Float(c % 17) / 17
        var cubes: [Instance] = []
        for y in 0..<n {
            for z in 0..<n {
                for x in 0..<n {
                    // Columns bob as one so stacked cubes never intersect.
                    let phase = Float(x + z * 3 + c * 5) * 0.37
                    let p = Vec3((Float(x) - offset) * spacing, Float(y) * spacing - 1.05, (Float(z) - offset) * spacing)
                    cubes.append(Instance(.trs(cluster.center + p, scale: Vec3(repeating: 0.15)),
                                          color: hsv(hue + Float(y) * 0.03, 0.7, 0.9))
                        .animated(phase: phase, bob: 0.25))
                }
            }
        }
        return cubes
    }

    /// Decides which clusters each pass draws. Query results only change between frames,
    /// so this holds for the whole frame.
    func renderOffscreen(frame: Frame) {
        let frustum = Frustum(viewProjection: renderer.uniforms.viewProj)
        let light = Vec3(renderer.uniforms.lightDir.x, renderer.uniforms.lightDir.y, renderer.uniforms.lightDir.z)
        for (i, cluster) in clusters.enumerated() {
            // Shadows fall away from the light until they hit something, at the latest the
            // ground (y = 0, below everything here). Padding covers the shadow filter's reach.
            let top = cluster.center.y + cluster.halfExtent.y
            castsIntoView[i] = !culling || light.y <= 0 || frustum.intersects(
                center: cluster.center, halfExtent: cluster.halfExtent + Vec3(repeating: 0.5),
                sweptBy: -light * (top / light.y))

            if !culling {
                visibility[i] = .drawn
            } else if !frustum.intersects(center: cluster.center, halfExtent: cluster.halfExtent) {
                // Not queried while outside, so drop results still in flight: an old
                // "hidden" must not arrive after the cluster comes back into view.
                queries.invalidate(i)
                visibility[i] = .outsideView
            } else if queries.results[i] == false && !contains(cluster, renderer.eye) {
                visibility[i] = .occluded
            } else {
                visibility[i] = .drawn  // visible, not yet known, or too close to trust the proxy
            }
        }
    }

    func drawShadowCasters(_ pass: RenderPass) {
        renderer.draw(pass, renderer.cube, instanceBuffer: buildings, count: buildingCount)
        drawClusters(pass) { castsIntoView[$0] }
    }

    func draw(_ pass: RenderPass) throws {
        pass.setPipeline(try renderer.litPipeline())
        renderer.draw(pass, renderer.cube, instanceBuffer: buildings, count: buildingCount)
        drawClusters(pass) { visibility[$0] == .drawn }
        guard culling else { return }

        // Queries go last, so they test against the finished depth buffer. Clusters drawn
        // this frame pass easily: their proxy surrounds geometry that is already in it.
        pass.setPipeline(try renderer.litPipeline(.occlusionProxy))
        renderer.setMesh(pass, renderer.cube)
        for (i, cluster) in clusters.enumerated() where visibility[i] != .outsideView && !contains(cluster, renderer.eye) {
            pass.beginOcclusionQuery(queries, index: i)
            pass.setVertexBuffer(proxies, offset: i * MemoryLayout<Instance>.stride, index: 1)
            pass.drawIndexed(indexCount: renderer.cube.indexCount)
            pass.endOcclusionQuery()
        }

        if xray {
            pass.setPipeline(try renderer.litPipeline(.xray))
            renderer.draw(pass, renderer.cube, clusters.indices.filter { visibility[$0] == .occluded }.map { i in
                var box = Self.proxy(clusters[i])
                box.color = Vec4(0.95, 0.15, 0.1, 0.35)
                box.params.y = 1  // emissive
                return box
            })
        }
    }

    /// Draws the clusters `include` selects, one draw per run of consecutive ones.
    private func drawClusters(_ pass: RenderPass, where include: (Int) -> Bool) {
        var i = 0
        while i < clusters.count {
            guard include(i) else { i += 1; continue }
            let start = i
            while i < clusters.count && include(i) { i += 1 }
            renderer.draw(pass, renderer.cube, instanceBuffer: cubes,
                          first: start * Self.cubesPerCluster, count: (i - start) * Self.cubesPerCluster)
        }
    }

    /// The padded bounding box drawn for a cluster's query.
    private static func proxy(_ cluster: Cluster) -> Instance {
        Instance(.trs(cluster.center, scale: cluster.halfExtent + Vec3(repeating: proxyPadding)), color: .zero)
    }

    /// Whether `point` is inside (or within near-plane distance of) the cluster's proxy.
    /// The proxy can't be trusted then: the near plane may clip it away entirely.
    private func contains(_ cluster: Cluster, _ point: Vec3) -> Bool {
        let d = point - cluster.center
        let reach = cluster.halfExtent + Vec3(repeating: Self.proxyPadding + 0.5)
        return abs(d.x) < reach.x && abs(d.y) < reach.y && abs(d.z) < reach.z
    }
}
