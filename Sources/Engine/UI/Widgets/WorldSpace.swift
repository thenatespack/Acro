import Foundation

// World-space UI: widgets that follow 3D positions on screen (name tags, health bars), and a
// whole UI drawn into a render target that a quad in the world shows, with the mouse mapped
// onto it through a ray hit.

/// Where a world point lands in a `ViewportProjection`.
public struct WorldScreenPoint: Sendable, Equatable {
    /// Viewport points (top-left origin).
    public var position: Vec2
    /// Distance from the camera (world units).
    public var distance: Float
    /// Clip-space w (view depth for a perspective projection).
    public var depth: Float
}

extension ViewportProjection {
    /// `world` in viewport points with its distance and depth, or nil behind the camera.
    public func screenPoint(of world: Vec3) -> WorldScreenPoint? {
        let c = clip(world)
        guard c.w > 1e-6, let position = project(world) else { return nil }
        let d = world - eye
        return WorldScreenPoint(position: position, distance: dot(d, d).squareRoot(), depth: c.w)
    }
}

/// Size and fade rules for world-anchored UI, as pure functions (for tests and immediate-mode drawing).
public enum WorldUIScaling {
    /// `reference / distance` clamped to `range`: 1 at the reference distance, smaller farther away.
    public static func scale(distance: Float, reference: Float, range: ClosedRange<Float>) -> Float {
        guard distance > 1e-4 else { return range.upperBound }
        return min(max(reference / distance, range.lowerBound), range.upperBound)
    }

    /// 1 up to `range.lowerBound`, 0 from `range.upperBound`, linear in between.
    public static func fade(distance: Float, range: ClosedRange<Float>) -> Float {
        guard range.upperBound > range.lowerBound else { return distance <= range.lowerBound ? 1 : 0 }
        return min(max((range.upperBound - distance) / (range.upperBound - range.lowerBound), 0), 1)
    }
}

/// A widget of a `WorldSpaceLayer` and the 3D point it follows.
@MainActor
public final class WorldAnchor {
    public let widget: Widget
    public var position: Vec3
    /// Which point of the widget sits on the projected position (0,0 top-left … 1,1 bottom-right;
    /// the default puts its bottom center there, above the point).
    public var pivot: Vec2
    /// Extra screen offset in points (after scaling), e.g. lift a tag above a head.
    public var screenOffset = Vec2.zero
    /// Scale 1 at this distance, `referenceDistance / distance` elsewhere within `scaleRange`. Nil keeps a constant size.
    public var referenceDistance: Float? = 10
    public var scaleRange: ClosedRange<Float> = 0.5...1.25
    /// Fully visible up to the lower bound, gone at the upper one. Nil never fades with distance.
    public var fadeDistance: ClosedRange<Float>?
    /// Set by the game (e.g. from a raycast to the camera): the widget fades to `occludedOpacity`.
    public var isOccluded = false
    public var occludedOpacity: Float = 0.3
    /// Opacity change per second when occlusion changes (0 or less: instant).
    public var occlusionFadeSpeed: Float = 6

    /// Results of the last `WorldSpaceLayer.update`: nil when behind the camera.
    public private(set) var screenPoint: WorldScreenPoint?
    public private(set) var scale: Float = 1
    public private(set) var occlusionOpacity: Float = 1

    init(widget: Widget, position: Vec3, pivot: Vec2) {
        self.widget = widget
        self.position = position
        self.pivot = pivot
    }

    fileprivate func update(projection: ViewportProjection, dt: Float) {
        let target: Float = isOccluded ? occludedOpacity : 1
        if occlusionFadeSpeed > 0, dt > 0 {
            let step = occlusionFadeSpeed * dt
            occlusionOpacity += min(max(target - occlusionOpacity, -step), step)
        } else {
            occlusionOpacity = target
        }
        screenPoint = projection.screenPoint(of: position)
        guard let point = screenPoint else { return }
        scale = referenceDistance.map { WorldUIScaling.scale(distance: point.distance, reference: $0, range: scaleRange) } ?? 1
    }
}

/// A full-viewport layer whose children follow 3D points: call `update(projection:dt:)` every
/// frame with the camera's `ViewportProjection` (sized like the layer, in points). Each widget is
/// laid out once at its measured size and then moved, scaled with distance and faded by
/// `visualOffset` / `visualScale` / `opacity`, so following a moving object costs no layout.
/// Widgets behind the camera are skipped; nearer ones paint over farther ones. The layer and
/// its widgets don't take the pointer.
@MainActor
public final class WorldSpaceLayer: Widget {
    public private(set) var anchors: [WorldAnchor] = []

    public override init(name: String = "worldSpace") {
        super.init(name: name)
        isHitTestable = false
    }

    /// Adds `widget`, following `position`.
    @discardableResult
    public func add(_ widget: Widget, at position: Vec3, pivot: Vec2 = Vec2(0.5, 1)) -> WorldAnchor {
        let anchor = WorldAnchor(widget: widget, position: position, pivot: pivot)
        anchors.append(anchor)
        addChild(widget)
        return anchor
    }

