import Engine
import Foundation

// The Mesh Builder's Look rows: a look picker (a dropdown plus a palette of swatches in each
// look's own average color), a wear slider, the look's tile size and grain direction; and the
// model's baked ambient occlusion switch.

extension MeshBuilderView {
    /// The look picker's options: "None" then every look's title.
    static var lookOptions: [String] { ["None"] + MeshBuildLook.allCases.map(\.title) }

    func addLookSection(for part: MeshBuildPart) {
        guard part.shape != .group else { return }
        let name = part.name
        view.addChild(Separator())
        view.addChild(Label("Look", role: .secondary))
        let current = part.resolvedLook
        let selected = current.flatMap { MeshBuildLook.allCases.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
        let picker = Dropdown(options: Self.lookOptions, selectedIndex: selected, name: "meshBuildLook") { [unowned self] index in
            editPart(name, label: "Part Look") { p in p.look = index == 0 ? nil : MeshBuildLook.allCases[index - 1].rawValue }
        }
        picker.command = MeshBuildEditCommand.id.rawValue
        picker.tooltip = "A realistic surface from generated textures; the part's color tints it (keep the default color for the look's own)"
        picker.style.grow = 1
        view.addChild(HStack(spacing: 6, [rowLabel("Look"), picker]))

        let palette = HStack(spacing: 3, name: "meshBuildLookSwatches")
        palette.wraps = true
        for look in MeshBuildLook.allCases {
            let chip = MeshBuildLookSwatch(look: look, isSelected: look == current, name: "meshBuildLookSwatch.\(look.rawValue)") {
                [unowned self] in editPart(name, label: "Part Look") { p in p.look = look.rawValue }
            }
            palette.addChild(chip)
        }
        view.addChild(palette)
        if let look = part.look, current == nil, !look.trimmingCharacters(in: .whitespaces).isEmpty {
            view.addChild(note("Unknown look '\(look)'. Pick one above."))
        }
        guard let look = current else { return }

        // Wear.
        let wear = min(max(part.wear ?? 0, 0), 1)
        let caption = Label(String(format: "%.2f", wear), role: .caption, name: "meshBuildWearValue")
        let slider = Slider(value: wear, in: 0...1, step: 0, name: "meshBuildWear")
        slider.style.grow = 1
        slider.tooltip = "Grime in low spots, scratches, chipped paint and darker creases"
        slider.accessibilityLabel = "Wear"
        var dragging = false
        let commit: (Float) -> Void = { [unowned self] v in
            editPart(name, label: "Part Wear") { $0.wear = v > 0.001 ? (v * 100).rounded() / 100 : nil }
        }
        slider.onEditBegan = { dragging = true }
        slider.onChange = { v in
            caption.text = String(format: "%.2f", v)
            if !dragging { commit(v) }
        }
        slider.onEditEnded = { [unowned slider] in
            dragging = false
            commit(slider.value)
        }
        view.addChild(HStack(spacing: 6, [rowLabel("Wear"), slider, caption]))

        // Tile size.
        let scale = NumberField(value: Double(part.lookScale ?? look.defaultScale), range: 0.01...100, step: 0.05,
                                name: "meshBuildLookScale")
        scale.tooltip = "Meters one texture tile covers (default \(look.defaultScale) m for \(look.title.lowercased()))"
        scale.onEditEnded = { [unowned self] _, end in
            editPart(name, label: "Look Scale") { p in
                let v = Float(end)
                p.lookScale = abs(v - look.defaultScale) < 1e-4 ? nil : v
            }
        }
        scale.style.grow = 1
        view.addChild(HStack(spacing: 6, [rowLabel("Look scale (m)"), scale]))

        // Grain.
        let grainOptions = ["Auto", "Along X", "Along Y", "Along Z"]
        let grain = Dropdown(options: grainOptions, selectedIndex: part.grain.map { $0.index + 1 } ?? 0, name: "meshBuildGrain") {
            [unowned self] index in editPart(name, label: "Look Grain") { p in p.grain = index == 0 ? nil : MeshBuildAxis.allCases[index - 1] }
        }
        grain.tooltip = "The part axis the grain, brushing or planks run along (Auto: Y for round shapes, else the longest side)"
        grain.style.grow = 1
        view.addChild(HStack(spacing: 6, [rowLabel("Grain"), grain]))
    }

    /// The model-wide switch for baked ambient occlusion.
    func addOcclusionToggle() {
        let box = Checkbox("Ambient occlusion", isOn: build.ao ?? true, name: "meshBuildAO") { [unowned self] on in
            var edited = build
            edited.ao = on ? nil : false
            guard edited != build else { return }
            apply(edited, label: on ? "Bake Occlusion" : "No Occlusion", select: selectedPart)
        }
        box.command = MeshBuildEditCommand.id.rawValue
        box.tooltip = "Darken the model where its parts meet (baked into the meshes when it imports)"
        view.addChild(HStack(spacing: 6, [box, Spacer()]))
    }
}

/// A small square in a look's average color; clicking it picks the look.
final class MeshBuildLookSwatch: Widget {
    let look: MeshBuildLook
    let isSelected: Bool
    let onPick: () -> Void
    private let color: UIColor

    init(look: MeshBuildLook, isSelected: Bool, name: String, onPick: @escaping () -> Void) {
        self.look = look
        self.isSelected = isSelected
        self.onPick = onPick
        let average = MeshBuildLookTextures.average(look).color
        color = UIColor(linearRGB: look == .glass ? Vec3(0.55, 0.65, 0.7) : average)
        super.init(name: name)
        tooltip = look.title
        accessibilityLabel = look.title
    }

    override var acceptsFocus: Bool { true }
    override var accessibilityRole: UIAccessibilityRole { .button }

    override func measureContent(width: Float?) -> Vec2 { Vec2(18, 18) }

    override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            return true
        case .pointerUp(let e):
            if frame.contains(e.position) { onPick() }
            return true
        case .key(let e) where (e.key == .enter || e.key == .space) && !e.isRepeat && e.modifiers.isEmpty:
            onPick()
            return true
        default:
            return false
        }
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        let radii = UICornerRadii(3)
        list.fillRect(frame, color: color, radii: radii)
        // A darker lower half hints at the look's relief and metalness.
        let lower = UIRect(x: frame.x, y: frame.y + frame.height * 0.55, width: frame.width, height: frame.height * 0.45)
        list.fillRect(lower, color: UIColor.black.withAlpha(look.isMetal ? 0.28 : 0.14),
                      radii: UICornerRadii(0))
        list.strokeRect(frame, color: isSelected ? theme.accent : isHovered ? theme.controlBorder.mixed(with: .white, 0.3)
                        : theme.controlBorder, width: isSelected ? theme.borderWidth + 1 : theme.borderWidth, radii: radii)
    }
}
