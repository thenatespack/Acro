import Foundation

// Building a Linux game in Docker (`GameExportOptions.useDocker`, the Export Game dialog's
// "Build in Docker"): the same generated player package, compiled by the Linux Swift toolchain
// in a container, so a Mac (or a Linux machine of the other architecture) can export a Linux
// game for x86_64 or arm64.
//
// - **Image.** `swift:<version>-noble` plus the engine's Linux build dependencies (the CI
//   workflow's list, without the test-only ones), built once per architecture as
//   `sge-export:<version>-<arch>`; later exports reuse it from Docker's cache.
//   `ENGINE_DOCKER_IMAGE` picks another base image.
// - **Paths.** The engine's package (and the game's) are mounted read-only at their own paths,
//   so the generated Package.swift's absolute paths and the game's source symlink resolve as on
//   the host. The player package (`.build/game-export-docker/<Target>`, or
//   `Library/GameExport/<Target>-docker`) is mounted read-write, and its `.build` is a named
//   volume per package and architecture: builds stay incremental and never touch the host's
//   products (bind-mounted builds on macOS are also much slower).
// - **Products.** The container builds, strips (release), copies the executable, the resource
//   bundles and the libraries to bundle (GLFW, per `ldd`) to a staging folder; the host lays out
//   the game folder with the pack and run.sh as for a native Linux export.
// - **Architecture.** `--platform linux/amd64` or `linux/arm64`; the one that isn't the host's
//   runs under emulation (QEMU / Rosetta in Docker Desktop): it works, but the first build takes
//   much longer.

extension GameExporter {
    /// The base image (the CI workflow's toolchain).
    public static var dockerBaseImage: String {
        ProcessInfo.processInfo.environment["ENGINE_DOCKER_IMAGE"].flatMap { $0.isEmpty ? nil : $0 } ?? "swift:6.4-noble"
    }

    /// Packages the engine needs to build on Linux (.github/workflows/linux.yml's, without the test-only ones).
    static let dockerPackages = ["libvulkan-dev", "libglfw3-dev", "zlib1g-dev", "pkg-config", "glslc", "libasound2-dev", "ca-certificates"]

    /// The `docker` executable: PATH, then where Docker Desktop, Homebrew and the static installs
    /// put it (an app started from Finder has a short PATH).
    public static let dockerExecutable: URL? = {
        let fm = FileManager.default
        let path = ProcessInfo.processInfo.environment["PATH"]?.split(separator: ":").map(String.init) ?? []
        let home = NSHomeDirectory()
        let folders = path + ["\(home)/.docker/bin", "/usr/local/bin", "/opt/homebrew/bin",
                              "/Applications/Docker.app/Contents/Resources/bin", "/usr/bin"]
        return folders.lazy.map { URL(fileURLWithPath: $0).appendingPathComponent("docker") }
            .first { fm.isExecutableFile(atPath: $0.path) }
    }()

    /// `docker <arguments>` with its folder on PATH (Docker Desktop's credential helpers live next to it).
    static func docker(_ arguments: [String], in folder: URL) -> GameModuleBuilder.StepResult {
        guard let docker = dockerExecutable else {
            return .init(succeeded: false, output: "Docker isn't installed", seconds: 0)
        }
        let path = ([docker.deletingLastPathComponent().path, "/usr/local/bin", "/opt/homebrew/bin"]
                    + (ProcessInfo.processInfo.environment["PATH"].map { [$0] } ?? ["/usr/bin:/bin"])).joined(separator: ":")
        return GameModuleBuilder.run(["PATH=\(path)", docker.path] + arguments, in: folder)
    }

    var dockerPlatform: String { options.architecture == .x86_64 ? "linux/amd64" : "linux/arm64" }

