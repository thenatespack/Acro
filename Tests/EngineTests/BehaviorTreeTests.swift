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

// Behavior trees: the file model, validation, editing, presets, the importer and the runtime
// (composites, decorators, movement leaves, attacks, custom leaves, hot reload).

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("BehaviorTreeTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "BehaviorTree")
}

private func decode(_ json: String) throws -> BehaviorTree {
    try AssetJSON.decoder().decode(BehaviorTree.self, from: Data(json.utf8))
}

/// A world running behavior trees, with a unique library name for `tree`.
@MainActor private func makeWorld(_ tree: BehaviorTree, name: String = #function) -> (World, String) {
    let world = World()
    world.assignsEntityIDs = true
    let key = "BehaviorTreeTests.\(name)"
    BehaviorTreeLibrary.register(tree, as: key)
    world.addBehaviorTrees()
    return (world, key)
}

@MainActor private func step(_ world: World, _ frames: Int, dt: Double = 1.0 / 60) {
    for _ in 0..<frames { world.update(dt: dt) }
}

@Suite struct BehaviorTreeTests {
    // MARK: Format

    @Test func decodesFlatParametersAndRoundTrips() throws {
        let tree = try decode("""
        {"root": "r", "nodes": [
          {"id": "r", "type": "selector", "children": ["w"]},
          {"id": "w", "type": "wait", "seconds": 2, "name": "Pause"}
        ], "blackboard": {"health": 50, "home": [1, 0, 2]}, "speed": 4}
        """)
        #expect(tree.nodes[1].params["seconds"] == .int(2))
        #expect(tree.nodes[1].name == "Pause")
        #expect(tree.nodes[1].number("seconds") == 2)
        #expect(tree.nodes[0].bool("memory") == false, "selector default")
        #expect(tree.speed == 4 && tree.turnSpeed == 10 && tree.tickRate == 0)
        let again = try AssetJSON.decoder().decode(BehaviorTree.self, from: tree.fileData())
        #expect(again == tree)
        // Every key is optional.
        let empty = try decode("{}")
        #expect(empty.nodes.isEmpty && empty.rootID == nil && empty.speed == 3)
        let bare = try decode("{\"nodes\": [{}]}")
        #expect(bare.nodes[0].type == "sequence")
    }

    @Test func rootDefaultsToTheFirstUnparentedNode() {
        let tree = BehaviorTree(nodes: [BehaviorNode("w", .wait), BehaviorNode("s", .sequence, children: ["w"])])
        #expect(tree.rootID == "s")
        #expect(tree.outline().map(\.id) == ["s", "w"])
        #expect(tree.outline().map(\.depth) == [0, 1])
    }

