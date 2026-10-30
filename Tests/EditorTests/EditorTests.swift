import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// MARK: Helpers

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

@MainActor private func entity(named name: String, in session: EditorSession) -> Entity {
    var found: Entity?
    session.world.query(Name.self) { entity, n in if n.value == name { found = entity } }
    return found!
}

@MainActor private func id(_ name: String, _ session: EditorSession) -> EntityID {
    session.world.id(of: entity(named: name, in: session))!
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("EditorTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

/// Row titles with indentation, depth first, as the hierarchy tree shows them.
@MainActor private func treeTitles(_ tree: TreeView) -> [String] {
    var titles: [String] = []
    func visit(_ node: TreeNode, _ depth: Int) {
        titles.append(String(repeating: "  ", count: depth) + node.title)
        for child in node.children { visit(child, depth + 1) }
    }
    for root in tree.roots { visit(root, 0) }
    return titles
}

@MainActor private func worldTitles(_ session: EditorSession) -> [String] {
    HierarchyPanel.structure(of: session.world, name: session.displayName(of:))
        .map { String(repeating: "  ", count: $0.depth) + $0.title }
}

// MARK: Document

@MainActor @Suite struct EditorDocumentTests {
    @Test func newDocumentBuildsTheStarterSceneClean() {
        let session = makeSession()
        let world = session.world
        #expect(world.assignsEntityIDs)
        #expect(world.count(of: Camera.self) == 1)
        #expect(world.count(of: DirectionalLight.self) == 1)
        #expect(world.count(of: SceneEnvironment.self) == 1)
        #expect(world.count(of: Spin.self) == 1)
        #expect(world.children(of: entity(named: "Props", in: session)).count == 3)
        #expect(!session.document.isDirty)
        #expect(session.document.url == nil)
        #expect(session.document.title == "Untitled")
        for e in world.entities { #expect(world.id(of: e) != nil) }
    }

    @Test func saveOpenRoundTripAndDirtyState() throws {
        let session = makeSession()
        let dir = temporaryDirectory()
        let path = dir.appendingPathComponent("sub/level.json").path

        // Save without a file fails and is logged; Save with a fallback path does Save As.
        #expect(!session.save())
        #expect(session.log.count(of: .error) == 1)
        session.rename(id("Red Cube", session), to: "Crate")
        #expect(session.document.isDirty)
        #expect(session.document.title == "Untitled *")
        #expect(session.save(fallbackPath: path))
        #expect(!session.document.isDirty)
        #expect(session.document.displayName == "level.json")

        session.rename(id("Crate", session), to: "Box")
        #expect(session.document.isDirty)
        session.performUndo()
        #expect(!session.document.isDirty, "undoing back to the save point is clean")
        session.performRedo()
        #expect(session.save())

        // New, then open the file again: same content and ids, clean, history cleared.
        let savedIDs = Set(session.world.entities.compactMap { session.world.id(of: $0) })
        session.newDocument()
        #expect(session.document.url == nil)
        #expect(session.open(path: path))
        #expect(!session.document.isDirty)
        #expect(!session.undo.canUndo)
        #expect(session.displayName(of: entity(named: "Box", in: session)) == "Box")
        #expect(Set(session.world.entities.compactMap { session.world.id(of: $0) }) == savedIDs)
        #expect(try Data(contentsOf: URL(fileURLWithPath: path)) == (try session.world.save()))
    }

    @Test func openingABadFileKeepsTheDocument() throws {
        let session = makeSession()
        let dir = temporaryDirectory()
        let bad = dir.appendingPathComponent("bad.json")
        try Data("{ not a scene".utf8).write(to: bad)
        let before = try session.world.save()
        session.rename(id("Floor", session), to: "Ground")
        #expect(!session.open(path: bad.path))
        #expect(!session.open(path: dir.appendingPathComponent("missing.json").path))
        #expect(session.log.count(of: .error) == 2)
        #expect(session.undo.canUndo, "a failed open leaves the history alone")
        session.performUndo()
        #expect(try session.world.save() == before)
    }

    @Test func savingAndOpeningAreRefusedWhilePlaying() {
        let session = makeSession()
        let path = temporaryDirectory().appendingPathComponent("s.json").path
        session.play()
        #expect(!session.save(as: path))
        #expect(!FileManager.default.fileExists(atPath: path))
        session.newDocument()
        #expect(session.isPlaying)
        #expect(session.log.count(of: .warning) == 2)
        session.stop()
        #expect(session.save(as: path))
    }
}

// MARK: Selection

@MainActor @Suite struct EditorSelectionTests {
    @Test func setToggleAndNotifications() {
        let selection = EditorSelection()
        var notified = 0
        selection.observe { _ in notified += 1 }
        let a = EntityID(high: 1, low: 1), b = EntityID(high: 2, low: 2)
        selection.set([a, b, a])
        #expect(selection.ids == [a, b])
        #expect(selection.primary == b)
        selection.set([a, b])
        #expect(notified == 1, "no notification without a change")
        selection.toggle(b)
        #expect(selection.ids == [a] && selection.primary == a)
        selection.toggle(b)
        #expect(selection.primary == b)
        selection.clear()
        #expect(selection.isEmpty && selection.primary == nil)
        #expect(notified == 4)
    }

    @Test func survivesUndoRedoOfDeleteByID() {
        let session = makeSession()
        let cube = id("Red Cube", session)
        session.selection.set([cube, id("Floor", session)], primary: cube)
        session.rename(cube, to: "Renamed")
        session.performUndo()
        session.performRedo()
        #expect(session.selection.primaryEntity(in: session.world) == session.world.entity(for: cube))

        // Delete clears the selection; re-select, delete through a command, undo: the entity
        // comes back with the same id, so the stored selection resolves again.
        session.selection.select(cube)
        session.perform(DespawnCommand(id: cube))
        #expect(session.selection.primaryEntity(in: session.world) == nil)
        #expect(session.selection.ids == [cube])
        session.performUndo()
        #expect(session.selection.primaryEntity(in: session.world).flatMap { session.world.id(of: $0) } == cube)
    }

    @Test func topLevelEntitiesSkipSelectedDescendants() {
        let session = makeSession()
        session.selection.set([id("Hub", session), id("Spinner", session), id("Red Cube", session)])
        let top = session.selection.topLevelEntities(in: session.world).map(session.displayName(of:))
        #expect(top == ["Red Cube", "Spinner"])
    }

    @Test func pruneDropsDeadIDsOnOpen() throws {
        let session = makeSession()
        session.selection.select(EntityID(high: 9, low: 9))
        let path = temporaryDirectory().appendingPathComponent("p.json").path
        #expect(session.save(as: path))
        #expect(session.open(path: path))
        #expect(session.selection.isEmpty)
    }
}

// MARK: Entity commands

@MainActor @Suite struct EditorCommandTests {
    @Test func duplicateAndDeleteAreOneStepEach() throws {
        let session = makeSession()
        let world = session.world
        let before = try world.save()
        let props = entity(named: "Props", in: session)
        let spinner = id("Spinner", session)
        session.selection.set([id("Red Cube", session), spinner, id("Hub", session)])
        session.duplicateSelection()
        #expect(session.undo.undoDepth == 1)
        #expect(session.undo.undoTitle == "Undo Duplicate")
        // Copies sit right after their originals and are selected; the subtree came along.
        let copies = session.selection.entities(in: world)
        #expect(copies.count == 2)
        #expect(copies.allSatisfy { !world.isDescendant($0, of: props) || world.parent(of: $0) == props })
        #expect(world.children(of: props).map(session.displayName(of:)) == ["Red Cube", "Red Cube", "Blue Sphere", "Green Pillar"])
        let spinnerCopy = copies.first { world.get(Spin.self, for: $0) != nil }!
        #expect(world.children(of: spinnerCopy).count == 3)
        #expect(world.id(of: spinnerCopy) != spinner)

        session.selection.set(copies.compactMap { world.id(of: $0) })
        session.deleteSelection()
        #expect(session.selection.isEmpty)
        #expect(session.undo.undoDepth == 2)
        session.performUndo()
        session.performUndo()
        #expect(try world.save() == before)
        session.performRedo()
        #expect(world.count(of: Spin.self) == 2)
    }

    @Test func createSpawnsSelectedUniqueNamedEntities() {
        let session = makeSession()
        let first = session.create(.cube, at: Vec3(1, 2, 3))!
        let second = session.create(.cube)!
        let world = session.world
        #expect(session.selection.ids == [second])
        #expect(session.displayName(of: world.entity(for: first)!) == "Cube")
        #expect(session.displayName(of: world.entity(for: second)!) == "Cube 2")
        #expect(world.get(Transform.self, for: world.entity(for: first)!)?.position == Vec3(1, 2, 3))
        session.performUndo()
        #expect(world.entity(for: second) == nil)
    }

    @Test func moveSeveralEntitiesKeepsOrderAndWorldTransforms() throws {
        let session = makeSession()
        let world = session.world
        world.propagateTransforms()
        let cube = id("Red Cube", session), pillar = id("Green Pillar", session), spinner = id("Spinner", session)
        let worldBefore = world.worldMatrix(of: world.entity(for: cube)!)
        let before = try world.save()
        // Into the spinner at index 1 (between Hub and Arm A).
        #expect(session.move([pillar, cube], to: spinner, at: 1))
        #expect(world.children(of: world.entity(for: spinner)!).map(session.displayName(of:)) == ["Hub", "Green Pillar", "Red Cube", "Arm A", "Arm B"])
        let after = world.worldMatrix(of: world.entity(for: cube)!)
        #expect(abs(after.c3.x - worldBefore.c3.x) < 1e-4 && abs(after.c3.y - worldBefore.c3.y) < 1e-4)
        #expect(session.undo.undoDepth == 1)
        session.performUndo()
        #expect(try world.save() == before)

        // Reorder among the roots.
        #expect(session.move([spinner], to: nil, at: 0))
        #expect(session.displayName(of: world.roots[0]) == "Spinner")
    }

    @Test func addAndRemoveComponents() throws {
        let session = makeSession()
        let world = session.world
        let cube = id("Red Cube", session)
        let e = world.entity(for: cube)!
        let addable = EditorComponentCatalog.addableNames(for: e, in: world)
        #expect(addable.contains("Spin") && addable.contains("Camera"))
        #expect(!addable.contains("MeshRenderer") && !addable.contains("Transform") && !addable.contains("Name"))

        session.addComponent(named: "Spin", to: cube)
        #expect(world.get(Spin.self, for: e) == Spin())
        let tinted = world.get(MeshRenderer.self, for: e)!
        session.removeComponent(named: "MeshRenderer", from: cube)
        #expect(world.get(MeshRenderer.self, for: e) == nil)
        session.performUndo()
        #expect(world.get(MeshRenderer.self, for: e) == tinted, "undo restores the exact data")
        session.performUndo()
        #expect(world.get(Spin.self, for: e) == nil)

        session.addComponent(named: "NoSuchThing", to: cube)
        #expect(session.log.count(of: .error) == 1)
    }
}

// MARK: Inspector

@MainActor @Suite struct InspectorTests {
    @Test func aWholeDragIsOneUndoStep() throws {
        let session = makeSession()
        let world = session.world
        let recorder = InspectorEditRecorder(session: session)
        let e = entity(named: "Blue Sphere", in: session)
        let start = world.get(Transform.self, for: e)!.position
        func edit(_ value: Vec3, _ phase: PropertyEditPhase) -> PropertyEdit {
            PropertyEdit(entity: e, componentName: "Transform", path: "position", oldValue: .vec3(start), newValue: .vec3(value), phase: phase)
        }
        recorder.handle(edit(start, .began))
        for i in 1...20 {
            recorder.handle(edit(start + Vec3(Float(i) * 0.1, 0, 0), .changed))
            #expect(world.get(Transform.self, for: e)!.position.x == start.x + Float(i) * 0.1, "applied live")
            #expect(!session.undo.canUndo, "undo is blocked mid-gesture")
        }
        recorder.handle(edit(start + Vec3(2, 0, 0), .ended))
        #expect(session.undo.undoDepth == 1)
        #expect(session.undo.undoTitle == "Undo Edit position")
        #expect(recorder.openGesture == nil)
        session.performUndo()
        #expect(world.get(Transform.self, for: e)!.position == start)
        session.performRedo()
        #expect(world.get(Transform.self, for: e)!.position == start + Vec3(2, 0, 0))
    }

    @Test func typedValueIsOneStepAndANoOpGestureRecordsNothing() {
        let session = makeSession()
        let recorder = InspectorEditRecorder(session: session)
        let e = entity(named: "Spinner", in: session)
        func edit(_ old: Float, _ new: Float, _ phase: PropertyEditPhase) -> PropertyEdit {
            PropertyEdit(entity: e, componentName: "Spin", path: "speed", oldValue: .float(Double(old)), newValue: .float(Double(new)), phase: phase)
        }
        // Typing: all three phases in a row.
        recorder.handle(edit(1.2, 1.2, .began))
        recorder.handle(edit(1.2, 3, .changed))
        recorder.handle(edit(1.2, 3, .ended))
        #expect(session.undo.undoDepth == 1)
        #expect(session.world.get(Spin.self, for: e)!.speed == 3)
        // A scrub that comes back to where it started.
        recorder.handle(edit(3, 3, .began))
        recorder.handle(edit(3, 4, .changed))
        recorder.handle(edit(3, 3, .changed))
        recorder.handle(edit(3, 3, .ended))
        #expect(session.undo.undoDepth == 1)
    }

    @Test func aGestureCutShortIsClosed() {
        let session = makeSession()
        let recorder = InspectorEditRecorder(session: session)
        let e = entity(named: "Spinner", in: session)
        recorder.handle(PropertyEdit(entity: e, componentName: "Spin", path: "speed", oldValue: .float(1.2), newValue: .float(1.2), phase: .began))
        #expect(session.undo.isGrouping)
        session.onWillReplaceWorld = { recorder.finishGesture() }
        session.play()
        #expect(!session.undo.isGrouping)
        session.stop()
    }

    @Test func panelShowsThePrimaryAndRenames() {
        let session = makeSession()
        let panel = InspectorPanel(session: session)
        session.selection.set([id("Floor", session), id("Red Cube", session)], primary: id("Red Cube", session))
        panel.refresh()
        #expect(panel.grid.entity == entity(named: "Red Cube", in: session))
        #expect(panel.grid.componentNames == ["Transform", "MeshRenderer"])
        session.selection.clear()
        panel.refresh()
        #expect(panel.grid.entity == nil)
    }
}

// MARK: Hierarchy

@MainActor @Suite struct HierarchyTests {
    @Test func treeMirrorsTheWorldThroughUndoAndKeepsExpansion() {
        let session = makeSession()
        let panel = HierarchyPanel(session: session)
        #expect(treeTitles(panel.tree) == worldTitles(session))
        #expect(treeTitles(panel.tree).first == "Main Camera")

        let props = id("Props", session)
        panel.node(for: props)!.isExpanded = false
        let propsNode = panel.node(for: props)

        // Delete Props, sync, undo, sync: back, with the same node and its expansion state.
        session.selection.select(props)
        session.deleteSelection()
        panel.sync()
        #expect(!treeTitles(panel.tree).contains("Props"))
        session.performUndo()
        panel.sync()
        #expect(treeTitles(panel.tree) == worldTitles(session))
        #expect(panel.node(for: props) === propsNode)
        #expect(panel.node(for: props)?.isExpanded == false)

        // Reparent, then undo.
        session.move([id("Red Cube", session)], to: id("Spinner", session), at: 0)
        panel.sync()
        #expect(treeTitles(panel.tree) == worldTitles(session))
        #expect(treeTitles(panel.tree).contains("    Red Cube") == false)
        #expect(treeTitles(panel.tree).contains("  Red Cube"))
        session.performUndo()
        panel.sync()
        #expect(treeTitles(panel.tree) == worldTitles(session))

        // Renames show up too.
        session.rename(id("Floor", session), to: "Ground")
        panel.sync()
        #expect(treeTitles(panel.tree).contains("Ground"))
    }

    @Test func treeSyncsAfterPlayAndLoad() throws {
        let session = makeSession()
        let panel = HierarchyPanel(session: session)
        session.play()
        _ = session.world.spawn(Name("Spawned In Play"))
        panel.sync()
        #expect(treeTitles(panel.tree).contains("Spawned In Play"))
        session.stop()
        panel.sync()
        #expect(!treeTitles(panel.tree).contains("Spawned In Play"))
        #expect(treeTitles(panel.tree) == worldTitles(session))

        let path = temporaryDirectory().appendingPathComponent("h.json").path
        session.create(.sphere)
        #expect(session.save(as: path))
        session.newDocument()
        #expect(session.open(path: path))
        panel.sync()
        #expect(treeTitles(panel.tree) == worldTitles(session))
        #expect(treeTitles(panel.tree).contains("Sphere"))
    }

    @Test func selectionIsBoundBothWays() {
        let session = makeSession()
        let panel = HierarchyPanel(session: session)
        let cube = id("Red Cube", session), floor = id("Floor", session)

        session.selection.set([floor, cube], primary: cube)
        #expect(panel.tree.selectedNodes.compactMap { $0.userData as? EntityID } == [floor, cube])
        #expect(panel.tree.selectedNode?.userData as? EntityID == cube)

        panel.tree.select(panel.node(for: floor))
        #expect(session.selection.ids == [floor])
        #expect(session.selection.primary == floor)

        // Selecting an entity the tree doesn't show yet (a fresh duplicate) isn't undone by the tree.
        session.selection.select(floor)
        session.duplicateSelection()
        let copy = session.selection.primary!
        #expect(copy != floor)
        panel.sync()
        #expect(panel.tree.selectedNode?.userData as? EntityID == copy)
        #expect(session.selection.ids == [copy])
    }

    @Test func renameAndMoveCallbacksGoThroughTheUndoStack() {
        let session = makeSession()
        let panel = HierarchyPanel(session: session)
        let cubeNode = panel.node(for: id("Red Cube", session))!
        #expect(panel.tree.onRename?(cubeNode, "Crate") == true)
        #expect(session.undo.undoTitle == "Undo Rename")
        let spinner = panel.node(for: id("Spinner", session))!
        #expect(panel.tree.onMove?([cubeNode], spinner, 3) == true)
        #expect(session.world.children(of: entity(named: "Spinner", in: session)).map(session.displayName(of:)).last == "Crate")
        #expect(session.undo.undoDepth == 2)
    }
}

// MARK: Play mode

@MainActor @Suite struct PlayModeTests {
    @Test func playRunsSystemsAndStopRestoresEverything() throws {
        let session = makeSession()
        let world = session.world
        let spinner = entity(named: "Spinner", in: session)
        session.rename(id("Floor", session), to: "Ground")
        let before = try world.save()
        let undoDepth = session.undo.undoDepth
        let selected = [id("Spinner", session), id("Arm A", session)]
        session.selection.set(selected, primary: selected[0])

        session.play()
        #expect(session.isPlaying)
        #expect(!session.undo.isRecording)
        let rotation = world.get(Transform.self, for: spinner)!.rotation
        for _ in 0..<30 { session.tick(dt: 1.0 / 60) }
        #expect(world.get(Transform.self, for: spinner)!.rotation != rotation, "Spin rotates in play mode")
        // Edits while playing apply but aren't recorded.
        session.rename(id("Red Cube", session), to: "Changed In Play")
        session.perform(DespawnCommand(id: id("Blue Sphere", session)))
        #expect(session.undo.undoDepth == undoDepth)

        session.stop()
        #expect(!session.isPlaying)
        #expect(session.undo.isRecording)
        #expect(try world.save() == before)
        #expect(session.undo.undoDepth == undoDepth)
        #expect(session.selection.ids == selected)
        #expect(session.selection.primaryEntity(in: world) == spinner)
        session.performUndo()
        #expect(session.displayName(of: entity(named: "Floor", in: session)) == "Floor")
    }

    @Test func editingDoesNotRunSystems() {
        let session = makeSession()
        let spinner = entity(named: "Spinner", in: session)
        let rotation = session.world.get(Transform.self, for: spinner)!.rotation
        for _ in 0..<10 { session.tick(dt: 1.0 / 60) }
        #expect(session.world.get(Transform.self, for: spinner)!.rotation == rotation)
    }
}

// MARK: Shortcuts

@MainActor @Suite struct ShortcutTests {
    let mac = EditorShortcuts(shortcutModifier: .command)
    let other = EditorShortcuts(shortcutModifier: .control)

    @Test func mapping() {
        #expect(mac.action(for: KeyEvent(key: .z, modifiers: .command)) == .undo)
        #expect(mac.action(for: KeyEvent(key: .z, modifiers: [.command, .shift])) == .redo)
        #expect(mac.action(for: KeyEvent(key: .y, modifiers: .control)) == nil)
        #expect(other.action(for: KeyEvent(key: .y, modifiers: .control)) == .redo)
        #expect(other.action(for: KeyEvent(key: .z, modifiers: .command)) == nil)
        #expect(mac.action(for: KeyEvent(key: .s, modifiers: .command)) == .save)
        #expect(mac.action(for: KeyEvent(key: .d, modifiers: .command)) == .duplicate)
        #expect(mac.action(for: KeyEvent(key: .backspace)) == .delete)
        #expect(mac.action(for: KeyEvent(key: .delete)) == .delete)
        #expect(mac.action(for: KeyEvent(key: .f)) == .focusSelection)
        #expect(mac.action(for: KeyEvent(key: .f, modifiers: .command)) == nil)
        #expect(mac.action(for: KeyEvent(key: .escape)) == .clearSelection)
        #expect(mac.action(for: KeyEvent(key: .z, modifiers: .command, isRepeat: true)) == .undo)
        #expect(mac.action(for: KeyEvent(key: .d, modifiers: .command, isRepeat: true)) == nil)
        #expect(mac.action(for: KeyEvent(key: .w)) == nil)
    }

    @Test func blockedWhileATextFieldHasFocus() {
        let ui = UIContext()
        ui.setViewport(size: Vec2(400, 300), scale: 1)
        let field = TextField(text: "name")
        let tree = TreeView(roots: [TreeNode("a")])
        let stack = VStack([field, tree])
        ui.root.addChild(stack)
        ui.layoutIfNeeded()
        let keys = [KeyEvent(key: .backspace), KeyEvent(key: .z, modifiers: .command), KeyEvent(key: .escape)]
        func focus() -> EditorShortcuts.Focus {
            EditorShortcuts.Focus(textEditing: ui.focusedWidget?.wantsTextInput == true, overlayOpen: !ui.overlays.isEmpty,
                                  widgetFocused: ui.focusedWidget != nil)
        }

        #expect(mac.actions(for: keys, focus: focus()) == [.delete, .undo, .clearSelection])
        ui.focus(field)
        #expect(mac.actions(for: keys, focus: focus()) == [])
        // A focused tree doesn't edit text: shortcuts work, Esc only unfocuses.
        ui.focus(tree)
        #expect(mac.actions(for: keys, focus: focus()) == [.delete, .undo])
        #expect(mac.actions(for: keys, focus: .init(overlayOpen: true)) == [])
    }

    @Test func cursorMapping() {
        #expect(cursorShape(for: .resizeLeftRight) == .resizeHorizontal)
        #expect(cursorShape(for: .resizeUpDown) == .resizeVertical)
        #expect(cursorShape(for: .pointingHand) == .pointingHand)
        #expect(cursorShape(for: .arrow) == .arrow)
    }
}

// MARK: Prefs and layout

@MainActor @Suite struct LayoutPersistenceTests {
    @Test func layoutRoundTripsThroughThePrefsFile() throws {
        let url = temporaryDirectory().appendingPathComponent("nested/prefs.json")
        let store = EditorPrefsStore(url: url)
        #expect(try store.load() == nil)

        let dock = DockSpace()
        for id in EditorLayout.panelIDs { dock.addPanel(DockPanel(id: id, title: id, content: Widget())) }
        dock.restoreLayout(EditorLayout.defaultLayout)
        dock.dock(EditorLayout.stats, at: .split(beside: EditorLayout.inspector, edge: .bottom))
        let changed = dock.layout
        #expect(changed != EditorLayout.defaultLayout)
        try store.save(EditorPrefs(layout: changed, lastScenePath: "/tmp/x.json"))

        let loaded = try #require(try store.load())
        #expect(loaded.layout == changed)
        #expect(loaded.lastScenePath == "/tmp/x.json")
        let restored = DockSpace()
        for id in EditorLayout.panelIDs { restored.addPanel(DockPanel(id: id, title: id, content: Widget())) }
        restored.restoreLayout(EditorLayout.initialLayout(stored: loaded.layout))
        #expect(restored.layout == changed)
    }

    @Test func fallsBackToTheDefaultLayout() throws {
        #expect(EditorLayout.initialLayout(stored: nil) == EditorLayout.defaultLayout)
        let noViewport = DockLayout(root: .tabs(panels: ["console"], active: "console"))
        #expect(EditorLayout.initialLayout(stored: noViewport) == EditorLayout.defaultLayout)
        let url = temporaryDirectory().appendingPathComponent("prefs.json")
        try Data("garbage".utf8).write(to: url)
        #expect(throws: (any Error).self) { try EditorPrefsStore(url: url).load() }
    }

    @Test func defaultLocation() {
        #expect(EditorPrefsStore.defaultURL(environment: ["EDITOR_PREFS": "/x/p.json"]).path == "/x/p.json")
        let url = EditorPrefsStore.defaultURL(environment: ["HOME": "/home/me"])
        #expect(url.lastPathComponent == "prefs.json")
        #expect(url.path.hasPrefix("/home/me/"))
    }
}

// MARK: Viewport

/// Consumes presses with the left button and records what it saw.
@MainActor private final class RecordingTool: ViewportTool {
    var events: [ViewportPointerEvent] = []
    func handlePointer(_ event: ViewportPointerEvent, context: ViewportToolContext) -> Bool {
        events.append(event)
        return event.button == .left
    }
    func draw(into debugDraw: DebugDraw, context: ViewportToolContext) {}
}

@MainActor @Suite struct ViewportTests {
    @Test func targetResizeBookkeeping() {
        var sizer = ViewportTargetSizer()
        #expect(sizer.update(rect: UIRect(x: 10, y: 20, width: 400, height: 300), scale: 2)! == (800, 600))
        #expect(sizer.update(rect: UIRect(x: 50, y: 20, width: 400, height: 300), scale: 2) == nil, "moving doesn't resize")
        #expect(sizer.update(rect: UIRect(x: 0, y: 0, width: 400.5, height: 300), scale: 2)! == (801, 600))
        #expect(sizer.update(rect: UIRect(x: 0, y: 0, width: 400.5, height: 300), scale: 2) == nil)
        #expect(sizer.update(rect: .zero, scale: 2) == nil, "a hidden panel keeps its size")
        #expect(sizer.update(rect: UIRect(x: 0, y: 0, width: 0.2, height: 0.2), scale: 1)! == (1, 1))
        #expect(sizer.resizeCount == 3)
        #expect(sizer.width == 1 && sizer.height == 1)
    }

    @Test func rayHitsBounds() {
        let ray = ViewportRay(origin: Vec3(0, 0, 10), direction: Vec3(0, 0, -1))
        #expect(ray.intersect(Bounds(center: .zero, halfExtent: Vec3(1, 1, 1))) == 9)
        #expect(ray.intersect(Bounds(center: Vec3(3, 0, 0), halfExtent: Vec3(1, 1, 1))) == nil)
        #expect(ray.intersect(Bounds(center: Vec3(0, 0, 20), halfExtent: Vec3(1, 1, 1))) == nil, "behind the origin")
        #expect(ray.intersect(Bounds(center: Vec3(0, 0, 10), halfExtent: Vec3(1, 1, 1))) == 0, "starting inside")
        let down = ViewportRay(origin: Vec3(0.5, 5, 0.5), direction: Vec3(0, -1, 0))
        #expect(down.intersect(Bounds(center: .zero, halfExtent: Vec3(2, 0, 2))) == 5, "flat plane bounds")
    }

    @Test func centerRayGoesAlongTheViewDirection() {
        let camera = EditorCamera()
        let view = camera.sceneView(aspect: 2, clearColor: Vec4(0, 0, 0, 1))
        let ray = ViewportRay(through: Vec2(200, 100), viewportSize: Vec2(400, 200), view: view)
        #expect(length(ray.direction - camera.forward) < 1e-3)
        #expect(length(cross(ray.origin - camera.eye, camera.forward)) < 1e-2)
    }

    private func context(_ session: EditorSession, _ view: SceneView, rect: UIRect) -> ViewportToolContext {
        ViewportToolContext(world: session.world, selection: session.selection, undo: session.undo, view: view, viewportRect: rect,
                            pixelScale: 1, toolMode: session.tool, isPlaying: false, meshBounds: builtinMeshBounds)
    }

    @Test func clickSelectPicksTheNearestEntity() {
        let session = makeSession()
        session.world.propagateTransforms()
        let rect = UIRect(x: 0, y: 0, width: 400, height: 300)
        var camera = EditorCamera()
        camera.frame(Bounds(center: Vec3(0, 0.75, 2), halfExtent: Vec3(repeating: 0.75)))  // the blue sphere
        let view = camera.sceneView(aspect: 4 / 3, clearColor: .zero)
        let ctx = context(session, view, rect: rect)
        let center = Vec2(200, 150)

        let tool = BoundsClickSelectTool()
        #expect(tool.handlePointer(ViewportPointerEvent(position: center, viewportSize: ctx.viewportSize, phase: .pressed, button: .left), context: ctx))
        #expect(tool.handlePointer(ViewportPointerEvent(position: center, viewportSize: ctx.viewportSize, phase: .released, button: .left), context: ctx))
        #expect(session.selection.ids == [id("Blue Sphere", session)])

        // Shift-click on the same spot toggles it off; a click at the sky clears.
        session.selection.select(id("Red Cube", session))
        _ = tool.handlePointer(ViewportPointerEvent(position: center, viewportSize: ctx.viewportSize, phase: .pressed, button: .left, modifiers: .shift), context: ctx)
        _ = tool.handlePointer(ViewportPointerEvent(position: center, viewportSize: ctx.viewportSize, phase: .released, button: .left, modifiers: .shift), context: ctx)
        #expect(Set(session.selection.ids) == [id("Red Cube", session), id("Blue Sphere", session)])

        var sky = EditorCamera(pivot: Vec3(0, 50, 0), yaw: 0, pitch: -1.2, distance: 5)
        sky.far = 100
        let skyCtx = context(session, sky.sceneView(aspect: 4 / 3, clearColor: .zero), rect: rect)
        _ = tool.handlePointer(ViewportPointerEvent(position: center, viewportSize: skyCtx.viewportSize, phase: .pressed, button: .left), context: skyCtx)
        _ = tool.handlePointer(ViewportPointerEvent(position: center, viewportSize: skyCtx.viewportSize, phase: .released, button: .left), context: skyCtx)
        #expect(session.selection.isEmpty)

        // A drag isn't a click; Alt-press is left to the camera.
        session.selection.select(id("Red Cube", session))
        _ = tool.handlePointer(ViewportPointerEvent(position: center, viewportSize: ctx.viewportSize, phase: .pressed, button: .left), context: ctx)
        _ = tool.handlePointer(ViewportPointerEvent(position: center + Vec2(30, 0), viewportSize: ctx.viewportSize, phase: .dragged, button: .left), context: ctx)
        _ = tool.handlePointer(ViewportPointerEvent(position: center + Vec2(30, 0), viewportSize: ctx.viewportSize, phase: .released, button: .left), context: ctx)
        #expect(session.selection.ids == [id("Red Cube", session)])
        #expect(!tool.handlePointer(ViewportPointerEvent(position: center, viewportSize: ctx.viewportSize, phase: .pressed, button: .left, modifiers: .alt), context: ctx))
    }

    @Test func toolsGetThePointerBeforeTheCamera() {
        let session = makeSession()
        let controller = ViewportController()
        let tool = RecordingTool()
        controller.tools = [tool]
        controller.rect = UIRect(x: 100, y: 50, width: 400, height: 300)
        let make: (SceneView) -> ViewportToolContext = { view in
            self.context(session, view, rect: controller.rect)
        }
        let start = controller.camera

        // Left press: consumed by the tool, which then gets the drag and release, even outside.
        var input = ViewportInput(mousePosition: Vec2(150, 100))
        input.pressed = [.left]; input.down = [.left]
        controller.update(input, context: make)
        #expect(tool.events.last?.phase == .pressed)
        #expect(tool.events.last?.position == Vec2(50, 50), "viewport-local points")
        input = ViewportInput(mousePosition: Vec2(900, 900)); input.down = [.left]; input.mouseDelta = Vec2(30, 0)
        controller.update(input, context: make)
        #expect(tool.events.last?.phase == .dragged)
        input = ViewportInput(mousePosition: Vec2(900, 900)); input.released = [.left]
        controller.update(input, context: make)
        #expect(tool.events.last?.phase == .released)
        #expect(controller.camera == start)
        #expect(controller.gesture == nil)

        // Middle drag: the tool declines, the camera orbits.
        input = ViewportInput(mousePosition: Vec2(150, 100)); input.pressed = [.middle]; input.down = [.middle]
        controller.update(input, context: make)
        #expect(controller.gesture == .orbit)
        input = ViewportInput(mousePosition: Vec2(180, 100)); input.down = [.middle]; input.mouseDelta = Vec2(30, 0)
        controller.update(input, context: make)
        #expect(controller.camera.yaw != start.yaw)

        // Over the UI, nothing happens; wheel zooms over the viewport.
        input = ViewportInput(mousePosition: Vec2(150, 100)); input.released = [.middle]
        controller.update(input, context: make)
        let count = tool.events.count
        input = ViewportInput(mousePosition: Vec2(150, 100)); input.pointerOverUI = true; input.scroll = Vec2(0, 10)
        controller.update(input, context: make)
        #expect(tool.events.count == count)
        let distance = controller.camera.distance
        input.pointerOverUI = false
        controller.update(input, context: make)
        #expect(controller.camera.distance < distance)

        // Right drag flies (and asks for mouse capture); WASD moves the camera.
        input = ViewportInput(mousePosition: Vec2(150, 100)); input.pressed = [.right]; input.down = [.right]
        controller.update(input, context: make)
        #expect(controller.wantsMouseCapture)
        let eye = controller.camera.eye
        input = ViewportInput(mousePosition: Vec2(150, 100)); input.down = [.right]; input.move = Vec3(0, 0, 1); input.dt = 0.5
        controller.update(input, context: make)
        #expect(length(controller.camera.eye - (eye + controller.camera.forward * 3)) < 1e-3)
        input = ViewportInput(mousePosition: Vec2(150, 100))
        controller.update(input, context: make)
        #expect(!controller.wantsMouseCapture)
    }

    @Test func framingFitsTheBounds() {
        var camera = EditorCamera()
        camera.frame(Bounds(center: Vec3(5, 1, -3), halfExtent: Vec3(1, 1, 1)))
        #expect(camera.pivot == Vec3(5, 1, -3))
        #expect(camera.distance > sqrtf(3) / sinf(camera.fovY / 2))
        let before = camera
        camera.pan(by: Vec2(10, 0), viewportHeight: 300)
        #expect(camera.pivot != before.pivot && camera.distance == before.distance)
    }
}

// MARK: Console and stats

@MainActor @Suite struct ConsoleTests {
    @Test func filterAndClear() {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let console = ConsolePanel(log: log)
        console.showsTime = false
        log.info("hello")
        log.warning("careful")
        log.error("broken")
        console.refresh()
        #expect(console.shownLines.count == 3)
        console.setMinimumLevel(.warning)
        console.refresh()
        #expect(console.shownLines.map { $0.contains("careful") || $0.contains("broken") } == [true, true])
        console.setMinimumLevel(.error)
        console.refresh()
        #expect(console.shownLines.count == 1 && console.shownLines[0].hasSuffix("broken"))
        log.clear()
        console.refresh()
        #expect(console.shownLines.isEmpty)
    }

    @Test func logKeepsTheNewest() {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        log.maxEntries = 3
        for i in 0..<5 { log.info("\(i)") }
        #expect(log.entries.map(\.message) == ["2", "3", "4"])
        #expect(log.entries.last?.sequence == 4)
    }

    @Test func statsLines() {
        var stats = EditorStatsSnapshot()
        stats.frame.gpuPassTimes = [GPUPassTime(name: "viewport", seconds: 0.0005)]
        stats.entityCount = 12
        stats.undoDepth = 3
        let lines = stats.lines
        #expect(lines.contains("    viewport: 0.50 ms"))
        #expect(lines.contains { $0.hasPrefix("Entities: 12") })
        #expect(lines.contains("Undo depth: 3 · redo: 0"))
    }
}

// MARK: Asset dropdowns

@MainActor private func dropdowns(in widget: Widget) -> [Dropdown] {
    (widget as? Dropdown).map { [$0] } ?? widget.children.flatMap { dropdowns(in: $0) }
}

@MainActor @Suite struct AssetChoiceTests {
    @Test func onlyMeshRendererAssetKeysGetOptions() {
        let choices = AssetChoices(meshes: { ["cube", "sphere"] }, materials: { ["default", "checker"] })
        #expect(choices.options(component: "MeshRenderer", path: "mesh") == ["cube", "sphere"])
        #expect(choices.options(component: "MeshRenderer", path: "material") == ["default", "checker"])
        #expect(choices.options(component: "MeshRenderer", path: "tint") == nil)
        #expect(choices.options(component: "Transform", path: "mesh") == nil)
    }

    /// The mesh field is a dropdown of the registered meshes; picking one is one undo step.
    @Test func meshFieldIsADropdownAndPickingIsOneUndoStep() throws {
        let session = makeSession()
        let panel = InspectorPanel(session: session)
        panel.assetChoices = AssetChoices(meshes: { ["cube", "plane", "sphere"] }, materials: { ["default", "checker"] })
        let sphere = entity(named: "Blue Sphere", in: session)
        session.selection.select(id("Blue Sphere", session))
        panel.refresh()

        let mesh = try #require(dropdowns(in: panel.grid).first { $0.options.contains("plane") })
        #expect(mesh.selectedOption == "sphere")
        #expect(dropdowns(in: panel.grid).contains { $0.options == ["default", "checker"] })

        let depth = session.undo.undoDepth
        let cube = try #require(mesh.options.firstIndex(of: "cube"))
        mesh.select(cube)
        mesh.onChange?(cube)
        #expect(session.world.get(MeshRenderer.self, for: sphere)?.mesh == .cube)
        #expect(session.undo.undoDepth == depth + 1)

        _ = try session.undo.undo()
        panel.refresh()
        #expect(session.world.get(MeshRenderer.self, for: sphere)?.mesh == .sphere)
        #expect(mesh.selectedOption == "sphere")
    }

    /// A key that isn't registered (e.g. from a hand-edited file) still shows and stays selectable.
    @Test func unknownCurrentKeyIsKept() throws {
        let session = makeSession()
        let panel = InspectorPanel(session: session)
        panel.assetChoices = AssetChoices(meshes: { ["cube"] }, materials: { ["default"] })
        session.selection.select(id("Blue Sphere", session))
        panel.refresh()
        let mesh = try #require(dropdowns(in: panel.grid).first { $0.options.contains("cube") && $0.options.count == 2 })
        #expect(mesh.options == ["cube", "sphere"])
        #expect(mesh.selectedOption == "sphere")
    }
}

// MARK: Transform tool (gizmo + picker adapter)

@MainActor @Suite struct TransformToolTests {
    private func setup() -> (EditorSession, TransformTool, ViewportToolContext) {
        let session = makeSession()
        session.world.propagateTransforms()
        var camera = EditorCamera()
        camera.frame(Bounds(center: Vec3(0, 0.75, 2), halfExtent: Vec3(repeating: 1.5)))  // around the blue sphere
        let ctx = ViewportToolContext(
            world: session.world, selection: session.selection, undo: session.undo,
            view: camera.sceneView(aspect: 4 / 3, clearColor: .zero), viewportRect: UIRect(x: 0, y: 0, width: 400, height: 300),
            pixelScale: 1, toolMode: .move, isPlaying: false, meshBounds: builtinMeshBounds)
        return (session, TransformTool(meshes: PickMeshLibrary()), ctx)
    }

    private func event(_ p: Vec2, _ phase: ViewportPointerPhase, _ ctx: ViewportToolContext,
                       modifiers: KeyModifiers = []) -> ViewportPointerEvent {
        ViewportPointerEvent(position: p, viewportSize: ctx.viewportSize, phase: phase, button: phase == .moved ? nil : .left,
                             modifiers: modifiers)
    }

    /// Screen points on the X axis handle of the gizmo for the current selection.
    private func xHandle(_ tool: TransformTool, _ ctx: ViewportToolContext) throws -> (grab: Vec2, along: Vec2) {
        let view = ViewportProjection(ctx.view, size: ctx.viewportSize, pixelScale: 1)
        let frame = try #require(tool.gizmo.frame(view: view, world: ctx.world, selection: ctx.selection.entities(in: ctx.world),
                                                  primary: ctx.selection.primaryEntity(in: ctx.world)))
        let grab = try #require(ctx.project(frame.origin + frame.axes[0] * frame.length * 0.8))
        let tip = try #require(ctx.project(frame.origin + frame.axes[0] * frame.length))
        return (grab, (tip - grab) / length(Vec3(tip - grab, 0)))
    }

    @Test func clickPicksExactlyAndClearsOnEmptySpace() {
        let (session, tool, ctx) = setup()
        let center = Vec2(200, 150)
        _ = tool.handlePointer(event(center, .pressed, ctx), context: ctx)
        _ = tool.handlePointer(event(center, .released, ctx), context: ctx)
        #expect(session.selection.ids == [id("Blue Sphere", session)])

        // The sphere's bounding-box corner is empty space for the exact picker.
        session.selection.clear()
        let corner = Vec3(0.75, 0.75 + 0.75, 2 + 0.75) * 0.999 + Vec3(0, 0, 0)
        if let p = ctx.project(Vec3(corner.x, corner.y, corner.z)) {
            _ = tool.handlePointer(event(p, .pressed, ctx), context: ctx)
            _ = tool.handlePointer(event(p, .released, ctx), context: ctx)
            #expect(!session.selection.ids.contains(id("Blue Sphere", session)))
        }
    }

    @Test func gizmoDragIsOneUndoStepThatRestoresExactly() throws {
        let (session, tool, ctx) = setup()
        let sphere = entity(named: "Blue Sphere", in: session)
        session.selection.select(id("Blue Sphere", session))
        let before = try #require(session.world.get(Transform.self, for: sphere))
        let depth = session.undo.undoDepth
        let (grab, along) = try xHandle(tool, ctx)

        #expect(tool.handlePointer(event(grab, .pressed, ctx), context: ctx))
        #expect(tool.isDragging)
        for step in 1...5 { _ = tool.handlePointer(event(grab + along * Float(step * 8), .dragged, ctx), context: ctx) }
        #expect(!session.undo.canUndo)  // the drag's group is open
        _ = tool.handlePointer(event(grab + along * 40, .released, ctx), context: ctx)

        let after = try #require(session.world.get(Transform.self, for: sphere))
        #expect(after.position.x > before.position.x + 0.05)
        #expect(abs(after.position.y - before.position.y) < 1e-4 && abs(after.position.z - before.position.z) < 1e-4)
        #expect(session.undo.undoDepth == depth + 1)
        #expect(session.selection.ids == [id("Blue Sphere", session)])  // a gizmo drag doesn't change the selection

        _ = try session.undo.undo()
        #expect(session.world.get(Transform.self, for: sphere) == before)
    }

    @Test func escapeCancelsTheDragAndRecordsNothing() throws {
        let (session, tool, ctx) = setup()
        let sphere = entity(named: "Blue Sphere", in: session)
        session.selection.select(id("Blue Sphere", session))
        let before = try #require(session.world.get(Transform.self, for: sphere))
        let depth = session.undo.undoDepth
        let (grab, along) = try xHandle(tool, ctx)

        _ = tool.handlePointer(event(grab, .pressed, ctx), context: ctx)
        _ = tool.handlePointer(event(grab + along * 30, .dragged, ctx), context: ctx)
        #expect(session.world.get(Transform.self, for: sphere) != before)
        #expect(tool.cancelDrag(world: session.world))
        #expect(session.world.get(Transform.self, for: sphere) == before)
        #expect(session.undo.undoDepth == depth)
        #expect(!tool.cancelDrag(world: session.world))  // nothing left to cancel
        _ = tool.handlePointer(event(grab + along * 30, .released, ctx), context: ctx)
        #expect(session.undo.undoDepth == depth)
    }

    @Test func toolbarModeDrivesTheGizmo() {
        #expect(TransformTool.mode(for: .move) == .translate)
        #expect(TransformTool.mode(for: .rotate) == .rotate)
        #expect(TransformTool.mode(for: .scale) == .scale)
    }
}
