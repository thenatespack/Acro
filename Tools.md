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
maps (layers are baked to one albedo). Other builders follow terrain through `Terrain.heightAt`
(the Path Builder does).


### Pixel Sprite Builder (`.sprite`)

Pixel art drawn in the editor: palette-indexed cels (row strings, `.` transparent), layers with
opacity, frames with per-frame durations, and tags (loop, once, ping-pong) that become
`SpriteClip`s. Palette presets: pico8, db16, db32, gameboy, grayscale. Imported as one
nearest-filtered atlas texture (frame i in grid cell i); `SpriteAssetLibrary` hands out atlases
and animators with hot reload. The tab has pencil, line, rect, fill, eraser, picker, mirror
drawing, onion skin and a playing preview of the selected tag. Tools: `sprite.new`,
`sprite.get`, `sprite.set`, `sprite.draw`, `sprite.edit`, `sprite.open`. Not done: selections
and copy/paste between cels; layer blend modes other than normal; importing PNG sprite sheets;
frame events on tags; tool keyboard shortcuts; the Scene view doesn't draw `Sprite` components.

### Tilemap Builder (`.tilemap`)

2D levels: tile sets from a sliced sheet or packed images, with per-tile collision shapes
(full, half, slopes, polygon), one-way platforms, tags, properties and animation; layers with
draw order, parallax and opacity; flipped and rotated cells; auto-tiling terrain sets (16-tile
edges or 47-tile blob); and object points and areas for game code. Imported as layer chunk
meshes plus merged `Collider2D` shapes; `TilemapSpriteDrawer` draws through `SpriteBatch` with
parallax and animated tiles, and `assets.tilemap(path:)` reads the map. A 32-tile starter set
is written when no tile set is given. Tools: `tilemap.new`, `.get`, `.set`, `.edit`, `.open`,
`.paint`, `.fill`, `.erase`. Not done: `.sprite` tile sets (the source enum is ready); placed
prefabs don't play animated tiles or apply parallax; one-way platforms only block from below,
even when rotated; `assets.tilemap(path:)` doesn't work in cooked games (the JSON isn't
shipped); canvas keyboard shortcuts; the tab not yet seen in the running editor.

### GridMap Builder (`.gridmap`)

3D levels from modular pieces (`.meshbuild`, glTF / OBJ models, scene-file prefabs or mesh
references) on a grid, by floor and layer (floor, walls, props), with 90° rotation and flips.
Brushes: cells, line, rectangle, outline, box, enclosed flood fill and a seeded random set.
Auto-joining walls pick single, end, straight, corner, tee or cross variants. Imported as a
prefab with equal pieces drawn instanced and one merged collider per chunk per floor; the map
reimports when a piece changes. Ships a starter piece library. The tab edits floor by floor
with lower floors faded. Tools: `gridMap.new`, `.get` (with a text picture of a floor), `.set`,
`.edit`, `.open`, `.paint`, `.fill`, `.erase`. Not done: multi-cell auto-join pieces; `.prefab`
variant files as pieces, and built-in meshes inside prefab pieces; mirrored mesh-build
animations; a cache for inline glTF piece imports (slow reimports with big models); keyboard
shortcuts; faded floors not checked with every material in the running editor.

### Path Builder (`.path`)

Splines that generate geometry: swept cross-sections (flat, box, tube or a custom outline,
with cable sag) and repeated pieces (shapes, `.meshbuild`, meshes; mirrored, upright or tilted),
with per-point and automatic banking, per-point width, colliders, and terrain following on
`.terrain` heightmaps (the path reimports when the terrain is sculpted). Presets: road, rail,
river, fence, cable, wall. Spline math is shared with `LineRenderer` and `CameraPath`
(`Spline.swift`). The tab drags control points with the Move gizmo. Tools: `path.new`,
`.get`, `.set`, `.edit`, `.open`, `.sample`. Not done: carving or flattening terrain under a
road; junctions; a runtime component that moves objects along a path; adding points by
clicking the ground; miter correction for sharp profiles; a missing piece is reported with
Terrain's "scatter '<name>'" wording; the tab not yet tried in the running editor.

### Behavior Tree Builder (`.behavior`)

