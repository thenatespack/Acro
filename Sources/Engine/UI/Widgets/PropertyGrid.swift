import Foundation

/// Phases of one edit of a field, in the order they arrive: `.began` once (old == new), `.changed`
/// any number of times (a drag changes continuously), `.ended` once. An edit that is a single act
/// (a checkbox, a typed number, an enum choice) delivers all three in a row.
public enum PropertyEditPhase: Sendable {
    case began, changed, ended
}

/// One step of a user edit of a component field, as reported by `PropertyGrid.onFieldEdit`.
/// `oldValue` is the field's value when the edit began (the same in every phase of one edit),
/// `newValue` the current one (`.ended`: the final one). An undo system records
/// `(entity, componentName, path, oldValue, newValue)` at `.ended` when the two differ.
public struct PropertyEdit: Equatable, Sendable {
    public var entity: Entity
    public var componentName: String
    /// The field's path (`"position"`, `"stats.health"`, `"points.2"`), as `World.setField` takes it.
    public var path: String
    public var oldValue: FieldValue
    public var newValue: FieldValue
    public var phase: PropertyEditPhase
}

/// The inspector's property grid: for one entity, a collapsible section per component, each
/// listing its fields with a label and an editor chosen from reflection (`World.components(of:)`,
/// `Component.fields()`):
///
/// | `FieldKind` | editor |
/// |---|---|
/// | `bool` | `Checkbox` |
/// | `int` / `float` | `NumberField` (range / step hints; with `usesSlidersForRanges`, a `Slider` beside it when a finite range is hinted) |
/// | `string` | `TextField` (commits on Enter or focus loss, Esc reverts) |
/// | `vec2` / `vec3` / `vec4` | `VectorField`; `vec3` / `vec4` with the `color` hint: `ColorSwatch` (linear RGB, opens a `ColorPicker`; alpha is kept; HDR values above 1 are clamped by the picker) |
/// | `quat` | `VectorField` of Euler degrees (`Quat.eulerDegrees`) |
/// | `enumeration` | `Dropdown` |
/// | `entity` | a read-only label with the entity's name (`entityName`) or index. A picker is future work |
/// | `structure` | an indented collapsible group of its fields |
/// | `array` | an indented collapsible group of its elements, read-only (the first `maxArrayElements`). Resizing / editing is future work |
/// | nil optional (`unknown`) | a "—" label. Optionals can't be set back to nil from the grid yet |
///
/// `hidden` hints skip a field, `readOnly` disables its editor, `displayName` replaces the
/// prettified name ("castsShadows" shows "Casts Shadows"), `tooltip` shows after hovering the
/// label for half a second. Components that aren't serialized (derived data such as
/// `GlobalTransform`) are hidden unless `showsDerivedComponents`; `componentFilter` hides others.
///
/// ## Driving it
///
/// Set `entity`, add the grid to a `ScrollView`, and call `refresh()` once per frame (after
/// `UIContext.update`): it re-reads the components and pushes the values into the existing
/// widgets, rebuilding only a component's section when its shape changed (a field appeared,
/// an array grew, an optional became nil) or the entity's component set changed. Editors that
/// are being used (a number being dragged or typed into, a focused text field, an open color
/// popup) are left alone, so focus and half-typed text survive refreshes. Collapsed sections
/// are neither read nor updated. Cost: one `fields()` call per visible component (about 1 µs
/// per field) plus a cheap pass over the widgets.
///
/// ## Edits and undo
///
/// Every user edit calls `onFieldEdit` with a `PropertyEdit` (phases above). By default the grid
/// also writes it to the world with `World.setField` at `.changed` (so the scene updates live
/// while dragging), and calls `onEditError` when that throws. An editor with an undo stack can
/// leave that on and just record steps at `.ended`, or set `appliesEditsToWorld = false` and
/// route `.changed` through its own command (the widgets re-sync from the world at the next
/// `refresh()` either way, so a rejected edit visibly snaps back).
public final class PropertyGrid: Stack {
    public let world: World
    /// The entity shown (nil: empty). Changing it rebuilds the grid.
    public var entity: Entity? {
        didSet {
            guard entity != oldValue else { return }
            rebuild()
            refresh()
        }
    }

