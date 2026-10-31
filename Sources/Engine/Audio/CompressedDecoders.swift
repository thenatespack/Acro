import CAudio
import Foundation

/// Decodes Ogg Vorbis with stb_vorbis, incrementally from the compressed file in memory.
/// Files with more than two channels are mixed down to stereo by stb_vorbis.
public final class VorbisDecoder: AudioDecoder {
    public let channelCount: Int
    public let sampleRate: Double
    public let frameCount: Int?
    private let bytes: UnsafeMutableRawBufferPointer
    private let vorbis: OpaquePointer

    public init(data: Data) throws {
        bytes = .allocate(byteCount: max(data.count, 1), alignment: 16)
        bytes.copyBytes(from: data)
        var error: Int32 = 0
        guard let vorbis = stb_vorbis_open_memory(bytes.baseAddress!.assumingMemoryBound(to: UInt8.self), Int32(data.count),
                                                  &error, nil) else {
            bytes.deallocate()
            throw AudioError("Ogg Vorbis: can't open (stb_vorbis error \(error))")
        }
        self.vorbis = vorbis
        let info = stb_vorbis_get_info(vorbis)
        channelCount = min(Int(info.channels), 2)
        sampleRate = Double(info.sample_rate)
        let length = Int(stb_vorbis_stream_length_in_samples(vorbis))
        frameCount = length > 0 ? length : nil
    }

    deinit {
        stb_vorbis_close(vorbis)
        bytes.deallocate()
    }

    public func read(into buffer: UnsafeMutablePointer<Float>, frames: Int) throws -> Int {
        var done = 0
        while done < frames {
            let n = stb_vorbis_get_samples_float_interleaved(vorbis, Int32(channelCount), buffer + done * channelCount,
                                                             Int32((frames - done) * channelCount))
            if n <= 0 { break }
            done += Int(n)
        }
        return done
    }

    public func rewind() throws {
        guard stb_vorbis_seek_start(vorbis) != 0 else { throw AudioError("Ogg Vorbis: seek failed") }
    }
}

/// Decodes MP3 with dr_mp3, incrementally from the compressed file in memory.
public final class MP3Decoder: AudioDecoder {
    public let channelCount: Int
    public let sampleRate: Double
    public let frameCount: Int?
    private let bytes: UnsafeMutableRawBufferPointer
    private let mp3: UnsafeMutablePointer<drmp3>

    public init(data: Data) throws {
        bytes = .allocate(byteCount: max(data.count, 1), alignment: 16)
        bytes.copyBytes(from: data)
        mp3 = .allocate(capacity: 1)
        guard drmp3_init_memory(mp3, bytes.baseAddress, data.count, nil) != 0 else {
            mp3.deallocate()
            bytes.deallocate()
            throw AudioError("MP3: can't open")
        }
        channelCount = Int(mp3.pointee.channels)
        sampleRate = Double(mp3.pointee.sampleRate)
        guard channelCount == 1 || channelCount == 2, sampleRate > 0 else {
            drmp3_uninit(mp3)
            mp3.deallocate()
            bytes.deallocate()
            throw AudioError("MP3: unsupported channel layout")
        }
        // Counting scans the frame headers, then seeks back to the start.
        let count = Int(drmp3_get_pcm_frame_count(mp3))
        frameCount = count > 0 ? count : nil
    }

    deinit {
        drmp3_uninit(mp3)
        mp3.deallocate()
        bytes.deallocate()
    }

    public func read(into buffer: UnsafeMutablePointer<Float>, frames: Int) throws -> Int {
        Int(drmp3_read_pcm_frames_f32(mp3, drmp3_uint64(frames), buffer))
    }

    public func rewind() throws {
        guard drmp3_seek_to_pcm_frame(mp3, 0) != 0 else { throw AudioError("MP3: seek failed") }
    }
}
