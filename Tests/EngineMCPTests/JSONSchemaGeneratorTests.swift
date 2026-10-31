import Foundation
import Testing
@testable import EngineMCP

// JSON Schemas probed from Codable types.

private enum Mode: String, Codable, CaseIterable { case fast, slow }
private enum Level: Int, Codable, CaseIterable { case low = 1, high = 2 }
private enum Opaque: String, Codable { case a, b }

private struct Point: Codable { var x: Float; var y: Float }

private struct Everything: Codable {
    var name: String
    var count: Int
    var ratio: Double?
    var enabled: Bool
    var mode: Mode
    var level: Level?
    var tags: [String]
    var points: [Point]?
    var position: SIMD3<Float>
    var lookup: [String: Int]
    var any: JSON?
    /// Rejects the probe's placeholder: a plain string, and nothing after it could be probed.
    var opaque: Opaque
}

/// Validates its string, like an id type: needs an override with a sample.
private struct Token: Codable {
    var value: String
    init(value: String) { self.value = value }
    init(from decoder: any Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        guard string.hasPrefix("tok_") else { throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad")) }
        value = string
    }
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

private struct UsesToken: Codable { var token: Token; var after: Int }

/// Hand-written decoder with defaults: decodeIfPresent keys are optional.
private struct Defaults: Decodable {
    var size: Int
    var label: String
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        size = try c.decodeIfPresent(Int.self, forKey: .size) ?? 1
        label = try c.decode(String.self, forKey: .label)
    }
    enum CodingKeys: String, CodingKey { case size, label }
}

private struct Described: Codable, JSONSchemaProviding {
    static var jsonSchema: JSON { ["type": "string", "format": "date"] }
}

private struct Empty: Codable {}

@Suite struct JSONSchemaGeneratorTests {
    @Test func probesStructsEnumsOptionalsArraysAndDictionaries() {
        let schema = JSONSchemaGenerator().schema(for: Everything.self)
        let expected: JSON = [
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "count": ["type": "integer"],
                "ratio": ["type": "number"],
                "enabled": ["type": "boolean"],
                "mode": ["type": "string", "enum": ["fast", "slow"]],
                "level": ["type": "integer", "enum": [1, 2]],
                "opaque": ["type": "string"],
                "tags": ["type": "array", "items": ["type": "string"]],
                "points": ["type": "array", "items": ["type": "object", "properties": ["x": ["type": "number"], "y": ["type": "number"]],
                                                      "required": ["x", "y"]]],
                "position": ["type": "array", "items": ["type": "number"], "minItems": 3, "maxItems": 3],
                "lookup": ["type": "object", "additionalProperties": ["type": "integer"]],
                "any": [:],
            ],
            "required": ["name", "count", "enabled", "mode", "tags", "position", "lookup", "opaque"],
        ]
        #expect(schema == expected)
    }

    @Test func overridesSupplySchemasAndSamples() {
        var generator = JSONSchemaGenerator()
        // Without an override the token is a plain string, and the probe can't get past it.
        #expect(generator.schema(for: UsesToken.self) == ["type": "object", "properties": ["token": ["type": "string"]],
                                                          "required": ["token"]])
        generator.override(Token.self, schema: ["type": "string", "pattern": "^tok_"], sample: Token(value: "tok_1"))
        #expect(generator.schema(for: UsesToken.self) == [
            "type": "object", "properties": ["token": ["type": "string", "pattern": "^tok_"], "after": ["type": "integer"]],
            "required": ["token", "after"],
        ])
        #expect(generator.schema(for: Described.self) == ["type": "string", "format": "date"])
    }

    @Test func handWrittenDecodersAndEmptyTypes() {
        #expect(JSONSchemaGenerator().schema(for: Defaults.self) == [
            "type": "object", "properties": ["size": ["type": "integer"], "label": ["type": "string"]], "required": ["label"],
        ])
        // Decodes from anything: any value.
        #expect(JSONSchemaGenerator().schema(for: Empty.self) == [:])
        #expect(JSONSchemaGenerator().schema(for: [Mode].self) == ["type": "array", "items": ["type": "string", "enum": ["fast", "slow"]]])
    }
}
