import Foundation

// File operations on a project's `Assets/` folder for tools such as the editor's asset browser.
//
// Each one changes the filesystem the way a user would in a file manager, keeping every file's
// `.meta` sidecar next to it, and then calls `refresh()`, so the database sees what a scan
// would: a moved or renamed file keeps its id (its sidecar moved with it), a deleted one is
// removed, a new one is imported. Paths are relative to `Assets/` with "/" separators; ""
// is `Assets/` itself.

/// Why a file operation on `Assets/` was refused.
public enum AssetFileError: Error, Equatable, CustomStringConvertible {
    /// Nothing at that path.
    case notFound(String)
    /// The destination is taken.
    case exists(String)
    /// The path leaves `Assets/`, is `Assets/` itself, or names a sidecar.
    case invalidPath(String)
    /// A folder can't move into itself or its own subfolders.
    case intoItself(String)

    public var description: String {
        switch self {
        case .notFound(let path): "Nothing at Assets/\(path)"
        case .exists(let path): "Assets/\(path) already exists"
        case .invalidPath(let path): "'\(path)' isn't a valid path inside Assets/"
        case .intoItself(let path): "Can't move \(path) into itself"
        }
    }
}

extension AssetDatabase {
    // MARK: Listing

    /// Every folder under `Assets/` (relative paths, sorted), including empty ones. Hidden
    /// folders are skipped.
    public func folders() -> [String] {
        let root = project.assetsURL.standardizedFileURL.resolvingSymlinksInPath()
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey],
                                                              options: [.skipsHiddenFiles]) else { return [] }
        var result: [String] = []
        for case let url as URL in enumerator {
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true,
                  let path = project.assetPath(for: url) else { continue }
            result.append(path)
        }
        return result.sorted()
    }

    /// Whether `path` is a folder under `Assets/` ("" is `Assets/` itself).
    public func isFolder(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: project.url(forAssetPath: path).path, isDirectory: &isDirectory)
            && isDirectory.boolValue
    }

    /// `path` if nothing is there, else `path` with " 2", " 3"… before its extension
    /// ("New Material 2.material").
    public func uniquePath(_ path: String) -> String {
        let fm = FileManager.default
        guard fm.fileExists(atPath: project.url(forAssetPath: path).path) else { return path }
        let ns = path as NSString
        let ext = ns.pathExtension
        let stem = ext.isEmpty ? path : ns.deletingPathExtension
        var n = 2
        while true {
            let candidate = "\(stem) \(n)" + (ext.isEmpty ? "" : ".\(ext)")
            if !fm.fileExists(atPath: project.url(forAssetPath: candidate).path) { return candidate }
            n += 1
        }
    }

    // MARK: Changing files

    /// Creates the folder `path` (and missing parents). Throws if something is already there.
    @discardableResult
    public func createFolder(_ path: String) throws -> AssetScanReport {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return refresh()
    }

    /// Renames or moves the file or folder at `path` to `newPath` (missing parent folders are
    /// created). A file's sidecar moves with it, and a folder's sidecars are inside it, so every
    /// asset keeps its id. Throws if `newPath` is taken.
    @discardableResult
    public func move(_ path: String, to newPath: String) throws -> AssetScanReport {
        let path = try Self.validated(path), newPath = try Self.validated(newPath)
        guard path != newPath else { return AssetScanReport() }
        let fm = FileManager.default
        let source = project.url(forAssetPath: path), destination = project.url(forAssetPath: newPath)
        guard fm.fileExists(atPath: source.path) else { throw AssetFileError.notFound(path) }
        // A case-only rename on a case-insensitive volume is the same file.
        let sameFile = path.lowercased() == newPath.lowercased()
        if fm.fileExists(atPath: destination.path) && !sameFile { throw AssetFileError.exists(newPath) }
        if newPath.hasPrefix(path + "/") { throw AssetFileError.intoItself(path) }
        try fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        let sidecar = AssetSidecar.url(for: source)
        if sameFile {
            // Through a temporary name, so the volume sees a rename.
            let temporary = source.deletingLastPathComponent().appendingPathComponent(".rename-\(UUID().uuidString)")
            try fm.moveItem(at: source, to: temporary)
            try fm.moveItem(at: temporary, to: destination)
        } else {
            try fm.moveItem(at: source, to: destination)
        }
        if !isFolder(newPath), fm.fileExists(atPath: sidecar.path) {
            try fm.moveItem(at: sidecar, to: AssetSidecar.url(for: destination))
        }
        return refresh()
    }

    /// Deletes the file at `path` with its sidecar, or the folder with everything in it.
    @discardableResult
    public func delete(_ path: String) throws -> AssetScanReport {
        let path = try Self.validated(path)
        let fm = FileManager.default
        let url = project.url(forAssetPath: path)
        guard fm.fileExists(atPath: url.path) else { throw AssetFileError.notFound(path) }
        let folder = isFolder(path)
        try fm.removeItem(at: url)
        let sidecar = AssetSidecar.url(for: url)
        if !folder, fm.fileExists(atPath: sidecar.path) { try fm.removeItem(at: sidecar) }
        return refresh()
    }

    // MARK: Materials

    /// The `.material` file contents for `material` (sorted keys, like sidecars).
    public static func materialFileData(_ material: MaterialAsset) throws -> Data {
        try AssetJSON.encode(material)
    }

    /// Writes `material` to a new `.material` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createMaterial(_ material: MaterialAsset, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Self.materialFileData(material).write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// Overwrites the `.material` asset `id` with `material` and reimports it, so renderers
    /// pick up the change on their next frame.
    public func writeMaterial(_ material: MaterialAsset, to id: AssetID) throws {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try Self.materialFileData(material).write(to: project.url(forAssetPath: path), options: .atomic)
        refresh()
    }

    /// `path` without surrounding slashes, refused when it is empty, leaves `Assets/` or
    /// names a sidecar.
    static func validated(_ path: String) throws -> String {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = trimmed.split(separator: "/", omittingEmptySubsequences: false)
        guard !trimmed.isEmpty, !parts.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." || $0.hasPrefix(".") }),
              !trimmed.hasSuffix("." + AssetSidecar.fileExtension) else {
            throw AssetFileError.invalidPath(path)
        }
        return trimmed
    }
}
