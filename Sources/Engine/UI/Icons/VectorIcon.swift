import Foundation

// Vector icons for the UI: line icons given as SVG markup on a square view box (24 units, the
// Lucide / Feather convention), flattened to polylines once and rasterized on demand at the
// exact pixel size they are drawn at, so they are crisp at every backing scale and zoom.
//
// `UIDrawList.drawIcon(_:in:color:)` puts the bitmap of the needed size into the list's glyph
// atlas (next to the text, so icons and text batch together) and draws it as a `.mask` quad
// tinted with any color: the same icon serves normal, disabled, selected and accent states.
//
// The built-in set is a subset of Lucide (ISC; Sources/Engine/UI/Icons/LICENSES.md), named
// as on lucide.dev: `VectorIcon.named("camera")`. Games can make their own from SVG:
// `try VectorIcon(name: "coin", svg: #"<circle cx="12" cy="12" r="8"/><path d="M12 8v8"/>"#)`.

/// A line icon: SVG elements on a square view box, stroked with round caps and joins.
///
/// Supported markup: `path` (every command: M L H V C S Q T A Z, absolute and relative),
/// `circle`, `ellipse`, `rect` (with `rx` / `ry`), `line`, `polyline` and `polygon`. Every
/// element is stroked with `strokeWidth`; an element with `fill="currentColor"` (or any fill
/// other than `none`) is also filled (non-zero winding), and `stroke="none"` leaves out its
/// outline. Transforms, styles and other attributes are ignored.
public struct VectorIcon: Hashable, @unchecked Sendable {
    /// What the icon is called (the built-in set's Lucide name, or the game's).
    public let name: String
    /// The SVG elements it was made from.
    public let svg: String
    /// The view box's edge, in SVG units (the box is `0 0 viewBox viewBox`).
    public let viewBox: Float
    /// Line width in SVG units (Lucide: 2 of 24).
    public let strokeWidth: Float
    let shape: VectorIconShape

    /// Parses `svg` (see the type's notes). Throws `VectorIconError` for markup it can't read.
    public init(name: String, svg: String, viewBox: Float = 24, strokeWidth: Float = 2) throws {
        self.name = name
        self.svg = svg
        self.viewBox = viewBox
        self.strokeWidth = strokeWidth
        shape = try VectorIconShape(svg: svg)
    }

    public static func == (a: VectorIcon, b: VectorIcon) -> Bool {
        a.name == b.name && a.svg == b.svg && a.viewBox == b.viewBox && a.strokeWidth == b.strokeWidth
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(svg)
        hasher.combine(viewBox)
        hasher.combine(strokeWidth)
    }

    /// The built-in icon called `name` (a Lucide name such as "camera", "sun", "folder-open"),
    /// or nil when the set doesn't have it. Parsed once, then cached.
    @MainActor public static func named(_ name: String) -> VectorIcon? {
        if let cached = builtinCache[name] { return cached }
        guard let svg = lucideIcons[name], let icon = try? VectorIcon(name: name, svg: svg) else { return nil }
        builtinCache[name] = icon
        return icon
    }

    /// Every built-in icon's name, sorted.
    public static var builtinNames: [String] { lucideIcons.keys.sorted() }

    @MainActor private static var builtinCache: [String: VectorIcon] = [:]

    /// The icon's coverage at `pixels` x `pixels` (row-major, top row first): 0 outside, 255
    /// on the lines. Lines are at least `minimumStrokePixels` wide, so small sizes don't fade.
    /// Coverage is the exact distance to the flattened outline, so edges are antialiased over one pixel.
    public func rasterize(pixels: Int, minimumStrokePixels: Float = 1) -> [UInt8] {
        shape.rasterize(size: pixels, scale: Float(pixels) / viewBox,
                        halfWidth: max(strokeWidth * Float(pixels) / viewBox, minimumStrokePixels) / 2)
    }
}

/// Why an icon's SVG couldn't be read.
public enum VectorIconError: Error, Equatable, CustomStringConvertible {
    /// A path's `d` attribute is malformed (a bad number or an unknown command).
    case badPath(String)
    /// Nothing drawable was found.
    case empty

    public var description: String {
        switch self {
        case .badPath(let d): "bad SVG path data: \(d.prefix(60))"
        case .empty: "no SVG elements (path, circle, ellipse, rect, line, polyline, polygon)"
        }
    }
}

/// The flattened outline of an icon, in view-box units.
final class VectorIconShape: @unchecked Sendable {
    struct Polyline {
        var points: [Vec2]
        var closed: Bool
        var stroked: Bool
        var filled: Bool
    }

