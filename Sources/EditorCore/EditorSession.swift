import Engine
import Foundation

/// The transform tool the toolbar selects. The viewport passes it to its tools
/// (`ViewportToolContext.toolMode`); the gizmos that act on it plug in as `ViewportTool`s.
public enum EditorTool: String, CaseIterable, Codable, Sendable {
    case move, rotate, scale

    public var title: String {
        switch self {
        case .move: "Move"
        case .rotate: "Rotate"
        case .scale: "Scale"
        }
    }
}

public enum PlayState: Sendable, Equatable {
    case editing, playing
}

/// What the "Create" menu makes.
public enum EntityTemplate: String, CaseIterable, Codable, Sendable {
    case empty, cube, sphere, plane

    public var title: String {
        switch self {
        case .empty: "Empty"
        case .cube: "Cube"
        case .sphere: "Sphere"
        case .plane: "Plane"
        }
    }

    @MainActor func components(at position: Vec3) -> [any Component] {
        let transform = Transform(position: position)
        switch self {
        case .empty: return [transform]
        case .cube: return [transform, MeshRenderer(mesh: .cube)]
        case .sphere: return [transform, MeshRenderer(mesh: .sphere)]
        case .plane: return [Transform(position: position, scale: Vec3(4, 1, 4)), MeshRenderer(mesh: .plane)]
        }
    }
}

/// The editor's model, independent of any GPU or window: the document, the selection, the log,
/// the current tool and play mode, and the actions behind every command (`commands`, the
/// `CommandRegistry` the toolbar, menus, shortcuts and panels run). Edits go through the
/// document's `UndoStack`; failures are logged rather than thrown.
///
/// ## Play mode
/// `play()` takes a `world.snapshot()`, turns undo recording off and from then on `tick(dt:)`
/// runs the world's systems (`world.update`). Edits while playing are allowed and applied but
/// not recorded, and they are lost on stop. `stop()` restores the snapshot and turns recording
/// back on, so the undo history is exactly as before. The selection stores `EntityID`s, which
/// the snapshot keeps, so it survives. Saving, New and Open are refused while playing.
///
/// While playing, `isPaused` stops the world (`setPaused`), `step(frames:dt:)` runs frames at a
/// fixed dt, and `timeScale` scales real dt. Game systems read `gameInput`, fed by the app (the
/// keyboard and mouse over the game view) and by `inputPlayer` scripts (`input.inject`), never
/// the window's input. The session's systems (physics for colliders, sprite animation, tweens)
/// are added on play and removed on stop (see EditorPlayCommands.swift).
@MainActor
public final class EditorSession {
    public let document: EditorDocument
    public let selection = EditorSelection()
    public let log: EditorLog
    public var tool: EditorTool = .move { didSet { if tool != oldValue { changed() } } }
    /// Gizmo drags snap (0.5 units, 15°, 0.1 scale steps); holding Cmd/Ctrl inverts it for one drag.
    public var snapping = false { didSet { if snapping != oldValue { changed() } } }
    public private(set) var playState: PlayState = .editing
    /// Called after the tool, the play state or the document changed (toolbar refresh).
    public var onChange: (() -> Void)?
    /// Called before play / stop / reload, to end in-progress edits (an inspector drag's undo group).
    public var onWillReplaceWorld: (() -> Void)?

    /// The open project's asset database (nil without a project). Its meshes and materials
    /// show in the inspector's dropdowns, and `MeshRenderer`s can reference them.
    public private(set) var assets: AssetDatabase?
    public var project: Project? { assets?.project }
    /// Called after a project was opened or created, or its assets changed.
    public var onAssetsChange: (() -> Void)?
    /// The projects opened before, for the launcher (RecentProjects.swift); every project
    /// opened or created goes to its top. The app loads and saves it with the prefs.
    public let recentProjects = RecentProjectList()
    /// The scene was saved (to its file or a new one); the app refreshes the project's thumbnail.
    public var onSceneSaved: (() -> Void)?

