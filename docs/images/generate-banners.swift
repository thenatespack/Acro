// Renders the repository banner and the social preview image (Arcade scheme: the split A in
// yellow and cyan, the monoline "acro" wordmark) with Core Graphics.
// Usage: swift docs/images/generate-banners.swift   (writes PNGs next to this file)
import AppKit

let lit = NSColor(srgbRed: 1.0, green: 0xE1 / 255, blue: 0x4D / 255, alpha: 1)        // #FFE14D
let shadow = NSColor(srgbRed: 0x22 / 255, green: 0xC7 / 255, blue: 0xF0 / 255, alpha: 1) // #22C7F0
func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: a)
}

func polygon(_ points: [(CGFloat, CGFloat)]) -> CGPath {
    let path = CGMutablePath()
    path.addLines(between: points.map { CGPoint(x: $0.0, y: $0.1) })
    path.closeSubpath()
    return path
}

/// The split A in its 512-unit design space (y down).
func drawMark(_ ctx: CGContext) {
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.setFillColor(lit.cgColor)
    ctx.addPath(polygon([(256, 86), (90, 420), (256, 420)])); ctx.fillPath()
    ctx.setFillColor(shadow.cgColor)
    ctx.addPath(polygon([(256, 86), (256, 420), (422, 420)])); ctx.fillPath()
    ctx.setBlendMode(.clear)
    ctx.addPath(polygon([(256, 230.9), (291.4, 302), (220.6, 302)])); ctx.fillPath()
    ctx.addPath(polygon([(195.8, 352), (316.2, 352), (350.5, 421), (161.5, 421)])); ctx.fillPath()
    ctx.fill(CGRect(x: 248, y: 0, width: 16, height: 512))
    ctx.setBlendMode(.normal)
    ctx.endTransparencyLayer()
}

/// The monoline "acro" with its origin at the x-height's vertical center, left edge at 0.
func drawWordmark(_ ctx: CGContext) {
    ctx.setLineWidth(32)
    ctx.setLineCap(.round)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.addEllipse(in: CGRect(x: 0, y: -58, width: 116, height: 116))
    ctx.move(to: CGPoint(x: 116, y: -58)); ctx.addLine(to: CGPoint(x: 116, y: 58))
    // c: from (259,-41) the long way round to (259,41) on a circle of radius 58.
    let cx: CGFloat = 259 - CGFloat(58.0 * 58.0 - 41.0 * 41.0).squareRoot()
    let a0 = atan2(CGFloat(-41), 259 - cx), a1 = atan2(CGFloat(41), 259 - cx)
    ctx.move(to: CGPoint(x: 259, y: -41))
    ctx.addArc(center: CGPoint(x: cx, y: 0), radius: 58, startAngle: a0, endAngle: a1, clockwise: true)
    ctx.move(to: CGPoint(x: 303, y: -58)); ctx.addLine(to: CGPoint(x: 303, y: 58))
    ctx.move(to: CGPoint(x: 303, y: -2)); ctx.addQuadCurve(to: CGPoint(x: 361, y: -58), control: CGPoint(x: 307, y: -58))
    ctx.strokePath()
    ctx.setStrokeColor(shadow.cgColor)
    ctx.addEllipse(in: CGRect(x: 405, y: -58, width: 116, height: 116))
    ctx.strokePath()
}

/// The lockup in the 1200x400 space of `split-lockup-dark.svg`: the A at (70,70) scale 0.52,
/// the wordmark at (400,222). Its ink spans x 117...937, y 114...296.
let lockupInk = CGRect(x: 116.8, y: 114.7, width: 937 - 116.8, height: 296 - 114.7)
func drawLockup(_ ctx: CGContext, center: CGPoint, height: CGFloat) {
    let s = height / lockupInk.height
    ctx.saveGState()
    ctx.translateBy(x: center.x - lockupInk.midX * s, y: center.y - lockupInk.midY * s)
    ctx.scaleBy(x: s, y: s)
    ctx.saveGState(); ctx.translateBy(x: 70, y: 70); ctx.scaleBy(x: 0.52, y: 0.52); drawMark(ctx); ctx.restoreGState()
    ctx.saveGState(); ctx.translateBy(x: 400, y: 222); drawWordmark(ctx); ctx.restoreGState()
    ctx.restoreGState()
}

