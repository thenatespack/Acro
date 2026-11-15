import Core
import WinSDK

let path = CommandLine.arguments[1]
guard let handle = path.withCString(encodedAs: UTF16.self, { LoadLibraryW($0) }) else {
    print("RESULT LoadLibraryW failed: \(GetLastError())")
    exit(1)
}
guard let symbol = GetProcAddress(handle, "acro_module_v1") else {
    print("RESULT GetProcAddress failed: \(GetLastError())")
    exit(1)
}
let entry = unsafeBitCast(symbol, to: Entry.self)
let registry = Registry.shared
let sameSingleton = entry(Unmanaged.passUnretained(registry).toOpaque())
print("RESULT sameSingleton:", sameSingleton == 1,
      "names:", registry.names,
      "counterShared:", counter == 10,
      "sameHealthType:", registry.healthID == ObjectIdentifier(Health.self),
      "castsToHealth:", registry.made as? Health == Health(points: 3),
      "castsToComponent:", registry.made is any Component)
