import CAudio
import Foundation

/// Output through miniaudio (vendored in `CAudio`): WASAPI/DirectSound on Windows, PulseAudio/
/// ALSA/JACK on Linux, Core Audio on macOS. The default device on Linux and Windows; on macOS
/// select it with `ENGINE_AUDIO=miniaudio`.
public final class MiniaudioDevice: AudioDevice {
    public private(set) var sampleRate: Double
    public private(set) var name: String
    public var isRealtime: Bool { true }

    /// Holds the callback for the C trampoline. Kept alive (retained by `self`) while the device exists.
    private final class Box: @unchecked Sendable {
        var render: AudioRenderCallback?
    }

    private let box = Box()
    private var device: OpaquePointer?
    private var running = false

    /// Opens the default playback device. `sampleRate` nil uses the device's native rate.
    public init(sampleRate: Double? = nil) throws {
        var rate: UInt32 = 0
        var nameBytes = [CChar](repeating: 0, count: 256)
        var errorBytes = [CChar](repeating: 0, count: 256)
        let trampoline: caudio_render_fn = { user, output, frames in
            guard let user, let output else { return }
            let box = Unmanaged<Box>.fromOpaque(user).takeUnretainedValue()
            if let render = box.render {
                render(output, Int(frames))
            } else {
                output.update(repeating: 0, count: Int(frames) * 2)
            }
        }
        let opened = caudio_device_open(UInt32(sampleRate ?? 0), trampoline, Unmanaged.passUnretained(box).toOpaque(),
                                        &rate, &nameBytes, nameBytes.count, &errorBytes, errorBytes.count)
        guard let opened else { throw AudioError("miniaudio: \(Self.string(errorBytes))") }
        device = opened
        self.sampleRate = Double(rate)
        name = "\(Self.string(nameBytes)) (miniaudio)"
    }

    deinit {
        caudio_device_close(device)
    }

    /// A NUL-terminated C string buffer as a String.
    private static func string(_ bytes: [CChar]) -> String {
        let end = bytes.firstIndex(of: 0) ?? bytes.endIndex
        return String(decoding: bytes[..<end].map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    public func start(render: @escaping AudioRenderCallback) throws {
        guard let device else { throw AudioError("miniaudio device is closed") }
        // Set before starting; the device thread isn't running yet, so this is the only writer.
        box.render = render
        guard caudio_device_start(device) == 0 else {
            box.render = nil
            throw AudioError("miniaudio: failed to start \(name)")
        }
        running = true
    }

    public func stop() {
        guard let device, running else { return }
        caudio_device_stop(device)  // returns after the last callback
        running = false
        box.render = nil
    }
}