    /// The asset the inspector shows instead of the selected entity (picked in the asset
    /// browser). Selecting entities clears it.
    public var inspectedAsset: AssetItem? {
        didSet { if inspectedAsset != oldValue { onInspectedAssetChange?() } }
    }
    /// Called after `inspectedAsset` changed.
    public var onInspectedAssetChange: (() -> Void)?
    /// Shows an asset in the browser (a path under `Assets/`, `file#sub-asset` for an object;
    /// the app reveals it). Set by the app; `selectAsset` calls it.
    public var onRevealAsset: ((String) -> Void)?

    /// Keeps the scene's prefab instances in step with their prefabs (see EditorSession+Prefabs.swift).
    public let prefabs = PrefabSync()
    /// A prefab changed while playing: instances are rebuilt on Stop.
    var prefabSyncPending = false
    /// Set while an action updates instances itself (Extract Materials).
    var suspendsPrefabSync = false

    /// Every editor action by id (see EditorCommand.swift). The UI runs these, never the
    /// methods below directly.
    public private(set) lazy var commands: CommandRegistry = {
        let registry = CommandRegistry(session: self)
        registry.register(BuiltinCommands.all)
        return registry
    }()
    /// The application around the session, for commands that act on its widgets (layout, camera).
    public weak var host: (any EditorHost)?
    /// The batch `edit.beginBatch` opened (one undo group until `edit.endBatch`), if any.
    public internal(set) var batch: EditorBatch?
    /// Meshes for picking without a host renderer: the built-in shapes and the project's meshes.
    public private(set) lazy var cpuPickMeshes = EditorPickMeshes(session: self)
    /// What `view.pick` and `scene.raycast` test against: the host's renderer, else `cpuPickMeshes`.
    public var pickMeshes: any PickMeshSource { host?.pickMeshes ?? cpuPickMeshes }

    /// Every call AI clients made, for the Activity panel (see EditorSafety.swift).
    public let activity = EditorActivityLog()
    /// What AI clients may do (read-only, confirmations, HTTP); persisted in the prefs by the app.
    public var aiSettings = AISettings() {
        didSet { if aiSettings != oldValue { onAISettingsChange?(); changed() } }
    }
    /// Called after `aiSettings` changed.
    public var onAISettingsChange: (() -> Void)?
    /// While set, file paths given to actions must lie inside one of these folders (the MCP
    /// server sets the project folder around each call); relative paths resolve against the
    /// first. Nil: anywhere, relative to the working directory.
    public var fileAccessRoots: [URL]?

    var playSnapshot: WorldSnapshot?

    /// Play mode is paused: the world doesn't update and scheduled input waits (`setPaused`, `step`).
    public private(set) var isPaused = false
    /// The game code (EditorGameModule.swift): loaded from a library, reloaded with the scene kept.
    public private(set) lazy var gameModule = EditorGameModule(session: self)
    /// Build Game (EditorBuildGame.swift): cooking and exporting in the background.
    public private(set) lazy var gameExport = EditorGameExport(session: self)
    /// Keeps unsaved work recoverable after a crash (EditorRecovery.swift); set by the app when
    /// it has a prefs folder.
    public var recovery: EditorRecovery?
    /// Multiplies play mode's dt (0 to 100; 1 is real time). Steps ignore it.
    public var timeScale: Double = 1 {
        didSet {
            timeScale = min(max(timeScale.isFinite ? timeScale : 1, 0), 100)
            if timeScale != oldValue { changed() }
        }
    }
    /// Game frames and seconds of game time run in this play session.
    public private(set) var playFrame = 0
    public private(set) var playTime: Double = 0
    /// What game systems read in play mode instead of the window's input, so the editor's own
    /// keys and clicks never reach them. It is fed by `inputPlayer` (`input.inject`) and by
    /// the real keyboard and mouse the app forwards while the viewport shows the game camera.
    /// Capture it in your systems: `world.addSystem("player") { [session] world in session.gameInput.isDown(.w) … }`.
    public let gameInput = Input()
    /// Scripted input for `gameInput`, over game time; a new one each play session.
    public private(set) var inputPlayer = InputPlayer()
    private var forwardedInput: [InputEvent] = []
    /// Whether the viewport shows the scene's Camera entity while playing (`view.gameCamera`);
    /// the editor camera otherwise. On by default.
    public var showsGameCamera = true { didSet { if showsGameCamera != oldValue { changed() } } }
    /// The play session's physics, when the scene has colliders (see `addPlaySystems`).
    public private(set) var physics: PhysicsWorld?
    /// The play session's 2D physics, when the scene has `Collider2D`s.
    public private(set) var physics2D: PhysicsWorld2D?
    /// Tweens for the play session, updated after the world each game frame.
    public private(set) var tweens: TweenSystem?
    /// Network play: this world as a server plus client worlds (`net.start`, EditorNetPlay.swift).
    public internal(set) var netPlay: EditorNetPlay?

