import Engine
import Foundation

/// The showcase: a field of ~800 cubes moving in waves, a spiral tower and a ring of
/// pillars, lit by an orbiting sun. L pauses the sun, R rebuilds the pillars.
final class ShadowsScene: DemoScene {
    static let name = "shadows"
    static let summary = "shadow mapping + PCF, per-frame and static instancing, R releases a buffer mid-run"

    private let renderer: Renderer
    /// Floor and pillars; rebuilt on R.
    private var staticInstances: GPUBuffer!
    private var staticCount = 0
    private var dynamicInstances: [Instance] = []
    private var uploaded: FrameInstances?
    private var layoutSeed: UInt64 = 1
    private var animateLight = true
    private var lightAngle: Float = 0.8

    init(renderer: Renderer) throws {
        self.renderer = renderer
        try buildStaticInstances()
    }

    var lighting: Lighting {
        let elevation: Float = 0.8
        return Lighting(direction: Vec3(cosf(lightAngle) * cosf(elevation), sinf(elevation), sinf(lightAngle) * cosf(elevation)))
    }

    var initialView: OrbitView { OrbitView(yaw: 0.7, pitch: 0.62, distance: 42) }
    var status: String { animateLight ? "" : "sun paused" }

    /// Replacing the buffer releases the old one; the backend frees it once in-flight
    /// frames are done with it.
    private func buildStaticInstances() throws {
        var rng = SplitMix64(state: layoutSeed)
        var instances = [floorInstance()]
        let pillars = 14
        for i in 0..<pillars {
            let angle = Float(i) / Float(pillars) * 2 * .pi + rng.next() * 0.2
            let radius: Float = 21 + rng.next() * 2
            let height: Float = 2 + rng.next() * 5
            instances.append(Instance(
                .trs(Vec3(cosf(angle) * radius, height, sinf(angle) * radius), angle: rng.next() * .pi, scale: Vec3(0.8, height, 0.8)),
                color: hsv(0.06 + rng.next() * 0.08, 0.45, 0.9)))
        }
        staticInstances = try renderer.device.makeBuffer(instances, usage: .vertex)
        staticCount = instances.count
    }

    func update(input: Input, dt: Float, time t: Float) {
        if input.wasPressed(.l) { animateLight.toggle() }
        if input.wasPressed(.r) {
            layoutSeed += 1
            do { try buildStaticInstances() } catch { print("Rebuild failed: \(error)") }
        }
        if animateLight { lightAngle += 0.3 * dt }

        dynamicInstances.removeAll(keepingCapacity: true)
        // Wave field with a clearing in the middle for the tower.
        let gridSize = 28, spacing: Float = 1.25
        let half = Float(gridSize - 1) / 2
        for gz in 0..<gridSize {
            for gx in 0..<gridSize {
                let p = Vec2(Float(gx) - half, Float(gz) - half) * spacing
                let r = (p * p).sum().squareRoot()
                if r < 5 { continue }
                let wave = sinf(r * 0.55 - t * 2.2) * 0.5 + 0.5
                let size = 0.3 + 0.18 * wave
                let hue = (atan2f(p.y, p.x) / (2 * .pi) + 0.5 + t * 0.02).truncatingRemainder(dividingBy: 1)
                dynamicInstances.append(Instance(
                    .trs(Vec3(p.x, 0.4 + wave * 1.6, p.y), angle: t * 0.8 + r * 0.3, scale: Vec3(repeating: size)),
                    color: hsv(hue, 0.75, 0.6 + 0.4 * wave)))
            }
        }
        // Spiral tower.
        let blocks = 36
        for i in 0..<blocks {
            let f = Float(i)
            let angle = f * 0.45 + t * 0.6
            let radius = 2.2 - f * 0.04
            dynamicInstances.append(Instance(
                .trs(Vec3(cosf(angle) * radius, 0.5 + f * 0.42, sinf(angle) * radius), angle: -angle, scale: Vec3(0.55, 0.2, 0.35)),
                color: hsv(f / Float(blocks) * 0.8, 0.7, 1)))
        }
        dynamicInstances.append(Instance(.trs(Vec3(0, 8, 0), scale: Vec3(0.3, 8, 0.3)), color: Vec3(0.8, 0.8, 0.82)))
    }

    func renderOffscreen(frame: Frame) {
        uploaded = renderer.upload(dynamicInstances, in: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {
        renderer.draw(pass, renderer.cube, instanceBuffer: staticInstances, count: staticCount)
        if let uploaded { renderer.draw(pass, renderer.cube, uploaded) }
    }

    func draw(_ pass: RenderPass) throws {
        pass.setPipeline(try renderer.litPipeline())
        drawShadowCasters(pass)
    }
}
