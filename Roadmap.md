# Roadmap

Planned engine features, grouped into waves. Builder-specific gaps stay in [Tools.md](Tools.md);
when an item here ships, move its notes to the changelog and Tools.md, then delete it from this
file.

Every item that adds content follows the builder pattern from Tools.md: a JSON file under
`Assets/` (every key optional), an importer, MCP tools (`<name>.new`, `.get`, `.set`, `.edit`,
`.open`, plus a `.preview` PNG and `.examples`), and an editor tab. That way an AI agent can author
and apply the feature in a few calls, and problems come back as warnings.

## How waves work

A wave is three tasks that three background agents can build at once, each in its own worktree,
without editing the same code much. Within a wave, each task belongs to a different area (lane)
and lists the modules it touches. The rendering lane gets at most one task per wave, since every
rendering feature edits `EngineRendering` and the shaders.

Waves are ordered by importance and by what they need: a wave only builds on earlier waves. The
first wave left is the most important, and later waves are progressively less. Waves 1 to 3 have
shipped (editor camera, IK and ragdolls, agent playtesting; fur and hair, physics v2, navigation
mesh and crowds; lighting probes, interaction and damage, camera rigs).

A few files are edited by almost every task: the Demo scene list, the `BuiltinCommands` list,
the builder registry, `CHANGELOG.md`, `docs/MCPTools.md` and `Tools.md`. Merge the tasks of a
wave into main one at a time, and resolve these files during each merge. Before merging, check
that test component names and demo scene names don't clash between tasks.

| Wave | Task A | Task B | Task C |
|---|---|---|---|
| 4 | Sky and volumetric clouds | Replication and network debugger | Localization |
| 5 | Water | Items, inventory and crafting | Game UI and accessibility kit |
| 6 | Cloth | Weapons and abilities | GPU profiler and memory budgets |
| 7 | Job system and multithreaded physics | NPC perception and utility AI | Steam and achievements |
| 8 | Screen-space GI, AO and reflections | Dedicated server and lobbies | Facial blend shapes |
| 9 | Weather | Templates: action and platformer | Asset style consistency |
| 10 | GPU-driven culling | World streaming | Rollback netcode |
| 11 | Biome painter | Snapping, align and undo history | In-editor AI chat panel |
| 12 | Destruction | Squad tactics | Templates: survival and arena |
| 13 | Subsurface scattering | Vehicles | Text-to-level and dungeons |
| 14 | Motion matching | Telemetry and auto-balance | Touch and gyro input |
| 15 | Interactive tutorials and video capture | AI agent cookbook | Sample game gallery |
| 16 | GPU smoke and fire | Texture painter | Scene diff/merge and large files |
| 17 | UV unwrapping and baking | Packages | Quests and encounters |
| 18 | Runtime character creator | Split-screen and cinematic cameras | Screen reader |
| 19 | Hardware ray tracing | Mounts, flying and swimming | Ropes, soft bodies and fluids |
| 20 | Virtual textures | Procedural creatures | Modding |
| 21 | Meshlets and mesh shaders | Visual Script compiled to Swift | Debugger for game code |

---

## Wave 4: outdoor look, multiplayer base, other languages

### 4A. Sky and volumetric clouds

Lane: rendering. Touches `EngineRendering` (sky, fog, shadows) and a new `.sky` tab.

- A physically based sky with a time-of-day cycle and raymarched clouds that cast shadows. Works
  with the existing `VolumetricFog`. Uses a `.sky` file and `sky.*` tools.

### 4B. Replication and network debugger

Lane: multiplayer. Touches `EngineNet`, `EditorNetCommands.swift`/`EditorNetPlay.swift` and the
inspector. All built on the existing networking (docs/Networking.md).

- **Replication components:** mark components and fields as replicated in the inspector or with
  an attribute. Includes snapshot interpolation, client prediction with reconciliation, and
  relevancy by distance.
- **Network debugger:** an editor panel showing bandwidth per entity and component, simulated
  lag, jitter and packet loss, and a desync replay that compares world hashes frame by frame.
  Includes `net.*` MCP tools to read it.

