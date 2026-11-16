# Editor builder tools

Builder tools let people and AI agents author game content inside the editor without outside
programs. Each one follows the same pattern as the Mesh Builder:

- **A file type** under `Assets/` (JSON, every key optional) that is the source of truth.
- **An importer** that turns it into engine objects (meshes, materials, prefabs, textures,
  sounds…), so the result is placed, packed and hot-reloaded like any asset.
- **MCP tools** (`<name>.new`, `.get`, `.set`, `.edit`, `.open`) so an agent can build and tweak
  it in a few calls, with problems reported back as warnings. The planned sections below list
  only the extra tools or arguments specific to each builder; the standard five are assumed.
- **An editor tab** next to the Scene view with a live preview and a sidebar form; every change
  is written to the file as one undo step.

## Shipped

### Mesh Builder (`.meshbuild`)

Models built from shapes (box, sphere, dome, cylinder, cone, capsule, torus, tube, plane,
wedge, pyramid, group pivots) with a part hierarchy, colors, textures, PBR settings, glow, and
keyframe or ready-made animations (spin, bob, swing, pulse, shake). The Mesh Builder tab shows
the model in its own viewport with picking, Move / Rotate / Scale gizmos and live animation
preview. Tools: `meshBuild.new`, `meshBuild.get`, `meshBuild.set`, `meshBuild.edit`,
`meshBuild.open`. See docs/Builders.md › Mesh Builder.

### VFX Builder (`.vfx`)

Effects as stacks of GPU particle emitters, each with placement and a start `delay`. Presets:
fire, smoke, sparks, explosion, magic hit, rain, snow, dust, portal. Imported as a prefab of
`ParticleEmitter` children (placed or spawned like a model; `ParticleEmitter.startDelay` and
`PrefabNode.particles` are new engine fields). The VFX Builder tab previews it looping with
Restart, Loop and Pause, a ground plane and a background color. Tools: `vfx.new`, `vfx.get`,
`vfx.set`, `vfx.edit`, `vfx.open`. Not done: sub-emitter links and particle textures in `.vfx`.
See docs/Builders.md › VFX Builder.

### Sound Builder (`.sfx`)

Sound effects generated from synth parameters (square/saw/sine/noise, pitch envelope and
slide, vibrato, attack/sustain/decay, low/high-pass, arpeggio, bit crush), with presets (jump,
coin, laser, explosion, hit, power-up, blip) plus Randomize and Mutate. Rendered by pure-Swift
DSP, deterministic per seed, and loadable anywhere an audio file is (`AudioEmitter.clip`). The
Sound Builder tab has a waveform view, Play / Auto-play and the parameters form. Tools:
`sfx.new`, `sfx.get`, `sfx.set`, `sfx.edit`, `sfx.play`, `sfx.open`. See docs/Builders.md › Sound Builder.

### Post-FX Builder (`.postfx`)

Saved camera looks: tonemapper, exposure and auto exposure, bloom, color grading (contrast,
lift, gamma, gain, saturation), vignette, chromatic aberration and film grain, in the engine's
single tonemap pass on both backends. Presets (neutral, cinematic, warm, cold, noir, retro),
assigned per camera (`Camera.postFX`) or blended by `PostFXVolume` (box or sphere, blend
distance, priority). The Post-FX tab previews a sample scene with a before/after split.
Tools: `postfx.new`, `postfx.get`, `postfx.set`, `postfx.edit`, `postfx.assign`, `postfx.open`.
Not done: depth of field, LUT grading, a split preview inside the Scene view. See docs/Builders.md › Post-FX Builder.

### Data Table (`.table`)

Typed spreadsheets for game data: columns (number, text, bool, color, enum, asset reference,
row reference) with defaults, min/max and enum options; validation warnings (wrong type,
unknown enum case, dangling asset or row reference, duplicate ids). The Data Table tab is a
grid with sort, filter, bulk edit and CSV import/export. Game code reads rows by id with typed
access (`assets.dataTable(path:)?.row("goblin")?.number("hp")`), hot-reloaded while playing.
Tools: `table.new`, `table.get`, `table.set`, `table.edit`, `table.query`, `table.importCsv`,
`table.exportCsv`, `table.open`. See docs/Builders.md › Data Table Builder.

### Terrain Builder (`.terrain`)

