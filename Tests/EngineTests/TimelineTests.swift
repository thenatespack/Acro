import Foundation
import Testing
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

// Timelines: the file model, sampling, problems, the importer and hot reload, the screen fade,
// and TimelinePlayer playback (camera, transforms, animation, audio, particles, events, skip).

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("TimelineTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Timeline")
}

private func decode(_ json: String) throws -> Timeline {
    try AssetJSON.decoder().decode(Timeline.self, from: Data(json.utf8))
}

private func close(_ a: Vec3?, _ b: Vec3, _ tolerance: Float = 1e-3) -> Bool {
    guard let a else { return false }
    return length(a - b) <= tolerance
}

@MainActor private func step(_ world: World, _ seconds: Double, dt: Double = 0.1) {
    var left = seconds
    while left > 1e-9 {
        let d = min(dt, left)
        world.update(dt: d)
        left -= d
    }
}

@Suite struct TimelineTests {
    // MARK: File model

    @Test func everyKeyIsOptionalAndUnknownKindsRoundTrip() throws {
        let empty = try decode("{}")
        #expect(empty.duration == 10 && !empty.loop && empty.skippable && empty.tracks.isEmpty)
        let timeline = try decode("""
            {"duration": 4, "tracks": [
              {"id": "cam", "kind": "camera", "keys": [{"position": [0, 1, 2]}, {"time": 2, "fov": 40, "easing": "cubicInOut"}]},
              {"id": "talk", "kind": "subtitles", "keys": [{"time": 1}]},
              {"kind": "event", "keys": [{}]}]}
            """)
        #expect(timeline.tracks.count == 3)
        #expect(timeline.tracks[0].keys[0].time == 0 && timeline.tracks[0].keys[1].easing == .cubicInOut)
        #expect(timeline.tracks[1].trackKind == nil && timeline.tracks[1].kind == "subtitles")
        #expect(timeline.tracks[2].id == "event", "a track without an id takes its kind")
        let again = try AssetJSON.decoder().decode(Timeline.self, from: timeline.fileData())
        #expect(again == timeline)
        let text = String(decoding: try timeline.fileData(), as: UTF8.self)
        #expect(!text.contains("lookAt"), "unset key fields are left out of the file")
        #expect(TimelineCheck.problems(timeline).contains { $0.contains("unknown kind 'subtitles'") })
    }

    @Test func normalizedSortsKeysAndUniqueIDs() {
        var timeline = Timeline(duration: -1, tracks: [TimelineTrack(id: "a", kind: .event, keys: [
            TimelineKey(time: 3, name: "c"), TimelineKey(time: -1, name: "a"), TimelineKey(time: 1, name: "b")])])
        timeline = timeline.normalized()
        #expect(timeline.duration == 0.1)
        #expect(timeline.tracks[0].keys.map(\.name) == ["a", "b", "c"])
        #expect(timeline.tracks[0].keys[0].time == 0)
        #expect(timeline.uniqueTrackID("a") == "a 2" && timeline.uniqueTrackID("b") == "b")
    }

    @Test func sampling() {
        let track = TimelineTrack(id: "t", kind: .transform, keys: [
            TimelineKey(time: 1, position: Vec3(0, 0, 0)),
            TimelineKey(time: 3, easing: .linear, position: Vec3(10, 0, 0), rotation: Vec3(0, 90, 0)),
            TimelineKey(time: 5, easing: .quadIn, position: Vec3(10, 10, 0)),
            TimelineKey(time: 6, position: Vec3(0, 0, 0), cut: true),
        ])
        #expect(close(track.vec3(\.position, at: 0), Vec3(0, 0, 0)), "holds the first key before it")
        #expect(close(track.vec3(\.position, at: 2), Vec3(5, 0, 0)))
        #expect(close(track.vec3(\.position, at: 4), Vec3(10, 2.5, 0)), "eased by the later key")
        #expect(close(track.vec3(\.position, at: 5.9), Vec3(10, 10, 0)), "a cut holds until its time")
        #expect(close(track.vec3(\.position, at: 6), Vec3(0, 0, 0)))
        #expect(close(track.vec3(\.position, at: 99), Vec3(0, 0, 0)), "holds the last key")
        #expect(track.vec3(\.scale, at: 2) == nil)
        let q = track.rotation(at: 2)
        #expect(q.map { abs($0.y) > 0.6 } == true, "a single rotation key holds")

        let fade = TimelineTrack(id: "f", kind: .fade, keys: [TimelineKey(time: 0, amount: 0),
                                                            TimelineKey(time: 2, amount: 1, color: Vec3(1, 1, 1))])
        let mid = fade.fade(at: 1)
        #expect(mid?.amount == 0.5)
        #expect(close(mid?.color, Vec3(0.5, 0.5, 0.5)))
    }

