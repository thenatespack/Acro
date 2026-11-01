import Foundation

/// Where a `TextMesh`'s box sits on its entity vertically (horizontally: `TextAlignment`).
public enum TextVerticalAlignment: String, Codable, Sendable, CaseIterable {
    /// The entity's origin is the top of the first line.
    case top
    case middle
    /// The origin is the bottom of the last line.
    case bottom
}

/// Text in the 3D world: signed-distance-field glyph quads in the entity's local XY plane (facing
/// +Z, reading left to right, y up), drawn by `SceneRenderer` after the transparent meshes in the
/// scene pass (depth tested, not depth written, sorted back to front with the other text,
/// fogged like meshes). Plain data: change any field at runtime. An entity without a
/// `TextMesh` costs nothing, and a world without any makes no text renderer at all.
///
/// - `text`: lines break at `\n` (the two characters backslash, n work too, for the inspector's
///   one-line field). With `maxWidth` > 0 words wrap at that many world units.
/// - `font`: "" is the bundled Inter. Otherwise a font file (`.ttf` / `.otf` with glyf or CFF
///   outlines / `.ttc`, a collection's first font, or `path#n` for font n): an absolute path, a path
///   relative to the project's `Assets` folder or its root, or an asset reference
///   (`asset:<id>`) to a font file in the project. Glyphs are rasterized into a shared atlas
///   the first time any text uses them, per font, so any script the font covers works (kanji);
///   a font that fails to load is reported once and Inter is used. Glyphs the font lacks draw
///   as its `.notdef`; there is no shaping (see `Font`).
/// - `size`: world units per em.
/// - Color: `color` (linear, unlit) plus `emissiveColor * emissiveStrength` added in HDR, so a
///   strength above 1 blooms like neon. `opacity` multiplies the alpha.
/// - `outlineWidth` (em, up to 0.12) draws `outlineColor` around the glyphs; `glowSize` (em, up to
///   0.12) adds a soft halo of the emissive color (the color when it has no emission) times
///   `glowStrength` hugging the glyphs.
/// - `doubleSided` false hides the text when seen from behind (the -Z side), true shows it
///   mirrored. `billboard` turns the text to face the camera (entity scale still applies).
public struct TextMesh: Component, Codable, Equatable, Sendable {
    public static let componentName = "TextMesh"
    /// Largest outline / glow distance in em (the atlas keeps 0.125 em of distance field).
    public static let maxEffectSize: Float = 0.12

    public static var fieldHints: [String: FieldHints] {
        ["text": FieldHints(tooltip: "Use \\n for a new line"),
         "font": FieldHints(tooltip: "Empty: bundled Inter. Else a .ttf / .otf / .ttc path (absolute, or relative to Assets or the project), or asset:<id>"),
         "size": FieldHints(range: 0.001...1000, step: 0.01, tooltip: "World units per em"),
         "lineSpacing": FieldHints(range: 0.1...5, step: 0.01),
         "maxWidth": FieldHints(range: 0...10_000, step: 0.1, tooltip: "Wrap width in world units (0: only explicit new lines)"),
         "color": FieldHints(color: true), "emissiveColor": FieldHints(color: true),
         "emissiveStrength": FieldHints(range: 0...1000, step: 0.1, tooltip: "HDR multiplier of the emissive color: above 1 glows with bloom"),
         "opacity": FieldHints(range: 0...1, step: 0.01),
         "outlineWidth": FieldHints(range: 0...Double(maxEffectSize), step: 0.001, tooltip: "Outline thickness in em"),
         "outlineColor": FieldHints(color: true),
         "glowSize": FieldHints(range: 0...Double(maxEffectSize), step: 0.001, tooltip: "Halo around the glyphs in em"),
         "glowStrength": FieldHints(range: 0...1000, step: 0.1, tooltip: "HDR multiplier of the halo's color"),
         "doubleSided": FieldHints(tooltip: "Show the text from behind (mirrored)"),
         "billboard": FieldHints(tooltip: "Face the camera")]
    }

    public var text: String
    public var font: String
    public var size: Float
    public var alignment: TextAlignment
    public var verticalAlignment: TextVerticalAlignment
    public var lineSpacing: Float
    public var maxWidth: Float
    public var color: Vec3
    public var emissiveColor: Vec3
    public var emissiveStrength: Float
    public var opacity: Float
    public var outlineWidth: Float
    public var outlineColor: Vec3
    public var glowSize: Float
    public var glowStrength: Float
    public var doubleSided: Bool
    public var billboard: Bool
    public var isVisible: Bool

