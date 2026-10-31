import Foundation

/// Registers WAV, Ogg Vorbis and MP3 files with the asset database. Sounds are not converted:
/// the import only checks that the file decodes (a broken file shows up in the scan report),
/// so audio files get stable ids and sidecars like any asset. Load one with
/// `AssetDatabase.loadSound(_:)` or play it with `AssetDatabase.play(_:on:...)`, which streams
/// or fully decodes according to `Settings.stream`.
public struct AudioImporter: AssetImporter {
    public struct Settings: Codable, Equatable, Sendable {
        /// Stream from disk when played (true) or decode fully into memory (false). nil streams
        /// sounds longer than `AudioImporter.streamThreshold` seconds.
        public var stream: Bool?

        public init(stream: Bool? = nil) {
            self.stream = stream
        }
    }

    /// Sounds at least this long stream by default (seconds).
    public static let streamThreshold = 10.0

    public init() {}

    public var name: String { "audio" }
    public var fileExtensions: [String] { AudioFile.fileExtensions }
    public var version: Int { 1 }
    public var defaultSettings: Settings { Settings() }

    public func importAsset(_ context: inout ImportContext, settings: Settings) throws -> ImportedAsset {
        let info = try Self.info(contentsOf: context.sourceURL)
        if info.fileChannelCount > 2 {
            context.warn("\(context.assetPath): \(info.fileChannelCount) channels; only the first two are played")
        }
        return ImportedAsset()
    }

    /// What a sound file holds, from its header (WAV) or the decoder's setup (Vorbis, MP3).
    public struct FileInfo: Equatable, Sendable {
        public var format: AudioFile.Format
        public var channelCount: Int
        public var fileChannelCount: Int
        public var sampleRate: Double
        public var frameCount: Int?
        public var duration: Double? { frameCount.map { Double($0) / sampleRate } }
    }

    public static func info(contentsOf url: URL) throws -> FileInfo {
        let decoder = try AudioFile.decoder(contentsOf: url)
        let format: AudioFile.Format
        var fileChannels = decoder.channelCount
        switch decoder {
        case let wav as WAVDecoder:
            format = .wav
            fileChannels = wav.fileChannelCount
        case is VorbisDecoder: format = .vorbis
        default: format = .mp3
        }
        return FileInfo(format: format, channelCount: decoder.channelCount, fileChannelCount: fileChannels,
                        sampleRate: decoder.sampleRate, frameCount: decoder.frameCount)
    }
}

extension AssetDatabase {
    /// The source file of an asset, if it exists in the project.
    /// nil for a database mounted from a pack (it has no source files).
    public func sourceURL(of id: AssetID) -> URL? {
        guard pack == nil else { return nil }
        return path(of: id).map { project.url(forAssetPath: $0) }
    }

    /// Fully decodes an audio asset.
    public func loadSound(_ id: AssetID) throws -> SoundBuffer {
        if pack != nil {
            return try SoundBuffer(data: fileData(of: id), name: record(id).map { ($0.fileName as NSString).deletingPathExtension } ?? "")
        }
        guard let url = sourceURL(of: id) else { throw AudioError("No asset \(id)") }
        return try SoundBuffer(contentsOf: url)
    }

    /// Plays an audio asset on `audio`: streamed (looping by default, on the music bus) or
    /// decoded into memory (one-shot, on the sfx bus) per its `AudioImporter.Settings.stream`.
    /// Decoded sounds are not cached; for sounds played often, keep the `loadSound` result.
    @discardableResult
    public func play(_ id: AssetID, on audio: AudioSystem, bus: AudioBus? = nil, volume: Float = 1,
                     loop: Bool? = nil) throws -> Voice {
        let decoder: AudioDecoder
        let name: String
        if pack != nil {
            // A pack keeps the file's bytes; streaming decodes them from memory.
            decoder = try AudioFile.decoder(data: fileData(of: id))
            name = record(id).map { ($0.fileName as NSString).deletingPathExtension } ?? ""
        } else {
            guard let url = sourceURL(of: id) else { throw AudioError("No asset \(id)") }
            decoder = try AudioFile.decoder(contentsOf: url)
            name = url.deletingPathExtension().lastPathComponent
        }
        let settings = settings(of: id, as: AudioImporter.Settings.self) ?? AudioImporter.Settings()
        let duration = decoder.frameCount.map { Double($0) / decoder.sampleRate } ?? .infinity
        if settings.stream ?? (duration >= AudioImporter.streamThreshold) {
            return audio.playStream(decoder, on: bus, volume: volume, loop: loop ?? true, name: name)
        }
        return audio.play(try SoundBuffer(decoder: decoder, name: name), on: bus, volume: volume, loop: loop ?? false)
    }
}
