import Engine
import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

// Crash recovery: game code runs in the editor's process, so a trap in it (or anywhere) takes
// the editor down. This keeps the user's work recoverable.
//
// While the editor runs, `EditorRecovery` keeps the scene as it would be saved, encoded in
// memory: the edit-time scene (while playing, the one play started from, i.e. the user's
// work) re-encoded at most once a second when the undo history moved, and while playing the
// live play world every couple of seconds. They go to disk under
// `<prefs folder>/Recovery/<pid>/` (`scene.json`, `play.json`, `recovery.json`):
// - every 10 s while there are unsaved changes, and right before risky moments (a game code
//   swap, entering play mode: `checkpoint`);
// - from the crash reporter's fatal hook (a fatal signal: Swift traps, `fatalError`,
//   `precondition`, bad memory accesses; or `engineFatal`), which only writes the buffers
//   prepared beforehand with open / write / close, nothing that allocates;
// - on a clean exit with unsaved changes (the window closed, Cmd-Q), so closing the window by
//   mistake loses nothing either. A clean exit without unsaved changes deletes the folder.
//
// On the next launch, folders whose process is gone are offered: a dialog (Recover / Not Now)
// and a console line; `scene.recover` opens the scene (or the play state) as an unsaved
// document that saves to the original file, `scene.discardRecovery` deletes it,
// `scene.listRecovery` lists them. Several editors can run at once: each writes its own
// folder, and folders of running processes are left alone.
//
// What can't be recovered: a crash in the first second after an edit (the buffer is up to a
// second old), and anything killed with SIGKILL between disk writes (up to 10 s). The process
// isn't kept alive: in Swift a trap can't be caught and continued from (see README › Game
// modules › Crashes).

/// A recoverable session's description (`recovery.json`).
public struct RecoveryInfo: Codable, Equatable, Sendable {
    /// The folder's name: the process id of the editor that wrote it.
    public var id: String
    /// When it was written.
    public var date: Date
    /// Why it was left behind ("the editor crashed or was killed", "closed with unsaved changes").
    public var reason: String
    /// The scene's file (nil: never saved) and display name.
    public var scenePath: String?
    public var sceneName: String
    /// Whether the scene had unsaved changes.
    public var unsaved: Bool
    /// Whether a play state (`play.json`) is included: the editor was playing.
    public var hasPlayState: Bool
    /// The game module that was loaded, if any.
    public var gameModule: String?
    /// Entities in the scene.
    public var entities: Int
}

/// Keeps the editor's unsaved work recoverable (see the notes at the top of the file).
@MainActor
public final class EditorRecovery {
    /// `<prefs folder>/Recovery`.
    public let folder: URL
    /// This process's folder in it.
    public let ownFolder: URL
    unowned let session: EditorSession
    /// Recoverable folders of sessions that are gone, found at start (newest first).
    public private(set) var found: [RecoveryInfo] = []

    private var sceneData: Data?
    private var playData: Data?
    private var sceneKey: (changeCount: Int, playing: Bool, generation: Int)?
    private var generation = 0
    private var lastSceneEncode = Date.distantPast
    private var lastPlayEncode = Date.distantPast
    private var lastDiskWrite = Date.distantPast
    private var diskWriteDirty = false
    private var encodeCost: Double = 0
    private var hookID: Int?
    /// Seconds between disk writes while there are unsaved changes.
    public var diskInterval: Double = 10

    /// Starts keeping `session`'s work under `folder`; `installsCrashHook` installs the crash
    /// reporter's signal handlers (if not yet) and the hook that writes the buffers.
    public init(session: EditorSession, folder: URL, installsCrashHook: Bool = true) {
        self.session = session
        self.folder = folder
        ownFolder = folder.appendingPathComponent(String(ProcessInfo.processInfo.processIdentifier), isDirectory: true)
        found = Self.recoverable(in: folder)
        if installsCrashHook {
            CrashReporter.install()
            hookID = CrashReporter.addFatalHook { RecoveryBuffers.shared.writeAll() }
        }
    }

    // MARK: Keeping the buffers

    /// The scene changed in a way the undo history doesn't show (a reload converted its game
    /// components, a recovery was opened): encode it again on the next `update`.
    public func invalidate() { generation += 1 }

