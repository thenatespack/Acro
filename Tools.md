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

Models built from shapes (box, sphere, dome, cylinder, cone, capsule, torus, tube, plane, sweep, loft,
wedge, pyramid, group pivots) with a part hierarchy, colors, textures, PBR settings, glow, and
keyframe or ready-made animations (spin, bob, swing, pulse, shake). The Mesh Builder tab shows
the model in its own viewport with picking, Move / Rotate / Scale gizmos and live animation
preview. Tools: `meshBuild.new`, `meshBuild.get`, `meshBuild.set`, `meshBuild.edit`,
`meshBuild.open`, `meshBuild.preview`, `meshBuild.examples`. See docs/Builders.md › Mesh Builder.
0.17.0 agent-results work:
Agent feedback loop: every result carries `bounds` (size, min, max, base; per-part boxes in
`get`) and spatial warnings (floating, buried, hidden, zero/negative size, out-of-scale parts, a
model off y=0), measured on the generated geometry through the parent chain, mirror / repeat
copies included (the scale check counts each source part once).
`meshBuild.preview` renders a 2x2 PNG (orthographic front/right/top, 3/4 perspective) of the
model in a world of its own, with grid, labels, highlight outline and animation posing (needs the
editor window). `meshBuild.examples` returns three warning-free builds; the tool docs now state
the axes, origin, rotation order, cylinder orientation and reference sizes.
Shapes: `bevel` (rounded boxes and cylinder rims), `lathe` and `extrude` (`profile` in meters,
`size` multiplies it; bad profiles warn and build nothing).
Symmetry: `mirror` ("x" or ["x","z"]) and `repeat` {count, offset, radial} copy a part and its
subtree (repeat, then mirror); mirror copies swap Left/Right, Top/Bottom, Front/Back in names
and play mirrored animations; results list them in `copies`. Importer version 2.
Curves: `sweep` (a circle of `radius` or a `profile` along a centripetal Catmull-Rom `path`,
rotation-minimizing frames, `radii` taper, `closed` loops, `smooth: false` mitred corners, capped
ends) and `loft` (`sections` {at, size, roundness superellipse 2^r, or profile} along `axis`
y/z/x, monotone cubic between sections or straight panels, auto-aligned rings, hard profile
corners, capped ends); `deform` on any mesh part (taper, bend, twist, noise, in order, before
mirroring) with edge-length `subdivide` (0-6, default 3, 60k-triangle cap) and normals recomputed
keeping hard edges. Mesh Builder rows for path points, loft sections and deformers; three new
examples (sailboat, gnarled tree, desk lamp). Importer version 3.
Curves not done: sweep profiles are always closed (no open ribbons such as a sail cross-section
or a leaf); no per-point twist or roll along a sweep (the frame is rotation-minimizing only, no
`up` hint); loft sections can't rotate (every section is perpendicular to the axis, so no curved
spine such as a banana or a swan neck; bend it with `deform` instead); deformers always work
along the part's Y (no bend or taper along X or Z; rotate the part instead); bend has no
`center`/range (it bends the whole height); noise is isotropic (no stretched bark grain); UVs are
stretched by deformers; no self-intersection warning for sweeps that cross themselves; the
editor has no viewport handles for path points or sections (number rows only, no insert or
reorder); deformed parts are rebuilt on every check (no geometry cache), so a build with many
large noisy parts takes a second or so to check in release.
Not done: no warning for rotations that make no visible difference (round shapes); spatial checks
use rest-pose AABBs, so a rotated part's box can hide a small gap and parts that collide only
while animating aren't caught; `bounds` in a posed preview are still the rest pose's; preview
labels overlap when part centers line up. Bevel on extrude; a 2D profile editor in the viewport
(number rows only, no insert or reorder); partial-angle or thin-shell lathes, extrude holes;
open lathe ends on the axis use the slant normal; lathe caps use lathe
UVs; the 40° sharp-edge threshold is fixed. No `mirrorName` key (naming rule is fixed); renaming
a source doesn't rename tracks or `partColors` that name its copies explicitly; a drag starting
on a copy may move it for that one drag before selection jumps to the source; mirrored textures
read backwards.

