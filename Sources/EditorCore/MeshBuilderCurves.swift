import Engine
import Foundation

// The Mesh Builder's rows for curved and deformed parts: a sweep's path points (x, y, z and the
// section's size there), radius, Closed and Smooth; a loft's axis and sections (position along
// the axis, size, roundness); and every mesh part's deformers (taper, bend, twist, noise) with
// the subdivision level. Each edit is one undo step, like the rest of the form.

extension MeshBuilderView {
    /// A new sweep's path: a pipe rising from the ground and curving over to the right (meters).
    static let starterSweepPath: [Vec3] = [Vec3(0, 0, 0), Vec3(0, 0.35, 0), Vec3(0.12, 0.56, 0), Vec3(0.45, 0.62, 0)]
    static let starterSweepRadius: Float = 0.04
    /// A new loft's sections: a flat flask (wider than deep, rounded-box body, round neck).
    static let starterLoftSections: [MeshBuildSection] = [
        MeshBuildSection(at: 0, size: Vec2(0.3, 0.14), roundness: 2.5),
        MeshBuildSection(at: 0.26, size: Vec2(0.32, 0.16), roundness: 2.5),
        MeshBuildSection(at: 0.36, size: Vec2(0.1, 0.08), roundness: 1.5),
        MeshBuildSection(at: 0.42, size: Vec2(0.07, 0.07)),
        MeshBuildSection(at: 0.5, size: Vec2(0.075, 0.075)),
    ]

    /// Gives a new part of a curve shape its starting path or sections.
    static func applyCurveStarter(to part: inout MeshBuildPart) {
        switch part.shape {
        case .sweep:
            part.path = starterSweepPath
            part.radius = starterSweepRadius
        case .loft:
            part.sections = starterLoftSections
        default: break
        }
    }

    // MARK: Sweep and loft

    /// The path rows of a sweep or the section rows of a loft (nothing for other shapes).
    func addCurveSection(for part: MeshBuildPart) {
        if part.shape == .sweep { addSweepRows(part) }
        if part.shape == .loft { addLoftRows(part) }
    }