    @Test func firedKeysAreHalfOpenAndInTimeOrder() {
        let timeline = Timeline(duration: 5, tracks: [
            TimelineTrack(id: "e", kind: .event, keys: [TimelineKey(time: 0, name: "start"), TimelineKey(time: 2, name: "mid")]),
            TimelineTrack(id: "f", kind: .event, keys: [TimelineKey(time: 1, name: "one")]),
            TimelineTrack(id: "m", kind: .event, muted: true, keys: [TimelineKey(time: 1, name: "muted")]),
            TimelineTrack(id: "c", kind: .camera, keys: [TimelineKey(time: 1, position: .zero)]),
        ])
        func names(_ keys: [(track: Int, key: Int)]) -> [String?] { keys.map { timeline.tracks[$0.track].keys[$0.key].name } }
        #expect(names(timeline.firedKeys(from: nil, to: 1)) == ["start", "one"])
        #expect(names(timeline.firedKeys(from: 1, to: 2)) == ["mid"])
        #expect(names(timeline.firedKeys(from: 0, to: 0.5)).isEmpty)
    }

    @Test func problems() {
        let timeline = Timeline(duration: 2, tracks: [
            TimelineTrack(id: "a", kind: .audio, keys: [TimelineKey(time: 3, clip: "Sounds/missing.sfx")]),
            TimelineTrack(id: "a", kind: .particles, keys: [TimelineKey(time: 1)]),
            TimelineTrack(id: "c", kind: .camera, keys: [TimelineKey(time: 1, fov: 200, path: [Vec3(1, 1, 1)])]),
            TimelineTrack(id: "e", kind: .event),
        ])
        let problems = TimelineCheck.problems(timeline, assetExists: { _ in false })
        #expect(problems.contains("some tracks share an id"))
        #expect(problems.contains { $0.contains("after the end") })
        #expect(problems.contains { $0.contains("no sound 'Sounds/missing.sfx'") })
        #expect(problems.contains { $0.contains("has no effect") })
        #expect(problems.contains { $0.contains("fov 200") })
        #expect(problems.contains { $0.contains("a path needs a position") })
        #expect(problems.contains("track 'e' has no keys"))
        #expect(TimelineCheck.problems(.starter()).isEmpty)
    }

    // MARK: Fade

    @Test func screenFadeFoldsIntoGrading() throws {
        let half = try #require(ScreenFade(color: Vec3(1, 0, 0), amount: 0.5).applied(to: nil))
        // Grading maps c to c·(gain - lift) + lift: c = 0 → lift, c = 1 → gain.
        #expect(close(half.lift, Vec3(0.5, 0, 0)))
        #expect(close(half.gain, Vec3(1, 0.5, 0.5)))
        #expect(half.tonemapper == .none, "pass-through when the scene has no post-processing")
        let graded = PostProcessSettings(lift: Vec3(0.1, 0.1, 0.1), gain: Vec3(0.9, 0.9, 0.9))
        let full = try #require(ScreenFade(color: Vec3(0, 0, 1), amount: 1).applied(to: graded))
        #expect(close(full.lift, Vec3(0, 0, 1)) && close(full.gain, Vec3(0, 0, 1)), "a full fade is the solid color")
        #expect(ScreenFade(amount: 0).applied(to: graded) == graded)
    }

