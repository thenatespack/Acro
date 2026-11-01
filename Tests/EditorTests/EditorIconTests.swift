import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Editor icons (card #659): the vector icon rasterizer, the icons of every component type and
// asset kind, game-registered icons, icon-only toolbar buttons that keep their labels, and the
// viewport's billboards (laid out, occluded, picked through ScenePicker). Touches the global
// icon registry (`EditorIcons.register`) and the component catalog, so the suite is serialized.

@MainActor
@Suite(.serialized)
struct EditorIconTests {
    // MARK: Rasterizer

    @Test func everyBuiltinIconParses() throws {
        #expect(VectorIcon.builtinNames.count >= 80)
        for name in VectorIcon.builtinNames {
            let icon = try #require(VectorIcon.named(name), "\(name)")
            let pixels = icon.rasterize(pixels: 24)
            #expect(pixels.count == 24 * 24)
            // Something drawn, and not everything.
            let covered = pixels.filter { $0 > 127 }.count
            #expect(covered > 8 && covered < 24 * 24 * 3 / 4, "\(name): \(covered) pixels")
        }
    }

    /// The same line at 1x and 2x: twice the size covers four times the pixels (within the
    /// antialiased edge), and fully covered pixels exist at every size, so lines stay solid.
    @Test func iconsAreCrispAtEveryScale() throws {
        let icon = try #require(VectorIcon.named("square"))
        var previous: Float = 0
        for pixels in [12, 16, 20, 24, 32, 48, 64] {
            let mask = icon.rasterize(pixels: pixels)
            let ink = mask.reduce(Float(0)) { $0 + Float($1) / 255 }
            #expect(mask.contains(255), "solid line pixels at \(pixels) px")
            #expect(ink > previous)
            previous = ink
            // A vertical edge of the square: the line is about strokeWidth * pixels / 24 wide.
            let row = pixels / 2
            let line = (0..<pixels).map { Float(mask[row * pixels + $0]) / 255 }.prefix(pixels / 2).reduce(0, +)
            #expect(abs(line - max(2 * Float(pixels) / 24, 1)) < 0.35, "\(pixels) px: line width \(line)")
        }
        let one = icon.rasterize(pixels: 16).reduce(Float(0)) { $0 + Float($1) }
        let two = icon.rasterize(pixels: 32).reduce(Float(0)) { $0 + Float($1) }
        #expect(abs(two / one - 4) < 0.4)  // length and width both scale with the size
    }

    @Test func svgMarkupForms() throws {
        // Arcs, cubic and quadratic curves, relative commands, implicit repeats, polygons, fills.
        let shapes = [
            #"<path d="M4 12a8 8 0 1 0 16 0a8 8 0 1 0-16 0"/>"#,
            #"<path d="M4 4C10 0 14 0 20 4S20 20 12 20Q4 20 4 12T4 4z"/>"#,
            #"<path d="m4 4 16 0 0 16-16 0z"/>"#,
            #"<polygon points="12,2 22,22 2,22"/>"#,
            #"<polyline points="2 2 22 22"/><line x1="2" y1="22" x2="22" y2="2"/>"#,
            #"<ellipse cx="12" cy="12" rx="10" ry="5"/><rect x="3" y="3" width="18" height="18" rx="4"/>"#,
        ]
        for svg in shapes {
            let icon = try VectorIcon(name: "test", svg: svg)
            #expect(icon.rasterize(pixels: 24).contains { $0 > 200 }, "\(svg)")
        }
        let filled = try VectorIcon(name: "dot", svg: #"<circle cx="12" cy="12" r="6" fill="currentColor" stroke="none"/>"#)
        let mask = filled.rasterize(pixels: 24)
        #expect(mask[12 * 24 + 12] == 255)  // inside the filled disc
        #expect(mask[2 * 24 + 2] == 0)
        #expect(throws: VectorIconError.self) { try VectorIcon(name: "bad", svg: #"<path d="M4 4 L x"/>"#) }
        #expect(throws: VectorIconError.self) { try VectorIcon(name: "none", svg: "<g></g>") }
    }

    /// Icons go into the draw list's glyph atlas once per pixel size, on whole pixels.
    @Test func drawListRasterizesPerPixelSize() throws {
        let icon = try #require(VectorIcon.named("video"))
        let list = UIDrawList()
        for (scale, zoom) in [(Float(1), Float(1)), (2, 1), (1, 2), (1.5, 1), (2, 1.25)] {
            list.beginFrame(framebufferSize: (800, 600), scale: scale)
            list.withTransform(scale: zoom) {
                list.drawIcon(icon, in: UIRect(x: 10.3, y: 20.6, width: 16, height: 16), color: .white)
            }
            let size = Int((16 * scale * zoom).rounded())
            #expect(list.glyphAtlas.info(for: icon, pixels: size) != nil)
            // One quad, its corners on whole pixels, as large as the bitmap.
            #expect(list.vertices.count == 4)
            let p0 = list.vertices[0].position, p2 = list.vertices[2].position
            #expect(p0.x == p0.x.rounded() && p0.y == p0.y.rounded())
            #expect(p2.x - p0.x == Float(size) && p2.y - p0.y == Float(size))
        }
        let count = list.glyphAtlas.iconCount
        list.beginFrame(framebufferSize: (800, 600), scale: 2)
        list.drawIcon(icon, in: UIRect(x: 0, y: 0, width: 16, height: 16), color: .white)
        #expect(list.glyphAtlas.iconCount == count)  // cached
    }

    // MARK: What gets an icon

    /// Every component type the engine and editor register has its own icon (not the fallback),
    /// and every icon name the editor uses exists in the built-in set.
    @Test func everyComponentTypeHasAnIcon() throws {
        EditorComponentCatalog.registerBuiltins()
        for name in EditorComponentCatalog.addableNames where !name.hasPrefix("GameModuleTest") && !name.hasPrefix("EditorIconTests") {
            #expect(EditorIcons.hasIcon(forComponent: name), "\(name) uses the fallback icon")
        }
        for name in ["Transform", "Name", "Camera", "DirectionalLight", "PointLight", "SpotLight", "SceneEnvironment", "PostProcess",
                     "MeshRenderer", "Collider", "RigidBody", "Joint", "CharacterController", "RigidBody2D", "Collider2D", "Joint2D",
                     "AudioListener", "AudioEmitter", "ParticleEmitter", "Sprite", "SpriteAnimator", "Animator", "Skin", "Saveable",
                     "Replicated", "Unpickable", "PrefabInstance", "Spin", "KeyboardMover"] {
            #expect(EditorIcons.hasIcon(forComponent: name), "\(name)")
        }
        let used = Array(EditorIcons.componentIconNames.values) + Array(EditorIcons.panelIconNames.values)
            + ["plus", "copy", "trash-2", "eraser", "layers", "circle-dashed", "file-plus", "folder-open", "save", "save-all", "undo-2",
               "redo-2", "play", "square", "pause", "step-forward", "gamepad-2", "refresh-cw", "loader", "hammer", "magnet",
               "folder-input", "folder-plus", "layout-dashboard", "file-down", "palette", "pencil", "list", "layout-grid", "plug",
               "plug-zap", "bot", "package-plus", "package-open", "package-check", "rotate-ccw", "unlink", "circle-x", "orbit",
               "appearance", "mesh-sphere", "mesh-plane", "mesh-cylinder", "mesh-custom"]
        for name in used { #expect(VectorIcon.named(name) != nil || EditorIcons.editorIcon(name) != nil, "\(name)") }
        // An unknown component gets the fallback.
        #expect(!EditorIcons.hasIcon(forComponent: "EditorIconTestsUnknown"))
        #expect(EditorIcons.component("EditorIconTestsUnknown").name == EditorIcons.fallbackComponent)
        // Distinct icons for what the hierarchy tells apart.
        let distinct = ["Camera", "DirectionalLight", "PointLight", "SpotLight", "MeshRenderer", "ParticleEmitter", "AudioEmitter",
                        "AudioListener", "Sprite"].map { EditorIcons.component($0).name }
        #expect(Set(distinct).count == distinct.count)
    }

    @Test func everyAssetKindHasAnIcon() {
        var names = Set<String>()
        for kind in EditorIcons.AssetIconKind.allCases {
            let icon = EditorIcons.asset(kind)
            #expect(icon.name != EditorIcons.fallbackComponent, "\(kind)")
            names.insert(icon.name)
        }
        #expect(names.count == EditorIcons.AssetIconKind.allCases.count)  // all different
        #expect(EditorIcons.assetKind(.folder, path: "Props") == .folder)
        #expect(EditorIcons.assetKind(.model, path: "crate.glb") == .model)
        #expect(EditorIcons.assetKind(.file, path: "Audio/hit.wav") == .audio)
        #expect(EditorIcons.assetKind(.file, path: "Levels/main scene.json") == .scene)
        #expect(EditorIcons.assetKind(.file, path: "notes.txt") == .text)
        #expect(EditorIcons.assetKind(.file, path: "data.bin") == .file)
        #expect(EditorIcons.assetKind(forFile: "Red.material") == .material)
        #expect(EditorIcons.assetKind(forFile: "Crate.prefab") == .prefab)
        for kind in AssetKind.allCases { #expect(EditorIcons.AssetIconKind(kind).rawValue == kind.rawValue) }
    }

    @Test func entitiesAreShownByTheirMainComponent() {
        let world = World()
        let camera = world.spawn(Transform(), Camera())
        let sun = world.spawn(Transform(), DirectionalLight())
        let lamp = world.spawn(Transform(), MeshRenderer(mesh: .cube), PointLight())
        let mesh = world.spawn(Transform(), MeshRenderer(mesh: .sphere))
        let sparks = world.spawn(Transform(), ParticleEmitter())
        let speaker = world.spawn(Transform(), AudioEmitter())
        var box = Collider(.box(halfExtents: Vec3(1, 1, 1)))
        box.isTrigger = true
        let trigger = world.spawn(Transform(), box)
        let empty = world.spawn(Transform())
        let group = world.spawn(Transform())
        _ = world.setParent(mesh, to: group)
        #expect(EditorIcons.entityKind(camera, in: world).kind == .camera)
        #expect(EditorIcons.entityKind(sun, in: world).kind == .directionalLight)
        #expect(EditorIcons.entityKind(lamp, in: world).kind == .pointLight)  // the light, though it has a mesh
        #expect(EditorIcons.entityKind(mesh, in: world).kind == .mesh)
        #expect(EditorIcons.entityKind(sparks, in: world).kind == .particles)
        #expect(EditorIcons.entityKind(speaker, in: world).kind == .audioEmitter)
        #expect(EditorIcons.entityKind(trigger, in: world).kind == .trigger)
        #expect(EditorIcons.entityKind(empty, in: world).kind == .empty)
        #expect(EditorIcons.entityKind(group, in: world).kind == .group)
        #expect(EditorIcons.entityIcon(camera, in: world).name == "video")
        #expect(EditorIcons.entityIcon(empty, in: world).name == "circle-dashed")
        // Billboards: entities without a mesh that have nothing else to click (not the lamp, mesh or empty).
        world.propagateTransforms()
        let billboarded = Set(EditorIcons.billboards(in: world).map(\.entity))
        #expect(billboarded == [camera, sun, sparks, speaker, trigger])
    }

    /// A prefab instance's root shows the prefab icon, though it renders a mesh.
    @Test func prefabRootsShowThePrefabIcon() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("EditorIconTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        session.newDocument()
        try #require(session.run(ProjectNewCommand.self, .init(path: folder.path)) != nil)
        let cube = try #require(session.run(EntityCreateCommand.self, .init(template: .cube)))
        try #require(session.run(PrefabCreateCommand.self, .init(entity: cube.entity)) != nil)
        let entity = try #require(session.world.entity(for: cube.entity))
        #expect(session.world.has(PrefabInstance.self, for: entity))
        #expect(EditorIcons.entityKind(entity, in: session.world).kind == .prefab)
        #expect(EditorIcons.entityIcon(entity, in: session.world).name == EditorIcons.prefabIconName)
        // The prefab file in the asset browser has the same mark.
        #expect(EditorIcons.asset(.prefab).name == EditorIcons.prefabIconName)
    }

    // MARK: Re-review after icons (card #660)

    /// The editor's own icons (mesh shapes, the prefab mark, Appearance) parse and draw like Lucide's.
    @Test func editorIconsParseAndDraw() throws {
        #expect(!EditorIcons.editorIconSVG.isEmpty)
        for name in EditorIcons.editorIconSVG.keys {
            #expect(VectorIcon.named(name) == nil, "\(name) shadows a Lucide icon")
            let icon = try #require(EditorIcons.editorIcon(name), "\(name)")
            #expect(EditorIcons.named(name) == icon)
            for pixels in [16, 24, 32] {
                let mask = icon.rasterize(pixels: pixels)
                let covered = mask.filter { $0 > 127 }.count
                #expect(covered > 8 && covered < pixels * pixels * 3 / 4, "\(name) at \(pixels) px: \(covered) pixels")
                // Solid line pixels (diagonal-only shapes reach a little less).
                #expect((mask.max() ?? 0) >= 230, "\(name) at \(pixels) px: no solid line pixels")
            }
        }
    }

    /// Meshes are told apart by shape (#660: every mesh entity had the cube), and a prefab
    /// doesn't look like a mesh: the 16-pixel masks differ in a good share of their ink.
    @Test func meshKindsAndPrefabsHaveDistinctIcons() throws {
        #expect(EditorIcons.meshIconName(.cube) == "box")
        #expect(EditorIcons.meshIconName(.sphere) == "mesh-sphere")
        #expect(EditorIcons.meshIconName(.plane) == "mesh-plane")
        #expect(EditorIcons.meshIconName(MeshHandle("sphere-hi")) == "mesh-sphere")
        #expect(EditorIcons.meshIconName(MeshHandle("floor")) == "mesh-plane")
        #expect(EditorIcons.meshIconName(MeshHandle("capsule")) == "mesh-cylinder")
        #expect(EditorIcons.meshIconName(MeshHandle("hero")) == "mesh-custom")
        let model = MeshHandle(AssetReference(AssetID(high: 1, low: 2), subAsset: "mesh/Box"))
        #expect(EditorIcons.meshIconName(model) == "mesh-custom")

        let world = World()
        let ball = world.spawn(Transform(), MeshRenderer(mesh: .sphere))
        let floor = world.spawn(Transform(), MeshRenderer(mesh: .plane))
        let crate = world.spawn(Transform(), MeshRenderer(mesh: .cube))
        #expect(EditorIcons.entityIcon(ball, in: world).name == "mesh-sphere")
        #expect(EditorIcons.entityIcon(floor, in: world).name == "mesh-plane")
        #expect(EditorIcons.entityIcon(crate, in: world).name == "box")
        // The Create menu shows the same shapes.
        #expect(EntityTemplate.allCases.map { EditorIcons.template($0).name } == ["circle-dashed", "box", "mesh-sphere", "mesh-plane"])

        let names = ["box", "mesh-sphere", "mesh-plane", "mesh-cylinder", "mesh-custom", EditorIcons.prefabIconName]
        let masks = names.map { EditorIcons.named($0).rasterize(pixels: 16).map { Float($0) / 255 } }
        for i in names.indices {
            for j in names.indices where j > i {
                let difference = zip(masks[i], masks[j]).reduce(Float(0)) { $0 + abs($1.0 - $1.1) }
                let ink = max(masks[i].reduce(0, +), masks[j].reduce(0, +))
                #expect(difference / ink > 0.5, "\(names[i]) and \(names[j]) look alike: \(difference / ink)")
            }
        }
    }

    /// WCAG 1.4.11: icon glyphs at 3:1 against what they are drawn on, in every theme: tinted
    /// icons (prefab instances, folders, the selected tab), disabled toolbar icons, menu icons,
    /// and the viewport billboards over bright and dark scene content.
    @Test func iconGlyphsHaveContrastInEveryTheme() {
        func solid(_ c: UIColor) -> UIColor { c.a < 1 ? c.composited(over: .black) : c }
        for theme in UITheme.presets {
            let panel = solid(theme.panelBackground)
            let selectedRow = theme.rowSelectedFocused.composited(over: panel)
            let pairs: [(String, UIColor, UIColor)] = [
                ("row icon", theme.secondaryTextColor, panel),
                ("selected row icon", theme.textColor, selectedRow),
                ("prefab icon", EditorIcons.prefabColor(theme: theme), panel),
                ("folder icon", EditorIcons.assetColor(.folder, theme: theme), panel),
                ("asset icon, selected cell", theme.textColor, selectedRow),
                ("selected tab icon", theme.accent.mixed(with: theme.textColor, 0.35), panel),
                ("toolbar icon", theme.textColor, theme.controlBackground.composited(over: panel)),
                ("disabled toolbar icon", theme.disabledTextColor, theme.controlBackground.fading(0.5).composited(over: panel)),
                ("menu icon", theme.secondaryTextColor, solid(theme.popupBackground)),
                ("highlighted menu icon", theme.accentText, solid(theme.accent)),
            ]
            for (what, glyph, background) in pairs {
                let ratio = glyph.contrastRatio(with: background)
                #expect(ratio >= 3, "\(theme.name): \(what) is \(ratio):1")
            }
        }
        // Billboards: a translucent dark disc over the scene, judged over white and black.
        let layer = ViewportBillboards()
        for kind in EditorIcons.EntityKind.allCases where kind.hasBillboard {
            for scene in [UIColor.white, .black, UIColor(hex: 0x8fb4e8)] {
                let disc = layer.background.composited(over: scene)
                let ratio = kind.billboardColor.contrastRatio(with: disc)
                #expect(ratio >= 3, "\(kind) billboard over \(scene): \(ratio):1")
            }
        }
        for fill in [layer.primaryColor, layer.secondaryColor] {
            #expect(layer.selectedIconColor.contrastRatio(with: fill) >= 3)
        }
    }

    // MARK: Games

    @Test func gamesRegisterIconsForTheirComponents() throws {
        let module = GameModule()
        module.component(EditorIconTestsComponent.self, icon: "orbit") { EditorIconTestsComponent() }
        module.icon(#"<circle cx="12" cy="12" r="9"/>"#, for: "EditorIconTestsOther")
        #expect(module.componentIcons == ["EditorIconTestsComponent": "orbit", "EditorIconTestsOther": #"<circle cx="12" cy="12" r="9"/>"#])

        defer { EditorIcons.unregister(["EditorIconTestsComponent", "EditorIconTestsOther"]) }
        #expect(!EditorIcons.hasIcon(forComponent: "EditorIconTestsComponent"))
        try EditorIcons.register("orbit", forComponent: "EditorIconTestsComponent")
        try EditorIcons.register(#"<circle cx="12" cy="12" r="9"/>"#, forComponent: "EditorIconTestsOther")
        #expect(EditorIcons.component("EditorIconTestsComponent").name == "orbit")
        #expect(EditorIcons.component("EditorIconTestsOther").svg.contains("circle"))
        #expect(throws: (any Error).self) { try EditorIcons.register("no-such-icon", forComponent: "EditorIconTestsBad") }
        #expect(throws: (any Error).self) { try EditorIcons.register(#"<path d="M1 x"/>"#, forComponent: "EditorIconTestsBad") }
        // A registered game component names an entity's main kind when nothing built in does.
        let world = World()
        let entity = world.spawn(Transform(), EditorIconTestsComponent())
        let main = EditorIcons.entityKind(entity, in: world)
        #expect(main.kind == .game && main.component == "EditorIconTestsComponent")
        EditorIcons.unregister(["EditorIconTestsComponent"])
        #expect(EditorIcons.component("EditorIconTestsComponent").name == EditorIcons.fallbackComponent)
    }

    // MARK: Billboards

    @Test func billboardsArePickedAndOccluded() throws {
        let world = World()
        let meshes = PickMeshLibrary()
        let light = world.spawn(Transform(position: Vec3(0, 0, -6)), PointLight())
        let wall = world.spawn(Transform(position: Vec3(2, 0, -3)), MeshRenderer(mesh: .cube))
        let hidden = world.spawn(Transform(position: Vec3(4, 0, -6)), AudioEmitter())  // right behind the wall
        world.propagateTransforms()
        let size = Vec2(800, 600)
        let view = ViewportProjection(view: Mat4.lookAt(eye: .zero, target: Vec3(0, 0, -1)),
                                      projection: Mat4.perspective(fovY: .pi / 3, aspect: size.x / size.y, near: 0.1, far: 100),
                                      size: size)
        let picker = ScenePicker(meshes: meshes)
        let layer = ViewportBillboards()
        picker.billboards = layer
        layer.update(EditorIcons.billboards(in: world), view: view, occluders: picker, world: world)
        #expect(layer.placed.count == 2)
        let placedLight = try #require(layer.placed.first { $0.entity == light })
        let placedHidden = try #require(layer.placed.first { $0.entity == hidden })
        #expect(!placedLight.isOccluded && placedHidden.isOccluded)
        #expect(abs(placedLight.rect.center.x - 400) < 0.01 && abs(placedLight.rect.center.y - 300) < 0.01)
        #expect(placedLight.rect.width == layer.size)

        // A click on the light's icon (anywhere on its disc) selects the light; nothing is there as a mesh.
        #expect(picker.pick(at: Vec2(400, 300), in: view, world: world)?.entity == light)
        #expect(picker.pick(at: Vec2(400 + layer.size / 2 - 2, 300), in: view, world: world)?.entity == light)
        #expect(picker.pick(at: Vec2(400 + layer.size, 300), in: view, world: world) == nil)
        // The faded icon behind the wall loses to the wall.
        #expect(picker.pick(at: placedHidden.rect.center, in: view, world: world)?.entity == wall)
        // Screen size is constant: farther away, same size.
        world.modify(Transform.self, for: light) { $0.position.z = -40 }
        world.propagateTransforms()
        layer.update(EditorIcons.billboards(in: world), view: view, occluders: picker, world: world)
        #expect(layer.placed.first { $0.entity == light }?.rect.width == layer.size)
        // Behind the camera: not placed.
        world.modify(Transform.self, for: light) { $0.position.z = 5 }
        world.propagateTransforms()
        layer.update(EditorIcons.billboards(in: world), view: view, occluders: picker, world: world)
        #expect(!layer.placed.contains { $0.entity == light })
    }

    /// The editor's own click path: a click on a billboard in the viewport selects its entity,
    /// and the selected billboard is drawn highlighted.
    @Test func clickingABillboardInTheViewportSelectsItsEntity() throws {
        let app = EditorApp(options: EditorOptions(deterministic: true))
        app.setupWithoutWindow(size: Vec2(1280, 720))
        let session = app.session
        let created = try #require(session.run(EntityCreateCommand.self, .init(template: .empty, position: Vec3(0, 6, 0))))
        let entity = try #require(session.world.entity(for: created.entity))
        session.world.add(AudioEmitter(), to: entity)
        session.world.propagateTransforms()
        session.run(SelectionClearCommand.self)
        // A click on empty space lays the billboards out for the current view.
        let rect = app.viewportWidget.frame
        let corner = Vec2(rect.x + 2, rect.maxY - 2)
        try app.viewportPointer([.init(position: corner, pressed: [.left], down: [.left]), .init(position: corner, released: [.left])],
                                modifiers: [])
        let placed = try #require(app.transformTool.billboards.placed.first { $0.entity == entity })
        let point = Vec2(rect.x, rect.y) + placed.rect.center
        #expect(app.isViewportPoint(point))
        try app.viewportPointer([.init(position: point, pressed: [.left], down: [.left]), .init(position: point, released: [.left])],
                                modifiers: [])
        #expect(session.selection.primary == created.entity)
        #expect(app.viewportWidget.selectionState(entity) == .primary)
    }

    // MARK: Toolbar and accessibility

    /// The toolbar is icon-only: one row at 1280 and 800 points wide, every button keeps its
    /// title as its label in ui.snapshot and has a tooltip.
    @Test func toolbarFitsOneRowAndKeepsLabels() throws {
        for width in [Float(1280), 800] {
            let app = EditorApp(options: EditorOptions(deterministic: true))
            app.setupWithoutWindow(size: Vec2(width, 600))
            let toolbar = app.toolbar.view
            let buttons = toolbar.children.compactMap { $0 as? Button }.filter { !$0.isHidden }
            #expect(buttons.count >= 17)
            let rowHeight = app.ui.theme.controlHeight + toolbar.padding.vertical
            let layout = toolbar.children.filter { !$0.isHidden }.map { "\($0.name) \($0.frame.x),\($0.frame.y) \($0.frame.width)" }
            #expect(toolbar.frame.height <= rowHeight + 0.5, "\(width) pt: toolbar \(toolbar.frame.height) pt tall: \(layout)")
            let elements = app.ui.accessibilityElements()
            for button in buttons {
                #expect(button.icon != nil && !button.showsTitle, "\(button.name)")
                #expect(!(button.tooltip(at: button.frame.center) ?? "").isEmpty, "\(button.name)")
                let element = try #require(elements.first { $0.widget === button })
                #expect(element.label == button.title, "\(button.name): \(element.label ?? "nil")")
                #expect(element.path == "editorRoot/toolbar/\(button.name)")
            }
        }
    }

    /// Writes every built-in icon at 16, 24 and 32 px to `ICON_SHEET` (a PNG), for looking at.
    @Test func contactSheet() throws {
        guard let path = ProcessInfo.processInfo.environment["ICON_SHEET"] else { return }
        let names = VectorIcon.builtinNames + EditorIcons.editorIconSVG.keys.sorted()
        let sizes = [16, 24, 32, 48]
        let cellWidth = 140, cellHeight = 56, columns = 8
        let rows = (names.count + columns - 1) / columns
        let width = columns * cellWidth, height = rows * cellHeight
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        for (i, name) in names.enumerated() {
            let icon = EditorIcons.named(name)
            var x = (i % columns) * cellWidth + 2
            let y = (i / columns) * cellHeight + 4
            for size in sizes {
                let mask = icon.rasterize(pixels: size)
                for row in 0..<size {
                    for column in 0..<size {
                        let value = 255 - mask[row * size + column]
                        let o = ((y + row) * width + x + column) * 4
                        pixels[o] = value
                        pixels[o + 1] = value
                        pixels[o + 2] = value
                    }
                }
                x += size + 4
            }
        }
        try Image(width: width, height: height, pixels: pixels).writePNG(to: URL(fileURLWithPath: path))
    }
}

/// A game component for the icon tests.
struct EditorIconTestsComponent: Component, Codable, Equatable, Sendable {
    static let componentName = "EditorIconTestsComponent"
    var value: Float = 0
}
