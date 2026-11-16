# Builder tools

Builder tools let people and AI agents author game content inside the Acro editor without outside programs. Each builder follows the same pattern:

- **A file type** under the project's `Assets/` folder (JSON, every key optional) that is the source of truth.
- **An importer** that turns it into engine objects (meshes, materials, prefabs, textures, sounds), so the result is placed, packed and hot-reloaded like any other asset.
- **An editor tab** next to the Scene view with a live preview and a sidebar form. Every change is written to the file as one undo step.
- **MCP tools** (`<name>.new`, `.get`, `.set`, `.edit`, `.open`) so an agent can build and adjust the asset in a few calls, with problems reported back as warnings. See [MCPTools.md](MCPTools.md) for schemas and parameters.

| Builder | File | Makes |
|---|---|---|
| [Mesh Builder](#mesh-builder) | `.meshbuild` | Models from primitive shapes, with materials and animation |
| [VFX Builder](#vfx-builder) | `.vfx` | Effects made of stacked GPU particle emitters |
| [Post-FX Builder](#post-fx-builder) | `.postfx` | Camera looks: tonemapping, bloom, grading, vignette, grain |
| [Terrain Builder](#terrain-builder) | `.terrain` | Sculpted, painted heightmap terrain with scattered props |
| [Sound Builder](#sound-builder) | `.sfx` | Synthesized sound effects |
| [Data Table Builder](#data-table-builder) | `.table` | Typed spreadsheets for game data |
| [Visual Script Builder](#visual-script-builder) | `.vscript` | Game logic as node graphs, run without a game module |

Planned builders are tracked in [Tools.md](../Tools.md).

## Mesh Builder

Mesh Builder assets describe models as editable JSON parts, so props, vehicles, and machines can be created without a separate modeling tool. The importer produces a mesh and PBR material for each part and a prefab hierarchy; placed copies update when the source asset changes.

In the editor, use **New Mesh Build** in the asset browser, then double-click the file (or use **Open in Mesh Builder** in the inspector) to open the **Mesh Builder** tab next to the Scene view. It is a scene view of its own: the model alone on a grid, with its own camera (right-drag or middle-drag orbits, Shift pans, the wheel zooms). Click a part to select it, and drag the Move / Rotate / Scale gizmos (W / E / R) to place it; scaling grows the part's size. **Animate** previews animations live. The sidebar holds the shape buttons, part tree, per-part properties (shape, hierarchy, materials, textures) and motion buttons. Every change is saved to the file as one undo step. **Place in Scene** adds the built asset to the current scene. Mesh Builder files use the `.meshbuild` extension and live under the project’s `Assets/` folder.

The format supports boxes, spheres, hemispheres, cylinders, cones, capsules, tori, tubes, planes, wedges, pyramids, and groups. Parts can specify dimensions, local transforms, UV behavior, color, opacity, metallic and roughness values, emissive glow, and material or texture references. Animations can use authored keyframe tracks or built-in spin, bob, swing, pulse, and shake motions. Autoplay animations are compiled onto prefab parts and run in play mode.

Editor MCP clients can create and edit these assets with `meshBuild.new`, `meshBuild.edit`, `meshBuild.set`, and `meshBuild.get`, and show one in the Mesh Builder tab with `meshBuild.open`. See [MCPTools.md](MCPTools.md) for schemas and parameters.

## VFX Builder

VFX Builder assets (`.vfx`, JSON under `Assets/`) describe visual effects as stacks of the engine's GPU particle emitters: fire is flames plus embers plus smoke, an explosion is a flash, a fireball, smoke and sparks. Each emitter has its own placement, particle settings and a `delay` (timing offset in seconds), and the importer produces a prefab with one `ParticleEmitter` child per emitter, so an effect is placed or spawned like any model. Presets: fire, smoke, sparks, explosion, magic hit, rain, snow, dust, portal.

In the editor, use **New VFX** in the asset browser, then double-click the file (or use **Open in VFX Builder** in the inspector) to open the **VFX Builder** tab next to the Scene view. It previews the effect looping in a viewport of its own over a ground plane and background color (right-drag orbits, the wheel zooms), with Restart, Loop and Pause controls. The sidebar has the preset picker, the emitter list (add, duplicate, delete) and a property grid for the selected emitter and the effect's duration, background and ground. Every change is saved to the file as one undo step and placed copies update.

Editor MCP clients can use `vfx.new {preset}`, `vfx.edit {addEmitters, updateEmitters, removeEmitters}`, `vfx.set`, `vfx.get` and `vfx.open`. See [MCPTools.md](MCPTools.md).

## Post-FX Builder

A `.postfx` file is a saved camera look: tonemapper, exposure and auto exposure, bloom, color grading (contrast, lift, gamma, gain, saturation), vignette, chromatic aberration and film grain, all in one post pass on Metal and Vulkan. Make one with the Assets panel's New Post-FX (or `postfx.new {preset}`: neutral, cinematic, warm, cold, noir, retro) and open it in the Post-FX tab for a sample scene with sliders, presets and a before/after split; each change is one undo step. Use it per camera (the Camera's `postFX` field, or `postfx.assign`) or blend it by area with a `PostFXVolume` component (box or sphere, blend distance, priority, weight).

Tools: `postfx.new`, `postfx.get`, `postfx.set`, `postfx.edit`, `postfx.assign`, `postfx.open`.

Not yet: depth of field and LUT grading. The tab previews on an 8-bit image, so bloom looks weaker there than in the game.

## Terrain Builder

Terrain assets (`.terrain`, JSON under `Assets/`) describe outdoor ground as a heightmap. The importer splits it into chunk meshes with smooth normals and a triangle-mesh collider each, bakes the painted texture layers into one albedo texture, and builds a prefab of the chunks plus the scattered props (props sharing a mesh and material draw as one instanced batch). Placed copies update when the file changes.

In the editor, use **New Terrain** in the asset browser, then double-click the file (or use **Open in Terrain Builder** in the inspector) to open the **Terrain Builder** tab next to the Scene view. Left-drag on the terrain with the chosen brush (raise, lower, smooth, flatten, noise, paint, erase paint) using the sidebar's radius, strength and falloff; a stroke is one undo step. The sidebar also edits the terrain's size, resolution and height range, its texture layers (a flat color, an image, or a `.proctex`, tiled per meter) and its scatter rules (a mesh build or mesh, candidate density, slope, height and layer rules, scale, seed).

Editor MCP clients can create and edit these assets with `terrain.new {size, resolution, seed}`, `terrain.sculpt {brush, points}`, `terrain.paint {layer, points}`, `terrain.scatter {asset, density, rules}`, `terrain.edit`, `terrain.set` and `terrain.get`, and show one in the Terrain Builder tab with `terrain.open`. Brush points are `[x, z]` meters from the terrain's center. See [MCPTools.md](MCPTools.md) for schemas and parameters.

## Sound Builder

Sound Builder assets (`.sfx`) generate game sound effects from synth parameters, the way procedural textures generate images: a waveform (square, saw, sine, noise), pitch slide, vibrato, arpeggio, a volume envelope (attack, sustain, decay), low-pass and high-pass filters, and bit crush. Presets (jump, coin, laser, explosion, hit, power-up, blip) come with **Randomize** and **Mutate**. The sound is rendered by pure-Swift DSP, so the same parameters and `seed` give identical samples on every platform.

In the editor, use **New Sound** in the asset browser, then double-click the file (or use **Open in Sound Builder** in the inspector) to open the **Sound Builder** tab next to the Scene view: a waveform view, a Play button (with Auto-play after each change), presets and the parameters form. Every change is saved to the file as one undo step. An `.sfx` file plays anywhere an audio file does: set an `AudioEmitter`'s `clip` to it, or load it with `AssetDatabase.loadSound`.

Editor MCP clients can use `sfx.new`, `sfx.get`, `sfx.set`, `sfx.edit` (preset, randomize, mutate, field changes), `sfx.play` (preview in the editor) and `sfx.open`. See [MCPTools.md](MCPTools.md) for schemas and parameters.

## Data Table Builder

Data tables are typed spreadsheets for game data (items, enemies, loot, waves, settings), stored as `.table` JSON files under `Assets/`. Columns have a type (`number`, `text`, `bool`, `color`, `enum`, `asset`, `row`), a default and optional `options` / `min` / `max`; rows are flat objects with a unique `id` (`{"id": "goblin", "hp": 30}`), and a missing cell takes its column's default. Values that don't fit (wrong type, unknown enum case, dangling asset or row reference, duplicate ids) are kept and reported as warnings.

In the editor, use **New Data Table** in the asset browser and double-click the file (or **Open in Data Table** in the inspector) to open the **Data Table** tab. Its grid has one row per table row (click a header to sort, type `hp > 10 kind == ranged goblin` in the filter box); the sidebar edits columns, bulk-sets a column across the shown rows, writes the sort into the file, lists problems and imports / exports CSV (quoted fields, doubled quotes and line breaks inside quotes are handled). Every change is one undo step.

Game code reads a table by row id with typed access; the lookup follows hot reload while playing:

```swift
let enemies = assets.dataTable(path: "Data/enemies.table")
let hp = enemies?.row("goblin")?.number("hp") ?? 10
let loot = enemies?.row("goblin")?.reference("drops")   // row column
```

Cooked games ship the file as written; include tables game code loads by path with the cooker's `--include`. MCP clients use `table.new`, `table.edit`, `table.query`, `table.get`, `table.set`, `table.importCsv`, `table.exportCsv` and `table.open`; see [MCPTools.md](MCPTools.md).

## Visual Script Builder

Visual scripts (`.vscript`, JSON under `Assets/`) are game logic as node graphs, so people can script without writing Swift or building a game module; a game can mix graphs and Swift. Put a **VisualScript** component on an entity (Add Component, **Attach to Selection** in the tab or the asset inspector, or `vscript.attach`) and its graph runs in the editor's play mode and in built games. A VisualScript on an empty "Game Rules" entity is a scene-level graph. The component's `variables` lists the graph's exposed variables, so each entity can have its own values.

A graph is `nodes` (`{id, type, x, y, config, inputs}`) and `links` (`{"from": "node.pin", "to": "node.pin"}`, always from an output pin to an input pin), plus `variables` (typed, with defaults), `functions` (sub-graphs from `function.entry` to `function.return`, called with `function.call`), `comments` (boxes) and `actions` (input actions: `{"jump": ["key.space", "pad.south"]}`). Every key is optional.

```json
{
  "variables": [{"name": "speed", "type": "float", "default": 90}],
  "nodes": [
    {"id": "tick", "type": "event.update"},
    {"id": "speed", "type": "var.get", "config": {"variable": "speed"}},
    {"id": "mul", "type": "math.multiply"},
    {"id": "turn", "type": "transform.rotate", "inputs": {"axis": [0, 1, 0]}}
  ],
  "links": [
    {"from": "tick.out", "to": "turn.in"}, {"from": "tick.dt", "to": "mul.a"},
    {"from": "speed.value", "to": "mul.b"}, {"from": "mul.result", "to": "turn.degrees"}
  ]
}
```

Event nodes start flows; exec wires (`in` / `out`, `true` / `false`, `body` / `done`…) carry the flow from node to node, and a node reads its data inputs by pulling values along data wires (pure nodes such as math are computed when read). An unconnected input uses the literal in `inputs`, else its default; an unconnected entity input means the script's own entity. Pins are typed (bool, int, float, string, vec2, vec3, vec4, color, quat, entity, asset, array, map, any) and convert automatically where it makes sense (int to float, anything to text…), shown as a dot on the wire.

- **Events:** start, update, fixed update, late update, destroy, timer, key pressed / released, input action pressed / released, collision and trigger enter / exit (3D and 2D), custom events (`event.send` between graphs and to Swift), sprite clip events and clip finished.
- **Flow:** branch, sequence, for loop, for each, while, gate, do once, delay, flip-flop, switch (on any value, so enum case names work).
- **Data:** math (also per component on vectors), random, vectors, colors, comparison, logic, select, text format, arrays and maps, variables, functions, time and input.
- **World:** self, spawn entity, spawn prefab (any `.prefab`, model, mesh build or `.vfx`), destroy (optionally after a delay), find by name, parent, transform get / set / translate / rotate / look at.
- **Components:** `component.get` / `component.set` for every reflected field of every registered component (`config: {"component": "PointLight", "field": "intensity"}`), so game components show up with no extra code; `component.has` / `add` / `remove`. Setting a field goes through reflection (a fraction of a millisecond), fine for events, slow for thousands of entities per frame.
- **Engine:** play sound (audio file or `.sfx`, as a one-shot emitter), spawn effect, raycast, apply force / impulse / velocity, load and reload scene, tween position / rotation / scale with easing, data table cells and row ids.

The graph is interpreted by a small VM with no compile step: editing the file while the game plays applies on the next frame, keeping variable values and pending delays (start doesn't run again). A runaway graph (an endless while loop, unbounded recursion) is stopped with an error after 100 000 node runs in one event and stays stopped until its graph changes. Built games ship `.vscript` files as written, with the assets they name by `asset:<id>`.

In the editor, use **New Visual Script** in the asset browser, then double-click the file (or **Open in Visual Script** in the inspector) to open the **Visual Script** tab next to the Scene view. Drag nodes to move them, drag from a pin to another to wire them, drop a wire on empty space or right-click (or press Space) to search for a node to add there (filtered by the dragged pin's type, and wired to it), right-click a pin to cut its wires, scroll to zoom, drag empty space to pan. Delete removes the selection, Cmd/Ctrl+C / V / D copy, paste and duplicate, F9 toggles a breakpoint. The sidebar edits the selected node's settings and input values, the graph's variables and functions (**Collapse to Function** moves the selected nodes into a new function, **Comment Box** frames them), and lists problems; nodes with errors (unknown type, type mismatch, unconnected required input, unreachable) are outlined on the canvas. Every change is one undo step. While playing, nodes that just ran glow along their wires, output pins show their values for the selected entity (hover a pin for its type and value), the sidebar shows that entity's variables, and a node with a breakpoint pauses play after the frame it ran in. Each graph's time shows in the profiler as `vscript <path>`.

Game modules add nodes and events, and Swift and graphs send events both ways:

```swift
game.scriptNode("mygame.heal", title: "Heal", inputs: [VisualScriptPin("amount", .float, default: .float(10))]) { node in
    let amount = try node.float("amount")
    node.world.modify(Health.self, for: node.entity) { $0.points += amount }
}
game.scriptEvent("mygame.wave")                                  // an "On mygame.wave" event node
world.sendScriptEvent("mygame.wave", value: .int(3))             // Swift → graphs
VisualScriptRuntime.runtime(for: world)?.onEvent("pickup") { sender, value in … }   // graphs → Swift (event.send)
```

Other modules register nodes with `VisualScriptNodes.register(_:)` (or `addProvider` to register on first use) and raise events with `VisualScriptRuntime.addEventSource`, so builders that ship later add their own nodes.

Editor MCP clients can use `vscript.new {template, target}` (templates: empty, spinner, mover, pickup, timer), `vscript.edit {addNodes, updateNodes, connect, disconnect, removeNodes, variables, functions, comments, actions}`, `vscript.nodes {search, pinType}` (every node type with its pins), `vscript.validate`, `vscript.get`, `vscript.set`, `vscript.attach` and `vscript.open`. See [MCPTools.md](MCPTools.md) for schemas and parameters.

Not yet: step over / into while paused (breakpoints pause after the frame), macros (functions cover reusable sub-graphs), reroute points and node groups, play animation / dialogue / timeline nodes (added by those builders), and a function's entry and return pins are edited through `vscript.edit {functions}` rather than in the tab.