### 4C. Localization

Lane: text and UI. Touches `EngineText`, `EngineUI`, and the Dialogue, UI and Timeline builders.

- **String tables:** `.strings` (a key with a value per language), with a builder tab in table
  form.
- **Runtime:** `Localization.current`, language switching at runtime, plural rules, and fallback
  to the base language.
- **Builder hooks:** Dialogue lines, UI text and Timeline subtitles can name a key instead of
  text. The checker reports missing keys and untranslated strings.
- **Fonts:** a fallback font per language for scripts the main font lacks.
- **MCP tools:** `strings.*`, and `strings.export`/`strings.import` as CSV for translators.

## Wave 5: water, items and a shippable game UI

### 5A. Water

Lane: rendering. Touches `EngineRendering`, buoyancy in `EnginePhysics`, and Terrain and Path
builder hooks.

- **Water surface component:** Gerstner/FFT waves, refraction, depth color, screen-space
  reflections falling back to probes, and shoreline foam from scene depth.
- **Buoyancy:** physics bodies float using sample points, with drag.
- **Builder:** a `.water` file and tab, plus Terrain and Path hooks (rivers along a path, lakes
  filled to a height).
- **Demo scene:** `water`.

### 5B. Items, inventory and crafting

Lane: gameplay. Touches new gameplay components in `EngineScene`, `SaveGames.swift`, the Data
Table and Visual Script.

- Item definitions stored in Data Tables, inventories with stacking, weight and slots, equipment
  that attaches to character bones, crafting recipes, and pickups. Inventories save through
  `SaveGame`. Includes `items.*` MCP tools and Visual Script nodes. The default inventory UI is a
  `.ui` layout.

### 5C. Game UI and accessibility kit

Lane: text and UI. Touches `EngineUI`, post-FX filters, input actions, and the UI Builder.

- **Menu and settings kit:** a ready-made main menu, pause menu, graphics/audio/control
  settings and save-slot screens as `.ui` layouts, themed by the project style.
- **Input remapping:** a built-in remapping screen for input actions (keyboard and gamepad),
  hold-or-toggle options, one-handed presets and adjustable timing, saved per player.
- **Subtitles and captions:** styled subtitles from Dialogue and Timeline, captions for sound
  effects from Sound Builder tags, with options for size, background and speaker colors.
- **Colorblind and contrast modes:** colorblind correction filters in post-FX, a high-contrast UI
  theme, and an editor check that simulates colorblindness in the Scene view.

## Wave 6: cloth, combat depth and performance tools

### 6A. Cloth

Lane: animation. Touches a new solver beside `EnginePhysics`, skinning in `EngineAssets`, and the
Character Builder.

- A position-based cloth solver for capes, flags and skirts, pinned to bones and colliding with
  character capsules. Uses a `.cloth` file and one AI call to apply it, the same as
  `groom.apply`.

### 6B. Weapons and abilities

Lane: gameplay. Touches gameplay components in `EngineScene` and new `.weapon` and `.ability`
tabs.

- **Weapons and projectiles:** a `.weapon` builder with fire modes, rate, recoil and spread
  patterns, hitscan or physics projectiles (using continuous collision), ammo, and
  VFX/sound/IK-aim hooks. Weapons are inventory items.
- **Abilities and status effects:** abilities stored as data with costs, cooldowns, targeting and
  effects, and buffs/debuffs with stacking rules and durations. Uses an `.ability` file and
  tools, and works with replication.

### 6C. GPU profiler and memory budgets

Lane: tools. Touches `ConsoleAndStats.swift` and the stats commands in `EditorCore`, plus
read-only counters in `EngineGraphics`.

- **GPU profiler panel:** an editor timeline of per-pass GPU times, draw and triangle counts and
  memory, with `profiler.*` MCP tools so agents can find what slows a scene down.
- **Memory budgets:** memory tracked per asset type and per system (GPU and CPU), with budgets
  per platform, an editor view and `memory.*` MCP tools. Going over budget reports warnings at
  import and in CI.

