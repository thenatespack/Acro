import Engine
import Foundation

// The builder tabs (Mesh Builder, Terrain Builder, Dialogue…) plug into the editor through
// `EditorBuilderModule`s instead of being named here, so most of them can live in modules of
// their own (Sources/EditorBuilders*) that depend on EditorCore and compile in parallel with
// each other (release builds compile a module as one job). A module gives its commands, how to
// make its tab for an `EditorApp`, its "New …" entry in the Assets panel, how its files open
// and its section of the asset inspector. `EditorBuilderRegistry` holds them: the Editor
// executable registers every module at launch (`EditorBuilders.registerAll()`); hosts that
// don't (tests) get them looked up on first use. The Sound Builder, Post-FX and Data Table tabs
// are still in EditorCore and register themselves the same way (EditorCoreBuilders below).

/// One builder tab and everything the editor needs to know about it.
@MainActor
public struct EditorBuilderModule {
    /// The tab's dock panel id (an `EditorLayout` id); it also orders the modules
    /// (`EditorBuilderRegistry.panelOrder`).
    package let panelID: String
    package let title: String
    package var minSize = Vec2(320, 200)
    /// Viewport tabs let pointer events through to their 3D view.
    package var passesPointerThrough = false
    package var commands: [any EditorCommand.Type]
    /// Makes the tab's workspace for an app being set up (`EditorApp.buildUI`).
    package var makeTab: @MainActor (EditorApp) -> EditorBuilderTab
    /// The tab's asset type: the browser's "New …" entry and how its files open.
    package var asset: EditorBuilderAsset?
    /// The tab's section of the asset inspector for `id`, if it is one of its files (widgets
    /// added in order), else nil.
    package var inspector: (@MainActor (EditorBuilderInspection) -> [Widget]?)?

    package init(panelID: String, title: String, minSize: Vec2 = Vec2(320, 200), passesPointerThrough: Bool = false,
                 commands: [any EditorCommand.Type], asset: EditorBuilderAsset?,
                 inspector: (@MainActor (EditorBuilderInspection) -> [Widget]?)? = nil,
                 makeTab: @escaping @MainActor (EditorApp) -> EditorBuilderTab) {
        self.panelID = panelID
        self.title = title
        self.minSize = minSize
        self.passesPointerThrough = passesPointerThrough
        self.commands = commands
        self.asset = asset
        self.inspector = inspector
        self.makeTab = makeTab
    }
}

/// A builder's asset type in the Assets panel.
@MainActor
package struct EditorBuilderAsset {
    /// Whether the asset is one of the builder's files.
    package var isFile: @MainActor (EditorSession, AssetID) -> Bool
    /// "New Mesh Build": the browser's context menu entry, and the command it runs.
    package var newTitle: String
    package var newCommand: CommandID
    /// Creates a file in a folder (under `Assets/`) with the new command; nil on failure (logged).
    package var create: @MainActor (EditorSession, String) -> AssetID?
    /// Opens a file in the tab with the builder's open command (double-click).
    package var open: @MainActor (EditorSession, AssetID) -> Void
    /// The command `open` runs, for buttons that open a file elsewhere (the Inspector's Material section).
    package var openCommand: CommandID?

    package init(isFile: @escaping @MainActor (EditorSession, AssetID) -> Bool, newTitle: String, newCommand: CommandID,
                 create: @escaping @MainActor (EditorSession, String) -> AssetID?, open: @escaping @MainActor (EditorSession, AssetID) -> Void,
                 openCommand: CommandID? = nil) {
        self.openCommand = openCommand
        self.isFile = isFile
        self.newTitle = newTitle
        self.newCommand = newCommand
        self.create = create
        self.open = open
    }
}

/// What a builder's asset inspector section is for.
@MainActor
package struct EditorBuilderInspection {
    package let session: EditorSession
    package let asset: AssetID
    /// The inspector's caption style for a line of explanation.
    package let note: @MainActor (String) -> Label
}

