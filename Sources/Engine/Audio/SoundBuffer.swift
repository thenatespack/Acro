import Foundation

/// A fully decoded sound in memory: interleaved float samples, mono or stereo, at its own
/// sample rate (the mixer converts to the device rate). Immutable and safe to share between
/// threads; play it any number of times at once with `AudioSystem.play`.
///
/// For long music, stream instead (`AudioSystem.playStream`): only a couple of seconds are
/// decoded ahead.
public final class SoundBuffer: @unchecked Sendable {
    /// 1 or 2. Files with more channels keep their first two.
    public let channelCount: Int
    public let sampleRate: Double
    public let frameCount: Int
    /// Optional label for debugging and UI.
    public var name: String
    /// Interleaved samples, allocated once so the audio thread can read them through a pointer.
    let storage: UnsafeMutablePointer<Float>

    public var duration: Double { Double(frameCount) / sampleRate }

    /// A copy of the interleaved samples.
    public var samples: [Float] { Array(UnsafeBufferPointer(start: storage, count: frameCount * channelCount)) }

    /// `samples` is interleaved (`frameCount * channelCount` values) and must have 1 or 2 channels.
    public init(samples: [Float], channelCount: Int, sampleRate: Double, name: String = "") {
        precondition(channelCount == 1 || channelCount == 2, "SoundBuffer supports mono or stereo")
        precondition(sampleRate > 0, "Sample rate must be positive")
        self.channelCount = channelCount
        self.sampleRate = sampleRate
        self.name = name
        frameCount = samples.count / channelCount
        storage = .allocate(capacity: max(frameCount * channelCount, 1))
        storage.initialize(repeating: 0, count: max(frameCount * channelCount, 1))
        samples.withUnsafeBufferPointer {
            if let base = $0.baseAddress { storage.update(from: base, count: frameCount * channelCount) }
        }
    }

    /// A procedurally generated sound: `generator(frame, channel)` returns each sample.
    public convenience init(frameCount: Int, channelCount: Int = 1, sampleRate: Double = 48000, name: String = "",
                            generator: (Int, Int) -> Float) {
        var samples = [Float](repeating: 0, count: frameCount * channelCount)
        for frame in 0..<frameCount {
            for channel in 0..<channelCount { samples[frame * channelCount + channel] = generator(frame, channel) }
        }
        self.init(samples: samples, channelCount: channelCount, sampleRate: sampleRate, name: name)
    }

    /// Decodes everything `decoder` produces.
    public convenience init(decoder: AudioDecoder, name: String = "") throws {
        var samples: [Float] = []
        if let count = decoder.frameCount { samples.reserveCapacity(count * decoder.channelCount) }
        let chunk = 4096
        var buffer = [Float](repeating: 0, count: chunk * decoder.channelCount)
        while true {
            let read = try buffer.withUnsafeMutableBufferPointer { try decoder.read(into: $0.baseAddress!, frames: chunk) }
            if read == 0 { break }
            samples.append(contentsOf: buffer[0..<(read * decoder.channelCount)])
        }
        self.init(samples: samples, channelCount: decoder.channelCount, sampleRate: decoder.sampleRate, name: name)
    }

    /// Loads and fully decodes a WAV, Ogg Vorbis or MP3 file (detected from its contents).
    public convenience init(contentsOf url: URL) throws {
        try self.init(decoder: AudioFile.decoder(contentsOf: url), name: url.deletingPathExtension().lastPathComponent)
    }

    /// Decodes a WAV, Ogg Vorbis or MP3 file already in memory.
    public convenience init(data: Data, name: String = "") throws {
        try self.init(decoder: AudioFile.decoder(data: data), name: name)
    }

    deinit {
        storage.deallocate()
    }
}

/// A source of decoded audio that can be read incrementally: what streamed voices play and
/// what `SoundBuffer` decodes from. Output is interleaved float, 1 or 2 channels.
/// Decoders are used from one thread at a time (the game thread, for streams).
public protocol AudioDecoder: AnyObject {
    /// 1 or 2.
    var channelCount: Int { get }
    var sampleRate: Double { get }
    /// Total frames, if known up front.
    var frameCount: Int? { get }
    /// Decodes up to `frames` frames into `buffer` (room for `frames * channelCount` floats).
    /// Returns the frames written; 0 only at the end.
    func read(into buffer: UnsafeMutablePointer<Float>, frames: Int) throws -> Int
    /// Goes back to the first frame (for looping).
    func rewind() throws
}

/// The audio file formats the engine decodes, and decoder construction.
public enum AudioFile {
    public enum Format: String, Sendable, CaseIterable {
        case wav, vorbis, mp3
    }

    /// File extensions the engine can load (lowercase, no dot).
    public static let fileExtensions = ["wav", "wave", "ogg", "oga", "mp3"]

    /// The format of a file from its first bytes, or nil if unrecognized.
    public static func format(of header: Data) -> Format? {
        let bytes = [UInt8](header.prefix(12))
        func matches(_ s: String, at offset: Int = 0) -> Bool {
            let ascii = Array(s.utf8)
            return bytes.count >= offset + ascii.count && Array(bytes[offset..<offset + ascii.count]) == ascii
        }
        if matches("RIFF") && matches("WAVE", at: 8) { return .wav }
        if matches("OggS") { return .vorbis }
        if matches("ID3") { return .mp3 }
        if bytes.count >= 2 && bytes[0] == 0xFF && bytes[1] & 0xE0 == 0xE0 { return .mp3 }  // MPEG frame sync
        return nil
    }

    /// The format a file extension usually means.
    public static func format(forExtension ext: String) -> Format? {
        switch ext.lowercased() {
        case "wav", "wave": .wav
        case "ogg", "oga": .vorbis
        case "mp3": .mp3
        default: nil
        }
    }

    /// A decoder for a file. WAV streams from disk; Vorbis and MP3 read the (compressed) file
    /// into memory and decode from it incrementally.
    public static func decoder(contentsOf url: URL) throws -> AudioDecoder {
        let handle = try FileHandle(forReadingFrom: url)
        let header = try handle.read(upToCount: 12) ?? Data()
        try? handle.close()
        guard let format = format(of: header) ?? format(forExtension: url.pathExtension) else {
            throw AudioError("\(url.lastPathComponent): not a WAV, Ogg Vorbis or MP3 file")
        }
        switch format {
        case .wav: return try WAVDecoder(contentsOf: url)
        case .vorbis: return try VorbisDecoder(data: Data(contentsOf: url))
        case .mp3: return try MP3Decoder(data: Data(contentsOf: url))
        }
    }

    /// A decoder for a file already in memory.
    public static func decoder(data: Data) throws -> AudioDecoder {
        guard let format = format(of: data) else { throw AudioError("Not a WAV, Ogg Vorbis or MP3 file") }
        switch format {
        case .wav: return try WAVDecoder(data: data)
        case .vorbis: return try VorbisDecoder(data: data)
        case .mp3: return try MP3Decoder(data: data)
        }
    }
}
