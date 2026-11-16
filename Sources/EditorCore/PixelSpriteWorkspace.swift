import Engine
import Foundation

// The Pixel Sprite Builder: the editor tab for a `.sprite` file. The canvas (PixelSpriteView.swift)
// shows the current frame with onion skin; the sidebar has the tools (pencil, line, rectangle,
// fill, eraser, color picker, mirror drawing), the palette (presets, edit, add, remove), layers,
// frames with their timing, tags and an animation preview. Every finished stroke and every form
// change is written to the file as one undo step (`EditorSession.applyPixelSprite`), which
// reimports the atlas texture; Ctrl+Z takes it back.

/// Edits one `.sprite` file: the working copy, the current frame / layer / color / tool, and the sidebar form.
@MainActor
public final class PixelSpriteBuilderView {
    public let session: EditorSession
    public let asset: AssetID
    public let view: VStack
    /// The working copy (the file plus an edit not written yet).
    public private(set) var sprite: PixelSprite
    public private(set) var frame = 0
    public private(set) var layer = 0
    /// The pixel value drawn (0 transparent, `n` palette entry `n - 1`).
    public private(set) var color: UInt8 = 1
    public var tool = PixelTool.pencil
    public var mirror: PixelMirror = []
    public var filled = false
    public var onionSkin = true
    /// The tag selected in the tags list (also the clip the preview plays).
    public private(set) var selectedTag: Int?
    /// Called when what the canvas shows changed (the workspace redraws).
    public var onChanged: (() -> Void)?

    let palette = PixelPaletteView()
    let layerList = ListView(items: [], name: "spriteLayers")
    let tagList = ListView(items: [], name: "spriteTags")
    private var pending: (sprite: PixelSprite, label: String)?
    /// The form is laid out again on the next `refresh` (not while a widget handles an event).
    private var needsLayout = false
    private struct Remembered { var frame = 0, layer = 0, color: UInt8 = 1, tool = PixelTool.pencil, tag: Int? }
    private static var remembered: [AssetID: Remembered] = [:]

    public init?(session: EditorSession, asset: AssetID) {
        guard session.isPixelSpriteFile(asset), let sprite = session.assets?.pixelSprite(of: asset) else { return nil }
        self.session = session
        self.asset = asset
        self.sprite = sprite
        view = VStack(spacing: 6, name: "spriteBuilder")
        if let r = Self.remembered[asset] {
            (frame, layer, color, tool, selectedTag) = (r.frame, r.layer, r.color, r.tool, r.tag)
        }
        clampSelection()
        layerList.style.height = 84
        tagList.style.height = 72
        layerList.onSelect = { [unowned self] row in
            guard let row else { return }
            let index = self.sprite.layers.count - 1 - row
            guard index != layer, self.sprite.layers.indices.contains(index) else { return }
            selectLayer(index)
        }
        tagList.onSelect = { [unowned self] row in
            guard let row, row != selectedTag else { return }
            selectTag(row)
        }
        palette.onSelect = { [unowned self] value in selectColor(value) }
        layout()
    }

    /// Call every frame: writes the pending edit and lays the form out again if needed.
    public func refresh() {
        if let pending {
            self.pending = nil
            commit(pending.sprite, label: pending.label)
        }
        if needsLayout { layout() }
    }

    public var hasPendingEdit: Bool { pending != nil }

    /// Rereads the file (after an undo or an edit from elsewhere) and lays the form out again.
    public func reload() {
        guard pending == nil, let sprite = session.assets?.pixelSprite(of: asset) else { return }
        self.sprite = sprite
        clampSelection()
        layout()
        onChanged?()
    }

    private func clampSelection() {
        frame = min(max(frame, 0), sprite.frames.count - 1)
        layer = min(max(layer, 0), sprite.layers.count - 1)
        if Int(color) > sprite.palette.count { color = sprite.palette.isEmpty ? 0 : 1 }
        if let t = selectedTag, !sprite.tags.indices.contains(t) { selectedTag = sprite.tags.isEmpty ? nil : 0 }
        if let r = selection?.clamped(width: sprite.width, height: sprite.height) { selection = r.isEmpty ? nil : r }
    }

    private func remember() {
        Self.remembered[asset] = Remembered(frame: frame, layer: layer, color: color, tool: tool, tag: selectedTag)
    }

    // MARK: Selection (no file change)

    public func selectFrame(_ index: Int) {
        frame = min(max(index, 0), sprite.frames.count - 1)
        remember()
        needsLayout = true
        onChanged?()
    }

    public func selectLayer(_ index: Int) {
        layer = min(max(index, 0), sprite.layers.count - 1)
        remember()
        needsLayout = true
        onChanged?()
    }

