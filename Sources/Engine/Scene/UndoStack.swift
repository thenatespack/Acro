// Undo and redo for editor edits.
//
// ```swift
// let undo = UndoStack(world: world)
// try undo.perform(SetFieldCommand(entity, "Transform", "position", to: .vec3(p), in: world))
// try undo.perform(DespawnCommand(entity, in: world))
// undo.undo()                       // the entity is back, with the same EntityIDs
// menu.title = undo.undoTitle       // "Undo Delete Entity", nil title when there is nothing
//
// undo.group("Move") {              // one step for a whole gizmo drag
//     for p in dragPositions { try undo.perform(SetFieldCommand(entity, "Transform", "position", to: .vec3(p), in: world)) }
// }
// ```
//
// ## Commands
//
// A command is a value with `perform` (also used to redo) and `revert`. `UndoStack.perform`
// runs the command, then records it, so the edit is made through the stack and a command
// that throws leaves nothing recorded. Commands refer to entities by `EntityID`, never by
// `Entity`: handles don't survive despawning and recreating an entity (undo of a delete), a
// snapshot restore or a reload, ids do. The built-in commands are in UndoCommands.swift;
// `ClosureCommand` covers anything else, and `UndoCommand` can be adopted for the rest.
//
// ## Grouping and coalescing
//
// `beginGroup` / `endGroup` (or `group(_:_:)`) turn every command performed in between into
// one undo step, undone in reverse order. Groups nest; the outermost one makes the step.
// Inside a group, a command that `merge`s into the one before it replaces it: consecutive
// edits to the same field (a slider scrub, a drag) become a single `SetFieldCommand` that
// keeps the first old value and the last new value. Outside a group nothing is merged,
// because without an end the stack can't know when a scrub is over. An empty group records
// nothing. `undo` / `redo` are refused while a group is open. `cancelGroup` ends a group by
// reverting what it did instead (a transaction that failed midway).
//
// ## Dirty state
//
// `isDirty` is whether the stack is at a different place than at `markSaved()`: undoing the
// edits since the save makes it clean again, and a new edit after undoing past the save
// point makes it permanently dirty (that state can't be reached again) until the next save.
// `changeCount` increases on every change to the stack for UIs that poll, and `onChange`
// fires after each one.
//
// ## Play mode and loading
//
// The stack only knows the commands it ran. Take a `world.snapshot()` before entering play
// mode, set `isRecording = false` (edits made while playing are performed but not recorded,
// and `canUndo` / `canRedo` read false), and on stop `world.restore(snapshot)` and
// `isRecording = true`. The stack is then exactly as it was, and every command still
// resolves, because snapshots keep `EntityID`s. After loading or creating a scene, call
// `clear()`: the old commands describe a different world.

/// A reversible edit. Commands are values; `perform` may capture state the first time it
/// runs (a despawn records what it removes) and is called again to redo.
@MainActor public protocol UndoCommand {
    /// What the menu shows after "Undo" / "Redo" ("Move", "Rename").
    var label: String { get }
    /// Makes the edit. Throws, changing nothing, if it can't (an entity is gone).
    mutating func perform(in world: World) throws
    /// Takes the edit back, exactly (a world saved before and after is byte-identical).
    mutating func revert(in world: World) throws
    /// Absorbs `next`, a command that has just been performed and follows this one inside a
    /// group, and returns true; or returns false to stay separate.
    mutating func merge(_ next: any UndoCommand) -> Bool
}

extension UndoCommand {
    public mutating func merge(_ next: any UndoCommand) -> Bool { false }
}

public enum UndoError: Error, Equatable, CustomStringConvertible {
    /// No live entity has this id.
    case entityNotFound(EntityID)
    /// The entity has no component with this name.
    case componentNotFound(String)
    /// The parent change can't be made: a stale entity or a cycle.
    case invalidReparent

    public var description: String {
        switch self {
        case .entityNotFound(let id): "No entity with id \(id)"
        case .componentNotFound(let name): "The entity has no '\(name)' component"
        case .invalidReparent: "Can't reparent (stale entity or cycle)"
        }
    }
}

