import Foundation
import EngineScene

/// A dialogue variable's value: a number, a bool or text.
public enum DialogueValue: Equatable, Hashable, Sendable, CustomStringConvertible, ExpressibleByIntegerLiteral,
                           ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral, ExpressibleByStringLiteral {
    case number(Double)
    case bool(Bool)
    case text(String)

    public init(integerLiteral value: Int) { self = .number(Double(value)) }
    public init(floatLiteral value: Double) { self = .number(value) }
    public init(booleanLiteral value: Bool) { self = .bool(value) }
    public init(stringLiteral value: String) { self = .text(value) }

    /// A JSON number, bool or string; nil for anything else.
    public init?(json: JSONValue) {
        switch json {
        case .int(let v): self = .number(Double(v))
        case .double(let v): self = .number(v)
        case .bool(let v): self = .bool(v)
        case .string(let v): self = .text(v)
        default: return nil
        }
    }

    public var json: JSONValue {
        switch self {
        case .number(let v): return v.rounded() == v && abs(v) < 1e15 ? .int(Int64(v)) : .double(v)
        case .bool(let v): return .bool(v)
        case .text(let v): return .string(v)
        }
    }

    public var type: DialogueVariableType {
        switch self {
        case .number: return .number
        case .bool: return .bool
        case .text: return .text
        }
    }

    public static func zero(_ type: DialogueVariableType) -> DialogueValue {
        switch type {
        case .number: return .number(0)
        case .bool: return .bool(false)
        case .text: return .text("")
        }
    }

    /// True for `true`, a non-zero number or non-empty text.
    public var isTruthy: Bool {
        switch self {
        case .number(let v): return v != 0
        case .bool(let v): return v
        case .text(let v): return !v.isEmpty
        }
    }

    public var number: Double? {
        switch self {
        case .number(let v): return v
        case .bool(let v): return v ? 1 : 0
        case .text(let v): return Double(v.trimmingCharacters(in: .whitespaces))
        }
    }

    /// As text: numbers without a needless ".0".
    public var description: String {
        switch self {
        case .number(let v): return v.rounded() == v && abs(v) < 1e15 ? String(Int64(v)) : String(v)
        case .bool(let v): return v ? "true" : "false"
        case .text(let v): return v
        }
    }

    /// This value as `type` (text "12" → 12, a number → its text, …); nil when it can't be.
    public func converted(to type: DialogueVariableType) -> DialogueValue? {
        switch (self, type) {
        case (_, .text): return .text(description)
        case (.number, .number), (.bool, .bool): return self
        case (.bool(let b), .number): return .number(b ? 1 : 0)
        case (.number(let v), .bool): return .bool(v != 0)
        case (.text(let s), .number): return Double(s.trimmingCharacters(in: .whitespaces)).map(DialogueValue.number)
        case (.text(let s), .bool):
            switch s.lowercased() {
            case "true", "yes", "1": return .bool(true)
            case "false", "no", "0", "": return .bool(false)
            default: return nil
            }
        }
    }
}

/// A small expression language for dialogue conditions and changes:
/// numbers (`10`, `2.5`), strings (`"gold"` or `'gold'`), `true` / `false`, variable names
/// (letters, digits, `_`, `.`), `+ - * /`, comparisons `== != < <= > >=`, `&&` / `and`,
/// `||` / `or`, `!` / `not` and parentheses: `gold >= 10 && !paid`, `visits + 1`.
/// A bare variable is a test of its truthiness. Unknown variables read as `false` / 0 / "".
public struct DialogueExpression: Sendable, Equatable {
    public let source: String
    private let root: Node

    indirect enum Node: Sendable, Equatable {
        case literal(DialogueValue)
        case variable(String)
        case not(Node)
        case negate(Node)
        case binary(String, Node, Node)
    }

    public struct ParseError: Error, CustomStringConvertible, Equatable, Sendable {
        public var message: String
        public var description: String { message }
    }

