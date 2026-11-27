# Changelog

Notable changes to Acro are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Version numbers are bumped automatically by `Scripts/version.sh`: MINOR when the public API of `Engine` or `EngineMCP` changes, PATCH for other source changes. While Acro is below 1.0, a MINOR release can contain breaking changes.

## [Unreleased]

### Added
- Fur and hair no longer alias: strand coverage is analytic and filtered (each strand's edge smoothed over the pixel from screen-space derivatives, strands thinner than a pixel drawn a pixel wide at their fractional opacity, and the pattern blending into its average, with tufts, once strands are about a pixel apart), shell fur is alpha blended inner to outer, fins (`GroomFins`) give close-ups strands at the silhouette, and hair cards pick MSAA samples by hashed alpha (`gl_SampleMask`) so overlapping cards fill a pixel; it stays steady under 4x MSAA and TAAU. `Scripts/compile-shaders.sh` takes a `// compile-shaders: wgsl <flags>` marker like the gles one.
- Skin and eye shading (roadmap 13A, pulled forward). Optional material blocks, off by default: `subsurface` (`MaterialSubsurface`: strength, radius in meters, per-channel falloff, transmission), `specularLobes` (two GGX lobes), `detailNormal` (procedural pores and creases in the mesh's own space, faded below a pixel) and `eye` (`MaterialEye`: iris color and size, pupil size, limbal ring, sclera color, veins, iris depth), in `.material` files, `material.set` and the Inspector's material form. They draw with a new shader variant (mesh_skin.frag, skin.glsl; other materials keep their exact shaders). Separable screen-space subsurface scattering (Jimenez et al. 2015) runs as a two-pass post effect on the HDR scene before fog and bloom, only in frames that show such a material: skin pixels carry their specular luminance in alpha so the pass can blur only their diffuse light, through the MSAA resolve, with no second render target. Light through ears and other thin parts uses the shadow map's thickness (Jimenez 2010); WebGL 2, low quality and `ENGINE_SSS=preintegrated` use Penner's pre-integrated skin shading instead, `ENGINE_SSS=off` turns scattering off. Eyes: a wet cornea, the iris refracted beneath it with a procedural pattern, pupil and limbal ring, veined sclera, occlusion at the corners. Presets `MaterialAsset.skin(_ tone:)` (`SkinTone`: pale, light, medium, tan, brown, deep) and `MaterialAsset.eye(iris:)`, and `MeshGeometry.eyeball` for the eye's UV layout. New demo scene `skin` (`SKIN_VIEW=face|ear|eye|tones`).
- Fur and hair cast and receive shadows and shade like hair: a few shells per groom (or its hair cards) draw into the shadow atlas cut to their strands (mesh_fur_depth, `GroomRenderer.castsShadows`, on by default), so fur shadows the ground and itself; the sun's shadow is read at each strand at three depths, so light reaches into fur by its length and density (deep-opacity style); ambient occlusion from root to tip follows density, thickness and clumping; and a Marschner-style hair model (R, TRT and TT lobes, multiple-scattering diffuse) replaces the two Kajiya-Kay highlights, with a lit rim when the sun is behind the hair. The fur scene takes `FUR_SUN=back`.
- Styled card hair in `.groom` files: parts (center, side or a curve), hair that lies on the scalp before it falls (`scalpHug`, `volume`, `sweepBack`), blue-noise roots with a soft hairline (`rootPlacement`, `hairlineWidth`), a flat inner layer and a few flyaways, tapered clumps (`clumpSize`, `cardTaper`), waves, length by region (`lengthProfile`), blunt cuts (`hemline`), bangs (`fringe`), ponytails (`tie`), and cards kept out of the mesh and `colliders` along their whole length. New hairstyle presets shortCrop, bob, bangs, longStraight, wavy and curly; straightHair and ponytail use the styling. Guides keep their per-point normals, layer, clump leader and length, and `GroomGeometry.cardSpans` maps each guide to its card vertices. The Groom Builder has a Hairstyle form; the `fur` demo's humanoid wears a side-parted hairdo (`FUR_VIEW=hairfront|hairside|hairback`, `FUR_HAIR=<preset>`).
- GPU particles and light probes on WebGL 2. Without compute, `ParticleSystem` simulates on the CPU (`simulatesOnCPU`, `ParticleSystem(device:simulatesOnCPU:)`): the same schedule, parameters, random numbers, ground and analytic colliders, sub-emitters, compaction and back-to-front sort as the compute shaders, drawn from per-instance attributes by a GLSL ES variant of the particle vertex shaders. Emitters larger than `cpuMaxCapacity` (65536) simulate every n-th particle, drawn n times brighter when additive, with a warning; depth-buffer collisions stay GPU-only (a warning). `ParticleSystem.Stats.cpuMilliseconds`. The probe-lit shaders have a GLSL ES variant that reads the probe data from a texture the WebGL 2 device copies the probe buffer into (storage buffers bound for GLSL ES that declares a texture at their binding), and probe bakes store their images from the CPU there (`RenderDevice.readFloatTexels`, synchronous on WebGL 2), so the `particles`, `rain` and `probes` scenes render as on WebGPU.
- Web exports ship textures for every GPU family: a pack per family (`game.bc.pack` and `game.astc.pack`, each an ordinary pack native players read too; meshes and other shared blobs are compressed once for both), listed in player.json's `packs`. The page asks the GPU which family it samples (WebGPU's `texture-compression-bc` / `texture-compression-astc` features, WebGL 2's BPTC, RGTC and ASTC extensions) and downloads only that pack, logging the choice (`[acro] textures: bc (...)`); `?textures=bc|astc` overrides it. `TextureFamily.choose` is the rule (`Web/loader.js` mirrors it), `TextureFamily.formats`, `CookPlatform.defaultTextureFamilies`, `AssetPackManifest.compressedTextureFormats`, `GameExportOptions.webTextureFamilies` / `textureFamilies`, `GameExportReport.familyPacks`. Web is the only target that defaults to both: `Editor --build-game --platform web --gpu bc|astc` (or `game.build`'s `textureFamily`) ships one family as a single `game.pack`, `--gpu all` both; the project's `build.textureFamily` applies to native builds. Players log at startup whether the pack's textures are sampled as cooked or partly decoded (`GamePlayer.textureSupportNote`).
- `TextureCodec.decodeForUpload`: what a GPU that can't sample a format gets instead (RGBA8, sRGB where the format is; RGBA16F for BC6H and ASTC HDR; two-channel normal maps expanded). `RenderDevice.makeTexture(compressedLevels:format:)` uses it and now warns once per format (it logged at info level), so a browser with neither BC nor ASTC, or ASTC HDR on WebGPU, still draws every texture.
- Material graphs on WebGL 2: graph materials, masked graph shadows and depth, graph decals and terrain splatting now draw with the WebGL 2 renderer instead of their plain surface. The graph templates have a GLSL ES variant that reads the graph's values from a std140 uniform block (`compile-shaders.sh` `// compile-shaders: gles <flags>`), and `MaterialGraphCompiler` splices each graph's code into it as for MSL and WGSL (`MaterialGraphProgram.glesFragment`, `glesDepthFragment`, `glesDecalFragment`). Graphs with more than `MaterialGraphCompiler.maxUniformValues` (1024) values still draw plain there, with a warning. `noperspective` varyings (debug lines) are emulated in GLSL ES instead of interpolating with perspective.
- Mesh and Material fields in the Inspector (MeshRenderer, Decal, and the Material section's header) show the asset's preview and name, and a click opens a picker: a modal list of the meshes or materials with previews, names and where each comes from (Built-in or its file), searchable, with the current one selected; Enter, a double-click or Select picks it (one undo step), Esc or Cancel closes it.
- A Material section in the Inspector for an object with a MeshRenderer: a foldable header with a preview and a picker for its material, then a larger preview, where the material comes from (Open in Material Builder, Select), and the material's settings, edited in place (each gesture one undo step, saved to the .material file, so every object using it changes). A built-in or model-imported material is read-only there, with New Material / Make Editable Copy, which writes a .material file and switches the object to it in one undo step.
- Right-click menus on the editor's tabs (Close, Close Other Tabs, Open in New Window — Float for the Scene and Game views —, Dock for a floating panel, Reset Layout) and on scene objects in the Hierarchy and the Scene view (Rename, Duplicate, Delete, Frame in Scene View, Create Empty Child, Unparent and the prefab actions; the Create items over empty space). A right-click in the Scene view selects what is under it; dragging with the right button still flies. Items run the same commands agents use and are disabled when their command isn't available.
- Open in Pop-Out: builder files (models, dialogue trees, timelines, effects…) open in their builder in a separate OS window from the Assets panel's right-click menu or the asset inspector, with the builder's sidebar in the window, so they stay in view while you work elsewhere, on another display if you like. Closing the window docks the builder again; opening another file of that kind reuses the window. `panel.popOut` pops out any other panel too (the Scene and Game views float inside the editor). Tools `asset.openPopOut` and `panel.popOut`; `panel.list` reports `window`.
- `Engine.openWindow` opens another OS window with its own `Input` and `UIDrawList`, drawn and presented with the main window's frame (`EngineWindow`), on Metal (AppKit) and Vulkan (GLFW, a swapchain per window); `DockSpace.showExternally` keeps a panel shown in such a window out of the layout.
- Builder sidebars in the Inspector: while the Inspector is open, the side panel of the builder tab in front (Mesh, Terrain, VFX, Material, Timeline and the others) shows in the Inspector instead of beside the builder's view, so the view gets the tab's whole width. Picking the Scene or Game view brings the Inspector back to the selection; with the Inspector closed the panel stays in its tab. `EditorBuilderTab.sidebar`, `InspectorPanel.showBuilderPanel`.
- The toolbar's View menu is short and grouped: Panels ▸ and Builders ▸ (open ones checked); Go to Object…, Return to Origin, Animate in Scene View, Scene Post-FX ▸, Lighting ▸ (Bake, Show Light Probes, Irradiance Only); Theme ▸ and Zoom ▸; Reset Layout and Settings…, with shortcuts shown at the right. `PopupMenu` gets submenus (hover, click or Right opens them; picking in one closes the chain), separators (`separatorsBefore`) and `itemShortcuts`; a press in a menu under its open submenu now goes to that menu.
- The crash-recovery prompt has **Ignore Changes**, which deletes the work the last session left behind (`scene.discardRecovery`), so it stops asking at every launch; Not Now still keeps it for later. `ConfirmDialog.addAlternative` adds such a third answer.
- A sound inspector for audio files (wav, ogg, mp3) and `.sfx`: the waveform (a lane per channel, read in the background) with a moving playhead (click it to play from there), Play / Stop and Loop, and the format, duration, sample rate, channels, frames, file size and bitrate, peak and RMS loudness in dBFS. Selecting a sound in the asset browser doesn't play it; songs stream from their file, and one starting part way in is skipped to off the main thread. Tools `audio.info` and `audio.preview` (from a time, looping, stop). In the Timeline Builder, clicking an audio track or key plays its sound with the key's volume and pitch, and audio keys get a **Play Sound** button. One preview plays at a time; playing the timeline stops it. `EditorSession.previewSound(asset:)`, `previewSound(clip:volume:pitch:)`, `toggleSoundPreview(asset:)`, `soundPreviewAsset`, `isSoundAsset(_:)`, `stopSoundPreview()` (the Sound Builder's preview shares it).
- WebGL 2 renderer for the web (`GraphicsBackend.webgl2`, `WebGL2RenderDevice`): browsers without WebGPU fall back to it, and players can pick either with `?renderer=webgpu|webgl2|auto`, a saved choice (`acro.setRenderer`, `WebHost.setRenderer`, `WebHost.renderer`, `WebHost.availableRenderers`) or the export's default (`renderer` in player.json; the Export Game dialog's Renderer, `game.build` `renderer`, `Editor --build-game --renderer`). Shaders are cross-compiled to GLSL ES 3.00 (`Scripts/spirv-to-gles.c`, `.gles` files next to the `.wgsl`, `ShaderSource.glesVertex` / `glesFragment`). Draws are recorded into a command buffer in WebAssembly memory and run by `Web/webgl2.js` in one call per frame. No compute or storage buffers there (`RenderDevice.supportsCompute`, `supportsStorageBuffers`): GPU particles, light probes, material graphs (drawn with their plain material) and FSR 3 are skipped with one warning each (particles, probes and material graphs work there since). The page only shows an error when neither renderer works.
- Camera rigs: a `CameraRig` component says how a camera follows a target: third-person orbit (shoulder offset, pitch limits, zoom, auto-recenter behind the target), first person (head bob, optional body turning), top-down, side-scroller (dead zone, look-ahead in the walking direction) or fixed (a placed shot). The enabled rig with the highest priority drives the scene's camera; switching blends position, rotation and field of view over the rig's `blendTime` with an easing curve (`world.activateCameraRig`, `CameraRigSystem`). A sphere cast keeps walls from coming between the target and the camera (pulls in at once, eases back out), ignoring the target's own colliders, its character and its ragdoll's bodies. Position (per axis) and rotation smoothing are time constants, the same at any frame rate. Orbit, zoom and recenter come from input actions (right stick, d-pad, right-stick click; mouse with the right button held or captured, scroll wheel) with sensitivity and invert settings. Every key is optional; mode-dependent settings default per mode. The editor's play mode, GameRunner and exported games run rigs (the Game view's caption names the live rig); the Scene view draws each rig's camera, followed point and collision probe. Tools `cameraRig.state`, `cameraRig.activate` and `cameraRig.setTarget`; Visual Script nodes Activate Camera Rig, Set Camera Rig Target, Set Camera Rig Mode and Live Camera Rig. Demo scene `camerarigs`; SampleGame `CameraRigs.scene` with a playtest.
- Light probes: `ReflectionProbe` (a box-projected reflection captured from its point, blended by its influence box with a `blendDistance`, higher `priority` or smaller boxes first, falling back to the sky where no probe covers a point) and `IrradianceVolume` (a grid of L2 spherical-harmonic probes giving indirect diffuse light to everything in its box, trilinear, with normal and view bias, a backface weight and probes found inside geometry turned off, several `bounces`). Every key is optional. Baked on the GPU (six capture faces, equirectangular images, the environment's prefilter and SH projection, a compute store), identical on Metal and Vulkan; `SceneRenderer.bakeProbes`, `bakesProbesAutomatically`, `probeDebug` (probe spheres, irradiance-only view), `LightProbeDebug.drawVolumes`. Bakes are cached in the project's `Library/Lighting` (`LightProbeBakeCache`) and cooked into exported games (`AssetPackManifest.lighting`), which load them instead of baking. Editor MCP tools `lighting.bake` (probe counts, bake time, warnings such as probes inside geometry and volumes without probes) and `lighting.debug`; View menu Bake Lighting, Show Light Probes and Irradiance Only; Add Component entries and icons. Demo scene `probes`: a room lit through a window.
- Fur and hair: the Groom Builder (`.groom` files: shell fur or hair cards, length, density, thickness, clumping, curl, frizz, gravity, stiffness, root and tip colors, masks by texture, vertex paint or part names, comb direction or flow texture, wind, detail levels, comb and cut strokes). A `GroomRenderer` grows a groom on its entity's mesh, skinned meshes included: instanced shells or ribbon cards along procedural guide curves with alpha-to-coverage, anisotropic strand highlights, wind and a spring per bone, and a fur-colored undercoat in the distance; Metal and Vulkan match. Tools `groom.new`, `.get`, `.set`, `.edit`, `.open`, `.preview`, `.examples`, `.presets` and `.apply` (an entity, a `.character` region or attachment, or a `.meshbuild` part; warns about missing UVs, fur too dense for the mesh and masks that cover nothing). The Groom Builder tab shows the fur live and paints mask, length and comb strokes into the file. Mesh Builder parts, `.character` regions (`grooms`) and attachments, and terrain scatter rules take a `groom`. `PipelineDescriptor.alphaToCoverage`. Demo scene `fur`.
- Navigation meshes (`NavMesh`): baked recast-style from the static colliders (voxel columns with every surface a ray down crosses, erosion by the agent radius, single-layer regions, convex polygons with detail heights), so floors above one another, ramps, bridges and the ground under them all work. `NavigationLink` components add off-mesh links (jump, drop, ladder; one-way or both ways, with an extra cost). Paths are A* over the polygons plus the funnel algorithm, with points added where they bend over a slope change. `world.bakeNavigation()` bakes the navmesh along with the grid (`NavigationSettings.navMesh`, new optional `NavigationArea` keys `navMesh`, `voxelSize`, `maxPolygonSize`); `world.findPath` and behavior trees use the navmesh when there is one and fall back to the grid. Also `world.bakeNavMesh()` (polygon count, bake time, warnings such as unreachable areas), `world.findNavigationPath` (with each segment's link kind), `NavMesh.locate`, `nearest`, `isClear`, `move` (slides along walls on the surface) and `drawDebug`.
- Crowd avoidance: `NavigationCrowd` (ORCA, deterministic). Behavior tree agents moving at once steer around each other (`BehaviorTreeRunner.avoidance`, `radius`); agents moved by their transform follow the navmesh surface (heights on ramps and floors) and cross off-mesh links along an arc (jumps, drops) or climb them (ladders).
- Navmesh bakes are cached in the project's `Library/Navigation` by what they were baked from (`NavigationBakeCache`) and cooked into exported games' packs (`AssetPackManifest.navigation`), which load them instead of baking.
- Editor MCP tools `navigation.bake` (polygons, islands, area, bake time, warnings, cache file), `navigation.query` (a path with its segment kinds and length, whether the ends are on the mesh and connected, the nearest walkable point) and `navigation.overlay` (the navmesh, links and agents' paths in the Scene view; `EditorSession.sceneOverlays` lets builder tools add Scene view overlays). `behavior.navigation` reports the navmesh's polygon count and returns navmesh paths.
- Demo scene `navmesh`: two floors joined by a ramp and a bridge, a one-way jump link, and behavior tree agents patrolling across them while avoiding each other, with the navmesh drawn over the level (N toggles it). The `crowd` scene's 144 foxes now walk through each other in two groups on a navmesh with crowd avoidance (N shows the navmesh and paths).
- Inverse kinematics on animators (`Animator.ik`, `.animgraph` `ik`): two-bone IK with a pole (arms, legs), aim chains (head, spine, weapon), FABRIK chains (tails, tentacles) and foot placement (rays against physics, pelvis drop, feet aligned to the ground's normal, planted feet locked). Nodes run after the states and layers and before the pose reaches the bones; each weight can follow a float parameter; targets are world points (`Animator.setIKTarget`) or entities followed by name. Solvers are public in `IKSolver`.
- Ragdolls: a `Ragdoll` component builds capsule bodies and limited joints from a skeleton's bones. Bodies follow the animation as kinematic hit boxes, take hits while the animation pulls them back (`hit`, partial), go limp (`goLimp`) and blend back to the animation (`getUp`), standing the character up under the pelvis. `world.addPhysics` runs them.
- Joint limits (`JointLimits` on `Joint` and `JointDescriptor`): a ball joint's swing cone and twist range, a hinge's angle range.
- Character Builder: a Ragdoll section (automatic body sizes from the body shapes, editable radii, limits and masses, Test Ragdoll) and IK switches (foot placement, look at, hand reach); `.character` keys `ragdoll` and `ik`; tools `character.ragdoll` and `character.ik`. The Animation Graph Builder lists, adds and edits IK nodes; `animGraph.edit` has `addIK`, `updateIK`, `removeIK`.
- Visual Script nodes Set IK Target, Set IK Weight, Enable Ragdoll, Apply Impulse to Bone and Ragdoll State.
- Demo scene `ik`: a character standing across uneven stairs, one aiming at and reaching for a moving target, and a ragdoll pushed off a crate that gets up again.
- Agent playtesting ([docs/Playtesting.md](docs/Playtesting.md)). New editor MCP tools: `input.action` presses input actions by name (tap, hold, press / release, analog `value`), `input.gamepad` drives a virtual gamepad, and `input.actions` lists the actions the scene's visual scripts and the playtest define. `playtest.assert` checks the world and records pass or fail: an entity, a component field, a visual script variable, a world position, or a count of entities. `playtest.start`, `playtest.result`, `playtest.save`, `playtest.stop` and `playtest.run` record a session as a `.playtest.json` file and replay it with its assertions checked again.
- `GameRunner <module | none> --playtest <file | folder> [--report out.json]` replays playtests headless at a fixed time step and exits 1 when an assertion fails (2 when one can't run). `GameRunner <module> <scene> --mcp` serves the scene headless to an MCP client with the same tools.
- Engine: `Playtest` (the file format), `PlaytestDriver` (runs, checks and records steps against any host), `PlaytestHeadlessHost` (a scene played without a window) and `PlaytestMCP`.
- SampleGame: a Player that walks with input actions (`Scripts/Player.vscript`) and a playtest for it (`Projects/SampleGame/Playtests/PlayerMoves.playtest.json`).
- Return to Origin (`view.home`, the Home key, the View menu) puts the Scene view's camera back on its default view of the origin; `pivot` and `distance` aim it elsewhere from the same angle.
- Go to Object (`view.goTo`, Cmd/Ctrl+G, the View menu): a search over the scene's entities that filters by name as you type (Up / Down, Enter or a click picks one), then selects and frames it as Frame Selection does. Over MCP it takes `entity` or `name` (whole names and "Parent/Child" paths first, then part of a name); a name that matches several entities fails and lists them with their ids.
- Double-clicking a Hierarchy row frames that entity in the Scene view (F2 still renames). `TreeView.onDoubleClick`.
- `builder.select`: selects inside a builder tab as a click there does (Mesh Builder parts; Animation Graph states, transitions, Any State, parameters and layers; Behavior Tree, Dialogue and Visual Script nodes), so an MCP client can check the panels that only show for a selection. Workspaces take part through `EditorBuilderSelecting`.
- Visual Script nodes for more builder pieces: path followers (`pathFollower.play`, `.pause`, `.resume`, `.stop`, `.seek`, `.state`, On Path Follower Event), grid navigation (`navigation.findPath`, which bakes the grid on first use, and `navigation.bake`), the game UI layer (`gameUI.setValue`, `.getValue`, `.layout`, `.hideAll`, On Game UI Event), timelines (`timeline.clearFade` for `holdFade` timelines, `timeline.dialogue` and `timeline.releaseDialogue` for `wait` dialogue keys) and dialogue layouts (`dialogue.setLayout`, `dialogue.layout`). `TimelinePlayer.clearFade()`, `waitingDialogue` and `startedDialogues`.
- Character controller v2: crouching (`crouch`, `crouchHeight`, `crouchSpeedScale`; stands up only with room above, `PhysicsWorld.canStand`; a capsule `Collider` on the entity follows the height), ledge grabs (`grabLedge`, or `grabLedges` to catch ledges while falling toward them), hanging with sideways shimmy, mantling (`mantle`, from a ledge or onto a low wall in front; ends crouched under a low ceiling), climbing walls whose physics material is `climbable` (`climbSpeed`), and `mode` / `ledgePoint` / `ledgeNormal` / `handTargets` (hand points for arm IK). Ledges and climbed walls carry the character when they move; jumping off a rising platform keeps its upward speed.
- Continuous collision: `RigidBody.continuous` / `BodyDescriptor.continuous` sweep fast bodies (bullets, thrown objects) from their pose before the step to after it so they stop at thin walls instead of passing through.
- Physics materials: `.physmat` files (friction, bounce, density, climbable, footstep / impact / scrape sounds and VFX, per-pair overrides; importer with warnings), 17 built-ins (wood, metal, stone, ice, rubber, climbingWall…) and the `PhysicsSurface` component that applies one to a collider (or its children). `physics.materialUnder`, `surfaceMaterialName(of:at:)`; per-area materials (`PhysicsSurfaceGrid`). Play mode adds "physics.surfaceEffects", which plays the effects. Mesh Builder parts take `physicsMaterial` (else their `look` implies one) and terrain layers take `physicsMaterial` (chunk colliders answer per painted cell).
- `PhysicsEvent.speed` (impact speed of `collisionBegan`) and `PhysicsWorld.slidingContacts(minSpeed:)`.
- MCP tools `physicsMaterial.new`, `.get`, `.set`, `.edit`, `.list`, `physics.materialAt`, `character.state` and `character.action`. Visual Script nodes Crouch, Grab Ledge, Mantle, Let Go, Character State and Material Under Point.
- Demo scene `physics2`: stairs and slopes, a moving platform, hanging, mantling, climbing and crouching characters, balls and crates on rubber, wood and ice, and bullets through a thin wall with continuous collision off and on. SampleGame: `Scenes/Physics2.scene` and `Playtests/Physics2.playtest.json`.
- Visual Script nodes for more builder pieces: path followers (`pathFollower.play`, `.pause`, `.resume`, `.stop`, `.seek`, `.state`, On Path Follower Event), grid navigation (`navigation.findPath`, which bakes the grid and navmesh on first use and uses the navmesh when there is one, and `navigation.bake`), the game UI layer (`gameUI.setValue`, `.getValue`, `.layout`, `.hideAll`, On Game UI Event), timelines (`timeline.clearFade` for `holdFade` timelines, `timeline.dialogue` and `timeline.releaseDialogue` for `wait` dialogue keys) and dialogue layouts (`dialogue.setLayout`, `dialogue.layout`). `TimelinePlayer.clearFade()`, `waitingDialogue` and `startedDialogues`.
- Damage: a `Health` component (max, current, resistances per damage type, team, invulnerability after a hit, ragdoll on death, removal after death), damage types with knockback, hit stop, shake, flash, VFX, sound and ragdoll reaction (`DamageType`, built-ins physical, slash, blunt, pierce, fire, ice, electric, poison; `World.combat.damageTypes` for a game's), `World.applyDamage` / `heal`, and a hit log of `HitEvent`s (attacker, victim, damage, type, point, normal, bone, region, killed).
- Hitboxes and hurtboxes: `Hurtbox` shapes (sphere, capsule, box on any entity or bone, with a region and damage multiplier) and `Hitbox` shapes that deal damage while active; hitbox tracks on animators (`Animator.hitboxes`, `.animgraph` `hitboxes`: a shape on a bone active during part of a state's cycle). The play-mode combat system hits each victim once per swing (or again every `rehitInterval`), picks the hurtbox with the highest multiplier, and turns hits into effects: the damage type's VFX and sound (else the victim's physics material impact effect), a hit flash, hit stop, camera shake, a partial ragdoll hit reaction, full ragdoll on death (else the Animator's `hit` / `die` triggers) and knockback on rigid bodies.
- Game feel: `World.timeScale`, `World.hitStop(_:scale:)` (`WorldTime.unscaledDelta` keeps real time) and `GameFeel` (trauma camera shake applied after camera rigs, hit flashes).
- Interaction: `Interactable` (prompt verb, use or pick-up action, range, once) and `Interactor` (reach, view angle, forward or the camera's view, use and pick-up actions, items carried). The interaction system focuses the best interactable by distance and view angle, brightens it, shows a billboard prompt with the action's current input glyph ("[E] Open"; it follows rebinding and switches to the gamepad's), and uses it on the action. Ready-made `Door` (locked doors take a key item), `Lever` (toggles a target by name), `Container` (opens its lid, hands over its items) and `Pickup`. The editor's Game view outlines the focused interactable with the selection outline (`World.interactionFocus`).
- `.character` `combat` section (Character Builder Combat section, `character.combat`): a `Health` on the prefab, hurtboxes over the ragdoll bodies with multipliers per body region (head 2, torso 1, limbs 0.75) and the template's attack hitbox track. Character importer version 3. The Animation Graph Builder lists, adds and edits hitboxes.
- MCP tools `animGraph.hitboxes`, `character.combat`, `combat.inspect`, `combat.simulateHit`, `combat.overlay` (hitboxes and hurtboxes in the Scene view, active ones highlighted), `interaction.list` and `interaction.use`. Visual Script nodes Apply Damage, Heal, Get Health, Hit Stop, Camera Shake, Set Interactable Enabled, Interact, Get Interaction Focus and the events On Hit, On Hit Dealt, On Death and On Interact.
- Demo scene `combat`: a fighter's sword swing kills a training dummy that flinches, then ragdolls, and a lever-opened gate and a chest used by two visitors with prompts. SampleGame: `Scenes/Interact.scene` and `Scenes/Combat.scene` with playtests that use a lever and a chest and land three sword hits.
- `FieldHints.srgb`: a color field that holds display (sRGB) values; the property grid shows and writes them as they are. `TextField.onKey` sees keys before the field does.
- Compressed asset packs (pack version 2, every platform): meshes are stored quantized (positions on a 16-bit power-of-two grid no coarser than 2^-10, octahedral 12-bit normals and tangents, 16-bit UVs, delta-coded byte planes, deflated; `PackMeshCodec`) and other blobs deflated when that saves 10% (`AssetPackBlob.encoding`, `rawSize`). The Racing project's pack goes from 126.5 MB to 31.9 MB (meshes 89.9 MB to 9.0 MB). `AssetPack` decodes them as it reads; a pack with nothing compressed is still written as version 1, and `Editor --cook --uncompressed` (`CookOptions.compressesBlobs`) writes one. Cook summaries show raw and stored sizes (`CookReport.storedMeshBytes` ...). The cooker compresses in parallel.
- Web export: the page shows a progress bar while the pack and the wasm download (`packSize`, `wasmSize` in `player.json` give the totals when the server compresses or doesn't say), and keeps the pack in the browser's cache (Cache API, keyed by `packHash`, the pack header's hash), so a second visit doesn't download it again. The wasm now downloads (and compiles) at the same time as the pack, not after it.
- Material graphs on WebGPU: `MaterialGraphCompiler` splices the graph's code into the WGSL of mesh_graph, mesh_graph_depth and decal_graph at run time, as it does for MSL (`MaterialGraphProgram.wgslFragment`, `wgslDepthFragment`, `wgslDecalFragment`), so graph materials, masked graph shadows, graph decals and terrain graph layers draw in the browser.
- Web: saves and settings persist across reloads. `UserData` is `/userdata/<app>` on WASI; `Web/saves.js` preloads it from IndexedDB before the game starts and writes it back after each save (`UserData.onChange`, `UserData.changed()`, `acro.onUserDataChange`). Web exports ship `saves.js`.
- `Key` cases for punctuation (`minus`, `equal`, `semicolon`, `apostrophe`, `backslash`, `period`, `slash`) and the numeric keypad (`numpad0`…`numpad9`, `numpadDecimal`, `numpadAdd`, `numpadSubtract`, `numpadMultiply`, `numpadDivide`, `numpadEqual`), by physical key on macOS, Windows, Linux and the web. The keypad's Enter is `enter` on every platform.
- Demo scene `graphs`: a sphere per material graph preset on a splat terrain with a lava graph layer.

### Fixed
- Web: alpha-to-coverage pipelines (fur and hair cards) in one-sample passes alpha-test at one half on WebGPU and WebGL 2, as one sample does on Metal and Vulkan; WebGPU allows alpha-to-coverage only with MSAA and WebGL 2 ignores it without, so the cards drew every faint fragment (`AlphaToCoverageFallback`).
- Shadow lookups outside the shadow map are lit in the shader (the Demo's `lit.frag`), instead of depending on the comparison sampler's white border, which WebGPU and WebGL 2 don't have (they clamp to the edge texel).
- macOS: the engine's main loop now drains an autorelease pool every frame (`Engine.tick`). It never did, so each frame's drawable and command buffers stayed alive until exit, each holding an IOSurface shared event; at 120 Hz the editor or a game used up the whole system's 65,535 in about 9 minutes, after which no process on the Mac could make one: browsers lost WebGPU (Edge: "Failed to create MTLSharedEvent"; Safari: `createTexture` threw InvalidStateError) and other Metal apps could fail. The editor now holds about 330 Mach ports instead of growing by ~120 a second.
- Web: folders listed empty in the browser (the WASI shim gives every directory entry inode 0, which Swift's `FileManager` skips), so an `AssetDatabase` found no files; the loader gives entries a nonzero inode. The `forest` and `fur` Demo scenes run in the browser.
- Mesh Builder looks trapped on wasm32 when a part's name hashed above `Int32.max` (`Int(UInt32)`).
- The private `Health` test components of `WorldTests` and `TweenTests` have their own component names, so they no longer clash with the engine's `Health`.
- A `Ragdoll` in a scene with no `Collider` does something in play: editor play mode, `ScenePlayback` and networked GameRunner start 3D physics when `World.needsPhysics` (a `Collider` or a `Ragdoll`).
- The `ik` demo scene: the ragdoll is pushed off the crate's corner hard enough to lie on the floor by the screenshot frame (it hung over the edge), and each character wears its own shirt color (the near-white tints didn't show).
- `EditorLayoutTests.viewMenuSwitchesThemeAndZoom` finds View menu entries by title, so Return to Origin and Go to Object didn't break it.
- GameRunner loads the `VisualScript` components of the first scene it plays. They were registered only once play systems started, so scripts in that scene didn't run.
- Builder color fields stored as sRGB (Mesh Builder part color and glow, Path Builder profile and piece colors, terrain layers, procedural textures, Timeline fade keys, the Tilemap and VFX backgrounds, character recolors) showed in the property grid as if linear, lighter than the file's color, and wrote linear values back.
- Cooked games ship `.dialogue` files (they had no data in the pack) and what they name by path or id (portraits, `uiLayout`), and the files scene and prefab components name by plain path: a `PathFollower`'s `.path`, a `UILayoutPlayer`'s layout, a `DialoguePlayer`'s dialogue and layout, a `TimelinePlayer`'s timeline. Paths inside JSON held in strings (a prefab's scene data) are followed too.
- `MCPToolSchemaTests.subscribedResourcesReportUpdates` no longer depends on how long a call takes: `EditorMCP.resourceCheckInterval` (default 200 ms) can be 0 to check subscribed resources on every pump.

### Changed
- Web: when WebGPU is there but gives no adapter, the page's message names the browser's own diagnostics page (`about:support` in Firefox, `edge://gpu` in Edge, `chrome://gpu` in Chrome) instead of Chrome's in every browser. Firefox 160 and WebKit 26.4 run every Demo scene and SampleGame (`Spikes/WebPlayerCheck/browsers.mjs`; [docs/wasm-spike.md](docs/wasm-spike.md), "Firefox and Safari (W2.7B)").
- An upscaler the device can't run falls back instead of being refused (an error at startup, kept old value at run time): FSR 3 and MetalFX temporal to TAAU, then FSR 1, then bilinear; MetalFX spatial and TAAU to FSR 1, then bilinear. One log line names the request, why it can't run and the pick (`Upscaler.fallbacks`, `Upscaler.choose`). So `ENGINE_UPSCALER=fsr3` on the web gives TAAU.
- Packs cooked with compression (the default) are version 2: engines from before it refuse them as "newer than this engine reads". Re-cook with `--uncompressed` for an older player.
- Web builds run CPU-heavy frames faster ([docs/wasm-spike.md](docs/wasm-spike.md), "Performance"): the Crowd Demo scene in Chromium went from 17.9 to 12.5 ms per frame (a steady 60 fps in real time, from ~47) and Racing from 7.1 to 3.4 ms. The WebGPU backend no longer converts a Swift string to JavaScript on every `setIndexBuffer` (6 ms of Racing's frame) or allocates per draw to match bind groups. Wasm builds compile the engine, and Web exports the game, with WebAssembly SIMD (`-msimd128`). The write-up also estimates what `wasip1-threads` would give (about 15-20% on Crowd, nothing on Racing) and what hosting it needs.
- Physics: the narrowphase makes each body's world-space shape once per step instead of once per contact, and GJK no longer allocates; results are bit-identical. `awakeBodyCount` and `touchingContactCount` no longer copy bodies.
- `Spikes/WebPlayerCheck/profile.mjs` times a web player over a fixed frame range and CPU-profiles it through Chrome's DevTools protocol, with Swift names.
- The Windows workflow exports and starts a game on every push to main and when run by hand, and no longer on pull requests or nightly. Its build cache leaves out the `.build/debug` symlink, which came back from the cache as a plain folder and hid the new `GameRunner.exe`.

## [0.18.1] - 2026-11-17

### Changed

- The Mesh Builder's algorithms (shapes, sculpting, looks, foliage, LOD, ambient occlusion) and the importers that run them (mesh builds, terrain, grid maps, paths, characters, procedural textures) moved out of EngineAssets into a new module, EngineMeshBuild, which compiles in parallel with EngineRendering in release builds. Their data types (`MeshBuild`, `MeshBuildPart` and what it holds) stay in EngineAssets. `import Engine` and the `Engine` product are unchanged, and the importers are still in `AssetImporterRegistry.builtIn`.
- Mesh builds bake ambient occlusion only when the file sets `"ao": true` (it was on by default). Baking tessellates every mesh first, which took simple pieces from 12 to thousands of triangles; GridMap levels made of such pieces carried all of it. The examples set `"ao": true`. Edge-worn parts are still tessellated for their wear band.
- Prefab sync and undo turn components into `JSONValue`s faster (`JSONValue.parse`).
- Text layout kerns faster: a font's GPOS pair-kerning coverage and classes are expanded into per-glyph tables when it loads, instead of scanning their glyph ranges for every pair. Laying out the editor's panels took about a quarter of the time in the layout tests.
- Mesh builds import faster in debug builds (sculpts, look textures, ambient occlusion, edge wear): their per-sample loops avoid the generic range iterators and tuples that debug builds run slowly (`forEachIndex`).
- The Windows workflow exports and starts a game only when packaging, the sample game, `Package.swift`, `Windows/` or the workflow change, nightly, and when run by hand: the export compiles the engine a second time (about 15 minutes).
- The builder tabs moved out of `EditorCore` into five modules that compile in parallel (`EditorBuildersMesh`, `EditorBuildersWorld`, `EditorBuilders2D`, `EditorBuildersAnimation`, `EditorBuildersLogic`), registered through `EditorBuilderModule` (`EditorBuilders.registerAll()`; found automatically on first use). EditorCore went from 54k to 27k lines; with `EngineMeshBuild`, a clean release build of every product took 165 s instead of 190 s on a 10-core Mac.
- CI: Linux and macOS run the release build and the tests as parallel jobs; the test jobs and the Windows build keep `.build` in the Actions cache (`Scripts/restore-mtimes.pl` sets each file's time to its last commit so unchanged modules aren't rebuilt); the Windows workflow builds in debug.

### Fixed

- `Editor --mcp --project <folder>` (what a project's `.mcp.json` runs) attaches to an editor that already has that project open, relaying the client to its HTTP server (`MCPStdioRelay`), instead of opening a second editor window. `--mcp-new-editor` opens one anyway. An editor that leaves a project marks that project's `Library/mcp.json` as no longer served.
- The builder tabs' 3D views (Mesh, VFX, Material, Terrain, GridMap, Path, Timeline, Animation Graph, Character, Post-FX) orbit, pan and zoom again: the layout containers around each view caught the pointer, so the UI kept it.

## [0.17.1] - 2026-11-16

### Added

- Mesh Builder:
  - Part shapes: rounded boxes and cylinders (bevel), lathe, extrude, sweep (along a Catmull-Rom path) and loft; deformers (taper, bend, twist, noise); `mirror` and `repeat` part keys.
  - Sculpt parts: a subtree combined as signed distance fields (add, subtract, intersect, smooth blend) and meshed by dual contouring. Sculpt children can keep their own looks, which blend across their boundary. Sculpts work in terrain scatter and character attachments.
  - Looks: generated surface textures with wear, worn convex edges (`EdgeWear`), and baked ambient occlusion; new proctex noise kinds (fbm, ridged, voronoi, cells, wood rings, streaks).
  - Plants: `foliage` leaf cards and tufts, eight generated leaf looks, ribbons, translucent materials, wind sway (`Wind`, matching on Metal and Vulkan), and detail levels down to an impostor (`MeshLOD`). New `forest` demo scene.
  - `meshBuild.preview` renders a tiled PNG of a build in a studio light. Every result reports bounds, triangle counts and spatial warnings (floating, buried, hidden or out-of-scale parts). `meshBuild.examples` returns sample builds.
  - Meshes can carry an optional per-vertex paint stream (`MeshGeometry.paint`).
- Builder gap-fill: the "not done" lists of fifteen builders (see `Tools.md`), among them:
  - Pixel Sprite: selections and copy/paste, PNG sheet import (`sprite.importSheet`), tag frame events, blend modes, canvas shortcuts; the Scene and Game views draw `Sprite` components.
  - Tilemap: `.sprite` tile sets, `TilemapMotion` (animated tiles and parallax in placed maps), one-way platforms that follow rotation, canvas shortcuts.
  - GridMap: a piece import cache, multi-cell auto-join pieces, `.prefab` variants and built-in meshes as pieces, mirrored animations, shortcuts.
  - Path: `PathFollower`, click to add points, `path.flattenTerrain`, T and X junctions, miter correction.
  - Behavior Tree: a node-graph canvas, grid navigation (`NavigationArea`, `world.findPath`, `behavior.navigation`) used by moveTo, patrol, chase and flee.
  - UI / HUD: a runtime game UI layer (`UILayoutPlayer`, `world.gameUI`), screen scaling, sliders, toggles and text fields, transitions, gamepad navigation order, color pickers.
  - Dialogue: `.ui` layouts as the dialogue box (`DialogueView`, `DialogueLayoutPresenter`), portraits; conversations show in GameRunner and exported games with no game code.
  - Timeline: a dialogue track, a preview that plays clips, sounds and conversations, `holdFade`.
  - Animation Graph: retargeting (`AnimationClip.retargeted`, `animGraph.bones`), 2D blend spaces, layer masks and override layers, sub-state machines, glTF clip events, parallel animators.
  - Character: edit-mode animation (View › Animate in Scene View), retargeted glTF clips, per-part colors, clips in GameRunner.
  - Material: masked graphs in shadows and the depth prepass, graph decals, planar reflections on graphs, dragging links.
  - Visual Script: nodes for animation graphs, dialogue, timelines, behavior trees and UI layouts; a `Tag` component; step over / into / out (`vscript.step`); reroutes, groups and macros.
  - Terrain: runtime LOD switching (`MeshLOD`), per-pixel GPU splat blending with normal maps, graph materials as layers.
  - VFX: particle textures and flipbooks, sub-emitter links (with a new birth trigger).
  - Post-FX: depth of field, LUT grading (`.cube` and strip PNGs), a Scene view split preview (`view.scenePostFX`).

### Changed

- 2D physics simulates colliders at their world pose, so colliders under a parent follow it.
- The cooker ships files that timelines, visual scripts and UI layouts name by path, and keeps the sources of sprites, tilemaps, paths and terrains (`AssetCooker.keepsSource`).
- `Animator` and its blend-space and layer-mask code moved to EngineAssets; `AssetClipLoader` and `addAssetAnimationSystem` are removed (use `addSceneAnimationSystem`).

### Fixed

- The editor finishes background asset loads every frame, so a load started while a builder tab covers the Scene and Game views no longer stalls (and no longer holds MCP replies).
- Visual Script calls of pure functions computed nothing.
- Nil asset handles (such as `Decal.texture`) can be set through the inspector and `setField`.
- Build Game for Windows copies `Engine.dll`, the Swift runtime and `zlib1.dll` next to the game's `.exe`, so an exported game starts on a PC without Swift. Windows CI exports and runs SampleGame.

## [0.14.1] - 2026-11-15

### Added

- The Script Editor checks scripts as you type: shortly after you stop typing, the game target is type-checked with the unsaved text (the cached `swiftc` plan replayed with `-typecheck`; nothing is built, saved or reloaded), and errors and warnings are marked in the gutter, underlined, and shown at the end of their lines. `GameModuleBuilder.typecheck(overrides:)`, `ScriptChecker`, and `GameBuildDiagnostic.severity` are new.
- Release workflow: pushing a `vX.Y.Z` tag builds the editor for macOS (`Editor.app`), Linux, and Windows (`Editor.exe`) (`Scripts/package-release.sh`, `Scripts/package-release.ps1`) and publishes them as a GitHub Release.
- Windows installer: releases include `Acro-<version>-windows-x64.msi`, which installs the editor into Program Files with Start Menu and desktop shortcuts (`Scripts\package-release.ps1 -Msi`, `Windows/Installer/Acro.wxs`, WiX v5).
- `PORTABLE=1 Scripts/make-editor-app.sh` builds an `Editor.app` without this checkout's paths, for distribution.
- `CONTRIBUTING.md`, `SECURITY.md`, issue forms, and a pull request template.
- Engine API reference built with DocC (`Scripts/build-docs.sh`, `Sources/Engine/Engine.docc`) and published to GitHub Pages by the Docs workflow.
- Windows: the editor and `GameRunner` load game modules, so Play runs game code there. A module links against the host's import library (`Editor.lib`, shipped next to `Editor.exe`) and is loaded with `LoadLibraryW`. Reloads use `swift build` and a link; the fast direct-`swiftc` rebuild is macOS and Linux only for now.
- `GameRunner --check` loads a game module, checks it shares the runner's Engine, and exits. Windows CI runs it on SampleGame.

### Changed

- Engine is split into twelve modules (EngineCore, EngineScene, EngineGraphics, EngineBackends, EngineText, EnginePhysics, EngineAudio, EngineAssets, EngineNet, EngineUI, EngineRendering, and `Engine`, which re-exports the rest), so release builds compile them in parallel: a release build of the editor takes about 96 s instead of 118 s, and after an edit in asset code 20 s instead of 68 s. `import Engine` and the `Engine` product are unchanged. The engine's resource bundle is now `Acro_EngineCore`, and `EngineVersion.swift` is in `Sources/EngineCore/Core/`. `SceneRenderer` takes a `SceneRenderHost` (`Engine` conforms) where it took an `Engine`.
- Windows: `Engine`'s library product is `.dynamic`, so Engine is compiled with its symbols exported and `swift build` also writes an `Engine.dll`.
- CI no longer renders the demo scenes; check rendering locally with `Scripts/render-scenes.sh`.
- Moved the cross-platform notes to `docs/cross-plat.md`.

### Fixed

- Windows: `Editor.exe` and `GameRunner.exe` started by double-clicking show startup errors in a message box, and on a crash a message box keeps the console window, with the error, open (`StartupErrors`). From a terminal they print as before.
- Windows release: the zip now includes the engine's resource bundle (`Acro_EngineCore.bundle`: shaders and fonts). Without it, `Editor.exe` exited as soon as it started. The packaging script only looked for Linux's `.resources` folder name.
- Windows: crash recovery files are written with the Windows `write` signature.
- Windows CI: the build links against vcpkg's zlib 1.3.2 and later, which names its import library `z.lib`.

## [0.8.4] - 2026-11-10

### Fixed

- Windows: the build no longer uses `getuid()` and `getgid()` in the Docker game exporter.
- A texture reimport test waits for loading instead of assuming a fixed number of frames.

## [0.8.3] - 2026-11-10

### Fixed

- Windows: the MCP stdio transport reads with `FileHandle.availableData`, because `fileDescriptor` is unavailable there.
- macOS CI runs on Xcode 27, the toolchain the engine is developed with.

## [0.8.2] - 2026-11-10

### Fixed

- The builder tabs compile with older Swift compilers: toolbar buttons no longer shadow the methods they call.
- Windows CI installs Swift 6.4.2.
- `docs/MCPTools.md` no longer embeds the engine version, so version bumps don't make it stale.

### Changed

- README reorganized, with builder documentation moved to `docs/Builders.md` and a continuous integration section.

## [0.8.1] - 2026-11-10

### Added

- README banner, social preview image, and the script that generates them.
- Mozilla Public License 2.0.

## [0.8.0] - 2026-11-10

### Changed

- The project is renamed Acro; remaining `swift-game-engine` identifiers now use the new name.

## [0.7.1] - 2026-11-04

### Fixed

- The editor icon test checks only built-in components.

## [0.7.0] - 2026-11-04

### Added

- Terrain Builder (`.terrain`): sculpted, painted heightmap terrain with scattered props, `terrain.*` MCP tools, and an editor tab.

## [0.6.0] - 2026-11-04

### Added

- Data Table Builder (`.table`): typed spreadsheets for game data, with validation, CSV import and export, typed runtime access, `table.*` MCP tools, and an editor tab.

## [0.5.0] - 2026-11-04

### Added

- Post-FX Builder (`.postfx`): saved camera looks with grading, vignette, chromatic aberration, and film grain; per-camera assignment and `PostFXVolume` blending; `postfx.*` MCP tools and an editor tab.

### Fixed

- `Scripts/version.sh` finds the repository root from its own path, so the pre-commit hook works in linked worktrees.

## [0.4.0] - 2026-11-04

### Added

- Sound Builder (`.sfx`): synthesized sound effects with presets, `sfx.*` MCP tools, and an editor tab.

## [0.3.0] - 2026-11-04

### Added

- VFX Builder (`.vfx`): effects made of stacked GPU particle emitters, with presets, `vfx.*` MCP tools, and an editor tab.

## [0.2.1] - 2026-11-04

### Fixed

- GitHub Actions builds across platforms.

## [0.2.0] - 2026-11-04

### Added

- Mesh Builder (`.meshbuild`): models built from primitive shapes, with materials, animation, `meshBuild.*` MCP tools, and an editor tab.
- `Tools.md` builder roadmap.

## [0.1.0] - 2026-11-04

First versioned release. Includes the Metal and Vulkan renderers, entity-component system, editor, MCP server, game modules with hot reload, asset pipeline, physics, audio, networking, packaging, decals, and planar reflections.

[Unreleased]: https://github.com/thenatespack/Acro/compare/v0.18.1...HEAD
[0.18.1]: https://github.com/thenatespack/Acro/compare/v0.17.1...v0.18.1
[0.17.1]: https://github.com/thenatespack/Acro/compare/v0.14.1...v0.17.1
[0.14.1]: https://github.com/thenatespack/Acro/compare/78f2983...v0.14.1
[0.8.4]: https://github.com/thenatespack/Acro/commit/78f2983
[0.8.3]: https://github.com/thenatespack/Acro/commit/e52e5d5
[0.8.2]: https://github.com/thenatespack/Acro/commit/aef9fc1
[0.8.1]: https://github.com/thenatespack/Acro/commit/b384435
[0.8.0]: https://github.com/thenatespack/Acro/commit/7a3a76a
[0.7.1]: https://github.com/thenatespack/Acro/commit/9458c71
[0.7.0]: https://github.com/thenatespack/Acro/commit/88e1878
[0.6.0]: https://github.com/thenatespack/Acro/commit/a800e39
[0.5.0]: https://github.com/thenatespack/Acro/commit/6eb4a2e
[0.4.0]: https://github.com/thenatespack/Acro/commit/8f1ef75
[0.3.0]: https://github.com/thenatespack/Acro/commit/913f10d
[0.2.1]: https://github.com/thenatespack/Acro/commit/ad3b9dc
[0.2.0]: https://github.com/thenatespack/Acro/commit/94f00f4
[0.1.0]: https://github.com/thenatespack/Acro/commit/c016ddb
