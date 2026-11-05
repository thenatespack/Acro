import Engine
import Foundation

/// The sound builder tools: `sfx.new`, `sfx.get`, `sfx.set`, `sfx.edit`, `sfx.play`, `sfx.open`.
@MainActor
public enum EditorSoundBuildCommands {
    public static let all: [any EditorCommand.Type] = [
        SoundBuildNewCommand.self,
        SoundBuildGetCommand.self,
        SoundBuildSetCommand.self,
        SoundBuildEditCommand.self,
        SoundBuildPlayCommand.self,
        SoundBuildOpenCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A sound build is a synthesized effect (every key optional): waveform square|saw|sine|noise, frequency Hz, slide \
        (octaves/second, negative falls), slideAcceleration, minFrequency (the sound ends when the pitch falls below it), \
        vibratoDepth (semitones) and vibratoRate (Hz), arpeggio (semitone jump after arpeggioTime seconds), duty and \
        dutySweep (square pulse width), attack / sustain / decay (seconds), punch 0-1, lowPass / highPass (Hz, 0 = off), \
        bitCrush (bits 1-15, 0 = off), volume 0-1, sampleRate, seed (drives the noise: the same parameters and seed give \
        identical samples). Presets: jump|coin|laser|explosion|hit|powerUp|blip. The file plays anywhere an audio file does: \
        set an AudioEmitter's `clip` to it.
        """

    /// Number of waveform peaks the tools return.
    static let peakCount = 48
}

/// The sound being previewed in the editor (a new preview replaces it).
@MainActor
enum SoundBuildPreview {
    private static var voice: Voice?

    /// Plays `build`; false when the editor has no audio device.
    @discardableResult
    static func play(_ build: SoundBuild, in session: EditorSession) -> Bool {
        guard let audio = session.audioProvider?() else { return false }
        voice?.stop()
        voice = audio.play(build.soundBuffer(name: "sfx preview"))
        return true
    }
}

extension EditorSession {
    /// Writes a sound build to "`name`.sfx" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createSoundBuildAsset(in folder: String, name: String = "New Sound", build: SoundBuild = .preset(.blip)) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Sound") else {
            log.error("New Sound: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".sfx"))
        do {
            let id = try assets.createSoundBuild(build, at: path)
            log.info("Created sound \(path)")
            return id
        } catch {
            log.error("New Sound failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.sfx` file.
    public func isSoundBuildFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == SoundBuildImporter().name
    }

    /// Replaces the contents of the sound build `id` as one undo step. Returns the import's
    /// warnings, nil on failure.
    @discardableResult
    public func applySoundBuild(_ build: SoundBuild, to id: AssetID, label: String = "Edit Sound") -> [String]? {
        guard let assets, let old = assets.soundBuild(of: id) else {
            log.error("\(label): \(id) isn't a readable .sfx file")
            return nil
        }
        guard old != build else { return [] }
        let command = SoundBuildFileEditCommand(asset: id, old: old, new: build, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }
}

/// Makes sound build edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct SoundBuildFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: SoundBuild
    public let new: SoundBuild
    /// The last write's import warnings.
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: SoundBuild, new: SoundBuild, in database: AssetDatabase, label: String = "Edit Sound") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ build: SoundBuild) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeSoundBuild(build, to: asset)
    }
}

/// Arguments naming a `.sfx` file.
public protocol SoundBuildTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    /// The sound build named by `target` and its contents.
    func resolveSoundBuild(_ target: some SoundBuildTarget, _ title: String) throws -> (AssetID, SoundBuild) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isSoundBuildFile(id), let build = assets?.soundBuild(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .sfx file")
        }
        return (id, build)
    }
}

/// What the sound tools return.
public struct SoundBuildResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// Set an AudioEmitter's `clip` to this ("asset:<id>").
    public var clip: AssetReference
    public var build: SoundBuild
    /// Length in seconds.
    public var duration: Float
    /// Peak loudness (0...1) across the sound, for a sense of its shape.
    public var peaks: [Float]
    public var warnings: [String]
    /// Whether the sound was played in the editor (`sfx.play`).
    public var played: Bool?
}

extension SoundBuildResult {
    @MainActor init(_ id: AssetID, _ build: SoundBuild, warnings: [String], played: Bool? = nil, in session: EditorSession) {
        let record = session.assets?.record(id)
        let samples = build.render()
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", clip: AssetReference(id), build: build,
                  duration: Float(samples.count) / Float(max(build.sampleRate, 1)),
                  peaks: build.peaks(count: EditorSoundBuildCommands.peakCount, of: samples),
                  warnings: Array(Set(build.problems() + warnings)).sorted() + (record?.importError.map { ["import failed: \($0)"] } ?? []),
                  played: played)
    }
}

public enum SoundBuildNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Sound" (the file gets ".sfx").
        public var name: String?
        /// Start from a preset (default blip).
        public var preset: SFXPreset?
        /// With a preset: a random variation, the same one for the same seed.
        public var seed: Int?
        /// Or the whole contents (overrides `preset`).
        public var build: SoundBuild?
        public init(folder: String? = nil, name: String? = nil, preset: SFXPreset? = nil, seed: Int? = nil, build: SoundBuild? = nil) {
            self.folder = folder
            self.name = name
            self.preset = preset
            self.seed = seed
            self.build = build
        }
    }

    public static let id: CommandID = "sfx.new"
    public static let title = "New Sound"
    public static let doc = "Writes a .sfx file in `folder` (default: the Assets root): a synthesized sound effect from `preset` (jump, coin, laser, explosion, hit, powerUp, blip) with an optional `seed` for a random variation, or from `build`. It imports as an audio file, so an AudioEmitter's `clip` can point at it. Returns the asset, its parameters, duration, a waveform summary and warnings. Change it with sfx.edit or sfx.set, hear it with sfx.play. " + EditorSoundBuildCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> SoundBuildResult {
        let build = arguments.build ?? .preset(arguments.preset ?? .blip, seed: arguments.seed)
        let id = try session.commands.require(session.createSoundBuildAsset(
            in: arguments.folder ?? "", name: arguments.name ?? "New Sound", build: build), title)
        return SoundBuildResult(id, build, warnings: [], in: session)
    }
}

public enum SoundBuildGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, SoundBuildTarget {
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "sfx.get"
    public static let title = "Get Sound"
    public static let doc = "Reads a .sfx file: every parameter (defaults included), its duration, a waveform summary (peak loudness across the sound) and warnings."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> SoundBuildResult {
        let (id, build) = try session.resolveSoundBuild(arguments, title)
        return SoundBuildResult(id, build, warnings: [], in: session)
    }
}

public enum SoundBuildSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, SoundBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var build: SoundBuild
        public init(asset: AssetReference? = nil, path: String? = nil, build: SoundBuild) {
            self.asset = asset
            self.path = path
            self.build = build
        }
    }

    public static let id: CommandID = "sfx.set"
    public static let title = "Set Sound"
    public static let doc = "Replaces a .sfx file's whole contents and reimports it. Undoable. For a few changes, sfx.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> SoundBuildResult {
        let (id, _) = try session.resolveSoundBuild(arguments, title)
        let warnings = try session.commands.require(session.applySoundBuild(arguments.build, to: id, label: title), title)
        return SoundBuildResult(id, arguments.build, warnings: warnings, in: session)
    }
}

public enum SoundBuildEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, SoundBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Replace the parameters with this preset (typical values; with `seed`, a random variation of it).
        public var preset: SFXPreset?
        /// Replace the parameters with a random variation of `preset` (needs `preset`; the seed
        /// defaults to the file's seed + 1, so repeating the call is predictable).
        public var randomize: Bool?
        /// Move every continuous parameter by up to this fraction (0...1) of its size.
        public var mutate: Float?
        /// Seed for `preset` / `randomize` / `mutate`; the file's `seed` becomes it.
        public var seed: Int?
        /// Fields to change, applied last: e.g. {"frequency": 660, "waveform": "saw"}.
        public var changes: JSONValue?
        public init(asset: AssetReference? = nil, path: String? = nil, preset: SFXPreset? = nil, randomize: Bool? = nil,
                    mutate: Float? = nil, seed: Int? = nil, changes: JSONValue? = nil) {
            self.asset = asset
            self.path = path
            self.preset = preset
            self.randomize = randomize
            self.mutate = mutate
            self.seed = seed
            self.changes = changes
        }
    }

    public static let id: CommandID = "sfx.edit"
    public static let title = "Edit Sound"
    public static let doc = "Changes a .sfx file in one undoable step, in this order: `preset` (load it; `randomize` with `seed` for a variation), `mutate` (jitter every continuous parameter by that fraction), then `changes` (field name → new value). Returns the new parameters, duration, waveform summary and warnings. Hear the result with sfx.play."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> SoundBuildResult {
        let (id, original) = try session.resolveSoundBuild(arguments, title)
        let build = try edited(original, with: arguments)
        let warnings = try session.commands.require(session.applySoundBuild(build, to: id, label: title), title)
        return SoundBuildResult(id, build, warnings: warnings, in: session)
    }

    /// `build` with the edits of `arguments` applied (pure, for tests and the UI).
    public static func edited(_ build: SoundBuild, with arguments: Arguments) throws -> SoundBuild {
        var build = build
        if arguments.randomize == true && arguments.preset == nil { throw CommandError.failed("randomize needs a preset") }
        if let preset = arguments.preset {
            let seed = arguments.seed ?? (arguments.randomize == true ? build.seed &+ 1 : nil)
            let previousSeed = build.seed
            build = .preset(preset, seed: seed)
            if seed == nil { build.seed = previousSeed }
        }
        if let amount = arguments.mutate {
            build = build.mutated(amount: amount, seed: arguments.seed ?? build.seed &+ 1)
        } else if arguments.preset == nil, let seed = arguments.seed {
            build.seed = seed
        }
        if let changes = arguments.changes {
            guard case .object(let fields) = changes else { throw CommandError.failed("changes must be an object of fields") }
            guard var json = try? JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(build)),
                  case .object(var current) = json else { return build }
            for (key, value) in fields { current[key] = value }
            json = .object(current)
            do { build = try JSONDecoder().decode(SoundBuild.self, from: JSONEncoder().encode(json)) } catch {
                throw CommandError.failed("changes: \(error)")
            }
        }
        return build
    }
}

public enum SoundBuildPlayCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, SoundBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "sfx.play"
    public static let title = "Play Sound"
    public static let doc = "Plays a .sfx file once through the editor's audio output (a new preview replaces the one playing). Returns its duration and waveform summary; `played` is false when the editor has no audio device."
    public static let isReadOnly = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> SoundBuildResult {
        let (id, build) = try session.resolveSoundBuild(arguments, title)
        let played = SoundBuildPreview.play(build, in: session)
        return SoundBuildResult(id, build, warnings: played ? [] : ["no audio device: nothing was played"], played: played, in: session)
    }
}

public enum SoundBuildOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, SoundBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "sfx.open"
    public static let title = "Open in Sound Builder"
    public static let doc = "Opens a .sfx file in the editor's Sound Builder tab (waveform view, play button, presets with Randomize and Mutate, and the parameters form) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"soundBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveSoundBuild(arguments, title)
        session.openSoundBuild = id
        session.onOpenSoundBuild?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}
