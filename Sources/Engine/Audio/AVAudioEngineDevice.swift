#if canImport(AVFAudio)
import AVFAudio
import Foundation

/// Output through AVAudioEngine: an `AVAudioSourceNode` at the hardware rate pulls from the
/// render callback into the engine's main mixer. The default device on macOS.
///
/// When the output configuration changes (headphones plugged in, a new default device),
/// AVAudioEngine stops; the device restarts it. The source node keeps its format, and
/// AVAudioEngine converts if the hardware rate changed.
public final class AVAudioEngineDevice: AudioDevice {
    public let sampleRate: Double
    public var name: String { "AVAudioEngine (\(Int(sampleRate)) Hz)" }
    public var isRealtime: Bool { true }

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var configurationObserver: NSObjectProtocol?
    /// Interleaved scratch for the callback, deinterleaved into AVAudioEngine's buffers.
    private let scratch: UnsafeMutablePointer<Float>
    private static let scratchFrames = 4096

    public init() throws {
        let rate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        guard rate > 0 else { throw AudioError("AVAudioEngine: no output device") }
        sampleRate = rate
        scratch = .allocate(capacity: Self.scratchFrames * 2)
    }

    deinit {
        stop()
        scratch.deallocate()
    }

    public func start(render: @escaping AudioRenderCallback) throws {
        guard sourceNode == nil else { return }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            throw AudioError("AVAudioEngine: unsupported format")
        }
        let scratch = self.scratch
        let capacity = Self.scratchFrames
        let node = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            // The real-time thread: no allocation or locks (UnsafeMutableAudioBufferListPointer is a view).
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            let total = Int(frameCount)
            var done = 0
            while done < total {
                let n = min(capacity, total - done)
                render(scratch, n)
                if buffers.count >= 2, let left = buffers[0].mData?.assumingMemoryBound(to: Float.self),
                   let right = buffers[1].mData?.assumingMemoryBound(to: Float.self) {
                    for k in 0..<n {
                        left[done + k] = scratch[2 * k]
                        right[done + k] = scratch[2 * k + 1]
                    }
                } else if let data = buffers.first?.mData?.assumingMemoryBound(to: Float.self) {
                    // Interleaved (not expected with the standard format, but harmless).
                    (data + done * 2).update(from: scratch, count: n * 2)
                }
                done += n
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.prepare()
        do {
            try engine.start()
        } catch {
            engine.detach(node)
            throw AudioError("AVAudioEngine failed to start: \(error.localizedDescription)")
        }
        sourceNode = node
        let engine = engine
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { _ in
            do { try engine.start() } catch { EngineLog.error("AVAudioEngine restart failed: \(error.localizedDescription)", category: .audio) }
        }
    }

    public func stop() {
        if let configurationObserver { NotificationCenter.default.removeObserver(configurationObserver) }
        configurationObserver = nil
        guard let sourceNode else { return }
        engine.stop()  // returns after the render thread has stopped calling the node
        engine.detach(sourceNode)
        self.sourceNode = nil
    }
}
#endif