NPC AI: sequence, selector and parallel composites; invert, repeat, cooldown and succeed
decorators; conditions (can see target with physics line of sight, within range, health below,
blackboard check) and actions (move to, patrol, chase, flee, attack, wait, play animation, set
blackboard, custom). Presets: patrol, guard, chaser, coward. A `BehaviorTreeRunner` component
runs a tree in play mode, `ScenePlayback` and built games; game code registers custom leaves
(`BehaviorTreeLeaves.register`). The tab tints each node running / success / failure for the
selected entity while playing. Tools: `behavior.new`, `.get`, `.set`, `.edit`, `.open`,
`.assign`, `.debug`. Sequences resume their running child by default (`memory: false` for
guarded branches). Not done: a node-graph canvas (the tab is an outline); navmesh pathfinding
(movement is straight-line steering on XZ); a parented entity's local position is treated as
world space.

### UI / HUD Builder (`.ui`)

Menus and HUDs: panels, stacks, labels, images, buttons, bars and spacers placed by anchors and
offsets, themed per layout (`Widget.themeOverride`), with `{key}` text, value bindings,
`visibleWhen` and button events. Presets: hud, menu. Game code shows a layout with
`UIBuildView` (a `Widget` that reloads when the file changes) and drives it with `set(key,
value)` and `on(event)`. The tab previews at 8 screen sizes with drag to move, a widget tree
with drag-and-drop, and an Interact mode. Tools: `uiLayout.new`, `.get`, `.set`, `.edit`, `.open`
(`ui.*` is the editor's UI automation). Not done: animation and transitions; sliders, toggles
and text fields; gamepad navigation order; scaling the whole layout with screen size; images a
layout uses aren't cooked automatically (`--include`); color pickers.

### Dialogue Builder (`.dialogue`)

Branching conversations: line, choice (with conditions), condition, set, event and end nodes;
speakers; typed variables; `{variable}` text; localization keys; and a small expression
language. The checker reports missing links, unknown speakers or variables, type mismatches
and unreachable nodes. `DialoguePlayer` and `world.dialogues` run conversations for game code
(variables, events, hot reload); `DialogueBox` is the default widget behind the
`DialoguePresenter` protocol. The tab is a graph view with a play-through preview. Tools:
`dialogue.new`, `.get`, `.set`, `.edit`, `.play` (headless play-through), `.open`. Not done:
speaker portraits aren't loaded from their texture; GameRunner and built games show no box
unless the host sets `ScenePlayback.dialoguePresenter`; picking a `.ui` layout as the presenter;
clicking the box over the Game view is untested in the real app.

### Timeline Builder (`.timeline`)

Cutscenes: camera (positions, look-at, FOV, cuts, `CameraPath` moves), transform, animation,
audio (incl. `.sfx`), particles (`.vfx` or prefabs), screen fade and event tracks, keyed with
`Easing`. `TimelinePlayer` plays, pauses, seeks and skips (skip lands on the final state) and
reports events; `ScreenFade` folds into the post pass. The tab plays a copy of the scene with a
scrubbable track strip. Tools: `timeline.new`, `.get`, `.set`, `.edit`, `.open`, `.sample`.
Not done: a dialogue track; the tab's preview doesn't play animation clips or sounds; a
parented camera is posed wrong (local transforms); sounds and effects named by path need
`--include` in cooked games; the last fade stays until `stop()`; the tab not yet tried in the
running editor.

### Animation Graph Builder (`.animgraph`) and glTF clip import

glTF animations import as clips (`<file>#animation/<name>`, cached, packed, hot-reloaded);
`World.animationRig(of:)` binds an `Animator` to a placed model; `Animator` saves with scenes.
Graphs have float / bool / trigger parameters, clip or 1D blend-space states, transitions from a
state or Any State with conditions, exit time and crossfade, and additive layers;
`Animator.graph` names one and keeps its state across reloads. One play-mode system
(`addSceneAnimationSystem`) drives graph and asset-clip animators everywhere. The tab is a node
editor with a live model preview and parameter controls. Tools: `animGraph.new`, `.get`, `.set`,
`.edit`, `.open`, `.assign`. Not done: 2D blend spaces, sub-state machines, layer masks and
override layers; retargeting clips to a different skeleton layout; editing clip events;
auto-framing the preview; animators advance one at a time on the main thread.

### Character Builder (`.character`)

Rigged characters from templates (humanoid, quadruped, bird, blob) with proportion sliders,
region colors and `.meshbuild` gear attached to bones. Skeletons, skinned bodies and stock clips
(idle, walk, run, jump, attack, die, with footstep / hit events) are generated in code per
template. Imported as a prefab with an `Animator` set up: a `locomotion` blend on `speed` and
`jump` / `attack` / `die` triggers. The tab plays clips with a bones overlay. Tools:
`character.new`, `.get`, `.set`, `.edit`, `.open`, `.bones`. Not done: glTF clips on a character
skeleton; skeleton editing; per-part colors in an attachment; authored clip curves; animation
in the edit-mode Scene view; clips in GameRunner (no asset database); looks unchecked in the
running editor. The prefab writes `Animator`'s Codable layout by hand, so changing
`Animator`'s stored properties needs that copy updated (CharacterTests catches it).

### Material Builder (`.material` graphs)

Node-graph surfaces as an optional `graph` key in `.material` files: textures (images or
`.proctex`, normal maps), triplanar, noise, scrolling / rotating UVs, 24 math ops, blend modes,
fresnel, time, vertex color and more, feeding every PBR output. Presets: basic, lava, water,
hologram, stone, pulse. Compiled at import with no run-time shader compiler: generated SPIR-V /
MSL replaces `graphSurface()` in a `-O0` template (`mesh_graph.frag`); constants sit in a storage
buffer, so tweaks don't recompile. Metal and Vulkan pixels match. Works on models and mesh
builds; the tab previews on shapes or the selection. Tools: `materialGraph.new`, `.get`, `.set`,
`.edit`, `.open`, `.nodes`, `.assign` (`material.get` / `.set` edit plain materials). Not done:
terrain layers and decals; graph opacity in shadows and the depth prepass (masked graphs cast
solid shadows); planar reflections; dragging links on the canvas; UV noise shows a sphere's seam
(use `position` or `triplanar`).

### Visual Script Builder (`.vscript`)

Node-graph game logic run by a VM with no compile step (edits apply on the next frame while
playing; runaway graphs stop after 100,000 node runs). Events (lifecycle, keys, input actions,
3D / 2D collisions and triggers, timers, custom, sprite clips); flow, data and world nodes;
get / set nodes generated for every reflected component field; engine nodes (sound, effects,
raycast, forces, scenes, tweens, data tables, sprite clips). `VisualScript` components run
graphs in play mode and built games; game modules add nodes and events (`game.scriptNode`,
`world.sendScriptEvent`). The tab has typed pins, live flow highlight, hover values,
breakpoints, search-to-add and collapse-to-function. Tools: `vscript.new`, `.get`, `.set`,
`.edit`, `.nodes`, `.validate`, `.open`, `.attach`. Not done: step over / into (breakpoints pause
after the frame); macros, reroutes and node groups; find by tag (no Tag component); editing
function pins in the tab; a collapsed selection with no exec wire out reads zeros; background
imports run only structural checks; the canvas not yet seen in the running editor.

## Follow-ups

Connections between builders that waited for the merge:

- `.sprite` as a Tilemap tile source (tile i = frame i).
- A `.ui` layout as the dialogue box (`DialoguePresenter`), chosen in the editor.
- A dialogue track in Timeline.
- Visual Script nodes for animation graphs, dialogue and timelines
  (`VisualScriptNodes.register`, `VisualScriptRuntime.addEventSource`).
- Graph materials on terrain layers and decals.
- Character clips from glTF, and one clip loader: the Character tab previews with
  `AssetClipLoader` / `addAssetAnimationSystem` (AssetAnimation.swift), while play mode uses
  `addSceneAnimationSystem`.

Engine gaps the builders ran into:

- 2D physics reads each collider's own `Transform` and ignores parents, so a placed tilemap
  keeps its colliders at the origin (`world.spawnTilemapColliders(map, at:)` works around it).
- No runtime game UI layer: GameRunner and built games show layouts and the dialogue box only
  when game code adds them.
- The cooker misses files referenced by path: layout images, timeline sounds and effects by
  path, and tilemap JSON (`AssetCooker.shippedAsWritten` / `followsReferences` cover the
  `asset:<id>` cases).
- No navigation mesh; no Tag component.
- Several tabs haven't been opened in the running editor yet (Path, Tilemap, Timeline,
  Character, Visual Script, GridMap's faded floors).
