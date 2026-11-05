# Editor MCP tool reference

Generated from the editor's command registry by `swift run Editor --mcp-tool-docs > docs/MCPTools.md`;
`swift test --filter ToolReferenceTests` fails when it is out of date. Every editor command is a tool
named by its id (see README › Editor › AI control). 138 tools.

Hints: **read-only** (changes nothing), **undoable** (one undo step, labeled "AI: …" when an MCP client
made it), **destructive** (can lose work undo can't bring back; needs `confirm: true`), **idempotent**
(running it again changes nothing more), **deferred** (answers after a frame or more). Types: entity ids
are 32-hex strings, assets `asset:<id>[#object]` references, vectors `[x, y, z]` number arrays, `?` marks
optional arguments.

| Namespace | Tools |
|---|---|
| `activity` | [`activity.clear`](#activityclear), [`activity.list`](#activitylist), [`activity.revert`](#activityrevert) |
| `ai` | [`ai.settings`](#aisettings) |
| `asset` | [`asset.applySettings`](#assetapplysettings), [`asset.assign`](#assetassign), [`asset.delete`](#assetdelete), [`asset.extractMaterials`](#assetextractmaterials), [`asset.get`](#assetget), [`asset.import`](#assetimport), [`asset.instantiate`](#assetinstantiate), [`asset.list`](#assetlist), [`asset.move`](#assetmove), [`asset.newFolder`](#assetnewfolder), [`asset.newMaterial`](#assetnewmaterial), [`asset.newProceduralTexture`](#assetnewproceduraltexture), [`asset.reimport`](#assetreimport), [`asset.rename`](#assetrename), [`asset.select`](#assetselect), [`asset.setProceduralTexture`](#assetsetproceduraltexture), [`asset.waitForImports`](#assetwaitforimports) |
| `component` | [`component.add`](#componentadd), [`component.remove`](#componentremove), [`component.setField`](#componentsetfield), [`component.types`](#componenttypes) |
| `diagnostics` | [`diagnostics.get`](#diagnosticsget) |
| `edit` | [`edit.batch`](#editbatch), [`edit.beginBatch`](#editbeginbatch), [`edit.endBatch`](#editendbatch), [`edit.redo`](#editredo), [`edit.undo`](#editundo) |
| `entity` | [`entity.create`](#entitycreate), [`entity.delete`](#entitydelete), [`entity.duplicate`](#entityduplicate), [`entity.find`](#entityfind), [`entity.get`](#entityget), [`entity.rename`](#entityrename), [`entity.reparent`](#entityreparent) |
| `file` | [`file.openInCodeEditor`](#fileopenincodeeditor), [`file.reveal`](#filereveal) |
| `files` | [`files.list`](#fileslist), [`files.newScene`](#filesnewscene), [`files.open`](#filesopen) |
| `game` | [`game.build`](#gamebuild), [`game.info`](#gameinfo), [`game.load`](#gameload), [`game.reload`](#gamereload), [`game.unload`](#gameunload) |
| `input` | [`input.clear`](#inputclear), [`input.inject`](#inputinject), [`input.state`](#inputstate) |
| `launcher` | [`launcher.dismiss`](#launcherdismiss), [`launcher.settings`](#launchersettings), [`launcher.show`](#launchershow) |
| `layout` | [`layout.reset`](#layoutreset) |
| `log` | [`log.clear`](#logclear), [`log.read`](#logread) |
| `material` | [`material.get`](#materialget), [`material.set`](#materialset) |
| `meshBuild` | [`meshBuild.edit`](#meshbuildedit), [`meshBuild.get`](#meshbuildget), [`meshBuild.new`](#meshbuildnew), [`meshBuild.open`](#meshbuildopen), [`meshBuild.set`](#meshbuildset) |
| `net` | [`net.overlay`](#netoverlay), [`net.setConditions`](#netsetconditions), [`net.start`](#netstart), [`net.stats`](#netstats), [`net.stop`](#netstop), [`net.view`](#netview) |
| `panel` | [`panel.close`](#panelclose), [`panel.dock`](#paneldock), [`panel.focus`](#panelfocus), [`panel.list`](#panellist), [`panel.open`](#panelopen) |
| `play` | [`play.pause`](#playpause), [`play.setTimeScale`](#playsettimescale), [`play.start`](#playstart), [`play.state`](#playstate), [`play.step`](#playstep), [`play.stop`](#playstop), [`play.toggle`](#playtoggle) |
| `prefab` | [`prefab.apply`](#prefabapply), [`prefab.create`](#prefabcreate), [`prefab.createVariant`](#prefabcreatevariant), [`prefab.overrides`](#prefaboverrides), [`prefab.revert`](#prefabrevert), [`prefab.unpack`](#prefabunpack) |
| `project` | [`project.close`](#projectclose), [`project.new`](#projectnew), [`project.open`](#projectopen), [`project.recent.list`](#projectrecentlist), [`project.recent.locate`](#projectrecentlocate), [`project.recent.pin`](#projectrecentpin), [`project.recent.remove`](#projectrecentremove), [`project.recent.reveal`](#projectrecentreveal) |
| `scene` | [`scene.discardRecovery`](#scenediscardrecovery), [`scene.hierarchy`](#scenehierarchy), [`scene.listRecovery`](#scenelistrecovery), [`scene.new`](#scenenew), [`scene.open`](#sceneopen), [`scene.raycast`](#sceneraycast), [`scene.recover`](#scenerecover), [`scene.save`](#scenesave), [`scene.saveAs`](#scenesaveas) |
| `script` | [`script.list`](#scriptlist), [`script.new`](#scriptnew), [`script.open`](#scriptopen), [`script.save`](#scriptsave) |
| `selection` | [`selection.clear`](#selectionclear), [`selection.get`](#selectionget), [`selection.set`](#selectionset) |
| `settings` | [`settings.get`](#settingsget), [`settings.setEditor`](#settingsseteditor), [`settings.setProject`](#settingssetproject) |
| `stats` | [`stats.get`](#statsget) |
| `tool` | [`tool.set`](#toolset), [`tool.snapping`](#toolsnapping) |
| `transform` | [`transform.lookAt`](#transformlookat), [`transform.set`](#transformset) |
| `ui` | [`ui.click`](#uiclick), [`ui.drag`](#uidrag), [`ui.find`](#uifind), [`ui.hover`](#uihover), [`ui.key`](#uikey), [`ui.scroll`](#uiscroll), [`ui.snapshot`](#uisnapshot), [`ui.type`](#uitype) |
| `vfx` | [`vfx.edit`](#vfxedit), [`vfx.get`](#vfxget), [`vfx.new`](#vfxnew), [`vfx.open`](#vfxopen), [`vfx.set`](#vfxset) |
| `view` | [`view.appearance`](#viewappearance), [`view.frameSelection`](#viewframeselection), [`view.gameCamera`](#viewgamecamera), [`view.pick`](#viewpick), [`view.screenshot`](#viewscreenshot) |

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
- `kind?`: "mesh" \| "material" \| "texture" \| "prefab"

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
- `kind?`: "mesh" \| "material" \| "texture" \| "prefab"
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
- `material?`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset id, filter?: "linear" \| "nearest", metallic?: number, metallicRoughnessTexture?: asset id, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset id, occlusionStrength?: number, occlusionTexture?: asset id, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset id, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2]}
- `name?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `path`: string

### `asset.newProceduralTexture`

**New Procedural Texture**

Writes a .proctex file in `folder`: a texture generated from parameters (generator windowGrid, checker, gradient, noise, bricks or stripes; size, colors, seed, counts, margin, variation; see README, Procedural textures), imported like any texture so materials can use its `texture` object. Returns its asset id and path. Change it with asset.setProceduralTexture.

Arguments:

- `folder?`: string
- `generator?`: "windowGrid" \| "checker" \| "gradient" \| "noise" \| "bricks" \| "stripes"
- `name?`: string
- `texture?`: {angle?: number, colorA?: number[3], colorB?: number[3], colorC?: number[3], columns?: integer, fraction?: number, generator?: "windowGrid" \| "checker" \| "gradient" \| "noise" \| "bricks" \| "stripes", height?: integer, margin?: number, octaves?: integer, rows?: integer, scale?: integer, seed?: integer, variation?: number, width?: integer}

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
- `texture`: {angle?: number, colorA?: number[3], colorB?: number[3], colorC?: number[3], columns?: integer, fraction?: number, generator?: "windowGrid" \| "checker" \| "gradient" \| "noise" \| "bricks" \| "stripes", height?: integer, margin?: number, octaves?: integer, rows?: integer, scale?: integer, seed?: integer, variation?: number, width?: integer}

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

Rebuilds the game module in the background (one direct `swiftc` call for the game target once a build plan is cached, else `swift build --target <game>`, or its build command), then swaps it in with the scene kept: game components (scene, play snapshot, undo history) are serialized, the old code's willUnload state saved, the new types registered and the components restored (new fields get defaults, removed fields are dropped, components whose type is gone stay as JSON), the new code's didLoad given the state; play mode goes on with the new systems. Build errors go to the console and the old code keeps running. Returns what changed, how it was built and the build, link, load and swap times. Keeps the undo history.

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

## input

### `input.clear`

**Clear Input** · _idempotent_

Drops scheduled input and releases every injected key and button.

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
- `material`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset id, filter?: "linear" \| "nearest", metallic?: number, metallicRoughnessTexture?: asset id, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset id, occlusionStrength?: number, occlusionTexture?: asset id, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset id, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2]}

### `material.set`

**Edit Material** · _undoable_, _idempotent_

Changes the .material file's fields and reimports it (the viewport updates). Fields left out in `material` keep their current values (`null` clears a texture); `reset: true` starts from the default material instead. A model's own materials are read-only: asset.extractMaterials makes editable .material files. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `label?`: string
- `material`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset id, filter?: "linear" \| "nearest", metallic?: number, metallicRoughnessTexture?: asset id, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset id, occlusionStrength?: number, occlusionTexture?: asset id, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset id, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2]}
- `previous?`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset id, filter?: "linear" \| "nearest", metallic?: number, metallicRoughnessTexture?: asset id, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset id, occlusionStrength?: number, occlusionTexture?: asset id, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset id, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2]}
- `reset?`: boolean
- `transient?`: boolean

## meshBuild

### `meshBuild.edit`

**Edit Mesh Build** · _undoable_

Changes part of a .meshbuild file in one undoable step, in this order: removeParts, addParts, updateParts (name → fields to change; "name" renames), removeAnimations, addAnimations, then addMotions / addTracks into `animation`. Placed copies update. Returns the part and animation names and import warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `addAnimations?`: [{autoplay?: boolean, loop?: "once" \| "loop" \| "pingPong", motions?: [object], name?: string, speed?: number, tracks?: [object]}]
- `addMotions?`: [{amount?: number, axis?: "x" \| "y" \| "z", kind?: "spin" \| "bob" \| "swing" \| "pulse" \| "shake", part?: string, period?: number}]
- `addParts?`: [{color?: number[3], glow?: number[3], glowStrength?: number, material?: string, metallic?: number, name?: string, opacity?: number, parent?: string, position?: number[3], rotation?: number[3], roughness?: number, segments?: integer, shape?: string (12 cases), size?: number[3], texture?: string, textureScale?: number[2], thickness?: number, worldUV?: boolean}]
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
- `entities?`: [entity id]
- `parts`: [string]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `meshBuild.get`

**Get Mesh Build** · _read-only_, _idempotent_

Reads a .meshbuild file: its parts and animations (every field, defaults included), the prefab to place, and problems with its references.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `build`: {animations?: [object], parts?: [object]}
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `meshBuild.new`

**New Mesh Build**

Writes a .meshbuild file in `folder` (default: the Assets root) and imports it as a model (a prefab of its parts, one mesh and material per part), optionally placing it in the scene (`place`, at `position`; undoable). Returns the asset, its prefab, the part names and import warnings. Edit it later with meshBuild.edit (small changes) or meshBuild.set (whole contents); placed copies update. A mesh build is a model made of shapes: `parts` (each: name, shape group|box|sphere|hemisphere|cylinder|cone|capsule|torus|tube|plane|wedge|pyramid, parent (another part's name; children move with it), position [x,y,z] m in the parent's space, rotation [x,y,z] degrees, size [x,y,z] m (the box the shape fills; cylinders/cones/capsules run along Y), segments, thickness (tube wall), color [r,g,b] 0-1 sRGB, opacity, texture (path under Assets/ such as "Textures/brick.png" or a .proctex, or "asset:<id>"), textureScale [u,v], worldUV (texture keeps its size in meters), metallic, roughness, glow [r,g,b] emitted color, glowStrength, material (a .material asset replacing the look)) and `animations` (each: name, autoplay (default true; every autoplay animation plays at once in play mode and games), loop loop|once|pingPong, speed, motions (ready-made: {part, kind spin|bob|swing|pulse|shake, axis x|y|z, amount (spin: turns, bob/shake: m, swing: degrees, pulse: growth fraction), period seconds}) and tracks (keyframes: {part, property position|rotation|scale, interpolation linear|hermite|step, keys [{time, value [x,y,z]}]}; values are relative to the part's rest pose: position offset in m, rotation degrees added, scale multiplier (1 = unchanged))). Every key is optional. A group part has no mesh: use it as a pivot (hinge, turret) for animated children.

Arguments:

- `build?`: {animations?: [object], parts?: [object]}
- `folder?`: string
- `name?`: string
- `place?`: boolean
- `position?`: number[3] — [x, y, z]

Result:

- `animations`: [string]
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `entities?`: [entity id]
- `parts`: [string]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

### `meshBuild.open`

**Open in Mesh Builder** · _idempotent_

Opens a .meshbuild file in the editor's Mesh Builder tab (a viewport showing just the model, with gizmos to place parts, live animation preview and the parts form) and brings the tab to the front. view.screenshot {source: "panel", panel: "meshBuilder"} shows it.

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

Result:

- `path`: string

### `meshBuild.set`

**Set Mesh Build** · _undoable_, _idempotent_

Replaces a .meshbuild file's whole contents and reimports it; placed copies update. Undoable. For a few changes, meshBuild.edit is shorter. Undoable (one step; edit.undo reverts it).

Arguments:

- `asset?`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `build`: {animations?: [object], parts?: [object]}
- `path?`: string

Result:

- `animations`: [string]
- `asset`: asset id — An asset id: 32 hex digits, with or without the "asset:" prefix (see the editor://assets resource).
- `entities?`: [entity id]
- `parts`: [string]
- `path`: string
- `prefab`: asset id — An asset: "asset:<id>" (a bare id works too) for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `warnings`: [string]

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

Opens the project at `path` (or a recent project by name), scans its assets and imports what changed (in the background); the project goes to the top of project.recent.list and the launcher closes. The scene stays open unless `openLastScene` is true. A project whose Project.json records another engine version (`engineVersion`) is refused unless `allowVersionMismatch` is true; opened, it is stamped with this engine's version (0.3.0). Returns the project's root folder. Destructive only when `openLastScene` is true and the open scene has unsaved changes: then pass confirm: true.

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

Creates a new Swift game script file with standard component boilerplate.

Arguments:

- `name`: string
- `template?`: string

Result:

- `created`: boolean
- `path`: string

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

Saves code to a project Swift game script and optionally triggers hot reloading. Only project script folders can be written.

Arguments:

- `content`: string
- `path`: string
- `reload?`: boolean

Result:

- `path`: string
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

Clicks a UI element (by `path`, `label` with optional `role` / `index`, or a `point`) as the user would: `button` right opens context menus, `count` 2 double-clicks (rename a tree row, open a folder), `modifiers` ["shift"] / ["mod"] extend selections. Returns the element, the focused element and any popup it opened with its items. A point on the 3D viewport picks like a click there.

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

## vfx

### `vfx.edit`

**Edit VFX** · _undoable_

Changes part of a .vfx file in one undoable step, in this order: removeEmitters, addEmitters, updateEmitters (name → fields to change; "name" renames), then duration / background / ground. Placed copies update. Returns the emitter names and import warnings. Undoable (one step; edit.undo reverts it).

Arguments:

- `addEmitters?`: [{armWidth?: number, attraction?: number, blend?: "additive" \| "alpha", bounce?: number, brightnessVariation?: number, bursts?: [object], capacity?: integer, collidesWithGround?: boolean, color?: [object], delay?: number, direction?: number[3], drag?: number, friction?: number, gravity?: number[3], groundHeight?: number, intensity?: number, lifetime?: number[2], lit?: boolean, name?: string, orbit?: number, position?: number[3], prewarm?: number, rate?: number, rotation?: number[3], seed?: integer, shape?: "point" \| "sphere" \| "box" \| "disc", shapeSize?: number[3], size?: number[2], sizeOverLife?: [object], softness?: number, speed?: number[2], spin?: number, spiralArms?: integer, spiralTwist?: number, spread?: number, stretch?: number, stretchMode?: "scaled" \| "streak", turbulence?: number, turbulenceFrequency?: number}]
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

Writes a .vfx file in `folder` (default: the Assets root) and imports it as a prefab of particle emitters, from a `preset` (or `effect` contents), optionally placing it in the scene (`place`, at `position`; undoable). Returns the asset, its prefab, the emitter names and import warnings. Edit it later with vfx.edit (small changes) or vfx.set (whole contents); placed copies update. A VFX effect is a stack of GPU particle emitters: `emitters` (each: name, position [x,y,z] m and rotation [x,y,z] degrees relative to the effect, delay (seconds before it starts: timing offset), rate (particles/s), bursts [{time, count, interval, cycles}], capacity, prewarm (seconds pre-simulated so a continuous effect starts steady), lifetime [min,max] s, shape point|sphere|box|disc, shapeSize, direction [x,y,z], spread (cone half-angle, radians), speed [min,max], gravity [x,y,z], drag, turbulence, turbulenceFrequency, attraction, orbit, spiralArms, spiralTwist, armWidth, size [min,max] (half-width m), spin, sizeOverLife [{time, value}] (up to 4), color [{time, color [r,g,b,a] linear}] (up to 4, alpha fades), intensity (HDR glow), brightnessVariation, blend additive|alpha (alpha = smoke/dust, sorted, at most 262144 particles), stretch, stretchMode scaled|streak, collidesWithGround, groundHeight, bounce, friction, softness, lit, seed), plus `duration` (seconds one run lasts; the editor preview loops after it), `background` [r,g,b] and `ground` (preview only). Every key is optional. Presets: fire, smoke, sparks, explosion, magicHit, rain, snow, dust, portal.

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
