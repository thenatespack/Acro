import Foundation
import EngineAssets
import EngineCore
import EngineRendering
import EngineScene
import EngineText

// The play-mode interaction system ("interaction", `.update`) and the ready-made devices
// ("interaction.devices"): see Interaction.swift in EngineScene for the components.
//
// Each frame, for every `Interactor`:
// - Focus: the enabled `Interactable` (not its own) whose focus point is in reach (the smaller
//   of both ranges, from the interactor's eye) and within `maxAngle` of its view (its `forward`,
//   or the active camera's with `useCamera`), scoring distance and angle; ties go to the nearest.
// - Highlight: the focused entity's (and children's) `MeshRenderer` tints are brightened by
//   `highlightTint` (`world.interactionFocus` names it for hosts that draw a selection-style
//   outline: the editor's Game view does).
// - Prompt: a billboard `TextMesh` ("Interaction Prompt") above it reads "[E] Open": the glyph
//   is the action's current binding (`actions`, so rebinding changes it; the gamepad's binding
//   after a gamepad button was pressed, the keyboard's after a key).
// - Input: the interactor's `useAction` / `pickUpAction` pressed uses the focused interactable
//   when its `action` matches (`interact(_:with:in:)` does it from code and scripts).
// Using: a `Door` opens or closes (a locked one needs its key item, which unlocks it), a `Lever`
// flips and toggles its target, a `Container` opens and hands over its items, a `Pickup` joins the
// interactor's items and is removed. The use is logged (`events`; Visual Script "On Interact").

/// The state of the "interaction" system (see InteractionSystem.swift). `World.gameplay?.interaction`.
@MainActor
public final class InteractionSystem {
    public static let systemName = "interaction"
    public static let devicesSystemName = "interaction.devices"

    /// The default bindings: use on E and the gamepad's west button, pick up on F and its north button.
    public static var defaultBindings: InputBindings {
        var bindings = InputBindings()
        bindings.buttons.append(.init("use", [.key(.e), .gamepadButton(.west)]))
        bindings.buttons.append(.init("pickUp", [.key(.f), .gamepadButton(.north)]))
        return bindings
    }

    /// The actions interactors press (`Interactor.useAction`, `.pickUpAction`). Rebind them (or
    /// set `bindings`) and prompts show the new glyphs.
    public let actions: InputActions
    /// Show the gamepad's glyphs (set when a gamepad button is pressed, cleared by a key).
    public var prefersGamepad = false
    /// Multiplies the focused entity's tints.
    public var highlightTint = Vec3(1.5, 1.45, 1.25)
    /// Spawn prompt text above the focused interactable.
    public var showsPrompts = true
    public var promptSize: Float = 0.22
    public var enabled = true
    /// Interactor → the interactable it focuses.
    public private(set) var focus: [Entity: Entity] = [:]
    /// The most recent uses, oldest first.
    public private(set) var events: [InteractEvent] = []
    public private(set) var lastSequence = 0
    /// The prompt shown per interactor ("[E] Open"), as last computed.
    public private(set) var prompts: [Entity: String] = [:]

    let input: Input?
    private var promptEntities: [Entity: Entity] = [:]
    private var highlighted: [Entity: [Entity: Vec3]] = [:]

    init(input: Input?, bindings: InputBindings = InteractionSystem.defaultBindings) {
        self.input = input
        actions = InputActions(bindings: bindings)
    }

    // MARK: Glyphs and prompts

    /// The label of `action`'s current binding: the keyboard or mouse one, or the gamepad's
    /// (`prefersGamepad`), else the first; "?" when unbound.
    public func glyph(for action: String) -> String {
        guard let sources = actions.bindings.buttons.first(where: { $0.name == action })?.bindings, !sources.isEmpty else { return "?" }
        func isPad(_ s: InputSource) -> Bool {
            switch s {
            case .gamepadButton, .gamepadAxis: true
            default: false
            }
        }
        let preferred = sources.first { isPad($0) == prefersGamepad } ?? sources[0]
        return preferred.displayName
    }

