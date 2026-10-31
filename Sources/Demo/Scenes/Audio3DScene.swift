import Engine
import Foundation

/// 3D audio (`AudioListener` / `AudioEmitter` components): three sounds orbit a listener at the
/// origin (the box with a nose pointing down -Z). A rising-and-falling siren (inverse rolloff,
/// strong Doppler), a spinning speaker that beeps (a cone, so it fades as it turns away) and a
/// swell of wind (linear rolloff) are drawn as spheres. Their level, pan and pitch follow the
/// transforms: distance attenuation, equal-power panning with a head-shadow low-pass on the far
/// ear, a distance low-pass and Doppler from the entities' movement. Inside the ring on the
/// ground the emitters feed a reverb send bus; outside it they are mostly dry. Bus meters and
/// a table of what each emitter hears are drawn with the UI draw list.
///
/// Keys: **R** reverb zone on/off, **L** low-pass on every emitter (800 Hz) on/off, **M** mute.
/// Every sound is synthesized at startup. Under `ENGINE_SCREENSHOT` the engine uses the offline
/// audio device and a fixed timestep, so the meters and positions in the screenshot are deterministic.
final class Audio3DScene: DemoScene {
    static let name = "audio3d"
    static let summary = "3D audio: emitters orbiting the listener, attenuation/pan/Doppler/cone, reverb zone, low-pass, meters"

    private static let sampleRate = 48000.0
    private static let panel = UIColor(hex: 0x1b2130)
    private static let border = UIColor(hex: 0x323b52)
    private static let text = UIColor(hex: 0xe6e9f0)
    private static let dim = UIColor(hex: 0x8a93a8)
    private static let green = UIColor(hex: 0x34c759)
    private static let warm = UIColor(hex: 0xf5a623)
    private static let red = UIColor(hex: 0xff5a4f)
    private static let sky = Vec3(0.05, 0.06, 0.1)
    private static let zoneRadius: Float = 8

    /// One orbiting emitter: its path and what it plays.
    private struct Source {
        var name: String
        var sound: String
        var entity = Entity.invalid
        var color: Vec3
        var radius: Float
        var wobble: Float
        var height: Float
        var speed: Float
        var phase: Float
        var wet: Float = 0
        // For the table.
        var distance: Float = 0
        var pan: Float = 0
        var pitch: Float = 1
    }

