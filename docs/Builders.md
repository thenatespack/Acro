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
| [Character Builder](#character-builder) | `.character` | Rigged, animated characters from body templates and parts |
| [Sound Builder](#sound-builder) | `.sfx` | Synthesized sound effects |
| [Data Table Builder](#data-table-builder) | `.table` | Typed spreadsheets for game data |
| [Pixel Sprite Builder](#pixel-sprite-builder) | `.sprite` | Pixel art and sprite animation for `SpriteAnimator` |
| [Tilemap Builder](#tilemap-builder) | `.tilemap` | 2D tile levels with auto-tiling, animated tiles, 2D collision and object points |
| [GridMap Builder](#gridmap-builder) | `.gridmap` | 3D levels painted from modular pieces on a grid |
| [Path Builder](#path-builder) | `.path` | Roads, rails, rivers, fences, cables and walls along splines |
| [Behavior Tree Builder](#behavior-tree-builder) | `.behavior` | NPC AI as node trees |
| [UI / HUD Builder](#ui--hud-builder) | `.ui` | Game menus and HUDs made from the engine's widgets |
| [Dialogue Builder](#dialogue-builder) | `.dialogue` | Branching conversations with variables and events |
| [Timeline Builder](#timeline-builder) | `.timeline` | Cutscenes: camera moves, animation, sound, effects, fades, events |
| [Material Builder](#material-builder) | `.material` | Node-graph surface shaders compiled for Metal and Vulkan |
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

## Character Builder

Character assets (`.character`, JSON under `Assets/`) describe rigged characters and creatures built from a body template: **humanoid**, **quadruped**, **bird** or **blob**. The template generates the skeleton and body shapes; `proportions` stretch it (height, head, torso, width, arms, legs, neck, tail; 1 is the template as designed, 0.25 to 3), `colors` paint its regions (skin, body, legs, accent, eyes), and `attachments` hang `.meshbuild` models (hair, hats, armor, weapons) on bones, placed in the bone's space and optionally recolored. Bones rest unrotated, facing +Z with +Y up; `.L` bones are on the character's left (+X).

The importer produces a skinned body (one mesh and material per color region, weights blended across joints when `smooth` is on), the attachments' meshes, the template's stock clips as animation sub-assets (`animation/idle`, `walk`, `run`, `jump`, `attack`, `die`, generated in code for that skeleton so they always fit) and a prefab: the root carries an `Animator`, the bones are entities (attachments under theirs), and the body meshes have a `Skin` bound to the bones. Placed copies update when the file or an attached mesh build changes.

The `Animator` has one state per clip (idle, walk and run loop) plus `locomotion`, a blend of idle, walk and run on the float parameter `speed` in meters per second; it starts in `defaultClip`. The triggers `jump`, `attack` and `die` play those clips from any state, and jump and attack return to locomotion. Clips fire events: `footstep` (walk, run), `takeoff` and `land` (jump), `hit` (attack), `down` (die). Characters animate in play mode and built games without game code; drive them from scripts:

```swift
world.modify(Animator.self, for: hero) { animator in
    animator.setFloat("speed", velocity.length)   // idle → walk → run
    if attackPressed { animator.setTrigger("attack") }
}
```

In the editor, use **New Character** in the asset browser, then double-click the file (or use **Open in Character Builder** in the inspector) to open the **Character Builder** tab next to the Scene view. The character plays a clip in a viewport of its own (right-drag orbits, Shift pans, the wheel zooms) with Restart, Pause and a Bones overlay. The sidebar has the template picker, clip buttons and the starting clip, proportion sliders, region colors, and the attachments list (pick a mesh build and a bone, then **Attach**; edit the selected one's bone, placement, scale and recolor). Every change is saved to the file as one undo step.

Editor MCP clients can use `character.new {template, proportions, colors}`, `character.edit {proportions, colors, attach, detach, updateAttachments, template, clips}`, `character.set`, `character.get` (bones, clips and their references), `character.bones {template}` (a template's bones without a file) and `character.open {clip}`. See [MCPTools.md](MCPTools.md) for schemas and parameters.

Not yet: importing glTF clips onto a character skeleton (clips are the procedural stock set), editing the skeleton or adding bones, per-part colors inside an attachment, and authored clip curves; the Animation Graph Builder is meant to replace the generated state machine.

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

Auto-joining pieces have a `join` instead of an asset: the names of their single, end, straight, corner, tee and cross variants (plus `joinsWith`, other pieces that count as neighbors). Each cell becomes the variant that fits its neighbors on the same floor and layer, turned to face them, so painting a run of `Wall` gives straight walls, corners and T-junctions by itself. Variants are authored connecting toward +x (end), +x and -x (straight), +x and +z (corner), and +x, -x and +z (tee). An auto-joining piece with a bigger footprint covers a square block (its footprint's larger side): it joins with neighbors anywhere along each side of the block, and its variants are drawn centered on the block (and collide as the block unless they set a `size`). Line, rectangle and fill brushes lay multi-cell pieces side by side instead of once per cell (rectangles and fills keep only whole footprints).

The importer runs each piece file's own importer to learn its nodes and triangles (so the map reimports when a piece file changes) and builds a prefab: a node per floor, a node per chunk (`chunkSize` cells per side) holding one merged triangle-mesh collider, and one node per placed piece that references the piece's meshes and materials, so equal pieces draw as one instanced batch. Flipped pieces get mirrored copies of their meshes, and their animations (a mesh build's autoplay tracks and motions) slide and turn mirrored too. Pieces whose triangles can't be read collide as boxes. A `.prefab` piece may be a scene file or a prefab variant (its base, a scene file, model or another variant, with the variant's overrides applied: moved, added and removed children, changed and added components); built-in primitives in it (`cube`, `sphere`, `cylinder`...) become meshes of the map, so they draw and collide like any other mesh. Piece imports are cached in the map's Library folder (`cache/pieces/`, meshes, materials and prefabs only, keyed by importer, settings and every file the import read), and an up-to-date import from the asset database is reused before running a piece's importer, so reimporting a map that uses big textured models stays fast.

In the editor, use **New GridMap** in the asset browser (it writes starter pieces as mesh builds next to the map: Floor, an auto-joining Wall with its six variants, Crate, Pillar), then double-click the file (or use **Open in GridMap Builder** in the inspector) to open the **GridMap Builder** tab. The edited floor shows its grid; floors below are faded and floors above hidden. Pick a brush (paint, line, rectangle (Shift: hollow), fill, erase, random from a set), a piece, the rotation, flips and layer, then click or drag on the grid; each stroke is one undo step. The floor slider and Up / Down buttons change the floor. With the pointer over the tab, keys 1 to 6 pick the brush (paint, line, rectangle, fill, erase, random), R and Shift+R rotate, X and Z flip, and Page Up / Page Down (or `]` / `[`) change the floor. The sidebar also edits each piece (asset, footprint, pivot, collider, auto-join variants) and the map's settings.

Editor MCP clients can use `gridMap.new {cellSize, library, assets, starter}`, `gridMap.paint {piece | pieces, cells, brush, rotation, flipX, flipZ, layer}` (brush: cells, line, rect, outline, fill), `gridMap.fill {piece, box, hollow}`, `gridMap.erase {cells | box, layer}`, `gridMap.edit` (settings, layers, add / update / remove pieces), `gridMap.set`, `gridMap.get` (with `mapFloor`, a text picture of one floor) and `gridMap.open`. See [MCPTools.md](MCPTools.md) for schemas and parameters.

Not yet: per-piece random variation of scale.
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
## Timeline Builder

Timelines (`.timeline`, JSON under `Assets/`) are cutscenes and scripted moments. A timeline has a `duration`, `loop`, `skippable` and tracks; each track has a `kind`, a `target` entity named by its `Name` or a `"Parent/Child"` path (so one file plays in any scene that has those names) and keys at times in seconds:

- **camera**: position, aim (`lookAt` point, `lookAtEntity`, or `rotation` in degrees) and `fov`, blended with the later key's `easing`; `cut` jumps instead of blending, and `path` makes a constant-speed spline move (the `CameraPath` spline) through extra points to the next key, with `followPath` facing the direction of travel. No target: the active camera.
- **transform**: an entity's position, rotation and scale.
- **animation**: plays an `Animator` state (crossfade `blend`, `speed`) or `SpriteAnimator` clip on the target or its first descendant that has one.
- **audio**: plays a sound file or `.sfx` (`clip`, `volume`, `pitch`, `loop`, `duration`) at the target, or unpositioned without one.
- **particles**: spawns a `.vfx` (or other prefab) at the target for `duration` seconds (default: the effect's own).
- **fade**: fades the screen toward `color` by `amount`, through the `ScreenFade` component (folded into the post pass's grading).
- **event**: a `name` and `value` for game code.

Every key field is optional; continuous kinds (camera, transform, fade) hold a field between the keys that set it. Track kinds are strings, so tracks of kinds this engine doesn't know (a later dialogue track, say) are kept and skipped with a warning.

At runtime a `TimelinePlayer` component (`timeline`: the file's `asset:<id>` or path, `playOnStart`, `speed`, `loop`) plays it; the editor's play mode, exported games and GameRunner add its system. Edits to the file show up while playing. Control and listen from game code:

```swift
world.modify(TimelinePlayer.self, for: intro) { $0.skip() }   // also play(from:), pause(), resume(), stop(), seek(to:)
for (_, event) in world.timelineEvents() where event.name == "introDone" { startLevel() }
```

`skip()` jumps to the end: the event keys not reached yet fire, the last animation key of each track plays, sounds and effects the timeline started stop, and the final frame is posed.

In the editor, use **New Timeline** in the asset browser and double-click the file (or **Open in Timeline** in the inspector) to open the **Timeline** tab next to the Scene view. It previews a copy of the open scene posed by the timeline, through the timeline's camera (**Camera View**) or a free orbit camera, with Play / Pause, Stop and Loop. The strip under the preview has a row per track: click or drag to scrub, click a key to select it, drag it to retime it (snapped to 0.05 s), double-click a row to add a key. The sidebar edits the timeline's settings, adds and deletes tracks, sets a track's name, target and mute, and edits the selected key (Add Field / Remove Field choose which fields it sets; **Key From View** keys the camera at the free camera's framing). **Add Player to Scene** places an entity with a `TimelinePlayer`. Every change is one undo step. The preview doesn't play animation clips or sounds (play mode does).

MCP clients use `timeline.new {duration, place}`, `timeline.edit {addTracks, updateTracks, removeTracks, addKeys, updateKeys, removeKeys, duration, loop}`, `timeline.set`, `timeline.get`, `timeline.sample {time}` (the camera and transform poses, the fade and the keys fired by then, without playing) and `timeline.open`; see [MCPTools.md](MCPTools.md). Cooked games ship the file as written, with sounds and effects it names by `asset:<id>`; include ones named by path with the cooker's `--include`.

## Animation Graph Builder

Animation graphs (`.animgraph`, JSON under `Assets/`) are `Animator` state machines without code: parameters (`float`, `bool`, `trigger`), states that play one clip or a 1D blend space of clips along a float parameter (with speed, a speed parameter and looping), transitions between states or from Any State with conditions (`greater`, `less`, `isTrue`, `isFalse`, `triggered`), an exit time and a crossfade duration (checked in order; the first that applies fires), additive layers, the initial state and the model to preview on. Every key is optional; problems (unknown states or parameters, a test on the wrong parameter type, missing clips, transitions that can never fire) are import warnings.

Clips come from glTF files: each animation in a `.gltf` / `.glb` is imported as an `animation/<name>` sub-asset (`asset:<id>#animation/Walk`), retargeted to the file's prefab node numbers (depth first, as `PrefabSkin` numbers joints), so it plays on an instance of that prefab, or of a prefab with the same node layout. An `Animator` whose `graph` names an `.animgraph` (or whose clip keys are asset references) is played by the scene animation system (`World.addSceneAnimationSystem`) in the editor's play mode, exported games and GameRunner: it binds an animator with no targets to its entity's subtree (`World.animationRig(of:)`), loads the clips, and takes the graph again whenever the file is reimported, keeping the current state and parameter values. Game code sets parameters on the component (`animator.setFloat("speed", 2)`, `setTrigger("jump")`).

In the editor, use **New Animation Graph** in the asset browser, then double-click the file (or **Open in Animation Graph Builder** in the inspector) to open the **Animation Graph** tab next to the Scene view. The top is a node editor: click to select, drag nodes to arrange them, drag from a node's port (the dot on its right, also on Any State) to another node to add a transition, drag the background to pan, Delete removes the selection. Below it the graph plays live on its preview model, with the playing state highlighted. The sidebar picks the preview model, lists the parameters with live controls that drive the preview by hand (not saved), edits the selected state (clip or blend space entries), transition (conditions, exit time, crossfade, order) or layer, and lists problems. **Put on Selection** gives the selected scene entity (a placed model's root) an `Animator` playing the graph. Every change is one undo step.

Editor MCP clients use `animGraph.new {preview}` (a starter graph from the model's clips), `animGraph.edit {parameters, addStates, addTransitions, updateStates, updateTransitions, addLayers, remove…}`, `animGraph.get`, `animGraph.set`, `animGraph.assign {entity}` and `animGraph.open`. Clip keys may be given as paths (`Models/hero.glb#animation/Walk`); they are stored as asset references. See [MCPTools.md](MCPTools.md).

Not done yet: 2D blend spaces, sub-state machines, per-layer masks and override (non-additive) layers, retargeting clips between skeletons with different node layouts, and editing clips' events.
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
