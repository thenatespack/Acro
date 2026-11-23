// Interaction: things a player can use or pick up, and ready-made doors, levers and containers.
//
// - `Interactor` on the player: how far it reaches, how wide it looks, which input actions use
//   and pick up, and the items it carries.
// - `Interactable` on anything usable: the prompt verb, the action (use or pick up), range and
//   whether it still works. The play-mode interaction system (Engine, Gameplay/Interaction.swift)
//   focuses the best one in reach (by distance and view angle), highlights it, shows its prompt
//   with the action's current input glyph ("[E] Open"), and on the action logs an
//   `InteractEvent` and runs the ready-made behaviors below.
// - `Door` swings open and closed (locked ones need a key item), `Lever` flips and toggles its
//   target (a door, another lever, an interactable), `Container` opens its lid and hands over its
//   items, `Pickup` goes into the interactor's items.
//
// Every key of these components is optional in scene files.
import EngineCore

/// The input action an `Interactable` answers to.
public enum InteractionAction: String, Codable, Sendable, CaseIterable {
    /// Use, open, talk, pull (the interactor's `useAction`, E by default).
    case use
    /// Pick up (the interactor's `pickUpAction`, F by default).
    case pickUp
}

/// Something an `Interactor` can use (see the notes at the top of Interaction.swift).
public struct Interactable: Component, Equatable, Sendable {
    public static let componentName = "Interactable"
    public static var fieldHints: [String: FieldHints] {
        ["prompt": FieldHints(tooltip: "The verb shown after the input glyph (\"[E] Open\"); empty: from the door, lever, container or pickup"),
         "action": FieldHints(tooltip: "use (E / pad west by default) or pickUp (F / pad north)"),
         "range": FieldHints(range: 0...50, step: 0.1, tooltip: "Meters from the interactor (also limited by the interactor's range)"),
         "focusOffset": FieldHints(tooltip: "The point the interactor aims at and the prompt shows above, in this entity's space"),
         "once": FieldHints(tooltip: "Disable after the first use"),
         "uses": FieldHints(readOnly: true, tooltip: "Times it was used")]
    }

    public var prompt: String
    public var action: InteractionAction
    public var enabled: Bool
    public var range: Float
    public var focusOffset: Vec3
    public var once: Bool
    public var uses: Int

    public init(prompt: String = "", action: InteractionAction = .use, enabled: Bool = true, range: Float = 2.5,
                focusOffset: Vec3 = Vec3(0, 0.5, 0), once: Bool = false) {
        self.prompt = prompt
        self.action = action
        self.enabled = enabled
        self.range = range
        self.focusOffset = focusOffset
        self.once = once
        uses = 0
    }

    private enum CodingKeys: String, CodingKey { case prompt, action, enabled, range, focusOffset, once, uses }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Interactable()
        self.init(prompt: try c.decodeIfPresent(String.self, forKey: .prompt) ?? d.prompt,
                  action: try c.decodeIfPresent(InteractionAction.self, forKey: .action) ?? d.action,
                  enabled: try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true,
                  range: try c.decodeIfPresent(Float.self, forKey: .range) ?? d.range,
                  focusOffset: try c.decodeIfPresent(Vec3.self, forKey: .focusOffset) ?? d.focusOffset,
                  once: try c.decodeIfPresent(Bool.self, forKey: .once) ?? false)
        uses = try c.decodeIfPresent(Int.self, forKey: .uses) ?? 0
    }
}

/// The player side of interaction: what it can reach and see, its input actions and items.
public struct Interactor: Component, Equatable, Sendable {
    public static let componentName = "Interactor"
    public static var fieldHints: [String: FieldHints] {
        ["range": FieldHints(range: 0...50, step: 0.1, tooltip: "Meters it reaches"),
         "maxAngle": FieldHints(range: 0...180, step: 1, tooltip: "Degrees off its view an interactable may be (180: any direction)"),
         "forward": FieldHints(tooltip: "The way it looks, in its own space (-Z like cameras; Character Builder characters face +Z)"),
         "useCamera": FieldHints(tooltip: "Look along the active camera instead (first person, over the shoulder)"),
         "eyeHeight": FieldHints(range: 0...5, step: 0.05, tooltip: "Meters above its origin where it looks from"),
         "useAction": FieldHints(tooltip: "The input action that uses (bound to E and pad west unless a game rebinds it)"),
         "pickUpAction": FieldHints(tooltip: "The input action that picks up (F and pad north by default)"),
         "items": FieldHints(tooltip: "What it carries: item name → count (pickups and containers add to it, locked doors read keys)")]
    }

    public var range: Float
    public var maxAngle: Float
    public var forward: Vec3
    public var useCamera: Bool
    public var eyeHeight: Float
    public var useAction: String
    public var pickUpAction: String
    public var showPrompt: Bool
    public var items: [String: Int]

