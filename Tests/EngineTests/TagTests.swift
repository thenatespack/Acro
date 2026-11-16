import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets

// The Tag component: cleaning, world helpers, scene files, inspector edits and visual script nodes.

@MainActor
@Suite struct TagTests {
    @Test func tagsAreCleanedAndUnique() {
        var tag = Tags(" enemy ", "boss", "enemy", "", "a,b")
        #expect(tag.tags == ["enemy", "boss", "a b"])
        tag.insert("pickup")
        tag.remove("boss")
        #expect(tag.tags == ["enemy", "a b", "pickup"] && tag.contains(" pickup"))
        #expect(Tags.parse(" x, , y ,x") == ["x", "y", "x"])
        #expect(Tags(tags: Tags.parse(" x, , y ,x")).tags == ["x", "y"])
    }

    @Test func worldHelpersFindAddAndRemove() {
        let world = World()
        let a = world.spawn(Transform(), Tags("enemy"))
        let b = world.spawn(Transform())
        let c = world.spawn(Transform(), Tags("enemy", "boss"))
        #expect(world.entities(taggedWith: "enemy") == [a, c])
        #expect(world.firstEntity(taggedWith: "boss") == c)
        #expect(world.firstEntity(taggedWith: "nobody") == nil)
        world.addTag("enemy", to: b)
        #expect(world.hasTag("enemy", b) && world.entities(taggedWith: "enemy").count == 3)
        world.removeTag("enemy", from: b)
        #expect(!world.has(Tags.self, for: b), "the last tag removes the component")
        world.removeTag("enemy", from: c)
        #expect(world.get(Tags.self, for: c)?.tags == ["boss"])
    }

    @Test func savedWithScenesAndEditedAsText() throws {
        let world = World()
        let e = world.spawn(Transform(), Name("Ogre"), Tags("enemy", "boss"))
        let data = try world.save()
        #expect(String(decoding: data, as: UTF8.self).contains("enemy, boss"), "one comma-separated string")
        let loaded = World()
        try loaded.load(data)
        #expect(loaded.entities(taggedWith: "boss").count == 1)
        #expect(try loaded.save() == data)

        // The inspector edits the text field; arrays load too.
        try world.setField("tags", of: "Tag", for: e, to: .string("pickup,  coin ,pickup"))
        #expect(world.get(Tags.self, for: e)?.tags == ["pickup", "coin"])
        #expect(world.fields(of: "Tag", for: e)?.first?.kind == .string)
        let fromArray = try AssetJSON.decoder().decode(Tags.self, from: Data(#"{"tags": ["a", "b"]}"#.utf8))
        #expect(fromArray.tags == ["a", "b"])
        #expect(ComponentRegistry.type(named: "Tag") == Tags.self)
    }

    @Test func visualScriptNodesFindAndChangeTags() {
        let world = World()
        let host = VisualScriptHost()
        var lines: [String] = []
        host.log = { lines.append($0) }
        let runtime = world.addVisualScripts(host: host)
        let coin = world.spawn(Transform(), Name("Coin"), Tags("pickup"))
        world.spawn(Transform(), Tags("pickup"))
        runtime.graphs["g"] = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "first", type: .entity), VisualScriptVariable(name: "count", type: .int),
                        VisualScriptVariable(name: "mine", type: .bool)],
            nodes: [VisualScriptNode(id: "start", type: "event.start"),
                    VisualScriptNode(id: "find", type: "world.findByTag", inputs: ["tag": .string("pickup")]),
                    VisualScriptNode(id: "all", type: "world.findAllByTag", inputs: ["tag": .string("pickup")]),
                    VisualScriptNode(id: "len", type: "array.length"),
                    VisualScriptNode(id: "setFirst", type: "var.set", config: ["variable": .string("first")]),
                    VisualScriptNode(id: "setCount", type: "var.set", config: ["variable": .string("count")]),
                    VisualScriptNode(id: "add", type: "world.addTag", inputs: ["tag": .string("player")]),
                    VisualScriptNode(id: "has", type: "world.hasTag", inputs: ["tag": .string("player")]),
                    VisualScriptNode(id: "setMine", type: "var.set", config: ["variable": .string("mine")]),
                    VisualScriptNode(id: "drop", type: "world.removeTag", inputs: ["tag": .string("pickup")])],
            links: [VisualScriptLink(from: "start.out", to: "setFirst.in"), VisualScriptLink(from: "find.entity", to: "setFirst.value"),
                    VisualScriptLink(from: "setFirst.out", to: "drop.in"), VisualScriptLink(from: "find.entity", to: "drop.entity"),
                    VisualScriptLink(from: "drop.out", to: "setCount.in"), VisualScriptLink(from: "all.entities", to: "len.array"),
                    VisualScriptLink(from: "len.length", to: "setCount.value"), VisualScriptLink(from: "setCount.out", to: "add.in"),
                    VisualScriptLink(from: "add.out", to: "setMine.in"), VisualScriptLink(from: "has.result", to: "setMine.value")])
        let me = world.spawn(Transform(), VisualScript(graph: "g"))
        world.update(dt: 1.0 / 60)
        #expect(lines.isEmpty, "\(lines)")
        #expect(runtime.variable("first", of: me) == .entity(coin))
        #expect(runtime.variable("count", of: me) == .int(1), "the coin lost its tag")
        #expect(runtime.variable("mine", of: me) == .bool(true))
        #expect(world.hasTag("player", me))
    }
}
