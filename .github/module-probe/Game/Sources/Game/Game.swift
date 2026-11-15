import Core

@_cdecl("acro_module_v1")
public func registerGame(_ pointer: UnsafeMutableRawPointer) -> Int32 {
    let registry = Unmanaged<Registry>.fromOpaque(pointer).takeUnretainedValue()
    registry.names.append("game")
    registry.healthID = ObjectIdentifier(Health.self)
    registry.made = Health(points: 3)
    counter += 10
    return registry === Registry.shared ? 1 : 0
}
