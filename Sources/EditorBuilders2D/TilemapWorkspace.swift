import EditorCore
import Engine
import Foundation

// The Tilemap Builder tab: a 2D canvas for one `.tilemap` file, tabbed with the Scene view, with
// the `TilemapBuilderView` sidebar (palette, layers, tile data, terrains, objects, map settings).
//
// - Left-drag paints with the toolbar's tool on the selected layer: Pencil, Rectangle, Fill
//   (flood), Erase, Random (from the palette's multi-selection), Terrain (auto-tiling), Object
//   (click to add or pick an object point, drag to move it) and Pick (take the tile under the
//   pointer). Right-click picks too. Flip X / Flip Y / Rotate transform the tiles you place.
// - Middle-drag (or Alt / Space + left-drag) pans, the wheel zooms around the pointer.
//
// A stroke is drawn live on a working copy and written to the file when you let go: one undo
// step of the editor (Ctrl+Z). The file is the truth: after an undo or an MCP edit the
// workspace rereads it. Edits made by widget callbacks are applied on the next `update`.

private extension UIRect {
    var origin: Vec2 { Vec2(x, y) }
}

private func distance2D(_ a: Vec2, _ b: Vec2) -> Float { ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)).squareRoot() }

/// The canvas tools.
public enum TilemapTool: String, CaseIterable, Sendable {
    case pencil, rectangle, fill, erase, random, terrain, object, pick

    public var title: String {
        switch self {
        case .pencil: "Pencil"
        case .rectangle: "Rect"
        case .fill: "Fill"
        case .erase: "Erase"
        case .random: "Random"
        case .terrain: "Terrain"
        case .object: "Object"
        case .pick: "Pick"
        }
    }

    /// The key that picks the tool on the canvas.
    public var shortcut: Key {
        switch self {
        case .pencil: .b
        case .rectangle: .r
        case .fill: .g   // F frames the selection editor-wide
        case .erase: .e
        case .random: .n
        case .terrain: .t
        case .object: .o
        case .pick: .i
        }
    }

    var tooltip: String {
        "\(description) (\(shortcut.rawValue.uppercased()))"
    }

    private var description: String {
        switch self {
        case .pencil: "Paint the selected tile cell by cell"
        case .rectangle: "Drag a rectangle to fill with the selected tile"
        case .fill: "Flood-fill the connected cells that hold the same tile"
        case .erase: "Clear cells (with a terrain selected in Terrain mode, its edges are re-tiled)"
        case .random: "Paint a random tile from the palette selection (Shift-click tiles in the palette to add them)"
        case .terrain: "Auto-tile: paint the selected terrain; edges and corners pick the right tile (Shift-drag erases it)"
        case .object: "Click to add an object point (or select one), drag to move it"
        case .pick: "Take the tile under the pointer as the brush (right-click does this in any tool)"
        }
    }
}

/// Draws the map with its tile set and turns pointer input into cell strokes.
@MainActor
public final class TilemapCanvas: Widget {
    weak var workspace: TilemapWorkspace?
    /// Screen points per tile set pixel.
    public var zoom: Float = 2
    /// Offset of the map's top-left corner from the canvas's top-left, in points.
    public var pan = Vec2(16, 16)
    public var showsGrid = true
    public private(set) var hoverCell: (x: Int, y: Int)?
    private var panning: Vec2?
    private var stroking = false

    public override init(name: String = "tilemapCanvas") {
        super.init(name: name)
        clipsContent = true
    }

    public override func measureContent(width: Float?) -> Vec2 { Vec2(320, 240) }

    /// Takes keyboard focus on click, for the tool shortcuts (`TilemapWorkspace.handleKey`).
    public override var acceptsFocus: Bool { true }

    /// The cell under a window point (nil outside the map).
    func cell(at point: Vec2) -> (x: Int, y: Int)? {
        guard let map = workspace?.map else { return nil }
        let p = (point - contentRect.origin - pan) / zoom
        let x = Int((p.x / Float(map.tileW)).rounded(.down)), y = Int((p.y / Float(map.tileH)).rounded(.down))
        return map.contains(x: x, y: y) ? (x, y) : nil
    }

