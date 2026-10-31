import Foundation

// Game code as a dynamic library ("game module") that a host — the editor, or `GameRunner` —
// loads at run time, so the editor can load any game and reload its code without restarting.
//
// ## The ABI
//
// A module exports one C symbol, `GameModuleABI.entryPoint`, with the signature
// `@convention(c) (UnsafeMutableRawPointer) -> Int32`. The host passes an unretained
// `GameModule`; the module fills it in (name, components, systems, optionally a `Game` for
// standalone runs) and returns the ABI version it was built for:
//
// ```swift
// import Engine
//
// @_cdecl("swift_game_engine_module_v1")
// public func registerGameModule(_ module: UnsafeMutableRawPointer) -> Int32 {
//     GameModule.register(module) { game in
//         game.name = "MyGame"
//         game.component(Health.self) { Health(points: 100) }
//         game.system("mygame.regen") { world, context in … }
//     }
// }
// ```
//
// Everything else that crosses the boundary is a Swift type owned by Engine (`GameModule`,
// `Component`, `World`, `Input`, `Game`). That only works if the host and the module use the
// *same* copy of Engine: a second copy would have its own type metadata (its `Transform` is
// not the host's, so `world.get(Transform.self, …)` finds nothing) and its own globals (a
// second `ComponentRegistry`). So the module is linked from the game target's object files
// alone, with Engine's symbols left undefined and resolved against the host process when it
// is loaded (`-undefined dynamic_lookup` on macOS; shared libraries may have undefined
// symbols on Linux, where the host is linked with `--export-dynamic`). `GameModuleBuilder`
// does that link. A SwiftPM `.dynamic` library product would not work: SwiftPM links a
// product's whole target closure statically, Engine included, and a package can't depend on
// its own products to get a shared `libEngine`. See README "Game modules".
//
// ## Versions
//
// The major version is in the entry point's name (`_v1`) and is what `register` returns; a
// host refuses another one. Minor versions add optional parts a module may use, and old
// modules keep loading: `register` records the minor version the module was compiled
// against (`GameModule.abiMinorVersion`, 0 for modules from before minor versions).
// 1.1 added the reload hooks (`willUnload` / `didLoad`, below).
//
// ## State across reloads
//
// Each load maps a fresh copy of the library, so the module's statics (singletons, caches,
// counters) start over. ECS state survives on its own (components are serialized and
// restored); for the rest, hand it from the old code to the new as Codable data:
//
// ```swift
// game.willUnload { Stats.shared }                       // any Encodable; JSON in between
// game.didLoad(Stats.self) { saved in Stats.shared = saved ?? Stats() }
// ```
//
// The host calls the old module's `willUnload` before taking it out and the new module's
// `didLoad` after its types are registered, with the decoded state (nil on the first load,
// when the previous version saved nothing, or when the data doesn't decode as the new type:
// keep the type's decoding tolerant with optionals or `decodeIfPresent`). An unload keeps the
// state for the next load.
//
// Consequences: a module must be built from the same Engine sources, in the same
// configuration, as the host that loads it (Engine is not built for library evolution, so
// struct layouts are baked into the module). The loader rejects a module that carries its
// own Engine, and the builder refuses to load one built after Engine changed under a
// running host.

/// The game module ABI's constants.
public enum GameModuleABI {
    /// The C symbol a module exports. The version is part of the name, so a module built for
    /// another ABI fails to load with a clear error rather than misbehaving.
    public static let entryPoint = "swift_game_engine_module_v1"
    /// What `GameModule.register` returns; checked by the loader. Inlinable, so a module
    /// returns the version it was compiled against, not the host's.
    @inlinable public static var version: Int32 { 1 }
    /// Optional additions within the major version (see "Versions" above); recorded in
    /// `GameModule.abiMinorVersion` by `register`, compiled into the module like `version`.
    @inlinable public static var minorVersion: Int32 { 1 }
    /// A symbol only Engine defines; a module that defines it too carries its own Engine.
    public static let engineMarker = "swift_game_engine_host_marker"
}

