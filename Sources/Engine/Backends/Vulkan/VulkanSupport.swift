#if ENGINE_VULKAN
import CVulkan

struct VulkanError: Error, CustomStringConvertible {
    let call: String
    let result: VkResult
    var description: String { "\(call) failed with VkResult \(result.rawValue)" }
}

@inline(__always)
func vkCheck(_ result: VkResult, _ call: @autoclosure () -> String) throws {
    guard result == VK_SUCCESS else { throw VulkanError(call: call(), result: result) }
}

func vkMakeVersion(_ major: UInt32, _ minor: UInt32, _ patch: UInt32) -> UInt32 {
    (major << 22) | (minor << 12) | patch
}

/// Converts a Vulkan flag-bit enum to the `VkFlags` bitmask type.
@inline(__always)
func vkFlags<T: RawRepresentable>(_ bits: T...) -> VkFlags where T.RawValue: BinaryInteger {
    bits.reduce(0) { $0 | VkFlags($1.rawValue) }
}

/// Runs the Vulkan "call twice" enumeration pattern.
func vkEnumerate<T>(_ call: String, _ body: (UnsafeMutablePointer<UInt32>, UnsafeMutablePointer<T>?) -> VkResult) throws -> [T] {
    var count: UInt32 = 0
    try vkCheck(body(&count, nil), call)
    return try [T](unsafeUninitializedCapacity: Int(count)) { buffer, initialized in
        var filled = count
        let result = body(&filled, buffer.baseAddress)
        initialized = Int(filled)
        if result != VK_INCOMPLETE { try vkCheck(result, call) }
    }
}

func vkEnumerate<T>(_ body: (UnsafeMutablePointer<UInt32>, UnsafeMutablePointer<T>?) -> Void) -> [T] {
    var count: UInt32 = 0
    body(&count, nil)
    return [T](unsafeUninitializedCapacity: Int(count)) { buffer, initialized in
        var filled = count
        body(&filled, buffer.baseAddress)
        initialized = Int(filled)
    }
}

/// Reads a fixed-size C `char[N]` field (imported as a tuple) as a String.
func vkString<T>(_ tuple: T) -> String {
    withUnsafeBytes(of: tuple) { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
}

/// Keeps memory referenced by Vulkan create-info structs alive until the arena is released.
final class Arena {
    private var allocations: [UnsafeMutableRawPointer] = []

    deinit {
        for pointer in allocations { pointer.deallocate() }
    }

    func store<T>(_ value: T) -> UnsafePointer<T> {
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.initialize(to: value)
        allocations.append(UnsafeMutableRawPointer(pointer))
        return UnsafePointer(pointer)
    }

    func array<T>(_ values: [T]) -> UnsafePointer<T>? {
        guard !values.isEmpty else { return nil }
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: values.count)
        pointer.initialize(from: values, count: values.count)
        allocations.append(UnsafeMutableRawPointer(pointer))
        return UnsafePointer(pointer)
    }

    func cString(_ string: String) -> UnsafePointer<CChar> {
        array(Array(string.utf8CString))!
    }

    func cStrings(_ strings: [String]) -> UnsafePointer<UnsafePointer<CChar>?>? {
        array(strings.map { Optional(cString($0)) })
    }
}
#endif
