// Not backend-specific code, so it builds everywhere and native tests can check it on the
// generated shaders.

/// Alpha-to-coverage without MSAA, for the web backends. Natively (Metal, Vulkan) a pipeline with
/// `PipelineDescriptor.alphaToCoverage` on a one-sample target keeps its fragments with alpha of
/// at least one half: an alpha test. WebGPU only allows alpha-to-coverage with MSAA, and WebGL 2
/// ignores it on single-sample framebuffers, so for those passes the WebGPU and WebGL 2 devices
/// build the pipeline's fragment stage from a copy that discards below one half itself.
///
/// Both rewrite the generated code without parsing it, relying on the output styles of naga
/// (WGSL: the `@fragment` entry point last, returning its outputs) and Scripts/spirv-to-gles.c
/// (GLSL ES: `layout(location = 0) out vec4 name;` and one `void main()`). nil when the source
/// doesn't look like that (the device then leaves the stage as it is).
package enum AlphaToCoverageFallback {
    /// The threshold one sample's coverage flips at.
    static let threshold = "0.5"

    /// `source` (a WGSL fragment module from naga) with each `return` of its entry point
    /// discarding fragments whose location-0 alpha is below one half.
    package static func wgsl(_ source: String) -> String? {
        let text = Array(source.utf8)
        guard let entry = find("@fragment", in: text, from: 0), let arrow = find("->", in: text, from: entry),
              let open = text[arrow...].firstIndex(of: UInt8(ascii: "{")),
              let close = matchingBrace(in: text, open: open) else { return nil }
        let returnType = trimmed(String(decoding: text[(arrow + 2)..<open], as: UTF8.self))
        let alpha: String  // how to read the alpha of the returned value `acroCoverage`
        if returnType.hasPrefix("@location(") {
            guard returnType == "@location(0) vec4<f32>" else { return nil }
            alpha = "acroCoverage.w"
        } else {
            // A struct: its member at location 0.
            guard let structStart = find("struct \(returnType) {", in: text, from: 0),
                  let structEnd = text[structStart...].firstIndex(of: UInt8(ascii: "}")),
                  let location = find("@location(0) ", in: text, from: structStart), location < structEnd,
                  let colon = text[location...].firstIndex(of: UInt8(ascii: ":")), colon < structEnd,
                  let comma = text[colon...].firstIndex(where: { $0 == UInt8(ascii: ",") || $0 == UInt8(ascii: "\n") }) else { return nil }
            let member = trimmed(String(decoding: text[(location + 13)..<colon], as: UTF8.self))
            let type = trimmed(String(decoding: text[(colon + 1)..<comma], as: UTF8.self))
            guard type == "vec4<f32>", !member.isEmpty else { return nil }
            alpha = "acroCoverage.\(member).w"
        }
        var body = Array(text[open...close])
        var rewrites = 0
        var i = 0
        while let ret = find("return ", in: body, from: i) {
            guard let semicolon = body[ret...].firstIndex(of: UInt8(ascii: ";")) else { return nil }
            let value = String(decoding: body[(ret + 7)..<semicolon], as: UTF8.self)
            let replacement = Array(("{ let acroCoverage = \(value); if (\(alpha) < \(threshold)) { discard; } return acroCoverage; }").utf8)
            body.replaceSubrange(ret...semicolon, with: replacement)
            i = ret + replacement.count
            rewrites += 1
        }
        guard rewrites > 0 else { return nil }
        return String(decoding: Array(text[..<open]) + body + Array(text[(close + 1)...]), as: UTF8.self)
    }

    /// `source` (a GLSL ES 3.00 fragment stage from Scripts/spirv-to-gles.c) with its `main`
    /// renamed and wrapped by one that discards fragments whose location-0 alpha is below one half.
    package static func gles(_ source: String) -> String? {
        let text = Array(source.utf8)
        guard let output = find("layout(location = 0) out ", in: text, from: 0),
              let semicolon = text[output...].firstIndex(of: UInt8(ascii: ";")) else { return nil }
        let words = String(decoding: text[(output + 25)..<semicolon], as: UTF8.self).split(separator: " ")
        guard words.count >= 2, words[words.count - 2] == "vec4", let name = words.last else { return nil }
        let signature = "void main()"
        guard let main = find(signature, in: text, from: 0), find(signature, in: text, from: main + 1) == nil else { return nil }
        let renamed = "void acroCoverageMain()"
        return String(decoding: text[..<main], as: UTF8.self) + renamed
            + String(decoding: text[(main + signature.utf8.count)...], as: UTF8.self)
            + "\nvoid main()\n{\n    acroCoverageMain();\n    if (\(name).w < \(threshold)) discard;\n}\n"
    }

    private static func find(_ needle: String, in text: [UInt8], from start: Int) -> Int? {
        let pattern = Array(needle.utf8)
        guard !pattern.isEmpty, start >= 0, start <= text.count - pattern.count else { return nil }
        var i = start
        while i <= text.count - pattern.count {
            if text[i] == pattern[0] && text[i..<(i + pattern.count)].elementsEqual(pattern) { return i }
            i += 1
        }
        return nil
    }

    private static func matchingBrace(in text: [UInt8], open: Int) -> Int? {
        var depth = 0
        for i in open..<text.count {
            if text[i] == UInt8(ascii: "{") { depth += 1 }
            if text[i] == UInt8(ascii: "}") {
                depth -= 1
                if depth == 0 { return i }
            }
        }
        return nil
    }

    private static func trimmed(_ string: String) -> String {
        let bytes = Array(string.utf8)
        let isSpace: (UInt8) -> Bool = { $0 == 32 || $0 == 9 || $0 == 10 || $0 == 13 }
        guard let first = bytes.firstIndex(where: { !isSpace($0) }), let last = bytes.lastIndex(where: { !isSpace($0) }) else { return "" }
        return String(decoding: bytes[first...last], as: UTF8.self)
    }
}