## Wave 7: scale, smarter NPCs, shipping on Steam

### 7A. Job system and multithreaded physics

Lane: core. Touches `EngineScene/Jobs`, the staged system scheduler, and the solver in
`EnginePhysics`. This touches widely used code, so keep the other two tasks in this wave away
from the scheduler.

- **Job system:** a work-stealing scheduler that systems, animation, particles and import work can
  fan out to. Staged systems declare what they read and write, so stages that don't conflict run
  in parallel. Fits Swift 6 strict concurrency.
- **Multithreaded physics:** the broadphase and island solving run on the job system, giving the
  same results with any thread count (needed for rollback).

### 7B. NPC perception and utility AI

Lane: NPC AI. Touches the behavior system and a new `.brain` tab in `EditorBuildersLogic`.

- **Perception:** sight cones with line-of-sight checks, hearing from sound events, and memory
  that fades over time. Exposed to Behavior Trees as conditions and blackboard values, with debug
  cones in the Scene view.
- **Utility AI and GOAP:** scored-action and goal-planning brains as alternatives to behavior
  trees, which can call behavior tree subtrees. Uses a `.brain` file, a builder tab and a live
  debugger showing scores and plans.

### 7C. Steam and achievements

Lane: platform. Touches the export pipeline (`EditorBuildGame.swift`, packaging), a new Steam
wrapper module, and `SaveGames.swift`.

- **Steam integration:** achievements, stats, cloud saves backed by `SaveGame`, rich presence, a
  Steam Deck input profile and verified-friendly defaults, and an export step that builds depots.
- **Achievements:** engine-side achievements and stats, defined in a Data Table and saved through
  `SaveGame`. Synced to Steam when Steam integration is enabled, and shown in a default `.ui`
  toast.

## Wave 8: better lighting, online play, faces

### 8A. Screen-space GI, AO and reflections

Lane: rendering. Touches `EngineRendering` post passes.

- Screen-space indirect diffuse light, a better ambient occlusion pass, and SSR that falls back to
  the reflection probes (3A).

### 8B. Dedicated server and lobbies

Lane: multiplayer. Touches `EngineNet`, `GameRunner`, a null graphics backend in
`EngineBackends`, and export.

- **Dedicated server build:** a headless export (no window or GPU, null graphics backend) for
  Linux and Windows, plus a Docker image and a health-check endpoint.
- **Lobby and matchmaking:** lobbies, invites, ready states and host migration. NAT punch-through
  with a relay server fallback that can be hosted yourself. Steam lobbies are available when
  Steam integration is enabled.

### 8C. Facial blend shapes

Lane: animation. Touches glTF import and skinning in `EngineAssets`, and the Character and
Dialogue builders.

- glTF morph targets, expression presets, and lip sync driven by Dialogue lines and their audio.

## Wave 9: weather, the first templates, a shared look

### 9A. Weather

Lane: rendering. Touches VFX, post-FX, materials (wetness) and `SceneEnvironment`.

- Rain, snow, wet surfaces and puddles, wind gusts and lightning. Drives VFX, post-FX, sound,
  `SceneEnvironment.wind` and how wet materials look. Uses a `.weather` file and blends between
  presets.

### 9B. Templates: action and platformer

Lane: templates. Touches `Projects/` and `ProjectScaffold.swift` only. Each template is a playable
project that puts the roadmap features together, and agent playtesting keeps it working.

- **3rd-person action:** character, camera rig, melee and ranged combat, IK, ragdolls, grooms and
  cloth.
- **2D platformer:** sprites, tilemaps, 2D physics, one-way platforms and tuned jump feel.

### 9C. Asset style consistency

Lane: content. Touches a new project style file plus small hooks in each builder's importer
(merge after 9B).

- Project-wide palettes and style presets (roughness range, edge wear, color saturation, texel
  density) that every builder applies. Includes a check that reports assets that don't match the
  project style.

## Wave 10: big worlds and rollback

