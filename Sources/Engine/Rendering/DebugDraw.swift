import Foundation

/// Immediate-mode 3D debug drawing: lines, boxes, spheres, arrows, axes, frusta, a ground grid
/// and text labels, drawn by `DebugDrawRenderer` into whatever view renders them (the scene
/// pass via `SceneRenderer.draw`, or any `SceneRenderer.renderView` target).
///
/// Every shape becomes line segments, kept in two batches (depth-tested, and always on top) that
/// are drawn with one instanced draw each. Lines are quads expanded in screen space, so their
/// width is in pixels of the target by default (`DebugStyle.width`), or in world units
/// (`DebugStyle.worldWidth`), with antialiased edges. Colors are linear RGBA, like `Material`.
///
/// Lifetime: shapes added with `duration: 0` (the default) are drawn in the frame they were
/// added in; longer durations keep them for that many seconds. `engine.debugDraw` is aged by the
/// engine before `Game.update`; own instances call `beginFrame(dt:)` themselves. `grid` is a
/// setting and stays until changed.
///
/// Debug geometry writes no depth and no motion vectors, so it doesn't occlude the scene and
/// temporal upscalers treat it as part of whatever is behind it.
public final class DebugDraw {
    /// Width and depth mode of a shape's lines.
    public struct Style: Sendable, Equatable {
        /// Line width in pixels, or in world units with `worldWidth`.
        public var width: Float
        /// Measure `width` in world units (lines get thinner with distance).
        public var worldWidth: Bool
        public var depth: DebugDepth

        public init(width: Float = 1.5, worldWidth: Bool = false, depth: DebugDepth = .tested) {
            self.width = width
            self.worldWidth = worldWidth
            self.depth = depth
        }

        public static let `default` = Style()
        public static let onTop = Style(depth: .onTop)
    }

    /// A text label anchored at a world position (always on top, centered on the point).
    public struct Label: Sendable, Equatable {
        public var text: String
        public var position: Vec3
        public var color: Vec4
        /// Em size in pixels.
        public var size: Float
    }

    /// Segments per depth mode, in the order added (the GPU instance data).
    public private(set) var segments: [DebugDepth: [DebugSegment]] = [.tested: [], .onTop: []]
    public private(set) var labels: [Label] = []
    /// The ground grid drawn under the debug lines, if any.
    public var grid: DebugGrid?
    /// Segments used for circles and spheres when no count is given.
    public var circleSegments = 32

    /// Seconds left per segment / label, parallel to `segments` and `labels`.
    private var segmentLife: [DebugDepth: [Float]] = [.tested: [], .onTop: []]
    private var labelLife: [Float] = []

    public init() {}

    /// Whether there is nothing to draw.
    public var isEmpty: Bool { grid == nil && labels.isEmpty && segments.values.allSatisfy(\.isEmpty) }
    public var segmentCount: Int { segments.values.reduce(0) { $0 + $1.count } }

    /// Ages everything by `dt` seconds and drops what has expired (everything added with
    /// duration 0). Call once per frame before adding that frame's shapes.
    public func beginFrame(dt: Float) {
        for depth in DebugDepth.allCases {
            Self.age(&segments[depth, default: []], &segmentLife[depth, default: []], dt: dt)
        }
        Self.age(&labels, &labelLife, dt: dt)
    }

    /// Removes every shape and label (the grid stays).
    public func removeAll() {
        for depth in DebugDepth.allCases {
            segments[depth]?.removeAll(keepingCapacity: true)
            segmentLife[depth]?.removeAll(keepingCapacity: true)
        }
        labels.removeAll(keepingCapacity: true)
        labelLife.removeAll(keepingCapacity: true)
    }

    private static func age<T>(_ items: inout [T], _ life: inout [Float], dt: Float) {
        var kept = 0
        for i in life.indices {
            let remaining = life[i] - dt
            guard remaining > 0 else { continue }
            items[kept] = items[i]
            life[kept] = remaining
            kept += 1
        }
        items.removeSubrange(kept...)
        life.removeSubrange(kept...)
    }

    // MARK: - Shapes

    public func line(_ a: Vec3, _ b: Vec3, color: Vec4, style: Style = .default, duration: Float = 0) {
        let width = style.worldWidth ? -abs(style.width) : max(style.width, 0)
        segments[style.depth, default: []].append(DebugSegment(start: Vec4(a, width), end: Vec4(b, 0), color: color))
        segmentLife[style.depth, default: []].append(max(duration, 0))
    }

