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
        PostFXVolume.componentName: "aperture",
        PlanarReflection.componentName: "reflection",
        MeshRenderer.componentName: "box",
        LineRenderer.componentName: "cable",
        MeshArray.componentName: "layout-grid",
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
        TextMesh.componentName: "type",
        Decal.componentName: "palette",
        Sprite.componentName: "image",
        SpriteAnimator.componentName: "images",
        Animator.componentName: "film",
        Skin.componentName: "bone",
        Saveable.componentName: "archive",
        Replicated.componentName: "network",
        Unpickable.componentName: "mouse-pointer-ban",
        PrefabInstance.componentName: EditorIcons.prefabIconName,
        UnresolvedComponents.componentName: "puzzle",
        Spin.componentName: "rotate-cw",
        KeyboardMover.componentName: "keyboard",
        FieldAnimator.componentName: "sliders-horizontal",
        LightFlicker.componentName: "gauge",
        CameraPath.componentName: "orbit",
        "Pulse": "gauge",
    ]

    /// The icon of component types without one of their own (games' components, unknown data).
    public static let fallbackComponent = "puzzle"

    /// Icons games registered, by component name.
    private static var registered: [String: VectorIcon] = [:]

    /// A built-in icon by Lucide name, or one of the editor's own (`editorIconSVG`); a missing
    /// one is a programming error, so it falls back to `fallbackComponent` (tests check every
    /// name the editor uses exists).
    public static func named(_ name: String) -> VectorIcon {
        if let icon = VectorIcon.named(name) { return icon }
        if let icon = editorIcon(name) { return icon }
        assertionFailure("No built-in icon named \(name)")
        return VectorIcon.named(fallbackComponent)!
    }

    // MARK: The editor's own icons

    /// Prefab files and instances: four diamonds (the "component / instance" mark of design
    /// tools), so a prefab never looks like a mesh's cube.
    public static let prefabIconName = "prefab"

    /// Icons drawn for the editor where Lucide has none: mesh shapes and the prefab mark. Same
    /// conventions as Lucide (24x24 view box, 2-unit round strokes).
    public static let editorIconSVG: [String: String] = [
        // A cable hanging between two posts.
        "cable": #"<path d="M3 4c3 16 15 16 18 0"/><path d="M3 2v4"/><path d="M21 2v4"/>"#,
        prefabIconName: #"<path d="M12 2.5 15.5 6 12 9.5 8.5 6Z"/><path d="M6 8.5 9.5 12 6 15.5 2.5 12Z"/><path d="M18 8.5 21.5 12 18 15.5 14.5 12Z"/><path d="M12 14.5 15.5 18 12 21.5 8.5 18Z"/>"#,
        // A ball with its front equator and a meridian.
        "mesh-sphere": #"<circle cx="12" cy="12" r="10"/><path d="M2 12a10 3.5 0 0 0 20 0"/><path d="M12 2a3.5 10 0 0 0 0 20"/>"#,
        // A flat quad seen at an angle, with a 2x2 grid.
        "mesh-plane": #"<path d="M2 16 7 8h15l-5 8Z"/><path d="M4.5 12h15"/><path d="M14.5 8l-5 8"/>"#,
        "mesh-cylinder": #"<ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M3 5v14a9 3 0 0 0 18 0V5"/>"#,
        // A circle half hatched (light and dark): the View menu (layout, theme and zoom).
        "appearance": #"<circle cx="12" cy="12" r="10"/><path d="M12 2a10 10 0 0 1 0 20Z"/><path d="M12 7h5"/><path d="M12 12h7"/><path d="M12 17h5"/>"#,
        // Two chevrons: the toolbar's More menu (Lucide's chevrons-right).
        "overflow": #"<path d="m6 17 5-5-5-5"/><path d="m13 17 5-5-5-5"/>"#,
        // A triangle above a dashed line and its mirror image below: PlanarReflection.
        "reflection": #"<path d="M12 3 18 10H6Z"/><path d="M12 21 18 14H6Z"/><path d="M2 12h2"/><path d="M8 12h2"/><path d="M14 12h2"/><path d="M20 12h2"/>"#,
        // A subdivided triangle: any other mesh (imported models, meshes games register).
        "mesh-custom": #"<path d="M12 3.5 21 19.5H3Z"/><path d="M7.5 11.5h9"/><path d="m7.5 11.5 4.5 8"/><path d="m16.5 11.5-4.5 8"/>"#,
    ]

    private static var editorIconCache: [String: VectorIcon] = [:]

    /// One of `editorIconSVG`, parsed once.
    public static func editorIcon(_ name: String) -> VectorIcon? {
        if let cached = editorIconCache[name] { return cached }
        guard let svg = editorIconSVG[name], let icon = try? VectorIcon(name: name, svg: svg) else { return nil }
        editorIconCache[name] = icon
        return icon
    }

    /// The icon of a mesh by its key: the built-in cube, sphere and plane (and code-registered
    /// meshes named like them: "sphere-hi", "floor", "capsule"), else the generic mesh mark.
    public static func meshIconName(_ mesh: MeshHandle) -> String {
        let key = mesh.key.lowercased()
        if AssetReference(mesh.key) != nil { return "mesh-custom" }
        if key.contains("sphere") || key.contains("ball") { return "mesh-sphere" }
        if key.contains("plane") || key.contains("floor") || key.contains("ground") || key.contains("quad") { return "mesh-plane" }
        if key.contains("cylinder") || key.contains("capsule") || key.contains("pillar") { return "mesh-cylinder" }
        if key.contains("cube") || key.contains("box") { return "box" }
        return "mesh-custom"
    }

    /// `color`, mixed toward `toward` (the theme's text color) in steps until it has `minimum`
    /// contrast with `background`: icon tints that read in every theme (WCAG 1.4.11 asks 3:1).
    public static func readable(_ color: UIColor, on background: UIColor, toward: UIColor, minimum: Float = 3) -> UIColor {
        var mixed = color
        var amount: Float = 0
        while mixed.contrastRatio(with: background) < minimum && amount < 1 {
            amount = min(1, amount + 0.1)
            mixed = color.mixed(with: toward, amount)
        }
        return mixed
    }

    /// A theme surface as drawn: translucent ones (the Game theme's) over black.
    static func opaque(_ color: UIColor) -> UIColor { color.a < 1 ? color.composited(over: .black) : color }

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
        case decal

        /// Kinds without anything to see or click on in the scene view: they get a billboard
        /// there when the entity has no mesh.
        public var hasBillboard: Bool {
            switch self {
            case .camera, .directionalLight, .pointLight, .spotLight, .particles, .audioEmitter, .audioListener, .trigger, .sprite, .decal: true
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
            case .decal: UIColor(hex: 0xffb86b)
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
        if world.has(Decal.self, for: entity) { return (.decal, Decal.componentName) }
        if world.has(CharacterController.self, for: entity) { return (.character, CharacterController.componentName) }
        if let collider = world.get(Collider.self, for: entity), collider.isTrigger { return (.trigger, Collider.componentName) }
        if let collider = world.get(Collider2D.self, for: entity), collider.isTrigger { return (.trigger, Collider2D.componentName) }
        for type in [RigidBody.self, Collider.self, Joint.self, RigidBody2D.self, Collider2D.self, Joint2D.self] as [any Component.Type]
            where world.has(type, for: entity) {
            return (.physics, type.componentName)
        }
        if world.has(SceneEnvironment.self, for: entity) { return (.environment, SceneEnvironment.componentName) }
        if world.has(PostProcessSettings.self, for: entity) { return (.postProcess, PostProcessSettings.componentName) }
        if world.has(PostFXVolume.self, for: entity) { return (.postProcess, PostFXVolume.componentName) }
        if world.has(PlanarReflection.self, for: entity) { return (.postProcess, PlanarReflection.componentName) }
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

    /// The color of prefab instance icons: the accent, lifted toward the text until it has 3:1
    /// on the panel (selected rows draw icons in the text color).
    public static func prefabColor(theme: UITheme) -> UIColor {
        readable(theme.accent.mixed(with: theme.textColor, 0.3), on: opaque(theme.panelBackground), toward: theme.textColor)
    }

    /// The icon for `entity`: its main component's; a mesh's by its shape (`meshIconName`).
    public static func entityIcon(_ entity: Entity, in world: World) -> VectorIcon {
        let (kind, component) = entityKind(entity, in: world)
        if kind == .mesh, let renderer = world.get(MeshRenderer.self, for: entity) { return named(meshIconName(renderer.mesh)) }
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
        case "gltf", "glb", "obj", "fbx", "meshbuild": return .model
        case "vfx": return .prefab
        case "table": return .model
        case "gltf", "glb", "obj", "fbx", "meshbuild", "terrain": return .model
        case "png", "jpg", "jpeg", "tga", "hdr", "exr", "ktx", "ktx2", "dds", "bmp", "proctex": return .texture
        case "material": return .material
        case "postfx": return .material
        case "prefab": return .prefab
        case "scene": return .scene
        case "wav", "ogg", "mp3", "flac", "sfx": return .audio
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
        case .prefab: named(prefabIconName)
        case .scene: named("clapperboard")
        case .audio: named("music")
        case .shader: named("file-code")
        case .font: named("type")
        case .text: named("file-text")
        case .data: named("file-json")
        case .file: named("file")
        }
    }

    /// The tint of an asset kind's big icon in the browser (cells without a thumbnail): folders
    /// amber (darkened where the panel is light), the rest the secondary text color.
    public static func assetColor(_ kind: AssetIconKind, theme: UITheme) -> UIColor {
        switch kind {
        case .folder: readable(UIColor(hex: 0xd9a646), on: opaque(theme.panelBackground), toward: theme.textColor)
        default: theme.secondaryTextColor
        }
    }

    // MARK: Editor UI

    /// Icons of the panels' tabs, by panel id (`EditorLayout`).
    public static let panelIconNames: [String: String] = [
        EditorLayout.viewport: "view",
        EditorLayout.game: "gamepad-2",
        EditorLayout.hierarchy: "list-tree",
        EditorLayout.inspector: "sliders-horizontal",
        EditorLayout.console: "terminal",
        EditorLayout.stats: "gauge",
        EditorLayout.assets: "folder",
        EditorLayout.activity: "bot",
        EditorLayout.scripts: "file-code",
        EditorLayout.files: "folder-open",
        EditorLayout.meshBuilder: "cuboid",
        EditorLayout.vfxBuilder: "sparkles",
        EditorLayout.soundBuilder: "volume-2",
        EditorLayout.postFXBuilder: "aperture",
        EditorLayout.dataTable: "layout-grid",
        EditorLayout.terrainBuilder: "layers",
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
        case .cube: named(meshIconName(.cube))
        case .sphere: named(meshIconName(.sphere))
        case .plane: named(meshIconName(.plane))
        case .cylinder: named(meshIconName(.cylinder))
        case .capsule: named(meshIconName(.capsule))
        case .cone: named(meshIconName(.cone))
        case .torus: named(meshIconName(.torus))
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
