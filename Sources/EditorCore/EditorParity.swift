import Engine

/// What every way of acting in the editor's UI runs, for the parity test (`ParityTests`): every
/// toolbar button, menu item, shortcut, context-menu entry and drag-and-drop target must map to
/// a command that MCP serves as a tool, so AI clients can do whatever the user can.
///
/// Widgets declare their command themselves (`Widget.command`, `itemCommands`,
/// `PopupMenu.itemCommandIDs`); `ui.snapshot` reports it, and the test walks the whole UI with
/// its menus open. Shortcuts are `EditorShortcuts.boundCommands`. Drags aren't widgets, so they
/// are listed here; `dropCommands(for:)` switches over `AssetDropTarget` exhaustively, so a new
/// kind of drop target doesn't compile until it names its command.
@MainActor
public enum EditorParity {
    /// A drag the UI supports and the command it runs.
    public struct Drag: Sendable {
        public var source: String
        public var target: String
        public var command: CommandID
    }

    public static let drags: [Drag] = [
        Drag(source: "a model, prefab or mesh in the Assets panel", target: "the viewport or a hierarchy row", command: AssetInstantiateCommand.id),
        Drag(source: "a material or mesh in the Assets panel", target: "an object in the viewport, a hierarchy row or a MeshRenderer field",
             command: AssetAssignCommand.id),
        Drag(source: "a file or folder in the Assets panel", target: "a folder of the folder tree", command: AssetMoveCommand.id),
        Drag(source: "hierarchy rows", target: "another row (child) or between rows (sibling)", command: EntityReparentCommand.id),
        Drag(source: "a dock tab", target: "a tab bar, a group's edge or the dock's edge", command: PanelDockCommand.id),
        Drag(source: "a gizmo handle", target: "the viewport", command: TransformSetCommand.id),
        Drag(source: "a number field (scrub) or a color", target: "itself", command: ComponentSetFieldCommand.id),
    ]

    /// The commands a drop on `target` can run (`EditorSession.drop(_:on:)`).
    public static func dropCommands(for target: AssetDropTarget) -> [CommandID] {
        switch target {
        case .viewport: [AssetInstantiateCommand.id, AssetAssignCommand.id]
        case .hierarchy: [AssetInstantiateCommand.id, AssetAssignCommand.id]
        case .field: [AssetAssignCommand.id]
        }
    }

    /// One of each drop target, for checking `dropCommands`.
    public static let sampleDropTargets: [AssetDropTarget] = [
        .viewport(position: .zero, entity: nil), .hierarchy(parent: nil, position: .zero),
        .field(entity: EntityID(high: 0, low: 1), kind: .material),
    ]
}