    /// Shows tag `index` (its range, mode and frame events) below the tag list.
    public func selectTag(_ index: Int) {
        guard sprite.tags.indices.contains(index) else { return }
        selectedTag = index
        remember()
        needsLayout = true
        onChanged?()
    }

    public func selectColor(_ value: UInt8) {
        color = Int(value) <= sprite.palette.count ? value : 0
        remember()
        needsLayout = true
    }

    public func selectTool(_ tool: PixelTool) {
        self.tool = tool
        remember()
        needsLayout = true
    }

    /// The color picker: selects the topmost visible color at `point` in the current frame.
    public func pickColor(at point: PixelPoint) {
        selectColor(sprite.pick(frame: frame, x: point.x, y: point.y))
    }

    // MARK: Selection and clipboard

    /// The selected rectangle of the canvas (always inside it), nil for none. It stays when the
    /// frame or layer changes, so pixels can be copied in one cel and pasted in another.
    public private(set) var selection: PixelRect?
    /// Copied pixels, shared by every sprite tab (so they paste into other files too), with the
    /// place they were copied from.
    public private(set) static var clipboard: (clip: PixelClip, origin: PixelPoint)?

    /// Selects `rect` (cut to the canvas; an empty rectangle deselects).
    public func select(_ rect: PixelRect?) {
        let r = rect?.clamped(width: sprite.width, height: sprite.height)
        selection = r.flatMap { $0.isEmpty ? nil : $0 }
        needsLayout = true
        onChanged?()
    }

    public func selectAll() { select(PixelRect(x: 0, y: 0, width: sprite.width, height: sprite.height)) }
    public func deselect() { select(nil) }

    /// Copies the selected pixels of the current cel (or the whole cel without a selection).
    @discardableResult
    public func copySelection() -> Bool {
        let rect = selection ?? PixelRect(x: 0, y: 0, width: sprite.width, height: sprite.height)
        guard let clip = sprite.copy(rect, frame: frame, layer: layer) else { return false }
        Self.clipboard = (clip, PixelPoint(rect.x, rect.y))
        needsLayout = true
        return true
    }

    /// Copies the selected pixels, then erases them.
    public func cutSelection() {
        guard copySelection() else { return }
        deleteSelection(label: "Cut")
    }

    /// Erases the selected pixels of the current cel (the whole cel without a selection).
    public func deleteSelection(label: String = "Delete Selection") {
        let rect = selection ?? PixelRect(x: 0, y: 0, width: sprite.width, height: sprite.height)
        let (f, l) = (frame, layer)
        edit(label) { $0.clear(rect, frame: f, layer: l) }
    }

    /// Pastes the clipboard into the current cel: at the selection's top-left, else where it was
    /// copied from. The pasted pixels become the selection (drag them to move them).
    public func paste() {
        guard let (clip, origin) = Self.clipboard else { return }
        let at = selection.map { PixelPoint($0.x, $0.y) } ?? origin
        let (f, l) = (frame, layer)
        edit("Paste") { $0.paste(clip, x: at.x, y: at.y, frame: f, layer: l) }
        select(PixelRect(x: at.x, y: at.y, width: clip.width, height: clip.height))
    }

    /// Moves the selected pixels of the current cel by (`dx`, `dy`) (with `copy`, a copy of them)
    /// and the selection with them.
    public func moveSelection(dx: Int, dy: Int, copy: Bool = false) {
        guard let rect = selection, dx != 0 || dy != 0 else { return }
        let (f, l) = (frame, layer)
        edit(copy ? "Duplicate Selection" : "Move Selection") { $0.move(rect, dx: dx, dy: dy, frame: f, layer: l, copy: copy) }
        // The selection follows the pixels, even partly off the canvas (cut to it).
        select(rect.offsetBy(dx, dy))
    }

    // MARK: Keyboard

    /// The single-key tool shortcuts.
    public static let toolKeys: [Key: PixelTool] = [.b: .pencil, .l: .line, .u: .rect, .g: .fill, .e: .eraser, .i: .picker, .m: .select]

    static func shortcutLabel(_ tool: PixelTool) -> String {
        toolKeys.first { $0.value == tool }.map { String(describing: $0.key).uppercased() } ?? ""
    }

    /// Whether the canvas handles `event` itself (so the editor's shortcuts leave it alone).
    public func claimsKey(_ event: KeyEvent) -> Bool {
        let mods = event.modifiers
        let shortcut = mods.contains(.command) || mods.contains(.control)
        switch event.key {
        case .delete, .backspace, .escape, .left, .right, .up, .down, .leftBracket, .rightBracket: return true
        case .a, .c, .x, .v, .d: return shortcut && !mods.contains(.shift)
        default: return !shortcut && !mods.contains(.alt) && (Self.toolKeys[event.key] != nil || event.key == .h || event.key == .j)
        }
    }