    public var world: World { document.world }
    public var undo: UndoStack { document.undo }
    public var isPlaying: Bool { playState == .playing }

    public init(document: EditorDocument = EditorDocument(), log: EditorLog = EditorLog()) {
        self.document = document
        self.log = log
        EditorComponentCatalog.registerBuiltins()
        ImportSettingsForms.registerBuiltins()
        document.world.addEditorSystems(input: gameInput)
        document.onReload = { [unowned self] in
            selection.prune(in: world)
            // A scene was opened (or a new one made): its instances follow their prefabs as they are now.
            prefabs.reset()
            syncPrefabs(force: true)
        }
        selection.observe { [unowned self] selection in if !selection.isEmpty { inspectedAsset = nil } }
    }

    /// Advances the world one frame: its systems in play mode (dt times `timeScale`; nothing
    /// while paused), only transforms while editing.
    public func tick(dt: Double) {
        gameModule.poll()
        gameExport.poll()
        if isPlaying && !isPaused {
            advanceGame(dt: dt * timeScale)
        } else {
            world.propagateTransforms()
        }
    }

    // MARK: Document

    @discardableResult
    public func newDocument(empty: Bool = false) -> Bool {
        guard !refuseWhilePlaying("New") else { return false }
        onWillReplaceWorld?()
        document.newDocument(empty: empty)
        log.info("New scene")
        changed()
        return true
    }

    @discardableResult
    public func open(path: String) -> Bool {
        guard !refuseWhilePlaying("Open") else { return false }
        guard let url = fileURL(forPath: path, "Open") else { return false }
        onWillReplaceWorld?()
        do {
            try document.open(url)
            log.info("Opened \(url.lastPathComponent) (\(world.entityCount) entities)")
            noteSceneInProject()
            changed()
            return true
        } catch {
            log.error("Couldn't open \(url.path): \(error)")
            return false
        }
    }

    /// Saves to the document's file, or to `fallbackPath` when it has none yet.
    @discardableResult
    public func save(fallbackPath: String? = nil) -> Bool {
        if document.url == nil, let fallbackPath, !fallbackPath.trimmingCharacters(in: .whitespaces).isEmpty {
            return save(as: fallbackPath)
        }
        guard !refuseWhilePlaying("Save") else { return false }
        if let url = document.url, !checkFileAccess(url, "Save") { return false }
        refreshPrefabOverrides()
        do {
            try document.save()
            log.info("Saved \(document.displayName)")
            noteSceneInProject()
            onSceneSaved?()
            changed()
            return true
        } catch {
            log.error("Couldn't save: \(error)")
            return false
        }
    }

    @discardableResult
    public func save(as path: String) -> Bool {
        guard !refuseWhilePlaying("Save As") else { return false }
        guard let url = fileURL(forPath: path, "Save As") else { return false }
        refreshPrefabOverrides()
        do {
            try document.save(to: url)
            log.info("Saved \(url.path)")
            noteSceneInProject()
            onSceneSaved?()
            changed()
            return true
        } catch {
            log.error("Couldn't save \(url.path): \(error)")
            return false
        }
    }

