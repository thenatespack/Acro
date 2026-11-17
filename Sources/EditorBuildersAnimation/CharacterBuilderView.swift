import EditorCore
import Engine
import Foundation

// The Character Builder form for a `.character` file: template, proportion sliders, region
// colors, attachments (mesh builds on bones) and the clips. Every change is written to the file as
// one undo step (`EditorSession.applyCharacter`), so the prefab reimports and placed copies update.

/// The proxy component for the body: proportions plus mesh settings.
struct CharacterBodyComponent: Component {
    static var componentName: String { "Body" }
    static var fieldHints: [String: FieldHints] {
        var hints: [String: FieldHints] = [:]
        let range = Double(CharacterProportions.range.lowerBound)...Double(CharacterProportions.range.upperBound)
        for name in CharacterProportions.names { hints[name] = FieldHints(range: range, step: 0.01) }
        hints["height"] = FieldHints(range: range, step: 0.01, tooltip: "Scales the whole character")
        hints["width"] = FieldHints(range: range, step: 0.01, tooltip: "Girth: body, limbs and their spacing")
        hints["arms"] = FieldHints(range: range, step: 0.01, tooltip: "Arm length (a bird's wingspan)")
        hints["smooth"] = FieldHints(tooltip: "Blend skin weights across joints so knees and elbows bend smoothly")
        hints["segments"] = FieldHints(range: 6...32, step: 1, tooltip: "Roundness of the body shapes")
        return hints
    }

    var height: Float, head: Float, torso: Float, width: Float, arms: Float, legs: Float, neck: Float, tail: Float
    var smooth: Bool
    var segments: Int

    init(_ c: CharacterBuild) {
        let p = c.proportions
        height = p.height; head = p.head; torso = p.torso; width = p.width
        arms = p.arms; legs = p.legs; neck = p.neck; tail = p.tail
        smooth = c.smooth
        segments = c.segments
    }

    var proportions: CharacterProportions {
        CharacterProportions(height: height, head: head, torso: torso, width: width, arms: arms, legs: legs, neck: neck, tail: tail).clamped
    }
}

/// The file's colors are sRGB; the property grid's color fields hold linear values (and show
/// them as sRGB), so the proxies convert both ways.
enum CharacterProxyColor {
    static func linear(_ srgb: Vec3) -> Vec3 { UIColor(srgb.x, srgb.y, srgb.z).linearRGB }
    static func srgb(_ linear: Vec3) -> Vec3 {
        let c = UIColor(linearRGB: linear)
        return Vec3(c.r, c.g, c.b)
    }
}

/// The proxy component for the region colors (the ones in use, defaults included), linear.
struct CharacterColorsComponent: Component {
    static var componentName: String { "Colors" }
    static var fieldHints: [String: FieldHints] {
        ["skin": FieldHints(color: true), "body": FieldHints(color: true), "legs": FieldHints(color: true),
         "accent": FieldHints(color: true, tooltip: "Feet, beak, ears and other details"), "eyes": FieldHints(color: true)]
    }

    var skin: Vec3, body: Vec3, legs: Vec3, accent: Vec3, eyes: Vec3

    init(_ c: CharacterBuild) {
        func f(_ region: CharacterRegion) -> Vec3 { CharacterProxyColor.linear(c.color(region)) }
        skin = f(.skin); body = f(.body); legs = f(.legs); accent = f(.accent); eyes = f(.eyes)
    }

    subscript(region: CharacterRegion) -> Vec3 {
        switch region {
        case .skin: skin
        case .body: body
        case .legs: legs
        case .accent: accent
        case .eyes: eyes
        }
    }
}

/// The proxy component for one attachment.
struct CharacterAttachmentComponent: Component {
    static var componentName: String { "Attachment" }
    static var fieldHints: [String: FieldHints] {
        var hints = CharacterAttachment.fieldHints
        hints["recolor"] = FieldHints(tooltip: "Paint every part of the model with Color")
        hints["color"] = FieldHints(color: true, tooltip: "Used when Recolor is on")
        return hints
    }

    var name: String
    var bone: String
    var asset: String
    var position: Vec3
    var rotation: Vec3
    var scale: Float
    var recolor: Bool
    var color: Vec3

    init(_ a: CharacterAttachment) {
        name = a.name; bone = a.bone; asset = a.asset; position = a.position; rotation = a.rotation; scale = a.scale
        recolor = a.color != nil
        color = CharacterProxyColor.linear(a.color ?? Vec3(0.8, 0.8, 0.8))
    }

