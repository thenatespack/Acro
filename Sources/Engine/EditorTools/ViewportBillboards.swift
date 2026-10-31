/// An icon an editor draws at an entity's position in a scene view, for entities with nothing
/// to see or click on (cameras, lights, audio sources, particle emitters, triggers).
public struct ViewportBillboard: Sendable, Equatable {
    public var entity: Entity
    /// World position (usually the entity's `GlobalTransform` translation).
    public var position: Vec3
    public var icon: VectorIcon
    /// The icon's color when not selected.
    public var color: UIColor

    public init(entity: Entity, position: Vec3, icon: VectorIcon, color: UIColor = .white) {
        self.entity = entity
        self.position = position
        self.icon = icon
        self.color = color
    }
}

/// A billboard as laid out for one view (`ViewportBillboards.update`).
public struct PlacedBillboard: Sendable, Equatable {
    public var billboard: ViewportBillboard
    /// Its square in viewport points.
    public var rect: UIRect
    /// Distance from the view ray's origin to the billboard's position, as `PickHit.distance` counts.
    public var distance: Float
    /// Geometry is in front of the billboard's center (it is drawn faded and loses clicks to that geometry).
    public var isOccluded: Bool

    public var entity: Entity { billboard.entity }
}

/// Screen-size icons for the entities of a scene view that have no mesh, kept the same size
/// in points at any distance, faded where geometry is in front of them, and picked like
/// meshes: give the `ScenePicker` the layer (`picker.billboards = layer`) and a click on one
/// selects its entity.
///
/// Each frame: `update(_:view:occluders:world:)` with the billboards and the view (viewport
/// points), then `draw(into:origin:selection:)` into the UI draw list over the view's image,
/// at the viewport's top-left corner. Occlusion is a ray cast against the meshes (through
/// `occluders`, without billboards) from the eye to each icon's center: exact, CPU-side, and the
/// same on every backend. `maxOcclusionTests` caps the casts per frame; the farthest icons past
/// it count as visible.
@MainActor
public final class ViewportBillboards {
    /// Icon disc diameter in points.
    public var size: Float = 26
    /// The icon's edge inside the disc, as a fraction of `size`.
    public var iconScale: Float = 0.6
    /// Opacity of icons behind geometry.
    public var occludedOpacity: Float = 0.35
    public var maxOcclusionTests = 256
    /// The disc behind an unselected icon.
    public var background = UIColor(0.08, 0.09, 0.11, 0.72)
    public var border = UIColor(1, 1, 1, 0.28)
    /// The disc of the primary selected entity, and of the other selected ones.
    public var primaryColor = UIColor(hex: 0xf5a524)
    public var secondaryColor = UIColor(hex: 0xc98a2b)
    /// The icon's color on a selected disc.
    public var selectedIconColor = UIColor(hex: 0x1a1206)

    /// The last `update`'s billboards in front of the camera and inside the view, far to near.
    public private(set) var placed: [PlacedBillboard] = []

    public init() {}

    /// Projects `billboards` into `view` and tests which are hidden behind geometry (meshes
    /// `occluders` can pick, in `world`; nil skips the test).
    public func update(_ billboards: [ViewportBillboard], view: ViewportProjection, occluders: ScenePicker?, world: World) {
        placed.removeAll(keepingCapacity: true)
        let half = size / 2
        for billboard in billboards {
            guard let point = view.project(billboard.position) else { continue }
            let rect = UIRect(x: point.x - half, y: point.y - half, width: size, height: size)
            guard rect.maxX > 0, rect.maxY > 0, rect.x < view.size.x, rect.y < view.size.y else { continue }
            let ray = view.ray(through: point)
            let along = dot(billboard.position - ray.origin, ray.direction) / max(dot(ray.direction, ray.direction), 1e-12)
            guard along > 0 else { continue }
            placed.append(PlacedBillboard(billboard: billboard, rect: rect, distance: along * length(ray.direction), isOccluded: false))
        }
        // Far to near, so nearer icons are drawn over farther ones; ties by entity for a stable order.
        placed.sort { $0.distance != $1.distance ? $0.distance > $1.distance : $0.entity.index < $1.entity.index }
        guard let occluders else { return }
        let saved = occluders.billboards
        occluders.billboards = nil
        defer { occluders.billboards = saved }
        let tested = max(placed.count - maxOcclusionTests, 0)
        for i in tested..<placed.count {
            let center = placed[i].rect.center
            let ray = view.ray(through: center)
            if let hit = occluders.pick(ray, in: world) {
                placed[i].isOccluded = hit.distance < placed[i].distance * 0.999 - 1e-3
            }
        }
    }

    /// The nearest billboard whose disc contains `point` (viewport points).
    public func hit(at point: Vec2) -> PlacedBillboard? {
        for placed in placed.reversed() {
            let d = point - placed.rect.center
            let radius = placed.rect.width / 2 + 1
            if (d * d).sum() <= radius * radius { return placed }
        }
        return nil
    }

    /// How a billboard's entity is selected, for `draw`.
    public enum SelectionState: Sendable {
        case none, selected, primary
    }

    /// Draws the billboards with the viewport's top-left corner at `origin` (list points).
    public func draw(into list: UIDrawList, origin: Vec2, selection: (Entity) -> SelectionState) {
        for item in placed {
            let rect = UIRect(x: origin.x + item.rect.x, y: origin.y + item.rect.y, width: item.rect.width, height: item.rect.height)
            let state = selection(item.entity)
            let disc = UICornerRadii(rect.width / 2)
            list.withOpacity(item.isOccluded ? occludedOpacity : 1) {
                switch state {
                case .none:
                    list.fillRect(rect, color: background, radii: disc)
                    list.strokeRect(rect, color: border, width: 1, radii: disc)
                case .selected, .primary:
                    list.fillRect(rect, color: state == .primary ? primaryColor : secondaryColor, radii: disc)
                    list.strokeRect(rect, color: UIColor(1, 1, 1, 0.9), width: 1.5, radii: disc)
                }
                let edge = (rect.width * iconScale).rounded()
                list.drawIcon(item.billboard.icon,
                              in: UIRect(x: rect.center.x - edge / 2, y: rect.center.y - edge / 2, width: edge, height: edge),
                              color: state == .none ? item.billboard.color : selectedIconColor)
            }
        }
    }
}

extension ScenePicker {
    /// A billboard hit as a `PickHit`: its position, facing back along `ray`.
    func hit(for billboard: PlacedBillboard, ray: Ray) -> PickHit {
        let direction = length(ray.direction) > 0 ? normalize(ray.direction) : Vec3(0, 0, 1)
        return PickHit(entity: billboard.entity, point: billboard.billboard.position, distance: billboard.distance,
                       normal: -direction, triangle: -1)
    }
}
