#!/usr/bin/env python3
"""Runs an eval scenario against a running editor (with a window) over MCP HTTP, for the steps
and checks that need one (screenshots). The headless run and the scene checks are
`swift test --filter EvalScenarioTests`.

    mkdir -p /tmp/eval && cd /tmp/eval && EDITOR_PREFS=/tmp/eval/prefs.json swift run --package-path <repo> Editor &
    Evals/run-window.py Evals/scenarios/01-level-with-crates.json --mcp /tmp/eval/mcp.json --workspace /tmp/eval --out Evals/results

The editor confines AI clients to the folder it was started in (or the project), so start it in
an empty folder and pass that as --workspace: fixtures are put there. Screenshots are written to
<out>/<id>-<n>.png, and the step log to <out>/<id>-window.json.
"""
import argparse
import base64
import json
import os
import shutil
import sys
import urllib.request

REPOSITORY = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class Client:
    def __init__(self, config):
        self.url, self.token = config["url"], config["token"]
        self.session = None
        self.next_id = 0
        self.post("initialize", {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "eval-agent"}})

    def post(self, method, params):
        self.next_id += 1
        body = json.dumps({"jsonrpc": "2.0", "id": self.next_id, "method": method, "params": params}).encode()
        request = urllib.request.Request(self.url, data=body, method="POST")
        request.add_header("Authorization", "Bearer " + self.token)
        request.add_header("Content-Type", "application/json")
        request.add_header("Accept", "application/json, text/event-stream")
        if self.session:
            request.add_header("Mcp-Session-Id", self.session)
        with urllib.request.urlopen(request, timeout=300) as response:
            self.session = response.headers.get("Mcp-Session-Id") or self.session
            text = response.read().decode()
        if text.startswith(("event:", "data:")):
            messages = [json.loads(line[5:]) for line in text.splitlines() if line.startswith("data:") and line[5:].strip()]
            return next((m for m in messages if m.get("id") == self.next_id), messages[-1] if messages else {})
        return json.loads(text)

    def call(self, tool, arguments):
        result = self.post("tools/call", {"name": tool, "arguments": arguments}).get("result", {})
        return result


def lookup(path, results):
    parts = path.split(".")
    value = results[int(parts[0])]
    for key in parts[1:]:
        if key == "*":
            return [v for v in value]  # only used as the last-but-one segment in the specs
        value = value[int(key)] if isinstance(value, list) else (value or {}).get(key)
    return value


def lookup_all(path, results):
    head, _, tail = path.partition(".*.")
    if not tail:
        return lookup(path, results)
    return [item.get(tail) for item in lookup(head, results)]


def substitute(value, results):
    if isinstance(value, str):
        if value.startswith("@") and value[1:2].isdigit():
            return lookup_all(value[1:], results)
        while "{@" in value:
            start = value.index("{@")
            end = value.index("}", start)
            value = value[:start] + str(lookup_all(value[start + 2:end], results)) + value[end + 1:]
        return value
    if isinstance(value, list):
        return [substitute(v, results) for v in value]
    if isinstance(value, dict):
        return {k: substitute(v, results) for k, v in value.items()}
    return value


def write_crate_texture(path):
    """The same 64x64 planks the Swift harness generates."""
    import struct
    import zlib
    rows = b""
    for y in range(64):
        row = b"\x00"
        for x in range(64):
            seam = y % 16 == 0 or x in (0, 63)
            grain = (x * 7 + y * 3) % 23
            row += bytes([60, 38, 20, 255] if seam else [150 + grain, 105 + grain // 2, 55, 255])
        rows += row

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 64, 64, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b"")
    open(path, "wb").write(png)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("scenario")
    parser.add_argument("--mcp", required=True)
    parser.add_argument("--workspace", required=True)
    parser.add_argument("--out", default=os.path.join(REPOSITORY, "Evals", "results"))
    args = parser.parse_args()
    spec = json.load(open(args.scenario))
    os.makedirs(args.out, exist_ok=True)
    for fixture in spec.get("fixtures", []):
        target = os.path.join(args.workspace, fixture["to"])
        if "copy" in fixture:
            shutil.copy(os.path.join(REPOSITORY, fixture["copy"]), target)
        elif fixture.get("generate") == "crate-texture":
            write_crate_texture(target)
    client = Client(json.load(open(args.mcp)))
    log = []
    shots = 0
    for phase in ("setup", "transcript"):
        results = []
        for n, step in enumerate(spec.get(phase, [])):
            arguments = substitute(step.get("arguments", {}), results)
            result = client.call(step["tool"], arguments)
            structured = result.get("structuredContent")
            results.append(structured)
            texts = [c.get("text", "") for c in result.get("content", []) if c.get("type") == "text"]
            for image in (c for c in result.get("content", []) if c.get("type") == "image"):
                path = os.path.join(args.out, f"{spec['id']}-{shots}.png")
                open(path, "wb").write(base64.b64decode(image["data"]))
                shots += 1
                print(f"  screenshot -> {path}")
            outcome = "error: " + " ".join(texts)[:300] if result.get("isError") else "ok"
            log.append({"phase": phase, "step": n, "tool": step["tool"], "outcome": outcome})
            print(f"{phase} {n} {step['tool']}: {outcome}")
    for check in spec.get("checks", []):
        if check["kind"] == "screenshot":
            result = client.call("view.screenshot", dict(check.get("arguments", {}), maxSize=800))
            for image in (c for c in result.get("content", []) if c.get("type") == "image"):
                path = os.path.join(args.out, f"{spec['id']}-check-{shots}.png")
                open(path, "wb").write(base64.b64decode(image["data"]))
                shots += 1
                print(f"check '{check['description']}': grade by eye -> {path}")
    json.dump({"id": spec["id"], "mode": "window", "steps": log}, open(os.path.join(args.out, f"{spec['id']}-window.json"), "w"), indent=2)
    return 1 if any(entry["outcome"] != "ok" for entry in log) else 0


if __name__ == "__main__":
    sys.exit(main())