    /// The canvas shortcuts: B pencil, L line, U rectangle (Shift+U toggles Filled), G fill,
    /// E eraser, I color picker, M select; H / J mirror X / Y; [ and ] previous / next color;
    /// Cmd/Ctrl+A select all, +C copy, +X cut, +V paste, +D or Esc deselect; Delete erases the
    /// selection; arrows nudge the selection (Shift: 8 pixels), or step frames (Left / Right) and
    /// layers (Up / Down) without one. Returns whether the key was used.
    @discardableResult
    public func handleKey(_ event: KeyEvent) -> Bool {
        guard claimsKey(event) else { return false }
        let mods = event.modifiers
        let shortcut = mods.contains(.command) || mods.contains(.control)
        let step = mods.contains(.shift) ? 8 : 1
        switch event.key {
        case .a where shortcut: selectAll()
        case .c where shortcut: copySelection()
        case .x where shortcut: cutSelection()
        case .v where shortcut: paste()
        case .d where shortcut: deselect()
        case .escape: deselect()
        case .delete, .backspace: deleteSelection()
        case .left, .right, .up, .down:
            let (dx, dy) = event.key == .left ? (-step, 0) : event.key == .right ? (step, 0) : event.key == .up ? (0, -step) : (0, step)
            if selection != nil {
                moveSelection(dx: dx, dy: dy)
            } else if dx != 0 {
                selectFrame((frame + (dx > 0 ? 1 : -1) + sprite.frames.count) % sprite.frames.count)
            } else {
                selectLayer(layer + (dy < 0 ? 1 : -1))
            }
        case .leftBracket, .rightBracket:
            let count = sprite.palette.count + 1
            selectColor(UInt8((Int(color) + (event.key == .rightBracket ? 1 : -1) + count) % count))
        case .h:
            if mirror.contains(.horizontal) { mirror.remove(.horizontal) } else { mirror.insert(.horizontal) }
            needsLayout = true
            onChanged?()
        case .j:
            if mirror.contains(.vertical) { mirror.remove(.vertical) } else { mirror.insert(.vertical) }
            needsLayout = true
            onChanged?()
        case .u where mods.contains(.shift):
            selectTool(.rect)
            filled.toggle()
        default:
            guard let tool = Self.toolKeys[event.key], !event.isRepeat else { return true }
            selectTool(tool)
        }
        return true
    }

    // MARK: Edits (one undo step each)

    /// A finished canvas stroke.
    public func applyStroke(_ tool: PixelTool, points: [PixelPoint]) {
        guard tool != .picker else { return }
        var edited = sprite
        edited.draw(tool, points: points, value: color, frame: frame, layer: layer, filled: filled, mirror: mirror)
        apply(edited, label: Self.title(tool))
    }

    /// Replaces the working copy and writes it on the next `refresh` (so no widget is torn down
    /// while it handles an event).
    public func apply(_ edited: PixelSprite, label: String) {
        var edited = edited
        edited.normalize()
        guard edited != sprite else { return }
        sprite = edited
        pending = (edited, label)
        onChanged?()
    }

    private func commit(_ edited: PixelSprite, label: String) {
        guard session.applyPixelSprite(edited, to: asset, label: label) != nil else { return }
        sprite = session.assets?.pixelSprite(of: asset) ?? edited
        clampSelection()
        layout()
        onChanged?()
    }

    private func edit(_ label: String, _ change: (inout PixelSprite) -> Void) {
        var copy = sprite
        change(&copy)
        apply(copy, label: label)
    }

    static func title(_ tool: PixelTool) -> String {
        switch tool {
        case .rect: "Rectangle"
        case .picker: "Color Picker"
        default: tool.rawValue.capitalized
        }
    }

    // MARK: Layout

    private func button(_ title: String, _ name: String, primary: Bool = false, tooltip: String, action: @escaping () -> Void) -> Button {
        let b = Button(title, role: primary ? .primary : .normal, name: name, action: action)
        b.tooltip = tooltip
        return b
    }

    private func layout() {
        needsLayout = false
        view.removeAllChildren()
        addTools()
        view.addChild(Separator())
        addPalette()
        view.addChild(Separator())
        addLayers()
        view.addChild(Separator())
        addFrames()
        view.addChild(Separator())
        addTags()
        view.addChild(Separator())
        addCanvasSettings()
        let note = Label("Every change is saved to the file. Use it with SpriteAssetLibrary (atlas + one SpriteAnimator clip per tag) "
                         + "or as a texture (sub-asset \"texture\"); frame i is cell i of the atlas grid.", role: .caption, name: "spriteNote")
        note.wraps = true
        view.addChild(note)
    }

