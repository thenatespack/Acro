import EditorCore
import Engine
import Foundation

// The Timeline tab's sidebar for a `.timeline` file: the timeline's settings, the track list
// (add by kind, delete, mute) with the selected track's name and target, and the selected key's
// fields (only the fields the key sets are shown; Add Field / Remove Field change which). Every
// change is written to the file as one undo step (`EditorSession.applyTimeline`).

/// The proxy component for the timeline's own settings.
struct TimelineSettingsComponent: Component {
    static var componentName: String { "Timeline" }
    static var fieldHints: [String: FieldHints] {
        ["duration": FieldHints(range: 0.1...3600, step: 0.1, tooltip: "Seconds the timeline lasts"),
         "loop": FieldHints(tooltip: "Start over at the end"),
         "skippable": FieldHints(tooltip: "Whether TimelinePlayer.skip() may end it early"),
         "holdFade": FieldHints(tooltip: "Keep the last screen fade on screen when the timeline finishes (off: it clears)")]
    }

    var duration: Float
    var loop: Bool
    var skippable: Bool
    var holdFade: Bool

    init(_ timeline: Timeline) {
        duration = timeline.duration
        loop = timeline.loop
        skippable = timeline.skippable
        holdFade = timeline.holdFade
    }
}

/// The proxy component for a track's name, target and mute.
struct TimelineTrackComponent: Component {
    static var componentName: String { "Track" }
    static var fieldHints: [String: FieldHints] {
        ["id": FieldHints(tooltip: "Unique in the timeline; tools name the track by it"),
         "target": FieldHints(tooltip: "The entity it drives (a Name or Parent/Child path); empty: the default target"),
         "muted": FieldHints(tooltip: "Skip this track")]
    }

    var id: String
    var name: String
    var target: String
    var muted: Bool

    init(_ track: TimelineTrack) {
        id = track.id
        name = track.name
        target = track.target
        muted = track.muted
    }
}

/// The proxy component for one key: encodes and decodes as `TimelineKey` (only the fields it sets).
struct TimelineKeyComponent: Component {
    static var componentName: String { "Key" }
    static var fieldHints: [String: FieldHints] {
        ["time": FieldHints(range: 0...3600, step: 0.05, tooltip: "Seconds from the start"),
         "easing": FieldHints(tooltip: "The curve from the previous key to this one"),
         "rotation": FieldHints(tooltip: "Euler angles, degrees"),
         "lookAt": FieldHints(tooltip: "Aim at this world point"),
         "lookAtEntity": FieldHints(tooltip: "Aim at this entity (Name or path)"),
         "fov": FieldHints(range: 1...179, step: 0.5, tooltip: "Vertical field of view, degrees"),
         "cut": FieldHints(tooltip: "Jump to this key instead of blending from the previous one"),
         "path": FieldHints(tooltip: "Spline points between this key's position and the next key's"),
         "followPath": FieldHints(tooltip: "Face the direction of travel along the path"),
         "clip": FieldHints(tooltip: "Animation: Animator state or SpriteAnimator clip. Audio: a sound file or .sfx"),
         "blend": FieldHints(range: 0...10, step: 0.05, tooltip: "Crossfade seconds"),
         "speed": FieldHints(range: 0...10, step: 0.05),
         "volume": FieldHints(range: 0...4, step: 0.01),
         "pitch": FieldHints(range: 0.1...4, step: 0.01),
         "duration": FieldHints(range: 0...600, step: 0.1, tooltip: "Seconds before it is stopped"),
         "effect": FieldHints(tooltip: "A .vfx file (or another prefab)"),
         "amount": FieldHints(range: 0...1, step: 0.01, tooltip: "0 clear, 1 solid color"),
         "color": FieldHints(color: true),
         "name": FieldHints(tooltip: "The event's name"),
         "value": FieldHints(tooltip: "The event's payload"),
         "dialogue": FieldHints(tooltip: "A .dialogue file to play (empty: the target's DialoguePlayer)"),
         "node": FieldHints(tooltip: "The dialogue node to start at (empty: the DialoguePlayer's start node or the dialogue's start)"),
         "wait": FieldHints(tooltip: "Hold the timeline here until the conversation ends")]
    }

    var key: TimelineKey

    init(key: TimelineKey) { self.key = key }
    init(from decoder: any Decoder) throws { key = try TimelineKey(from: decoder) }
    func encode(to encoder: any Encoder) throws { try key.encode(to: encoder) }
}