/// A builder tab made for an app: its workspace and how the app drives it each frame.
@MainActor
package struct EditorBuilderTab {
    /// The workspace object (`MeshBuilderWorkspace`…), found again by type (`EditorApp.builderWorkspace`).
    package let workspace: AnyObject
    package let view: Widget
    /// Each frame while the editor (not the launcher) shows: the tab's pointer input and dt.
    package var update: (@MainActor (ViewportInput, Float) -> Void)?
    /// Each frame before the viewport's: this frame's key presses and the pointer (UI points),
    /// when no text field or overlay has the keyboard.
    package var handleKeys: (@MainActor ([KeyEvent], Vec2) -> Void)?
    /// Sizes the tab's render target before painting (backing pixels per UI point).
    package var prepareFrame: (@MainActor (Float) -> Void)?
    /// Renders the tab's view.
    package var render: (@MainActor (Frame) -> Void)?
    /// Routes the session's "open" for the tab's files to it (`session.onOpen…`); called once
    /// the app has opened its project and scene.
    package var connect: (@MainActor () -> Void)?
    /// The tab's side panel (its settings and forms), shown in the Inspector while the tab is in
    /// front so its view gets the tab's whole width (`EditorApp.syncBuilderSidebars`). Found in
    /// `view`: the last child of its body row (an `HStack` named "…Body") after a vertical
    /// `Separator`. nil when the tab has none.
    package var sidebar: Widget?

    package init(workspace: AnyObject, view: Widget, update: (@MainActor (ViewportInput, Float) -> Void)? = nil,
                 handleKeys: (@MainActor ([KeyEvent], Vec2) -> Void)? = nil, prepareFrame: (@MainActor (Float) -> Void)? = nil,
                 render: (@MainActor (Frame) -> Void)? = nil, connect: (@MainActor () -> Void)? = nil) {
        self.workspace = workspace
        self.view = view
        self.update = update
        self.handleKeys = handleKeys
        self.prepareFrame = prepareFrame
        self.render = render
        self.connect = connect
        sidebar = Self.findSidebar(in: view)
    }

    /// The side panel of a builder laid out as `[main, Separator(.vertical), side]` in an
    /// `HStack` named "…Body" (every builder tab is), else nil.
    package static func findSidebar(in root: Widget) -> Widget? {
        var stack: [Widget] = [root]
        while let node = stack.popLast() {
            let children = node.children
            if node is HStack, node.name.hasSuffix("Body"), children.count >= 3, children[children.count - 2] is Separator {
                return children.last
            }
            stack.append(contentsOf: children.reversed())
        }
        return nil
    }

    /// A tab with a 3D view (`EditorViewportBuilder`): the app's device and quality, and its
    /// update, prepare and render.
    package static func viewport<W: EditorViewportBuilder>(_ workspace: W, app: EditorApp, connect: (@MainActor () -> Void)? = nil) -> EditorBuilderTab {
        workspace.device = app.builderDevice
        if let quality = app.builderQuality { workspace.quality = quality }
        passPointerThrough(to: workspace.viewportWidget, in: workspace.view)
        return EditorBuilderTab(workspace: workspace, view: workspace.view,
                                update: { [unowned workspace] input, dt in workspace.update(input: input, dt: dt) },
                                prepareFrame: { [unowned workspace] scale in workspace.prepareFrame(pixelScale: scale) },
                                render: { [unowned workspace] frame in workspace.render(frame: frame) },
                                connect: connect)
    }

    /// Makes the containers around `viewport` (up to `root`: stacks, and plain `Widget`s that
    /// hold the view and its overlays) transparent to the pointer, as the viewport itself is.
    /// Otherwise a click or drag over the 3D view hits a container, the UI claims the pointer
    /// (`UIContext.wantsPointer`) and the view never orbits, pans or zooms. They are layout
    /// only, with no events of their own; their other children (the sidebar, an overlay) still
    /// get the pointer.
    static func passPointerThrough(to viewport: Widget, in root: Widget) {
        var node = viewport.parent
        while let container = node, container is Stack || type(of: container) == Widget.self {
            container.isHitTestable = false
            if container === root { break }
            node = container.parent
        }
    }
}

