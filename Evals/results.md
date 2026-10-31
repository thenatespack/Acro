# Eval results

Claude played the agent for each scenario: it read the tool list (docs/MCPTools.md) and drove the
editor through MCP tools only, first against the headless editor (`EvalScenarioTests`), then replayed
the same transcripts against the windowed editor over HTTP (`run-window.py`, Metal) for the
screenshot checks. The transcripts in `scenarios/` are those runs. 2026-10-31.

| Scenario | Scene checks (headless) | Screenshot (window) |
|---|---|---|
| 01 level with a floor, three lit textured crates and a camera | 7/7 pass | pass by eye: `results/level-with-crates-window.png` (three plank-textured crates on a floor) |
| 02 import a .glb, red metal materials, save | 3/3 pass | — (none) |
| 03 playtest: walk forward until hitting a wall | 2/2 pass (stops at z ≈ -0.25, the wall's face) | pass by eye: `results/walk-to-wall-window.png` (the player cube against the wall) |
| 04 find and fix the entity with a missing mesh | 3/3 pass | — (none) |

Every mutating call shows in the activity log, and every undo step it left is labeled "AI: …".

## Missing tools and confusing schemas found

1. **Missing meshes were invisible** (04). Nothing reported a `MeshRenderer` naming a mesh that
   doesn't exist; an agent had to `entity.get` every renderer and guess which keys are valid.
   Fixed here: `diagnostics.get` returns `missingMeshes` (entity, name, key).
2. **Ids versus references** (01, 02). `asset.newMaterial` and `asset.extractMaterials` return bare
   asset ids, `material.set` takes a bare id, but `material.get`, `asset.assign` and
   `asset.instantiate` take `asset:<id>` references. The agent has to build strings, and inside
   `edit.batch` it can't: `"$n.path"` substitutes whole strings only. Suggest: accept both forms
   everywhere (or return references), and allow `"asset:{$n.asset}"` in batches.
3. **Rotations are quaternions only** (01). Aiming a camera or a light means computing a
   quaternion; the reference run left the sun at its default orientation, so the crates' tops are
   unlit in the screenshot. Suggest `transform.lookAt {entity, target}` or Euler degrees in
   `component.setField` for rotations.
4. **No empty scene** (01, 02). `scene.new` makes the starter scene; starting clean needs
   `scene.hierarchy` + `entity.delete` of every root. Suggest `scene.new {template: "empty"}`.
5. **Imported materials are read-only** (02). The agent has to know to `asset.extractMaterials`
   first (the doc says so, but `material.set` on an imported material could name that tool in its error).
6. **`material.set` replaces the whole material**: fields left out go back to their defaults
   rather than keeping the current values. A merge (or `previous`-style patch) would be safer.
7. **Playtesting is polled** (03). The agent alternates `play.step {frames: 60}` and `entity.get`
   until the position stops changing. `play.step {until: {entity, stopped: true}}` or a
   `maxFrames` with a condition would save round trips.
8. **`scene.save` needs `confirm: true` every time** (02): it is marked destructive because it
   overwrites a file, even when that file is the scene's own. Consider requiring `confirm` only when
   saving over a different file.
9. **Screenshots need the window**; headless runs grade scenes only. `run-window.py` covers the
   screenshot checks against a running editor.

The window replay of scenarios 02 and 04 in the same editor session as 01 and 03 failed at setup
(the project already existed and 03 had left the game playing), which is why a fresh folder per
scenario is recommended; headless, each scenario gets its own editor.