    /// A file URL for a path typed by the user (`~` expanded, relative to the working directory).
    public static func url(forPath path: String) -> URL {
        let expanded = (path.trimmingCharacters(in: .whitespaces) as NSString).expandingTildeInPath
        return URL(fileURLWithPath: expanded).standardizedFileURL
    }

    // MARK: Project

    /// Opens the project at `path` (its folder or its `Project.json`), scans its assets and
    /// imports what changed. The scene stays open.
    @discardableResult
    public func openProject(path: String) -> Bool {
        guard let url = fileURL(forPath: path, "Open Project") else { return false }
        do {
            setProject(try Project.open(at: url), verb: "Opened")
            return true
        } catch {
            log.error("Couldn't open the project at \(url.path): \(error)")
            return false
        }
    }

    /// Creates a project at `path` (a new or existing folder without a project) and opens it.
    /// With a `template` it is filled from it and its scene opened (an empty one for `.empty`),
    /// replacing the open scene; without, the scene stays. `name` defaults to the folder's.
    @discardableResult
    public func newProject(path: String, name: String? = nil, template: ProjectTemplate? = nil) -> Bool {
        guard let url = fileURL(forPath: path, "New Project") else { return false }
        if template != nil, refuseWhilePlaying("New Project") { return false }
        if let reason = template?.unavailableReason {
            log.error("New Project: \(reason)")
            return false
        }
        let created: (project: Project, scene: URL?)
        do {
            created = try (template ?? .empty).create(at: url, name: name.flatMap { $0.isEmpty ? nil : $0 })
        } catch {
            log.error("Couldn't create a project at \(url.path): \(error)")
            return false
        }
        setProject(created.project, verb: "Created")
        guard template != nil else { return true }
        if let scene = created.scene { return open(path: scene.path) }
        return newDocument(empty: true)
    }

    /// The document's file is in the open project: remember it as the project's last scene.
    private func noteSceneInProject() {
        guard let project, let url = document.url else { return }
        recentProjects.noteScene(url, in: project)
    }

    /// Closes the open project (the scene stays open; asset references in it stay as they are).
    /// Returns false when no project is open.
    @discardableResult
    public func closeProject() -> Bool {
        guard let assets else {
            log.warning("Close Project: no project is open")
            return false
        }
        assets.stopWatching()
        assets.onChange = nil
        self.assets = nil
        inspectedAsset = nil
        prefabs.reset()
        log.info("Closed project \(assets.project.name)")
        onAssetsChange?()
        changed()
        return true
    }

    /// Feeds file changes under `Assets/` (from a `FileWatcher`) to the database.
    public func assetsChanged(_ changes: [FileChange]) {
        guard let assets, !changes.isEmpty else { return }
        // Errors and warnings are logged by the database's `onChange`, as each report arrives.
        let report = assets.reimportAsync(changed: changes)
        if report.hasChanges { log.info("Assets changed: \(report.summary)") }
        if assets.isLoading { log.info("Importing \(assets.pendingLoadCount) assets in the background") }
    }

    private func setProject(_ project: Project, verb: String) {
        assets?.stopWatching()
        assets?.onChange = nil
        prefabs.reset()
        let database = AssetDatabase(project: project)
        // Imports run in the background (the viewport draws placeholders until they finish);
        // `ENGINE_SCREENSHOT` runs wait so the picture is complete.
        let report = database.refreshAsync()
        assets = database
        inspectedAsset = nil
        log.info("\(verb) project \(project.name) (\(database.records.count) assets: \(report.summary))")
        if database.isLoading { log.info("Importing \(database.pendingLoadCount) assets in the background") }
        logReport(report, prefix: nil)
        database.onChange = { [unowned self, unowned database] report in
            logReport(report, prefix: nil)
            if report.hasChanges && !database.isLoading && report.imported.count > 0 { log.info("Assets ready: \(report.summary)") }
            // Prefab instances follow reimported prefabs (and models).
            if !report.imported.isEmpty || !report.removed.isEmpty { syncPrefabs() }
            onAssetsChange?()
        }
        if ProcessInfo.processInfo.environment["ENGINE_SCREENSHOT"] != nil { database.waitForAll() }
        recentProjects.noteOpened(project)
        noteSceneInProject()
        gameModule.projectOpened(project)
        syncPrefabs(force: true)
        onAssetsChange?()
        changed()
    }