    /// Called every frame: re-encodes what changed (throttled) and writes to disk now and then.
    public func update(now: Date = Date()) {
        let key = (session.undo.changeCount, session.isPlaying, generation)
        let minimum = max(1, encodeCost * 50)
        if sceneKey.map({ $0 != key }) ?? true, now.timeIntervalSince(lastSceneEncode) >= minimum {
            encodeScene()
            sceneKey = key
            lastSceneEncode = now
        }
        if session.isPlaying, now.timeIntervalSince(lastPlayEncode) >= max(2, encodeCost * 100) {
            encodePlay()
            lastPlayEncode = now
        } else if !session.isPlaying, playData != nil {
            playData = nil
            publish()
        }
        if diskWriteDirty, hasWork, now.timeIntervalSince(lastDiskWrite) >= diskInterval {
            writeToDisk()
        }
    }

    /// Encodes everything now and writes it to disk: before a risky moment (game code about to
    /// be swapped or to start running).
    public func checkpoint() {
        encodeScene()
        sceneKey = (session.undo.changeCount, session.isPlaying, generation)
        lastSceneEncode = Date()
        if session.isPlaying {
            encodePlay()
            lastPlayEncode = Date()
        }
        if hasWork { writeToDisk() }
    }

    /// Whether there is anything worth recovering: unsaved changes, or a play state.
    private var hasWork: Bool { session.document.isDirty || playData != nil }

    private func encodeScene() {
        let start = Date()
        do {
            if session.isPlaying, let snapshot = session.playSnapshot {
                let scratch = World()
                scratch.restore(snapshot)
                sceneData = try scratch.save()
            } else {
                sceneData = try session.world.save()
            }
        } catch {
            session.log.warning("Recovery: couldn't encode the scene: \(error)")
        }
        encodeCost = Date().timeIntervalSince(start)
        diskWriteDirty = true
        publish()
    }

    private func encodePlay() {
        let start = Date()
        do { playData = try session.world.save() } catch { playData = nil }
        encodeCost = max(encodeCost, Date().timeIntervalSince(start))
        diskWriteDirty = true
        publish()
    }

    private func info(reason: String) -> RecoveryInfo {
        RecoveryInfo(
            id: ownFolder.lastPathComponent, date: Date(), reason: reason, scenePath: session.document.url?.path,
            sceneName: session.document.displayName, unsaved: session.document.isDirty, hasPlayState: playData != nil,
            gameModule: session.gameModule.loaded?.module.name, entities: session.world.entityCount)
    }

    private static let crashReason = "the editor crashed or was killed"

    /// Hands the buffers to the fatal hook (with a manifest saying it crashed).
    private func publish() {
        guard hasWork, let sceneData else {
            RecoveryBuffers.shared.set([])
            // Saved (or nothing to keep any more): what is on disk is stale.
            if lastDiskWrite != .distantPast {
                try? FileManager.default.removeItem(at: ownFolder)
                lastDiskWrite = .distantPast
            }
            return
        }
        var files: [(URL, Data)] = [(ownFolder.appendingPathComponent("scene.json"), sceneData)]
        if let playData { files.append((ownFolder.appendingPathComponent("play.json"), playData)) }
        if let manifest = try? Self.encoder.encode(info(reason: Self.crashReason)) {
            files.append((ownFolder.appendingPathComponent("recovery.json"), manifest))
        }
        // The folder exists before a signal handler would need it.
        try? FileManager.default.createDirectory(at: ownFolder, withIntermediateDirectories: true)
        RecoveryBuffers.shared.set(files)
    }

    private func writeToDisk(reason: String = EditorRecovery.crashReason) {
        guard let sceneData else { return }
        do {
            try FileManager.default.createDirectory(at: ownFolder, withIntermediateDirectories: true)
            try sceneData.write(to: ownFolder.appendingPathComponent("scene.json"), options: .atomic)
            let play = ownFolder.appendingPathComponent("play.json")
            if let playData { try playData.write(to: play, options: .atomic) } else { try? FileManager.default.removeItem(at: play) }
            try Self.encoder.encode(info(reason: reason)).write(to: ownFolder.appendingPathComponent("recovery.json"), options: .atomic)
        } catch {
            session.log.warning("Recovery: couldn't write \(ownFolder.path): \(error)")
        }
        lastDiskWrite = Date()
        diskWriteDirty = false
    }

    /// A clean exit: keeps the work if it is unsaved ("closed with unsaved changes: <why>"),
    /// else deletes this process's folder.
    public func finish(quitReason: String?) {
        if let hookID { CrashReporter.removeFatalHook(hookID) }
        hookID = nil
        RecoveryBuffers.shared.set([])
        if session.document.isDirty {
            encodeScene()
            playData = nil
            writeToDisk(reason: "closed with unsaved changes" + (quitReason.map { " (\($0))" } ?? ""))
            session.log.warning("Recovery: unsaved changes kept in \(ownFolder.path); the next launch offers them")
        } else {
            try? FileManager.default.removeItem(at: ownFolder)
        }
    }

