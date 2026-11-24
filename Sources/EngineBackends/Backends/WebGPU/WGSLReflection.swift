// Not WebGPU-specific code, so it builds everywhere and native tests can check the generated WGSL.

/// How a texture binding is sampled, as WebGPU's bind group layouts declare it.
package enum WGSLTextureSampleType: String, Sendable, Hashable {
    /// Read with a filtering sampler somewhere in the module.
    case float
    /// Only read with `textureLoad` (or never sampled with a sampler), so any float texture binds,
    /// including `.depth32Float` and `.r32Float` ones.
    case unfilterableFloat = "unfilterable-float"
    case depth, sint, uint
}

/// A resource binding a WGSL module declares and uses (see the table in `ShaderSource`).
package struct WGSLBinding: Sendable, Hashable {
    package enum Kind: Sendable, Hashable {
        case uniformBuffer
        case storageBuffer(readOnly: Bool)
        case sampler(comparison: Bool)
        case texture(WGSLTextureSampleType)
        /// A WebGPU texture format (`rgba16float`) and access (`write-only`, `read-only`, `read-write`).
        case storageTexture(format: String, access: String)
    }

    package var group: Int
    package var binding: Int
    package var kind: Kind

    package init(group: Int, binding: Int, kind: Kind) {
        self.group = group
        self.binding = binding
        self.kind = kind
    }
}