    private func logReport(_ report: AssetScanReport, prefix: String?) {
        if let prefix, report.hasChanges || !report.errors.isEmpty { log.info("\(prefix): \(report.summary)") }
        for (path, message) in report.errors { log.error("\(path): \(message)") }
        for warning in report.warnings { log.warning(warning) }
        for (path, old, new) in report.reassigned {
            log.warning("\(path) had the same asset id as another file (\(old.description.prefix(8))); it now has \(new.description.prefix(8))")
        }
    }

    // MARK: Undo

    /// Undoes the last step. Returns false when there was nothing to undo or it failed.
    @discardableResult
    public func performUndo() -> Bool {
        do {
            guard try undo.undo() else { return false }
            changed()
            return true
        } catch {
            log.error("Undo failed: \(error)")
            changed()
            return false
        }
    }

    @discardableResult
    public func performRedo() -> Bool {
        do {
            guard try undo.redo() else { return false }
            changed()
            return true
        } catch {
            log.error("Redo failed: \(error)")
            changed()
            return false
        }
    }

    /// Runs `command` through the undo stack, logging a failure. Returns whether it succeeded.
    @discardableResult
    public func perform(_ command: some UndoCommand) -> Bool {
        do {
            try undo.perform(command)
            changed()
            return true
        } catch {
            log.error("\(command.label) failed: \(error)")
            return false
        }
    }

    // MARK: Play mode

    /// Enters play mode (`paused`: paused before the first frame, for stepping from the start).
    public func play(paused: Bool = false) {
        guard !isPlaying else { return }
        onWillReplaceWorld?()
        playSnapshot = world.snapshot()
        undo.isRecording = false
        playState = .playing
        isPaused = paused
        playFrame = 0
        playTime = 0
        gameInput.reset()
        inputPlayer = InputPlayer()
        forwardedInput.removeAll()
        addPlaySystems()
        log.info(paused ? "Play (paused)" : "Play")
        changed()
    }

    public func stop() {
        guard isPlaying, let snapshot = playSnapshot else { return }
        onWillReplaceWorld?()
        endNetPlay(reason: nil)
        removePlaySystems()
        world.restore(snapshot)
        world.propagateTransforms()
        playSnapshot = nil
        undo.isRecording = true
        playState = .editing
        isPaused = false
        gameInput.reset()
        inputPlayer.clear()
        forwardedInput.removeAll()
        log.info("Stop: scene restored")
        if prefabSyncPending {
            prefabSyncPending = false
            syncPrefabs()
        }
        changed()
    }

    public func togglePlay() { if isPlaying { stop() } else { play() } }

    /// Pauses or resumes play mode. Paused, the world doesn't update (edits still apply) and
    /// scheduled input waits.
    public func setPaused(_ paused: Bool) {
        guard isPlaying, paused != isPaused else { return }
        isPaused = paused
        log.info(paused ? "Paused at frame \(playFrame)" : "Resumed")
        changed()
    }

    /// Pauses and runs `frames` game frames now, each `dt` seconds (default the world's fixed
    /// step), with the input scheduled for them. Deterministic: the same scene, script and
    /// steps give the same world. Returns false when not playing.
    @discardableResult
    public func step(frames: Int = 1, dt: Double? = nil) -> Bool {
        guard isPlaying else { return false }
        isPaused = true
        let dt = dt ?? world.fixedTimestep
        for _ in 0..<max(frames, 0) { advanceGame(dt: dt) }
        changed()
        return true
    }