    private var world = World()
    private let sceneRenderer: SceneRenderer
    private let debug = DebugDraw()
    private var cameraEntity = Entity.invalid
    private var sources: [Source] = [
        Source(name: "siren", sound: "siren", color: Vec3(1, 0.3, 0.25), radius: 6, wobble: 3, height: 1.2, speed: 0.9, phase: 0),
        Source(name: "beeper", sound: "beeper", color: Vec3(0.3, 0.8, 1), radius: 9, wobble: 2.5, height: 2.4, speed: -0.55, phase: 2.2),
        Source(name: "wind", sound: "wind", color: Vec3(0.55, 1, 0.5), radius: 12, wobble: 3, height: 0.8, speed: 0.35, phase: 4.1),
    ]
    private let sounds: [(name: String, buffer: SoundBuffer)]
    private var audio: AudioSystem?
    private var reverbBus: AudioBus?
    private var reverbOn = true
    private var lowPass = false
    private var muted = false
    private var orbit: (eye: Vec3, target: Vec3)?
    private var meters: [(name: String, level: Float)] = []
    private var deviceName = ""

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        sceneRenderer.debugDraw = debug
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.3, 0.32, 0.36, 1), checker: true, roughness: 0.9), key: "floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.3), key: "gloss")
        sounds = [("siren", Self.makeSiren()), ("beeper", Self.makeBeeper()), ("wind", Self.makeWind())]
        build()
    }

    private func build() {
        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(14, 14, 18), at: Vec3(0, 1, 0)),
            Camera(fovY: .pi / 3.5, near: 0.3, far: 200, clearColor: Vec4(Self.sky, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Vec3(0.35, 0.42, 0.6), groundColor: Vec3(0.12, 0.12, 0.14), fogColor: Self.sky,
                                         fogDensity: 0.006))
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -Vec3(0.4, 0.8, 0.35))),
                        DirectionalLight(intensity: 1.4, shadowExtent: 22, shadowCenter: Vec3(0, 1, 0)))
        _ = world.spawn(Transform(position: Vec3(0, -0.01, 0), scale: Vec3(60, 1, 60)), Name("Floor"),
                        MeshRenderer(mesh: .plane, material: MaterialHandle("floor"), castsShadows: false))

        // The listener: a body with a nose toward -Z (the way it hears "ahead").
        let listener = world.spawn(Transform(position: Vec3(0, 0.5, 0)), Name("Listener"), AudioListener(),
                                   MeshRenderer(mesh: .cube, tint: Vec3(0.85, 0.85, 0.9)))
        world.modify(Transform.self, for: listener) { $0.scale = Vec3(0.9, 0.9, 0.9) }
        _ = world.spawn(Transform(position: Vec3(0, 0.5, -0.65), scale: Vec3(0.3, 0.3, 0.5)), Name("Nose"),
                        MeshRenderer(mesh: .cube, tint: Vec3(1, 0.8, 0.2)))

        for i in sources.indices {
            let s = sources[i]
            var emitter = AudioEmitter(sound: s.sound, volume: s.name == "wind" ? 0.9 : 0.7, reverbSend: 0)
            emitter.spatial.dopplerFactor = 3
            emitter.spatial.minDistance = 2
            emitter.spatial.maxDistance = 30
            switch s.name {
            case "siren": emitter.spatial.rolloff = .inverse
            case "beeper":
                emitter.spatial.rolloff = .inverse
                emitter.spatial.coneInnerAngle = 70
                emitter.spatial.coneOuterAngle = 200
                emitter.spatial.coneOuterGain = 0.15
            default:
                emitter.spatial.rolloff = .linear
                emitter.spatial.maxDistance = 22
            }
            sources[i].entity = world.spawn(
                Transform(position: position(of: s, time: 0), scale: Vec3(repeating: 0.8)), Name(s.name), emitter,
                MeshRenderer(mesh: .sphere, material: MaterialHandle("gloss"), tint: s.color))
        }
        world.propagateTransforms()
    }

    var initialView: OrbitView { OrbitView(yaw: 0.55, pitch: 0.75, distance: 30, target: Vec3(0, 0.5, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.sky) }
    var status: String { "reverb zone \(reverbOn ? "on" : "off") [R], low-pass \(lowPass ? "on" : "off") [L], muted \(muted ? "yes" : "no") [M]" }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, near: 0.3)
    }

    // MARK: - Update

    /// A slow ellipse-ish orbit around the listener whose radius breathes, so the sound
    /// approaches and recedes (that is what Doppler needs).
    private func position(of s: Source, time t: Float) -> Vec3 {
        let angle = s.phase + s.speed * t
        let radius = s.radius + s.wobble * sinf(t * 0.45 + s.phase)
        return Vec3(cosf(angle) * radius, s.height, sinf(angle) * radius)
    }

    func willClose() {
        guard let audio else { return }
        audio.stopAll(on: audio.sfx)
        audio.listener = AudioListenerState()
        audio.sfx.isMuted = false
        reverbBus?.effects = []
    }

    func update(engine: Engine, dt: Float, time t: Float) {
        let audio = setUp(engine.audio)
        let input = engine.input
        if input.wasPressed(.r) { reverbOn.toggle() }
        if input.wasPressed(.l) { lowPass.toggle() }
        if input.wasPressed(.m) { muted.toggle(); audio.sfx.isMuted = muted }

        for i in sources.indices {
            var s = sources[i]
            let p = position(of: s, time: t)
            let rotation: Quat = s.name == "beeper" ? Quat(angle: t * 1.6, axis: Vec3(0, 1, 0)) : .identity
            world.modify(Transform.self, for: s.entity) { $0.position = p; $0.rotation = rotation }

            // Reverb: wet inside the zone (smoothed so crossing the edge fades), a little outside.
            let target: Float = reverbOn ? (length(Vec3(p.x, 0, p.z)) < Self.zoneRadius ? 0.8 : 0.08) : 0
            s.wet += (target - s.wet) * min(dt * 4, 1)
            let filter = lowPass ? AudioFilter(.lowPass, cutoff: 800) : nil
            world.modify(AudioEmitter.self, for: s.entity) { $0.reverbSend = s.wet; $0.filter = filter }

            // What it hears, for the table (the same math as the mixer, with analytic velocity).
            let ahead = position(of: s, time: t + 0.01)
            let velocity = (ahead - p) / 0.01
            let offset = p - Vec3(0, 0.5, 0)
            s.distance = length(offset)
            s.pan = s.distance > 0 ? offset.x / s.distance : 0
            s.pitch = SpatialAudio.doppler(listenerPosition: Vec3(0, 0.5, 0), listenerVelocity: .zero, sourcePosition: p,
                                           sourceVelocity: velocity, speedOfSound: 343, factor: 3)
            sources[i] = s
        }
        reverbBus?.effects = [.reverb(AudioReverb(roomSize: 0.82, damping: 0.45, width: 1, wet: 1, dry: 0))]

        world.update(dt: Double(dt))

        debug.removeAll()
        let ring = reverbOn ? Vec4(0.4, 0.8, 1, 1) : Vec4(0.5, 0.5, 0.55, 1)
        debug.circle(center: Vec3(0, 0.02, 0), normal: Vec3(0, 1, 0), radius: Self.zoneRadius, color: ring, segments: 96,
                     style: DebugDraw.Style(width: 3))
        for s in sources {
            let p = position(of: s, time: t)
            debug.line(Vec3(p.x, 0.02, p.z), p, color: Vec4(s.color, 0.6), style: DebugDraw.Style(width: 1.5))
        }

        meters = audio.buses.filter { ["master", "sfx", "reverb"].contains($0.name) }.map { ($0.name, $0.level) }
    }

    private func setUp(_ system: AudioSystem) -> AudioSystem {
        if let audio { return audio }
        audio = system
        deviceName = system.device.name
        for sound in sounds { system.register(sound.buffer, as: sound.name) }
        reverbBus = system.bus(named: "reverb") ?? system.addBus("reverb")
        world.addSpatialAudio(system)
        return system
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        if let orbit {
            world.add(Transform.looking(from: orbit.eye, at: orbit.target), to: cameraEntity)
            world.propagateTransforms()
        }
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }

    // MARK: - Drawing

    func drawUI(_ ui: UIDrawList) {
        let canvas = UIRect(x: 0, y: 0, width: 1280, height: 720)
        let origin = Vec2(max((ui.size.x - canvas.width) / 2, 0), max((ui.size.y - canvas.height) / 2, 0))
        func at(_ x: Float, _ y: Float, _ w: Float, _ h: Float) -> UIRect {
            UIRect(x: origin.x + x, y: origin.y + y, width: w, height: h)
        }
        func text(_ s: String, _ x: Float, _ y: Float, size: Float = 14, color: UIColor = Audio3DScene.text) {
            ui.drawText(s, at: Vec2(origin.x + x, origin.y + y), size: size, color: color)
        }
        func section(_ rect: UIRect, _ title: String) {
            ui.fillRect(rect, color: Self.panel, radii: UICornerRadii(10))
            ui.strokeRect(rect, color: Self.border, width: 1, radii: UICornerRadii(10))
            ui.drawText(title, at: Vec2(rect.x + 14, rect.y + 10), size: 14, color: Self.dim)
        }

        text("3D audio", 24, 18, size: 30)
        text(deviceName.isEmpty ? "" : "Device: \(deviceName)", 24, 58, size: 13, color: Self.dim)

        // Bus meters.
        section(at(24, 90, 330, 130), "Buses (peak level)")
        for (i, meter) in meters.enumerated() {
            let y: Float = 124 + Float(i) * 30
            text(meter.name, 40, y, size: 14)
            let bar = at(110, y + 2, 180, 14)
            ui.fillRect(bar, color: UIColor(hex: 0x10141d), radii: UICornerRadii(4))
            let level = min(meter.level, 1)
            if level > 0 {
                let color = level > 0.9 ? Self.red : level > 0.6 ? Self.warm : Self.green
                ui.fillRect(UIRect(x: bar.x, y: bar.y, width: bar.width * level, height: bar.height), color: color,
                            radii: UICornerRadii(4))
            }
            text(String(format: "%.2f", meter.level), 300, y, size: 12, color: Self.dim)
        }

        // What each emitter hears.
        section(at(24, 232, 330, 150), "Emitters (distance · pan · Doppler · reverb)")
        for (i, s) in sources.enumerated() {
            let y: Float = 268 + Float(i) * 36
            ui.fillRect(at(40, y + 3, 10, 10), color: UIColor(powf(s.color.x, 0.45), powf(s.color.y, 0.45), powf(s.color.z, 0.45)), radii: UICornerRadii(5))
            text(s.name, 58, y, size: 14)
            text(String(format: "%4.1f m   pan %+.2f   x%.3f   wet %.2f", s.distance, s.pan, s.pitch, s.wet), 58, y + 17, size: 11,
                 color: Self.dim)
        }

        ui.fillRect(at(16, 648, 640, 58), color: Self.panel, radii: UICornerRadii(10))
        let help = "R reverb zone \(reverbOn ? "on" : "off") · L low-pass \(lowPass ? "on" : "off") · M mute"
        text(help, 24, 660, size: 13, color: Self.dim)
        text("The listener (box, nose toward -Z) is at the center; everything is synthesized at startup.", 24, 682, size: 12,
             color: Self.dim)
    }

    // MARK: - Sounds

    private struct Noise {
        var state: UInt32 = 0x2468_ace1
        mutating func next() -> Float {
            state = state &* 1_664_525 &+ 1_013_904_223
            return Float(state >> 8) / Float(1 << 23) - 1
        }
    }

    /// A 2 s seamless loop: a tone sweeping 500-900 Hz and back with a little second harmonic.
    private static func makeSiren() -> SoundBuffer {
        let seconds = 2.0
        return SoundBuffer(frameCount: Int(sampleRate * seconds), sampleRate: sampleRate, name: "siren") { i, _ in
            let t = Double(i) / sampleRate
            // Integral of 700 + 200 sin(2π 0.5 t): a whole number of cycles in 2 s, so the loop is seamless.
            let phase = 2 * Double.pi * (700 * t + 200 * (1 - cos(2 * Double.pi * 0.5 * t)) / (2 * Double.pi * 0.5))
            return Float(sin(phase) + 0.3 * sin(2 * phase)) * 0.45
        }
    }

    /// A 1 s loop: four short 1.2 kHz beeps with a soft envelope.
    private static func makeBeeper() -> SoundBuffer {
        SoundBuffer(frameCount: Int(sampleRate), sampleRate: sampleRate, name: "beeper") { i, _ in
            let t = Float(i) / Float(sampleRate)
            let inBeat = t.truncatingRemainder(dividingBy: 0.25)
            let envelope = min(inBeat / 0.005, 1) * max(1 - inBeat / 0.09, 0)
            return sinf(2 * .pi * 1200 * t) * envelope * 0.7
        }
    }

    /// A 3 s loop of low-passed noise that swells and fades (zero at both ends, so it loops cleanly).
    private static func makeWind() -> SoundBuffer {
        var noise = Noise()
        var low: Float = 0, lower: Float = 0
        let seconds: Float = 3
        return SoundBuffer(frameCount: Int(sampleRate * Double(seconds)), sampleRate: sampleRate, name: "wind") { i, _ in
            let t = Float(i) / Float(sampleRate)
            low += (noise.next() - low) * 0.08
            lower += (low - lower) * 0.08
            let swell = powf(sinf(.pi * t / seconds), 2)
            return lower * 5 * swell
        }
    }
}
