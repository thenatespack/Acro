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
public enum EntityTemplate: String, CaseIterable, Sendable {
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
/// the current tool and play mode, and every action the toolbar, menus, shortcuts and panels
/// trigger. Edits go through the document's `UndoStack`; failures are logged rather than thrown.
///
/// ## Play mode
/// `play()` takes a `world.snapshot()`, turns undo recording off and from then on `tick(dt:)`
/// runs the world's systems (`world.update`). Edits while playing are allowed and applied but
/// not recorded, and they are lost on stop. `stop()` restores the snapshot and turns recording
/// back on, so the undo history is exactly as before. The selection stores `EntityID`s, which
/// the snapshot keeps, so it survives. Saving, New and Open are refused while playing.
@MainActor
public final class EditorSession {
    public let document: EditorDocument
    public let selection = EditorSelection()
    public let log: EditorLog
    public var tool: EditorTool = .move { didSet { if tool != oldValue { changed() } } }
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

    /// The asset the inspector shows instead of the selected entity (picked in the asset
    /// browser). Selecting entities clears it.
    public var inspectedAsset: AssetItem? {
        didSet { if inspectedAsset != oldValue { onInspectedAssetChange?() } }
    }
    /// Called after `inspectedAsset` changed.
    public var onInspectedAssetChange: (() -> Void)?

    private var playSnapshot: WorldSnapshot?

    public var world: World { document.world }
    public var undo: UndoStack { document.undo }
    public var isPlaying: Bool { playState == .playing }

    public init(document: EditorDocument = EditorDocument(), log: EditorLog = EditorLog()) {
        self.document = document
        self.log = log
        EditorComponentCatalog.registerBuiltins()
        ImportSettingsForms.registerBuiltins()
        document.world.addEditorSystems()
        document.onReload = { [unowned self] in selection.prune(in: world) }
        selection.observe { [unowned self] selection in if !selection.isEmpty { inspectedAsset = nil } }
    }

    /// Advances the world one frame: its systems in play mode, only transforms while editing.
    public func tick(dt: Double) {
        if isPlaying {
            world.update(dt: dt)
        } else {
            world.propagateTransforms()
        }
    }

    // MARK: Document

    public func newDocument() {
        guard !refuseWhilePlaying("New") else { return }
        onWillReplaceWorld?()
        document.newDocument()
        log.info("New scene")
        changed()
    }

