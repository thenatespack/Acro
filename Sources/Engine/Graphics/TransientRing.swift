/// Linear allocator for data that only lives for one frame. Each frame-in-flight
/// slot owns one ring; it is reset once the GPU has finished with that slot.
/// Grows by adding chunks, which are kept and reused for later frames.
@MainActor
final class TransientRing<Chunk> {
    struct Allocation {
        let chunk: Chunk
        let offset: Int
    }

    private var chunks: [(chunk: Chunk, base: UnsafeMutableRawPointer, size: Int)] = []
    private var current = 0
    private var offset = 0
    private let minimumChunkSize: Int
    private let makeChunk: (Int) throws -> (Chunk, UnsafeMutableRawPointer)

    init(minimumChunkSize: Int = 256 * 1024, makeChunk: @escaping (Int) throws -> (Chunk, UnsafeMutableRawPointer)) {
        self.minimumChunkSize = minimumChunkSize
        self.makeChunk = makeChunk
    }

    func reset() {
        current = 0
        offset = 0
    }

    /// Copies `bytes` into the ring and returns where they landed.
    /// `reserve` keeps at least that many bytes addressable after the offset (for
    /// fixed-range bindings such as Vulkan dynamic uniform buffers).
    func upload(_ bytes: UnsafeRawBufferPointer, alignment: Int = 16, reserve: Int = 0) throws -> Allocation {
        let size = max(bytes.count, reserve, 1)
        while current < chunks.count {
            let aligned = (offset + alignment - 1) & ~(alignment - 1)
            if aligned + size <= chunks[current].size {
                offset = aligned + size
                return copy(bytes, chunk: current, at: aligned)
            }
            current += 1
            offset = 0
        }
        let (chunk, base) = try makeChunk(max(size, minimumChunkSize))
        chunks.append((chunk, base, max(size, minimumChunkSize)))
        current = chunks.count - 1
        offset = size
        return copy(bytes, chunk: current, at: 0)
    }

    private func copy(_ bytes: UnsafeRawBufferPointer, chunk index: Int, at offset: Int) -> Allocation {
        if let source = bytes.baseAddress, bytes.count > 0 {
            (chunks[index].base + offset).copyMemory(from: source, byteCount: bytes.count)
        }
        return Allocation(chunk: chunks[index].chunk, offset: offset)
    }
}

import Foundation

/// A value written from GPU completion handlers and read on the main thread.
final class LockedValue<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: T

    init(_ value: T) { self.value = value }

    func get() -> T { lock.withLock { value } }
    func set(_ newValue: T) { lock.withLock { value = newValue } }
}