    public func remove(_ anchor: WorldAnchor) {
        anchors.removeAll { $0 === anchor }
        anchor.widget.removeFromParent()
    }

    /// Projects every anchor and places its widget. `projection.size` should be the layer's size.
    public func update(projection: ViewportProjection, dt: Float) {
        for anchor in anchors {
            anchor.update(projection: projection, dt: dt)
            let widget = anchor.widget
            guard let point = anchor.screenPoint else {
                widget.opacity = 0
                continue
            }
            let size = Vec2(widget.frame.width, widget.frame.height) * anchor.scale
            let topLeft = point.position + anchor.screenOffset - anchor.pivot * size
            // Snap to the pixel grid so labels at scale 1 stay crisp.
            widget.visualOffset = Vec2(snap(topLeft.x), snap(topLeft.y)) - Vec2(widget.frame.x, widget.frame.y)
            widget.visualScale = anchor.scale
            let fade = anchor.fadeDistance.map { WorldUIScaling.fade(distance: point.distance, range: $0) } ?? 1
            widget.opacity = fade * anchor.occlusionOpacity
        }
        let distance = Dictionary(uniqueKeysWithValues: anchors.map {
            (ObjectIdentifier($0.widget), $0.screenPoint?.distance ?? .infinity)
        })
        sortChildren { (distance[ObjectIdentifier($0)] ?? 0) > (distance[ObjectIdentifier($1)] ?? 0) }
    }

    /// Each widget at its measured size at the layer's origin; `update` moves it from there.
    public override func layoutChildren() {
        let origin = contentRect
        for child in children where !child.isHidden {
            let size = child.measure(width: nil)
            child.layout(in: UIRect(x: origin.x, y: origin.y, width: size.x, height: size.y))
        }
    }

    public override func hitTest(_ point: Vec2) -> Widget? { nil }
}

/// A UI drawn into its own `RenderTarget`, for showing on a surface in the world (a terminal,
/// a billboard, a wrist menu): it owns a `UIContext` (`ui`), a `UIDrawList` and a `UIRenderer`.
/// Each frame: `update(input:dt:pointer:)` with the panel point under the mouse (from
/// `hit(ray:planeTransform:)` against the quad showing it), then `render(frame:)` in
/// `renderOffscreen`, before the pass that samples `texture`.
@MainActor
public final class WorldUIPanel {
    public let ui: UIContext
    public let list = UIDrawList()
    public let target: RenderTarget
    /// Panel size in points.
    public let size: Vec2
    /// Target pixels per point.
    public let pixelsPerPoint: Float
    /// What the target is cleared to (linear RGBA) before the UI is drawn.
    public var clearColor = Vec4(0, 0, 0, 1)
    private let renderer: UIRenderer

    public init(device: RenderDevice, size: Vec2, pixelsPerPoint: Float = 2, theme: UITheme = .dark(),
                label: String = "ui panel") throws {
        self.size = size
        self.pixelsPerPoint = pixelsPerPoint
        let pixels = RenderTargetSizing.pixels(points: size, scale: pixelsPerPoint)
        target = try RenderTarget(device: device, width: pixels.width, height: pixels.height, multisampled: false, label: label)
        renderer = try UIRenderer(device: device)
        ui = UIContext(theme: theme)
    }

    /// The texture to show (sRGB color; sample it like any image).
    public var texture: GPUTexture { target.texture }

    /// Runs the panel's UI for a frame with the pointer at `pointer` (panel points, nil when the mouse isn't over it).
    public func update(input: Input, dt: Float, pointer: Vec2?) {
        ui.pointerMapping = { _ in pointer }
        ui.update(input: input, dt: dt, viewportSize: size, scale: pixelsPerPoint)
    }

    /// Paints the UI and draws it into the target. Call in `renderOffscreen`.
    public func render(frame: Frame) {
        list.beginFrame(framebufferSize: (target.width, target.height), scale: pixelsPerPoint)
        ui.draw(into: list)
        frame.renderPass(into: target, clearColor: clearColor) { pass in renderer.render(list, into: pass) }
    }

    /// Where `ray` hits a `MeshHandle.plane` (1x1 in XZ, facing +Y) placed by `planeTransform`,
    /// as UV (0...1, u along +x, v along +z: the texture's orientation on it), or nil when it
    /// misses or hits the back.
    public static func hit(ray: Ray, planeTransform: Mat4) -> Vec2? {
        let inverse = planeTransform.inverse
        let o = inverse * Vec4(ray.origin, 1), d = inverse * Vec4(ray.direction, 0)
        guard d.y < -1e-6, o.y > 0 else { return nil }
        let t = -o.y / d.y
        let x = o.x + d.x * t, z = o.z + d.z * t
        guard abs(x) <= 0.5, abs(z) <= 0.5 else { return nil }
        return Vec2(x + 0.5, z + 0.5)
    }
}