@MainActor
public final class TimelineBuilderView {
    public let session: EditorSession
    public let asset: AssetID
    public let view: VStack
    public private(set) var timeline: Timeline
    /// The track being edited.
    public private(set) var selectedTrack: String?
    /// The key being edited (an index into the selected track's keys).
    public private(set) var selectedKey: Int?
    /// Where new keys go (the workspace's playhead).
    public var playhead: Float = 0
    /// The free camera's framing, for Key Camera From View (set by the workspace).
    public var viewCamera: (() -> EditorCamera?)?
    /// Called after the selection changed (the workspace redraws its strip).
    public var onSelectionChange: (() -> Void)?
    let trackList = ListView(items: [], name: "timelineTracks")
    private let gridWorld = World()
    private var grids: [PropertyGrid] = []
    private var listed: [String] = []
    private var newTrackKind = 0
    private var addFieldIndex = 0
    private var removeFieldIndex = 0
    private static var selections: [AssetID: (track: String?, key: Int?)] = [:]
    private var pending: (timeline: Timeline, label: String, track: String?, key: Int?)?

    public init?(session: EditorSession, asset: AssetID) {
        guard session.isTimelineFile(asset), let timeline = session.assets?.timeline(of: asset) else { return nil }
        self.session = session
        self.asset = asset
        self.timeline = timeline.normalized()
        view = VStack(spacing: 6, name: "timelineBuilder")
        let remembered = Self.selections[asset]
        selectedTrack = remembered?.track.flatMap { id in timeline.track(id: id) != nil ? id : nil } ?? timeline.tracks.first?.id
        selectedKey = remembered?.key
        clampKey()
        trackList.style.height = 130
        trackList.onSelect = { [unowned self] row in
            guard let row, listed.indices.contains(row), listed[row] != selectedTrack else { return }
            select(track: listed[row], key: self.timeline.track(id: listed[row])?.keys.isEmpty == false ? 0 : nil)
        }
        layout()
    }

    /// Call every frame: applies the pending edit and keeps the grids in step with their proxies.
    public func refresh() {
        if let pending {
            self.pending = nil
            commit(pending.timeline, label: pending.label, track: pending.track, key: pending.key)
        }
        for grid in grids { grid.refresh() }
    }

    public var hasPendingEdit: Bool { pending != nil }

    /// Rereads the file (after an undo or an edit from elsewhere) and lays the form out again.
    public func reload() {
        guard pending == nil, let timeline = session.assets?.timeline(of: asset) else { return }
        self.timeline = timeline.normalized()
        if timeline.track(id: selectedTrack ?? "") == nil { selectedTrack = timeline.tracks.first?.id }
        clampKey()
        layout()
    }

    private func clampKey() {
        let count = timeline.track(id: selectedTrack ?? "")?.keys.count ?? 0
        if let k = selectedKey, k >= count { selectedKey = count > 0 ? count - 1 : nil }
    }

    // MARK: Selection

    public func select(track: String?, key: Int?) {
        selectedTrack = track
        selectedKey = key
        clampKey()
        Self.selections[asset] = (selectedTrack, selectedKey)
        layout()
        onSelectionChange?()
    }

    // MARK: Layout

    private func layout() {
        view.removeAllChildren()
        for grid in grids { grid.entity = nil }
        grids.removeAll()
        for entity in gridWorld.roots { gridWorld.despawn(entity) }

        let addPlayer = Button("Add Player to Scene", role: .primary, name: "timelineAddPlayer") { [unowned self] in
            session.addTimelinePlayer(for: asset)
        }
        addPlayer.tooltip = "Add an entity with a TimelinePlayer for this timeline to the scene (it plays when the game runs)"
        view.addChild(HStack(spacing: 6, [addPlayer, Spacer()]))

        addSettingsGrid()
        view.addChild(Separator())
        view.addChild(Label("Tracks", role: .secondary))
        listed = timeline.tracks.map(\.id)
        trackList.items = timeline.tracks.map { track in
            let kind = track.trackKind?.title ?? "? \(track.kind)"
            let target = track.target.isEmpty ? "" : " → \(track.target)"
            return "\(track.displayName)  ·  \(kind)\(target)\(track.muted ? "  (muted)" : "")"
        }
        if let selectedTrack, let row = listed.firstIndex(of: selectedTrack) { trackList.selectRow(row, reveal: true) }
        view.addChild(trackList)
        let kinds = Dropdown(options: TimelineTrackKind.allCases.map(\.title), selectedIndex: newTrackKind, name: "timelineNewTrackKind") {
            [unowned self] index in newTrackKind = index
        }
        kinds.tooltip = "The kind of track Add Track makes"
        let add = Button("Add Track", name: "timelineAddTrack") { [unowned self] in addTrack(TimelineTrackKind.allCases[newTrackKind]) }
        add.command = TimelineEditCommand.id.rawValue
        let delete = Button("Delete", name: "timelineDeleteTrack") { [unowned self] in deleteTrack() }
        delete.isEnabled = selectedTrack != nil
        delete.tooltip = "Remove the selected track"
        view.addChild(HStack(spacing: 4, [kinds, add, delete]))

        if let track = timeline.track(id: selectedTrack ?? "") {
            addTrackGrid(track)
            addKeySection(track)
        } else {
            view.addChild(note(timeline.tracks.isEmpty ? "Add a track to start: a camera move, a fade, an event…" : "Pick a track to edit it."))
        }
    }