Heightmap terrain with 16-bit heights, split into chunks (smooth seam normals, optional extra
LOD meshes, a triangle-mesh collider per chunk), brushes (raise, lower, smooth, flatten, noise
with radius, strength and falloff), a splat map of texture layers (flat colors, images or
`.proctex`, baked into one albedo texture), and scatter rules (mesh builds or meshes placed by
density, slope, height and layer rules on a stable seed, drawn instanced). The Terrain Builder
tab sculpts and paints by dragging on the terrain. Tools: `terrain.new`, `terrain.get`,
`terrain.set`, `terrain.edit`, `terrain.open`, `terrain.sculpt`, `terrain.paint`,
`terrain.scatter`. See docs/Builders.md › Terrain Builder. Not yet: runtime LOD switching (the extra
LOD meshes are generated but nothing swaps them in), per-pixel GPU splat blending with normal
maps (layers are baked to one albedo), and terrain-following for other builders.

## Planned

Recommended order (everything under Shipped is done), grouped so each builder lands after the ones it depends on:

1. **Level building:** Pixel Sprite (makes Tilemap tiles), Tilemap, GridMap, Path (adds
   terrain following, the Terrain Builder's open item).
2. **Characters and AI:** glTF animation clip import (engine work, not a builder; built with
   the Animation Graph branch), then Character and Animation Graph, which both need it;
   Behavior Tree.
3. **Presentation:** UI / HUD (Dialogue's default widget), Dialogue, Material (hardest:
   shader compile for Metal and Vulkan; Terrain and mesh builds use images and `.proctex`
   until it lands).
4. **Integrators:** Timeline, then Visual Script, whose engine nodes call into most other
   builders. Its VM and core flow/data nodes can start earlier, with engine nodes added as
   each builder ships.

### 1. Pixel Sprite Builder (`.sprite`)

Pixel art and sprite animation drawn inside the editor.

- Canvas with pencil, line, rectangle, fill, eraser, color picker, mirror drawing and a
  palette (custom or presets like 16- and 32-color sets).
- Layers, frames, onion skin and per-frame timing; tags name clips (idle, run, jump).
- Imported into a `SpriteAtlas` with one `SpriteClip` per tag, ready for `SpriteAnimator`;
  usable as Tilemap tiles.
- Tools: `sprite.new {width, height, palette?}`, `sprite.draw {frame, layer, pixels}`,
  `sprite.edit {addFrames, tags}`.

**Status:** built, awaiting merge. **Gaps:** selections and copy/paste between cels; layer
blend modes other than normal; importing PNG sprite sheets into a `.sprite`; frame events on
tags; tool keyboard shortcuts; the Scene view doesn't draw `Sprite` components (it never has);
Tilemap doesn't take `.sprite` as a tile source yet (tile i = frame i, ready to connect).

### 2. Tilemap Builder (`.tilemap`)

2D levels for sprite games, painted from tiles on the engine's `SpriteAtlas` / `SpriteBatch`.

- Tile sets from `.sprite` files, sprite atlases or sliced images, with per-tile collision shape, tags and
  custom properties.
- Several layers (background, ground, foreground) with draw order, parallax and opacity.
- Brushes: pencil, rectangle, flood fill, eraser, random from a set; flip and rotate tiles.
- Auto-tiling rules (terrain sets) so edges and corners pick the right tile as you paint.
- Animated tiles (water, torches) using `SpriteClip` frames.
- Collision built from tiles into merged `Collider2D` shapes for 2D physics, with one-way
  platforms.
- Drawn in chunks with batched sprites; object points (spawns, triggers) for game code.
- Tools: `tilemap.new {tileSize, size, tileset}`, `tilemap.paint {layer, tile, cells}`,
  `tilemap.fill {layer, tile, rect}`, `tilemap.erase {layer, cells}`, `tilemap.edit`.

**Status:** built, awaiting merge. **Gaps:** `.sprite` tile sets (the source enum is ready);
placed prefabs don't play animated tiles or apply parallax (only `TilemapSpriteDrawer`
does); one-way platforms only block from below, even when the tile is rotated; the engine
has no SpriteAtlas asset files, so sources are a sliced sheet or packed images;
`assets.tilemap(path:)` doesn't work in cooked games (the cooker ships the prefab and
texture, not the JSON); no keyboard shortcuts for the canvas tools; the tab's drawing not yet
seen in the running editor. **Engine limit:** 2D physics reads each collider's own
`Transform` and ignores parents, so a tilemap prefab placed away from the origin keeps its
colliders at the origin (`world.spawnTilemapColliders(map, at:)` is the workaround; the
real fix is parent-aware 2D colliders).

### 3. GridMap Builder (`.gridmap`)