### VFX Builder (`.vfx`)

Effects as stacks of GPU particle emitters, each with placement and a start `delay`. Presets:
fire, smoke, sparks, explosion, magic hit, rain, snow, dust, portal. Imported as a prefab of
`ParticleEmitter` children (placed or spawned like a model; `ParticleEmitter.startDelay` and
`PrefabNode.particles` are new engine fields). The VFX Builder tab previews it looping with
Restart, Loop and Pause, a ground plane and a background color. Tools: `vfx.new`, `vfx.get`,
`vfx.set`, `vfx.edit`, `vfx.open`. Not done in 0.15.0: sub-emitter links and particle textures in `.vfx`.
See docs/Builders.md › VFX Builder.
0.16.0 gap-fill: particle
textures (image, `.proctex`, `.sprite` with tag, flipbooks) and sub-emitter links (birth, death,
collision; new birth trigger in the particle shaders) done, GPU-tested on Metal and Vulkan.
Touches shared particle shaders, `ParticleSystem` (4 counts per workgroup) and
`PrefabNode.subEmitterNodes`. Still not done: `vfx.new` / `vfx.get` don't report import warnings
(`AssetDatabase` keeps no per-asset warnings); sub-emitters can't nest (runtime limit); long
emitter rows are cut off in the tab.

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
Not done in 0.15.0: depth of field, LUT grading, a split preview inside the Scene view. See docs/Builders.md › Post-FX Builder.
0.16.0 gap-fill: all of the
above done, GPU-tested on Metal and Vulkan with existing looks byte-identical: depth of field
(`dof.frag` before bloom; focal length is a setting, `focusTarget` auto-focus), LUT grading
(`LUTImporter` for `.cube` and strip PNGs, applied after tonemapping and before lift/gain so
ScreenFade is unchanged; PostFX importer version 2), Scene view split preview
(`view.scenePostFX`, View menu). `tonemap.frag` push constants are now 120 of 128 bytes. Not
done: gizmos get graded with the scene when the preview is on; `view.screenshot {source:
"viewport"}` skips the preview; the `lut` field is plain text (no picker, no neutral strip
maker); a strip PNG on the normal texture importer breaks under texture compression;
transparent surfaces take the blur of what's behind them (prepass is opaque only); engine users
without `SceneRenderer` must set `PostProcessor.assets` for LUTs.

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
0.16.0 gap-fill: runtime LOD
switching (new `MeshLOD` component, skirts between chunks, `lodDistance`; editor views now
switch too via `shadowFocus`), per-pixel GPU splat blending of up to 8 layers with normal maps
(`mesh_terrain.frag` through the material-graph path, key "terrain-splat"), and graph
`.material` files as layers (alpha-blended overlay pass) done, GPU-tested on Metal and Vulkan.
Importer version 1 → 4; `.terrain` heights and `writeTerrain` unchanged. Still not done: overlay and
ground pick LOD levels independently (can differ for a frame); one LOD viewpoint per frame for
all views; graph layers get 4 textures (the mask takes the fifth); graph layers aren't in the
baked albedo; the overlay lift may show at grazing angles; atlas cells clamp rather than wrap
(half-texel seam at tile repeats), layer images resampled to one cell size (16–512); a terrain
looks washed out for a frame while textures load; more than 8 layers falls back to the baked
albedo.


### Pixel Sprite Builder (`.sprite`)