/// A builder workspace with its own 3D view, rendered with the app's device.
@MainActor
package protocol EditorViewportBuilder: AnyObject {
    var view: VStack { get }
    /// The 3D view inside `view`.
    var viewportWidget: ViewportWidget { get }
    var device: RenderDevice? { get set }
    var quality: RenderQuality { get set }
    func update(input: ViewportInput?, dt: Float)
    func prepareFrame(pixelScale: Float)
    func render(frame: Frame)
}

/// Every builder module, in `panelOrder`.
@MainActor
package enum EditorBuilderRegistry {
    /// The order of the builder tabs: their dock panels, the browser's "New …" entries, their
    /// frame updates.
    package static let panelOrder = [
        EditorLayout.meshBuilder, EditorLayout.vfxBuilder, EditorLayout.soundBuilder, EditorLayout.postFXBuilder,
        EditorLayout.dataTable, EditorLayout.visualScript, EditorLayout.terrainBuilder, EditorLayout.spriteBuilder,
        EditorLayout.tilemapBuilder, EditorLayout.gridMapBuilder, EditorLayout.pathBuilder, EditorLayout.behaviorTree,
        EditorLayout.uiBuilder, EditorLayout.dialogueBuilder, EditorLayout.timeline, EditorLayout.animationGraph,
        EditorLayout.characterBuilder, EditorLayout.materialBuilder, EditorLayout.groomBuilder,
    ]

    private static var registered: [EditorBuilderModule] = EditorCoreBuilders.modules
    private static var lookedUp = false

    /// Adds `module` (replacing one with the same panel id).
    package static func register(_ module: EditorBuilderModule) {
        registered.removeAll { $0.panelID == module.panelID }
        registered.append(module)
        registered.sort { order($0.panelID) < order($1.panelID) }
    }

    package static func register(_ modules: [EditorBuilderModule]) {
        for module in modules { register(module) }
    }

    private static func order(_ panelID: String) -> Int { panelOrder.firstIndex(of: panelID) ?? panelOrder.count }

    /// The builder that opens file `id`, if any.
    package static func module(forFile id: AssetID, in session: EditorSession) -> EditorBuilderModule? {
        modules.first { $0.asset?.isFile(session, id) == true }
    }

    /// The mangled name of `EditorBuilders.EditorBuilders` (`_mangledTypeName`; a demangled
    /// "Module.Type" name only finds classes). EditorTests checks it.
    package static let providerTypeName = "14EditorBuildersAAO"

    /// Every registered module. When the host hasn't registered the builder modules (tests,
    /// tools that make sessions themselves) they are looked up the first time: the
    /// `EditorBuilders` module's `EditorBuilders` type, if it is linked in.
    package static var modules: [EditorBuilderModule] {
        if !lookedUp {
            lookedUp = true
            if registered.count < panelOrder.count, let provider = _typeByName(providerTypeName) as? any EditorBuilderProvider.Type {
                provider.registerAll()
            }
        }
        return registered
    }

    /// Every registered module's commands.
    package static var commands: [any EditorCommand.Type] { modules.flatMap(\.commands) }
}

/// The type that registers every builder module (`EditorBuilders.EditorBuilders`), which
/// `EditorBuilderRegistry` finds by name when the host didn't register them.
@MainActor
public protocol EditorBuilderProvider {
    static func registerAll()
}

extension EditorApp {
    /// The registered builder tab whose workspace is a `W` (`meshWorkspace`…).
    package func builderWorkspace<W: AnyObject>(_ type: W.Type) -> W? {
        for tab in builderTabs { if let workspace = tab.workspace as? W { return workspace } }
        return nil
    }
}

/// The builder tabs still in EditorCore.
@MainActor
enum EditorCoreBuilders {
    static var modules: [EditorBuilderModule] { [sound, postFX, dataTable] }

