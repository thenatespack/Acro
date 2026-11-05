# Editor builder tools

Builder tools let people and AI agents author game content inside the editor without outside
programs. Each one follows the same pattern as the Mesh Builder:

- **A file type** under `Assets/` (JSON, every key optional) that is the source of truth.
- **An importer** that turns it into engine objects (meshes, materials, prefabs, textures,
  sounds…), so the result is placed, packed and hot-reloaded like any asset.
- **MCP tools** (`<name>.new`, `.get`, `.set`, `.edit`, `.open`) so an agent can build and tweak
  it in a few calls, with problems reported back as warnings.
- **An editor tab** next to the Scene view with a live preview and a sidebar form; every change
  is written to the file as one undo step.

## Shipped

### Mesh Builder (`.meshbuild`)

Models built from shapes (box, sphere, dome, cylinder, cone, capsule, torus, tube, plane,
wedge, pyramid, group pivots) with a part hierarchy, colors, textures, PBR settings, glow, and
keyframe or ready-made animations (spin, bob, swing, pulse, shake). The Mesh Builder tab shows
the model in its own viewport with picking, Move / Rotate / Scale gizmos and live animation
preview. Tools: `meshBuild.new`, `meshBuild.get`, `meshBuild.set`, `meshBuild.edit`,
`meshBuild.open`. See README › Mesh Builder.

### VFX Builder (`.vfx`)

Effects as stacks of GPU particle emitters, each with placement and a start `delay`. Presets:
fire, smoke, sparks, explosion, magic hit, rain, snow, dust, portal. Imported as a prefab of
`ParticleEmitter` children (placed or spawned like a model; `ParticleEmitter.startDelay` and
`PrefabNode.particles` are new engine fields). The VFX Builder tab previews it looping with
Restart, Loop and Pause, a ground plane and a background color. Tools: `vfx.new`, `vfx.get`,
`vfx.set`, `vfx.edit`, `vfx.open`. Not done: sub-emitter links and particle textures in `.vfx`.
See README > VFX Builder.

### Sound Builder (`.sfx`)

Sound effects generated from synth parameters (square/saw/sine/noise, pitch envelope and
slide, vibrato, attack/sustain/decay, low/high-pass, arpeggio, bit crush), with presets (jump,
coin, laser, explosion, hit, power-up, blip) plus Randomize and Mutate. Rendered by pure-Swift
DSP, deterministic per seed, and loadable anywhere an audio file is (`AudioEmitter.clip`). The
Sound Builder tab has a waveform view, Play / Auto-play and the parameters form. Tools:
`sfx.new`, `sfx.get`, `sfx.set`, `sfx.edit`, `sfx.play`, `sfx.open`. See README › Sound Builder.

### Post-FX Builder (`.postfx`)

Saved camera looks: tonemapper, exposure and auto exposure, bloom, color grading (contrast,
lift, gamma, gain, saturation), vignette, chromatic aberration and film grain, in the engine's
single tonemap pass on both backends. Presets (neutral, cinematic, warm, cold, noir, retro),
assigned per camera (`Camera.postFX`) or blended by `PostFXVolume` (box or sphere, blend
distance, priority). The Post-FX tab previews a sample scene with a before/after split.
Tools: `postfx.new`, `postfx.get`, `postfx.set`, `postfx.edit`, `postfx.assign`, `postfx.open`.
Not done: depth of field, LUT grading, a split preview inside the Scene view. See README.

### Data Table (`.table`)

Typed spreadsheets for game data: columns (number, text, bool, color, enum, asset reference,
row reference) with defaults, min/max and enum options; validation warnings (wrong type,
unknown enum case, dangling asset or row reference, duplicate ids). The Data Table tab is a
grid with sort, filter, bulk edit and CSV import/export. Game code reads rows by id with typed
access (`assets.dataTable(path:)?.row("goblin")?.number("hp")`), hot-reloaded while playing.
Tools: `table.new`, `table.get`, `table.set`, `table.edit`, `table.query`, `table.importCsv`,
`table.exportCsv`, `table.open`. See README › Data Table Builder.

### Terrain Builder (`.terrain`)

Heightmap terrain with 16-bit heights, split into chunks (smooth seam normals, optional extra
LOD meshes, a triangle-mesh collider per chunk), brushes (raise, lower, smooth, flatten, noise
with radius, strength and falloff), a splat map of texture layers (flat colors, images or
`.proctex`, baked into one albedo texture), and scatter rules (mesh builds or meshes placed by
density, slope, height and layer rules on a stable seed, drawn instanced). The Terrain Builder
tab sculpts and paints by dragging on the terrain. Tools: `terrain.new`, `terrain.get`,
`terrain.set`, `terrain.edit`, `terrain.open`, `terrain.sculpt`, `terrain.paint`,
`terrain.scatter`. See README › Terrain Builder. Not yet: runtime LOD switching (the extra
LOD meshes are generated but nothing swaps them in), per-pixel GPU splat blending with normal
maps (layers are baked to one albedo), and terrain-following for other builders.

