import Engine

/// The editor's icons: which `VectorIcon` (built-in Lucide names) stands for each component
/// type, entity, asset kind, toolbar action, panel and log level, plus the icons game modules
/// register for their components (`GameModule.icon(_:for:)`).
///
/// Every component type the engine and the editor register has its own icon; unknown ones
/// (a game's without an icon, unresolved data) get `fallbackComponent`. An entity is shown by
/// its main component (`entityIcon`): camera, light, particles, audio, mesh, sprite, physics…,
/// a game component with an icon, else a group (with children) or an empty.
@MainActor
public enum EditorIcons {
    /// Built-in icon names by component name.
    public static let componentIconNames: [String: String] = [
        Transform.componentName: "move-3d",
        GlobalTransform.componentName: "move-3d",
        Name.componentName: "tag",
        Camera.componentName: "video",
        DirectionalLight.componentName: "sun",
        PointLight.componentName: "lightbulb",
        SpotLight.componentName: "flashlight",
        SceneEnvironment.componentName: "globe",
        PostProcessSettings.componentName: "aperture",
        MeshRenderer.componentName: "box",
        Collider.componentName: "square-dashed",
        RigidBody.componentName: "weight",
        Joint.componentName: "link",
        CharacterController.componentName: "person-standing",
        RigidBody2D.componentName: "weight",
        Collider2D.componentName: "square-dashed",
        Joint2D.componentName: "link",
        AudioListener.componentName: "ear",
        AudioEmitter.componentName: "volume-2",
        ParticleEmitter.componentName: "sparkles",
        Sprite.componentName: "image",
        SpriteAnimator.componentName: "images",
        Animator.componentName: "film",
        Skin.componentName: "bone",
        Saveable.componentName: "archive",
        Replicated.componentName: "network",
        Unpickable.componentName: "mouse-pointer-ban",
        PrefabInstance.componentName: "package",
        UnresolvedComponents.componentName: "puzzle",
        Spin.componentName: "rotate-cw",
        KeyboardMover.componentName: "keyboard",
    ]

    /// The icon of component types without one of their own (games' components, unknown data).
    public static let fallbackComponent = "puzzle"

    /// Icons games registered, by component name.
    private static var registered: [String: VectorIcon] = [:]

    /// A built-in icon by Lucide name; a missing one is a programming error, so it falls back
    /// to `fallbackComponent` (tests check every name the editor uses exists).
    public static func named(_ name: String) -> VectorIcon {
        if let icon = VectorIcon.named(name) { return icon }
        assertionFailure("No built-in icon named \(name)")
        return VectorIcon.named(fallbackComponent)!
    }

    // MARK: Components

    /// Uses `icon` for the component named `component`: a built-in icon's name or SVG markup
    /// (`VectorIcon`). Throws when the SVG can't be read; an unknown name is an error too.
    public static func register(_ icon: String, forComponent component: String) throws {
        let trimmed = icon.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("<") {
            registered[component] = try VectorIcon(name: component, svg: trimmed)
        } else if let builtin = VectorIcon.named(trimmed) {
            registered[component] = builtin
        } else {
            throw VectorIconError.badPath("unknown icon name '\(trimmed)'")
        }
    }

    /// Forgets the icons registered for `components` (their game module was unloaded).
    public static func unregister(_ components: some Sequence<String>) {
        for name in components { registered[name] = nil }
    }

    /// Whether the component named `name` has its own icon (built in or registered).
    public static func hasIcon(forComponent name: String) -> Bool {
        registered[name] != nil || componentIconNames[name] != nil
    }

    /// The icon of the component named `name` (the fallback when it has none).
    public static func component(_ name: String) -> VectorIcon {
        if let icon = registered[name] { return icon }
        return named(componentIconNames[name] ?? fallbackComponent)
    }

    // MARK: Entities

    /// What an entity mainly is, for its hierarchy icon and its viewport billboard.
    public enum EntityKind: String, Sendable, CaseIterable {
        case camera, directionalLight, pointLight, spotLight, particles, audioEmitter, audioListener, mesh, sprite
        case character, trigger, physics, environment, postProcess, prefab, game, group, empty

        /// Kinds without anything to see or click on in the scene view: they get a billboard
        /// there when the entity has no mesh.
        public var hasBillboard: Bool {
            switch self {
            case .camera, .directionalLight, .pointLight, .spotLight, .particles, .audioEmitter, .audioListener, .trigger, .sprite: true
            default: false
            }
        }