    /// The export image's tag ("sge-export:swift-6.4-noble-arm64").
    var dockerImageTag: String {
        let base = Self.dockerBaseImage.map { $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" ? $0 : "-" }
        return "sge-export:\(String(base))-\(options.architecture.rawValue)"
    }

    /// The `.build` volume for this player package and architecture.
    var dockerVolume: String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325  // FNV-1a
        for byte in playerPackage.standardizedFileURL.path.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100_0000_01b3
        }
        return "sge-export-\(String(hash, radix: 16))-\(options.architecture.rawValue)"
    }

    /// The script the container runs (its inputs come as environment variables).
    static let dockerScript = #"""
        set -euo pipefail
        cd "$PLAYER"
        swift build $FLAGS --product "$PRODUCT"
        bin=$(swift build $FLAGS --show-bin-path | tail -1)
        rm -rf /out/app && mkdir -p /out/app/lib
        cp "$bin/$PRODUCT" "/out/app/$NAME"
        for b in "$bin"/*.bundle "$bin"/*.resources; do
            if [ -e "$b" ]; then cp -R "$b" /out/app/; fi
        done
        if [ "$STRIP" = 1 ]; then strip -g "/out/app/$NAME"; fi
        ldd "/out/app/$NAME" | awk '$2 == "=>" && $1 ~ /^libglfw\.so/ {print $1, $3}' | while read -r name path; do
            cp -L "$path" "/out/app/lib/$name"
        done
        chown -R "$HOST_IDS" /out/app 2>/dev/null || true
        if [ -e Package.resolved ]; then chown "$HOST_IDS" Package.resolved 2>/dev/null || true; fi
        """#

    /// Builds the player in a Linux container; the products land in `staging/docker`.
    func buildInDocker(staging: URL, progress: (@Sendable (String) -> Void)?) throws -> BuiltPlayer {
        let start = Date()
        let fm = FileManager.default
        let info = Self.docker(["info", "--format", "{{.ServerVersion}}"], in: staging)
        guard info.succeeded else {
            throw GameExportError.docker("Docker isn't running (start Docker Desktop or the docker service): "
                                         + (info.output.split(separator: "\n").first.map(String.init) ?? ""))
        }

        // The image: the toolchain plus the engine's build dependencies (cached by Docker after the first time).
        progress?("Docker: preparing \(dockerImageTag) (\(dockerPlatform); the first time downloads the Swift toolchain)")
        let context = staging.appendingPathComponent("docker-image", isDirectory: true)
        try fm.createDirectory(at: context, withIntermediateDirectories: true)
        let dockerfile = """
            FROM \(Self.dockerBaseImage)
            RUN apt-get update && apt-get install -y --no-install-recommends \(Self.dockerPackages.joined(separator: " ")) \
             && rm -rf /var/lib/apt/lists/*

            """
        try Data(dockerfile.utf8).write(to: context.appendingPathComponent("Dockerfile"))
        let image = Self.docker(["build", "--platform", dockerPlatform, "-t", dockerImageTag, context.path], in: staging)
        guard image.succeeded else { throw GameExportError.buildFailed("docker build failed:\n\(image.output)") }

        // The build.
        let out = staging.appendingPathComponent("docker", isDirectory: true)
        try fm.createDirectory(at: out, withIntermediateDirectories: true)
        let player = playerPackage.standardizedFileURL.path
        let engine = options.enginePackage.standardizedFileURL.path
        var mounts = ["-v", "\(engine):\(engine):ro"]
        if !options.sceneOnly {
            let game = options.gamePackage.standardizedFileURL.path
            if game != engine { mounts += ["-v", "\(game):\(game):ro"] }
        }
        mounts += ["-v", "\(player):\(player)", "-v", "\(dockerVolume):\(player)/.build", "-v", "\(out.path):/out"]
        let environment = ["PLAYER": player, "PRODUCT": playerTarget, "NAME": options.name, "FLAGS": buildFlags.joined(separator: " "),
                           "STRIP": options.configuration == .release ? "1" : "0", "HOST_IDS": "\(getuid()):\(getgid())"]
        let command = ["run", "--rm", "--platform", dockerPlatform] + mounts
            + environment.sorted { $0.key < $1.key }.flatMap { ["-e", "\($0.key)=\($0.value)"] }
            + [dockerImageTag, "bash", "-c", Self.dockerScript]
        progress?("Docker: building \(options.gameTarget) with Engine (\(options.configuration.rawValue), \(options.architecture.rawValue)) "
                  + "in \(Self.dockerBaseImage); the first build compiles Engine: minutes, more under emulation")
        let build = Self.docker(command, in: staging)
        guard build.succeeded else { throw GameExportError.buildFailed(build.output) }
        progress?(String(format: "Built in Docker in %.1f s", Date().timeIntervalSince(start)))

        let app = out.appendingPathComponent("app", isDirectory: true)
        let executable = app.appendingPathComponent(options.name)
        guard fm.fileExists(atPath: executable.path) else { throw GameExportError.missingProduct(executable.path) }
        let bundles = ((try? fm.contentsOfDirectory(atPath: app.path)) ?? [])
            .filter { $0.hasSuffix(".bundle") || $0.hasSuffix(".resources") }.sorted().map { app.appendingPathComponent($0) }
        return BuiltPlayer(executable: executable, bundles: bundles, libraries: app.appendingPathComponent("lib", isDirectory: true),
                           seconds: Date().timeIntervalSince(start))
    }
}