    /// Like `step`, but stops early: after each frame `stop` says whether to. Returns the frames
    /// run (nil when not playing).
    public func step(maxFrames: Int, dt: Double? = nil, stopAfterFrame stop: () -> Bool) -> Int? {
        guard isPlaying else { return nil }
        isPaused = true
        let dt = dt ?? world.fixedTimestep
        var run = 0
        while run < max(maxFrames, 0) {
            advanceGame(dt: dt)
            run += 1
            if stop() { break }
        }
        changed()
        return run
    }

    /// Real input to hand the game in its next frame (the app forwards the keyboard and the
    /// mouse over the game view).
    public func forwardToGame(_ events: [InputEvent]) {
        guard isPlaying else { return }
        forwardedInput += events
    }

    /// One game frame: `gameInput` gets this frame's forwarded and scheduled events, the world
    /// updates by `dt`, then the input script's clock moves on.
    private func advanceGame(dt: Double) {
        gameInput.beginFrame()
        for event in forwardedInput { gameInput.inject(event) }
        forwardedInput.removeAll()
        inputPlayer.apply(to: gameInput)
        gameInput.endEvents()
        world.update(dt: dt)
        netPlay?.advance(dt: dt)
        tweens?.update(dt: Float(dt))
        inputPlayer.advance(by: dt)
        playFrame += 1
        playTime += dt
    }

    /// The play session's systems: physics (3D, 2D) when the scene has colliders, sprite animation when
    /// it has animators. Systems are code, not data, so the snapshot doesn't hold them: they
    /// are added on play and removed on stop, with a new `PhysicsWorld` each time.
    private func addPlaySystems() {
        if world.count(of: Collider.self) > 0 {
            let physics = PhysicsWorld()
            world.addPhysics(physics)
            self.physics = physics
        }
        if world.count(of: Collider2D.self) > 0 {
            let physics = PhysicsWorld2D()
            world.addPhysics2D(physics)
            physics2D = physics
        }
        if world.count(of: SpriteAnimator.self) > 0 { world.addSpriteAnimationSystem(name: Self.spriteSystem) }
        tweens = TweenSystem()
        gameModule.addSystems()
    }

    private func removePlaySystems() {
        if physics != nil {
            world.removePhysics()
            physics = nil
        }
        if physics2D != nil {
            world.removePhysics2D()
            physics2D = nil
        }
        world.removeSystem(named: Self.spriteSystem)
        tweens = nil
        gameModule.removeSystems()
    }

    private static let spriteSystem = "editor.spriteAnimation"

    // MARK: Entities

    /// Creates an entity from `template` at `position` (in `parent`'s space; default a root),
    /// named `name` (default the template's title, numbered when taken); selected afterwards.
    @discardableResult
    public func create(_ template: EntityTemplate, at position: Vec3 = .zero, name: String? = nil,
                       parent: EntityID? = nil) -> EntityID? {
        do {
            let parentEntity = try parent.map { try world.require($0) }
            let command = try SpawnCommand(components: template.components(at: position), name: name ?? uniqueName(template.title),
                                           parent: parentEntity, in: world, label: "Create \(template.title)")
            guard perform(command) else { return nil }
            selection.set(command.rootIDs)
            return command.rootIDs.first
        } catch {
            log.error("Create \(template.title) failed: \(error)")
            return nil
        }
    }

    /// Duplicates the selected subtrees next to their originals (one undo step) and selects the
    /// copies. Returns their ids.
    @discardableResult
    public func duplicateSelection() -> [EntityID] {
        duplicate(selection.topLevelEntities(in: world))
    }

