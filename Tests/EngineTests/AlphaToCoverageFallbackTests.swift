import Foundation
import Testing
@testable import EngineBackends

/// `AlphaToCoverageFallback`: the alpha-tested copies of fragment stages that the WebGPU and
/// WebGL 2 devices use for alpha-to-coverage pipelines in single-sample passes.
@Suite struct AlphaToCoverageFallbackTests {
    static var shaders: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/EngineCore/Shaders")
    }

    static func source(_ name: String) throws -> String {
        try String(contentsOf: shaders.appendingPathComponent(name), encoding: .utf8)
    }

    /// Runs `tool` (if installed) on `text` saved with `fileExtension`: nil when it isn't
    /// installed, "" when it accepts the file, else its output.
    static func validate(_ text: String, fileExtension: String, tools: [String], arguments: [String] = []) -> String? {
        guard let tool = tools.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AlphaToCoverageFallbackTests-\(UUID().uuidString).\(fileExtension)")
        defer { try? FileManager.default.removeItem(at: url) }
        guard (try? Data(text.utf8).write(to: url)) != nil else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments + [url.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        guard (try? process.run()) != nil else { return nil }
        process.waitUntilExit()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        return process.terminationStatus == 0 ? "" : output
    }

    @Test func alphaToCoverageFallbackWGSLDiscardsBelowHalf() throws {
        let original = try Self.source("mesh_fur.frag.wgsl")
        let patched = try #require(AlphaToCoverageFallback.wgsl(original))
        #expect(patched.contains("let acroCoverage = FragmentOutput(") && patched.contains("if (acroCoverage.member.w < 0.5) { discard; }"))
        #expect(WGSLReflection.bindings(patched) == WGSLReflection.bindings(original))
        #expect(WGSLReflection.fragmentOutputs(patched) == WGSLReflection.fragmentOutputs(original))
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let naga = [ProcessInfo.processInfo.environment["NAGA"], "\(home)/.cargo/bin/naga"].compactMap { $0 }
        if let result = Self.validate(patched, fileExtension: "wgsl", tools: naga) { #expect(result == "", "\(result)") }
    }

    @Test func alphaToCoverageFallbackWGSLSingleOutput() {
        let source = """
        @fragment
        fn main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
            let c = vec4<f32>(uv, 0.0, uv.x);
            return c;
        }
        """
        let patched = AlphaToCoverageFallback.wgsl(source)
        #expect(patched?.contains("{ let acroCoverage = c; if (acroCoverage.w < 0.5) { discard; } return acroCoverage; }") == true)
        // No vec4 color output: left alone.
        #expect(AlphaToCoverageFallback.wgsl(source.replacingOccurrences(of: "vec4<f32> {", with: "vec2<f32> {")) == nil)
    }

    @Test func alphaToCoverageFallbackGLESWrapsMain() throws {
        let original = try Self.source("mesh_fur.frag.gles")
        let patched = try #require(AlphaToCoverageFallback.gles(original))
        #expect(patched.contains("void acroCoverageMain()"))
        #expect(patched.hasSuffix("void main()\n{\n    acroCoverageMain();\n    if (_2099.w < 0.5) discard;\n}\n"))
        #expect(GLESInterface(source: patched) == GLESInterface(source: original))
        let glslang = ["/opt/homebrew/bin/glslangValidator", "/usr/local/bin/glslangValidator", "/usr/bin/glslangValidator"]
        if let result = Self.validate(patched, fileExtension: "frag", tools: glslang, arguments: ["-S", "frag"]) {
            #expect(result == "", "\(result)")
        }
    }

    /// Every generated fragment stage with a vec4 color output can be alpha-tested, so a future
    /// alpha-to-coverage pipeline on any of them gets the fallback.
    @Test func alphaToCoverageFallbackCoversEveryColorFragment() throws {
        let files = try FileManager.default.contentsOfDirectory(atPath: Self.shaders.path)
        var checked = 0
        for name in files where name.hasSuffix(".frag.wgsl") {
            let source = try Self.source(name)
            guard WGSLReflection.fragmentOutputs(source).contains(0), source.contains("@location(0) member: vec4<f32>")
                    || source.contains("-> @location(0) vec4<f32>") else { continue }
            #expect(AlphaToCoverageFallback.wgsl(source) != nil, "\(name)")
            checked += 1
        }
        for name in files where name.hasSuffix(".frag.gles") {
            let source = try Self.source(name)
            guard source.contains("layout(location = 0) out vec4 ") else { continue }
            #expect(AlphaToCoverageFallback.gles(source) != nil, "\(name)")
            checked += 1
        }
        #expect(checked > 40)
    }
}
