/// Packs rectangles into a fixed-size page in horizontal shelves: each rectangle goes on the
/// shortest existing shelf that is tall enough and has room (a shelf is a row as tall as its
/// first rectangle), otherwise a new shelf is opened below the last. Simple and fast, with a
/// little wasted height when sizes within a shelf vary. Nothing is ever freed.
public struct ShelfPacker {
    public let width: Int
    public let height: Int
    private struct Shelf {
        var y: Int
        var height: Int
        var used = 0
    }
    private var shelves: [Shelf] = []
    private var nextY = 0

    public init(width: Int, height: Int) {
        precondition(width > 0 && height > 0, "Page size must be positive")
        self.width = width
        self.height = height
    }

    /// The top-left of a free `width` x `height` rectangle, or nil when it doesn't fit.
    public mutating func pack(width w: Int, height h: Int) -> (x: Int, y: Int)? {
        guard w > 0, h > 0, w <= width, h <= height else { return nil }
        var best: Int?
        for (i, shelf) in shelves.enumerated() where shelf.height >= h && width - shelf.used >= w {
            if best == nil || shelf.height < shelves[best!].height { best = i }
        }
        if let i = best {
            let origin = (x: shelves[i].used, y: shelves[i].y)
            shelves[i].used += w
            return origin
        }
        guard nextY + h <= height else { return nil }
        shelves.append(Shelf(y: nextY, height: h, used: w))
        nextY += h
        return (0, nextY - h)
    }

    /// Fraction of the page covered by packed rectangles' shelf area (for diagnostics).
    public var fill: Float {
        Float(shelves.reduce(0) { $0 + $1.used * $1.height }) / Float(width * height)
    }
}
