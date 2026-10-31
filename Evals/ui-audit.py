#!/usr/bin/env python3
"""Visual and geometric UI review of a real, windowed editor over MCP HTTP.

For each window size x UI scale x theme it launches the editor (EDITOR_WINDOW_SIZE, EDITOR_UI_SCALE,
EDITOR_THEME, a fresh prefs folder and workspace), walks it through the states below (default,
no selection, long names, many entities, long console lines, a long undo title, every Add
Component type, the asset inspector per asset type, menus, context menus, the delete dialog,
play mode, a floating and a squeezed panel, the Activity and Stats panels), checks each
`ui.snapshot` for interactive elements outside the window, overlapping each other, or too small
to hit, and saves a window screenshot of each state to look at.

    swift build --product Editor
    Evals/ui-audit.py --out /tmp/ui-review                                   # default matrix
    Evals/ui-audit.py --sizes 800x600 --scales 1,2 --themes Dark,Light --states default,menus
    Evals/ui-audit.py --backend vulkan --sizes 1280x720 --out /tmp/ui-vk     # compare with Metal

Writes <out>/<config>/<state>.png and <out>/report.json, and prints the issues. The headless
twin of these checks (plus text sizes and button titles) is `UIContext.layoutAudit`, run by
Tests/EditorTests/EditorLayoutTests.swift.
"""
import argparse
import base64
import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import urllib.request
import zlib
import struct

REPOSITORY = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INTERACTIVE = {"button", "checkbox", "radioButton", "toggle", "slider", "textField", "numberField", "dropdown",
               "menuItem", "listItem", "treeItem", "tab", "header", "colorWell"}
SCROLLING = {"scrollView", "list", "tree"}
LONG = "A Very Long Entity Name That Keeps Going To See Where Panels Clip Or Ellipsize It " * 2


class Client:
    def __init__(self, config):
        self.url, self.token = config["url"], config["token"]
        self.session = None
        self.next_id = 0
        self.post("initialize", {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "ui-audit"}})

    def post(self, method, params):
        self.next_id += 1
        body = json.dumps({"jsonrpc": "2.0", "id": self.next_id, "method": method, "params": params}).encode()
        request = urllib.request.Request(self.url, data=body, method="POST")
        request.add_header("Authorization", "Bearer " + self.token)
        request.add_header("Content-Type", "application/json")
        request.add_header("Accept", "application/json, text/event-stream")
        if self.session:
            request.add_header("Mcp-Session-Id", self.session)
        with urllib.request.urlopen(request, timeout=120) as response:
            self.session = response.headers.get("Mcp-Session-Id") or self.session
            text = response.read().decode()
        if text.startswith(("event:", "data:")):
            messages = [json.loads(line[5:]) for line in text.splitlines() if line.startswith("data:") and line[5:].strip()]
            return next((m for m in messages if m.get("id") == self.next_id), messages[-1] if messages else {})
        return json.loads(text)

    def call(self, tool, arguments=None):
        result = self.post("tools/call", {"name": tool, "arguments": arguments or {}}).get("result", {})
        if result.get("isError"):
            text = (result.get("content") or [{}])[0].get("text", "")
            print(f"    {tool} failed: {text[:200]}")
        return result

    def value(self, tool, arguments=None):
        return self.call(tool, arguments).get("structuredContent") or {}


# MARK: Checks on a snapshot


def inside(a, b, slack=1.0):
    return a[0] >= b[0] - slack and a[1] >= b[1] - slack and a[0] + a[2] <= b[0] + b[2] + slack and a[1] + a[3] <= b[1] + b[3] + slack


def overlap(a, b):
    w = min(a[0] + a[2], b[0] + b[2]) - max(a[0], b[0])
    h = min(a[1] + a[3], b[1] + b[3]) - max(a[1], b[1])
    return (w, h) if w > 1 and h > 1 else None


def clip(a, b):
    x0, y0 = max(a[0], b[0]), max(a[1], b[1])
    x1, y1 = min(a[0] + a[2], b[0] + b[2]), min(a[1] + a[3], b[1] + b[3])
    return [x0, y0, x1 - x0, y1 - y0] if x1 > x0 and y1 > y0 else None


