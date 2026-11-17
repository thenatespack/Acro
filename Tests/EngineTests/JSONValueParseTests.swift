import Foundation
import Testing
@testable import EngineCore
@testable import EngineScene

// JSONValue.parse must give exactly what decoding a JSONValue with SceneCoder.decoder() gives
// (the Codable path it replaces in JSONValue.encoding), on edge cases and on the repository's
// own JSON assets.

/// The Codable path, the reference.
private func decoded(_ data: Data) -> Result<JSONValue, Error> {
    Result { try SceneCoder.decoder().decode(JSONValue.self, from: data) }
}

private func parsed(_ data: Data) -> Result<JSONValue, Error> {
    Result { try JSONValue.parse(data) }
}

/// Equal, with NaN equal to NaN and -0.0 told apart from 0.0.
private func same(_ a: JSONValue, _ b: JSONValue) -> Bool {
    switch (a, b) {
    case (.double(let x), .double(let y)):
        return (x.isNaN && y.isNaN) || (x == y && x.sign == y.sign)
    case (.array(let x), .array(let y)):
        return x.count == y.count && zip(x, y).allSatisfy(same)
    case (.object(let x), .object(let y)):
        return x.count == y.count && x.allSatisfy { key, value in y[key].map { same(value, $0) } ?? false }
    default:
        return a == b
    }
}

/// The two paths agree: the same value, or both fail.
private func agree(_ data: Data) -> String? {
    switch (decoded(data), parsed(data)) {
    case (.success(let a), .success(let b)): return same(a, b) ? nil : "decoded \(a), parsed \(b)"
    case (.failure, .failure): return nil
    case (.success(let a), .failure(let e)): return "decoded \(a), parse failed: \(e)"
    case (.failure(let e), .success(let b)): return "decode failed (\(e)), parsed \(b)"
    }
}

@Suite struct JSONValueParseTests {
    static let cases: [String] = [
        // Scalars and their int/double split.
        "null", "true", "false", "0", "-0", "1", "-1", "42", "1.0", "-1.0", "1.5", "0.1", "-0.0", "1e3", "1E3",
        "1e-3", "2.5e+2", "123456789012", "9223372036854775807", "-9223372036854775808", "9223372036854775808",
        "-9223372036854775809", "1e400", "18446744073709551616", "3.0000000000000004", "0.30000000000000004",
        // Strings, escapes, and the non-finite spellings.
        #""""#, #""a""#, #""inf""#, #""-inf""#, #""nan""#, #""Inf""#, #""NaN""#, #""a\"b\\c\/d""#,
        #""\b\f\n\r\t""#, #""é中""#, #""😀""#, #""é中😀""#, #""\ud83d""#, #""\x""#,
        // Containers.
        "[]", "{}", "[1, 2.5, \"x\", null, true, [ ], { }]", #"{"a": 1, "b": {"c": [1.25, -3]}}"#,
        "[0, 1, 0]", " [ 1 , 2 ] ", "\n{\n  \"k\" : 1\n}\n", #"{"a": 1, "a": 2}"#,
        // Entity references outside a scene file.
        #"{"$entity": [3, 1]}"#, #"{"$entity": [0, 0]}"#, #"{"$entity": 3}"#, #"{"$entity": [3]}"#,
        #"{"$entity": [-1, 0]}"#, #"{"$entity": [4294967296, 0]}"#, #"{"$entity": [1.5, 0]}"#,
        #"{"$entity": [3, 1], "x": 1}"#, #"[{"$entity": [7, 2]}]"#,
        // Malformed.
        "", "[", "{\"a\" 1}", "[1,]", "tru", "nul", "01", "-", "1.", ".5", "+1", "1 2", "[1] x",
        "{\"a\": 1,}", "[,]", "[1,,2]", "{,}", "[1 2]", "{\"a\": 1 \"b\": 2}", "-01", "1e", "1e+", "-.5", "00",
        // Raw control characters in strings, and escaped NUL and lone surrogates.
        "\"a\tb\"", "\"a\nb\"", #""\u0000""#, #""\uD800""#, #""\uDC00""#, #""\uD800x""#, "\"unterminated",
        // Precision and range at the int/double boundary.
        "9007199254740993", "9007199254740993.0", "1e19", "-1e19", "1.0e2", "0.0", "1e-400", "-1e-400",
        "4.9e-324", "1.7976931348623157e308", "1.8e308", "123.456e-1", "0.5e1", "-9223372036854775808.0",
        "9223372036854775807.0", "9223372036854775808.0", "100e-2", "1.000e3", "12.5e1", "0.00e5", "-0e0", "5e-1",
    ]

    @Test(arguments: cases) func agreesWithTheDecoder(_ text: String) {
        #expect(agree(Data(text.utf8)) == nil, "\(text)")
    }

    /// Every JSON asset in the repository's projects and evals.
    @Test func agreesOnTheRepositorysAssets() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        var checked = 0
        for folder in ["Projects", "Evals", "Tests"] {
            guard let files = FileManager.default.enumerator(at: root.appendingPathComponent(folder), includingPropertiesForKeys: nil) else { continue }
            for case let url as URL in files where !url.pathComponents.contains(".build") && !url.pathComponents.contains("Library") {
                guard let data = try? Data(contentsOf: url), data.count < 4_000_000,
                      (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) != nil else { continue }
                #expect(agree(data) == nil, "\(url.lastPathComponent)")
                checked += 1
            }
        }
        #expect(checked >= 10, "found \(checked) JSON files")
    }

    /// What encoding real values gives: Encodable values round-trip through `encoding`.
    @Test func encodingMatchesTheDecoderOnEncodedValues() throws {
        struct Sample: Encodable {
            var position = SIMD3<Float>(1.5, -0.25, 3)
            var scale: Float = 1
            var count = 3
            var name = "Crate \"big\" / é"
            var entity = Entity(index: 5, generation: 2)
            var missing: Entity? = nil
            var flags = [true, false]
            var nested = ["a": [0.1, 0.2], "b": []]
            var nonFinite: [Double] = [.infinity, -.infinity, .nan]
        }
        let data = try SceneCoder.encoder().encode(Sample())
        #expect(agree(data) == nil)
        let value = try JSONValue.encoding(Sample())
        guard case .object(let fields) = value else { Issue.record("\(value)"); return }
        #expect(fields["entity"] == .entity(Entity(index: 5, generation: 2)))
        #expect(fields["count"] == .int(3))
    }
}