    /// Lines through `points`, back to the first one when `closed`.
    public func polyline(_ points: [Vec3], closed: Bool = false, color: Vec4, style: Style = .default, duration: Float = 0) {
        guard points.count > 1 else { return }
        for i in 1..<points.count { line(points[i - 1], points[i], color: color, style: style, duration: duration) }
        if closed && points.count > 2 { line(points[points.count - 1], points[0], color: color, style: style, duration: duration) }
    }

    /// An axis-aligned box (12 edges).
    public func box(_ bounds: Bounds, color: Vec4, style: Style = .default, duration: Float = 0) {
        box(Mat4.translation(bounds.center) * Mat4.scale(bounds.halfExtent), color: color, style: style, duration: duration)
    }

    /// An oriented box: the cube from -1 to 1 transformed by `transform` (e.g. a model matrix
    /// times the mesh bounds' half extent).
    public func box(_ transform: Mat4, color: Vec4, style: Style = .default, duration: Float = 0) {
        let corners = (0..<8).map { i in
            Self.transform(transform, Vec3(i & 1 == 0 ? -1 : 1, i & 2 == 0 ? -1 : 1, i & 4 == 0 ? -1 : 1))
        }
        boxEdges(corners, color: color, style: style, duration: duration)
    }

    /// An oriented box from its center, half extents and rotation.
    public func box(center: Vec3, halfExtent: Vec3, rotation: Quat, color: Vec4, style: Style = .default, duration: Float = 0) {
        box(Mat4(translation: center, rotation: rotation, scale: halfExtent), color: color, style: style, duration: duration)
    }

    /// The 12 edges between 8 corners indexed by bits (x: 1, y: 2, z: 4).
    private func boxEdges(_ corners: [Vec3], color: Vec4, style: Style, duration: Float) {
        for i in 0..<8 {
            for bit in [1, 2, 4] where i & bit == 0 {
                line(corners[i], corners[i | bit], color: color, style: style, duration: duration)
            }
        }
    }

    /// A circle around `normal`.
    public func circle(center: Vec3, normal: Vec3, radius: Float, color: Vec4, segments count: Int? = nil,
                       style: Style = .default, duration: Float = 0) {
        let (u, v) = Self.basis(normal)
        let n = max(count ?? circleSegments, 3)
        let points = (0..<n).map { i -> Vec3 in
            let angle = Float(i) / Float(n) * 2 * .pi
            return center + (u * cosf(angle) + v * sinf(angle)) * radius
        }
        polyline(points, closed: true, color: color, style: style, duration: duration)
    }

    /// A wire sphere: three circles around the x, y and z axes.
    public func sphere(center: Vec3, radius: Float, color: Vec4, segments count: Int? = nil,
                       style: Style = .default, duration: Float = 0) {
        for axis in [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)] {
            circle(center: center, normal: axis, radius: radius, color: color, segments: count, style: style, duration: duration)
        }
    }

    /// A line from `start` to `end` with a four-line head of length `headSize` (default: a
    /// fifth of the arrow, at most 0.5).
    public func arrow(from start: Vec3, to end: Vec3, color: Vec4, headSize: Float? = nil,
                      style: Style = .default, duration: Float = 0) {
        line(start, end, color: color, style: style, duration: duration)
        let d = end - start
        let length = Swift.max(dot(d, d).squareRoot(), 1e-6)
        let direction = d / length
        let head = headSize ?? Swift.min(length * 0.2, 0.5)
        let (u, v) = Self.basis(direction)
        let base = end - direction * head
        for side in [u, v, -u, -v] {
            line(end, base + side * (head * 0.35), color: color, style: style, duration: duration)
        }
    }

    /// The x (red), y (green) and z (blue) axes of `transform`, as arrows `length` long.
    public func axes(_ transform: Mat4, length: Float = 1, style: Style = .default, duration: Float = 0) {
        let origin = Vec3(transform.c3.x, transform.c3.y, transform.c3.z)
        let columns = [transform.c0, transform.c1, transform.c2]
        let colors = [Vec4(0.9, 0.12, 0.1, 1), Vec4(0.2, 0.8, 0.1, 1), Vec4(0.1, 0.3, 1, 1)]
        for (column, color) in zip(columns, colors) {
            let axis = normalize(Vec3(column.x, column.y, column.z))
            arrow(from: origin, to: origin + axis * length, color: color, style: style, duration: duration)
        }
    }

    /// The edges of the volume a view-projection sees (e.g. another camera's frustum), from its
    /// near plane (clip z = 0) to its far plane (clip z = 1); reversed-Z works the same.
    /// `farFraction` < 1 pulls the far plane in toward the near one.
    public func frustum(viewProjection: Mat4, color: Vec4, farFraction: Float = 1, style: Style = .default, duration: Float = 0) {
        let inverse = viewProjection.inverse
        var corners = (0..<8).map { i in
            Self.project(inverse, Vec4(i & 1 == 0 ? -1 : 1, i & 2 == 0 ? -1 : 1, i & 4 == 0 ? 0 : 1, 1))
        }
        if farFraction < 1 {
            for i in 0..<4 { corners[i + 4] = corners[i] + (corners[i + 4] - corners[i]) * farFraction }
        }
        boxEdges(corners, color: color, style: style, duration: duration)
    }

    /// A text label centered on `position`, `size` pixels high, drawn on top of everything.
    public func text(_ text: String, at position: Vec3, color: Vec4 = Vec4(1, 1, 1, 1), size: Float = 14, duration: Float = 0) {
        labels.append(Label(text: text, position: position, color: color, size: size))
        labelLife.append(max(duration, 0))
    }

    // MARK: - Math

    /// Two unit vectors perpendicular to `n` and to each other.
    static func basis(_ n: Vec3) -> (Vec3, Vec3) {
        let n = normalize(n)
        let helper = abs(n.y) < 0.99 ? Vec3(0, 1, 0) : Vec3(1, 0, 0)
        let u = normalize(cross(helper, n))
        return (u, cross(n, u))
    }

    static func transform(_ m: Mat4, _ p: Vec3) -> Vec3 {
        let r = m * Vec4(p, 1)
        return Vec3(r.x, r.y, r.z)
    }

    static func project(_ m: Mat4, _ p: Vec4) -> Vec3 {
        let r = m * p
        return Vec3(r.x, r.y, r.z) / r.w
    }
}