Pixel art drawn in the editor: palette-indexed cels (row strings, `.` transparent), layers with
opacity, frames with per-frame durations, and tags (loop, once, ping-pong) that become
`SpriteClip`s. Palette presets: pico8, db16, db32, gameboy, grayscale. Imported as one
nearest-filtered atlas texture (frame i in grid cell i); `SpriteAssetLibrary` hands out atlases
and animators with hot reload. The tab has pencil, line, rect, fill, eraser, picker, mirror
drawing, onion skin and a playing preview of the selected tag. Tools: `sprite.new`,
`sprite.get`, `sprite.set`, `sprite.draw`, `sprite.edit`, `sprite.open`. Not done in 0.15.0: selections
and copy/paste between cels; layer blend modes other than normal; importing PNG sprite sheets;
frame events on tags; tool keyboard shortcuts; the Scene view doesn't draw `Sprite` components.
0.16.0 gap-fill: all of the
above done: selections and copy/paste (tab, `sprite.draw` move/copy/clear, `sprite.edit
copyCels`), PNG sheet import (`sprite.importSheet`, texture inspector row), tag frame events,
canvas shortcuts (new `EditorShortcutClaiming`), blend modes (multiply, add, screen, overlay),
`SceneSpriteDrawer` draws `Sprite`s in Scene/Game views with depth, tab checked in the running
editor. Still not done: clicking a sprite's quad doesn't select it (only its icon) and Frame
Selection zooms too close (`ViewportToolContext.worldBounds` only knows meshes); sprites draw
after gizmos and can cover them; atlases registered by game code under non-`.sprite` keys don't
show in editor views; `merged` copies and `compositeRows` ignore blend modes and opacity.

### Tilemap Builder (`.tilemap`)

2D levels: tile sets from a sliced sheet or packed images, with per-tile collision shapes
(full, half, slopes, polygon), one-way platforms, tags, properties and animation; layers with
draw order, parallax and opacity; flipped and rotated cells; auto-tiling terrain sets (16-tile
edges or 47-tile blob); and object points and areas for game code. Imported as layer chunk
meshes plus merged `Collider2D` shapes; `TilemapSpriteDrawer` draws through `SpriteBatch` with
parallax and animated tiles, and `assets.tilemap(path:)` reads the map. A 32-tile starter set
is written when no tile set is given. Tools: `tilemap.new`, `.get`, `.set`, `.edit`, `.open`,
`.paint`, `.fill`, `.erase`. Not done in 0.15.0: `.sprite` tile sets (the source enum is ready); placed
prefabs don't play animated tiles or apply parallax; one-way platforms only block from below,
even when rotated; `assets.tilemap(path:)` doesn't work in cooked games (the JSON isn't
shipped); canvas keyboard shortcuts; the tab not yet seen in the running editor.
0.16.0 gap-fill: all of the
above done: `.sprite` tile sets (tile i = frame i, tags animate), 2D physics now uses world
poses through parents (`Physics2DECS`), `AssetCooker.keepsSource` ships tilemap JSON, new `TilemapMotion` component plays animated
tiles and parallax in placed prefabs (`builtin.tilemapMotion`), one-way platforms follow
rotation and flips, canvas shortcuts (Fill is G, since F frames the selection), tab checked in
the running editor. Still not done: sideways one-way platforms aren't merged down a column (one box
per cell); parallax ignores parent scale; `TilemapMotion` doesn't run in edit mode; the toolbar
is too wide for the panel and squeezes the file name.

### GridMap Builder (`.gridmap`)