    private func addTools() {
        view.addChild(Label("Tools", role: .secondary))
        let tools = HStack(spacing: 4, name: "spriteTools")
        tools.wraps = true
        for t in PixelTool.allCases {
            let b = button(Self.title(t), "spriteTool.\(t.rawValue)", primary: t == tool, tooltip: Self.tooltip(t) + " (\(Self.shortcutLabel(t)))") { [unowned self] in selectTool(t) }
            tools.addChild(b)
        }
        view.addChild(tools)
        let filledBox = Checkbox("Filled", isOn: filled, name: "spriteFilled") { [unowned self] on in filled = on }
        filledBox.tooltip = "The rectangle tool fills the rectangle (Shift+U)"
        let mirrorX = Checkbox("Mirror X", isOn: mirror.contains(.horizontal), name: "spriteMirrorX") { [unowned self] on in
            if on { mirror.insert(.horizontal) } else { mirror.remove(.horizontal) }
            onChanged?()
        }
        mirrorX.tooltip = "Also draw mirrored left-right (H)"
        let mirrorY = Checkbox("Mirror Y", isOn: mirror.contains(.vertical), name: "spriteMirrorY") { [unowned self] on in
            if on { mirror.insert(.vertical) } else { mirror.remove(.vertical) }
            onChanged?()
        }
        mirrorY.tooltip = "Also draw mirrored top-bottom (J)"
        let options = HStack(spacing: 8, [filledBox, mirrorX, mirrorY, Spacer()])
        options.wraps = true
        view.addChild(options)

        let mod = EditorShortcuts().shortcutModifier == .command ? "Cmd" : "Ctrl"
        let all = button("All", "spriteSelectAll", tooltip: "Select the whole canvas (\(mod)+A)") { [unowned self] in selectAll() }
        let copy = button("Copy", "spriteCopy", tooltip: "Copy the selected pixels of this cel, or the whole cel (\(mod)+C)") { [unowned self] in copySelection() }
        let cut = button("Cut", "spriteCut", tooltip: "Copy, then erase the selected pixels (\(mod)+X)") { [unowned self] in cutSelection() }
        let paste = button("Paste", "spritePaste", tooltip: "Paste into this cel at the selection, or where the pixels came from (\(mod)+V)") { [unowned self] in self.paste() }
        paste.isEnabled = Self.clipboard != nil
        let delete = button("Delete", "spriteDeleteSelection", tooltip: "Erase the selected pixels of this cel (Delete)") { [unowned self] in deleteSelection() }
        let none = button("Deselect", "spriteDeselect", tooltip: "Drop the selection (Esc or \(mod)+D)") { [unowned self] in deselect() }
        none.isEnabled = selection != nil
        let text = selection.map { "\($0.width) x \($0.height) at \($0.x), \($0.y)" } ?? "No selection"
        let row = HStack(spacing: 4, name: "spriteSelectionRow", [all, copy, cut, paste, delete, none])
        row.wraps = true
        view.addChild(row)
        view.addChild(Label(text, role: .caption, name: "spriteSelectionInfo"))
    }

    static func tooltip(_ tool: PixelTool) -> String {
        switch tool {
        case .pencil: "Draw pixels (right-drag erases with any tool)"
        case .line: "Drag a straight line"
        case .rect: "Drag a rectangle (outline, or filled with Filled)"
        case .fill: "Fill the area of one color on this layer"
        case .eraser: "Erase pixels"
        case .picker: "Pick the color under the pointer (or Alt+click with any tool)"
        case .select: "Drag to select pixels; drag the selection to move it (Cmd/Ctrl+drag copies). Copy, cut and paste between frames and layers"
        }
    }

