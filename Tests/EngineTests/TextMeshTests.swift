import Foundation
import Testing
@testable import Engine

@Test func textMeshRoundTripsThroughJSON() throws {
    let mesh = TextMesh("Open\nNow", font: "Fonts/neon.ttf#1", size: 2, alignment: .right, verticalAlignment: .bottom,
                        lineSpacing: 1.2, maxWidth: 6, color: Vec3(1, 0.5, 0), emissiveStrength: 4, opacity: 0.8,
                        outlineWidth: 0.05, glowSize: 0.1, glowStrength: 2, doubleSided: true, billboard: true, isVisible: false)
    let data = try JSONEncoder().encode(mesh)
    #expect(try JSONDecoder().decode(TextMesh.self, from: data) == mesh)
}

@Test func textMeshDecodesMissingFieldsAsDefaults() throws {
    let mesh = try JSONDecoder().decode(TextMesh.self, from: Data(#"{"text": "Hi", "alignment": "left"}"#.utf8))
    var expected = TextMesh("Hi")
    expected.alignment = .left
    #expect(mesh == expected)
}

@MainActor @Test func textMeshIsARegisteredComponent() throws {
    TextMeshComponents.registerComponents()
    #expect(ComponentRegistry.type(named: "TextMesh") == TextMesh.self)
    let world = World()
    _ = world.spawn(Transform(), TextMesh("Neon", emissiveStrength: 4))
    let loaded = World()
    _ = try loaded.load(try world.save())
    var found: [TextMesh] = []
    loaded.query(TextMesh.self) { _, mesh in found.append(mesh) }
    #expect(found == [TextMesh("Neon", emissiveStrength: 4)])
}

@Test func textEscapeBecomesALineBreak() {
    #expect(TextMeshGeometry.expandedText("a\\nb") == "a\nb")
}

@MainActor @Test func geometryHasSixVerticesPerVisibleGlyphAndAlignsTheBox() throws {
    let font = try Font.bundledUI()
    let atlas = GlyphAtlas()
    let centered = TextMeshGeometry(TextMesh("Hello", size: 2), font: font, atlas: atlas)
    #expect(centered.glyphCount == 5)
    #expect(centered.vertices.reduce(0) { $0 + $1.count } == 30)
    #expect(abs(centered.boxMin.x + centered.boxMax.x) < 1e-4 && abs(centered.boxMin.y + centered.boxMax.y) < 1e-4)
    #expect(centered.boxSize.x > 0 && centered.boxSize.y > 0)

    let left = TextMeshGeometry(TextMesh("Hello", size: 2, alignment: .left, verticalAlignment: .top), font: font, atlas: atlas)
    #expect(left.boxMin.x == 0 && left.boxMax.y == 0)
    let right = TextMeshGeometry(TextMesh("Hello", size: 2, alignment: .right, verticalAlignment: .bottom), font: font, atlas: atlas)
    #expect(right.boxMax.x == 0 && right.boxMin.y == 0)
    #expect(abs(left.boxSize.x - right.boxSize.x) < 1e-4)

    // Spaces make no quads; a second line doubles the height; size scales everything.
    #expect(TextMeshGeometry(TextMesh("a b", size: 1), font: font, atlas: atlas).glyphCount == 2)
    let one = TextMeshGeometry(TextMesh("Hi", size: 1), font: font, atlas: atlas)
    let two = TextMeshGeometry(TextMesh("Hi\\nHi", size: 1), font: font, atlas: atlas)
    #expect(two.glyphCount == 4 && abs(two.boxSize.y - 2 * one.boxSize.y) < 1e-3)
    let big = TextMeshGeometry(TextMesh("Hi", size: 3), font: font, atlas: atlas)
    #expect(abs(big.boxSize.x - 3 * one.boxSize.x) < 1e-3)
}

@MainActor @Test func maxWidthWrapsWords() throws {
    let font = try Font.bundledUI()
    let atlas = GlyphAtlas()
    let wrapped = TextMeshGeometry(TextMesh("one two three four", size: 1, maxWidth: 3), font: font, atlas: atlas)
    let single = TextMeshGeometry(TextMesh("one two three four", size: 1), font: font, atlas: atlas)
    #expect(wrapped.boxSize.x == 3)
    #expect(wrapped.boxSize.y > single.boxSize.y)
}

@MainActor @Test func unloadableFontSpecIsNil() {
    #expect(WorldTextRenderer.loadFont("/nonexistent/font.ttf", assets: nil) == nil)
    #expect(WorldTextRenderer.loadFont("nope.ttf#2", assets: nil) == nil)
}

@Test func fontIndexOutOfRangeThrows() throws {
    let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources/Engine/Fonts/Inter-Regular.ttf")
    let bytes = [UInt8](try Data(contentsOf: url))
    #expect(throws: FontError.self) { try Font(data: bytes, index: 5) }
    _ = try Font(data: bytes, index: 0)
}
