import Engine
import Foundation

// The inspector of a sound asset (an audio file: WAV, Ogg Vorbis, MP3; or a `.sfx`):
//
//   ┌─────────────────────────────────────────────┐
//   │▁▃▇█▆▃▂▁▂▅▇▆▃▁   (one lane per channel)  │    ← the waveform; the playhead runs over it,
//   │▁▂▆█▇▄▂▁▂▄▆▅▂▁         │                 │      a click plays from there
//   └─────────────────────────────────────────────┘
//   0:01.250                               0:04.800
//   [▶ Play]  [☐ Loop]
//   Format        Ogg Vorbis
//   Duration      0:04.800
//   Sample rate   44,100 Hz
//   Channels      Stereo
//   File size     78 KB (130 kbps)
//   Peak          -0.4 dBFS
//   Loudness      -16.2 dBFS RMS
//
// The sound is read in the background (`AudioAnalysisCache`) and read again when its asset
// changes (a reimport, a `.sfx` edited in the Sound Builder). Selecting a sound doesn't play
// it; Play, or a click on the waveform, does. `audio.info` and `audio.preview` do the same for
// agents.

/// What the inspector shows about a sound: its format, length and levels, and a waveform summary.
public struct AudioAnalysis: Sendable, Equatable, Codable {
    /// "WAV", "Ogg Vorbis", "MP3" or "Synthesized (.sfx)".
    public var format: String
    public var channelCount: Int
    public var sampleRate: Double
    public var frameCount: Int
    /// The file's size in bytes.
    public var fileSize: Int?
    /// The loudest sample's magnitude (0…1; 1 is full scale).
    public var peak: Float
    /// The root mean square of every sample: how loud it is on average.
    public var rms: Float
    /// Per channel, the lowest and highest sample of each of the summary's equal stretches.
    public var minimums: [[Float]]
    public var maximums: [[Float]]

    public var duration: Double { sampleRate > 0 ? Double(frameCount) / sampleRate : 0 }
    /// Average bits per second of a compressed file (Vorbis, MP3).
    public var bitrate: Double? {
        guard let fileSize, duration > 0, format != "WAV", !format.hasPrefix("Synth") else { return nil }
        return Double(fileSize) * 8 / duration
    }

    /// Decibels relative to full scale of a level (−∞ for silence, as -inf).
    public static func decibels(_ level: Float) -> Double { level > 0 ? 20 * log10(Double(level)) : -.infinity }

    /// Reads `source` through: levels and a `buckets`-stretch summary per channel.
    static func analyze(_ source: SoundPreview.Source, buckets: Int = 1024) throws -> AudioAnalysis {
        let decoder: AudioDecoder
        let format: String
        var fileSize: Int?
        switch source {
        case .build(let build):
            let sound = build.soundBuffer()
            decoder = BufferReader(sound)
            format = "Synthesized (.sfx)"
        case .file(let url):
            decoder = try AudioFile.decoder(contentsOf: url)
            let header = (try? FileHandle(forReadingFrom: url)).flatMap { handle in
                defer { try? handle.close() }
                return try? handle.read(upToCount: 12)
            } ?? Data()
            format = switch AudioFile.format(of: header) ?? AudioFile.format(forExtension: url.pathExtension) {
            case .wav?: "WAV"
            case .vorbis?: "Ogg Vorbis"
            case .mp3?: "MP3"
            case nil: url.pathExtension.uppercased()
            }
            fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? nil
        }
        let channels = max(decoder.channelCount, 1)
        // Fine blocks first (the length may not be known up front), then `buckets` from them.
        let block = 256
        var fineMin = [[Float]](repeating: [], count: channels), fineMax = fineMin
        var blockMin = [Float](repeating: .infinity, count: channels), blockMax = [Float](repeating: -.infinity, count: channels)
        var inBlock = 0, frames = 0
        var peak: Float = 0, squares: Double = 0
        let chunk = 4096
        var buffer = [Float](repeating: 0, count: chunk * channels)
        while true {
            let read = try buffer.withUnsafeMutableBufferPointer { try decoder.read(into: $0.baseAddress!, frames: chunk) }
            if read == 0 { break }
            for frame in 0..<read {
                for channel in 0..<channels {
                    let sample = buffer[frame * channels + channel]
                    blockMin[channel] = min(blockMin[channel], sample)
                    blockMax[channel] = max(blockMax[channel], sample)
                    peak = max(peak, abs(sample))
                    squares += Double(sample * sample)
                }
                inBlock += 1
                if inBlock == block {
                    for channel in 0..<channels {
                        fineMin[channel].append(blockMin[channel])
                        fineMax[channel].append(blockMax[channel])
                    }
                    blockMin = [Float](repeating: .infinity, count: channels)
                    blockMax = [Float](repeating: -.infinity, count: channels)
                    inBlock = 0
                }
            }
            frames += read
        }
        if inBlock > 0 {
            for channel in 0..<channels {
                fineMin[channel].append(blockMin[channel])
                fineMax[channel].append(blockMax[channel])
            }
        }
        let fine = fineMin.first?.count ?? 0
        let count = min(buckets, fine)
        var minimums = [[Float]](repeating: [], count: channels), maximums = minimums
        for channel in 0..<channels {
            for bucket in 0..<count {
                let range = (bucket * fine / count)..<max((bucket + 1) * fine / count, bucket * fine / count + 1)
                minimums[channel].append(fineMin[channel][range].min() ?? 0)
                maximums[channel].append(fineMax[channel][range].max() ?? 0)
            }
        }
        let samples = Double(frames * channels)
        return AudioAnalysis(format: format, channelCount: channels, sampleRate: decoder.sampleRate, frameCount: frames,
                             fileSize: fileSize, peak: peak, rms: samples > 0 ? Float((squares / samples).squareRoot()) : 0,
                             minimums: minimums, maximums: maximums)
    }
}