    private func makeGrid<C: Component>(_ component: C, name: String, onEnd: @escaping (C) -> Void) -> PropertyGrid {
        let entity = gridWorld.spawn(component)
        let grid = PropertyGrid(world: gridWorld, name: name)
        grid.appliesEditsToWorld = false
        grid.labelWidth = 96
        grid.entity = entity
        grid.command = TimelineEditCommand.id.rawValue
        grid.onFieldEdit = { [unowned self] edit in
            do { try gridWorld.setField(edit.path, of: C.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Timeline \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended, let value = gridWorld.get(C.self, for: entity) { onEnd(value) }
        }
        grids.append(grid)
        return grid
    }

    private func addSettingsGrid() {
        view.addChild(Label("Timeline", role: .secondary))
        let grid = makeGrid(TimelineSettingsComponent(timeline), name: "timelineSettingsGrid") { [unowned self] s in
            var edited = timeline
            edited.duration = max(s.duration, 0.1)
            edited.loop = s.loop
            edited.skippable = s.skippable
            edited.holdFade = s.holdFade
            apply(edited, label: "Edit Timeline", track: selectedTrack, key: selectedKey)
        }
        view.addChild(grid)
    }

    private func addTrackGrid(_ track: TimelineTrack) {
        view.addChild(Separator())
        view.addChild(Label("Track: \(track.displayName) (\(track.trackKind?.title ?? track.kind))", role: .secondary))
        let grid = makeGrid(TimelineTrackComponent(track), name: "timelineTrackGrid") { [unowned self] t in
            guard let index = timeline.trackIndex(id: track.id) else { return }
            var edited = timeline
            let newID = t.id.trimmingCharacters(in: .whitespaces)
            var id = track.id
            if !newID.isEmpty, newID != track.id {
                if timeline.track(id: newID) != nil { session.log.warning("Timeline: a track is already named \(newID)") } else { id = newID }
            }
            edited.tracks[index].id = id
            edited.tracks[index].name = t.name
            edited.tracks[index].target = t.target.trimmingCharacters(in: .whitespaces)
            edited.tracks[index].muted = t.muted
            apply(edited, label: "Edit Track", track: id, key: selectedKey)
        }
        grid.stringChoices = { [unowned self] _, path in
            guard path == "target" else { return nil }
            var names: [String] = [""]
            session.world.query(Name.self) { _, name in if !names.contains(name.value) { names.append(name.value) } }
            return names
        }
        grid.stringChoiceTitle = { _, _, value in value.isEmpty ? Self.defaultTargetTitle(track.trackKind) : value }
        view.addChild(grid)
    }

    static func defaultTargetTitle(_ kind: TimelineTrackKind?) -> String {
        switch kind {
        case .camera: "(active camera)"
        case .audio: "(unpositioned)"
        case .particles: "(world origin)"
        case .dialogue: "(the player's entity, or the key's file)"
        default: "(the player's entity)"
        }
    }

    private func addKeySection(_ track: TimelineTrack) {
        view.addChild(Separator())
        let header = track.keys.isEmpty ? "Keys: none" : "Keys: \(track.keys.count)"
        view.addChild(Label(header, role: .secondary))
        let addKey = Button("Add Key at Playhead", name: "timelineAddKey") { [unowned self] in addKey(to: track.id) }
        addKey.command = TimelineEditCommand.id.rawValue
        addKey.tooltip = "Add a key at the playhead, holding the track's current values there"
        let deleteKey = Button("Delete Key", name: "timelineDeleteKey") { [unowned self] in deleteSelectedKey() }
        deleteKey.isEnabled = selectedKey != nil
        var row: [Widget] = [addKey, deleteKey]
        if track.trackKind == .camera {
            let fromView = Button("Key From View", name: "timelineKeyFromView") { [unowned self] in keyCameraFromView(track.id) }
            fromView.tooltip = "Add a camera key at the playhead framed like the preview's free camera"
            row.append(fromView)
        }
        view.addChild(HStack(spacing: 4, row + [Spacer()]))
        guard let k = selectedKey, track.keys.indices.contains(k) else {
            view.addChild(note("Click a key in the strip under the preview to edit it; double-click a track's row to add one there."))
            return
        }
        let key = track.keys[k]
        view.addChild(Label(String(format: "Key %d at %.2f s", k + 1, key.time), role: .secondary))
        let grid = makeGrid(TimelineKeyComponent(key: key), name: "timelineKeyGrid") { [unowned self] proxy in
            guard let t = timeline.trackIndex(id: track.id), timeline.tracks[t].keys.indices.contains(k) else { return }
            var edited = timeline
            edited.tracks[t].keys[k] = proxy.key
            let sorted = edited.normalized()
            // Follow the key if the edit moved it past a neighbor.
            let index = sorted.tracks[t].keys.firstIndex(of: proxy.key) ?? k
            apply(sorted, label: "Edit Key", track: track.id, key: index)
        }
        view.addChild(grid)

        // Which fields the key sets.
        let fields = track.trackKind?.keyFields ?? []
        let set = Self.setFields(of: key)
        let addable = fields.filter { !set.contains($0) }
        let removable = fields.filter { set.contains($0) }
        if !addable.isEmpty {
            addFieldIndex = min(addFieldIndex, addable.count - 1)
            let picker = Dropdown(options: addable, selectedIndex: addFieldIndex, name: "timelineAddFieldKind") { [unowned self] i in addFieldIndex = i }
            let button = Button("Add Field", name: "timelineAddField") { [unowned self] in
                setField(addable[min(addFieldIndex, addable.count - 1)], on: track.id, key: k, present: true)
            }
            button.tooltip = "Set another of this key's fields (unset fields hold the neighboring keys' values)"
            view.addChild(HStack(spacing: 4, [picker, button, Spacer()]))
        }
        if !removable.isEmpty {
            removeFieldIndex = min(removeFieldIndex, removable.count - 1)
            let picker = Dropdown(options: removable, selectedIndex: removeFieldIndex, name: "timelineRemoveFieldKind") { [unowned self] i in removeFieldIndex = i }
            let button = Button("Remove Field", name: "timelineRemoveField") { [unowned self] in
                setField(removable[min(removeFieldIndex, removable.count - 1)], on: track.id, key: k, present: false)
            }
            view.addChild(HStack(spacing: 4, [picker, button, Spacer()]))
        }
        view.addChild(note(Self.kindNote(track.trackKind)))
    }

    static func kindNote(_ kind: TimelineTrackKind?) -> String {
        switch kind {
        case .camera: "Camera keys blend position, aim and field of view with the later key's easing; a cut jumps. A path makes a spline move to the next key."
        case .transform: "Transform keys blend the target's position, rotation and scale (parent space)."
        case .animation: "Plays the clip on the target's Animator (or SpriteAnimator) when reached. Not shown in this preview."
        case .audio: "Plays the sound when reached (heard in play mode, not in this preview)."
        case .particles: "Spawns the effect at the target when reached, for its duration."
        case .fade: "Fades the screen toward the color by amount."
        case .event: "Game code sees the event in TimelinePlayer.events and world.timelineEvents()."
        case .dialogue: "Starts the target's DialoguePlayer conversation (or the key's .dialogue file) at the node; Wait holds the timeline until it ends. The preview shows it: click the box to continue."
        case nil: "This track's kind is unknown to this engine version; it is kept but skipped."
        }
    }

    /// The names of the optional fields `key` sets.
    static func setFields(of key: TimelineKey) -> Set<String> {
        guard let data = try? JSONEncoder().encode(key), let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }
        return Set(object.keys).subtracting(["time"])
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "timelineNote")
        label.wraps = true
        return label
    }

