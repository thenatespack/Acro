#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif

/// Reads JSON text straight into a `JSONValue` (see `JSONValue.parse`). Gives the same values as
/// decoding a `JSONValue` with `SceneCoder.decoder()`; `JSONValueParseTests` compares the two.
struct JSONValueParser {
    let bytes: UnsafeBufferPointer<UInt8>
    var i = 0

    init(bytes: UnsafeBufferPointer<UInt8>) { self.bytes = bytes }

    var atEnd: Bool { i >= bytes.count }

    struct ParseError: Error, CustomStringConvertible {
        var description: String
    }

    func error(_ message: String) -> ParseError { ParseError(description: "JSON at byte \(i): \(message)") }

    mutating func skipWhitespace() {
        while i < bytes.count {
            switch bytes[i] {
            case 0x20, 0x09, 0x0A, 0x0D: i += 1
            default: return
            }
        }
    }

    mutating func value() throws -> JSONValue {
        skipWhitespace()
        guard i < bytes.count else { throw error("expected a value") }
        switch bytes[i] {
        case UInt8(ascii: "{"): return try object()
        case UInt8(ascii: "["): return .array(try array())
        case UInt8(ascii: "\""):
            let text = try string()
            // SceneCoder spells non-finite doubles as these strings, and decodes them back as doubles.
            switch text {
            case "inf": return .double(.infinity)
            case "-inf": return .double(-.infinity)
            case "nan": return .double(.nan)
            default: return .string(text)
            }
        case UInt8(ascii: "t"): try literal("true"); return .bool(true)
        case UInt8(ascii: "f"): try literal("false"); return .bool(false)
        case UInt8(ascii: "n"): try literal("null"); return .null
        default: return try number()
        }
    }

    private mutating func literal(_ word: StaticString) throws {
        let count = word.utf8CodeUnitCount
        guard i + count <= bytes.count else { throw error("expected \(word)") }
        for k in 0..<count where bytes[i + k] != word.utf8Start[k] { throw error("expected \(word)") }
        i += count
    }

    private mutating func expect(_ byte: UInt8) throws {
        skipWhitespace()
        guard i < bytes.count, bytes[i] == byte else { throw error("expected '\(Character(Unicode.Scalar(byte)))'") }
        i += 1
    }

    /// Next non-space byte is `byte`: consume it.
    private mutating func take(_ byte: UInt8) -> Bool {
        skipWhitespace()
        guard i < bytes.count, bytes[i] == byte else { return false }
        i += 1
        return true
    }

    private mutating func array() throws -> [JSONValue] {
        i += 1
        var values: [JSONValue] = []
        // A trailing comma is accepted, as the decoder does.
        while !take(UInt8(ascii: "]")) {
            values.append(try value())
            if !take(UInt8(ascii: ",")) {
                try expect(UInt8(ascii: "]"))
                break
            }
        }
        return values
    }

    private mutating func object() throws -> JSONValue {
        i += 1
        var members: [String: JSONValue] = [:]
        // A trailing comma is accepted and the first of duplicate keys wins, as in the decoder.
        while !take(UInt8(ascii: "}")) {
            skipWhitespace()
            guard i < bytes.count, bytes[i] == UInt8(ascii: "\"") else { throw error("expected a key") }
            let key = try string()
            try expect(UInt8(ascii: ":"))
            let member = try value()
            if members[key] == nil { members[key] = member }
            if !take(UInt8(ascii: ",")) {
                try expect(UInt8(ascii: "}"))
                break
            }
        }
        // `{"$entity": [index, generation]}`: an entity handle, as Entity's Decodable reads it
        // outside a scene file (anything else under that lone key is an error there too).
        if members.count == 1, let reference = members[Entity.codingKey] {
            guard case .array(let pair) = reference, pair.count == 2,
                  case .int(let index) = pair[0], case .int(let generation) = pair[1],
                  let index = UInt32(exactly: index), let generation = UInt32(exactly: generation)
            else { throw error("bad entity reference") }
            return .entity(Entity(index: index, generation: generation))
        }
        return .object(members)
    }

    private mutating func string() throws -> String {
        i += 1
        let start = i
        // Fast path: no escapes. Control characters must be escaped, as the decoder requires.
        while i < bytes.count, bytes[i] != UInt8(ascii: "\""), bytes[i] != UInt8(ascii: "\\") {
            guard bytes[i] >= 0x20 else { throw error("control character in a string") }
            i += 1
        }
        guard i < bytes.count else { throw error("unterminated string") }
        if bytes[i] == UInt8(ascii: "\"") {
            defer { i += 1 }
            return String(decoding: UnsafeBufferPointer(rebasing: bytes[start..<i]), as: UTF8.self)
        }
        var utf8 = Array(bytes[start..<i])
        while true {
            guard i < bytes.count else { throw error("unterminated string") }
            let c = bytes[i]
            i += 1
            if c == UInt8(ascii: "\"") { break }
            guard c >= 0x20 else { throw error("control character in a string") }
            guard c == UInt8(ascii: "\\") else { utf8.append(c); continue }
            guard i < bytes.count else { throw error("unterminated string") }
            let e = bytes[i]
            i += 1
            switch e {
            case UInt8(ascii: "\""), UInt8(ascii: "\\"), UInt8(ascii: "/"): utf8.append(e)
            case UInt8(ascii: "b"): utf8.append(0x08)
            case UInt8(ascii: "f"): utf8.append(0x0C)
            case UInt8(ascii: "n"): utf8.append(0x0A)
            case UInt8(ascii: "r"): utf8.append(0x0D)
            case UInt8(ascii: "t"): utf8.append(0x09)
            case UInt8(ascii: "u"):
                var scalar = try hex4()
                if (0xD800...0xDBFF).contains(scalar) {
                    // A surrogate pair: the low half must follow as another \u escape.
                    guard i + 1 < bytes.count, bytes[i] == UInt8(ascii: "\\"), bytes[i + 1] == UInt8(ascii: "u") else {
                        throw error("lone surrogate")
                    }
                    i += 2
                    let low = try hex4()
                    guard (0xDC00...0xDFFF).contains(low) else { throw error("bad surrogate pair") }
                    scalar = 0x10000 + ((scalar - 0xD800) << 10) + (low - 0xDC00)
                }
                guard let unicode = Unicode.Scalar(scalar) else { throw error("bad \\u escape") }
                utf8.append(contentsOf: Array(String(Character(unicode)).utf8))
            default: throw error("bad escape")
            }
        }
        return String(decoding: utf8, as: UTF8.self)
    }