/// Defined by Engine only (see `GameModuleABI.engineMarker`).
@_cdecl("swift_game_engine_host_marker")
public func swiftGameEngineHostMarker() -> Int32 { GameModuleABI.version }

/// The marker's address in this image (taken here: elsewhere the compiler emits a second
/// definition of the C symbol).
nonisolated(unsafe) let swiftGameEngineHostMarkerAddress = unsafeBitCast(
    swiftGameEngineHostMarker as @convention(c) () -> Int32, to: UnsafeMutableRawPointer.self)

/// What a game module registers with its host: filled in by the module's entry point (see
/// the notes at the top of this file).
@MainActor
public final class GameModule {
    /// The module's display name ("SampleGame").
    public var name = ""
    /// One line about the game, shown by the editor.
    public var summary = ""
    /// Component types, in registration order.
    public private(set) var components: [GameComponent] = []
    /// Systems, in registration order. Hosts add them while the game runs (the editor's play
    /// mode) and remove them when it stops or the module is unloaded.
    public private(set) var systems: [GameSystem] = []
    /// The game for standalone runs (`GameRunner`); nil runs the module's systems on a scene.
    public var makeGame: (@MainActor () -> any Game)?
    /// The ABI minor version the module was built against (set by `register`; 0: older).
    public var abiMinorVersion: Int32 = 0
    /// Returns the state to hand to the next version of the module, as JSON (see "State
    /// across reloads" above). Set with `willUnload(_:)`.
    public private(set) var saveState: (@MainActor () throws -> Data)?
    /// Takes the previous version's state (nil: none). Set with `didLoad(_:_:)`.
    public private(set) var restoreState: (@MainActor (Data?) -> Void)?

    public init() {}

    /// Before this module is reloaded or unloaded: `save` returns state (statics, caches) for
    /// the next version, encoded as JSON (ABI 1.1).
    public func willUnload<State: Encodable>(_ save: @escaping @MainActor () -> State) {
        saveState = {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            return try encoder.encode(save())
        }
    }

    /// After this module was loaded and its types registered: `restore` gets what the previous
    /// version's `willUnload` saved, decoded as `State`, or nil (first load, nothing saved, or
    /// it doesn't decode) (ABI 1.1).
    public func didLoad<State: Decodable>(_ type: State.Type, _ restore: @escaping @MainActor (State?) -> Void) {
        restoreState = { data in restore(data.flatMap { try? JSONDecoder().decode(State.self, from: $0) }) }
    }

    /// Registers a component type, created with `make` by the editor's Add Component. Give it
    /// a stable `componentName`: saved scenes and hot reload refer to it by name.
    public func component<C: Component>(_ type: C.Type, make: @escaping () -> C) {
        components.append(GameComponent(type: type, makeDefault: make))
    }

    /// Registers a system for `stage`, run by the host's world while the game runs. `name`
    /// must be unique in the world (prefix it with the game's name); `before` / `after` name
    /// another system in the same stage (ignored, with a warning, when there is none).
    public func system(_ name: String, stage: SystemStage = .update, before: String? = nil, after: String? = nil,
                       _ run: @escaping @MainActor (World, GameContext) -> Void) {
        systems.append(GameSystem(name: name, stage: stage, before: before, after: after, run: run))
    }

    /// For the module's entry point: fills the host's `GameModule` (passed as `raw`) with
    /// `body` and returns the ABI version the module was built for.
    @inlinable
    public nonisolated static func register(_ raw: UnsafeMutableRawPointer, _ body: @MainActor (GameModule) -> Void) -> Int32 {
        let address = UInt(bitPattern: raw)
        MainActor.assumeIsolated {
            let module = Unmanaged<GameModule>.fromOpaque(UnsafeRawPointer(bitPattern: address)!).takeUnretainedValue()
            module.abiMinorVersion = GameModuleABI.minorVersion
            body(module)
        }
        return GameModuleABI.version
    }