    @MainActor @Test func resolverAppliesTheStrongestFade() {
        let world = World()
        world.spawn(ScreenFade(color: Vec3(1, 1, 1), amount: 0.2))
        world.spawn(ScreenFade(color: Vec3(0, 0, 0), amount: 0.6))
        let settings = PostFXResolver.resolve(world: world, camera: Camera(), cameraWorld: .identity, assets: nil)
        #expect(close(settings?.gain, Vec3(0.4, 0.4, 0.4)))
    }

    // MARK: Player

    @MainActor @Test func playerPosesCameraAndTransformsAndFiresEvents() throws {
        let world = World()
        let camera = world.spawn(Transform(), Name("Main Camera"), Camera())
        let hero = world.spawn(Transform(), Name("Hero"))
        let timeline = Timeline(duration: 4, tracks: [
            TimelineTrack(id: "cam", kind: .camera, keys: [
                TimelineKey(time: 0, position: Vec3(0, 0, 10), lookAt: Vec3(0, 0, 0), fov: 40),
                TimelineKey(time: 2, position: Vec3(10, 0, 0), lookAt: Vec3(0, 0, 0), fov: 60),
                TimelineKey(time: 3, position: Vec3(0, 5, 0), rotation: Vec3(0, 0, 0), cut: true),
            ]),
            TimelineTrack(id: "walk", kind: .transform, target: "Hero", keys: [
                TimelineKey(time: 0, position: Vec3(0, 0, 0)), TimelineKey(time: 4, position: Vec3(4, 0, 0))]),
            TimelineTrack(id: "fade", kind: .fade, keys: [TimelineKey(time: 3, amount: 0), TimelineKey(time: 4, amount: 1)]),
            TimelineTrack(id: "events", kind: .event, keys: [
                TimelineKey(time: 0, name: "begin"), TimelineKey(time: 1.05, name: "middle", value: "42"),
                TimelineKey(time: 4, name: "end")]),
        ])
        let system = try #require(world.addTimelinePlayers(source: .fixed(["intro": timeline])))
        #expect(world.addTimelinePlayers(source: .fixed([:])) == nil, "installed once")
        var heard: [String] = []
        system.onEvent = { _, event in heard.append(event.name) }
        let director = world.spawn(Name("Director"), TimelinePlayer(timeline: "intro"))

        world.update(dt: 0)
        #expect(world.get(TimelinePlayer.self, for: director)?.state == .playing)
        #expect(world.get(TimelinePlayer.self, for: director)?.events.map(\.name) == ["begin"])
        #expect(close(world.get(Transform.self, for: camera)?.position, Vec3(0, 0, 10)))
        let fov = try #require(world.get(Camera.self, for: camera)?.fovY)
        #expect(abs(fov - 40 * .pi / 180) < 1e-4)

        step(world, 1.1)
        #expect(close(world.get(Transform.self, for: camera)?.position, Vec3(5.5, 0, 4.5), 1e-2))
        let forward = try #require(world.get(Transform.self, for: camera)).rotation * Vec3(0, 0, -1)
        #expect(close(forward, normalize(-Vec3(5.5, 0, 4.5)), 1e-2), "aims at the look-at point")
        #expect(close(world.get(Transform.self, for: hero)?.position, Vec3(1.1, 0, 0), 1e-3))
        #expect(heard == ["begin", "middle"])

        step(world, 1.85)  // 2.95: holding before the cut
        #expect(close(world.get(Transform.self, for: camera)?.position, Vec3(10, 0, 0), 1e-3))
        step(world, 0.1)  // 3.05: cut
        #expect(close(world.get(Transform.self, for: camera)?.position, Vec3(0, 5, 0), 1e-3))
        #expect((world.get(ScreenFade.self, for: director)?.amount ?? 1) < 0.1)

        step(world, 1.5)
        let player = try #require(world.get(TimelinePlayer.self, for: director))
        #expect(player.state == .finished && player.time == 4)
        #expect(heard == ["begin", "middle", "end"])
        #expect(!world.has(ScreenFade.self, for: director), "a finished timeline clears its fade by default")
        #expect(close(world.get(Transform.self, for: hero)?.position, Vec3(4, 0, 0)))

        world.modify(TimelinePlayer.self, for: director) { $0.stop() }
        world.update(dt: 0.1)
        #expect(world.get(TimelinePlayer.self, for: director)?.state == .stopped)
        #expect(!world.has(ScreenFade.self, for: director), "stop clears the fade")
    }