/// Near-black gradient, a glow, and a perspective grid floor like the editor viewport's.
func drawBackground(_ ctx: CGContext, _ size: CGSize, horizon: CGFloat, glow: CGPoint) {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let bg = CGGradient(colorsSpace: space, colors: [hex(0x1E1E28).cgColor, hex(0x0A0A0F).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(bg, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])

    // Grid floor below the horizon, fading toward it.
    ctx.saveGState()
    ctx.clip(to: CGRect(x: 0, y: horizon, width: size.width, height: size.height - horizon))
    let vanish = CGPoint(x: size.width / 2, y: horizon - size.height * 0.35)
    let depth = size.height - horizon
    ctx.setLineWidth(1)
    for i in -40...40 {
        let x = size.width / 2 + CGFloat(i) * size.width / 18
        ctx.move(to: vanish); ctx.addLine(to: CGPoint(x: vanish.x + (x - vanish.x) * 3, y: vanish.y + (size.height - vanish.y) * 3))
    }
    for k in 1...14 {
        let t = pow(CGFloat(k) / 14, 2.2)
        let y = horizon + depth * t
        ctx.move(to: CGPoint(x: 0, y: y)); ctx.addLine(to: CGPoint(x: size.width, y: y))
    }
    ctx.setStrokeColor(hex(0x4A4A66, 0.55).cgColor)
    ctx.strokePath()
    // Axis lines: red/blue, as in the scene view.
    ctx.setLineWidth(1.5)
    ctx.setStrokeColor(hex(0xE0525A, 0.55).cgColor)
    ctx.move(to: CGPoint(x: 0, y: horizon + depth * 0.62)); ctx.addLine(to: CGPoint(x: size.width, y: horizon + depth * 0.62)); ctx.strokePath()
    ctx.setStrokeColor(hex(0x4C7DF0, 0.55).cgColor)
    ctx.move(to: vanish); ctx.addLine(to: CGPoint(x: vanish.x, y: size.height)); ctx.strokePath()
    // Fade the grid into the horizon.
    let fade = CGGradient(colorsSpace: space, colors: [hex(0x12121A, 1).cgColor, hex(0x0A0A0F, 0).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(fade, start: CGPoint(x: 0, y: horizon), end: CGPoint(x: 0, y: horizon + depth * 0.7), options: [])
    ctx.restoreGState()

    // Glow behind the lockup.
    let g = CGGradient(colorsSpace: space, colors: [hex(0x3A3A55, 0.55).cgColor, hex(0x3A3A55, 0).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(g, startCenter: glow, startRadius: 0, endCenter: glow, endRadius: size.width * 0.42, options: [])
}

func drawText(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, centerX: CGFloat, top: CGFloat, kern: CGFloat = 0) {
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .kern: kern])
    let bounds = string.size()
    string.draw(at: CGPoint(x: centerX - bounds.width / 2, y: top))
}

func render(_ name: String, width: Int, height: Int, _ draw: (CGContext, CGSize) -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    // y down, like the SVGs.
    let flipped = NSGraphicsContext(cgContext: context.cgContext, flipped: true)
    NSGraphicsContext.current = flipped
    let ctx = flipped.cgContext
    ctx.translateBy(x: 0, y: CGFloat(height)); ctx.scaleBy(x: 1, y: -1)
    ctx.setShouldAntialias(true)
    draw(ctx, CGSize(width: width, height: height))
    NSGraphicsContext.restoreGraphicsState()
    let url = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().appendingPathComponent(name)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
    print("wrote \(url.path)")
}

let tagline = "3D game engine and editor, written in Swift"
let platforms = "Metal  ·  Vulkan  ·  macOS  ·  Linux  ·  Windows"
let muted = hex(0xB8BCCC)

// Social preview: 1280x640 (GitHub's recommended size). Content kept inside a 40 px margin.
render("social-preview.png", width: 1280, height: 640) { ctx, size in
    drawBackground(ctx, size, horizon: 430, glow: CGPoint(x: 640, y: 250))
    drawLockup(ctx, center: CGPoint(x: 640, y: 236), height: 168)
    drawText(tagline, size: 38, weight: .medium, color: .white, centerX: 640, top: 372)
    drawText(platforms, size: 24, weight: .regular, color: muted, centerX: 640, top: 438, kern: 0.5)
}

// README banner: 1280x400 at 2x density looks sharp; drawn at 2560x800.
render("banner.png", width: 2560, height: 800) { ctx, size in
    ctx.scaleBy(x: 2, y: 2)
    let s = CGSize(width: 1280, height: 400)
    drawBackground(ctx, s, horizon: 280, glow: CGPoint(x: 640, y: 160))
    drawLockup(ctx, center: CGPoint(x: 640, y: 150), height: 136)
    drawText(tagline, size: 30, weight: .medium, color: .white, centerX: 640, top: 252)
    drawText(platforms, size: 19, weight: .regular, color: muted, centerX: 640, top: 304, kern: 0.5)
}
