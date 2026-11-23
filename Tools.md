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
wedge, pyramid, lathe, extrude, sweep, loft, sculpt, foliage, group pivots) with a part hierarchy, colors, textures, PBR settings, glow, and
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
rotation-minimizing frames, `radii` taper, `closed` loops, `straight: true` mitred corners, capped
ends) and `loft` (`sections` {at, size, roundness superellipse 2^r, or profile} along `axis`
y/z/x, monotone cubic between sections or straight panels, auto-aligned rings, hard profile
corners, capped ends); `deform` on any mesh part (taper, bend, twist, noise, in order, before
mirroring) with edge-length `subdivide` (0-6, default 3, 60k-triangle cap) and normals recomputed
keeping hard edges. Mesh Builder rows for path points, loft sections and deformers; three new
examples (sailboat, gnarled tree, desk lamp). Importer version 3.
Merged with sculpt: the curves' straight-segments switch is `straight: true` (not `smooth`, which
is a sculpt child's melt radius). (Sweeps, lofts and deformed children now work in sculpts: see
"Sculpt looks and mesh fields" below.)
Curves not done: no per-point twist or roll along a sweep (the frame is rotation-minimizing only, no
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
Sculpts: shape `sculpt` combines its subtree as signed distance fields in file order (child
`blend` add/subtract/intersect, `smooth` m), sculpt `resolution` (cells on the longest side,
8-128, default 64) and `noise` {amount, scale, seed} (intersects trim cleanly). Every solid shape
works, lathe and extrude included; mirror/repeat copies join after their source. Meshed by dual
contouring (crisp carved edges, gradient normals split above 40°, box-projected UVs in meters),
closed and outward; cached; children stay pivot nodes without meshes; spatial checks, bounds and
`parts(of:)` see only the sculpt; tracks on children warn. Editor: Sculpt button (carved stone
starter), Resolution / Noise rows, Blend / Smooth rows on children, wireframe ghost of a
selected child. Examples: Armchair, Stone Arch. Importer version 3. About 0.6 s for a 20-child
sculpt at resolution 64 (debug build, loaded machine).
Not done: no decimation of flat regions (a carved box has as many triangles as a curved one), no
per-child noise, ellipsoids and oval round shapes use approximate fields (smooth radii vary a
little around them), thin features under about a cell vanish or may leave non-manifold edges,
the ghost is a wireframe of the shape (not the blended result), import of a large sculpt at
resolution 128 takes seconds in a debug build, and `segments` of analytic children is ignored
(fields are exact).
Sculpt looks and mesh fields (importer version 6): sculpt children that set any look field
(color, look, wear, roughness, metallic, glow, texture, material…) keep their own look; the rest
inherit the sculpt's. After dual contouring each vertex is owned by the owning child whose
surface is nearest (|distance|, noise included; subtracts/intersects own their cut only when
they set a look), edges between owners are cut where both are equally close (bisection, then
onto the surface) and triangles split along the cuts (3-owner triangles get a center point), so
the color boundary follows the surface; vertices are split per owner, cut points shared, so no
cracks and no bleeding of UVs/AO. `MeshBuildSculpting.splittingLooks()` (used by the mesh build,
terrain-scatter and character-attachment importers): a one-look sculpt keeps its mesh (with that
look); with several, the sculpt node becomes a pivot (still animated) and each look is a node
`<sculpt>/<first child of that look>` with `mesh/…` and `material/…` sub-assets of that name.
Spatial checks, bounds and `parts(of:)` still use the whole mesh; preview labels name the
sculpt once and `highlight` of a child outlines its look's mesh; clicking a look mesh in the
Mesh Builder selects the sculpt. Sweeps, lofts and any shape with `deform` are sculpt children
through an exact mesh distance field (MeshBuildMeshSDF.swift: welded mesh, BVH nearest-point
query, sign from angle-weighted face/edge/corner pseudo-normals, BVH lower bounds for the
per-block active lists; built at segments >= 32). 3 sweeps + 1 loft + a bent box at
resolution 64: meshing ~0.7 s debug (test), whole set+import+checks ~0.9 s debug and ~70 ms release (separate parts: ~0.5 s / ~20 ms). Armchair is now one sculpt
(fabric frame, linen-fabric cushions); new Teapot example (lathe body/lid, swept spout and
handle, cream knob).
Sculpt looks / mesh field gaps: a child that sets any look field uses all its own look fields
(no per-field inheritance, so setting only `wear` drops the sculpt's color); several looks
cost a mesh, material and draw each (plus a blend layer draw per look that cross-fades textures); a mesh child must be closed (an open deformed lathe or a
sweep crossing itself can get the wrong sign near the gap or crossing); mesh children are
faceted at their own segments (32+), which shows on large smooth sweeps at high resolution;
lathe profiles are polygons in the field, so a coarse profile shows bands (write ~20+ points for
a smooth pot); terrain scatter and character attachments draw the looks but character
`partColors` recolor every look of a sculpt at once.
Sculpt look blending (MeshBuildSculptBlend.swift, MeshBuildImporter+Blends.swift, VertexPaint.swift):
looks meet in a band of half-width 0.75 x the join's smooth (min 4 mm; smooth 0 stays sharp), found by
a band-limited Dijkstra from the cut points; same-texture looks mix color/roughness/metallic/glow in a
new optional vertex paint stream (vertex buffer 2, attributes 14-15, mesh_paint.vert /
mesh_paint(_mask).frag; meshes without it render byte-identically), different textures cross-fade
through alpha-blended "<sculpt>/<child> blend" layers (depth less-or-equal on the same surface, no
dither). Leaf cards get a seeded per-card color jitter in the same stream. Mossy Stone example.
Armchair cushions and the Teapot knob now blend. Debug editor (loaded machine), before -> after:
Armchair new 12.1 -> 11.6 s, set+import ~6.8 -> ~7.0 s; Teapot new 5.1 -> 5.7 s, set+import ~1.85 ->
~2.1 s; the blend pass alone on a 135k-triangle two-look sculpt is 0.37 s debug (of 5.4 s meshing).
Blending gaps: only the nearest boundary counts (a vertex near two different looks blends with one;
triple points get a third each at the center only); groups 8+ of one sculpt don't blend; a look with
a `material` asset or opacity < 1 keeps a sharp line; blend layers have no edge wear and copy (not
re-bake) occlusion; a blend layer per look costs a transparent draw and covers decals in the band;
bands narrower than the sculpt's cells blend over one cell; deformed multi-look sculpts deform each
piece by its own bounds (pre-existing) so layers can drift from their surface; terrain scatter keeps
the paint but character attachments draw sculpts without blending; painted meshes use
mesh_paint.vert, so vertex-shader effects added to mesh.vert (wind sway) must go in
mesh_vertex.glsl to reach painted leaves; material graphs ignore vertex paint; no vertex paint
editing tool (by design).
Realistic surfaces (looks): parts take `look` (23 generated, tileable surfaces: woods, metals,
stone, brick, fabric, glass, ground…), `lookScale` (m per tile), `wear` (0-1) and `grain`
(x|y|z); `color` tints a look to its average color. Each look is albedo (sRGB) + normal map +
ORM (occlusion/roughness/metal, linear), generated on all cores (~25 ms per 512 px set in
release, ~0.3-1 s in debug), cached per look/wear level/resolution per process and stored with
the import. Look UVs are in meters: round shapes wrap around Y in whole tiles, others get
per-triangle box projection. File-level `ao` (off by default since importer version 12: its tessellation took GridMap
starter pieces from 12 to 2-9k triangles each; the examples set it) bakes per-vertex ambient occlusion
from the whole model (voxel ray march on tessellated meshes) into `MeshVertex.tangent.w`'s
magnitude, which mesh_surface.glsl multiplies into the ambient term (Metal and Vulkan from one
GLSL source). `.proctex` gained fbm, ridged, voronoi, cells, woodRings, streaks and a
`normalStrength` companion normal map. Examples use looks; new Weathered Crate and Park Bench.
`meshBuild.preview` (all world captures) now waits for texture loads. Importer version 3.
Merged with sculpt and curves (importer version 5): looks box-project on sculpt, sweep and loft
meshes; splitting meshes for occlusion is capped at about 30k triangles per model (edges half the
occlusion reach), which cut the examples from up to 260k triangles to 10-50k (the tree, with
noise-deformed foliage, is about 100k from its own subdivision) and imports 3-4x faster.
Merged (importer version 8): edge wear on dense meshes (sculpt pieces) only searches the band plus
the longest triangle edge and runs on all cores (the Armchair import went from 885 s to 8 s in a
debug build); foliage and ribbons inside a sculpt are left out with a warning.
Object-space edge wear (importer version 9): the chip noise is 3D value noise (two octaves, as
before) of the fragment's position in the mesh's own space, so a chip on a box edge wraps around it
as one and corners chip as one; chips stay on the model when it moves, turns or is scaled.
`EdgeWear.noiseFrequency` is now cycles per meter (1 / (1.5 x band width), the same chip size as
before) instead of per UV unit; `EdgeWear.chipNoise(at:)` mirrors the shader for tests. Shared
rendering changes: mesh.vert and mesh_skinned.vert write a new varying `vObjectPos` (location 4,
the free slot between vColor and vParams; the vertex position before the model transform, bind
pose when skinned), and mesh_surface.glsl reads it only in the non-material-graph variants
(mesh.frag, mesh_mask.frag), inside the existing `uvRow1.w > 0.5` edge-wear branch, so material
graph and terrain shaders compile to the same SPIR-V/MSL as before. Demo scenes (pbr, gltf,
reflections, sky, textures, facades, skinning) render byte-identical before/after on Metal and
Vulkan.
Object-space edge wear gaps: repeat copies of a part share one mesh, so they show identical chips
(mirror copies show mirrored ones); the noise is axis-aligned value noise, so on an axis-aligned
face the chips are slices through a cubic lattice (not visible as a grid at chip scale, but not as
varied as gradient or cellular chips); a sculpt with several looks chips continuously across the
look meshes (same space), but two separate parts touching don't share an edge band (as before);
grime, scratches and the paint chips inside a face are still in the look textures (box projected
per face).
Plants (importer version 8): shape `foliage` scatters leaf cards (alpha-cutout quads) over the
ellipsoid of its `size` (78% on the shell facing out, tilted and rolled at random, the rest inside;
kept inside the size box) or `on` named parts (along the outer `along` [from, to] of sweeps,
default [0.35, 1], ending at the tips; over any other mesh's surface; a name covers its mirror /
repeat copies); upright looks (grassBlades, flowers, fern) stand crossed tufts on the box's floor,
size.y tall. `cardSize`, `density` (1 = full) or `count`, `seed` (plus the part name):
deterministic; 2 triangles a card (4 a tuft), capped at 12k per part with a warning. Normals are
bent toward the cloud's outward normal (ellipsoid, or the box around the leafy branches) so a
crown shades as one volume; foliage isn't tessellated for AO but gets it (inner cards darker).
Eight generated leaf looks (broadleaf, oakLeaves, mapleLeaves, pineNeedles, fern, grassBlades,
flowers, ivy): a 512 px texture with four shaded sprig variants in its quadrants, albedo with alpha
(push-pull filled under the cutout), normal and ORM, ~1 s per look in debug; materials are mask
(cutoff 0.35-0.42), double-sided and translucent; `color` tints to that average. Ribbons: a
sweep with `ribbon` (width) or `open: true` + `profile` (an open curve) is an uncapped,
double-sided strip; a leaf look on a ribbon or plane maps one sprig along it (fern ribbons are
fronds). Renderer: `MaterialAsset.translucency` (0...1, PBR; packed in the material uniform's
params.z, which only Blinn-Phong used): back faces keep their normals instead of flipping, sunlight
through the leaf adds to the side away from the sun, specular uses each card's face normal (screen
derivatives, plus the normal map's bump) with NoV and VoH at least 0.5, so a bent-normal crown has
scattered glints instead of one shiny blob or a grazing sheen (mesh_surface.glsl; Metal and Vulkan
from one source). Deformers: subdivision has a budget of 8k triangles per part (was 60k); noise
octaves finer than the mesh can show fade out, and noise whose largest lumps don't fit warns.
Results report `triangles`. Examples: Gnarled Tree rebuilt (bark sweeps, oak cards on the branches
plus a crown: 100,796 → ~8.8k triangles), new Shrub (~3k, with grass and wildflower tufts), Potted
Fern (lathe pot, fern ribbons, ~8.7k), Small Pine (needle cards on six whorls, ~11.4k). Editor:
Foliage button (a broadleaf crown), Leaves / Card size / Density / Count / Seed / Grows on / From
rows, Ribbon width and Open profile on sweeps, a leaf look picker on planes and ribbons.
Game-ready plants (importer version 9): wind, detail levels with impostors, verified instancing.
See docs/Builders.md › Game-ready plants. Wind: `SceneEnvironment.wind` (direction, strength,
gustiness; default a 0.5 breeze; `component.setField "SceneEnvironment.wind.strength"`) sways
materials with `MaterialWind` (flutter, bend, height, origin, up in the mesh's space); plant parts
get one at import (leaves flutter 1, sweeps/lofts 0.08, other parts none; file `wind` scales,
0 = still). Sway is in new vertex shaders only (wind.glsl in mesh_wind.vert / mesh_shadow_wind.vert):
trunk bend along the wind ∝ h² / height from the plant's base, a bend²/2h drop, per-vertex flutter
from a noise of the object position, gusts and sway phased by the plant base's world position;
previous-frame sway for motion vectors; shadows and depth prepasses use the same displacement.
Detail levels at import (`lod`, default on for plants; `lodDistances`): level 1 half the cards
(1.3x, about their stems) and other parts (not sculpts) at half the segments and sweep rings, without AO tessellation (or trunk noise)
(AO copied from the nearest full-detail vertex), level 2 a quarter (1.75x, nested subset) and a third
of the segments, level 3 a CPU-baked impostor (3 crossed quads, 512 px albedo + tangent-space normal
atlas; importers can't use the GPU); parts with equal materials merge at levels 1+; all parts
measure to one plant sphere and switch at 8/16/32 x its radius. Results add `lodTriangles` and
`lodDistances`; `meshBuild.preview` is still air at full detail; the tab sways (its own clock).
Instancing already existed (RenderList batches equal mesh + material); verified for prefab copies.
Shared rendering changes: `Material.wind` / `MaterialAsset.wind` (optional, not written when nil),
`Material.sways`, `SceneEnvironment.wind`, `MeshLOD.sphere` / `.materials` / empty level meshes
(draw nothing), `RenderPrep.lodKeys`, `SceneRenderer.windClock`, `PipelineKey.wind`,
`DepthChoice.wind`, `MaterialTraits.alphaTested` also set for swaying materials (their depth batches
keep the material), material buffer 2 bound to both stages for swaying materials only. Demo scene
`forest` (200 Gnarled Trees).
Plants not done: mipmaps are plain box
filters, so distant cards thin out a little (the low alpha cutoff hides most of it; no
coverage-preserving mips or alpha-to-coverage); crossed tufts read as thin lines from straight
above; leaves `on` a part are placed at rest, so an animated branch leaves its leaves
behind unless the foliage is its child; the crown's bent normals come from one ellipsoid or box per
foliage part (lobed crowns need several parts); no control of leaf arrangement on a branch
(phyllotaxis, leaves only on top, droop); translucency is one factor per material (no thickness
map, no subsurface color) and isn't exposed in the Material Builder or materialGraph tools; leaf
sprigs are 256 px each, soft up close; the deform budget is fixed (no per-part override); spatial
checks treat foliage by its box like any part (fine for crowns around branches, but a card cloud
whose box overlaps a part counts as touching it).
Studio light and edge wear (importer version 6): `meshBuild.preview` and the Mesh Builder tab
light models with a neutral gray HDR studio (gradient walls, darker floor, five white softboxes;
made in code, `MeshBuildPreviewEnvironment`) through the existing image-based lighting
(`SceneEnvironment.sky = .map`), so metals get highlights and reflections; the preview takes
`environment` studio|outdoor|flat. Look parts with `wear` get worn convex edges and corners:
paint chipped to bare metal or wood, lighter rubbed wood/stone/brick/leather, polished edges on
rusty and plain metal. Per vertex, the importer stores an edge coordinate (strength - distance to
the nearest convex edge / band width, linear so it interpolates exactly across big flat
triangles) as the tangent's component along the normal, which mesh_surface.glsl already
projects away; the worn surface's color, roughness, metalness, noise frequency and crispness
ride in the two unused w components of the material's UV rows (`EdgeWear`, packed as 24-bit
integers). Shared rendering changes: `Material.edgeWear` / `MaterialAsset.edgeWear` (optional,
not written when nil), `SceneRenderer.MaterialUniforms.uvRow0.w / uvRow1.w`, and a branch in
mesh_surface.glsl (not in material graph or terrain variants) that only runs when
`uvRow1.w > 0`; and the sky under an orthographic view (sky.vert, `SkyUniforms.extra.z`, set by
`EnvironmentLighting.drawSky`) now looks along the view direction everywhere (one flat color)
instead of fanning out by screen position. Demo scenes (pbr, gltf, reflections, sky, textures,
facades, skinning) render byte-identical before/after on Metal and Vulkan.
Looks gaps: no triplanar blending, so box projection shows a seam where projections meet on
curved non-round shapes (bevels, extrude sides) and spheres pinch slightly at the cap boundary;
edge strength is per part, so where two parts meet nothing wears (only each
part's own edges); concave edges and creases get no wear-specific treatment beyond AO; very
non-uniform entity scale skews the edge band a little (the coordinate is a ratio of tangent
components); edge wear needs a look (plain-colored parts with `wear` get none) and isn't on parts
with a `material` asset or in material graphs; the studio isn't selectable in the tab (always
studio) and has a fixed orientation; textures are 512 px (up close below ~0.3 m the grain gets
soft); textures are duplicated per .meshbuild file in Library (≈1 MB per texture); vertex AO only
darkens ambient light, not direct light; AO is baked at rest pose (moving parts keep it);
debug-build editors spend ~0.5 s per new look on first import.

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
"piece" wording, tab checked in the running editor. `AssetCooker.keepsSource` is now `sprite`, `tilemap`, `path`, `terrain`. Still not done: terrain shaping ignores banking and shapes each path alone; junctions of three
or more roads aren't merged, no roundabouts; a faint seam where a patch meets a box road's edge
and the main road's center line runs through the junction; cut-back assumes straight roads
at the crossing; `path.get` doesn't report junctions; side-offset pieces (lamps, posts) aren't
mitered. 0.19 follow-up: the cooker follows `PathFollower.path` given as a plain file path; Visual
Script nodes drive followers (`pathFollower.*`, On Path Follower Event).

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
Roadmap 2C (navmesh and crowds): a baked navmesh (`AI/Navigation/`: recast-style voxel columns
from downward rays, erosion, single-layer regions, planar rectangle polygons with detail heights,
`NavigationLink` off-mesh links for jumps, drops and ladders), A* over polygons with the funnel,
ORCA crowd avoidance between behavior tree agents, surface following and link crossing for
transform-moved agents, a Library bake cache cooked into packs, the Scene view overlay, and tools
`navigation.bake`, `navigation.query`, `navigation.overlay`. Demo scenes `navmesh` and `crowd`.
Gaps: polygons are cell-aligned rectangles (no contour simplification or triangulation), so
diagonal walls give stair-stepped edges and more polygons than recast; one surface per collider
per voxel column (a single mesh collider with two floors over the same spot only bakes its top);
no moving obstacles or runtime tile rebakes (rebake the whole mesh); character-controller and
dynamic-body agents walk at off-mesh links rather than jumping across them; avoidance covers
behavior tree agents only (not the player or other characters) and has no static-obstacle
lines (the navmesh keeps transform-moved agents off walls); no standalone `NavigationAgent`
component; the Behavior Tree tab has no bake button (use the tools); exports ship only navmeshes
baked in the editor (others bake at load); no playtest (demo scenes aren't project scenes):
reachability and avoidance are asserted in `NavMeshTests`.

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
all four arrow keys, so a gamepad can't leave it; transitions only step while the layout is drawn.
0.19 follow-up: the cooker follows a `UILayoutPlayer`'s layout named by path; Visual Script nodes for the
game UI layer (`gameUI.*`, On Game UI Event).

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
on the game UI layer, so GameRunner and exported games show conversations. 0.19 follow-up: `.dialogue`
files ship as written (they had no data in a pack) with the portraits and `uiLayout` they name, and a
`DialoguePlayer`'s dialogue and layout named by path are followed; `dialogue.setLayout` / `dialogue.layout`
nodes. Still not done: the layout preview draws at about 0.26 scale in a small window;
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
`wait` key without clicking through the conversation (graphs can, with `timeline.releaseDialogue`);
preview sound only covered in code, not listened to. 0.19 follow-up: `timeline.clearFade` (and
`TimelinePlayer.clearFade()`) lets a `holdFade` timeline's fade go; `timeline.dialogue` reports `wait` keys.

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
for the tab's level (`builder.select` now sets the selection: states, transitions, parameters, layers).
IK (roadmap 1B): graphs have an `ik` list run after the states and layers, before the pose
reaches the bones (`Animator.ik`, AnimationIK.swift): `twoBoneIK` (root, middle, end; `pole` in
the character's space or the animated bend), `aim` (a chain turns so the last bone's `aimAxis`
points at the target, shared along the chain, `maxAngle` per bone), `chainIK` (FABRIK, tails and
tentacles) and `footPlacement` (`legs`, `pelvis`: a ray down from above each foot against
physics (`World.attachedPhysics`), the pelvis drops so the lower foot reaches, feet align to the
normal up to 40 degrees, planted feet lock until they lift or slide 0.25 m). Every node has a
`weight` times its float `weightParameter`; targets are world points (`target`,
`Animator.setIKTarget`) or an entity followed by `Name` (`targetEntity`). Both animation systems
run it on the main thread after the parallel sampling. A graph's nodes replace the animator's
(run-time targets kept by name). The tab lists nodes with a settings grid (bones as
comma-separated names) and an Add IK menu; `animGraph.edit` `addIK` / `updateIK` / `removeIK`;
problems for bone counts, duplicate names, weight parameters and (with a preview) unknown bones.
Not done: no IK gizmos or target handles in the viewport (targets are typed or follow entities);
the aim's shared turn isn't exactly `weight` of the way for chains (it converges at weight 1);
two-bone and FABRIK keep bones' twist by shortest-arc turns only (no twist distribution, no
per-joint limits in FABRIK); foot placement uses one ray per foot (no toe/heel rays, so feet over
an edge use the ankle's ground), doesn't raise the pelvis for ground above the base, and its
locks snap instead of blending out; the preview has no physics, so foot placement does nothing
in the graph tab; bones IK moves that no clip drives start from the rest pose each frame (a game
moving them by hand is overwritten).

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
Ragdoll and IK (roadmap 1B): `ragdoll` {enabled, mass, strength, blendTime, bones: [{bone,
radius, swing, minAngle, maxAngle, mass}]} puts a `Ragdoll` on the prefab: bodies sized from the
body shapes per template (`CharacterRig.ragdollBones`; humanoid: hips, spine, head, upper and lower
arms and legs; ball joints with swing and twist at shoulders, hips, spine and neck, hinges at elbows
and knees), the file's entries changing single values. `ik` {footPlacement, lookAt, lookTarget,
handIK} puts IK nodes on the Animator ("Feet", "Look", "Hand.L" / "Hand.R";
`CharacterRig.ikNodes`). Importer version 2. The tab has a Ragdoll section (settings, a body
picker with its radius, limits and mass, Automatic to drop a change, Test Ragdoll / Get Up on a
physics floor in the preview, automatic bodies when the file has none) and an IK grid. Tools:
`character.ragdoll` (lists bodies with parents, limits and masses; enabled, mass, strength,
blendTime, bones merged by name, resetBones, remove; `test` drops the open tab's preview) and
`character.ik`. The `Ragdoll` component (EnginePhysics, Ragdoll.swift) works on any skeleton
with named bones: `animated` (kinematic hit boxes following the animation; ray hits report the
bone), `partial` (`hit`: dynamic bodies pulled back to the animation, `weight` of their pose shown
for `duration`), `full` (`goLimp`) and back (`getUp`: blends from the frozen physics pose over
`blendTime`, moving the root under the pelvis onto the ground). Bodies of one ragdoll never
collide (`BodyDescriptor.group`), the ECS sync leaves them alone, and a `CharacterController` on
the same entity ignores them. `Joint` / `JointDescriptor` gained `limits` (`JointLimits`: swing
cone, twist or hinge range) solved as one-sided soft rows. Visual Script nodes `ik.setTarget`,
`ik.setWeight`, `ragdoll.enable`, `ragdoll.applyImpulse`, `ragdoll.state`. Demo scene `ik`.
Not done: no viewport gizmos for ragdoll capsules or joint limits (the physics debug view shows
the bodies only in demos; the tab draws none); partial ragdolls drive bodies by velocity, not
joint motors, so strong hits on light limbs snap back quickly; no get-up animation (the pose
blends straight back, the root keeps its yaw rather than facing where the body lies); getting up
doesn't check that the spot under the pelvis is free; ragdoll state isn't networked or saved
mid-fall (the component saves its mode, not the bodies); the Test Ragdoll push is fixed (backwards,
0.6 m/s); quadruped, bird and blob ragdolls are rough (blob arms are spheres; bird wings have no
lift); `character.ragdoll {test}` needs the editor window. Play mode starts physics for a ragdoll even in a scene with no `Collider` (`World.needsPhysics`).

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
in GameRunner and exported games. 0.19 follow-up: nodes for `PathFollower`, `world.findPath` /
`bakeNavigation`, `world.gameUI`, timeline `holdFade` and `wait` dialogue keys, and
`DialoguePlayer.uiLayout` (Sources/Engine/VisualScript/VisualScriptBuilderLinkNodes.swift).

### Groom Builder (`.groom`)

Fur and hair any mesh can wear. The file (GroomBuild.swift, every key optional): `style` shell
(short fur, moss, velvet) | cards (hair, manes, feathers) | strands (reserved, draws as cards),
`length`, `lengthVariation`, `density` (strands or cards per cm²), `thickness` [root, tip],
`clumping`, `curl`, `frizz`, `gravity`, `stiffness`, `rootColor` / `tipColor` (sRGB, `FieldHints(srgb:)`),
`colorNoise`, `specular`, `mask` {texture, vertexPaint channel, parts, invert}, `combDirection`
("normal" | "followSurface" | [x,y,z]) with `combStrength`, `flowTexture`, `wind`, `shells`,
`cardWidth`, `cardSegments`, `strandsPerCard`, `lod` {shells, cards, distances}, `comb` and `cut`
strokes (spheres in the mesh's space, applied in order: what the brushes and agents write), `seed`,
`previewMesh`. Presets: shortFur, shaggyFur, velvet, moss, tufts (grass-like), straightHair,
ponytail, mane, feathers, each with a GPU budget in `groom.presets`.
How it draws: `GroomImporter` (EngineMeshBuild) makes `material/fur`, a `MaterialAsset` whose new
`fur` (`MaterialFur`) carries the whole groom plus its mask and flow maps downsampled to 128 px
(so fur geometry can be built anywhere), the full mask texture in the metallic-roughness slot, and
a preview prefab. A new `GroomRenderer` component (next to a `MeshRenderer`; EditorIcons "brush",
Add Component entry, registered by `SkeletalAnimation.registerComponents` and GamePlayer) names that
material. `SceneRenderer.syncGroomMeshes` builds the fur meshes from the entity's mesh the first
time a (mesh, groom) pair draws, keyed by a hash of the groom's geometry fields (GroomGeometry.swift):
a shell mesh (furry triangles; comb vector and length factor in the tangent; skin kept) and, for
cards, guide curves grown from area-weighted random roots (comb, gravity, curl, frizz, clumps
toward leaders) turned into strips, one mesh per card detail level. `RenderPrep` adds the fur
items after the entity's own: one instance per shell (its height in `params.y`), all copies of
one mesh and groom batching into one instanced draw (checked by GroomTests: 3 furry entities x 9
shells = one draw of 27 instances), plus an opaque undercoat shell in the root color that is all
that draws past the last `lod.distances` entry (the fur-tinted far look). Skinned fur shares its
entity's pose: `RenderList` now merges consecutive skinned items with the same skin, mesh and
material into one batch. Shaders (Metal and Vulkan from one GLSL source, the `fur` scene renders
byte-identical): `fur.glsl` in mesh_fur.vert / mesh_fur_skinned.vert (shells pushed out along the
normal, leaning by the comb, drooping by gravity, bent by wind and the springs; cards bent toward
their tips) and mesh_fur.frag (strands from a 3D cell grid on the bind-pose surface position, so
they stay put on animated meshes and need no UVs; clumping, curl, frizz, random lengths, the mask
texture's length per pixel; card strands with soft edges through alpha-to-coverage; wrapped diffuse
and two shifted Kajiya-Kay highlights, sun shadows, ambient or image-based light, clustered point
and spot lights, fog). Fur is left out of shadows and the depth prepass. Secondary motion: a damped
spring per joint (skinned) or per entity (rigid) pulled toward a lag behind its velocity
(RenderPrep+Fur.swift), plus `SceneEnvironment.wind` x the groom's `wind`.
Hooks: Mesh Builder parts take `groom`; `.character` files take `grooms` {region: groom} (skinned
with the body) and attachments take `groom` (its `mask.parts` picks the attachment's parts; a part's
own `groom` wins); terrain scatter rules take `groom` (every prop wears it; shell fur batches across
props). Shared changes: `PrefabNode.groom`, `Material.fur` / `MaterialAsset.fur`,
`MaterialTraits.fur`, `PipelineKey.fur`, `PipelineDescriptor.alphaToCoverage` (Metal
`isAlphaToCoverageEnabled`, Vulkan `alphaToCoverageEnable`), `RenderPrep.items` / `missingKeys`
settable inside EngineRendering, a "brush" Lucide icon.
Tools: `groom.new`, `.get`, `.set`, `.edit` (changes, addComb, addCut, clearStrokes), `.open`,
`.preview` (3/4 view and a close-up PNG), `.examples` (fox fur with strokes, long hair, moss patch),
`.presets`, `.apply` {groom, target: {entity} | {character, part} | {meshBuild, part}, remove}
(one undo step; warns about meshes without UVs, fur too dense for the triangle count and masks
that cover nothing, and reports the fur triangles). The Groom Builder tab grows the fur live on the
preview mesh in a breeze, with preset, comb direction, settings, mask and detail-level forms and
Mask / Restore / Length / Comb brushes that write `cut` / `comb` strokes (one undo step per drag).
Demo scene `fur`: a shaggy walking quadruped (skinned shells), a humanoid with hair cards on a scalp
riding its head bone (combed down, cut from the face) and three mossy rocks in the wind
(`FUR_VIEW=hair|creature|moss` close-ups, `FUR_OFF=1`, `FUR_WIND=0`).
Performance (M5, release, 1440p high, `ENGINE_SCREENSHOT_FRAME=200 ENGINE_VSYNC=0`, scene pass GPU
time with and without fur): the whole `fur` scene 2.75 -> 4.56 ms
(+1.8 ms, 5 more draws for 3 furry entities and 3 rocks: every shell of every rock is one draw);
creature close-up (filling most of the view, 32 shells) 2.77 -> 7.42 ms; hair close-up 2.57 -> 4.65 ms;
moss close-up 3.69 -> 5.53 ms (other builds were running, so take these as upper bounds). Preset
budgets (`groom.presets`) are set from these: shell fur costs about shells x covered pixels, so
fewer shells (`lod`) or shorter fur are the levers.
Gaps: the springs are per bone (skinned) or per entity (rigid), not per guide, and rigid springs
move only in X and Z; fur casts no shadows and doesn't shadow itself beyond darker roots; no
strand rendering (`strands` draws cards); the flow texture and mask texture shape the geometry per
vertex (128 px copies), the mask also cuts per pixel but the flow doesn't; mask textures go
through the texture importer's color space (an sRGB mask reads a little darker); card hair can
pass through the body (guides only stay above their root's tangent plane, no collision); shells on
low-poly or hard-edged meshes split at the edges (warned under 48 triangles); `MeshArray` copies
get no fur; a groom on a sculpt with several looks grows on each look's mesh separately; fur meshes
are built on the main thread the first frame they're used (a 5k-triangle character with cards takes
a few ms in release) and an edited groom rebuilds them; picking and the selection outline use the
base mesh; `groom.preview` shows the preview mesh only (not an arbitrary target); the brushes paint
only on the preview mesh, not on a character in the tab; the editor tab wasn't checked in the
running editor (tests drive the workspace).
### Physics Material (`.physmat`) and Physics v2

What a surface is made of: `friction`, `bounce`, `density`, `climbable`, `footstep` / `impact` /
`scrape` effects (`{sound, vfx, volume, pitch}`), `minImpactSpeed`, `minScrapeSpeed` and `pairs`
(effects against another material, used instead of either one's own); every key optional, unset
numbers keep the `Collider`'s. 17 built-ins (default, wood, metal, stone, concrete, brick, dirt,
grass, sand, mud, ice, rubber, glass, plastic, fabric, ceramic, climbingWall). The importer warns
about out-of-range values, effects naming nothing, missing sounds / VFX and unknown pair
materials. A `PhysicsSurface` component names a material on a collider's entity or an ancestor;
the ECS sync applies it, `physics.materialUnder` / `surfaceMaterialName(of:at:)` answer queries,
and play mode's "physics.surfaceEffects" system (EngineAssets, PhysicsSurfaceEffects.swift) plays
impacts (`PhysicsEvent.speed`), scrapes (`slidingContacts`) and footsteps (every 0.42 × height
walked, and on landing). Mesh Builder parts take `physicsMaterial` (else their `look` implies
one; importer version 13), terrain layers take `physicsMaterial` (chunk colliders get a per-cell
`PhysicsSurfaceGrid`; terrain importer version 5). Tools: `physicsMaterial.new`, `.get`, `.set`,
`.edit`, `.list`, `physics.materialAt`, `character.state`, `character.action`.
Physics v2 in EnginePhysics (CharacterControllerMoves.swift, PhysicsContinuous.swift): character
crouch / ledge grab / hang and shimmy / mantle / climb (`CharacterController.mode`,
`handTargets` for arm IK), jumps off rising platforms keep its speed, `RigidBody.continuous`
(swept after the solve; stops at the first surface, bounces by the pair's restitution).
Visual Script nodes `character.crouch`, `.grabLedge`, `.mantle`, `.drop`, `.state`,
`physics.materialAt`. Demo scene `physics2`; SampleGame `Physics2.scene` with a playtest.
Not done: no editor tab for `.physmat` (inspector `PhysicsSurface` and the tools only; no
`physicsMaterial.open`); pair overrides change only effects, not friction or bounce; per-area
materials only on the collider's own entity (terrain chunks), so a mesh build with several
materials under one root `Collider` uses the root's (most common) one; surfaces are found once
per sync, so a `.physmat` edited while playing applies after `physics.materials.reload()` (the
edit tools do it); continuous collision sweeps translation only with the start rotation, ignores
triangle-mesh moving bodies and sweeps against other bodies where they ended the step (two
fast bodies can pass each other); ledge detection uses rays (a ledge narrower than the probe spacing,
about 0.1 m vertically, can be missed; round tops and ledges at the very end of a wall may not
be found); the hang pose is fixed (hands at height × 1.1); auto-grab on a 2 m wall catches only
near the ground (the hang height); climbing has no ledge-to-climb or climb-to-hang transition,
no stamina, and works only on near-vertical walls; mantling moves without collision along its
path (start and end are checked); crouch, ledge and climb inputs aren't in `NetCharacterInput`
(the state is replicated, the input command still carries only move and jump);
`character.action` isn't recorded in playtests (drive characters with input actions); footstep
stride is a constant fraction of height, no animation-driven foot contacts; IK hand points are
exposed but nothing sets IK targets automatically.

### Combat and interaction (roadmap 3B)

Components in EngineScene (Gameplay/: Damage.swift, HitShapes.swift, Interaction.swift; every key
optional, registered by `GameplayComponents.register()`): `Health`, `Hurtbox`, `Hitbox`,
`Interactable`, `Interactor`, `Door`, `Lever`, `Container`, `Pickup`; `HitboxTrack` on
`Animator.hitboxes`. `World.applyDamage` / `heal` / `combat` (hit log, damage types),
`World.timeScale` / `hitStop`. Play systems in Engine (Gameplay/: `world.addGameplay`, added by the
editor's play mode and `ScenePlayback`): "interaction" and "interaction.devices" (`.update`),
"combat" and "gameFeel" (`.lateUpdate`). `.animgraph` `hitboxes` (the Animation Graph tab's
Hitboxes section, `animGraph.hitboxes`); `.character` `combat` (Character Builder Combat section,
`character.combat`; importer version 3). Tools `combat.inspect`, `combat.simulateHit`,
`combat.overlay`, `interaction.list`, `interaction.use`. Visual Script nodes in
VisualScriptCombatNodes.swift. Demo scene `combat`; SampleGame `Interact.scene` / `Combat.scene`
with playtests. The editor Game view outlines the focused interactable with a second
`SelectionOutlineRenderer` (`World.interactionFocus`).
Not done: damage types are code or per-world data (`World.combat.damageTypes`), not a project
file; `Health.resistances` and `Interactor.items` are dictionaries the inspector can edit but not
add keys to (scene files and `component.setField` can); hitbox tracks are keyed to a state's
normalized cycle, not to clip frames or events, and there is no hitbox gizmo or timeline strip in
the Animation Graph tab's preview (the Scene view overlay draws them while playing); fast swings
are tested once per frame with no sweep, so a thin blade can skip a small hurtbox at low frame
rates; the `.character` default hitbox is a fist sphere (no weapon attachment hitboxes); hit
stop freezes the whole world (no per-entity time scale); camera shake moves the active camera
entity and assumes nothing else edits it after `.lateUpdate` (3C's camera rigs should call or
replace `GameFeel` rather than fight it); hit flashes and the focus highlight both multiply
`MeshRenderer.tint`, so an entity flashed while highlighted can keep a wrong tint until its
highlight ends; exported games and GameRunner get the tint highlight and the prompt text but no
outline (`SceneRenderer.renderOffscreen` in EngineRendering has no hook for it); prompts are a
billboard `TextMesh` (no icon glyphs, no UI-layer prompt); the glyph is the action's first
keyboard or gamepad binding, switching on the last device pressed; doors swing their transform
only (a door with a static `Collider` doesn't move its body: make the panel kinematic); levers
toggle one target by name; containers hand over everything at once (no inventory UI);
`interaction.use` and `combat.simulateHit` aren't recorded in playtests (press input actions).
### Camera rigs (`CameraRig`)

Not a file type: a component (EngineRendering/Camera, CameraRig.swift and CameraRigSystem.swift),
ready for the action and platformer templates. A rig is a virtual camera: `mode` thirdPerson |
firstPerson | topDown | sideScroller | fixed, `target` (EntityRef; none follows the rig's own
entity), `targetOffset` (the followed point), `priority`, `enabled`, `camera` (which Camera it
moves: else its own entity's Camera, else the active camera with the lowest index), `fieldOfView`,
`blendTime`, `blendCurve` (an `Easing`), `distance` / `minDistance` / `maxDistance`,
`shoulderOffset`, `yaw` / `pitch` / `minPitch` / `maxPitch`, `autoRecenter` / `recenterDelay` /
`recenterTime`, `headBob` / `headBobFrequency` / `rotateTarget` (first person), `sideDirection` /
`deadZone` / `lookAhead` / `lookAheadTime` (side scroller), `collision` / `collisionRadius` /
`collisionMask` / `pullInTime` / `easeOutTime`, `positionDamping` (per world axis) /
`rotationDamping` (yaw, pitch), and input: `inputEnabled`, `orbitAction` / `zoomAction` /
`recenterAction` (named actions of `CameraRigSystem.actions`, default right stick, d-pad up/down,
right-stick click or middle mouse), `mouseOrbit` (right button held or mouse captured),
`orbitSpeed`, `mouseSensitivity`, `zoomSpeed`, `invertX` / `invertY`. Every key is optional;
`distance`, `pitch` and its limits and the damping are optional fields whose unset value is the
mode's (`CameraRigMode.defaults`). State the system writes (readable in playtests): `isLive`,
`blendWeight`, `cameraPosition`, `probeStart`, `probeEnd`, `probeHit`.
The "cameraRigs" system (`world.addCameraRigs(input:)`, `.lateUpdate`; added by the editor's play
mode, `ScenePlayback` (GameRunner, exported games)) evaluates every enabled rig each frame (standby
rigs too, so a blend follows both ends), picks the live one by priority, blends position (lerp),
rotation (slerp) and field of view over the new rig's `blendTime` (from the pose reached when a
blend is interrupted) and writes the output camera's `Transform` (in its parent's space) and
`fovY`. Switching = raising a priority: `world.activateCameraRig(_:blendTime:)`, the tool
`cameraRig.activate`, the node Activate Camera Rig. Collision sphere-casts from the followed point to
the wanted camera position, retrying past bodies of the target's subtree, its nearest
`CharacterController` / `Ragdoll` ancestor's subtree (ragdoll bones), the rig and the camera; the
camera pulls in within `pullInTime` (never more than a collision radius behind the hit) and eases
out over `easeOutTime`. Smoothing is `1 - exp(-dt / time)` everywhere (tested at 30 vs 144 fps).
Tools: `cameraRig.state`, `.activate`, `.setTarget` (undoable when editing). Visual Script nodes
(VisualScriptCameraNodes.swift): Activate Camera Rig, Set Camera Rig Target, Set Camera Rig Mode,
Live Camera Rig. Editor: Add Component entry (a third-person rig), "camera-rig" icon (rig entities
show as cameras in the hierarchy and get a billboard), Scene view gizmo (each rig's camera as a
small frustum, the followed point and the probe, red past a hit; selected rigs probe the scene's
colliders in edit mode), the Game view caption names the live rig. Demo scene `camerarigs`
(`CAMERARIGS_MODE=orbit|first|top|side`, C next rig, G probes); SampleGame `CameraRigs.scene` and
`Playtests/CameraRigs.playtest.json` (collision in front of a wall, a blend through a visual script).
Gaps: the component lives in EngineRendering (it needs physics queries and `Camera`), not
EngineScene; one output camera at a time (no split-screen brains yet); blends are straight lerps
(no arc around the target, and a blend can pass through a wall since collision is per rig, not on
the blended pose); first person has no collision or near-clip push-back, so a camera against a
wall can see through it; side-scroller dead zone and look-ahead are horizontal (look-ahead along
the view's right only, none vertically); auto-recenter needs the target's +Z to be its facing and
waits for it to move faster than 0.5 m/s; `rotateTarget` sets the target's local rotation (assumes
an unrotated parent); rig input actions live on the system (`CameraRigSystem.actions`), not in the
project's input settings or a visual script's `actions` (playtests declare them in `actions`);
mouse orbit in the editor's Game view needs the right button held (no capture toggle); the
Scene view gizmo's edit-mode probe keeps a second physics world in step with the scene; no camera
shake, no look-at framing of a second target, no per-rig post-FX; the editor features were checked
by tests, not in the running editor.
### Light probes (`ReflectionProbe`, `IrradianceVolume`, `lighting.bake`)

Baked indirect light for interiors (LightProbes.swift, SceneRenderer+Probes.swift, probes.glsl).
`ReflectionProbe` (every key optional): `size` (influence box, centered on the entity and turned with
it; scale ignored), `blendDistance`, `boxProjection`, `projectionSize` (0: the influence box),
`captureOffset`, `intensity`, `priority`, `nearClip`, `farClip`. PBR surfaces in the box reflect the
probe instead of the sky: the reflected ray is intersected with the projection box and the image
looked up from the capture point; overlapping probes blend (higher priority, then smaller boxes
first) and fade over `blendDistance`; what no probe covers keeps the sky's (or hemisphere's)
reflection; planar reflections still win on their plane. `IrradianceVolume`: `size`, `countX/Y/Z`
(probes at cell centers), `blendDistance`, `normalBias`, `viewBias`, `intensity`, `bounces`. Inside
the box, diffuse ambient light (Blinn-Phong and PBR, static and dynamic meshes) comes from the eight
probes around the point instead of the sky: L2 SH, trilinear, a smooth backface weight, probes found
inside geometry turned off (CPU rays at bake time: more than a quarter of 48 rays leaving through
back faces).
Baking is on the GPU, in the offscreen part of a frame, with the device's 2D textures only: six
90° faces per probe (the normal mesh pass and the sky, LDR c / (1 + c) like the planar pass, real
lights; the sun's shadows recentered on the probes' bounds), an equirectangular image
(probe_equirect.frag), then for reflection probes the environment's progressive GGX prefilter
(256 x 128 image, six roughness levels) and for irradiance probes the environment's SH projection
(32 px faces, 64 x 32 image), each stored into one storage buffer by probe_store.comp (images as
half floats, SH as 28 halves per probe). Bounce n is captured with bounce n-1's volumes lighting the
scene (black in the first); reflection probes are captured last, lit by the finished volumes. The
frame draws with the new buffer at once; it is read back, split per probe and cached by a key of
what shapes the bake (transform, box, counts, capture point, bounces; not intensity or biases) in
`Library/Lighting/*.lightprobe`; the cooker ships them (`AssetPackManifest.lighting`) and games
load them (`LightProbeBakeCache.forAssets`) instead of baking. `SceneRenderer.bakesProbesAutomatically`
(default on; off in the editor) bakes probes that have no bake when they appear; a moved probe keeps
its last bake (stale) until baked again. Metal and Vulkan bake bit-identical data (LightProbeTests)
and the `probes` scene renders identically.
Debug: `SceneRenderer.probeDebug` (`showsProbes`: a sphere per probe, mirror balls showing the
probe image, irradiance probes shaded by their SH, red inside geometry; `irradianceOnly`: every
surface shaded with its indirect diffuse light only), `LightProbeDebug.drawVolumes` (influence,
blend and projection boxes, volumes and probe points).
Tools: `lighting.bake` {show} (deferred, needs the window: probe counts, probes inside geometry,
bounces, milliseconds, warnings, cache files), `lighting.debug` {probes, volumes, irradianceOnly}.
View menu: Bake Lighting, Show Light Probes, Irradiance Only. Add Component entries and icons for
both components. Demo scene `probes`: a 12 x 3.6 x 10 m room lit through a 3 x 2 m window
(6 x 3 x 5 volume, two bounces, one room-sized reflection probe; `PROBES_OFF=1`,
`PROBES_VIEW=irradiance|window`, `PROBES_DEBUG=1`, `PROBES_BAKE_EACH_FRAME=1`; keys P, I, G, B).
Performance (M5, release, 1440p high, 4x MSAA, `ENGINE_SCREENSHOT_FRAME=300 ENGINE_VSYNC=0`, other
agents' builds running, so noisy): scene pass of `probes` 2.6-3.7 ms without probes, 7.9-9.5 ms
with them (a later, busier run: 4.8-5.0 ms against 14.2-14.8 ms) (about 1.5-3 ms the reflection probe, 4-5 ms the volume's eight-probe lookup; one probe
instead of eight costs almost nothing, so it is the per-pixel storage-buffer reads, not the math).
The bake of the scene (90 irradiance probes x 2 bounces + 1 reflection probe, about 1,700 passes):
0.3-3.5 s from request to read-back (the first includes pipeline creation); per capture face
0.03-0.1 ms GPU (scene pass at 32 or 128 px), equirect / prefilter 0.01-1.3 ms, stores ~0.
Gaps: no texture slot was free in the mesh shaders, so probes live in a storage buffer and are read
with manual bilinear filtering (that's the per-pixel cost above; a texture atlas, or fewer SH
reads, e.g. per-vertex or per-object SH for small objects, would be cheaper); fur, particles and
decals, material graphs and terrains still use the sky's ambient light, not the probes (the
probe shading lives in separate fragment variants, mesh(_paint)(_mask)_probes.frag, used only
while a frame has probes, because adding any code to the mesh shader made Metal's fast math move
a few pixels of existing scenes by one level; graph materials would need the same variants from
MaterialGraphCompiler); captures include every mesh (dynamic
objects too) and no particles; reflection probe resolution is fixed (128 px faces), bakes are
uncompressed (~350 KB per reflection probe, 64 bytes per irradiance probe); no realtime / per-frame
probe updates (bake again, or `PROBES_BAKE_EACH_FRAME`-style requests); the probe key doesn't
include the scene, so a cached bake stays in use after the room changes until baked again (the
cooker ships every file in Library/Lighting, stale ones too); the editor bakes the viewport's world
(play world while playing) and the bake waits until that world is gathered; the inside-geometry
test needs mesh triangles on the CPU (skinned meshes are ignored); volumes clamp counts to 64 per
axis; the editor's View menu entries weren't clicked in the running editor (tests drive the commands).

## Follow-ups

Connections between builders: all of the 0.15.0 list is done in 0.16.0 (`.sprite` tile sets,
`.ui` dialogue boxes, a Timeline dialogue track, Visual Script nodes for the builders, graph
materials on terrain layers and decals, retargeted glTF character clips and one clip loader).
The Visual Script nodes still open after 0.16.0 (`PathFollower`, `world.gameUI`, `world.findPath`,
timeline `holdFade` and dialogue keys, `DialoguePlayer.uiLayout`) were added in 0.19.

Agent playtesting (docs/Playtesting.md) checks builders' demo scenes and templates: record a
session with `playtest.start` … `playtest.save`, commit the `.playtest.json` next to the project
and run `GameRunner <module | none> --playtest <folder>` in CI. `input.action` presses the input
actions visual script graphs declare (`actions`), so graphs that read input should declare them
rather than read keys directly. Not done yet: screenshots in headless runs (nothing renders), image
assertions, and recording edits made to the live world (`component.setField`).

Engine gaps the builders ran into:

- 2D physics reads each collider's own `Transform` and ignores parents, so a placed tilemap
  keeps its colliders at the origin (`world.spawnTilemapColliders(map, at:)` works around it). Fixed in 0.16.0.
- No runtime game UI layer: GameRunner and built games show layouts and the dialogue box only
  when game code adds them. Added in 0.16.0 (`world.gameUI`).
- The cooker misses files referenced by path: layout images, timeline sounds and effects by
  path, and tilemap JSON. Fixed in 0.16.0 (`CookPlan.pathReferences`, `keepsSource`), except
  `.dialogue` references and components naming a layout or path by plain path, fixed in 0.19
  (`.dialogue` ships as written and follows references; scenes and prefabs follow plain paths).
- No navigation mesh (0.16.0 adds a grid navigator, `world.findPath`); the Tag component is
  added in 0.16.0.
- `asset.import` over MCP stdio hung on its reply when the source file was inside the project
  folder. Rechecked in 0.19 (stdio, headless and windowed): replies in under half a second; the
  0.16.0 per-frame load pump fixed it.
- Builder color fields showed sRGB file colors as linear. Fixed in 0.19 with `FieldHints.srgb`
  (Mesh Builder part color and glow, Path profiles and pieces, terrain layers, procedural textures,
  Timeline fade keys, Tilemap and VFX backgrounds, character recolors); Character's proxy
  conversion stays.
- Failing on main: `ParityTests.everyUIElementRunsACommandThatIsATool` (fixed in 0.17: the
  console's Copy button runs `log.read`); `MCPToolSchemaTests.subscribedResourcesReportUpdates`
  depended on the wall-clock resource-check throttle and is deterministic since 0.19
  (`EditorMCP.resourceCheckInterval`).
- Every builder tab was checked in the running editor in 0.16.0; panels behind a selection were
  checked by tests only. `builder.select` (0.19) selects inside the Mesh Builder, Animation Graph,
  Behavior Tree, Dialogue and Visual Script tabs; the other tabs don't take part yet.