    /// Called for every phase of every user edit (see `PropertyEdit`).
    public var onFieldEdit: ((PropertyEdit) -> Void)?
    /// Write edits into the world with `setField` (default). Turn off when the owner applies them.
    public var appliesEditsToWorld = true
    /// `setField` failed for an edit the grid applied.
    public var onEditError: ((PropertyEdit, Error) -> Void)?
    /// When set, component headers show a remove button that calls this.
    public var onRemoveComponent: ((_ entity: Entity, _ componentName: String) -> Void)? {
        didSet { for section in sections { section.header.showsRemove = onRemoveComponent != nil } }
    }
    /// Names an entity for `entity` fields; nil results show "Entity <index>".
    public var entityName: ((Entity) -> String?)?
    /// Components to show by name (nil: all that are shown by default).
    public var componentFilter: ((String) -> Bool)? { didSet { rebuild(); refresh() } }
    /// Also show components whose type opts out of serialization.
    public var showsDerivedComponents = false { didSet { rebuild(); refresh() } }
    /// Use a slider next to the number for fields with a finite `range` hint.
    public var usesSlidersForRanges = false
    /// Width of the label column of a top-level field, in points.
    public var labelWidth: Float = 140
    /// Indentation per nesting level, in points.
    public var indentWidth: Float = 14
    /// Elements of an array shown (the rest are counted in the title).
    public var maxArrayElements = 64

    /// The shown components' names, in order.
    public var componentNames: [String] { sections.map(\.name) }

    @MainActor private final class Section {
        let name: String
        let root: VStack
        let header: GridHeader
        let body: VStack
        var bindings: [Binding] = []
        var isBuilt = false

        init(name: String, header: GridHeader, body: VStack) {
            self.name = name
            self.header = header
            self.body = body
            root = VStack(spacing: 0, name: "section.\(name)", [header, body])
        }
    }

    @MainActor private final class Binding {
        let entity: Entity
        let component: String
        let path: String
        let kind: FieldKind
        let childCount: Int
        let isNull: Bool
        /// Collapse keys of the groups this row is inside.
        let ancestors: [String]
        var row: Widget?
        /// The world's value as of the last refresh or edit.
        var current: FieldValue?
        /// The value when the edit in progress began.
        var start: FieldValue?
        var update: (FieldDescriptor) -> Void = { _ in }

        init(entity: Entity, component: String, field: FieldDescriptor, ancestors: [String]) {
            self.entity = entity
            self.component = component
            path = field.path
            kind = field.kind
            childCount = field.children.count
            isNull = field.value == .null
            self.ancestors = ancestors
            current = field.value
        }

        func matches(_ f: FieldDescriptor) -> Bool {
            f.path == path && f.kind == kind && f.children.count == childCount && (f.value == .null) == isNull
        }
    }

    private var sections: [Section] = []
    private var collapsed = Set<String>()
    private var tooltip: (widget: Widget, since: Double)?

    public init(world: World, name: String = "propertyGrid") {
        self.world = world
        super.init(.vertical, spacing: 6, alignment: .stretch, name: name)
    }

    // MARK: Collapse state

    /// Whether the component section (`path` empty) or the group at `path` is collapsed. This
    /// survives refreshes, rebuilds and switching entities.
    public func isCollapsed(component: String, path: String = "") -> Bool {
        collapsed.contains("\(component)/\(path)")
    }