        /// The billboard's icon color (on a dark disc).
        public var billboardColor: UIColor {
            switch self {
            case .camera: UIColor(hex: 0xe8ecf4)
            case .directionalLight, .pointLight, .spotLight: UIColor(hex: 0xffd34d)
            case .particles: UIColor(hex: 0xff9ad5)
            case .audioEmitter, .audioListener: UIColor(hex: 0x5fd4c4)
            case .trigger: UIColor(hex: 0x86e08a)
            case .sprite: UIColor(hex: 0xb0bcff)
            default: UIColor(hex: 0xe8ecf4)
            }
        }
    }

    /// The main kind of `entity`: the first of camera, the lights, particles, audio, a prefab
    /// instance's root, a mesh, a sprite, a character, a trigger, physics, environment,
    /// post-processing, a component with a registered (game) icon; else a group (has children) or empty.
    public static func entityKind(_ entity: Entity, in world: World) -> (kind: EntityKind, component: String?) {
        if world.has(Camera.self, for: entity) { return (.camera, Camera.componentName) }
        if world.has(DirectionalLight.self, for: entity) { return (.directionalLight, DirectionalLight.componentName) }
        if world.has(SpotLight.self, for: entity) { return (.spotLight, SpotLight.componentName) }
        if world.has(PointLight.self, for: entity) { return (.pointLight, PointLight.componentName) }
        if world.has(ParticleEmitter.self, for: entity) { return (.particles, ParticleEmitter.componentName) }
        if world.has(AudioEmitter.self, for: entity) { return (.audioEmitter, AudioEmitter.componentName) }
        if world.has(AudioListener.self, for: entity) { return (.audioListener, AudioListener.componentName) }
        // A prefab instance's root shows that it is one, before what it renders.
        if world.has(PrefabInstance.self, for: entity) { return (.prefab, PrefabInstance.componentName) }
        if world.has(MeshRenderer.self, for: entity) { return (.mesh, MeshRenderer.componentName) }
        if world.has(Sprite.self, for: entity) { return (.sprite, Sprite.componentName) }
        if world.has(CharacterController.self, for: entity) { return (.character, CharacterController.componentName) }
        if let collider = world.get(Collider.self, for: entity), collider.isTrigger { return (.trigger, Collider.componentName) }
        if let collider = world.get(Collider2D.self, for: entity), collider.isTrigger { return (.trigger, Collider2D.componentName) }
        for type in [RigidBody.self, Collider.self, Joint.self, RigidBody2D.self, Collider2D.self, Joint2D.self] as [any Component.Type]
            where world.has(type, for: entity) {
            return (.physics, type.componentName)
        }
        if world.has(SceneEnvironment.self, for: entity) { return (.environment, SceneEnvironment.componentName) }
        if world.has(PostProcessSettings.self, for: entity) { return (.postProcess, PostProcessSettings.componentName) }
        if !registered.isEmpty {
            for type in world.componentTypes(of: entity) where registered[type.componentName] != nil {
                return (.game, type.componentName)
            }
        }
        return world.children(of: entity).isEmpty ? (.empty, nil) : (.group, nil)
    }

    /// The icon for an entity of `kind` whose main component is `component`.
    public static func entityIcon(kind: EntityKind, component: String?) -> VectorIcon {
        switch kind {
        case .group: named("layers")
        case .empty: named("circle-dashed")
        default: component.map(Self.component) ?? named(fallbackComponent)
        }
    }

    /// The color of prefab instance icons (the accent, lifted toward the text to read on panels and selected rows).
    public static func prefabColor(theme: UITheme) -> UIColor {
        theme.accent.mixed(with: theme.textColor, 0.3)
    }

    /// The icon for `entity` (its main component's).
    public static func entityIcon(_ entity: Entity, in world: World) -> VectorIcon {
        let (kind, component) = entityKind(entity, in: world)
        return entityIcon(kind: kind, component: component)
    }

    // MARK: Assets

    /// The kinds of asset the browser and asset inspector tell apart by icon.
    public enum AssetIconKind: String, Sendable, CaseIterable {
        case folder, model, mesh, texture, material, prefab, scene, audio, shader, font, text, data, file
    }

    /// The icon kind of an imported object.
    public static func objectKind(_ kind: AssetKind) -> AssetIconKind { AssetIconKind(kind) }