    public init(_ text: String = "Text", font: String = "", size: Float = 1, alignment: TextAlignment = .center,
                verticalAlignment: TextVerticalAlignment = .middle, lineSpacing: Float = 1, maxWidth: Float = 0,
                color: Vec3 = Vec3(1, 1, 1), emissiveColor: Vec3 = Vec3(1, 1, 1), emissiveStrength: Float = 0,
                opacity: Float = 1, outlineWidth: Float = 0, outlineColor: Vec3 = Vec3(0, 0, 0), glowSize: Float = 0,
                glowStrength: Float = 1, doubleSided: Bool = false, billboard: Bool = false, isVisible: Bool = true) {
        self.text = text
        self.font = font
        self.size = size
        self.alignment = alignment
        self.verticalAlignment = verticalAlignment
        self.lineSpacing = lineSpacing
        self.maxWidth = maxWidth
        self.color = color
        self.emissiveColor = emissiveColor
        self.emissiveStrength = emissiveStrength
        self.opacity = opacity
        self.outlineWidth = outlineWidth
        self.outlineColor = outlineColor
        self.glowSize = glowSize
        self.glowStrength = glowStrength
        self.doubleSided = doubleSided
        self.billboard = billboard
        self.isVisible = isVisible
    }

    /// Missing fields take their defaults, so files from older versions keep loading.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = TextMesh()
        func value<T: Decodable>(_ key: CodingKeys, _ fallback: T) throws -> T { try c.decodeIfPresent(T.self, forKey: key) ?? fallback }
        text = try value(.text, d.text)
        font = try value(.font, d.font)
        size = try value(.size, d.size)
        alignment = try value(.alignment, d.alignment)
        verticalAlignment = try value(.verticalAlignment, d.verticalAlignment)
        lineSpacing = try value(.lineSpacing, d.lineSpacing)
        maxWidth = try value(.maxWidth, d.maxWidth)
        color = try value(.color, d.color)
        emissiveColor = try value(.emissiveColor, d.emissiveColor)
        emissiveStrength = try value(.emissiveStrength, d.emissiveStrength)
        opacity = try value(.opacity, d.opacity)
        outlineWidth = try value(.outlineWidth, d.outlineWidth)
        outlineColor = try value(.outlineColor, d.outlineColor)
        glowSize = try value(.glowSize, d.glowSize)
        glowStrength = try value(.glowStrength, d.glowStrength)
        doubleSided = try value(.doubleSided, d.doubleSided)
        billboard = try value(.billboard, d.billboard)
        isVisible = try value(.isVisible, d.isVisible)
    }
}

/// Registers `TextMesh` with `ComponentRegistry` (needed before loading scene files that use it).
public enum TextMeshComponents {
    @MainActor public static func registerComponents() { ComponentRegistry.register(TextMesh.self) }
}

/// One corner of a world-text glyph quad: a position in the entity's local XY plane and an atlas UV.
public struct WorldTextVertex: Sendable, BitwiseCopyable {
    public var position: Vec2
    public var uv: Vec2
}

/// The glyph quads of a `TextMesh`, in local units, grouped by atlas page (6 vertices per glyph).
/// Built on the CPU from a `TextLayout`; rasterizes glyphs into `atlas` as needed.
public struct TextMeshGeometry {
    /// Vertices by atlas page (empty pages for pages other fonts' glyphs use).
    public var vertices: [[WorldTextVertex]] = []
    /// The text box in local units: `boxMin` the bottom-left, `boxMax` the top-right corner.
    public var boxMin = Vec2.zero
    public var boxMax = Vec2.zero
    public var glyphCount = 0

    public var boxSize: Vec2 { boxMax - boxMin }

    /// The text with the escape `\n` turned into a line break.
    public static func expandedText(_ text: String) -> String {
        text.replacingOccurrences(of: "\\n", with: "\n")
    }

    @MainActor
    public init(_ mesh: TextMesh, font: Font, atlas: GlyphAtlas) {
        let size = max(mesh.size, 0.0001)
        let layout = TextLayout(Self.expandedText(mesh.text), font: font, size: size,
                                maxWidth: mesh.maxWidth > 0 ? mesh.maxWidth : nil, alignment: mesh.alignment,
                                lineSpacing: mesh.lineSpacing)
        let width = mesh.maxWidth > 0 ? mesh.maxWidth : layout.width
        let height = layout.height
        let left: Float = switch mesh.alignment {
        case .left: 0
        case .center: -width / 2
        case .right: -width
        }
        let top: Float = switch mesh.verticalAlignment {
        case .top: 0
        case .middle: height / 2
        case .bottom: height
        }
        boxMin = Vec2(left, top - height)
        boxMax = Vec2(left + width, top)
        for placed in layout.glyphs {
            guard let info = atlas.info(for: placed.glyph, in: font) else { continue }
            let x0 = left + placed.x + info.offset.x * size, y0 = top - (placed.y + info.offset.y * size)
            let x1 = x0 + info.extent.x * size, y1 = y0 - info.extent.y * size
            while vertices.count <= info.page { vertices.append([]) }
            let a = WorldTextVertex(position: Vec2(x0, y0), uv: Vec2(info.uvMin.x, info.uvMin.y))
            let b = WorldTextVertex(position: Vec2(x1, y0), uv: Vec2(info.uvMax.x, info.uvMin.y))
            let c = WorldTextVertex(position: Vec2(x1, y1), uv: Vec2(info.uvMax.x, info.uvMax.y))
            let d = WorldTextVertex(position: Vec2(x0, y1), uv: Vec2(info.uvMin.x, info.uvMax.y))
            vertices[info.page].append(contentsOf: [a, b, c, a, c, d])
            glyphCount += 1
        }
    }
}
