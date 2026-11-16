import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// The timeline builder as an agent uses it (timeline.* tools) and as a user does (view / workspace).

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("TimelineToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct TimelineToolsTests {
    @Test func newEditGetSampleAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])

        let created = try call(session, "timeline.new", ["duration": 6, "folder": "Cutscenes", "name": "Intro", "place": true])
        #expect(created["path"] as? String == "Cutscenes/Intro.timeline")
        #expect(created["duration"] as? Double == 6)
        #expect(created["tracks"] as? [String] == ["camera (camera, 2 keys)"])
        #expect((created["warnings"] as? [String])?.isEmpty == true, "\(created["warnings"] ?? "")")
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isTimelineFile(id))
        #expect(session.world.count(of: TimelinePlayer.self) == 1, "place adds a player")
        var player: TimelinePlayer?
        session.world.query(TimelinePlayer.self) { _, p in player = p }
        #expect(player?.timeline == created["key"] as? String)

        let edited = try call(session, "timeline.edit", [
            "path": "Cutscenes/Intro.timeline",
            "addTracks": [["id": "fade", "kind": "fade", "keys": [["time": 5, "amount": 0], ["time": 6, "amount": 1]]],
                          ["id": "camera", "kind": "event"]],
            "addKeys": [["track": "camera", "time": 3, "position": [0, 5, 5], "cut": true],
                        ["track": "camera 2", "time": 6, "name": "introDone", "value": "x"]],
            "updateTracks": ["fade": ["name": "Fade Out"]],
        ])
        #expect(edited["tracks"] as? [String] == ["camera (camera, 3 keys)", "fade (fade, 2 keys)", "camera 2 (event, 1 key)"])
        var timeline = try #require(session.assets?.timeline(of: id))
        #expect(timeline.tracks[0].keys.map(\.time) == [0, 3, 6], "keys stay sorted")
        #expect(timeline.tracks[1].name == "Fade Out")

        try call(session, "timeline.edit", [
            "asset": id.description,
            "removeKeys": [["track": "camera", "index": 0]],
            "updateKeys": [["track": "camera", "time": 3, "set": ["cut": NSNull(), "fov": 30]]],
            "removeTracks": ["camera 2"], "loop": true,
        ])
        timeline = try #require(session.assets?.timeline(of: id))
        #expect(timeline.loop && timeline.tracks.count == 2)
        #expect(timeline.tracks[0].keys.count == 2 && timeline.tracks[0].keys[0].cut == nil && timeline.tracks[0].keys[0].fov == 30)

        let sample = try call(session, "timeline.sample", ["asset": id.description, "time": 5.5])
        let tracks = try #require(sample["tracks"] as? [[String: Any]])
        #expect((tracks.first { $0["track"] as? String == "fade" }?["fadeAmount"] as? Double).map { abs($0 - 0.5) < 1e-4 } == true)
        #expect(tracks.first?["position"] != nil)

        let got = try call(session, "timeline.get", ["asset": id.description])
        #expect(((got["timeline"] as? [String: Any])?["tracks"] as? [Any])?.count == 2)

        #expect(session.performUndo())
        #expect(session.assets?.timeline(of: id)?.tracks.count == 3)
        #expect(throws: (any Error).self) { try call(session, "timeline.edit", ["asset": id.description, "removeTracks": ["nope"]]) }
        #expect(throws: (any Error).self) {
            try call(session, "timeline.edit", ["asset": id.description, "addTracks": [["id": "x", "kind": "dialogue"]]])
        }
        #expect(throws: (any Error).self) {
            try call(session, "timeline.edit", ["asset": id.description, "removeKeys": [["track": "camera", "time": 99]]])
        }

        // Missing sounds come back as warnings.
        let warned = try call(session, "timeline.edit", ["asset": id.description,
                                                          "addTracks": [["id": "sfx", "kind": "audio", "keys": [["time": 1, "clip": "Sounds/none.sfx"]]]]])
        #expect((warned["warnings"] as? [String])?.contains { $0.contains("no sound 'Sounds/none.sfx'") } == true)
    }

    @Test func playModePlaysThePlacedTimeline() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        session.world.spawn(Transform(), Name("TimelineToolsTests Box"))
        let timeline = Timeline(duration: 2, tracks: [
            TimelineTrack(id: "box", kind: .transform, target: "TimelineToolsTests Box", keys: [
                TimelineKey(time: 0, position: .zero), TimelineKey(time: 2, position: Vec3(2, 0, 0))])])
        let id = try #require(session.createTimelineAsset(in: "", name: "Move", timeline: timeline))
        try #require(session.addTimelinePlayer(for: id) != nil)
        try call(session, "play.start")
        for _ in 0..<10 { session.tick(dt: 0.1) }
        var box: Entity?
        session.world.query(Name.self) { e, n in if n.value == "TimelineToolsTests Box" { box = e } }
        let x = box.flatMap { session.world.get(Transform.self, for: $0)?.position.x } ?? 0
        #expect(x > 0.5, "moved by the timeline while playing (x = \(x))")
        try call(session, "play.stop")
        let after = box.flatMap { session.world.get(Transform.self, for: $0)?.position.x }
        #expect(after == nil || after == 0, "stop restores the scene")
    }

    @Test func viewAndWorkspace() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        session.world.spawn(Transform(position: Vec3(0, 1, 5)), Name("TimelineToolsTests Camera"), Camera())
        let id = try #require(session.createTimelineAsset(in: "", name: "Cut", timeline: .starter(duration: 4)))

        let view = try #require(TimelineBuilderView(session: session, asset: id))
        let undoBefore = session.undo.changeCount
        view.addTrack(.fade)
        view.refresh()
        #expect(view.timeline.tracks.map(\.id) == ["camera", "fade"])
        #expect(view.selectedTrack == "fade" && view.selectedKey == 0)
        #expect(session.undo.changeCount == undoBefore + 1, "one undo step")
        view.playhead = 2
        view.addKey(to: "camera")
        view.refresh()
        let camera = try #require(view.timeline.track(id: "camera"))
        #expect(camera.keys.map(\.time) == [0, 2, 4])
        #expect(camera.keys[1].position != nil, "a new key holds the track's pose there")
        view.moveKey("camera", 1, to: 3)
        view.refresh()
        #expect(view.timeline.track(id: "camera")?.keys.map(\.time) == [0, 3, 4])
        #expect(view.selectedKey == 1)
        view.deleteSelectedKey()
        view.refresh()
        #expect(view.timeline.track(id: "camera")?.keys.count == 2)
        view.select(track: "fade", key: nil)
        view.deleteTrack()
        view.refresh()
        #expect(view.timeline.tracks.map(\.id) == ["camera"])
        #expect(session.performUndo())
        view.reload()
        #expect(view.timeline.tracks.count == 2)
        #expect(TimelineBuilderView.setFields(of: TimelineKey(time: 1, fov: 3)) == ["fov"])

        let workspace = TimelineWorkspace(session: session)
        var opened: AssetID?
        session.onOpenTimeline = { opened = $0; workspace.open($0) }
        try call(session, "timeline.open", ["asset": id.description])
        #expect(opened == id && workspace.asset == id)
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.world.count(of: Camera.self) == session.world.count(of: Camera.self), "the preview copies the scene")
        let previewCamera = try #require(workspace.timelineCamera())
        workspace.scrub(to: 0)
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.world.get(Transform.self, for: previewCamera)?.position == Vec3(0, 2, 10), "posed at the playhead")
        var scenePositions: [Vec3] = []
        session.world.query(Camera.self) { e, _ in scenePositions += [session.world.get(Transform.self, for: e)?.position ?? .zero] }
        #expect(!scenePositions.contains(Vec3(0, 2, 10)), "the scene itself is untouched")
        workspace.setPlaying(true)
        for _ in 0..<30 { workspace.update(input: nil, dt: 0.1) }
        #expect(workspace.playhead > 0 && workspace.isPlaying, "loops by default")
        workspace.setLooping(false)
        for _ in 0..<60 { workspace.update(input: nil, dt: 0.1) }
        #expect(!workspace.isPlaying && workspace.playhead == 4)
        workspace.close()
        #expect(workspace.asset == nil)
    }

    @Test func stripMapsTimeAndHitsKeys() {
        let strip = TimelineStripView()
        strip.tracks = [TimelineTrack(id: "e", kind: .event, keys: [TimelineKey(time: 5, name: "a")])]
        strip.duration = 10
        strip.layout(in: UIRect(x: 0, y: 0, width: 528, height: 100))
        // Lane: x 120 ... 520.
        #expect(abs(strip.x(of: 5) - 320) < 0.01)
        #expect(abs(strip.time(at: 220) - 2.5) < 0.01)
        let y = TimelineStripView.rulerHeight + TimelineStripView.rowHeight / 2
        #expect(strip.key(at: Vec2(322, y))?.key == 0)
        #expect(strip.key(at: Vec2(340, y)) == nil)
        var scrubbed: Float?
        strip.onScrub = { scrubbed = $0 }
        _ = strip.handleEvent(.pointerDown(PointerEvent(position: Vec2(420, 5))))
        #expect(scrubbed.map { abs($0 - 7.5) < 0.01 } == true)
        var moved: (String, Int, Float)?
        strip.onMoveKey = { moved = ($0, $1, $2) }
        _ = strip.handleEvent(.pointerUp(PointerEvent(position: Vec2(420, 5))))
        _ = strip.handleEvent(.pointerDown(PointerEvent(position: Vec2(320, y))))
        _ = strip.handleEvent(.pointerDrag(PointerEvent(position: Vec2(359, y))))
        _ = strip.handleEvent(.pointerUp(PointerEvent(position: Vec2(359, y))))
        #expect(moved?.0 == "e" && moved?.1 == 0 && moved.map { abs($0.2 - 6) < 0.001 } == true, "snapped to 0.05 s")
    }
}
