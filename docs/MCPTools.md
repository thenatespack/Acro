# Editor MCP tool reference

Generated from the editor's command registry by `swift run Editor --mcp-tool-docs > docs/MCPTools.md`;
`swift test --filter ToolReferenceTests` fails when it is out of date. Every editor command is a tool
named by its id (see README › Use the editor › AI control). 301 tools.

Hints: **read-only** (changes nothing), **undoable** (one undo step, labeled "AI: …" when an MCP client
made it), **destructive** (can lose work undo can't bring back; needs `confirm: true`), **idempotent**
(running it again changes nothing more), **deferred** (answers after a frame or more). Types: entity ids
are 32-hex strings, assets `asset:<id>[#object]` references, vectors `[x, y, z]` number arrays, `?` marks
optional arguments.

| Namespace | Tools |
|---|---|
| `activity` | [`activity.clear`](#activityclear), [`activity.list`](#activitylist), [`activity.revert`](#activityrevert) |
| `ai` | [`ai.settings`](#aisettings) |
| `animGraph` | [`animGraph.assign`](#animgraphassign), [`animGraph.bones`](#animgraphbones), [`animGraph.clipEvents`](#animgraphclipevents), [`animGraph.edit`](#animgraphedit), [`animGraph.get`](#animgraphget), [`animGraph.hitboxes`](#animgraphhitboxes), [`animGraph.new`](#animgraphnew), [`animGraph.open`](#animgraphopen), [`animGraph.set`](#animgraphset), [`animGraph.setClipEvents`](#animgraphsetclipevents) |
| `asset` | [`asset.applySettings`](#assetapplysettings), [`asset.assign`](#assetassign), [`asset.delete`](#assetdelete), [`asset.extractMaterials`](#assetextractmaterials), [`asset.get`](#assetget), [`asset.import`](#assetimport), [`asset.instantiate`](#assetinstantiate), [`asset.list`](#assetlist), [`asset.move`](#assetmove), [`asset.newFolder`](#assetnewfolder), [`asset.newMaterial`](#assetnewmaterial), [`asset.newProceduralTexture`](#assetnewproceduraltexture), [`asset.reimport`](#assetreimport), [`asset.rename`](#assetrename), [`asset.select`](#assetselect), [`asset.setProceduralTexture`](#assetsetproceduraltexture), [`asset.waitForImports`](#assetwaitforimports) |
| `behavior` | [`behavior.assign`](#behaviorassign), [`behavior.debug`](#behaviordebug), [`behavior.edit`](#behavioredit), [`behavior.get`](#behaviorget), [`behavior.navigation`](#behaviornavigation), [`behavior.new`](#behaviornew), [`behavior.open`](#behavioropen), [`behavior.set`](#behaviorset) |
| `builder` | [`builder.select`](#builderselect) |
| `cameraRig` | [`cameraRig.activate`](#camerarigactivate), [`cameraRig.setTarget`](#camerarigsettarget), [`cameraRig.state`](#camerarigstate) |
| `character` | [`character.action`](#characteraction), [`character.bones`](#characterbones), [`character.combat`](#charactercombat), [`character.edit`](#characteredit), [`character.get`](#characterget), [`character.ik`](#characterik), [`character.new`](#characternew), [`character.open`](#characteropen), [`character.ragdoll`](#characterragdoll), [`character.set`](#characterset), [`character.state`](#characterstate) |
| `combat` | [`combat.inspect`](#combatinspect), [`combat.overlay`](#combatoverlay), [`combat.simulateHit`](#combatsimulatehit) |
| `component` | [`component.add`](#componentadd), [`component.remove`](#componentremove), [`component.setField`](#componentsetfield), [`component.types`](#componenttypes) |
| `diagnostics` | [`diagnostics.get`](#diagnosticsget) |
| `dialogue` | [`dialogue.edit`](#dialogueedit), [`dialogue.get`](#dialogueget), [`dialogue.new`](#dialoguenew), [`dialogue.open`](#dialogueopen), [`dialogue.play`](#dialogueplay), [`dialogue.set`](#dialogueset) |
| `edit` | [`edit.batch`](#editbatch), [`edit.beginBatch`](#editbeginbatch), [`edit.endBatch`](#editendbatch), [`edit.redo`](#editredo), [`edit.undo`](#editundo) |
| `entity` | [`entity.create`](#entitycreate), [`entity.delete`](#entitydelete), [`entity.duplicate`](#entityduplicate), [`entity.find`](#entityfind), [`entity.get`](#entityget), [`entity.rename`](#entityrename), [`entity.reparent`](#entityreparent) |
| `file` | [`file.openInCodeEditor`](#fileopenincodeeditor), [`file.reveal`](#filereveal) |
| `files` | [`files.list`](#fileslist), [`files.newScene`](#filesnewscene), [`files.open`](#filesopen) |
| `game` | [`game.build`](#gamebuild), [`game.info`](#gameinfo), [`game.load`](#gameload), [`game.reload`](#gamereload), [`game.unload`](#gameunload) |
| `gridMap` | [`gridMap.edit`](#gridmapedit), [`gridMap.erase`](#gridmaperase), [`gridMap.fill`](#gridmapfill), [`gridMap.get`](#gridmapget), [`gridMap.new`](#gridmapnew), [`gridMap.open`](#gridmapopen), [`gridMap.paint`](#gridmappaint), [`gridMap.set`](#gridmapset) |
| `groom` | [`groom.apply`](#groomapply), [`groom.edit`](#groomedit), [`groom.examples`](#groomexamples), [`groom.get`](#groomget), [`groom.new`](#groomnew), [`groom.open`](#groomopen), [`groom.presets`](#groompresets), [`groom.preview`](#groompreview), [`groom.set`](#groomset) |
| `input` | [`input.action`](#inputaction), [`input.actions`](#inputactions), [`input.clear`](#inputclear), [`input.gamepad`](#inputgamepad), [`input.inject`](#inputinject), [`input.state`](#inputstate) |
| `interaction` | [`interaction.list`](#interactionlist), [`interaction.use`](#interactionuse) |
| `launcher` | [`launcher.dismiss`](#launcherdismiss), [`launcher.settings`](#launchersettings), [`launcher.show`](#launchershow) |
| `layout` | [`layout.reset`](#layoutreset) |
| `log` | [`log.clear`](#logclear), [`log.read`](#logread) |
| `material` | [`material.get`](#materialget), [`material.set`](#materialset) |
| `materialGraph` | [`materialGraph.assign`](#materialgraphassign), [`materialGraph.edit`](#materialgraphedit), [`materialGraph.get`](#materialgraphget), [`materialGraph.new`](#materialgraphnew), [`materialGraph.nodes`](#materialgraphnodes), [`materialGraph.open`](#materialgraphopen), [`materialGraph.set`](#materialgraphset) |
| `meshBuild` | [`meshBuild.edit`](#meshbuildedit), [`meshBuild.examples`](#meshbuildexamples), [`meshBuild.get`](#meshbuildget), [`meshBuild.new`](#meshbuildnew), [`meshBuild.open`](#meshbuildopen), [`meshBuild.preview`](#meshbuildpreview), [`meshBuild.set`](#meshbuildset) |
| `navigation` | [`navigation.bake`](#navigationbake), [`navigation.overlay`](#navigationoverlay), [`navigation.query`](#navigationquery) |
| `net` | [`net.overlay`](#netoverlay), [`net.setConditions`](#netsetconditions), [`net.start`](#netstart), [`net.stats`](#netstats), [`net.stop`](#netstop), [`net.view`](#netview) |
| `panel` | [`panel.close`](#panelclose), [`panel.dock`](#paneldock), [`panel.focus`](#panelfocus), [`panel.list`](#panellist), [`panel.open`](#panelopen) |
| `path` | [`path.edit`](#pathedit), [`path.flattenTerrain`](#pathflattenterrain), [`path.get`](#pathget), [`path.new`](#pathnew), [`path.open`](#pathopen), [`path.sample`](#pathsample), [`path.set`](#pathset) |
| `physics` | [`physics.materialAt`](#physicsmaterialat) |
| `physicsMaterial` | [`physicsMaterial.edit`](#physicsmaterialedit), [`physicsMaterial.get`](#physicsmaterialget), [`physicsMaterial.list`](#physicsmateriallist), [`physicsMaterial.new`](#physicsmaterialnew), [`physicsMaterial.set`](#physicsmaterialset) |
| `play` | [`play.pause`](#playpause), [`play.setTimeScale`](#playsettimescale), [`play.start`](#playstart), [`play.state`](#playstate), [`play.step`](#playstep), [`play.stop`](#playstop), [`play.toggle`](#playtoggle) |
| `playtest` | [`playtest.assert`](#playtestassert), [`playtest.result`](#playtestresult), [`playtest.run`](#playtestrun), [`playtest.save`](#playtestsave), [`playtest.start`](#playteststart), [`playtest.stop`](#playteststop) |
| `postfx` | [`postfx.assign`](#postfxassign), [`postfx.edit`](#postfxedit), [`postfx.get`](#postfxget), [`postfx.new`](#postfxnew), [`postfx.open`](#postfxopen), [`postfx.set`](#postfxset) |
| `prefab` | [`prefab.apply`](#prefabapply), [`prefab.create`](#prefabcreate), [`prefab.createVariant`](#prefabcreatevariant), [`prefab.overrides`](#prefaboverrides), [`prefab.revert`](#prefabrevert), [`prefab.unpack`](#prefabunpack) |
| `project` | [`project.close`](#projectclose), [`project.new`](#projectnew), [`project.open`](#projectopen), [`project.recent.list`](#projectrecentlist), [`project.recent.locate`](#projectrecentlocate), [`project.recent.pin`](#projectrecentpin), [`project.recent.remove`](#projectrecentremove), [`project.recent.reveal`](#projectrecentreveal) |
| `scene` | [`scene.discardRecovery`](#scenediscardrecovery), [`scene.hierarchy`](#scenehierarchy), [`scene.listRecovery`](#scenelistrecovery), [`scene.new`](#scenenew), [`scene.open`](#sceneopen), [`scene.raycast`](#sceneraycast), [`scene.recover`](#scenerecover), [`scene.save`](#scenesave), [`scene.saveAs`](#scenesaveas) |
| `script` | [`script.list`](#scriptlist), [`script.new`](#scriptnew), [`script.open`](#scriptopen), [`script.save`](#scriptsave) |
| `selection` | [`selection.clear`](#selectionclear), [`selection.get`](#selectionget), [`selection.set`](#selectionset) |
| `settings` | [`settings.get`](#settingsget), [`settings.setEditor`](#settingsseteditor), [`settings.setProject`](#settingssetproject) |
| `sfx` | [`sfx.edit`](#sfxedit), [`sfx.get`](#sfxget), [`sfx.new`](#sfxnew), [`sfx.open`](#sfxopen), [`sfx.play`](#sfxplay), [`sfx.set`](#sfxset) |
| `sprite` | [`sprite.draw`](#spritedraw), [`sprite.edit`](#spriteedit), [`sprite.get`](#spriteget), [`sprite.importSheet`](#spriteimportsheet), [`sprite.new`](#spritenew), [`sprite.open`](#spriteopen), [`sprite.set`](#spriteset) |
| `stats` | [`stats.get`](#statsget) |
| `table` | [`table.edit`](#tableedit), [`table.exportCsv`](#tableexportcsv), [`table.get`](#tableget), [`table.importCsv`](#tableimportcsv), [`table.new`](#tablenew), [`table.open`](#tableopen), [`table.query`](#tablequery), [`table.set`](#tableset) |
| `terrain` | [`terrain.edit`](#terrainedit), [`terrain.get`](#terrainget), [`terrain.new`](#terrainnew), [`terrain.open`](#terrainopen), [`terrain.paint`](#terrainpaint), [`terrain.scatter`](#terrainscatter), [`terrain.sculpt`](#terrainsculpt), [`terrain.set`](#terrainset) |
| `tilemap` | [`tilemap.edit`](#tilemapedit), [`tilemap.erase`](#tilemaperase), [`tilemap.fill`](#tilemapfill), [`tilemap.get`](#tilemapget), [`tilemap.new`](#tilemapnew), [`tilemap.open`](#tilemapopen), [`tilemap.paint`](#tilemappaint), [`tilemap.set`](#tilemapset) |
| `timeline` | [`timeline.edit`](#timelineedit), [`timeline.get`](#timelineget), [`timeline.new`](#timelinenew), [`timeline.open`](#timelineopen), [`timeline.sample`](#timelinesample), [`timeline.set`](#timelineset) |
| `tool` | [`tool.set`](#toolset), [`tool.snapping`](#toolsnapping) |
| `transform` | [`transform.lookAt`](#transformlookat), [`transform.set`](#transformset) |
| `ui` | [`ui.click`](#uiclick), [`ui.drag`](#uidrag), [`ui.find`](#uifind), [`ui.hover`](#uihover), [`ui.key`](#uikey), [`ui.scroll`](#uiscroll), [`ui.snapshot`](#uisnapshot), [`ui.type`](#uitype) |
| `uiLayout` | [`uiLayout.edit`](#uilayoutedit), [`uiLayout.get`](#uilayoutget), [`uiLayout.new`](#uilayoutnew), [`uiLayout.open`](#uilayoutopen), [`uiLayout.place`](#uilayoutplace), [`uiLayout.set`](#uilayoutset) |
| `vfx` | [`vfx.edit`](#vfxedit), [`vfx.get`](#vfxget), [`vfx.new`](#vfxnew), [`vfx.open`](#vfxopen), [`vfx.set`](#vfxset) |
| `view` | [`view.animateInEditMode`](#viewanimateineditmode), [`view.appearance`](#viewappearance), [`view.frameSelection`](#viewframeselection), [`view.gameCamera`](#viewgamecamera), [`view.goTo`](#viewgoto), [`view.home`](#viewhome), [`view.pick`](#viewpick), [`view.scenePostFX`](#viewscenepostfx), [`view.screenshot`](#viewscreenshot) |
| `vscript` | [`vscript.attach`](#vscriptattach), [`vscript.edit`](#vscriptedit), [`vscript.get`](#vscriptget), [`vscript.new`](#vscriptnew), [`vscript.nodes`](#vscriptnodes), [`vscript.open`](#vscriptopen), [`vscript.set`](#vscriptset), [`vscript.step`](#vscriptstep), [`vscript.validate`](#vscriptvalidate) |

## activity

### `activity.clear`

**Clear Activity** · _idempotent_

Empties the AI activity log (the undo history stays).

Arguments: none.

### `activity.list`

**Activity** · _read-only_, _idempotent_

The AI activity log: every MCP call with its arguments, outcome, result summary and the undo step it recorded ("AI: …"), as the Activity panel lists it.

Arguments:

- `limit?`: integer
- `since?`: integer

Result:

- `entries`: [{arguments: string, id: integer, outcome: string, time: number, tool: string}]

### `activity.revert`

**Revert AI Changes**

Undoes the AI clients' steps on top of the undo history: all consecutive "AI: …" steps (the last AI batch), or down to the step of activity `entry`. Refused when a step of the user's is in the way. edit.redo brings them back.

Arguments:

- `entry?`: integer

Result:

- `undone`: [string]

## ai

### `ai.settings`

**AI Settings** · _idempotent_

What AI clients may do: `readOnly` (only perception and query tools), `askBeforeDestructive` (the editor asks the user before deleting files or discarding changes) and `httpEnabled` (the localhost HTTP server). Returns the settings. Over MCP it only reads them: they change in the editor (the Activity panel) or the prefs file.

Arguments:

- `askBeforeDestructive?`: boolean
- `httpEnabled?`: boolean
- `readOnly?`: boolean

Result:

- `askBeforeDestructive?`: boolean
- `httpEnabled?`: boolean
- `readOnly?`: boolean

## animGraph

### `animGraph.assign`

**Assign Animation Graph** · _undoable_

Puts an Animator playing an .animgraph on an entity (default: the selection), usually a placed model's root: its targets are the entity and its descendants depth first, which is how imported clips address a model's nodes. Replaces an Animator already there. Undoable. The animator plays in play mode and in exported games, and follows the graph file when it changes. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `path?`: string

Result:

- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `graph`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `targets`: integer
- `warnings`: [string]

### `animGraph.bones`

**Match Animation Bones** · _read-only_, _idempotent_

Shows how a clip's bones pair with a model's when retargeted by name: matched pairs, model bones left at rest, and animated clip bones that drive nothing, under the graph's `retarget` options (or `retarget` given here). Use it to write a `boneMap` before setting `retarget` with animGraph.edit. `model` (a glTF file, prefab or .character) defaults to the graph's preview.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `clip`: string
- `model?`: string
- `path?`: string
- `retarget?`: {boneMap?: object, matchNames?: boolean, rootScale?: number, rotation?: "copy" \| "local" \| "world", sampleRate?: number, translation?: "none" \| "root" \| "all"}

Result:

- `clipBones`: [string]
- `matched`: object
- `modelBones`: [string]
- `needsRetarget`: boolean
- `unmatchedClipBones`: [string]
- `unmatchedModelBones`: [string]

### `animGraph.clipEvents`

**Get Clip Events** · _read-only_, _idempotent_

Lists an animation clip's events ({time (seconds), name}, by time) and its duration. Animators report events as their clip plays past them (FiredAnimationEvent, VisualScript animation events); `editable` says whether animGraph.setClipEvents can change them.

Arguments:

- `clip`: string

Result:

- `clip`: string
- `duration`: number
- `editable`: boolean
- `events`: [{name: string, time: number}]

### `animGraph.edit`

**Edit Animation Graph** · _undoable_

Changes part of an .animgraph file in one undoable step, in this order: removeTransitions (indices), removeStates, removeParameters, removeLayers, parameters (add or replace by name), addStates, updateStates (name → fields; "name" renames everywhere), addTransitions, updateTransitions (index → fields), addLayers, updateLayers, initialState, preview, retarget / removeRetarget, removeIK, addIK, updateIK (name → fields). With `level` (a sub-state machine's path, e.g. "Combat"), the state and transition edits and initialState apply inside that machine, and its transitions may also go to states of enclosing levels (by name). Clip paths become asset references. Returns the states, numbered transitions, parameters and problems. An animation graph (.animgraph) is an Animator state machine; every key is optional: `preview` (the model prefab the builder previews on, an asset reference or path), `retarget` {boneMap {source bone: target bone}, matchNames (default true), rotation world|local|copy, translation root|none|all, rootScale, sampleRate} (plays clips made for another skeleton by matching bones by name; see animGraph.bones), `parameters` [{name, type float|bool|trigger, default}], `states` [{name, clip (one clip) or blend {parameter (a float), clips [{clip, position}]} (a 1D blend space; add parameterY (a second float) and give each clip a `y` for a 2D one, e.g. moveX / moveY for strafing), speed, speedParameter (a float multiplying speed), loops, position [x,y] (node position in the editor)}], `transitions` [{from (a state; omit or "*" for any state), to, conditions [{parameter, test greater|less|isTrue|isFalse|triggered, value}], exitTime (normalized time of the source state, e.g. 0.9), duration (crossfade seconds), canTransitionToSelf}] (checked in order, the first that applies fires), `layers` [{name, clip, weight, speed, referenceTime, blend additive|override (override replaces the bones the clip animates), mask [bone names: the layer only touches their subtrees]}], `initialState`, `ik` [{name, type twoBoneIK|aim|chainIK|footPlacement, bones (twoBoneIK: root, middle, end; aim and chainIK: root to tip), weight 0-1, weightParameter (a float multiplying the weight), target [x,y,z] (world) or targetEntity (an entity's Name), pole [x,y,z] (twoBoneIK: the way the middle joint bends, character space), aimAxis (aim: the last bone's axis that points, default [0,0,1]), maxAngle (aim, degrees per bone), iterations / tolerance (chainIK), legs [[hip, knee, ankle]…] and pelvis (footPlacement: rays against physics, the pelvis drops, feet align and lock), rayHeight, maxStep, alignFeet, lockFeet}] run in order after the states and layers. A state with `machine` {states, transitions, initialState} instead of a clip is a sub-state machine: entering it enters its initial state, its own transitions leave from any state inside, and transitions inside may go to states outside it by name (edit inside with animGraph.edit `level`). Clips are imported glTF clips: "asset:<id>#animation/<name>" or "Models/hero.glb#animation/Walk" (paths are turned into references). Put it on a model with animGraph.assign; scene animators follow the file when it changes. Undoable (one step; edit.undo reverts it).

Arguments:

- `addIK?`: [{aimAxis?: number[3], alignFeet?: boolean, bones?: [string], iterations?: integer, legs?: [[string]], lockFeet?: boolean, mask?: integer, maxAngle?: number, maxStep?: number, name?: string, pelvis?: string, plantHeight?: number, pole?: number[3], rayHeight?: number, target?: number[3], targetEntity?: string, tolerance?: number, type?: "twoBoneIK" \| "aim" \| "chainIK" \| "footPlacement", weight?: number, weightParameter?: string}]
- `addLayers?`: [{blend?: "additive" \| "override", clip?: string, mask?: [string], name?: string, referenceTime?: number, speed?: number, weight?: number}]
- `addStates?`: [{blend?: object, clip?: string, loops?: boolean, machine?: object, name?: string, position?: number[2], speed?: number, speedParameter?: string}]
- `addTransitions?`: [{canTransitionToSelf?: boolean, conditions?: [object], duration?: number, exitTime?: number, from?: string, to?: string}]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `initialState?`: string
- `level?`: string
- `parameters?`: [{default?: boolean, name?: string, type?: "float" \| "bool" \| "trigger"}]
- `path?`: string
- `preview?`: string
- `removeIK?`: [string]
- `removeLayers?`: [string]
- `removeParameters?`: [string]
- `removeRetarget?`: boolean
- `removeStates?`: [string]
- `removeTransitions?`: [integer]
- `retarget?`: {boneMap?: object, matchNames?: boolean, rootScale?: number, rotation?: "copy" \| "local" \| "world", sampleRate?: number, translation?: "none" \| "root" \| "all"}
- `updateIK?`: object
- `updateLayers?`: object
- `updateStates?`: object
- `updateTransitions?`: object

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `ik?`: [string]
- `initialState?`: string
- `layers`: [string]
- `level?`: string
- `machines?`: [string]
- `parameters`: [string]
- `path`: string
- `states`: [string]
- `transitions`: [string]
- `warnings`: [string]

### `animGraph.get`

**Get Animation Graph** · _read-only_, _idempotent_

Reads an .animgraph file: its parameters, states, transitions (in order), layers and preview model (every field, defaults included), the clips it can use, and problems found (unknown states or parameters, wrong parameter types, missing clips, transitions that can't fire).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `clips`: [string]
- `graph`: {anyStatePosition?: number[2], hitboxes?: [object], ik?: [object], initialState?: string, layers?: [object], parameters?: [object], preview?: string, retarget?: {boneMap?: object, matchNames?: boolean, rootScale?: number, rotation?: "copy" \| "local" \| "world", sampleRate?: number, translation?: "none" \| "root" \| "all"}, states?: [object], transitions?: [object]}
- `path`: string
- `warnings`: [string]

### `animGraph.hitboxes`

**Animation Graph Hitboxes** · _undoable_

Reads or edits an .animgraph file's hitboxes: shapes on bones that deal damage while a state plays inside a window of its cycle (a swing). Each is {name, state (sub-machine states by path, "Combat/Slash"), clip (instead of state), bone, shape {kind: sphere | capsule | box, radius, from, to, size}, start, end (fractions 0...1 of the cycle), damage {amount, type, knockback}}. `set` replaces them all; `add` adds new ones or changes the named ones (only the keys given); `remove` deletes by name; one undo step. Animators playing the graph get them (Animator.hitboxes): in play mode each swing hits a victim's hurtboxes once. With no changes it lists them with the graph's states. Undoable (one step; edit.undo reverts it).

Arguments:

- `add?`: [any]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `remove?`: [string]
- `set?`: [{bone?: string, clip?: string, damage?: object, end?: number, name?: string, shape?: object, start?: number, state?: string}]

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `hitboxes`: [{bone?: string, clip?: string, damage?: object, end?: number, name?: string, shape?: object, start?: number, state?: string}]
- `path`: string
- `states`: [string]
- `warnings`: [string]

### `animGraph.new`

**New Animation Graph**

Writes an .animgraph file in `folder` (default: the Assets root) and imports it: `graph` contents, or a starter (Idle, plus Move on a `speed` parameter when the `preview` model has two clips or more, using its clips). Returns the states, transitions, parameters and warnings. An animation graph (.animgraph) is an Animator state machine; every key is optional: `preview` (the model prefab the builder previews on, an asset reference or path), `retarget` {boneMap {source bone: target bone}, matchNames (default true), rotation world|local|copy, translation root|none|all, rootScale, sampleRate} (plays clips made for another skeleton by matching bones by name; see animGraph.bones), `parameters` [{name, type float|bool|trigger, default}], `states` [{name, clip (one clip) or blend {parameter (a float), clips [{clip, position}]} (a 1D blend space; add parameterY (a second float) and give each clip a `y` for a 2D one, e.g. moveX / moveY for strafing), speed, speedParameter (a float multiplying speed), loops, position [x,y] (node position in the editor)}], `transitions` [{from (a state; omit or "*" for any state), to, conditions [{parameter, test greater|less|isTrue|isFalse|triggered, value}], exitTime (normalized time of the source state, e.g. 0.9), duration (crossfade seconds), canTransitionToSelf}] (checked in order, the first that applies fires), `layers` [{name, clip, weight, speed, referenceTime, blend additive|override (override replaces the bones the clip animates), mask [bone names: the layer only touches their subtrees]}], `initialState`, `ik` [{name, type twoBoneIK|aim|chainIK|footPlacement, bones (twoBoneIK: root, middle, end; aim and chainIK: root to tip), weight 0-1, weightParameter (a float multiplying the weight), target [x,y,z] (world) or targetEntity (an entity's Name), pole [x,y,z] (twoBoneIK: the way the middle joint bends, character space), aimAxis (aim: the last bone's axis that points, default [0,0,1]), maxAngle (aim, degrees per bone), iterations / tolerance (chainIK), legs [[hip, knee, ankle]…] and pelvis (footPlacement: rays against physics, the pelvis drops, feet align and lock), rayHeight, maxStep, alignFeet, lockFeet}] run in order after the states and layers. A state with `machine` {states, transitions, initialState} instead of a clip is a sub-state machine: entering it enters its initial state, its own transitions leave from any state inside, and transitions inside may go to states outside it by name (edit inside with animGraph.edit `level`). Clips are imported glTF clips: "asset:<id>#animation/<name>" or "Models/hero.glb#animation/Walk" (paths are turned into references). Put it on a model with animGraph.assign; scene animators follow the file when it changes.

Arguments:

- `folder?`: string
- `graph?`: {anyStatePosition?: number[2], hitboxes?: [object], ik?: [object], initialState?: string, layers?: [object], parameters?: [object], preview?: string, retarget?: {boneMap?: object, matchNames?: boolean, rootScale?: number, rotation?: "copy" \| "local" \| "world", sampleRate?: number, translation?: "none" \| "root" \| "all"}, states?: [object], transitions?: [object]}
- `name?`: string
- `preview?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `ik?`: [string]
- `initialState?`: string
- `layers`: [string]
- `level?`: string
- `machines?`: [string]
- `parameters`: [string]
- `path`: string
- `states`: [string]
- `transitions`: [string]
- `warnings`: [string]

### `animGraph.open`

**Open in Animation Graph Builder** · _idempotent_

Opens an .animgraph file in the editor's Animation Graph Builder tab (the node editor, a live preview on the graph's model with parameters you drive by hand, and the form) and brings the tab to the front. view.screenshot {source: "panel", panel: "animationGraph"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `animGraph.set`

**Set Animation Graph** · _undoable_, _idempotent_

Replaces an .animgraph file's whole contents and reimports it; animators using it follow. Undoable. For a few changes, animGraph.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `graph`: {anyStatePosition?: number[2], hitboxes?: [object], ik?: [object], initialState?: string, layers?: [object], parameters?: [object], preview?: string, retarget?: {boneMap?: object, matchNames?: boolean, rootScale?: number, rotation?: "copy" \| "local" \| "world", sampleRate?: number, translation?: "none" \| "root" \| "all"}, states?: [object], transitions?: [object]}
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `ik?`: [string]
- `initialState?`: string
- `layers`: [string]
- `level?`: string
- `machines?`: [string]
- `parameters`: [string]
- `path`: string
- `states`: [string]
- `transitions`: [string]
- `warnings`: [string]

### `animGraph.setClipEvents`

**Set Clip Events** · _undoable_, _idempotent_

Replaces the events of a clip imported from a glTF file ({time, name}; footsteps, hits, sounds). They are kept in the model's import settings, so they survive reimports and apply wherever the clip plays. Undoable. Times outside the clip are clamped to it. Undoable (one step; edit.undo reverts it).

Arguments:

- `clip`: string
- `events`: [{name: string, time: number}]

Result:

- `clip`: string
- `duration`: number
- `editable`: boolean
- `events`: [{name: string, time: number}]

## asset

### `asset.applySettings`

**Apply Import Settings** · _destructive_, _idempotent_

Writes the asset's import settings to its sidecar and reimports it. Not undoable. Destructive: pass confirm: true.

Arguments:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `confirm`: true — Must be true: this tool can lose work that undo can't bring back.
- `settings`: any — Any JSON value.

### `asset.assign`

**Assign Asset** · _undoable_, _idempotent_

Sets the entity's MeshRenderer mesh or material to the asset (an entity without a MeshRenderer gets one for a mesh). Undoable (one step; edit.undo reverts it).

Arguments:

- `asset`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `kind?`: "mesh" \| "material" \| "texture" \| "prefab" \| "animation" \| "animationGraph"

### `asset.delete`

**Delete Asset** · _destructive_

Deletes a file (with its sidecar) or a folder. Not undoable; the editor asks first, the command doesn't. Destructive: pass confirm: true.

Arguments:

- `confirm`: true — Must be true: this tool can lose work that undo can't bring back.
- `path`: string

### `asset.extractMaterials`

**Extract Materials**

Writes the model's materials to .material files in "<model> Materials/", remaps the model to them and points the scene's renderers at them. The scene edit is one undo step; the files stay.

Arguments:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).

Result:

- `materials`: [asset id]

### `asset.get`

**Get Asset** · _read-only_, _idempotent_

One asset's metadata: id, path, importer, kind, load state, import error, objects, its effective import settings and the importer's defaults (as asset.applySettings takes them), and its revision.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: {error?: string, folder: string, id: asset id, importer?: string, kind: string, objects: [object], path: string, state: string}
- `defaultSettings?`: any — Any JSON value.
- `revision`: integer
- `settings?`: any — Any JSON value.

### `asset.import`

**Import**

Copies files or folders into `folder` of the project and imports them in the background (a .gltf brings its .bin and images). Taken names get " 2". Not undoable.

Arguments:

- `folder?`: string
- `sources`: [string]

Result:

- `paths`: [string]

### `asset.instantiate`

**Instantiate** · _undoable_

Places a model, prefab or mesh in the scene at `position`, under `parent` (default: a root), and selects it. Returns the new roots. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `parent?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `position?`: number[3] — [x, y, z]

Result:

- `entities`: [entity id]

### `asset.list`

**List Assets** · _read-only_, _idempotent_

Lists a folder of the project: its subfolders and assets, each with id, path, importer, kind, load state, import error and objects (sub-assets: meshes, materials, textures, prefabs as asset: references). `recursive` includes subfolders; `kind` and `search` filter (search looks at paths and object names, in the whole project when no folder is given).

Arguments:

- `folder?`: string
- `kind?`: "mesh" \| "material" \| "texture" \| "prefab" \| "animation" \| "animationGraph"
- `recursive?`: boolean
- `search?`: string

Result:

- `assets`: [{error?: string, folder: string, id: asset id, importer?: string, kind: string, objects: [object], path: string, state: string}]
- `folders`: [string]
- `importing`: integer

### `asset.move`

**Move Asset**

Moves a file or folder into `folder`, keeping asset ids. Returns the new path. Not undoable.

Arguments:

- `folder`: string
- `path`: string

Result:

- `path`: string

### `asset.newFolder`

**New Folder**

Creates a folder in `folder`. Returns its path.

Arguments:

- `folder?`: string
- `name?`: string

Result:

- `path`: string

### `asset.newMaterial`

**New Material**

Writes a .material file in `folder` (default parameters, or `material`). Returns its asset id and path.

Arguments:

- `folder?`: string
- `material?`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, edgeWear?: {color: number[3], crisp: number, metallic: number, noiseFrequency: number, roughness: number}, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset id, filter?: "linear" \| "nearest", fur?: {flowImage?: object, groom?: object, maskImage?: object}, metallic?: number, metallicRoughnessTexture?: asset id, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset id, occlusionStrength?: number, occlusionTexture?: asset id, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset id, translucency?: number, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2], wind?: {bend?: number, flutter?: number, height?: number, origin?: number[3], up?: number[3]}}
- `name?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `path`: string

### `asset.newProceduralTexture`

**New Procedural Texture**

Writes a .proctex file in `folder`: a texture generated from parameters (generator windowGrid, checker, gradient, noise, bricks, stripes, or the tileable noise kinds fbm, ridged, voronoi, cells, woodRings, streaks; size, colors, seed, counts, margin, variation, scale, octaves, angle), imported like any texture so materials can use its `texture` object; normalStrength > 0 also makes a linear `normal` texture (a normal map of its height) for a material's normal slot. Returns its asset id and path. Change it with asset.setProceduralTexture.

Arguments:

- `folder?`: string
- `generator?`: "windowGrid" \| "checker" \| "gradient" \| "noise" \| "bricks" \| "stripes" \| "fbm" \| "ridged" \| "voronoi" \| "cells" \| "woodRings" \| "streaks"
- `name?`: string
- `texture?`: {angle?: number, colorA?: number[3], colorB?: number[3], colorC?: number[3], columns?: integer, fraction?: number, generator?: string (12 cases), height?: integer, margin?: number, normalStrength?: number, octaves?: integer, rows?: integer, scale?: integer, seed?: integer, variation?: number, width?: integer}

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `path`: string

### `asset.reimport`

**Reimport** · _idempotent_

Imports the asset again now, even if it is up to date (prefab instances in the scene follow). Returns its metadata (see asset.get).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: {error?: string, folder: string, id: asset id, importer?: string, kind: string, objects: [object], path: string, state: string}
- `defaultSettings?`: any — Any JSON value.
- `revision`: integer
- `settings?`: any — Any JSON value.

### `asset.rename`

**Rename Asset**

Renames a file or folder in place. Asset ids, and so every reference, survive. Returns the new path. Not undoable.

Arguments:

- `name`: string
- `path`: string

Result:

- `path`: string

### `asset.select`

**Select Asset** · _idempotent_

Selects an asset (or one of its objects) in the asset browser, opening its folder, and shows it in the inspector.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

### `asset.setProceduralTexture`

**Set Procedural Texture**

Overwrites a .proctex file with `texture` and reimports it, so materials using it update. Not undoable.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `texture`: {angle?: number, colorA?: number[3], colorB?: number[3], colorC?: number[3], columns?: integer, fraction?: number, generator?: string (12 cases), height?: integer, margin?: number, normalStrength?: number, octaves?: integer, rows?: integer, scale?: integer, seed?: integer, variation?: number, width?: integer}

Result:

- `path`: string

### `asset.waitForImports`

**Wait for Imports** · _read-only_, _idempotent_

Waits until the background imports (asset.import, hot reload, a project just opened) are done or `timeout` seconds pass, applying them; returns whether they finished and any import errors.

Arguments:

- `timeout?`: number

Result:

- `errors`: [string]
- `finished`: boolean
- `pending`: integer

## behavior

### `behavior.assign`

**Assign Behavior Tree** · _undoable_

Makes an entity run a .behavior tree while playing: adds or updates its BehaviorTreeRunner component (tree, optional target entity, speed and blackboard overrides) as one undoable step. Give it a CharacterController or dynamic RigidBody to move with physics; otherwise its Transform is moved. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `blackboard?`: object
- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `path?`: string
- `speed?`: number
- `target?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `path`: string

### `behavior.debug`

**Debug Behavior Tree** · _read-only_

While playing: an entity's behavior tree state from the last tick (root status, the running path, each ticked node's status, the blackboard, problems such as a missing custom leaf). The Behavior Tree tab highlights the same path.

Arguments:

- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `blackboard`: object
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `nodes`: object
- `playing`: boolean
- `problems`: [string]
- `runningPath`: [string]
- `status`: string
- `ticks`: integer
- `tree`: string

### `behavior.edit`

**Edit Behavior Tree** · _undoable_

Changes part of a .behavior file in one undoable step, in this order: preset (replace everything first), removeNodes, addNodes, updateNodes, disconnect, connect, root, blackboard, speed / turnSpeed / tickRate. NPCs running it while playing pick up the change. Returns the outline and warnings. Example: {"addNodes": [{"id": "low", "type": "healthBelow", "value": 20}, {"id": "run", "type": "flee"}, {"id": "escape", "type": "sequence", "children": ["low", "run"]}], "connect": [{"parent": "root", "child": "escape", "index": 0}]}. A behavior tree (.behavior) is NPC AI as nodes: `nodes` is a flat list of {id, type, name?, children? [ids], ...parameters}, `root` the root id (default: the first node nobody lists as a child), `blackboard` starting shared values ({"health": 100, "home": [0, 0, 0]}), `speed` (m/s, default 3), `turnSpeed` (rad/s, 10) and `tickRate` (per second, 0 = every frame). Types: composites sequence (memory: resume at running child, default true), selector (re-checks from the first child every tick), parallel (succeedOn all|one, failOn one|all); decorators (one child) invert, repeat (count, 0 = forever; untilFailure), cooldown (seconds), succeed; conditions canSeeTarget (range, fov degrees about -Z, lineOfSight, eyeHeight), withinRange (range), healthBelow (key=health, value), checkBlackboard (key, op == != < <= > >= set unset, value); actions moveTo (position [x,y,z] or key), patrol (points [[x,y,z]...], relative, loop, wait), chase (stopDistance, giveUpDistance), flee (safeDistance), attack (range, damage, cooldown, key, animation), wait (seconds, randomness), playAnimation (animation, fade, duration), setBlackboard (key, value), custom (leaf: a name game code registered with BehaviorTreeLeaves.register). Move nodes take `speed`; target nodes take `target` (a blackboard key, default "target": an entity name, else the BehaviorTreeRunner's target entity). Problems are reported in `warnings`. An entity runs a tree with a BehaviorTreeRunner component (behavior.assign) while playing. Undoable (one step; edit.undo reverts it).

Arguments:

- `addNodes?`: [{children?: [string], id?: string, name?: string, type?: string}]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `blackboard?`: object
- `connect?`: [{child: string, index?: integer, parent: string}]
- `disconnect?`: [{child: string, index?: integer, parent: string}]
- `path?`: string
- `preset?`: "empty" \| "patrol" \| "guard" \| "chaser" \| "coward"
- `removeNodes?`: [string]
- `root?`: string
- `speed?`: number
- `tickRate?`: number
- `turnSpeed?`: number
- `updateNodes?`: object

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `blackboard`: [string]
- `nodeCount`: integer
- `outline`: [string]
- `path`: string
- `root`: string
- `warnings`: [string]

### `behavior.get`

**Get Behavior Tree** · _read-only_, _idempotent_

Reads a .behavior file: its nodes, blackboard and settings as stored, an indented outline from the root, and its problems.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `outline`: [string]
- `path`: string
- `tree`: {blackboard?: object, nodes?: [object], root?: string, speed?: number, tickRate?: number, turnSpeed?: number}
- `warnings`: [string]

### `behavior.navigation`

**Behavior Navigation** · _read-only_

The navigation behavior trees walk on (moveTo, patrol, chase and flee follow paths on it, avoiding each other; straight-line steering where there is none): bakes the navmesh and the grid fallback from the static colliders of the current world (the play world while playing) if it has none or `rebake`, reports the grid's size and walkable areas and the navmesh's polygon count, and with `from` and `to` returns the path between them (on the navmesh when there is one). A NavigationArea component sets the baked box and the agent's radius, height, step and slope; without one the bake covers the static colliders around the agents. navigation.bake, navigation.query and navigation.overlay do more with the navmesh. Game code: `world.bakeNavigation()`, `world.findPath(from:to:)`.

Arguments:

- `from?`: number[3] — [x, y, z]
- `partial?`: boolean
- `rebake?`: boolean
- `to?`: number[3] — [x, y, z]

Result:

- `areas`: integer
- `baked`: boolean
- `boundsMax?`: number[3] — [x, y, z]
- `boundsMin?`: number[3] — [x, y, z]
- `cellSize`: number
- `depth`: integer
- `hasGrid`: boolean
- `navMeshPolygons`: integer
- `path`: [number[3]]
- `pathFound`: boolean
- `pathLength`: number
- `walkableCells`: integer
- `width`: integer

### `behavior.new`

**New Behavior Tree**

Writes a .behavior file in `folder` (default: the Assets root) from a `preset` (empty: a selector with a wait; patrol: walks a square; guard: patrols, chases and attacks the target it sees, flees when hurt; chaser; coward) and imports it. Returns the outline and warnings. Change it with behavior.edit; run it on an entity with behavior.assign. A behavior tree (.behavior) is NPC AI as nodes: `nodes` is a flat list of {id, type, name?, children? [ids], ...parameters}, `root` the root id (default: the first node nobody lists as a child), `blackboard` starting shared values ({"health": 100, "home": [0, 0, 0]}), `speed` (m/s, default 3), `turnSpeed` (rad/s, 10) and `tickRate` (per second, 0 = every frame). Types: composites sequence (memory: resume at running child, default true), selector (re-checks from the first child every tick), parallel (succeedOn all|one, failOn one|all); decorators (one child) invert, repeat (count, 0 = forever; untilFailure), cooldown (seconds), succeed; conditions canSeeTarget (range, fov degrees about -Z, lineOfSight, eyeHeight), withinRange (range), healthBelow (key=health, value), checkBlackboard (key, op == != < <= > >= set unset, value); actions moveTo (position [x,y,z] or key), patrol (points [[x,y,z]...], relative, loop, wait), chase (stopDistance, giveUpDistance), flee (safeDistance), attack (range, damage, cooldown, key, animation), wait (seconds, randomness), playAnimation (animation, fade, duration), setBlackboard (key, value), custom (leaf: a name game code registered with BehaviorTreeLeaves.register). Move nodes take `speed`; target nodes take `target` (a blackboard key, default "target": an entity name, else the BehaviorTreeRunner's target entity). Problems are reported in `warnings`. An entity runs a tree with a BehaviorTreeRunner component (behavior.assign) while playing.

Arguments:

- `folder?`: string
- `name?`: string
- `preset?`: "empty" \| "patrol" \| "guard" \| "chaser" \| "coward"

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `blackboard`: [string]
- `nodeCount`: integer
- `outline`: [string]
- `path`: string
- `root`: string
- `warnings`: [string]

### `behavior.open`

**Open in Behavior Tree Builder** · _idempotent_

Opens a .behavior file in the editor's Behavior Tree tab (the tree as a node graph you can drag nodes on to reparent or reorder, with a node form, presets and the blackboard; while playing it tints each node with its last status for the selected entity) and brings the tab to the front. view.screenshot {source: "panel", panel: "behaviorTree"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `behavior.set`

**Set Behavior Tree** · _undoable_, _idempotent_

Replaces a .behavior file's whole contents and reimports it (NPCs running it while playing switch to it). Undoable. For a few changes, behavior.edit is shorter. A behavior tree (.behavior) is NPC AI as nodes: `nodes` is a flat list of {id, type, name?, children? [ids], ...parameters}, `root` the root id (default: the first node nobody lists as a child), `blackboard` starting shared values ({"health": 100, "home": [0, 0, 0]}), `speed` (m/s, default 3), `turnSpeed` (rad/s, 10) and `tickRate` (per second, 0 = every frame). Types: composites sequence (memory: resume at running child, default true), selector (re-checks from the first child every tick), parallel (succeedOn all|one, failOn one|all); decorators (one child) invert, repeat (count, 0 = forever; untilFailure), cooldown (seconds), succeed; conditions canSeeTarget (range, fov degrees about -Z, lineOfSight, eyeHeight), withinRange (range), healthBelow (key=health, value), checkBlackboard (key, op == != < <= > >= set unset, value); actions moveTo (position [x,y,z] or key), patrol (points [[x,y,z]...], relative, loop, wait), chase (stopDistance, giveUpDistance), flee (safeDistance), attack (range, damage, cooldown, key, animation), wait (seconds, randomness), playAnimation (animation, fade, duration), setBlackboard (key, value), custom (leaf: a name game code registered with BehaviorTreeLeaves.register). Move nodes take `speed`; target nodes take `target` (a blackboard key, default "target": an entity name, else the BehaviorTreeRunner's target entity). Problems are reported in `warnings`. An entity runs a tree with a BehaviorTreeRunner component (behavior.assign) while playing. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `tree`: {blackboard?: object, nodes?: [object], root?: string, speed?: number, tickRate?: number, turnSpeed?: number}

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `blackboard`: [string]
- `nodeCount`: integer
- `outline`: [string]
- `path`: string
- `root`: string
- `warnings`: [string]

## builder

### `builder.select`

**Select in Builder Tab**

Selects something inside a builder tab as a click there does, bringing up the panels that only show for a selection (check them with ui.snapshot or view.screenshot): `panel` names the tab (panel id or title; default: the builder tab in front), `item` what to select ("" clears; leave it out to just read). Returns the selection and every selectable item. Items: Mesh Builder parts by name; Animation Graph "state:<name>", "transition:<index>", "anyState", "parameter:<name>", "layer:<name>", "ik:<name>"; Behavior Tree, Dialogue and Visual Script nodes by id. Open the file first (meshBuild.open, animGraph.open…). Needs the editor window.

Arguments:

- `item?`: string
- `panel?`: string

Result:

- `asset?`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `items`: [string]
- `panel`: string
- `selected`: [string]

## cameraRig

### `cameraRig.activate`

**Activate Camera Rig**

Makes a CameraRig the live rig: enables it and raises its priority above every other rig's. While playing the camera blends to it over blendTime seconds (default the rig's own; 0 cuts): step the game (play.step) and read cameraRig.state or view.screenshot {source: "game"}. When editing it changes the saved priority (one undo step), so the scene starts on it.

Arguments:

- `blendTime?`: number
- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `blending`: boolean
- `camera?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `live?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `playing`: boolean
- `rigs`: [{blendWeight: number, cameraPosition?: number[3], collisionHit: boolean, desiredPosition?: number[3], enabled: boolean, entity: entity id, live: boolean, mode: string, name: string, priority: integer, target?: entity id}]

### `cameraRig.setTarget`

**Set Camera Rig Target**

Points a CameraRig at a target entity (what it follows: a character, a vehicle); no target makes it follow its own entity. While playing it changes the running rig (it glides to the new target with its damping); when editing it is one undo step.

Arguments:

- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `target?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `blending`: boolean
- `camera?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `live?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `playing`: boolean
- `rigs`: [{blendWeight: number, cameraPosition?: number[3], collisionHit: boolean, desiredPosition?: number[3], enabled: boolean, entity: entity id, live: boolean, mode: string, name: string, priority: integer, target?: entity id}]

### `cameraRig.state`

**Camera Rig State** · _read-only_, _idempotent_

Lists the scene's CameraRig components (mode, enabled, priority, target, where each puts its camera and where it wants to be, whether a wall pulled it in) and which rig is live, the camera it moves and whether a blend between rigs is running. While playing it reports the running rigs; when editing, the live rig is the enabled one with the highest priority and positions are the settled poses (no collision). Switch rigs with cameraRig.activate.

Arguments: none.

Result:

- `blending`: boolean
- `camera?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `live?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `playing`: boolean
- `rigs`: [{blendWeight: number, cameraPosition?: number[3], collisionHit: boolean, desiredPosition?: number[3], enabled: boolean, entity: entity id, live: boolean, mode: string, name: string, priority: integer, target?: entity id}]

## character

### `character.action`

**Character Action**

While playing, sets an input of an entity's CharacterController for its next step: crouch / stand (held until changed; it stands only with room above), grabLedge (grab a ledge within reach), mantle (pull up onto the ledge it hangs from or a low wall it walks toward), drop (let go of a ledge or climbing wall), jump. Step the game (play.step) and read character.state to see the result. Not recorded in playtests: drive characters there through input actions.

Arguments:

- `action`: "crouch" \| "stand" \| "grabLedge" \| "mantle" \| "drop" \| "jump"
- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `canStand`: boolean
- `crouching`: boolean
- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `ground?`: string
- `grounded`: boolean
- `ledgePoint?`: number[3] — [x, y, z]
- `leftHand?`: number[3] — [x, y, z]
- `mode`: string
- `position`: number[3] — [x, y, z]
- `rightHand?`: number[3] — [x, y, z]
- `sliding`: boolean
- `verticalVelocity`: number
- `wallNormal?`: number[3] — [x, y, z]

### `character.bones`

**Character Bones** · _read-only_, _idempotent_

Lists a body template's bones (name, parent, rest position in meters; +Y up, +Z forward, ".L" on the character's left at +X) and stock clips, without a file: pick bones for character.edit {attach}.

Arguments:

- `proportions?`: object
- `template?`: "humanoid" \| "quadruped" \| "bird" \| "blob"

Result:

- `bones`: [{name: string, parent?: string, position: number[3]}]
- `clips`: [string]
- `handBone`: string
- `template`: "humanoid" \| "quadruped" \| "bird" \| "blob"

### `character.combat`

**Character Combat** · _undoable_

Reads or changes a .character file's combat settings. With them the prefab's root gets a Health (`health`, `team`, `resistances` per damage type, `removeAfter` death), its bones Hurtboxes (capsules over the ragdoll bodies, a little fatter; damage multipliers per body region: head 2, torso 1, arm and leg 0.75 unless `regions` changes them) and its Animator hitbox tracks (`hitboxes`, by default the template's attack: the right hand during the attack clip's swing for a humanoid). Any argument adds the section; `remove` deletes it; one undo step. With no changes it lists the hurtboxes and hitboxes the importer makes. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `defaultHitboxes?`: boolean
- `health?`: number
- `hitboxes?`: [{bone?: string, clip?: string, damage?: object, end?: number, name?: string, shape?: object, start?: number, state?: string}]
- `hurtboxes?`: boolean
- `path?`: string
- `regions?`: object
- `remove?`: boolean
- `removeAfter?`: number
- `resistances?`: object
- `team?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `combat?`: {health?: number, hitboxes?: [object], hurtboxes?: boolean, regions?: object, removeAfter?: number, resistances?: object, team?: string}
- `hitboxes`: [{bone?: string, clip?: string, damage?: object, end?: number, name?: string, shape?: object, start?: number, state?: string}]
- `hurtboxes`: [{bone: string, multiplier: number, region: string, shape: object}]
- `path`: string
- `warnings`: [string]

### `character.edit`

**Edit Character** · _undoable_

Changes a .character file in one undoable step, in this order: template, proportions (name → multiplier), colors (region → [r,g,b]), resetColors, detach, attach, updateAttachments (name → fields; "name" renames), clips (stock), removeClips, addClips (clips from glTF animations or other characters, played by bone-name match; boneMap maps source node names to bones), defaultClip, smooth, segments. Placed copies update. Bone names for attach come from character.bones or character.get. Undoable (one step; edit.undo reverts it).

Arguments:

- `addClips?`: [string]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `attach?`: [{asset?: string, bone?: string, color?: number[3], groom?: string, name?: string, partColors?: object, position?: number[3], rotation?: number[3], scale?: number}]
- `clips?`: [string]
- `colors?`: object
- `defaultClip?`: string
- `detach?`: [string]
- `path?`: string
- `proportions?`: object
- `removeClips?`: [string]
- `resetColors?`: [string]
- `segments?`: integer
- `smooth?`: boolean
- `template?`: "humanoid" \| "quadruped" \| "bird" \| "blob"
- `updateAttachments?`: object

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `attachments`: [string]
- `bones`: [string]
- `clips`: [string]
- `entities?`: [entity id]
- `height`: number
- `parameters`: [string]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `template`: "humanoid" \| "quadruped" \| "bird" \| "blob"
- `warnings`: [string]

### `character.get`

**Get Character** · _read-only_, _idempotent_

Reads a .character file: template, proportions, colors (the ones in use, defaults included), attachments, the generated bones (name, parent, rest position) and clips (state name, clip reference, duration, looping, events), and a summary with problems.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `bones`: [{name: string, parent?: string, position: number[3]}]
- `character`: {attachments?: [object], clips?: [string], colors?: {accent?: number[3], body?: number[3], eyes?: number[3], legs?: number[3], skin?: number[3]}, combat?: {health?: number, hitboxes?: [object], hurtboxes?: boolean, regions?: object, removeAfter?: number, resistances?: object, team?: string}, defaultClip?: string, grooms?: object, ik?: {footPlacement?: boolean, handIK?: boolean, lookAt?: boolean, lookTarget?: string}, proportions?: {arms?: number, head?: number, height?: number, legs?: number, neck?: number, tail?: number, torso?: number, width?: number}, ragdoll?: {blendTime?: number, bones?: [object], enabled?: boolean, mass?: number, strength?: number}, segments?: integer, smooth?: boolean, template?: "humanoid" \| "quadruped" \| "bird" \| "blob"}
- `clips`: [{clip: string, duration: number, events: [string], loops: boolean, name: string, source?: string}]
- `colors`: object
- `summary`: {asset: asset id, attachments: [string], bones: [string], clips: [string], entities?: [entity id], height: number, parameters: [string], path: string, prefab: asset id, template: "humanoid" \| "quadruped" \| "bird" \| "blob", warnings: [string]}

### `character.ik`

**Character IK** · _undoable_

Reads or changes a .character file's inverse kinematics, which the importer turns into Animator IK nodes run after the animation: `footPlacement` (node "Feet": rays against physics find the ground under each foot, the pelvis drops, feet turn to the slope and planted feet lock), `lookAt` (node "Look": the spine, chest, neck and head turn toward the entity named `lookTarget`, or a point set at run time), `handIK` (humanoids, nodes "Hand.L" / "Hand.R": two-bone arms reach points set at run time). Returns the nodes. Set targets and weights at run time with the Visual Script nodes ik.setTarget / ik.setWeight or Animator.setIKTarget / setIKWeight. One undo step. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `footPlacement?`: boolean
- `handIK?`: boolean
- `lookAt?`: boolean
- `lookTarget?`: string
- `path?`: string
- `remove?`: boolean

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `ik?`: {footPlacement?: boolean, handIK?: boolean, lookAt?: boolean, lookTarget?: string}
- `nodes`: [{aimAxis?: number[3], alignFeet?: boolean, bones?: [string], iterations?: integer, legs?: [[string]], lockFeet?: boolean, mask?: integer, maxAngle?: number, maxStep?: number, name?: string, pelvis?: string, plantHeight?: number, pole?: number[3], rayHeight?: number, target?: number[3], targetEntity?: string, tolerance?: number, type?: "twoBoneIK" \| "aim" \| "chainIK" \| "footPlacement", weight?: number, weightParameter?: string}]
- `path`: string
- `warnings`: [string]

### `character.new`

**New Character**

Writes a .character file in `folder` (default: the Assets root) from a body template, imported as a skinned prefab with an Animator and the stock clips (idle, walk, run, jump, attack, die), optionally placed in the scene. Then change it with character.edit {proportions, colors, attach}. A character is a body `template` (humanoid, quadruped, bird, blob) with a generated skeleton, `proportions` (multipliers, 1 = as designed, 0.25-3: height (scales everything), head, torso, width, arms (a bird's wings), legs, neck, tail), `colors` by region (skin, body, legs, accent, eyes; [r,g,b] 0-1 sRGB; a missing one is the template's default), `attachments` (each: name, bone (see character.bones), asset (a .meshbuild path under Assets/), position [x,y,z] meters and rotation [x,y,z] degrees in the bone's space (+Y up, +Z forward, +X the character's left), scale, optional color recoloring every part, optional partColors {part name: [r,g,b]} recoloring single mesh-build parts over color), `clips` (stock clips to include: idle, walk, run, jump, attack, die; all by default; an entry may instead be {name, clip: "asset:<id>#animation/<name>" (a glTF animation or another character's clip), boneMap: {sourceNode: bone}, loops}, played by bone-name match: rotations of nodes named like bones, no rest-pose correction; named like a stock clip it replaces it), `defaultClip` (the Animator's first state), `smooth` (blended skin weights at joints) and `segments` (6-32, roundness). It imports as a skinned prefab with an Animator whose states are the clips plus `locomotion` (idle/walk/run blended by the float parameter `speed` in m/s), with triggers `jump`, `attack`, `die`. Every key is optional.

Arguments:

- `attachments?`: [{asset?: string, bone?: string, color?: number[3], groom?: string, name?: string, partColors?: object, position?: number[3], rotation?: number[3], scale?: number}]
- `colors?`: object
- `folder?`: string
- `name?`: string
- `place?`: boolean
- `position?`: number[3] — [x, y, z]
- `proportions?`: object
- `template?`: "humanoid" \| "quadruped" \| "bird" \| "blob"

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `attachments`: [string]
- `bones`: [string]
- `clips`: [string]
- `entities?`: [entity id]
- `height`: number
- `parameters`: [string]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `template`: "humanoid" \| "quadruped" \| "bird" \| "blob"
- `warnings`: [string]

### `character.open`

**Open in Character Builder** · _idempotent_

Opens a .character file in the editor's Character Builder tab (the character alone in a viewport playing a clip, with the template, proportion sliders, colors, attachments and clip buttons) and brings the tab to the front; `clip` picks the clip it plays. view.screenshot {source: "panel", panel: "characterBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `clip?`: string
- `path?`: string

Result:

- `path`: string

### `character.ragdoll`

**Character Ragdoll** · _undoable_

Reads or changes a .character file's ragdoll: capsule bodies sized automatically from the body shapes (humanoid: hips, spine, head, upper and lower arms and legs), ball joints with swing and twist limits at shoulders, hips, spine and neck, hinges at elbows and knees. With no changes it lists the bodies (bone, end bone, radius, parent, joint, limits in degrees, mass). `enabled` adds or switches it, `bones` merges per-bone changes {bone, radius, swing, minAngle, maxAngle, mass}, `resetBones` drops them, `remove` deletes the section; one undo step. The prefab gets a Ragdoll component: Visual Script ragdoll.enable / ragdoll.applyImpulse or Ragdoll.goLimp / hit / getUp in code. `test` opens the Character Builder and drops the preview (false stands it up). Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `blendTime?`: number
- `bones?`: [{bone?: string, mass?: number, maxAngle?: number, minAngle?: number, radius?: number, swing?: number}]
- `enabled?`: boolean
- `mass?`: number
- `path?`: string
- `remove?`: boolean
- `resetBones?`: [string]
- `strength?`: number
- `test?`: boolean

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `bodies`: [{bone: string, edited: boolean, end?: string, joint: "fixed" \| "ball" \| "hinge" \| "distance", length?: number, mass: number, maxAngle: number, minAngle: number, parent?: string, radius: number, swing?: number}]
- `enabled`: boolean
- `mass`: number
- `path`: string
- `ragdoll?`: {blendTime?: number, bones?: [object], enabled?: boolean, mass?: number, strength?: number}
- `tested?`: boolean
- `warnings`: [string]

### `character.set`

**Set Character** · _undoable_, _idempotent_

Replaces a .character file's whole contents and reimports it; placed copies update. Undoable. For a few changes character.edit is shorter. A character is a body `template` (humanoid, quadruped, bird, blob) with a generated skeleton, `proportions` (multipliers, 1 = as designed, 0.25-3: height (scales everything), head, torso, width, arms (a bird's wings), legs, neck, tail), `colors` by region (skin, body, legs, accent, eyes; [r,g,b] 0-1 sRGB; a missing one is the template's default), `attachments` (each: name, bone (see character.bones), asset (a .meshbuild path under Assets/), position [x,y,z] meters and rotation [x,y,z] degrees in the bone's space (+Y up, +Z forward, +X the character's left), scale, optional color recoloring every part, optional partColors {part name: [r,g,b]} recoloring single mesh-build parts over color), `clips` (stock clips to include: idle, walk, run, jump, attack, die; all by default; an entry may instead be {name, clip: "asset:<id>#animation/<name>" (a glTF animation or another character's clip), boneMap: {sourceNode: bone}, loops}, played by bone-name match: rotations of nodes named like bones, no rest-pose correction; named like a stock clip it replaces it), `defaultClip` (the Animator's first state), `smooth` (blended skin weights at joints) and `segments` (6-32, roundness). It imports as a skinned prefab with an Animator whose states are the clips plus `locomotion` (idle/walk/run blended by the float parameter `speed` in m/s), with triggers `jump`, `attack`, `die`. Every key is optional. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `character`: {attachments?: [object], clips?: [string], colors?: {accent?: number[3], body?: number[3], eyes?: number[3], legs?: number[3], skin?: number[3]}, combat?: {health?: number, hitboxes?: [object], hurtboxes?: boolean, regions?: object, removeAfter?: number, resistances?: object, team?: string}, defaultClip?: string, grooms?: object, ik?: {footPlacement?: boolean, handIK?: boolean, lookAt?: boolean, lookTarget?: string}, proportions?: {arms?: number, head?: number, height?: number, legs?: number, neck?: number, tail?: number, torso?: number, width?: number}, ragdoll?: {blendTime?: number, bones?: [object], enabled?: boolean, mass?: number, strength?: number}, segments?: integer, smooth?: boolean, template?: "humanoid" \| "quadruped" \| "bird" \| "blob"}
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `attachments`: [string]
- `bones`: [string]
- `clips`: [string]
- `entities?`: [entity id]
- `height`: number
- `parameters`: [string]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `template`: "humanoid" \| "quadruped" \| "bird" \| "blob"
- `warnings`: [string]

### `character.state`

**Character State** · _read-only_, _idempotent_

Returns an entity's CharacterController state: mode (walking, hanging, mantling, climbing), grounded, sliding, crouching and whether it has room to stand, the ledge point and wall normal, hand points for IK, and the physics material under its feet.

Arguments:

- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `canStand`: boolean
- `crouching`: boolean
- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `ground?`: string
- `grounded`: boolean
- `ledgePoint?`: number[3] — [x, y, z]
- `leftHand?`: number[3] — [x, y, z]
- `mode`: string
- `position`: number[3] — [x, y, z]
- `rightHand?`: number[3] — [x, y, z]
- `sliding`: boolean
- `verticalVelocity`: number
- `wallNormal?`: number[3] — [x, y, z]

## combat

### `combat.inspect`

**Inspect Combat** · _read-only_, _idempotent_

Lists the scene's damageable entities (Health: current, max, dead, team, resistances), hitboxes (Hitbox components and animator hitbox tracks: world-space shape, whether active now, damage) and hurtboxes (shape, region, multiplier), and the latest hits. `entity` limits it to one entity's subtree. Hitbox tracks are active only while playing (their state's window). See combat.overlay to draw them.

Arguments:

- `activeOnly?`: boolean
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `health`: [{current: number, dead: boolean, entity?: entity id, max: number, name: string, resistances: object, team: string}]
- `hitboxes`: [{active?: boolean, bone: string, damage?: object, entity?: entity id, from: number[3], halfExtents?: number[3], kind: string, multiplier?: number, name: string, owner?: entity id, radius: number, region?: string, to: number[3]}]
- `hurtboxes`: [{active?: boolean, bone: string, damage?: object, entity?: entity id, from: number[3], halfExtents?: number[3], kind: string, multiplier?: number, name: string, owner?: entity id, radius: number, region?: string, to: number[3]}]
- `playing`: boolean
- `recentHits`: [{attacker?: entity id, bone: string, damage: number, health: number, hitbox: string, killed: boolean, normal: number[3], point: number[3], region: string, sequence: integer, type: string, victim?: entity id, victimName: string}]

### `combat.overlay`

**Show Hitboxes** · _idempotent_

Shows or hides hitboxes and hurtboxes in the Scene view, drawn over the scene: hurtboxes blue (gray once dead), hitboxes dim yellow, active ones bright red and thicker, and arrows along the normals of the latest hits. While playing it follows the animation (hitbox tracks light up during their window). view.screenshot shows it with gizmos on.

Arguments:

- `show?`: boolean

Result:

- `hitboxes`: integer
- `hurtboxes`: integer
- `shown`: boolean

### `combat.simulateHit`

**Simulate Hit**

While playing, hits `victim` as a hitbox would: `damage` of `type` from `attacker` at `bone` (its hurtbox's region multiplier applies) or `point`, then steps `frames` (default 1) so the combat system runs the effects: hit flash, hit stop, camera shake, VFX and sound, a partial ragdoll hit reaction, a full ragdoll on death, On Hit / On Death in visual scripts. Returns the hit (damage dealt after multipliers and resistances, killed), the victim's health and ragdoll mode.

Arguments:

- `attacker?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `bone?`: string
- `damage?`: number
- `frames?`: integer
- `knockback?`: number
- `point?`: number[3] — [x, y, z]
- `type?`: string
- `victim`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `health?`: {current: number, dead: boolean, entity?: entity id, max: number, name: string, resistances: object, team: string}
- `hit?`: {attacker?: entity id, bone: string, damage: number, health: number, hitbox: string, killed: boolean, normal: number[3], point: number[3], region: string, sequence: integer, type: string, victim?: entity id, victimName: string}
- `ragdoll?`: string

## component

### `component.add`

**Add Component** · _undoable_

Adds the default value of an addable component (`EditorComponentCatalog`) to the entity. Undoable (one step; edit.undo reverts it).

Arguments:

- `component`: string
- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

### `component.remove`

**Remove Component** · _undoable_

Removes the named component from the entity. Undoable (one step; edit.undo reverts it).

Arguments:

- `component`: string
- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

### `component.setField`

**Set Field** · _undoable_, _idempotent_

Sets one field of a component by reflection path (what the inspector edits): `component` "Transform" with `path` "position", or just `path` "Transform.position.x" (a trailing .x/.y/.z/.w sets one element of a vector). A rotation (a quaternion field) is [x, y, z, w] or {"eulerDegrees": [x, y, z]} (Z roll, then X pitch, then Y yaw). With `space` "world", Transform's position, rotation and scale are given in world space. Undoable (one step; edit.undo reverts it).

Arguments:

- `component?`: string
- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `label?`: string
- `path`: string
- `previous?`: any — Any JSON value.
- `space?`: "local" \| "world"
- `transient?`: boolean
- `value`: any — Any JSON value.

### `component.types`

**Component Types** · _read-only_, _idempotent_

Lists the registered component types: whether component.add can add them, their fields (dotted paths for component.setField, kinds, enum cases, defaults, ranges) and the JSON Schema of their saved form.

Arguments:

- `component?`: string

Result:

- `components`: [{addable: boolean, fields: [object], name: string, schema: any}]

## diagnostics

### `diagnostics.get`

**Diagnostics** · _read-only_, _idempotent_

Returns what is wrong: entities whose MeshRenderer names a mesh that doesn't exist (they draw nothing), assets whose import failed (with the importer's message), how many are still importing, graphics validation messages in the console, and the latest console warnings and errors.

Arguments: none.

Result:

- `backend?`: string
- `importErrors`: [{message: string, path: string}]
- `importing`: integer
- `missingMeshes`: [{entity: entity id, mesh: string, name: string}]
- `problems`: [{level: "info" \| "warning" \| "error", message: string, sequence: integer, time: number}]
- `validation`: [{level: "info" \| "warning" \| "error", message: string, sequence: integer, time: number}]
- `validationEnabled`: boolean

## dialogue

### `dialogue.edit`

**Edit Dialogue** · _undoable_

Changes part of a .dialogue file in one undoable step, in this order: speakers, removeSpeakers, variables, removeVariables, removeNodes, addNodes, updateNodes, connect, start, generateKeys, layout, uiLayout. Returns node summaries and warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `addNodes?`: [{args?: object, changes?: [object], choices?: [object], comment?: string, condition?: string, else?: string, event?: string, id?: string, key?: string, next?: string, position?: [number], speaker?: string, text?: string, type?: "line" \| "choice" \| "condition" \| "set" \| "event" \| "end"}]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `connect?`: [{branch?: string, choice?: integer, from: string, text?: string, to: string}]
- `generateKeys?`: string
- `layout?`: boolean
- `path?`: string
- `removeNodes?`: [string]
- `removeSpeakers?`: [string]
- `removeVariables?`: [string]
- `speakers?`: [{color?: string, id?: string, name?: string, portrait?: string}]
- `start?`: string
- `uiLayout?`: string
- `updateNodes?`: object
- `variables?`: [{default?: any, name?: string, type?: "number" \| "bool" \| "text"}]

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `nodes`: [string]
- `path`: string
- `speakers`: [string]
- `start`: string
- `variables`: [string]
- `warnings`: [string]

### `dialogue.get`

**Get Dialogue** · _read-only_, _idempotent_

Reads a .dialogue file: speakers, variables and nodes as stored, its problems, and its localization keys with their text.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `dialogue`: {nodes?: [object], speakers?: [object], start?: string, uiLayout?: string, variables?: [object]}
- `localizationKeys`: object
- `path`: string
- `warnings`: [string]

### `dialogue.new`

**New Dialogue**

Writes a .dialogue file in `folder` (default: the Assets root) and imports it: `dialogue` as given, else a starter conversation (or nothing with empty: true). Returns the asset, node summaries and warnings. Build it up with dialogue.edit {addNodes, connect, variables, speakers}, try it with dialogue.play. A .dialogue file is a branching conversation: `start` (node id), `speakers` [{id, name, portrait (texture path), color "#RRGGBB"}], `variables` [{name, type number|bool|text, default}] and `nodes` [{id, type, ...}]. Node types: line {speaker, text, key, next}; choice {speaker?, text? (prompt), choices [{text, key, next, condition}], next (used when no option is available)}; condition {condition, next (true), else (false)}; set {changes [{variable, op set|add|subtract|toggle, value | expression}], next}; event {event, args {}, next}; end. An empty next ends the conversation. Text fills in {variable}. Conditions/expressions: `gold >= 10 && !paid`, `visits + 1` (== != < <= > >= && || ! and or not + - * / parentheses, "strings"). `key` is a localization key per line/option. `position` [x, y] places the node in the graph view (omitted: placed automatically). `uiLayout` (path or asset:<id>) shows the dialogue in a .ui layout instead of the default box: it sets the values speaker, speakerColor, text, portrait, hasPortrait, isLine, isChoice, active, choiceCount, choice1…9, hasChoice1…9 and answers the button events continue and choice1…9 (uiLayout.new {preset: "dialogue"} makes one). Problems (missing nodes, unknown speakers/variables, bad conditions, unreachable nodes) come back as `warnings`. In game a DialoguePlayer component {dialogue: path, startNode, autoStart, uiLayout} plays it; game code uses world.dialogues?.start(entity), world.dialogue(for:)?.setVariable / .variable, and world.dialogues?.onEvent.

Arguments:

- `dialogue?`: {nodes?: [object], speakers?: [object], start?: string, uiLayout?: string, variables?: [object]}
- `empty?`: boolean
- `folder?`: string
- `name?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `nodes`: [string]
- `path`: string
- `speakers`: [string]
- `start`: string
- `variables`: [string]
- `warnings`: [string]

### `dialogue.open`

**Open in Dialogue Builder** · _idempotent_

Opens a .dialogue file in the editor's Dialogue tab (graph view, node form and a play-through preview that tracks variables) and brings the tab to the front. view.screenshot {source: "panel", panel: "dialogue"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `dialogue.play`

**Play Dialogue** · _read-only_, _idempotent_

Plays a .dialogue file through without the game: lines are continued automatically, choices are picked from `choices` in order, variables start from the file's defaults plus `variables`. Returns the transcript (lines with speaker and filled-in text, options shown, picks, events, variable changes), where it stopped and the final variables. Use it to test branches and conditions.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `choices?`: [integer]
- `maxLines?`: integer
- `path?`: string
- `start?`: string
- `strings?`: object
- `variables?`: object

Result:

- `events`: [string]
- `node?`: string
- `state`: string
- `transcript`: [{args?: object, event?: string, kind: string, node?: string, options?: [string], speaker?: string, text?: string, value?: any, variable?: string}]
- `variables`: object

### `dialogue.set`

**Set Dialogue** · _undoable_, _idempotent_

Replaces a .dialogue file's whole contents and reimports it (running games pick it up). Undoable. Nodes without a position are placed automatically. For a few changes, dialogue.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `dialogue`: {nodes?: [object], speakers?: [object], start?: string, uiLayout?: string, variables?: [object]}
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `nodes`: [string]
- `path`: string
- `speakers`: [string]
- `start`: string
- `variables`: [string]
- `warnings`: [string]

## edit

### `edit.batch`

**Batch** · _undoable_

Runs `calls` (each {command, arguments}) in order as ONE undo step named `label`. If a call fails, everything the batch did is undone, the selection is restored, and the error names the call. A string "$<n>.<path>" in arguments is replaced by part of call n's result ("$0.entity" is the entity call 0 created); "{$<n>.<path>}" inside a longer string interpolates it ("asset:{$2.asset}"). File operations and screenshots aren't rolled back or can't be batched. Undoable (one step; edit.undo reverts it).

Arguments:

- `calls`: [{arguments?: any, command: string}]
- `label`: string

Result:

- `results`: [any]

### `edit.beginBatch`

**Begin Batch**

Starts recording every following edit (from any tool) as ONE undo step named `label`, until edit.endBatch. Undo is unavailable meanwhile. Use edit.batch when the calls are known up front.

Arguments:

- `label`: string

### `edit.endBatch`

**End Batch**

Ends the batch edit.beginBatch started: its edits become one undo step, or with `cancel` are undone.

Arguments:

- `cancel?`: boolean

Result:

- `label`: string
- `recorded`: boolean

### `edit.redo`

**Redo**

Redoes the last undone step.

Arguments: none.

### `edit.undo`

**Undo**

Undoes the last recorded step (a whole command, gizmo drag or inspector gesture).

Arguments: none.

## entity

### `entity.create`

**Create Entity** · _undoable_

Creates an entity from `template` at `position` ([x, y, z]), named `name` (default: after the template, "Cube 2" when taken), as a root or under `parent`, and selects it. Undoable (one step; edit.undo reverts it).

Arguments:

- `name?`: string
- `parent?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `position?`: number[3] — [x, y, z]
- `template`: "empty" \| "cube" \| "sphere" \| "plane" \| "cylinder" \| "capsule" \| "cone" \| "torus"

Result:

- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

### `entity.delete`

**Delete** · _undoable_

Deletes the selected entities (or `entities`) with their children. The editor asks for confirmation before running it; the command itself doesn't. Undoable (one step; edit.undo reverts it).

Arguments:

- `entities?`: [entity id]

Result:

- `count`: integer

### `entity.duplicate`

**Duplicate** · _undoable_

Duplicates the selected entities (or `entities`) with their children next to the originals and selects the copies. Returns the copies. Undoable (one step; edit.undo reverts it).

Arguments:

- `entities?`: [entity id]

Result:

- `entities`: [entity id]

### `entity.find`

**Find Entities** · _read-only_, _idempotent_

Finds entities by `name` (substring, any case; whole name with `exact`), by `component` they have, and/or by `id` (or its leading hex digits); all given criteria must match. Returns them in hierarchy order with id, name, path ("Parent/Child"), parent and component names.

Arguments:

- `component?`: string
- `exact?`: boolean
- `id?`: string
- `name?`: string

Result:

- `entities`: [{components: [string], id: entity id, name: string, parent?: entity id, path: string}]

### `entity.get`

**Get Entity** · _read-only_, _idempotent_

Returns one entity as the inspector shows it: name, parent, children, its world transform and every component's fields (the values `component.setField` takes, by field name).

Arguments:

- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `children`: [entity id]
- `components`: object
- `id`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `name`: string
- `parent?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `world`: {position: number[3], rotation: number[4], scale: number[3]}

### `entity.rename`

**Rename** · _undoable_, _idempotent_

Sets the entity's `Name` (adding one if it has none). Undoable (one step; edit.undo reverts it).

Arguments:

- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `name`: string

### `entity.reparent`

**Reparent** · _undoable_

Makes `entities` children of `parent` (nil: roots) at `index` (nil: last), keeping their world transforms. Undoable (one step; edit.undo reverts it).

Arguments:

- `entities`: [entity id]
- `index?`: integer
- `parent?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

## file

### `file.openInCodeEditor`

**Open in Code Editor** · _idempotent_

Opens a file or folder in the code editor picked in the Settings window (settings.setEditor `codeEditor`: the system default, VS Code, Cursor, Xcode, Zed, Sublime Text or a custom command). `path` is absolute, relative to the project folder or to Assets/; default: the game code's package folder, else the project folder. Only inside the project for AI clients. Returns the path and the command; it runs only in an editor with a window.

Arguments:

- `path?`: string

Result:

- `command`: [string]
- `launched`: boolean
- `path`: string

### `file.reveal`

**Show in Folder** · _idempotent_

Shows a file or folder in the system's file manager (Finder, Explorer; on Linux its folder opens): `path` absolute, relative to the project folder or to Assets/ (default: the project folder). Only inside the project for AI clients. Returns the path and the command; it runs only in an editor with a window.

Arguments:

- `path?`: string

Result:

- `command`: [string]
- `launched`: boolean
- `path`: string

## files

### `files.list`

**List Files** · _read-only_, _idempotent_

Lists what the Files panel shows: the project's scenes (.scene under Assets/) and its own scripts (script.list), with paths from the project folder.

Arguments: none.

Result:

- `files`: [{absolutePath: string, kind: string, path: string}]

### `files.newScene`

**New Scene** · _destructive_

Creates a scene file in the project's Assets/Scenes/ (Assets/ without a project), saves it and opens it in the Scene view, as the Files panel's New Scene does. Refuses a name that exists. The open scene is replaced (unsaved changes are lost). Not while playing. Destructive: pass confirm: true.

Arguments:

- `confirm`: true — Must be true: this tool can lose work that undo can't bring back.
- `name`: string
- `template?`: string

Result:

- `path`: string

### `files.open`

**Open File** · _destructive_, _idempotent_

Opens a file from the Files panel: a scene replaces the open scene and shows the Scene view (as scene.open), a script opens in the Scripts editor tabbed with the Scene view (as script.open). Not for scenes while playing. Destructive only when `path` is a scene (it replaces the open scene); opening a script needs no confirm: then pass confirm: true.

Arguments:

- `confirm?`: true — Required only when `path` is a scene (it replaces the open scene); opening a script needs no confirm: that can lose work that undo can't bring back.
- `path`: string

Result:

- `path`: string

## game

### `game.build`

**Build Game** · _deferred_

Exports the project as a standalone game: cooks every asset reachable from the scenes into one pack (textures block-compressed for the target GPU family, no source files), builds the game module (a generated one that only plays the scenes when the project has no game code) and Engine in release and links them into one executable, and lays out a runnable app (macOS: <output>/<Name>.app; Linux: <output>/<Name>/ with run.sh). Runs in the background (the first build compiles Engine in release, minutes; later ones seconds); progress and errors go to the console. Returns the output path, the pack's contents and sizes, and timings. `platform`, `architecture` (x86_64 or arm64) and `configuration` (release or debug) pick what is built; only this machine's platform can be built (macOS builds either architecture, other platforms only their own), except with `docker: true`, which builds a Linux game in a container from any machine for either architecture (Docker must be installed and running; the first build takes many minutes). `output` may be any folder. `cookOnly` writes just the pack (for any platform). The output folder is replaced.

Arguments:

- `architecture?`: "x86_64" \| "arm64"
- `configuration?`: "release" \| "debug"
- `cookOnly?`: boolean
- `docker?`: boolean
- `output?`: string
- `platform?`: "macos" \| "linux" \| "windows"
- `scenes?`: [string]
- `textureFamily?`: "bc" \| "astc"
- `textures?`: "compress" \| "asImported"

Result:

- `buildSeconds?`: number
- `cook`: {assetCount: integer, fileBytes: integer, files: integer, fromCookCache: integer, fromLibrary: integer, imported: [string], manifestPath?: string, meshBytes: integer, packBytes: integer, packPath: string, scenes: [string], seconds: number, textureBytes: integer, warnings: [string]}
- `executablePath?`: string
- `outputPath`: string
- `packPath`: string
- `summary`: string
- `totalSeconds`: number

### `game.info`

**Game Code Info** · _read-only_, _idempotent_

The game module: where it comes from, whether it is loaded, its components and systems, whether a rebuild is running, the last error and the last reload's report (timings, restored and dropped components), and components the scene holds as JSON because their type isn't loaded.

Arguments: none.

Result:

- `busy`: boolean
- `components`: [string]
- `configured`: boolean
- `diagnostics?`: [{column: integer, file: string, line: integer, message: string, severity?: string}]
- `lastError?`: string
- `lastReport?`: {added: [string], buildMode?: string, buildSeconds?: number, built: boolean, carriedStateBytes?: integer, components: [string], failed: object, fastBuildSkipped?: string, libraryTargets?: [string], linkSeconds?: number, loadSeconds: number, module: string, playing: boolean, removed: object, resetFields: object, restored: integer, swapSeconds: number, systems: [string], totalSeconds: number, undoValuesRestored?: integer, warnings: [string]}
- `library?`: string
- `loaded`: boolean
- `module?`: string
- `settings?`: {buildCommand?: [string], library?: string, package?: string, target?: string, watch?: boolean}
- `summary?`: string
- `systems`: [string]
- `unresolved`: object

### `game.load`

**Load Game Code** · _deferred_

Loads game code: a SwiftPM `target` (built, then its objects linked into a module) or a prebuilt `library`. Its components become addable and its systems run in play mode; scene components of its types are restored. Replaces the module loaded before, like game.reload.

Arguments:

- `build?`: boolean
- `library?`: string
- `package?`: string
- `target?`: string
- `watch?`: boolean

Result:

- `added`: [string]
- `buildMode?`: string
- `buildSeconds?`: number
- `built`: boolean
- `carriedStateBytes?`: integer
- `components`: [string]
- `failed`: object
- `fastBuildSkipped?`: string
- `libraryTargets?`: [string]
- `linkSeconds?`: number
- `loadSeconds`: number
- `module`: string
- `playing`: boolean
- `removed`: object
- `resetFields`: object
- `restored`: integer
- `swapSeconds`: number
- `systems`: [string]
- `totalSeconds`: number
- `undoValuesRestored?`: integer
- `warnings`: [string]

### `game.reload`

**Reload Game Code** · _deferred_

Rebuilds the game module in the background (one direct `swiftc` call for the game target once a build plan is cached, else `swift build --target <game>`, or its build command), then swaps it in with the scene kept: game components (scene, play snapshot, undo history) are serialized, the old code's willUnload state saved, the new types registered and the components restored (new fields get defaults, removed fields are dropped, components whose type is gone stay as JSON), the new code's didLoad given the state; play mode goes on with the new systems. A failed build keeps the old code running and fails with the first compiler errors (file:line:column: message); game.info's diagnostics has them all, structured. Returns what changed, how it was built and the build, link, load and swap times. Keeps the undo history.

Arguments:

- `build?`: boolean

Result:

- `added`: [string]
- `buildMode?`: string
- `buildSeconds?`: number
- `built`: boolean
- `carriedStateBytes?`: integer
- `components`: [string]
- `failed`: object
- `fastBuildSkipped?`: string
- `libraryTargets?`: [string]
- `linkSeconds?`: number
- `loadSeconds`: number
- `module`: string
- `playing`: boolean
- `removed`: object
- `resetFields`: object
- `restored`: integer
- `swapSeconds`: number
- `systems`: [string]
- `totalSeconds`: number
- `undoValuesRestored?`: integer
- `warnings`: [string]

### `game.unload`

**Unload Game Code**

Unloads the game module: its systems stop, its components stay in the scene (and the undo history) as JSON (saved unchanged) until game code with those types is loaded again; its willUnload state is kept for the next load.

Arguments: none.

## gridMap

### `gridMap.edit`

**Edit GridMap** · _undoable_

Changes a .gridmap file's settings and piece library in one undoable step, in this order: clear / clearFloor, cellSize, chunkSize, collider, layers, removePieces (their cells go too), addPieces, updatePieces (name → fields; "name" renames and cells follow). Placed copies update. Cells are painted with gridMap.paint, gridMap.fill and gridMap.erase. Undoable (one step; edit.undo reverts it).

Arguments:

- `addPieces?`: [{asset?: string, collider?: "auto" \| "mesh" \| "box" \| "none", footprint?: integer[2], join?: object, layer?: string, material?: string, name?: string, offset?: number[3], rotation?: number, scale?: number[3], size?: number[3]}]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `cellSize?`: number[3] — [x, y, z]
- `chunkSize?`: integer
- `clear?`: boolean
- `clearFloor?`: integer
- `collider?`: boolean
- `layers?`: [string]
- `path?`: string
- `removePieces?`: [string]
- `updatePieces?`: object

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[3] — [x, y, z]
- `cells`: integer
- `changed?`: integer
- `entities?`: [entity id]
- `floors`: [integer]
- `layers`: [string]
- `max?`: [integer]
- `min?`: [integer]
- `path`: string
- `pieces`: [string]
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `gridMap.erase`

**Erase GridMap** · _undoable_

Clears cells of a .gridmap file in one undoable step: `cells` ([x, y, z] list) and/or `box` (two opposite corners), on `layer` or every layer. A multi-cell piece goes when any cell it covers is erased. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `box?`: [[integer]]
- `cells?`: [[integer]]
- `layer?`: string
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[3] — [x, y, z]
- `cells`: integer
- `changed?`: integer
- `entities?`: [entity id]
- `floors`: [integer]
- `layers`: [string]
- `max?`: [integer]
- `min?`: [integer]
- `path`: string
- `pieces`: [string]
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `gridMap.fill`

**Fill GridMap** · _undoable_

Fills a box of cells (`box`: two opposite [x, y, z] corners, every floor between them) with a piece in one undoable step; `hollow` paints only each floor's edge (a ring of walls; auto-joining walls form corners by themselves). `rotation` 0/90/180/270, `layer` (default: the piece's). Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `box`: [[integer]]
- `hollow?`: boolean
- `layer?`: string
- `path?`: string
- `piece`: string
- `rotation?`: integer

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[3] — [x, y, z]
- `cells`: integer
- `changed?`: integer
- `entities?`: [entity id]
- `floors`: [integer]
- `layers`: [string]
- `max?`: [integer]
- `min?`: [integer]
- `path`: string
- `pieces`: [string]
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `gridMap.get`

**Get GridMap** · _read-only_, _idempotent_

Reads a .gridmap file: settings, the piece library (every field, defaults included), the cells (optionally one `floor`, up to `cellLimit`), a summary (floors, bounds, problems), and with `mapFloor` a text picture of one floor.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `cellLimit?`: integer
- `floor?`: integer
- `mapFloor?`: integer
- `path?`: string

Result:

- `cellSize`: number[3] — [x, y, z]
- `cells`: [{at?: [integer], flipX?: boolean, flipZ?: boolean, layer?: string, piece?: string, rotation?: integer}]
- `chunkSize`: integer
- `collider`: boolean
- `layers`: [string]
- `map?`: [string]
- `mapOrigin?`: [integer]
- `pieces`: [{asset?: string, collider?: "auto" \| "mesh" \| "box" \| "none", footprint?: integer[2], join?: object, layer?: string, material?: string, name?: string, offset?: number[3], rotation?: number, scale?: number[3], size?: number[3]}]
- `summary`: {asset: asset id, cellSize: number[3], cells: integer, changed?: integer, entities?: [entity id], floors: [integer], layers: [string], max?: [integer], min?: [integer], path: string, pieces: [string], prefab: asset id, warnings: [string]}
- `truncated`: boolean

### `gridMap.new`

**New GridMap**

Writes a .gridmap file in `folder` (default: the Assets root) with a piece library: `library` pieces, `assets` paths (each a piece named after its file), and unless a library is given the starter pieces (Floor, auto-joining Wall with its Wall Single/End/Straight/Corner/Tee/Cross variants, Crate, Pillar) written as mesh builds next to it. Optionally places it in the scene. Then paint with gridMap.paint, gridMap.fill and gridMap.erase. A grid map is a level built from modular pieces on a grid: `cellSize` [x, floor height, z] meters, `chunkSize` (cells per chunk side; one merged collider per chunk and floor), `collider`, `layers` (default floor, walls, props; one piece per cell per layer), `pieces` (the library; each: name, asset (a .meshbuild, .gltf/.glb/.obj model or .prefab path under Assets/, or "asset:<id>#mesh/<name>" with `material`), footprint [w, d] cells, size [x,y,z] collision box meters (0: footprint by one floor), offset [x,y,z] pivot meters, rotation degrees (fixes how the model faces), scale, layer (default layer), collider (auto, mesh, box, none), join (auto-joining: single, end, straight, corner, tee, cross piece names, plus joinsWith)) and `cells` (each: at [x, y, z] (y is the floor), piece, layer, rotation 0/90/180/270, flipX, flipZ). Cell (x,y,z) spans x*cellSize.x...(x+1)*cellSize.x and z likewise, standing on y*cellSize.y; a piece is centered on its footprint, which runs from the anchor toward +x and +z. An auto-joining piece becomes the variant that fits its neighbors on the same floor and layer, turned to face them (variants are authored connecting toward +x (end), +x/-x (straight), +x/+z (corner), +x/-x/+z (tee)). Every key is optional.

Arguments:

- `assets?`: [string]
- `cellSize?`: number[3] — [x, y, z]
- `chunkSize?`: integer
- `folder?`: string
- `layers?`: [string]
- `library?`: [{asset?: string, collider?: "auto" \| "mesh" \| "box" \| "none", footprint?: integer[2], join?: object, layer?: string, material?: string, name?: string, offset?: number[3], rotation?: number, scale?: number[3], size?: number[3]}]
- `name?`: string
- `place?`: boolean
- `position?`: number[3] — [x, y, z]
- `starter?`: boolean

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[3] — [x, y, z]
- `cells`: integer
- `changed?`: integer
- `entities?`: [entity id]
- `floors`: [integer]
- `layers`: [string]
- `max?`: [integer]
- `min?`: [integer]
- `path`: string
- `pieces`: [string]
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `gridMap.open`

**Open in GridMap Builder** · _idempotent_

Opens a .gridmap file in the editor's GridMap Builder tab (a viewport showing the map with the edited floor's grid, the floors below faded and the ones above hidden, brushes you click or drag, and the piece library form) and brings the tab to the front. view.screenshot {source: "panel", panel: "gridMapBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `floor?`: integer
- `path?`: string

Result:

- `path`: string

### `gridMap.paint`

**Paint GridMap** · _undoable_

Paints a piece (or a random one of `pieces`) onto a .gridmap file's cells in one undoable step and reimports it. `cells` are [x, y, z] (y is the floor); `brush` reads them as: cells (each one), line or rect / outline (between the first two), fill (flood fill from the first). `rotation` 0/90/180/270, `flipX` / `flipZ` mirror, `layer` (default: the piece's) — a piece replaces what it overlaps on its layer only. Auto-joining pieces (like the starter Wall) pick their straight/corner/tee/end shape from neighbors by themselves. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `brush?`: "cells" \| "line" \| "rect" \| "outline" \| "fill"
- `cells`: [[integer]]
- `flipX?`: boolean
- `flipZ?`: boolean
- `layer?`: string
- `path?`: string
- `piece?`: string
- `pieces?`: [string]
- `randomRotation?`: boolean
- `rotation?`: integer
- `seed?`: integer

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[3] — [x, y, z]
- `cells`: integer
- `changed?`: integer
- `entities?`: [entity id]
- `floors`: [integer]
- `layers`: [string]
- `max?`: [integer]
- `min?`: [integer]
- `path`: string
- `pieces`: [string]
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `gridMap.set`

**Set GridMap** · _undoable_, _idempotent_

Replaces a .gridmap file's whole contents (library and cells) and reimports it; placed copies update. Undoable. For library or settings changes gridMap.edit is shorter; paint with gridMap.paint / gridMap.fill / gridMap.erase. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `map`: {cellSize?: number[3], cells?: [object], chunkSize?: integer, collider?: boolean, layers?: [string], pieces?: [object]}
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[3] — [x, y, z]
- `cells`: integer
- `changed?`: integer
- `entities?`: [entity id]
- `floors`: [integer]
- `layers`: [string]
- `max?`: [integer]
- `min?`: [integer]
- `path`: string
- `pieces`: [string]
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

## groom

### `groom.apply`

**Apply Groom** · _undoable_

Grows a .groom's fur on a mesh in one undoable step. `target`: {entity} (a scene entity with a MeshRenderer, or a placed model whose parts get it: those the groom's mask.parts names, or all), {character, part} (a .character body region skin|body|legs|accent|eyes, skinned with the body so it follows the animation, or an attachment's name: its parts), or {meshBuild, part} (a .meshbuild part's `groom` key). `remove: true` takes it off. Warns about meshes without UVs, fur too dense for the triangle count and masks that cover nothing. The fur draws in the editor views (needs the groom imported). Undoable (one step; edit.undo reverts it).

Arguments:

- `groom`: string
- `remove?`: boolean
- `target`: {character?: string, entity?: entity id, meshBuild?: string, part?: string}

Result:

- `applied`: [string]
- `furTriangles`: integer
- `warnings`: [string]

### `groom.edit`

**Edit Groom** · _undoable_

Changes part of a .groom file in one undoable step, in this order: clearStrokes, changes (top-level fields; nested objects such as mask or lod are replaced whole), addComb, addCut. Strokes are spheres in the mesh's space: comb {center [x,y,z], radius, direction [x,y,z], strength} turns strands toward a direction; cut {center, radius, length 0 (bald) … 1 (full) … 2, strength} sets the length (a mask). Fur using the groom updates. Returns detail levels and warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `addComb?`: [{center?: number[3], direction?: number[3], radius?: number, strength?: number}]
- `addCut?`: [{center?: number[3], length?: number, radius?: number, strength?: number}]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `changes?`: any — Any JSON value.
- `clearStrokes?`: boolean
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `levels`: [number]
- `material`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `style`: "shell" \| "cards" \| "strands"
- `warnings`: [string]

### `groom.examples`

**Groom Examples** · _read-only_, _idempotent_

Returns three warning-free .groom files to copy or adapt: fur with comb and cut strokes, long hair cards, and moss. Pass `name` for one.

Arguments:

- `name?`: string

Result:

- `examples`: [{about: string, groom: object, name: string}]

### `groom.get`

**Get Groom** · _read-only_, _idempotent_

Reads a .groom file: every field (defaults included), its fur material and preview prefab, detail levels and problems found.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `groom`: {cardSegments?: integer, cardWidth?: number, clumping?: number, colorNoise?: number, comb?: [object], combDirection?: string, combStrength?: number, curl?: number, cut?: [object], density?: number, flowTexture?: string, frizz?: number, gravity?: number, length?: number, lengthVariation?: number, lod?: {cards?: [number], distances?: [number], shells?: [integer]}, mask?: {invert?: boolean, parts?: [string], texture?: string, vertexPaint?: string}, previewMesh?: string, rootColor?: number[3], seed?: integer, shells?: integer, specular?: number, stiffness?: number, strandsPerCard?: integer, style?: "shell" \| "cards" \| "strands", thickness?: number[2], tipColor?: number[3], wind?: number}
- `summary`: {asset: asset id, levels: [number], material: asset id, path: string, prefab: asset id, style: "shell" \| "cards" \| "strands", warnings: [string]}

### `groom.new`

**New Groom**

Writes a .groom file in `folder` (default: the Assets root) from a `preset` (or `groom` contents) and imports it as a fur material and a preview prefab. Returns the asset, its fur material, the preview prefab, detail levels and warnings. Put it on a mesh with groom.apply; edit it with groom.edit or groom.set (fur using it updates). A .groom file is fur or hair any mesh can wear (every key optional): style shell (short fur, moss, velvet: instanced shells) | cards (longer hair, manes, feathers: ribbon cards along guide curves) | strands (reserved, draws as cards); length (m), lengthVariation 0-1, density (strands per cm² for shells, cards per cm² for cards), thickness [root, tip] (0-1 of the strand spacing), clumping, curl, frizz, gravity, stiffness (0-1), rootColor / tipColor ([r,g,b] 0-1 sRGB), colorNoise, specular (0-1), mask {texture (red scales the length), vertexPaint "r"|"g"|"b"|"a", parts [Mesh Builder part / entity names], invert}, combDirection "normal" | "followSurface" | [x,y,z] (mesh space) with combStrength 0-1 (1 lies flat), flowTexture (red/green: a direction in UV space), wind (scales the scene's wind; 0 still), shells (2-64 at full detail), cardWidth (m), cardSegments (2-16), strandsPerCard (1-32), lod {shells [per level], cards [fraction per level], distances [m where levels 1, 2… start; past the last only a fur-colored undercoat is drawn]}, comb [{center [x,y,z], radius, direction [x,y,z], strength}] and cut [{center, radius, length (0 bald, 1 full, up to 2), strength}] strokes in the mesh's space, applied in order, seed, previewMesh (sphere, cube, capsule, plane or a .meshbuild path). Presets: shortFur, shaggyFur, velvet, moss, tufts, straightHair, ponytail, mane, feathers (groom.presets). Put it on a mesh with groom.apply (an entity, a .character body region or attachment, or a .meshbuild part).

Arguments:

- `folder?`: string
- `groom?`: {cardSegments?: integer, cardWidth?: number, clumping?: number, colorNoise?: number, comb?: [object], combDirection?: string, combStrength?: number, curl?: number, cut?: [object], density?: number, flowTexture?: string, frizz?: number, gravity?: number, length?: number, lengthVariation?: number, lod?: {cards?: [number], distances?: [number], shells?: [integer]}, mask?: {invert?: boolean, parts?: [string], texture?: string, vertexPaint?: string}, previewMesh?: string, rootColor?: number[3], seed?: integer, shells?: integer, specular?: number, stiffness?: number, strandsPerCard?: integer, style?: "shell" \| "cards" \| "strands", thickness?: number[2], tipColor?: number[3], wind?: number}
- `name?`: string
- `preset?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `levels`: [number]
- `material`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `style`: "shell" \| "cards" \| "strands"
- `warnings`: [string]

### `groom.open`

**Open in Groom Builder** · _idempotent_

Opens a .groom file in the editor's Groom Builder tab (the fur growing live on its previewMesh in a light breeze, the settings form, and Mask / Restore / Length / Comb brushes that paint cut and comb strokes into the file) and brings the tab to the front. view.screenshot {source: "panel", panel: "groomBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `groom.presets`

**Groom Presets** · _read-only_, _idempotent_

Lists the built-in grooms (short fur, shaggy fur, velvet, moss, grass-like tufts, straight hair, ponytail, mane, feathers) with what each is for, its GPU budget and its full contents. groom.new {preset} makes a file from one.

Arguments: none.

Result:

- `presets`: [{about: string, groom: object, name: string, style: "shell" \| "cards" \| "strands"}]

### `groom.preview`

**Preview Groom** · _read-only_, _idempotent_, _deferred_

Returns one PNG of a .groom's fur grown on its previewMesh (a sphere by default, or a .meshbuild's parts): a 3/4 view from the front right and (closeUp, default true) a close-up of the surface, studio-lit (`environment` studio|outdoor|flat) in still air. `size`: tile pixels (default 384). Also returns a summary (style, length, detail levels, fur triangles on the preview mesh) and warnings. Read-only: shown in a world of its own. Finishes after a few frames. Needs the editor window.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `closeUp?`: boolean
- `environment?`: "studio" \| "outdoor" \| "flat"
- `path?`: string
- `size?`: integer

Result:

- `image`: {data?: string, height: integer, mimeType: string, width: integer}
- `summary`: string
- `warnings`: [string]

### `groom.set`

**Set Groom** · _undoable_, _idempotent_

Replaces a .groom file's whole contents and reimports it; fur using it updates. Undoable. For a few changes, groom.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `groom`: {cardSegments?: integer, cardWidth?: number, clumping?: number, colorNoise?: number, comb?: [object], combDirection?: string, combStrength?: number, curl?: number, cut?: [object], density?: number, flowTexture?: string, frizz?: number, gravity?: number, length?: number, lengthVariation?: number, lod?: {cards?: [number], distances?: [number], shells?: [integer]}, mask?: {invert?: boolean, parts?: [string], texture?: string, vertexPaint?: string}, previewMesh?: string, rootColor?: number[3], seed?: integer, shells?: integer, specular?: number, stiffness?: number, strandsPerCard?: integer, style?: "shell" \| "cards" \| "strands", thickness?: number[2], tipColor?: number[3], wind?: number}
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `levels`: [number]
- `material`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `style`: "shell" \| "cards" \| "strands"
- `warnings`: [string]

## input

### `input.action`

**Input Action**

Presses an input action by name (play mode), from the next game frame: tapped (down one frame), held `duration` seconds, pressed (`down`: true) or released (false). `value` (-1…1) sets an analog source instead (a gamepad axis such as "axis.leftStickX+"); a key or button counts as pressed at |value| ≥ 0.5. Actions come from the scene's visual scripts (known once they started: step a frame first) and playtest.start's `actions`; input.actions lists them. Paused, it waits: play.step runs it. Recorded while a playtest records.

Arguments:

- `action`: string
- `down?`: boolean
- `duration?`: number
- `value?`: number

Result:

- `actionInputPending`: integer
- `state`: {buttons: ["left" \| "right" \| "middle"], frame: integer, gameCamera: boolean, inputPending: integer, inputSeconds: number, keys: [string (74 cases)], paused: boolean, physics: boolean, playing: boolean, reason?: string, stepped?: integer, time: number, timeScale: number}

### `input.actions`

**Input Actions** · _read-only_, _idempotent_

Lists the input actions input.action can press, with their sources ("key.space", "pad.south", "axis.leftStickX+") and origin: "playtest" (playtest.start's `actions`) or "script" (a visual script running in the scene, so known once play ran a frame).

Arguments: none.

Result:

- `actions`: [{name: string, origin: string, sources: [string]}]

### `input.clear`

**Clear Input** · _idempotent_

Drops scheduled input (input.inject's, input.action's and input.gamepad's) and releases every injected key and button and the virtual gamepad.

Arguments: none.

Result:

- `buttons`: ["left" \| "right" \| "middle"]
- `frame`: integer
- `gameCamera`: boolean
- `inputPending`: integer
- `inputSeconds`: number
- `keys`: [string (74 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
- `reason?`: string
- `stepped?`: integer
- `time`: number
- `timeScale`: number

### `input.gamepad`

**Gamepad Input**

Drives a virtual gamepad in the game's input (play mode), from the next game frame: a `button` ("south", "east", "dpadUp", "start"…) tapped, held `duration` seconds or pressed / released (`down`), or an `axis` ("leftStickX", "leftStickY", "rightStickX", "rightStickY" -1…1, "leftTrigger", "rightTrigger" 0…1) set to `value` for `duration` seconds or until set again. Game code sees it in `Input.gamepads` like a real pad. Recorded while a playtest records.

Arguments:

- `axis?`: "leftStickX" \| "leftStickY" \| "rightStickX" \| "rightStickY" \| "leftTrigger" \| "rightTrigger"
- `button?`: "south" \| "east" \| "west" \| "north" \| "leftShoulder" \| "rightShoulder" \| "leftStickClick" \| "rightStickClick" \| "dpadUp" \| "dpadDown" \| "dpadLeft" \| "dpadRight" \| "start" \| "back" \| "guide"
- `down?`: boolean
- `duration?`: number
- `value?`: number

Result:

- `actionInputPending`: integer
- `state`: {buttons: ["left" \| "right" \| "middle"], frame: integer, gameCamera: boolean, inputPending: integer, inputSeconds: number, keys: [string (74 cases)], paused: boolean, physics: boolean, playing: boolean, reason?: string, stepped?: integer, time: number, timeScale: number}

### `input.inject`

**Inject Input**

Plays input into the game (play mode) over game time, after what is already scheduled (`replace`: instead). Each step does one thing: `key` (or `keys` together) / `button` tapped for one frame, held `duration` seconds, or pressed (`down`: true) / released (false); `mouseTo` [x, y] in game-view points; `mouseBy`; `scroll`; `text`. The next step starts `wait` seconds later (default the step's `duration`; 0 overlaps them). Game systems read it from the session's gameInput, never the editor's UI. Paused, it waits: play.step runs it frame by frame. Example: [{"key": "w", "duration": 2}, {"key": "space"}].

Arguments:

- `replace?`: boolean
- `steps`: [{button?: "left" \| "right" \| "middle", down?: boolean, duration?: number, key?: string (74 cases), keys?: [string (74 cases)], mouseBy?: number[2], mouseTo?: number[2], scroll?: number[2], text?: string, wait?: number}]

Result:

- `seconds`: number
- `state`: {buttons: ["left" \| "right" \| "middle"], frame: integer, gameCamera: boolean, inputPending: integer, inputSeconds: number, keys: [string (74 cases)], paused: boolean, physics: boolean, playing: boolean, reason?: string, stepped?: integer, time: number, timeScale: number}

### `input.state`

**Input State** · _read-only_, _idempotent_

Returns the game's input as of the last game frame: keys and buttons down, the cursor, keys held by injection and events still scheduled.

Arguments: none.

Result:

- `buttons`: ["left" \| "right" \| "middle"]
- `injectedKeys`: [string (74 cases)]
- `keys`: [string (74 cases)]
- `mouse`: number[2] — [x, y]
- `mouseDelta`: number[2] — [x, y]
- `pending`: integer

## interaction

### `interaction.list`

**List Interactables** · _read-only_, _idempotent_

Lists the scene's interactables (verb its prompt shows, use or pick-up action, enabled, door / lever / container state, times used) and interactors (what each focuses while playing, the prompt with the action's current input glyph, items carried).

Arguments: none.

Result:

- `glyphs`: object
- `interactables`: [{action: "use" \| "pickUp", enabled: boolean, entity?: entity id, kind: string, name: string, state?: boolean, uses: integer, verb: string}]
- `interactors`: [{entity?: entity id, focus?: entity id, items: object, name: string, prompt?: string}]
- `playing`: boolean

### `interaction.use`

**Use Interactable**

While playing, makes an interactor use an interactable as if it pressed the action: a door opens or closes (a locked one needs its key item), a lever flips and toggles its target, a container opens and hands over its items, a pickup joins the interactor's items. Defaults: the first Interactor and what it focuses. Not recorded in playtests (press the use action there: input.action {action: "use"}).

Arguments:

- `interactor?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `target?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `items`: object
- `result`: string
- `verb`: string

## launcher

### `launcher.dismiss`

**Continue Without a Project** · _idempotent_

Leaves the launcher for the editor without opening a project (the starter scene; no assets).

Arguments: none.

### `launcher.settings`

**Launcher Settings** · _idempotent_

Whether the editor skips the launcher at startup and reopens the last project (`reopenLastProject`, saved in the prefs). Returns the settings and whether the launcher is shown.

Arguments:

- `reopenLastProject?`: boolean

Result:

- `launcherShown`: boolean
- `reopenLastProject`: boolean

### `launcher.show`

**Close Project and Show Launcher** · _destructive_

Closes the open project (if any) and shows the launcher: the start screen with the recent projects, New Project and Open. The scene is replaced with a new starter scene, so unsaved changes are lost. Not while playing. Destructive only when the open scene has unsaved changes: then pass confirm: true.

Arguments:

- `confirm?`: true — Required only when the open scene has unsaved changes: that can lose work that undo can't bring back.

Result:

- `closedProject?`: string
- `launcherShown`: boolean

## layout

### `layout.reset`

**Reset Layout** · _idempotent_

Restores the default panel layout. Needs the editor window.

Arguments: none.

## log

### `log.clear`

**Clear Console** · _idempotent_

Clears the console (log.read then starts from the next message).

Arguments: none.

### `log.read`

**Read Console** · _read-only_, _idempotent_

Returns console messages, oldest first: at `level` or above, from sequence `since` on, containing `contains`, the newest `limit` (default 100). `next` is the `since` for the following read. The editor://log resource (and editor://log/{level}) is the same, subscribable.

Arguments:

- `contains?`: string
- `level?`: "info" \| "warning" \| "error"
- `limit?`: integer
- `since?`: integer

Result:

- `entries`: [{level: "info" \| "warning" \| "error", message: string, sequence: integer, time: number}]
- `next`: integer

## material

### `material.get`

**Get Material** · _read-only_, _idempotent_

Reads a material: a .material file or a model's material object, with every parameter as material.set takes it.

Arguments:

- `asset`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).

Result:

- `editable`: boolean
- `material`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, edgeWear?: {color: number[3], crisp: number, metallic: number, noiseFrequency: number, roughness: number}, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset id, filter?: "linear" \| "nearest", fur?: {flowImage?: object, groom?: object, maskImage?: object}, metallic?: number, metallicRoughnessTexture?: asset id, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset id, occlusionStrength?: number, occlusionTexture?: asset id, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset id, translucency?: number, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2], wind?: {bend?: number, flutter?: number, height?: number, origin?: number[3], up?: number[3]}}

### `material.set`

**Edit Material** · _undoable_, _idempotent_

Changes the .material file's fields and reimports it (the viewport updates). Fields left out in `material` keep their current values (`null` clears a texture); `reset: true` starts from the default material instead. A model's own materials are read-only: asset.extractMaterials makes editable .material files. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `label?`: string
- `material`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, edgeWear?: {color: number[3], crisp: number, metallic: number, noiseFrequency: number, roughness: number}, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset id, filter?: "linear" \| "nearest", fur?: {flowImage?: object, groom?: object, maskImage?: object}, metallic?: number, metallicRoughnessTexture?: asset id, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset id, occlusionStrength?: number, occlusionTexture?: asset id, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset id, translucency?: number, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2], wind?: {bend?: number, flutter?: number, height?: number, origin?: number[3], up?: number[3]}}
- `previous?`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, edgeWear?: {color: number[3], crisp: number, metallic: number, noiseFrequency: number, roughness: number}, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset id, filter?: "linear" \| "nearest", fur?: {flowImage?: object, groom?: object, maskImage?: object}, metallic?: number, metallicRoughnessTexture?: asset id, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset id, occlusionStrength?: number, occlusionTexture?: asset id, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset id, translucency?: number, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2], wind?: {bend?: number, flutter?: number, height?: number, origin?: number[3], up?: number[3]}}
- `reset?`: boolean
- `transient?`: boolean

## materialGraph

### `materialGraph.assign`

**Assign Material Graph** · _undoable_

Sets the MeshRenderer.material of an entity (default: the selected one), and with `children: true` of every MeshRenderer below it (a placed model or prefab), to a .material file. A Decal gets it as its `material` (it paints the graph instead of its texture). Undoable, one step. Mesh build parts use a material through their `material` key instead. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `children?`: boolean
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `path?`: string

Result:

- `entities`: [entity id]
- `path`: string

### `materialGraph.edit`

**Edit Material Graph** · _undoable_

Changes a .material file's node graph in one undoable step, in this order: optional `preset` restart, `removeNodes`, `addNodes` ({type, id?, ...keys}), `params` ({nodeId: {key: value}}), `connect` ([{from, to}] with to "node.input" or "output.<pbr input>"), `disconnect` (["node.input"]), `output`, `settings`. A material without a graph gets an empty one first. Returns the full graph, the ids of added nodes and warnings. A material graph lives in a .material file's `graph` key: {"nodes": [...], "output": {...}}. A node is {"id", "type", ...keys}; an input key holds a constant (number or [2-4 numbers]) or a link "nodeId" / "nodeId.swizzle" ("tex.rgb", "n.x"); a link may also name a built-in: uv, position, normal, viewDir, vertexColor, time. Sizes convert as in GLSL (a scalar fills a vector). Node types: color, value, vector, uv, position, normal, viewDir, vertexColor, time, texture, triplanar, noise, scrollUV, rotateUV, math, blend, fresnel, combine, remap (see materialGraph.nodes for inputs and settings). `output` maps the PBR inputs baseColor (vec3, default 0.8,0.8,0.8), opacity (float, default 1), normal (vec3, default 0,0,1), metallic (float, default 0), roughness (float, default 0.5), emissive (vec3, default 0,0,0), occlusion (float, default 1); normal is tangent-space, emissive is linear light added after lighting. Colors are linear. Texture settings take a path under Assets/ (image or .proctex) or asset:<id>; up to 5 different textures. The graph compiles into a shader variant for Metal and Vulkan at import; constants are data, so changing one doesn't recompile. Opacity needs alphaMode "blend" (or "mask" with alphaCutoff). Presets: basic, lava, water, hologram, stone, pulse. Undoable (one step; edit.undo reverts it).

Arguments:

- `addNodes?`: [object]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `connect?`: [{from: any, to: string}]
- `disconnect?`: [string]
- `output?`: object
- `params?`: object
- `path?`: string
- `preset?`: string
- `removeNodes?`: [string]
- `settings?`: {addressMode?: string, alphaCutoff?: number, alphaMode?: string, doubleSided?: boolean, filter?: string}

Result:

- `added?`: [string]
- `alphaCutoff`: number
- `alphaMode`: string
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `code?`: string
- `doubleSided`: boolean
- `graph?`: {nodes?: [object], output?: object}
- `path`: string
- `warnings`: [string]

### `materialGraph.get`

**Get Material Graph** · _read-only_, _idempotent_

Reads a .material file's node graph as written, its alpha mode and sidedness, and the graph's problems (unknown nodes, missing links, cycles, missing textures). `code: true` adds the generated shader code.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `code?`: boolean
- `path?`: string

Result:

- `added?`: [string]
- `alphaCutoff`: number
- `alphaMode`: string
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `code?`: string
- `doubleSided`: boolean
- `graph?`: {nodes?: [object], output?: object}
- `path`: string
- `warnings`: [string]

### `materialGraph.new`

**New Material Graph**

Writes a .material file with a node graph in `folder` (default: the Assets root) from a `preset` (default basic) or a whole `graph`, with optional `settings` (alphaMode, alphaCutoff, doubleSided, filter, addressMode), and imports it. Returns the asset, the graph and warnings. Use it on a MeshRenderer (materialGraph.assign) or a mesh build part's `material`. A material graph lives in a .material file's `graph` key: {"nodes": [...], "output": {...}}. A node is {"id", "type", ...keys}; an input key holds a constant (number or [2-4 numbers]) or a link "nodeId" / "nodeId.swizzle" ("tex.rgb", "n.x"); a link may also name a built-in: uv, position, normal, viewDir, vertexColor, time. Sizes convert as in GLSL (a scalar fills a vector). Node types: color, value, vector, uv, position, normal, viewDir, vertexColor, time, texture, triplanar, noise, scrollUV, rotateUV, math, blend, fresnel, combine, remap (see materialGraph.nodes for inputs and settings). `output` maps the PBR inputs baseColor (vec3, default 0.8,0.8,0.8), opacity (float, default 1), normal (vec3, default 0,0,1), metallic (float, default 0), roughness (float, default 0.5), emissive (vec3, default 0,0,0), occlusion (float, default 1); normal is tangent-space, emissive is linear light added after lighting. Colors are linear. Texture settings take a path under Assets/ (image or .proctex) or asset:<id>; up to 5 different textures. The graph compiles into a shader variant for Metal and Vulkan at import; constants are data, so changing one doesn't recompile. Opacity needs alphaMode "blend" (or "mask" with alphaCutoff). Presets: basic, lava, water, hologram, stone, pulse.

Arguments:

- `folder?`: string
- `graph?`: {nodes?: [object], output?: object}
- `name?`: string
- `preset?`: string
- `settings?`: {addressMode?: string, alphaCutoff?: number, alphaMode?: string, doubleSided?: boolean, filter?: string}

Result:

- `added?`: [string]
- `alphaCutoff`: number
- `alphaMode`: string
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `code?`: string
- `doubleSided`: boolean
- `graph?`: {nodes?: [object], output?: object}
- `path`: string
- `warnings`: [string]

### `materialGraph.nodes`

**Material Graph Node Types** · _read-only_, _idempotent_

Lists every material graph node type with its inputs (sizes, defaults), settings and output size, plus the PBR outputs, built-in link names and presets.

Arguments: none.

Result:

- `builtins`: [string]
- `nodes`: [{category: string, inputs: [string], output: string, settings: [string], summary: string, type: string}]
- `outputs`: [string]
- `presets`: [string]

### `materialGraph.open`

**Open in Material Builder** · _idempotent_

Opens a .material file in the editor's Material Builder tab (live preview, node graph canvas, outputs and node form) and brings the tab to the front. Optional preview `shape` (sphere, cube, plane, selected), `light` (studio, sun, rim, dim), `background` (gray, dark, light, sky) and a `node` to select. view.screenshot {source: "panel", panel: "materialBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `background?`: string
- `light?`: string
- `node?`: string
- `path?`: string
- `shape?`: string

Result:

- `path`: string

### `materialGraph.set`

**Set Material Graph** · _undoable_, _idempotent_

Replaces a .material file's whole node graph (`graph` or a `preset`; `clear: true` removes it) and optional `settings`, then reimports it; everything using the material updates. Undoable. For a few changes, materialGraph.edit is shorter. A material graph lives in a .material file's `graph` key: {"nodes": [...], "output": {...}}. A node is {"id", "type", ...keys}; an input key holds a constant (number or [2-4 numbers]) or a link "nodeId" / "nodeId.swizzle" ("tex.rgb", "n.x"); a link may also name a built-in: uv, position, normal, viewDir, vertexColor, time. Sizes convert as in GLSL (a scalar fills a vector). Node types: color, value, vector, uv, position, normal, viewDir, vertexColor, time, texture, triplanar, noise, scrollUV, rotateUV, math, blend, fresnel, combine, remap (see materialGraph.nodes for inputs and settings). `output` maps the PBR inputs baseColor (vec3, default 0.8,0.8,0.8), opacity (float, default 1), normal (vec3, default 0,0,1), metallic (float, default 0), roughness (float, default 0.5), emissive (vec3, default 0,0,0), occlusion (float, default 1); normal is tangent-space, emissive is linear light added after lighting. Colors are linear. Texture settings take a path under Assets/ (image or .proctex) or asset:<id>; up to 5 different textures. The graph compiles into a shader variant for Metal and Vulkan at import; constants are data, so changing one doesn't recompile. Opacity needs alphaMode "blend" (or "mask" with alphaCutoff). Presets: basic, lava, water, hologram, stone, pulse. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `clear?`: boolean
- `graph?`: {nodes?: [object], output?: object}
- `path?`: string
- `preset?`: string
- `settings?`: {addressMode?: string, alphaCutoff?: number, alphaMode?: string, doubleSided?: boolean, filter?: string}

Result:

- `added?`: [string]
- `alphaCutoff`: number
- `alphaMode`: string
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `code?`: string
- `doubleSided`: boolean
- `graph?`: {nodes?: [object], output?: object}
- `path`: string
- `warnings`: [string]

## meshBuild

### `meshBuild.edit`

**Edit Mesh Build** · _undoable_

Changes part of a .meshbuild file in one undoable step, in this order: removeParts, addParts, updateParts (name → fields to change; "name" renames), removeAnimations, addAnimations, then addMotions / addTracks into `animation`. Placed copies update. Returns the part and animation names, `bounds` and warnings (broken references and spatial problems). Undoable (one step; edit.undo reverts it).

Arguments:

- `addAnimations?`: [{autoplay?: boolean, loop?: "once" \| "loop" \| "pingPong", motions?: [object], name?: string, speed?: number, tracks?: [object]}]
- `addMotions?`: [{amount?: number, axis?: "x" \| "y" \| "z", kind?: "spin" \| "bob" \| "swing" \| "pulse" \| "shake", part?: string, period?: number}]
- `addParts?`: [{along?: number[2], axis?: "x" \| "y" \| "z", bevel?: number, blend?: "add" \| "subtract" \| "intersect", cardSize?: number, closed?: boolean, color?: number[3], count?: integer, deform?: [object], density?: number, glow?: number[3], glowStrength?: number, grain?: "x" \| "y" \| "z", groom?: string, look?: string, lookScale?: number, material?: string, metallic?: number, mirror?: "x" \| "y" \| "z" \| ["x" \| "y" \| "z"], name?: string, noise?: object, on?: [string], opacity?: number, open?: boolean, parent?: string, path?: [number[3]], physicsMaterial?: string, position?: number[3], profile?: [number[2]], radii?: [number], radius?: number, repeat?: object, resolution?: integer, ribbon?: number, rotation?: number[3], roughness?: number, sections?: [object], seed?: integer, segments?: integer, shape?: string (18 cases), size?: number[3], smooth?: number, straight?: boolean, subdivide?: integer, texture?: string, textureScale?: number[2], thickness?: number, wear?: number, worldUV?: boolean}]
- `addTracks?`: [{interpolation?: "linear" \| "step" \| "hermite", keys?: [object], part?: string, property?: "position" \| "rotation" \| "scale"}]
- `animation?`: string
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `removeAnimations?`: [string]
- `removeParts?`: [string]
- `updateParts?`: object

Result:

- `animations`: [string]
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `bounds?`: {base: number, max: number[3], min: number[3], parts?: [object], size: number[3]}
- `copies?`: [string]
- `entities?`: [entity id]
- `lodDistances?`: [number]
- `lodTriangles?`: [integer]
- `parts`: [string]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `triangles?`: integer
- `warnings`: [string]

### `meshBuild.examples`

**Mesh Build Examples** · _read-only_, _idempotent_

Returns small, correct mesh builds to learn from or start with (pass one's `build` to meshBuild.new; keys at their defaults are left out): a street lamp (a parent chain, glow), a wooden cart (wheels turned onto an axle, a spin animation), a turret (a group pivot swinging its children), a weathered crate (looks, wear, mirrored corner caps), a park bench (mirror and repeat, wood and painted iron), three sculpts: an armchair (parts melted together with smooth, cushions in a second fabric as children with their own look), a stone arch (carved with subtracts, roughened with noise) and a ceramic teapot (swept spout and handle melted onto a lathe body, a knob in another glaze), three built from curves: a sailboat (lofted hull, bent mast, billowing sails, swept rigging), a gnarled tree (tapered bark sweeps, leaf-card foliage on branches and in a crown) and a desk lamp (lathes, swept arms, helical springs, a cable), and plants: a flowering shrub, a potted fern (a lathe pot, ribbon fronds) and a small pine (whorls of branches with needle cards). Each stands on y=0, faces -Z and gives no warnings. `name` picks one.

Arguments:

- `name?`: string

Result:

- `examples`: [{about: string, build: any, name: string}]

### `meshBuild.get`

**Get Mesh Build** · _read-only_, _idempotent_

Reads a .meshbuild file: its parts and animations (every field, defaults included), the prefab to place, warnings (broken references; floating, buried, hidden or out-of-scale parts; a model not standing on y=0) and `bounds`: overall size, min, max and base height plus every part's world box (rest pose, meters).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `bounds?`: {base: number, max: number[3], min: number[3], parts?: [object], size: number[3]}
- `build`: {animations?: [object], ao?: boolean, lod?: boolean, lodDistances?: [number], parts?: [object], wind?: number}
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `meshBuild.new`

**New Mesh Build**

Writes a .meshbuild file in `folder` (default: the Assets root) and imports it as a model (a prefab of its parts, one mesh and material per part), optionally placing it in the scene (`place`, at `position`; undoable). Returns the asset, its prefab, the part names, `bounds` and warnings. Edit it later with meshBuild.edit (small changes) or meshBuild.set (whole contents); placed copies update. A mesh build is a model made of shapes: `parts` (each: name, shape group|box|sphere|hemisphere|cylinder|cone|capsule|torus|tube|plane|wedge|pyramid|lathe|extrude|sculpt|sweep|loft|foliage, parent (another part's name; children move with it), position [x,y,z] m: the part's center in the parent's space, rotation [x,y,z] degrees (about X, then Y, then Z, fixed axes; children inherit it), size [x,y,z] m (the box the shape fills; lathe/extrude/sweep/loft: a multiplier, see below), segments, thickness (tube wall), color [r,g,b] 0-1 sRGB, opacity, texture (path under Assets/ such as "Textures/brick.png" or a .proctex, or "asset:<id>"), textureScale [u,v], worldUV (texture keeps its size in meters), metallic, roughness, glow [r,g,b] emitted color, glowStrength, material (a .material asset replacing the look)) and `animations` (each: name, autoplay (default true; every autoplay animation plays at once in play mode and games), loop loop|once|pingPong, speed, motions (ready-made: {part, kind spin|bob|swing|pulse|shake, axis x|y|z (the part's own axes), amount (spin: turns, bob/shake: m, swing: degrees, pulse: growth fraction), period seconds}) and tracks (keyframes: {part, property position|rotation|scale, interpolation linear|hermite|step, keys [{time, value [x,y,z]}]}; values are relative to the part's rest pose: position offset in m, rotation degrees added, scale multiplier (1 = unchanged))). Every key is optional. A group part has no mesh: use it as a pivot (hinge, turret) for animated children. Conventions: meters; +Y is up, the model's front faces -Z (the engine's forward), +X is its right. The origin is the model's base center: it stands on y=0, so a 1 m box on the ground has position [0,0.5,0]. Cylinders, cones, capsules and tubes run along Y: a wheel on an axle along X (a vehicle facing -Z) needs rotation [0,0,90], one on an axle along Z [90,0,0]. Real sizes: person 1.8 m, door 2 x 0.9 m, table top 0.75 m high, chair seat 0.45 m, car about 4.5 x 1.5 x 1.8 m (long, high, wide). Results include `bounds` (size, min, max, base), `triangles` and warnings about floating, buried, hidden or out-of-scale parts and a model off the ground. Workflow: build, look at it with meshBuild.preview, fix the warnings, repeat; meshBuild.examples has correct builds to copy. Rounding: `bevel` (m) rounds a box's edges or a cylinder's rims (0 = sharp, clamped to half the smallest size; segments sets how smooth). Profile shapes: their `profile` points are meters used as written in the part's space (not fitted to size; size multiplies them, so leave size [1,1,1]). `lathe` spins `profile` [[radius, height], ...] (bottom to top) around Y; ends with radius > 0 get flat caps, bends sharper than 40° get a hard edge; segments = steps around. A vase: [[0,0],[0.2,0],[0.26,0.3],[0.12,0.6],[0.16,0.7]]. `extrude` pushes the outline `profile` [[x, y], ...] (either winding, concave is fine, must not cross itself) along Z, size.z m deep and centered in Z; corners sharper than 40° stay hard. An L: [[0,0],[0.6,0],[0.6,0.2],[0.2,0.2],[0.2,1],[0,1]] with size [1,1,0.1]. A bad profile (too few points, no area, crossing itself) builds nothing and gives a warning. Curves: `sweep` moves a section along `path` [[x,y,z],...] (m, part space, at least 2 points; a smooth spline through them, straight:true = straight segments with mitred corners): a circle of `radius` (default 0.05) or a `profile` [[x,y],...] (x = right of the direction of travel, y = up; never twists), `radii` [k,...] multiplies it per path point (taper: [1,0.7,0] makes a horn), `closed`:true joins the end to the start (rings), open ends are capped. Pipe: {"shape":"sweep","path":[[0,0,0],[0,0.5,0],[0.3,0.7,0]],"radius":0.04}. `loft` skins `sections` [{at, size, roundness, profile}] along `axis` (default y; "z" for hulls, fuselages, car bodies lying front to back): at = position along the axis or the center [x,y,z]; size [across, other] m (axis y: [x,z]; z: [x,y]; x: [z,y]); roundness 0 diamond, 1 ellipse (default), 2 squircle, 3 rounded box, 4 box; or profile [[a,b],...] (the same point count in every section keeps its corners exact); smooth spline between sections (straight:true = straight panels); ends capped (size [0,0] = a point). Bottle: {"shape":"loft","sections":[{"at":0,"size":[0.3,0.2],"roundness":2},{"at":0.3,"size":[0.32,0.22],"roundness":2},{"at":0.4,"size":[0.08,0.08]},{"at":0.5,"size":[0.08,0.08]}]}. Sweep and loft numbers are meters as written (size multiplies; leave [1,1,1]). Deform any mesh part: `deform` [{"taper":[x,z]} (scale at the top vs the bottom, along Y), {"bend":{"axis":"x"|"z","degrees":d}} (the top leans toward +axis, d<0 the other way, length kept), {"twist":deg} (about Y, bottom to top), {"noise":{"amount":m,"scale":m,"seed":n}} (bumps for rocks, bark, dents)], applied in order, before mirror (copies deform symmetrically). The mesh is split finely first (`subdivide` 0-6, default 3; 0 = off); hard edges stay hard. Leaning trunk: {"shape":"cylinder","size":[0.3,2,0.3],"deform":[{"taper":[0.6,0.6]},{"bend":{"axis":"x","degrees":25}}]}. Symmetry: a part's mirror ("x"|"y"|"z" or ["x","z"]: every combination) adds a mirror image of it and its children across the parent's plane through its origin, and repeat {count (parts in all, the original first), offset [x,y,z] step per copy, radial {axis (default y), angle (total degrees, default 360 = evenly round), radius (ring around the part's own position; omitted: around the parent's origin)}} adds copies "<name> 2", "<name> 3"… (repeat first, then mirror); a mirror copy's name swaps Left/Right or L/R (x), Top/Bottom or Upper/Lower (y), Front/Back (z), else gets " (mirror x)", copies play their source's animations mirrored, tracks and partColors can name them, and results list them in `copies`. Sculpt: a part with shape "sculpt" draws its children (its whole subtree) as one smooth surface instead of separate shapes, combined in file order. Each child's blend: "add" (default) joins it, "subtract" cuts it out, "intersect" keeps only the overlap; smooth (m, default 0) melts it into what came before over that distance (0.05-0.2 for organic joins, small values just round a cut's edge). Children keep their position/rotation/size in the sculpt's space; every solid shape works (box with bevel, sphere/ellipsoid, hemisphere, cylinder, cone, capsule, torus, tube, wedge, pyramid, lathe, extrude, sweep, loft, and any shape with deform, e.g. a swept spout and handle melted onto a lathe pot; groups are pivots; planes are skipped); mirror/repeat children join too. Sculpt fields: resolution (cells along the longest side, 8-128, default 64: more = finer detail, slower; a sweep or rim needs about 3+ cells across), noise {amount m, scale m, seed} roughens the surface for rock/bark/weathered stone (intersects trim cleanly: intersect a big box standing on y=0, as the last child, for a flat base), size multiplies the mesh (keep [1,1,1]). Looks: the sculpt's color/look/material/roughness… are the default; a child that sets any look field (color, look, wear, roughness, metallic, glow, texture, material…) is drawn with its own look fields (e.g. linen cushions on a green fabric chair, a cream knob on a blue teapot): each point of the surface takes the look of the added child it lies on (in a smooth join, the nearer one). Where they meet with smooth > 0 the looks blend over a band about 1.5 x smooth wide (color, roughness, metallic and glow mix; different textures cross-fade), e.g. moss melting into stone; smooth 0 keeps a sharp line. A subtracted child with its own look paints the cut it makes; without one, the cut takes the look of the child it cuts into. UVs are world-projected in meters. A sculpt is one mesh per look: animate the sculpt part, not its children. Example: {"name":"Stone","shape":"sculpt","position":[0,0.4,0]}, {"name":"Block","shape":"box","parent":"Stone","size":[1,0.8,0.6],"bevel":0.05}, {"name":"Hole","shape":"cylinder","parent":"Stone","rotation":[90,0,0],"size":[0.3,1,0.3],"blend":"subtract","smooth":0.03,"color":[0.1,0.1,0.1]}. Looks: a part's look gives it a realistic surface (generated color, bump, roughness and metal textures, sized in meters, so it looks right at any part size): wood|paintedWood|planks|bark|brushedMetal|polishedMetal|paintedMetal|rustyMetal|gold|copper|brass|stone|cobblestone|concrete|brick|ceramic|plastic|rubber|glass|fabric|leather|dirt|grass. Its color tints the look (the average color: a stain for wood, the paint of paintedMetal; leave color out for the look's own); metallic is ignored, roughness (if set) sets the average. lookScale: meters per texture tile (default per look); wear 0-1: grime in low spots, scratches, chipped paint, darker creases, and worn convex edges and corners (paint chipped to bare metal or wood, lighter rubbed wood, stone and leather, polished edges on rusty and plain metal; sharp and bevelled edges count, smooth round sides don't; chips wrap around edges and corners); grain x|y|z: the part axis wood grain, planks and brushing run along (default: y on round shapes, else the longest side). The file's ao (default false; the examples set true) bakes ambient occlusion, darkening parts where they meet; it tessellates every mesh (to about 30k triangles a model), so leave it off for simple or repeated pieces. Use looks for anything meant to look real. Example: {"name": "Lid", "shape": "box", "size": [0.8, 0.05, 0.6], "look": "planks", "wear": 0.4}, {"name": "Hinge", "look": "paintedMetal", "color": [0.1, 0.1, 0.1], "wear": 0.6}. Foliage and plants: shape "foliage" scatters leaf cards (quads cut out by a leaf look, double-sided, alpha cutout incl. shadows, normals bent outward from the whole cloud so it shades like one rounded volume). Leaf looks: broadleaf, oakLeaves, mapleLeaves, pineNeedles, fern, grassBlades, flowers, ivy (color tints them; leave color out for their own). Without `on`, tree looks fill the ellipsoid of `size` (cards mostly on its shell facing out, some inside); grassBlades, flowers and fern stand crossed tufts on the floor of the box, size.y tall. With `on` ("Branch" or ["Branch A","Twig B"]) cards sprout from the outer part of those sweeps (`along` [from,to] of their length, default [0.35,1]) or cover any other part's surface (ivy on a wall); then size is unused. cardSize m (default 0.35-0.6 per look), density (default 1 = full; 0.5 sparse) or count (exact cards), seed. Each card is 2 triangles (a tuft 4): results give `triangles`; keep a whole tree under about 15k. Crown: {"name":"Crown","shape":"foliage","look":"oakLeaves","parent":"Trunk","position":[0,4,0],"size":[3,2.4,3]}. Tips: put a crown where the branches end (cards touch them) and/or "on" the twigs; use bark look on tapered sweeps for wood (no noise deform needed: the bark normal map gives the relief). Ribbons: a sweep with `ribbon` w (a flat strip w m wide, times radii) or `profile` + `open`:true (an open curve, e.g. a V-fold) is a double-sided surface with no caps: grass blades, leaves on stems, fronds, straps, cloth strips, sail sections. A leaf look on a ribbon or a plane maps one sprig along it (base at the path's start): a fern ribbon is a frond. Frond: {"shape":"sweep","path":[[0,0,0],[0.1,0.35,0],[0.35,0.55,0]],"ribbon":0.22,"radii":[0.6,1,0.5],"look":"fern"}. Game-ready plants (builds with foliage or leaf looks): they sway in the scene's wind (SceneEnvironment.wind: direction, strength, gustiness; set it with component.setField "SceneEnvironment.wind.strength"): the whole plant bends from its base at y=0 and leaves flutter; pots, rocks and other non-sweep parts stay still; file-level "wind" scales it (0 = still). Imports also make detail levels: level 1 half the cards (larger) and other parts with fewer segments, level 2 a quarter, then an impostor (3 crossed quads with baked pictures of the plant, 6 triangles); parts with equal materials merge at far levels; all parts switch together at 8/16/32x the plant's radius. "lod": false turns them off, "lodDistances": [m1, m2, m3] sets the distances. Results give `lodTriangles` (full, 1, 2, impostor) and `lodDistances`. Many placed copies draw instanced (one draw per part and level for the whole forest). meshBuild.preview shows full detail in still air.

Arguments:

- `build?`: {animations?: [object], ao?: boolean, lod?: boolean, lodDistances?: [number], parts?: [object], wind?: number}
- `folder?`: string
- `name?`: string
- `place?`: boolean
- `position?`: number[3] — [x, y, z]

Result:

- `animations`: [string]
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `bounds?`: {base: number, max: number[3], min: number[3], parts?: [object], size: number[3]}
- `copies?`: [string]
- `entities?`: [entity id]
- `lodDistances?`: [number]
- `lodTriangles?`: [integer]
- `parts`: [string]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `triangles?`: integer
- `warnings`: [string]

### `meshBuild.open`

**Open in Mesh Builder** · _idempotent_

Opens a .meshbuild file in the editor's Mesh Builder tab (a viewport showing just the model, with gizmos to place parts, live animation preview and the parts form) and brings the tab to the front. view.screenshot {source: "panel", panel: "meshBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `meshBuild.preview`

**Preview Mesh Build** · _read-only_, _idempotent_, _deferred_

Returns one PNG of a .meshbuild model from fixed angles, tiled: by default front (camera at -Z, the model's front; +X is on the image's left), right (from +X), top (front up) and a 3/4 perspective; `views` picks and orders them (also back, left). Front / right / top are orthographic, each auto-framed with a ground grid (spacing in the caption; red line z=0, blue x=0) and a white ground line at y=0. `size`: tile pixels (default 384). `labels`: part names at their centers. `highlight`: part names to outline (a sculpt child outlines the surface it owns: its look's mesh). `animation` + `time`: pose that animation at `time` seconds. `environment`: what lights the model, "studio" (default: a neutral photo studio with softboxes that metals reflect), "outdoor" (the procedural sky) or "flat" (plain ambient light, nothing to reflect). Also returns a summary (size in m, part count), the bounds and the same warnings as meshBuild.get. Read-only: the model is shown in a world of its own, not the scene. Finishes after a few frames. Needs the editor window.

Arguments:

- `animation?`: string
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `environment?`: "studio" \| "outdoor" \| "flat"
- `highlight?`: [string]
- `labels?`: boolean
- `path?`: string
- `size?`: integer
- `time?`: number
- `views?`: ["front" \| "right" \| "top" \| "threeQuarter" \| "back" \| "left"]

Result:

- `bounds?`: {base: number, max: number[3], min: number[3], parts?: [object], size: number[3]}
- `image`: {data?: string, height: integer, mimeType: string, width: integer}
- `summary`: string
- `views`: ["front" \| "right" \| "top" \| "threeQuarter" \| "back" \| "left"]
- `warnings`: [string]

### `meshBuild.set`

**Set Mesh Build** · _undoable_, _idempotent_

Replaces a .meshbuild file's whole contents and reimports it; placed copies update. Undoable. For a few changes, meshBuild.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `build`: {animations?: [object], ao?: boolean, lod?: boolean, lodDistances?: [number], parts?: [object], wind?: number}
- `path?`: string

Result:

- `animations`: [string]
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `bounds?`: {base: number, max: number[3], min: number[3], parts?: [object], size: number[3]}
- `copies?`: [string]
- `entities?`: [entity id]
- `lodDistances?`: [number]
- `lodTriangles?`: [integer]
- `parts`: [string]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `triangles?`: integer
- `warnings`: [string]

## navigation

### `navigation.bake`

**Bake Navigation** · _read-only_

Bakes the navmesh behavior trees and `world.findPath` walk on from the static colliders of the current world (the play world while playing): voxelized, eroded by the agent radius, cut into layer regions and convex polygons with detail heights, so floors above one another, ramps and bridges work; NavigationLink components add off-mesh links (jumps, drops, ladders). A NavigationArea component sets the box and the agent (radius, height, step, slope, voxelSize, maxPolygonSize). Reports the polygon count, bake time and warnings (areas the largest can't reach, links off the mesh). Bakes are cached in the project's Library/Navigation by what they were baked from (`force` bakes anyway) and cooked into exported games, which load them instead of baking. The grid fallback is baked too. Game code: `world.bakeNavMesh()`.

Arguments:

- `force?`: boolean
- `overlay?`: boolean

Result:

- `area`: number
- `baked`: boolean
- `boundsMax?`: number[3] — [x, y, z]
- `boundsMin?`: number[3] — [x, y, z]
- `cacheFile?`: string
- `cached`: boolean
- `islands`: integer
- `milliseconds`: number
- `offMeshLinks`: integer
- `polygons`: integer
- `regions`: integer
- `voxelSize`: number
- `warnings`: [string]

### `navigation.overlay`

**Show Navigation** · _idempotent_

Shows or hides the navmesh in the Scene view: polygons tinted by region (areas the largest can't reach in red), their outlines, off-mesh links as arcs, the paths behavior tree agents are walking and the last `navigation.query` path. It draws the current world's navmesh as last baked (`navigation.bake`). view.screenshot shows it with gizmos on.

Arguments:

- `show?`: boolean

Result:

- `polygons`: integer
- `shown`: boolean

### `navigation.query`

**Query Navigation** · _read-only_

Tests navigation in the current world (baking it first if it has none): with `from` and `to`, the path an agent would walk (on the navmesh when there is one, else the grid; `partial` returns the way to the nearest reachable point), how each segment is crossed (walk, jump, drop, ladder), its length, and whether the ends are on the mesh and connected; with `point`, whether the point is walkable and the nearest walkable point. The navigation overlay (`navigation.overlay`) draws the last path found.

Arguments:

- `from?`: number[3] — [x, y, z]
- `partial?`: boolean
- `point?`: number[3] — [x, y, z]
- `to?`: number[3] — [x, y, z]

Result:

- `baked`: boolean
- `connected?`: boolean
- `found`: boolean
- `fromOnMesh?`: boolean
- `length`: number
- `nearest?`: number[3] — [x, y, z]
- `path`: [number[3]]
- `pointOnMesh?`: boolean
- `segments`: [string]
- `surface`: string
- `toOnMesh?`: boolean

## net

### `net.overlay`

**Network Stats Overlay**

Whether the viewport shows the network stats overlay during network play (RTT, loss, kbit/s, interpolation buffer per client). On by default.

Arguments:

- `enabled?`: boolean

Result:

- `active`: boolean
- `clients`: [{connected: boolean, down: object, entities: integer, index: integer, up: object}]
- `overlay`: boolean
- `replicatesAll`: boolean
- `view`: string

### `net.setConditions`

**Set Network Conditions** · _idempotent_

Simulated link between the server and `client` (omitted: every client), `direction` "both" (default), "down" (server to client) or "up": `latencyMs` one way (0-5000), `jitterMs` (extra delay, uniform, so packets reorder), `loss` and `duplicate` (fractions 0-1). Omitted fields keep their value. Applies to packets sent from now on. Returns the network play state with every client's conditions.

Arguments:

- `client?`: integer
- `direction?`: string
- `duplicate?`: number
- `jitterMs?`: number
- `latencyMs?`: number
- `loss?`: number

Result:

- `active`: boolean
- `clients`: [{connected: boolean, down: object, entities: integer, index: integer, up: object}]
- `overlay`: boolean
- `replicatesAll`: boolean
- `view`: string

### `net.start`

**Play with Clients**

Plays the scene as a server with `clients` client worlds (1-8, default 2) in this process, on a simulated network (`latencyMs` one way, `jitterMs`, `loss` and `duplicate` fractions; default perfect). Starts play mode if needed; each client loaded the scene as play started, so entities are matched by id, and what the server does reaches them as snapshots (30 Hz, interpolated 100 ms behind). Clients only display: systems, physics and input run on the server. `replicate`: "marked" sends entities with a Replicated component; "all" gives every entity with a Transform one (Transform, MeshRenderer, Name), also ones spawned later; "auto" (default) is "marked" when the scene has Replicated components, else "all". Restarts network play when it runs. Then: net.view, net.setConditions, net.stats; play.stop ends it.

Arguments:

- `clients?`: integer
- `duplicate?`: number
- `jitterMs?`: number
- `latencyMs?`: number
- `loss?`: number
- `replicate?`: string

Result:

- `active`: boolean
- `clients`: [{connected: boolean, down: object, entities: integer, index: integer, up: object}]
- `overlay`: boolean
- `replicatesAll`: boolean
- `view`: string

### `net.stats`

**Network Stats** · _read-only_, _idempotent_

Every connection's numbers during network play: for each client as the server sees it and as the client does, RTT (ms), loss (%), bytes in / out per second (last second) and in total, packets, snapshots, the last snapshot's size and deferred entities (server), the interpolation delay, what is buffered and starved frames (client), its replicated entities and those waiting for their parent; plus the simulated network's totals.

Arguments: none.

Result:

- `clients`: [{bufferedMs?: number, bufferedSnapshots?: integer, bytesIn: integer, bytesInPerSecond: number, bytesOut: integer, bytesOutPerSecond: number, connected: boolean, corrections?: integer, deferredEntities?: integer, entities?: integer, interpolationDelayMs?: number, lastCorrection?: number, lastSnapshotBytes?: integer, lossPercent: number, missingBaseline?: integer, name: string, packetsIn: integer, packetsOut: integer, reconciliations?: integer, rttMs?: number, snapshots: integer, starvedFrames?: integer, unresolvedParents?: integer}]
- `network`: {bytesSent: integer, packetsDelivered: integer, packetsDropped: integer, packetsSent: integer}
- `server`: [{bufferedMs?: number, bufferedSnapshots?: integer, bytesIn: integer, bytesInPerSecond: number, bytesOut: integer, bytesOutPerSecond: number, connected: boolean, corrections?: integer, deferredEntities?: integer, entities?: integer, interpolationDelayMs?: number, lastCorrection?: number, lastSnapshotBytes?: integer, lossPercent: number, missingBaseline?: integer, name: string, packetsIn: integer, packetsOut: integer, reconciliations?: integer, rttMs?: number, snapshots: integer, starvedFrames?: integer, unresolvedParents?: integer}]
- `time`: number

### `net.stop`

**Stop Network Play**

Disconnects the clients and drops their worlds; play mode goes on with the server's world alone (play.stop ends both).

Arguments: none.

Result:

- `active`: boolean
- `clients`: [{connected: boolean, down: object, entities: integer, index: integer, up: object}]
- `overlay`: boolean
- `replicatesAll`: boolean
- `view`: string

### `net.view`

**Game View Source** · _idempotent_

Which world the Game View (view.gameCamera) and view.screenshot {source: "game"} show during network play: "server" (the scene's world) or a client ("client 2", or "2"), through that world's Camera entity. The scene view (Game View off) always shows the server.

Arguments:

- `target`: string

Result:

- `active`: boolean
- `clients`: [{connected: boolean, down: object, entities: integer, index: integer, up: object}]
- `overlay`: boolean
- `replicatesAll`: boolean
- `view`: string

## panel

### `panel.close`

**Close Panel** · _idempotent_

Closes a panel (its tab's close button); panel.open or layout.reset bring it back. The viewport can't be closed.

Arguments:

- `panel`: string

### `panel.dock`

**Dock Panel**

Moves a panel (as dragging its tab does): as a tab with `tabWith`, to an `edge` (left, right, top, bottom) of `beside` or of the whole dock taking `fraction`, or into a `floating` window. The layout is saved; layout.reset restores the default.

Arguments:

- `beside?`: string
- `edge?`: "left" \| "right" \| "top" \| "bottom"
- `floating?`: [number]
- `fraction?`: number
- `panel`: string
- `tabWith?`: string

### `panel.focus`

**Show Panel** · _idempotent_

Brings a panel's tab to the front (opening it where the default layout has it when closed), as clicking its tab does.

Arguments:

- `panel`: string

### `panel.list`

**Panels** · _read-only_, _idempotent_

The editor's dock panels (viewport, hierarchy, inspector, assets, console, activity, stats): open, selected (its tab in front), floating, closable and the content's rect.

Arguments: none.

Result:

- `panels`: [{closable: boolean, floating: boolean, id: string, open: boolean, rect?: [number], selected: boolean, title: string}]

### `panel.open`

**Open Panel** · _idempotent_

Opens a closed panel (where the default layout has it, or at `placement`) and brings it to the front; an open one just comes to the front.

Arguments:

- `panel`: string
- `placement?`: {beside?: string, edge?: "left" \| "right" \| "top" \| "bottom", floating?: [number], fraction?: number, tabWith?: string}

## path

### `path.edit`

**Edit Path** · _undoable_

Changes a .path file in one undoable step, in this order: kind (applies that preset's profiles and pieces), points (replace all), removePoints, insertPoints, addPoints, updatePoints ({index, position?, bank?, width?}), the curve settings (closed, smooth, spacing, bank, autoBank), profile (fields to change on `profileName` or the first profile), removeProfiles, addProfiles, updateProfiles (name → fields), removePieces, addPieces, updatePieces, terrain (fields: asset, offset, height), removeJunctions (other paths' paths), addJunctions ({path, radius, offset}; replaces one with the same path). Placed copies update. Returns the length, piece counts and warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `addJunctions?`: [{offset?: number[3], path?: string, radius?: number}]
- `addPieces?`: [{asset?: string, collider?: boolean, color?: number[3], material?: string, metallic?: number, mirror?: boolean, name?: string, offset?: number[3], rotation?: number[3], roughness?: number, scale?: number, shape?: string (18 cases), size?: number[3], spacing?: number, start?: number, upright?: boolean}]
- `addPoints?`: [number[3]]
- `addProfiles?`: [{closedShape?: boolean, collider?: boolean, color?: number[3], glow?: number[3], height?: number, material?: string, metallic?: number, name?: string, offset?: number[2], opacity?: number, points?: [number[2]], roughness?: number, sag?: number, shape?: "flat" \| "box" \| "tube" \| "custom", sides?: integer, texture?: string, textureScale?: number[2], width?: number}]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `autoBank?`: number
- `bank?`: number
- `closed?`: boolean
- `insertPoints?`: [{index: integer, points: [number[3]]}]
- `kind?`: "road" \| "rail" \| "river" \| "fence" \| "cable" \| "wall" \| "custom"
- `path?`: string
- `points?`: [number[3]]
- `profile?`: any — Any JSON value.
- `profileName?`: string
- `removeJunctions?`: [string]
- `removePieces?`: [string]
- `removePoints?`: [integer]
- `removeProfiles?`: [string]
- `smooth?`: boolean
- `spacing?`: number
- `terrain?`: any — Any JSON value.
- `updatePieces?`: object
- `updatePoints?`: [{bank?: number, index: integer, position?: number[3], width?: number}]
- `updateProfiles?`: object

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `entities?`: [entity id]
- `kind`: "road" \| "rail" \| "river" \| "fence" \| "cable" \| "wall" \| "custom"
- `length`: number
- `path`: string
- `pieceCounts`: [integer]
- `pieces`: [string]
- `points`: integer
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `profiles`: [string]
- `terrain?`: string
- `warnings`: [string]

### `path.flattenTerrain`

**Flatten Terrain Under Path**

Shapes a .terrain's heights to a .path, writing them into the .terrain file as one undo step: under the path (`width` meters across, default the widest profile) the ground is set to the path's ground level (the centerline on the followed terrain averaged over `smoothing` meters, less `depth`; or the path's own heights when it doesn't follow that terrain), blending back over `shoulder` meters each side. mode: flatten (cut and fill), carve (only lower: cuttings, river beds with `depth`) or raise (only raise: embankments). The terrain is the one the path follows unless `terrain` names another. The path then reimports onto the new ground. Cross-sections come out level (banking is ignored).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `depth?`: number
- `mode?`: "flatten" \| "carve" \| "raise"
- `path?`: string
- `shoulder?`: number
- `smoothing?`: number
- `terrain?`: string
- `width?`: number

Result:

- `changedSamples`: integer
- `clampedSamples`: integer
- `largestChange`: number
- `terrain`: string

### `path.get`

**Get Path** · _read-only_, _idempotent_

Reads a .path file: every field (defaults included) and a summary (length, piece counts, the followed terrain, problems). path.sample returns points along it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `build`: {autoBank?: number, bank?: number, closed?: boolean, junctions?: [object], kind?: string (7 cases), pieces?: [object], points?: [number[3]], profiles?: [object], smooth?: boolean, spacing?: number, terrain?: {asset?: string, height?: number, offset?: number[3]}}
- `summary`: {asset: asset id, entities?: [entity id], kind: string (7 cases), length: number, path: string, pieceCounts: [integer], pieces: [string], points: integer, prefab: asset id, profiles: [string], terrain?: string, warnings: [string]}

### `path.new`

**New Path**

Writes a .path file in `folder` (default: the Assets root) from a `kind` preset (road: a road bed with a center line and a collider; rail: ballast, two rails and sleepers; river: water over a bed; fence: posts and two rails; cable: a sagging wire 6 m up; wall: a wall with a cap), through `points` (default an S curve), optionally following a terrain and placed in the scene. Then reshape it with path.edit. A path is a spline through `points` (each [x,y,z] meters, or {position, bank (degrees, positive lowers the right side), width (multiplies the profiles' widths there)}), `closed` (a loop), `smooth` (Catmull-Rom; false: straight lines), `spacing` (meters between samples), `bank` (degrees added everywhere), `autoBank` (extra degrees in tight turns), `kind` (road, rail, river, fence, cable, wall, custom), `profiles` (cross-sections swept into meshes; each: name, shape flat|box|tube|custom, width, height, offset [right, up] meters from the centerline, sides (tube), points (custom outline [right, up], counter-clockwise seen along the path), closedShape, sag (cables hang this far between control points), color [r,g,b] 0-1 sRGB, opacity, metallic, roughness, glow, texture, textureScale [across, per meter along], material, collider), `pieces` (repeated along the path; each: name, asset (a .meshbuild path or "asset:<id>#mesh/<name>"; empty uses shape/size/color, a Mesh Builder shape such as box or cylinder), spacing meters, start, offset [right, up, forward], rotation degrees, scale, upright, mirror (also on the other side), collider) and `terrain` {asset (a .terrain path), offset (the terrain's origin in the path's space), height (meters above the ground)}: with a terrain every sample and piece sits on its surface (point y is ignored). `junctions` (other paths this one meets; each: path (a .path under Assets/ or "asset:<id>"), radius (meters of corner rounding, default 3), offset (the other path's origin in this path's space)): where this path's end stops at, just short of or just past the other road it makes a T, where it crosses the other road it makes an X; this path is cut back from the other road's edges (its profiles and pieces leave a gap) and a patch with rounded corners paves the gap with its widest flat or box profile, at both roads' heights. The other road stays whole. Forward is the direction of travel, right is level with the ground. Every key is optional.

Arguments:

- `closed?`: boolean
- `folder?`: string
- `kind?`: "road" \| "rail" \| "river" \| "fence" \| "cable" \| "wall" \| "custom"
- `name?`: string
- `place?`: boolean
- `points?`: [number[3]]
- `position?`: number[3] — [x, y, z]
- `terrain?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `entities?`: [entity id]
- `kind`: "road" \| "rail" \| "river" \| "fence" \| "cable" \| "wall" \| "custom"
- `length`: number
- `path`: string
- `pieceCounts`: [integer]
- `pieces`: [string]
- `points`: integer
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `profiles`: [string]
- `terrain?`: string
- `warnings`: [string]

### `path.open`

**Open in Path Builder** · _idempotent_

Opens a .path file in the editor's Path Builder tab (a viewport showing the path over the terrain it follows, control-point handles you click and drag with the Move gizmo, and the points, profiles and pieces forms) and brings the tab to the front. view.screenshot {source: "panel", panel: "pathBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `path.sample`

**Sample Path** · _read-only_, _idempotent_

Returns points along a .path's centerline (on its terrain when it follows one), in the path's space: position, forward (direction of travel), right and up (after banking), and the distance in meters. Use it to place things along a road or river (add the placed path entity's position). To move an entity along the path at run time, give it a PathFollower component (path: "asset:<id>", speed, mode once | loop | pingPong, orient, placedAt: the placed path entity's name).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `count?`: integer
- `distances?`: [number]
- `path?`: string

Result:

- `length`: number
- `points`: [{distance: number, forward: number[3], position: number[3], right: number[3], up: number[3]}]

### `path.set`

**Set Path** · _undoable_, _idempotent_

Replaces a .path file's whole contents and reimports it; placed copies update. Undoable. For a few changes path.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `build`: {autoBank?: number, bank?: number, closed?: boolean, junctions?: [object], kind?: string (7 cases), pieces?: [object], points?: [number[3]], profiles?: [object], smooth?: boolean, spacing?: number, terrain?: {asset?: string, height?: number, offset?: number[3]}}
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `entities?`: [entity id]
- `kind`: "road" \| "rail" \| "river" \| "fence" \| "cable" \| "wall" \| "custom"
- `length`: number
- `path`: string
- `pieceCounts`: [integer]
- `pieces`: [string]
- `points`: integer
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `profiles`: [string]
- `terrain?`: string
- `warnings`: [string]

## physics

### `physics.materialAt`

**Material Under Point** · _read-only_, _idempotent_

Returns the physics material of the collider under `point` (a ray straight down up to `distance`, default 2 m): its name, friction, bounce and whether characters climb it, the entity and the surface point. Terrain colliders answer per painted layer. Works while playing and while editing (then from the scene's colliders as they are).

Arguments:

- `distance?`: number
- `point`: number[3] — [x, y, z]

Result:

- `bounce?`: number
- `climbable?`: boolean
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `friction?`: number
- `hit`: boolean
- `material?`: string
- `normal?`: number[3] — [x, y, z]
- `point?`: number[3] — [x, y, z]

## physicsMaterial

### `physicsMaterial.edit`

**Edit Physics Material** · _undoable_

Changes some keys of a .physmat file in one undoable step (`changes`: key → new value, null to unset it; whole objects replace, e.g. `impact`). Returns the new contents, the numbers colliders get and warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `changes`: any — Any JSON value.
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `bounce`: number
- `density`: number
- `friction`: number
- `material`: {bounce?: number, climbable?: boolean, density?: number, footstep?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, friction?: number, impact?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, minImpactSpeed?: number, minScrapeSpeed?: number, pairs?: object, scrape?: {pitch?: number, sound?: string, vfx?: string, volume?: number}}
- `name`: string
- `path`: string
- `warnings`: [string]

### `physicsMaterial.get`

**Get Physics Material** · _read-only_, _idempotent_

Reads a .physmat file: its keys, the friction, bounce and density colliders get, and warnings.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `bounce`: number
- `density`: number
- `friction`: number
- `material`: {bounce?: number, climbable?: boolean, density?: number, footstep?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, friction?: number, impact?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, minImpactSpeed?: number, minScrapeSpeed?: number, pairs?: object, scrape?: {pitch?: number, sound?: string, vfx?: string, volume?: number}}
- `name`: string
- `path`: string
- `warnings`: [string]

### `physicsMaterial.list`

**List Physics Materials** · _read-only_, _idempotent_

Lists the physics materials a PhysicsSurface can name: the built-ins and the project's .physmat files, with friction, bounce, density, climbable and which effects each has.

Arguments: none.

Result:

- `materials`: [{bounce?: number, builtIn: boolean, climbable?: boolean, density?: number, effects: [string], friction?: number, name: string, pairs: integer}]

### `physicsMaterial.new`

**New Physics Material**

Writes a .physmat file in `folder` (default: the Assets root) from `preset` (a built-in's friction, bounce and density) or `material`. Returns the asset, the name to put in a PhysicsSurface, the effective numbers and warnings (out-of-range values, sounds or effects that don't exist, unknown pair materials). A physics material (.physmat, every key optional) says what a surface is made of: friction (Coulomb, a pair uses the geometric mean; ice 0.03, rubber 1), bounce (restitution 0-1, a pair uses the larger), density (kg/m³, for dynamic bodies), climbable (characters climb walls of it), footstep / impact / scrape effects ({sound, vfx, volume, pitch}: sound an audio file or .sfx path, vfx a .vfx or prefab path), minImpactSpeed (m/s, default 1.5), minScrapeSpeed (default 0.5) and pairs ({"<other material>": {impact: {...}, scrape: {...}, footstep: {...}}}, used instead of either material's own effects). Unset friction, bounce or density keep the Collider's own. Use it by adding a PhysicsSurface component {material: "<path or built-in>"} to an entity with a Collider (or an ancestor of one), a Mesh Builder part's `physicsMaterial` or a terrain layer's `physicsMaterial`. Built-ins: brick, ceramic, climbingWall, concrete, default, dirt, fabric, glass, grass, ice, metal, mud, plastic, rubber, sand, stone, wood.

Arguments:

- `folder?`: string
- `material?`: {bounce?: number, climbable?: boolean, density?: number, footstep?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, friction?: number, impact?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, minImpactSpeed?: number, minScrapeSpeed?: number, pairs?: object, scrape?: {pitch?: number, sound?: string, vfx?: string, volume?: number}}
- `name?`: string
- `preset?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `bounce`: number
- `density`: number
- `friction`: number
- `material`: {bounce?: number, climbable?: boolean, density?: number, footstep?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, friction?: number, impact?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, minImpactSpeed?: number, minScrapeSpeed?: number, pairs?: object, scrape?: {pitch?: number, sound?: string, vfx?: string, volume?: number}}
- `name`: string
- `path`: string
- `warnings`: [string]

### `physicsMaterial.set`

**Set Physics Material** · _undoable_, _idempotent_

Replaces a .physmat file's whole contents and reimports it. Undoable. While playing, bodies pick the change up on their next sync. For a few changes, physicsMaterial.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `material`: {bounce?: number, climbable?: boolean, density?: number, footstep?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, friction?: number, impact?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, minImpactSpeed?: number, minScrapeSpeed?: number, pairs?: object, scrape?: {pitch?: number, sound?: string, vfx?: string, volume?: number}}
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `bounce`: number
- `density`: number
- `friction`: number
- `material`: {bounce?: number, climbable?: boolean, density?: number, footstep?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, friction?: number, impact?: {pitch?: number, sound?: string, vfx?: string, volume?: number}, minImpactSpeed?: number, minScrapeSpeed?: number, pairs?: object, scrape?: {pitch?: number, sound?: string, vfx?: string, volume?: number}}
- `name`: string
- `path`: string
- `warnings`: [string]

## play

### `play.pause`

**Pause**

Pauses play mode (`paused` true), resumes it (false) or toggles (omitted). Paused, the world doesn't update and scheduled input waits; edits still apply.

Arguments:

- `paused?`: boolean

Result:

- `buttons`: ["left" \| "right" \| "middle"]
- `frame`: integer
- `gameCamera`: boolean
- `inputPending`: integer
- `inputSeconds`: number
- `keys`: [string (74 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
- `reason?`: string
- `stepped?`: integer
- `time`: number
- `timeScale`: number

### `play.setTimeScale`

**Set Time Scale** · _idempotent_

Multiplies play mode's dt by `scale` (0 to 100; 1 is real time). Steps use their own dt.

Arguments:

- `scale`: number

Result:

- `buttons`: ["left" \| "right" \| "middle"]
- `frame`: integer
- `gameCamera`: boolean
- `inputPending`: integer
- `inputSeconds`: number
- `keys`: [string (74 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
- `reason?`: string
- `stepped?`: integer
- `time`: number
- `timeScale`: number

### `play.start`

**Play** · _idempotent_

Snapshots the scene and runs its systems (with physics when it has colliders); edits while playing apply to the live world and are discarded on stop. `paused` starts paused, for play.step.

Arguments:

- `paused?`: boolean

Result:

- `buttons`: ["left" \| "right" \| "middle"]
- `frame`: integer
- `gameCamera`: boolean
- `inputPending`: integer
- `inputSeconds`: number
- `keys`: [string (74 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
- `reason?`: string
- `stepped?`: integer
- `time`: number
- `timeScale`: number

### `play.state`

**Play State** · _read-only_, _idempotent_

Returns whether the editor is playing and paused, the time scale, game frames and seconds run, scheduled input, keys and buttons down in the game, and whether physics runs.

Arguments: none.

Result:

- `buttons`: ["left" \| "right" \| "middle"]
- `frame`: integer
- `gameCamera`: boolean
- `inputPending`: integer
- `inputSeconds`: number
- `keys`: [string (74 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
- `reason?`: string
- `stepped?`: integer
- `time`: number
- `timeScale`: number

### `play.step`

**Step**

Pauses play mode and runs `frames` game frames now (default 1), each `dt` seconds (default 1/60), with the input scheduled for them. Deterministic: the same scene, input and steps give the same result. With `until` {entity, stopped: true, epsilon?, window?} it runs frames (at most `maxFrames`, default 600) until the entity's world position moved less than `epsilon` (default 0.001) over the last `window` frames (default 10), i.e. it came to rest. Returns the play state with `stepped` (frames run) and `reason`: "frames" (ran them all), "stopped" (the condition held) or "maxFrames" (it never did: the entity is still moving).

Arguments:

- `dt?`: number
- `frames?`: integer
- `maxFrames?`: integer
- `until?`: {entity: entity id, epsilon?: number, stopped: boolean, window?: integer}

Result:

- `buttons`: ["left" \| "right" \| "middle"]
- `frame`: integer
- `gameCamera`: boolean
- `inputPending`: integer
- `inputSeconds`: number
- `keys`: [string (74 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
- `reason?`: string
- `stepped?`: integer
- `time`: number
- `timeScale`: number

### `play.stop`

**Stop** · _idempotent_

Leaves play mode, restoring the scene as it was when Play was pressed.

Arguments: none.

### `play.toggle`

**Play / Stop**

Play when editing, Stop when playing.

Arguments: none.

## playtest

### `playtest.assert`

**Assert**

Checks the world now and records pass / fail in the playtest session (made if there is none). The value: `entity` (a name, a path "Level/Door" or an id) alone checks it exists; with `component` and `field` a component field ("position.x", "linearVelocity"); with `variable` a visual script variable; with only `field` its world transform ("position", "position.y", "rotation", "scale"); or `count` {name?, component?} of entities. Compared with `exists`, `equals` (numbers within `tolerance`, default 1e-4), `min` / `max`, or `near` [x, y, z] within `tolerance` (default 0.01). Returns the check: passed, message, the actual value. A failing assertion is a result, not a tool error.

Arguments:

- `component?`: string
- `count?`: {component?: string, name?: string}
- `entity?`: string
- `equals?`: any — Any JSON value.
- `exists?`: boolean
- `field?`: string
- `label?`: string
- `max?`: number
- `min?`: number
- `near?`: [number]
- `tolerance?`: number
- `variable?`: string

Result:

- `actual?`: any — Any JSON value.
- `frame`: integer
- `label`: string
- `message`: string
- `passed`: boolean
- `step?`: integer
- `time`: number

### `playtest.result`

**Playtest Result** · _read-only_, _idempotent_

Returns the playtest session's result: every assertion so far (label, passed, message, actual value, frame), `passed` (none failed and no step errored), step errors, frames run and how many steps are recorded. Still readable after playtest.stop.

Arguments: none.

Result:

- `checks`: [{actual?: any, frame: integer, label: string, message: string, passed: boolean, step?: integer, time: number}]
- `errors`: [string]
- `failedCount`: integer
- `frames`: integer
- `name?`: string
- `passed`: boolean
- `passedCount`: integer
- `recordedSteps`: integer
- `recording`: boolean
- `time`: number

### `playtest.run`

**Run Playtest**

Replays a playtest (`path` to a .playtest.json file, or the `playtest` itself) in play mode: opens its `scene` when another one is open (refused while that one has unsaved changes), plays from the start paused, runs every step at the fixed dt and checks its assertions, then stops (`keepPlaying` keeps the end state). Returns the result; `passed` is false when an assertion failed or a step couldn't run.

Arguments:

- `keepPlaying?`: boolean
- `path?`: string
- `playtest?`: {actions?: object, dt?: number, format?: string, name?: string, scene?: string, steps?: [object], version?: integer}

Result:

- `checks`: [{actual?: any, frame: integer, label: string, message: string, passed: boolean, step?: integer, time: number}]
- `errors`: [string]
- `failedCount`: integer
- `frames`: integer
- `name?`: string
- `passed`: boolean
- `passedCount`: integer
- `recordedSteps`: integer
- `recording`: boolean
- `time`: number

### `playtest.save`

**Save Playtest**

Writes what the playtest session recorded since playtest.start (input, frames and assertions, with the scene) as a playtest JSON file: `path` relative to the project folder (".playtest.json" added when missing). Replay it with playtest.run, or headless with `GameRunner <module> --playtest <file>` (exit code 1 when an assertion fails). Overwrites an existing file. Works during play and after playtest.stop.

Arguments:

- `path`: string

Result:

- `assertions`: integer
- `frames`: integer
- `path`: string
- `steps`: integer

### `playtest.start`

**Start Playtest**

Starts a playtest session: Play from the scene as saved in the editor (stopping play first if it runs), paused at frame 0, recording (unless `record` is false) every input.action, input.gamepad, input.inject, input.clear, play.step and playtest.assert for playtest.save. `actions` adds input actions (name → sources such as "key.space", "pad.south", "axis.leftStickX") to the scene's visual scripts' ones. Assertions collect in playtest.result.

Arguments:

- `actions?`: object
- `name?`: string
- `record?`: boolean

Result:

- `buttons`: ["left" \| "right" \| "middle"]
- `frame`: integer
- `gameCamera`: boolean
- `inputPending`: integer
- `inputSeconds`: number
- `keys`: [string (74 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
- `reason?`: string
- `stepped?`: integer
- `time`: number
- `timeScale`: number

### `playtest.stop`

**Stop Playtest**

Ends the playtest session's recording and stops play mode (the scene is restored; `keepPlaying` keeps it running). Returns the session's result; playtest.save still saves the recording.

Arguments:

- `keepPlaying?`: boolean

Result:

- `checks`: [{actual?: any, frame: integer, label: string, message: string, passed: boolean, step?: integer, time: number}]
- `errors`: [string]
- `failedCount`: integer
- `frames`: integer
- `name?`: string
- `passed`: boolean
- `passedCount`: integer
- `recordedSteps`: integer
- `recording`: boolean
- `time`: number

## postfx

### `postfx.assign`

**Assign Post-FX** · _undoable_

Assigns a .postfx profile to a camera (sets Camera.postFX; default: the active camera) or to a PostFXVolume entity (sets its profile). Undoable. A camera's profile replaces the scene's PostProcess component; volumes blend over it by priority. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `clear?`: boolean
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `path?`: string

Result:

- `path`: string

### `postfx.edit`

**Edit Post-FX** · _undoable_

Changes some settings of a .postfx profile in one undoable step: optionally restart from a `preset`, then set the keys in `changes` (others keep their values). Returns the full contents and warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `changes?`: any — Any JSON value.
- `path?`: string
- `preset?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `path`: string
- `settings`: {adaptationSpeed?: number, aperture?: number, autoExposure?: boolean, autoExposureMax?: number, autoExposureMin?: number, bloom?: boolean, bloomIntensity?: number, chromaticAberration?: number, contrast?: number, depthOfField?: boolean, exposure?: number, filmGrain?: number, focalLength?: number, focusDistance?: number, focusRange?: number, focusTarget?: string, gain?: number[3], gamma?: number[3], lift?: number[3], lut?: string, lutIntensity?: number, maxBlur?: number, saturation?: number, tonemapper?: "none" \| "reinhard" \| "neutral" \| "aces", vignette?: number, vignetteSoftness?: number}
- `warnings`: [string]

### `postfx.get`

**Get Post-FX** · _read-only_, _idempotent_

Reads a .postfx profile: every setting (defaults included) and warnings about out-of-range values.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `path`: string
- `settings`: {adaptationSpeed?: number, aperture?: number, autoExposure?: boolean, autoExposureMax?: number, autoExposureMin?: number, bloom?: boolean, bloomIntensity?: number, chromaticAberration?: number, contrast?: number, depthOfField?: boolean, exposure?: number, filmGrain?: number, focalLength?: number, focusDistance?: number, focusRange?: number, focusTarget?: string, gain?: number[3], gamma?: number[3], lift?: number[3], lut?: string, lutIntensity?: number, maxBlur?: number, saturation?: number, tonemapper?: "none" \| "reinhard" \| "neutral" \| "aces", vignette?: number, vignetteSoftness?: number}
- `warnings`: [string]

### `postfx.new`

**New Post-FX**

Writes a .postfx profile in `folder` (default: the Assets root) from a `preset` (default neutral) with optional `settings` overrides, and imports it. Returns the asset, its contents and warnings. Assign it with postfx.assign, tweak it with postfx.edit. A post-fx profile is a camera look; every key is optional (missing = neutral): tonemapper none|reinhard|neutral|aces, exposure (EV stops, -10..10), autoExposure (bool), autoExposureMin/autoExposureMax (EV), adaptationSpeed, bloom (bool), bloomIntensity (0..1), color grading applied after tonemapping: contrast (0.5..1.5, 1 = unchanged), lift [r,g,b] (adds to shadows, 0 = unchanged), gamma [r,g,b] (midtone, 1 = unchanged), gain [r,g,b] (multiplier, 1 = unchanged), saturation (0..2, 1 = unchanged), vignette (0..1), vignetteSoftness (0..1), chromaticAberration (0..1), filmGrain (0..1); depth of field: depthOfField (bool), focusDistance (m), focusRange (m kept fully sharp around it), aperture (f-number, lower blurs more), focalLength (mm, longer blurs more; the view's field of view is unchanged), maxBlur (largest blur radius, % of the height, 0..10), focusTarget (entity name to auto-focus on); LUT grading: lut (path under Assets/ of a .cube file, or of an N²×N strip image whose sidecar importer is "lut"), lutIntensity (0..1). Presets: neutral, cinematic, warm, cold, noir, retro. Assign a profile to a camera (Camera.postFX) or a PostFXVolume component (profile, shape box|sphere, size, radius, blendDistance, priority, weight, isGlobal) with postfx.assign.

Arguments:

- `folder?`: string
- `name?`: string
- `preset?`: string
- `settings?`: any — Any JSON value.

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `path`: string
- `settings`: {adaptationSpeed?: number, aperture?: number, autoExposure?: boolean, autoExposureMax?: number, autoExposureMin?: number, bloom?: boolean, bloomIntensity?: number, chromaticAberration?: number, contrast?: number, depthOfField?: boolean, exposure?: number, filmGrain?: number, focalLength?: number, focusDistance?: number, focusRange?: number, focusTarget?: string, gain?: number[3], gamma?: number[3], lift?: number[3], lut?: string, lutIntensity?: number, maxBlur?: number, saturation?: number, tonemapper?: "none" \| "reinhard" \| "neutral" \| "aces", vignette?: number, vignetteSoftness?: number}
- `warnings`: [string]

### `postfx.open`

**Open in Post-FX Builder** · _idempotent_

Opens a .postfx file in the editor's Post-FX tab (a sample scene run through the profile, with presets, sliders and a before/after split) and brings the tab to the front. view.screenshot {source: "panel", panel: "postFXBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `postfx.set`

**Set Post-FX** · _undoable_, _idempotent_

Replaces a .postfx profile's whole contents (`settings`, or a `preset`) and reimports it; cameras and volumes using it update. Undoable. For a few changes, postfx.edit is shorter. A post-fx profile is a camera look; every key is optional (missing = neutral): tonemapper none|reinhard|neutral|aces, exposure (EV stops, -10..10), autoExposure (bool), autoExposureMin/autoExposureMax (EV), adaptationSpeed, bloom (bool), bloomIntensity (0..1), color grading applied after tonemapping: contrast (0.5..1.5, 1 = unchanged), lift [r,g,b] (adds to shadows, 0 = unchanged), gamma [r,g,b] (midtone, 1 = unchanged), gain [r,g,b] (multiplier, 1 = unchanged), saturation (0..2, 1 = unchanged), vignette (0..1), vignetteSoftness (0..1), chromaticAberration (0..1), filmGrain (0..1); depth of field: depthOfField (bool), focusDistance (m), focusRange (m kept fully sharp around it), aperture (f-number, lower blurs more), focalLength (mm, longer blurs more; the view's field of view is unchanged), maxBlur (largest blur radius, % of the height, 0..10), focusTarget (entity name to auto-focus on); LUT grading: lut (path under Assets/ of a .cube file, or of an N²×N strip image whose sidecar importer is "lut"), lutIntensity (0..1). Presets: neutral, cinematic, warm, cold, noir, retro. Assign a profile to a camera (Camera.postFX) or a PostFXVolume component (profile, shape box|sphere, size, radius, blendDistance, priority, weight, isGlobal) with postfx.assign. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `preset?`: string
- `settings?`: {adaptationSpeed?: number, aperture?: number, autoExposure?: boolean, autoExposureMax?: number, autoExposureMin?: number, bloom?: boolean, bloomIntensity?: number, chromaticAberration?: number, contrast?: number, depthOfField?: boolean, exposure?: number, filmGrain?: number, focalLength?: number, focusDistance?: number, focusRange?: number, focusTarget?: string, gain?: number[3], gamma?: number[3], lift?: number[3], lut?: string, lutIntensity?: number, maxBlur?: number, saturation?: number, tonemapper?: "none" \| "reinhard" \| "neutral" \| "aces", vignette?: number, vignetteSoftness?: number}

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `path`: string
- `settings`: {adaptationSpeed?: number, aperture?: number, autoExposure?: boolean, autoExposureMax?: number, autoExposureMin?: number, bloom?: boolean, bloomIntensity?: number, chromaticAberration?: number, contrast?: number, depthOfField?: boolean, exposure?: number, filmGrain?: number, focalLength?: number, focusDistance?: number, focusRange?: number, focusTarget?: string, gain?: number[3], gamma?: number[3], lift?: number[3], lut?: string, lutIntensity?: number, maxBlur?: number, saturation?: number, tonemapper?: "none" \| "reinhard" \| "neutral" \| "aces", vignette?: number, vignetteSoftness?: number}
- `warnings`: [string]

## prefab

### `prefab.apply`

**Apply to Prefab** · _undoable_

Writes an instance's change into its .prefab file, so every instance (in open scenes and when scenes open) gets it: one component of one entity, or with no component the whole instance (its overrides, added and removed entities). One undo step (undo writes the old file back). A model's prefab can't be changed; neither can the root's Transform. Undoable (one step; edit.undo reverts it).

Arguments:

- `component?`: string
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

### `prefab.create`

**Create Prefab** · _undoable_

Saves an entity and its subtree as a .prefab file and makes the entity an instance of it (linking it is one undo step; the file stays). Instances inside the subtree become nested prefabs. Returns the prefab. Undoable (one step; edit.undo reverts it).

Arguments:

- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `folder?`: string
- `name?`: string

Result:

- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).

### `prefab.createVariant`

**Create Prefab Variant** · _undoable_

Creates a variant: a new .prefab based on another prefab (`asset`) or on an instance's prefab (`entity`, taking the instance's overrides, added children and removals into the variant and linking the instance to it; one undo step, the file stays). Changes to the base flow into the variant and its instances unless the variant overrides them. Variants of variants work; cycles are rejected. Returns the new prefab. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `folder?`: string
- `name?`: string

Result:

- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).

### `prefab.overrides`

**Prefab Overrides** · _read-only_, _idempotent_

The prefab instance an entity belongs to: its prefab (and its base, for a variant), root, overrides (changed fields and array elements, added and removed components, added children, removed prefab entities) and added children, and whether prefab.apply can write the prefab.

Arguments:

- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `added`: [entity id]
- `base?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `canApply`: boolean
- `overrides`: [{component?: string, entity?: entity id, kind: "field" \| "addedComponent" \| "removedComponent" \| "removedEntity" \| "addedEntity" \| "removedElement", path?: string, prefabEntity: string, value?: any}]
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `prefabEntity?`: string
- `root`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

### `prefab.revert`

**Revert to Prefab** · _undoable_

Puts an instance back to its prefab: one component of one entity (added, removed or changed), with `path` one overridden field or array element of it, with `child` one added child (deleted) or removed child (restored), or with none of them the whole instance (every override goes, added children are deleted). One undo step. Undoable (one step; edit.undo reverts it).

Arguments:

- `child?`: string
- `component?`: string
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `path?`: string

### `prefab.unpack`

**Unpack Prefab** · _undoable_

Unlinks a prefab instance from its prefab: its entities stay, but no longer follow the prefab. One undo step. Undoable (one step; edit.undo reverts it).

Arguments:

- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

## project

### `project.close`

**Close Project** · _idempotent_

Closes the open project. The scene stays open; its asset references stay as they are (they draw again when the project is reopened).

Arguments: none.

### `project.new`

**New Project** · _destructive_

Creates a project (Project.json, Assets/, Library/) at `path`, or in `location` as a folder called `name`, and opens it (it goes to the top of project.recent.list and the launcher closes). With `template` (empty, starter, game) it is filled from the template and its scene opened. Paths outside the project folder (the editor's start folder without one) are refused for AI clients. Returns its root folder. Destructive only when a `template` is given and the open scene has unsaved changes (the template's scene replaces it): then pass confirm: true.

Arguments:

- `confirm?`: true — Required only when a `template` is given and the open scene has unsaved changes (the template's scene replaces it): that can lose work that undo can't bring back.
- `location?`: string
- `name?`: string
- `path?`: string
- `template?`: "empty" \| "starter" \| "game"

Result:

- `path`: string

### `project.open`

**Open Project** · _destructive_, _idempotent_

Opens the project at `path` (or a recent project by name), scans its assets and imports what changed (in the background); the project goes to the top of project.recent.list and the launcher closes. The scene stays open unless `openLastScene` is true. A project whose Project.json records another engine version (`engineVersion`) is refused unless `allowVersionMismatch` is true; opened, it is stamped with this engine's version, which the MCP server reports in its initialize response. Returns the project's root folder. Destructive only when `openLastScene` is true and the open scene has unsaved changes: then pass confirm: true.

Arguments:

- `allowVersionMismatch?`: boolean
- `confirm?`: true — Required only when `openLastScene` is true and the open scene has unsaved changes: that can lose work that undo can't bring back.
- `openLastScene?`: boolean
- `path`: string

Result:

- `path`: string

### `project.recent.list`

**Recent Projects** · _read-only_, _idempotent_

The recent projects as the launcher lists them (pinned first, then by last opened; at most 20 besides the pinned): name, folder, when last opened, pinned, whether it has game code, whether its folder is missing, its thumbnail and last scene. project.open {path, openLastScene: true} opens one as the launcher does.

Arguments:

- `query?`: string

Result:

- `launcherShown`: boolean
- `openProject?`: string
- `projects`: [{game: boolean, lastOpened: string, lastOpenedText: string, lastScene?: string, missing: boolean, name: string, path: string, pinned: boolean, thumbnail?: string}]
- `reopenLastProject`: boolean

### `project.recent.locate`

**Locate Project** · _idempotent_

Points a recent project whose folder moved (missing in project.recent.list) at its new folder, keeping its place, pin and last scene. `newPath` must hold a Project.json.

Arguments:

- `newPath`: string
- `path`: string

Result:

- `game`: boolean
- `lastOpened`: string
- `lastOpenedText`: string
- `lastScene?`: string
- `missing`: boolean
- `name`: string
- `path`: string
- `pinned`: boolean
- `thumbnail?`: string

### `project.recent.pin`

**Pin Project** · _idempotent_

Pins a recent project to the top of the list (`pinned: false` unpins it). Pinned projects are never dropped from the list.

Arguments:

- `path`: string
- `pinned?`: boolean

Result:

- `game`: boolean
- `lastOpened`: string
- `lastOpenedText`: string
- `lastScene?`: string
- `missing`: boolean
- `name`: string
- `path`: string
- `pinned`: boolean
- `thumbnail?`: string

### `project.recent.remove`

**Remove from List**

Takes a project off the recent projects list (the folder isn't touched).

Arguments:

- `path`: string

Result:

- `path`: string

### `project.recent.reveal`

**Show in Finder** · _idempotent_

Shows a recent project's folder in the Finder (macOS; elsewhere it only returns the folder's path, which the launcher's Copy Path puts on the clipboard).

Arguments:

- `path`: string

Result:

- `path`: string

## scene

### `scene.discardRecovery`

**Discard Recoverable Work** · _destructive_, _idempotent_

Deletes the work a crashed or closed session left behind (`id`, default every session in scene.listRecovery). Destructive: pass confirm: true.

Arguments:

- `confirm`: true — Must be true: this tool can lose work that undo can't bring back.
- `id?`: string

Result:

- `enabled`: boolean
- `folder?`: string
- `sessions`: [{date: number, entities: integer, gameModule?: string, hasPlayState: boolean, id: string, reason: string, sceneName: string, scenePath?: string, unsaved: boolean}]

### `scene.hierarchy`

**Hierarchy** · _read-only_, _idempotent_

Returns the entity tree as the hierarchy panel shows it (roots in order, children in sibling order): each node's id, name, component names and children. `root` limits it to one subtree, `depth` to that many levels.

Arguments:

- `depth?`: integer
- `root?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `entities`: [{children: [object], components: [string], id: entity id, more?: integer, name: string}]

### `scene.listRecovery`

**List Recoverable Work** · _read-only_, _idempotent_

Work that earlier editor sessions left behind because they crashed (game code included) or were closed with unsaved changes: per session the scene, why it ended, whether it had unsaved changes and a play state. Open one with scene.recover, delete with scene.discardRecovery.

Arguments: none.

Result:

- `enabled`: boolean
- `folder?`: string
- `sessions`: [{date: number, entities: integer, gameModule?: string, hasPlayState: boolean, id: string, reason: string, sceneName: string, scenePath?: string, unsaved: boolean}]

### `scene.new`

**New Scene** · _destructive_

Replaces the open scene with a new one: the starter scene (default) or, with `template: "empty"`, a scene with no entities. Clears the undo history; unsaved changes are lost. Not while playing. Destructive: pass confirm: true.

Arguments:

- `confirm`: true — Must be true: this tool can lose work that undo can't bring back.
- `template?`: string

### `scene.open`

**Open Scene** · _destructive_, _idempotent_

Replaces the open scene with the scene file at `path` and clears the undo history. Not while playing. With a project open, `path` is relative to the project folder (Assets/Scenes/Main.scene) or to Assets/ (Scenes/Main.scene, the form Project.json's build.scenes uses); only scenes inside the project folder can be opened. Destructive: pass confirm: true.

Arguments:

- `confirm`: true — Must be true: this tool can lose work that undo can't bring back.
- `path`: string

Result:

- `path`: string

### `scene.raycast`

**Raycast** · _read-only_, _idempotent_

Casts a ray from world-space `origin` along `direction` and returns the first entity it hits exactly (against its triangles), with the point, normal and distance.

Arguments:

- `direction`: number[3] — [x, y, z]
- `maxDistance?`: number
- `origin`: number[3] — [x, y, z]

Result:

- `direction`: number[3] — [x, y, z]
- `distance?`: number
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `hit`: boolean
- `name?`: string
- `normal?`: number[3] — [x, y, z]
- `origin`: number[3] — [x, y, z]
- `point?`: number[3] — [x, y, z]

### `scene.recover`

**Recover Unsaved Work** · _destructive_

Opens the work a crashed or closed session left behind (scene.listRecovery) as the document: unsaved, saving to the scene's original file; `playState` opens the play world at the crash instead, as a new scene. Replaces the open scene and clears the undo history. Not while playing. Destructive: pass confirm: true.

Arguments:

- `confirm`: true — Must be true: this tool can lose work that undo can't bring back.
- `id?`: string
- `playState?`: boolean

Result:

- `date`: number
- `entities`: integer
- `gameModule?`: string
- `hasPlayState`: boolean
- `id`: string
- `reason`: string
- `sceneName`: string
- `scenePath?`: string
- `unsaved`: boolean

### `scene.save`

**Save Scene** · _destructive_, _idempotent_

Saves the scene to its file, or to `path` when it has never been saved. Not while playing. Scenes are only saved inside the project folder (or the editor's start folder without a project); relative paths are relative to it, and a scene opened from elsewhere must be saved with scene.saveAs. Destructive only when `path` names an existing file that isn't the scene's own (saving to the scene's own file or to a new file needs no confirm): then pass confirm: true.

Arguments:

- `confirm?`: true — Required only when `path` names an existing file that isn't the scene's own (saving to the scene's own file or to a new file needs no confirm): that can lose work that undo can't bring back.
- `path?`: string

Result:

- `path`: string

### `scene.saveAs`

**Save Scene As** · _destructive_, _idempotent_

Saves the scene to `path`, which becomes its file. Not while playing. `path` must be inside the project folder (or the editor's start folder without a project); relative paths are relative to it. Destructive only when `path` is an existing file that isn't the scene's own (a new file or the scene's own file needs no confirm): then pass confirm: true.

Arguments:

- `confirm?`: true — Required only when `path` is an existing file that isn't the scene's own (a new file or the scene's own file needs no confirm): that can lose work that undo can't bring back.
- `path`: string

Result:

- `path`: string

## script

### `script.list`

**List Scripts** · _read-only_, _idempotent_

Lists the project's own Swift game scripts (game target, project Scripts/ and Assets/ folders); engine and editor sources are never included.

Arguments: none.

Result:

- `scripts`: [string]

### `script.new`

**New Script**

Creates a Swift game script: a component with an update(_ context:) that runs every frame for each entity that has it (the Script protocol). Registers it in the game module's entry point (game.script(Name.self)) so it shows in Add Component after the next reload. Refuses to overwrite an existing file.

Arguments:

- `name`: string
- `template?`: string

Result:

- `created`: boolean
- `note?`: string
- `path`: string
- `registeredIn?`: string
- `typeName`: string

### `script.open`

**Open Script**

Opens a project Swift game script by file path, reading its content and showing it in the editor. Only files listed by script.list can be opened.

Arguments:

- `path`: string

Result:

- `content`: string
- `lineCount`: integer
- `path`: string

### `script.save`

**Save Script**

Saves code to a project Swift game script and starts a rebuild and hot reload (reload: false skips it). The build runs in the background; if it fails, game.info's diagnostics list each error's file, line and message. Only project script folders can be written.

Arguments:

- `content`: string
- `path`: string
- `reload?`: boolean

Result:

- `path`: string
- `reloadNote?`: string
- `reloaded`: boolean
- `saved`: boolean

## selection

### `selection.clear`

**Clear Selection** · _idempotent_

Deselects everything.

Arguments: none.

### `selection.get`

**Get Selection** · _read-only_, _idempotent_

Returns the selected entities and the primary one (shown in the inspector).

Arguments: none.

Result:

- `entities`: [entity id]
- `primary?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

### `selection.set`

**Select** · _idempotent_

Selects exactly `entities` (empty clears), with `primary` shown in the inspector.

Arguments:

- `entities`: [entity id]
- `primary?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

## settings

### `settings.get`

**Get Settings** · _read-only_, _idempotent_

The editor settings (`editor`: snap steps, viewport camera; `appearance`: theme and UI zoom, with the editor window) and the open project's settings (`project`, its Project.json: name, `game`, `build`, `runtime`). Change them with settings.setEditor, view.appearance and settings.setProject. With a project, `gameTargets` lists the package's game module targets (the choices for game.target) and `scenes` its scene files (for build.scenes).

Arguments: none.

Result:

- `appearance?`: {effectiveUIScale: number, theme: string, themes: [string], uiScale: number}
- `editor`: {cameraFieldOfView?: number, cameraFlySpeed?: number, codeEditor?: string (7 cases), codeEditorCommand?: string, snapRotateDegrees?: number, snapScale?: number, snapTranslate?: number}
- `gameTargets?`: [string]
- `project?`: {build?: {enginePackage?: string, include?: [string], name?: string, output?: string, scenes?: [string], textureFamily?: "bc" \| "astc", textures?: "compress" \| "asImported"}, engineVersion?: string, game?: {buildCommand?: [string], library?: string, package?: string, target?: string, watch?: boolean}, name?: string, runtime?: {physics?: object, window?: object}, version?: integer}
- `projectPath?`: string
- `scenes?`: [string]

### `settings.setEditor`

**Editor Settings** · _idempotent_

Changes the user's editor settings (the Settings window's Editor tab) and saves them in the prefs: gizmo snap steps (`snapTranslate`, `snapRotateDegrees`, `snapScale`; tool.snapping turns snapping on) and the viewport camera (`cameraFlySpeed`, `cameraFieldOfView`) and the code editor file.openInCodeEditor uses (`codeEditor`; `codeEditorCommand` for custom, which AI clients can't change). Only the fields given change; `reset: true` goes back to the defaults first. A value outside its range is refused. Returns all of them.

Arguments:

- `cameraFieldOfView?`: number
- `cameraFlySpeed?`: number
- `codeEditor?`: "system" \| "vscode" \| "cursor" \| "xcode" \| "zed" \| "sublime" \| "custom"
- `codeEditorCommand?`: string
- `reset?`: boolean
- `snapRotateDegrees?`: number
- `snapScale?`: number
- `snapTranslate?`: number

Result:

- `cameraFieldOfView?`: number
- `cameraFlySpeed?`: number
- `codeEditor?`: "system" \| "vscode" \| "cursor" \| "xcode" \| "zed" \| "sublime" \| "custom"
- `codeEditorCommand?`: string
- `snapRotateDegrees?`: number
- `snapScale?`: number
- `snapTranslate?`: number

### `settings.setProject`

**Project Settings** · _idempotent_

Changes the open project's settings (the Settings window's Project tab) and writes Project.json. `name` sets the display name; `game`, `build` and `runtime` each replace their whole section (read it with settings.get, change it, send it back); `clear` removes sections. `runtime.window` (title, width, height, vsync, quality low|medium|high|ultra, showDebugOverlay, renderResolution native|720p|1080p|4k|<w>x<h>|quality|balanced|performance|ultraperformance|<factor>x, upscaler bilinear|fsr1|metalfx|metalfx-temporal|taau|fsr3, upscalerSharpness 0-4 stops, msaa 1|2|4|8, backend metal|vulkan, minWidth, minHeight, allowLargerThanScreen) applies to exported games; `runtime.physics` (gravity [x,y,z], gravity2D [x,y], fixedTimestep in seconds) applies in play mode and exported games. AI clients can't change `game`, `build.enginePackage` or `build.output` (they decide what code runs and where files go): change those in the editor. Not while playing.

Arguments:

- `build?`: {enginePackage?: string, include?: [string], name?: string, output?: string, scenes?: [string], textureFamily?: "bc" \| "astc", textures?: "compress" \| "asImported"}
- `clear?`: [string]
- `game?`: {buildCommand?: [string], library?: string, package?: string, target?: string, watch?: boolean}
- `name?`: string
- `runtime?`: {physics?: {fixedTimestep?: number, gravity?: number[3], gravity2D?: number[2]}, window?: {allowLargerThanScreen?: boolean, backend?: "metal" \| "vulkan", height?: integer, minHeight?: integer, minWidth?: integer, msaa?: integer, quality?: "low" \| "medium" \| "high" \| "ultra", renderResolution?: string, showDebugOverlay?: boolean, title?: string, upscaler?: string, upscalerSharpness?: number, vsync?: boolean, width?: integer}}

Result:

- `path`: string
- `project`: {build?: {enginePackage?: string, include?: [string], name?: string, output?: string, scenes?: [string], textureFamily?: "bc" \| "astc", textures?: "compress" \| "asImported"}, engineVersion?: string, game?: {buildCommand?: [string], library?: string, package?: string, target?: string, watch?: boolean}, name?: string, runtime?: {physics?: object, window?: object}, version?: integer}

## sfx

### `sfx.edit`

**Edit Sound** · _undoable_

Changes a .sfx file in one undoable step, in this order: `preset` (load it; `randomize` with `seed` for a variation), `mutate` (jitter every continuous parameter by that fraction), then `changes` (field name → new value). Returns the new parameters, duration, waveform summary and warnings. Hear the result with sfx.play. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `changes?`: any — Any JSON value.
- `mutate?`: number
- `path?`: string
- `preset?`: "jump" \| "coin" \| "laser" \| "explosion" \| "hit" \| "powerUp" \| "blip"
- `randomize?`: boolean
- `seed?`: integer

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `build`: {arpeggio?: number, arpeggioTime?: number, attack?: number, bitCrush?: integer, decay?: number, duty?: number, dutySweep?: number, frequency?: number, highPass?: number, lowPass?: number, minFrequency?: number, punch?: number, sampleRate?: integer, seed?: integer, slide?: number, slideAcceleration?: number, sustain?: number, vibratoDepth?: number, vibratoRate?: number, volume?: number, waveform?: "square" \| "saw" \| "sine" \| "noise"}
- `clip`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `duration`: number
- `path`: string
- `peaks`: [number]
- `played?`: boolean
- `warnings`: [string]

### `sfx.get`

**Get Sound** · _read-only_, _idempotent_

Reads a .sfx file: every parameter (defaults included), its duration, a waveform summary (peak loudness across the sound) and warnings.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `build`: {arpeggio?: number, arpeggioTime?: number, attack?: number, bitCrush?: integer, decay?: number, duty?: number, dutySweep?: number, frequency?: number, highPass?: number, lowPass?: number, minFrequency?: number, punch?: number, sampleRate?: integer, seed?: integer, slide?: number, slideAcceleration?: number, sustain?: number, vibratoDepth?: number, vibratoRate?: number, volume?: number, waveform?: "square" \| "saw" \| "sine" \| "noise"}
- `clip`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `duration`: number
- `path`: string
- `peaks`: [number]
- `played?`: boolean
- `warnings`: [string]

### `sfx.new`

**New Sound**

Writes a .sfx file in `folder` (default: the Assets root): a synthesized sound effect from `preset` (jump, coin, laser, explosion, hit, powerUp, blip) with an optional `seed` for a random variation, or from `build`. It imports as an audio file, so an AudioEmitter's `clip` can point at it. Returns the asset, its parameters, duration, a waveform summary and warnings. Change it with sfx.edit or sfx.set, hear it with sfx.play. A sound build is a synthesized effect (every key optional): waveform square|saw|sine|noise, frequency Hz, slide (octaves/second, negative falls), slideAcceleration, minFrequency (the sound ends when the pitch falls below it), vibratoDepth (semitones) and vibratoRate (Hz), arpeggio (semitone jump after arpeggioTime seconds), duty and dutySweep (square pulse width), attack / sustain / decay (seconds), punch 0-1, lowPass / highPass (Hz, 0 = off), bitCrush (bits 1-15, 0 = off), volume 0-1, sampleRate, seed (drives the noise: the same parameters and seed give identical samples). Presets: jump|coin|laser|explosion|hit|powerUp|blip. The file plays anywhere an audio file does: set an AudioEmitter's `clip` to it.

Arguments:

- `build?`: {arpeggio?: number, arpeggioTime?: number, attack?: number, bitCrush?: integer, decay?: number, duty?: number, dutySweep?: number, frequency?: number, highPass?: number, lowPass?: number, minFrequency?: number, punch?: number, sampleRate?: integer, seed?: integer, slide?: number, slideAcceleration?: number, sustain?: number, vibratoDepth?: number, vibratoRate?: number, volume?: number, waveform?: "square" \| "saw" \| "sine" \| "noise"}
- `folder?`: string
- `name?`: string
- `preset?`: "jump" \| "coin" \| "laser" \| "explosion" \| "hit" \| "powerUp" \| "blip"
- `seed?`: integer

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `build`: {arpeggio?: number, arpeggioTime?: number, attack?: number, bitCrush?: integer, decay?: number, duty?: number, dutySweep?: number, frequency?: number, highPass?: number, lowPass?: number, minFrequency?: number, punch?: number, sampleRate?: integer, seed?: integer, slide?: number, slideAcceleration?: number, sustain?: number, vibratoDepth?: number, vibratoRate?: number, volume?: number, waveform?: "square" \| "saw" \| "sine" \| "noise"}
- `clip`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `duration`: number
- `path`: string
- `peaks`: [number]
- `played?`: boolean
- `warnings`: [string]

### `sfx.open`

**Open in Sound Builder** · _idempotent_

Opens a .sfx file in the editor's Sound Builder tab (waveform view, play button, presets with Randomize and Mutate, and the parameters form) and brings the tab to the front. view.screenshot {source: "panel", panel: "soundBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `sfx.play`

**Play Sound** · _read-only_

Plays a .sfx file once through the editor's audio output (a new preview replaces the one playing). Returns its duration and waveform summary; `played` is false when the editor has no audio device.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `build`: {arpeggio?: number, arpeggioTime?: number, attack?: number, bitCrush?: integer, decay?: number, duty?: number, dutySweep?: number, frequency?: number, highPass?: number, lowPass?: number, minFrequency?: number, punch?: number, sampleRate?: integer, seed?: integer, slide?: number, slideAcceleration?: number, sustain?: number, vibratoDepth?: number, vibratoRate?: number, volume?: number, waveform?: "square" \| "saw" \| "sine" \| "noise"}
- `clip`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `duration`: number
- `path`: string
- `peaks`: [number]
- `played?`: boolean
- `warnings`: [string]

### `sfx.set`

**Set Sound** · _undoable_, _idempotent_

Replaces a .sfx file's whole contents and reimports it. Undoable. For a few changes, sfx.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `build`: {arpeggio?: number, arpeggioTime?: number, attack?: number, bitCrush?: integer, decay?: number, duty?: number, dutySweep?: number, frequency?: number, highPass?: number, lowPass?: number, minFrequency?: number, punch?: number, sampleRate?: integer, seed?: integer, slide?: number, slideAcceleration?: number, sustain?: number, vibratoDepth?: number, vibratoRate?: number, volume?: number, waveform?: "square" \| "saw" \| "sine" \| "noise"}
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `build`: {arpeggio?: number, arpeggioTime?: number, attack?: number, bitCrush?: integer, decay?: number, duty?: number, dutySweep?: number, frequency?: number, highPass?: number, lowPass?: number, minFrequency?: number, punch?: number, sampleRate?: integer, seed?: integer, slide?: number, slideAcceleration?: number, sustain?: number, vibratoDepth?: number, vibratoRate?: number, volume?: number, waveform?: "square" \| "saw" \| "sine" \| "noise"}
- `clip`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `duration`: number
- `path`: string
- `peaks`: [number]
- `played?`: boolean
- `warnings`: [string]

## sprite

### `sprite.draw`

**Draw Sprite** · _undoable_

Draws on one cel (`frame`, `layer`) of a .sprite file in one undoable step: `pixels` (row strings stamped at `x`, `y`; "." keeps the pixel, or erases with `clear`) then `ops` in order: drawing ({tool pencil|line|rect|fill|eraser, points [[x, y], …], color, filled}, optionally mirrored with `mirrorX` / `mirrorY`) and selections ({tool move, rect [x, y, w, h], to [x, y]} cuts and pastes; {tool copy, rect, to, fromFrame, fromLayer, merged} pastes pixels from this or another cel, `merged` takes the frame's visible pixels; {tool clear, rect} erases). Transparent pixels don't cover when pasted. A color is a palette index (0 = first), a row character ("3", "a", "." transparent) or a hex color (added to the palette if missing). Returns `preview`: the frame's visible pixels as rows. Rows: "." transparent, 0-9 a-z A-Z palette entries 0-61. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `clear?`: boolean
- `color?`: any — Any JSON value.
- `frame?`: integer
- `layer?`: any — Any JSON value.
- `mirrorX?`: boolean
- `mirrorY?`: boolean
- `ops?`: [{color?: any, filled?: boolean, fromFrame?: integer, fromLayer?: any, merged?: boolean, points?: [integer[2]], rect?: integer[4], to?: integer[2], tool: string (9 cases)}]
- `path?`: string
- `pixels?`: [string]
- `x?`: integer
- `y?`: integer

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `atlasColumns`: integer
- `clips`: [{events?: [string], fps: number, frames: [integer], mode: string, name: string}]
- `frames`: [integer]
- `height`: integer
- `layers`: [{blend: string, name: string, opacity: number, visible: boolean}]
- `palette`: [string]
- `path`: string
- `preview?`: [string]
- `previewFrame?`: integer
- `sheet?`: {colorsFound: integer, columns: integer, quantized: boolean, rows: integer}
- `sprite?`: {frames?: [object], height?: integer, layers?: [object], palette?: [string], pivot?: number[2], pixelsPerUnit?: number, tags?: [object], width?: integer}
- `tags`: [{events?: [object], from?: integer, mode?: "loop" \| "once" \| "pingPong", name?: string, to?: integer}]
- `texture`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]
- `width`: integer

### `sprite.edit`

**Edit Sprite** · _undoable_

Changes a .sprite file's structure in one undoable step, in this order: `palette` / `addColors`, canvas `width` / `height`, layers (`addLayers`, `removeLayers`, `updateLayers` [{name, rename, visible, opacity, blend normal|multiply|add|screen|overlay}]), frames (`addFrames` blank or copies of `copyFrame` at `insertAt`, `removeFrames`), timing (`duration` for all, `durations` per frame, ms), `copyCels` ([{fromFrame, fromLayer, toFrame, toLayer, rect [x, y, w, h], x, y, merged, replace}]: copy / paste pixels between cels; default the whole cel to the same place, transparent pixels don't cover unless `replace`), tags (`tags` replaces all, `addTags`, `removeTags`; a tag {name, from, to, mode loop|once|pingPong, events [{frame, name}]} becomes a SpriteAnimator clip whose events fire when it reaches those frames), frame events (`addEvents` / `removeEvents` [{tag, frame, name}]), then `pivot` and `pixelsPerUnit`. Returns the summary and warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `addColors?`: [string]
- `addEvents?`: [{frame?: integer, name?: string, tag: string}]
- `addFrames?`: integer
- `addLayers?`: [string]
- `addTags?`: [{events?: [object], from?: integer, mode?: "loop" \| "once" \| "pingPong", name?: string, to?: integer}]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `copyCels?`: [{fromFrame: integer, fromLayer?: any, merged?: boolean, rect?: integer[4], replace?: boolean, toFrame: integer, toLayer?: any, x?: integer, y?: integer}]
- `copyFrame?`: integer
- `duration?`: integer
- `durations?`: [integer]
- `height?`: integer
- `insertAt?`: integer
- `palette?`: any — Any JSON value.
- `path?`: string
- `pivot?`: number[2] — [x, y]
- `pixelsPerUnit?`: number
- `removeEvents?`: [{frame?: integer, name?: string, tag: string}]
- `removeFrames?`: [integer]
- `removeLayers?`: [string]
- `removeTags?`: [string]
- `tags?`: [{events?: [object], from?: integer, mode?: "loop" \| "once" \| "pingPong", name?: string, to?: integer}]
- `updateLayers?`: [{blend?: "normal" \| "multiply" \| "add" \| "screen" \| "overlay", name: string, opacity?: number, rename?: string, visible?: boolean}]
- `width?`: integer

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `atlasColumns`: integer
- `clips`: [{events?: [string], fps: number, frames: [integer], mode: string, name: string}]
- `frames`: [integer]
- `height`: integer
- `layers`: [{blend: string, name: string, opacity: number, visible: boolean}]
- `palette`: [string]
- `path`: string
- `preview?`: [string]
- `previewFrame?`: integer
- `sheet?`: {colorsFound: integer, columns: integer, quantized: boolean, rows: integer}
- `sprite?`: {frames?: [object], height?: integer, layers?: [object], palette?: [string], pivot?: number[2], pixelsPerUnit?: number, tags?: [object], width?: integer}
- `tags`: [{events?: [object], from?: integer, mode?: "loop" \| "once" \| "pingPong", name?: string, to?: integer}]
- `texture`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]
- `width`: integer

### `sprite.get`

**Get Sprite** · _read-only_, _idempotent_

Reads a .sprite file: the whole contents (`sprite`, cels as row strings), a summary (layers, frame durations, tags, the clips they become, atlas columns), the texture reference and warnings. With `frame`, also `preview`: that frame's visible pixels as rows.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `frame?`: integer
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `atlasColumns`: integer
- `clips`: [{events?: [string], fps: number, frames: [integer], mode: string, name: string}]
- `frames`: [integer]
- `height`: integer
- `layers`: [{blend: string, name: string, opacity: number, visible: boolean}]
- `palette`: [string]
- `path`: string
- `preview?`: [string]
- `previewFrame?`: integer
- `sheet?`: {colorsFound: integer, columns: integer, quantized: boolean, rows: integer}
- `sprite?`: {frames?: [object], height?: integer, layers?: [object], palette?: [string], pivot?: number[2], pixelsPerUnit?: number, tags?: [object], width?: integer}
- `tags`: [{events?: [object], from?: integer, mode?: "loop" \| "once" \| "pingPong", name?: string, to?: integer}]
- `texture`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]
- `width`: integer

### `sprite.importSheet`

**Import Sprite Sheet**

Turns a sprite sheet image (`image` asset, `imagePath` under Assets/, or a `file` anywhere; PNG, JPEG or TGA) into a .sprite: cells of `frameWidth` x `frameHeight` (or the size that gives `columns` x `rows`), after `margin` around the sheet and `spacing` between cells, read left to right, top to bottom, become frames (at most `frames`; empty cells at the end are dropped). Pixels map to `palette` (a preset or hex colors, nearest color) or, by default, to the sheet's own colors, reduced to `maxColors` (default 62) by median cut. Pixels less opaque than `alphaThreshold` (default 128) become transparent. Every frame lasts `duration` ms (default 100); `tags`, `pivot` and `pixelsPerUnit` are set as given. Writes a new file (`folder`, `name`; default next to the image, named after it) or replaces the .sprite at `into` (undoable). Returns the sprite summary, `sheet` {columns, rows, colorsFound, quantized} and warnings.

Arguments:

- `alphaThreshold?`: integer
- `columns?`: integer
- `duration?`: integer
- `file?`: string
- `folder?`: string
- `frameHeight?`: integer
- `frameWidth?`: integer
- `frames?`: integer
- `image?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `imagePath?`: string
- `into?`: string
- `margin?`: integer
- `maxColors?`: integer
- `name?`: string
- `palette?`: any — Any JSON value.
- `pivot?`: number[2] — [x, y]
- `pixelsPerUnit?`: number
- `rows?`: integer
- `spacing?`: integer
- `tags?`: [{events?: [object], from?: integer, mode?: "loop" \| "once" \| "pingPong", name?: string, to?: integer}]

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `atlasColumns`: integer
- `clips`: [{events?: [string], fps: number, frames: [integer], mode: string, name: string}]
- `frames`: [integer]
- `height`: integer
- `layers`: [{blend: string, name: string, opacity: number, visible: boolean}]
- `palette`: [string]
- `path`: string
- `preview?`: [string]
- `previewFrame?`: integer
- `sheet?`: {colorsFound: integer, columns: integer, quantized: boolean, rows: integer}
- `sprite?`: {frames?: [object], height?: integer, layers?: [object], palette?: [string], pivot?: number[2], pixelsPerUnit?: number, tags?: [object], width?: integer}
- `tags`: [{events?: [object], from?: integer, mode?: "loop" \| "once" \| "pingPong", name?: string, to?: integer}]
- `texture`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]
- `width`: integer

### `sprite.new`

**New Sprite**

Writes a .sprite file in `folder` (default: the Assets root): a blank `width` x `height` canvas with `palette` and `frames` blank frames, or `sprite`. Draw on it with sprite.draw, add frames, layers and tags with sprite.edit. Returns the asset, its texture reference, layers, frames, clips and warnings. A .sprite file is pixel art (every key optional): width and height (1-256, default 16), palette (hex colors, up to 62), layers (bottom first: name, visible, opacity 0-1, blend normal|multiply|add|screen|overlay, cels: one list of row strings per frame), frames ({duration} in ms), tags ({name, from, to, mode loop|once|pingPong, events [{frame, name}]}: inclusive frame ranges, one animation clip each, firing its events when it reaches those frames), pivot ([x, y] 0-1 from the bottom-left, default [0.5, 0]) and pixelsPerUnit (default 16). In a row string each character is one pixel: "." is transparent and 0-9, a-z, A-Z are palette entries 0-61 ("0" is the first color, "a" the 11th). It imports as a texture (sub-asset "texture"): the frames in a grid, frame i in cell i, so indices stay stable for SpriteAnimator clips and tile sets. Palette presets: pico8, db16, db32, gameboy, grayscale.

Arguments:

- `folder?`: string
- `frames?`: integer
- `height?`: integer
- `name?`: string
- `palette?`: any — Any JSON value.
- `sprite?`: {frames?: [object], height?: integer, layers?: [object], palette?: [string], pivot?: number[2], pixelsPerUnit?: number, tags?: [object], width?: integer}
- `width?`: integer

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `atlasColumns`: integer
- `clips`: [{events?: [string], fps: number, frames: [integer], mode: string, name: string}]
- `frames`: [integer]
- `height`: integer
- `layers`: [{blend: string, name: string, opacity: number, visible: boolean}]
- `palette`: [string]
- `path`: string
- `preview?`: [string]
- `previewFrame?`: integer
- `sheet?`: {colorsFound: integer, columns: integer, quantized: boolean, rows: integer}
- `sprite?`: {frames?: [object], height?: integer, layers?: [object], palette?: [string], pivot?: number[2], pixelsPerUnit?: number, tags?: [object], width?: integer}
- `tags`: [{events?: [object], from?: integer, mode?: "loop" \| "once" \| "pingPong", name?: string, to?: integer}]
- `texture`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]
- `width`: integer

### `sprite.open`

**Open in Pixel Sprite Builder** · _idempotent_

Opens a .sprite file in the editor's Pixel Sprite Builder tab (canvas with drawing tools, palette, layers, frames with onion skin, tags and an animation preview) and brings the tab to the front. view.screenshot {source: "panel", panel: "spriteBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `sprite.set`

**Set Sprite** · _undoable_, _idempotent_

Replaces a .sprite file's whole contents and reimports it. Undoable. To draw, sprite.draw is shorter; for frames, layers, tags and the palette, sprite.edit. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `sprite`: {frames?: [object], height?: integer, layers?: [object], palette?: [string], pivot?: number[2], pixelsPerUnit?: number, tags?: [object], width?: integer}

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `atlasColumns`: integer
- `clips`: [{events?: [string], fps: number, frames: [integer], mode: string, name: string}]
- `frames`: [integer]
- `height`: integer
- `layers`: [{blend: string, name: string, opacity: number, visible: boolean}]
- `palette`: [string]
- `path`: string
- `preview?`: [string]
- `previewFrame?`: integer
- `sheet?`: {colorsFound: integer, columns: integer, quantized: boolean, rows: integer}
- `sprite?`: {frames?: [object], height?: integer, layers?: [object], palette?: [string], pivot?: number[2], pixelsPerUnit?: number, tags?: [object], width?: integer}
- `tags`: [{events?: [object], from?: integer, mode?: "loop" \| "once" \| "pingPong", name?: string, to?: integer}]
- `texture`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]
- `width`: integer

## stats

### `stats.get`

**Stats** · _read-only_, _idempotent_

Returns the stats panel's numbers: FPS, frame / CPU / GPU times in milliseconds with each GPU pass, draw calls, triangles, the viewport's size and culling, entity count, undo depth and play state. Frame numbers are missing headless.

Arguments: none.

Result:

- `backend?`: string
- `device?`: string
- `drawCalls?`: integer
- `entities`: integer
- `fps?`: number
- `frameMilliseconds?`: number
- `gpuMilliseconds?`: number
- `gpuPasses`: [{milliseconds: number, name: string}]
- `playing`: boolean
- `redoDepth`: integer
- `renderMilliseconds?`: number
- `triangles?`: integer
- `uiPaintMilliseconds?`: number
- `undoDepth`: integer
- `updateMilliseconds?`: number
- `viewport?`: [integer]
- `viewportCulled?`: integer
- `viewportDrawn?`: integer

## table

### `table.edit`

**Edit Data Table** · _undoable_

Changes part of a .table file in one undoable step, in this order: renameColumns, columns (add or replace by name), removeColumns, removeRows, addRows, updateRows (row id → cells; null clears; "id" renames). Running games read the new data. Returns column names, row ids and warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `addRows?`: [boolean]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `columns?`: [{default?: any, max?: number, min?: number, name?: string, options?: [string], table?: string, type?: string (7 cases)}]
- `path?`: string
- `removeColumns?`: [string]
- `removeRows?`: [string]
- `renameColumns?`: object
- `updateRows?`: object

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `columns`: [string]
- `path`: string
- `rowCount`: integer
- `rows`: [string]
- `warnings`: [string]

### `table.exportCsv`

**Export Data Table as CSV** · _idempotent_

Returns a .table file as CSV text (header `id` plus the column names; fields with commas, quotes or line breaks are quoted), and writes it to `file` when given.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `file?`: string
- `path?`: string

Result:

- `csv`: string
- `file?`: string

### `table.get`

**Get Data Table** · _read-only_, _idempotent_

Reads a .table file: its columns and rows as stored, and the problems with its values and references. For filtered or sorted rows use table.query.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `path`: string
- `table`: {columns?: [object], rows?: [boolean]}
- `warnings`: [string]

### `table.importCsv`

**Import CSV into Data Table** · _undoable_

Reads CSV (RFC 4180: quoted fields, doubled quotes, line breaks inside quotes; the header is `id` plus column names, matched by name) from `csv` or `file` into a .table file as one undoable step. Modes: replace, merge (by id), append. Cells that don't fit their column are kept and reported in the table's warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `createColumns?`: boolean
- `csv?`: string
- `file?`: string
- `mode?`: "replace" \| "merge" \| "append"
- `path?`: string

Result:

- `added`: integer
- `createdColumns`: [string]
- `importWarnings`: [string]
- `skippedColumns`: [string]
- `table`: {asset: asset id, columns: [string], path: string, rowCount: integer, rows: [string], warnings: [string]}
- `updated`: integer

### `table.new`

**New Data Table**

Writes a .table file in `folder` (default: the Assets root) with the given `columns` and optional `rows`, and imports it. Returns the asset, column names, row ids and warnings. Change it later with table.edit (add/update/remove rows and columns), table.set (whole contents) or table.importCsv. A data table is a typed spreadsheet for game data: `columns` (each: name, type number|text|bool|color|enum|asset|row, default (value of a row without that cell), options [..] for enum, table (for a row column: another .table path under Assets/; empty means this table), min/max for number) and `rows` (flat objects: {"id": "goblin", "hp": 30, ...}; ids are unique and are how game code finds a row). Values: number, text, bool, color ("#RRGGBB[AA]" or [r,g,b,a] sRGB 0-1), enum (one of options), asset (path under Assets/ or "asset:<id>"), row (a row id). Wrong values are kept and reported in `warnings` (wrong type, unknown enum case, dangling asset or row reference, duplicate ids). Game code reads it with assets.dataTable(path: "Data/enemies.table")?.row("goblin")?.number("hp").

Arguments:

- `columns?`: [{default?: any, max?: number, min?: number, name?: string, options?: [string], table?: string, type?: string (7 cases)}]
- `folder?`: string
- `name?`: string
- `rows?`: [boolean]

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `columns`: [string]
- `path`: string
- `rowCount`: integer
- `rows`: [string]
- `warnings`: [string]

### `table.open`

**Open in Data Table** · _idempotent_

Opens a .table file in the editor's Data Table tab (a grid with sort, filter, bulk edit and CSV import/export) and brings the tab to the front. view.screenshot {source: "panel", panel: "dataTable"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `table.query`

**Query Data Table** · _read-only_, _idempotent_

Finds rows of a .table file by a text `filter` (see its format), optionally sorted and limited. Rows come back as game code reads them: id plus each column's value with defaults filled in.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `columns?`: [string]
- `descending?`: boolean
- `filter?`: string
- `limit?`: integer
- `path?`: string
- `sort?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `matched`: integer
- `path`: string
- `rows`: [any]

### `table.set`

**Set Data Table** · _undoable_, _idempotent_

Replaces a .table file's whole contents and reimports it (running games read the new data). Undoable. For a few changes, table.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `table`: {columns?: [object], rows?: [boolean]}

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `columns`: [string]
- `path`: string
- `rowCount`: integer
- `rows`: [string]
- `warnings`: [string]

## terrain

### `terrain.edit`

**Edit Terrain** · _undoable_

Changes a .terrain file's settings, layers or scatter rules in one undoable step, in this order: size, resolution (resamples), heightRange, the scalar settings, removeLayers, addLayers, updateLayers (name → fields; "name" renames), removeScatter, addScatter, updateScatter. Placed copies update. Heights and paint are changed with terrain.sculpt and terrain.paint. Undoable (one step; edit.undo reverts it).

Arguments:

- `addLayers?`: [{color?: number[3], material?: string, name?: string, normalMap?: string, physicsMaterial?: string, texture?: string, tileSize?: number}]
- `addScatter?`: [{alignToNormal?: boolean, asset?: string, density?: number, groom?: string, layer?: string, material?: string, maxCount?: integer, maxHeight?: number, maxScale?: number, maxSlope?: number, minHeight?: number, minScale?: number, minSlope?: number, name?: string, seed?: integer}]
- `albedoSize?`: integer
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `chunkCells?`: integer
- `collider?`: boolean
- `colliderLod?`: integer
- `heightRange?`: number
- `lodDistance?`: number
- `lods?`: integer
- `path?`: string
- `removeLayers?`: [string]
- `removeScatter?`: [string]
- `resolution?`: integer
- `seed?`: integer
- `size?`: number[2] — [x, y]
- `updateLayers?`: object
- `updateScatter?`: object

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `chunks`: integer
- `entities?`: [entity id]
- `heightRange`: number
- `layers`: [string]
- `maxHeight`: number
- `minHeight`: number
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `resolution`: integer
- `scatter`: [string]
- `scatterCounts`: [integer]
- `size`: number[2] — [x, y]
- `warnings`: [string]

### `terrain.get`

**Get Terrain** · _read-only_, _idempotent_

Reads a .terrain file: settings, layers and scatter rules (every field, defaults included), a summary (chunks, height range, props per rule, problems), and with `sampleHeights` a coarse grid of heights. The raw height and weight data stay in the file.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `sampleHeights?`: integer

Result:

- `albedoSize`: integer
- `chunkCells`: integer
- `collider`: boolean
- `colliderLod`: integer
- `heightRange`: number
- `heights?`: [[number]]
- `layers`: [{color?: number[3], material?: string, name?: string, normalMap?: string, physicsMaterial?: string, texture?: string, tileSize?: number}]
- `lodDistance`: number
- `lods`: integer
- `resolution`: integer
- `scatter`: [{alignToNormal?: boolean, asset?: string, density?: number, groom?: string, layer?: string, material?: string, maxCount?: integer, maxHeight?: number, maxScale?: number, maxSlope?: number, minHeight?: number, minScale?: number, minSlope?: number, name?: string, seed?: integer}]
- `seed`: integer
- `size`: number[2] — [x, y]
- `summary`: {asset: asset id, chunks: integer, entities?: [entity id], heightRange: number, layers: [string], maxHeight: number, minHeight: number, path: string, prefab: asset id, resolution: integer, scatter: [string], scatterCounts: [integer], size: number[2], warnings: [string]}

### `terrain.new`

**New Terrain**

Writes a .terrain file in `folder` (default: the Assets root): rolling hills generated from `seed` with grass, rock and dirt layers (grass everywhere), imported as chunk meshes with colliders and per-pixel blended layers (a baked albedo on low quality), optionally placed in the scene. Then shape it with terrain.sculpt, texture it with terrain.paint, and add props with terrain.scatter. A terrain is a heightmap centered on its origin: `size` [x,z] meters, `resolution` height samples per side (3-1025), `heightRange` (meters at full height; heights span 0 to heightRange), `chunkCells` (cells per chunk mesh), `lods` (detail levels per chunk, swapped by camera distance), `lodDistance` (meters where level 1 starts, doubling per level; 0: 1.5 chunk widths), `collider` (a triangle-mesh collider per chunk), `colliderLod`, `albedoSize`, `seed`, `layers` (each: name, color [r,g,b] 0-1 sRGB, texture (path under Assets/: an image or .proctex), tileSize meters per repeat, normalMap (an optional tangent-space normal map path, tiled like texture), material (an optional graph .material path drawn where the layer is painted, its UVs repeating every tileSize, instead of texture)); up to 8 layers blend per pixel on the GPU (more are baked into one albedo, which low quality always draws), `scatter` rules (each: name, asset (a .meshbuild path, or "asset:<id>#mesh/<name>"), material, density (candidate spots per 100 m²), minSlope/maxSlope degrees, minHeight/maxHeight meters, minScale/maxScale, layer (only where this layer is painted), alignToNormal, seed, maxCount), and the data `heights` (base64 UInt16) and `splat` (base64 UInt8 weights per layer). Positions in tools are terrain-space [x,z] meters from the center (x and z each run -size/2 to size/2). Every key is optional; use terrain.sculpt / terrain.paint to change the data rather than writing it.

Arguments:

- `folder?`: string
- `heightRange?`: number
- `hilliness?`: number
- `name?`: string
- `place?`: boolean
- `position?`: number[3] — [x, y, z]
- `resolution?`: integer
- `seed?`: integer
- `size?`: number[2] — [x, y]

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `chunks`: integer
- `entities?`: [entity id]
- `heightRange`: number
- `layers`: [string]
- `maxHeight`: number
- `minHeight`: number
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `resolution`: integer
- `scatter`: [string]
- `scatterCounts`: [integer]
- `size`: number[2] — [x, y]
- `warnings`: [string]

### `terrain.open`

**Open in Terrain Builder** · _idempotent_

Opens a .terrain file in the editor's Terrain Builder tab (a viewport showing just the terrain, brush tools you drag over it, and the layers and scatter forms) and brings the tab to the front. view.screenshot {source: "panel", panel: "terrainBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `terrain.paint`

**Paint Terrain** · _undoable_

Paints a texture layer (by name) at `points` ([x,z] meters from the terrain's center) onto a .terrain file's splat map in one undoable step; other layers give way so weights sum to 1. `radius` meters, `strength` 0-1, `falloff` 0-1, `erase` removes the layer's paint. Add layers with terrain.edit addLayers (an image or .proctex texture, or a flat color). Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `erase?`: boolean
- `falloff?`: number
- `layer`: string
- `path?`: string
- `points`: [number[2]]
- `radius?`: number
- `strength?`: number

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `chunks`: integer
- `entities?`: [entity id]
- `heightRange`: number
- `layers`: [string]
- `maxHeight`: number
- `minHeight`: number
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `resolution`: integer
- `scatter`: [string]
- `scatterCounts`: [integer]
- `size`: number[2] — [x, y]
- `warnings`: [string]

### `terrain.scatter`

**Scatter on Terrain** · _undoable_

Adds (or replaces, by `name`) a scatter rule on a .terrain file: `terrain` (or `path`) names the terrain; `asset` is the prop to scatter (a .meshbuild path such as "Models/pine.meshbuild", or "asset:<id>#mesh/<name>" with `material`); `density` is candidate spots per 100 m²; `rules` limit where props stand (minSlope/maxSlope degrees, minHeight/maxHeight meters, layer, minScale/maxScale, alignToNormal, seed, maxCount). `remove` deletes rules by name first. Props are drawn instanced. Returns how many props each rule places. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: string
- `density?`: number
- `material?`: string
- `name?`: string
- `path?`: string
- `remove?`: [string]
- `rules?`: {alignToNormal?: boolean, layer?: string, maxCount?: integer, maxHeight?: number, maxScale?: number, maxSlope?: number, minHeight?: number, minScale?: number, minSlope?: number, seed?: integer}
- `terrain?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `chunks`: integer
- `entities?`: [entity id]
- `heightRange`: number
- `layers`: [string]
- `maxHeight`: number
- `minHeight`: number
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `resolution`: integer
- `scatter`: [string]
- `scatterCounts`: [integer]
- `size`: number[2] — [x, y]
- `warnings`: [string]

### `terrain.sculpt`

**Sculpt Terrain** · _undoable_

Applies a brush (raise, lower, smooth, flatten, noise) at `points` ([x,z] meters from the terrain's center) to a .terrain file's heights, in one undoable step, and reimports it (chunks, colliders and scatter follow). `radius` meters, `strength` (raise/lower/noise: meters per point; smooth/flatten: 0-1), `falloff` 0-1, `height` for flatten. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `brush`: "raise" \| "lower" \| "smooth" \| "flatten" \| "noise"
- `falloff?`: number
- `height?`: number
- `path?`: string
- `points`: [number[2]]
- `radius?`: number
- `strength?`: number

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `chunks`: integer
- `entities?`: [entity id]
- `heightRange`: number
- `layers`: [string]
- `maxHeight`: number
- `minHeight`: number
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `resolution`: integer
- `scatter`: [string]
- `scatterCounts`: [integer]
- `size`: number[2] — [x, y]
- `warnings`: [string]

### `terrain.set`

**Set Terrain** · _undoable_, _idempotent_

Replaces a .terrain file's whole contents (heights included) and reimports it; placed copies update. Undoable. For settings, layers or scatter changes terrain.edit is shorter; sculpt and paint with terrain.sculpt / terrain.paint. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `terrain`: {albedoSize?: integer, chunkCells?: integer, collider?: boolean, colliderLod?: integer, heightRange?: number, heights?: string, layers?: [object], lodDistance?: number, lods?: integer, resolution?: integer, scatter?: [object], seed?: integer, size?: number[2], splat?: [string]}

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `chunks`: integer
- `entities?`: [entity id]
- `heightRange`: number
- `layers`: [string]
- `maxHeight`: number
- `minHeight`: number
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `resolution`: integer
- `scatter`: [string]
- `scatterCounts`: [integer]
- `size`: number[2] — [x, y]
- `warnings`: [string]

## tilemap

### `tilemap.edit`

**Edit Tilemap** · _undoable_

Changes a .tilemap file in one undoable step, in this order: size (anchorBottom keeps the bottom rows), tileSize, pixelsPerUnit, chunkSize, background, tilesetSource, filter, setTiles / removeTiles (per-tile collision, oneWay, tags, properties, animation), removeLayers, addLayers, updateLayers (name → fields; "name" renames), layerOrder, removeTerrains, addTerrains, updateTerrains, removeObjects, addObjects, updateObjects. Placed copies update. Cells are painted with tilemap.paint / fill / erase. Undoable (one step; edit.undo reverts it).

Arguments:

- `addLayers?`: [{cells?: [[integer]], collision?: boolean, data?: [integer], name?: string, opacity?: number, order?: number, parallax?: number[2], visible?: boolean}]
- `addObjects?`: [{name?: string, position?: number[2], properties?: object, size?: number[2], trigger?: boolean, type?: string}]
- `addTerrains?`: [{edgesConnect?: boolean, fill?: integer, first?: integer, mode?: "edges" \| "blob", name?: string, tiles?: object}]
- `anchorBottom?`: boolean
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `background?`: number[4] — [x, y, z, w] (colors: linear [r, g, b, a])
- `chunkSize?`: integer
- `filter?`: string
- `layerOrder?`: [string]
- `path?`: string
- `pixelsPerUnit?`: number
- `removeLayers?`: [string]
- `removeObjects?`: [string]
- `removeTerrains?`: [string]
- `removeTiles?`: [integer]
- `setTiles?`: [{animation?: object, collision?: string (7 cases), index?: integer, name?: string, oneWay?: boolean, points?: [number[2]], properties?: object, tags?: [string]}]
- `size?`: [integer]
- `tileSize?`: [integer]
- `tilesetSource?`: string \| {image?: string, images?: [string], kind?: "image" \| "images" \| "sprite", margin?: integer, spacing?: integer, sprite?: string} — Where the tile pictures come from: an image path (a sprite sheet sliced by tileSize), a .sprite path (tile i = frame i), or an object with a kind.
- `updateLayers?`: object
- `updateObjects?`: object
- `updateTerrains?`: object

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[2] — [x, y]
- `changed?`: integer
- `colliders`: integer
- `entities?`: [entity id]
- `layers`: [string]
- `objects`: [string]
- `painted`: [integer]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `size`: [integer]
- `terrains`: [string]
- `tileCount`: integer
- `tileSize`: [integer]
- `warnings`: [string]

### `tilemap.erase`

**Erase Tilemap** · _undoable_

Clears `cells` [[x, y], …], a `rect` [x0, y0, x1, y1] or `all` of a layer in one undoable step. With `terrain`, the terrain cells around them are re-tiled so the new edges get border tiles. Undoable (one step; edit.undo reverts it).

Arguments:

- `all?`: boolean
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `cells?`: [[integer]]
- `layer?`: string
- `path?`: string
- `rect?`: [integer]
- `terrain?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[2] — [x, y]
- `changed?`: integer
- `colliders`: integer
- `entities?`: [entity id]
- `layers`: [string]
- `objects`: [string]
- `painted`: [integer]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `size`: [integer]
- `terrains`: [string]
- `tileCount`: integer
- `tileSize`: [integer]
- `warnings`: [string]

### `tilemap.fill`

**Fill Tilemap** · _undoable_

Fills a `rect` [x0, y0, x1, y1] of a layer, or flood-fills from `at` [x, y] (the 4-connected cells holding the same tile), with one brush: `tile`, `tiles` (random) or `terrain` (auto-tiled). One undoable step. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `at?`: [integer]
- `flipX?`: boolean
- `flipY?`: boolean
- `layer?`: string
- `path?`: string
- `rect?`: [integer]
- `rotation?`: integer
- `seed?`: integer
- `terrain?`: string
- `tile?`: integer
- `tiles?`: [integer]

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[2] — [x, y]
- `changed?`: integer
- `colliders`: integer
- `entities?`: [entity id]
- `layers`: [string]
- `objects`: [string]
- `painted`: [integer]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `size`: [integer]
- `terrains`: [string]
- `tileCount`: integer
- `tileSize`: [integer]
- `warnings`: [string]

### `tilemap.get`

**Get Tilemap** · _read-only_, _idempotent_

Reads a .tilemap file: size, tile set (source and per-tile entries), layer settings, terrains, objects and a summary (painted cells per layer, merged colliders, problems). With `layer` it also returns that layer's cells (or the `rect` [x0, y0, x1, y1] of them) as rows of cell values, top row first.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `layer?`: string
- `path?`: string
- `rect?`: [integer]

Result:

- `background?`: number[4] — [x, y, z, w] (colors: linear [r, g, b, a])
- `cells?`: [[integer]]
- `chunkSize`: integer
- `layers`: [{collision: boolean, name: string, opacity: number, order: number, painted: integer, parallax: number[2], visible: boolean}]
- `objects`: [{name?: string, position?: number[2], properties?: object, size?: number[2], trigger?: boolean, type?: string}]
- `origin?`: [integer]
- `pixelsPerUnit`: number
- `summary`: {asset: asset id, cellSize: number[2], changed?: integer, colliders: integer, entities?: [entity id], layers: [string], objects: [string], painted: [integer], path: string, prefab: asset id, size: [integer], terrains: [string], tileCount: integer, tileSize: [integer], warnings: [string]}
- `terrains`: [{edgesConnect?: boolean, fill?: integer, first?: integer, mode?: "edges" \| "blob", name?: string, tiles?: object}]
- `tileset`: {filter?: string, source?: string \| {image?: string, images?: [string], kind?: "image" \| "images" \| "sprite", margin?: integer, spacing?: integer, sprite?: string}, tiles?: [object]}

### `tilemap.new`

**New Tilemap**

Writes a .tilemap file in `folder` (default: the Assets root) with empty layers, imported as a prefab of layer chunk meshes, merged Collider2D shapes and object points, optionally placed in the scene. Without `tileset` a 16 px starter tile set image is written next to it (tiles 0-15 the "Dirt" terrain by edge mask, 16 stone, 17 brick, 18 one-way platform, 19/20 ramps, 21 spikes, 22-25 animated water, 26-27 torch, 28 coin, 29 grass tuft, 30 back wall, 31 ladder). Then paint with tilemap.paint / tilemap.fill. A tilemap is a grid of `size` [columns, rows] cells of `tileSize` [w, h] pixels; `pixelsPerUnit` (0: the tile width, so a tile is 1 world unit) sets the world size. Cells are addressed [x, y] with x right and y DOWN from the top-left cell. `tileset`: `source` ({"kind": "image", "image": "Tiles/sheet.png", "margin", "spacing"} slices a sprite sheet into tiles in reading order, tile 0 first; {"kind": "images", "images": [...]} packs one image per tile; {"kind": "sprite", "sprite": "Tiles/tiles.sprite"} (or a path ending .sprite) uses a Pixel Sprite's frames, tile i = frame i, and plays each of its tags on the tag's first tile unless that tile has its own animation), `filter` (nearest/linear), `tiles` (per-tile entries: index, name, collision none/full/top/bottom/slopeUp/slopeDown/polygon (+points 0-1, y up), oneWay, tags, properties, animation {frames, fps, mode loop/pingPong/once}). `layers` (name, cells (rows of cell values, top row first), order, parallax [x,y], opacity, visible, collision) draw in list order, first at the back. A cell value is -1 (empty) or a tile index + 65536 (flip x) + 131072 (flip y) + 262144 * quarter turns clockwise. `terrains` are auto-tiling sets (name, mode edges (mask N1 E2 S4 W8) or blob (8 neighbors), first (edges: tile first+mask), tiles {"mask": tile}, fill, edgesConnect). `objects` (name, type, position [x,y] world units from the bottom-left, size, trigger, properties) are points for game code. Every key is optional; paint with tilemap.paint / fill / erase rather than writing cells.

Arguments:

- `folder?`: string
- `layers?`: [string]
- `name?`: string
- `pixelsPerUnit?`: number
- `place?`: boolean
- `position?`: number[3] — [x, y, z]
- `size?`: [integer]
- `tileSize?`: [integer]
- `tileset?`: any — Any JSON value.

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[2] — [x, y]
- `changed?`: integer
- `colliders`: integer
- `entities?`: [entity id]
- `layers`: [string]
- `objects`: [string]
- `painted`: [integer]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `size`: [integer]
- `terrains`: [string]
- `tileCount`: integer
- `tileSize`: [integer]
- `warnings`: [string]

### `tilemap.open`

**Open in Tilemap Builder** · _idempotent_

Opens a .tilemap file in the editor's Tilemap Builder tab (the map drawn with its tile set, a tile palette, brushes and the layer, tile, terrain and object forms) and brings the tab to the front. view.screenshot {source: "panel", panel: "tilemapBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `tilemap.paint`

**Paint Tilemap** · _undoable_

Paints cells of a layer in one undoable step with exactly one brush: `tile` (one tile, with flipX / flipY / rotation), `tiles` (random from a set) or `terrain` (auto-tiling: the cells become that terrain and every terrain cell around them picks the tile matching its neighbors). Cells are [x, y] with y down from the top-left; cells outside the map are skipped. Returns the summary with `changed`. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `cells`: [[integer]]
- `flipX?`: boolean
- `flipY?`: boolean
- `layer?`: string
- `path?`: string
- `rotation?`: integer
- `seed?`: integer
- `terrain?`: string
- `tile?`: integer
- `tiles?`: [integer]

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[2] — [x, y]
- `changed?`: integer
- `colliders`: integer
- `entities?`: [entity id]
- `layers`: [string]
- `objects`: [string]
- `painted`: [integer]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `size`: [integer]
- `terrains`: [string]
- `tileCount`: integer
- `tileSize`: [integer]
- `warnings`: [string]

### `tilemap.set`

**Set Tilemap** · _undoable_, _idempotent_

Replaces a .tilemap file's whole contents and reimports it; placed copies update. Undoable. For settings, layers, tiles, terrains or objects tilemap.edit is shorter; paint cells with tilemap.paint / fill / erase. A tilemap is a grid of `size` [columns, rows] cells of `tileSize` [w, h] pixels; `pixelsPerUnit` (0: the tile width, so a tile is 1 world unit) sets the world size. Cells are addressed [x, y] with x right and y DOWN from the top-left cell. `tileset`: `source` ({"kind": "image", "image": "Tiles/sheet.png", "margin", "spacing"} slices a sprite sheet into tiles in reading order, tile 0 first; {"kind": "images", "images": [...]} packs one image per tile; {"kind": "sprite", "sprite": "Tiles/tiles.sprite"} (or a path ending .sprite) uses a Pixel Sprite's frames, tile i = frame i, and plays each of its tags on the tag's first tile unless that tile has its own animation), `filter` (nearest/linear), `tiles` (per-tile entries: index, name, collision none/full/top/bottom/slopeUp/slopeDown/polygon (+points 0-1, y up), oneWay, tags, properties, animation {frames, fps, mode loop/pingPong/once}). `layers` (name, cells (rows of cell values, top row first), order, parallax [x,y], opacity, visible, collision) draw in list order, first at the back. A cell value is -1 (empty) or a tile index + 65536 (flip x) + 131072 (flip y) + 262144 * quarter turns clockwise. `terrains` are auto-tiling sets (name, mode edges (mask N1 E2 S4 W8) or blob (8 neighbors), first (edges: tile first+mask), tiles {"mask": tile}, fill, edgesConnect). `objects` (name, type, position [x,y] world units from the bottom-left, size, trigger, properties) are points for game code. Every key is optional; paint with tilemap.paint / fill / erase rather than writing cells. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `tilemap`: {background?: number[4], chunkSize?: integer, layers?: [object], objects?: [object], pixelsPerUnit?: number, size?: [integer], terrains?: [object], tileSize?: [integer], tileset?: {filter?: string, source?: string \| object, tiles?: [object]}}

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `cellSize`: number[2] — [x, y]
- `changed?`: integer
- `colliders`: integer
- `entities?`: [entity id]
- `layers`: [string]
- `objects`: [string]
- `painted`: [integer]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `size`: [integer]
- `terrains`: [string]
- `tileCount`: integer
- `tileSize`: [integer]
- `warnings`: [string]

## timeline

### `timeline.edit`

**Edit Timeline** · _undoable_

Changes part of a .timeline file in one undoable step, in this order: removeTracks, addTracks, updateTracks (id → fields; "id" renames), removeKeys ({track, time | index}), addKeys (key fields plus "track"; replaces a key at the same time), updateKeys ({track, time | index, set: {field: value, …}}), then duration / loop / skippable / holdFade. Keys are kept sorted by time. Returns the tracks and problems (e.g. a sound that doesn't exist). Undoable (one step; edit.undo reverts it).

Arguments:

- `addKeys?`: [{amount?: number, blend?: number, clip?: string, color?: number[3], cut?: boolean, dialogue?: string, duration?: number, easing?: string (25 cases), effect?: string, followPath?: boolean, fov?: number, lookAt?: number[3], lookAtEntity?: string, loop?: boolean, name?: string, node?: string, path?: [number[3]], pitch?: number, position?: number[3], rotation?: number[3], scale?: number[3], speed?: number, time?: number, track: string, value?: string, volume?: number, wait?: boolean}]
- `addTracks?`: [{id?: string, keys?: [object], kind?: string, muted?: boolean, name?: string, target?: string}]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `duration?`: number
- `holdFade?`: boolean
- `loop?`: boolean
- `path?`: string
- `removeKeys?`: [{index?: integer, time?: number, track: string}]
- `removeTracks?`: [string]
- `skippable?`: boolean
- `updateKeys?`: [{index?: integer, set: object, time?: number, track: string}]
- `updateTracks?`: object

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `duration`: number
- `key`: string
- `path`: string
- `player?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `tracks`: [string]
- `warnings`: [string]

### `timeline.get`

**Get Timeline** · _read-only_, _idempotent_

Reads a .timeline file: duration, loop, skippable and every track with its keys (only the fields set), its key for TimelinePlayer.timeline and problems found.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `key`: string
- `path`: string
- `timeline`: {duration?: number, holdFade?: boolean, loop?: boolean, skippable?: boolean, tracks?: [object]}
- `warnings`: [string]

### `timeline.new`

**New Timeline**

Writes a .timeline file (a cutscene) in `folder` (default: the Assets root) and imports it: the given `timeline`, else a starter of `duration` seconds with a camera track. `place` also adds an entity with a TimelinePlayer to the scene. Returns the asset, its key for TimelinePlayer.timeline, the tracks and problems. Change it with timeline.edit (tracks and keys) or timeline.set. A timeline is a cutscene: `duration` (seconds), `loop`, `skippable`, `holdFade` (keep the last fade on screen after the end; default it clears) and `tracks`. Each track: id (unique), kind (camera | transform | animation | audio | particles | fade | event | dialogue), name, target (an entity Name or "Parent/Child" path; empty = the active camera for camera tracks, unpositioned for audio, the world origin for particles, else the entity holding the TimelinePlayer), muted, keys. Every key has `time` (s); continuous kinds blend from the previous key with this key's `easing` (linear, quadIn, quadOut, quadInOut, cubicIn, cubicOut, cubicInOut, … default linear) unless `cut` is true. camera keys: position [x,y,z], lookAt [x,y,z] | lookAtEntity "Name" | rotation [x,y,z] degrees, fov (degrees; positions and aims are world space, also for a parented camera), cut, path [[x,y,z]…] (spline through position, these points and the next key's position until the next key, constant speed), followPath (face the travel direction). transform keys: position, rotation (degrees), scale, cut. animation keys: clip (Animator state or SpriteAnimator clip), blend (crossfade s), speed. audio keys: clip (audio file or .sfx: path under Assets/ or asset:<id>), volume, pitch, loop, duration (s), position (offset). particles keys: effect (.vfx or prefab path), duration (s; default the .vfx's), position, rotation. fade keys: amount (0 clear … 1 solid), color [r,g,b] sRGB. event keys: name, value (game code reads TimelinePlayer.events / world.timelineEvents()). dialogue keys: start the target's DialoguePlayer (or its first descendant's) conversation, or `dialogue` (a .dialogue file path or asset:<id>) instead; node (start node), wait (hold the timeline until the conversation ends). Every key is optional. A TimelinePlayer component (timeline: the file's asset:<id> or path, playOnStart, speed, loop) plays it.

Arguments:

- `duration?`: number
- `folder?`: string
- `name?`: string
- `place?`: boolean
- `timeline?`: {duration?: number, holdFade?: boolean, loop?: boolean, skippable?: boolean, tracks?: [object]}

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `duration`: number
- `key`: string
- `path`: string
- `player?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `tracks`: [string]
- `warnings`: [string]

### `timeline.open`

**Open in Timeline** · _idempotent_

Opens a .timeline file in the editor's Timeline tab (a preview of the open scene posed by the timeline, seen through its camera, with transport, scrubbing, the track strip and the key form) and brings the tab to the front. view.screenshot {source: "panel", panel: "timeline"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `timeline.sample`

**Sample Timeline** · _read-only_, _idempotent_

Evaluates a .timeline at `time` seconds without playing it: each camera / transform / fade track's position, rotation (degrees), scale, fov and fade there (look-at entities resolve in the open scene), and the animation / audio / particles / event keys fired by then. Use it to check a camera move or timing.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `time`: number

Result:

- `fired`: [string]
- `time`: number
- `tracks`: [{fadeAmount?: number, fadeColor?: number[3], fov?: number, kind: string, position?: number[3], rotation?: number[3], scale?: number[3], target: string, targetFound: boolean, track: string}]

### `timeline.set`

**Set Timeline** · _undoable_, _idempotent_

Replaces a .timeline file's whole contents (keys are sorted by time) and reimports it; playing TimelinePlayers pick it up. Undoable. For a few changes, timeline.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `timeline`: {duration?: number, holdFade?: boolean, loop?: boolean, skippable?: boolean, tracks?: [object]}

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `duration`: number
- `key`: string
- `path`: string
- `player?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `tracks`: [string]
- `warnings`: [string]

## tool

### `tool.set`

**Select Tool** · _idempotent_

Picks the viewport gizmo: `tool` is "move", "rotate" or "scale".

Arguments:

- `tool`: "move" \| "rotate" \| "scale"

### `tool.snapping`

**Snapping**

Turns gizmo snapping on or off (`enabled`; omitted toggles it): drags move, rotate and scale in the steps of settings.setEditor (default 0.5 units, 15° and 0.1). Holding Cmd (Ctrl elsewhere) during a drag inverts it.

Arguments:

- `enabled?`: boolean

Result:

- `enabled`: boolean

## transform

### `transform.lookAt`

**Look At** · _undoable_, _idempotent_

Turns the entity so its local -Z (a camera's or light's forward) points at `target` (another entity or a world point [x, y, z]), keeping +Y toward `up` (default [0, 1, 0]). Only the rotation changes. Aiming straight along `up` picks another up vector. Undoable (one step; edit.undo reverts it).

Arguments:

- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `target`: entity id \| number[3] — What to aim at: an entity id or a world point [x, y, z].
- `up?`: number[3] — [x, y, z]

### `transform.set`

**Set Transform** · _undoable_, _idempotent_

Sets the local Transform (position, rotation as a quaternion [x, y, z, w], scale) of each entity in `changes`, as one undo step. The gizmo records its drags with it. Undoable (one step; edit.undo reverts it).

Arguments:

- `changes`: [{entity: entity id, previous?: object, transform: object}]
- `label?`: string

## ui

### `ui.click`

**Click**

Clicks a UI element (by `path`, `label` with optional `role` / `index`, or a `point`) as the user would: `button` right opens context menus, `count` 2 double-clicks (frame a Hierarchy row's entity, open a folder), `modifiers` ["shift"] / ["mod"] extend selections. Returns the element, the focused element and any popup it opened with its items. A point on the 3D viewport picks like a click there.

Arguments:

- `button?`: "left" \| "right" \| "middle"
- `count?`: integer
- `index?`: integer
- `label?`: string
- `modifiers?`: [string]
- `path?`: string
- `point?`: number[2] — [x, y]
- `role?`: "group" \| "label" \| "button" \| "checkbox" \| "radioButton" \| "toggle" \| "slider" \| "textField" \| "numberField" \| "dropdown" \| "menu" \| "menuItem" \| "list" \| "listItem" \| "tree" \| "treeItem" \| "tabGroup" \| "tab" \| "scrollView" \| "splitView" \| "separator" \| "header" \| "colorWell" \| "dialog" \| "progressBar" \| "viewport" \| "image"

Result:

- `focused?`: string
- `opened?`: [{command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}]
- `point`: number[2] — [x, y]
- `target?`: {command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}
- `tooltip?`: string
- `viewport?`: boolean

### `ui.drag`

**Drag**

Drags from one UI element or point to another: press at `from`, move in `steps`, release at `to`. Reorders and reparents hierarchy rows, moves assets onto folders, drops assets into the viewport, the hierarchy or inspector fields, moves dock tabs, scrubs number fields and drags gizmos in the viewport.

Arguments:

- `button?`: "left" \| "right" \| "middle"
- `from`: {index?: integer, label?: string, path?: string, point?: number[2], role?: string (27 cases)}
- `modifiers?`: [string]
- `steps?`: integer
- `to`: {index?: integer, label?: string, path?: string, point?: number[2], role?: string (27 cases)}

Result:

- `focused?`: string
- `opened?`: [{command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}]
- `point`: number[2] — [x, y]
- `target?`: {command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}
- `tooltip?`: string
- `viewport?`: boolean

### `ui.find`

**Find UI Elements** · _read-only_, _idempotent_

UI elements whose label contains `label` (ignoring case), with `role`, running `command` and/or inside `root`, as ui.snapshot lists them (paths to act on).

Arguments:

- `command?`: string
- `label?`: string
- `role?`: "group" \| "label" \| "button" \| "checkbox" \| "radioButton" \| "toggle" \| "slider" \| "textField" \| "numberField" \| "dropdown" \| "menu" \| "menuItem" \| "list" \| "listItem" \| "tree" \| "treeItem" \| "tabGroup" \| "tab" \| "scrollView" \| "splitView" \| "separator" \| "header" \| "colorWell" \| "dialog" \| "progressBar" \| "viewport" \| "image"
- `root?`: string

Result:

- `elements`: [{command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}]

### `ui.hover`

**Hover** · _read-only_

Moves the pointer over a UI element or point and returns the tooltip shown there (without waiting for the delay).

Arguments:

- `index?`: integer
- `label?`: string
- `path?`: string
- `point?`: number[2] — [x, y]
- `role?`: "group" \| "label" \| "button" \| "checkbox" \| "radioButton" \| "toggle" \| "slider" \| "textField" \| "numberField" \| "dropdown" \| "menu" \| "menuItem" \| "list" \| "listItem" \| "tree" \| "treeItem" \| "tabGroup" \| "tab" \| "scrollView" \| "splitView" \| "separator" \| "header" \| "colorWell" \| "dialog" \| "progressBar" \| "viewport" \| "image"

Result:

- `focused?`: string
- `opened?`: [{command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}]
- `point`: number[2] — [x, y]
- `target?`: {command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}
- `tooltip?`: string
- `viewport?`: boolean

### `ui.key`

**Press Keys**

Presses keys as the user would: the focused widget or open popup gets each first, then the editor's shortcuts ("mod+z" undo, "mod+s" save, "mod+d" duplicate, "delete" (asks first), "f" frame, "escape"…; mod is Cmd on macOS, Ctrl elsewhere). Optionally clicks an element first to focus it.

Arguments:

- `keys`: [string]
- `label?`: string
- `path?`: string
- `role?`: "group" \| "label" \| "button" \| "checkbox" \| "radioButton" \| "toggle" \| "slider" \| "textField" \| "numberField" \| "dropdown" \| "menu" \| "menuItem" \| "list" \| "listItem" \| "tree" \| "treeItem" \| "tabGroup" \| "tab" \| "scrollView" \| "splitView" \| "separator" \| "header" \| "colorWell" \| "dialog" \| "progressBar" \| "viewport" \| "image"

Result:

- `focused?`: string
- `opened?`: [{command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}]
- `point`: number[2] — [x, y]
- `target?`: {command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}
- `tooltip?`: string
- `viewport?`: boolean

### `ui.scroll`

**Scroll**

Scrolls with the pointer over a UI element or point by `dx` / `dy` wheel units (negative dy scrolls a list down; over the viewport it zooms).

Arguments:

- `dx?`: number
- `dy?`: number
- `index?`: integer
- `label?`: string
- `path?`: string
- `point?`: number[2] — [x, y]
- `role?`: "group" \| "label" \| "button" \| "checkbox" \| "radioButton" \| "toggle" \| "slider" \| "textField" \| "numberField" \| "dropdown" \| "menu" \| "menuItem" \| "list" \| "listItem" \| "tree" \| "treeItem" \| "tabGroup" \| "tab" \| "scrollView" \| "splitView" \| "separator" \| "header" \| "colorWell" \| "dialog" \| "progressBar" \| "viewport" \| "image"

Result:

- `focused?`: string
- `opened?`: [{command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}]
- `point`: number[2] — [x, y]
- `target?`: {command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}
- `tooltip?`: string
- `viewport?`: boolean

### `ui.snapshot`

**UI Snapshot** · _read-only_, _idempotent_

The editor's widget tree as an accessibility snapshot: each element's path, role (button, textField, numberField, dropdown, treeItem, tab, menuItem…), label, value, rect [x, y, w, h] in window points, state (disabled, focused, selected, offscreen), tooltip and the command it runs. Tree rows, tabs, menu items and asset cells are elements too. Act on elements with ui.click, ui.type, ui.key, ui.drag, ui.scroll and ui.hover by path or label; prefer the command when an element names one. `root` limits it to a subtree (a panel: "editorRoot/dock/…"), `maxDepth` to levels; `all` keeps unlabeled groups.

Arguments:

- `all?`: boolean
- `maxDepth?`: integer
- `root?`: string

Result:

- `elements`: [{command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}]
- `focused?`: string
- `hovered?`: string
- `overlays`: [string]
- `window`: [number]

### `ui.type`

**Type**

Types `text` into a text or number field (clicked first when given by `path` / `label`; else the focused one). `replace` (default true with a field) selects its text first; `submit` presses Enter afterwards, which commits a number field, a rename or a path field.

Arguments:

- `index?`: integer
- `label?`: string
- `path?`: string
- `replace?`: boolean
- `role?`: "group" \| "label" \| "button" \| "checkbox" \| "radioButton" \| "toggle" \| "slider" \| "textField" \| "numberField" \| "dropdown" \| "menu" \| "menuItem" \| "list" \| "listItem" \| "tree" \| "treeItem" \| "tabGroup" \| "tab" \| "scrollView" \| "splitView" \| "separator" \| "header" \| "colorWell" \| "dialog" \| "progressBar" \| "viewport" \| "image"
- `submit?`: boolean
- `text`: string

Result:

- `focused?`: string
- `opened?`: [{command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}]
- `point`: number[2] — [x, y]
- `target?`: {command?: string, depth: integer, enabled?: boolean, focused?: boolean, hovered?: boolean, label?: string, offscreen?: boolean, path: string, rect: [number], role: string (27 cases), selected?: boolean, tooltip?: string, value?: string}
- `tooltip?`: string
- `viewport?`: boolean

## uiLayout

### `uiLayout.edit`

**Edit UI Layout** · _undoable_

Changes part of a .ui file in one undoable step, in this order: removeWidgets, addWidgets, updateWidgets (id → fields; null resets; "id" renames), moveWidgets, bindings (widget id → value key), values (sample values), then theme / colors / fontSize / safeArea / size / scaleMode / show / hide / navigation / focus. Running games show the change. Returns widget ids, value keys, events and warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `addWidgets?`: [{align?: "auto" \| "start" \| "center" \| "end" \| "stretch", anchor?: string (10 cases), background?: string, bind?: string, borderColor?: string, color?: string, cornerRadius?: number, event?: string, fit?: "fit" \| "fill" \| "stretch", fontSize?: number, grow?: number, height?: number, hidden?: boolean, hide?: object, id?: string, image?: string, justify?: "start" \| "center" \| "end" \| "spaceBetween", kind?: "progress" \| "health", max?: number, maxLength?: integer, min?: number, navDown?: string, navLeft?: string, navRight?: string, navUp?: string, offset?: number[2], on?: boolean, opacity?: number, padding?: number, parent?: string, placeholder?: string, primary?: boolean, segments?: integer, shadow?: boolean, show?: object, spacing?: number, step?: number, text?: string, textAlign?: "left" \| "center" \| "right", toggleStyle?: "checkbox" \| "switch", trail?: boolean, tween?: number, type?: string (11 cases), value?: number, visibleWhen?: string, width?: number, wrap?: boolean}]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `bindings?`: object
- `colors?`: object
- `focus?`: string
- `fontSize?`: number
- `hide?`: {delay?: number, distance?: number, duration?: number, easing?: string (25 cases), from?: "left" \| "right" \| "top" \| "bottom", kind?: "none" \| "fade" \| "slide" \| "scale", scale?: number}
- `moveWidgets?`: [{id: string, index?: integer, parent?: string}]
- `navigation?`: [string]
- `path?`: string
- `removeWidgets?`: [string]
- `safeArea?`: number
- `scaleMode?`: "none" \| "fit" \| "fill" \| "width" \| "height"
- `show?`: {delay?: number, distance?: number, duration?: number, easing?: string (25 cases), from?: "left" \| "right" \| "top" \| "bottom", kind?: "none" \| "fade" \| "slide" \| "scale", scale?: number}
- `size?`: number[2] — [x, y]
- `theme?`: string
- `updateWidgets?`: object
- `values?`: object

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `events`: [string]
- `path`: string
- `valueKeys`: [string]
- `warnings`: [string]
- `widgets`: [string]

### `uiLayout.get`

**Get UI Layout** · _read-only_, _idempotent_

Reads a .ui file: its theme, sample values and widgets as stored, the value keys and events game code uses, and the problems with it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `events`: [string]
- `layout`: {colors?: object, focus?: string, fontSize?: number, hide?: {delay?: number, distance?: number, duration?: number, easing?: string (25 cases), from?: "left" \| "right" \| "top" \| "bottom", kind?: "none" \| "fade" \| "slide" \| "scale", scale?: number}, navigation?: [string], safeArea?: number, scaleMode?: "none" \| "fit" \| "fill" \| "width" \| "height", show?: {delay?: number, distance?: number, duration?: number, easing?: string (25 cases), from?: "left" \| "right" \| "top" \| "bottom", kind?: "none" \| "fade" \| "slide" \| "scale", scale?: number}, size?: number[2], theme?: string, values?: object, widgets?: [object]}
- `path`: string
- `valueKeys`: [string]
- `warnings`: [string]

### `uiLayout.new`

**New UI Layout**

Writes a .ui file (a game menu or HUD) in `folder` (default: the Assets root) from a `preset` (hud, menu, dialogue, empty) plus optional `widgets`, and imports it. Returns the widget ids, value keys, events and warnings. Change it with uiLayout.edit (add/update/move/remove widgets, bindings, sample values) or uiLayout.set. A .ui file is a game menu or HUD: `theme` (game|dark|light|highContrast), `colors` (theme color name → "#RRGGBB[AA]"; names: text, secondaryText, accent, accentText, panel, panelBorder, control, controlHover, barBackground, health, warning, danger, hudText, hudShadow), `fontSize`, `safeArea` (points kept clear of the screen edges), `size` (design screen size [w, h]), `scaleMode` (none|fit|fill|width|height: how the whole layout scales with the screen from `size`; default none), `values` (sample values by key for the preview) and `widgets`, a flat list. Each widget: `id` (unique), `type` (panel|vstack|hstack|label|image|button|bar|spacer|slider|toggle|textField), `parent` (a container id; "" is the screen). The screen and panels place children by `anchor` (topLeft|top|topRight|left|center|right|bottomLeft|bottom|bottomRight|fill) and `offset` [x, y] points in from the anchored edges; stacks line them up (`spacing`, `align` auto|start|center|end|stretch, `justify` start|center|end|spaceBetween, children's `grow`). Also: width/height (omit to fit content), padding, background/borderColor/color ("#hex" or a theme color name), cornerRadius, opacity, hidden; label/button `text` with `{key}` placeholders, fontSize, textAlign, wrap, shadow; image `image` (path under Assets/), fit fit|fill|stretch; bar value, max, kind progress|health, segments, trail; button primary, event (default: the id); slider value, min, max, step; toggle text, on, toggleStyle checkbox|switch; textField text, placeholder, maxLength. Animation: the layout's and any widget's `show` / `hide` transitions ({kind: none|fade|slide|scale, duration, delay, easing, from: left|right|top|bottom, distance, scale}; a widget's play when visibleWhen / hidden change, the layout's when the game shows or hides it) and a bar's, label's or button's `tween` (seconds its numbers take to move to a new value). Gamepad / arrow-key focus: the layout's `navigation` (widget ids that Down / Right step through, Up / Left back, wrapping) and `focus` (focused first); a button's or input's navUp / navDown / navLeft / navRight override it. Sliders and toggles send their event when the player changes them, text fields on Enter, with the new value. `bind` ties a widget to a value key (bar fill = value / max; label/button text; image path; slider / toggle / text field value, written back as the player changes it) and `visibleWhen` shows it only while a key is truthy ("!key": falsy). In a game, a UILayoutPlayer component (uiLayout.place) shows a layout with no code; game code uses world.gameUI: set("health", 64), on("pause") { event, entity in ... }.

Arguments:

- `folder?`: string
- `name?`: string
- `preset?`: string
- `theme?`: string
- `widgets?`: [{align?: "auto" \| "start" \| "center" \| "end" \| "stretch", anchor?: string (10 cases), background?: string, bind?: string, borderColor?: string, color?: string, cornerRadius?: number, event?: string, fit?: "fit" \| "fill" \| "stretch", fontSize?: number, grow?: number, height?: number, hidden?: boolean, hide?: object, id?: string, image?: string, justify?: "start" \| "center" \| "end" \| "spaceBetween", kind?: "progress" \| "health", max?: number, maxLength?: integer, min?: number, navDown?: string, navLeft?: string, navRight?: string, navUp?: string, offset?: number[2], on?: boolean, opacity?: number, padding?: number, parent?: string, placeholder?: string, primary?: boolean, segments?: integer, shadow?: boolean, show?: object, spacing?: number, step?: number, text?: string, textAlign?: "left" \| "center" \| "right", toggleStyle?: "checkbox" \| "switch", trail?: boolean, tween?: number, type?: string (11 cases), value?: number, visibleWhen?: string, width?: number, wrap?: boolean}]

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `events`: [string]
- `path`: string
- `valueKeys`: [string]
- `warnings`: [string]
- `widgets`: [string]

### `uiLayout.open`

**Open in UI Builder** · _idempotent_

Opens a .ui file in the editor's UI Builder tab (live preview at a chosen screen size, widget tree with drag and drop, property form) and brings the tab to the front, optionally at `previewSize` with preview `values` and a widget selected. view.screenshot {source: "panel", panel: "uiBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string
- `previewSize?`: number[2] — [x, y]
- `select?`: string
- `values?`: object

Result:

- `path`: string

### `uiLayout.place`

**Add UI Layout to Scene** · _undoable_

Adds an entity with a UILayoutPlayer to the open scene, so the .ui layout shows over the game while it plays (editor play mode, GameRunner, exported games) with no game code. Game code sets its values and handles its events through world.gameUI (set(key, value), on(event) { event, entity in }). Undoable; returns the new entity. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `focus?`: boolean
- `name?`: string
- `order?`: integer
- `path?`: string
- `visible?`: boolean

Result:

- `entities`: [entity id]

### `uiLayout.set`

**Set UI Layout** · _undoable_, _idempotent_

Replaces a .ui file's whole contents and reimports it (running games show the new layout). Undoable. For a few changes, uiLayout.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `layout`: {colors?: object, focus?: string, fontSize?: number, hide?: {delay?: number, distance?: number, duration?: number, easing?: string (25 cases), from?: "left" \| "right" \| "top" \| "bottom", kind?: "none" \| "fade" \| "slide" \| "scale", scale?: number}, navigation?: [string], safeArea?: number, scaleMode?: "none" \| "fit" \| "fill" \| "width" \| "height", show?: {delay?: number, distance?: number, duration?: number, easing?: string (25 cases), from?: "left" \| "right" \| "top" \| "bottom", kind?: "none" \| "fade" \| "slide" \| "scale", scale?: number}, size?: number[2], theme?: string, values?: object, widgets?: [object]}
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `events`: [string]
- `path`: string
- `valueKeys`: [string]
- `warnings`: [string]
- `widgets`: [string]

## vfx

### `vfx.edit`

**Edit VFX** · _undoable_

Changes part of a .vfx file in one undoable step, in this order: removeEmitters (links to them go too), addEmitters, updateEmitters (name → fields to change; "name" renames, and links follow; e.g. {"Sparks": {"subEmitters": [{"trigger": "death", "emitter": "Pops", "count": 6}]}} or {"Smoke": {"texture": "Textures/puff.png", "atlasColumns": 4, "atlasRows": 4}}), then duration / background / ground. Placed copies update. Returns the emitter names and import warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `addEmitters?`: [{armWidth?: number, atlasColumns?: integer, atlasRows?: integer, attraction?: number, blend?: "additive" \| "alpha", bounce?: number, brightnessVariation?: number, bursts?: [object], capacity?: integer, collidesWithGround?: boolean, color?: [object], delay?: number, direction?: number[3], drag?: number, frameBlending?: boolean, frameCount?: integer, frameRate?: number, friction?: number, gravity?: number[3], groundHeight?: number, intensity?: number, killOnCollision?: boolean, lifetime?: number[2], lit?: boolean, name?: string, orbit?: number, position?: number[3], prewarm?: number, randomStartFrame?: boolean, rate?: number, rotation?: number[3], seed?: integer, shape?: "point" \| "sphere" \| "box" \| "disc", shapeSize?: number[3], size?: number[2], sizeOverLife?: [object], softness?: number, speed?: number[2], spin?: number, spiralArms?: integer, spiralTwist?: number, spread?: number, spriteTag?: string, stretch?: number, stretchMode?: "scaled" \| "streak", subEmitters?: [object], texture?: string, turbulence?: number, turbulenceFrequency?: number}]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `background?`: number[3] — [x, y, z]
- `duration?`: number
- `ground?`: boolean
- `path?`: string
- `removeEmitters?`: [string]
- `updateEmitters?`: object

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `duration`: number
- `emitters`: [string]
- `entities?`: [entity id]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `vfx.get`

**Get VFX** · _read-only_, _idempotent_

Reads a .vfx file: its emitters (every field, defaults included), duration, preview settings, the prefab to place, and problems found.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `effect`: {background?: number[3], duration?: number, emitters?: [object], ground?: boolean}
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `vfx.new`

**New VFX**

Writes a .vfx file in `folder` (default: the Assets root) and imports it as a prefab of particle emitters, from a `preset` (or `effect` contents), optionally placing it in the scene (`place`, at `position`; undoable). Returns the asset, its prefab, the emitter names and import warnings. Edit it later with vfx.edit (small changes) or vfx.set (whole contents); placed copies update. A VFX effect is a stack of GPU particle emitters: `emitters` (each: name, position [x,y,z] m and rotation [x,y,z] degrees relative to the effect, delay (seconds before it starts: timing offset), rate (particles/s), bursts [{time, count, interval, cycles}], capacity, prewarm (seconds pre-simulated so a continuous effect starts steady), lifetime [min,max] s, shape point|sphere|box|disc, shapeSize, direction [x,y,z], spread (cone half-angle, radians), speed [min,max], gravity [x,y,z], drag, turbulence, turbulenceFrequency, attraction, orbit, spiralArms, spiralTwist, armWidth, size [min,max] (half-width m), spin, sizeOverLife [{time, value}] (up to 4), color [{time, color [r,g,b,a] linear}] (up to 4, alpha fades), intensity (HDR glow), brightnessVariation, blend additive|alpha (alpha = smoke/dust, sorted, at most 262144 particles), stretch, stretchMode scaled|streak, collidesWithGround, groundHeight, bounce, friction, killOnCollision, softness, lit, seed, texture (an image, .proctex or .sprite by path relative to Assets/ or "asset:<id>"; its RGBA multiplies the color; "" = soft disc), atlasColumns / atlasRows (an image's flipbook grid; a .sprite sets its own from its frames), spriteTag (a .sprite's tag to play; "" = every frame), frameCount (0 = every cell), frameRate (fps looping; 0 = once over each particle's life), randomStartFrame, frameBlending, subEmitters [{trigger birth|death|collision, emitter (another emitter's name), count (particles per event, 1-1024), inheritVelocity}] (at most 2; the target emits only from those events: its rate, bursts, delay and position are ignored; targets can't have links of their own)), plus `duration` (seconds one run lasts; the editor preview loops after it), `background` [r,g,b] and `ground` (preview only). Every key is optional. Presets: fire, smoke, sparks, explosion, magicHit, rain, snow, dust, portal.

Arguments:

- `effect?`: {background?: number[3], duration?: number, emitters?: [object], ground?: boolean}
- `folder?`: string
- `name?`: string
- `place?`: boolean
- `position?`: number[3] — [x, y, z]
- `preset?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `duration`: number
- `emitters`: [string]
- `entities?`: [entity id]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `vfx.open`

**Open in VFX Builder** · _idempotent_

Opens a .vfx file in the editor's VFX Builder tab (a looping live preview over a ground plane, with the emitters form) and brings the tab to the front. view.screenshot {source: "panel", panel: "vfxBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `vfx.set`

**Set VFX** · _undoable_, _idempotent_

Replaces a .vfx file's whole contents and reimports it; placed copies update. Undoable. For a few changes, vfx.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `effect`: {background?: number[3], duration?: number, emitters?: [object], ground?: boolean}
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `duration`: number
- `emitters`: [string]
- `entities?`: [entity id]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

## view

### `view.animateInEditMode`

**Animate in Scene View**

Turns on (or off, or toggles without `on`) animation in the edit-mode Scene view: characters, glTF models with asset clips and animation graphs play their Animator (from its initial state, e.g. a character's idle) while you edit, without entering play mode. Editor-only and never saved: the pose is shown, not written into the scene, so saving, undo and the inspector see the authored transforms. Returns whether it is on and how many animators play.

Arguments:

- `on?`: boolean

Result:

- `animators`: integer
- `on`: boolean

### `view.appearance`

**Appearance** · _idempotent_

The editor's theme and UI zoom (the toolbar's View menu): sets `theme` (Dark, Light or High Contrast; the engine's Game preset is for game UI and is refused) and / or `uiScale` (0.85-2) when given and saves them in the prefs, then returns them. A zoom the window is too small for is lowered while it lasts (`effectiveUIScale`). Needs the editor window.

Arguments:

- `theme?`: string
- `uiScale?`: number

Result:

- `effectiveUIScale`: number
- `theme`: string
- `themes`: [string]
- `uiScale`: number

### `view.frameSelection`

**Frame Selection** · _idempotent_

Moves the viewport camera to frame the selected entities, or `entities` (without selecting them). Needs the editor window.

Arguments:

- `entities?`: [entity id]

### `view.gameCamera`

**Game View**

Whether play happens in the Game view: Play brings the Game tab (the scene's Camera entity) to the front and the game gets the keyboard and the mouse over it; off, Play stays in the Scene view (the editor camera). While playing it switches between the two tabs, and picking a tab sets it. On by default.

Arguments:

- `enabled?`: boolean

Result:

- `enabled`: boolean

### `view.goTo`

**Go to Object**

Selects an entity and frames it in the Scene view, as Frame Selection does (in the editor, Cmd/Ctrl+G opens a search that filters the scene's entities by name as you type). Give `entity`, or `name`: matched without regard to case against whole names and "Parent/Child" paths first, then as part of a name. A name that matches more than one entity fails and lists the candidates with their ids; pass one as `entity`. Needs the editor window.

Arguments:

- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `name?`: string

Result:

- `camera?`: {distance: number, eye: number[3], pitch: number, pivot: number[3], yaw: number}
- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `name`: string
- `path`: string

### `view.home`

**Return to Origin** · _idempotent_

Puts the Scene view's camera back on its default view of the origin (Home key, View menu): pivot [0, 0.5, 0], the default yaw and pitch, 15 m away. `pivot` and `distance` aim it elsewhere from the same angle. Returns the camera. Needs the editor window.

Arguments:

- `distance?`: number
- `pivot?`: number[3] — [x, y, z]

Result:

- `distance`: number
- `eye`: number[3] — [x, y, z]
- `pitch`: number
- `pivot`: number[3] — [x, y, z]
- `yaw`: number

### `view.pick`

**Pick** · _read-only_, _idempotent_

Returns the entity and surface point (world space, with the normal) at pixel (`x`, `y`) of a view: pass the same view arguments as view.screenshot (source "viewport" (default), "game" or "camera", camera, eye, target, fov, width, height, maxSize) to pick in its image. "game" and "camera" work headless.

Arguments:

- `camera?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `eye?`: number[3] — [x, y, z]
- `fov?`: number
- `height?`: integer
- `maxSize?`: integer
- `source?`: "viewport" \| "game" \| "camera" \| "window" \| "panel" \| "thumbnail"
- `target?`: number[3] — [x, y, z]
- `width?`: integer
- `x`: number
- `y`: number

Result:

- `direction`: number[3] — [x, y, z]
- `distance?`: number
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `hit`: boolean
- `name?`: string
- `normal?`: number[3] — [x, y, z]
- `origin`: number[3] — [x, y, z]
- `point?`: number[3] — [x, y, z]

### `view.scenePostFX`

**Scene View Post-FX** · _idempotent_

Shows post-processing in the Scene view (the View menu's Scene Post-FX items): `mode` off (the plain scene, the default), on (the look the game would use at the editor camera: the scene camera's post-fx profile or the scene's PostProcess component, with the PostFXVolumes the editor camera is in blended over it) or split (plain left of `split`, 0.05-0.95 of the width, the look right of it). Without arguments it only returns the setting. view.screenshot {source: "window"} shows the result (the "viewport" source renders without it).

Arguments:

- `mode?`: "off" \| "on" \| "split"
- `split?`: number

Result:

- `mode`: "off" \| "on" \| "split"
- `split`: number

### `view.screenshot`

**Screenshot** · _read-only_, _idempotent_, _deferred_

Returns a PNG of `source`: "viewport" (default; what the user sees, from the editor camera), "game" (the scene's Camera, or `camera`), "camera" (from `eye` looking at `target`, `fov` degrees, without moving the user's view), "window", "panel" (`panel`) or "thumbnail" (`asset`). `grid`, `gizmos` and `outline` toggle the viewport overlays; `maxSize` scales it down. Finishes after the next frame renders. Needs the editor window.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `camera?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `eye?`: number[3] — [x, y, z]
- `fov?`: number
- `gizmos?`: boolean
- `grid?`: boolean
- `height?`: integer
- `maxSize?`: integer
- `outline?`: boolean
- `panel?`: string
- `source?`: "viewport" \| "game" \| "camera" \| "window" \| "panel" \| "thumbnail"
- `target?`: number[3] — [x, y, z]
- `width?`: integer

Result:

- `camera?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `eye?`: number[3] — [x, y, z]
- `forward?`: number[3] — [x, y, z]
- `image`: {data?: string, height: integer, mimeType: string, width: integer}
- `source`: "viewport" \| "game" \| "camera" \| "window" \| "panel" \| "thumbnail"

## vscript

### `vscript.attach`

**Attach Visual Script** · _undoable_

Puts a VisualScript component running the .vscript graph on `entity` (replacing one it has), with the graph's exposed variables listed for per-entity values. Undoable. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `entity`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `path?`: string

Result:

- `added?`: [string]
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `attachedTo?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `functions`: [string]
- `nodes`: [string]
- `path`: string
- `variables`: [string]
- `warnings`: [string]

### `vscript.edit`

**Edit Visual Script** · _undoable_

Changes part of a .vscript graph in one undoable step, in this order: removeNodes, addNodes, updateNodes, disconnect, connect (in `function` when given), then variables, removeVariables, functions, signatures (a function's inputs and outputs, with renames: wires on its entry, return and call nodes follow, and those to removed pins go), removeFunctions, comments, removeComments, actions. New nodes without an id get one from their type (returned in `added`); nodes without x/y are placed right of the others. A link into a data input that has one replaces it. Returns node ids and problems (unconnected required inputs, type mismatches, unreachable nodes). A .vscript file is a node graph run by the VisualScript component in play mode and built games (no game module needed; edits apply while playing). `nodes`: {id, type, x, y, config {settings such as variable, component, field, key, name}, inputs {literal values for unconnected input pins}}. `links`: {"from": "node.pin", "to": "node.pin"}, always from an output pin to an input pin. Exec pins carry the flow (most nodes: input `in`, output `out`; branch: `true`/`false`; loops: `body`/`done`); event nodes (event.start, event.update, event.keyPressed, event.triggerEnter, event.custom…) start flows. Data pins are typed (bool, int, float, string, vec2, vec3, vec4, color, quat, entity, asset, array, map, any) and convert automatically where it makes sense; an unconnected entity input means the script's own entity. `variables`: {name, type, default, exposed}; `functions`: {name, inputs, outputs, nodes, links, macro?} called with function.call (config.function), starting at function.entry and ending at function.return (a `macro` is copied into each use instead, and its inputs and outputs may be exec pins). `reroute` nodes bend a wire. `actions`: input actions {"jump": ["key.space", "pad.south"]} for event.actionPressed. List node types and their pins with vscript.nodes {search}. Undoable (one step; edit.undo reverts it).

Arguments:

- `actions?`: object
- `addNodes?`: [{breakpoint?: boolean, collapsed?: boolean, comment?: string, config?: object, id?: string, inputs?: object, type?: string, x?: number, y?: number}]
- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `comments?`: [{color?: string, height?: number, id?: string, text?: string, width?: number, x?: number, y?: number}]
- `connect?`: [string[2]]
- `disconnect?`: [string[2]]
- `function?`: string
- `functions?`: [{inputs?: [object], links?: [string[2]], macro?: boolean, name?: string, nodes?: [object], outputs?: [object], pure?: boolean}]
- `path?`: string
- `removeComments?`: [string]
- `removeFunctions?`: [string]
- `removeNodes?`: [string]
- `removeVariables?`: [string]
- `signatures?`: [{function: string, inputs?: [object], outputs?: [object], renamedInputs?: object, renamedOutputs?: object}]
- `updateNodes?`: [{breakpoint?: boolean, collapsed?: boolean, comment?: string, config?: object, id: string, inputs?: object, type?: string, x?: number, y?: number}]
- `variables?`: [{default?: any, exposed?: boolean, name?: string, tooltip?: string, type?: string (15 cases)}]

Result:

- `added?`: [string]
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `attachedTo?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `functions`: [string]
- `nodes`: [string]
- `path`: string
- `variables`: [string]
- `warnings`: [string]

### `vscript.get`

**Get Visual Script** · _read-only_, _idempotent_

Reads a .vscript graph as stored (variables, nodes, links, functions, comments, actions) and its problems.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `graph`: {actions?: object, comments?: [object], functions?: [object], links?: [string[2]], nodes?: [object], variables?: [object]}
- `issues`: [{severity: string}]
- `path`: string

### `vscript.new`

**New Visual Script** · _undoable_

Writes a .vscript graph in `folder` (default: the Assets root) from `template` (empty, spinner, mover, pickup, timer) and imports it; with `target` (an entity id) also puts a VisualScript component running it on that entity (undoable). Build it with vscript.edit (addNodes, connect, variables…), find nodes with vscript.nodes. A .vscript file is a node graph run by the VisualScript component in play mode and built games (no game module needed; edits apply while playing). `nodes`: {id, type, x, y, config {settings such as variable, component, field, key, name}, inputs {literal values for unconnected input pins}}. `links`: {"from": "node.pin", "to": "node.pin"}, always from an output pin to an input pin. Exec pins carry the flow (most nodes: input `in`, output `out`; branch: `true`/`false`; loops: `body`/`done`); event nodes (event.start, event.update, event.keyPressed, event.triggerEnter, event.custom…) start flows. Data pins are typed (bool, int, float, string, vec2, vec3, vec4, color, quat, entity, asset, array, map, any) and convert automatically where it makes sense; an unconnected entity input means the script's own entity. `variables`: {name, type, default, exposed}; `functions`: {name, inputs, outputs, nodes, links, macro?} called with function.call (config.function), starting at function.entry and ending at function.return (a `macro` is copied into each use instead, and its inputs and outputs may be exec pins). `reroute` nodes bend a wire. `actions`: input actions {"jump": ["key.space", "pad.south"]} for event.actionPressed. List node types and their pins with vscript.nodes {search}. Undoable (one step; edit.undo reverts it).

Arguments:

- `folder?`: string
- `name?`: string
- `target?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `template?`: "empty" \| "spinner" \| "mover" \| "pickup" \| "timer"

Result:

- `added?`: [string]
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `attachedTo?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `functions`: [string]
- `nodes`: [string]
- `path`: string
- `variables`: [string]
- `warnings`: [string]

### `vscript.nodes`

**Visual Script Nodes** · _read-only_, _idempotent_

Lists the node types a .vscript graph can use, with their pins (name, type, default) and config settings: events, flow, math, vectors, logic, text, arrays, maps, variables, functions, world, transform, components (a get and a set node per reflected field of every registered component, e.g. type component.get with config {component: Light, field: intensity}), audio, effects, physics, scenes, tweens, data tables, and game modules' own nodes. Add one with vscript.edit {addNodes: [{type, config}]} using the entry's `type` and `config`.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `componentFields?`: boolean
- `limit?`: integer
- `path?`: string
- `pinType?`: "exec" \| "any" \| "bool" \| "int" \| "float" \| "string" \| "vec2" \| "vec3" \| "vec4" \| "color" \| "quat" \| "entity" \| "asset" \| "array" \| "map"
- `search?`: string

Result:

- `matched`: integer
- `nodes`: [{category: string, kind: string, title: string, type: string}]

### `vscript.open`

**Open in Visual Script Editor**

Shows a .vscript graph in the Visual Script tab next to the Scene view: nodes and wires on a canvas (drag to move, drag from a pin to wire, right-click or Space to search-add), problems drawn on their nodes and, while playing, the flow highlighted live.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `added?`: [string]
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `attachedTo?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `functions`: [string]
- `nodes`: [string]
- `path`: string
- `variables`: [string]
- `warnings`: [string]

### `vscript.set`

**Set Visual Script** · _undoable_, _idempotent_

Replaces a .vscript file's whole graph and reimports it (a running game picks it up next frame, keeping variables). Undoable. For a few changes, vscript.edit is shorter. A .vscript file is a node graph run by the VisualScript component in play mode and built games (no game module needed; edits apply while playing). `nodes`: {id, type, x, y, config {settings such as variable, component, field, key, name}, inputs {literal values for unconnected input pins}}. `links`: {"from": "node.pin", "to": "node.pin"}, always from an output pin to an input pin. Exec pins carry the flow (most nodes: input `in`, output `out`; branch: `true`/`false`; loops: `body`/`done`); event nodes (event.start, event.update, event.keyPressed, event.triggerEnter, event.custom…) start flows. Data pins are typed (bool, int, float, string, vec2, vec3, vec4, color, quat, entity, asset, array, map, any) and convert automatically where it makes sense; an unconnected entity input means the script's own entity. `variables`: {name, type, default, exposed}; `functions`: {name, inputs, outputs, nodes, links, macro?} called with function.call (config.function), starting at function.entry and ending at function.return (a `macro` is copied into each use instead, and its inputs and outputs may be exec pins). `reroute` nodes bend a wire. `actions`: input actions {"jump": ["key.space", "pad.south"]} for event.actionPressed. List node types and their pins with vscript.nodes {search}. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `graph`: {actions?: object, comments?: [object], functions?: [object], links?: [string[2]], nodes?: [object], variables?: [object]}
- `path?`: string

Result:

- `added?`: [string]
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `attachedTo?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).
- `functions`: [string]
- `nodes`: [string]
- `path`: string
- `variables`: [string]
- `warnings`: [string]

### `vscript.step`

**Step Visual Script**

While play is paused at a visual script breakpoint: `into` shows the next node of the flow (entering function calls), `over` the next one not inside a call made here, `out` the next one in the caller, `continue` resumes play. The flow from the breakpoint to the end of its event was recorded during the frame (scripts run inside the world's update and can't stop half way), so each step shows that node's inputs, outputs and the variables as it started; past the end, play resumes until the same entity's graph runs another node and pauses there. Without `mode`, reports the current step.

Arguments:

- `mode?`: "into" \| "over" \| "out" \| "continue"

Result:

- `atBreakpoint`: boolean
- `count`: integer
- `index?`: integer
- `paused`: boolean
- `playing`: boolean
- `step?`: {depth: integer, entity?: entity id, error?: string, function?: string, graph: string, inputs: object, node: string, outputs: object, variables: object}
- `truncated`: boolean

### `vscript.validate`

**Validate Visual Script** · _read-only_, _idempotent_

Checks a .vscript file (or a `graph` given inline): unknown node types, wires to missing pins or between incompatible types, several wires into one input, unconnected required inputs, literal values that don't fit their pin, unreachable nodes (info: unused pure nodes), unknown variables, functions and components, loops among data wires. `valid` means no errors.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `graph?`: {actions?: object, comments?: [object], functions?: [object], links?: [string[2]], nodes?: [object], variables?: [object]}
- `path?`: string

Result:

- `errors`: integer
- `issues`: [{severity: string}]
- `valid`: boolean
- `warnings`: integer