    private func addSweepRows(_ part: MeshBuildPart) {
        let name = part.name
        let path = part.path ?? []
        view.addChild(Separator())
        view.addChild(Label("Path: x, y, z (m) and the section's size there (×)", role: .secondary))
        for (i, point) in path.enumerated() {
            let index = Label("\(i + 1)", role: .caption)
            index.style.width = 24
            var fields: [Widget] = [index]
            for axis in 0..<3 {
                fields.append(numberField(Double(point[axis]), step: 0.01, prefix: ["x", "y", "z"][axis], name: "meshBuildPath.\(i).\(axis)") {
                    [unowned self] value in
                    updatePart(name, label: "Edit Path") { p in
                        guard var path = p.path, path.indices.contains(i) else { return }
                        path[i][axis] = Float(value)
                        p.path = path
                    }
                })
            }
            let k = part.radii.flatMap { i < $0.count ? $0[i] : nil } ?? 1
            let scale = numberField(Double(k), step: 0.05, prefix: "×", name: "meshBuildPathRadius.\(i)") { [unowned self] value in
                updatePart(name, label: "Edit Path") { p in
                    let count = p.path?.count ?? 0
                    var radii = (p.radii ?? []) + Array(repeating: 1, count: max(count - (p.radii?.count ?? 0), 0))
                    guard radii.indices.contains(i) else { return }
                    radii[i] = max(Float(value), 0)
                    p.radii = radii.allSatisfy { $0 == 1 } ? nil : radii
                }
            }
            scale.tooltip = "The section's size at this point (1: full, 0: a point), for tapering branches and horns"
            fields.append(scale)
            let remove = Button("Remove", name: "meshBuildPathRemove.\(i)") { [unowned self] in
                updatePart(name, label: "Remove Path Point") { p in
                    guard var path = p.path, path.indices.contains(i) else { return }
                    path.remove(at: i)
                    p.path = path
                    if var radii = p.radii, radii.indices.contains(i) { radii.remove(at: i); p.radii = radii }
                }
            }
            remove.command = MeshBuildEditCommand.id.rawValue
            remove.isEnabled = path.count > 2
            remove.tooltip = "Remove this point (a sweep keeps at least 2)"
            fields.append(remove)
            view.addChild(HStack(spacing: 4, fields))
        }
        let add = Button("Add Point", name: "meshBuildPathAdd") { [unowned self] in
            updatePart(name, label: "Add Path Point") { p in
                var path = p.path ?? []
                let last = path.last ?? .zero
                let step = path.count >= 2 ? last - path[path.count - 2] : Vec3(0, 0.2, 0)
                path.append(last + step)
                p.path = path
                if var radii = p.radii { radii.append(radii.last ?? 1); p.radii = radii }
            }
        }
        add.command = MeshBuildEditCommand.id.rawValue
        add.tooltip = "A new point after the last, continuing the path"
        view.addChild(HStack(spacing: 6, [add, Spacer()]))

        var options: [Widget] = [rowLabel(part.profile == nil ? "Radius" : "Section")]
        if part.profile == nil {
            let radius = numberField(Double(part.radius ?? MeshGeometry.defaultSweepRadius), step: 0.005, prefix: nil,
                                     name: "meshBuildSweepRadius", range: 0.0001...10_000) { [unowned self] value in
                updatePart(name, label: "Sweep Radius") { $0.radius = Float(value) }
            }
            radius.tooltip = "The round section's radius, meters"
            options.append(radius)
        }
        let section = Dropdown(options: ["Circle", "Profile"], selectedIndex: part.profile == nil ? 0 : 1, name: "meshBuildSweepSection") {
            [unowned self] index in
            updatePart(name, label: "Sweep Section") { p in
                if index == 0 { p.profile = nil } else if p.profile == nil {
                    let r = p.radius ?? MeshGeometry.defaultSweepRadius
                    p.profile = [Vec2(-r, -r / 2), Vec2(r, -r / 2), Vec2(r, r / 2), Vec2(-r, r / 2)]
                }
            }
        }
        section.tooltip = "A round section, or an outline of points (x across, y up) edited below"
        options.append(section)
        view.addChild(HStack(spacing: 6, options))
        let closed = Checkbox("Closed loop", isOn: part.closed ?? false, name: "meshBuildSweepClosed") { [unowned self] on in
            updatePart(name, label: "Sweep Closed") { $0.closed = on ? true : nil }
        }
        closed.tooltip = "Join the end back to the start (rings, tyres, loops of rail)"
        let smooth = Checkbox("Smooth", isOn: part.smooth ?? true, name: "meshBuildSweepSmooth") { [unowned self] on in
            updatePart(name, label: "Sweep Smooth") { $0.smooth = on ? nil : false }
        }
        smooth.tooltip = "A smooth curve through the points; off: straight segments with mitred corners"
        for box in [closed, smooth] { box.command = MeshBuildEditCommand.id.rawValue }
        view.addChild(HStack(spacing: 6, [rowLabel(""), closed, smooth, Spacer()]))
        view.addChild(curveNote("The section follows the path without twisting; open ends are capped. Size multiplies it.", part))
    }