def audit(snapshot, min_hit=12):
    """Interactive elements outside the window, overlapping on one layer, or too small to hit."""
    window = [0, 0] + snapshot["window"]
    elements = snapshot["elements"]
    scrollers = {e["path"]: e["rect"] for e in elements if e["role"] in SCROLLING}
    # A dock tab group: its panel's content is clipped to it (the tabs scroll along its bar).
    groups = {e["path"]: e["rect"] for e in elements if e["role"] == "tabGroup"}
    issues = []
    shown = []
    for e in elements:
        if e["role"] not in INTERACTIVE or e.get("offscreen"):
            continue
        # What shows of a scrolled element: its rect clipped by the scroll views around it.
        visible = e["rect"]
        for path, rect in scrollers.items():
            if e["path"].startswith(path + "/"):
                visible = clip(visible, rect)
        if visible:
            shown.append(dict(e, full=e["rect"], rect=visible))
    for e in shown:
        r = e["full"]
        scrolled = any(e["path"].startswith(s + "/") for s in scrollers)
        if not scrolled and not inside(r, window):
            issues.append({"kind": "outsideWindow", "path": e["path"], "rect": r})
        elif not scrolled and e["role"] != "tab" and not e["path"].split("/")[-1].startswith(("tab:", "close:")):
            group = max((p for p in groups if e["path"].startswith(p + "/")), key=len, default=None)
            if group and not inside(r, groups[group]):
                issues.append({"kind": "clippedByPanel", "path": e["path"], "rect": r, "panel": groups[group]})
        if r[2] < min_hit or r[3] < min_hit:  # the whole element, not the part scrolled into view
            issues.append({"kind": "tooSmall", "path": e["path"], "rect": r})
    layer = lambda p: p.split("/")[0] + ("/float" if "dockFloat" in p else "")
    for i, a in enumerate(shown):
        for b in shown[i + 1:]:
            if layer(a["path"]) != layer(b["path"]):
                continue
            if b["path"].startswith(a["path"] + "/") or a["path"].startswith(b["path"] + "/"):
                continue
            o = overlap(a["rect"], b["rect"])
            if not o:
                continue
            # A part drawn inside another part of the same widget (a tab's close button) is fine.
            nested = inside(a["rect"], b["rect"]) or inside(b["rect"], a["rect"])
            if nested and a["path"].rsplit("/", 1)[0] == b["path"].rsplit("/", 1)[0]:
                continue
            issues.append({"kind": "overlap", "path": a["path"], "other": b["path"], "by": o})
    return issues


# MARK: States


def first_entity(client, name):
    found = client.value("entity.find", {"name": name}).get("entities") or []
    return found[0]["id"] if found and isinstance(found[0], dict) else (found[0] if found else None)


def make_assets(client, workspace):
    """A project with a texture, a model, a material and a prefab."""
    project = os.path.join(workspace, "Project")
    client.call("project.new", {"path": project})
    # AI clients may only import from inside the project.
    incoming = os.path.join(project, "Incoming")
    os.makedirs(incoming, exist_ok=True)
    png = os.path.join(incoming, "Checker With A Rather Long File Name For The Asset Browser.png")
    write_png(png, 64, 64)
    model = os.path.join(REPOSITORY, "Tests/EngineTests/Resources/glTF/Box.glb")
    local_model = os.path.join(incoming, "Box.glb")
    shutil.copy(model, local_model)
    client.call("asset.import", {"sources": [png, local_model]})
    client.call("asset.waitForImports", {})
    client.call("asset.newMaterial", {"name": "Red Material"})
    entity = client.value("entity.create", {"template": "cube", "name": "Prefab Source"}).get("entity")
    client.call("prefab.create", {"entity": entity, "name": "Crate Prefab"})
    client.call("asset.waitForImports", {})
    return client.value("asset.list", {"recursive": True}).get("assets", [])


def write_png(path, width, height):
    rows = b"".join(b"\0" + b"".join(bytes((255, 255, 255, 255) if (x // 8 + y // 8) % 2 else (40, 40, 40, 255))
                                     for x in range(width)) for y in range(height))

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b""))