    private mutating func hex4() throws -> UInt32 {
        guard i + 4 <= bytes.count else { throw error("short \\u escape") }
        var value: UInt32 = 0
        for _ in 0..<4 {
            let c = bytes[i]
            let digit: UInt32
            switch c {
            case UInt8(ascii: "0")...UInt8(ascii: "9"): digit = UInt32(c - UInt8(ascii: "0"))
            case UInt8(ascii: "a")...UInt8(ascii: "f"): digit = UInt32(c - UInt8(ascii: "a") + 10)
            case UInt8(ascii: "A")...UInt8(ascii: "F"): digit = UInt32(c - UInt8(ascii: "A") + 10)
            default: throw error("bad \\u escape")
            }
            value = value * 16 + digit
            i += 1
        }
        return value
    }

    /// A JSON number. As the decoder tries Int64 before Double, any number with an integral value
    /// that fits (`3`, `3.0`, `2.5e2`, `-0.0`) is `.int`; the rest is `.double`; a number too
    /// big for a Double is an error.
    private mutating func number() throws -> JSONValue {
        let start = i
        var integral = true
        if peek(UInt8(ascii: "-")) { i += 1 }
        // No leading zeros, no leading '+' or '.'.
        if peek(UInt8(ascii: "0")) {
            i += 1
        } else {
            guard digits() > 0 else { throw error("expected a value") }
        }
        if peek(UInt8(ascii: ".")) {
            i += 1
            integral = false
            guard digits() > 0 else { throw error("expected digits after '.'") }
        }
        if peek(UInt8(ascii: "e")) || peek(UInt8(ascii: "E")) {
            i += 1
            integral = false
            if peek(UInt8(ascii: "+")) || peek(UInt8(ascii: "-")) { i += 1 }
            guard digits() > 0 else { throw error("expected an exponent") }
        }
        let text = String(decoding: UnsafeBufferPointer(rebasing: bytes[start..<i]), as: UTF8.self)
        if integral, let value = Int64(text) { return .int(value) }
        guard let value = Double(text), value.isFinite else { throw error("number \(text) out of range") }
        // The decoder's Int64 for a number with a fraction or exponent: its Double must be whole
        // and strictly inside ±2^63 (so 1e-400, which underflows to 0, is 0), and the value is
        // then the exact decimal one where that is whole (9007199254740993.0 isn't rounded).
        if !integral, value.rounded() == value, value > -0x1p63, value < 0x1p63 {
            return .int(Self.exactInteger(text) ?? Int64(value))
        }
        return .double(value)
    }

    /// The Int64 that a number written with a fraction or exponent (`3.0`, `2.5e2`) equals
    /// exactly, worked out on its decimal digits (a Double rounds past 2^53); nil when it isn't
    /// whole or doesn't fit.
    private static func exactInteger(_ text: String) -> Int64? {
        var mantissa = text
        var exponent = 0
        if let e = mantissa.firstIndex(where: { $0 == "e" || $0 == "E" }) {
            guard let value = Int(mantissa[mantissa.index(after: e)...]) else { return nil }
            exponent = value
            mantissa = String(mantissa[..<e])
        }
        let negative = mantissa.hasPrefix("-")
        if negative { mantissa.removeFirst() }
        if let dot = mantissa.firstIndex(of: ".") {
            exponent -= mantissa.distance(from: dot, to: mantissa.endIndex) - 1
            mantissa.remove(at: dot)
        }
        // Digits × 10^exponent: drop leading zeros, and trailing zeros into the exponent.
        var digits = Substring(mantissa.drop { $0 == "0" })
        while exponent < 0, digits.last == "0" {
            digits.removeLast()
            exponent += 1
        }
        if digits.isEmpty { return 0 }
        guard exponent >= 0, digits.count + exponent <= 19 else { return nil }
        return Int64((negative ? "-" : "") + digits + String(repeating: "0", count: exponent))
    }

    private func peek(_ byte: UInt8) -> Bool { i < bytes.count && bytes[i] == byte }

    /// Consumes a run of decimal digits; returns how many.
    private mutating func digits() -> Int {
        let start = i
        while i < bytes.count, (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(bytes[i]) { i += 1 }
        return i - start
    }
}