## Planned

Recommended order, grouped so each builder lands after the ones it depends on:

1. **Big gaps and quick wins:** Terrain, VFX, Post-FX, Data Table.
2. **Level building:** Pixel Sprite (makes Tilemap tiles), Tilemap, GridMap, Path (after
   Terrain, for terrain following).
3. **Characters and AI:** Character, Animation Graph (needs glTF clip import), Behavior Tree.
4. **Presentation:** UI / HUD (Dialogue's default widget), Dialogue, Material (hardest:
   shader compile for Metal and Vulkan; Terrain and mesh builds use images and `.proctex`
   until it lands).
5. **Integrators:** Timeline, then Visual Script, whose engine nodes call into most other
   builders. Its VM and core flow/data nodes can start earlier, with engine nodes added as
   each builder ships.

### 1. Terrain Builder (`.terrain`)

Outdoor ground for 3D games. The engine has no terrain system yet, so this is the largest gap.

- Heightmap terrain split into chunks with LODs, normals, and a collider for physics.
- Brushes: raise, lower, smooth, flatten, noise; radius, strength and falloff.
- Texture layers (grass, rock, dirt, sand) painted with a splat map, using images or `.proctex`.
- Scatter: props (trees, rocks, including mesh builds) placed by density, slope and height
  rules, drawn instanced.
- Tools: `terrain.new {size, resolution, seed}`, `terrain.sculpt {brush, points}`,
  `terrain.paint {layer, points}`, `terrain.scatter {asset, density, rules}`.


### 2. VFX Builder (`.vfx`)

Effects as stacks of the engine's existing GPU particle emitters (today they are edited only
through raw `ParticleEmitter` fields in the inspector).

- Several emitters per effect (fire = flames + smoke + embers), each with timing offsets.
- A looping preview with restart, a ground plane and a background color.
- Presets: fire, smoke, sparks, explosion, magic hit, rain, snow, dust, portal.
- Imported as a prefab, so an effect is placed or spawned like any model.
- Tools: `vfx.new {preset?}`, `vfx.edit {addEmitters, updateEmitters, removeEmitters}`.

### 3. Sound Builder (`.sfx`)

Game sound effects generated from parameters, the way `.proctex` generates textures.

- A synth voice: waveform (square, saw, sine, noise), pitch envelope and slide, vibrato,
  volume envelope (attack, sustain, decay), filters, arpeggio, bit crush.
- Presets with Randomize and Mutate: jump, coin, laser, explosion, hit, power-up, blip.
- Rendered at import into an audio buffer usable by `AudioEmitter.clip`; deterministic per seed.
- Tools: `sfx.new {preset?, seed?}`, `sfx.set`, `sfx.play` (preview in the editor).

### 4. Post-FX Profile Builder (`.postfx`)

Saved camera looks built on the engine's existing post-processing (tonemapping, exposure,
bloom).

- Bloom, exposure and auto-exposure, tonemapper, color grading (lift, gamma, gain,
  saturation, LUT), vignette, chromatic aberration, film grain, depth of field.
- Before/after split preview in the Scene view.
- Profiles assigned per camera or blended by volume, so areas can have their own look.
- Tools: `postfx.new {preset?}`, `postfx.set`.

### 5. Data Table Builder (`.table`)

Typed spreadsheets for game data: items, enemies, loot, waves, level settings.

- Columns with types (number, text, bool, color, enum, asset reference, row reference)
  and defaults; validation warnings for bad values.
- Grid editing with sort, filter and bulk edit; CSV import and export.
- Readable from game code by row ID with typed access; hot-reloaded while playing.
- Tools: `table.new {columns}`, `table.edit {addRows, updateRows, removeRows, columns}`,
  `table.query {filter}`.

### 6. Pixel Sprite Builder (`.sprite`)

Pixel art and sprite animation drawn inside the editor.

- Canvas with pencil, line, rectangle, fill, eraser, color picker, mirror drawing and a
  palette (custom or presets like 16- and 32-color sets).
- Layers, frames, onion skin and per-frame timing; tags name clips (idle, run, jump).
- Imported into a `SpriteAtlas` with one `SpriteClip` per tag, ready for `SpriteAnimator`;
  usable as Tilemap tiles.
