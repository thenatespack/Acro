# SwiftGameEngine

A small cross-platform game engine in Swift: **Metal on macOS, Vulkan everywhere else**.

```
Sources/
  Engine/
    Core/            Engine loop, Game protocol, math (Mat4/Vec*), Input, TextInput, FrameStats, Image/PNGEncoder (compressed PNG writer)
    Debug/           Performance overlay + built-in 5x7 bitmap font
    Assets/          Model import: ImportedModel (CPU-side meshes, materials, textures, nodes), GLTFReader (glTF 2.0 / GLB)
    Scene/           World (entities, sparse-set components, queries), Transform hierarchy, staged systems
    Assets/          Projects, sidecar asset ids, AssetDatabase, importers (OBJ, .material), Library cache, FileWatcher
    Rendering/       SceneRenderer: draws ECS entities (Camera, DirectionalLight, MeshRenderer components)
    UI/              2D UI draw list (UIDrawList) and its renderer; Widgets/ (retained widget tree)
    Text/            Font (stb_truetype + GPOS kerning), GlyphAtlas (SDF pages), TextLayout, TextRenderer
    Fonts/           Bundled Inter Regular (SIL OFL, license alongside)
    Shaders/         Engine-owned shaders (blit, upscalers, overlay, ui, text)
    Graphics/        Backend-agnostic API: RenderDevice, RenderPass, GPUBuffer, PipelineDescriptor, ShaderSource
    Platform/        Windows: AppKitWindow (CAMetalLayer) and GLFWWindow (Vulkan surface)
    Backends/Metal/  MetalRenderDevice
    Backends/Vulkan/ VulkanRenderDevice (+ helpers)
  CVulkan, CGLFW, CZlib/  System-library module maps (Windows variants under Windows/)
  CStbTrueType/      Vendored stb_truetype (public domain)
  CStbImage/         Vendored stb_image v2.30 (public domain; PNG/JPEG/TGA/HDR, decode from memory only)
  Demo/              Test scenes (Renderer + Scenes/) and their shaders
Scripts/compile-shaders.sh   GLSL -> SPIR-V -> MSL (+ spirv-to-msl.c, the SPIRV-Cross driver)
Scripts/render-scenes.sh     Render every demo scene on every backend and compare
```

## How it fits together

- Games implement `Game` (`setup` / `update` / `render`) and call `Engine(config:).run(game)`.
- Rendering goes through `RenderDevice` / `RenderPass`. Each backend implements them; game code never touches Metal or Vulkan directly.
- The backend is picked by `EngineConfig.backend`, then the `ENGINE_BACKEND` env var, then the platform default (Metal on macOS, Vulkan otherwise).
- Metal pairs with a native AppKit window; Vulkan pairs with GLFW.
- Resources (`GPUBuffer`, `GPUTexture`, `RenderPipeline`) are freed when you drop the last reference. Metal relies on ARC plus command buffers retaining what they use. On Vulkan, `deinit` hands the handles to a deletion queue, and they are destroyed once the fence of the last frame that could use them has signaled. Anything still alive at shutdown is destroyed with the device.
- Static buffers and textures are uploaded once at creation. On Vulkan they live in device-local memory and are filled through a staging buffer; creation blocks until the copy has finished, so create them up front rather than every frame.
- Static buffers can be edited later with `frame.updateBuffer(buffer, offset:, elements:)` (or `device.updateBuffer`) between passes, e.g. in `renderOffscreen`. The bytes are copied into the frame's transient memory and a GPU copy is recorded into the current frame, ordered after the reads of earlier frames still in flight (a barrier on Vulkan, a blit encoder on Metal). Passes begun after the call and all later frames see the new data; earlier passes of the same frame still see the old data. Calling it inside a pass traps, and a range outside the buffer throws. It is meant for occasional edits, not bulk streaming.
- Per-frame data (UI, debug geometry, particles) goes through `pass.setVertexData(_:)`, which copies into a per-frame ring buffer. No buffer management needed. Data that several passes draw (e.g. instances for both the shadow and the screen pass) can be copied once with `frame.upload(_:)` in `renderOffscreen`, then bound in each pass with `pass.setVertexBuffer(_:index:)`.
- Metal acquires the window's drawable only when the first pass that draws into the window begins. It commits everything recorded before that point first, so the GPU renders shadow maps (and an offscreen scene) while the CPU waits for the window server to hand over a drawable.
- Both backends use the same conventions so one set of math works everywhere: right-handed, column-major matrices, clip depth in [0, 1], y-up clip space (Vulkan vertex shaders end with `gl_Position.y = -gl_Position.y;` and the viewport is not flipped: a flipped viewport makes MoltenVK feed Metal mirrored geometry, which breaks bit-exactness with native Metal), counter-clockwise front faces, sRGB BGRA8 swapchains.

### Shaders

Shaders are written once, in GLSL (`name.vert` / `name.frag`). `Scripts/compile-shaders.sh` (needs `glslc` and SPIRV-Cross: `brew install shaderc spirv-cross`) regenerates everything from them:

1. `glslc` compiles each stage to SPIR-V (`name.vert.spv`), which the Vulkan backend loads.
2. `Scripts/spirv-to-msl.c`, a small driver for the SPIRV-Cross C API that the script builds into `.build/`, cross-compiles each SPIR-V stage to MSL (`name.vert.metal`, `name.frag.metal`), which the Metal backend compiles at runtime. Generated files start with a "do not edit" header and a hash of their SPIR-V. A test (`generatedMetalMatchesSPIRV`) fails if the `.metal` is stale. A fragment shader with outputs beyond `[[color(0)]]` (motion vectors) also gets `name.frag.color0.metal` with the others dropped, which the Metal backend uses for pipelines whose pass has no attachment for them. MoltenVK drops unconsumed outputs the same way, and it matters for bit-exactness: with an unconsumed output, Apple's compiler emits a different color-0 epilogue, and blending without MSAA then rounds differently.