    // MARK: Edits

    private func apply(_ edited: Timeline, label: String, track: String?, key: Int?) {
        pending = (edited, label, track, key)
    }

    private func commit(_ edited: Timeline, label: String, track: String?, key: Int?) {
        guard session.applyTimeline(edited, to: asset, label: label) != nil else { return }
        timeline = (session.assets?.timeline(of: asset) ?? edited).normalized()
        select(track: timeline.track(id: track ?? "") != nil ? track : timeline.tracks.first?.id, key: key)
    }

    /// Applies an edit made elsewhere in the tab (the strip) as one undo step.
    public func applyEdit(_ edited: Timeline, label: String, track: String?, key: Int?) {
        apply(edited, label: label, track: track, key: key)
    }

    func addTrack(_ kind: TimelineTrackKind) {
        var edited = timeline
        let id = edited.uniqueTrackID(kind.rawValue)
        var track = TimelineTrack(id: id, kind: kind, name: kind.title)
        track.keys = [Self.defaultKey(kind, at: playhead, in: nil)]
        edited.tracks.append(track)
        apply(edited, label: "Add \(kind.title) Track", track: id, key: 0)
    }

    func deleteTrack() {
        guard let id = selectedTrack else { return }
        var edited = timeline
        edited.tracks.removeAll { $0.id == id }
        apply(edited, label: "Delete Track", track: nil, key: nil)
    }