/// Several commands as one undo step.
public struct GroupCommand: UndoCommand {
    public var label: String
    public private(set) var commands: [any UndoCommand]

    public init(_ label: String, _ commands: [any UndoCommand] = []) {
        self.label = label
        self.commands = commands
    }

    /// Performs the children in order (stopping, with the earlier ones undone, if one throws).
    public mutating func perform(in world: World) throws {
        for i in commands.indices {
            do { try commands[i].perform(in: world) } catch {
                for j in stride(from: i - 1, through: 0, by: -1) { try? commands[j].revert(in: world) }
                throw error
            }
        }
    }

    public mutating func revert(in world: World) throws {
        for i in commands.indices.reversed() { try commands[i].revert(in: world) }
    }

    /// Appends an already performed command, merging it into the last one if it can.
    mutating func append(_ command: any UndoCommand) {
        if !commands.isEmpty, commands[commands.count - 1].merge(command) { return }
        commands.append(command)
    }
}

/// The undo and redo history of one `World`. See the notes at the top of this file.
@MainActor public final class UndoStack {
    public let world: World
    /// At most this many undo steps are kept; the oldest are dropped.
    public var maxDepth: Int {
        didSet { precondition(maxDepth > 0, "maxDepth must be positive"); trim() }
    }
    /// Called after every change to the stack: a step recorded, undone or redone, the stack
    /// cleared, the save point moved or recording toggled.
    public var onChange: (() -> Void)?
    /// While false, `perform` makes the edit without recording it, and `undo` / `redo` do
    /// nothing. For play mode (see above).
    public var isRecording = true {
        didSet { if isRecording != oldValue { changed() } }
    }
    /// Increases on every change to the stack.
    public private(set) var changeCount = 0
    /// Put in front of the label of every step recorded while it is set, so the history says
    /// who made a step (the editor sets "AI: " while an MCP client's call runs).
    public var labelPrefix: String?

    private var undoSteps: [any UndoCommand] = []
    private var redoSteps: [any UndoCommand] = []
    private var groups: [GroupCommand] = []
    /// `undoSteps.count` when the document was saved, nil if that state can't be reached.
    private var savedDepth: Int? = 0

    public init(world: World, maxDepth: Int = 200) {
        precondition(maxDepth > 0, "maxDepth must be positive")
        self.world = world
        self.maxDepth = maxDepth
    }

    // MARK: Performing

    /// Performs `command` and records it (inside a group: adds it to the group). Throws,
    /// recording nothing, if the command fails. Recording a command drops the redo history.
    public func perform(_ command: some UndoCommand) throws {
        precondition(!world.isIterating, "UndoStack.perform can't run inside a query")
        var command = command
        try command.perform(in: world)
        guard isRecording else { return }
        let hadRedo = !redoSteps.isEmpty
        discardRedo()
        if !groups.isEmpty {
            groups[groups.count - 1].append(command)
            if hadRedo { changed() }
            return
        }
        push(command)
        changed()
    }

    /// Starts a group; everything performed until the matching `endGroup` is one step,
    /// labeled `label`.
    public func beginGroup(_ label: String) {
        groups.append(GroupCommand(label))
    }

    /// Ends the innermost group, recording it as one step (a nested group becomes a child
    /// of its parent group). Does nothing if no group is open.
    public func endGroup() {
        guard let group = groups.popLast() else { return }
        guard !group.commands.isEmpty else { return }
        if groups.isEmpty {
            push(group)
            changed()
        } else {
            groups[groups.count - 1].append(group)
        }
    }

    /// Runs `body` as a group, ending it however `body` exits.
    public func group<T>(_ label: String, _ body: () throws -> T) rethrows -> T {
        beginGroup(label)
        defer { endGroup() }
        return try body()
    }

    /// Ends the innermost group by taking back everything performed in it (in reverse order),
    /// recording nothing: a transaction that failed midway. Does nothing if no group is open.
    /// Rethrows a revert failure (the group is gone either way).
    public func cancelGroup() throws {
        guard var group = groups.popLast() else { return }
        guard !group.commands.isEmpty else { return }
        defer { changed() }
        try group.revert(in: world)
    }

