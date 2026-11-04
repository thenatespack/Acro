import Foundation
import Testing
@testable import EditorCore
import Engine

// The editor's app icon (EditorAppIcon): drawn in code, so check its shape.
// EDITOR_ICON_PNG=<file> writes it out to look at.

@Test func appIconIsATileWithTransparentCorners() throws {
    let size = 256
    let icon = EditorAppIcon.image(size: size)
    #expect(icon.width == size && icon.height == size)
    func pixel(_ x: Int, _ y: Int) -> ArraySlice<UInt8> { icon.pixels[(y * size + x) * 4 ..< (y * size + x) * 4 + 4] }
    // Outside the macOS icon grid's tile: transparent.
    #expect(pixel(0, 0).last == 0)
    #expect(pixel(size - 1, 0).last == 0)
    // Inside the tile and on the cube: opaque.
    #expect(pixel(size / 2, size / 8).last == 255)
    #expect(pixel(size / 2, size / 2).last == 255)
    // The cube's top face (warm) is brighter in red than the tile's blue.
    let topFace = pixel(size / 2, size * 40 / 100)
    let tile = pixel(size / 2, size / 8)
    #expect(topFace[topFace.startIndex] > 200 && tile[tile.startIndex] < 100)
    if let path = ProcessInfo.processInfo.environment["EDITOR_ICON_PNG"] {
        try EditorAppIcon.image(size: 512).writePNG(to: URL(fileURLWithPath: path))
    }
}
