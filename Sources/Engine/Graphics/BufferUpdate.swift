/// Checks the arguments of `RenderDevice.updateBuffer`: the range `offset ..< offset + byteCount`
/// must lie inside a buffer of `bufferLength` bytes.
func validateBufferUpdate(bufferLength: Int, offset: Int, byteCount: Int) throws {
    guard offset >= 0, byteCount >= 0, offset <= bufferLength, byteCount <= bufferLength - offset else {
        throw GraphicsError(
            "Buffer update of \(byteCount) bytes at offset \(offset) is outside the buffer's \(bufferLength) bytes")
    }
}