def states(client, workspace):
    """Yields (name, description) after putting the editor into each state."""
    yield "default", "starter scene, Blue Sphere selected"
    client.call("selection.clear")
    yield "no-selection", "nothing selected (inspector empty state), no project (asset browser empty state)"

    entity = client.value("entity.create", {"template": "cube", "name": LONG.strip()}).get("entity")
    client.call("component.setField", {"entity": entity, "path": "Transform.position", "value": [1, 2, 3],
                                       "label": "Set Transform.position on " + LONG.strip()})
    client.call("scene.open", {"path": "no/such/folder/" + "very-long-folder-name/" * 12 + "scene.json", "confirm": True})
    yield "long-names", "an 166-character entity name, a long undo title and a long console line"

    calls = [{"command": "entity.create", "arguments": {"template": "empty", "name": f"Entity {i:03d}"}} for i in range(300)]
    client.call("edit.batch", {"calls": calls, "label": "Create 300 entities"})
    yield "many-entities", "300 more entities in the hierarchy"

    client.call("panel.focus", {"panel": "console"})
    yield "console", "console panel with long lines"
    client.call("panel.focus", {"panel": "activity"})
    yield "activity", "Activity panel"
    client.call("panel.focus", {"panel": "stats"})
    yield "stats", "Stats panel"

    client.call("selection.set", {"entities": [entity], "primary": entity})
    opened = client.value("ui.click", {"label": "Add Component", "role": "button"}).get("opened") or []
    yield "add-component-menu", f"the Add Component menu ({len(opened)} items)"
    client.call("ui.key", {"keys": ["escape"]})
    opened = client.value("ui.click", {"label": "Create", "role": "button"}).get("opened") or []
    yield "create-menu", f"the Create menu ({len(opened)} items)"
    client.call("ui.key", {"keys": ["escape"]})
    types = client.value("component.types").get("components", [])
    holder = client.value("entity.create", {"template": "empty", "name": "Component Holder"}).get("entity")
    for component in (c["name"] for c in types if c.get("addable")):
        client.call("component.add", {"entity": holder, "component": component})
    client.call("selection.set", {"entities": [holder], "primary": holder})
    yield "all-components", "an entity with every addable component in the inspector"
    for _ in range(6):
        client.call("ui.scroll", {"label": "Inspector", "role": "scrollView", "dy": -10})
    yield "all-components-scrolled", "the same, scrolled down"

    client.call("ui.click", {"label": "Component Holder", "role": "treeItem", "button": "right"})
    yield "hierarchy-context-menu", "the hierarchy's context menu"
    client.call("ui.key", {"keys": ["escape"]})
    client.call("ui.click", {"label": "Component Holder", "role": "treeItem"})
    client.call("ui.key", {"keys": ["delete"]})
    yield "delete-dialog", "the delete confirmation dialog"
    client.call("ui.key", {"keys": ["escape"]})

    client.call("play.start", {})
    yield "play", "play mode"
    client.call("play.pause", {})
    yield "play-paused", "paused"
    client.call("play.stop", {})

    client.call("panel.dock", {"panel": "inspector", "floating": [200, 160, 320, 360]})
    yield "floating-inspector", "the inspector in a floating window"
    client.call("layout.reset")
    client.call("panel.dock", {"panel": "hierarchy", "edge": "left", "fraction": 0.08})
    client.call("panel.dock", {"panel": "inspector", "edge": "right", "fraction": 0.1})
    yield "narrow-panels", "hierarchy and inspector squeezed to their minimum width"
    client.call("layout.reset")

    assets = make_assets(client, workspace)
    client.call("panel.focus", {"panel": "assets"})
    yield "assets", "a project with a texture, a model, a material and a prefab"
    client.call("ui.click", {"label": "Box", "role": "listItem", "button": "right"})
    yield "asset-context-menu", "the asset browser's context menu"
    client.call("ui.key", {"keys": ["escape"]})
    seen = set()
    for asset in assets:
        kind = asset.get("importer") or asset.get("kind")
        if kind in seen:
            continue
        seen.add(kind)
        client.call("asset.select", {"asset": asset["id"]})
        yield f"asset-{kind}", f"the asset inspector for a {kind} asset ({os.path.basename(asset['path'])})"


