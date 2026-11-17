import Engine
import Foundation

// Types and helpers the builder modules (Sources/EditorBuilders*) share with EditorCore or with
// each other. They live here so the builder modules depend only on EditorCore, not on one
// another, and compile in parallel.

/// Preview settings `uiLayout.open` hands to the UI Builder tab.
public struct UIPreviewRequest: Equatable, Sendable {
    public var size: Vec2?
    public var values: [String: JSONValue]?
    public var select: String?

    package init(size: Vec2? = nil, values: [String: JSONValue]? = nil, select: String? = nil) {
        self.size = size
        self.values = values
        self.select = select
    }
}

/// The Material Builder preview's shape, light and background (`MaterialBuilderWorkspace.PreviewShape` …).
public enum MaterialPreviewShape: String, CaseIterable, Sendable { case sphere, cube, plane, selected }
public enum MaterialPreviewLight: String, CaseIterable, Sendable { case studio, sun, rim, dim }
public enum MaterialPreviewBackground: String, CaseIterable, Sendable { case gray, dark, light, sky }

/// Preview settings `materialGraph.open` asks the Material Builder tab for.
public struct MaterialPreviewRequest: Sendable {
    public var shape: MaterialPreviewShape?
    public var light: MaterialPreviewLight?
    public var background: MaterialPreviewBackground?
    public var node: String?

    package init(shape: MaterialPreviewShape? = nil, light: MaterialPreviewLight? = nil, background: MaterialPreviewBackground? = nil,
                 node: String? = nil) {
        self.shape = shape
        self.light = light
        self.background = background
        self.node = node
    }
}

// The Dialogue tab (EditorBuildersLogic) makes and lists UI layouts too.
extension EditorSession {
    /// Writes a layout to "`name`.ui" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createUIBuildAsset(in folder: String, name: String = "New UI", build: UIBuild = .starter) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New UI Layout") else {
            log.error("New UI Layout: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".ui"))
        do {
            let id = try assets.createUIBuild(build, at: path)
            log.info("Created UI layout \(path)")
            return id
        } catch {
            log.error("New UI Layout failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.ui` file.
    public func isUIBuildFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == UIBuildImporter().name
    }

    /// The visual scripts running in play mode (nil while editing).
    public var visualScriptRuntime: VisualScriptRuntime? { VisualScriptRuntime.runtime(for: world) }
}

/// Helpers more than one builder module uses.
package enum EditorBuilderSupport {
    /// The asset a file value names: "asset:<id>" or a path under `Assets/` (with or without the prefix).
    @MainActor package static func resolve(_ value: String, session: EditorSession) -> AssetID? {
        if let reference = AssetReference(value), value.hasPrefix(AssetReference.scheme) {
            return session.assets?.record(reference.asset) != nil ? reference.asset : nil
        }
        let path = value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
        return session.assets?.id(forPath: path)
    }

    /// `base`, or "`base` 2", "`base` 3"… if `names` has it.
    package static func uniqueName(_ base: String, among names: [String]) -> String {
        guard names.contains(base) else { return base }
        var n = 2
        while names.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

    /// `value` with the fields of `changes` replaced.
    package static func merged<T: Codable>(_ value: T, _ changes: JSONValue, _ label: String) throws -> T {
        guard case .object(let fields) = changes else { throw CommandError.failed("\(label) must be an object of fields") }
        guard case .object(var current) = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value)) else { return value }
        for (key, v) in fields { current[key] = v }
        do { return try JSONDecoder().decode(T.self, from: JSONEncoder().encode(JSONValue.object(current))) } catch {
            throw CommandError.failed("\(label): \(error)")
        }
    }

    /// A mutable value an undo command (a struct) shares with its copies.
    package final class Box<T> {
        package var value: T
        package init(_ value: T) { self.value = value }
    }

    /// Where `ray` meets the ground of `terrain` (nil if it misses), by marching then bisecting.
    package static func intersect(_ ray: ViewportRay, with terrain: Terrain) -> Vec3? {
        let half = Vec3(terrain.size.x / 2, terrain.heightRange, terrain.size.y / 2)
        guard let enter = ray.intersect(Bounds(center: Vec3(0, terrain.heightRange / 2, 0), halfExtent: half)) else { return nil }
        let step = max(min(terrain.size.x, terrain.size.y) / Float(max(terrain.res - 1, 1)) * 0.5, 0.05)
        func above(_ t: Float) -> Bool {
            let p = ray.point(at: t)
            return p.y > terrain.heightAt(x: p.x, z: p.z)
        }
        var t = enter
        let limit = enter + length(half) * 2 + 1
        var previous = t
        while t < limit {
            let p = ray.point(at: t)
            let inside = abs(p.x) <= half.x + 0.001 && abs(p.z) <= half.z + 0.001
            if inside && !above(t) {
                var lo = previous, hi = t
                for _ in 0..<24 {
                    let mid = (lo + hi) / 2
                    if above(mid) { lo = mid } else { hi = mid }
                }
                let hit = ray.point(at: hi)
                return Vec3(min(max(hit.x, -half.x), half.x), hit.y, min(max(hit.z, -half.z), half.z))
            }
            previous = t
            t += step
        }
        return nil
    }
}