    private func addLoftRows(_ part: MeshBuildPart) {
        let name = part.name
        let axis = part.axis ?? .y
        let sections = part.sections ?? []
        view.addChild(Separator())
        let across = axis == .y ? ("w (x)", "d (z)") : axis == .z ? ("w (x)", "h (y)") : ("d (z)", "h (y)")
        view.addChild(Label("Sections along \(axis.rawValue.uppercased()): position, size \(across.0) × \(across.1), roundness", role: .secondary))
        for (i, section) in sections.enumerated() {
            let index = Label("\(i + 1)", role: .caption)
            index.style.width = 24
            let along = section.at.split(axis).along
            var fields: [Widget] = [index]
            fields.append(numberField(Double(along), step: 0.01, prefix: axis.rawValue, name: "meshBuildSection.\(i).at") { [unowned self] value in
                updateSection(name, i) { s in
                    switch s.at {
                    case .along: s.at = .along(Float(value))
                    case .point(var p): p[axis.index] = Float(value); s.at = .point(p)
                    }
                }
            })
            let size = section.size ?? (section.profile == nil ? MeshBuildSection.defaultSize : Vec2(1, 1))
            for k in 0..<2 {
                fields.append(numberField(Double(size[k]), step: 0.01, prefix: k == 0 ? "w" : (axis == .y ? "d" : "h"),
                                          name: "meshBuildSection.\(i).size.\(k)", range: 0...10_000) { [unowned self] value in
                    updateSection(name, i) { s in
                        var v = s.size ?? size
                        v[k] = Float(value)
                        s.size = v
                    }
                })
            }
            if section.profile == nil {
                let round = numberField(Double(section.roundness ?? 1), step: 0.1, prefix: "◯", name: "meshBuildSection.\(i).roundness",
                                        range: 0...6) { [unowned self] value in
                    updateSection(name, i) { $0.roundness = abs(value - 1) < 1e-6 ? nil : Float(value) }
                }
                round.tooltip = "0 diamond, 1 ellipse, 2 squircle, 3 rounded box, 4+ box"
                fields.append(round)
            }
            let remove = Button("Remove", name: "meshBuildSectionRemove.\(i)") { [unowned self] in
                updatePart(name, label: "Remove Section") { p in
                    if var s = p.sections, s.indices.contains(i) { s.remove(at: i); p.sections = s }
                }
            }
            remove.command = MeshBuildEditCommand.id.rawValue
            remove.isEnabled = sections.count > 2
            remove.tooltip = "Remove this section (a loft keeps at least 2)"
            fields.append(remove)
            view.addChild(HStack(spacing: 4, fields))
        }
        let add = Button("Add Section", name: "meshBuildSectionAdd") { [unowned self] in
            updatePart(name, label: "Add Section") { p in
                var s = p.sections ?? []
                let last = s.last ?? MeshBuildSection(at: 0)
                let a = last.at.split(axis).along, before = s.count >= 2 ? s[s.count - 2].at.split(axis).along : a - 0.2
                var next = last
                next.at = .along(a + (a - before == 0 ? 0.2 : a - before))
                s.append(next)
                p.sections = s
            }
        }
        add.command = MeshBuildEditCommand.id.rawValue
        add.tooltip = "A new section past the last, the same size"
        let axisMenu = Dropdown(options: ["Along X", "Along Y", "Along Z"], selectedIndex: axis.index, name: "meshBuildLoftAxis") {
            [unowned self] index in
            updatePart(name, label: "Loft Axis") { $0.axis = index == 1 ? nil : MeshBuildAxis.allCases[index] }
        }
        axisMenu.tooltip = "The axis the sections stack along: Y for bottles and towers, Z for hulls, fuselages and car bodies"
        let smooth = Checkbox("Smooth", isOn: part.smooth ?? true, name: "meshBuildLoftSmooth") { [unowned self] on in
            updatePart(name, label: "Loft Smooth") { $0.smooth = on ? nil : false }
        }
        smooth.command = MeshBuildEditCommand.id.rawValue
        smooth.tooltip = "A smooth skin through the sections; off: straight panels with creases at each section"
        view.addChild(HStack(spacing: 6, [add, axisMenu, smooth, Spacer()]))
        view.addChild(curveNote("The skin passes through every section in order along the axis; the ends are capped (size 0 makes a point). Size multiplies it.", part))
    }

    private func updateSection(_ name: String, _ i: Int, _ change: @escaping (inout MeshBuildSection) -> Void) {
        updatePart(name, label: "Edit Section") { p in
            guard var s = p.sections, s.indices.contains(i) else { return }
            change(&s[i])
            p.sections = s
        }
    }

    // MARK: Deformers

