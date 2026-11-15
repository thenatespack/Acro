// The `game` and `build` sections of Project.json (see `Project`). They live with the asset
// side so `Project` can hold them; `GameModuleBuilder` and `GameExporter` act on them.
import Foundation

/// Where a host finds a game module: `Project.json`'s `"game"` object, or the editor's
/// `--game` option. Either a SwiftPM target to build and link (`target`, in the package at
/// `package`), or a prebuilt module (`library`, a `.dylib` / `.so`).
public struct GameModuleSettings: Equatable, Sendable, Codable {
    /// The game's SwiftPM target ("SampleGame").
    public var target: String?
    /// The package folder holding `target`, relative to the project folder; nil searches up
    /// from it (or from the working directory) for a `Package.swift`.
    public var package: String?
    /// A prebuilt module, relative to the project folder; reloading copies it again (after
    /// running `buildCommand`, if any).
    public var library: String?
    /// The build command instead of `swift build --target <target>`, run in the package
    /// folder (`["make", "game"]`).
    public var buildCommand: [String]?
    /// Reload when a source file of `target` (`Sources/<target>/`) changes.
    public var watch: Bool?

    public init(target: String? = nil, package: String? = nil, library: String? = nil, buildCommand: [String]? = nil,
                watch: Bool? = nil) {
        self.target = target
        self.package = package
        self.library = library
        self.buildCommand = buildCommand
        self.watch = watch
    }

    /// From an editor `--game` argument: a path to a module file, or a target name.
    public init(argument: String) {
        let lower = argument.lowercased()
        if lower.hasSuffix(".dylib") || lower.hasSuffix(".so") || lower.hasSuffix(".dll") || argument.contains("/") {
            self.init(library: argument)
        } else {
            self.init(target: argument)
        }
    }
}

/// `Project.json`'s `"build"` object: defaults for Build Game (`game.build`) and `--cook`.
///
/// ```json
/// "build": {"scenes": ["Scenes/Main.scene"], "include": ["Audio/theme.ogg"], "name": "My Game",
///           "output": "Build", "textureFamily": "astc", "textures": "compress", "enginePackage": "../engine"}
/// ```
public struct GameBuildSettings: Equatable, Sendable, Codable {
    /// Scenes to cook, the start scene first (paths relative to the project folder or `Assets/`).
    public var scenes: [String]?
    /// More assets to cook: ones only code refers to (paths relative to `Assets/`, or ids).
    public var include: [String]?
    /// The app's name; default: the project's.
    public var name: String?
    /// The output folder, relative to the project folder (default `Build`); a folder per platform goes inside.
    public var output: String?
    /// Default: ASTC on macOS, BC elsewhere.
    public var textureFamily: TextureFamily?
    public var textures: TextureCookMode?
    /// The engine's package, when it can't be found from the game's package.
    public var enginePackage: String?

    public init(scenes: [String]? = nil, include: [String]? = nil, name: String? = nil, output: String? = nil,
                textureFamily: TextureFamily? = nil, textures: TextureCookMode? = nil, enginePackage: String? = nil) {
        self.scenes = scenes
        self.include = include
        self.name = name
        self.output = output
        self.textureFamily = textureFamily
        self.textures = textures
        self.enginePackage = enginePackage
    }
}
