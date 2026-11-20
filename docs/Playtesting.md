# Playtesting with an agent

An AI agent can play your game over MCP: start it, press input actions, step frames, look at it,
read the world and check what should be true. A session can be saved as a playtest file and
replayed later, in the editor or headless from the command line, with its checks run again. Commit
the files and CI tells you when a change breaks a scene.

The SampleGame project has one: [`Projects/SampleGame/Playtests/PlayerMoves.playtest.json`](../Projects/SampleGame/Playtests/PlayerMoves.playtest.json)
walks the Player (a cube running `Scripts/Player.vscript`) with the keyboard and the gamepad and
checks where it ends up.

## In the editor

Connect an agent to the editor (README › AI control), open the project and the scene, then:

```
playtest.start {name: "walk right"}                 // Play, paused at frame 0, recording
play.step {frames: 1}                                // visual scripts start: their actions are known
input.actions                                        // [{name: "jump", sources: ["key.space", "pad.south"]}, …]
input.action {action: "right", duration: 1}          // hold the action's key for a second of game time
input.action {action: "jump"}                        // tap it (down for one frame)
play.step {frames: 90}                               // run 90 frames at 1/60 s: deterministic
view.screenshot {source: "game"}                     // look at it
entity.get {entity: "…"}                             // read it
playtest.assert {entity: "Player", field: "position.x", min: 1.9, max: 2.1}
playtest.result                                      // every check so far, and whether all passed
playtest.save {path: "Playtests/WalkRight"}          // Playtests/WalkRight.playtest.json in the project
playtest.stop                                        // stop playing; the scene is restored
```

Replay a saved playtest with `playtest.run {path: "Playtests/WalkRight.playtest.json"}`. It opens
the playtest's scene, plays it from the start, runs the steps and returns the result.

### Input

- `input.action {action, duration?, down?, value?}` presses an input action by name, starting
  next frame. Without `duration` or `down` it taps the action for one frame. With `duration` it
  holds it that many seconds. `down: true` presses it until `down: false`. `value` (-1 to 1) sets
  an analog source, such as a stick or trigger in `axis.leftStickX+`. The actions come from the
  scene's visual scripts (their graphs' `actions`) and from `playtest.start {actions}`.
- `input.gamepad {button | axis + value, duration?, down?}` drives a virtual gamepad. Game code
  sees it in `Input.gamepads` as "Playtest Pad".
- `input.inject {steps}` plays raw keys, mouse and text, as before.
- `input.clear` drops all scheduled input and releases everything held.

### Assertions

`playtest.assert` checks one thing now and records a pass or a failure. A failing check doesn't
make the tool call fail: read `passed` in its result, or call `playtest.result` at the end.

| What to check | Example |
|---|---|
| An entity exists (or not) | `{entity: "Player"}`, `{entity: "Coin 3", exists: false}` |
| A world position, rotation or scale | `{entity: "Player", field: "position", near: [2, 0.3, 2], tolerance: 0.1}` |
| One coordinate in a range | `{entity: "Player", field: "position.y", min: 0}` |
| A component field | `{entity: "Door", component: "Collider", field: "isTrigger", equals: true}` |
| A visual script variable | `{entity: "Player", variable: "jumps", equals: 1}` |
| How many entities | `{count: {component: "Enemy"}, equals: 0}`, `{count: {name: "Coin"}, max: 2}` |

`entity` is a name (exact first, then any case), a path of names (`"Level/Door"`) or an id. Add
`label` to name the check in results. Numbers compare within `tolerance`: 1e-4 for `equals`, 0.01
for `near`.

### Recording

From `playtest.start` until `playtest.stop`, these calls are recorded with the frames between
them: `input.action`, `input.gamepad`, `input.inject`, `input.clear`, `play.step` and
`playtest.assert`. Frames that ran in real time (unpaused) are recorded at the fixed time step. For
a recording that replays exactly, keep play paused and use `play.step`. Edits to the live world,
such as `component.setField`, aren't recorded.

## Headless

GameRunner plays a scene without a window, with the same play systems as the editor: the game
module's systems, visual scripts, physics, behavior trees and timelines. Frames run at a fixed dt,
so a run gives the same result on every machine.

```sh
# Replay one playtest, or every *.playtest.json in a folder. Exit code 0: all passed, 1: one failed, 2: one couldn't run.
swift run GameRunner SampleGame --playtest Projects/SampleGame/Playtests
swift run GameRunner SampleGame --playtest walk.playtest.json --report playtest-report.json

# No game module (the scene needs only visual scripts and built-in components):
swift run GameRunner none --playtest Projects/SampleGame/Playtests

# Let an agent play a scene headless over MCP (stdio):
claude mcp add sample-headless -- swift run GameRunner SampleGame Projects/SampleGame/Assets/Scenes/Main.scene --mcp
```

The playtest's `scene` is resolved next to the file or in the project above it. A scene given on
the command line takes precedence. The headless MCP server has the editor's tools under the same
names: `play.state`, `play.step`, `input.*`, `scene.hierarchy`, `entity.find`, `entity.get` and
`playtest.*`. Nothing renders, so there are no screenshots there.

In CI, run each project's playtests after building:

```sh
swift build --product GameRunner
.build/debug/GameRunner SampleGame --playtest Projects/SampleGame/Playtests --report playtest-report.json
```

## The file

A playtest is JSON. Every key except `steps` is optional:

```json
{
  "format": "Acro.Playtest", "version": 1,
  "name": "Player walks right and jumps",
  "scene": "Scenes/Main.scene",
  "dt": 0.016666666666666666,
  "actions": {"dash": ["key.leftShift", "pad.east"]},
  "steps": [
    {"frames": 1},
    {"action": "right", "duration": 1},
    {"action": "jump"},
    {"gamepad": {"axis": "leftStickX", "value": -0.5}, "duration": 0.5},
    {"input": [{"key": "e"}]},
    {"frames": 90},
    {"assert": {"label": "walked right", "entity": "Player", "field": "position.x", "min": 1.5}},
    {"note": "Comments are steps too."}
  ]
}
```

Steps run in order. `frames` runs that many game frames (with its own `dt` if it has one), and
every other step happens between frames. `action` and `gamepad` input starts on the next frame.
`input` is scheduled like `input.inject`: after raw input that is already scheduled, or instead of
it with `replace: true`. You can write playtests by hand as well as record them. Recordings are
easy to edit, for example to loosen a tolerance or add an assertion.

## Tips

- Step one frame before you press actions: visual scripts declare their actions when they start.
- Give the entities you check unique names, or name them by path (`"Level/Door"`): a name
  matches the first entity that has it.
- Check outcomes with some tolerance (`min` / `max`, `near`) rather than exact floats, so small
  changes to movement code don't break every playtest.
- Look at the game with `view.screenshot {source: "game"}` while you write a playtest, then keep
  the assertions that describe what you saw.