    /// Buttons that add a deformer, a row per deformer (its numbers and Remove) and the subdivision level.
    func addDeformSection(for part: MeshBuildPart) {
        guard part.shape != .group else { return }
        let name = part.name
        let deform = part.deform ?? []
        view.addChild(Separator())
        view.addChild(Label("Deform \(part.name)", role: .secondary))
        let buttons = HStack(spacing: 4, name: "meshBuildDeformAdd")
        buttons.wraps = true
        let kinds: [(String, MeshBuildDeform, String)] = [
            ("Taper", .taper(0.6, 0.6), "Narrow (or widen) toward the top"),
            ("Bend", .bend(.x, 30), "Curve the part over so its top leans"),
            ("Twist", .twist(45), "Turn the top about the vertical axis"),
            ("Noise", .noise(0.02, scale: 0.15), "Lumps and dents: rocks, bark, worn surfaces"),
        ]
        for (label, value, tooltip) in kinds {
            let button = Button(label, name: "meshBuildDeform.\(label.lowercased())") { [unowned self] in
                updatePart(name, label: "Add \(label)") { p in p.deform = (p.deform ?? []) + [value] }
            }
            button.command = MeshBuildEditCommand.id.rawValue
            button.tooltip = tooltip
            buttons.addChild(button)
        }
        view.addChild(buttons)
        for (i, d) in deform.enumerated() {
            var fields: [Widget] = []
            func edit(_ change: @escaping (inout MeshBuildDeform) -> Void) {
                updatePart(name, label: "Edit Deform") { p in
                    guard var list = p.deform, list.indices.contains(i) else { return }
                    change(&list[i])
                    p.deform = list
                }
            }
            if let taper = d.taper {
                fields.append(rowLabel("Taper"))
                for k in 0..<2 {
                    fields.append(numberField(Double(taper[k]), step: 0.05, prefix: k == 0 ? "x" : "z", name: "meshBuildDeform.\(i).taper.\(k)",
                                              range: 0...100) { value in edit { $0.taper?[k] = Float(value) } })
                }
            } else if let bend = d.bend {
                fields.append(rowLabel("Bend"))
                let toward = Dropdown(options: ["Toward X", "Toward Z"], selectedIndex: bend.axis == .z ? 1 : 0, name: "meshBuildDeform.\(i).axis") {
                    index in edit { $0.bend?.axis = index == 1 ? .z : .x }
                }
                toward.tooltip = "The way the top leans (negative degrees: the other way)"
                fields.append(toward)
                fields.append(numberField(Double(bend.degrees), step: 1, prefix: "°", name: "meshBuildDeform.\(i).degrees") { value in
                    edit { $0.bend?.degrees = Float(value) }
                })
            } else if let twist = d.twist {
                fields.append(rowLabel("Twist"))
                fields.append(numberField(Double(twist), step: 1, prefix: "°", name: "meshBuildDeform.\(i).twist") { value in
                    edit { $0.twist = Float(value) }
                })
            } else if let noise = d.noise {
                fields.append(rowLabel("Noise"))
                fields.append(numberField(Double(noise.amount), step: 0.005, prefix: "m", name: "meshBuildDeform.\(i).amount") { value in
                    edit { $0.noise?.amount = Float(value) }
                })
                fields.append(numberField(Double(noise.scale), step: 0.01, prefix: "↔", name: "meshBuildDeform.\(i).scale", range: 0.001...10_000) {
                    value in edit { $0.noise?.scale = Float(value) }
                })
                let seed = NumberField(value: Double(noise.seed), isInteger: true, step: 1, name: "meshBuildDeform.\(i).seed")
                seed.prefix = "#"
                seed.style.grow = 1
                seed.tooltip = "Another seed gives other lumps"
                seed.onEditEnded = { start, end in
                    guard start != end else { return }
                    edit { $0.noise?.seed = Int(end.rounded()) }
                }
                fields.append(seed)
            } else {
                fields.append(Label(d.summary, role: .caption))
            }
            let remove = Button("Remove", name: "meshBuildDeformRemove.\(i)") { [unowned self] in
                updatePart(name, label: "Remove Deform") { p in
                    guard var list = p.deform, list.indices.contains(i) else { return }
                    list.remove(at: i)
                    p.deform = list.isEmpty ? nil : list
                    if list.isEmpty { p.subdivide = nil }
                }
            }
            remove.command = MeshBuildEditCommand.id.rawValue
            fields.append(remove)
            view.addChild(HStack(spacing: 4, fields))
        }
        guard !deform.isEmpty else { return }
        let level = NumberField(value: Double(part.subdivide ?? MeshBuildPart.defaultSubdivide), isInteger: true,
                                range: Double(MeshBuildPart.subdivideRange.lowerBound)...Double(MeshBuildPart.subdivideRange.upperBound),
                                step: 1, name: "meshBuildSubdivide")
        level.tooltip = "How finely the mesh is split so it can curve (0: not at all; each step halves the pieces)"
        level.style.grow = 1
        level.onEditEnded = { [unowned self] start, end in
            guard start != end else { return }
            updatePart(name, label: "Subdivide") { p in
                let n = Int(end.rounded())
                p.subdivide = n == MeshBuildPart.defaultSubdivide ? nil : n
            }
        }
        view.addChild(HStack(spacing: 6, [rowLabel("Subdivide"), level]))
        view.addChild(note("Deformers run in order on the part's mesh (meters, its own axes; Y is up), before mirroring. Hard edges stay hard."))
    }

    // MARK: Helpers

    private func numberField(_ value: Double, step: Double, prefix: String?, name: String, range: ClosedRange<Double>? = nil,
                             _ commit: @escaping (Double) -> Void) -> NumberField {
        let field = NumberField(value: value, range: range, step: step, name: name)
        field.prefix = prefix
        field.precision = 3
        field.style.grow = 1
        field.onEditEnded = { start, end in
            guard start != end else { return }
            commit(end)
        }
        return field
    }

    private func curveNote(_ text: String, _ part: MeshBuildPart) -> Label {
        let warnings = part.shapeWarnings
        return note(warnings.isEmpty ? text : text + " ⚠ " + warnings.joined(separator: " "))
    }
}