    /// The cell under a point, clamped to the map (for drags that leave it).
    func clampedCell(at point: Vec2) -> (x: Int, y: Int)? {
        guard let map = workspace?.map else { return nil }
        let p = (point - contentRect.origin - pan) / zoom
        let x = Int((p.x / Float(map.tileW)).rounded(.down)), y = Int((p.y / Float(map.tileH)).rounded(.down))
        return (min(max(x, 0), map.cols - 1), min(max(y, 0), map.rowCount - 1))
    }

    /// Zooms and pans so the whole map fits.
    public func fit() {
        guard let map = workspace?.map, contentRect.width > 8, contentRect.height > 8 else { return }
        let w = Float(map.cols * map.tileW), h = Float(map.rowCount * map.tileH)
        zoom = max(min((contentRect.width - 32) / w, (contentRect.height - 32) / h), 0.05)
        pan = Vec2((contentRect.width - w * zoom) / 2, (contentRect.height - h * zoom) / 2)
        setNeedsDisplay()
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        guard let workspace else { return false }
        switch event {
        case .pointerDown(let e):
            context?.focus(self)
            if e.button == .middle || (e.button == .left && e.modifiers.contains(.alt)) {
                panning = e.position
                return true
            }
            if e.button == .right {
                if let c = cell(at: e.position) { workspace.pick(x: c.x, y: c.y) }
                return true
            }
            guard e.button == .left, let c = cell(at: e.position) else { return e.button == .left }
            stroking = true
            workspace.beginStroke(x: c.x, y: c.y, erasing: e.modifiers.contains(.shift))
            return true
        case .pointerDrag(let e):
            if let last = panning {
                pan = pan + (e.position - last)
                panning = e.position
                setNeedsDisplay()
            } else if stroking, let c = clampedCell(at: e.position) {
                hoverCell = c
                workspace.continueStroke(x: c.x, y: c.y)
            }
            return true
        case .pointerUp:
            if panning != nil { panning = nil } else if stroking {
                stroking = false
                workspace.endStroke()
            }
            return true
        case .pointerMove(let e):
            let c = cell(at: e.position)
            if c?.x != hoverCell?.x || c?.y != hoverCell?.y {
                hoverCell = c
                setNeedsDisplay()
            }
            return false
        case .key(let key):
            return workspace.handleKey(key)
        case .scroll(let delta, let position):
            let factor = powf(1.0015, delta.y * 10)
            let anchor = position - contentRect.origin
            let newZoom = min(max(zoom * factor, 0.05), 32)
            pan = anchor - (anchor - pan) * (newZoom / zoom)
            zoom = newZoom
            setNeedsDisplay()
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let rect = contentRect
        list.fillRect(rect, color: UIColor(0.09, 0.1, 0.12, 1))
        guard let workspace, let map = workspace.map else { return }
        let tw = Float(map.tileW) * zoom, th = Float(map.tileH) * zoom
        let origin = rect.origin + pan
        let mapRect = UIRect(x: origin.x, y: origin.y, width: tw * Float(map.cols), height: th * Float(map.rowCount))
        let bg = map.background ?? Vec4(0.16, 0.17, 0.2, 1)
        list.withClip(rect) {
            list.fillRect(mapRect, color: UIColor(bg.x, bg.y, bg.z, max(bg.w, 0.35)))
            // Visible cells only.
            let x0 = max(Int(((rect.x - origin.x) / tw).rounded(.down)), 0)
            let x1 = min(Int(((rect.maxX - origin.x) / tw).rounded(.down)), map.cols - 1)
            let y0 = max(Int(((rect.y - origin.y) / th).rounded(.down)), 0)
            let y1 = min(Int(((rect.maxY - origin.y) / th).rounded(.down)), map.rowCount - 1)
            if x0 <= x1, y0 <= y1 {
                let order = map.layers.indices.sorted { map.order(ofLayer: $0) < map.order(ofLayer: $1) }
                for li in order where map.layers[li].visible && !workspace.hiddenLayers.contains(map.layers[li].name) {
                    var alpha = min(max(map.layers[li].opacity, 0), 1)
                    if workspace.dimsOtherLayers && li != workspace.selectedLayer { alpha *= 0.35 }
                    for y in y0...y1 {
                        for x in x0...x1 {
                            let c = map.cell(layer: li, x: x, y: y)
                            guard !c.isEmpty else { continue }
                            let frame = workspace.animation(ofTile: c.tile, in: map)?.frame(at: workspace.time) ?? c.tile
                            drawTile(list, frame: frame, cell: c, at: Vec2(origin.x + Float(x) * tw, origin.y + Float(y) * th),
                                     size: Vec2(tw, th), alpha: alpha)
                        }
                    }
                }
            }
            if showsGrid && tw >= 6 {
                let gridColor = UIColor(1, 1, 1, 0.08)
                for x in 0...map.cols {
                    let px = origin.x + Float(x) * tw
                    guard px >= rect.x - 1, px <= rect.maxX + 1 else { continue }
                    list.drawLine(from: Vec2(px, mapRect.y), to: Vec2(px, mapRect.maxY), width: 1, color: gridColor)
                }
                for y in 0...map.rowCount {
                    let py = origin.y + Float(y) * th
                    guard py >= rect.y - 1, py <= rect.maxY + 1 else { continue }
                    list.drawLine(from: Vec2(mapRect.x, py), to: Vec2(mapRect.maxX, py), width: 1, color: gridColor)
                }
            }
            list.strokeRect(mapRect, color: UIColor(1, 1, 1, 0.3), width: 1)
            if let r = workspace.rectPreview {
                let lx = min(r.0, r.2), hx = max(r.0, r.2), ly = min(r.1, r.3), hy = max(r.1, r.3)
                let box = UIRect(x: origin.x + Float(lx) * tw, y: origin.y + Float(ly) * th, width: Float(hx - lx + 1) * tw, height: Float(hy - ly + 1) * th)
                list.fillRect(box, color: theme.accent.withAlpha(0.18))
                list.strokeRect(box, color: theme.accent, width: 2)
            }
            if let hover = hoverCell, workspace.tool != .object {
                list.strokeRect(UIRect(x: origin.x + Float(hover.x) * tw, y: origin.y + Float(hover.y) * th, width: tw, height: th),
                                color: UIColor(1, 0.85, 0.3, 0.9), width: 2)
            }
            // Object points (y up from the bottom-left in world units).
            let unit = map.unitsPerPixel
            for (i, object) in map.objects.enumerated() {
                let px = origin.x + object.position.x / unit * zoom
                let py = origin.y + (Float(map.rowCount * map.tileH) - object.position.y / unit) * zoom
                let selected = i == workspace.selectedObject
                let color = selected ? theme.accent : UIColor(1, 0.45, 0.8, 1)
                if object.size.x > 0, object.size.y > 0 {
                    let w = object.size.x / unit * zoom, h = object.size.y / unit * zoom
                    list.strokeRect(UIRect(x: px - w / 2, y: py - h / 2, width: w, height: h), color: color, width: selected ? 2 : 1)
                }
                list.fillRect(UIRect(x: px - 4, y: py - 4, width: 8, height: 8), color: color, radii: UICornerRadii(4))
                list.drawText(object.name, at: Vec2(px + 6, py - 14), size: 11, color: color)
            }
        }
        let caption = hoverCell.map { "cell \($0.x), \($0.y) · " } ?? ""
        list.drawText(caption + "\(workspace.tool.title) (\(workspace.tool.shortcut.rawValue.uppercased())) · middle-drag pans · wheel zooms · click, then keys pick tools", at: Vec2(rect.x + 8, rect.maxY - 18), size: 11,
                      color: theme.secondaryTextColor)
    }

    private func drawTile(_ list: UIDrawList, frame: Int, cell: TileCell, at topLeft: Vec2, size: Vec2, alpha: Float) {
        guard let workspace else { return }
        let corners = [Vec2(0, 0), Vec2(1, 0), Vec2(1, 1), Vec2(0, 1)]
        guard let texture = workspace.texture, let layout = workspace.layout, layout.contains(frame) else {
            // No GPU or an unknown tile: a colored square per tile index.
            let hue = Float((frame * 37) % 100) / 100
            list.fillRect(UIRect(x: topLeft.x + 1, y: topLeft.y + 1, width: size.x - 2, height: size.y - 2),
                          color: UIColor(0.3 + 0.6 * hue, 0.8 - 0.5 * hue, 0.5, alpha))
            return
        }
        let uv = layout.uv(frame, inset: 0.01)
        let tint = UIColor(1, 1, 1, alpha)
        list.drawTexturedQuad(texture, mode: .image, sampler: workspace.sampler, corners: corners.map { c in
            let p = cell.place(c)
            return UIQuadCorner(position: Vec2(topLeft.x + p.x * size.x, topLeft.y + (1 - p.y) * size.y),
                                uv: Vec2(c.x == 0 ? uv.min.x : uv.max.x, c.y == 0 ? uv.max.y : uv.min.y), color: tint)
        })
    }
}

/// The tile set as a clickable grid: click picks the brush tile, Shift-click adds tiles to the random set.
@MainActor
public final class TilesetPalette: Widget {
    weak var workspace: TilemapWorkspace?