    private(set) var polylines: [Polyline] = []
    /// Chord length used when flattening curves, in view-box units.
    static let flatness: Float = 0.35

    init(svg: String) throws {
        for element in Self.elements(in: svg) {
            let a = element.attributes
            func number(_ key: String, _ fallback: Float = 0) -> Float { a[key].flatMap { Float($0.trimmingCharacters(in: .whitespaces)) } ?? fallback }
            let stroked = a["stroke"] != "none"
            let filled = a["fill"].map { $0 != "none" } ?? false
            var lines: [Polyline] = []
            switch element.tag {
            case "path":
                lines = try Self.parsePath(a["d"] ?? "")
            case "circle":
                lines = [Self.ellipse(cx: number("cx"), cy: number("cy"), rx: number("r"), ry: number("r"))]
            case "ellipse":
                lines = [Self.ellipse(cx: number("cx"), cy: number("cy"), rx: number("rx"), ry: number("ry"))]
            case "line":
                lines = [Polyline(points: [Vec2(number("x1"), number("y1")), Vec2(number("x2"), number("y2"))], closed: false,
                                  stroked: true, filled: false)]
            case "polyline", "polygon":
                let values = Self.numbers(in: a["points"] ?? "")
                let points = stride(from: 0, to: values.count - 1, by: 2).map { Vec2(values[$0], values[$0 + 1]) }
                lines = [Polyline(points: points, closed: element.tag == "polygon", stroked: true, filled: false)]
            case "rect":
                let rx = a["rx"] != nil ? number("rx") : number("ry"), ry = a["ry"] != nil ? number("ry") : rx
                lines = [Self.roundedRect(x: number("x"), y: number("y"), width: number("width"), height: number("height"),
                                          rx: rx, ry: ry)]
            default:
                continue
            }
            for var line in lines where line.points.count >= 1 {
                line.stroked = stroked
                line.filled = filled
                polylines.append(line)
            }
        }
        guard !polylines.isEmpty else { throw VectorIconError.empty }
    }

    // MARK: Markup

    struct Element {
        var tag: String
        var attributes: [String: String]
    }

    /// `<tag a="1" b='2'/>` elements, in order (closing tags and groups are skipped).
    static func elements(in svg: String) -> [Element] {
        var result: [Element] = []
        var rest = Substring(svg)
        while let open = rest.firstIndex(of: "<") {
            rest = rest[rest.index(after: open)...]
            guard let close = rest.firstIndex(of: ">") else { break }
            var body = rest[..<close]
            rest = rest[rest.index(after: close)...]
            if body.hasPrefix("/") || body.hasPrefix("!") || body.hasPrefix("?") { continue }
            if body.hasSuffix("/") { body = body.dropLast() }
            let tag = String(body.prefix { !$0.isWhitespace })
            var attributes: [String: String] = [:]
            var scan = body.dropFirst(tag.count)
            while let eq = scan.firstIndex(of: "=") {
                let key = scan[..<eq].trimmingCharacters(in: .whitespacesAndNewlines)
                scan = scan[scan.index(after: eq)...].drop { $0.isWhitespace }
                guard let quote = scan.first, quote == "\"" || quote == "'" else { break }
                scan = scan.dropFirst()
                guard let end = scan.firstIndex(of: quote) else { break }
                attributes[key] = String(scan[..<end])
                scan = scan[scan.index(after: end)...]
            }
            result.append(Element(tag: tag, attributes: attributes))
        }
        return result
    }

    /// The numbers in a list such as `points="1,2 3 4"` or `-1.5.5e2`.
    static func numbers(in text: String) -> [Float] {
        var scanner = NumberScanner(Array(text.utf8))
        var values: [Float] = []
        while let value = scanner.number() { values.append(value) }
        return values
    }

    /// Reads SVG numbers ("-1.5", ".5", "1e-3", "0.5.5" = 0.5 0.5) and flags ("01" = 0 1).
    struct NumberScanner {
        let bytes: [UInt8]
        var index = 0

        init(_ bytes: [UInt8]) { self.bytes = bytes }

        mutating func skipSeparators() {
            while index < bytes.count, [0x20, 0x09, 0x0a, 0x0d, 0x2c].contains(bytes[index]) { index += 1 }
        }

        var atEnd: Bool { index >= bytes.count }
        var peek: UInt8? { index < bytes.count ? bytes[index] : nil }