    private func addPalette() {
        view.addChild(Label("Palette", role: .secondary))
        palette.colors = sprite.palette
        palette.selected = color
        view.addChild(palette)
        let selected = color == 0 ? "transparent" : "\(sprite.palette[Int(color) - 1]) (\"\(PixelSprite.character(for: color))\")"
        let swatch = ColorSwatch(color: color == 0 ? .clear : sprite.palette[Int(color) - 1].uiColor, name: "spriteColor")
        swatch.isEnabled = color != 0
        swatch.tooltip = "Edit the selected palette color (every pixel using it changes)"
        swatch.onEditEnded = { [unowned self] _, end in
            guard color != 0 else { return }
            let index = Int(color) - 1
            edit("Edit Color") { $0.palette[index] = PixelColor(end) }
        }
        let add = button("Add", "spriteAddColor", tooltip: "Add a color to the palette (a copy of the selected one) and select it") { [unowned self] in
            guard sprite.palette.count < PixelSprite.maxColors else { return }
            let base = color == 0 ? PixelColor(255, 255, 255) : sprite.palette[Int(color) - 1]
            var copy = sprite
            copy.palette.append(base)
            color = UInt8(copy.palette.count)
            remember()
            apply(copy, label: "Add Color")
        }
        let remove = button("Remove", "spriteRemoveColor", tooltip: "Remove the selected color; its pixels become transparent") { [unowned self] in
            guard color != 0 else { return }
            let index = Int(color) - 1
            color = 0
            edit("Remove Color") { $0.removeColor(index) }
        }
        remove.isEnabled = color != 0
        view.addChild(HStack(spacing: 6, [swatch, Label(selected, role: .caption), Spacer(), add, remove]))
        let presets = Dropdown(options: ["Load preset…"] + PixelPalette.allCases.map { "\($0.rawValue) (\($0.colors.count))" }, name: "spritePalettePreset")
        presets.tooltip = "Replace the palette with a preset (pixels keep their palette indices)"
        presets.onChange = { [unowned self] i in
            guard i > 0 else { return }
            let preset = PixelPalette.allCases[i - 1]
            edit("\(preset.rawValue) Palette") { $0.palette = preset.colors }
        }
        view.addChild(presets)
    }

    private func addLayers() {
        view.addChild(Label("Layers", role: .secondary))
        layerList.items = sprite.layers.reversed().map { ($0.visible ? "" : "(hidden) ") + $0.name + ($0.blend == .normal ? "" : "  (\($0.blend.rawValue))") }
        layerList.selectRow(sprite.layers.count - 1 - layer, reveal: true)
        view.addChild(layerList)
        let add = button("Add", "spriteAddLayer", tooltip: "Add an empty layer above the selected one") { [unowned self] in
            var copy = sprite
            layer = copy.insertLayer(at: layer + 1)
            remember()
            apply(copy, label: "Add Layer")
        }
        let remove = button("Remove", "spriteRemoveLayer", tooltip: "Delete the selected layer") { [unowned self] in
            let index = layer
            edit("Remove Layer") { $0.removeLayer(index) }
        }
        remove.isEnabled = sprite.layers.count > 1
        let up = button("Up", "spriteLayerUp", tooltip: "Move the layer up (in front)") { [unowned self] in
            let index = layer
            guard index + 1 < sprite.layers.count else { return }
            layer = index + 1
            edit("Move Layer") { $0.moveLayer(index, to: index + 1) }
        }
        let down = button("Down", "spriteLayerDown", tooltip: "Move the layer down (behind)") { [unowned self] in
            let index = layer
            guard index > 0 else { return }
            layer = index - 1
            edit("Move Layer") { $0.moveLayer(index, to: index - 1) }
        }
        view.addChild(HStack(spacing: 4, [add, remove, up, down, Spacer()]))

        let current = sprite.layers[layer]
        let name = TextField(text: current.name, placeholder: "Layer name", name: "spriteLayerName")
        name.preferredWidth = 110
        let rename: (String) -> Void = { [unowned self] text in
            let index = layer
            let text = text.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty, text != sprite.layers[index].name, sprite.layerIndex(named: text) == nil else { return }
            edit("Rename Layer") { $0.layers[index].name = text }
        }
        name.onSubmit = rename
        name.onEndEditing = rename
        let visible = Checkbox("Visible", isOn: current.visible, name: "spriteLayerVisible") { [unowned self] on in
            let index = layer
            edit(on ? "Show Layer" : "Hide Layer") { $0.layers[index].visible = on }
        }
        let opacity = NumberField(value: Double(current.opacity), range: 0...1, step: 0.05, name: "spriteLayerOpacity")
        opacity.preferredWidth = 52
        opacity.tooltip = "Layer opacity"
        opacity.onEditEnded = { [unowned self] _, end in
            let index = layer
            edit("Layer Opacity") { $0.layers[index].opacity = Float(min(max(end, 0), 1)) }
        }
        let modes = PixelSprite.BlendMode.allCases
        let blend = Dropdown(options: modes.map(\.rawValue), selectedIndex: modes.firstIndex(of: current.blend) ?? 0, name: "spriteLayerBlend")
        blend.tooltip = "How this layer mixes with the layers below: multiply darkens, add and screen brighten, overlay adds contrast"
        blend.onChange = { [unowned self] i in
            let index = layer
            edit("Layer Blend Mode") { $0.layers[index].blend = modes[i] }
        }
        let row = HStack(spacing: 6, [name, visible, opacity, blend])
        row.wraps = true
        view.addChild(row)
    }