    func addKey(to trackID: String, at time: Float? = nil) {
        guard let t = timeline.trackIndex(id: trackID) else { return }
        let time = min(max(time ?? playhead, 0), timeline.duration)
        var edited = timeline
        let track = edited.tracks[t]
        let key = Self.defaultKey(track.trackKind, at: time, in: track)
        if let existing = track.keyIndex(at: time) { edited.tracks[t].keys[existing] = key } else { edited.tracks[t].keys.append(key) }
        edited = edited.normalized()
        apply(edited, label: "Add Key", track: trackID, key: edited.tracks[t].keyIndex(at: time))
    }

    func keyCameraFromView(_ trackID: String) {
        guard let t = timeline.trackIndex(id: trackID), let camera = viewCamera?() else { return }
        let time = min(max(playhead, 0), timeline.duration)
        var edited = timeline
        let key = TimelineKey(time: time, easing: .sineInOut, position: camera.eye, lookAt: camera.pivot, fov: camera.fovY * 180 / .pi)
        if let existing = edited.tracks[t].keyIndex(at: time) { edited.tracks[t].keys[existing] = key } else { edited.tracks[t].keys.append(key) }
        edited = edited.normalized()
        apply(edited, label: "Key Camera From View", track: trackID, key: edited.tracks[t].keyIndex(at: time))
    }

    func deleteSelectedKey() {
        guard let id = selectedTrack, let t = timeline.trackIndex(id: id), let k = selectedKey, timeline.tracks[t].keys.indices.contains(k) else { return }
        var edited = timeline
        edited.tracks[t].keys.remove(at: k)
        apply(edited, label: "Delete Key", track: id, key: edited.tracks[t].keys.isEmpty ? nil : max(k - 1, 0))
    }

    /// Moves key `k` of `trackID` to `time` (the strip's drag).
    func moveKey(_ trackID: String, _ k: Int, to time: Float) {
        guard let t = timeline.trackIndex(id: trackID), timeline.tracks[t].keys.indices.contains(k) else { return }
        var edited = timeline
        var key = edited.tracks[t].keys[k]
        key.time = min(max(time, 0), timeline.duration)
        edited.tracks[t].keys[k] = key
        edited = edited.normalized()
        apply(edited, label: "Move Key", track: trackID, key: edited.tracks[t].keys.firstIndex(of: key))
    }

    private func setField(_ field: String, on trackID: String, key k: Int, present: Bool) {
        guard let t = timeline.trackIndex(id: trackID), timeline.tracks[t].keys.indices.contains(k) else { return }
        let track = timeline.tracks[t]
        var key = track.keys[k]
        if present {
            let filled = Self.defaultKey(track.trackKind, at: key.time, in: track, fields: [field])
            guard let value = try? TimelineEditCommand.merged(filled, [:], ""), let json = try? JSONValue.encoding(value),
                  case .object(let object) = json, let fieldValue = object[field] ?? Self.fallback(field) else { return }
            key = (try? TimelineEditCommand.merged(key, [field: fieldValue], "")) ?? key
        } else {
            key = (try? TimelineEditCommand.merged(key, [field: .null], "")) ?? key
        }
        var edited = timeline
        edited.tracks[t].keys[k] = key
        apply(edited, label: present ? "Add Key Field" : "Remove Key Field", track: trackID, key: k)
    }

