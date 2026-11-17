import EditorCore
import Engine
import Foundation

// The Mesh Builder's rows for plants (MeshBuildFoliage.swift, MeshBuildRibbon.swift): a foliage
// part's leaf look, card size, density or exact count, seed and the parts it grows on; a sweep's
// ribbon width and open profile; and a leaf look on ribbons and planes. Each edit is one undo step.

extension MeshBuilderView {
    /// A new foliage part: a broadleaf crown about 1.6 m across.
    static func applyFoliageStarter(to part: inout MeshBuildPart) {
        guard part.shape == .foliage else { return }
        part.look = MeshBuildLeafLook.broadleaf.rawValue
        part.size = Vec3(1.6, 1.2, 1.6)
    }

    /// The leaf look picker's options: "None" (or the default for foliage) then every leaf look's title.
    static var leafLookOptions: [String] { ["None"] + MeshBuildLeafLook.allCases.map(\.title) }

    func addFoliageSection(for part: MeshBuildPart) {
        let name = part.name
        let leafy = part.shape == .foliage || part.shape == .plane || part.isRibbon
        if leafy {
            view.addChild(Separator())
            view.addChild(Label(part.shape == .foliage ? "Foliage" : "Leaf look", role: .secondary))
            let current = part.leafLook.flatMap { MeshBuildLeafLook.allCases.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
            var options = Self.leafLookOptions
            if part.shape == .foliage { options[0] = "Default (broadleaf)" }
            let picker = Dropdown(options: options, selectedIndex: current, name: "meshBuildLeafLook") { [unowned self] index in
                editPart(name, label: "Leaf Look") { p in p.look = index == 0 ? nil : MeshBuildLeafLook.allCases[index - 1].rawValue }
            }
            picker.command = MeshBuildEditCommand.id.rawValue
            picker.tooltip = "Leaves cut out of a generated picture (double-sided, shadows cut out too); the part's color tints them"
            picker.style.grow = 1
            view.addChild(HStack(spacing: 6, [rowLabel("Leaves"), picker]))
        }
        if part.shape == .foliage { addFoliageRows(part) }
        if part.shape == .sweep { addRibbonRows(part) }
    }

    private func addFoliageRows(_ part: MeshBuildPart) {
        let name = part.name
        let look = part.resolvedLeafLook ?? .broadleaf
        func number(_ title: String, _ value: Double, step: Double, range: ClosedRange<Double>, field: String, tooltip: String,
                    _ commit: @escaping (Double) -> Void) {
            let box = NumberField(value: value, range: range, step: step, name: field)
            box.precision = 2
            box.style.grow = 1
            box.tooltip = tooltip
            box.onEditEnded = { start, end in if start != end { commit(end) } }
            view.addChild(HStack(spacing: 6, [rowLabel(title), box]))
        }
        number("Card size (m)", Double(part.effectiveCardSize), step: 0.05, range: 0.01...10, field: "meshBuildCardSize",
               tooltip: "A leaf card's side (default \(look.defaultCardSize) m for \(look.title.lowercased()))") { [unowned self] v in
            editPart(name, label: "Card Size") { p in p.cardSize = abs(Float(v) - look.defaultCardSize) < 1e-4 ? nil : Float(v) }
        }
        number("Density", Double(part.density ?? 1), step: 0.1, range: 0.05...8, field: "meshBuildDensity",
               tooltip: "How thickly the cards cover: 1 is a full canopy, 0.5 sparse (ignored when Count is set)") { [unowned self] v in
            editPart(name, label: "Foliage Density") { p in p.density = abs(v - 1) < 1e-4 ? nil : Float(v) }
        }
        number("Count", Double(part.count ?? 0), step: 10, range: 0...100_000, field: "meshBuildCardCount",
               tooltip: "Exactly this many cards (0: from the density); each is 2 triangles, an upright tuft 4") { [unowned self] v in
            editPart(name, label: "Foliage Count") { p in p.count = v < 0.5 ? nil : Int(v.rounded()) }
        }
        number("Seed", Double(part.seed ?? 0), step: 1, range: -1_000_000...1_000_000, field: "meshBuildFoliageSeed",
               tooltip: "Another seed scatters the cards differently") { [unowned self] v in
            editPart(name, label: "Foliage Seed") { p in p.seed = v == 0 ? nil : Int(v.rounded()) }
        }
        let on = TextField(text: (part.on ?? []).joined(separator: ", "), placeholder: "Part names, or empty for the size's volume",
                           name: "meshBuildFoliageOn")
        on.style.grow = 1
        on.tooltip = "Grow along these sweeps' outer parts (or over these parts' surfaces) instead of filling the size's volume"
        on.onEndEditing = { [unowned self] text in
            let names = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            editPart(name, label: "Foliage Targets") { p in p.on = names.isEmpty ? nil : names }
        }
        view.addChild(HStack(spacing: 6, [rowLabel("Grows on"), on]))
        if !(part.on ?? []).isEmpty {
            let along = part.foliageAlong
            number("From (0-1)", Double(along.x), step: 0.05, range: 0...0.99, field: "meshBuildFoliageFrom",
                   tooltip: "Where along the branches the leaves start (a fraction of their length)") { [unowned self] v in
                editPart(name, label: "Foliage Range") { p in
                    let to = p.foliageAlong.y
                    let range = Vec2(min(Float(v), to - 0.01), to)
                    p.along = range == MeshBuildPart.defaultFoliageAlong ? nil : range
                }
            }
        }
        let geometry = part.geometry()
        let triangles = (geometry?.indices.count ?? 0) / 3
        view.addChild(note(part.on.map { _ in "\(triangles) triangles (the leaves follow the parts they grow on)" }
                           ?? "\(triangles) triangles"))
    }

    private func addRibbonRows(_ part: MeshBuildPart) {
        let name = part.name
        view.addChild(Separator())
        view.addChild(Label("Ribbon", role: .secondary))
        let width = NumberField(value: Double(part.ribbon ?? 0), range: 0...100, step: 0.01, name: "meshBuildRibbonWidth")
        width.precision = 3
        width.style.grow = 1
        width.tooltip = "Draw the sweep as a flat, double-sided strip this wide (m) instead of a tube (0: a tube)"
        width.onEditEnded = { [unowned self] start, end in
            guard start != end else { return }
            editPart(name, label: "Ribbon Width") { p in p.ribbon = end > 0 ? Float(end) : nil }
        }
        view.addChild(HStack(spacing: 6, [rowLabel("Width (m)"), width]))
        let open = Checkbox("Open profile (a curved strip)", isOn: part.open ?? false, name: "meshBuildSweepOpen") { [unowned self] on in
            editPart(name, label: "Open Profile") { p in p.open = on ? true : nil }
        }
        open.tooltip = "The profile is an open curve (left to right), drawn double-sided without caps: a folded leaf, a sail section"
        view.addChild(open)
    }
}