        /// The next number, or nil at the end or before a command letter.
        mutating func number() -> Float? {
            skipSeparators()
            let start = index
            if index < bytes.count, bytes[index] == 0x2b || bytes[index] == 0x2d { index += 1 }  // + -
            var digits = false, dot = false
            while index < bytes.count {
                let c = bytes[index]
                if c >= 0x30 && c <= 0x39 { digits = true; index += 1 }
                else if c == 0x2e && !dot { dot = true; index += 1 }
                else { break }
            }
            if digits, index < bytes.count, bytes[index] == 0x65 || bytes[index] == 0x45 {  // e E
                var j = index + 1
                if j < bytes.count, bytes[j] == 0x2b || bytes[j] == 0x2d { j += 1 }
                if j < bytes.count, bytes[j] >= 0x30 && bytes[j] <= 0x39 {
                    index = j
                    while index < bytes.count, bytes[index] >= 0x30 && bytes[index] <= 0x39 { index += 1 }
                }
            }
            guard digits else {
                index = start
                return nil
            }
            return Float(String(decoding: bytes[start..<index], as: UTF8.self))
        }

        /// An arc flag: a single 0 or 1.
        mutating func flag() -> Bool? {
            skipSeparators()
            guard let c = peek, c == 0x30 || c == 0x31 else { return nil }
            index += 1
            return c == 0x31
        }
    }

    // MARK: Paths

    static func parsePath(_ d: String) throws -> [Polyline] {
        var scanner = NumberScanner(Array(d.utf8))
        var result: [Polyline] = []
        var current: [Vec2] = []
        var point = Vec2.zero, start = Vec2.zero
        var lastControl: Vec2?  // for S / T reflection
        var lastCommand: UInt8 = 0
        func flush(closed: Bool) {
            if current.count >= 1 { result.append(Polyline(points: current, closed: closed, stroked: true, filled: false)) }
            current = []
        }
        func lineTo(_ p: Vec2) {
            if current.isEmpty { current.append(point) }
            current.append(p)
            point = p
        }
        func need(_ value: Float?) throws -> Float {
            guard let value else { throw VectorIconError.badPath(d) }
            return value
        }
        var command: UInt8 = 0
        while true {
            scanner.skipSeparators()
            guard let c = scanner.peek else { break }
            if (c >= 0x41 && c <= 0x5a) || (c >= 0x61 && c <= 0x7a) {
                command = c
                scanner.index += 1
            } else if command == 0 {
                throw VectorIconError.badPath(d)
            }
            let relative = command >= 0x61
            let base = relative ? point : .zero
            let upper = relative ? command - 0x20 : command
            switch upper {
            case 0x4d:  // M
                let p = base + Vec2(try need(scanner.number()), try need(scanner.number()))
                flush(closed: false)
                point = p
                start = p
                current = [p]
                command = relative ? 0x6c : 0x4c  // further pairs are line-tos
                lastControl = nil
            case 0x4c:  // L
                lineTo(base + Vec2(try need(scanner.number()), try need(scanner.number())))
                lastControl = nil
            case 0x48:  // H
                lineTo(Vec2((relative ? point.x : 0) + (try need(scanner.number())), point.y))
                lastControl = nil
            case 0x56:  // V
                lineTo(Vec2(point.x, (relative ? point.y : 0) + (try need(scanner.number()))))
                lastControl = nil
            case 0x43, 0x53:  // C, S
                let c1: Vec2
                if upper == 0x43 {
                    c1 = base + Vec2(try need(scanner.number()), try need(scanner.number()))
                } else {
                    let previousWasCubic = lastCommand == 0x43 || lastCommand == 0x53
                    c1 = previousWasCubic ? point * 2 - (lastControl ?? point) : point
                }
                let c2 = base + Vec2(try need(scanner.number()), try need(scanner.number()))
                let end = base + Vec2(try need(scanner.number()), try need(scanner.number()))
                cubic(from: point, c1, c2, end).forEach(lineTo)
                lastControl = c2
            case 0x51, 0x54:  // Q, T
                let control: Vec2
                if upper == 0x51 {
                    control = base + Vec2(try need(scanner.number()), try need(scanner.number()))
                } else {
                    let previousWasQuadratic = lastCommand == 0x51 || lastCommand == 0x54
                    control = previousWasQuadratic ? point * 2 - (lastControl ?? point) : point
                }
                let end = base + Vec2(try need(scanner.number()), try need(scanner.number()))
                let c1 = point + (control - point) * (2 / 3), c2 = end + (control - end) * (2 / 3)
                cubic(from: point, c1, c2, end).forEach(lineTo)
                lastControl = control
            case 0x41:  // A
                let rx = try need(scanner.number()), ry = try need(scanner.number()), rotation = try need(scanner.number())
                guard let large = scanner.flag(), let sweep = scanner.flag() else { throw VectorIconError.badPath(d) }
                let end = base + Vec2(try need(scanner.number()), try need(scanner.number()))
                arc(from: point, to: end, rx: rx, ry: ry, rotation: rotation, large: large, sweep: sweep).forEach(lineTo)
                lastControl = nil
            case 0x5a:  // Z
                if current.count >= 2 {
                    flush(closed: true)
                } else {
                    flush(closed: false)
                }
                point = start
                current = []
                lastControl = nil
            default:
                throw VectorIconError.badPath(d)
            }
            lastCommand = upper
            // After Z only a new command may follow.
            if upper == 0x5a { command = 0 }
        }
        flush(closed: false)
        return result
    }