    public func setCollapsed(_ isCollapsed: Bool, component: String, path: String = "") {
        let key = "\(component)/\(path)"
        guard collapsed.contains(key) != isCollapsed else { return }
        if isCollapsed { collapsed.insert(key) } else { collapsed.remove(key) }
        guard let section = sections.first(where: { $0.name == component }) else { return }
        if path.isEmpty {
            section.header.isCollapsed = isCollapsed
            section.body.isHidden = isCollapsed
        } else {
            for b in section.bindings {
                if b.path == path, let header = b.row as? GridHeader { header.isCollapsed = isCollapsed }
                if b.ancestors.contains(key) { b.row?.isHidden = b.ancestors.contains { collapsed.contains($0) } }
            }
        }
    }

    // MARK: Building

    private func visibleComponents() -> [any Component] {
        guard let entity else { return [] }
        return world.components(of: entity).filter { component in
            let type = Swift.type(of: component)
            if !showsDerivedComponents && !type.isSerialized { return false }
            return componentFilter?(type.componentName) ?? true
        }
    }

    private func rebuild() {
        removeAllChildren()
        sections = []
        tooltip = nil
        guard let entity else { return }
        for component in visibleComponents() {
            let name = Swift.type(of: component).componentName
            let header = GridHeader(title: name, isComponent: true, name: "header.\(name)")
            let body = VStack(spacing: 3, padding: EdgeInsets(top: 6, left: 8, bottom: 8, right: 8), name: "body.\(name)")
            let section = Section(name: name, header: header, body: body)
            header.showsRemove = onRemoveComponent != nil
            let collapsedNow = collapsed.contains("\(name)/")
            header.isCollapsed = collapsedNow
            body.isHidden = collapsedNow
            header.onToggle = { [weak self, weak section] in
                guard let self, let section else { return }
                self.setCollapsed(!self.collapsed.contains("\(section.name)/"), component: section.name)
            }
            header.onRemove = { [weak self] in self?.onRemoveComponent?(entity, name) }
            sections.append(section)
            addChild(section.root)
        }
    }

    // MARK: Refresh

    /// Re-reads the entity's components into the widgets. Call once per frame; see the type's docs.
    public func refresh() {
        guard let entity else { return }
        let components = visibleComponents()
        if components.count != sections.count
            || !zip(components, sections).allSatisfy({ Swift.type(of: $0).componentName == $1.name }) {
            rebuild()
        }
        for (component, section) in zip(components, sections) where !collapsed.contains("\(section.name)/") {
            let fields = component.fields()
            var index = 0
            if !section.isBuilt || !updateFields(fields[...], section: section, index: &index) || index != section.bindings.count {
                buildSection(section, fields: fields, entity: entity)
            }
        }
    }

    private func shownChildren(_ field: FieldDescriptor) -> ArraySlice<FieldDescriptor> {
        field.children.prefix(maxArrayElements)
    }

    /// Pushes the values into the section's widgets. False when the shape differs from what was built.
    private func updateFields(_ fields: ArraySlice<FieldDescriptor>, section: Section, index: inout Int) -> Bool {
        for field in fields where !field.hints.hidden {
            guard index < section.bindings.count else { return false }
            let binding = section.bindings[index]
            guard binding.matches(field) else { return false }
            index += 1
            binding.current = field.value
            if binding.row?.isHidden != true { binding.update(field) }
            switch field.kind {
            case .structure:
                if !updateFields(field.children[...], section: section, index: &index) { return false }
            case .array:
                if !updateFields(shownChildren(field), section: section, index: &index) { return false }
            default:
                break
            }
        }
        return true
    }

    private func buildSection(_ section: Section, fields: [FieldDescriptor], entity: Entity) {
        section.body.removeAllChildren()
        section.bindings = []
        section.isBuilt = true
        addRows(fields[...], depth: 0, readOnly: false, ancestors: [], section: section, entity: entity)
    }