    @discardableResult
    public func open(path: String) -> Bool {
        guard !refuseWhilePlaying("Open") else { return false }
        let url = Self.url(forPath: path)
        onWillReplaceWorld?()
        do {
            try document.open(url)
            log.info("Opened \(url.lastPathComponent) (\(world.entityCount) entities)")
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
        do {
            try document.save()
            log.info("Saved \(document.displayName)")
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
        let url = Self.url(forPath: path)
        do {
            try document.save(to: url)
            log.info("Saved \(url.path)")
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
        let url = Self.url(forPath: path)
        do {
            setProject(try Project.open(at: url), verb: "Opened")
            return true
        } catch {
            log.error("Couldn't open the project at \(url.path): \(error)")
            return false
        }
    }

    /// Creates a project at `path` (a new or existing folder without a project) and opens it.
    @discardableResult
    public func newProject(path: String) -> Bool {
        let url = Self.url(forPath: path)
        do {
            setProject(try Project.create(at: url), verb: "Created")
            return true
        } catch {
            log.error("Couldn't create a project at \(url.path): \(error)")
            return false
        }
    }

    /// Feeds file changes under `Assets/` (from a `FileWatcher`) to the database.
    public func assetsChanged(_ changes: [FileChange]) {
        guard let assets, !changes.isEmpty else { return }
        logReport(assets.reimport(changed: changes), prefix: "Assets changed")
    }

    private func setProject(_ project: Project, verb: String) {
        let database = AssetDatabase(project: project)
        let report = database.refresh()
        assets = database
        inspectedAsset = nil
        log.info("\(verb) project \(project.name) (\(database.records.count) assets: \(report.summary))")
        logReport(report, prefix: nil)
        database.onChange = { [unowned self] _ in onAssetsChange?() }
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

    public func performUndo() {
        do {
            if try undo.undo() { changed() }
        } catch {
            log.error("Undo failed: \(error)")
            changed()
        }
    }

    public func performRedo() {
        do {
            if try undo.redo() { changed() }
        } catch {
            log.error("Redo failed: \(error)")
            changed()
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

    public func play() {
        guard !isPlaying else { return }
        onWillReplaceWorld?()
        playSnapshot = world.snapshot()
        undo.isRecording = false
        playState = .playing
        log.info("Play")
        changed()
    }

    public func stop() {
        guard isPlaying, let snapshot = playSnapshot else { return }
        onWillReplaceWorld?()
        world.restore(snapshot)
        world.propagateTransforms()
        playSnapshot = nil
        undo.isRecording = true
        playState = .editing
        log.info("Stop: scene restored")
        changed()
    }

    public func togglePlay() { if isPlaying { stop() } else { play() } }

    // MARK: Entities

    /// Creates an entity from `template` at `position` (a root; selected afterwards).
    @discardableResult
    public func create(_ template: EntityTemplate, at position: Vec3 = .zero) -> EntityID? {
        do {
            let command = try SpawnCommand(components: template.components(at: position), name: uniqueName(template.title),
                                           in: world, label: "Create \(template.title)")
            guard perform(command) else { return nil }
            selection.set(command.rootIDs)
            return command.rootIDs.first
        } catch {
            log.error("Create \(template.title) failed: \(error)")
            return nil
        }
    }

    /// Duplicates the selected subtrees next to their originals (one undo step) and selects the copies.
    public func duplicateSelection() {
        let originals = selection.topLevelEntities(in: world)
        guard !originals.isEmpty else { return }
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
    }

    /// Deletes the selected subtrees (one undo step) and clears the selection.
    public func deleteSelection() {
        let doomed = selection.topLevelEntities(in: world)
        guard !doomed.isEmpty else { return }
        undo.beginGroup(doomed.count == 1 ? "Delete Entity" : "Delete \(doomed.count) Entities")
        defer { undo.endGroup(); changed() }
        for entity in doomed {
            do { try undo.perform(DespawnCommand(entity, in: world)) } catch { log.error("Delete failed: \(error)") }
        }
        selection.clear()
    }

    public func rename(_ id: EntityID, to name: String) {
        guard let entity = world.entity(for: id), world.get(Name.self, for: entity)?.value != name else { return }
        do { perform(try RenameCommand(entity, to: name, in: world)) } catch { log.error("Rename failed: \(error)") }
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

    public func addComponent(named name: String, to id: EntityID) {
        guard let entity = world.entity(for: id) else { return }
        guard let component = EditorComponentCatalog.makeDefault(named: name) else {
            log.error("Add component: \(EditorError.unknownComponent(name))")
            return
        }
        do { perform(try AddComponentCommand(entity, component, in: world)) } catch { log.error("Add \(name) failed: \(error)") }
    }

    public func removeComponent(named name: String, from id: EntityID) {
        guard let entity = world.entity(for: id) else { return }
        guard let type = ComponentRegistry.type(named: name) else {
            log.error("Remove component: \(EditorError.unknownComponent(name))")
            return
        }
        do { perform(try RemoveComponentCommand(entity, type, in: world)) } catch { log.error("Remove \(name) failed: \(error)") }
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
/// group, `.changed` applies the value live (unrecorded), and `.ended` records a single
/// `SetFieldCommand` from the value at `.began` to the final one and closes the group. A whole
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
            do {
                try world.setField(edit.path, of: edit.componentName, for: edit.entity, to: edit.newValue)
            } catch {
                session.log.error("Edit \(edit.componentName).\(edit.path) failed: \(error)")
            }
        case .ended:
            if edit.newValue != edit.oldValue, let id = world.id(of: edit.entity) {
                session.perform(SetFieldCommand(id: id, component: edit.componentName, path: edit.path,
                                                old: edit.oldValue, new: edit.newValue))
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