- Tools: `sprite.new {width, height, palette?}`, `sprite.draw {frame, layer, pixels}`,
  `sprite.edit {addFrames, tags}`.

### 7. Tilemap Builder (`.tilemap`)

2D levels for sprite games, painted from tiles on the engine's `SpriteAtlas` / `SpriteBatch`.

- Tile sets from sprite atlases (or sliced images), with per-tile collision shape, tags and
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

### 8. GridMap Builder (`.gridmap`)

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

### 9. Path Builder (`.path`)

Splines that generate geometry along them, reusing `LineRenderer` and `CameraPath`.

- Roads, rails, rivers, fences, cables and walls: a cross-section or repeated piece along
  the curve, with banking and terrain following (once Terrain exists).
- Edit control points with gizmos in the viewport.
- Tools: `path.new {kind}`, `path.edit {points, profile}`.

### 10. Character Builder (`.character`)

Rigged characters and creatures assembled from parts.

- Body templates (humanoid, quadruped, bird, blob) with a skeleton; proportions by sliders.
- Parts and gear (heads, hair, armor, weapons) as mesh builds attached to bones, with colors.
- Stock clips per template (idle, walk, run, jump, attack, die) retargeted to the skeleton.
- Imported as a skinned prefab with an `Animator`, ready for the Animation Graph Builder.
- Tools: `character.new {template}`, `character.edit {proportions, attach, colors}`.

### 11. Animation Graph Builder (`.animgraph`)

A node editor for the engine's existing `Animator` state machine, which is only usable from code today.

- States, transitions with conditions (`greater`, `less`, `isTrue`, `triggered`), exit times
  and crossfades; 1D blend spaces; additive layers.
- Parameters panel and a live preview of the character, driving parameters by hand.
- Needs animation clips imported through the asset database (glTF clips are not yet).
- Tools: `animGraph.new`, `animGraph.edit {addStates, addTransitions, parameters}`.

### 12. Behavior Tree Builder (`.behavior`)

NPC AI as a node tree instead of hand-written code.

- Composites (sequence, selector, parallel), decorators (repeat, invert, cooldown) and
  leaves: conditions (can see target, health below, within range) and actions (move to,
  patrol, chase, flee, attack, wait, play animation).
- A blackboard of shared values; custom leaves registered from game code.
- Live debugging: the running path highlighted on a selected entity while playing.
- Tools: `behavior.new {preset?}`, `behavior.edit {addNodes, connect, blackboard}`.

### 13. UI / HUD Builder (`.ui`)

Game menus and HUDs laid out visually with the engine's widget toolkit.

- Drag-and-drop layout (stacks, anchors), text, images, buttons, bars, with theme colors.
- Bindings from widgets to game values (health → bar, score → label) and button events.
- Preview at several screen sizes and aspect ratios.
- Tools: `ui.newLayout`, `ui.editLayout {addWidgets, updateWidgets, bindings}`.

### 14. Dialogue Builder (`.dialogue`)

Branching conversations for NPCs, quests and tutorials.

- Nodes for lines, player choices, conditions, variable changes and events; speakers with
  names and portraits.
- Graph view plus a play-through preview that tracks variables.
- A runtime `DialoguePlayer` component and a default UI widget; game code reads and sets
  variables and listens for events.
- Localization keys per line.
- Tools: `dialogue.new`, `dialogue.edit {addNodes, connect, variables}`, `dialogue.play`.

### 15. Material Builder (`.material`)

A node graph for surface shaders, beyond the fixed PBR settings in `Material` today.

- Nodes: textures (images or `.proctex`), noise, math, blend, fresnel, scrolling and
  rotating UVs, time, vertex color, triplanar mapping.
- Outputs to the PBR inputs (base color, normal, metallic, roughness, emissive, opacity).
- Live preview on a sphere, cube or the selected model, with a light and background picker.
- Compiled at import into a shader variant for Metal and Vulkan; used by mesh builds,
  models, terrain layers and decals.
- Tools: `material.new {preset?}`, `material.edit {addNodes, connect, removeNodes, params}`.

### 16. Cutscene / Timeline Builder (`.timeline`)

Sequenced scenes for intros, cutscenes and scripted moments.

- Tracks for camera (`CameraPath` and cuts), entity transforms, animation clips, audio,
  particles, dialogue lines, screen fades and game events.
- Keyframes with easing (`Easing`), scrubbing and looped preview in the viewport.
- A runtime `TimelinePlayer` component with play, pause, skip and events for game code.
- Tools: `timeline.new {duration}`, `timeline.edit {addTracks, addKeys, removeKeys}`.

### 17. Visual Script Builder (`.vscript`)

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