/// Reads a `SoundBuffer` as a decoder (a `.sfx`, rendered).
private final class BufferReader: AudioDecoder {
    let sound: SoundBuffer
    private var position = 0
    init(_ sound: SoundBuffer) { self.sound = sound }
    var channelCount: Int { sound.channelCount }
    var sampleRate: Double { sound.sampleRate }
    var frameCount: Int? { sound.frameCount }
    func read(into buffer: UnsafeMutablePointer<Float>, frames: Int) throws -> Int {
        let count = min(frames, sound.frameCount - position)
        guard count > 0 else { return 0 }
        let samples = sound.samples
        for i in 0..<count * sound.channelCount { buffer[i] = samples[position * sound.channelCount + i] }
        position += count
        return count
    }
    func rewind() throws { position = 0 }
}

/// The sounds read so far, by asset, for the revision they were read at. Reading happens off
/// the main thread; `state` starts it and reports it.
@MainActor
final class AudioAnalysisCache {
    static let shared = AudioAnalysisCache()

    enum State: Equatable {
        case reading
        case ready(AudioAnalysis)
        case failed(String)
    }

    private var entries: [AssetID: (revision: Int, state: State)] = [:]
    /// Readings finished in the background, collected on the main thread by `state(of:)` (so
    /// it works however the host runs its loop).
    private let finished = Finished()

    private final class Finished: @unchecked Sendable {
        private let lock = NSLock()
        private var results: [(AssetID, Int, State)] = []
        func post(_ id: AssetID, _ revision: Int, _ state: State) { lock.withLock { results.append((id, revision, state)) } }
        func take() -> [(AssetID, Int, State)] { lock.withLock { defer { results = [] }; return results } }
    }

    /// Where reading `id` is (starting it, or again after a reimport); nil when it isn't a sound.
    func state(of id: AssetID, in session: EditorSession) -> State? {
        guard let assets = session.assets, let source = SoundPreview.source(of: id, in: assets) else { return nil }
        for (done, doneRevision, state) in finished.take() where entries[done]?.revision == doneRevision {
            // (A newer revision started its own reading.)
            entries[done] = (doneRevision, state)
        }
        let revision = assets.revision(of: id)
        if let entry = entries[id], entry.revision == revision { return entry.state }
        if entries.count > 48 { entries.removeAll() }
        entries[id] = (revision, .reading)
        let finished = finished
        Task.detached(priority: .utility) {
            let state: State
            do { state = .ready(try AudioAnalysis.analyze(source)) } catch { state = .failed("\(error)") }
            finished.post(id, revision, state)
        }
        return .reading
    }

    /// Reads `id` now, on this thread, and keeps it (`audio.info`).
    func analysis(of id: AssetID, in session: EditorSession) throws -> AudioAnalysis? {
        guard let assets = session.assets, let source = SoundPreview.source(of: id, in: assets) else { return nil }
        let revision = assets.revision(of: id)
        if case .ready(let analysis)? = entries[id].flatMap({ $0.revision == revision ? $0.state : nil }) { return analysis }
        let analysis = try AudioAnalysis.analyze(source)
        entries[id] = (revision, .ready(analysis))
        return analysis
    }
}