    /// The icon kind of a browser entry (files without an importer by extension).
    public static func assetKind(_ kind: AssetBrowserEntry.Kind, path: String) -> AssetIconKind {
        switch kind {
        case .folder: return .folder
        case .model: return .model
        case .mesh: return .mesh
        case .texture: return .texture
        case .material: return .material
        case .prefab: return .prefab
        case .file: return assetKind(forFile: path)
        }
    }

    /// The icon kind of a file by its extension.
    public static func assetKind(forFile path: String) -> AssetIconKind {
        let ext = path.split(separator: ".").last.map { $0.lowercased() } ?? ""
        switch ext {
        case "gltf", "glb", "obj", "fbx": return .model
        case "png", "jpg", "jpeg", "tga", "hdr", "exr", "ktx", "ktx2", "dds", "bmp": return .texture
        case "material": return .material
        case "prefab": return .prefab
        case "scene": return .scene
        case "wav", "ogg", "mp3", "flac": return .audio
        case "metal", "vert", "frag", "comp", "glsl", "hlsl", "spv": return .shader
        case "ttf", "otf": return .font
        case "txt", "md": return .text
        case "json":
            // Scenes are JSON files; the editor names them "…scene….json".
            let name = path.split(separator: "/").last.map { $0.lowercased() } ?? ""
            return name.contains("scene") ? .scene : .data
        default: return .file
        }
    }

    public static func asset(_ kind: AssetIconKind) -> VectorIcon {
        switch kind {
        case .folder: named("folder")
        case .model: named("file-box")
        case .mesh: named("box")
        case .texture: named("image")
        case .material: named("palette")
        case .prefab: named("package")
        case .scene: named("clapperboard")
        case .audio: named("music")
        case .shader: named("file-code")
        case .font: named("type")
        case .text: named("file-text")
        case .data: named("file-json")
        case .file: named("file")
        }
    }

    /// The tint of an asset kind's big icon in the browser (cells without a thumbnail).
    public static func assetColor(_ kind: AssetIconKind, theme: UITheme) -> UIColor {
        switch kind {
        case .folder: UIColor(hex: 0xd9a646)
        default: theme.secondaryTextColor
        }
    }

    // MARK: Editor UI

    /// Icons of the panels' tabs, by panel id (`EditorLayout`).
    public static let panelIconNames: [String: String] = [
        EditorLayout.viewport: "view",
        EditorLayout.hierarchy: "list-tree",
        EditorLayout.inspector: "sliders-horizontal",
        EditorLayout.console: "terminal",
        EditorLayout.stats: "gauge",
        EditorLayout.assets: "folder",
        EditorLayout.activity: "bot",
    ]

    /// Console lines by level.
    public static func log(_ level: LogLevel) -> VectorIcon {
        switch level {
        case .info: named("info")
        case .warning: named("triangle-alert")
        case .error: named("circle-x")
        }
    }

    /// The Create menu's entity templates.
    public static func template(_ template: EntityTemplate) -> VectorIcon {
        switch template {
        case .empty: named("circle-dashed")
        case .cube: named("box")
        case .sphere: named("circle")
        case .plane: named("square")
        }
    }

    /// The transform tools.
    public static func tool(_ tool: EditorTool) -> VectorIcon {
        switch tool {
        case .move: named("move")
        case .rotate: named("rotate-3d")
        case .scale: named("scale-3d")
        }
    }

    // MARK: Viewport billboards

    /// A billboard for every entity of `world` without a mesh whose kind has one (see
    /// `EntityKind.hasBillboard`), at its world position.
    public static func billboards(in world: World) -> [ViewportBillboard] {
        var result: [ViewportBillboard] = []
        world.query(GlobalTransform.self) { entity, transform in
            guard !world.has(MeshRenderer.self, for: entity) else { return }
            let (kind, component) = entityKind(entity, in: world)
            guard kind.hasBillboard else { return }
            result.append(ViewportBillboard(entity: entity, position: transform.matrix.translation,
                                            icon: entityIcon(kind: kind, component: component), color: kind.billboardColor))
        }
        return result
    }
}

extension EditorIcons.AssetIconKind {
    /// The icon kind of an imported object (mesh, material, texture, prefab).
    public init(_ kind: AssetKind) {
        switch kind {
        case .mesh: self = .mesh
        case .material: self = .material
        case .texture: self = .texture
        case .prefab: self = .prefab
        }
    }
}