    public init(range: Float = 2.5, maxAngle: Float = 70, forward: Vec3 = Vec3(0, 0, -1), useCamera: Bool = false, eyeHeight: Float = 1,
                useAction: String = "use", pickUpAction: String = "pickUp", showPrompt: Bool = true, items: [String: Int] = [:]) {
        self.range = range
        self.maxAngle = maxAngle
        self.forward = forward
        self.useCamera = useCamera
        self.eyeHeight = eyeHeight
        self.useAction = useAction
        self.pickUpAction = pickUpAction
        self.showPrompt = showPrompt
        self.items = items
    }

    private enum CodingKeys: String, CodingKey { case range, maxAngle, forward, useCamera, eyeHeight, useAction, pickUpAction, showPrompt, items }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Interactor()
        self.init(range: try c.decodeIfPresent(Float.self, forKey: .range) ?? d.range,
                  maxAngle: try c.decodeIfPresent(Float.self, forKey: .maxAngle) ?? d.maxAngle,
                  forward: try c.decodeIfPresent(Vec3.self, forKey: .forward) ?? d.forward,
                  useCamera: try c.decodeIfPresent(Bool.self, forKey: .useCamera) ?? false,
                  eyeHeight: try c.decodeIfPresent(Float.self, forKey: .eyeHeight) ?? d.eyeHeight,
                  useAction: try c.decodeIfPresent(String.self, forKey: .useAction) ?? d.useAction,
                  pickUpAction: try c.decodeIfPresent(String.self, forKey: .pickUpAction) ?? d.pickUpAction,
                  showPrompt: try c.decodeIfPresent(Bool.self, forKey: .showPrompt) ?? true,
                  items: try c.decodeIfPresent([String: Int].self, forKey: .items) ?? [:])
    }

    /// How many `item`s it carries.
    public func count(of item: String) -> Int { items[item] ?? 0 }
}

/// How a door, lever or container part turns between its two positions: `angle` degrees about
/// `axis` (in its parent's space, applied after its rest rotation), `speed` of the whole swing per
/// second. `progress` (0 closed / off ... 1 open / on) is where it is now.
public struct SwingMotion: Codable, Equatable, Sendable {
    public var angle: Float
    public var axis: Vec3
    public var speed: Float
    public var progress: Float
    /// The rotation at progress 0, recorded the first time it moves (nil: not yet).
    public var rest: Quat?

    public init(angle: Float = 90, axis: Vec3 = Vec3(0, 1, 0), speed: Float = 2, progress: Float = 0) {
        self.angle = angle
        self.axis = axis
        self.speed = speed
        self.progress = progress
    }

    private enum CodingKeys: String, CodingKey { case angle, axis, speed, progress, rest }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = SwingMotion()
        angle = try c.decodeIfPresent(Float.self, forKey: .angle) ?? d.angle
        axis = try c.decodeIfPresent(Vec3.self, forKey: .axis) ?? d.axis
        speed = try c.decodeIfPresent(Float.self, forKey: .speed) ?? d.speed
        progress = try c.decodeIfPresent(Float.self, forKey: .progress) ?? 0
        rest = try c.decodeIfPresent(Quat.self, forKey: .rest)
    }

    /// Moves `progress` toward `target` (0 or 1) by `dt`; returns the rotation for it (`rest` is
    /// taken from `current` the first time).
    public mutating func advance(toward target: Float, dt: Float, current: Quat) -> Quat {
        if rest == nil { rest = current }
        let step = max(speed, 0.01) * dt
        progress = target > progress ? min(progress + step, target) : max(progress - step, target)
        let eased = progress * progress * (3 - 2 * progress)
        let n = length(axis) > 1e-6 ? normalize(axis) : Vec3(0, 1, 0)
        return (rest ?? current) * Quat(angle: angle * eased * .pi / 180, axis: n)
    }
}

/// A door that swings open about its hinge (the entity's origin) when used. With `key`, it is
/// locked until an interactor carrying that item uses it.
public struct Door: Component, Equatable, Sendable {
    public static let componentName = "Door"
    public static var fieldHints: [String: FieldHints] {
        ["open": FieldHints(tooltip: "Open (it swings toward it while playing)"),
         "locked": FieldHints(tooltip: "Won't open until used by an interactor carrying the key item"),
         "key": FieldHints(tooltip: "The item that unlocks it (empty: none opens it while locked)"),
         "motion.progress": FieldHints(readOnly: true), "motion.rest": FieldHints(hidden: true)]
    }

    public var open: Bool
    public var locked: Bool
    public var key: String
    public var motion: SwingMotion

    public init(open: Bool = false, locked: Bool = false, key: String = "", motion: SwingMotion = SwingMotion(angle: 95, axis: Vec3(0, 1, 0), speed: 1.5)) {
        self.open = open
        self.locked = locked
        self.key = key
        self.motion = motion
    }