    private func addRows(_ fields: ArraySlice<FieldDescriptor>, depth: Int, readOnly: Bool, ancestors: [String],
                         section: Section, entity: Entity) {
        for field in fields where !field.hints.hidden {
            let readOnly = readOnly || field.hints.readOnly
            let binding = Binding(entity: entity, component: section.name, field: field, ancestors: ancestors)
            let title = Self.title(of: field)
            switch field.kind {
            case .structure, .array:
                let isArray = field.kind == .array
                let key = "\(section.name)/\(field.path)"
                var text = title
                if isArray { text += field.children.count > maxArrayElements ? " (\(field.children.count), first \(maxArrayElements))" : " (\(field.children.count))" }
                let header = GridHeader(title: text, isComponent: false, name: "group.\(section.name).\(field.path)")
                header.depth = depth
                header.indent = Float(depth) * indentWidth
                header.isCollapsed = collapsed.contains(key)
                header.tooltipText = field.hints.tooltip
                header.onToggle = { [weak self] in
                    guard let self else { return }
                    self.setCollapsed(!self.collapsed.contains(key), component: section.name, path: field.path)
                }
                binding.row = header
                header.isHidden = ancestors.contains { collapsed.contains($0) }
                section.body.addChild(header)
                section.bindings.append(binding)
                let children = isArray ? shownChildren(field) : field.children[...]
                addRows(children, depth: depth + 1, readOnly: readOnly || isArray, ancestors: ancestors + [key],
                        section: section, entity: entity)
            default:
                let row = makeRow(field, binding: binding, depth: depth, readOnly: readOnly)
                row.isHidden = ancestors.contains { collapsed.contains($0) }
                binding.row = row
                section.body.addChild(row)
                section.bindings.append(binding)
            }
        }
    }

    /// "castsShadows" -> "Casts Shadows"; array elements "[2]"; the `displayName` hint wins.
    static func title(of field: FieldDescriptor) -> String {
        if let name = field.hints.displayName { return name }
        if !field.name.isEmpty, field.name.allSatisfy(\.isNumber) { return "[\(field.name)]" }
        var result = ""
        var previousLower = false
        for character in field.name {
            if character.isUppercase && previousLower { result.append(" ") }
            result.append(result.isEmpty ? Character(character.uppercased()) : character)
            previousLower = character.isLowercase || character.isNumber
        }
        return result
    }

    // MARK: Editors

    private func makeRow(_ field: FieldDescriptor, binding b: Binding, depth: Int, readOnly: Bool) -> Widget {
        let name = "\(b.component).\(field.path)"
        let (editor, fillsWidth) = makeEditor(field, binding: b, name: name, readOnly: readOnly)
        let label = FieldLabel(Self.title(of: field), tooltip: field.hints.tooltip)
        label.style.width = max(40, labelWidth - Float(depth) * indentWidth)
        if fillsWidth {
            editor.style.grow = 1
            editor.style.width = 0
        }
        if readOnly { editor.isEnabled = false }
        let row = HStack(spacing: 6, padding: EdgeInsets(left: Float(depth) * indentWidth), name: "row.\(name)", [label, editor])
        row.style.minHeight = 24
        return row
    }

    private static func number(_ value: FieldValue?) -> Double? {
        switch value {
        case .int(let i)?: Double(i)
        case .float(let d)?: d
        default: nil
        }
    }

    private static func components(_ value: FieldValue?) -> [Double]? {
        switch value {
        case .vec2(let v)?: return [Double(v.x), Double(v.y)]
        case .vec3(let v)?: return [Double(v.x), Double(v.y), Double(v.z)]
        case .vec4(let v)?: return [Double(v.x), Double(v.y), Double(v.z), Double(v.w)]
        case .quat(let q)?:
            let e = q.eulerDegrees
            return [Double(e.x), Double(e.y), Double(e.z)]
        default: return nil
        }
    }

