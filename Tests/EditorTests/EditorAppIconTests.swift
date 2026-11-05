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
    // Inside the tile: opaque, near-black.
    let tile = pixel(size / 2, size / 8)
    #expect(tile.last == 255 && tile.dropLast().max()! < 80)
    // The split down the middle shows the tile through the A.
    #expect(pixel(size / 2, size * 55 / 100).dropLast().max()! < 100)
    // The A's left leg is the yellow lit half, its right leg the cyan shadow half.
    let left = pixel(size * 317 / 1000, size * 743 / 1000), right = pixel(size * 683 / 1000, size * 743 / 1000)
    #expect(left[left.startIndex] > 230 && left[left.startIndex + 1] > 200 && left[left.startIndex + 2] < 120)
    #expect(right[right.startIndex] < 80 && right[right.startIndex + 1] > 170 && right[right.startIndex + 2] > 210)
    if let path = ProcessInfo.processInfo.environment["EDITOR_ICON_PNG"] {
        try EditorAppIcon.image(size: 512).writePNG(to: URL(fileURLWithPath: path))
    }
}