    public init(_ source: String) throws {
        self.source = source
        var parser = Parser(tokens: try Self.tokenize(source))
        guard !parser.tokens.isEmpty else { throw ParseError(message: "the expression is empty") }
        root = try parser.parseOr()
        if parser.index < parser.tokens.count { throw ParseError(message: "unexpected '\(parser.tokens[parser.index].text)'") }
    }

    /// Whether `name` can be a variable name.
    public static func isIdentifier(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first, !CharacterSet.decimalDigits.contains(first) else { return false }
        return !["true", "false", "and", "or", "not"].contains(name)
            && name.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) || $0 == "_" || $0 == "." }
    }

    /// The variables the expression reads.
    public var variableNames: Set<String> {
        var out = Set<String>()
        func walk(_ node: Node) {
            switch node {
            case .literal: break
            case .variable(let name): out.insert(name)
            case .not(let a), .negate(let a): walk(a)
            case .binary(_, let a, let b): walk(a); walk(b)
            }
        }
        walk(root)
        return out
    }

    /// The value with variables read from `variables`.
    public func evaluate(_ variables: (String) -> DialogueValue?) -> DialogueValue {
        Self.eval(root, variables)
    }

    /// The value as a test.
    public func test(_ variables: (String) -> DialogueValue?) -> Bool { evaluate(variables).isTruthy }

    private static func eval(_ node: Node, _ variables: (String) -> DialogueValue?) -> DialogueValue {
        switch node {
        case .literal(let v): return v
        case .variable(let name): return variables(name) ?? .bool(false)
        case .not(let a): return .bool(!eval(a, variables).isTruthy)
        case .negate(let a): return .number(-(eval(a, variables).number ?? 0))
        case .binary(let op, let a, let b):
            if op == "&&" { return .bool(eval(a, variables).isTruthy && eval(b, variables).isTruthy) }
            if op == "||" { return .bool(eval(a, variables).isTruthy || eval(b, variables).isTruthy) }
            let l = eval(a, variables), r = eval(b, variables)
            switch op {
            case "+":
                if case .text(let s) = l { return .text(s + r.description) }
                if case .text(let s) = r { return .text(l.description + s) }
                return .number((l.number ?? 0) + (r.number ?? 0))
            case "-": return .number((l.number ?? 0) - (r.number ?? 0))
            case "*": return .number((l.number ?? 0) * (r.number ?? 0))
            case "/":
                let d = r.number ?? 0
                return .number(d == 0 ? 0 : (l.number ?? 0) / d)
            case "==": return .bool(equal(l, r))
            case "!=": return .bool(!equal(l, r))
            default:
                let order: Bool
                if case .text(let x) = l, case .text(let y) = r {
                    order = op == "<" ? x < y : op == "<=" ? x <= y : op == ">" ? x > y : x >= y
                } else {
                    let x = l.number ?? 0, y = r.number ?? 0
                    order = op == "<" ? x < y : op == "<=" ? x <= y : op == ">" ? x > y : x >= y
                }
                return .bool(order)
            }
        }
    }

    private static func equal(_ a: DialogueValue, _ b: DialogueValue) -> Bool {
        switch (a, b) {
        case (.text(let x), .text(let y)): return x == y
        case (.text, _), (_, .text): return a.description == b.description
        case (.bool(let x), .bool(let y)): return x == y
        default: return a.number == b.number
        }
    }

    // MARK: Parsing

    struct Token: Equatable {
        enum Kind: Equatable { case number(Double), string(String), name(String), op(String) }
        var kind: Kind
        var text: String
    }

    static func tokenize(_ source: String) throws -> [Token] {
        var tokens: [Token] = []
        let chars = Array(source)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace { i += 1; continue }
            if c.isNumber {
                var j = i
                while j < chars.count, chars[j].isNumber || chars[j] == "." { j += 1 }
                let text = String(chars[i..<j])
                guard let value = Double(text) else { throw ParseError(message: "bad number '\(text)'") }
                tokens.append(Token(kind: .number(value), text: text))
                i = j
                continue
            }
            if c == "\"" || c == "'" {
                var j = i + 1
                while j < chars.count, chars[j] != c { j += 1 }
                guard j < chars.count else { throw ParseError(message: "a string isn't closed") }
                let text = String(chars[(i + 1)..<j])
                tokens.append(Token(kind: .string(text), text: String(chars[i...j])))
                i = j + 1
                continue
            }
            if c.isLetter || c == "_" {
                var j = i
                while j < chars.count, chars[j].isLetter || chars[j].isNumber || chars[j] == "_" || chars[j] == "." { j += 1 }
                let text = String(chars[i..<j])
                switch text {
                case "and": tokens.append(Token(kind: .op("&&"), text: text))
                case "or": tokens.append(Token(kind: .op("||"), text: text))
                case "not": tokens.append(Token(kind: .op("!"), text: text))
                default: tokens.append(Token(kind: .name(text), text: text))
                }
                i = j
                continue
            }
            let two = i + 1 < chars.count ? String(chars[i...(i + 1)]) : ""
            if ["&&", "||", "==", "!=", "<=", ">="].contains(two) {
                tokens.append(Token(kind: .op(two), text: two))
                i += 2
                continue
            }
            if "+-*/<>!()=".contains(c) {
                // A single "=" means "==" (writers often type it in conditions).
                let op = c == "=" ? "==" : String(c)
                tokens.append(Token(kind: .op(op), text: String(c)))
                i += 1
                continue
            }
            throw ParseError(message: "unexpected '\(c)'")
        }
        return tokens
    }

    struct Parser {
        let tokens: [Token]
        var index = 0

        mutating func take(_ ops: Set<String>) -> String? {
            guard index < tokens.count, case .op(let op) = tokens[index].kind, ops.contains(op) else { return nil }
            index += 1
            return op
        }

        mutating func parseOr() throws -> Node {
            var node = try parseAnd()
            while take(["||"]) != nil { node = .binary("||", node, try parseAnd()) }
            return node
        }

        mutating func parseAnd() throws -> Node {
            var node = try parseComparison()
            while take(["&&"]) != nil { node = .binary("&&", node, try parseComparison()) }
            return node
        }

        mutating func parseComparison() throws -> Node {
            var node = try parseSum()
            while let op = take(["==", "!=", "<", "<=", ">", ">="]) { node = .binary(op, node, try parseSum()) }
            return node
        }

        mutating func parseSum() throws -> Node {
            var node = try parseProduct()
            while let op = take(["+", "-"]) { node = .binary(op, node, try parseProduct()) }
            return node
        }

        mutating func parseProduct() throws -> Node {
            var node = try parseUnary()
            while let op = take(["*", "/"]) { node = .binary(op, node, try parseUnary()) }
            return node
        }

        mutating func parseUnary() throws -> Node {
            if take(["!"]) != nil { return .not(try parseUnary()) }
            if take(["-"]) != nil { return .negate(try parseUnary()) }
            return try parsePrimary()
        }

        mutating func parsePrimary() throws -> Node {
            guard index < tokens.count else { throw ParseError(message: "the expression ends too early") }
            let token = tokens[index]
            index += 1
            switch token.kind {
            case .number(let v): return .literal(.number(v))
            case .string(let s): return .literal(.text(s))
            case .name("true"): return .literal(.bool(true))
            case .name("false"): return .literal(.bool(false))
            case .name(let name): return .variable(name)
            case .op("("):
                let inner = try parseOr()
                guard take([")"]) != nil else { throw ParseError(message: "a '(' isn't closed") }
                return inner
            case .op(let op): throw ParseError(message: "unexpected '\(op)'")
            }
        }
    }
}