    /// The attachment with these fields (`partColors` from `original`, which the grid doesn't show).
    func attachment(keeping original: CharacterAttachment) -> CharacterAttachment {
        // An unchanged color keeps the file's exact value (no round trip through linear).
        let unchanged = original.color.map { CharacterProxyColor.linear($0) == color } ?? false
        let srgb = unchanged ? original.color : CharacterProxyColor.srgb(color)
        return CharacterAttachment(name: name, bone: bone, asset: asset, position: position, rotation: rotation, scale: max(scale, 0.01),
                                   color: recolor ? srgb ?? CharacterProxyColor.srgb(color) : nil, partColors: original.partColors)
    }
}

@MainActor
public final class CharacterBuilderView {
    public let session: EditorSession
    public let asset: AssetID
    public let view: VStack
    public private(set) var character: CharacterBuild
    public private(set) var selectedAttachment: String?
    /// Plays a clip in the preview (set by the workspace).
    var onPlayClip: ((String) -> Void)?
    /// The clip the preview plays (for highlighting).
    var playingClip: () -> String? = { nil }
    let attachmentList = ListView(items: [], name: "characterAttachments")
    private var grids: [PropertyGrid] = []
    private let gridWorld = World()
    private var gridEntities: [Entity] = []
    private var listed: [String] = []
    private var newAsset = 0
    private var newBone = Int.max  // the template's hand bone until one is picked
    private var pending: (character: CharacterBuild, label: String, select: String?)?
    private static var selections: [AssetID: String] = [:]

    public init?(session: EditorSession, asset: AssetID) {
        guard session.isCharacterFile(asset), let character = session.assets?.character(of: asset) else { return nil }
        self.session = session
        self.asset = asset
        self.character = character
        view = VStack(spacing: 6, name: "characterBuilder")
        let remembered = Self.selections[asset]
        selectedAttachment = character.attachments.contains { $0.name == remembered } ? remembered : character.attachments.first?.name
        attachmentList.style.height = 90
        attachmentList.onSelect = { [unowned self] row in
            guard let row, listed.indices.contains(row), listed[row] != selectedAttachment else { return }
            select(listed[row])
        }
        layout()
    }

    /// Call every frame: applies the pending edit and keeps the grids in step with their proxies.
    public func refresh() {
        if let pending {
            self.pending = nil
            commit(pending.character, label: pending.label, select: pending.select)
        }
        for grid in grids { grid.refresh() }
    }

    public var hasPendingEdit: Bool { pending != nil }

    /// Rereads the file (after an undo or an edit from elsewhere) and lays the form out again.
    public func reload() {
        guard pending == nil, let character = session.assets?.character(of: asset) else { return }
        self.character = character
        if !character.attachments.contains(where: { $0.name == selectedAttachment }) { selectedAttachment = character.attachments.first?.name }
        layout()
    }

    // MARK: Layout