    public override init(name: String = "tilemapPalette") { super.init(name: name) }

    private var columns: Int { max(workspace?.layout?.columns ?? 8, 1) }
    private var count: Int { workspace?.layout?.count ?? 0 }

    private func cellSize(width: Float) -> Float { min(max(width / Float(columns), 8), 40) }

    public override func measureContent(width: Float?) -> Vec2 {
        let w = width ?? 300
        let rows = max((count + columns - 1) / columns, 1)
        return Vec2(w, cellSize(width: w) * Float(rows))
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        guard case .pointerDown(let e) = event, let workspace else { return false }
        let s = cellSize(width: contentRect.width)
        let p = e.position - contentRect.origin
        let c = Int(p.x / s), r = Int(p.y / s)
        guard c >= 0, c < columns, r >= 0 else { return true }
        let tile = r * columns + c
        guard tile < count else { return true }
        workspace.selectTile(tile, adding: e.modifiers.contains(.shift))
        return true
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        guard let workspace else { return }
        let rect = contentRect
        let s = cellSize(width: rect.width)
        list.fillRect(UIRect(x: rect.x, y: rect.y, width: s * Float(columns), height: rect.height), color: UIColor(0.12, 0.12, 0.14, 1))
        for tile in 0..<count {
            let box = UIRect(x: rect.x + Float(tile % columns) * s, y: rect.y + Float(tile / columns) * s, width: s, height: s)
            if let texture = workspace.texture, let layout = workspace.layout {
                let uv = layout.uv(tile)
                list.drawTexturedRect(texture, rect: box, uv: UIRect(x: uv.min.x, y: uv.min.y, width: uv.max.x - uv.min.x, height: uv.max.y - uv.min.y),
                                      mode: .image, sampler: workspace.sampler)
            } else {
                list.drawText("\(tile)", at: Vec2(box.x + 2, box.y + 2), size: 9, color: theme.secondaryTextColor)
            }
            if workspace.randomTiles.contains(tile) { list.strokeRect(box.inset(by: 2), color: UIColor(0.4, 0.9, 1, 1), width: 2) }
            if tile == workspace.brushTile { list.strokeRect(box, color: theme.accent, width: 2) }
        }
    }
}

@MainActor
public final class TilemapWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    /// The tilemap being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    /// The map as shown (the file's contents plus a stroke in progress).
    public private(set) var map: Tilemap?
    public var tool = TilemapTool.pencil { didSet { if tool != oldValue { rebuildToolbar() } } }
    public var selectedLayer = 0
    /// The tile the pencil, rectangle and fill place.
    public var brushTile = 0
    /// The random brush's tiles.
    public var randomTiles: [Int] = []
    public var selectedTerrain = 0
    public var selectedObject: Int?
    public var flipX = false
    public var flipY = false
    /// Quarter turns clockwise of placed tiles.
    public var rotation = 0
    /// Shows the other layers faded.
    public var dimsOtherLayers = false
    /// Layers hidden in the canvas only (not in the file).
    public var hiddenLayers: Set<String> = []
    /// Seconds, for animated tiles.
    public private(set) var time: Float = 0
    /// Set by the host to draw the tile set (nil without a GPU: tiles show as colored squares).
    public var device: RenderDevice?
    public private(set) var texture: GPUTexture?
    public private(set) var sampler: GPUSampler?
    public private(set) var layout: TilesetLayout?
    /// Tile animations from a `.sprite` tile set's tags (tiles with their own animation keep it).
    public private(set) var tagAnimations: [Int: TilemapAnimation] = [:]
    /// The rectangle tool's drag, as cells (x0, y0, x1, y1).
    public private(set) var rectPreview: (Int, Int, Int, Int)?