All outputs are committed, so building the package needs neither tool. Rerun the script after editing any GLSL. Shared code goes in `.glsl` files pulled in with `#include` (`GL_GOOGLE_include_directive`; e.g. `mesh.frag` and `mesh_mask.frag` both include `mesh_surface.glsl` and differ by a `#define`). The script doesn't compile `.glsl` files on their own, and the staleness test only hashes the including file, so rerun the script after editing an include. MoltenVK runs our SPIR-V on Metal by converting it with the same SPIRV-Cross, so native Metal runs essentially the MSL that Vulkan-on-MoltenVK runs. This keeps the backends byte-identical. The driver differs from a plain `spirv-cross --msl` in three ways:
- It renames the entry points to `vertex_main` / `fragment_main`. The stages stay in separate files (SPIRV-Cross names its per-stage types and helpers independently, so they can't simply be concatenated). `ShaderSource.metalFragmentSource` carries the fragment file.
- It remaps resources to the Metal column of the table below. The `spirv-cross` CLI can't remap descriptor sets or push constants, hence the driver. A resource outside the table is an error.
- It undoes the Vulkan y flip with SPIRV-Cross's `flip_vert_y`, which negates `gl_Position.y` again at the end of the vertex shader (MoltenVK does the same).

Binding conventions (see `ShaderSource`). The GLSL column is what you write. Hand-written MSL (one `name.metal` with both entry points, loaded in preference to generated files) must follow the Metal column:

| | Metal | Vulkan GLSL |
|---|---|---|
| Entry points | `vertex_main`, `fragment_main` | `main` |
| Vertex attribute *n* | `[[attribute(n)]]` | `layout(location = n) in` |
| Push constants (≤128 B) | `constant T& [[buffer(16)]]` | `layout(push_constant) uniform` |
| Per-frame uniform block | `constant T& [[buffer(15)]]` | `layout(set = 0, binding = 0, std140) uniform` |
| Shadow map / image 0 | `[[texture(0)]]`, `[[sampler(0)]]` | `layout(set = 1, binding = 0) uniform sampler2DShadow` (or `sampler2D`) |
| Uniform buffer *n* (2–7) | `constant T& [[buffer(n)]]` | `layout(set = 2, binding = n, std140) uniform` |
| Texture *n* (1–7) | `texture2d<float> [[texture(n)]]` | `layout(set = 2, binding = 8 + n) uniform texture2D` |
| Sampler *n* (1–7) | `sampler [[sampler(n)]]` | `layout(set = 2, binding = 16 + n) uniform sampler` |
| Motion vectors | `[[color(1)]]` | `layout(location = 1) out` |

Buffer indices 0 and 1 are vertex buffers. On Vulkan, textures and samplers are separate descriptors: sample with `texture(sampler2D(tex, samp), uv)`. GLSL vertex shaders must end with `gl_Position.y = -gl_Position.y;` (see above).

### Textures, samplers and uniform buffers

- **Decoding** (`ImageDecoder`, CPU only, any thread, no shared state): `decode(_ data:)` / `decode(contentsOf:)` give an 8-bit RGBA `Image` from PNG, JPEG or TGA (gray, gray+alpha and RGB expand to RGBA; 16-bit PNG reduces to 8). `decodeFloat` gives a linear `FloatImage` (RGBA32F), what Radiance HDR files hold. `decodeAny` picks by content (`DecodedImage.rgba8` / `.rgba32F`), `size(of:)` reads just the header. Failures throw `ImageDecodeError` with stb_image's reason.
- **Upload** (main thread; blocks on Vulkan): `device.makeTexture(image: Image, srgb:, generateMipmaps: true)` (true for color maps, false for normal / roughness / data), `makeTexture(image: FloatImage, generateMipmaps:)` (an `.rgba16Float` texture, mips filtered in float) or `makeTexture(decoded:srgb:)`. Decode on a background thread, upload on the main thread.
- `device.updateTexture(texture, region: TextureRegion(x:y:width:height:), mipLevel:, pixels:)` overwrites a sub-rectangle of one mip level (synchronous, allowed inside a pass; on Vulkan it uses its own command buffer with the layout transitions and waits for the queue, on Metal it blits from a staging buffer on its own command buffer; both are ordered after frames already in flight). Other mips are not regenerated. The glyph atlas uses it to upload only the bounding box of new glyphs per page.
- `device.makeTexture(pixels:width:height:format:generateMipmaps:)` creates a 2D `.rgba8Unorm`, `.rgba8Srgb` or `.rgba16Float` (half-float bytes, no CPU mips) texture; `makeTexture(levels:format:)` takes explicit `TextureMipLevel`s. Mipmaps are generated on the CPU (box filter, in linear light for sRGB), so both backends sample identical data.
- `device.makeSampler(SamplerDescriptor(filter:mipFilter:addressMode:))` returns a cached sampler (nearest/linear, mip none/nearest/linear, repeat/clamp/mirror).
- In a pass: `setTexture(_:index:)`, `setSampler(_:index:)`, `setUniformBuffer(_:index:)` for a static buffer created with `.uniform` usage, or `setUniformData(_:index:)` to copy per-draw data (≤16 KiB) into the frame's ring buffer. Pass `stage:` to bind to the vertex and/or fragment stage.
- On Vulkan, bindings are collected per pass and written into a descriptor set (set 2) allocated from the frame slot's pool on the first draw after a change. The pool is reset when that slot's fence signals.

### Scene / ECS

`World` (in `Sources/Engine/Scene/`) holds entities and their components. It's opt-in: set `engine.world = world` and the engine calls `world.update(dt:)` right after `Game.update` every frame. Games that don't use it are unaffected.

- **Entities** are `Entity` handles (slot index + generation). `despawn` bumps the generation, so stale handles read as nil and mutations through them are ignored, even after the slot is reused.
- **Components** are structs conforming to `Component`. Use `add(_:to:)` (inserts or replaces), `remove(_:from:)`, `get(_:for:)`, `modify(_:for:)`. Each type is stored in its own sparse set, so add/remove are O(1) and iteration walks dense arrays.
- **Queries**: `world.query(A.self, B.self) { entity, a, b in }` (read-only) and `world.queryMutating(A.self, B.self) { entity, a, b in }` (`inout`, written back after the body). They take 1–4 component types and walk the smallest store. Despawning, removing a component and adding a new component type during a query are deferred until the outermost query returns. In release builds a two-component query over 100k entities takes about 0.2 ms.
- **Components are `Codable`.** Synthesized conformance works when every stored property is Codable (numbers, strings, `Vec2/3/4`, `Quat`, `Entity`, enums, arrays, optionals, nested structs). Give saved components a stable `static let componentName = "Health"`, because the default (the type name) changes on rename. `ComponentRegistry` maps names to types. It is global, filled automatically when a world first stores a type; call `ComponentRegistry.register(...)` at startup for the rest. Derived data opts out with `static var isSerialized: Bool { false }`, as `GlobalTransform` does.
- **Scene files**: `let data = try world.save()` (or `save([root])` for subtrees) and `let roots = try world.load(data, under: optionalParent)`. The format is human-readable JSON: sorted keys, one-line vectors, a `format`/`version` header, entities depth first with `parent` links, and components keyed by name. Saving is byte-stable, and loading then saving reproduces the file. Loading is additive and atomic. Entity references inside components are stored as file-local `{"$entity": id}` and remapped to the new entities; references to unsaved entities load as nil or `Entity.invalid`. Components with unknown names are kept as `UnresolvedComponents`, written back unchanged, and can be resolved later with `resolveUnresolvedComponents()`. Systems, timing and settings are code or configuration and are not saved. Save/load of 10k entities (3.5 MB) take roughly 0.13–0.19 s / 0.09–0.13 s in release.
- **Snapshots** (play-in-editor): `let s = world.snapshot()` … `world.restore(s)` is an in-memory copy (well under a millisecond for 10k entities). Handles from snapshot time are valid again, and handles to entities spawned afterwards stay stale.
- **Reflection** (for the inspector): `component.fields()` / `world.fields(of: "Transform", for: e)` return `FieldDescriptor`s (name, dotted path, kind, current value, optional flag, hints, children) built from the component's Codable encoding, so no per-component code is needed. Set fields with `try world.setField("position", of: "Transform", for: e, to: .vec3(v))`. Hints such as ranges, steps, color pickers and read-only flags come from `static var fieldHints`. `Quat(eulerDegrees:)` / `.eulerDegrees` are for display. Release cost: about 1 µs per field to read and about 0.3 ms per set.
- **Hierarchy**: `setParent(child, to: parent, keepWorldTransform:)`. By default the child keeps its local `Transform` and moves with the new parent. `keepWorldTransform: true` rewrites it so the child stays put. Despawning an entity despawns its children; reparent them first to keep them. `GlobalTransform.matrix` (added automatically) is computed parent-first each frame, and only dirty subtrees are recomputed.
- **Systems**: `world.addSystem("name", stage: .fixedUpdate) { world in … }`. Stages run in order: `.fixedUpdate` (zero or more times per frame at `fixedTimestep`, capped by `maxFixedStepsPerFrame`, excess dropped), `.update`, `.lateUpdate`, transform propagation, `.renderPrep` (interpolate with `world.time.alpha`). Within a stage, systems run in registration order (or `before:` / `after:`). `world.time.delta` is the fixed step in `.fixedUpdate` and the frame's dt elsewhere. In screenshot mode dt is a fixed 1/60 s, so fixed steps are deterministic.
- `Quat` (Math.swift) is the rotation type: axis-angle, composition, vector rotation, `matrix`, `init(rotationMatrix:)`, `slerp`.

### Entity IDs and names
An `Entity` handle is only valid in the running world. `world.id(of:)` returns an `EntityID`, a stable 128-bit random id that survives save/load, snapshot/restore and despawn-then-undo. `world.entity(for:)` finds the entity in O(1).
- **Enabling:** ids are opt-in. Set `world.assignsEntityIDs = true` (the editor does) so every spawn gets one, or call `ensureID(of:)` for single entities.
- **Where they live:** a side table in the world, not a component, so they can't be edited or removed. Scene files store them as `"uid"` (format version 2; version 1 files load fine and get ids if the flag is on).
- **Loading:** it keeps uids that are free, and gives a copy new ids when they are taken (loading the same file twice, prefab instances). `load(_:ids: .regenerate)` forces new ids, for duplicating.
- **Order and names:** roots have an explicit order (`world.roots`, `setParent(_:to:at:)`, `siblingIndex(of:)`) that scene files and undo preserve. `Name` is an optional display-name component.

### Undo / redo
`UndoStack(world:)` runs `UndoCommand`s and keeps undo and redo history. Built-in commands: `SetFieldCommand`, `SetComponentCommand`, `AddComponentCommand`, `RemoveComponentCommand`, `RenameCommand`, `SpawnCommand`, `DespawnCommand`, `ReparentCommand`, `ClosureCommand`.
- **Entities by id:** commands store `EntityID`s, so they still work after play mode restores a snapshot or undo recreates an entity.
- **Edits through the stack:** `try undo.perform(cmd)`. A command that throws isn't recorded.
- **Groups:** `undo.group("Move") { … }` makes a drag one step, and consecutive edits of the same field inside it merge into one.
- **Menus and save state:** `undoTitle` and `redoTitle` give menu text, `isDirty` and `markSaved()` track unsaved changes, and `onChange` fires when the stack changes.
- **Play mode and load:** set `isRecording = false` while playing, and call `clear()` after loading.
- **Limit:** undoing a despawn restores references among the entities inside the subtree; references from outside to it stay stale. Despawn/undo of a 1000-entity subtree costs ~25 ms each way.

### Rendering entities
`SceneRenderer` (`Sources/Engine/Rendering/`) draws a `World`: a forward renderer with one shadow-casting directional light, hemisphere ambient, exponential fog, instancing, frustum and shadow-caster culling, a back-to-front sorted transparent pass, and motion vectors plus jitter for the temporal upscalers. It is opt-in, and games that don't use it are unaffected:

```swift
sceneRenderer = try SceneRenderer(engine: engine)                                 // in setup
sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)         // in renderOffscreen
sceneRenderer.draw(pass)                                                          // in render
```

`renderOffscreen` gathers every entity with a `GlobalTransform` and a `MeshRenderer`, culls and batches them, sets `engine.clearColor` / `clearDepth` from the camera, uploads all instances once and renders the shadow map. Call it after the world's transforms are current for the frame (after `world.update`).

- **Components** (all `Codable`):
  - `Camera` (fovY, near/far, `reversedZ`, clear color, `isActive`): it looks down its entity's -Z. The active camera with the lowest entity index is used, unless `sceneRenderer.camera` is set.
  - `DirectionalLight` (color, intensity, shadows): it shines along its entity's -Z, or along an explicit `direction`. `shadowExtent` is the half-size of the shadowed square, and `shadowCenter` nil makes that square follow the camera, snapped to texels. The shadow map uses `engine.quality.shadowMapSize` and `shadowFilterRadius`.
  - `SceneEnvironment`: ambient sky/ground colors and fog.
  - `MeshRenderer`: mesh, material, tint, opacity, casts/receives shadows, visible.
- **Assets:** meshes (`MeshGeometry`: `.cube()`, `.plane()`, `.sphere()`, or your own vertices and indices) and `Material`s (see **Materials** below) are GPU resources. Register them with `registerMesh(_:key:)` / `registerMaterial(_:key:)`, and reference them from components with `MeshHandle("key")` / `MaterialHandle("key")`, which serialize as the key. `MeshHandle.cube`, `.plane`, `.sphere` and `MaterialHandle.default` (Blinn-Phong) are built in.
- **Materials** (`Material`, glTF metallic-roughness conventions). `shading` picks the lighting model:
  - `.pbr` (the default): Cook-Torrance specular with a GGX distribution, height-correlated Smith visibility and Schlick Fresnel, plus Lambert diffuse weighted by 1 − F. Lights use the same units as before: the BRDF is scaled by π, so a white Lambert surface facing the sun reflects exactly the light's color × intensity. Ambient light is the hemisphere (`SceneEnvironment` sky/ground): diffuse gets it as irradiance; specular gets the hemisphere seen along the reflection vector (blurred toward the irradiance as roughness grows) times Karis' analytic split-sum DFG fit. Without that, metals would be black away from the sun. There is no cubemap IBL. Roughness is perceptual (α = roughness²), clamped to at least 0.045.
  - `.blinnPhong`: the original model (`specular`, `shininess`), kept bit for bit. The built-in default material uses it, and so do `.material` files written before PBR existed, so existing scenes look exactly as before.
  - Parameters: `baseColor` × `texture` (sRGB) × the `MeshRenderer` tint; `metallic` / `roughness` × `metallicRoughnessTexture` (linear; B metallic, G roughness); `normalTexture` (linear tangent space, +Y up) × `normalScale`; `occlusionTexture` (R, ambient only) with `occlusionStrength`; `emissiveColor` × `emissiveTexture` (sRGB) × `emissiveStrength`, added after lighting; `emissive` (0–1, unlit: shows the albedo, glTF `KHR_materials_unlit`); `checker`; `doubleSided` (PBR lights back faces with the flipped normal). Every texture uses one `sampler` and one UV transform: `uvOffset + rotate(uvRotation) · (uvScale · uv)`, as in `KHR_texture_transform`. Missing textures count as white; without a normal map the mesh normal is used. Everything except metallic and roughness also works with `.blinnPhong`.
  - `alphaMode`: `.opaque`; `.blend` (the transparent pass; `isTransparent` is the same flag); `.mask` discards fragments whose base color alpha (factor × texture) is below `alphaCutoff`, in the screen pass and in the shadow map, and draws the rest opaque. Masked materials use their own shader variants (`mesh_mask.frag`, `mesh_shadow_mask`), so the discard doesn't cost early depth testing elsewhere. Their shadow casters are batched per mesh and material; all other casters still share one depth-only batch per mesh.
  - **Tangents** live in the vertex: `MeshVertex.tangent` (xyz along increasing U, w = ±1; the bitangent `cross(n, t) · w` points up in the texture), attribute 13, making the vertex 64 bytes. glTF `TANGENT`s are used when the file has normals. Otherwise `registerMesh` generates them unless every vertex has one (`MeshGeometry.generateTangents()` / `withTangents()`): each triangle corner contributes its UV gradient direction, projected onto the vertex's normal plane and weighted by the corner angle, then orthonormalized. That is close to MikkTSpace on ordinary meshes, but it never splits vertices, so a vertex shared by triangles with mirrored UVs gets one averaged frame. The vertex shader transforms tangents with the model matrix and flips the handedness for mirroring transforms. The fragment shader re-orthogonalizes against the interpolated normal.
- **Batching:** opaque entities sharing a mesh and material are drawn in one instanced draw. Transparent ones (opacity < 1 or a transparent material) are drawn after the opaque pass, sorted back to front, blended, without depth writes. `tint` varies color without splitting batches.
- **Motion vectors:** the renderer remembers each entity's previous world matrix (keyed by entity, checked against its generation), so moving and animated entities don't ghost under TAAU / MetalFX temporal. Call `sceneRenderer.resetMotion()` together with `engine.resetTemporalHistory()` on camera cuts.
- **Limits:** one directional light, no point/spot lights or cascades. No image-based lighting, no tone mapping (colors above 1 clip), no `TEXCOORD_1`, one sampler and UV transform per material. The selection outline ignores alpha masks.
- **Cost:** gathering, culling and batching 10k entities takes about 0.8 ms of CPU time in release on an M5. `sceneRenderer.stats` reports counts and prepare time.

### Model import (glTF 2.0)
`GLTFReader.read(contentsOf: url)` (or `read(data:baseURL:options:loadResource:)`) reads `.gltf` (external files and `data:` URIs) and `.glb` into an `ImportedModel`. It is CPU-only and touches no shared state, so it can run on a background thread.
- **Reads:** buffer views with strides; accessors of every component type, normalized or not, and sparse ones; triangle lists, strips and fans (points and lines are skipped with a warning); `POSITION`, `NORMAL`, `TEXCOORD_0/1`, `TANGENT`, `COLOR_0`; 8/16/32-bit indices or none; nodes with TRS or a matrix (decomposed); multiple scenes (`scene`, else the first; `Options.scene` overrides).
- **Output:** `meshes[m].primitives[p]` hold a `MeshGeometry` plus the attributes `MeshVertex` has no slot for (tangents, `TEXCOORD_1`, colors) and a material index. `materials` keep the whole metallic-roughness material (all five textures with texCoord and `KHR_texture_transform`, factors, normal scale, occlusion strength, emissive and `KHR_materials_emissive_strength`, alpha mode and cutoff, double-sided, `KHR_materials_unlit`). `textures` have an image index, an `ImportedSampler` (separate U/V wrap) and the slots that use them; `colorSpace` is `.sRGB` for base color and emissive, `.linear` for normal, metallic-roughness and occlusion. Also `nodes` (parent/children), `scenes`, `roots`, `warnings`.
- **Images are not decoded:** `images[i]` is the encoded bytes and MIME type. `model.makeTextures(device:decoder:)` decodes with a caller-supplied `(Data, String?) throws -> Image` (e.g. `{ data, _ in try ImageDecoder.decode(data) }`) and uploads with the right format and mipmaps; `decodeImages(using:)` only decodes.
- **Into a world:** `model.register(with: sceneRenderer, keyPrefix:, textures:)` uploads meshes and materials and returns `ModelHandles`; `model.instantiate(in: world, under: parent, handles:)` (or with `mesh:`/`material:` closures for handles from elsewhere) spawns an entity per node with `Transform`, `Name` and the file's hierarchy. A node whose mesh has one primitive gets the `MeshRenderer` itself; a mesh with several primitives gets one child entity per primitive ("<mesh> [i]"), since a `MeshRenderer` draws one mesh with one material.
- **Conventions:** glTF matches the engine (right-handed, +Y up, CCW front faces, UV origin top-left), so data passes through unchanged. Missing normals are generated flat (the spec's rule; `Options(normals: .smooth)` averages instead). Nodes that mirror (negative determinant) get a copy of their mesh with reversed winding.
- **Mapping to `Material`** (`engineMaterial(textures:sampler:)`, or `materialAsset(textures:sampler:)` for the asset database): a `.pbr` material with every factor and all five textures (base color and emissive sRGB, the others linear), emissive strength, normal scale, occlusion strength, alpha mode and cutoff (`OPAQUE` forces alpha 1), double-sided, unlit as `emissive` 1. The sampler and `KHR_texture_transform` (offset, rotation, scale) of the `primaryTexture` (base color, else the first texture) apply to all textures. Not mapped: per-texture samplers or transforms that differ, `TEXCOORD_1` (every texture samples `TEXCOORD_0`), separate U/V wrap modes.
- **Errors:** malformed containers, JSON, out-of-range indices and offsets, cycles and unsupported `extensionsRequired` throw `GLTFError`; unknown optional extensions, skins, animations and cameras are ignored with a warning.
- **Not supported yet:** skins, morph targets, animations, cameras, lights, Draco/meshopt compression, KTX2/WebP decoding, `TEXCOORD_2+`.
- **Test data:** Khronos sample models (CC BY 4.0 / CC0, attribution in `Tests/EngineTests/Resources/glTF/LICENSE.md`).

### Render targets and multiple views
`RenderTarget(device:width:height:multisampled:label:)` is an offscreen color + depth target that game code renders into and then samples. Its color uses the window's sRGB format, with the device's MSAA resolved into the texture, or 1x when `multisampled` is false. Depth only exists during the pass. Every `.screen` pipeline can draw into it. In `renderOffscreen`, call `frame.renderPass(into: target, clearColor:) { pass in … }`. Any later pass of the frame can then sample `target.texture`, e.g. `engine.ui.drawImage(target.texture, in: panel)` in the window pass. `target.resize(toPoints: panel.size, scale: engine.ui.scale)` recreates the target only when its size changes. On Vulkan the old one is freed through the deletion queue, and a texture already queued in a draw list stays valid. Target passes have no motion vectors and no occlusion queries, and they are timed under the target's `label`. On Vulkan they use the offscreen scene pass, whose subpass dependencies order them after the previous frame's reads and before later fragment-shader reads; on Metal, hazard tracking does the same.

`SceneRenderer` can draw one world from several cameras per frame:
```swift
sceneRenderer.beginViews(world: world, frame: frame)                 // gather + one shared shadow map
sceneRenderer.renderView(editorView, into: editorTarget, frame: frame, debugDraw: gizmos)
sceneRenderer.renderView(SceneView(camera: gameCamera, in: world, aspect: gameTarget.aspectRatio)!, into: gameTarget, frame: frame)
```
A `SceneView` is either a view matrix plus projection, or a camera entity's. The views share the gathered entities and one shadow map, which holds every caster in the light's frustum and is centred for `shadowFocus` (the game camera by default). When views look at different places, give the light a fixed `shadowCenter` and a larger `shadowExtent`. Views have no jitter or motion vectors. Use either this or `renderOffscreen` + `draw` in a given frame.

### Debug draw
`engine.debugDraw` (a `DebugDraw`) is an immediate-mode list of 3D debug shapes: `line`, `polyline`, `box` (an AABB, or an OBB from a matrix or center/extent/rotation), `circle`, `sphere`, `arrow`, `axes`, `frustum(viewProjection:)` (e.g. another camera's) and `text(_:at:)` labels. A ground `grid` (`DebugGrid`) is drawn by a shader: lines stay a fixed number of pixels wide with antialiasing, the X and Z axes are coloured, and it fades out with distance and where cells become smaller than a few pixels. Each shape takes a `DebugDraw.Style`: width in pixels (constant on screen) or in world units, and depth-tested or always on top. Shapes without a `duration` last one frame; the engine ages `engine.debugDraw` before `Game.update`. Lines are expanded in screen space and batched into one instanced draw per depth mode, plus one draw for the grid and one per glyph page for labels. Debug geometry writes no depth and no motion vectors, so TAAU treats it as part of the surface behind it. A `SceneRenderer` made with `init(engine:)` draws `engine.debugDraw` in the screen pass; `renderView(…, debugDraw:)` takes any list; `DebugDrawRenderer` draws a list into any pass.

### Editor tools: picking, selection outline, gizmos
`Sources/Engine/EditorTools/` has the viewport tools an editor builds on, driven by plain inputs: a `ViewportProjection` (view, projection, reversed-Z, size in points, pixel scale; `ViewportProjection(sceneView, size:pixelScale:)`), a `ViewportPointer` (position in viewport points, phase moved/pressed/dragged/released, modifiers), the `World` and the selected entities.
- **Picking:** `ScenePicker(meshes: sceneRenderer).pick(at: point, in: view, world:)` returns the closest entity, hit point, distance and normal. It tests world bounds, then the mesh's triangles exactly in local space (`SceneRenderer.geometry(_:)` keeps a CPU copy of each registered mesh). It skips invisible entities, those with `Unpickable`, and those rejected by `filter`. `entities(in: rect, ...)` does marquee selection. A pick among 10k entities takes about 0.4 ms in release. `ViewportProjection.ray(through:)` unprojects with either depth convention.
- **Selection outline:** `SelectionOutlineRenderer.renderView(view, sceneRenderer:, world:, selection:, primary:, into: target, pixelScale:, frame:)` replaces `SceneRenderer.renderView`. A mask pass flags the selected entities (and their children), the primary entity, and the parts in front of unselected geometry. A scissored composite then draws a constant-width outline (`style.width` points) in the primary or secondary color, dimmed to `hiddenOpacity` where the entity is hidden. It uses texel loads only, so Metal and Vulkan match byte for byte. Use one renderer per view. Cost ≈0.5 ms GPU on a large view at 4 px width (grows with width²).
- **Gizmos:** `TransformGizmo` (modes translate / rotate / scale, space world / local, pivot primary / selection center). Call `handle(pointer, view:, world:, selection:, primary:)` with every pointer event and `draw(into: debugDraw, ...)` every frame, drawing that list in the view's `overlay`. It handles hover highlight, hides axes seen end-on, keeps a constant screen size and snaps while `snapping.modifier` is held (Cmd on macOS, Ctrl elsewhere). Every selected entity gets the same world delta, converted to its parent's space. The returned `GizmoEdit` reports began / changed / ended / cancelled with old and new `Transform`s. `cancel(world:)` (Esc) restores them, and `edit.record(in: undoStack)` makes the drag one undo step.
- `DebugDraw` also draws filled triangles (`triangle`, `quad`, `disc`, `cone`, `solidBox`).

### Projects and assets
A project is a folder with `Project.json` (marker and settings), `Assets/` (your files, checked in) and `Library/` (import cache, rebuildable; the generated `.gitignore` ignores it). `Project.create(at:)` / `Project.open(at:)`; `AssetDatabase(project:)` then `refresh()` scans and imports (`Sources/Engine/Assets/`).
- **Sidecars:** every file in `Assets/` gets `<file>.meta` (JSON, sorted keys): its `AssetID` (32 hex digits), its importer and that importer's settings (missing keys take defaults). Keep the sidecar with its file and references survive renames and moves. A scan creates sidecars for new files, re-attaches a sidecar left behind by a file moved without it (same content), gives copies with a duplicated id a fresh id (the original keeps it), deletes orphaned sidecars (`orphanPolicy = .report` only lists them) and reports unreadable sidecars without touching them.
- **References:** `AssetReference(id, subAsset:)` names a file or one object imported from it, written `asset:<id>#<sub-asset>`. Sub-asset ids come from the importer, `<kind>/<name>` by convention (`mesh/Rock`; `mesh/2` when unnamed; `SubAssetNamer`), so they survive reimports and reordering. `MeshHandle(reference)` / `MaterialHandle(reference)` store that string, so scene files keep their format and old files load unchanged; set `sceneRenderer.assets = database` and such handles are imported, uploaded on first use and re-uploaded after a reimport. Built-in and code-registered keys work as before (`asset:` is a reserved prefix).
- **Importers:** implement `AssetImporter` (`name` stored in sidecars, `fileExtensions`, `version`, a Codable `Settings` with `defaultSettings`, `importAsset(_:settings:)` returning an `ImportedAsset` of meshes (`MeshGeometry`), materials (`MaterialAsset`, texture as a reference), textures (`TextureAsset`: RGBA8 `Image` or float `FloatImage` pixels, sRGB flag, mipmaps) and prefabs (`PrefabAsset` node trees; `world.instantiate(_:)`)). Register with `AssetImporterRegistry.standard.register(…)` before creating databases. Importers never touch the GPU; `AssetImportJob.run()` can run off the main thread. Built in:
  - `TextureImporter` (`.png`, `.jpg`, `.tga`, `.hdr`): one `texture` object; settings `sRGB` (false for normal maps and masks) and `mipmaps`. `.hdr` stays float (`TextureAsset.floatImage`, cached as RGBA32F in `Library/`) and uploads as `.rgba16Float`; `sRGB` doesn't apply to it. `TextureAsset(image:isSRGB:generatesMipmaps:)` still builds an 8-bit one; `TextureAsset(floatImage:)` an HDR one.
  - `GLTFImporter` (`.gltf`, `.glb`): `mesh/<name>` per primitive (`mesh/<name> [<p>]` for multi-primitive meshes), `material/<name>` (mapped like `ImportedMaterial.engineMaterial`, via `materialAsset`, with all five texture slots), `texture/<name>` for embedded images, and the main object `prefab/<file name>`, the scene's node tree laid out like `ImportedModel.instantiate`. An external image that is itself a project asset is referenced rather than copied; external `.bin` files are read next to the model and recorded as dependencies (editing one reimports the model). Settings: `smoothNormals` for files without normals, and `materialRemap` (material sub-asset id → `AssetReference`, written by the editor's Extract Materials) so the prefab's nodes use other material assets; the file's own materials are still imported, so old references keep working.
  - Wavefront `.obj` (one mesh per object plus a prefab) and `.material` (a `MaterialAsset` as JSON: every `Material` parameter, textures as `asset:` references, every key optional; `alphaMode` is `"opaque"`, `"mask"` or `"blend"`. A file without `shading` was written before PBR and loads as `blinnPhong`, and the old key `isTransparent` still reads as `blend`. New files always contain `shading`).
- **Reimport:** only when the source content hash, the effective settings, the importer or its `version` change, or the cache is missing; otherwise results load from `Library/Artifacts/<id>/`. `setSettings(_:for:)` writes the sidecar and reimports.
- **File operations** (`AssetDatabase+Files.swift`, for tools): `importFiles(_:into:)` (copies outside files or folders into `Assets/`, with a `.gltf`'s external buffers and images; sources already in `Assets/` aren't copied; fresh ids, not the sources' sidecars), `folders()`, `isFolder`, `uniquePath` ("New Material 2.material"), `createFolder`, `move(_:to:)` (renames and moves files with their sidecar, and folders with everything in them, so ids are kept), `delete` (file and sidecar, or a folder), `createMaterial(_:at:)` and `writeMaterial(_:to:)` (`.material` files, sorted keys). Each refreshes the database afterwards; refusals throw `AssetFileError`.
- **File watching:** `FileWatcher(directory:)` polls (size, mtime, file number; works everywhere) and reports created / modified / deleted / renamed files, via `poll()`, `start(interval:handler:)` on the main actor, or `startCollecting()` + `takeChanges()` for a frame loop. A slow poll (a huge tree) stretches the interval to 20 times its cost, up to 10 s.
- **Dependencies:** an importer that reads other files calls `context.readDependency(relativePath:)` (it returns the bytes and records the file, with its hash, in the Library index). The asset is reimported when any of them changes, appears or disappears, not only when its own source does. References to other assets (a material's texture) aren't dependencies: they resolve live through revisions, so a texture reimport updates every material using it.

#### Background loading and hot reload
Importing, decoding and reading the Library cache run on a small worker pool (`AssetLoadQueue`, up to 4 threads, `.utility` QoS); the database itself and all GPU work stay on the main actor. Results wait in a mailbox until `database.pump()` applies them (bumps revisions, updates the index, calls `onChange` once per batch); `SceneRenderer` calls it every frame, and nothing depends on the main run loop.
- `refreshAsync()` scans now (hashing only changed files) and queues the out-of-date imports; `request(id)` queues one asset (import or cache read); `loadState(of:)` is `.loaded`, `.loading`, `.unloaded`, `.failed` or `.missing`. `pendingLoadCount`, `isLoading` and `loadProgress` (completed / total of the current batch, `fraction`) feed UI; `waitForAll()` blocks, pumping, until everything is applied (tests, tools). One job per asset runs at a time; an asset that changes again while its job runs is reimported afterwards. The old `refresh()`, `asset(_:)` and `reimport` stay synchronous.
- **Rendering while loading:** an entity whose mesh isn't ready is skipped; one whose material (or its texture) isn't ready draws with a neutral gray placeholder material, replaced when the real one is uploaded. Uploads are budgeted: `sceneRenderer.assetUploadBudget` (default 32 MB per frame, at least one upload per frame) spreads big imports over frames. With `ENGINE_SCREENSHOT` (or `blocksOnAssetLoading = true`) the renderer waits for imports and uploads everything in the first frame instead, so screenshots show fully loaded assets and Metal and Vulkan stay byte-identical.
- **Hot reload:** `database.startWatching(interval:)` (or `ENGINE_HOT_RELOAD=1`, which every `AssetDatabase` checks when created) polls `Assets/` on a background queue; the next `pump()` rescans and reimports in the background, and renderers re-upload changed meshes, materials and textures (a material also follows its texture's revision). `stopWatching()` stops it; `logsHotReloads` controls the console lines. A game only needs `sceneRenderer.assets = database` plus one of those. The editor watches its project (once a second) and logs "Importing N assets in the background" / "Assets ready" to the console.
- **Deleting an asset** bumps its revision: its mesh is unregistered and its GPU buffers released (entities draw nothing, reported once on the console), its material becomes the placeholder, and materials that used a deleted texture draw untextured.

### 2D UI draw list

`engine.ui` is an immediate-mode 2D draw list (`UIDrawList`) that game code and the future retained widget tree fill each frame, in points (top-left origin, y down; one point is `ui.scale` framebuffer pixels, the window's backing scale factor). It is cleared before `Game.update`, so fill it in `update` or `render`. The engine draws it in the window pass, at window resolution, over the scene and under the debug overlay.

Primitives: `fillRect` (solid color or linear gradient, per-corner radii), `strokeRect` (a border inside the edge, rounded too), `drawImage` (any `GPUTexture` with a sampler, UV rect, tint, rounded corners), `drawLine` (butt or round caps), and generic textured quads `drawTexturedRect` / `drawTexturedQuad` (modes `.image`, `.mask` for glyph atlases with coverage in alpha, `.sdf(smoothing:)` for SDF text). `drawText(_:at:size:color:font:maxWidth:alignment:)` / `drawText(_ layout:font:at:color:)` draw SDF text from the list's own `glyphAtlas` in the same ordered list, so text clips, culls and batches with shapes (sRGB colors, origin snapped to pixels, baselines to pixel rows). Every shape is one quad whose fragment shader evaluates the signed distance to a rounded box, so edges are antialiased analytically at any scale, without MSAA.

Colors are sRGB with straight alpha. They are interpolated in sRGB (gradients look like CSS), converted to linear in the shader and blended in linear light on the sRGB target. `.rgba8Srgb` textures sample as linear, `.rgba8Unorm` as stored.

`pushClip` / `popClip` / `withClip` keep a stack of scissor rectangles (nested clips intersect). They are whole-pixel rectangles with no antialiasing, and there is no rounded clipping. Items entirely outside the clip are dropped on the CPU.

Consecutive items with the same clip, texture and sampler merge into one draw call; items without a texture join any batch. Each frame uploads all vertices and indices once through the per-frame ring (`setVertexData` / `setIndexData`). `engine.ui.stats` reports items, culled, vertices, indices and batches (draw calls). `RenderPass.setScissorRect(_:)` is available to any pass. Cost: the full demo UI is ~1.5–1.7 ms of window-pass GPU time at 2560x1440 on M-series (lots of blended overdraw).

### UI widgets
`UIContext` runs a retained widget tree (opt-in; games that don't create one are unaffected). Add widgets to `ui.root`, call `ui.update(engine:dt:)` early in `Game.update` and `ui.draw(into: engine.ui)` later. Then check `ui.wantsPointer` / `ui.wantsKeyboard` before driving cameras or shortcuts.

- **Layout:** frames are absolute window points, snapped to the pixel grid. `VStack` / `HStack` offer spacing, padding, cross alignment, justify, and flex `grow` / `shrink` with min/max (`LayoutStyle`). `.absolute(Anchors)` pins overlays and badges. `ScrollView` clips and scrolls (wheel, thumb, track, content drag) vertically, and horizontally with `scrollsHorizontally`. Layout only runs when something called `setNeedsLayout`; measurements are cached. No grid container yet.
- **Events:** pointer down and scroll go to the widget under the pointer and bubble; the handler captures the pointer until release. Keys and text go to the focused widget and bubble. Tab / Shift-Tab cycle focus; Esc closes the top popup, then clears focus. A press that starts outside every widget belongs to the game until release.
- **Widgets:** `Label`, `Button`, `Checkbox` (checkbox or switch), `Slider`, `TextField`, `Dropdown` (with a `PopupMenu` overlay), `ScrollView`, `ListView` and `TreeView` (virtualized rows), `ColorPicker`, `NumberField`, `VectorField`, `ColorSwatch`, `PropertyGrid`, `Separator`, `Spacer`. A focused `TextField` owns text input: caret rect for the IME, composition underlined, copy/cut/paste through `ui.clipboard`. `UITheme` holds colors (sRGB), font sizes and metrics.
- **Inspector widgets:** `NumberField` is a number box: drag horizontally to scrub (Shift fine, Alt/Option coarse; the rate scales with `step` and `range`), click or Enter to type an exact value (Enter commits, Esc cancels, bad input reverts), Up/Down to nudge. `VectorField` is 2-4 of them with X/Y/Z/W axis labels, `ColorSwatch` opens a `ColorPicker` popup. Each reports one gesture as `onEditBegan(start)`, `onChange(value)` ..., `onEditEnded(start, end)`, so an undo system can record a whole drag as one step. `PropertyGrid(world:)` shows an entity's components from reflection: a collapsible section per component and an editor per `FieldKind` (checkbox, number, text, vector, colour swatch for `color` hints, Euler degrees for `Quat`, dropdown for enums, read-only entity names and arrays, collapsible nested structs), honouring the `range` / `step` / `readOnly` / `hidden` / `displayName` / `tooltip` hints. Call `grid.refresh()` every frame: it updates the widgets in place and rebuilds a section only when its shape changes (about 0.06 ms for 40 fields). Every edit calls `onFieldEdit(PropertyEdit)` with phases began / changed / ended and old and new values; by default the grid also writes it with `world.setField` (turn off with `appliesEditsToWorld`).
- **TreeView editing** (opt in): `allowsMultipleSelection` (cmd/ctrl-click toggles, shift-click selects a range, shift+arrows extend, cmd/ctrl+A selects all; `selectedNodes`), `allowsRename` (F2, Enter or double click edit the title in place; `onRename` can veto), `allowsDragAndDrop` (drag rows to reparent or reorder with before / after / into indicators, auto-expand on hover, auto-scroll at the edges, no drops into a node's own subtree; `canMove` and `onMove` can veto).
- **Tooltips:** set `widget.tooltip = "text"`, or override `tooltip(at:)` for per-part tips (rows, a tab's close button). After the pointer rests on a widget for `theme.tooltipDelay` (0.5 s), `UIContext` shows the tooltip of the deepest hovered widget that has one, in a box below-right of the pointer. The box is drawn above popups, never clipped by scroll views, flipped and clamped to stay in the window, and wrapped at `theme.tooltipMaxWidth`. Moving to another widget with a tooltip right after one was shown switches at once. A press, scroll or key hides it until the pointer leaves the widget. There are none while dragging or capturing, and none in screenshot runs (the pointer never moves). Single-line text that doesn't fit ends in "…" (labels, grid field labels, tree and list rows, tab titles) and shows its full text as the tooltip unless it has its own. `TooltipController` and `TooltipLayout` hold the timing and placement logic, for tests.
- **`ConfirmDialog(title:message:confirmTitle:)`**: a modal question. `present(in: ui)` dims the whole window and shows a centered card with Cancel and a confirm button (focused, so Enter confirms; Esc cancels). Clicks behind it go nowhere. Exactly one of `onConfirm` / `onCancel` runs.
- **Cost:** about 0.2 ms CPU per frame to paint the demo panel and about 0.15 ms per full layout; about 3 ms window-pass GPU at 2560x1440 (blended overdraw).

### Docking and panels
Editor-style layout on top of the widget tree (all drawn with `UIDrawList` and the theme, pixel-snapped):

- **`SplitView(.horizontal | .vertical, panes:, fractions:, minSizes:)`**: N panes with draggable dividers. Panes keep their fractions when the window resizes and never go below their minimum (when the minimums don't fit, they are scaled down together). Dragging a divider changes only its two neighbors; double-click (or `resetFractions()`) restores `defaultFractions`. The math is in `SplitLayout`.
- **`TabView(tabs: [DockPanel])`**: a tab bar over one visible `DockPanel` (an id, a title and a content widget). Click to select, drag along the bar to reorder, close button on the selected and hovered closable tabs (or middle click). Tabs that don't fit shrink to `minTabWidth`, then the bar scrolls with the wheel and keeps the selected tab in view. With focus inside: Ctrl-Tab / Ctrl-Shift-Tab and Ctrl-Page Down / Up cycle tabs; Left/Right when the bar itself is focused.
- **`DockSpace`**: register panels with `addPanel`, arrange them with `dock(id, at: .tab(with:) | .split(beside:edge:) | .edge(_:) | .floating(rect))` or `restoreLayout`. Dragging a tab off its bar shows a drop highlight: another bar inserts at the marker, a group's middle adds a tab, its outer quarter splits it, the dock's outer 24 pt docks along the whole edge, anywhere else makes a floating window (Esc cancels). Closing the last tab of a group removes the group and collapses the split. Floating windows stay inside the main window: move them by the empty part of the tab bar, resize them by their edges, and click to bring one to the front. Separate OS windows are future work. `DockPanel.passesPointerThrough` gives a viewport panel's empty area to the game, and `drawsBackground = false` lets a scene drawn behind the UI show through.
- **Layout persistence:** `dock.layout` is a Codable `DockLayout` (tree of splits with fractions, tab groups with panel ids and the active one, floating frames). `jsonData()` writes sorted, pretty JSON. `restoreLayout` drops unknown and repeated ids and collapses what became empty. `onLayoutChange` fires after every user change.
- **Scrolling both ways:** `ScrollView.scrollsHorizontally = true` lays the content out at its measured width, adds a bottom scrollbar, scrolls with horizontal wheel deltas and with Shift plus the wheel, and drags in both axes.
- **Cursors:** widgets return a `UICursor` from `cursor(at:)` (dividers, window edges, drags), and `UIContext.desiredCursor` resolves it from the captured or hovered widget up. The host applies it to the window.

### Text

Text is drawn as signed-distance-field glyphs. `Font` loads a TrueType/OpenType file with the vendored stb_truetype (`Sources/CStbTrueType`, public domain); `Font.bundledUI()` is Inter Regular (SIL OFL, license next to it in `Sources/Engine/Fonts`). Kerning comes from GPOS (`kern` feature) or the legacy `kern` table. One Unicode scalar maps to one glyph; complex shaping (ligatures, RTL, combining marks) is not supported.

- `TextLayout(text, font:, size:, maxWidth:, alignment:)` breaks lines (explicit newlines, word wrap, long-word splitting), applies advances and kerning, and reports `width`/`height`. It needs no GPU, so it is also the `measure` API.
- `GlyphAtlas` rasterizes each glyph once on demand (48 px/em, 6 px SDF padding, 128 on the outline) into 512x512 RGBA8 pages packed with a shelf packer. A full page is kept and a new one added. The device has no sub-region texture update, so a page that gained glyphs is re-created from its CPU copy; call `prewarm` for large character sets.
- `TextRenderer.draw(_:at:size:color:...)` queues text in pixel coordinates, and `render(into:screenSize:)` issues one draw per atlas page. The shader (`text.frag`) turns the distance into alpha with `smoothstep` over the screen-space derivative, so edges stay about one pixel wide at any scale. Output is straight alpha with standard alpha blending; colors are linear RGB; depth is not tested.
- To batch text through another renderer, call `GlyphAtlas.appendQuads(layout, font:, origin:, color:, to:)`. It fills `TextQuads.vertices[page]` with `TextVertex` (position, uv, color) triangles, and `atlas.texture(page:)` is the texture to bind (call `atlas.uploadDirtyPages(device:)` first).

For UI, prefer `engine.ui.drawText`, whose colors are sRGB `UIColor`s like all UI colors; `TextRenderer` (linear colors, its own pass) remains for text drawn inside a scene pass.

### Text input

Typing for text fields is separate from key state. A focused field calls `input.startTextInput(rect:)` with its caret rectangle (window points, top-left origin) and `input.stopTextInput()` when it loses focus. Each frame, `input.textEvents` is the ordered stream of `.text(String)` (committed Unicode text: typed characters, dead-key results, finished IME compositions) and `.key(KeyEvent)` (backspace, delete, arrows, home/end, page up/down, enter, tab, escape, function keys, and shortcuts: a character key with control or command held; each with `modifiers` and `isRepeat` for OS key repeats). `input.committedText` and `input.keyEvents` are convenience views of it, and `KeyModifiers.shortcut` is the platform's editing modifier (command on macOS, control elsewhere). `input.composition` is the IME's in-progress (marked) text and its selection in Characters; draw it underlined at the caret. `Clipboard.string` gets/sets the system clipboard as plain text. `input.keyPresses` lists every key press and repeat with modifiers, even when text input is inactive, and `input.scrollDelta` is the wheel / trackpad scroll in points (positive y scrolls up).

While text input is active, character, editing and navigation keys are not reported by `isDown` / `wasPressed` (typing "w" doesn't move the camera); modifier keys and the mouse still are. With ENGINE_SCREENSHOT, text input is ignored like all other input.

On macOS the window view is an NSTextInputClient, so dead keys (option+e, e), the press-and-hold accent popup and input methods such as Japanese/Chinese/Korean work, and the candidate window appears at the caret rectangle. On the GLFW (Vulkan) window, committed text comes from GLFW's char callback, but GLFW 3.4 has no preedit API: `composition` stays nil, an input method's text only appears once committed, and the candidate window can't be positioned. In the Demo, F2 toggles a debug mode that echoes typed text, the composition and key events in the window title (Esc exits).

### Mouse capture and cursors
`input.cursor` sets the cursor shape over the window (`.arrow`, `.iBeam`, `.pointingHand`, `.resizeHorizontal`, `.resizeVertical`, `.crosshair`, `.notAllowed`, `.hidden`). It resets to `.arrow` every frame, so set it every frame while it should differ. `input.isMouseCaptured = true` asks for relative mouse mode: the cursor is hidden and locked, and `mouseDelta` reports raw motion in points that isn't stopped by the screen edges. The request is ignored while the window lacks focus. Capture ends when the window loses focus or Esc is pressed (that press isn't reported; see `escapeReleasesCapture`), and the game has to ask again. On macOS this uses `CGAssociateMouseAndMouseCursorPosition` and `NSCursor`; on GLFW it uses `GLFW_CURSOR_DISABLED` with raw mouse motion where supported, and `notAllowed` needs GLFW 3.4. Screenshot runs leave the cursor alone. `UIContext.desiredCursor` (from the docking widgets) isn't wired to `input.cursor` yet.

## Editor

`swift run -c release Editor [path/to/scene.json] [--backend metal|vulkan]` starts the in-engine editor, built from the engine's own systems (`Sources/EditorCore`, a library with all the logic and tests in `Tests/EditorTests`; `Sources/Editor` is the thin executable). Without a path it opens a starter scene (camera, sun, environment, floor, a few primitives, a spinning group).

- **Panels** (a `DockSpace`): Scene viewport in the middle, Hierarchy left, Inspector right, Assets, Console and Stats as tabs below (older saved layouts get the Assets tab added). Drag tabs to rearrange; the layout is saved to `~/Library/Application Support/SwiftGameEngine/Editor/prefs.json` (Linux `$XDG_CONFIG_HOME/swift-game-engine/editor/`, Windows `%APPDATA%\SwiftGameEngine\Editor\`; override with `EDITOR_PREFS=<file>`) and restored on launch; "Reset Layout" or an unreadable file falls back to the default.
- **Toolbar:** New, Open / Save / Save As (using the path field; Save on a never-saved scene saves to the field's path), Undo / Redo (titled with the step, e.g. "Undo Rename"), Play / Stop, and the Move / Rotate / Scale tool selector. The title shows `*` for unsaved changes.
- **Viewport:** the scene rendered into a `RenderTarget` sized to the panel, with a grid, a selection outline (`SelectionOutlineRenderer`), camera frustums and light arrows. The toolbar's Move / Rotate / Scale picks the `TransformGizmo` mode; a gizmo drag is one undo step and Esc cancels it. Click selects exactly against the mesh (`ScenePicker`; Shift or Cmd/Ctrl toggles), middle-drag or Alt-drag orbits, add Shift to pan, the wheel zooms, holding the right button flies (WASD, Q/E, Shift faster). Tools implement `ViewportTool` and get the pointer before the camera.
- **Hierarchy:** the entity tree (by `Name`), multi-select, F2 / double click renames, drag to reparent or reorder (world transforms kept), Create / Duplicate / Delete. All recorded in undo. Deleting (the button, or Delete/Backspace) asks first in a modal dialog that names the entity, or the count, and says whether children go too.
- **Inspector:** the primary selected entity's name, id and components (`PropertyGrid`; `MeshRenderer.mesh` / `.material` are dropdowns of the registered keys via `PropertyGrid.stringChoices`); one undo step per drag or typed value; per-component remove; Add Component for registered types with a default (Transform, Camera, DirectionalLight, SceneEnvironment, MeshRenderer, Spin; register more with `EditorComponentCatalog.register`). With several entities selected it shows the primary one.
- **Shortcuts** (Cmd on macOS, Ctrl elsewhere): Z undo, Shift+Z (or Ctrl+Y) redo, S save, D duplicate, P play/stop, Shift+I import files into the Assets panel's folder, Delete/Backspace delete, F frame selection, Esc clear selection. `EditorShortcuts` binds them to command ids (below). They are off while a text field is being edited or a popup is open.
- **Play mode:** Play snapshots the world, runs its systems with real dt and stops recording undo; edits while playing apply but are discarded on Stop, which restores the snapshot. Selection survives (it stores `EntityID`s). Saving, New and Open wait until Stop. The viewport keeps the editor camera while playing.
- **Files:** plain scene files (`World.save`, JSON).
- **Projects:** the project path field with Open Project / New Project (or `--project <folder>`) opens a project, imports its assets and watches `Assets/` (changes are rescanned once a second). The inspector's mesh and material dropdowns then list its assets after the built-in keys, titled "path › object"; picking one stores the asset id. The last project path is remembered in the field, not reopened. Without a project the editor behaves as before.
- **Screenshots:** with `ENGINE_SCREENSHOT` the editor starts deterministically (default layout, starter scene, fixed ids, selection and camera), so Metal and Vulkan images match byte for byte.
- **Assets panel:** the project's folders as a tree on the left; the current folder's subfolders and files on the right as a grid of thumbnails (or a list, "List" / "Grid"), with a breadcrumb and a search field that filters the whole project by file or object name. A model expands (its triangle, or double click) to show its meshes, materials, textures and prefab. Buttons and the right-click menu: Import… (Shift+Cmd/Ctrl+I: copies files or folders from anywhere on disk into the current folder and imports them in the background, selecting the first; a native file dialog on macOS, a path field elsewhere; a `.gltf` brings its external `.bin` and images along; taken names get " 2"; see `AssetDatabase.importFiles` / `EditorSession.importAssets`), New Folder, New Material (a default `.material`), Rename (inline field; the extension is kept), Delete (asks first in a modal dialog; not undoable), Extract Materials (models), Show in Finder (macOS). Drag a cell onto a folder of the tree to move it. Renames and moves go through `AssetDatabase.move`, so ids and every reference to them survive. While imports run in the background the breadcrumb shows "importing N…".
- **Thumbnails** (`AssetThumbnails`): textures show the image (downsampled to 128 px); meshes, materials (on a sphere) and prefabs a preview rendered by a second `SceneRenderer` into a 128 px `RenderTarget` each, four per frame, made when first shown and again when the asset's database revision changes. Assets not loaded yet are requested in the background first. Folders and other files get icons. Memory only (no disk cache yet).
- **Asset inspector:** selecting an item in the browser shows it in the inspector until an entity is selected: path, importer and id; the import settings as a form (`PropertyGrid` on a proxy component; typed for the built-in importers via `ImportSettingsForms`, from the JSON for others) with Apply (writes the sidecar and reimports) and Revert; the file's objects. A `.material` file shows its fields, driven by `MaterialAsset`'s Codable form (new fields appear automatically; fields named "…color" get a color picker, "…texture" a dropdown of the project's textures with None, sampler settings their values). Each edit gesture is one undo step (`MaterialEditCommand`) that saves the file; a drag writes the file live, so the viewport updates as you scrub. Materials imported with a model are shown read-only.
- **Extract Materials** (a glTF model's inspector or context menu): writes each of its materials to `<model> Materials/<name>.material` next to it, adds them to the model's `materialRemap` (new instances use them) and points the open scene's renderers that used the model's materials at the new files (one undo step). Materials already extracted are skipped.
- **Drag and drop from the browser:** a model, prefab or mesh dropped in the viewport is instantiated where the pointer ray meets the surface under it or the ground plane (else 6 units ahead), as one undo step, and selected; dropped on a hierarchy row it becomes that entity's child (below the rows: a root). A material dropped on an object in the viewport (exact pick) or on a hierarchy row sets its `MeshRenderer.material`; a mesh or material dropped on the inspector's matching `MeshRenderer` field sets it. A badge follows the pointer and turns green over a valid target; Esc cancels. Scenes store asset ids. The logic is `EditorSession.drop(_:on:)` with an `AssetDropTarget`, so it is tested without a window.
- **Long titles** in dropdowns (asset paths in the mesh and material fields) end in "…" before the chevron and show in full as a tooltip.
- `EDITOR_SELECT_ASSET=<path>` (relative to `Assets/`; `file#sub-asset` for an object) selects an asset at startup, for screenshots of the browser and asset inspector.
- **Limitations:** no native file dialogs, no right-click menus outside the asset browser, no undo for file operations (rename, move, delete, extract), no multi-selection or dragging several assets at once, no thumbnail disk cache, no multi-entity inspector, no game-camera view in play mode, no pause or step, closed panels come back only via Reset Layout.
- **Commands** (`EditorCommand`, `CommandRegistry`): every editor action is a named command, and the toolbar, menus, shortcuts, hierarchy, inspector, gizmo, asset browser and drops only run commands; none of them edits the world or the document itself. A command has a stable `id`, a `title` and a `doc`, Codable `Arguments` and `Result`, `isAvailable(in:)` (which enables its buttons) and `run`, which records one undo step when the command is undoable. Commands act on the `EditorSession` only, so they run headless: `session.commands.run(EntityCreateCommand.self, .init(template: .cube))`, or generically `session.commands.run("entity.rename", json: data)` with JSON arguments, returning a JSON result (entities as id strings, assets as `asset:` references or paths under `Assets/`, vectors as arrays). `session.commands.all` lists them (`CommandInfo`). A run checks availability first; failures are logged once and thrown (`CommandError`). Asking the user stays in the UI: Delete confirms and Import picks files, then they run the command. What only the window can do (dock layout, viewport camera) goes through `EditorHost`, which the app implements; those commands are unavailable without it. Live previews during a drag go through commands too (`transient: true`), except the gizmo's, which moves entities itself and then records the result with `transform.set`.

  | Id | Does | Undo |
  |---|---|---|
  | `scene.new`, `scene.open {path}`, `scene.save {path?}`, `scene.saveAs {path}` | New / Open / Save / Save As (not while playing) | |
  | `edit.undo`, `edit.redo` | Undo / Redo | |
  | `play.start`, `play.stop`, `play.toggle` | Play mode | |
  | `tool.set {tool}` | Move / Rotate / Scale gizmo | |
  | `project.open {path}`, `project.new {path}` | Open / create a project | |
  | `layout.reset`, `view.frameSelection` | Reset the dock layout, frame the selection (need the window) | |
  | `selection.set {entities, primary?}`, `selection.clear` | Select | |
  | `entity.create {template, position?}` | Create Empty / Cube / Sphere / Plane | yes |
  | `entity.duplicate`, `entity.delete` | Duplicate / delete the selection (the UI confirms delete) | yes |
  | `entity.rename {entity, name}` | Rename | yes |
  | `entity.reparent {entities, parent?, index?}` | Reparent / reorder, keeping world transforms | yes |
  | `transform.set {changes: [{entity, transform, previous?}], label?}` | Set local transforms (gizmo drags) | yes |
  | `component.add {entity, component}`, `component.remove {entity, component}` | Add (catalog default) / remove a component | yes |
  | `component.setField {entity, component, path, value, previous?, label?, transient?}` | Set a field by reflection path (inspector edits) | yes |
  | `asset.import {sources, folder?}` | Copy files into the project and import them | no |
  | `asset.newFolder {folder?, name?}`, `asset.newMaterial {folder?, name?}` | New folder / `.material` | no |
  | `asset.rename {path, name}`, `asset.move {path, folder}`, `asset.delete {path}` | File operations, keeping ids (the UI confirms delete) | no |
  | `asset.extractMaterials {asset}` | Extract a model's materials (the scene edit is undoable) | partly |
  | `asset.applySettings {asset, settings}` | Write import settings and reimport | no |
  | `asset.instantiate {asset, position?, parent?}` | Place a model, prefab or mesh (drops) | yes |
  | `asset.assign {entity, asset, kind?}` | Set a renderer's mesh or material (drops) | yes |
  | `material.set {asset, material, previous?, label?, transient?}` | Edit a `.material` file | yes |
- **Tooltips:** toolbar buttons show their shortcut, taken from `EditorShortcuts` so it always matches the real binding ("Undo Rename (⌘Z)" on macOS, "(Ctrl+Z)" elsewhere). Tool, file, hierarchy, console and inspector buttons, the component remove buttons ("Remove Transform"), the entity ID, and dock tab close buttons ("Close Console") have tooltips. Truncated names show in full.

## Building

### macOS

```sh
swift run -c release Demo                      # Metal
swift run -c release Demo --backend vulkan     # Vulkan via MoltenVK (if the Vulkan SDK is installed)
```

Use `-c release` for anything performance-related. Debug Swift is several times slower at the per-frame CPU work the scenes do (building tens of thousands of instances). In the `occlusion` scene it took 56 ms per frame in debug versus a vsync-capped 16.7 ms in release.

The Vulkan backend is compiled on macOS only when Vulkan headers are found. To get it:
`brew install vulkan-loader vulkan-headers molten-vk glfw shaderc pkgconf`.
Set `ENGINE_DISABLE_VULKAN=1` to build Metal-only.

### Linux

```sh
sudo apt install libvulkan-dev libglfw3-dev zlib1g-dev pkg-config glslc
swift run -c release Demo
```

### Windows

**Untested so far:** the setup below has not been built on a Windows machine yet. CI (`.github/workflows/windows.yml`, build only) is set up but has not run.

Needs Swift for Windows, the LunarG Vulkan SDK (sets `VULKAN_SDK`), GLFW (the prebuilt `glfw-3.4.bin.WIN64` zip works: copy `lib-vc2022` to `lib`) and zlib (e.g. `vcpkg install zlib:x64-windows`; `zlib1.dll` must be on `PATH` to run).

```bat
set GLFW_DIR=C:\glfw-3.4.bin.WIN64
set ZLIB_DIR=C:\vcpkg\installed\x64-windows
swift build -c release
swift run -c release Demo
```

`Package.swift` uses the module maps in `Windows/` (linking `vulkan-1`, `glfw3`, `zlib`) and adds `-I`/`-L` flags from `VULKAN_SDK`, `GLFW_DIR` and `ZLIB_DIR` (`include\` and `lib\` under each; the SDK uses `Include` and `Lib`). These use unsafeFlags, so on Windows the package can't be used as a dependency of another package. Recompile shaders with `Scripts\compile-shaders.ps1` (glslc and SPIRV-Cross from the SDK, clang from the Swift toolchain; untested). `Scripts/render-scenes.sh` is bash-only (use Git Bash or WSL).

### Occlusion queries

`OcclusionQuerySet(count:)` holds the results of hardware occlusion queries. In the screen pass, wrap a draw in `pass.beginOcclusionQuery(set, index:)` / `pass.endOcclusionQuery()`. `set.results[index]` then says whether any sample of that draw passed the depth test (nil until the first result arrives). The usual pattern, used by the `occlusion` demo scene:

1. Draw the big occluders, then every object whose last result wasn't `false`.
2. Draw a bounding box per object with a pipeline set to `colorWrites = false`, `depthWrite = false`, `cullMode = .none`, wrapped in a query.

Results are read back when the frame slot is reused: 3 frames later on Metal (visibility-result buffer) and 2 on Vulkan (`VK_QUERY_TYPE_OCCLUSION` pool). So an object coming into view can show up a few frames late. Padding the proxy boxes hides most of that. Treat the result as stale (e.g. draw the object) when the camera is inside or right next to its box, because the near plane can clip the proxy away. Each frame can issue at most `maxOcclusionQueriesPerFrame` (8192) queries. Skip objects outside the view first with `Frustum(viewProjection:).intersects(center:halfExtent:)`, and call `set.invalidate(index)` for them so a stale "hidden" can't arrive after they come back into view. Don't cull the shadow pass with these results: an object hidden from the camera can still cast a visible shadow. Instead, skip casters whose shadow can't reach the view. Sweep the caster's box along the light direction down to the lowest receiver and test that with `frustum.intersects(center:halfExtent:sweptBy:)`.

## Debugging aids

| Env var | Effect |
|---|---|
| `ENGINE_BACKEND=metal\|vulkan` | Force a backend |
| `ENGINE_HOT_RELOAD=1` | Every `AssetDatabase` watches its `Assets/` folder and reimports changes in the background (see Projects and assets) |
| `ENGINE_QUALITY=low\|medium\|high\|ultra` | Override `EngineConfig.quality` |
| `ENGINE_RESOLUTION=720p\|4k\|16k\|1920x1080\|performance\|native…` | Override `EngineConfig.renderResolution` |
| `ENGINE_UPSCALER=bilinear\|fsr1\|fsr1:<sharpness>\|metalfx\|metalfx-temporal\|taau\|taau:<sharpness>` | Override `EngineConfig.upscaler` |
| `ENGINE_VSYNC=0\|1` | Override `EngineConfig.vsync`. `0` removes the frame-rate cap (Metal: `displaySyncEnabled = false`; Vulkan: mailbox, else immediate presentation) |
| `ENGINE_SCREENSHOT_SOURCE=window` | Screenshots capture the window image (after upscaling and the overlay) instead of the scene at render resolution |
| `ENGINE_SCREENSHOT=out.png` | Run with a fixed timestep, ignore keyboard/mouse input, save frame `ENGINE_SCREENSHOT_FRAME` (default 60) and quit, printing average update / render / GPU times and GPU time per pass over the run (a quick benchmark; add `ENGINE_VSYNC=0`). Useful for golden-image tests. With `ENGINE_OVERLAY=0`, Metal and Vulkan produce byte-identical output for every demo scene at every quality level. Culling in `occlusion` is exact on both backends: the image with culling on matches the one with culling off byte for byte. (The overlay shows live timings, so it differs run to run.) |
| `ENGINE_VULKAN_VALIDATION=1` | Enable `VK_LAYER_KHRONOS_validation`. On macOS with Homebrew, also set `VK_LAYER_PATH=$(brew --prefix vulkan-validationlayers)/share/vulkan/explicit_layer.d` and `DYLD_LIBRARY_PATH=$(brew --prefix vulkan-validationlayers)/lib`. Launch the binary directly, because SIP-protected wrappers such as `timeout` strip `DYLD_*`. |

`engine.saveScreenshot(to:)` captures the next frame from game code.

### Performance overlay

On by default and toggled with the backtick key (`` ` ``). Configure it with `EngineConfig.showDebugOverlay` / `debugOverlayKey` or `ENGINE_OVERLAY=0|1`. It shows FPS and average frame time, min/max over the last 120 frames, CPU time (update + render recording), GPU time and GPU time per pass (see below), draw calls and triangles, backend/GPU and vsync state, and resolution (native size, or render size → upscaled output size with the scale factor and upscaler, plus the window size when letterboxed), plus a frame-time graph with a 60 FPS line. Bars are green under ~18 ms, yellow under ~36 ms, red above. The same numbers are available to game code as `engine.stats`.

GPU time is measured per pass: `depth` (each `beginDepthPass`), `scene`, `upscale` and `window` (the last two only when rendering offscreen). Metal samples timestamps at the start and end of each pass's vertex and fragment stages, and adds the two stage durations. Vulkan writes timestamps around each render pass. The frame's GPU time is the sum of its passes on Metal and the span of its command buffer on Vulkan. On Metal, a command buffer's own span (the fallback on GPUs that can't sample at stage boundaries) also counts time spent waiting for the window server to release a drawable, which can be more than the rendering itself.

Reading the numbers:
- With vsync on, the GPU clocks down when it has headroom, so pass times read higher than with `ENGINE_VSYNC=0`.
- On macOS, even with vsync off, the window server limits how fast a window can present (120 or 240 FPS depending on the display, and it varies between runs). Most demo scenes hit that limit long before the GPU is busy. Compare GPU time with frame time to see how much headroom is left.
- The window pass's cost is the texel reads of the scene image. When downscaling it box-filters the whole footprint: on an M5 about 2–3 ms from 8K and about 20 ms from 16K (a single-tap blit was about 0.4 ms from 8K). Upscaling and native rendering are unaffected. (On Metal, the scene image deliberately has no `.pixelFormatView` usage: the flag turns off Apple GPUs' lossless compression, which made this pass 3–4x slower. Views that only drop sRGB don't need it.)

## Render quality

`EngineConfig.quality` (or `ENGINE_QUALITY`) picks a `RenderQuality` preset. The engine applies its MSAA sample count, unless `EngineConfig.sampleCount` is set explicitly. Games read the other settings from `engine.quality`:

| | low | medium | high (default) | ultra |
|---|---|---|---|---|
| MSAA (clamped to GPU support) | 1x | 2x | 4x | 8x |
| `shadowMapSize` | 1024 | 2048 | 2048 | 4096 |
| `shadowFilterRadius` (PCF taps) | 0 (1) | 1 (3x3) | 1 (3x3) | 2 (5x5) |

## Render resolution

`EngineConfig.renderResolution` (or `ENGINE_RESOLUTION`, or `engine.renderResolution` at runtime) sets the size the scene renders at, independent of the window:

- `.native` (default) renders straight to the window, as before.
- `.fixed(width:height:)` renders offscreen at that size. `beginWindowPass()` then scales the image into the window (bilinear, letterboxed to keep the aspect ratio), and the overlay is drawn at window resolution on top. Screenshots are taken at the render resolution, without the overlay.

`.scaled(factor)` renders at the window size divided by `factor` and lets the upscaler (below) bring it back up. These are the FSR-style modes `quality` (1.5), `balanced` (1.7), `performance` (2) and `ultraperformance` (3), or any `<factor>x`.

`RenderResolution("…")` accepts `native`, the presets `144p 240p 360p 480p 540p 720p 1080p 1440p 4k 5k 8k 12k 16k`, any `<height>p` or `<n>k` (16:9), or `<width>x<height>`. Use `engine.renderSize` / `engine.aspectRatio` for projections.

Limits:
- Sizes above `device.maxTextureSize` are rejected with an error. That limit is 16384 on most GPUs and 32768 on Apple10-family GPUs such as M5, so `32k` works there.
- MSAA is reduced at startup so the multisampled targets fit in 4 GiB (16K drops to 4x, 32K to 1x). A runtime change that wouldn't fit at the current sample count is rejected with a message.
- Downscaling to the window (render size above the window) box-filters the scene image in linear light: each window pixel averages the texels under it with exact area weights, up to 8 texels per axis, and 4 spread taps per axis beyond that. The result is byte-identical on Metal and Vulkan. The screenshot is the real output.
- Screenshots are compressed PNGs (system zlib, adaptive row filters, streamed in chunks): a 4K screenshot is typically 1–2 MB and a 16K one about 10 MB (scene-dependent). Encoding a 16K image takes a few seconds.

## Upscaling

`EngineConfig.upscaler` (or `ENGINE_UPSCALER`, or `engine.upscaler` at runtime) picks how an offscreen scene is scaled into the window:

| | Backends | How |
|---|---|---|
| `.bilinear` (default) | all | One bilinear tap per pixel |
| `.fsr1(sharpness:)` | all | AMD FSR 1: edge-adaptive upsampling (EASU) into a texture at the window size, then contrast-adaptive sharpening (RCAS) into the window. `sharpness` is in stops: 0 is the sharpest, default 0.2 |
| `.metalFXSpatial` | Metal | Apple's MetalFX spatial scaler, then a plain copy into the window |
| `.metalFXTemporal` | Metal | Apple's MetalFX temporal scaler, then a plain copy into the window. Temporal (see below) |
| `.taau(sharpness:)` | all | Temporal anti-aliasing upsample: accumulates jittered frames into a history at the window size (reprojected with motion vectors, clamped to the current neighborhood in YCoCg), then RCAS. Default sharpness 0.5. Temporal |

Notes:
- **Gamma:** the upscalers work on gamma-encoded values. They read the sRGB scene image through a UNORM view, and the last pass converts back to linear for the sRGB window.
- **Pixel alignment:** the output goes into a pixel-aligned letterbox rectangle, so upscaled pixels map 1:1 onto the window.
- **Cross-backend checks:** FSR 1 loads texels directly instead of using gathers, so Metal and Vulkan produce byte-identical results. Run `ENGINE_RESOLUTION=performance ENGINE_UPSCALER=fsr1 Scripts/render-scenes.sh` to check.
- **Cost:** measured in isolation on an M5 at 1280x720 → 2560x1440, FSR 1 takes about 0.9 ms (upscale) + 0.23 ms (sharpen), and MetalFX spatial about 0.77 ms + 0.23 ms (copy). That only pays off when per-pixel work costs more than that, i.e. with expensive shading or high-resolution displays. Shadow maps and vertex work don't shrink with the render size.
- **Temporal upscalers** (`metalfx-temporal`, `taau`) need three things from the game:
  - Jitter the projection with `engine.jittered(projection)` (Halton 2,3 sub-pixel offsets; `engine.jitter` / `engine.previousJitter` in render pixels, zero when inactive).
  - Write motion vectors: set `PipelineDescriptor.writesMotionVectors` and output `float2` to `[[color(1)]]` / `layout(location = 1)`. The value is previous UV − current UV from unjittered clip positions, `(prev.xy/prev.w − cur.xy/cur.w) * (0.5, −0.5)`. Pipelines without the flag leave 0 there.
  - Call `engine.resetTemporalHistory()` on camera cuts. The engine resets on resolution, window or upscaler changes.

  The engine then stores the scene's depth for the upscaler (reversed-Z follows `clearDepth`) and adds an RG16F motion attachment to the scene pass.
- **MSAA:** a temporal upscaler forces MSAA to 1x. The sample count is fixed at startup, so start with `ENGINE_UPSCALER=taau` (or `--quality low`) to be able to switch to one at runtime.
- **TAAU across backends:** it loads texels directly, so Metal and Vulkan match byte for byte (`ENGINE_RESOLUTION=performance ENGINE_UPSCALER=taau Scripts/render-scenes.sh`). On Vulkan it needs `independentBlend`.
- **Demo motion:** objects animated on the CPU have no object motion vectors and can trail slightly at fast edges; vertex-animated ones (the `occlusion` cubes) don't. Transparent pipelines don't write motion. TAAU has no depth-based disocclusion test and relies on the clamp.
- **Temporal cost** at 1280x720 → 2560x1440 on an M5: TAAU about 2 ms, MetalFX temporal about 3 ms. The MetalFX spatial timing reported under `upscale` is currently unreliably low.

## Demo scenes

```sh
swift run -c release Demo --scene shadows --quality ultra --resolution 4k   # --list prints scene names, --help describes everything
```

| # | Scene | Tests | Keys |
|---|---|---|---|
| 1 | `shadows` | Shadow mapping + PCF, static and per-frame instancing | **L** pause sun, **R** rebuild pillars (releases a buffer mid-run) |
| 2 | `instancing` | 3.6k–40k instances per draw, large transient uploads | **I** cycle grid size |
| 3 | `transparency` | Alpha blending, depth writes off, back-to-front sorting | **O** toggle sorting |
| 4 | `depth` | Depth precision from 0.05 m to 50 km | **Z** toggle standard / reversed-Z |
| 5 | `culling` | Back / front / no culling, counter-clockwise winding | |
| 6 | `churn` | Buffers, textures and pipelines created and dropped while in flight | |
| 7 | `occlusion` | Frustum, occlusion and shadow-caster culling: 169 clusters of 125 cubes in a city grid, hardware queries on bounding-box proxies, cubes animated in the vertex shader from a static buffer | **O** toggle culling, **B** show culled clusters through walls |
| 8 | `textures` | Procedural mipmapped sRGB texture with a repeat/trilinear sampler, a nearest-sampled linear texture, static and per-frame uniform buffers | **M** toggle mipmapping |
| 9 | `text` | SDF text: sizes from 12 to 128 px, kerning pairs, word wrap, alignment, non-ASCII Latin | |
| 10 | `ui` | 2D draw list: rounded rects with per-corner radii, strokes, gradients, images, lines, nested clipping, batching | |
| 11 | `ecs` | Entities drawn by the engine's `SceneRenderer`: hierarchy, instancing, shadows, transparency, motion vectors | |
| 12 | `widgets` | Retained widgets: layout, focus, text field, dropdown, scroll view, list, tree, color picker | mouse/keyboard; Esc unfocuses |
| 13 | `docking` | Docking panels: splits, tab groups, drag-and-drop docking, floating panel, 2-axis scrolling | mouse; Ctrl-Tab cycles tabs; Esc cancels a drag |
| 14 | `inspector` | Editor panels: hierarchy TreeView (multi-select, rename, drag to reparent) and a reflection-driven PropertyGrid | mouse/keyboard; F2 renames |
| 15 | `viewports` | One world rendered into two render targets (editor camera with grid and debug gizmos, game camera) shown side by side in the UI | right-drag flies the editor camera (mouse captured); drag the divider |
| 16 | `gizmos` | Picking, selection outline, translate/rotate/scale gizmos with snapping and undo | click/shift-click select; W/E/R modes; X space; C pivot; hold Cmd/Ctrl to snap; Esc cancels; Cmd/Ctrl+Z undo |
| 17 | `images` | Decoded PNG/HDR textures: mip chains receding to the horizon, sRGB vs linear upload of the same bytes, an `.rgba16Float` HDR cube, a texture updated in place every frame | M toggles the floor's mipmaps |
| 18 | `gltf` | glTF 2.0 import (Khronos OrientationTest: arrows must point into their targets), or any file via `DEMO_GLTF=<path>` | |
| 19 | `pbr` | PBR materials: spheres from dielectric to metal (bottom to top) and smooth to rough (left to right), a normal-mapped brick slab, an emissive panel, an alpha-masked plant (cutout shadow too), the Khronos BoomBox (CC0; all five texture maps, textures downscaled) | |

Everywhere: **1–9** and **0** (scene 10) switch scenes, **]** / **[** next / previous scene, **F2** toggles a text-input test mode (echoes typing in the window title), **Tab / Shift-Tab** cycle the render resolution (native, quality, performance, 144p … 16k), **U** cycles the upscaler (temporal ones only without MSAA), **V** toggles vsync, **Space** pauses animation, arrows/WASD or left-drag orbit, **Q/E** zoom, **Esc** quits. The window title shows the scene, its state, the render size, the quality and the backend.

`Scripts/render-scenes.sh [quality]` renders every scene on each available backend, writes PNGs to `.build/scene-shots/<quality>[-<resolution>]/`, and fails if the backends differ. Set `ENGINE_RESOLUTION` to render at a fixed size. Set `ENGINE_UPSCALER` as well to compare upscaled window images. Set `VALIDATE=1` to run Vulkan under the validation layers, which also fails on validation errors.

## Current limitations / next steps

The full roadmap (ECS, assets, physics, audio, UI, in-engine editor) lives on the project task board.

- Static buffers are immutable after creation (use `setVertexData` / `setUniformData` for dynamic data); textures can be patched with `updateTexture`. Creating either on Vulkan blocks on the upload.
- Textures are 2D RGBA8 or RGBA16F only: no compressed formats (BC7/ASTC), cube maps or arrays.
