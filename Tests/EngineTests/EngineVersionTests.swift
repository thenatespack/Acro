import Foundation
import Testing
@testable import Engine

// The engine version: recorded in Project.json and asset packs, compared when they are opened.

@MainActor @Suite struct EngineVersionTests {
    @Test func mismatchesAndOrdering() {
        #expect(EngineVersionMismatch.check(nil) == nil)
        #expect(EngineVersionMismatch.check(EngineVersion.current) == nil)
        let newer = EngineVersionMismatch(saved: "99.0.0", current: "0.1.0")
        #expect(newer.isNewer)
        #expect(!EngineVersionMismatch(saved: "0.0.9", current: "0.1.0").isNewer)
        #expect(EngineVersionMismatch(saved: "0.10.0", current: "0.9.0").isNewer)  // numeric, not lexical
        #expect(EngineVersionMismatch.check("99.0.0")?.saved == "99.0.0")
        // PATCH is bumped on every source change: only MAJOR.MINOR counts.
        #expect(EngineVersionMismatch.check("0.3.1", current: "0.3.7") == nil)
        #expect(EngineVersionMismatch.check("0.2.9", current: "0.3.0") != nil)
        #expect(EngineVersionMismatch.check("1.3.0", current: "0.3.0") != nil)
    }

    @Test func projectsRecordTheVersion() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("EngineVersionTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        var project = try Project.create(at: root)
        #expect(project.settings.engineVersion == EngineVersion.current)
        let json = try String(contentsOf: project.settingsURL, encoding: .utf8)
        #expect(json.contains("\"engineVersion\" : \"\(EngineVersion.current)\""))
        #expect(project.engineVersionMismatch == nil)
        #expect(Project.engineVersionMismatch(at: root) == nil)

        // From another version: noticed without opening, and by the opened project; stamping fixes it.
        project.settings.engineVersion = "99.0.0"
        try project.saveSettings()
        #expect(Project.engineVersionMismatch(at: root)?.saved == "99.0.0")
        #expect(Project.engineVersionMismatch(at: project.settingsURL)?.saved == "99.0.0")
        project = try Project.open(at: root)
        #expect(project.engineVersionMismatch?.saved == "99.0.0")
        try project.stampEngineVersion()
        #expect(try Project.open(at: root).engineVersionMismatch == nil)

        // A project from before versions were recorded: no mismatch, and no key until stamped.
        try Data(#"{"format": "SwiftGameEngine.Project", "name": "Old", "version": 1}"#.utf8).write(to: project.settingsURL)
        project = try Project.open(at: root)
        #expect(project.settings.engineVersion == nil)
        #expect(project.engineVersionMismatch == nil)
        try project.saveSettings()
        #expect(!(try String(contentsOf: project.settingsURL, encoding: .utf8)).contains("engineVersion"))
    }

    @Test func packsRecordTheVersion() throws {
        var manifest = AssetPackManifest(name: "Game", platform: .macos, textureFamily: .bc, vertexStride: 0, scenes: [], assets: [])
        #expect(GamePlayer.packVersionWarning(manifest) == nil)  // not recorded
        manifest.engineVersion = EngineVersion.current
        #expect(GamePlayer.packVersionWarning(manifest) == nil)
        manifest.engineVersion = "99.0.0"
        #expect(GamePlayer.packVersionWarning(manifest)?.contains("99.0.0") == true)
        let decoded = try JSONDecoder().decode(AssetPackManifest.self, from: JSONEncoder().encode(manifest))
        #expect(decoded.engineVersion == "99.0.0")
        #expect(try GamePlayer.Options.parse(["--version"]).version)
    }
}

@Test func fileFormatTagsAcceptTheirPreRenameSpelling() {
    #expect(FileFormat.tag("Scene") == "Acro.Scene")
    #expect(FileFormat.matches("Acro.Scene", "Acro.Scene"))
    #expect(FileFormat.matches("SwiftGameEngine.Scene", "Acro.Scene"))
    #expect(!FileFormat.matches("SwiftGameEngine.Save", "Acro.Scene"))
    #expect(!FileFormat.matches(nil, "Acro.Scene"))
}
