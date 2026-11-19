# Roadmap

Planned engine features, in the order we plan to build them. Builder-specific gaps stay in
[Tools.md](Tools.md); when an item here ships, move its notes to the changelog and Tools.md, then
delete it from this file.

Every item that adds content follows the builder pattern from Tools.md: a JSON file under
`Assets/` (every key optional), an importer, MCP tools (`<name>.new`, `.get`, `.set`, `.edit`,
`.open`, plus a `.preview` PNG and `.examples`), and an editor tab. That way an AI agent can author
and apply the feature in a few calls, and problems come back as warnings.

## 1. Inverse kinematics and ragdolls

There is no IK solver or ragdoll today. Characters can't plant their feet on slopes, aim, reach, or
go limp.

- **IK solvers:** two-bone (arms and legs, with a pole target), look-at/aim chains (head, spine,
  weapon), and FABRIK for longer chains (tails, tentacles). Run them after the animation graph and
  before skinning.
- **Animation Graph nodes:** `twoBoneIK`, `aim`, `chainIK` and `footPlacement`. Each node has a
  weight that can be blended and driven by a graph parameter.
- **Foot placement:** ray casts against physics, adjusts the pelvis height, aligns feet to the
  ground normal, and locks feet while they are planted.
- **Ragdolls:** `Ragdoll` builds capsule bodies and limited joints from a skeleton (reusing
  `Joint`/`JointKind`). Physics can blend in partly (hit reactions) or take over fully (death), and
  the character can return to animation (get-up).
- **Character Builder:** a ragdoll section with automatic body sizes, editable joint limits and a
  Test Ragdoll button. Add `character.ragdoll` and `character.ik` MCP tools.
- **Visual Script nodes:** set IK target/weight, enable ragdoll, apply impulse to bone.
- **Demo scene:** `ik`, with uneven stairs, an aiming character and a ragdoll drop.

## 2. Lighting probes

The only reflections are planar, and there is no global illumination or baked lighting.

- **Reflection probes:** box-projected cubemaps, baked in the editor and blended by influence volume.
  Metal and Vulkan must match.
- **Irradiance probes:** an editor-placed grid of spherical-harmonic probes for indirect diffuse
  light on dynamic objects and static geometry.
- **Baking:** `lighting.bake` MCP tool and editor button. Results go into the Library cache and are
  cooked into exported games.
- **Debug views:** probe spheres, influence boxes and an irradiance-only view mode.
- **Demo scene:** `probes`, an interior lit through a window.

## 3. Fur and hair (Groom Builder, `.groom`)

Fur and hair that an AI can apply to any mesh, character part or Mesh Builder part with one call.

- **File type** `.groom`. Keys:
  - `style`: `shell` for short fur, `cards` for longer hair and manes, `strands` for close-ups
    later.
  - `length`, `density`, `thickness` (root and tip), `clumping`, `curl`, `frizz`, `gravity`,
    `stiffness`.
  - Colors: `rootColor`, `tipColor`, plus `colorNoise`.
  - `mask`: a texture, vertex paint or Mesh Builder part names; controls where fur grows and how
    long it is.
  - Direction: `combDirection`, a flow texture, or `"followSurface"`.
  - `wind`: scales `SceneEnvironment.wind` through `MaterialWind`, the same as plants.
  - `lod`: shell or card count per detail level, falling back to a fur-tinted material in the
    distance.
- **Rendering:**
  - Shell fur: N instanced shells pushed out along normals, with noise alpha and anisotropic
    (Kajiya-Kay / Marschner-lite) specular.
  - Hair cards: generated ribbon strips that follow guide curves, using alpha-to-coverage and
    `MaterialAsset.translucency`.
  - Both use skinning so they follow animated characters.
- **Guides:** procedural guide curves grown from the surface, with simple comb and cut operations
  stored in the file, so edits are data an agent can write.