    static func fallback(_ field: String) -> JSONValue? {
        switch field {
        case "easing": .string(Easing.sineInOut.rawValue)
        case "lookAtEntity", "clip", "effect", "name", "value", "dialogue", "node": .string("")
        case "cut", "loop", "followPath", "wait": .bool(true)
        case "path": .array([])
        case "position", "rotation", "lookAt", "color": .array([.double(0), .double(0), .double(0)])
        case "scale": .array([.double(1), .double(1), .double(1)])
        case "fov": .double(50)
        case "blend": .double(0.25)
        case "speed", "volume", "pitch", "amount": .double(1)
        case "duration": .double(2)
        default: nil
        }
    }

    /// A new key for a track of `kind` at `time`: continuous tracks hold their current values
    /// there (camera: position, aim, fov; transform: position, rotation, scale; fade: amount,
    /// color), discrete ones get placeholders. `fields` limits which fields are filled.
    static func defaultKey(_ kind: TimelineTrackKind?, at time: Float, in track: TimelineTrack?, fields: Set<String>? = nil) -> TimelineKey {
        var key = TimelineKey(time: time)
        func wants(_ field: String) -> Bool { fields?.contains(field) ?? true }
        switch kind {
        case .camera:
            let pose = track.map { TimelineEvaluator.cameraPose($0, at: time, in: nil) }
            if wants("position") { key.position = pose?.position ?? Vec3(0, 2, 8) }
            if fields == nil {
                if let rotation = pose?.rotation { key.rotation = rotation.eulerDegrees } else { key.lookAt = Vec3(0, 1, 0) }
            } else {
                if wants("rotation") { key.rotation = pose?.rotation?.eulerDegrees ?? .zero }
                if wants("lookAt") { key.lookAt = Vec3(0, 1, 0) }
            }
            if wants("fov") { key.fov = pose?.fovDegrees ?? 50 }
            if fields == nil { key.easing = .sineInOut } else if wants("easing") { key.easing = .sineInOut }
        case .transform:
            if wants("position") { key.position = track?.vec3(\.position, at: time) ?? .zero }
            if fields == nil {
                if let rotation = track?.rotation(at: time) { key.rotation = rotation.eulerDegrees }
                if let scale = track?.vec3(\.scale, at: time) { key.scale = scale }
                key.easing = .sineInOut
            } else {
                if wants("rotation") { key.rotation = track?.rotation(at: time)?.eulerDegrees ?? .zero }
                if wants("scale") { key.scale = track?.vec3(\.scale, at: time) ?? Vec3(1, 1, 1) }
                if wants("easing") { key.easing = .sineInOut }
            }
        case .fade:
            let fade = track?.fade(at: time)
            if wants("amount") { key.amount = fade?.amount ?? 0 }
            if wants("color") { key.color = fade?.color ?? Vec3(0, 0, 0) }
            if fields != nil, wants("easing") { key.easing = .linear }
        case .animation:
            if wants("clip") { key.clip = track?.keys.last?.clip ?? "idle" }
            if fields != nil {
                if wants("blend") { key.blend = 0.25 }
                if wants("speed") { key.speed = 1 }
            }
        case .audio:
            if wants("clip") { key.clip = track?.keys.last?.clip ?? "" }
            if fields != nil {
                if wants("volume") { key.volume = 1 }
                if wants("pitch") { key.pitch = 1 }
                if wants("loop") { key.loop = true }
                if wants("duration") { key.duration = 2 }
                if wants("position") { key.position = .zero }
            }
        case .particles:
            if wants("effect") { key.effect = track?.keys.last?.effect ?? "" }
            if fields != nil {
                if wants("duration") { key.duration = 2 }
                if wants("position") { key.position = .zero }
                if wants("rotation") { key.rotation = .zero }
            }
        case .event:
            if wants("name") { key.name = track.map { "event\($0.keys.count + 1)" } ?? "event" }
            if fields != nil, wants("value") { key.value = "" }
        case .dialogue:
            let last = track?.keys.last
            if fields == nil {
                key.wait = true
                if let file = last?.dialogue { key.dialogue = file }
                if let node = last?.node { key.node = node }
            } else {
                if wants("dialogue") { key.dialogue = last?.dialogue ?? "" }
                if wants("node") { key.node = last?.node ?? "" }
                if wants("wait") { key.wait = true }
            }
        case nil:
            break
        }
        if fields != nil {
            // Fields the switch didn't cover.
            if wants("lookAtEntity") { key.lookAtEntity = "" }
            if wants("cut") { key.cut = true }
            if wants("path") { key.path = [] }
            if wants("followPath") { key.followPath = true }
        }
        return key
    }
}