    @Test func validationReportsProblems() {
        let tree = BehaviorTree(root: "root", nodes: [
            BehaviorNode("root", .selector, children: ["a", "missing", "inv"]),
            BehaviorNode("a", .sequence, children: ["leaf", "leaf2"]),
            BehaviorNode("leaf", .wait, ["seconds": .string("soon"), "bogus": .int(1)]),
            BehaviorNode("leaf2", .patrol),
            BehaviorNode("inv", .invert, children: ["leaf", "c"]),
            BehaviorNode(id: "c", type: "dance"),
            BehaviorNode("loop", .sequence, children: ["loop2"]),
            BehaviorNode("loop2", .succeed, children: ["loop"]),
            BehaviorNode("custom", .custom),
            BehaviorNode("hb", .healthBelow),
        ])
        let messages = tree.validate().map(\.description)
        func has(_ text: String) -> Bool { messages.contains { $0.contains(text) } }
        #expect(has("node 'root': no child node 'missing'"))
        #expect(has("node 'leaf': seconds: expected a number"))
        #expect(has("unknown parameter 'bogus'"))
        #expect(has("node 'leaf2': needs `points`"))
        #expect(has("node 'inv': a invert needs exactly one child"))
        #expect(has("node 'leaf': has two parents"))
        #expect(has("unknown type 'dance'"))
        #expect(has("node 'loop': is not connected"))
        #expect(has("node 'custom': a custom node needs `leaf`"))
        #expect(has("the blackboard has no 'health'"))
        #expect(BehaviorTree.preset(.guardian).validate().isEmpty)
        for preset in BehaviorPreset.allCases { #expect(BehaviorTree.preset(preset).validate().isEmpty, "\(preset)") }
        let cyclic = BehaviorTree(root: "a", nodes: [BehaviorNode("a", .sequence, children: ["b"]), BehaviorNode("b", .sequence, children: ["a"])])
        #expect(cyclic.validate().contains { $0.description.contains("cycle") || $0.description.contains("lists the root") })
        let leaves = BehaviorTree(nodes: [BehaviorNode("c", .custom, ["leaf": .string("nope")])])
        #expect(leaves.validate(customLeaves: ["other"]).contains { $0.message.contains("no custom leaf 'nope'") })
    }

    // MARK: Editing

    @Test func editAddsConnectsUpdatesAndRemoves() throws {
        let tree = BehaviorTree.preset(.empty)
        let edited = try tree.applying(BehaviorTreeEdit(
            addNodes: [BehaviorNode("low", .healthBelow, ["value": .int(20)]), BehaviorNode("idle", .flee),
                       BehaviorNode("escape", .sequence, children: ["low", "idle"])],
            updateNodes: ["idle": .object(["safeDistance": .int(8)])],
            connect: [BehaviorConnection(parent: "root", child: "escape", index: 0)],
            blackboard: ["health": .int(100)], tickRate: 5))
        // "idle" was taken, so the flee node became "idle2" and the sequence's child followed.
        #expect(edited.node("escape")?.children == ["low", "idle2"])
        #expect(edited.node("idle2")?.params["safeDistance"] == .int(8))
        #expect(edited.node("root")?.children == ["escape", "idle"])
        #expect(edited.blackboard["health"] == .int(100))
        #expect(edited.tickRate == 5)
        #expect(edited.validate().isEmpty, "\(edited.validate())")

        let renamed = try edited.applying(BehaviorTreeEdit(updateNodes: ["escape": .object(["id": .string("run"), "name": .string("Run away")])]))
        #expect(renamed.node("root")?.children.first == "run")
        #expect(renamed.node("run")?.name == "Run away")

        let moved = try renamed.applying(BehaviorTreeEdit(connect: [BehaviorConnection(parent: "root", child: "run")]))
        #expect(moved.node("root")?.children == ["idle", "run"])
        let removed = try moved.applying(BehaviorTreeEdit(removeNodes: ["run"], blackboard: ["health": .null]))
        #expect(removed.node("run") == nil && removed.node("root")?.children == ["idle"])
        #expect(removed.blackboard.isEmpty)

        #expect(throws: BehaviorTreeEditError.cycle(parent: "low", child: "escape")) {
            _ = try edited.applying(BehaviorTreeEdit(connect: [BehaviorConnection(parent: "low", child: "escape")]))
        }
        #expect(throws: BehaviorTreeEditError.noNode("ghost")) { _ = try tree.applying(BehaviorTreeEdit(removeNodes: ["ghost"])) }

        var direct = BehaviorTree()
        let root = direct.addNode(.selector, under: nil)
        let a = direct.addNode(.wait, under: root)
        let b = direct.addNode(.wait, under: root)
        #expect(direct.rootID == root && direct.node(root)?.children == [a, b])
        direct.moveNode(b, by: -1)
        #expect(direct.node(root)?.children == [b, a])
        direct.removeSubtree(root)
        #expect(direct.nodes.isEmpty)
    }

    // MARK: Importer

    @MainActor @Test func importerWarnsAndDatabaseReadsAndReloads() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        var tree = BehaviorTree.preset(.patrol)
        let id = try database.createBehaviorTree(tree, at: "AI/guard.behavior")
        #expect(database.record(id)?.importer == "behavior")
        #expect(database.isBehaviorTree(id))
        #expect(database.behaviorTreeContents(of: id) == tree)
        #expect(database.behaviorTreeID(for: "AI/guard.behavior") == id)
        #expect(database.behaviorTreeID(for: "Assets/AI/guard.behavior") == id)
        #expect(database.behaviorTreeID(for: AssetReference(id).description) == id)
        #expect(database.behaviorTreeReferences() == [AssetReference(id)])
        let first = try #require(database.behaviorTreeRevision("AI/guard.behavior"))