    private static func vectorValue(_ kind: FieldKind, _ v: [Double]) -> FieldValue {
        func f(_ i: Int) -> Float { i < v.count ? Float(v[i]) : 0 }
        switch kind {
        case .vec2: return .vec2(Vec2(f(0), f(1)))
        case .vec3: return .vec3(Vec3(f(0), f(1), f(2)))
        case .vec4: return .vec4(Vec4(f(0), f(1), f(2), f(3)))
        default: return .quat(Quat(eulerDegrees: Vec3(f(0), f(1), f(2))))
        }
    }

    /// The editor widget for `field` and whether it should stretch over the row.
    private func makeEditor(_ field: FieldDescriptor, binding b: Binding, name: String, readOnly: Bool) -> (Widget, Bool) {
        func placeholder(_ text: String) -> (Widget, Bool) {
            let label = Label(text, role: .secondary, name: name)
            b.update = { [weak self, weak label] f in
                if case .entity(let e)? = f.value, let self { label?.text = self.entityText(e) }
            }
            return (label, true)
        }
        if field.value == .null { return placeholder("—") }
        switch field.kind {
        case .bool:
            let box = Checkbox("", isOn: field.value == .bool(true), name: name)
            box.onChange = { [weak self, weak b] on in if let self, let b { self.atomicEdit(b, .bool(on)) } }
            b.update = { f in
                if case .bool(let v)? = f.value, box.isOn != v { box.isOn = v }
            }
            return (box, false)

        case .int, .float:
            return (numberEditor(field, binding: b, name: name), true)

        case .string:
            var initial = ""
            if case .string(let s)? = field.value { initial = s }
            let editor = TextEditor(text: initial, name: name)
            editor.onCommit = { [weak self, weak b] text in if let self, let b { self.atomicEdit(b, .string(text)) } }
            b.update = { f in
                if case .string(let s)? = f.value { editor.setText(s) }
            }
            return (editor, true)

        case .vec2, .vec3, .vec4, .quat:
            let kind = field.kind
            let values = Self.components(field.value) ?? []
            if field.hints.color, kind == .vec3 || kind == .vec4 {
                return (colorEditor(field, binding: b, name: name), true)
            }
            let count = kind == .vec2 ? 2 : kind == .vec4 ? 4 : 3
            let vector = VectorField(count: count, values: values, range: field.hints.range, step: field.hints.step ?? 0, name: name)
            if kind == .quat {
                vector.step = 1
                vector.precision = 2
            }
            vector.onEditBegan = { [weak self, weak b] _ in if let self, let b { self.beginEdit(b) } }
            vector.onChange = { [weak self, weak b] v in if let self, let b { self.changeEdit(b, Self.vectorValue(kind, v)) } }
            vector.onEditEnded = { [weak self, weak b] _, end in if let self, let b { self.endEdit(b, Self.vectorValue(kind, end)) } }
            b.update = { f in
                if let v = Self.components(f.value) { vector.setValues(v) }
            }
            return (vector, true)

        case .enumeration(let cases):
            var index = 0
            if case .enumCase(let c)? = field.value { index = cases.firstIndex(of: c) ?? 0 }
            let dropdown = Dropdown(options: cases, selectedIndex: index, name: name)
            dropdown.onChange = { [weak self, weak b] i in
                if let self, let b, cases.indices.contains(i) { self.atomicEdit(b, .enumCase(cases[i])) }
            }
            b.update = { f in
                if case .enumCase(let c)? = f.value, let i = cases.firstIndex(of: c) { dropdown.select(i) }
            }
            return (dropdown, true)

        case .entity:
            var text = "None"
            if case .entity(let e)? = field.value { text = entityText(e) }
            return placeholder(text)

        default:
            return placeholder("—")
        }
    }

    private func entityText(_ e: Entity) -> String {
        if e == .invalid { return "None" }
        if !world.isAlive(e) { return "Missing (\(e.index))" }
        return entityName?(e) ?? "Entity \(e.index)"
    }