    /// Duplicates `entities` with their subtrees next to the originals (one undo step) and
    /// selects the copies. An entity under another one in the list is copied with it, once.
    @discardableResult
    public func duplicate(_ entities: [Entity]) -> [EntityID] {
        let originals = topLevel(entities)
        guard !originals.isEmpty else { return [] }
        var copies: [EntityID] = []
        undo.beginGroup("Duplicate")
        defer { undo.endGroup(); changed() }
        for entity in originals {
            do {
                let index = (world.siblingIndex(of: entity) ?? 0) + 1
                let command = try SpawnCommand(duplicating: [entity], parent: world.parent(of: entity), index: index, in: world)
                try undo.perform(command)
                copies += command.rootIDs
            } catch {
                log.error("Duplicate failed: \(error)")
            }
        }
        selection.set(copies)
        return copies
    }

    /// Deletes the selected subtrees (one undo step) and clears the selection. Returns the
    /// number deleted.
    @discardableResult
    public func deleteSelection() -> Int {
        delete(selection.topLevelEntities(in: world))
    }

    /// Deletes `entities` with their subtrees (one undo step) and deselects what went. Returns
    /// the number of subtrees deleted.
    @discardableResult
    public func delete(_ entities: [Entity]) -> Int {
        let doomed = topLevel(entities)
        guard !doomed.isEmpty else { return 0 }
        undo.beginGroup(doomed.count == 1 ? "Delete Entity" : "Delete \(doomed.count) Entities")
        defer { undo.endGroup(); changed() }
        var deleted = 0
        for entity in doomed {
            do {
                try undo.perform(DespawnCommand(entity, in: world))
                deleted += 1
            } catch {
                log.error("Delete failed: \(error)")
            }
        }
        selection.prune(in: world)
        return deleted
    }

    /// The live ones of `entities` that have no ancestor among them, in order, without repeats.
    private func topLevel(_ entities: [Entity]) -> [Entity] {
        let set = Set(entities.filter { world.isAlive($0) })
        var seen = Set<Entity>()
        return entities.filter { entity in
            guard set.contains(entity), seen.insert(entity).inserted else { return false }
            var ancestor = world.parent(of: entity)
            while let current = ancestor {
                if set.contains(current) { return false }
                ancestor = world.parent(of: current)
            }
            return true
        }
    }

    /// Renames `id` (one undo step). Returns false when the entity is gone or it failed.
    @discardableResult
    public func rename(_ id: EntityID, to name: String) -> Bool {
        guard let entity = world.entity(for: id) else {
            log.error("Rename failed: \(UndoError.entityNotFound(id))")
            return false
        }
        guard world.get(Name.self, for: entity)?.value != name else { return true }
        do { return perform(try RenameCommand(entity, to: name, in: world)) } catch {
            log.error("Rename failed: \(error)")
            return false
        }
    }

    /// Moves `ids` (in order) to become children of `parent` (nil: roots) starting at `index`
    /// among its children once they have been taken out (`TreeDropTarget.index`), keeping their
    /// world transforms. One undo step. Returns whether every move succeeded.
    @discardableResult
    public func move(_ ids: [EntityID], to parent: EntityID?, at index: Int) -> Bool {
        guard !ids.isEmpty else { return true }
        let label = ids.count == 1 ? "Reparent" : "Reparent \(ids.count) Entities"
        if ids.count == 1 {
            return perform(ReparentCommand(id: ids[0], newParent: parent, index: index, keepWorldTransform: true, label: label))
        }
        // Several: first append them all to the new parent, in order (so the ones not yet
        // moved can't shift the positions of the ones already placed), then put each at its slot.
        undo.beginGroup(label)
        defer { undo.endGroup(); changed() }
        do {
            for id in ids {
                try undo.perform(ReparentCommand(id: id, newParent: parent, index: Int.max, keepWorldTransform: true))
            }
            for (k, id) in ids.enumerated() {
                try undo.perform(ReparentCommand(id: id, newParent: parent, index: index + k))
            }
            return true
        } catch {
            log.error("\(label) failed: \(error)")
            return false
        }
    }

    // MARK: Components