        tree.nodes.append(BehaviorNode("loose", .wait))
        let warnings = try database.writeBehaviorTree(tree, to: id)
        #expect(warnings.contains { $0.contains("node 'loose': is not connected") }, "\(warnings)")
        let second = try #require(database.behaviorTree("AI/guard.behavior"))
        #expect(second.revision > first.revision)
        #expect(second.tree.node("loose") != nil)

        try Data("not json".utf8).write(to: project.assetsURL.appendingPathComponent("AI/broken.behavior"))
        database.refresh()
        let broken = try #require(database.id(forPath: "AI/broken.behavior"))
        #expect(database.record(broken)?.importError != nil)
    }

    // MARK: Runtime

    @MainActor @Test func sequenceSelectorAndCustomLeaves() throws {
        var calls: [String] = []
        BehaviorTreeLeaves.register("BehaviorTreeTests.fail") { leaf in calls.append("fail:\(leaf.node.id)"); return .failure }
        BehaviorTreeLeaves.register("BehaviorTreeTests.ok") { leaf in
            calls.append("ok:\(leaf.node.id)")
            leaf[blackboard: "seen"] = .number((leaf[blackboard: "seen"]?.number ?? 0) + 1)
            return .success
        }
        BehaviorTreeLeaves.register("BehaviorTreeTests.run") { leaf in
            calls.append("run:\(leaf.node.id):\(leaf.isFirstTick)")
            return .running
        }
        defer {
            for name in ["fail", "ok", "run"] { BehaviorTreeLeaves.unregister("BehaviorTreeTests.\(name)") }
        }
        let tree = BehaviorTree(root: "root", nodes: [
            BehaviorNode("root", .selector, children: ["first", "second"]),
            BehaviorNode("first", .sequence, children: ["a", "b"]),
            BehaviorNode("a", .custom, ["leaf": .string("BehaviorTreeTests.ok")]),
            BehaviorNode("b", .custom, ["leaf": .string("BehaviorTreeTests.fail")]),
            BehaviorNode("second", .custom, ["leaf": .string("BehaviorTreeTests.run")]),
        ])
        let (world, key) = makeWorld(tree)
        let npc = world.spawn(Transform(), BehaviorTreeRunner(tree: key))
        step(world, 1)
        #expect(calls == ["ok:a", "fail:b", "run:second:true"])
        let state = try #require(world.get(BehaviorTreeState.self, for: npc))
        #expect(state.rootStatus == .running)
        #expect(state.status(of: "first") == .failure)
        #expect(state.status(of: "second") == .running)
        #expect(state.runningPath == ["root", "second"])
        #expect(world.blackboardValue("seen", for: npc) == .number(1))
        calls = []
        step(world, 1)
        #expect(calls == ["ok:a", "fail:b", "run:second:false"], "the selector re-checks earlier children; the running leaf continues")

        // A missing custom leaf fails and is reported.
        BehaviorTreeLibrary.register(BehaviorTree(nodes: [BehaviorNode("x", .custom, ["leaf": .string("BehaviorTreeTests.none")])]), as: key)
        step(world, 1)
        let after = try #require(world.get(BehaviorTreeState.self, for: npc))
        #expect(after.rootStatus == .failure)
        #expect(after.problems.contains { $0.contains("no custom leaf 'BehaviorTreeTests.none'") })
        #expect(after.blackboard["seen"] == .number(2), "the blackboard survives a tree reload")
    }

    @MainActor @Test func waitRepeatCooldownAndInvert() throws {
        var repeated = 0
        var cooled = 0
        BehaviorTreeLeaves.register("BehaviorTreeTests.repeated") { _ in repeated += 1; return .success }
        BehaviorTreeLeaves.register("BehaviorTreeTests.cooled") { _ in cooled += 1; return .success }
        BehaviorTreeLeaves.register("BehaviorTreeTests.forever") { _ in .running }
        defer { for name in ["repeated", "cooled", "forever"] { BehaviorTreeLeaves.unregister("BehaviorTreeTests.\(name)") } }

        // wait, then set a flag.
        let timed = BehaviorTree(root: "root", nodes: [
            BehaviorNode("root", .sequence, children: ["pause", "flag"]),
            BehaviorNode("pause", .wait, ["seconds": .double(0.5)]),
            BehaviorNode("flag", .setBlackboard, ["key": .string("done"), "value": .bool(true)]),
        ])
        // repeat 3 times through two inverts, then run forever.
        let repeating = BehaviorTree(root: "root", nodes: [
            BehaviorNode("root", .sequence, children: ["three", "stay"]),
            BehaviorNode("three", .repeat, children: ["not"], ["count": .int(3)]),
            BehaviorNode("not", .invert, children: ["inner"]),
            BehaviorNode("inner", .invert, children: ["leaf"]),
            BehaviorNode("leaf", .custom, ["leaf": .string("BehaviorTreeTests.repeated")]),
            BehaviorNode("stay", .custom, ["leaf": .string("BehaviorTreeTests.forever")]),
        ])
        // a cooldown of 0.25 s over a leaf, ticked every 0.1 s.
        let cooling = BehaviorTree(root: "gate", nodes: [
            BehaviorNode("gate", .cooldown, children: ["leaf"], ["seconds": .double(0.25)]),
            BehaviorNode("leaf", .custom, ["leaf": .string("BehaviorTreeTests.cooled")]),
        ])
        let (world, key) = makeWorld(timed)
        BehaviorTreeLibrary.register(repeating, as: key + ".repeat")
        BehaviorTreeLibrary.register(cooling, as: key + ".cooldown")
        let npc = world.spawn(Transform(), BehaviorTreeRunner(tree: key))
        world.spawn(Transform(), BehaviorTreeRunner(tree: key + ".repeat"))
        world.spawn(Transform(), BehaviorTreeRunner(tree: key + ".cooldown"))
        step(world, 4, dt: 0.1)
        #expect(world.blackboardValue("done", for: npc) == nil)
        step(world, 3, dt: 0.1)
        #expect(world.blackboardValue("done", for: npc) == .bool(true))
        #expect(repeated == 3)
        step(world, 3, dt: 0.1)  // 1 s in all: hits at 0.1, 0.4, 0.7, 1.0
        #expect(cooled >= 3 && cooled <= 5, "\(cooled)")
        #expect(repeated == 3)
    }

    @MainActor @Test func patrolWalksThePointsAndWaits() throws {
        let tree = BehaviorTree(root: "p", nodes: [
            BehaviorNode("p", .patrol, ["points": .array([.array([.int(2), .int(0), .int(0)]), .array([.int(2), .int(0), .int(2)])]),
                                        "relative": .bool(true), "loop": .bool(false), "wait": .double(0.2), "arriveDistance": .double(0.02)]),
        ], speed: 4, turnSpeed: 0)
        let (world, key) = makeWorld(tree)
        let npc = world.spawn(Transform(position: Vec3(10, 0, 0)), BehaviorTreeRunner(tree: key))
        step(world, 30)  // 0.5 s at 4 m/s: reached the first point (2 m away)
        let position = try #require(world.get(Transform.self, for: npc)?.position)
        #expect(abs(position.x - 12) < 0.05 && abs(position.z) < 0.05, "\(position)")
        step(world, 48)  // waits 0.2 s, walks 2 m; a finished tree would start over and walk back
        let end = try #require(world.get(Transform.self, for: npc)?.position)
        #expect(abs(end.x - 12) < 0.05 && abs(end.z - 2) < 0.05, "\(end)")
        #expect(world.get(BehaviorTreeState.self, for: npc)?.rootStatus != nil)
    }

    @MainActor @Test func guardSeesChasesAndAttacks() throws {
        let tree = BehaviorTree.preset(.guardian)
        let (world, key) = makeWorld(tree)
        let player = world.spawn(Transform(position: Vec3(0, 0, -6)), Name("Player"),
                                 BehaviorTreeRunner(tree: "BehaviorTreeTests.none", isRunning: false))
        world.setBlackboardValue(.number(100), forKey: "health", of: player)
        let guardEntity = world.spawn(Transform(), BehaviorTreeRunner(tree: key, target: world.ref(to: player)))
        step(world, 1)
        var state = try #require(world.get(BehaviorTreeState.self, for: guardEntity))
        #expect(state.status(of: "see") == .success)
        #expect(state.status(of: "chase") == .running)
        #expect(state.blackboard["lastSeenPosition"] == .vector(Vec3(0, 0, -6)))
        step(world, 120)
        state = try #require(world.get(BehaviorTreeState.self, for: guardEntity))
        let guardPosition = try #require(world.get(Transform.self, for: guardEntity)?.position)
        #expect(guardPosition.z < -4, "walked to the player: \(guardPosition)")
        let health = world.blackboardValue("health", for: player)?.number ?? 100
        #expect(health < 100, "attacked: \(health)")

        // Behind the guard (outside its field of view) and far away: it patrols instead.
        world.modify(Transform.self, for: player) { $0.position = Vec3(0, 0, 40) }
        step(world, 2)
        state = try #require(world.get(BehaviorTreeState.self, for: guardEntity))
        #expect(state.status(of: "see") == .failure)
        #expect(state.status(of: "patrol") == .running)

        // Hurt: it flees.
        world.modify(Transform.self, for: player) { $0.position = guardPosition + Vec3(0, 0, -3) }
        world.setBlackboardValue(.number(10), forKey: "health", of: guardEntity)
        step(world, 2)
        state = try #require(world.get(BehaviorTreeState.self, for: guardEntity))
        #expect(state.status(of: "flee") == .running)
        #expect(state.runningPath == ["root", "retreat", "flee"])
    }

    @MainActor @Test func eventsTickRateAndStoppedRunners() throws {
        let tree = BehaviorTree(root: "root", nodes: [
            BehaviorNode("root", .sequence, children: ["near", "hit"]),
            BehaviorNode("near", .withinRange, ["range": .int(3)]),
            BehaviorNode("hit", .attack, ["range": .int(3), "damage": .int(5), "cooldown": .int(10)]),
        ], tickRate: 10)
        let (world, key) = makeWorld(tree)
        let dummy = world.spawn(Transform(position: Vec3(1, 0, 0)), Name("Dummy"))
        let npc = world.spawn(Transform(), BehaviorTreeRunner(tree: key, blackboard: [BehaviorBlackboardEntry(key: "target", value: "Dummy")]))
        step(world, 1)
        let state = try #require(world.get(BehaviorTreeState.self, for: npc))
        #expect(state.events == [BehaviorEvent(name: "attack", node: "hit", target: dummy, amount: 5)])
        #expect(state.blackboard["target"] == .text("Dummy"))
        step(world, 1)
        #expect(world.get(BehaviorTreeState.self, for: npc)?.events.isEmpty == true, "events last one frame")
        step(world, 58)  // one second at 10 ticks a second
        let ticks = try #require(world.get(BehaviorTreeState.self, for: npc)?.tickCount)
        #expect(ticks >= 10 && ticks <= 12, "\(ticks)")

        world.modify(BehaviorTreeRunner.self, for: npc) { $0.isRunning = false }
        step(world, 30)
        #expect(world.get(BehaviorTreeState.self, for: npc)?.tickCount == ticks)
    }

    @MainActor @Test func runsAssetTreesAndFollowsHotReload() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let tree = BehaviorTree(nodes: [BehaviorNode("go", .moveTo, ["position": .array([.int(5), .int(0), .int(0)]), "arriveDistance": .double(0.02)])], speed: 10)
        let id = try database.createBehaviorTree(tree, at: "AI/mover.behavior")
        let world = World()
        world.addBehaviorTrees(assets: { database })
        let npc = world.spawn(Transform(), BehaviorTreeRunner(tree: AssetReference(id).description))
        step(world, 60)
        #expect(abs((world.get(Transform.self, for: npc)?.position.x ?? 0) - 5) < 0.05)

        var moved = tree
        moved.nodes[0].params["position"] = .array([.int(-5), .int(0), .int(0)])
        try database.writeBehaviorTree(moved, to: id)
        step(world, 120)
        #expect(abs((world.get(Transform.self, for: npc)?.position.x ?? 0) + 5) < 0.05, "the edited tree runs")
    }
}