3D levels built from modular pieces on a grid: dungeons, buildings, city blocks.

- A piece library (mesh builds, models or prefabs) with size, pivot and footprint per piece.
- Paint pieces cell by cell on a chosen floor level, with 90° rotation, flips and layers
  (floor, walls, props).
- Brushes: single, line, rectangle, fill, eraser, random from a set.
- Auto-joining: walls, fences and floors pick straight, corner, T or end pieces from neighbors.
- Floor-by-floor editing with a height slider; levels below shown faded.
- Imported as a prefab with pieces drawn instanced and colliders merged per chunk.
- Tools: `gridMap.new {cellSize, library}`, `gridMap.paint {piece, cells, rotation}`,
  `gridMap.fill {piece, box}`, `gridMap.erase {cells}`, `gridMap.edit`.

**Status:** built, awaiting merge. **Gaps:** auto-joining treats pieces as one cell
(multi-cell join pieces aren't handled); `.prefab` variant files can't be pieces, and
scene-file prefab pieces drop built-in meshes like "cube"; mirrored pieces keep their
mesh-build animations unmirrored; glTF pieces are imported inline with no cache (slow
reimports for big textured models); no keyboard shortcuts for rotate / flip; faded lower
floors not checked in the running editor with every material.

### 4. Path Builder (`.path`)

Splines that generate geometry along them, reusing `LineRenderer` and `CameraPath`.

- Roads, rails, rivers, fences, cables and walls: a cross-section or repeated piece along
  the curve, with banking and terrain following on `.terrain` heightmaps (this also covers
  the Terrain Builder's open "terrain-following for other builders" item).
- Edit control points with gizmos in the viewport.
- Tools: `path.new {kind}`, `path.edit {points, profile}`.

**Status:** built, awaiting merge (terrain following done, which closes the Terrain
Builder's open item). **Gaps:** carving or flattening terrain under a road; junctions
between paths; a runtime component that moves objects along a path; adding points by
clicking the ground in the tab; miter correction for sharp-cornered profiles; the tab not
yet tried in the running editor; a missing piece asset is reported with Terrain's
"scatter '<name>'" wording.

### 5. Character Builder (`.character`)

Rigged characters and creatures assembled from parts.

- Body templates (humanoid, quadruped, bird, blob) with a skeleton; proportions by sliders.
- Parts and gear (heads, hair, armor, weapons) as mesh builds attached to bones, with colors.
- Stock clips per template (idle, walk, run, jump, attack, die) retargeted to the skeleton
  (needs glTF animation clip import).
- Imported as a skinned prefab with an `Animator`, ready for the Animation Graph Builder.
- Tools: `character.new {template}`, `character.edit {proportions, attach, colors}`.

**Status:** built, awaiting merge (stock clips generated in code per template, not from
glTF). **Gaps:** no glTF clips on a character skeleton; no skeleton editing or custom bones;
an attachment's recolor applies to the whole model (no per-part colors); no authored clip
curves; characters stay in rest pose in the edit-mode Scene view (they animate only in play
mode and in the tab); GameRunner has no asset database, so `.character` clips don't play
there; how the bodies and clips look is unchecked in the running editor. **Fragile:** the
character prefab writes `Animator`'s Codable layout by hand (`PrefabNode` can't hold an
`Animator`), so changing `Animator`'s stored properties breaks it until the copy is updated.
**Merge:** its clip asset kind and play-mode Animator system overlap the Animation Graph
branch; keep one of each.

### 6. Animation Graph Builder (`.animgraph`)

A node editor for the engine's existing `Animator` state machine, which is only usable from code today.

- States, transitions with conditions (`greater`, `less`, `isTrue`, `triggered`), exit times
  and crossfades; 1D blend spaces; additive layers.
- Parameters panel and a live preview of the character, driving parameters by hand.
- Needs animation clips imported through the asset database; glTF clip import is not done
  yet and is listed in the recommended order above.

**Status:** built, awaiting merge, together with glTF animation clip import (glTF importer
v4: one `animation/<name>` sub-asset per clip, cached and packed, hot-reloaded;
`World.animationRig(of:)` binds an Animator to a placed prefab; `Animator` saves with scenes).
**Gaps:** 2D blend spaces, sub-state machines, layer masks and override (non-additive)
layers; retargeting a clip onto a skeleton with a different node layout (clips play only on
their own file's prefab or an identical layout); editing clip events; the preview camera
doesn't auto-frame the model; the scene animation system advances animators one at a time
on the main thread. **Merge:** the Character branch also adds `AssetKind.animation` (same
names) but uses `#clip/<name>` sub-asset ids where this uses `#animation/<name>`, and both
add a play-mode Animator system; keep one id scheme and one system (this one also applies
`Animator.graph` and resolves `asset:` clips). This branch adds `Animator.graph`, so
Character's hand-written `Animator` JSON needs checking.
- Tools: `animGraph.new`, `animGraph.edit {addStates, addTransitions, parameters}`.

### 7. Behavior Tree Builder (`.behavior`)

NPC AI as a node tree instead of hand-written code.

- Composites (sequence, selector, parallel), decorators (repeat, invert, cooldown) and
  leaves: conditions (can see target, health below, within range) and actions (move to,
  patrol, chase, flee, attack, wait, play animation).
- A blackboard of shared values; custom leaves registered from game code.
- Live debugging: the running path highlighted on a selected entity while playing.
- Tools: `behavior.new {preset?}`, `behavior.edit {addNodes, connect, blackboard}`.

**Status:** built, awaiting merge. **Gaps:** the tab is an indented outline, not a node-graph
canvas; no navmesh pathfinding (the engine has no navigation; movement is straight-line
steering on XZ); a parented entity's local position is treated as world space.

### 8. UI / HUD Builder (`.ui`)

Game menus and HUDs laid out visually with the engine's widget toolkit.

- Drag-and-drop layout (stacks, anchors), text, images, buttons, bars, with theme colors.
- Bindings from widgets to game values (health → bar, score → label) and button events.
- Preview at several screen sizes and aspect ratios.
- Tools: `uiLayout.new`, `uiLayout.edit {addWidgets, updateWidgets, bindings}` (`ui.*` is
  taken by the editor's UI automation tools).

**Status:** built, awaiting merge. **Gaps:** animation and transitions; sliders, toggles and
text fields as layout widgets; explicit gamepad navigation order; scaling the whole layout
with screen size; the cooker doesn't pull in images a layout uses (they need `--include`);
color fields are text boxes, not pickers; no runtime game UI layer to show layouts in
GameRunner / exported games without game code.

### 9. Dialogue Builder (`.dialogue`)

Branching conversations for NPCs, quests and tutorials.

- Nodes for lines, player choices, conditions, variable changes and events; speakers with
  names and portraits.
- Graph view plus a play-through preview that tracks variables.
- A runtime `DialoguePlayer` component and a default UI widget; game code reads and sets
  variables and listens for events.
- Localization keys per line.
- Tools: `dialogue.new`, `dialogue.edit {addNodes, connect, variables}`, `dialogue.play`.

**Status:** built, awaiting merge. **Gaps:** speaker portraits aren't loaded from their
texture (the box shows the speaker's initial unless game code sets an image); GameRunner and
exported games show no box unless the host sets `ScenePlayback.dialoguePresenter`; no way to
pick a `.ui` layout as the presenter (the `DialoguePresenter` protocol is ready for it);
clicking the box over the Game view is untested in the real app (Enter / Space work).

### 10. Material Builder (`.material`)

A node graph for surface shaders, beyond the fixed PBR settings in `Material` today.

- Nodes: textures (images or `.proctex`), noise, math, blend, fresnel, scrolling and
  rotating UVs, time, vertex color, triplanar mapping.
- Outputs to the PBR inputs (base color, normal, metallic, roughness, emissive, opacity).
- Live preview on a sphere, cube or the selected model, with a light and background picker.
- Compiled at import into a shader variant for Metal and Vulkan; used by mesh builds,
  models, terrain layers and decals.
- Tools: `materialGraph.new {preset?}`, `materialGraph.edit {addNodes, connect, removeNodes,
  params}` (`material.get` / `material.set` already edit plain PBR materials).

**Status:** built, awaiting merge. Graphs are an optional `graph` key in `.material` files and
compile at import with no runtime shader compiler: generated SPIR-V / MSL replaces a
`graphSurface()` body in a `-O0` template shader (`mesh_graph.frag`); constants live in a
storage buffer, so tweaking numbers doesn't recompile. Metal and Vulkan pixels match.
**Gaps:** terrain layers and decals can't use graph materials (terrain still bakes layers to
one albedo); graph opacity doesn't shape shadows or the depth prepass (masked graph
materials cast solid shadows); graph materials don't receive planar reflections; links
can't be dragged on the canvas (link from the sidebar); the preview's "selected" shape uses
the first mesh under the selection at unit scale; UV-based noise shows a sphere's UV seam
(use `position` or `triplanar`). **Risky shared changes to review at merge:**
`mesh_surface.glsl` (new code behind `#ifdef MATERIAL_GRAPH`; existing shader outputs
byte-identical), `SceneRenderer` (graph pipeline key, per-material storage buffer, push
constants), `Material` / `MaterialAsset`, the shader compile scripts (`-O0` marker), and
`material.set` / the inspector's material form now start from the file as written.

### 11. Cutscene / Timeline Builder (`.timeline`)

Sequenced scenes for intros, cutscenes and scripted moments.

- Tracks for camera (`CameraPath` and cuts), entity transforms, animation clips, audio,
  particles, dialogue lines, screen fades and game events.
- Keyframes with easing (`Easing`), scrubbing and looped preview in the viewport.
- A runtime `TimelinePlayer` component with play, pause, skip and events for game code.
- Tools: `timeline.new {duration}`, `timeline.edit {addTracks, addKeys, removeKeys}`.

**Status:** built, awaiting merge. **Gaps:** no dialogue track (one enum case to add after
merge); the tab's preview doesn't play animation clips or sounds (only play mode does);
camera tracks set local transforms, so a parented camera is posed wrong; sounds and effects
named by path need `--include` in cooked games (`asset:<id>` references ship); a finished
timeline leaves its last fade on screen until `stop()`; the tab not yet tried in the running
editor.

### 12. Visual Script Builder (`.vscript`)

Game logic as node graphs, Blueprint-style, so people can script without writing Swift and
without building a game module. Graphs live alongside Swift code: a game can mix both.

- **Graphs:** event graphs attached to an entity or prefab through a `VisualScript`
  component; functions and macros as reusable sub-graphs; a scene-level graph for game
  rules. Graph-level variables (typed, with defaults, shown in the inspector per instance).
- **Events:** start, update, fixed update, destroy; input actions pressed / released
  (`InputActions`); collision and trigger enter / exit (3D and 2D physics); timers; custom
  events sent between graphs; animation, sprite clip and timeline events.
- **Nodes:**
  - Flow: branch, sequence, for-each, while, gate, do-once, delay, flip-flop, switch on enum.
  - Data: math, vectors, comparison, random, string format, arrays and maps.
  - World: spawn and destroy entities and prefabs, find by name or tag, get / set
    transform, add / remove components.
  - Components: get / set nodes generated automatically for every reflected field
    (`Reflection` / `ComponentRegistry`), so game components show up with no extra code.
  - Engine: play sound, spawn VFX, raycast, apply force, play animation, load scene,
    tween, start dialogue or timeline, read data table rows.
- **Typed pins** with colors per type, automatic conversion nodes, and errors shown on the
  node (unconnected required input, type mismatch, unreachable code).
- **Swift interop:** game modules register custom nodes and events with a small API
  (`game.scriptNode("mygame.heal") { … }`); graphs can call Swift functions and Swift can
  send events to graphs.
- **Editor:** a graph tab with search-to-add (filtered by the dragged pin's type), comments
  and groups, reroute points, copy / paste, and collapse-to-function.
- **Debugging while playing:** live flow highlighting along wires, breakpoints on nodes,
  step over / into, and hover to see pin values; per-graph time in the profiler.
- **Runtime:** interpreted by a compact VM with no compile step, so edits apply instantly
  while the game runs; graphs are packed with the game like any asset.
- Tools: `vscript.new {target?, template?}`,
  `vscript.edit {addNodes, connect, disconnect, removeNodes, variables}`,
  `vscript.nodes {search}` (list available nodes and pins), `vscript.validate`,
  `vscript.open`.

**Status:** built, awaiting merge (VM, events, flow/data/world nodes, auto-generated
component get/set nodes, engine nodes for features on main, Swift interop, graph tab with
flow highlight, hover values and breakpoints). **Gaps:** step over / into (breakpoints pause
after the frame; the VM can't suspend mid-frame); macros, reroute points and node groups;
play animation, dialogue and timeline nodes (to add through `VisualScriptNodes.register` /
`VisualScriptRuntime.addEventSource` once those builders merge); find by tag (main has no
Tag component); editing a function's input / output pins in the tab (only through
`vscript.edit {functions}`); a selection collapsed to a function with no exec wire leaving
it reads its outputs as zero; background imports run only structural checks (the node
registry is main-actor); the canvas not yet seen in the running editor. Every play session
now always adds three `vscript.*` systems.