- **Simulation:** cheap secondary motion (spring per guide, driven by bone velocity and wind),
  with no full strand physics at first.
- **MCP tools:**
  - `groom.new/get/set/edit/open/preview/examples`.
  - `groom.apply { groom, target }`, where `target` is an entity, a `.character` part or a
    `.meshbuild` part.
  - `groom.presets` lists the built-in presets: short fur, shaggy fur, velvet/moss, grass-like
    tufts, straight hair, ponytail, mane and feathers.
  - `groom.apply` reports warnings for missing UVs, fur too dense for the triangle count, or masks
    that cover nothing.
- **Editor tab:** a live preview on the target mesh, sliders, and paint brushes for mask, length and
  comb that write into the file.
- **Builder hooks:**
  - Character Builder gets a `groom` key per part.
  - Mesh Builder parts gain `groom`, so a sculpted animal gets fur in the same file.
  - Terrain scatter can use shell fur for moss and lawn patches.
- **Performance:** a budget per preset, GPU time measured per pass (frame time on macOS is tied to the
  display's refresh), and instancing checked.
- **Demo scene:** `fur`, with a furry creature, a character with card hair and a mossy rock in wind.

## 4. Water

- **Water surface component:** Gerstner/FFT waves, refraction, depth color, screen-space
  reflections falling back to probes, and shoreline foam from scene depth.
- **Buoyancy:** physics bodies float using sample points, with drag.
- **Builder:** a `.water` file and tab, plus Terrain and Path hooks (rivers along a path, lakes
  filled to a height).
- **Demo scene:** `water`.

## 5. Navigation mesh and crowds

Navigation is a flat walkable grid today, which can't handle multiple floors, ramps or bridges well,
and NPCs don't avoid each other.

- **Baked navmesh:** recast-style voxelize, regions, polygons. Off-mesh links for jumps and ladders.
  `NavigationArea` keeps its settings.
- **Pathfinding:** `world.findPath` uses the navmesh when one is baked and falls back to the grid.
- **Crowds:** RVO/ORCA avoidance for agents moving at the same time. The existing `crowd` demo
  scene uses it.
- **Debug and tools:** navmesh overlay and `navigation.bake` MCP tool.

## 6. Localization

- **String tables:** `.strings` (a key with a value per language), with a builder tab in table form.
- **Runtime:** `Localization.current`, language switching at runtime, plural rules, and fallback to
  the base language.
- **Builder hooks:** Dialogue lines, UI text and Timeline subtitles can name a key instead of text.
  The checker reports missing keys and untranslated strings.
- **Fonts:** a fallback font per language for scripts the main font lacks.
- **MCP tools:** `strings.*`, and `strings.export`/`strings.import` as CSV for translators.

## 7. Open follow-ups (from Tools.md)

- Visual Script nodes for:
  - `PathFollower`
  - `world.findPath`
  - `world.gameUI`
  - timeline `holdFade` and dialogue keys
  - `DialoguePlayer.uiLayout`
- Fix `ParityTests.everyUIElementRunsACommandThatIsATool`: the console's `consoleCopy` button has
  no command.
- Make `MCPToolSchemaTests.subscribedResourcesReportUpdates` reliable in combined runs.
- Mesh Builder part colors (and other builders' color fields) may show sRGB file colors as
  linear.
- Recheck whether `asset.import` over MCP stdio still hangs when the source file is inside the
  project.
- Cooker: follow `.dialogue` references, and components that name a layout or path by plain path.
- An MCP tool to select inside a builder tab, so panels behind a selection can be checked in the
  running editor.

## Accepted ideas (not yet ordered)

Picked from idea polls. Each one follows the builder pattern above when it adds content.

### Rendering

- **Sky and volumetric clouds:** a physically based sky with a time-of-day cycle and raymarched
  clouds that cast shadows. Works with the existing `VolumetricFog`. Uses a `.sky` file and
  `sky.*` tools.
- **Screen-space GI, AO and reflections:** screen-space indirect diffuse light, a better ambient
  occlusion pass, and SSR that falls back to the reflection probes (item 2).
- **GPU-driven culling:** Hi-Z occlusion culling and indirect draws, so dense scatter, forests and
  GridMap cities stay fast. Measure GPU time per pass.

- **Hardware ray tracing:** ray-traced shadows, reflections and AO through Metal ray tracing and
  Vulkan ray queries, used when the GPU supports it and falling back to the raster paths.
- **Virtual textures:** streaming page-based textures for large terrains and texture-heavy
  scenes, with a feedback pass, a page cache and Library-cooked tiles.
- **Meshlets and mesh shaders:** cluster-based geometry with per-cluster LOD and culling (a small
  Nanite-style path), using mesh shaders where available and compute plus indirect draws
  elsewhere.
- **Subsurface scattering:** a screen-space diffusion profile for skin and wax, and thin-surface
  transmission for leaves and ears. Pairs with grooms and facial blend shapes.

- **GPU smoke and fire:** grid-based 3D fluid volumes (advection, pressure solve, temperature)
  for smoke, fire and explosions in the VFX Builder, raymarched with lighting and shadows.
  Wind and weather affect them.

### Characters and animation

- **Cloth:** a position-based cloth solver for capes, flags and skirts, pinned to bones and
  colliding with character capsules. Uses a `.cloth` file and one AI call to apply it, the same
  as `groom.apply`.
- **Facial blend shapes:** glTF morph targets, expression presets, and lip sync driven by
  Dialogue lines and their audio.
- **Motion matching:** pick poses from a clip database by trajectory and pose features. It is an
  Animation Graph node, so it mixes with state machines and IK.
- **Procedural creatures:** Mesh Builder bodies get an automatic rig, skin weights and procedural
  walk cycles for any number of legs. Works with IK foot placement and grooms.
- **Runtime character creator:** a customizer players use in game, with body and face sliders
  (blend shapes), outfits (equipment attachments), groom and color choices. Saved through
  `SaveGame` and replicated in multiplayer. A default `.ui` layout is included.
- **Mounts and riding:** mount and dismount, a rider attached with IK to saddle sockets,
  mount locomotion through the Animation Graph, and mounts NPCs can ride.
- **Flying and swimming:** locomotion modes for flight (glide, hover, flap) and swimming (surface
  and underwater, with buoyancy from water), plus 3D volume navigation for flying and swimming
  NPCs.

### Gameplay

- **Vehicles:** raycast wheels with suspension, tire friction curves, a drivetrain and a
  `.vehicle` builder.
- **Destruction:** Mesh Builder Voronoi fracture is baked when a part is imported. Pieces break
  off when hit hard enough, with debris pooling and VFX/sound hooks.
- **Weather:** rain, snow, wet surfaces and puddles, wind gusts and lightning. Drives VFX,
  post-FX, sound, `SceneEnvironment.wind` and how wet materials look. Uses a `.weather` file
  and blends between presets.
- **Items, inventory and crafting:** item definitions stored in Data Tables, inventories with
  stacking, weight and slots, equipment that attaches to character bones, crafting recipes, and
  pickups. Inventories save through `SaveGame`. Includes `items.*` MCP tools and Visual Script
  nodes. The default inventory UI is a `.ui` layout.

- **Soft bodies and fluids:** jiggle and squash soft bodies (shape matching, can also be applied
  to character parts) and small-scale SPH particle fluids for pours, splashes and slime, drawn
  through the VFX renderer.

### Procedural content

- **Dungeon generator:** rooms, corridors, keys and locks from a seed, built from GridMap pieces.
  Checked to be solvable using navigation, with a `.dungeon` file and tools to regenerate it. An
  agent can then tweak single rooms.
- **Quest and encounter generator:** fetch, defeat, escort and delivery encounters made from
  items, NPCs and Dialogue templates, scaled by difficulty. Needs a basic quest state model
  (objectives and rewards, saved through `SaveGame`). Quest graphs were not picked, so keep it
  minimal.

### Combat and interaction

- **Hitboxes and damage:** hitbox and hurtbox shapes keyed to animation frames in the Animation
  Graph and Character Builders, damage types and resistances, hit events for VFX, sound, game
  feel and ragdolls, and a Scene view debug overlay.
- **Weapons and projectiles:** a `.weapon` builder with fire modes, rate, recoil and spread
  patterns, hitscan or physics projectiles, ammo, and VFX/sound/IK-aim hooks. Weapons are
  inventory items.
- **Interaction:** interactable components with prompts (input glyphs that follow remapping),
  use and pick-up actions, doors, levers and containers, plus highlight outlines. Visual Script
  nodes included.
- **Abilities and status effects:** abilities stored as data with costs, cooldowns, targeting and
  effects, and buffs/debuffs with stacking rules and durations. Uses an `.ability` file and
  tools, and works with replication.
- **Achievements:** engine-side achievements and stats, defined in a Data Table and saved
  through `SaveGame`. Synced to Steam when Steam integration is enabled, and shown in a
  default `.ui` toast.

### Physics

- **Ropes and chains:** constraint chains that can be swung on, climbed and attached to
  bodies or bones. Drawn as `.path`-style sweeps or chain-link instances.
- **Continuous collision:** swept tests for fast bodies (bullets, thrown objects) so they don't
  pass through thin walls, turned on per `RigidBody`.
- **Character controller v2:** extends `CharacterController` with moving platforms, stairs and
  slopes, ledge grabs, mantling, climbing surfaces and crouch capsules. Ties into IK.
- **Physics materials:** friction, bounce and density per surface, with footstep, impact and
  scrape sounds and VFX per material pair. Mesh Builder looks and terrain layers can set one.

### Game UI

- **Menu and settings kit:** a ready-made main menu, pause menu, graphics/audio/control
  settings (including remapping and accessibility options) and save-slot screens as `.ui`
  layouts, themed by the project style.

### Cameras

- **Camera rigs:** third-person orbit, first-person, top-down and side-scrolling rigs with
  collision, look-ahead and smooth blends between rigs. A `CameraRig` component, ready for the
  templates.
- **Split-screen:** local split-screen for 2 to 4 players, with input devices assigned per player,
  a game UI layer per viewport and a render-scale budget per view.

### Cinematics

- **Cinematic camera tools:** camera rails on `.path` curves, look-at and framing constraints,
  depth-of-field focus pulls, shot cuts and blends as a Timeline camera track, and an in-game
  photo mode (free camera, post-FX sliders, hide UI).

### AI tooling

- **Agent playtesting:** MCP tools to run the game, send input actions, step frames, take
  screenshots and query world state. Assertions record pass/fail. Sessions can be recorded and
  replayed.
- **Text-to-level:** one MCP call turns a short brief into a level. It lays out GridMap rooms,
  terrain, paths and scatter, then checks that the level can be walked through, using navigation.
- **GPU profiler panel:** an editor timeline of per-pass GPU times, draw and triangle counts and
  memory, with `profiler.*` MCP tools so agents can find what slows a scene down.
- **Asset style consistency:** project-wide palettes and style presets (roughness range, edge
  wear, color saturation, texel density) that every builder applies. Includes a check that
  reports assets that don't match the project style.
- **Analytics and telemetry:** opt-in gameplay event logging from exported games (deaths,
  positions, timings) to a file or an endpoint you host. The editor shows heatmaps and paths in
  the Scene view, and `telemetry.*` MCP tools let an agent find balance problems.
- **Auto-balance:** agents play many headless runs and tune Data Table values toward targets you
  set (win rate, time to kill, economy curves). Every change is reported with before and after
  numbers. Builds on agent playtesting, telemetry and the dedicated server build.

### NPC AI

- **Perception:** sight cones with line-of-sight checks, hearing from sound events, and memory
  that fades over time. Exposed to Behavior Trees as conditions and blackboard values, with
  debug cones in the Scene view.
- **Utility AI and GOAP:** scored-action and goal-planning brains as alternatives to behavior
  trees, which can call behavior tree subtrees. Uses a `.brain` file, a builder tab and a live
  debugger showing scores and plans.
- **Squad tactics:** cover points generated from the navmesh, flanking, suppression roles and
  shared squad memory, built on perception, the navmesh and crowds.

### Accessibility

- **Input remapping:** a built-in remapping screen for input actions (keyboard and gamepad),
  hold-or-toggle options, one-handed presets and adjustable timing, saved per player.
- **Subtitles and captions:** styled subtitles from Dialogue and Timeline, captions for sound
  effects from Sound Builder tags, with options for size, background and speaker colors.
- **Colorblind and contrast modes:** colorblind correction filters in post-FX, a high-contrast UI
  theme, and an editor check that simulates colorblindness in the Scene view.
- **Screen reader:** game UI layouts expose labels and focus order to VoiceOver, Orca and
  Narrator. The UI Builder warns about elements without labels.

### Input

- **Touch and gestures:** touch input in the input action system (taps, swipes, pinches and
  drags), virtual sticks and buttons as `.ui` elements, and touch simulation with the mouse in
  the editor.
- **Motion and gyro input:** gyro aiming and motion controls for gamepads that report them
  (DualSense, Switch Pro, Steam Deck), mapped through input actions with sensitivity and
  smoothing settings.

### Platforms and shipping

- **Steam integration:** achievements, stats, cloud saves backed by `SaveGame`, rich presence,
  a Steam Deck input profile and verified-friendly defaults, and an export step that builds
  depots.

### World building

- **World streaming:** split worlds into tiled cells that load and unload around the player on
  a background thread, with streamed detail levels and impostors far away. The editor edits
  one region at a time.
- **Biome painter:** paint biomes that drive terrain layers, scatter, grooms, weather and
  ambient sound together, with blending at the borders. Uses a `.biome` file and
  `biome.paint` so an agent can lay out a world in a few calls.

### Multiplayer

All built on the existing networking (docs/Networking.md).

- **Replication components:** mark components and fields as replicated in the inspector or
  with an attribute. Includes snapshot interpolation, client prediction with reconciliation,
  and relevancy by distance.
- **Rollback netcode:** a deterministic fixed-step simulation mode, input delay plus rollback
  and resimulation, and a desync checker that compares world hashes. Aimed at fighting and
  action games.
- **Lobby and matchmaking:** lobbies, invites, ready states and host migration. NAT punch-through
  with a relay server fallback that can be hosted yourself. Steam lobbies are available when
  Steam integration is enabled.
- **Modding:** `.acro` mod packs made of builder files and visual scripts, loaded at runtime in a
  sandbox (no native code). Includes a mod browser in exported games, load order and conflict
  reports.
- **Network debugger:** an editor panel showing bandwidth per entity and component, simulated
  lag, jitter and packet loss, and a desync replay that compares world hashes frame by frame.
  Includes `net.*` MCP tools to read it.
- **Dedicated server build:** a headless export (no window or GPU, null graphics backend) for
  Linux and Windows, plus a Docker image and a health-check endpoint.

### Performance and scale

- **Job system:** a work-stealing scheduler that systems, animation, particles and import work
  can fan out to. Staged systems declare what they read and write, so stages that don't conflict
  run in parallel. Fits Swift 6 strict concurrency.
- **Multithreaded physics:** the broadphase and island solving run on the job system, giving the
  same results with any thread count (needed for rollback).
- **Memory budgets:** memory tracked per asset type and per system (GPU and CPU), with budgets
  per platform, an editor view and `memory.*` MCP tools. Going over budget reports warnings at
  import and in CI.

### Editor experience

- **Editor camera: return to origin and go to object:**
  - *Return to origin* (`view.home`, Home key, View menu): resets the Scene view's
    `EditorCamera` to its default view of the origin (pivot `(0, 0.5, 0)`, default yaw, pitch
    and distance). Optional `pivot`/`distance` arguments let it aim somewhere else.
  - *Go to object* (`view.goTo`, Cmd/Ctrl+G): a search popup that filters scene entities by
    name as you type. Picking one selects it and frames it, using `view.frameSelection`'s
    bounds logic. Over MCP it takes `entity` or `name`; an ambiguous name returns the
    candidates as an error.
  - Double-clicking a Hierarchy row frames that entity as well.

- **Snapping and align tools:** vertex, edge and surface snapping for the move gizmo, align and
  distribute, drop to ground, and pivot snapping. Includes `scene.align`/`scene.snap` MCP tools
  so agent-placed props sit flush.

- **Visual Script compiled to Swift:** shipping builds turn `.vscript` graphs into Swift that runs
  in the game module, at native speed and with the same behavior. Tests run both forms and
  compare the results.
- **Debugger for game code:** set breakpoints in game Swift code from the editor and inspect
  variables and entity state while paused, using LLDB with the hot-reloaded module. Pairs with
  the Visual Script debugger.

- **In-editor AI chat panel:** a docked panel that talks to Claude using the editor's own MCP
  tools. Shows tool calls as they run, with undo grouping per request, and can attach the
  selection or a viewport screenshot.
- **Scene and prefab diff and merge:** readable diffs of scene, prefab and builder JSON by
  entity and component, plus a 3-way merge tool and a git merge driver.
- **Undo history browser:** a visual undo timeline across the scene and every builder tab, with
  thumbnails, jumping to any step, and branches kept when you undo and then edit.

### Content pipeline

- **Texture painter:** paint albedo, roughness, metallic and normal maps on meshes in layers,
  with masks, brushes from proctex noise, and the result saved as builder data an agent can edit.
- **UV unwrapping and baking:** automatic UV unwrapping and packing, lightmap UVs (needed by item 2
  if lighting is baked later), and baking normal, AO and curvature maps from high-poly to
  low-poly, including Mesh Builder sculpts.
- **Packages:** share builder files, presets, styles and scripts as versioned packages across
  projects, with dependency resolution and a package browser in the editor.

### New-project templates

Each template is a playable project that puts the roadmap features together, and is kept
working by agent playtesting.

- **3rd-person action:** character, orbit camera, melee and ranged combat, IK, ragdolls,
  grooms and cloth.
- **2D platformer:** sprites, tilemaps, 2D physics, one-way platforms and tuned jump feel.
- **Open-world survival:** streaming, biomes, weather, day/night, inventory and crafting.
- **Online arena:** lobby, replication, rollback option, dedicated server and the network
  debugger.

### Team and production

- **Large-file asset storage:** Git LFS setup in new projects for textures, audio and glTF, or
  content-addressed storage so the Library cache and cooked output can be shared across
  machines.

### Documentation and learning

- **Interactive tutorials:** step-by-step tutorials in the editor that highlight the UI and check
  each step through the command registry (so the same tutorials can test the editor). Covers a
  first scene, first builder and first game module.
- **Sample game gallery:** small complete games, one per major feature, each with a write-up and
  checked by agent playtesting in CI.
- **AI agent cookbook:** tested MCP recipes for common tasks (make a character, build a level,
  tune a material, groom a creature), run as evals in `Evals/` so they stay correct.
- **Video capture:** record GIFs and MP4s of the editor or a running game (`capture.*` MCP tools),
  with a cursor overlay, for docs, bug reports and the sample gallery.