    /// Whether a group is open.
    public var isGrouping: Bool { !groups.isEmpty }
    /// How many groups are open (nested).
    public var groupDepth: Int { groups.count }

    // MARK: Undo and redo

    public var canUndo: Bool { isRecording && groups.isEmpty && !undoSteps.isEmpty }
    public var canRedo: Bool { isRecording && groups.isEmpty && !redoSteps.isEmpty }

    /// The label of the step `undo` would take back ("Move").
    public var undoLabel: String? { canUndo ? undoSteps[undoSteps.count - 1].label : nil }
    public var redoLabel: String? { canRedo ? redoSteps[redoSteps.count - 1].label : nil }
    /// "Undo Move", or "Undo" when there is nothing to undo, for menu items.
    public var undoTitle: String { undoLabel.map { "Undo \($0)" } ?? "Undo" }
    public var redoTitle: String { redoLabel.map { "Redo \($0)" } ?? "Redo" }

    /// Labels of the undo steps, most recent first, for a history panel.
    public var undoHistory: [String] { undoSteps.reversed().map(\.label) }
    public var redoHistory: [String] { redoSteps.reversed().map(\.label) }
    public var undoDepth: Int { undoSteps.count }
    public var redoDepth: Int { redoSteps.count }

    /// Takes back the most recent step. Returns false if there is none. If the step throws
    /// (an entity it needs is gone) it is dropped and the error rethrown; the stack stays
    /// usable.
    @discardableResult
    public func undo() throws -> Bool {
        guard canUndo else { return false }
        var step = undoSteps.removeLast()
        do { try step.revert(in: world) } catch { savedDepth = nil; changed(); throw error }
        redoSteps.append(step)
        changed()
        return true
    }

    /// Re-does the step most recently undone. Same failure rules as `undo`.
    @discardableResult
    public func redo() throws -> Bool {
        guard canRedo else { return false }
        var step = redoSteps.removeLast()
        do { try step.perform(in: world) } catch { changed(); throw error }
        undoSteps.append(step)
        changed()
        return true
    }

    // MARK: Dirty state

    /// Whether the world differs from how it was at the last `markSaved()` (or since the
    /// stack was created or cleared, if never saved).
    public var isDirty: Bool { savedDepth != undoSteps.count }

    /// Records that the document was just saved.
    public func markSaved() {
        savedDepth = undoSteps.count
        changed()
    }

    /// Records a change the stack can't undo (an edit made outside it): dirty until the
    /// next `markSaved()`.
    public func markUnsaved() {
        savedDepth = nil
        changed()
    }

    /// Forgets all history. Call it after loading or creating a scene. The world then counts
    /// as saved; call `markUnsaved()` if it isn't (an unsaved new scene).
    public func clear() {
        undoSteps = []
        redoSteps = []
        groups = []
        savedDepth = 0
        changed()
    }

    // MARK: Internals

    private func push(_ command: any UndoCommand) {
        if let labelPrefix, !command.label.hasPrefix(labelPrefix) {
            // The step keeps doing what it did, under a label that says who made it.
            if var group = command as? GroupCommand {
                group.label = labelPrefix + group.label
                undoSteps.append(group)
            } else {
                undoSteps.append(GroupCommand(labelPrefix + command.label, [command]))
            }
        } else {
            undoSteps.append(command)
        }
        trim()
    }

    private func trim() {
        let extra = undoSteps.count - maxDepth
        guard extra > 0 else { return }
        undoSteps.removeFirst(extra)
        if let saved = savedDepth { savedDepth = saved >= extra ? saved - extra : nil }
    }

    private func discardRedo() {
        guard !redoSteps.isEmpty else { return }
        // Once the redo steps go, a save point among them can't be reached again.
        if let saved = savedDepth, saved > undoSteps.count { savedDepth = nil }
        redoSteps = []
    }

    private func changed() {
        changeCount += 1
        onChange?()
    }
}
