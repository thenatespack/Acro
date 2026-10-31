# Editor MCP tool reference

Generated from the editor's command registry by `swift run Editor --mcp-tool-docs > docs/MCPTools.md`;
`swift test --filter ToolReferenceTests` fails when it is out of date. Every editor command is a tool
named by its id (see README › Editor › AI control). 88 tools.

Hints: **read-only** (changes nothing), **undoable** (one undo step, labeled "AI: …" when an MCP client
made it), **destructive** (can lose work undo can't bring back; needs `confirm: true`), **idempotent**
(running it again changes nothing more), **deferred** (answers after a frame or more). Types: entity ids
are 32-hex strings, assets `asset:<id>[#object]` references, vectors `[x, y, z]` number arrays, `?` marks
optional arguments.

| Namespace | Tools |
|---|---|
| `activity` | [`activity.clear`](#activityclear), [`activity.list`](#activitylist), [`activity.revert`](#activityrevert) |
| `ai` | [`ai.settings`](#aisettings) |
| `asset` | [`asset.applySettings`](#assetapplysettings), [`asset.assign`](#assetassign), [`asset.delete`](#assetdelete), [`asset.extractMaterials`](#assetextractmaterials), [`asset.get`](#assetget), [`asset.import`](#assetimport), [`asset.instantiate`](#assetinstantiate), [`asset.list`](#assetlist), [`asset.move`](#assetmove), [`asset.newFolder`](#assetnewfolder), [`asset.newMaterial`](#assetnewmaterial), [`asset.reimport`](#assetreimport), [`asset.rename`](#assetrename), [`asset.select`](#assetselect), [`asset.waitForImports`](#assetwaitforimports) |
| `component` | [`component.add`](#componentadd), [`component.remove`](#componentremove), [`component.setField`](#componentsetfield), [`component.types`](#componenttypes) |
| `diagnostics` | [`diagnostics.get`](#diagnosticsget) |
| `edit` | [`edit.batch`](#editbatch), [`edit.beginBatch`](#editbeginbatch), [`edit.endBatch`](#editendbatch), [`edit.redo`](#editredo), [`edit.undo`](#editundo) |
| `entity` | [`entity.create`](#entitycreate), [`entity.delete`](#entitydelete), [`entity.duplicate`](#entityduplicate), [`entity.find`](#entityfind), [`entity.get`](#entityget), [`entity.rename`](#entityrename), [`entity.reparent`](#entityreparent) |
| `input` | [`input.clear`](#inputclear), [`input.inject`](#inputinject), [`input.state`](#inputstate) |
| `layout` | [`layout.reset`](#layoutreset) |
| `log` | [`log.clear`](#logclear), [`log.read`](#logread) |
| `material` | [`material.get`](#materialget), [`material.set`](#materialset) |
| `panel` | [`panel.close`](#panelclose), [`panel.dock`](#paneldock), [`panel.focus`](#panelfocus), [`panel.list`](#panellist), [`panel.open`](#panelopen) |
| `play` | [`play.pause`](#playpause), [`play.setTimeScale`](#playsettimescale), [`play.start`](#playstart), [`play.state`](#playstate), [`play.step`](#playstep), [`play.stop`](#playstop), [`play.toggle`](#playtoggle) |
| `prefab` | [`prefab.apply`](#prefabapply), [`prefab.create`](#prefabcreate), [`prefab.overrides`](#prefaboverrides), [`prefab.revert`](#prefabrevert), [`prefab.unpack`](#prefabunpack) |
| `project` | [`project.close`](#projectclose), [`project.new`](#projectnew), [`project.open`](#projectopen) |
| `scene` | [`scene.hierarchy`](#scenehierarchy), [`scene.new`](#scenenew), [`scene.open`](#sceneopen), [`scene.raycast`](#sceneraycast), [`scene.save`](#scenesave), [`scene.saveAs`](#scenesaveas) |
| `selection` | [`selection.clear`](#selectionclear), [`selection.get`](#selectionget), [`selection.set`](#selectionset) |
| `stats` | [`stats.get`](#statsget) |
| `tool` | [`tool.set`](#toolset) |
| `transform` | [`transform.set`](#transformset) |
| `ui` | [`ui.click`](#uiclick), [`ui.drag`](#uidrag), [`ui.find`](#uifind), [`ui.hover`](#uihover), [`ui.key`](#uikey), [`ui.scroll`](#uiscroll), [`ui.snapshot`](#uisnapshot), [`ui.type`](#uitype) |
| `view` | [`view.frameSelection`](#viewframeselection), [`view.gameCamera`](#viewgamecamera), [`view.pick`](#viewpick), [`view.screenshot`](#viewscreenshot) |

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

- `asset`: asset id — An asset id: 32 hex digits (see the editor://assets resource).
- `confirm`: true — Must be true: this tool can lose work that undo can't bring back.
- `settings`: any — Any JSON value.

### `asset.assign`

**Assign Asset** · _undoable_, _idempotent_

Sets the entity's MeshRenderer mesh or material to the asset (an entity without a MeshRenderer gets one for a mesh). Undoable (one step; edit.undo reverts it).

Arguments:

- `asset`: asset reference — An asset: "asset:<id>" for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
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

- `asset`: asset id — An asset id: 32 hex digits (see the editor://assets resource).

Result:

- `materials`: [asset id]

### `asset.get`

**Get Asset** · _read-only_, _idempotent_

One asset's metadata: id, path, importer, kind, load state, import error, objects, its effective import settings and the importer's defaults (as asset.applySettings takes them), and its revision.

Arguments:

- `asset?`: asset reference — An asset: "asset:<id>" for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
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

- `asset`: asset reference — An asset: "asset:<id>" for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
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
- `material?`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset reference, filter?: "linear" \| "nearest", metallic?: number, metallicRoughnessTexture?: asset reference, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset reference, occlusionStrength?: number, occlusionTexture?: asset reference, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset reference, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2]}
- `name?`: string

Result:

- `asset`: asset id — An asset id: 32 hex digits (see the editor://assets resource).
- `path`: string

### `asset.reimport`

**Reimport** · _idempotent_

Imports the asset again now, even if it is up to date (prefab instances in the scene follow). Returns its metadata (see asset.get).

Arguments:

- `asset?`: asset reference — An asset: "asset:<id>" for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
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

- `asset?`: asset reference — An asset: "asset:<id>" for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `path?`: string

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

Sets one field of a component by reflection path (what the inspector edits): `component` "Transform" with `path` "position", or just `path` "Transform.position.x" (a trailing .x/.y/.z/.w sets one element of a vector). With `space` "world", Transform's position, rotation and scale are given in world space. Undoable (one step; edit.undo reverts it).

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

Runs `calls` (each {command, arguments}) in order as ONE undo step named `label`. If a call fails, everything the batch did is undone, the selection is restored, and the error names the call. A string "$<n>.<path>" in arguments is replaced by part of call n's result ("$0.entity" is the entity call 0 created). File operations and screenshots aren't rolled back or can't be batched. Undoable (one step; edit.undo reverts it).

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
- `template`: "empty" \| "cube" \| "sphere" \| "plane"

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
- `keys`: [string (73 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
- `time`: number
- `timeScale`: number

### `input.inject`

**Inject Input**

Plays input into the game (play mode) over game time, after what is already scheduled (`replace`: instead). Each step does one thing: `key` (or `keys` together) / `button` tapped for one frame, held `duration` seconds, or pressed (`down`: true) / released (false); `mouseTo` [x, y] in game-view points; `mouseBy`; `scroll`; `text`. The next step starts `wait` seconds later (default the step's `duration`; 0 overlaps them). Game systems read it from the session's gameInput, never the editor's UI. Paused, it waits: play.step runs it frame by frame. Example: [{"key": "w", "duration": 2}, {"key": "space"}].

Arguments:

- `replace?`: boolean
- `steps`: [{button?: "left" \| "right" \| "middle", down?: boolean, duration?: number, key?: string (73 cases), keys?: [string (73 cases)], mouseBy?: number[2], mouseTo?: number[2], scroll?: number[2], text?: string, wait?: number}]

Result:

- `seconds`: number
- `state`: {buttons: ["left" \| "right" \| "middle"], frame: integer, gameCamera: boolean, inputPending: integer, inputSeconds: number, keys: [string (73 cases)], paused: boolean, physics: boolean, playing: boolean, time: number, timeScale: number}

### `input.state`

**Input State** · _read-only_, _idempotent_

Returns the game's input as of the last game frame: keys and buttons down, the cursor, keys held by injection and events still scheduled.

Arguments: none.

Result:

- `buttons`: ["left" \| "right" \| "middle"]
- `injectedKeys`: [string (73 cases)]
- `keys`: [string (73 cases)]
- `mouse`: number[2] — [x, y]
- `mouseDelta`: number[2] — [x, y]
- `pending`: integer

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

- `asset`: asset reference — An asset: "asset:<id>" for a file, "asset:<id>#<object>" for one object in it (see editor://assets).

Result:

- `editable`: boolean
- `material`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset reference, filter?: "linear" \| "nearest", metallic?: number, metallicRoughnessTexture?: asset reference, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset reference, occlusionStrength?: number, occlusionTexture?: asset reference, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset reference, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2]}

### `material.set`

**Edit Material** · _undoable_, _idempotent_

Writes `material` to the .material file and reimports it (the viewport updates). Undoable (one step; edit.undo reverts it).

Arguments:

- `asset`: asset id — An asset id: 32 hex digits (see the editor://assets resource).
- `label?`: string
- `material`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset reference, filter?: "linear" \| "nearest", metallic?: number, metallicRoughnessTexture?: asset reference, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset reference, occlusionStrength?: number, occlusionTexture?: asset reference, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset reference, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2]}
- `previous?`: {addressMode?: "repeat" \| "clampToEdge" \| "mirrorRepeat", alphaCutoff?: number, alphaMode?: "opaque" \| "mask" \| "blend", baseColor?: number[4], checker?: boolean, doubleSided?: boolean, emissive?: number, emissiveColor?: number[3], emissiveStrength?: number, emissiveTexture?: asset reference, filter?: "linear" \| "nearest", metallic?: number, metallicRoughnessTexture?: asset reference, mipFilter?: "linear" \| "nearest" \| "none", normalScale?: number, normalTexture?: asset reference, occlusionStrength?: number, occlusionTexture?: asset reference, roughness?: number, shading?: "pbr" \| "blinnPhong", shininess?: number, specular?: number, texture?: asset reference, uvOffset?: number[2], uvRotation?: number, uvScale?: number[2]}
- `transient?`: boolean

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
- `keys`: [string (73 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
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
- `keys`: [string (73 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
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
- `keys`: [string (73 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
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
- `keys`: [string (73 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
- `time`: number
- `timeScale`: number

### `play.step`

**Step**

Pauses play mode and runs `frames` game frames now (default 1), each `dt` seconds (default 1/60), with the input scheduled for them. Deterministic: the same scene, input and steps give the same result.

Arguments:

- `dt?`: number
- `frames?`: integer

Result:

- `buttons`: ["left" \| "right" \| "middle"]
- `frame`: integer
- `gameCamera`: boolean
- `inputPending`: integer
- `inputSeconds`: number
- `keys`: [string (73 cases)]
- `paused`: boolean
- `physics`: boolean
- `playing`: boolean
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
- `prefab`: asset reference — An asset: "asset:<id>" for a file, "asset:<id>#<object>" for one object in it (see editor://assets).

### `prefab.overrides`

**Prefab Overrides** · _read-only_, _idempotent_

The prefab instance an entity belongs to: its prefab, root, overrides (changed fields, added and removed components, removed entities) and added children, and whether prefab.apply can write the prefab.

Arguments:

- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `added`: [entity id]
- `canApply`: boolean
- `overrides`: [{component?: string, entity?: entity id, kind: "field" \| "addedComponent" \| "removedComponent" \| "removedEntity", path?: string, prefabEntity: string, value?: any}]
- `prefab`: asset reference — An asset: "asset:<id>" for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
- `prefabEntity?`: string
- `root`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

### `prefab.revert`

**Revert to Prefab** · _undoable_

Puts an instance back to its prefab: one component of one entity (added, removed or changed), or with no component the whole instance (every override goes, added children are deleted). One undo step. Undoable (one step; edit.undo reverts it).

Arguments:

- `component?`: string
- `entity?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

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

**New Project**

Creates a project (Project.json, Assets/, Library/) at `path` and opens it. Returns its root folder.

Arguments:

- `path`: string

Result:

- `path`: string

### `project.open`

**Open Project** · _idempotent_

Opens the project at `path`, scans its assets and imports what changed (in the background). The scene stays open. Returns the project's root folder.

Arguments:

- `path`: string

Result:

- `path`: string

## scene

### `scene.hierarchy`

**Hierarchy** · _read-only_, _idempotent_

Returns the entity tree as the hierarchy panel shows it (roots in order, children in sibling order): each node's id, name, component names and children. `root` limits it to one subtree, `depth` to that many levels.

Arguments:

- `depth?`: integer
- `root?`: entity id — An entity id: 32 lowercase hex digits (see the editor://scene resource).

Result:

- `entities`: [{children: [object], components: [string], id: entity id, more?: integer, name: string}]

### `scene.new`

**New Scene** · _destructive_

Replaces the open scene with the starter scene. Clears the undo history; unsaved changes are lost. Not while playing. Destructive: pass confirm: true.

Arguments:

- `confirm`: true — Must be true: this tool can lose work that undo can't bring back.

### `scene.open`

**Open Scene** · _destructive_, _idempotent_

Replaces the open scene with the scene file at `path` and clears the undo history. Not while playing. Destructive: pass confirm: true.

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

### `scene.save`

**Save Scene** · _destructive_, _idempotent_

Saves the scene to its file, or to `path` when it has never been saved. Not while playing. Destructive: pass confirm: true.

Arguments:

- `confirm`: true — Must be true: this tool can lose work that undo can't bring back.
- `path?`: string

Result:

- `path`: string

### `scene.saveAs`

**Save Scene As** · _destructive_, _idempotent_

Saves the scene to `path`, which becomes its file. Not while playing. Destructive: pass confirm: true.

Arguments:

- `confirm`: true — Must be true: this tool can lose work that undo can't bring back.
- `path`: string

Result:

- `path`: string

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

## transform

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

## view

### `view.frameSelection`

**Frame Selection** · _idempotent_

Moves the viewport camera to frame the selected entities, or `entities` (without selecting them). Needs the editor window.

Arguments:

- `entities?`: [entity id]

### `view.gameCamera`

**Game View**

Whether the viewport shows the scene's Camera entity while playing (and forwards the keyboard and the mouse over it to the game) or the editor camera. On by default.

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

- `asset?`: asset reference — An asset: "asset:<id>" for a file, "asset:<id>#<object>" for one object in it (see editor://assets).
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