    /// What using `target` would do, as a verb ("Open", "Close", "Pull", "Pick up key", "Locked").
    public static func verb(for target: Entity, interactor: Entity?, in world: World) -> String {
        if let custom = world.get(Interactable.self, for: target)?.prompt, !custom.isEmpty { return custom }
        if let door = world.get(Door.self, for: target) {
            if door.locked {
                let hasKey = !door.key.isEmpty && (interactor.flatMap { world.get(Interactor.self, for: $0) }?.count(of: door.key) ?? 0) > 0
                return hasKey ? "Unlock" : "Locked"
            }
            return door.open ? "Close" : "Open"
        }
        if world.has(Lever.self, for: target) { return "Pull" }
        if let container = world.get(Container.self, for: target) { return container.open ? "Empty" : "Open" }
        if let pickup = world.get(Pickup.self, for: target) { return "Pick up " + pickup.item }
        return "Use"
    }

    /// The prompt for `interactor` focusing `target`: "[glyph] verb".
    public func prompt(for target: Entity, interactor: Entity, in world: World) -> String {
        let player = world.get(Interactor.self, for: interactor) ?? Interactor()
        let action = world.get(Interactable.self, for: target)?.action == .pickUp ? player.pickUpAction : player.useAction
        return "[\(glyph(for: action))] \(Self.verb(for: target, interactor: interactor, in: world))"
    }

    // MARK: Focus

    /// The interactable `interactor` would focus now (see the notes at the top of the file).
    public static func bestTarget(for interactor: Entity, in world: World) -> Entity? {
        guard let player = world.get(Interactor.self, for: interactor) else { return nil }
        let matrix = world.worldMatrix(of: interactor)
        let origin = Vec3(matrix.c3.x, matrix.c3.y, matrix.c3.z)
        let eye = origin + Vec3(0, player.eyeHeight, 0)
        var view: Vec3
        if player.useCamera, let camera = RenderPrep.findCamera(in: world) {
            view = -Vec3(camera.world.c2.x, camera.world.c2.y, camera.world.c2.z)
        } else {
            let f = matrix * Vec4(player.forward.x, player.forward.y, player.forward.z, 0)
            view = Vec3(f.x, f.y, f.z)
        }
        view = length(view) > 1e-6 ? normalize(view) : Vec3(0, 0, -1)
        var candidates: [(Entity, Interactable)] = []
        world.query(Interactable.self) { e, i in if i.enabled, e != interactor { candidates.append((e, i)) } }
        var best: (entity: Entity, score: Float, distance: Float)?
        for (entity, interactable) in candidates {
            if world.isAncestor(interactor, of: entity) { continue }
            let p = world.worldMatrix(of: entity) * Vec4(interactable.focusOffset.x, interactable.focusOffset.y, interactable.focusOffset.z, 1)
            let point = Vec3(p.x, p.y, p.z)
            let range = min(interactable.range, player.range)
            // Reach from the eye or the feet, whichever is closer (things on the floor, high levers).
            let toTarget = point - eye
            let distance = min(length(toTarget), length(point - origin))
            guard distance <= range else { continue }
            let angle: Float = length(toTarget) > 1e-4 ? acos(min(max(dot(normalize(toTarget), view), -1), 1)) * 180 / .pi : 0
            guard angle <= player.maxAngle + 1e-3 else { continue }
            let score = distance / max(range, 1e-3) + angle / max(player.maxAngle, 1)
            if best == nil || score < best!.score - 1e-5 || (abs(score - best!.score) <= 1e-5 && distance < best!.distance) {
                best = (entity, score, distance)
            }
        }
        return best?.entity
    }

    // MARK: Using

