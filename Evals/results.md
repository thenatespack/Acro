# Eval results

Claude played the agent for each scenario: it read the tool list (docs/MCPTools.md) and drove the
editor through MCP tools only, first against the headless editor (`EvalScenarioTests`), then replayed
the same transcripts against the windowed editor over HTTP (`run-window.py`, Metal) for the
screenshot checks. The transcripts in `scenarios/` are those runs. 2026-10-31.

| Scenario | Scene checks (headless) | Screenshot (window) | Tool calls: setup + transcript, before -> after |
|---|---|---|---|
| 01 level with a floor, three lit textured crates and a camera | 8/8 pass (one new: the sun is aimed) | pass by eye: `results/level-with-crates-window.png` (three plank-textured crates on a floor, tops lit, shadows to one side) | 4 + 6 -> 2 + 5 |
| 02 import a .glb, red metal materials, save | 3/3 pass | none | 4 + 7 -> 2 + 6 |
| 03 playtest: walk forward until hitting a wall | 2/2 pass (stops at z ≈ -0.25, the wall's face; the step reports `reason: "stopped"`) | pass by eye: `results/walk-to-wall-window.png` (the player cube against the wall) | 0 + 13 -> 0 + 9 |
| 04 find and fix the entity with a missing mesh | 3/3 pass | none | 0 + 5 -> 0 + 5 (nothing to shorten) |

The transcripts were re-recorded with the tools below (#653) and re-run headless and, for 01 and 03,
against the window (Metal). The first run's numbers are the "before".

Every mutating call shows in the activity log, and every undo step it left is labeled "AI: …".

## Missing tools and confusing schemas found

Findings 2 to 8 were addressed in #653 (finding 1 and 9 earlier); how:

1. **Missing meshes were invisible** (04). Nothing reported a `MeshRenderer` naming a mesh that
   doesn't exist; an agent had to `entity.get` every renderer and guess which keys are valid.
   Fixed: `diagnostics.get` returns `missingMeshes` (entity, name, key).
2. **Ids versus references** (01, 02). *Addressed:* an `AssetID` argument also reads `asset:<id>` and
   an `AssetReference` argument also reads a bare id, so every tool takes both (the schemas say so;
   a reference with a `#object` where only a file is meant is still an error). Results still return ids
   (`asset.newMaterial`, `asset.extractMaterials`) or references (`objects[].reference`). Inside
   `edit.batch`, `"asset:{$0.asset}"` interpolates a result into a longer string (whole-string
   `"$0.asset"` still keeps its type).
3. **Rotations are quaternions only** (01). *Addressed:* `transform.lookAt {entity, target, up?}`
   (target an entity id or a world point; under a rotated parent the world direction is what is aimed;
   straight along `up` picks another up) and `{"eulerDegrees": [x, y, z]}` wherever a quaternion
   field is set (`component.setField`, local or world space; Z, then X, then Y). `transform.set` keeps
   taking quaternions (the gizmo's command). The reference run aims the sun with `lookAt`: the crates'
   tops are lit now (`results/level-with-crates-window.png`).
4. **No empty scene** (01, 02). *Addressed:* `scene.new {template: "empty"}` (default `"starter"`);
   setup drops from four calls (new, hierarchy, delete every root) to two.
5. **Imported materials are read-only** (02). *Addressed:* `material.set` on a model's id fails with
   "... isn't a .material file, so its materials are read-only. To edit a model's materials, run
   asset.extractMaterials {asset: ...}".
6. **`material.set` replaced the whole material** (02). *Addressed:* it merges: fields left out keep
   their current values, `null` clears a texture, unknown field names are an error listing the valid
   ones, and `reset: true` starts from the default material (the old behavior). Undo restores the
   previous file as before. The inspector keeps replacing whole materials (typed `MaterialAsset` call).
7. **Playtesting is polled** (03). *Addressed:* `play.step {until: {entity, stopped: true, epsilon?,
   window?}, maxFrames?}` runs until the entity's world position moved less than `epsilon` (default
   0.001) over the last `window` frames (default 10), at most `maxFrames` (default 600). The result is
   the play state plus `stepped` (frames run) and `reason`: `"frames"`, `"stopped"`, `"maxFrames"`
   (still moving) or `"entity removed"`. Scenario 03 went from three step/get rounds to one call.
8. **`scene.save` needed `confirm: true` every time** (02). *Addressed:* `scene.save` and `scene.saveAs`
   are still marked destructive, but `confirm` is optional in their schemas and required only when
   the target is an existing file that isn't the scene's own (inside `edit.batch` too). New files and
   the scene's own file need none. `scene.new` and `scene.open` still always ask.
9. **Screenshots need the window**; headless runs grade scenes only. `run-window.py` covers the
   screenshot checks against a running editor.

Still open: agents have to call `asset.get` to find a texture's reference after `asset.import`
(import returns paths only); `transform.set` has no Euler form; `entity.get`'s world transform
lags a frame behind an edit made in the same batch (it reads the propagated transform).

The window replay of scenarios 02 and 04 in the same editor session as 01 and 03 failed at setup
(the project already existed and 03 had left the game playing), which is why a fresh folder per
scenario is recommended; headless, each scenario gets its own editor.
