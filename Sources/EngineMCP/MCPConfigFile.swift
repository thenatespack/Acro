import Foundation

/// `mcp.json`: how to reach a running HTTP transport. Written owner-only next to the project
/// (or the host's prefs), read by people and scripts to configure a client:
///
/// ```json
/// {
///   "url": "http://127.0.0.1:7333/mcp",
///   "token": "…",
///   "pid": 1234,
///   "mcpServers": { "swift-engine": { "type": "http", "url": "…", "headers": { "Authorization": "Bearer …" } } }
/// }
/// ```
///
/// `mcpServers` is in the shape of a client's `.mcp.json`, ready to paste.
public struct MCPConfigFile: Equatable, Sendable {
    public var url: String
    public var token: String
    public var pid: Int32
    /// The name to suggest for the server in a client's config.
    public var serverName: String

    public init(url: String, token: String, pid: Int32 = ProcessInfo.processInfo.processIdentifier, serverName: String) {
        self.url = url
        self.token = token
        self.pid = pid
        self.serverName = serverName
    }

    public var json: JSON {
        [
            "url": .string(url),
            "token": .string(token),
            "pid": .int(Int64(pid)),
            "mcpServers": [
                serverName: ["type": "http", "url": .string(url), "headers": ["Authorization": .string("Bearer \(token)")]],
            ],
        ]
    }

    /// Writes the file, readable by its owner only.
    public func write(to url: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = Data(json.prettyText.utf8)
        if !fm.fileExists(atPath: url.path) {
            fm.createFile(atPath: url.path, contents: nil, attributes: [.posixPermissions: 0o600])
        }
        try data.write(to: url)
        try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    /// The token in an existing file, so a restarted host keeps it and configured clients
    /// still work. Nil if there is no file or no plausible token in it.
    public static func existingToken(at url: URL) -> String? {
        guard let data = try? Data(contentsOf: url), let token = try? JSON(data: data)["token"]?.stringValue,
              token.utf8.count >= 32, token.allSatisfy(\.isHexDigit) else { return nil }
        return token
    }
}