    private func addFrames() {
        view.addChild(Label("Frames", role: .secondary))
        let previous = button("<", "spritePrevFrame", tooltip: "Previous frame") { [unowned self] in
            selectFrame((frame - 1 + sprite.frames.count) % sprite.frames.count)
        }
        let next = button(">", "spriteNextFrame", tooltip: "Next frame") { [unowned self] in selectFrame((frame + 1) % sprite.frames.count) }
        let label = Label("Frame \(frame + 1) of \(sprite.frames.count)", name: "spriteFrameLabel")
        let duration = NumberField(value: Double(sprite.frames[frame].duration), isInteger: true, range: 1...10_000, step: 10, name: "spriteFrameDuration")
        duration.preferredWidth = 60
        duration.tooltip = "How long this frame shows, in milliseconds"
        duration.onEditEnded = { [unowned self] _, end in
            let index = frame
            edit("Frame Duration") { $0.frames[index].duration = max(Int(end.rounded()), 1) }
        }
        view.addChild(HStack(spacing: 6, [previous, label, next, Spacer(), duration, Label("ms", role: .caption)]))
        let add = button("Add", "spriteAddFrame", tooltip: "Add a blank frame after this one") { [unowned self] in
            let at = frame + 1
            frame = at
            remember()
            edit("Add Frame") { $0.insertFrames(1, at: at) }
        }
        let duplicate = button("Duplicate", "spriteDuplicateFrame", tooltip: "Copy this frame after it") { [unowned self] in
            let source = frame
            frame = source + 1
            remember()
            edit("Duplicate Frame") { $0.insertFrames(1, at: source + 1, copyOf: source) }
        }
        let remove = button("Remove", "spriteRemoveFrame", tooltip: "Delete this frame") { [unowned self] in
            let index = frame
            frame = max(index - 1, 0)
            edit("Remove Frame") { $0.removeFrames([index]) }
        }
        remove.isEnabled = sprite.frames.count > 1
        let left = button("Move <", "spriteMoveFrameLeft", tooltip: "Move this frame earlier") { [unowned self] in
            let index = frame
            guard index > 0 else { return }
            frame = index - 1
            edit("Move Frame") { $0.moveFrame(index, to: index - 1) }
        }
        let right = button("Move >", "spriteMoveFrameRight", tooltip: "Move this frame later") { [unowned self] in
            let index = frame
            guard index + 1 < sprite.frames.count else { return }
            frame = index + 1
            edit("Move Frame") { $0.moveFrame(index, to: index + 1) }
        }
        let row = HStack(spacing: 4, [add, duplicate, remove, left, right])
        row.wraps = true
        view.addChild(row)
        let onion = Checkbox("Onion skin", isOn: onionSkin, name: "spriteOnionSkin") { [unowned self] on in
            onionSkin = on
            onChanged?()
        }
        onion.tooltip = "Show the previous frame (red) and the next (blue) faintly behind this one"
        let clear = button("Clear Cel", "spriteClearCel", tooltip: "Erase this layer in this frame") { [unowned self] in
            let (f, l) = (frame, layer)
            edit("Clear Cel") { $0.clearCel(frame: f, layer: l) }
        }
        let flip = button("Flip", "spriteFlipFrame", tooltip: "Mirror this frame left-right (all layers)") { [unowned self] in
            let f = frame
            edit("Flip Frame") { $0.flip(frame: f, horizontal: true) }
        }
        view.addChild(HStack(spacing: 6, [onion, Spacer(), flip, clear]))
    }

