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
| [Pixel Sprite Builder](#pixel-sprite-builder) | `.sprite` | Pixel art and sprite animation for `SpriteAnimator` |
| [Tilemap Builder](#tilemap-builder) | `.tilemap` | 2D tile levels with auto-tiling, animated tiles, 2D collision and object points |
| [GridMap Builder](#gridmap-builder) | `.gridmap` | 3D levels painted from modular pieces on a grid |
| [Path Builder](#path-builder) | `.path` | Roads, rails, rivers, fences, cables and walls along splines |
| [Behavior Tree Builder](#behavior-tree-builder) | `.behavior` | NPC AI as node trees |
| [UI / HUD Builder](#ui--hud-builder) | `.ui` | Game menus and HUDs made from the engine's widgets |
| [Dialogue Builder](#dialogue-builder) | `.dialogue` | Branching conversations with variables and events |

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

## Pixel Sprite Builder

Pixel Sprite assets (`.sprite`, JSON under `Assets/`) are pixel art with layers, frames and tags. Pixels are palette indices: each cel (one layer in one frame) is a list of row strings with one character per pixel, `.` for transparent and `0`-`9`, `a`-`z`, `A`-`Z` for palette entries 0-61, so a file reads like the picture:

```json
{"width": 6, "height": 2, "palette": ["#000000", "#ff004d"],
 "layers": [{"name": "Body", "cels": [["..11..", ".1001."], ["......", "..11.."]]}],
 "frames": [{"duration": 100}, {"duration": 150}],
 "tags": [{"name": "idle", "from": 0, "to": 1, "mode": "loop"}]}
```

Every key is optional (a blank 16 x 16 canvas with the PICO-8 palette). Layers are listed bottom first, with `visible` and `opacity`. Frame durations are milliseconds. A tag names an inclusive frame range played as `loop`, `once` or `pingPong`. `pivot` (default bottom middle) and `pixelsPerUnit` (default 16) apply when the frames are drawn as sprites. Palette presets: `pico8`, `db16`, `db32`, `gameboy`, `grayscale`.

The importer composites each frame and lays the frames out as an atlas grid in one `texture` sub-asset (no mipmaps). Each cell has a 1-pixel border that repeats the frame's edge. Indexing is stable: frame `i` is atlas frame `i`, in cell `i` in reading order, whatever the tags. So the same file also works as a tile set (tile `i` is frame `i`, see `SpriteSheet.frameIndex(column:row:)`). Each tag becomes one `SpriteClip`. Frames longer than the clip's shortest frame are repeated, so per-frame timing plays exactly at the clip's `fps`. A sprite without tags gets one looping `default` clip.

Game code loads sprites through `SpriteAssetLibrary`. It uploads the atlas with nearest filtering, registers it with a `SpriteRenderer` under the file's path and reloads it when the file changes:

```swift
let library = SpriteAssetLibrary(assets: assets, device: device, renderer: sprites)
let hero = library.handle(path: "Sprites/hero.sprite")!
world.spawn(Transform(), Sprite(atlas: hero), library.animator(path: "Sprites/hero.sprite", playing: "run")!)
// once a frame:
library.update()
```

`AssetDatabase.spriteSheet(path:)` returns the same data as plain CPU values: the image, frame rectangles, clips and grid. Cooked packs keep the `.sprite` source next to its texture, so this also works in a shipped game.

In the editor, use **New Sprite** in the asset browser, then double-click the file (or use **Open in Pixel Sprite Builder** in the inspector) to open the **Pixel Sprite Builder** tab next to the Scene view. The canvas shows the current frame with onion skin (the previous frame in red and the next in blue) and a pixel grid when zoomed in. The wheel zooms and middle-drag pans. Left-drag draws with the selected tool: pencil, line, rectangle (outline or filled), fill, eraser or color picker. Alt+click picks a color with any tool, and right-drag erases. Mirror X / Mirror Y draw mirrored copies. The sidebar has an animation preview of the selected tag, the palette (click a swatch, edit the selected color, add, remove, load a preset), layers (add, remove, reorder, rename, show or hide, opacity), frames (step, add, duplicate, remove, reorder, duration, flip, clear the cel), tags (name, range, mode) and the canvas size. Each stroke and each form change is saved to the file as one undo step.

Editor MCP clients can use `sprite.new {width, height, palette, frames}`, `sprite.draw {frame, layer, pixels, x, y, ops}` (rows to stamp, then pencil / line / rect / fill / eraser operations, optionally mirrored; a color is a palette index, a row character or a hex color, which is added to the palette if needed), `sprite.edit {addFrames, copyFrame, removeFrames, durations, tags, addTags, addLayers, updateLayers, palette, width, height}`, `sprite.set`, `sprite.get` (with `frame`, returns that frame as rows) and `sprite.open`. See [MCPTools.md](MCPTools.md) for schemas and parameters.

Not yet: selections and copy / paste between cels, layer blend modes other than normal, importing PNG sprite sheets into a `.sprite`, and per-tag frame events.
## Tilemap Builder

Tilemaps (`.tilemap`, JSON under `Assets/`) are 2D levels painted from a tile set: a grid of `size` [columns, rows] cells of `tileSize` [w, h] pixels in several layers. The tile set's `source` is a sprite sheet sliced into tiles in reading order (`{"kind": "image", "image": "Tiles/sheet.png", "margin": 0, "spacing": 0}`, or just the path) or separate images packed into an atlas (`{"kind": "images", "images": [...]}`); the source is an enum, so more kinds (a Pixel Sprite `.sprite`) can be added later. Per-tile entries give a tile a `collision` shape (`full`, `top`, `bottom`, `slopeUp`, `slopeDown`, or a `polygon` of points), `oneWay`, `tags`, custom `properties` and an `animation` (tile frames at an fps, looping or ping-pong, played like a `SpriteClip`). Layers have a draw order, parallax, opacity, visibility and a collision switch. A cell is -1 (empty) or a tile index plus flip and quarter-turn bits (see `TileCell`); cells are addressed [x, y] with y down from the top-left. Terrain sets (`edges`: 16 tiles by the four sides; `blob`: 47 by sides and corners) auto-tile: painting a terrain picks every edge and corner tile from its neighbors. Objects are named points or areas (spawns, triggers) for game code.

The importer makes the tile set texture, one unlit material per layer (nearest filtering by default) and one mesh per non-empty layer chunk, and a prefab with a node per layer, a `Collision` node holding one static `Collider2D` per merged shape (solid tiles merge into rectangles, platforms and other strips merge along their row, ramps and polygons stay one shape per tile) and an `Objects` node with a named node per object (areas with `trigger` get a trigger box). The map lies in the XY plane with its bottom-left corner at the origin; a tile is `tileSize / pixelsPerUnit` units (one unit by default). Placed copies update when the file changes.

In the editor, use **New Tilemap** in the asset browser (it writes a starter tile set next to the map: a "Dirt" terrain, stone, brick, a one-way platform, ramps, spikes, animated water and torch, coin, ladder), then double-click the file (or **Open in Tilemap Builder** in the inspector) to open the **Tilemap Builder** tab. The canvas draws the map with its tile set; the toolbar has Pencil, Rect, Fill (flood), Erase, Random (Shift-click palette tiles to build the set), Terrain (Shift-drag erases it), Object (click to add or select, drag to move) and Pick (right-click picks in every tool), plus Flip X, Flip Y, Rotate, Grid and Fit. Middle-drag or Alt-drag pans, the wheel zooms. The sidebar has the tile palette, the selected tile's data, the layers (add, remove, reorder, hide in the view, dim the others, settings), terrain sets, objects and the map settings. A stroke is one undo step.

Sprite games draw a map through a `SpriteBatch`, a visible chunk at a time, with parallax, opacity and animated tiles, and read its data with hot reload:

```swift
let drawer = try TilemapSpriteDrawer(assets: assets, path: "Levels/level1.tilemap", device: device)
drawer?.draw(into: sprites.batch, camera: camera, time: elapsed)
let level = assets.tilemap(path: "Levels/level1.tilemap")
let spawn = level?.object(named: "Player")?.position
let deadly = level?.hasTag("hazard", atWorld: playerPosition) ?? false
```

2D physics reads each collider entity's own `Transform` (parents are ignored), so the prefab's colliders line up when the map is placed at the world origin; elsewhere, spawn them with `world.spawnTilemapColliders(map, at: origin)`.

Editor MCP clients use `tilemap.new {tileSize, size, tileset}`, `tilemap.paint {layer, tile | tiles | terrain, cells}`, `tilemap.fill {layer, tile | tiles | terrain, rect | at}`, `tilemap.erase {layer, cells | rect | all}`, `tilemap.edit` (size, tile set, per-tile data, layers, terrains, objects), `tilemap.set`, `tilemap.get` (with `layer` and `rect` for cells) and `tilemap.open`. See [MCPTools.md](MCPTools.md).

Not yet: parallax and animated tiles in placed prefabs (they show the painted frame and move with the world; `TilemapSpriteDrawer` does both), one-way platforms that face other directions than up, `assets.tilemap(path:)` in cooked games (the cooker ships the imported prefab, not the JSON), and Pixel Sprite (`.sprite`) tile sets.
## GridMap Builder

Grid maps (`.gridmap`, JSON under `Assets/`) are 3D levels built from modular pieces on a grid: dungeons, buildings, city blocks. The file holds a `cellSize` (x, floor height, z in meters), a list of `layers` (default `floor`, `walls`, `props`; each cell holds one piece per layer), a piece library and the painted cells. A piece names a `.meshbuild`, a model (`.gltf`, `.glb`, `.obj`), a `.prefab` or a mesh reference, with a footprint in cells, a collision `size`, a pivot `offset`, a model `rotation`, `scale`, a default layer and a `collider` mode (`auto`, `mesh`, `box`, `none`). A cell is `{"at": [x, y, z], "piece": "Floor", "layer": "floor", "rotation": 90, "flipX": true}`, where `y` is the floor; a piece is centered on the cells it covers and stands on its floor.

Auto-joining pieces have a `join` instead of an asset: the names of their single, end, straight, corner, tee and cross variants (plus `joinsWith`, other pieces that count as neighbors). Each cell becomes the variant that fits its neighbors on the same floor and layer, turned to face them, so painting a run of `Wall` gives straight walls, corners and T-junctions by itself. Variants are authored connecting toward +x (end), +x and -x (straight), +x and +z (corner), and +x, -x and +z (tee).

The importer runs each piece file's own importer to learn its nodes and triangles (so the map reimports when a piece file changes) and builds a prefab: a node per floor, a node per chunk (`chunkSize` cells per side) holding one merged triangle-mesh collider, and one node per placed piece that references the piece's meshes and materials, so equal pieces draw as one instanced batch. Flipped pieces get mirrored copies of their meshes. Pieces whose triangles can't be read collide as boxes.

In the editor, use **New GridMap** in the asset browser (it writes starter pieces as mesh builds next to the map: Floor, an auto-joining Wall with its six variants, Crate, Pillar), then double-click the file (or use **Open in GridMap Builder** in the inspector) to open the **GridMap Builder** tab. The edited floor shows its grid; floors below are faded and floors above hidden. Pick a brush (paint, line, rectangle (Shift: hollow), fill, erase, random from a set), a piece, the rotation, flips and layer, then click or drag on the grid; each stroke is one undo step. The floor slider and Up / Down buttons change the floor. The sidebar also edits each piece (asset, footprint, pivot, collider, auto-join variants) and the map's settings.

Editor MCP clients can use `gridMap.new {cellSize, library, assets, starter}`, `gridMap.paint {piece | pieces, cells, brush, rotation, flipX, flipZ, layer}` (brush: cells, line, rect, outline, fill), `gridMap.fill {piece, box, hollow}`, `gridMap.erase {cells | box, layer}`, `gridMap.edit` (settings, layers, add / update / remove pieces), `gridMap.set`, `gridMap.get` (with `mapFloor`, a text picture of one floor) and `gridMap.open`. See [MCPTools.md](MCPTools.md) for schemas and parameters.

Not yet: per-piece random variation of scale, auto-joining for multi-cell pieces, and editing a `.prefab` variant as a piece.
## Path Builder

Path assets (`.path`, JSON under `Assets/`) are splines that generate geometry along them: roads, rails, rivers, fences, cables and walls. The curve is the Catmull-Rom spline `CameraPath` uses, through control points (each `[x, y, z]`, or `{position, bank, width}`), open or `closed`, `smooth` or straight between points, sampled every `spacing` meters. Along it, **profiles** are cross-sections swept into meshes (`flat` strip, `box`, `tube`, or a `custom` outline of `[right, up]` points, each with an `offset` from the centerline, a look, an optional triangle-mesh collider, and `sag` so cables hang between their supports like a `LineRenderer`), and **pieces** are repeated every `spacing` meters (a built-in shape, a `.meshbuild` or a mesh; offset, `mirror` to the other side, `upright` or tilted with the path, optional box colliders). Banking rolls the frame per point (`bank`, degrees; positive lowers the right side) plus `autoBank` in tight turns; a per-point `width` widens or narrows the profiles. The importer makes one mesh per profile and a prefab of those plus the pieces (equal pieces draw as one instanced batch); placed copies update when the file changes.

**Terrain following:** set `terrain.asset` to a `.terrain` file and every sample and piece sits on its surface plus `terrain.height` (point heights are ignored), so a road hugs the hills between its control points. `terrain.offset` is the terrain's origin in the path's space (zero when both are placed at the same spot). The terrain is an import dependency: sculpting it reimports the path onto the new ground. `Terrain.heightAt(x:z:)` is the height-sampling API used.

In the editor, use **New Path** in the asset browser, then double-click the file (or use **Open in Path Builder** in the inspector) to open the **Path Builder** tab next to the Scene view. It shows the path over the terrain it follows, the curve as a line and a handle per control point (the first is green): click a handle and drag it with the Move gizmo; the move is written when you let go. The sidebar has the kind presets (road, rail, river, fence, cable, wall, custom: they replace the profiles and pieces and keep the points), the curve settings, the point list with Add / Insert / Delete and the selected point's position, bank and width, the profile and piece lists with their property grids, the terrain following settings, and the length, sample and piece counts and problems. Every change is one undo step.

Editor MCP clients use `path.new {kind, points, terrain, place}`, `path.edit {points, addPoints, insertPoints, updatePoints, removePoints, profile, profileName, addProfiles, updateProfiles, removeProfiles, addPieces, updatePieces, removePieces, kind, terrain, …}`, `path.set`, `path.get`, `path.sample {count | distances}` (positions and frames along the centerline, on the terrain, to place things beside a road) and `path.open`. Code with the project's files at hand (editor tools, tests) can read a path with `assets.pathBuild(of:)` and walk it with `samples(on:)` / `PathBuild.sample(_:atDistance:)`; cooked games get the generated meshes, not the `.path` source. See [MCPTools.md](MCPTools.md).

Not yet: carving or flattening the terrain under a road, junctions between paths, a component that moves objects along a path at runtime, and adding points by clicking on the ground in the tab (use Add / Insert, then drag).
## Behavior Tree Builder

Behavior trees (`.behavior`, JSON under `Assets/`) describe NPC AI as nodes instead of hand-written code. `nodes` is a flat list of `{id, type, name?, children?, ...parameters}`; `root` names the root (by default the first node no other node lists as a child); `blackboard` holds starting shared values (numbers, booleans, text, `[x, y, z]` vectors, lists of points); `speed`, `turnSpeed` and `tickRate` (0 means every frame) apply to the whole tree.

- **Composites:** `sequence` (resumes at the running child; set `memory: false` to re-check from the first child), `selector` (re-checks from the first child every tick, so a higher-priority branch interrupts a running one), `parallel` (`succeedOn` all/one, `failOn` one/all).
- **Decorators** (one child): `invert`, `repeat` (`count`, 0 means forever; `untilFailure`), `cooldown` (`seconds`), `succeed`.
- **Conditions:** `canSeeTarget` (range, field of view about -Z, and line of sight through physics colliders when the scene has physics), `withinRange`, `healthBelow` (a blackboard number, default key `health`), `checkBlackboard` (`key`, `op`, `value`).
- **Actions:** `moveTo`, `patrol` (`points`, `relative`, `loop`, `wait`), `chase`, `flee`, `attack` (lowers the target's blackboard health by `damage` every `cooldown` seconds and records an `attack` event), `wait`, `playAnimation` (an `Animator` state or `SpriteAnimator` clip), `setBlackboard`, and `custom` for leaves registered by game code.

Problems such as unknown types, missing children, nodes with two parents, cycles, unconnected nodes and wrong parameters are reported as import warnings. At runtime a broken node fails.

An entity runs a tree with a **BehaviorTreeRunner** component: `tree` (the asset), `target` (the entity that target-based nodes aim at unless the blackboard's `target` names one by entity name), `speed` and per-entity blackboard values. In play mode and in built games, the behavior tree system ticks every runner and steers movement nodes on the XZ plane. A `CharacterController` gets its `moveVelocity`, a dynamic `RigidBody` gets its horizontal velocity, and anything else has its `Transform` moved. The live state is a `BehaviorTreeState` component (not saved), which holds the blackboard, each node's last status and this frame's events. Editing the file while playing switches running NPCs to the new tree and keeps their blackboard. There is no navigation mesh yet, so NPCs walk straight toward their goal.

```swift
BehaviorTreeLeaves.register("hasAmmo") { leaf in
    (leaf[blackboard: "ammo"]?.number ?? 0) > 0 ? .success : .failure
}
world.setBlackboardValue(.entity(player), forKey: "target", of: guardEntity)
for event in world.get(BehaviorTreeState.self, for: guardEntity)?.events ?? [] where event.name == "attack" { ... }
```

In the editor, use **New Behavior Tree** in the asset browser and double-click the file (or **Open in Behavior Tree Builder** in the inspector) to open the **Behavior Tree** tab. The tab shows the tree as an outline. Click a node to edit its id, label, type and parameters in the sidebar, move it among its siblings, make it the root or delete it. The sidebar also has controls to add nodes of any type, edit the blackboard and settings, and pick a preset (empty, patrol, guard, chaser, coward). Every change is one undo step. While playing, rows are tinted with what each node returned on the last tick: running is yellow, success is green and failure is red. The tint follows the selected entity if it runs the tree, otherwise the entity chosen in the toolbar picker.

Editor MCP clients use `behavior.new {preset}`, `behavior.edit {addNodes, connect, disconnect, updateNodes, removeNodes, blackboard}`, `behavior.set`, `behavior.get`, `behavior.assign {entity, target}`, `behavior.debug` (the live running path and blackboard while playing) and `behavior.open`. See [MCPTools.md](MCPTools.md).

Not yet: a node-graph canvas (the tab shows an outline) and navigation-mesh pathfinding. Movement assumes root entities.

## UI / HUD Builder

UI layouts (`.ui`, JSON under `Assets/`) describe game menus and HUDs built from the engine's widget toolkit: panels, vertical and horizontal stacks, labels, images, buttons, progress / health bars and spacers. Widgets are a flat list; each has a unique `id` and names its `parent` container ("" is the screen). The screen and panels place their children by `anchor` (the nine corners, edges and center, or `fill`) and an `offset` in points from the anchored edges, inside a safe area; stacks line their children up with spacing, alignment and grow. A layout picks a base theme (`game`, `dark`, `light`, `highContrast`) and can change its colors (`accent`, `text`, `panel`, `health`…); widget colors are `#RRGGBB[AA]` or one of those names.

Widgets show game values in three ways: `{key}` placeholders in text (`"Score: {score}"`), `bind` (a bar's fill is the value divided by `max`; a label's or button's whole text; an image's path) and `visibleWhen` (shown while a value is truthy, `"!key"` while it is falsy). The file's `values` are samples for the preview. A button sends its `event` (or its id) when pressed.

In the editor, use **New UI Layout** in the asset browser (a starter HUD), then double-click the file (or **Open in UI Builder** in the inspector) to open the **UI Builder** tab next to the Scene view. The preview in the middle is drawn by the same `UIBuildView` games use, fitted to the panel at a screen size picked from presets (16:9, 21:9, 16:10, 4:3, phone landscape and portrait). Click a widget to select it; drag one that sits on the screen or in a panel to change its offset from its anchor. With **Interact** on, clicking the preview's buttons shows the event they send. On the left are the add buttons and the widget tree (drag rows to put a widget in another container or reorder it); on the right are the selected widget's properties and bindings, then the layout's theme, colors, sample values and problems. Every change is one undo step.

Game code shows a layout, sets values and handles buttons. The view follows hot reload while the game runs:

```swift
let hud = UIBuildView(assets: assets, path: "UI/hud.ui")!
hud.useImages(renderer: sceneRenderer, assets: assets)   // project images
ui.root.addChild(hud)                                     // fills the window; clicks between widgets reach the game
hud.set("health", 64)
hud.set("score", 1200)
hud.on("pause") { openPauseMenu() }
hud.widget("score")                                       // the engine widget, for anything the file can't express
```

`UIBuildView(build)` and `load(_:)` show a `UIBuild` value made in code, and `onEvent` reports every press. The view's widgets use the layout's theme (`Widget.themeOverride`), not the game's context theme. Cooked games ship the file as written; include layouts and their images with the cooker's `--include`.

MCP clients use `uiLayout.new {preset: hud|menu|empty, widgets}`, `uiLayout.edit {addWidgets, updateWidgets, moveWidgets, removeWidgets, bindings, values, theme, colors}`, `uiLayout.get`, `uiLayout.set` and `uiLayout.open {previewSize, values, select}`; see [MCPTools.md](MCPTools.md). (The `ui.*` names belong to the editor's UI automation tools.)

Not yet: per-widget animation and transitions, sliders / toggles / text fields as layout widgets, navigation order for gamepads beyond the toolkit's spatial default, and scaling the whole layout with the screen (it is laid out in points; anchors keep it in place at any size).
## Dialogue Builder

Dialogue assets (`.dialogue`, JSON under `Assets/`) are branching conversations for NPCs, quests and tutorials. A file lists `speakers` (id, name, portrait texture, name color), `variables` (number, bool or text, with a default) and `nodes`:

- `line`: a speaker says `text`, then the player continues to `next`. `{gold}` in the text shows a variable.
- `choice`: the player picks one of `choices` (text, `next`, an optional `condition`; options whose condition is false are hidden). An optional `text` is a prompt shown above them.
- `condition`: goes to `next` when `condition` is true, else to `else`.
- `set`: changes variables (`set`, `add`, `subtract`, `toggle`, with a `value` or an `expression`).
- `event`: tells game code something happened (`event` name and `args`).
- `end`: ends the conversation, as does an empty `next`.

Conditions are small expressions: `gold >= 10 && !paid`, `visits + 1 > 3`, `name == "Ann"` (comparisons, `&&` `||` `!` or `and` `or` `not`, `+ - * /`, parentheses). Every line and option can have a localization `key`; **Make Keys** (or `dialogue.edit {generateKeys: "prefix"}`) fills in missing ones. The importer warns about links to missing nodes, unknown speakers or variables, conditions that don't parse, nodes nothing reaches and missing portraits.

In the editor, use **New Dialogue** in the asset browser, then double-click the file (or **Open in Dialogue Builder** in the inspector) to open the **Dialogue** tab. The graph shows each node as a box colored by type, with arrows for its links: click a node to select it, drag it to move it, drag from its dot onto another node to link them, and drag empty space or scroll to pan. The toolbar adds nodes of each type (linked from the selected node when it has a free link), deletes, re-arranges and makes keys. Below the graph, the play-through preview runs the conversation in the same `DialogueBox` the game uses, highlights the node it is at, and lists the variables it tracks (edit one to try another branch); it follows edits live. The sidebar edits the selected node, the start node, the speakers and the variables, and lists problems. Every change is one undo step.

In a game, add a `DialoguePlayer` component (`dialogue`: the file, `startNode`, `autoStart`) to an entity. The dialogue system runs in play mode, in `GameRunner` and in exported games; in the editor the conversation shows in a `DialogueBox` over the Game view. Game code drives it through `world.dialogues` (a `DialogueDirector`):

```swift
world.dialogues?.start(npc)                              // talk to this NPC
world.dialogues?.setVariable("questDone", true)          // shared by every dialogue
let gold = world.dialogue(for: npc)?.number("gold")      // the NPC's runner
world.dialogues?.onEvent { entity, event in
    if event.name == "openGate" { openGate() }
}
```

`DialogueRunner` plays a dialogue without the component (`start`, `advance`, `choose`, `variable` / `setVariable`, `onEvent`, `onStateChange`, `localize` or `useLocalization([key: text])`). The UI is anything that conforms to `DialoguePresenter`; the default `DialogueBox` widget shows a portrait (the speaker's initial in its color, or an image from `portraitImage`), the name, the line typed out, and the options as buttons (click, Enter / Space, or keys 1-9). Host one in your own UI with `world.dialogues?.presenter = box`.

Editor MCP clients use `dialogue.new`, `dialogue.edit {speakers, variables, addNodes, updateNodes, removeNodes, connect, start, generateKeys, layout}`, `dialogue.set`, `dialogue.get`, `dialogue.play {variables, choices, strings}` (a play-through that returns the transcript, events and final variables) and `dialogue.open`. See [MCPTools.md](MCPTools.md).

Not yet: portraits in the box come from game code (`portraitImage`), not loaded automatically from the speaker's `portrait`, and a `.ui` layout can't yet be picked as the presenter from the editor.