/// "1:04.250", "0:03.500".
func formatAudioTime(_ seconds: Double) -> String {
    let total = max(seconds, 0)
    let minutes = Int(total / 60)
    let rest = total - Double(minutes * 60)
    return String(format: "%d:%06.3f", minutes, rest)
}

/// A sound's waveform: a lane per channel, the part played brighter, the playhead as a line, the
/// time under the pointer as a tooltip. A click (or a drag) calls `onSeek` with the time there.
final class WaveformView: Widget {
    var analysis: AudioAnalysis? { didSet { if analysis != oldValue { setNeedsLayout() } } }
    /// Seconds into the sound the preview is at; nil when it isn't playing.
    var playhead: Double? { didSet { if playhead != oldValue { setNeedsDisplay() } } }
    var onSeek: ((Double) -> Void)?

    override init(name: String = "waveform") {
        super.init(name: name)
    }

    override var acceptsFocus: Bool { false }
    override var accessibilityRole: UIAccessibilityRole { .slider }
    override var accessibilityText: String? { "Waveform" }
    override var accessibilityValue: String? { playhead.map(formatAudioTime) }

    override func measureContent(width: Float?) -> Vec2 {
        Vec2(120, (analysis?.channelCount ?? 1) > 1 ? 112 : 72)
    }

    private func time(at x: Float) -> Double {
        guard let analysis, frame.width > 0 else { return 0 }
        return Double(min(max((x - frame.x) / frame.width, 0), 1)) * analysis.duration
    }

    override func tooltip(at point: Vec2) -> String? {
        analysis.map { _ in "\(formatAudioTime(time(at: point.x))) — click to play from here" }
    }

    override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            onSeek?(time(at: e.position.x))
            return true
        case .pointerUp, .pointerDrag:
            return true
        default:
            return false
        }
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        let radii = UICornerRadii(theme.smallCornerRadius)
        list.fillRect(frame, color: theme.fieldBackground, radii: radii)
        list.strokeRect(frame, color: theme.controlBorder, width: theme.borderWidth, radii: radii)
        guard let analysis, analysis.duration > 0, let first = analysis.maximums.first, !first.isEmpty else { return }
        let lanes = analysis.channelCount
        let laneHeight = (frame.height - 8) / Float(lanes)
        let columns = max(Int(frame.width.rounded(.down)) - 4, 1)
        let played = playhead.map { Float($0 / analysis.duration) } ?? -1
        let bright = theme.accent, dim = theme.accent.withAlpha(0.55)
        for lane in 0..<lanes {
            let top = frame.y + 4 + Float(lane) * laneHeight
            let mid = top + laneHeight / 2
            list.fillRect(UIRect(x: frame.x + 2, y: mid, width: frame.width - 4, height: 1 / scale), color: theme.controlBorder)
            let mins = analysis.minimums[lane], maxs = analysis.maximums[lane]
            let count = maxs.count
            for column in 0..<columns {
                let a = column * count / columns, b = max((column + 1) * count / columns, a + 1)
                guard a < count else { break }
                let high = maxs[a..<min(b, count)].max() ?? 0, low = mins[a..<min(b, count)].min() ?? 0
                let y0 = mid - max(high, 0) * laneHeight / 2, y1 = mid - min(low, 0) * laneHeight / 2
                let x = frame.x + 2 + Float(column)
                let color = Float(column) / Float(columns) <= played ? bright : dim
                list.fillRect(UIRect(x: x, y: y0, width: 1, height: max(y1 - y0, 1 / scale)), color: color)
            }
            if lane > 0 {
                list.fillRect(UIRect(x: frame.x + 2, y: top, width: frame.width - 4, height: 1 / scale), color: theme.controlBorder)
            }
        }
        if played >= 0 {
            let x = frame.x + 2 + min(max(played, 0), 1) * (frame.width - 4)
            list.fillRect(UIRect(x: x - 0.5, y: frame.y + 2, width: 1.5, height: frame.height - 4), color: theme.textColor)
        }
    }
}