    private func addTags() {
        view.addChild(Label("Tags (animation clips)", role: .secondary))
        tagList.items = sprite.tags.map { "\($0.name)  \($0.from)-\($0.to)  \($0.mode.rawValue)" + ($0.events.isEmpty ? "" : "  \($0.events.count) event\($0.events.count == 1 ? "" : "s")") }
        if let selectedTag { tagList.selectRow(selectedTag, reveal: true) }
        view.addChild(tagList)
        let add = button("Add Tag", "spriteAddTag", tooltip: "Tag this frame as a new clip (edit its range below)") { [unowned self] in
            var n = sprite.tags.count + 1
            while sprite.tags.contains(where: { $0.name == "clip\(n)" }) { n += 1 }
            let tag = PixelSprite.Tag("clip\(n)", from: frame, to: frame)
            selectedTag = sprite.tags.count
            remember()
            edit("Add Tag") { $0.tags.append(tag) }
        }
        let remove = button("Remove", "spriteRemoveTag", tooltip: "Delete the selected tag") { [unowned self] in
            guard let t = selectedTag else { return }
            selectedTag = nil
            edit("Remove Tag") { $0.tags.remove(at: t) }
        }
        remove.isEnabled = selectedTag != nil
        view.addChild(HStack(spacing: 4, [add, remove, Spacer()]))
        guard let t = selectedTag, sprite.tags.indices.contains(t) else { return }
        let tag = sprite.tags[t]
        let name = TextField(text: tag.name, placeholder: "Clip name", name: "spriteTagName")
        name.preferredWidth = 90
        let rename: (String) -> Void = { [unowned self] text in
            let text = text.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty, text != sprite.tags[t].name else { return }
            edit("Rename Tag") { $0.tags[t].name = text }
        }
        name.onSubmit = rename
        name.onEndEditing = rename
        let last = Double(sprite.frames.count - 1)
        let from = NumberField(value: Double(tag.from), isInteger: true, range: 0...last, step: 1, name: "spriteTagFrom")
        from.preferredWidth = 44
        from.tooltip = "First frame"
        from.onEditEnded = { [unowned self] _, end in edit("Tag Range") { $0.tags[t].from = Int(end.rounded()); $0.tags[t].to = max($0.tags[t].to, $0.tags[t].from) } }
        let to = NumberField(value: Double(tag.to), isInteger: true, range: 0...last, step: 1, name: "spriteTagTo")
        to.preferredWidth = 44
        to.tooltip = "Last frame"
        to.onEditEnded = { [unowned self] _, end in edit("Tag Range") { $0.tags[t].to = Int(end.rounded()); $0.tags[t].from = min($0.tags[t].from, $0.tags[t].to) } }
        let modes = PixelSprite.TagMode.allCases
        let mode = Dropdown(options: modes.map(\.rawValue), selectedIndex: modes.firstIndex(of: tag.mode) ?? 0, name: "spriteTagMode")
        mode.onChange = { [unowned self] i in edit("Tag Mode") { $0.tags[t].mode = modes[i] } }
        let row = HStack(spacing: 4, [name, from, to, mode])
        row.wraps = true
        view.addChild(row)
        addTagEvents(t)
    }

    /// The selected tag's frame events: one row each (go to the frame, remove), then a name field
    /// and a button adding an event on the current frame.
    private func addTagEvents(_ t: Int) {
        let tag = sprite.tags[t]
        for (e, event) in tag.events.enumerated() {
            let go = button("Frame \(event.frame)", "spriteEventFrame\(e)", tooltip: "Show this frame") { [unowned self] in selectFrame(event.frame) }
            let label = Label(event.name, name: "spriteEventName\(e)")
            let remove = button("Remove", "spriteRemoveEvent\(e)", tooltip: "Delete this event") { [unowned self] in
                edit("Remove Frame Event") { $0.tags[t].events.removeAll { $0 == event } }
            }
            view.addChild(HStack(spacing: 4, [go, label, Spacer(), remove]))
        }
        let inRange = frame >= tag.from && frame <= tag.to
        let field = TextField(text: "", placeholder: "Event name", name: "spriteEventNewName")
        field.preferredWidth = 90
        let addEvent: (String) -> Void = { [unowned self] text in
            let text = text.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty, frame >= sprite.tags[t].from, frame <= sprite.tags[t].to else { return }
            let event = PixelSprite.FrameEvent(frame: frame, name: text)
            guard !sprite.tags[t].events.contains(event) else { return }
            edit("Add Frame Event") {
                $0.tags[t].events.append(event)
                $0.tags[t].events.sort { $0.frame < $1.frame }
            }
        }
        field.onSubmit = addEvent
        field.isEnabled = inRange
        let add = button("Add Event", "spriteAddEvent",
                         tooltip: inRange ? "Fire this event when the clip reaches frame \(frame) (SpriteAnimator.events)"
                                          : "Go to a frame inside the tag to add an event on it") { [unowned self] in addEvent(field.text) }
        add.isEnabled = inRange
        let row = HStack(spacing: 4, name: "spriteEventRow", [field, add, Spacer()])
        row.wraps = true
        view.addChild(row)
    }

    private func addCanvasSettings() {
        view.addChild(Label("Canvas", role: .secondary))
        let width = NumberField(value: Double(sprite.width), isInteger: true, range: 1...Double(PixelSprite.maxSize), step: 1, name: "spriteWidth")
        width.preferredWidth = 52
        width.prefix = "W"
        width.onEditEnded = { [unowned self] _, end in apply(sprite.resized(width: Int(end.rounded()), height: sprite.height), label: "Resize Canvas") }
        let height = NumberField(value: Double(sprite.height), isInteger: true, range: 1...Double(PixelSprite.maxSize), step: 1, name: "spriteHeight")
        height.preferredWidth = 52
        height.prefix = "H"
        height.onEditEnded = { [unowned self] _, end in apply(sprite.resized(width: sprite.width, height: Int(end.rounded())), label: "Resize Canvas") }
        let ppu = NumberField(value: Double(sprite.pixelsPerUnit), range: 0.01...10_000, step: 1, name: "spritePixelsPerUnit")
        ppu.preferredWidth = 52
        ppu.tooltip = "Pixels per world unit when drawn as a sprite"
        ppu.onEditEnded = { [unowned self] _, end in edit("Pixels per Unit") { $0.pixelsPerUnit = Float(max(end, 0.01)) } }
        let row = HStack(spacing: 6, [width, height, Label("px/unit", role: .caption), ppu, Spacer()])
        row.wraps = true
        view.addChild(row)
    }
}