    /// Adds the catalog's default `name` component to `id` (one undo step). Returns whether it worked.
    @discardableResult
    public func addComponent(named name: String, to id: EntityID) -> Bool {
        guard let entity = world.entity(for: id) else {
            log.error("Add \(name) failed: \(UndoError.entityNotFound(id))")
            return false
        }
        guard let component = EditorComponentCatalog.makeDefault(named: name) else {
            log.error("Add component: \(EditorError.unknownComponent(name))")
            return false
        }
        do { return perform(try AddComponentCommand(entity, component, in: world)) } catch {
            log.error("Add \(name) failed: \(error)")
            return false
        }
    }

    /// Removes the `name` component from `id` (one undo step). Returns whether it worked.
    @discardableResult
    public func removeComponent(named name: String, from id: EntityID) -> Bool {
        guard let entity = world.entity(for: id) else {
            log.error("Remove \(name) failed: \(UndoError.entityNotFound(id))")
            return false
        }
        guard let type = ComponentRegistry.type(named: name) else {
            log.error("Remove component: \(EditorError.unknownComponent(name))")
            return false
        }
        do { return perform(try RemoveComponentCommand(entity, type, in: world)) } catch {
            log.error("Remove \(name) failed: \(error)")
            return false
        }
    }

    // MARK: Helpers

    /// The display name of `entity`: its `Name`, or "Entity <id prefix>".
    public func displayName(of entity: Entity) -> String {
        if let name = world.get(Name.self, for: entity)?.value, !name.isEmpty { return name }
        return Self.fallbackName(world.id(of: entity))
    }

    public static func fallbackName(_ id: EntityID?) -> String {
        id.map { "Entity \($0.description.prefix(8))" } ?? "Entity"
    }

    /// `base`, or `base 2`, `base 3`… so new entities are told apart in the hierarchy.
    private func uniqueName(_ base: String) -> String {
        var taken = Set<String>()
        world.query(Name.self) { _, name in taken.insert(name.value) }
        guard taken.contains(base) else { return base }
        var n = 2
        while taken.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

    private func refuseWhilePlaying(_ action: String) -> Bool {
        guard isPlaying else { return false }
        log.warning("\(action): \(EditorError.playing)")
        return true
    }

    func changed() { onChange?() }
}

/// Turns `PropertyGrid` edits into undo steps: one step per gesture. `.began` opens an undo
/// group, `.changed` applies the value live (`component.setField`, transient), and `.ended`
/// runs `component.setField` from the value at `.began` to the final one and closes the group. A whole
/// scrub or drag is then exactly one step, as is a typed value, and a gesture that ends where
/// it began records nothing. Use it with `grid.appliesEditsToWorld = false`.
@MainActor
public final class InspectorEditRecorder {
    public let session: EditorSession
    /// The gesture in progress (component, path), if any.
    public private(set) var openGesture: (component: String, path: String)?

    public init(session: EditorSession) {
        self.session = session
    }

    public func handle(_ edit: PropertyEdit) {
        let world = session.world
        switch edit.phase {
        case .began:
            finishGesture()
            session.undo.beginGroup("Edit \(edit.path)")
            openGesture = (edit.componentName, edit.path)
        case .changed:
            guard let id = world.id(of: edit.entity) else { return }
            session.run(ComponentSetFieldCommand.self, .init(entity: id, component: edit.componentName, path: edit.path,
                                                             value: edit.newValue, transient: true, in: world))
        case .ended:
            if edit.newValue != edit.oldValue, let id = world.id(of: edit.entity) {
                session.run(ComponentSetFieldCommand.self, .init(entity: id, component: edit.componentName, path: edit.path,
                                                                 value: edit.newValue, previous: edit.oldValue, in: world))
            }
            finishGesture()
        }
    }

    /// Closes a gesture whose `.ended` never came (the entity went away mid-drag, play started).
    public func finishGesture() {
        guard openGesture != nil else { return }
        openGesture = nil
        session.undo.endGroup()
        session.changed()
    }
}
