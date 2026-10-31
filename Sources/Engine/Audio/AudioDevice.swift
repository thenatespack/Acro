import Foundation

/// Fills `frames` frames of interleaved stereo float samples. Devices call it on their audio
/// thread; it must be real-time safe (the engine's `AudioMixer` is).
public typealias AudioRenderCallback = @Sendable (_ output: UnsafeMutablePointer<Float>, _ frames: Int) -> Void

/// An audio output: pulls interleaved stereo float frames from a render callback at
/// `sampleRate`. The engine's `AudioSystem` mixes in Swift and only needs this.
///
/// Implementations: `AVAudioEngineDevice` (macOS default), `MiniaudioDevice` (Linux and
/// Windows default; also on macOS) and `OfflineAudioDevice` (renders on demand into memory:
/// tests, screenshots, headless runs).
public protocol AudioDevice: AnyObject {
    /// Frames per second the callback is asked for.
    var sampleRate: Double { get }
    /// A name for logs ("MacBook Pro Speakers (AVAudioEngine)").
    var name: String { get }
    /// True when the device pulls frames on its own thread. False for `OfflineAudioDevice`,
    /// which renders only when asked (`AudioSystem.update` does it as time passes).
    var isRealtime: Bool { get }
    /// Starts calling `render`. Throws if the device can't start.
    func start(render: @escaping AudioRenderCallback) throws
    /// Stops calling the callback; when it returns, the callback is no longer running.
    func stop()
}

public struct AudioError: Error, CustomStringConvertible {
    public let description: String
    public init(_ description: String) { self.description = description }
}

/// Renders on demand into memory instead of to speakers. Deterministic: the same commands
/// and the same `render` calls always produce the same samples. Used by tests, by automated
/// screenshots (`ENGINE_SCREENSHOT`) and when no real device is available.
public final class OfflineAudioDevice: AudioDevice {
    public let sampleRate: Double
    public var name: String { "Offline (\(Int(sampleRate)) Hz)" }
    public var isRealtime: Bool { false }
    private var callback: AudioRenderCallback?
    private var scratch: [Float] = []

    public init(sampleRate: Double = 48000) {
        self.sampleRate = sampleRate
    }

    public func start(render: @escaping AudioRenderCallback) throws { callback = render }
    public func stop() { callback = nil }

    /// Renders `frames` frames (interleaved stereo) on the calling thread. Silence when stopped.
    public func render(frames: Int) -> [Float] {
        var output = [Float](repeating: 0, count: frames * 2)
        render(frames: frames, into: &output)
        return output
    }

    /// Renders and drops `frames` frames, reusing an internal buffer.
    public func advance(frames: Int) {
        if scratch.count < frames * 2 { scratch = [Float](repeating: 0, count: frames * 2) }
        render(frames: frames, into: &scratch)
    }

    private func render(frames: Int, into output: inout [Float]) {
        guard let callback, frames > 0 else { return }
        output.withUnsafeMutableBufferPointer { callback($0.baseAddress!, frames) }
    }
}

extension AudioSystem {
    /// The device the engine uses when nothing else is asked for, chosen by `ENGINE_AUDIO`:
    /// - `offline` (or `off`, `none`): `OfflineAudioDevice`, silent.
    /// - `avaudioengine` (macOS only) or `miniaudio`: that backend.
    /// - unset or `default`: AVAudioEngine on macOS, miniaudio elsewhere.
    /// `headless` (automated screenshots) picks the offline device unless `ENGINE_AUDIO` names
    /// a backend, so the frames don't depend on audio timing. A backend that fails to start
    /// falls back to the offline device (printed), so a machine without sound still runs.
    public static func makeDefaultDevice(headless: Bool = false) -> AudioDevice {
        let choice = ProcessInfo.processInfo.environment["ENGINE_AUDIO"]?.lowercased() ?? "default"
        if (headless && choice == "default") || ["offline", "off", "none", "null"].contains(choice) {
            return OfflineAudioDevice()
        }
        do {
            switch choice {
            case "miniaudio":
                return try MiniaudioDevice()
            case "avaudioengine":
                #if canImport(AVFAudio)
                return try AVAudioEngineDevice()
                #else
                throw AudioError("AVAudioEngine is only available on Apple platforms")
                #endif
            default:
                if choice != "default" { EngineLog.warning("Unknown ENGINE_AUDIO '\(choice)'; using the default device", category: .audio) }
                #if canImport(AVFAudio)
                return try AVAudioEngineDevice()
                #else
                return try MiniaudioDevice()
                #endif
            }
        } catch {
            EngineLog.warning("Audio device unavailable (\(error)); using the offline device (silent)", category: .audio)
            return OfflineAudioDevice()
        }
    }
}