    func layout() {
        view.removeAllChildren()
        for entity in gridEntities { gridWorld.despawn(entity) }
        gridEntities.removeAll()
        grids.removeAll()

        let place = Button("Place in Scene", role: .primary, name: "characterPlace") { [unowned self] in
            session.run(AssetInstantiateCommand.self, .init(asset: AssetReference(asset)))
        }
        place.command = AssetInstantiateCommand.id.rawValue
        place.tooltip = "Put a copy of this character in the scene (copies update when you change it here; it animates in play mode)"
        view.addChild(HStack(spacing: 6, [place, Spacer()]))

        // Template.
        view.addChild(Label("Template", role: .secondary))
        let templates = CharacterTemplate.allCases
        let template = Dropdown(options: templates.map { Self.title($0.rawValue) }, selectedIndex: templates.firstIndex(of: character.template) ?? 0,
                                name: "characterTemplate") { [unowned self] index in
            guard templates.indices.contains(index), templates[index] != character.template else { return }
            var edited = character
            edited.template = templates[index]
            apply(edited, label: "Change Template")
        }
        template.tooltip = "The body plan: skeleton, shapes and stock clips"
        view.addChild(template)

        // Clips.
        view.addChild(Label("Clips", role: .secondary))
        var clipButtons: [Widget] = []
        for name in character.clipNames {
            let button = Button(Self.title(name), role: playingClip() == name ? .primary : .normal, name: "characterClip.\(name)") {
                [unowned self] in onPlayClip?(name)
            }
            button.tooltip = "Preview the \(name) clip"
            clipButtons.append(button)
        }
        if clipButtons.isEmpty { view.addChild(note("No clips: add some with character.edit {clips}.")) }
        for row in stride(from: 0, to: clipButtons.count, by: 3) {
            view.addChild(HStack(spacing: 4, Array(clipButtons[row..<min(row + 3, clipButtons.count)]) + [Spacer()]))
        }
        let clipNames = character.clipNames
        if !clipNames.isEmpty {
            let start = Dropdown(options: clipNames.map(Self.title), selectedIndex: clipNames.firstIndex(of: character.defaultClip) ?? 0,
                                 name: "characterDefaultClip") { [unowned self] index in
                guard clipNames.indices.contains(index), clipNames[index] != character.defaultClip else { return }
                var edited = character
                edited.defaultClip = clipNames[index]
                apply(edited, label: "Set Default Clip")
            }
            start.tooltip = "The state the Animator starts in"
            view.addChild(HStack(spacing: 6, [Label("Starts in", role: .caption), start]))
        }

        // Body.
        view.addChild(Separator())
        view.addChild(Label("Proportions", role: .secondary))
        addGrid(CharacterBodyComponent(character), name: "characterBodyGrid") { [unowned self] (body: CharacterBodyComponent) in
            var edited = character
            edited.proportions = body.proportions
            edited.smooth = body.smooth
            edited.segments = min(max(body.segments, 6), 32)
            apply(edited, label: "Edit Proportions")
        }
        let reset = Button("Reset Proportions", name: "characterResetProportions") { [unowned self] in
            var edited = character
            edited.proportions = CharacterProportions()
            apply(edited, label: "Reset Proportions")
        }
        view.addChild(HStack(spacing: 6, [reset, Spacer()]))

        view.addChild(Label("Colors", role: .secondary))
        addGrid(CharacterColorsComponent(character), name: "characterColorsGrid") { [unowned self] (colors: CharacterColorsComponent) in
            var edited = character
            let before = CharacterColorsComponent(character)
            for region in CharacterRegion.allCases where colors[region] != before[region] {
                edited.colors[region] = CharacterProxyColor.srgb(colors[region])
            }
            apply(edited, label: "Edit Colors")
        }
        let resetColors = Button("Template Colors", name: "characterResetColors") { [unowned self] in
            var edited = character
            edited.colors = CharacterColors()
            apply(edited, label: "Reset Colors")
        }
        resetColors.tooltip = "Go back to the template's default colors"
        view.addChild(HStack(spacing: 6, [resetColors, Spacer()]))

        // Attachments.
        view.addChild(Separator())
        view.addChild(Label("Attachments", role: .secondary))
        listed = character.attachments.map(\.name)
        attachmentList.items = character.attachments.map { a in a.name + "  ·  " + a.bone }
        if let selectedAttachment, let row = listed.firstIndex(of: selectedAttachment) { attachmentList.selectRow(row, reveal: true) }
        view.addChild(attachmentList)
        let builds = meshBuildPaths()
        let bones = character.rig.bones.map(\.name)
        if newBone >= bones.count { newBone = bones.firstIndex(of: character.template.handBone) ?? 0 }
        if builds.isEmpty {
            view.addChild(note("Make a model with New Mesh Build in the Assets panel, then attach it to a bone here."))
        } else {
            newAsset = min(newAsset, builds.count - 1)
            let assetPicker = Dropdown(options: builds, selectedIndex: newAsset, name: "characterAttachAsset") { [unowned self] i in newAsset = i }
            assetPicker.tooltip = "The mesh build to attach"
            let bonePicker = Dropdown(options: bones, selectedIndex: newBone, name: "characterAttachBone") { [unowned self] i in newBone = i }
            bonePicker.tooltip = "The bone it follows"
            let add = Button("Attach", name: "characterAttach") { [unowned self] in attach(builds[newAsset], bone: bones[newBone]) }
            add.command = CharacterEditCommand.id.rawValue
            view.addChild(assetPicker)
            view.addChild(HStack(spacing: 4, [bonePicker, add]))
        }
        if let selectedAttachment, let attachment = character.attachments.first(where: { $0.name == selectedAttachment }) {
            let delete = Button("Detach", name: "characterDetach") { [unowned self] in detach(attachment.name) }
            delete.tooltip = "Remove this attachment"
            view.addChild(HStack(spacing: 6, [Label(attachment.name, role: .secondary), Spacer(), delete]))
            addGrid(CharacterAttachmentComponent(attachment), name: "characterAttachmentGrid") { [unowned self] (proxy: CharacterAttachmentComponent) in
                commitAttachment(proxy.attachment(keeping: attachment), originalName: attachment.name)
            }
            addPartColors(attachment)
        }

        let problems = character.problems + CharacterCheck.problems(character, in: session)
        if !problems.isEmpty {
            view.addChild(Separator())
            view.addChild(Label("Problems", role: .secondary))
            for problem in problems { view.addChild(note(problem)) }
        }
        view.addChild(note("Imported as a skinned prefab with an Animator: states per clip plus \"locomotion\" (idle, walk and run blended by the "
                           + "float parameter speed, m/s); triggers jump, attack and die. Placed copies animate in play mode, and in the Scene view with View > Animate in Scene View."))
    }