    private func numberEditor(_ field: FieldDescriptor, binding b: Binding, name: String) -> Widget {
        let isInt = field.kind == .int
        func value(_ d: Double) -> FieldValue { isInt ? .int(Int(d.rounded())) : .float(d) }
        let initial = Self.number(field.value) ?? 0
        let numberField = NumberField(value: initial, isInteger: isInt, range: field.hints.range, step: field.hints.step ?? 0,
                                      name: name)
        numberField.onEditBegan = { [weak self, weak b] _ in if let self, let b { self.beginEdit(b) } }
        numberField.onEditEnded = { [weak self, weak b] _, end in if let self, let b { self.endEdit(b, value(end)) } }

        if usesSlidersForRanges, let range = field.hints.range, range.lowerBound.isFinite, range.upperBound.isFinite,
           range.upperBound > range.lowerBound {
            let slider = Slider(value: Float(initial), in: Float(range.lowerBound)...Float(range.upperBound),
                                step: isInt ? 1 : Float(field.hints.step ?? 0), name: "\(name).slider")
            slider.style.grow = 1
            slider.style.width = 0
            numberField.style.width = 56
            numberField.preferredWidth = 56
            slider.onEditBegan = { [weak self, weak b] in if let self, let b { self.beginEdit(b) } }
            slider.onEditEnded = { [weak self, weak b, weak slider] in
                if let self, let b, let slider { self.endEdit(b, value(Double(slider.value))) }
            }
            slider.onChange = { [weak self, weak b, weak numberField] x in
                guard let self, let b else { return }
                numberField?.setValue(Double(x))
                let new = value(Double(x))
                // A drag is one edit; a key press is a whole one.
                if b.start != nil { self.changeEdit(b, new) } else { self.atomicEdit(b, new) }
            }
            numberField.onChange = { [weak self, weak b, weak slider] d in
                slider?.setValue(Float(d))
                if let self, let b { self.changeEdit(b, value(d)) }
            }
            b.update = { f in
                guard let v = Self.number(f.value) else { return }
                numberField.setValue(v)
                if b.start == nil { slider.setValue(Float(v)) }
            }
            return HStack(spacing: 6, name: "\(name).slider.row", [slider, numberField])
        }
        numberField.onChange = { [weak self, weak b] d in if let self, let b { self.changeEdit(b, value(d)) } }
        b.update = { f in
            if let v = Self.number(f.value) { numberField.setValue(v) }
        }
        return numberField
    }

    private func colorEditor(_ field: FieldDescriptor, binding b: Binding, name: String) -> Widget {
        func color(_ value: FieldValue?) -> UIColor {
            switch value {
            case .vec3(let v)?: UIColor(linearRGB: v)
            case .vec4(let v)?: UIColor(linearRGB: Vec3(v.x, v.y, v.z), alpha: min(max(v.w, 0), 1))
            default: .white
            }
        }
        func value(_ c: UIColor) -> FieldValue {
            let linear = c.linearRGB
            if case .vec4(let old)? = b.current { return .vec4(Vec4(linear.x, linear.y, linear.z, old.w)) }
            return .vec3(linear)
        }
        let swatch = ColorSwatch(color: color(field.value), name: name)
        swatch.onEditBegan = { [weak self, weak b] _ in if let self, let b { self.beginEdit(b) } }
        swatch.onChange = { [weak self, weak b] c in if let self, let b { self.changeEdit(b, value(c)) } }
        swatch.onEditEnded = { [weak self, weak b] _, end in if let self, let b { self.endEdit(b, value(end)) } }
        b.update = { f in swatch.setColor(color(f.value)) }
        return swatch
    }

    // MARK: Edits

    private func emit(_ phase: PropertyEditPhase, _ b: Binding, old: FieldValue, new: FieldValue) {
        onFieldEdit?(PropertyEdit(entity: b.entity, componentName: b.component, path: b.path, oldValue: old, newValue: new,
                                  phase: phase))
    }

    private func beginEdit(_ b: Binding) {
        guard b.start == nil, let old = b.current else { return }
        b.start = old
        emit(.began, b, old: old, new: old)
    }