### 10A. GPU-driven culling

Lane: rendering. Touches `EngineRendering` draw submission.

- Hi-Z occlusion culling and indirect draws, so dense scatter, forests and GridMap cities stay
  fast. Measure GPU time per pass with the profiler (6C).

### 10B. World streaming

Lane: world. Touches scene loading in `EngineScene`, `EngineAssets` loading, and the editor's
scene document.

- Split worlds into tiled cells that load and unload around the player on a background thread,
  with streamed detail levels and impostors far away. The editor edits one region at a time.

### 10C. Rollback netcode

Lane: multiplayer. Touches `EngineNet` and a deterministic fixed-step mode in the scheduler
(after 7A).

- A deterministic fixed-step simulation mode, input delay plus rollback and resimulation, and a
  desync checker that compares world hashes. Aimed at fighting and action games.

## Wave 11: painting worlds, editor comfort

### 11A. Biome painter

Lane: world. Touches the Terrain Builder in `EditorBuildersWorld` and a new `.biome` importer.

- Paint biomes that drive terrain layers, scatter, grooms, weather and ambient sound together,
  with blending at the borders. Uses a `.biome` file and `biome.paint` so an agent can lay out a
  world in a few calls.

### 11B. Snapping, align and undo history

Lane: editor. Touches `TransformTool.swift`, `ViewportTool.swift` and the undo system.

- **Snapping and align tools:** vertex, edge and surface snapping for the move gizmo, align and
  distribute, drop to ground, and pivot snapping. Includes `scene.align`/`scene.snap` MCP tools
  so agent-placed props sit flush.
- **Undo history browser:** a visual undo timeline across the scene and every builder tab, with
  thumbnails, jumping to any step, and branches kept when you undo and then edit.

### 11C. In-editor AI chat panel

Lane: AI tooling. Touches a new panel in `EditorCore` and `EditorMCP.swift`.

- A docked panel that talks to Claude using the editor's own MCP tools. Shows tool calls as they
  run, with undo grouping per request, and can attach the selection or a viewport screenshot.

## Wave 12: destruction, tactics, the big templates

### 12A. Destruction

Lane: physics. Touches `EngineMeshBuild` (fracture) and `EnginePhysics`.

- Mesh Builder Voronoi fracture is baked when a part is imported. Pieces break off when hit hard
  enough, with debris pooling and VFX/sound hooks.

### 12B. Squad tactics

Lane: NPC AI. Touches the behavior system and navigation.

- Cover points generated from the navmesh, flanking, suppression roles and shared squad memory,
  built on perception, the navmesh and crowds.

### 12C. Templates: survival and arena

Lane: templates. Touches `Projects/` only.

- **Open-world survival:** streaming, biomes, weather, day/night, inventory and crafting.
- **Online arena:** lobby, replication, rollback option, dedicated server and the network
  debugger.

## Wave 13

### 13A. Subsurface scattering

Lane: rendering. Touches `EngineRendering` lighting.

- A screen-space diffusion profile for skin and wax, and thin-surface transmission for leaves and
  ears. Pairs with grooms and facial blend shapes.

### 13B. Vehicles

Lane: physics. Touches `EnginePhysics` and a new `.vehicle` tab.

- Raycast wheels with suspension, tire friction curves, a drivetrain and a `.vehicle` builder.

### 13C. Text-to-level and dungeons

Lane: content. Touches new MCP tools and the GridMap builder in `EditorBuildersWorld`.

- **Text-to-level:** one MCP call turns a short brief into a level. It lays out GridMap rooms,
  terrain, paths and scatter, then checks that the level can be walked through, using navigation.
- **Dungeon generator:** rooms, corridors, keys and locks from a seed, built from GridMap pieces.
  Checked to be solvable using navigation, with a `.dungeon` file and tools to regenerate it. An
  agent can then tweak single rooms.

## Wave 14

### 14A. Motion matching

Lane: animation. Touches the Animation Graph in `EngineAssets` and `EditorBuildersAnimation`.

