import Foundation

/// Decodes RIFF WAVE files: PCM 8 (unsigned), 16, 24 and 32-bit integer and 32/64-bit float,
/// including WAVE_FORMAT_EXTENSIBLE. Streams from a file (only the header is read up front) or
/// from memory. Files with more than two channels keep the first two.
public final class WAVDecoder: AudioDecoder {
    public enum SampleFormat: Equatable, Sendable {
        case pcm(bits: Int)
        case float(bits: Int)
    }

    public let channelCount: Int
    public let sampleRate: Double
    public var frameCount: Int? { totalFrames }
    /// Channels in the file (before keeping the first two).
    public let fileChannelCount: Int
    public let sampleFormat: SampleFormat

    private let totalFrames: Int
    private let blockAlign: Int
    private let dataOffset: Int
    private var position = 0
    private let source: Source
    private var bytes: [UInt8] = []

    private enum Source {
        case memory(Data)
        case file(FileHandle)
    }

    public convenience init(contentsOf url: URL) throws {
        let handle = try FileHandle(forReadingFrom: url)
        do {
            try self.init(source: .file(handle))
        } catch {
            try? handle.close()
            throw AudioError("\(url.lastPathComponent): \(error)")
        }
    }

    public convenience init(data: Data) throws {
        try self.init(source: .memory(data))
    }

    private init(source: Source) throws {
        self.source = source
        func read(_ offset: Int, _ count: Int) throws -> [UInt8] {
            switch source {
            case .memory(let data):
                guard offset >= 0, offset + count <= data.count else { return [] }
                let start = data.startIndex + offset
                return [UInt8](data[start..<start + count])
            case .file(let handle):
                try handle.seek(toOffset: UInt64(offset))
                return [UInt8](try handle.read(upToCount: count) ?? Data())
            }
        }
        let size: Int = switch source {
        case .memory(let data): data.count
        case .file(let handle): Int(try handle.seekToEnd())
        }

        let riff = try read(0, 12)
        guard riff.count == 12, riff[0..<4] == [0x52, 0x49, 0x46, 0x46], riff[8..<12] == [0x57, 0x41, 0x56, 0x45] else {
            throw AudioError("not a RIFF WAVE file")
        }
        var offset = 12
        var format: (tag: Int, channels: Int, rate: Int, blockAlign: Int, bits: Int)?
        var data: (offset: Int, size: Int)?
        while offset + 8 <= size, data == nil {
            let header = try read(offset, 8)
            guard header.count == 8 else { break }
            let id = String(decoding: header[0..<4], as: UTF8.self)
            let chunkSize = Int(Self.u32(header, 4))
            let body = offset + 8
            switch id {
            case "fmt ":
                let fmt = try read(body, min(chunkSize, 40))
                guard fmt.count >= 16 else { throw AudioError("truncated fmt chunk") }
                var tag = Int(Self.u16(fmt, 0))
                if tag == 0xFFFE, fmt.count >= 26 {
                    tag = Int(Self.u16(fmt, 24))  // WAVE_FORMAT_EXTENSIBLE: the sub-format GUID starts with the tag
                }
                format = (tag, Int(Self.u16(fmt, 2)), Int(Self.u32(fmt, 4)), Int(Self.u16(fmt, 12)), Int(Self.u16(fmt, 14)))
            case "data":
                guard format != nil else { throw AudioError("data chunk before fmt chunk") }
                // Streaming writers may leave the size as 0 or 0xFFFFFFFF: use what the file has.
                let available = size - body
                data = (body, chunkSize == 0 || chunkSize > available ? available : chunkSize)
            default:
                break
            }
            offset = body + chunkSize + (chunkSize & 1)  // chunks are padded to even sizes
        }
        guard let format else { throw AudioError("missing fmt chunk") }
        guard let data else { throw AudioError("missing data chunk") }
        guard format.channels > 0, format.rate > 0 else { throw AudioError("invalid channel count or sample rate") }
        switch (format.tag, format.bits) {
        case (1, 8), (1, 16), (1, 24), (1, 32): sampleFormat = .pcm(bits: format.bits)
        case (3, 32), (3, 64): sampleFormat = .float(bits: format.bits)
        default: throw AudioError("unsupported WAV encoding (format \(format.tag), \(format.bits) bits)")
        }
        let bytesPerSample = format.bits / 8
        blockAlign = max(format.blockAlign, bytesPerSample * format.channels)
        fileChannelCount = format.channels
        channelCount = min(format.channels, 2)
        sampleRate = Double(format.rate)
        dataOffset = data.offset
        totalFrames = data.size / blockAlign
    }

    deinit {
        if case .file(let handle) = source { try? handle.close() }
    }

    public func rewind() throws { position = 0 }

    public func read(into buffer: UnsafeMutablePointer<Float>, frames: Int) throws -> Int {
        let count = min(frames, totalFrames - position)
        guard count > 0 else { return 0 }
        let byteCount = count * blockAlign
        let start = dataOffset + position * blockAlign
        switch source {
        case .memory(let data):
            data.withUnsafeBytes { raw in
                convert(UnsafeRawBufferPointer(rebasing: raw[start..<start + byteCount]), frames: count, into: buffer)
            }
        case .file(let handle):
            try handle.seek(toOffset: UInt64(start))
            let chunk = try handle.read(upToCount: byteCount) ?? Data()
            guard chunk.count == byteCount else { throw AudioError("WAV file truncated") }
            chunk.withUnsafeBytes { convert($0, frames: count, into: buffer) }
        }
        position += count
        return count
    }