/// The Pixel Sprite Builder tab for one `.sprite` file.
@MainActor
public final class PixelSpriteWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    /// The sprite being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    public private(set) var builder: PixelSpriteBuilderView?
    public let canvas = PixelCanvasView()
    public let preview = PixelSpritePreviewView()

    private let title = Label("Pixel Sprite Builder", role: .heading, name: "spriteBuilderTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "spriteBuilderSidebar")
    private let previewBox = VStack(spacing: 4, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "spriteBuilderPreviewBox")
    private let playButton = Button("Pause", name: "spriteBuilderPlay")
    private var shownRevision = -1

    public init(session: EditorSession) {
        self.session = session
        view = VStack(spacing: 0, name: "spriteBuilderWorkspace")
        layOutChrome()
        showEmpty()
    }

    /// Shows `id` (a `.sprite` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isPixelSpriteFile(id) else { return false }
        if asset != id {
            guard let builder = PixelSpriteBuilderView(session: session, asset: id) else { return false }
            asset = id
            self.builder = builder
            builder.onChanged = { [unowned self] in changed() }
            canvas.builder = builder
            canvas.zoom = 1
            canvas.pan = .zero
            preview.builder = builder
            shownRevision = -1
            sidebar.removeAllChildren()
            sidebar.addChild(builder.view)
            previewBox.isHidden = false
            changed()
        }
        title.text = session.assets?.record(id)?.fileName ?? "Pixel Sprite Builder"
        title.icon = EditorIcons.asset(.texture)
        return true
    }

    /// Closes the file (the panel shows how to open one).
    public func close() {
        asset = nil
        builder = nil
        canvas.builder = nil
        preview.builder = nil
        canvas.invalidate()
        showEmpty()
    }

    private func changed() {
        canvas.invalidate()
        preview.invalidate()
        preview.clipName = builder.flatMap { b in b.selectedTag.flatMap { b.sprite.tags.indices.contains($0) ? b.sprite.tags[$0].name : nil } }
    }

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "spriteBuilderToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        let fit = Button("Fit", name: "spriteBuilderFit") { [unowned self] in
            canvas.zoom = 1
            canvas.pan = .zero
        }
        fit.tooltip = "Fit the canvas in the view (the wheel zooms, middle-drag pans)"
        bar.addChild(fit)
        let closeButton = Button("Close", name: "spriteBuilderClose") { [unowned self] in self.close() }
        closeButton.tooltip = "Stop editing this sprite"
        bar.addChild(closeButton)

        playButton.action = { [unowned self] in
            preview.isPlaying.toggle()
            playButton.title = preview.isPlaying ? "Pause" : "Play"
        }
        playButton.tooltip = "Play or pause the animation preview (the selected tag, or every frame)"
        previewBox.addChildren([HStack(spacing: 6, [Label("Preview", role: .secondary), Spacer(), playButton]), preview])

        canvas.style.grow = 1
        canvas.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "spriteBuilderSidebarScroll")
        scroll.style.grow = 1
        scroll.style.shrink = 1
        let side = VStack(spacing: 0, name: "spriteBuilderSide", [previewBox, Separator(), scroll])
        side.style.width = 350
        let body = HStack(spacing: 0, alignment: .stretch, name: "spriteBuilderBody", [canvas, Separator(.vertical), side])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Pixel Sprite Builder"
        title.icon = EditorIcons.asset(.texture)
        previewBox.isHidden = true
        sidebar.removeAllChildren()
        let note = Label("Double-click a .sprite file in the Assets panel to draw it here, or make one with the Assets panel's "
                         + "New Sprite (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New Sprite", role: .primary, name: "spriteBuilderNew") { [unowned self] in
            if let id = session.run(PixelSpriteNewCommand.self, .init())?.asset { session.run(PixelSpriteOpenCommand.self, .init(asset: AssetReference(id))) }
        }
        new.command = PixelSpriteNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
    }

    /// Writes the pending edit, follows changes to the file (undo, MCP, other panels) and advances
    /// the preview. Call every frame.
    public func update(dt: Float = 0) {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        builder?.refresh()
        let revision = assets.revision(of: asset)
        if revision != shownRevision {
            if shownRevision >= 0, builder?.hasPendingEdit == false { builder?.reload() }
            shownRevision = revision
            changed()
        }
        preview.advance(dt: dt)
    }
}