- Pick poses from a clip database by trajectory and pose features. It is an Animation Graph node,
  so it mixes with state machines and IK.

### 14B. Telemetry and auto-balance

Lane: AI tooling. Touches a new telemetry module, `GameRunner`, and Scene view overlays.

- **Analytics and telemetry:** opt-in gameplay event logging from exported games (deaths,
  positions, timings) to a file or an endpoint you host. The editor shows heatmaps and paths in
  the Scene view, and `telemetry.*` MCP tools let an agent find balance problems.
- **Auto-balance:** agents play many headless runs and tune Data Table values toward targets you
  set (win rate, time to kill, economy curves). Every change is reported with before and after
  numbers. Builds on agent playtesting, telemetry and the dedicated server build.

### 14C. Touch and gyro input

Lane: input. Touches the input action system and `.ui` elements.

- **Touch and gestures:** touch input in the input action system (taps, swipes, pinches and
  drags), virtual sticks and buttons as `.ui` elements, and touch simulation with the mouse in the
  editor.
- **Motion and gyro input:** gyro aiming and motion controls for gamepads that report them
  (DualSense, Switch Pro, Steam Deck), mapped through input actions with sensitivity and
  smoothing settings.

## Wave 15: documentation and learning

### 15A. Interactive tutorials and video capture

Lane: editor. Touches a new tutorial overlay and capture commands in `EditorCore`.

- **Interactive tutorials:** step-by-step tutorials in the editor that highlight the UI and check
  each step through the command registry (so the same tutorials can test the editor). Covers a
  first scene, first builder and first game module.
- **Video capture:** record GIFs and MP4s of the editor or a running game (`capture.*` MCP tools),
  with a cursor overlay, for docs, bug reports and the sample gallery.

### 15B. AI agent cookbook

Lane: docs. Touches `Evals/` and `docs/` only.

- Tested MCP recipes for common tasks (make a character, build a level, tune a material, groom a
  creature), run as evals in `Evals/` so they stay correct.

### 15C. Sample game gallery

Lane: templates. Touches `Projects/` only.

- Small complete games, one per major feature, each with a write-up and checked by agent
  playtesting in CI.

## Wave 16

### 16A. GPU smoke and fire

Lane: rendering. Touches VFX rendering in `EngineRendering` and the VFX Builder.

- Grid-based 3D fluid volumes (advection, pressure solve, temperature) for smoke, fire and
  explosions in the VFX Builder, raymarched with lighting and shadows. Wind and weather affect
  them.

### 16B. Texture painter

Lane: content. Touches a new painting tab in `EditorBuildersMesh` and proctex.

- Paint albedo, roughness, metallic and normal maps on meshes in layers, with masks, brushes from
  proctex noise, and the result saved as builder data an agent can edit.

### 16C. Scene diff/merge and large files

Lane: team. Touches scene serialization tools, `Scripts/` and `ProjectScaffold.swift`.

- **Scene and prefab diff and merge:** readable diffs of scene, prefab and builder JSON by entity
  and component, plus a 3-way merge tool and a git merge driver.
- **Large-file asset storage:** Git LFS setup in new projects for textures, audio and glTF, or
  content-addressed storage so the Library cache and cooked output can be shared across machines.

## Wave 17

### 17A. UV unwrapping and baking

Lane: content. Touches `EngineMeshBuild`.

- Automatic UV unwrapping and packing, lightmap UVs, and baking normal, AO and curvature maps from
  high-poly to low-poly, including Mesh Builder sculpts.

### 17B. Packages

Lane: editor. Touches the asset database and a package browser panel.

- Share builder files, presets, styles and scripts as versioned packages across projects, with
  dependency resolution and a package browser in the editor.

### 17C. Quests and encounters

Lane: gameplay. Touches gameplay components, `SaveGames.swift` and Dialogue templates.

- Fetch, defeat, escort and delivery encounters made from items, NPCs and Dialogue templates,
  scaled by difficulty. Needs a basic quest state model (objectives and rewards, saved through
  `SaveGame`). Quest graphs were not picked, so keep it minimal.

