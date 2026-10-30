import Engine
import Foundation

/// The 2D UI draw layer (`engine.ui`): fills, rounded corners with per-corner radii, strokes,
/// gradients, images, lines, nested clipping and batching, laid out in points on a 1280x720
/// canvas (centered when the window is larger). The 3D scene is just a dark background: the UI
/// is drawn in the window pass, so compare window screenshots (`ENGINE_SCREENSHOT_SOURCE=window`).
final class UIScene: DemoScene {
    static let name = "ui"
    static let summary = "2D draw list: rounded rects, strokes, gradients, images, lines, nested clipping, batching"

    private let tiles: GPUTexture
    private let pixelated: GPUSampler
    private let trilinear: GPUSampler
    private var time: Float = 0

    private static let panel = UIColor(hex: 0x1d2330)
    private static let accent = UIColor(hex: 0x3478f6)
    private static let warm = UIColor(hex: 0xf5a623)
    private static let green = UIColor(hex: 0x34c759)
    private static let red = UIColor(hex: 0xff453a)
    private static let line = UIColor(hex: 0x39425a)

    init(renderer: Renderer) throws {
        let device = renderer.device
        tiles = try device.makeTexture(
            pixels: Self.tilePixels(size: 64), width: 64, height: 64, format: .rgba8Srgb, generateMipmaps: true)
        pixelated = try device.makeSampler(SamplerDescriptor(filter: .nearest, mipFilter: .none, addressMode: .clampToEdge))
        trilinear = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .linear, addressMode: .clampToEdge))
    }

    var lighting: Lighting { Lighting(fogColor: Vec3(0.004, 0.005, 0.009)) }
    var initialView: OrbitView { OrbitView(distance: 10) }

    func update(input: Input, dt: Float, time t: Float) { time = t }
    func drawShadowCasters(_ pass: RenderPass) {}
    func draw(_ pass: RenderPass) throws {}

    func drawUI(_ ui: UIDrawList) {
        let canvas = UIRect(x: 0, y: 0, width: 1280, height: 720)
        let origin = Vec2(max((ui.size.x - canvas.width) / 2, 0), max((ui.size.y - canvas.height) / 2, 0))
        func at(_ x: Float, _ y: Float, _ w: Float, _ h: Float) -> UIRect {
            UIRect(x: origin.x + x, y: origin.y + y, width: w, height: h)
        }
        func section(_ x: Float, _ y: Float, _ w: Float, _ h: Float) {
            ui.fillRect(at(x, y, w, h), color: Self.panel, radii: UICornerRadii(10))
            ui.strokeRect(at(x, y, w, h), color: Self.line, width: 1, radii: UICornerRadii(10))
        }

        // Fills and corner radii.
        section(20, 20, 400, 200)
        ui.fillRect(at(36, 36, 80, 60), color: Self.accent)
        ui.fillRect(at(128, 36, 80, 60), color: Self.accent, radii: UICornerRadii(12))
        ui.fillRect(at(220, 36, 80, 60), color: Self.accent,
                    radii: UICornerRadii(topLeft: 0, topRight: 28, bottomRight: 0, bottomLeft: 28))
        ui.fillRect(at(312, 36, 92, 60), color: Self.accent, radii: UICornerRadii(30))  // pill
        ui.fillRect(at(36, 112, 96, 96), color: Self.warm, radii: UICornerRadii(48))  // circle
        ui.fillRect(at(148, 112, 96, 96), color: Self.green, radii: UICornerRadii(200))  // radii shrink to fit
        // Overlapping translucent shapes: blending in linear light.
        ui.fillRect(at(264, 120, 80, 80), color: Self.red.withAlpha(0.6), radii: UICornerRadii(16))
        ui.fillRect(at(300, 136, 100, 64), color: Self.accent.withAlpha(0.6), radii: UICornerRadii(16))

        // Gradients.
        section(440, 20, 400, 200)
        let sunrise = UIFill.linearGradient(start: UIColor(hex: 0xff5e62), end: UIColor(hex: 0xff9966), angle: 0)
        ui.fillRect(at(456, 36, 168, 80), fill: sunrise)
        ui.fillRect(at(636, 36, 188, 80), fill: .linearGradient(start: Self.accent, end: Self.green), radii: UICornerRadii(16))
        ui.fillRect(at(456, 132, 120, 76), fill: .linearGradient(start: .white, end: .black, angle: .pi / 4),
                    radii: UICornerRadii(topLeft: 38, topRight: 4, bottomRight: 38, bottomLeft: 4))
        ui.fillRect(at(588, 132, 120, 76), fill: .linearGradient(start: Self.warm, end: Self.warm.withAlpha(0), angle: 0),
                    radii: UICornerRadii(12))
        ui.fillRect(at(720, 132, 104, 76), fill: .linearGradient(start: UIColor(hex: 0x00c6ff), end: UIColor(hex: 0x0072ff),
                                                                    angle: 2.4), radii: UICornerRadii(38))

        // Strokes.
        section(860, 20, 400, 200)
        for (i, width) in ([1, 2, 4, 8] as [Float]).enumerated() {
            ui.strokeRect(at(876 + Float(i) * 76, 36, 64, 52), color: Self.warm, width: width)
        }
        ui.strokeRect(at(876, 104, 100, 100), color: Self.green, width: 3, radii: UICornerRadii(50))
        ui.fillRect(at(992, 104, 120, 100), color: Self.accent.withAlpha(0.35), radii: UICornerRadii(20))
        ui.strokeRect(at(992, 104, 120, 100), color: Self.accent, width: 2, radii: UICornerRadii(20))
        ui.strokeRect(at(1128, 104, 116, 100), color: .white, width: 3,
                      radii: UICornerRadii(topLeft: 40, topRight: 0, bottomRight: 40, bottomLeft: 0))

        // Lines: a fan of widths and caps, and hairlines.
        section(20, 240, 400, 220)
        let hub = Vec2(origin.x + 120, origin.y + 350)
        for i in 0..<12 {
            let angle = Float(i) / 12 * 2 * .pi
            let tip = hub + Vec2(cosf(angle), sinf(angle)) * 80
            ui.drawLine(from: hub + Vec2(cosf(angle), sinf(angle)) * 14, to: tip, width: 1 + Float(i) * 0.5,
                        color: UIColor(hex: 0x3478f6).mixed(with: Self.warm, Float(i) / 11), cap: i % 2 == 0 ? .round : .butt)
        }
        let spinner = time * 1.5
        ui.drawLine(from: hub, to: hub + Vec2(cosf(spinner), sinf(spinner)) * 96, width: 3, color: .white, cap: .round)
        for i in 0..<5 {
            let y = origin.y + 280 + Float(i) * 16
            ui.drawLine(from: Vec2(origin.x + 250, y + 0.5), to: Vec2(origin.x + 404, y + 0.5), width: 1, color: .white.withAlpha(0.8))
        }
        ui.drawLine(from: Vec2(origin.x + 250, origin.y + 380), to: Vec2(origin.x + 404, origin.y + 440), width: 1, color: Self.green)
        ui.drawLine(from: Vec2(origin.x + 250, origin.y + 440), to: Vec2(origin.x + 404, origin.y + 380), width: 6, color: Self.red,
                    cap: .round)

        // Images: any texture + sampler, UV rect, tint, rounded corners.
        section(440, 240, 400, 220)
        ui.drawImage(tiles, in: at(456, 256, 64, 64), sampler: pixelated)
        ui.drawImage(tiles, in: at(532, 256, 64, 64), tint: Self.warm, sampler: trilinear)
        ui.drawImage(tiles, in: at(608, 256, 64, 64), uv: UIRect(x: 0.25, y: 0.25, width: 0.25, height: 0.25), sampler: pixelated)
        ui.drawImage(tiles, in: at(684, 256, 64, 64), radii: UICornerRadii(32), sampler: trilinear)
        ui.drawImage(tiles, in: at(760, 256, 64, 64), radii: UICornerRadii(topLeft: 24, topRight: 0, bottomRight: 24, bottomLeft: 0),
                     sampler: trilinear)
        ui.drawImage(tiles, in: at(456, 336, 120, 120), radii: UICornerRadii(16), sampler: trilinear)
        ui.drawImage(tiles, in: at(592.5, 336.5, 52, 52), sampler: trilinear)  // half-pixel offsets
        ui.drawImage(tiles, in: at(660, 336, 24, 24), sampler: trilinear)
        ui.drawImage(tiles, in: at(696, 336, 12, 12), sampler: trilinear)
        ui.fillRect(at(592, 400, 232, 56), fill: .linearGradient(start: Self.green, end: Self.accent, angle: 0), radii: UICornerRadii(12))
        ui.drawImage(tiles, in: at(600, 408, 40, 40), tint: .white.withAlpha(0.7), radii: UICornerRadii(8), sampler: trilinear)

        // The same button at several sizes, all from one function.
        section(860, 240, 400, 220)
        var buttonX: Float = 876
        for size in [0.5, 0.75, 1, 1.5] as [Float] {
            let rect = at(buttonX, 256, 84 * size, 36 * size)
            ui.fillRect(rect, fill: .linearGradient(start: Self.accent, end: UIColor(hex: 0x1f5bd1)), radii: UICornerRadii(8 * size))
            ui.strokeRect(rect, color: .white.withAlpha(0.35), width: 1, radii: UICornerRadii(8 * size))
            ui.drawImage(tiles, in: UIRect(x: rect.x + 6 * size, y: rect.y + 6 * size, width: 24 * size, height: 24 * size),
                         radii: UICornerRadii(6 * size), sampler: trilinear)
            buttonX += 84 * size + 12
        }
        for (i, radius) in ([2, 6, 12, 18] as [Float]).enumerated() {
            let rect = at(876 + Float(i) * 96, 340, 84, 56)
            ui.fillRect(rect, color: Self.panel.mixed(with: .white, 0.12), radii: UICornerRadii(radius))
            ui.strokeRect(rect, color: Self.warm, width: 1.5, radii: UICornerRadii(radius))
        }
        ui.fillRect(at(876, 412, 368, 28), color: Self.green, radii: UICornerRadii(14))
        ui.fillRect(at(876, 412, 368 * 0.62, 28), color: Self.accent, radii: UICornerRadii(14))

        // Clipping: nested clips intersect; shapes bleed across and are cut at the scissor edges.
        section(20, 480, 400, 220)
        let outer = at(36, 496, 200, 120)
        ui.fillRect(outer, color: .white.withAlpha(0.06))
        ui.pushClip(outer)
        ui.fillRect(at(16, 480, 120, 90), fill: .linearGradient(start: Self.accent, end: Self.green, angle: 0.8), radii: UICornerRadii(24))
        let inner = at(120, 540, 200, 100)
        ui.pushClip(inner)
        ui.fillRect(at(100, 520, 160, 140), color: Self.red.withAlpha(0.85), radii: UICornerRadii(40))
        ui.strokeRect(at(100, 520, 160, 140), color: .white, width: 4, radii: UICornerRadii(40))
        ui.popClip()
        ui.drawLine(from: Vec2(origin.x + 30, origin.y + 600), to: Vec2(origin.x + 260, origin.y + 500), width: 3, color: Self.warm)
        ui.popClip()
        ui.strokeRect(outer, color: .white.withAlpha(0.5), width: 1)
        ui.strokeRect(inner.intersection(outer) ?? inner, color: Self.green.withAlpha(0.7), width: 1)

        // A clipped scrolling list: rows mix rects and images (a batching mix: texture-less
        // items join the image batch), and the clip rejects rows outside the viewport.
        let list = at(256, 496, 148, 188)
        ui.fillRect(list, color: .black.withAlpha(0.35), radii: UICornerRadii(8))
        ui.pushClip(list)
        let scroll = (time * 20).truncatingRemainder(dividingBy: 40)
        for i in -1..<6 {
            let row = UIRect(x: list.x + 6, y: list.y + 6 + Float(i) * 40 - scroll, width: 136, height: 34)
            ui.fillRect(row, color: Self.panel.mixed(with: .white, i % 2 == 0 ? 0.14 : 0.08), radii: UICornerRadii(6))
            ui.drawImage(tiles, in: UIRect(x: row.x + 4, y: row.y + 4, width: 26, height: 26), radii: UICornerRadii(13),
                         sampler: trilinear)
            ui.fillRect(UIRect(x: row.x + 38, y: row.y + 9, width: 60 + Float(i * 9 % 30), height: 6), color: .white.withAlpha(0.7),
                        radii: UICornerRadii(3))
            ui.fillRect(UIRect(x: row.x + 38, y: row.y + 21, width: 40, height: 5), color: .white.withAlpha(0.3), radii: UICornerRadii(2.5))
        }
        ui.popClip()
        ui.strokeRect(list, color: Self.line, width: 1, radii: UICornerRadii(8))

        // Clipped stripes at fractional positions, and a clip pushed back to the same rect
        // (the batcher merges those draws).
        section(440, 480, 400, 220)
        let stripes = at(456, 496, 368, 60)
        ui.pushClip(stripes)
        for i in 0..<30 {
            let x = stripes.x - 20 + Float(i) * 14 + (time * 10).truncatingRemainder(dividingBy: 14)
            ui.drawLine(from: Vec2(x, stripes.y + 70), to: Vec2(x + 40, stripes.y - 10), width: 6,
                        color: i % 2 == 0 ? Self.warm : Self.accent)
        }
        ui.popClip()
        ui.withClip(at(456, 572, 176, 112)) {
            ui.fillRect(at(440, 560, 100, 100), color: Self.green, radii: UICornerRadii(24))
            ui.drawImage(tiles, in: at(520, 600, 150, 150), radii: UICornerRadii(75), sampler: trilinear)
        }
        ui.withClip(at(648, 572, 176, 112)) {
            ui.fillRect(at(640, 560, 100, 100), color: Self.red, radii: UICornerRadii(24))
            ui.strokeRect(at(700, 600, 200, 100), color: .white, width: 3, radii: UICornerRadii(24))
        }

        // Retina-independent hairlines and tiny shapes.
        section(860, 480, 400, 220)
        for i in 0..<8 {
            let size = 2 + Float(i) * 2
            ui.fillRect(at(876 + Float(i) * 46, 496, size, size), color: Self.warm, radii: UICornerRadii(size / 2))
            ui.strokeRect(at(876 + Float(i) * 46, 530, size + 4, size + 4), color: Self.green, width: 1, radii: UICornerRadii(size / 4))
        }
        ui.fillRect(at(876, 580, 368, 100), fill: .linearGradient(start: UIColor(hex: 0x141e30), end: UIColor(hex: 0x35577d)),
                    radii: UICornerRadii(topLeft: 8, topRight: 32, bottomRight: 8, bottomLeft: 32))
        ui.strokeRect(at(876, 580, 368, 100), color: .white.withAlpha(0.5), width: 1,
                      radii: UICornerRadii(topLeft: 8, topRight: 32, bottomRight: 8, bottomLeft: 32))
    }

    /// 8-pixel cells in two colors with a darker diagonal and a bright frame, so mapping, UV
    /// rectangles, filtering and tint are all easy to see. Integer math only.
    private static func tilePixels(size: Int) -> [UInt8] {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let checker = (x / 8 + y / 8) % 2 == 0
                var color: (Int, Int, Int) = checker ? (236, 196, 64) : (48, 96, 206)
                if x == y || x + y == size - 1 { color = (color.0 * 6 / 10, color.1 * 6 / 10, color.2 * 6 / 10) }
                if x < 2 || y < 2 || x >= size - 2 || y >= size - 2 { color = (240, 240, 244) }
                let i = (y * size + x) * 4
                pixels[i] = UInt8(color.0)
                pixels[i + 1] = UInt8(color.1)
                pixels[i + 2] = UInt8(color.2)
            }
        }
        return pixels
    }
}
