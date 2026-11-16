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
| [Material Builder](#material-builder) | `.material` | Node-graph surface shaders compiled for Metal and Vulkan |

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

## Material Builder

A `.material` file can hold a node graph (the `graph` key) that computes its surface instead of the fixed PBR settings: textures (images or `.proctex`), noise (value, fractal, cells), math, blend modes, fresnel, scrolling and rotating UVs, time, vertex color and triplanar mapping, wired into the PBR inputs base color, opacity, normal (tangent space), metallic, roughness, emissive and occlusion. The material's `alphaMode`, `alphaCutoff`, `doubleSided` and sampler settings still apply; use `blend` (or `mask`) for a graph that drives opacity.

```json
{
  "shading": "pbr",
  "alphaMode": "opaque",
  "graph": {
    "nodes": [
      {"id": "flow", "type": "scrollUV", "speed": [0.03, 0.015]},
      {"id": "heat", "type": "noise", "kind": "fbm", "uv": "flow", "scale": 5, "octaves": 5},
      {"id": "hot", "type": "color", "value": [6, 1.6, 0.15, 1]},
      {"id": "glow", "type": "math", "op": "multiply", "a": "hot", "b": "heat"}
    ],
    "output": {"baseColor": [0.06, 0.035, 0.03], "emissive": "glow.rgb", "roughness": 0.8}
  }
}
```

A node is `{"id", "type", ...keys}`. An input holds a constant (a number or 2-4 numbers) or a link: a node id, optionally with a swizzle (`"tex.rgb"`, `"n.x"`), or a built-in (`uv`, `position`, `normal`, `viewDir`, `vertexColor`, `time`). Sizes convert as in GLSL. Colors are linear. Up to five different textures per graph. UV-space noise isn't tileable, so it shows the mesh's UV seam; feed it `position.xz` (or use `triplanar`) for seamless world-space patterns. Problems (unknown nodes or ops, missing links, cycles, missing textures) are import warnings, and the graph still compiles with defaults in their place. Presets: basic, lava, water, hologram, stone, pulse.

**How it compiles.** At import the graph becomes straight-line shader code that replaces the body of one function, `graphSurface`, in a template variant of the lit mesh shader (`mesh_graph.frag`: `mesh_surface.glsl` with `MATERIAL_GRAPH`, compiled unoptimized so the function survives). For Vulkan the code is emitted as SPIR-V and spliced into the template's SPIR-V; for Metal it is emitted as MSL and spliced into the template's MSL. No shader compiler is needed at run time, so this works in the editor and in cooked games alike. Every constant the author typed is data (a storage buffer), so changing a number doesn't recompile, and materials whose graphs differ only in constants share pipelines. Lighting, shadows, fog, IBL and the punctual lights are the same code as every other PBR material.

**Using it.** Assign a graph material like any material: a MeshRenderer's `material` (`materialGraph.assign`, with `children: true` for a placed model or prefab), or a mesh build part's `material` key. Placed copies update when the file changes.

In the editor, use **New Material Graph** in the asset browser, then double-click a `.material` file (or use **Open in Material Builder** in the inspector) to open the **Material Builder** tab next to the Scene view. It previews the material on a sphere, cube, plane or the selected entity's mesh, with a light and background picker and an Animate switch for time-driven graphs (right-drag orbits, Shift pans, the wheel zooms). Below the preview, the graph canvas draws the nodes and their links; click a node to edit it, drag it to move it. The sidebar has the presets, alpha mode and sidedness, the PBR outputs, Add Node, the selected node's inputs and settings, and the graph's problems. A material without a graph has **Convert to Graph**, which rebuilds its fixed settings as nodes. Every change is saved to the file as one undo step.

Editor MCP clients can use `materialGraph.new {preset}`, `materialGraph.edit {addNodes, removeNodes, connect, disconnect, params, output, settings}`, `materialGraph.set`, `materialGraph.get {code}`, `materialGraph.nodes` (the node catalog), `materialGraph.assign` and `materialGraph.open`. The older `material.get` and `material.set` keep editing a material's fixed fields. See [MCPTools.md](MCPTools.md) for schemas and parameters.

Not yet: terrain layers and decals can't use graph materials, graph opacity doesn't shape shadows (alpha-tested graph materials cast solid shadows), graph materials don't receive planar reflections, and the canvas can't draw links by dragging (link from the sidebar instead).