    @MainActor @Test func holdFadeKeepsTheLastFadeAfterTheEnd() throws {
        let world = World()
        var timeline = Timeline(duration: 1, tracks: [
            TimelineTrack(id: "fade", kind: .fade, keys: [TimelineKey(time: 0, amount: 0), TimelineKey(time: 1, amount: 1)])])
        #expect(!String(decoding: try timeline.fileData(), as: UTF8.self).contains("holdFade"), "left out when off")
        timeline.holdFade = true
        let back = try AssetJSON.decoder().decode(Timeline.self, from: timeline.fileData())
        #expect(back.holdFade)
        var clearing = timeline
        clearing.holdFade = false
        world.addTimelinePlayers(source: .fixed(["hold": timeline, "clear": clearing]))
        let holding = world.spawn(TimelinePlayer(timeline: "hold"))
        let clears = world.spawn(TimelinePlayer(timeline: "clear"))
        step(world, 0.5)
        #expect((world.get(ScreenFade.self, for: clears)?.amount ?? 0) > 0.4, "fades while playing")
        step(world, 1)
        #expect(world.get(TimelinePlayer.self, for: holding)?.state == .finished)
        #expect(world.get(ScreenFade.self, for: holding)?.amount == 1, "holdFade keeps it")
        #expect(!world.has(ScreenFade.self, for: clears))
        step(world, 0.5)
        #expect(!world.has(ScreenFade.self, for: clears), "stays cleared")
        // Skipping lands on the end the same way.
        let skipped = world.spawn(TimelinePlayer(timeline: "clear"))
        step(world, 0.5)
        world.modify(TimelinePlayer.self, for: skipped) { $0.skip() }
        world.update(dt: 0.016)
        #expect(world.get(TimelinePlayer.self, for: skipped)?.state == .finished)
        #expect(!world.has(ScreenFade.self, for: skipped))
    }

    @MainActor @Test func parentedCameraKeysAreWorldSpace() throws {
        let world = World()
        let rig = world.spawn(Transform(position: Vec3(10, 0, 0), rotation: Quat(eulerDegrees: Vec3(0, 90, 0)), scale: Vec3(2, 2, 2)),
                              Name("Rig"))
        let camera = world.spawn(Transform(), Name("Shot Camera"), Camera())
        world.setParent(camera, to: rig)
        let timeline = Timeline(duration: 2, tracks: [
            TimelineTrack(id: "cam", kind: .camera, target: "Rig/Shot Camera", keys: [
                TimelineKey(time: 0, position: Vec3(0, 3, 8), lookAt: Vec3(0, 3, 0))])])
        world.addTimelinePlayers(source: .fixed(["t": timeline]))
        world.spawn(TimelinePlayer(timeline: "t"))
        world.update(dt: 0.1)
        let m = world.worldMatrix(of: camera)
        #expect(close(Vec3(m.c3.x, m.c3.y, m.c3.z), Vec3(0, 3, 8), 1e-3), "lands at the key's world position")
        let forward = normalize(Vec3(-m.c2.x, -m.c2.y, -m.c2.z))
        #expect(close(forward, Vec3(0, 0, -1), 1e-3), "aims at the world look-at point")
        // A root camera is unchanged by the conversion.
        let pose = TimelineCameraPose(position: Vec3(1, 2, 3), rotation: .identity, fovDegrees: nil)
        #expect(TimelineEvaluator.localized(pose, for: rig, in: world) == pose)
    }