## Wave 18

### 18A. Runtime character creator

Lane: animation. Touches the Character Builder runtime and a default `.ui` layout.

- A customizer players use in game, with body and face sliders (blend shapes), outfits
  (equipment attachments), groom and color choices. Saved through `SaveGame` and replicated in
  multiplayer.

### 18B. Split-screen and cinematic cameras

Lane: cameras. Touches the camera rigs, the Timeline builder and multi-view rendering setup.

- **Split-screen:** local split-screen for 2 to 4 players, with input devices assigned per player,
  a game UI layer per viewport and a render-scale budget per view.
- **Cinematic camera tools:** camera rails on `.path` curves, look-at and framing constraints,
  depth-of-field focus pulls, shot cuts and blends as a Timeline camera track, and an in-game
  photo mode (free camera, post-FX sliders, hide UI).

### 18C. Screen reader

Lane: text and UI. Touches `EngineUI` and platform accessibility bridges.

- Game UI layouts expose labels and focus order to VoiceOver, Orca and Narrator. The UI Builder
  warns about elements without labels.

## Wave 19

### 19A. Hardware ray tracing

Lane: rendering. Touches `EngineGraphics` backends and `EngineRendering`.

- Ray-traced shadows, reflections and AO through Metal ray tracing and Vulkan ray queries, used
  when the GPU supports it and falling back to the raster paths.

### 19B. Mounts, flying and swimming

Lane: animation. Touches locomotion, the Animation Graph and 3D navigation.

- **Mounts and riding:** mount and dismount, a rider attached with IK to saddle sockets, mount
  locomotion through the Animation Graph, and mounts NPCs can ride.
- **Flying and swimming:** locomotion modes for flight (glide, hover, flap) and swimming (surface
  and underwater, with buoyancy from water), plus 3D volume navigation for flying and swimming
  NPCs.

### 19C. Ropes, soft bodies and fluids

Lane: physics. Touches `EnginePhysics` and VFX particles.

- **Ropes and chains:** constraint chains that can be swung on, climbed and attached to bodies or
  bones. Drawn as `.path`-style sweeps or chain-link instances.
- **Soft bodies and fluids:** jiggle and squash soft bodies (shape matching, can also be applied
  to character parts) and small-scale SPH particle fluids for pours, splashes and slime, drawn
  through the VFX renderer.

## Wave 20

### 20A. Virtual textures

Lane: rendering. Touches `EngineRendering` texture sampling and the cooker.

- Streaming page-based textures for large terrains and texture-heavy scenes, with a feedback
  pass, a page cache and Library-cooked tiles.

### 20B. Procedural creatures

Lane: content. Touches `EngineMeshBuild` (rigging, skinning) and the Mesh Builder.

- Mesh Builder bodies get an automatic rig, skin weights and procedural walk cycles for any number
  of legs. Works with IK foot placement and grooms.

### 20C. Modding

Lane: platform. Touches asset loading at runtime and the export pipeline.

- `.acro` mod packs made of builder files and visual scripts, loaded at runtime in a sandbox (no
  native code). Includes a mod browser in exported games, load order and conflict reports.

## Wave 21

### 21A. Meshlets and mesh shaders

Lane: rendering. Touches `EngineGraphics` and `EngineRendering` geometry.

- Cluster-based geometry with per-cluster LOD and culling (a small Nanite-style path), using mesh
  shaders where available and compute plus indirect draws elsewhere.

### 21B. Visual Script compiled to Swift

Lane: scripting. Touches the Visual Script compiler in `EditorBuildersLogic` and the game-module
build.

- Shipping builds turn `.vscript` graphs into Swift that runs in the game module, at native speed
  and with the same behavior. Tests run both forms and compare the results.

### 21C. Debugger for game code

Lane: editor. Touches `EditorGameModule.swift` and a new debugger panel.

- Set breakpoints in game Swift code from the editor and inspect variables and entity state while
  paused, using LLDB with the hot-reloaded module. Pairs with the Visual Script debugger.