    private func changeEdit(_ b: Binding, _ new: FieldValue) {
        guard let old = b.start ?? b.current else { return }
        if b.start == nil { b.start = old }
        b.current = new
        let edit = PropertyEdit(entity: b.entity, componentName: b.component, path: b.path, oldValue: old, newValue: new,
                                phase: .changed)
        if appliesEditsToWorld {
            do {
                try world.setField(b.path, of: b.component, for: b.entity, to: new)
            } catch {
                onEditError?(edit, error)
            }
        }
        onFieldEdit?(edit)
    }

    private func endEdit(_ b: Binding, _ new: FieldValue) {
        guard let old = b.start else { return }
        b.start = nil
        b.current = new
        emit(.ended, b, old: old, new: new)
    }

    /// A whole edit at once: began, changed, ended.
    private func atomicEdit(_ b: Binding, _ new: FieldValue) {
        guard let old = b.current, old != new else { return }
        beginEdit(b)
        changeEdit(b, new)
        endEdit(b, new)
    }

    // MARK: Tooltip

    public override func drawForeground(_ list: UIDrawList, theme: UITheme) {
        guard let context else { return }
        let hovered = context.hoveredWidget
        guard let hovered, hovered.isDescendant(of: self),
              let text = (hovered as? FieldLabel)?.tooltip ?? (hovered as? GridHeader)?.tooltipText, !text.isEmpty else {
            tooltip = nil
            return
        }
        if tooltip?.widget !== hovered { tooltip = (hovered, context.time) }
        guard let since = tooltip?.since, context.time - since >= 0.5 else { return }
        let layout = cachedLayout(text, size: theme.smallFontSize)
        let size = Vec2((layout.width * scale).rounded(.up) / scale + 16, theme.smallFontSize + 12)
        let x = min(max(hovered.frame.x, frame.x + 4), max(frame.x + 4, frame.maxX - size.x - 4))
        let rect = UIRect(x: x, y: hovered.frame.maxY + 2, width: size.x, height: size.y)
        list.fillRect(rect, color: theme.popupBackground, radii: UICornerRadii(4))
        list.strokeRect(rect, color: theme.popupBorder, width: 1, radii: UICornerRadii(4))
        drawLine(layout, font: theme.font, in: UIRect(x: rect.x + 8, y: rect.y, width: rect.width - 16, height: rect.height),
                 color: theme.textColor, list: list)
    }
}

// MARK: Parts

/// A component or group header: disclosure triangle, title, and for components an optional remove button.
final class GridHeader: Widget {
    var title: String { didSet { if title != oldValue { setNeedsDisplay() } } }
    var isCollapsed = false { didSet { if isCollapsed != oldValue { setNeedsDisplay() } } }
    var showsRemove = false { didSet { setNeedsDisplay() } }
    var depth = 0
    var indent: Float = 0 { didSet { setNeedsDisplay() } }
    var tooltipText: String?
    var onToggle: (() -> Void)?
    var onRemove: (() -> Void)?
    let isComponent: Bool
    private var cache = CachedTextLayout()

    init(title: String, isComponent: Bool, name: String) {
        self.title = title
        self.isComponent = isComponent
        super.init(name: name)
    }

    override func measureContent(width: Float?) -> Vec2 {
        Vec2(80, isComponent ? 26 : 22)
    }

    private var removeRect: UIRect { UIRect(x: frame.maxX - 26, y: frame.y, width: 26, height: frame.height) }

