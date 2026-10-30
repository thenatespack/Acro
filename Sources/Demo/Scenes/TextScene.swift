import Engine
import Foundation

/// SDF text rendering with the bundled font: a range of sizes, kerning pairs, a word-wrapped
/// paragraph, the three alignments, and non-ASCII Latin. Laid out in 1280x720 pixel
/// coordinates; everything is static, so the image is deterministic.
final class TextScene: DemoScene {
    static let name = "text"
    static let summary = "SDF text: sizes, kerning, word wrap, alignment, non-ASCII Latin"

    private let renderer: Renderer
    private let text: TextRenderer

    init(renderer: Renderer) throws {
        self.renderer = renderer
        text = try TextRenderer(device: renderer.device)
    }

    var lighting: Lighting { Lighting(fogColor: Vec3(0.012, 0.014, 0.02)) }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        // Design units are 1280x720; scale to the actual target.
        let scale = Float(renderer.targetSize.height) / 720
        func draw(_ string: String, at position: Vec2, size: Float, color: Vec4, maxWidth: Float? = nil,
                  alignment: TextAlignment = .left) {
            text.draw(string, at: position * scale, size: size * scale, color: color,
                      maxWidth: maxWidth.map { $0 * scale }, alignment: alignment)
        }
        let white = Vec4(1, 1, 1, 1)
        let dim = Vec4(0.45, 0.5, 0.58, 1)
        let accent = Vec4(1, 0.62, 0.2, 1)

        draw("Text rendering", at: Vec2(40, 24), size: 44, color: white)
        draw("Signed distance field glyphs, one atlas, any size", at: Vec2(40, 76), size: 16, color: dim)

        // Sizes.
        var y: Float = 112
        for size in [12, 16, 24, 32, 48] as [Float] {
            draw("Sphinx of black quartz \(Int(size))", at: Vec2(40, y), size: size, color: white)
            y += text.measure("X", size: size).y + 2
        }

        // Kerning: pairs that move closer together.
        draw("AV To Wa Ty Yo", at: Vec2(40, 360), size: 56, color: accent)
        draw("kerning: AV, To, Wa, Ty, Yo", at: Vec2(40, 428), size: 14, color: dim)

        // Non-ASCII Latin.
        draw("é ñ ü ß  Çà ø å ÿ Ž Ł", at: Vec2(40, 460), size: 40, color: white)
        draw("Crème brûlée, jalapeño, Größe, Łódź", at: Vec2(40, 516), size: 24, color: Vec4(0.55, 0.85, 1, 1))

        // Large, to show the edges holding up.
        draw("Aa&g@", at: Vec2(40, 560), size: 128, color: Vec4(0.5, 0.9, 0.55, 1))

        // Word wrap in a 520 px box.
        let paragraph = "Word wrapping breaks lines at spaces so that each one fits the box. "
            + "A very long word like Pneumonoultramicroscopicsilicovolcanoconiosis is broken between glyphs. "
            + "Explicit newlines work too:\nthis starts a new line."
        draw("Word wrap, 520 px", at: Vec2(720, 112), size: 14, color: dim)
        draw(paragraph, at: Vec2(720, 134), size: 20, color: white, maxWidth: 520)

        // Alignment within the same 520 px box.
        let blurb = "Aligned within the box, wrapped at 520 px."
        draw("Left, center, right", at: Vec2(720, 360), size: 14, color: dim)
        draw("Left\n" + blurb, at: Vec2(720, 384), size: 20, color: accent, maxWidth: 520, alignment: .left)
        draw("Center\n" + blurb, at: Vec2(720, 470), size: 20, color: accent, maxWidth: 520, alignment: .center)
        draw("Right\n" + blurb, at: Vec2(720, 556), size: 20, color: accent, maxWidth: 520, alignment: .right)

        try text.render(into: pass, screenSize: renderer.targetSize)
    }
}