    /// Points along a cubic Bézier after `p0` (excluded), ending at `p3`.
    static func cubic(from p0: Vec2, _ p1: Vec2, _ p2: Vec2, _ p3: Vec2) -> [Vec2] {
        let hull = distance2(p0, p1) + distance2(p1, p2) + distance2(p2, p3)
        let n = min(max(Int((hull / flatness).rounded(.up)), 2), 96)
        return (1...n).map { i in
            let t = Float(i) / Float(n), u = 1 - t
            return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t)
        }
    }

    /// Points along an SVG elliptical arc after `p0` (excluded), ending at `p1` (SVG 1.1 F.6.5).
    static func arc(from p0: Vec2, to p1: Vec2, rx: Float, ry: Float, rotation: Float, large: Bool, sweep: Bool) -> [Vec2] {
        var rx = abs(rx), ry = abs(ry)
        guard rx > 1e-6, ry > 1e-6, p0 != p1 else { return [p1] }
        let phi = rotation * .pi / 180, cosPhi = cosf(phi), sinPhi = sinf(phi)
        let half = (p0 - p1) / 2
        let x1 = cosPhi * half.x + sinPhi * half.y, y1 = -sinPhi * half.x + cosPhi * half.y
        let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if lambda > 1 {
            rx *= lambda.squareRoot()
            ry *= lambda.squareRoot()
        }
        let numerator = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1
        var factor = denominator > 0 ? (max(numerator, 0) / denominator).squareRoot() : 0
        if large == sweep { factor = -factor }
        let cx1 = factor * rx * y1 / ry, cy1 = -factor * ry * x1 / rx
        let mid = (p0 + p1) / 2
        let center = Vec2(cosPhi * cx1 - sinPhi * cy1 + mid.x, sinPhi * cx1 + cosPhi * cy1 + mid.y)
        func angle(_ u: Vec2, _ v: Vec2) -> Float {
            let a = atan2f(u.x * v.y - u.y * v.x, u.x * v.x + u.y * v.y)
            return a
        }
        let u = Vec2((x1 - cx1) / rx, (y1 - cy1) / ry), v = Vec2((-x1 - cx1) / rx, (-y1 - cy1) / ry)
        let theta = angle(Vec2(1, 0), u)
        var delta = angle(u, v)
        if !sweep && delta > 0 { delta -= 2 * .pi }
        if sweep && delta < 0 { delta += 2 * .pi }
        let n = min(max(Int((abs(delta) * max(rx, ry) / flatness).rounded(.up)), 2), 128)
        return (1...n).map { i in
            if i == n { return p1 }
            let a = theta + delta * Float(i) / Float(n)
            let x = rx * cosf(a), y = ry * sinf(a)
            return Vec2(cosPhi * x - sinPhi * y + center.x, sinPhi * x + cosPhi * y + center.y)
        }
    }

    static func distance2(_ a: Vec2, _ b: Vec2) -> Float { ((b - a) * (b - a)).sum().squareRoot() }

    static func ellipse(cx: Float, cy: Float, rx: Float, ry: Float) -> Polyline {
        let n = min(max(Int((2 * .pi * max(rx, ry) / flatness).rounded(.up)), 12), 160)
        let points = (0..<n).map { i -> Vec2 in
            let a = 2 * Float.pi * Float(i) / Float(n)
            return Vec2(cx + rx * cosf(a), cy + ry * sinf(a))
        }
        return Polyline(points: points, closed: true, stroked: true, filled: false)
    }

    static func roundedRect(x: Float, y: Float, width: Float, height: Float, rx: Float, ry: Float) -> Polyline {
        let rx = min(max(rx, 0), width / 2), ry = min(max(ry, 0), height / 2)
        guard rx > 0, ry > 0 else {
            return Polyline(points: [Vec2(x, y), Vec2(x + width, y), Vec2(x + width, y + height), Vec2(x, y + height)],
                            closed: true, stroked: true, filled: false)
        }
        var points: [Vec2] = []
        let n = min(max(Int((Float.pi / 2 * max(rx, ry) / flatness).rounded(.up)), 2), 32)
        // Corners clockwise from the top-right, each a quarter ellipse.
        let corners: [(Vec2, Float)] = [(Vec2(x + width - rx, y + ry), -.pi / 2), (Vec2(x + width - rx, y + height - ry), 0),
                                        (Vec2(x + rx, y + height - ry), .pi / 2), (Vec2(x + rx, y + ry), .pi)]
        for (center, start) in corners {
            for i in 0...n {
                let a = start + Float.pi / 2 * Float(i) / Float(n)
                points.append(Vec2(center.x + rx * cosf(a), center.y + ry * sinf(a)))
            }
        }
        return Polyline(points: points, closed: true, stroked: true, filled: false)
    }

    // MARK: Rasterizing

    /// Coverage (0...255) of `size`² pixels; one view-box unit is `scale` pixels and strokes
    /// reach `halfWidth` pixels either side of the line.
    func rasterize(size: Int, scale: Float, halfWidth: Float) -> [UInt8] {
        guard size > 0 else { return [] }
        // Squared distance (pixels) from each pixel center to the nearest stroked segment.
        var nearest = [Float](repeating: .infinity, count: size * size)
        let reach = halfWidth + 1
        func segments(of line: Polyline, _ body: (Vec2, Vec2) -> Void) {
            let points = line.points.map { $0 * scale }
            if points.count == 1 { body(points[0], points[0]); return }
            for i in 0..<(points.count - 1) { body(points[i], points[i + 1]) }
            if line.closed, let first = points.first, let last = points.last, first != last { body(last, first) }
        }
        for line in polylines where line.stroked {
            segments(of: line) { a, b in
                let x0 = max(Int((min(a.x, b.x) - reach).rounded(.down)), 0), x1 = min(Int((max(a.x, b.x) + reach).rounded(.up)), size - 1)
                let y0 = max(Int((min(a.y, b.y) - reach).rounded(.down)), 0), y1 = min(Int((max(a.y, b.y) + reach).rounded(.up)), size - 1)
                guard x0 <= x1, y0 <= y1 else { return }
                let ab = b - a
                let lengthSquared = (ab * ab).sum()
                for y in y0...y1 {
                    for x in x0...x1 {
                        let p = Vec2(Float(x) + 0.5, Float(y) + 0.5)
                        let t = lengthSquared > 0 ? min(max(((p - a) * ab).sum() / lengthSquared, 0), 1) : 0
                        let d = p - (a + ab * t)
                        let squared = (d * d).sum()
                        if squared < nearest[y * size + x] { nearest[y * size + x] = squared }
                    }
                }
            }
        }
        var coverage = [UInt8](repeating: 0, count: size * size)
        for i in coverage.indices where nearest[i].isFinite {
            let c = min(max(halfWidth + 0.5 - nearest[i].squareRoot(), 0), 1)
            coverage[i] = UInt8((c * 255).rounded())
        }
        let fills = polylines.filter(\.filled)
        guard !fills.isEmpty else { return coverage }
        // Filled shapes: non-zero winding at each pixel center, antialiased by the distance to the edge.
        for y in 0..<size {
            for x in 0..<size {
                let p = Vec2(Float(x) + 0.5, Float(y) + 0.5)
                var winding = 0
                var edge = Float.infinity
                for line in fills {
                    let points = line.points.map { $0 * scale }
                    guard points.count >= 3 else { continue }
                    for i in points.indices {
                        let a = points[i], b = points[(i + 1) % points.count]
                        if a.y <= p.y {
                            if b.y > p.y, cross2(b - a, p - a) > 0 { winding += 1 }
                        } else if b.y <= p.y, cross2(b - a, p - a) < 0 {
                            winding -= 1
                        }
                        let ab = b - a
                        let lengthSquared = (ab * ab).sum()
                        let t = lengthSquared > 0 ? min(max(((p - a) * ab).sum() / lengthSquared, 0), 1) : 0
                        let d = p - (a + ab * t)
                        edge = min(edge, (d * d).sum())
                    }
                }
                let distance = edge.squareRoot()
                let c = min(max(winding != 0 ? 0.5 + distance : 0.5 - distance, 0), 1)
                let value = UInt8((c * 255).rounded())
                if value > coverage[y * size + x] { coverage[y * size + x] = value }
            }
        }
        return coverage
    }

    private func cross2(_ a: Vec2, _ b: Vec2) -> Float { a.x * b.y - a.y * b.x }
}