3D levels from modular pieces (`.meshbuild`, glTF / OBJ models, scene-file prefabs or mesh
references) on a grid, by floor and layer (floor, walls, props), with 90° rotation and flips.
Brushes: cells, line, rectangle, outline, box, enclosed flood fill and a seeded random set.
Auto-joining walls pick single, end, straight, corner, tee or cross variants. Imported as a
prefab with equal pieces drawn instanced and one merged collider per chunk per floor; the map
reimports when a piece changes. Ships a starter piece library. The tab edits floor by floor
with lower floors faded. Tools: `gridMap.new`, `.get` (with a text picture of a floor), `.set`,
`.edit`, `.open`, `.paint`, `.fill`, `.erase`. Not done in 0.15.0: multi-cell auto-join pieces; `.prefab`
variant files as pieces, and built-in meshes inside prefab pieces; mirrored mesh-build
animations; a cache for inline glTF piece imports (slow reimports with big models); keyboard
shortcuts; faded floors not checked with every material in the running editor.
0.16.0 gap-fill: all of the
above done: piece import cache (`GridMapPieceCache`, also reimports when a piece's buffers or
textures change), multi-cell auto-join pieces (brushes lay them side by side), `.prefab`
variants and built-in meshes as pieces (`GridMapPieceVariants`, variants applied to the base's
data off the main thread), mirrored mesh-build animations, keyboard shortcuts, faded floors
checked in the running editor (glowing parts now fade too). `World.stableID` is now
`nonisolated`. Still not done: faded pieces show their inner surfaces through themselves (see-through
objects don't write depth; needs a renderer feature); variants ignore where an added child sits
among its siblings; nested prefab instances inside a variant's base aren't synced.

### Path Builder (`.path`)

Splines that generate geometry: swept cross-sections (flat, box, tube or a custom outline,
with cable sag) and repeated pieces (shapes, `.meshbuild`, meshes; mirrored, upright or tilted),
with per-point and automatic banking, per-point width, colliders, and terrain following on
`.terrain` heightmaps (the path reimports when the terrain is sculpted). Presets: road, rail,
river, fence, cable, wall. Spline math is shared with `LineRenderer` and `CameraPath`
(`Spline.swift`). The tab drags control points with the Move gizmo. Tools: `path.new`,
`.get`, `.set`, `.edit`, `.open`, `.sample`. Not done in 0.15.0: carving or flattening terrain under a
road; junctions; a runtime component that moves objects along a path; adding points by
clicking the ground; miter correction for sharp profiles; a missing piece is reported with
Terrain's "scatter '<name>'" wording; the tab not yet tried in the running editor.
0.16.0 gap-fill: all of the
above done: `PathFollower` component (loop / ping-pong, orient, events; play mode, exports,
GameRunner), click to add or insert points, `path.flattenTerrain` (flatten, carve, raise)
writing the `.terrain`, T and X junctions (`junctions`, `addJunctions`), miter correction,
"piece" wording, tab checked in the running editor. `AssetCooker.keepsSource` is now `sprite`, `tilemap`, `path`, `terrain`. Still not done: `PathFollower.path` as a plain file path needs `--include` (use
`asset:<id>`); terrain shaping ignores banking and shapes each path alone; junctions of three
or more roads aren't merged, no roundabouts; a faint seam where a patch meets a box road's edge
and the main road's center line runs through the junction; cut-back assumes straight roads
at the crossing; `path.get` doesn't report junctions; side-offset pieces (lamps, posts) aren't
mitered.

### Behavior Tree Builder (`.behavior`)

NPC AI: sequence, selector and parallel composites; invert, repeat, cooldown and succeed
decorators; conditions (can see target with physics line of sight, within range, health below,
blackboard check) and actions (move to, patrol, chase, flee, attack, wait, play animation, set
blackboard, custom). Presets: patrol, guard, chaser, coward. A `BehaviorTreeRunner` component
runs a tree in play mode, `ScenePlayback` and built games; game code registers custom leaves
(`BehaviorTreeLeaves.register`). The tab tints each node running / success / failure for the
selected entity while playing. Tools: `behavior.new`, `.get`, `.set`, `.edit`, `.open`,
`.assign`, `.debug`. Sequences resume their running child by default (`memory: false` for
guarded branches). Not done in 0.15.0: a node-graph canvas (the tab is an outline); navmesh pathfinding
(movement is straight-line steering on XZ); a parented entity's local position is treated as
world space.
0.16.0 gap-fill: node-graph
canvas (drag to reparent / reorder), world-space movement under parents, and grid navigation
done (`Navigation.swift`: walkable grid baked from static colliders, A* with smoothing,
`world.findPath`, `NavigationArea` component, `behavior.navigation` tool; moveTo, patrol, chase
and flee follow paths). Tab checked in the running editor. Still not done: a true multi-layer navmesh
(no stacked floors, no walking under bridges), moving obstacles, avoidance between NPCs, drawing
the grid in the Scene view; the first bake happens on the first frame something walks (can stall
near the 250k-cell cap); a grid baked in edit mode doesn't carry into play mode; the canvas is
narrow next to the sidebar and clips parameter summaries.

### UI / HUD Builder (`.ui`)

Menus and HUDs: panels, stacks, labels, images, buttons, bars and spacers placed by anchors and
offsets, themed per layout (`Widget.themeOverride`), with `{key}` text, value bindings,
`visibleWhen` and button events. Presets: hud, menu. Game code shows a layout with
`UIBuildView` (a `Widget` that reloads when the file changes) and drives it with `set(key,
value)` and `on(event)`. The tab previews at 8 screen sizes with drag to move, a widget tree
with drag-and-drop, and an Interact mode. Tools: `uiLayout.new`, `.get`, `.set`, `.edit`, `.open`
(`ui.*` is the editor's UI automation). Not done in 0.15.0: animation and transitions; sliders, toggles
and text fields; gamepad navigation order; scaling the whole layout with screen size; images a
layout uses aren't cooked automatically (`--include`); color pickers.
0.16.0 gap-fill: all of the
above done: runtime game UI layer (`UILayoutPlayer` component, `world.gameUI` / `GameUILayer`
in the Game view, GameRunner and exports; `uiLayout.place`), layout images cooked (`ui` in
`followsReferences`, with Timeline's `pathReferences` hunk copied in), `scaleMode` scaling,
slider / toggle / text field widgets bound to keys, show / hide transitions and tweens,
gamepad navigation order, color pickers. Tab checked in the running editor. Still not done: the
editor preview's Interact mode doesn't pass typing to text fields; a focused `TextField` keeps
all four arrow keys, so a gamepad can't leave it; a `UILayoutPlayer` naming its layout by path
isn't followed by the cooker; transitions only step while the layout is drawn.

### Dialogue Builder (`.dialogue`)

Branching conversations: line, choice (with conditions), condition, set, event and end nodes;
speakers; typed variables; `{variable}` text; localization keys; and a small expression
language. The checker reports missing links, unknown speakers or variables, type mismatches
and unreachable nodes. `DialoguePlayer` and `world.dialogues` run conversations for game code
(variables, events, hot reload); `DialogueBox` is the default widget behind the
`DialoguePresenter` protocol. The tab is a graph view with a play-through preview. Tools:
`dialogue.new`, `.get`, `.set`, `.edit`, `.play` (headless play-through), `.open`. Not done in 0.15.0:
speaker portraits aren't loaded from their texture; GameRunner and built games show no box
unless the host sets `ScenePlayback.dialoguePresenter`; picking a `.ui` layout as the presenter;
clicking the box over the Game view is untested in the real app.
0.16.0 gap-fill: all of the
above done: `.ui` layouts as the dialogue presenter (`DialogueLayoutPresenter` via
`DialogueLayoutKeys`; `DialogueView` picks the default box or a layout; `DialoguePlayer.uiLayout`
or the file's `uiLayout`; "dialogue" preset in `uiLayout.new`), portraits loaded and cropped,
clicks over the Game view checked in the running editor. Out-of-scope fix: the editor now pumps
asset loads every frame (loads stalled while a builder tab covered the Scene and Game views,
holding MCP replies up to 300 s). With no host presenter, `ScenePlayback` puts a `DialogueView`
on the game UI layer, so GameRunner and exported games show conversations. Still not done: the cooker
doesn't follow `.dialogue` references (portraits, `uiLayout`), and how `.dialogue` files ship
at all needs a look; the layout preview draws at about 0.26 scale in a small window;
`DialogueGraphView` re-lays out node text every frame (about 64 ms in debug); Space and Enter
reach game input while the box has focus.

### Timeline Builder (`.timeline`)

Cutscenes: camera (positions, look-at, FOV, cuts, `CameraPath` moves), transform, animation,
audio (incl. `.sfx`), particles (`.vfx` or prefabs), screen fade and event tracks, keyed with
`Easing`. `TimelinePlayer` plays, pauses, seeks and skips (skip lands on the final state) and
reports events; `ScreenFade` folds into the post pass. The tab plays a copy of the scene with a
scrubbable track strip. Tools: `timeline.new`, `.get`, `.set`, `.edit`, `.open`, `.sample`.
Not done in 0.15.0: a dialogue track; the tab's preview doesn't play animation clips or sounds; a
parented camera is posed wrong (local transforms); sounds and effects named by path need
`--include` in cooked games; the last fade stays until `stop()`; the tab not yet tried in the
running editor.
0.16.0 gap-fill: all of the
above done: dialogue track (with `wait`), world-space camera keys through parents, the cooker
ships files named by path for every `followsReferences` importer (incl. `vscript`), the preview
plays clips, sounds and conversations, `holdFade` (off by default clears the fade at the end),
tab checked in the running editor. Still not done: no step button in the preview to get past a held
`wait` key without clicking through the conversation; preview sound only covered in code, not
listened to.

### Animation Graph Builder (`.animgraph`) and glTF clip import

glTF animations import as clips (`<file>#animation/<name>`, cached, packed, hot-reloaded);
`World.animationRig(of:)` binds an `Animator` to a placed model; `Animator` saves with scenes.
Graphs have float / bool / trigger parameters, clip or 1D blend-space states, transitions from a
state or Any State with conditions, exit time and crossfade, and additive layers;
`Animator.graph` names one and keeps its state across reloads. One play-mode system
(`addSceneAnimationSystem`) drives graph and asset-clip animators everywhere. The tab is a node
editor with a live model preview and parameter controls. Tools: `animGraph.new`, `.get`, `.set`,
`.edit`, `.open`, `.assign`. Not done in 0.15.0: 2D blend spaces, sub-state machines, layer masks and
override layers; retargeting clips to a different skeleton layout; editing clip events;
auto-framing the preview; animators advance one at a time on the main thread.
0.16.0 gap-fill: all of the
above done: retargeting (`AnimationRetarget.swift`: `AnimationSkeleton`, options with bone map
and a `mixamoHumanoid` preset, `AnimationClip.retargeted`, `Animator.retarget` / `.animgraph`
`retarget`, `animGraph.bones`; glTF importer version 5), 2D blend spaces (`blend2D`), layer
masks and override layers, sub-state machines (flattened, `Combat/Slash` paths), glTF clip
events (`animGraph.clipEvents` / `.setClipEvents`), preview auto-frame, parallel animators
(`addSceneAnimationSystem(jobs:)`, identical results on 1 and 4 threads). `.character` external
clips are retargeted with it. Still not done: events of non-glTF clips (a `.character`'s generated clips) can't
be edited; renaming an outer state doesn't update inner transitions that exit to it; no MCP tool
for the tab's level or selection, so the 2D plot, events and mask panels were only checked by
tests.

### Character Builder (`.character`)

Rigged characters from templates (humanoid, quadruped, bird, blob) with proportion sliders,
region colors and `.meshbuild` gear attached to bones. Skeletons, skinned bodies and stock clips
(idle, walk, run, jump, attack, die, with footstep / hit events) are generated in code per
template. Imported as a prefab with an `Animator` set up: a `locomotion` blend on `speed` and
`jump` / `attack` / `die` triggers. The tab plays clips with a bones overlay. Tools:
`character.new`, `.get`, `.set`, `.edit`, `.open`, `.bones`. Not done in 0.15.0: glTF clips on a character
skeleton; skeleton editing; per-part colors in an attachment; authored clip curves; animation
in the edit-mode Scene view; clips in GameRunner (no asset database); looks unchecked in the
running editor. The prefab writes `Animator`'s Codable layout by hand, so changing
`Animator`'s stored properties needs that copy updated (CharacterTests catches it).
0.16.0 gap-fill: one clip
loader (`AssetClipLoader` / `addAssetAnimationSystem` removed), the prefab encodes a real
`Animator` (no hand-written layout), edit-mode animation (View › Animate in Scene View,
`view.animateInEditMode`; pose applied only while rendering), external glTF clips in `clips`
with `boneMap` (plain name match, rotation and scale only), per-part colors in attachments,
clips in GameRunner (`ScenePlayback.projectAssets`) and built games, tab checked in the running
editor (color fields fixed to convert sRGB). `Animator.swift` moved to
`Sources/EngineAssets/Animation/` (with the blend-space and layer-mask code it uses). External
clips are retargeted (`AnimationClip.retargeted`: rest poses corrected, both rigs should rest
alike, glTF translations dropped). Still not done: edit-mode animation propagates transforms twice per frame;
skeleton editing and authored clip curves.

### Material Builder (`.material` graphs)

Node-graph surfaces as an optional `graph` key in `.material` files: textures (images or
`.proctex`, normal maps), triplanar, noise, scrolling / rotating UVs, 24 math ops, blend modes,
fresnel, time, vertex color and more, feeding every PBR output. Presets: basic, lava, water,
hologram, stone, pulse. Compiled at import with no run-time shader compiler: generated SPIR-V /
MSL replaces `graphSurface()` in a `-O0` template (`mesh_graph.frag`); constants sit in a storage
buffer, so tweaks don't recompile. Metal and Vulkan pixels match. Works on models and mesh
builds; the tab previews on shapes or the selection. Tools: `materialGraph.new`, `.get`, `.set`,
`.edit`, `.open`, `.nodes`, `.assign` (`material.get` / `.set` edit plain materials). Not done in 0.15.0:
terrain layers and decals; graph opacity in shadows and the depth prepass (masked graphs cast
solid shadows); planar reflections; dragging links on the canvas; UV noise shows a sphere's seam
(use `position` or `triplanar`).
0.16.0 gap-fill: masked
graphs cut out their shadows and depth prepass (new graph depth / shadow templates; optional
depth fragments on `MaterialGraphProgram`), graph materials on decals (`Decal.material`,
`decal_graph.frag`), planar reflections on graphs using 3 or fewer textures, dragging and
deleting links on the canvas, and the Selected preview shape done, GPU-tested on Metal and
Vulkan. `mesh_surface.glsl` is unchanged; the new `material_graph.glsl` repeats its
MATERIAL_GRAPH block (keep the two in sync by hand). Out-of-scope fix: nil asset handles can be
set through `setField` (`ReflectedAsString`), which also fixes `Decal.texture`. Still not done: graphs
with 4 or 5 textures get no planar reflections (no free slot); graph decals use the analytic
BRDF fit for environment specular (depth takes the BRDF table's slot); the skinned masked-graph
shadow path has no GPU test; the canvas shows only about two node columns at default size; UV
noise seam.

### Visual Script Builder (`.vscript`)

Node-graph game logic run by a VM with no compile step (edits apply on the next frame while
playing; runaway graphs stop after 100,000 node runs). Events (lifecycle, keys, input actions,
3D / 2D collisions and triggers, timers, custom, sprite clips); flow, data and world nodes;
get / set nodes generated for every reflected component field; engine nodes (sound, effects,
raycast, forces, scenes, tweens, data tables, sprite clips). `VisualScript` components run
graphs in play mode and built games; game modules add nodes and events (`game.scriptNode`,
`world.sendScriptEvent`). The tab has typed pins, live flow highlight, hover values,
breakpoints, search-to-add and collapse-to-function. Tools: `vscript.new`, `.get`, `.set`,
`.edit`, `.nodes`, `.validate`, `.open`, `.attach`. Not done in 0.15.0: step over / into (breakpoints pause
after the frame); macros, reroutes and node groups; find by tag (no Tag component); editing
function pins in the tab; a collapsed selection with no exec wire out reads zeros; background
imports run only structural checks; the canvas not yet seen in the running editor.
0.16.0 gap-fill: all of the
above done: builder nodes and events (animation graphs, dialogue, timelines, behavior trees, UI
layouts; `Sources/Engine/VisualScript/`), a Tag component (Swift type `Tags`, saved as "Tag"),
step over / into / out by recording the breakpoint's flow to the end of its event and stepping
the record (`vscript.step`, F10 / F11 / Shift+F11 / F5; the scene shows the end of the frame),
editing function pins, collapse with no exec wire out, main-actor checks on background imports
(`AssetImporterMainActorChecks`), reroutes, groups and macros, canvas checked in the running
editor. Out-of-scope fix: calls of pure functions now compute their outputs. Still not done: groups
don't work inside functions; reroutes and macro-inlined nodes don't glow or show live values;
a breakpoint in fixed update can miss its recording. `ui.show` uses `world.gameUI`, so it works
in GameRunner and exported games. Nodes worth adding: `PathFollower`,
`world.gameUI`, `world.findPath`, timeline `holdFade` and dialogue keys,
`DialoguePlayer.uiLayout`.

## Follow-ups

Connections between builders: all of the 0.15.0 list is done in 0.16.0 (`.sprite` tile sets,
`.ui` dialogue boxes, a Timeline dialogue track, Visual Script nodes for the builders, graph
materials on terrain layers and decals, retargeted glTF character clips and one clip loader).
Still open: Visual Script nodes for `PathFollower`, `world.gameUI`, `world.findPath`, timeline
`holdFade` and dialogue keys, and `DialoguePlayer.uiLayout`.

Engine gaps the builders ran into:

- 2D physics reads each collider's own `Transform` and ignores parents, so a placed tilemap
  keeps its colliders at the origin (`world.spawnTilemapColliders(map, at:)` works around it). Fixed in 0.16.0.
- No runtime game UI layer: GameRunner and built games show layouts and the dialogue box only
  when game code adds them. Added in 0.16.0 (`world.gameUI`).
- The cooker misses files referenced by path: layout images, timeline sounds and effects by
  path, and tilemap JSON. Fixed in 0.16.0 (`CookPlan.pathReferences`, `keepsSource`), except
  `.dialogue` references and components naming a layout or path by plain path.
- No navigation mesh (0.16.0 adds a grid navigator, `world.findPath`); the Tag component is
  added in 0.16.0.
- `asset.import` over MCP stdio hangs on its reply when the source file is inside the project
  folder (the import itself succeeds). Possibly the stalled asset loads fixed in 0.16.0 (the editor
  now pumps loads every frame); recheck.
- Other builders' color fields may show sRGB file colors as linear (Character fixed its own;
  the Mesh Builder's part colors look affected).
- Failing on main, unrelated to the builders: `ParityTests.everyUIElementRunsACommandThatIsATool`
  (the console's `consoleCopy` button has no command); `MCPToolSchemaTests.subscribedResourcesReportUpdates`
  is timing-sensitive and fails now and then in combined runs.
- Every builder tab was checked in the running editor in 0.16.0. There is no MCP tool to select
  inside a tab, so panels behind a selection (e.g. Animation Graph's 2D plot, events and masks)
  were checked by tests only.