    /// `interactor` uses `target` (its `Interactable` must be enabled): runs the door, lever,
    /// container or pickup behavior and logs the use. Returns nil when it can't be used.
    @discardableResult
    public func interact(_ interactor: Entity, with target: Entity, in world: World) -> InteractEvent? {
        guard world.isAlive(target), let interactable = world.get(Interactable.self, for: target), interactable.enabled else { return nil }
        let verb = Self.verb(for: target, interactor: interactor, in: world)
        var result = "used"
        if var door = world.get(Door.self, for: target) {
            if door.locked {
                let carried = world.get(Interactor.self, for: interactor)?.count(of: door.key) ?? 0
                if !door.key.isEmpty && carried > 0 {
                    door.locked = false
                    door.open = true
                    result = "unlocked"
                } else {
                    result = "locked"
                }
            } else {
                door.open.toggle()
                result = door.open ? "opened" : "closed"
            }
            world.add(door, to: target)
        } else if var lever = world.get(Lever.self, for: target) {
            lever.on.toggle()
            result = lever.on ? "on" : "off"
            world.add(lever, to: target)
            if !lever.target.isEmpty, let other = world.firstEntity(named: lever.target), other != target {
                Self.toggle(other, in: world)
            }
        } else if var container = world.get(Container.self, for: target) {
            if !container.open {
                container.open = true
                world.modify(Interactor.self, for: interactor) { player in
                    for (item, count) in container.items { player.items[item, default: 0] += count }
                }
                container.items = [:]
                result = "looted"
                world.add(container, to: target)
            }
        } else if let pickup = world.get(Pickup.self, for: target) {
            world.modify(Interactor.self, for: interactor) { $0.items[pickup.item, default: 0] += pickup.count }
            result = "picked up"
        }
        world.modify(Interactable.self, for: target) { i in
            i.uses += 1
            if i.once { i.enabled = false }
            if world.get(Container.self, for: target)?.open == true { i.enabled = false }
        }
        lastSequence += 1
        let event = InteractEvent(sequence: lastSequence, interactor: interactor, target: target, action: interactable.action, verb: verb, result: result)
        events.append(event)
        if events.count > 128 { events.removeFirst(events.count - 128) }
        if result == "picked up" {
            unhighlight(target, in: world)
            world.despawn(target)
        }
        return event
    }

    /// A lever's target: a `Door` opens or closes, a `Lever` flips, else an `Interactable` is
    /// enabled or disabled.
    static func toggle(_ entity: Entity, in world: World) {
        if world.has(Door.self, for: entity) {
            world.modify(Door.self, for: entity) { $0.open.toggle() }
        } else if world.has(Lever.self, for: entity) {
            world.modify(Lever.self, for: entity) { $0.on.toggle() }
        } else if world.has(Interactable.self, for: entity) {
            world.modify(Interactable.self, for: entity) { $0.enabled.toggle() }
        }
    }

    /// Uses after the one numbered `sequence`.
    public func events(after sequence: Int) -> ArraySlice<InteractEvent> {
        guard let first = events.firstIndex(where: { $0.sequence > sequence }) else { return [] }
        return events[first...]
    }

    // MARK: Update

    func update(_ world: World) {
        if let input {
            actions.update(input)
            if !input.keyEvents.isEmpty { prefersGamepad = false }
            if input.gamepads.contains(where: { pad in GamepadButton.allCases.contains { pad.isDown($0) } }) { prefersGamepad = true }
        }
        var interactors: [(Entity, Interactor)] = []
        world.query(Interactor.self) { e, i in interactors.append((e, i)) }
        var seen = Set<Entity>()
        for (entity, player) in interactors {
            seen.insert(entity)
            let target = enabled ? Self.bestTarget(for: entity, in: world) : nil
            setFocus(target, for: entity, in: world)
            guard let target, let interactable = world.get(Interactable.self, for: target) else {
                prompts[entity] = nil
                updatePrompt(for: entity, text: nil, at: .zero, show: false, in: world)
                continue
            }
            let action = interactable.action == .pickUp ? player.pickUpAction : player.useAction
            if input != nil, actions.wasPressed(action) {
                interact(entity, with: target, in: world)
            }
            guard world.isAlive(target) else {
                updatePrompt(for: entity, text: nil, at: .zero, show: false, in: world)
                continue
            }
            let text = prompt(for: target, interactor: entity, in: world)
            prompts[entity] = text
            let offset = world.get(Interactable.self, for: target)?.focusOffset ?? .zero
            let p = world.worldMatrix(of: target) * Vec4(offset.x, offset.y + 0.45, offset.z, 1)
            updatePrompt(for: entity, text: text, at: Vec3(p.x, p.y, p.z), show: player.showPrompt && showsPrompts, in: world)
        }
        for (interactor, _) in focus where !seen.contains(interactor) { setFocus(nil, for: interactor, in: world) }
        for (interactor, prompt) in promptEntities where !seen.contains(interactor) {
            world.despawn(prompt)
            promptEntities[interactor] = nil
        }
    }

    private func setFocus(_ target: Entity?, for interactor: Entity, in world: World) {
        let old = focus[interactor]
        guard old != target else { return }
        if let old, !focus.contains(where: { $0.key != interactor && $0.value == old }) { unhighlight(old, in: world) }
        focus[interactor] = target
        if let target { highlight(target, in: world) }
    }

