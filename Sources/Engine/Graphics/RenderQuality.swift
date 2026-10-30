/// A rendering quality preset. The engine applies `sampleCount`; the other settings
/// are hints for game code (read them from `Engine.quality`).
public enum RenderQuality: String, Sendable, CaseIterable {
    case low, medium, high, ultra

    /// MSAA samples for the screen pass (backends clamp to what the GPU supports).
    public var sampleCount: Int {
        switch self {
        case .low: 1
        case .medium: 2
        case .high: 4
        case .ultra: 8
        }
    }

    /// Suggested shadow-map resolution (square).
    public var shadowMapSize: Int {
        switch self {
        case .low: 1024
        case .medium, .high: 2048
        case .ultra: 4096
        }
    }

    /// Suggested PCF kernel radius in texels: 0 is a single (hardware 2x2) tap, 1 is 3x3, 2 is 5x5.
    public var shadowFilterRadius: Int {
        switch self {
        case .low: 0
        case .medium, .high: 1
        case .ultra: 2
        }
    }
}
