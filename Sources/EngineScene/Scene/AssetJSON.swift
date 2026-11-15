// How the engine writes and reads its JSON files (assets, project settings, sound builds).
import Foundation
import EngineCore

/// JSON helpers for sidecars, settings and the Library index: sorted keys, stable output.
package enum AssetJSON {
    package static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return encoder
    }

    package static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return decoder
    }

    /// Pretty, sorted, with short numeric arrays on one line and a trailing newline.
    package static func encode<T: Encodable>(_ value: T) throws -> Data {
        var bytes = SceneCoder.collapsingNumericArrays(try encoder().encode(value))
        bytes.append(UInt8(ascii: "\n"))
        return Data(bytes)
    }

    package static func value<T: Encodable>(_ value: T) throws -> JSONValue {
        try decoder().decode(JSONValue.self, from: encoder().encode(value))
    }

    package static func decode<T: Decodable>(_ type: T.Type, from value: JSONValue) throws -> T {
        try decoder().decode(T.self, from: encoder().encode(value))
    }

    /// One-line canonical text of a value (sorted keys), for comparing settings.
    package static func canonical(_ value: JSONValue) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(value)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    package static func merge(_ value: JSONValue, over base: JSONValue) -> JSONValue {
        guard case .object(let top) = value, case .object(var result) = base else { return value }
        for (key, v) in top { result[key] = result[key].map { merge(v, over: $0) } ?? v }
        return .object(result)
    }
}