def launch(editor, size, scale, theme, backend, workspace, port):
    os.makedirs(workspace, exist_ok=True)
    env = dict(os.environ, EDITOR_PREFS=os.path.join(workspace, "prefs.json"), EDITOR_WINDOW_SIZE=size,
               EDITOR_UI_SCALE=str(scale), EDITOR_THEME=theme, EDITOR_MCP_PORT=str(port), EDITOR_MCP_HTTP="1")
    env.pop("ENGINE_SCREENSHOT", None)
    if backend:
        env["ENGINE_BACKEND"] = backend
    log = open(os.path.join(workspace, "editor.log"), "w")
    process = subprocess.Popen([editor], cwd=workspace, env=env, stdout=log, stderr=subprocess.STDOUT)
    config = os.path.join(workspace, "mcp.json")
    for _ in range(600):
        if os.path.exists(config) and os.path.getsize(config) > 0:
            time.sleep(0.5)
            return process, Client(json.load(open(config)))
        if process.poll() is not None:
            break
        time.sleep(0.1)
    process.kill()
    raise RuntimeError(f"the editor didn't start (see {workspace}/editor.log)")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--editor", default=os.path.join(REPOSITORY, ".build/debug/Editor"))
    parser.add_argument("--sizes", default="800x600,1280x720,2560x1440,2560x600,800x1400")
    parser.add_argument("--scales", default="1", help="UI scales (EDITOR_UI_SCALE), e.g. 0.85,1,2")
    parser.add_argument("--themes", default="Dark", help="Dark,Light,High Contrast,Game")
    parser.add_argument("--states", default="", help="only these states (comma-separated names)")
    parser.add_argument("--backend", default="")
    parser.add_argument("--port", type=int, default=7391)
    parser.add_argument("--max-size", type=int, default=1600, help="screenshots are scaled to fit this")
    parser.add_argument("--no-screenshots", action="store_true")
    parser.add_argument("--out", default=os.path.join(tempfile.gettempdir(), "ui-audit"))
    args = parser.parse_args()
    wanted = set(filter(None, args.states.split(",")))
    report = []
    for size in args.sizes.split(","):
        for scale in args.scales.split(","):
            for theme in args.themes.split(","):
                name = f"{size}@{scale}x-{theme.replace(' ', '')}" + (f"-{args.backend}" if args.backend else "")
                folder = os.path.join(args.out, name)
                os.makedirs(folder, exist_ok=True)
                workspace = tempfile.mkdtemp(prefix="ui-audit-")
                print(f"== {name}")
                process, client = launch(args.editor, size, scale, theme, args.backend, workspace, args.port)
                try:
                    for state, description in states(client, workspace):
                        if wanted and state not in wanted:
                            continue
                        snapshot = client.value("ui.snapshot", {"all": True})
                        issues = audit(snapshot)
                        entry = {"config": name, "state": state, "description": description,
                                 "window": snapshot.get("window"), "issues": issues}
                        if not args.no_screenshots:
                            shot = client.call("view.screenshot", {"source": "window", "maxSize": args.max_size})
                            for image in (c for c in shot.get("content", []) if c.get("type") == "image"):
                                path = os.path.join(folder, state + ".png")
                                open(path, "wb").write(base64.b64decode(image["data"]))
                                entry["screenshot"] = path
                        report.append(entry)
                        print(f"  {state}: {len(issues)} issue(s)")
                        for issue in issues[:12]:
                            print(f"    {issue}")
                finally:
                    process.send_signal(signal.SIGTERM)
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        process.kill()
                    shutil.rmtree(workspace, ignore_errors=True)
    json.dump(report, open(os.path.join(args.out, "report.json"), "w"), indent=1)
    total = sum(len(e["issues"]) for e in report)
    print(f"{total} issue(s) in {len(report)} state(s); report: {os.path.join(args.out, 'report.json')}")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