    @MainActor @Test func dialogueKeysStartConversationsAndWait() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let talk = try DialogueAsset.decode(Data("""
            {"start": "a", "nodes": [
              {"id": "a", "type": "line", "text": "Hello.", "next": "b"},
              {"id": "b", "type": "line", "text": "Goodbye."},
              {"id": "c", "type": "line", "text": "Psst."}]}
            """.utf8))
        _ = try database.createDialogue(talk, at: "Talk/npc.dialogue")
        let world = World()
        let director = world.addDialogueSystem(assets: { database })
        let npc = world.spawn(Transform(), Name("TimelineTests NPC"))
        let mouth = world.spawn(Transform(), DialoguePlayer(dialogue: "Talk/npc.dialogue"))
        world.setParent(mouth, to: npc)
        let timeline = Timeline(duration: 4, tracks: [
            TimelineTrack(id: "talk", kind: .dialogue, target: "TimelineTests NPC", keys: [TimelineKey(time: 1, wait: true)]),
            TimelineTrack(id: "aside", kind: .dialogue, keys: [TimelineKey(time: 3, dialogue: "Talk/npc.dialogue", node: "c")]),
            TimelineTrack(id: "e", kind: .event, keys: [TimelineKey(time: 1, name: "same"), TimelineKey(time: 1.5, name: "after")]),
        ])
        #expect(TimelineCheck.problems(timeline).isEmpty)
        #expect(TimelineCheck.problems(Timeline(tracks: [TimelineTrack(id: "d", kind: .dialogue, keys: [
            TimelineKey(time: 0, dialogue: "Talk/none.dialogue")])]), assetExists: { _ in false }).contains { $0.contains("no dialogue") })
        world.addTimelinePlayers(source: .fixed(["t": timeline]))
        let player = world.spawn(TimelinePlayer(timeline: "t"))

        step(world, 1.5)
        var p = try #require(world.get(TimelinePlayer.self, for: player))
        #expect(p.isWaitingForDialogue && abs(p.time - 1) < 1e-4, "held at the wait key")
        #expect(p.events.isEmpty || p.events.map(\.name) == ["same"])
        #expect(director.activeEntity == mouth, "started on the target's descendant with a DialoguePlayer")
        guard case .line(let line)? = world.dialogue(for: mouth)?.state else { Issue.record("expected a line"); return }
        #expect(line.node == "a")
        step(world, 2)
        #expect(abs((world.get(TimelinePlayer.self, for: player)?.time ?? 0) - 1) < 1e-4, "still waiting")
        world.dialogue(for: mouth)?.advance()
        world.dialogue(for: mouth)?.advance()
        #expect(world.dialogue(for: mouth)?.isActive == false)
        step(world, 0.6)  // 1.6
        p = try #require(world.get(TimelinePlayer.self, for: player))
        #expect(!p.isWaitingForDialogue && p.time > 1.5 && p.time < 1.7, "carries on once the conversation ends")

        // A key with its own file plays on a temporary DialoguePlayer at its node, and doesn't wait.
        step(world, 1.5)  // 3.1
        var temporary: Entity?
        world.query(Name.self) { e, n in if n.value == "Timeline Dialogue" { temporary = e } }
        let aside = try #require(temporary)
        #expect(world.dialogue(for: aside)?.currentNode == "c")
        #expect(world.get(TimelinePlayer.self, for: player)?.isWaitingForDialogue == false)
        world.dialogue(for: aside)?.advance()
        step(world, 0.2)
        #expect(!world.isAlive(aside), "removed when its conversation ends")

        // Skipping stops a conversation the timeline started.
        world.modify(TimelinePlayer.self, for: player) { $0.play(from: 0) }
        step(world, 1.2)
        #expect(world.dialogue(for: mouth)?.isActive == true)
        world.modify(TimelinePlayer.self, for: player) { $0.skip() }
        world.update(dt: 0.016)
        #expect(world.dialogue(for: mouth)?.isActive == false)
        #expect(world.get(TimelinePlayer.self, for: player)?.state == .finished)

        // Without a dialogue system the key does nothing and nothing waits.
        let bare = World()
        bare.spawn(Transform(), Name("TimelineTests NPC"), DialoguePlayer(dialogue: "Talk/npc.dialogue"))
        bare.addTimelinePlayers(source: .fixed(["t": timeline]))
        let lone = bare.spawn(TimelinePlayer(timeline: "t"))
        step(bare, 2)
        #expect(bare.get(TimelinePlayer.self, for: lone)?.isWaitingForDialogue == false)
        #expect((bare.get(TimelinePlayer.self, for: lone)?.time ?? 0) > 1.9)
    }

    @MainActor @Test func pauseResumeSeekLoopAndSkip() throws {
        let world = World()
        let timeline = Timeline(duration: 2, tracks: [
            TimelineTrack(id: "e", kind: .event, keys: [TimelineKey(time: 0.5, name: "a"), TimelineKey(time: 1.5, name: "b")]),
            TimelineTrack(id: "box", kind: .transform, keys: [TimelineKey(time: 0, position: .zero), TimelineKey(time: 2, position: Vec3(2, 0, 0))]),
        ])
        var looping = timeline
        looping.loop = true
        let system = try #require(world.addTimelinePlayers(source: .fixed(["t": timeline, "loop": looping])))
        var heard: [String] = []
        system.onEvent = { _, event in heard.append(event.name) }
        let e = world.spawn(Transform(), TimelinePlayer(timeline: "t", playOnStart: false))

        step(world, 1)
        #expect(world.get(TimelinePlayer.self, for: e)?.state == .stopped, "waits for play()")
        world.modify(TimelinePlayer.self, for: e) { $0.play() }
        step(world, 0.6)
        #expect(heard == ["a"])
        world.modify(TimelinePlayer.self, for: e) { $0.pause() }
        step(world, 1)
        #expect(world.get(TimelinePlayer.self, for: e)?.state == .paused)
        #expect(abs((world.get(TimelinePlayer.self, for: e)?.time ?? 0) - 0.6) < 1e-4)
        world.modify(TimelinePlayer.self, for: e) { $0.seek(to: 1.6) }
        world.update(dt: 0)
        #expect(world.get(TimelinePlayer.self, for: e)?.state == .paused, "seeking keeps it paused")
        world.modify(TimelinePlayer.self, for: e) { $0.resume() }
        step(world, 0.1)
        #expect(heard == ["a"], "seek skipped 'b'")
        #expect(close(world.get(Transform.self, for: e)?.position, Vec3(1.7, 0, 0), 1e-3))

        // Skip: fires the rest and finishes.
        world.modify(TimelinePlayer.self, for: e) { $0.play(from: 0) }
        step(world, 0.2)
        world.modify(TimelinePlayer.self, for: e) { $0.skip() }
        world.update(dt: 0.016)
        let skipped = try #require(world.get(TimelinePlayer.self, for: e))
        #expect(skipped.state == .finished && skipped.didFinish && skipped.time == 2)
        #expect(heard == ["a", "a", "b"])
        #expect(close(world.get(Transform.self, for: e)?.position, Vec3(2, 0, 0)))

        // Looping fires every lap's keys.
        let l = world.spawn(Transform(), TimelinePlayer(timeline: "loop"))
        heard.removeAll()
        step(world, 4.2)
        #expect(heard == ["a", "b", "a", "b"])
        #expect(world.get(TimelinePlayer.self, for: l)?.state == .playing)

        // A timeline that isn't skippable ignores skip.
        var locked = timeline
        locked.skippable = false
        system.source = .fixed(["locked": locked])
        let k = world.spawn(Transform(), TimelinePlayer(timeline: "locked"))
        step(world, 0.2)
        world.modify(TimelinePlayer.self, for: k) { $0.skip() }
        world.update(dt: 0.1)
        #expect(world.get(TimelinePlayer.self, for: k)?.state == .playing)
    }

    @MainActor @Test func cameraPathFollowsTheSpline() {
        let track = TimelineTrack(id: "cam", kind: .camera, keys: [
            TimelineKey(time: 0, position: Vec3(0, 0, 0), path: [Vec3(5, 0, 5)], followPath: true),
            TimelineKey(time: 2, position: Vec3(10, 0, 0)),
        ])
        let start = TimelineEvaluator.cameraPose(track, at: 0, in: nil)
        let middle = TimelineEvaluator.cameraPose(track, at: 1, in: nil)
        let end = TimelineEvaluator.cameraPose(track, at: 2, in: nil)
        #expect(close(start.position, .zero))
        #expect(close(middle.position, Vec3(5, 0, 5), 0.2), "passes through the path point")
        #expect(close(end.position, Vec3(10, 0, 0)))
        let forward = (middle.rotation ?? .identity) * Vec3(0, 0, -1)
        #expect(forward.x > 0.9, "faces the direction of travel")
    }

    @MainActor @Test func animationAudioAndParticleKeys() throws {
        let world = World()
        let hero = world.spawn(Transform(), Name("Hero"))
        let rig = world.spawn(Transform(), Name("Rig"))
        world.setParent(rig, to: hero)
        let clipA = AnimationClipHandle("TimelineTests.idle"), clipB = AnimationClipHandle("TimelineTests.wave")
        world.add(Animator(targets: [], restPose: [], stateMachine: AnimationStateMachine(states: [
            AnimationState("idle", .clip(clipA)), AnimationState("wave", .clip(clipB))])), to: rig)
        let listener = world.spawn(Transform(), AudioListener())
        let effect = PrefabAsset(roots: [PrefabNode(name: "Boom", children: [PrefabNode(name: "Sparks", particles: ParticleEmitter())])])
        let timeline = Timeline(duration: 3, tracks: [
            TimelineTrack(id: "anim", kind: .animation, target: "Hero", keys: [TimelineKey(time: 0.5, clip: "wave", blend: 0, speed: 2)]),
            TimelineTrack(id: "sfx", kind: .audio, keys: [TimelineKey(time: 0.5, clip: "asset:sound", volume: 0.5, duration: 1)]),
            TimelineTrack(id: "fx", kind: .particles, target: "Hero", keys: [TimelineKey(time: 1, position: Vec3(0, 1, 0), effect: "boom")]),
        ])
        world.addTimelinePlayers(source: TimelineAssetSource(
            timeline: { $0 == "t" ? (timeline, 0) : nil },
            sound: { $0 == "asset:sound" ? "asset:0123" : nil },
            effect: { $0 == "boom" ? (effect, 0.5) : nil }))
        let director = world.spawn(TimelinePlayer(timeline: "t"))

        step(world, 0.6)
        #expect(world.get(Animator.self, for: rig)?.currentState == "wave", "plays on the first descendant with an Animator")
        #expect(world.get(Animator.self, for: rig)?.speed == 2)
        var sounds: [(Entity, AudioEmitter)] = []
        world.query(AudioEmitter.self) { sounds.append(($0, $1)) }
        #expect(sounds.count == 1)
        #expect(sounds.first?.1.clip == "asset:0123" && sounds.first?.1.volume == 0.5 && sounds.first?.1.loop == false)
        #expect(sounds.first.map { world.parent(of: $0.0) } == listener, "unpositioned sounds ride on the listener")

        step(world, 0.5)  // 1.1
        #expect(world.count(of: ParticleEmitter.self) == 1)
        var boom: Entity?
        world.query(Name.self) { e, n in if n.value == "Boom" { boom = e } }
        #expect(boom.map { world.parent(of: $0) } == hero)
        #expect(close(boom.flatMap { world.get(Transform.self, for: $0)?.position }, Vec3(0, 1, 0)))

        step(world, 0.6)  // 1.7: the effect's 0.5 s and the sound's 1 s are over
        #expect(world.count(of: ParticleEmitter.self) == 0)
        #expect(world.count(of: AudioEmitter.self) == 0)
        #expect(world.get(TimelinePlayer.self, for: director)?.state == .playing)
    }

    @MainActor @Test func targetsByNameAndPath() {
        let world = World()
        let a = world.spawn(Transform(), Name("Ship"))
        let b = world.spawn(Transform(), Name("Turret"))
        world.setParent(b, to: a)
        let other = world.spawn(Transform(), Name("Turret"))
        #expect(TimelineEvaluator.find("Turret", in: world) == b, "the lowest index wins")
        #expect(TimelineEvaluator.find("Ship/Turret", in: world) == b)
        #expect(TimelineEvaluator.find("Nope/Turret", in: world) == nil)
        #expect(TimelineEvaluator.find("", in: world) == nil)
        _ = other
    }

    // MARK: Importer and hot reload

    @MainActor @Test func importerWarnsAndPlayersFollowEdits() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        var timeline = Timeline(duration: 2, tracks: [
            TimelineTrack(id: "box", kind: .transform, keys: [TimelineKey(time: 0, position: Vec3(1, 0, 0))]),
            TimelineTrack(id: "sfx", kind: .audio, keys: [TimelineKey(time: 1, clip: "Sounds/missing.sfx")]),
        ])
        let id = try database.createTimeline(timeline, at: "Cutscenes/intro.timeline")
        #expect(database.record(id)?.importer == "timeline")
        #expect(database.record(id)?.importError == nil)
        #expect(database.timeline(of: id) == timeline)
        #expect(database.timelineID(forKey: "Assets/Cutscenes/intro.timeline") == id)
        #expect(database.timelineID(forKey: AssetReference(id).description) == id)
        #expect(database.timelineProblems(timeline).contains { $0.contains("no sound 'Sounds/missing.sfx'") })

        let world = World()
        world.addTimelinePlayers(assets: { database })
        let box = world.spawn(Transform(), TimelinePlayer(timeline: "Cutscenes/intro.timeline"))
        world.update(dt: 0.1)
        #expect(close(world.get(Transform.self, for: box)?.position, Vec3(1, 0, 0)))

        timeline.tracks[0].keys[0].position = Vec3(0, 3, 0)
        timeline.tracks.remove(at: 1)
        let warnings = try database.writeTimeline(timeline, to: id)
        #expect(warnings.isEmpty, "\(warnings)")
        world.update(dt: 0.1)
        #expect(close(world.get(Transform.self, for: box)?.position, Vec3(0, 3, 0)), "hot reload")

        try Data("not json".utf8).write(to: project.assetsURL.appendingPathComponent("Cutscenes/bad.timeline"))
        database.refresh()
        let bad = try #require(database.id(forPath: "Cutscenes/bad.timeline"))
        #expect(database.record(bad)?.importError != nil)
        #expect(database.timeline(of: bad) == nil)
    }

    @MainActor @Test func playerSerializesItsSettingsOnly() throws {
        var player = TimelinePlayer(timeline: "a.timeline", playOnStart: false, speed: 2, loop: true)
        player.time = 3
        let data = try JSONEncoder().encode(player)
        let back = try JSONDecoder().decode(TimelinePlayer.self, from: data)
        #expect(back.timeline == "a.timeline" && !back.playOnStart && back.speed == 2 && back.loop && back.time == 0)
        let defaults = try JSONDecoder().decode(TimelinePlayer.self, from: Data("{}".utf8))
        #expect(defaults.playOnStart && defaults.speed == 1)
    }
}
