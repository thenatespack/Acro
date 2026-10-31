# Agent evals

Reproducible scenarios for AI agents driving the editor over MCP. Each spec in `scenarios/` has:

- `prompt`: what the user asks the agent.
- `fixtures`: files put in the workspace first (`copy` from the repository, or `generate`).
- `setup`: tool calls that build the starting state (not graded).
- `transcript`: a reference agent run, the tool calls an agent made to solve it (recorded by Claude
  playing the agent; see `results.md`). Steps with `"requires": "window"` (screenshots) run only
  against a windowed editor.
- `checks`: the grading: scene queries (`count`, `entities` with field predicates, `material`,
  `position`, `tool` with expected result fields, `file`, `undo`) and `screenshot` checks graded by eye.

Inside `setup` and `transcript` arguments, `"@<n>.<path>"` is part of step n's result (`"@0.entities.0.id"`,
`"@2.entities.*.id"` for every element) and `"{@<n>.<path>}"` interpolates into a string
(`"asset:{@1.asset.id}"`). `"$<n>.<path>"` and `"{$<n>.<path>}"` stay as they are: that is `edit.batch`'s own reference syntax. A transcript step
can also state what its result must hold, `"expect": {"reason": "stopped"}`.

## Running

```sh
swift test --filter EvalScenarioTests                       # headless: fixtures, setup, transcript, every check but screenshots
WRITE_EVAL_RESULTS=1 swift test --filter EvalScenarioTests  # also writes results/<id>.json

# Screenshots: start the editor in an empty folder (AI clients may only touch files there),
# then replay a scenario against it over HTTP; images go to results/.
mkdir -p /tmp/eval && cd /tmp/eval && EDITOR_PREFS=/tmp/eval/prefs.json swift run --package-path <repo> Editor &
Evals/run-window.py Evals/scenarios/01-level-with-crates.json --mcp /tmp/eval/mcp.json --workspace /tmp/eval
```

Use a fresh folder (and editor) per scenario: a scenario that leaves the game playing or a
project open changes the next one's start.

`Evals/ui-audit.py` is a UI review rather than an agent eval: it starts the editor itself at
each window size, UI zoom, theme and backend you list, walks it through 23 states over MCP,
checks each `ui.snapshot` for controls outside the window, cut off by their panel, overlapping
or too small, and saves window screenshots (`--out`). See docs/EditorUIReview.md.

To evaluate a real agent instead of the reference transcript, give it the `prompt` with the
editor attached as an MCP server (`claude mcp add …`, see the README), run `setup` first, then
run only the `checks`.