/// Whether debug lines are hidden behind scene geometry.
public enum DebugDepth: Hashable, Sendable, CaseIterable {
    /// Depth-tested against the scene (not written).
    case tested
    /// Drawn over everything.
    case onTop
}

/// One debug line, the per-instance data of the debug line shader (48 bytes).
public struct DebugSegment: Equatable, Sendable, BitwiseCopyable {
    /// xyz: start; w: width in pixels, or minus the width in world units.
    public var start: Vec4
    /// xyz: end; w: unused.
    public var end: Vec4
    /// Linear RGBA.
    public var color: Vec4

    public init(start: Vec4, end: Vec4, color: Vec4) {
        self.start = start
        self.end = end
        self.color = color
    }

    static let layout = VertexLayout(
        stride: MemoryLayout<DebugSegment>.stride,
        attributes: (0..<3).map { VertexAttribute(location: $0, format: .float4, offset: $0 * MemoryLayout<Vec4>.stride) })
}

/// A shader-drawn ground grid on the plane y = `height`: minor lines every `spacing`, major
/// lines every `majorEvery` cells, the world x axis (z = 0) and z axis (x = 0) in their own
/// colors, faded out with distance from the camera and where cells get smaller than a few
/// pixels. Depth-tested; raise `height` slightly above a floor to avoid z-fighting.
public struct DebugGrid: Sendable, Equatable {
    public var height: Float
    public var spacing: Float
    public var majorEvery: Int
    /// Distance from the camera (along the plane) where the grid has faded out completely.
    public var fadeDistance: Float
    /// Line width in pixels.
    public var lineWidth: Float
    /// Linear RGBA colors.
    public var minorColor: Vec4
    public var majorColor: Vec4
    public var xAxisColor: Vec4
    public var zAxisColor: Vec4

    public init(height: Float = 0, spacing: Float = 1, majorEvery: Int = 10, fadeDistance: Float = 80, lineWidth: Float = 1,
                minorColor: Vec4 = Vec4(0.5, 0.5, 0.5, 0.35), majorColor: Vec4 = Vec4(0.7, 0.7, 0.7, 0.6),
                xAxisColor: Vec4 = Vec4(0.9, 0.12, 0.1, 0.9), zAxisColor: Vec4 = Vec4(0.1, 0.3, 1, 0.9)) {
        self.height = height
        self.spacing = spacing
        self.majorEvery = majorEvery
        self.fadeDistance = fadeDistance
        self.lineWidth = lineWidth
        self.minorColor = minorColor
        self.majorColor = majorColor
        self.xAxisColor = xAxisColor
        self.zAxisColor = zAxisColor
    }
}