/// The inspector section of a sound asset (see the notes at the top).
@MainActor
final class AudioInspectorSection {
    let session: EditorSession
    let asset: AssetID
    let view = VStack(spacing: 6, name: "audioInspector")
    let waveform = WaveformView()
    let playButton: Button
    let loopToggle: Checkbox
    private let status = Label("Reading the sound…", role: .caption, name: "audioStatus")
    private let positionLabel = Label("", role: .caption, name: "audioPosition")
    private let durationLabel = Label("", role: .caption, name: "audioDuration")
    private let info = VStack(spacing: 2, name: "audioInfo")
    private(set) var analysis: AudioAnalysis?

    init(session: EditorSession, asset: AssetID) {
        self.session = session
        self.asset = asset
        playButton = Button("Play", role: .primary, name: "assetPlaySound")
        loopToggle = Checkbox("Loop", name: "audioLoop")
        playButton.icon = EditorIcons.named("play")
        playButton.tooltip = "Hear the sound (selecting it in the Assets panel doesn't play it)"
        loopToggle.tooltip = "Play it over and over"
        playButton.command = AudioPreviewCommand.id.rawValue
        loopToggle.command = AudioPreviewCommand.id.rawValue
        waveform.command = AudioPreviewCommand.id.rawValue
        waveform.style.grow = 0
        positionLabel.style.grow = 1
        let times = HStack(spacing: 6, name: "audioTimes", [positionLabel, durationLabel])
        let controls = HStack(spacing: 10, alignment: .center, name: "audioControls", [playButton, loopToggle, Spacer()])
        view.addChildren([waveform, times, controls, status, info])
        playButton.action = { [unowned self] in togglePlay() }
        loopToggle.onChange = { [unowned self] _ in
            // Looping applies to the next play: restart a playing preview where it is.
            if session.soundPreviewAsset == asset { play(from: session.soundPreviewPlayhead ?? 0) }
        }
        waveform.onSeek = { [unowned self] time in play(from: time) }
        refresh()
    }

    func togglePlay() {
        if session.soundPreviewAsset == asset {
            session.stopSoundPreview()
        } else {
            play(from: 0)
        }
        refresh()
    }

    func play(from time: Double) {
        session.previewSound(asset: asset, from: time, loop: loopToggle.isOn, duration: analysis?.duration)
        refresh()
    }

    /// Picks up the finished reading and follows the preview; call every frame.
    func refresh() {
        let state = AudioAnalysisCache.shared.state(of: asset, in: session)
        switch state {
        case .ready(let analysis)?:
            if analysis != self.analysis { show(analysis) }
            if !status.isHidden { status.isHidden = true }
        case .failed(let message)?:
            status.text = "Couldn't read the sound: \(message)"
            status.isHidden = false
        case .reading?, nil:
            status.isHidden = false
        }
        let playing = session.soundPreviewAsset == asset
        let title = playing ? "Stop" : "Play"
        if playButton.title != title {
            playButton.title = title
            playButton.icon = EditorIcons.named(playing ? "square" : "play")
        }
        let playhead = playing ? session.soundPreviewPlayhead : nil
        waveform.playhead = playhead
        let position = playhead.map(formatAudioTime) ?? ""
        if positionLabel.text != position { positionLabel.text = position }
    }

    private func show(_ analysis: AudioAnalysis) {
        self.analysis = analysis
        waveform.analysis = analysis
        durationLabel.text = formatAudioTime(analysis.duration)
        info.removeAllChildren()
        func row(_ name: String, _ value: String) {
            let label = Label(name, role: .secondary, name: "audioInfoLabel")
            label.style.width = 96
            let text = Label(value, name: "audioInfo.\(name)")
            text.style.grow = 1
            text.style.shrink = 1
            text.style.width = 0
            info.addChild(HStack(spacing: 6, [label, text]))
        }
        row("Format", analysis.format)
        row("Duration", formatAudioTime(analysis.duration))
        row("Sample rate", "\(Int(analysis.sampleRate).formatted()) Hz")
        row("Channels", analysis.channelCount == 1 ? "Mono" : analysis.channelCount == 2 ? "Stereo" : "\(analysis.channelCount)")
        row("Frames", analysis.frameCount.formatted())
        if let size = analysis.fileSize {
            let bytes = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            row("File size", bytes + (analysis.bitrate.map { " (\(Int(($0 / 1000).rounded())) kbps)" } ?? ""))
        }
        func level(_ value: Float) -> String {
            let db = AudioAnalysis.decibels(value)
            return db.isFinite ? String(format: "%.1f dBFS", db) : "Silent"
        }
        row("Peak", level(analysis.peak) + (analysis.peak >= 0.999 ? " (clipping)" : ""))
        row("Loudness", level(analysis.rms) + (analysis.rms > 0 ? " RMS" : ""))
    }
}