    static var sound: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.soundBuilder, title: "Sound Builder", commands: EditorSoundBuildCommands.all,
                            asset: EditorBuilderAsset(isFile: { $0.isSoundBuildFile($1) }, newTitle: "New Sound", newCommand: SoundBuildNewCommand.id,
                                                      create: { $0.run(SoundBuildNewCommand.self, .init(folder: $1))?.asset },
                                                      open: { $0.run(SoundBuildOpenCommand.self, .init(asset: AssetReference($1))) }),
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isSoundBuildFile(id) else { return nil }
            let open = Button("Open in Sound Builder", role: .primary, name: "openSoundBuilder") { [unowned session] in
                session.run(SoundBuildOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = SoundBuildOpenCommand.id.rawValue
            open.tooltip = "Edit this sound in the Sound Builder tab (or double-click it in the Assets panel)"
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("A synthesized sound effect. Set an AudioEmitter's clip to it to play it in the game.")]
        }) { app in
            let workspace = SoundBuilderWorkspace(session: app.session)
            return EditorBuilderTab(workspace: workspace, view: workspace.view, update: { [unowned workspace] _, _ in workspace.update() },
                                    connect: { [unowned app, unowned workspace] in
                app.session.onOpenSoundBuild = { [unowned app] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.soundBuilder)
                }
            })
        }
    }

    static var postFX: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.postFXBuilder, title: "Post-FX", passesPointerThrough: true, commands: EditorPostFXCommands.all,
                            asset: EditorBuilderAsset(isFile: { $0.isPostFXFile($1) }, newTitle: "New Post-FX", newCommand: PostFXNewCommand.id,
                                                      create: { $0.run(PostFXNewCommand.self, .init(folder: $1))?.asset },
                                                      open: { $0.run(PostFXOpenCommand.self, .init(asset: AssetReference($1))) }),
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isPostFXFile(id) else { return nil }
            let open = Button("Open in Post-FX Builder", role: .primary, name: "openPostFXBuilder") { [unowned session] in
                session.run(PostFXOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = PostFXOpenCommand.id.rawValue
            open.tooltip = "Edit this look in the Post-FX tab (or double-click it in the Assets panel)"
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("A camera look. Assign it with postfx.assign, a camera's Post FX field or a PostFXVolume.")]
        }) { app in
            let workspace = PostFXWorkspace(session: app.session)
            return .viewport(workspace, app: app) { [unowned app, unowned workspace] in
                app.session.onOpenPostFX = { [unowned app] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.postFXBuilder)
                }
            }
        }
    }

    static var dataTable: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.dataTable, title: "Data Table", commands: EditorDataTableCommands.all,
                            asset: EditorBuilderAsset(isFile: { $0.isTableFile($1) }, newTitle: "New Data Table", newCommand: TableNewCommand.id,
                                                      create: { $0.run(TableNewCommand.self, .init(folder: $1))?.asset },
                                                      open: { $0.run(TableOpenCommand.self, .init(asset: AssetReference($1))) }),
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isTableFile(id) else { return nil }
            let open = Button("Open in Data Table", role: .primary, name: "openDataTable") { [unowned session] in
                session.run(TableOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = TableOpenCommand.id.rawValue
            open.tooltip = "Edit this table in the Data Table tab (or double-click it in the Assets panel)"
            let table = session.assets?.dataTableContents(of: id)
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("A data table of \(table?.rows.count ?? 0) rows and \(table?.columns.count ?? 0) columns. Game code reads it with assets.dataTable(path:)?.row(id)?.number(column).")]
        }) { app in
            let workspace = DataTableWorkspace(session: app.session)
            return EditorBuilderTab(workspace: workspace, view: workspace.view, update: { [unowned workspace] _, _ in workspace.update() },
                                    connect: { [unowned app, unowned workspace] in
                app.session.onOpenTable = { [unowned app] id in
                    guard workspace.open(id) else { return }
                    // The Data Table opens where the Scene view is: tabbed with the viewport.
                    app.showBuilderPanel(EditorLayout.dataTable)
                }
            })
        }
    }
}

extension PostFXWorkspace: EditorViewportBuilder {}