    let canvas = TilemapCanvas()
    let palette = TilesetPalette()
    private(set) var builder: TilemapBuilderView?
    private let title = Label("Tilemap Builder", role: .heading, name: "tilemapTitle")
    private let toolbar = HStack(spacing: 4, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "tilemapToolbar")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "tilemapSidebar")
    private var file: Tilemap?
    private var shownRevision = -1
    private var pending: (map: Tilemap, label: String)?
    private var needsSidebar = false
    private var needsFit = false
    private var stroke: (start: (x: Int, y: Int), last: (x: Int, y: Int), erasing: Bool, moved: Bool, objectStart: Vec2?)?
    private var textureRevision = -1

    public init(session: EditorSession) {
        self.session = session
        view = VStack(spacing: 0, name: "tilemapWorkspace")
        canvas.workspace = self
        palette.workspace = self
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.tilemap` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isTilemapFile(id), var contents = session.assets?.tilemapContents(of: id) else { return false }
        contents.normalize()
        if asset != id {
            asset = id
            selectedLayer = contents.layers.firstIndex { $0.collision } ?? 0
            selectedObject = nil
            selectedTerrain = 0
            hiddenLayers = []
            needsFit = true
            textureRevision = -1
        }
        file = contents
        map = contents
        shownRevision = session.assets?.revision(of: id) ?? 0
        title.text = session.assets?.record(id)?.fileName ?? "Tilemap Builder"
        // The toolbar can squeeze the name to a few letters; the tooltip keeps it readable.
        title.tooltip = session.assets?.record(id)?.path
        builder = TilemapBuilderView(workspace: self)
        reloadTexture()
        needsSidebar = true
        rebuildSidebar()
        return true
    }

    /// Closes the file (the panel shows how to open one).
    public func close() {
        asset = nil
        map = nil
        file = nil
        pending = nil
        builder = nil
        texture = nil
        layout = nil
        showEmpty()
    }

    // MARK: Chrome

    private func layOutChrome() {
        title.style.shrink = 1
        title.icon = EditorIcons.asset(.texture)
        canvas.style.grow = 1
        canvas.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "tilemapSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "tilemapBody", [canvas, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        toolbar.wraps = true
        view.addChildren([toolbar, Separator(), body])
        rebuildToolbar()
    }

    private func rebuildToolbar() {
        toolbar.removeAllChildren()
        toolbar.addChild(title)
        toolbar.addChild(Spacer())
        for t in TilemapTool.allCases {
            let button = Button(t.title, role: t == tool ? .primary : .normal, name: "tilemapTool.\(t.rawValue)") { [unowned self] in tool = t }
            button.tooltip = t.tooltip
            toolbar.addChild(button)
        }
        toolbar.addChild(Separator(.vertical))
        let fx = Button("Flip X", role: flipX ? .primary : .normal, name: "tilemapFlipX") { [unowned self] in flipX.toggle(); rebuildToolbar() }
        let fy = Button("Flip Y", role: flipY ? .primary : .normal, name: "tilemapFlipY") { [unowned self] in flipY.toggle(); rebuildToolbar() }
        let rot = Button("Rotate \(rotation * 90)°", role: rotation != 0 ? .primary : .normal, name: "tilemapRotate") { [unowned self] in
            rotation = (rotation + 1) % 4
            rebuildToolbar()
        }
        fx.tooltip = "Mirror placed tiles left to right (X)"
        fy.tooltip = "Mirror placed tiles top to bottom (Y)"
        rot.tooltip = "Turn placed tiles a quarter turn clockwise (Z; Shift-Z turns back)"
        let grid = Button("Grid", role: canvas.showsGrid ? .primary : .normal, name: "tilemapGrid") { [unowned self] in
            canvas.showsGrid.toggle()
            rebuildToolbar()
        }
        grid.tooltip = "Show the cell grid (Shift-G)"
        let fit = Button("Fit", name: "tilemapFit") { [unowned self] in canvas.fit() }
        fit.tooltip = "Zoom to show the whole map (0)"
        let close = Button("Close", name: "tilemapClose") { [unowned self] in self.close() }
        toolbar.addChildren([fx, fy, rot, grid, fit, close])
    }

    private func showEmpty() {
        title.text = "Tilemap Builder"
        title.tooltip = nil
        sidebar.removeAllChildren()
        let note = Label("Double-click a .tilemap file in the Assets panel to paint it here, or make one with the Assets panel's "
                         + "New Tilemap (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New Tilemap", role: .primary, name: "tilemapNew") { [unowned self] in
            if let id = session.run(TilemapNewCommand.self, .init())?.asset { session.run(TilemapOpenCommand.self, .init(asset: AssetReference(id))) }
        }
        new.command = TilemapNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
    }

    func rebuildSidebar() {
        guard needsSidebar, let builder else { return }
        needsSidebar = false
        sidebar.removeAllChildren()
        builder.layout()
        sidebar.addChild(builder.view)
    }

    /// Asks for the sidebar to be laid out again on the next `update` (or now, outside a widget callback).
    func setNeedsSidebar() { needsSidebar = true }

    // MARK: Per frame

    /// Call every frame: applies the pending edit, follows the file (undo, MCP, other panels) and steps animated tiles.
    public func update(dt: Float = 0) {
        time += dt
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        builder?.refresh()
        if let pending {
            self.pending = nil
            commit(pending.map, label: pending.label)
        }
        let revision = assets.revision(of: asset)
        if revision != shownRevision, stroke == nil, var fresh = assets.tilemapContents(of: asset) {
            shownRevision = revision
            fresh.normalize()
            if fresh != file {
                file = fresh
                map = fresh
                needsSidebar = true
            }
            reloadTexture()
        }
        clampSelection()
        rebuildSidebar()
        if needsFit, canvas.contentRect.width > 8 {
            needsFit = false
            canvas.fit()
        }
    }

    /// Whether an edit is waiting for `update`.
    public var hasPendingEdit: Bool { pending != nil }

    private func clampSelection() {
        guard let map else { return }
        if !map.layers.indices.contains(selectedLayer) { selectedLayer = max(map.layers.count - 1, 0) }
        if let o = selectedObject, !map.objects.indices.contains(o) { selectedObject = nil }
        if !map.terrains.indices.contains(selectedTerrain) { selectedTerrain = 0 }
    }

    private func reloadTexture() {
        guard let asset, let assets = session.assets else { return }
        let revision = assets.revision(of: asset)
        guard revision != textureRevision else { return }
        textureRevision = revision
        tagAnimations = map.flatMap { assets.tilesetSprite(of: $0) }.map(Tilemap.spriteTagAnimations) ?? [:]
        guard let tileset = assets.tileset(of: asset) else {
            layout = nil
            texture = nil
            return
        }
        layout = tileset.layout
        guard let device else { return }
        do {
            texture = try device.makeTexture(image: tileset.image, srgb: true, generateMipmaps: false)
            if sampler == nil { sampler = try device.makeSampler(SamplerDescriptor(filter: .nearest, mipFilter: .none, addressMode: .clampToEdge)) }
        } catch {
            session.log.error("Tilemap Builder: the tile set can't be shown: \(error)")
            texture = nil
        }
    }

    /// The animation tile `tile` plays: its own entry's, else its sprite tag's.
    public func animation(ofTile tile: Int, in map: Tilemap) -> TilemapAnimation? {
        map.tileset.tile(tile)?.animation ?? tagAnimations[tile]
    }

    // MARK: Edits

    /// Queues `edited` to be written as one undo step on the next `update`.
    func apply(_ edited: Tilemap, label: String) {
        map = edited
        pending = (edited, label)
    }

    /// The map edits build on (a queued edit, else what is shown).
    var current: Tilemap? { pending?.map ?? map }

    private func commit(_ edited: Tilemap, label: String) {
        guard let asset, session.applyTilemap(edited, to: asset, label: label) != nil else {
            map = file
            return
        }
        var fresh = session.assets?.tilemapContents(of: asset) ?? edited
        fresh.normalize()
        file = fresh
        map = fresh
        shownRevision = session.assets?.revision(of: asset) ?? shownRevision
        reloadTexture()
        clampSelection()
        needsSidebar = true
    }

    /// The canvas's keyboard shortcuts: a tool's letter picks it (B Pencil, R Rect, G Fill, E Erase,
    /// N Random, T Terrain, O Object, I Pick); X and Y flip placed tiles, Z turns them clockwise
    /// (Shift-Z counterclockwise); [ and ] step the brush through the tile set; Shift-G toggles the
    /// grid and 0 fits the map. Keys with Command, Control or Alt held pass on (undo, save...).
    @discardableResult
    public func handleKey(_ key: KeyEvent) -> Bool {
        guard map != nil, !key.modifiers.contains(.command), !key.modifiers.contains(.control), !key.modifiers.contains(.alt) else { return false }
        if key.key == .g && key.modifiers.contains(.shift) {
            canvas.showsGrid.toggle()
            rebuildToolbar()
            canvas.setNeedsDisplay()
            return true
        }
        if let t = TilemapTool.allCases.first(where: { $0.shortcut == key.key }) {
            tool = t
            return true
        }
        switch key.key {
        case .x: flipX.toggle()
        case .y: flipY.toggle()
        case .z: rotation = (rotation + (key.modifiers.contains(.shift) ? 3 : 1)) % 4
        case .num0: canvas.fit(); return true
        case .leftBracket, .rightBracket:
            let count = layout?.count ?? 0
            guard count > 0 else { return true }
            selectTile(((brushTile + (key.key == .rightBracket ? 1 : -1)) % count + count) % count)
            return true
        default: return false
        }
        rebuildToolbar()
        canvas.setNeedsDisplay()
        return true
    }

    /// Picks the brush tile (with `adding`, toggles it in the random set).
    public func selectTile(_ tile: Int, adding: Bool = false) {
        if adding {
            if let i = randomTiles.firstIndex(of: tile) { randomTiles.remove(at: i) } else { randomTiles.append(tile) }
        } else {
            brushTile = tile
            randomTiles = [tile]
            if tool == .erase || tool == .pick || tool == .object { tool = .pencil }
        }
        needsSidebar = true
    }

    /// Takes the tile at (x, y) of the selected layer as the brush, with its transform.
    public func pick(x: Int, y: Int) {
        guard let map else { return }
        let c = map.cell(layer: selectedLayer, x: x, y: y)
        guard !c.isEmpty else { return }
        brushTile = c.tile
        randomTiles = [c.tile]
        flipX = c.flipX
        flipY = c.flipY
        rotation = c.rotation
        if tool == .pick || tool == .erase || tool == .object { tool = .pencil }
        rebuildToolbar()
        needsSidebar = true
    }

    private var brushCell: TileCell { TileCell(tile: brushTile, flipX: flipX, flipY: flipY, rotation: rotation) }

    /// The cells on the line from `a` to `b` (so fast drags leave no gaps).
    static func line(_ a: (x: Int, y: Int), _ b: (x: Int, y: Int)) -> [(x: Int, y: Int)] {
        let n = max(abs(b.x - a.x), abs(b.y - a.y))
        guard n > 0 else { return [b] }
        return (0...n).map { i in
            let t = Float(i) / Float(n)
            return (a.x + Int((Float(b.x - a.x) * t).rounded()), a.y + Int((Float(b.y - a.y) * t).rounded()))
        }
    }

    /// Starts a stroke at cell (x, y) with the current tool (`erasing`: Shift held, the terrain tool erases).
    public func beginStroke(x: Int, y: Int, erasing: Bool = false) {
        guard var m = current, !m.layers.isEmpty || tool == .object else { return }
        let start = (x: x, y: y)
        stroke = (start, start, erasing, false, nil)
        let layer = min(selectedLayer, max(m.layers.count - 1, 0))
        switch tool {
        case .pick:
            pick(x: x, y: y)
            stroke = nil
            return
        case .fill:
            m.floodFill(layer: layer, x: x, y: y, brushCell)
            map = m
        case .rectangle:
            rectPreview = (x, y, x, y)
        case .object:
            let world = m.cellCenter(x: x, y: y)
            let near = m.objects.indices.min { distance2D(m.objects[$0].position, world) < distance2D(m.objects[$1].position, world) }
            if let near, distance2D(m.objects[near].position, world) < max(m.cellSize.x, m.cellSize.y) {
                selectedObject = near
                stroke?.objectStart = m.objects[near].position
            } else {
                let name = EditorBuilderSupport.uniqueName("Object", among: m.objects.map(\.name))
                m.objects.append(TilemapObject(name: name, type: "point", position: world))
                selectedObject = m.objects.count - 1
                map = m
                stroke?.moved = true
            }
            needsSidebar = true
        default:
            paint(&m, cells: [start], layer: layer, erasing: erasing)
            map = m
        }
    }

    public func continueStroke(x: Int, y: Int) {
        guard var s = stroke, var m = map else { return }
        let to = (x: x, y: y)
        guard to.x != s.last.x || to.y != s.last.y else { return }
        let layer = min(selectedLayer, max(m.layers.count - 1, 0))
        switch tool {
        case .rectangle:
            rectPreview = (s.start.x, s.start.y, x, y)
        case .object:
            if let o = selectedObject, m.objects.indices.contains(o) {
                m.objects[o].position = m.cellCenter(x: x, y: y)
                map = m
                s.moved = true
            }
        case .fill, .pick:
            break
        default:
            paint(&m, cells: Self.line(s.last, to), layer: layer, erasing: s.erasing)
            map = m
        }
        s.last = to
        stroke = s
    }

    public func endStroke() {
        guard let s = stroke, var m = map else { return }
        stroke = nil
        let layer = min(selectedLayer, max(m.layers.count - 1, 0))
        if tool == .rectangle, let r = rectPreview {
            rectPreview = nil
            paint(&m, cells: m.rectCells(r.0, r.1, r.2, r.3), layer: layer, erasing: s.erasing)
        }
        if tool == .object && !s.moved { return }
        guard m != file else {
            map = file
            return
        }
        let label: String
        switch tool {
        case .object: label = s.objectStart == nil ? "Add Object" : "Move Object"
        case .erase: label = "Erase Tiles"
        case .terrain: label = s.erasing ? "Erase Terrain" : "Paint Terrain"
        default: label = "Paint Tiles"
        }
        apply(m, label: label)
    }

    private func paint(_ m: inout Tilemap, cells: [(x: Int, y: Int)], layer: Int, erasing: Bool) {
        guard m.layers.indices.contains(layer) else { return }
        switch tool {
        case .erase:
            if !m.terrains.isEmpty, m.terrains.indices.contains(selectedTerrain),
               cells.contains(where: { m.terrains[selectedTerrain].members.contains(m.cell(layer: layer, x: $0.x, y: $0.y).tile) }) {
                m.paintTerrain(layer: layer, terrain: selectedTerrain, cells: cells, erase: true)
            } else {
                m.paint(layer: layer, cells: cells, .empty)
            }
        case .random:
            m.paintRandom(layer: layer, cells: cells, tiles: randomTiles.isEmpty ? [brushTile] : randomTiles,
                          seed: Int(time * 1000) & 0xFFFF, flipX: flipX, flipY: flipY, rotation: rotation)
        case .terrain:
            guard m.terrains.indices.contains(selectedTerrain) else {
                session.log.warning("Tilemap Builder: add a terrain set to auto-tile with")
                return
            }
            m.paintTerrain(layer: layer, terrain: selectedTerrain, cells: cells, erase: erasing)
        default:
            m.paint(layer: layer, cells: cells, erasing ? .empty : brushCell)
        }
    }
}