    private func addGrid<C: Component>(_ proxy: C, name: String, onCommit: @escaping (C) -> Void) {
        let entity = gridWorld.spawn(proxy)
        gridEntities.append(entity)
        let grid = PropertyGrid(world: gridWorld, name: name)
        grid.appliesEditsToWorld = false
        grid.labelWidth = 96
        grid.entity = entity
        grid.command = CharacterEditCommand.id.rawValue
        grid.onFieldEdit = { [unowned self] edit in
            do { try gridWorld.setField(edit.path, of: C.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Character \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended, let value = gridWorld.get(C.self, for: entity) { onCommit(value) }
        }
        grids.append(grid)
        view.addChild(grid)
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "characterNote")
        label.wraps = true
        return label
    }

    static func title(_ name: String) -> String { name.prefix(1).uppercased() + name.dropFirst() }

    /// The project's `.meshbuild` files.
    func meshBuildPaths() -> [String] {
        guard let assets else { return [] }
        return assets.allRecords.filter { $0.importer == MeshBuildImporter().name }.map(\.path).sorted()
    }

    private var assets: AssetDatabase? { session.assets }

    // MARK: Edits

    private func select(_ name: String?) {
        selectedAttachment = name
        Self.selections[asset] = name
        layout()
    }

    func apply(_ edited: CharacterBuild, label: String, select name: String? = nil) {
        pending = (edited, label, name)
    }

    private func commit(_ edited: CharacterBuild, label: String, select name: String?) {
        guard session.applyCharacter(edited, to: asset, label: label) != nil else { return }
        character = session.assets?.character(of: asset) ?? edited
        if let name { Self.selections[asset] = name }
        select(Self.selections[asset].flatMap { n in character.attachments.contains { $0.name == n } ? n : nil } ?? character.attachments.first?.name)
    }

    func attach(_ path: String, bone: String) {
        var edited = character
        let base = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        let attachment = CharacterAttachment(name: edited.uniqueAttachmentName(base), bone: bone, asset: path)
        edited.attachments.append(attachment)
        apply(edited, label: "Attach \(base)", select: attachment.name)
    }

    func detach(_ name: String) {
        var edited = character
        edited.attachments.removeAll { $0.name == name }
        Self.selections[asset] = edited.attachments.first?.name
        apply(edited, label: "Detach \(name)")
    }

    /// A color per part of the selected attachment's mesh build: its override (or the color
    /// it gets now), with Reset where one is set.
    private func addPartColors(_ attachment: CharacterAttachment) {
        guard let id = EditorBuilderSupport.resolve(attachment.asset.trimmingCharacters(in: .whitespaces), session: session),
              let expansion = session.assets?.meshBuild(of: id)?.expansion() else { return }
        let build = expansion.build  // mirror / repeat copies included
        var names: [String] = []
        for part in build.parts where !names.contains(part.name) && part.shape != .group { names.append(part.name) }
        guard !names.isEmpty else { return }
        view.addChild(Label("Part Colors", role: .secondary))
        for name in names {
            let own = build.parts.first { $0.name == name }?.color ?? Vec3(0.8, 0.8, 0.8)
            let current = attachment.color(ofPart: name, source: expansion.source(of: name)) ?? own
            let swatch = ColorSwatch(color: UIColor(current.x, current.y, current.z), name: "characterPartColor.\(name)")
            swatch.tooltip = "The color of part \(name) (over Color)"
            swatch.onEditEnded = { [unowned self] _, end in setPartColor(name, Vec3(end.r, end.g, end.b), of: attachment.name) }
            var row: [Widget] = [Label(name), Spacer(), swatch]
            if attachment.partColors[name] != nil {
                let reset = Button("Reset", name: "characterPartColorReset.\(name)") { [unowned self] in setPartColor(name, nil, of: attachment.name) }
                reset.tooltip = "Back to the attachment's Color (or the part's own)"
                reset.command = CharacterEditCommand.id.rawValue
                row.append(reset)
            }
            view.addChild(HStack(spacing: 6, row))
        }
    }

    private func setPartColor(_ part: String, _ color: Vec3?, of attachmentName: String) {
        guard let index = character.attachments.firstIndex(where: { $0.name == attachmentName }) else { return }
        var edited = character
        edited.attachments[index].partColors[part] = color
        apply(edited, label: "Edit Part Color", select: attachmentName)
    }

    private func commitAttachment(_ updated: CharacterAttachment, originalName: String) {
        guard let index = character.attachments.firstIndex(where: { $0.name == originalName }) else { return }
        var edited = character
        var attachment = updated
        let newName = attachment.name.trimmingCharacters(in: .whitespaces)
        attachment.name = originalName
        if !newName.isEmpty, newName != originalName {
            if edited.attachments.contains(where: { $0.name == newName }) {
                session.log.warning("Character: an attachment is already named \(newName)")
            } else {
                attachment.name = newName
            }
        }
        edited.attachments[index] = attachment
        apply(edited, label: "Edit Attachment", select: attachment.name)
    }
}