    override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            return true
        case .pointerUp(let e):
            if frame.contains(e.position) {
                if isComponent, showsRemove, removeRect.contains(e.position) { onRemove?() } else { onToggle?() }
            }
            return true
        default:
            return false
        }
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        let radii = UICornerRadii(isComponent ? 4 : 3)
        if isComponent {
            list.fillRect(frame, color: isHovered ? theme.controlHover : theme.controlBackground, radii: radii)
        } else if isHovered {
            list.fillRect(frame, color: theme.rowHover, radii: radii)
        }
        let c = Vec2(frame.x + indent + 12, frame.center.y)
        let s: Float = 3.5
        let arrow = theme.secondaryTextColor
        if isCollapsed {
            list.drawLine(from: c + Vec2(-s / 2, -s), to: c + Vec2(s / 2, 0), width: 1.5, color: arrow, cap: .round)
            list.drawLine(from: c + Vec2(s / 2, 0), to: c + Vec2(-s / 2, s), width: 1.5, color: arrow, cap: .round)
        } else {
            list.drawLine(from: c + Vec2(-s, -s / 2), to: c + Vec2(0, s / 2), width: 1.5, color: arrow, cap: .round)
            list.drawLine(from: c + Vec2(0, s / 2), to: c + Vec2(s, -s / 2), width: 1.5, color: arrow, cap: .round)
        }
        let layout = cache.get(title, font: theme.font, size: theme.fontSize)
        let x = frame.x + indent + 24
        let right = (isComponent && showsRemove) ? removeRect.x : frame.maxX
        list.withClip(UIRect(x: x, y: frame.y, width: max(0, right - x - 4), height: frame.height)) {
            drawLine(layout, font: theme.font, in: UIRect(x: x, y: frame.y, width: layout.width, height: frame.height),
                     color: isComponent ? theme.textColor : theme.secondaryTextColor, list: list)
        }
        if isComponent, showsRemove {
            let r = removeRect
            let center = r.center
            let hovered = r.contains(context?.pointerPosition ?? Vec2(-1, -1)) && isHovered
            let color = hovered ? theme.textColor : theme.secondaryTextColor
            list.drawLine(from: center + Vec2(-3.5, -3.5), to: center + Vec2(3.5, 3.5), width: 1.5, color: color, cap: .round)
            list.drawLine(from: center + Vec2(3.5, -3.5), to: center + Vec2(-3.5, 3.5), width: 1.5, color: color, cap: .round)
        }
    }
}

/// A field's label, clipped to its width, hoverable for the tooltip.
final class FieldLabel: Widget {
    var text: String { didSet { if text != oldValue { setNeedsDisplay() } } }
    let tooltip: String?
    private var cache = CachedTextLayout()

    init(_ text: String, tooltip: String?) {
        self.text = text
        self.tooltip = tooltip
        super.init(name: "label")
        isHitTestable = tooltip != nil
    }

    override func measureContent(width: Float?) -> Vec2 {
        Vec2(40, theme.controlHeight)
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        let layout = cache.get(text, font: theme.font, size: theme.fontSize)
        let color = isEffectivelyEnabled ? theme.secondaryTextColor : theme.disabledTextColor
        list.withClip(frame) {
            drawLine(layout, font: theme.font, in: frame, color: color, list: list)
        }
    }
}

/// A text field for a string property: Enter or leaving it commits (`onCommit`, only when the
/// text changed), Esc puts the committed text back.
final class TextEditor: Widget {
    let field: TextField
    private(set) var committed: String
    var onCommit: ((String) -> Void)?

    init(text: String, name: String) {
        committed = text
        field = TextField(text: text, name: "\(name).text")
        super.init(name: name)
        addChild(field)
        field.onSubmit = { [weak self] text in self?.commit(text) }
        field.onEndEditing = { [weak self] text in self?.commit(text) }
    }

    /// Takes the model's value; a field being edited keeps its text.
    func setText(_ text: String) {
        guard text != committed else { return }
        committed = text
        if !field.isFocused { field.text = text }
    }

    private func commit(_ text: String) {
        guard text != committed else { return }
        committed = text
        onCommit?(text)
    }

    override func handleEvent(_ event: UIEvent) -> Bool {
        guard case .key(let e) = event, e.key == .escape, field.isFocused else { return false }
        field.text = committed
        context?.focus(nil)
        return true
    }
}