/// Reads what the WebGPU backend needs from the WGSL that `Scripts/compile-shaders.sh` generates
/// with naga: the bindings a module uses (to build bind group layouts that follow the binding
/// table) and its fragment outputs. Not a WGSL parser: it relies on naga's output style (one
/// global per `@group(g) @binding(b)` attribute pair, no comments inside declarations).
package enum WGSLReflection {
    /// The module's resource bindings that its code uses, sorted by group and binding. Declared but
    /// unused globals are left out: WebGPU only checks the bindings an entry point uses, so a
    /// pass needn't bind them.
    package static func bindings(_ source: String) -> [WGSLBinding] {
        let text = Array(source.utf8)
        var result: [WGSLBinding] = []
        var i = 0
        while let start = find("@group(", in: text, from: i) {
            i = start + 7
            guard let group = integer(in: text, at: &i), let bindingStart = find("@binding(", in: text, from: i) else { break }
            i = bindingStart + 9
            guard let binding = integer(in: text, at: &i), let varStart = find("var", in: text, from: i),
                  let end = text[varStart...].firstIndex(of: UInt8(ascii: ";")) else { break }
            i = end
            let declaration = String(decoding: text[(varStart + 3)..<end], as: UTF8.self)
            guard let (space, name, type) = parseDeclaration(declaration),
                  occurrences(of: name, in: text, limit: 2) > 1,
                  let kind = kind(space: space, type: type, name: name, text: text) else { continue }
            result.append(WGSLBinding(group: group, binding: binding, kind: kind))
        }
        return result.sorted { ($0.group, $0.binding) < ($1.group, $1.binding) }
    }

    /// Locations of the fragment entry point's outputs (`@location(n)` in its return type).
    package static func fragmentOutputs(_ source: String) -> [Int] {
        let text = Array(source.utf8)
        guard let entry = find("@fragment", in: text, from: 0), let arrow = find("->", in: text, from: entry),
              let body = text[arrow...].firstIndex(of: UInt8(ascii: "{")) else { return [] }
        let returnType = String(decoding: text[(arrow + 2)..<body], as: UTF8.self).trimmingWhitespace()
        if returnType.hasPrefix("@location(") {
            var j = 10
            let bytes = Array(returnType.utf8)
            return integer(in: bytes, at: &j).map { [$0] } ?? []
        }
        // A struct: the locations of its members.
        guard let structStart = find("struct \(returnType) {", in: text, from: 0),
              let structEnd = text[structStart...].firstIndex(of: UInt8(ascii: "}")) else { return [] }
        var locations: [Int] = []
        var j = structStart
        while let location = find("@location(", in: text, from: j), location < structEnd {
            j = location + 10
            if let value = integer(in: text, at: &j) { locations.append(value) }
        }
        return locations.sorted()
    }

    /// `<space> name: type` after `var`, e.g. `<uniform> global: type_21`.
    private static func parseDeclaration(_ declaration: String) -> (space: String, name: String, type: String)? {
        var rest = Substring(declaration)
        var space = ""
        if rest.first == "<" {
            guard let close = rest.firstIndex(of: ">") else { return nil }
            space = rest[rest.index(after: rest.startIndex)..<close].filter { $0 != " " }
            rest = rest[rest.index(after: close)...]
        }
        guard let colon = rest.firstIndex(of: ":") else { return nil }
        let name = String(rest[..<colon]).trimmingWhitespace()
        let type = String(rest[rest.index(after: colon)...]).trimmingWhitespace()
        return name.isEmpty ? nil : (space, name, type)
    }

    private static func kind(space: String, type: String, name: String, text: [UInt8]) -> WGSLBinding.Kind? {
        switch space {
        case "uniform": return .uniformBuffer
        case "storage", "storage,read": return .storageBuffer(readOnly: true)
        case "storage,read_write": return .storageBuffer(readOnly: false)
        case "": break
        default: return nil
        }
        if type == "sampler" { return .sampler(comparison: false) }
        if type == "sampler_comparison" { return .sampler(comparison: true) }
        if type.hasPrefix("texture_depth_") { return .texture(.depth) }
        if type.hasPrefix("texture_storage_2d<") {
            let arguments = type.dropFirst("texture_storage_2d<".count).prefix { $0 != ">" }
                .split(separator: ",").map { String($0).trimmingWhitespace() }
            guard arguments.count == 2 else { return nil }
            let access = switch arguments[1] {
            case "read": "read-only"
            case "read_write": "read-write"
            default: "write-only"
            }
            return .storageTexture(format: arguments[0], access: access)
        }
        if type.hasPrefix("texture_") {
            if type.hasSuffix("<i32>") { return .texture(.sint) }
            if type.hasSuffix("<u32>") { return .texture(.uint) }
            return .texture(isSampled(name, in: text) ? .float : .unfilterableFloat)
        }
        return nil
    }

    /// Whether `name` is an argument of a `textureSample…` or `textureGather…` call.
    private static func isSampled(_ name: String, in text: [UInt8]) -> Bool {
        for prefix in ["textureSample", "textureGather"] {
            var i = 0
            while let call = find(prefix, in: text, from: i) {
                i = call + prefix.utf8.count
                guard let open = text[i...].firstIndex(of: UInt8(ascii: "(")) else { break }
                var depth = 0, close = open
                for j in open..<text.count {
                    if text[j] == UInt8(ascii: "(") { depth += 1 }
                    if text[j] == UInt8(ascii: ")") { depth -= 1; if depth == 0 { close = j; break } }
                }
                if occurrences(of: name, in: Array(text[open...close]), limit: 1) > 0 { return true }
                i = close
            }
        }
        return false
    }

    private static func find(_ needle: String, in text: [UInt8], from start: Int) -> Int? {
        let pattern = Array(needle.utf8)
        guard !pattern.isEmpty, start <= text.count - pattern.count else { return nil }
        var i = start
        while i <= text.count - pattern.count {
            if text[i] == pattern[0] && text[i..<(i + pattern.count)].elementsEqual(pattern) { return i }
            i += 1
        }
        return nil
    }

    /// Whole-word occurrences of `word`, counting up to `limit`.
    private static func occurrences(of word: String, in text: [UInt8], limit: Int) -> Int {
        func isWordByte(_ byte: UInt8) -> Bool {
            (byte >= 48 && byte <= 57) || (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122) || byte == 95
        }
        let length = word.utf8.count
        var count = 0, i = 0
        while count < limit, let found = find(word, in: text, from: i) {
            let before = found == 0 || !isWordByte(text[found - 1])
            let after = found + length == text.count || !isWordByte(text[found + length])
            if before && after { count += 1 }
            i = found + 1
        }
        return count
    }

    private static func integer(in text: [UInt8], at index: inout Int) -> Int? {
        var value = 0, digits = 0
        while index < text.count, text[index] >= 48, text[index] <= 57 {
            value = value * 10 + Int(text[index] - 48)
            index += 1
            digits += 1
        }
        return digits > 0 ? value : nil
    }
}

private extension String {
    func trimmingWhitespace() -> String {
        let bytes = Array(utf8)
        let isSpace: (UInt8) -> Bool = { $0 == 32 || $0 == 9 || $0 == 10 || $0 == 13 }
        guard let first = bytes.firstIndex(where: { !isSpace($0) }), let last = bytes.lastIndex(where: { !isSpace($0) }) else { return "" }
        return String(decoding: bytes[first...last], as: UTF8.self)
    }
}
