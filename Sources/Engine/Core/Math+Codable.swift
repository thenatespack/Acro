// Codable for the math types that aren't stdlib SIMD vectors (those already encode as
// arrays of their scalars). Same style: flat arrays, so scene files show `[x, y, z, w]`.

extension Quat: Codable {
    /// Decodes `[x, y, z, w]`.
    public init(from decoder: any Decoder) throws {
        vector = try Vec4(from: decoder)
    }

    /// Encodes `[x, y, z, w]`.
    public func encode(to encoder: any Encoder) throws {
        try vector.encode(to: encoder)
    }
}

extension Mat4: Codable {
    /// Decodes 16 floats, column by column.
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var columns: [Vec4] = []
        for _ in 0..<4 {
            columns.append(Vec4(try container.decode(Float.self), try container.decode(Float.self),
                                try container.decode(Float.self), try container.decode(Float.self)))
        }
        self.init(columns[0], columns[1], columns[2], columns[3])
    }

    /// Encodes 16 floats, column by column.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        for column in [c0, c1, c2, c3] {
            for i in 0..<4 { try container.encode(column[i]) }
        }
    }
}
