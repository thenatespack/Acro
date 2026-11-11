# Security policy

## Supported versions

Acro is below 1.0, and only the latest release on `main` receives security fixes.

| Version | Supported |
|---|---|
| Latest 0.x | Yes |
| Older versions | No |

## Reporting a vulnerability

Don't report security problems in public issues, discussions, or pull requests.

Report them privately through GitHub: on the repository's **Security** tab, choose **Report a vulnerability**, or go directly to [the new advisory form](https://github.com/thenatespack/Acro/security/advisories/new).

Please include:

- What the problem is and what an attacker could do with it
- Steps to reproduce, or a proof of concept
- The affected version or commit, platform, and configuration
- Any fix or mitigation you have in mind

You should get an acknowledgment within a week. Once the problem is confirmed, we'll work on a fix and agree with you on when to publish. We'll credit you in the advisory unless you'd rather stay anonymous.

## Scope

These parts of Acro handle untrusted input or run code, so they matter most:

- **Editor MCP server:** `Editor --mcp` serves editor commands to AI clients over stdio and HTTP. Issues include commands that escape the project folder, destructive commands running without `confirm: true`, or the HTTP endpoint being reachable or controllable from unintended origins.
- **Game modules:** the editor and `GameRunner` build and load Swift game modules as native code. Loading a module runs its code with your permissions by design, so only open projects you trust. Problems in how modules are located, built, or loaded are in scope.
- **Asset import:** parsers for glTF/GLB, OBJ, images, audio, and Acro's JSON asset formats (scenes, prefabs, builder files). Crashes or memory-safety problems from malformed files are in scope.
- **Networking:** the engine's network transport and snapshot protocol.
- **Packaging and export:** cooking, `--build-game`, and Docker builds.

Out of scope: problems that need an attacker to already control your machine or your project's source code, and vulnerabilities in third-party dependencies that have no Acro-specific impact (report those upstream).
