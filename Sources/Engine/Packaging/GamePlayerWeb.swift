#if os(WASI)
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import JavaScriptKit
import EngineAssets
import EngineCore

// The exported game's runtime in a browser (Web/loader.js starts it). A browser can't block in
// a loop, so `main` starts the game and returns: `WebFrameDriver` then runs one engine frame
// per `requestAnimationFrame`. PackageToJS builds the player as a WASI reactor, so returning
// from `main` keeps the instance alive (calling `exit` would end it).
//
// The page talks to the player through `globalThis.acro`:
// - in: `args` (the command line, as strings), `pack` (the fetched pack as a Uint8Array; the
//   player copies it and deletes it) and `packName`; `adapter`, `device`, `context`, `format`
//   and `canvas` for the WebGPU device.
// - out: `onError(message)` when the game fails to start or a frame throws, `onExit(code)`
//   when it ends (0: quit normally).

extension GamePlayer {
    /// The browser's `main`: like the native one, but it returns once the game has started,
    /// and reports failures to `acro.onError` and the console instead of exiting.
    public static func main(module entry: (UnsafeMutableRawPointer) -> Int32, arguments: [String]? = nil) {
        do {
            let options = try Options.parse(arguments ?? WebHost.arguments)
            if options.version {
                print(EngineVersion.displayName)
                WebHost.exited(0)
                return
            }
            let (engine, game) = try prepare(options: options, module: entry) { try WebHost.openPack(explicit: options.pack) }
            do {
                try engine.start(game)
            } catch {
                engine.finish()
                throw error
            }
            WebFrameDriver.start(tick: { try engine.tick() }, finish: { engine.finish() })
        } catch {
            WebHost.report(error)
        }
    }
}

/// `globalThis.acro`: what the page passes the player, and the callbacks it reports to.
@MainActor
public enum WebHost {
    /// `globalThis.acro` (undefined before the loader sets it up).
    public static var acro: JSValue { JSObject.global.acro }

    /// The player's command line: `acro.args`, else the WASI arguments.
    public static var arguments: [String] {
        if let args = acro.args.object, let count = args.length.number {
            return (0..<Int(count)).compactMap { args[$0].string }
        }
        return Array(CommandLine.arguments.dropFirst())
    }

    /// The pack the page fetched (`acro.pack`, a Uint8Array), opened from memory, else the
    /// one at `explicit` (`--pack`) in the WASI filesystem.
    public static func openPack(explicit: String?) throws -> AssetPack {
        if let object = acro.pack.object, let array = JSTypedArray<UInt8>(from: .object(object)) {
            let data = array.withUnsafeBytes { Data(buffer: $0) }
            // The player has its own copy now; let the browser free the fetched one.
            acro.object?["pack"] = .undefined
            return try AssetPack(data: data, name: acro.packName.string ?? "Game.pack")
        }
        if let path = explicit ?? ProcessInfo.processInfo.environment["ENGINE_PACK"] { return try AssetPack(url: URL(fileURLWithPath: path)) }
        throw GamePlayerError.noPack(["acro.pack"])
    }

    /// Prints `error` to the console and passes it to `acro.onError`.
    public static func report(_ error: any Error) {
        let message = "\(error)"
        FileHandle.standardError.write(Data((message + "\n").utf8))
        if let onError = acro.onError.function { _ = onError(message) }
    }

    /// Tells the page the game ended (`acro.onExit(code)`).
    public static func exited(_ code: Int) {
        if let onExit = acro.onExit.function { _ = onExit(code) }
    }
}

/// Runs a main loop from `requestAnimationFrame`: `tick` once per animation frame until it
/// returns false or throws, then `finish` once (and `acro.onExit(0)`, or the error to
/// `acro.onError`).
@MainActor
public enum WebFrameDriver {
    private static var callback: JSClosure?
    /// Animation frames that ran `tick`.
    public private(set) static var frames = 0
    /// Whether a loop is running.
    public static var isRunning: Bool { callback != nil }

    public static func start(tick: @escaping @MainActor () throws -> Bool, finish: @escaping @MainActor () -> Void) {
        precondition(callback == nil, "WebFrameDriver is already running")
        let callback = JSClosure { _ in
            MainActor.assumeIsolated {
                frames += 1
                let more: Bool
                do {
                    more = try tick()
                } catch {
                    stop()
                    finish()
                    WebHost.report(error)
                    return
                }
                if more {
                    requestFrame()
                } else {
                    stop()
                    finish()
                    WebHost.exited(0)
                }
            }
            return .undefined
        }
        self.callback = callback
        requestFrame()
    }

    private static func requestFrame() {
        guard let callback else { return }
        _ = JSObject.global.requestAnimationFrame!(callback)
    }

    private static func stop() {
        callback = nil
    }
}
#endif