    /// The component names, in registration order.
    public var componentNames: [String] { components.map(\.name) }

    // MARK: Systems

    /// Adds the module's systems to `world`, each called with `context`. Returns warnings
    /// (a name already taken, a missing `before` / `after` anchor); never traps.
    @discardableResult
    public func addSystems(to world: World, context: GameContext) -> [String] {
        var warnings: [String] = []
        for system in systems {
            let taken = SystemStage.allCases.contains { world.systemNames(in: $0).contains(system.name) }
            if taken {
                warnings.append("System '\(system.name)' already exists; skipped")
                continue
            }
            let names = world.systemNames(in: system.stage)
            var before = system.before, after = system.after
            if let anchor = before ?? after, !names.contains(anchor) {
                warnings.append("System '\(system.name)': no system '\(anchor)' in \(system.stage); added last")
                before = nil
                after = nil
            }
            if before != nil { after = nil }
            let run = system.run
            world.addSystem(system.name, stage: system.stage, before: before, after: after) { world in run(world, context) }
        }
        return warnings
    }

    /// Removes the module's systems from `world`.
    public func removeSystems(from world: World) {
        for system in systems { world.removeSystem(named: system.name) }
    }
}

/// A component type a game module registers.
public struct GameComponent {
    public let type: any Component.Type
    public let makeDefault: () -> any Component
    public var name: String { type.componentName }

    public init(type: any Component.Type, makeDefault: @escaping () -> any Component) {
        self.type = type
        self.makeDefault = makeDefault
    }
}

/// A system a game module registers (see `GameModule.system`).
public struct GameSystem {
    public let name: String
    public let stage: SystemStage
    public let before: String?
    public let after: String?
    public let run: @MainActor (World, GameContext) -> Void
}

/// What a game module's systems get from the host besides the world.
@MainActor
public final class GameContext {
    /// The game's input: the editor's `gameInput` (Game View and injected input, never the
    /// editor's own clicks) or the window's input in a standalone run.
    public let input: Input
    /// Writes a line to the host's log (the editor's console).
    public let log: @MainActor (String) -> Void

    public init(input: Input, log: @escaping @MainActor (String) -> Void = { print($0) }) {
        self.input = input
        self.log = log
    }
}

/// Where a host finds a game module: `Project.json`'s `"game"` object, or the editor's
/// `--game` option. Either a SwiftPM target to build and link (`target`, in the package at
/// `package`), or a prebuilt module (`library`, a `.dylib` / `.so`).
public struct GameModuleSettings: Equatable, Sendable, Codable {
    /// The game's SwiftPM target ("SampleGame").
    public var target: String?
    /// The package folder holding `target`, relative to the project folder; nil searches up
    /// from it (or from the working directory) for a `Package.swift`.
    public var package: String?
    /// A prebuilt module, relative to the project folder; reloading copies it again (after
    /// running `buildCommand`, if any).
    public var library: String?
    /// The build command instead of `swift build --target <target>`, run in the package
    /// folder (`["make", "game"]`).
    public var buildCommand: [String]?
    /// Reload when a source file of `target` (`Sources/<target>/`) changes.
    public var watch: Bool?

    public init(target: String? = nil, package: String? = nil, library: String? = nil, buildCommand: [String]? = nil,
                watch: Bool? = nil) {
        self.target = target
        self.package = package
        self.library = library
        self.buildCommand = buildCommand
        self.watch = watch
    }

    /// From an editor `--game` argument: a path to a module file, or a target name.
    public init(argument: String) {
        let lower = argument.lowercased()
        if lower.hasSuffix(".dylib") || lower.hasSuffix(".so") || lower.hasSuffix(".dll") || argument.contains("/") {
            self.init(library: argument)
        } else {
            self.init(target: argument)
        }
    }
}