    // MARK: Previous sessions

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Folders in `folder` left by sessions that are gone (their process isn't running),
    /// newest first.
    public static func recoverable(in folder: URL) -> [RecoveryInfo] {
        let own = String(ProcessInfo.processInfo.processIdentifier)
        let entries = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return entries.compactMap { entry -> RecoveryInfo? in
            let id = entry.lastPathComponent
            guard id != own, let pid = Int32(id), !isRunning(pid),
                  let data = try? Data(contentsOf: entry.appendingPathComponent("recovery.json")),
                  var info = try? decoder.decode(RecoveryInfo.self, from: data),
                  FileManager.default.fileExists(atPath: entry.appendingPathComponent("scene.json").path) else { return nil }
            info.id = id
            return info
        }.sorted { $0.date > $1.date }
    }

    private static func isRunning(_ pid: Int32) -> Bool {
        #if canImport(Darwin) || canImport(Glibc)
        return kill(pid, 0) == 0 || errno == EPERM
        #else
        return false
        #endif
    }

    /// Re-reads the folder.
    public func refresh() { found = Self.recoverable(in: folder) }

    /// Opens a recovered scene (`id`, default the newest) as the document: unsaved, saving to
    /// its original file. `playState` opens the play world at the crash instead, as a new
    /// unsaved scene. The recovery folder is deleted (the work is the document now, kept by
    /// this session's own recovery).
    @discardableResult
    public func recover(id: String? = nil, playState: Bool = false) throws -> RecoveryInfo {
        guard !session.isPlaying else { throw EditorError.playing }
        guard let info = id.map({ id in found.first { $0.id == id } }) ?? found.first else {
            throw CommandError.failed(id.map { "No recoverable session '\($0)'" } ?? "Nothing to recover")
        }
        let entry = folder.appendingPathComponent(info.id, isDirectory: true)
        let file = entry.appendingPathComponent(playState ? "play.json" : "scene.json")
        let data: Data
        do { data = try Data(contentsOf: file) } catch {
            throw CommandError.failed(playState ? "That session has no play state" : "Couldn't read \(file.path): \(error)")
        }
        session.onWillReplaceWorld?()
        try session.document.recover(data, url: playState ? nil : info.scenePath.map { URL(fileURLWithPath: $0) })
        try? FileManager.default.removeItem(at: entry)
        refresh()
        invalidate()
        session.log.info("Recovered \(playState ? "the play state of " : "")\(info.sceneName) from \(Self.describe(info))")
        session.changed()
        return info
    }

    /// Deletes a recovered session (`id`, default all).
    public func discard(id: String? = nil) {
        for info in found where id == nil || info.id == id {
            try? FileManager.default.removeItem(at: folder.appendingPathComponent(info.id, isDirectory: true))
        }
        refresh()
    }

    /// "the editor crashed or was killed, 2026-10-31 10:37".
    static func describe(_ info: RecoveryInfo) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return "a session that ended \(formatter.string(from: info.date)) (\(info.reason))"
    }
}

/// The files the fatal hook writes, prepared on the main thread: paths as C strings and their
/// bytes, so the hook only calls open / write / close.
final class RecoveryBuffers: @unchecked Sendable {
    static let shared = RecoveryBuffers()
    private let lock = NSLock()
    private var files: [(path: [CChar], bytes: [UInt8])] = []

    func set(_ new: [(URL, Data)]) {
        let prepared = new.map { (Array($0.0.path.utf8CString), [UInt8]($0.1)) }
        lock.withLock { files = prepared }
    }

    /// From a signal handler: writes the files if the buffers aren't being replaced right now.
    func writeAll() {
        guard lock.try() else { return }
        defer { lock.unlock() }
        for file in files {
            guard !file.bytes.isEmpty else { continue }
            file.path.withUnsafeBufferPointer { path in
                let descriptor = open(path.baseAddress!, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
                guard descriptor >= 0 else { return }
                file.bytes.withUnsafeBufferPointer { bytes in
                    var offset = 0
                    while offset < bytes.count {
                        #if os(Windows)
                        let written = Int(write(descriptor, bytes.baseAddress! + offset, UInt32(bytes.count - offset)))
                        #else
                        let written = write(descriptor, bytes.baseAddress! + offset, bytes.count - offset)
                        #endif
                        if written <= 0 { break }
                        offset += written
                    }
                }
                close(descriptor)
            }
        }
    }
}