    private enum CodingKeys: String, CodingKey { case open, locked, key, motion }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Door()
        self.init(open: try c.decodeIfPresent(Bool.self, forKey: .open) ?? false, locked: try c.decodeIfPresent(Bool.self, forKey: .locked) ?? false,
                  key: try c.decodeIfPresent(String.self, forKey: .key) ?? "", motion: try c.decodeIfPresent(SwingMotion.self, forKey: .motion) ?? d.motion)
    }
}

/// A lever that flips when used and toggles its `target`: the first entity with that `Name`
/// (its `Door` opens or closes, its `Lever` flips, else its `Interactable` is enabled or not).
public struct Lever: Component, Equatable, Sendable {
    public static let componentName = "Lever"
    public static var fieldHints: [String: FieldHints] {
        ["on": FieldHints(tooltip: "Pulled (it swings toward it while playing)"),
         "target": FieldHints(tooltip: "Name of the entity it toggles: a Door opens / closes, a Lever flips, an Interactable is enabled"),
         "motion.progress": FieldHints(readOnly: true), "motion.rest": FieldHints(hidden: true)]
    }

    public var on: Bool
    public var target: String
    public var motion: SwingMotion

    public init(on: Bool = false, target: String = "", motion: SwingMotion = SwingMotion(angle: -80, axis: Vec3(1, 0, 0), speed: 4)) {
        self.on = on
        self.target = target
        self.motion = motion
    }

    private enum CodingKeys: String, CodingKey { case on, target, motion }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Lever()
        self.init(on: try c.decodeIfPresent(Bool.self, forKey: .on) ?? false, target: try c.decodeIfPresent(String.self, forKey: .target) ?? "",
                  motion: try c.decodeIfPresent(SwingMotion.self, forKey: .motion) ?? d.motion)
    }
}

/// A chest or crate: used, it opens its lid (the child named `lid`) and gives its `items` to the
/// interactor; empty, it can't be used again.
public struct Container: Component, Equatable, Sendable {
    public static let componentName = "Container"
    public static var fieldHints: [String: FieldHints] {
        ["items": FieldHints(tooltip: "What it holds: item name → count (given to whoever opens it)"),
         "lid": FieldHints(tooltip: "Name of the child that swings open (empty: nothing moves)"),
         "motion.progress": FieldHints(readOnly: true), "motion.rest": FieldHints(hidden: true)]
    }

    public var open: Bool
    public var items: [String: Int]
    public var lid: String
    public var motion: SwingMotion

    public init(open: Bool = false, items: [String: Int] = [:], lid: String = "Lid", motion: SwingMotion = SwingMotion(angle: -100, axis: Vec3(1, 0, 0), speed: 2)) {
        self.open = open
        self.items = items
        self.lid = lid
        self.motion = motion
    }

    private enum CodingKeys: String, CodingKey { case open, items, lid, motion }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Container()
        self.init(open: try c.decodeIfPresent(Bool.self, forKey: .open) ?? false, items: try c.decodeIfPresent([String: Int].self, forKey: .items) ?? [:],
                  lid: try c.decodeIfPresent(String.self, forKey: .lid) ?? d.lid,
                  motion: try c.decodeIfPresent(SwingMotion.self, forKey: .motion) ?? d.motion)
    }
}

/// An item lying around: picking it up adds `count` `item`s to the interactor and removes it.
public struct Pickup: Component, Equatable, Sendable {
    public static let componentName = "Pickup"
    public var item: String
    public var count: Int

    public init(item: String = "coin", count: Int = 1) {
        self.item = item
        self.count = count
    }

    private enum CodingKeys: String, CodingKey { case item, count }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        item = try c.decodeIfPresent(String.self, forKey: .item) ?? "coin"
        count = try c.decodeIfPresent(Int.self, forKey: .count) ?? 1
    }
}

/// The gameplay components (Damage.swift, Interaction.swift).
@MainActor
public enum GameplayComponents {
    public static let types: [any Component.Type] = [Health.self, Hurtbox.self, Hitbox.self, Interactable.self, Interactor.self,
                                                     Door.self, Lever.self, Container.self, Pickup.self]

    /// Registers them with `ComponentRegistry`, so scene files that use them load. Hosts call it
    /// at startup (`GamePlayer.registerEngineComponents`, the editor's component catalog).
    public static func register() {
        for type in types { ComponentRegistry.register(type) }
    }
}

/// One use of an interactable (the interaction system's log; Visual Script "On Interact").
public struct InteractEvent: Codable, Equatable, Sendable {
    public var sequence: Int
    public var interactor: Entity
    public var target: Entity
    public var action: InteractionAction
    /// The verb shown when it was used ("Open", "Pull", "Pick up key").
    public var verb: String
    /// What it did: "opened", "closed", "locked", "unlocked", "on", "off", "looted", "picked up", "used".
    public var result: String

    public init(sequence: Int, interactor: Entity, target: Entity, action: InteractionAction, verb: String, result: String) {
        self.sequence = sequence
        self.interactor = interactor
        self.target = target
        self.action = action
        self.verb = verb
        self.result = result
    }
}
