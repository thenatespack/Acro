public protocol Component {}

public struct Health: Component, Equatable {
    public var points: Int
    public init(points: Int) { self.points = points }
}

public final class Registry {
    public static let shared = Registry()
    public var names: [String] = []
    public var healthID: ObjectIdentifier?
    public var made: Any?
    public init() {}
}

public nonisolated(unsafe) var counter = 0

public typealias Entry = @convention(c) (UnsafeMutableRawPointer) -> Int32