    private func highlight(_ entity: Entity, in world: World) {
        guard highlighted[entity] == nil else { return }
        var tints: [Entity: Vec3] = [:]
        var stack = [entity]
        while let e = stack.popLast() {
            if let renderer = world.get(MeshRenderer.self, for: e) {
                tints[e] = renderer.tint
                world.modify(MeshRenderer.self, for: e) { $0.tint = renderer.tint * highlightTint }
            }
            stack += world.children(of: e)
        }
        highlighted[entity] = tints
    }

    private func unhighlight(_ entity: Entity, in world: World) {
        guard let tints = highlighted.removeValue(forKey: entity) else { return }
        for (e, tint) in tints { world.modify(MeshRenderer.self, for: e) { $0.tint = tint } }
    }

    private func updatePrompt(for interactor: Entity, text: String?, at position: Vec3, show: Bool, in world: World) {
        var entity = promptEntities[interactor]
        if let e = entity, !world.isAlive(e) { entity = nil }
        guard let text, show else {
            if let entity { world.modify(TextMesh.self, for: entity) { $0.isVisible = false } }
            return
        }
        if entity == nil {
            TextMeshComponents.registerComponents()
            let e = world.spawn(Transform(position: position), Name("Interaction Prompt"),
                                TextMesh(text, size: promptSize, color: Vec3(1, 1, 1), emissiveColor: Vec3(1, 0.95, 0.8), emissiveStrength: 1.5,
                                         outlineWidth: 0.12, outlineColor: Vec3(0.05, 0.05, 0.08), billboard: true))
            promptEntities[interactor] = e
            return
        }
        world.modify(Transform.self, for: entity!) { $0.position = position }
        world.modify(TextMesh.self, for: entity!) {
            $0.text = text
            $0.isVisible = true
        }
    }

    /// Animates doors, levers and container lids toward their state.
    func updateDevices(_ world: World) {
        let dt = world.time.delta
        var doors: [Entity] = [], levers: [Entity] = [], containers: [Entity] = []
        world.query(Door.self) { e, d in if d.motion.progress != (d.open ? 1 : 0) { doors.append(e) } }
        world.query(Lever.self) { e, l in if l.motion.progress != (l.on ? 1 : 0) { levers.append(e) } }
        world.query(Container.self) { e, c in if c.motion.progress != (c.open ? 1 : 0) { containers.append(e) } }
        func swing(_ part: Entity, _ motion: inout SwingMotion, toward target: Float) {
            let current = world.get(Transform.self, for: part)?.rotation ?? .identity
            let rotation = motion.advance(toward: target, dt: dt, current: current)
            world.modify(Transform.self, for: part) { $0.rotation = rotation }
        }
        for e in doors { world.modify(Door.self, for: e) { d in swing(e, &d.motion, toward: d.open ? 1 : 0) } }
        for e in levers { world.modify(Lever.self, for: e) { l in swing(e, &l.motion, toward: l.on ? 1 : 0) } }
        for e in containers {
            guard let container = world.get(Container.self, for: e), !container.lid.isEmpty,
                  let lid = CombatSystem.descendant(named: container.lid, of: e, in: world), lid != e else {
                world.modify(Container.self, for: e) { $0.motion.progress = $0.open ? 1 : 0 }
                continue
            }
            world.modify(Container.self, for: e) { c in swing(lid, &c.motion, toward: c.open ? 1 : 0) }
        }
    }

    /// Restores highlights and removes prompts.
    func reset(_ world: World) {
        for entity in Array(highlighted.keys) { unhighlight(entity, in: world) }
        for prompt in promptEntities.values where world.isAlive(prompt) { world.despawn(prompt) }
        promptEntities = [:]
        focus = [:]
        prompts = [:]
    }
}

extension World {
    /// An entity named `name` (the first in storage order), if any.
    public func firstEntity(named name: String) -> Entity? {
        var found: Entity?
        query(Name.self) { e, n in if found == nil, n.value == name { found = e } }
        return found
    }

    /// Whether `ancestor` is `entity` or above it.
    func isAncestor(_ ancestor: Entity, of entity: Entity) -> Bool {
        var current: Entity? = entity
        while let e = current {
            if e == ancestor { return true }
            current = parent(of: e)
        }
        return false
    }
}