    private func convert(_ raw: UnsafeRawBufferPointer, frames: Int, into out: UnsafeMutablePointer<Float>) {
        let keep = channelCount
        for frame in 0..<frames {
            let base = frame * blockAlign
            for channel in 0..<keep {
                let at = base + channel * (blockAlignPerChannel)
                out[frame * keep + channel] = sample(raw, at)
            }
        }
    }

    private var blockAlignPerChannel: Int {
        switch sampleFormat {
        case .pcm(let bits), .float(let bits): bits / 8
        }
    }

    @inline(__always) private func sample(_ raw: UnsafeRawBufferPointer, _ at: Int) -> Float {
        switch sampleFormat {
        case .pcm(8):
            return (Float(raw[at]) - 128) / 128
        case .pcm(16):
            return Float(Int16(bitPattern: UInt16(raw[at]) | UInt16(raw[at + 1]) << 8)) / 32768
        case .pcm(24):
            let value = Int32(bitPattern: UInt32(raw[at]) << 8 | UInt32(raw[at + 1]) << 16 | UInt32(raw[at + 2]) << 24) >> 8
            return Float(value) / 8_388_608
        case .pcm:
            return Float(Double(Int32(bitPattern: raw.loadUnaligned(fromByteOffset: at, as: UInt32.self).littleEndian)) / 2_147_483_648)
        case .float(32):
            return Float(bitPattern: raw.loadUnaligned(fromByteOffset: at, as: UInt32.self).littleEndian)
        case .float:
            return Float(Double(bitPattern: raw.loadUnaligned(fromByteOffset: at, as: UInt64.self).littleEndian))
        }
    }

    private static func u16(_ b: [UInt8], _ i: Int) -> UInt16 { UInt16(b[i]) | UInt16(b[i + 1]) << 8 }
    private static func u32(_ b: [UInt8], _ i: Int) -> UInt32 {
        UInt32(b[i]) | UInt32(b[i + 1]) << 8 | UInt32(b[i + 2]) << 16 | UInt32(b[i + 3]) << 24
    }
}

/// Writes RIFF WAVE files (for generated sounds, offline renders and tests).
public enum WAVWriter {
    public enum Encoding: Sendable {
        case pcm8, pcm16, pcm24, pcm32, float32, float64
    }

    /// `samples` is interleaved with `channelCount` channels; values outside [-1, 1] are clamped
    /// for integer encodings.
    public static func encode(_ samples: [Float], channelCount: Int, sampleRate: Int, encoding: Encoding = .pcm16) -> Data {
        let (tag, bits): (UInt16, Int) = switch encoding {
        case .pcm8: (1, 8)
        case .pcm16: (1, 16)
        case .pcm24: (1, 24)
        case .pcm32: (1, 32)
        case .float32: (3, 32)
        case .float64: (3, 64)
        }
        let bytesPerSample = bits / 8
        let dataSize = samples.count * bytesPerSample
        var out = [UInt8]()
        out.reserveCapacity(44 + dataSize)
        func u16(_ v: UInt16) { out += [UInt8(v & 0xFF), UInt8(v >> 8)] }
        func u32(_ v: UInt32) { out += [UInt8(v & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v >> 16 & 0xFF), UInt8(v >> 24)] }
        out += Array("RIFF".utf8)
        u32(UInt32(36 + dataSize + (dataSize & 1)))
        out += Array("WAVEfmt ".utf8)
        u32(16)
        u16(tag)
        u16(UInt16(channelCount))
        u32(UInt32(sampleRate))
        u32(UInt32(sampleRate * channelCount * bytesPerSample))
        u16(UInt16(channelCount * bytesPerSample))
        u16(UInt16(bits))
        out += Array("data".utf8)
        u32(UInt32(dataSize))
        // Integers use the decoder's scale (full scale = 2^(bits-1)), so 1.0 clamps to the
        // largest positive code and everything else round-trips within half a step.
        func quantize(_ sample: Float, bits: Int) -> Int64 {
            let scale = Double(Int64(1) << (bits - 1))
            let value = (Double(sample) * scale).rounded()
            return value.isNaN ? 0 : Int64(min(max(value, -scale), scale - 1))
        }
        for sample in samples {
            switch encoding {
            case .pcm8:
                out.append(UInt8(quantize(sample, bits: 8) + 128))
            case .pcm16:
                u16(UInt16(truncatingIfNeeded: quantize(sample, bits: 16)))
            case .pcm24:
                let v = UInt32(truncatingIfNeeded: quantize(sample, bits: 24))
                out += [UInt8(v & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v >> 16 & 0xFF)]
            case .pcm32:
                u32(UInt32(truncatingIfNeeded: quantize(sample, bits: 32)))
            case .float32:
                u32(sample.bitPattern)
            case .float64:
                let v = Double(sample).bitPattern
                u32(UInt32(v & 0xFFFF_FFFF))
                u32(UInt32(v >> 32))
            }
        }
        if dataSize & 1 == 1 { out.append(0) }
        return Data(out)
    }
}