// MARK: Commands

public enum AudioInfoCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A sound: an audio file (wav, ogg, mp3) or a .sfx.
        public var asset: AssetReference
        /// How many stretches the waveform summary has (default 64, at most 1024).
        public var buckets: Int?
        public init(asset: AssetReference, buckets: Int? = nil) {
            self.asset = asset
            self.buckets = buckets
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var format: String
        public var duration: Double
        public var sampleRate: Double
        public var channels: Int
        public var frames: Int
        public var fileSize: Int?
        public var bitrate: Double?
        /// Decibels relative to full scale (nil for silence).
        public var peakDB: Double?
        public var rmsDB: Double?
        /// Per stretch of the sound, the loudest magnitude across channels (0…1).
        public var waveform: [Float]
    }

    public static let id: CommandID = "audio.info"
    public static let title = "Sound Info"
    public static let doc = "What the inspector shows about a sound asset (an audio file: WAV, Ogg Vorbis, MP3; or a .sfx): its format, duration, sample rate, channels, frames, file size and bitrate, peak and RMS levels in dBFS, and a waveform summary of `buckets` peak magnitudes (default 64)."
    public static let isReadOnly = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        guard let analysis = try AudioAnalysisCache.shared.analysis(of: arguments.asset.asset, in: session) else {
            throw CommandError.failed("\(title): \(arguments.asset) isn't a sound (an audio file or a .sfx)")
        }
        let buckets = min(max(arguments.buckets ?? 64, 1), 1024)
        let fine = analysis.maximums.first?.count ?? 0
        var waveform: [Float] = []
        if fine > 0 {
            let count = min(buckets, fine)
            for bucket in 0..<count {
                let range = (bucket * fine / count)..<max((bucket + 1) * fine / count, bucket * fine / count + 1)
                var loudest: Float = 0
                for channel in 0..<analysis.channelCount {
                    loudest = max(loudest, analysis.maximums[channel][range].max() ?? 0, -(analysis.minimums[channel][range].min() ?? 0))
                }
                waveform.append((loudest * 1000).rounded() / 1000)
            }
        }
        let peak = AudioAnalysis.decibels(analysis.peak), rms = AudioAnalysis.decibels(analysis.rms)
        return Result(format: analysis.format, duration: analysis.duration, sampleRate: analysis.sampleRate,
                      channels: analysis.channelCount, frames: analysis.frameCount, fileSize: analysis.fileSize,
                      bitrate: analysis.bitrate, peakDB: peak.isFinite ? (peak * 10).rounded() / 10 : nil,
                      rmsDB: rms.isFinite ? (rms * 10).rounded() / 10 : nil, waveform: waveform)
    }
}

public enum AudioPreviewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A sound: an audio file (wav, ogg, mp3) or a .sfx. Omit it with stop: true.
        public var asset: AssetReference?
        /// Seconds into the sound to start at (default 0).
        public var from: Double?
        /// Play it over and over until stopped.
        public var loop: Bool?
        /// Stop the preview instead.
        public var stop: Bool?
        public init(asset: AssetReference? = nil, from: Double? = nil, loop: Bool? = nil, stop: Bool? = nil) {
            self.asset = asset
            self.from = from
            self.loop = loop
            self.stop = stop
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// Whether a preview is playing (false without an audio device, or after stop).
        public var playing: Bool
    }

    public static let id: CommandID = "audio.preview"
    public static let title = "Preview Sound"
    public static let doc = "Plays a sound asset (an audio file or a .sfx) through the editor's audio output, as the inspector's Play and waveform do: from `from` seconds in, once or with `loop`; a new preview replaces the one playing. stop: true stops it. `playing` is false when the editor has no audio device."
    public static let isReadOnly = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        if arguments.stop == true {
            session.stopSoundPreview()
            return Result(playing: false)
        }
        guard let reference = arguments.asset else { throw CommandError.failed("\(title): give asset, or stop: true") }
        guard session.isSoundAsset(reference.asset) else {
            throw CommandError.failed("\(title): \(reference) isn't a sound (an audio file or a .sfx)")
        }
        let duration = (try? AudioAnalysisCache.shared.analysis(of: reference.asset, in: session))?.duration
        let played = session.previewSound(asset: reference.asset, from: arguments.from ?? 0, loop: arguments.loop ?? false,
                                          duration: duration)
        return Result(playing: played)
    }
}
