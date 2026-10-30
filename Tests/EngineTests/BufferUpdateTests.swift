import Testing
@testable import Engine

@Test func bufferUpdateAcceptsRangesInsideTheBuffer() throws {
    try validateBufferUpdate(bufferLength: 64, offset: 0, byteCount: 64)
    try validateBufferUpdate(bufferLength: 64, offset: 16, byteCount: 48)
    try validateBufferUpdate(bufferLength: 64, offset: 64, byteCount: 0)
}

@Test func bufferUpdateRejectsRangesOutsideTheBuffer() {
    #expect(throws: GraphicsError.self) { try validateBufferUpdate(bufferLength: 64, offset: 0, byteCount: 65) }
    #expect(throws: GraphicsError.self) { try validateBufferUpdate(bufferLength: 64, offset: 60, byteCount: 8) }
    #expect(throws: GraphicsError.self) { try validateBufferUpdate(bufferLength: 64, offset: 65, byteCount: 0) }
    #expect(throws: GraphicsError.self) { try validateBufferUpdate(bufferLength: 64, offset: -1, byteCount: 4) }
    #expect(throws: GraphicsError.self) { try validateBufferUpdate(bufferLength: 64, offset: Int.max, byteCount: 2) }
}
