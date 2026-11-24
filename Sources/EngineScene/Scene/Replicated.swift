// The networking marker component. It lives with the scene code because `ComponentRegistry`
// registers it up front (so scenes can name it before networking runs); replication itself
// is in Net/.
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore

/// Marks an entity for replication and names the components sent (by `componentName`).
/// Transforms replicate as local transforms; the parent link is always sent (see Net/Replication.swift).
public struct Replicated: Component, Equatable, Sendable {
    public static let componentName = "Replicated"
    public var components: [String]
    /// How often it is sent relative to others when a snapshot can't carry every change (see
    /// `NetServer.bandwidthLimit`): it gains this much priority per snapshot it waits.
    public var priority: Float
    /// Quantized (about 14 bytes) or exact (41 bytes; for entities a client predicts).
    public var transform: NetTransformEncoding

    public init(components: [String] = [Transform.componentName], priority: Float = 1, transform: NetTransformEncoding = .quantized) {
        self.components = components
        self.priority = priority
        self.transform = transform
    }

    private enum CodingKeys: String, CodingKey { case components, priority, transform }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        components = try c.decode([String].self, forKey: .components)
        priority = try c.decodeIfPresent(Float.self, forKey: .priority) ?? 1
        transform = try c.decodeIfPresent(NetTransformEncoding.self, forKey: .transform) ?? .quantized
    }
}

/// How a replicated entity's `Transform` is sent.
public enum NetTransformEncoding: String, Codable, Sendable {
    /// Position in 1/1024 m steps (zigzag varints), rotation as smallest-three in 32 bits
    /// (within 0.2 degrees), scale omitted when one: 12-14 bytes for an unscaled entity within
    /// 500 m of the origin, and a delta of the changed fields against the client's baseline in
    /// snapshots (2-8 bytes for something moving and turning).
    case quantized
    /// 41 bytes, bit-exact (what client-side prediction reconciles from).
    case exact
}
