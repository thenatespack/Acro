import EditorCore
import Engine
import Foundation

/// The builder tabs of this module: the Visual Script, Behavior Tree and Dialogue tabs (see EditorCore/EditorBuilders.swift).
@MainActor
package enum EditorBuildersLogic {
    package static var modules: [EditorBuilderModule] { [visualScript, behaviorTree, dialogue] }

    static let visualScriptAsset = EditorBuilderAsset(isFile: { $0.isVisualScriptFile($1) }, newTitle: "New Visual Script", newCommand: VScriptNewCommand.id,
                                             create: { $0.run(VScriptNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(VScriptOpenCommand.self, .init(asset: AssetReference($1))) })

    static var visualScript: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.visualScript, title: "Visual Script", minSize: Vec2(360, 220), commands: EditorVisualScriptCommands.all, asset: visualScriptAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isVisualScriptFile(id) else { return nil }
            let open = Button("Open in Visual Script", role: .primary, name: "openVisualScript") { [unowned session] in
                session.run(VScriptOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = VScriptOpenCommand.id.rawValue
            open.tooltip = "Edit this graph in the Visual Script tab (or double-click it in the Assets panel)"
            let attach = Button("Attach to Selection", name: "attachVisualScript") { [unowned session] in
                if let entity = session.selection.ids.first { session.run(VScriptAttachCommand.self, .init(asset: AssetReference(id), entity: entity)) }
            }
            attach.command = VScriptAttachCommand.id.rawValue
            attach.tooltip = "Run this graph on the selected entity (adds a VisualScript component)"
            let graph = session.assets?.visualScript(of: id)
            return [HStack(spacing: 6, [open, attach, Spacer()]),
                    context.note("A visual script of \(graph?.nodes.count ?? 0) nodes. It runs on entities with a VisualScript component in play mode and built games.")]
        }) { app in
            let workspace = VisualScriptWorkspace(session: app.session)
            return EditorBuilderTab(workspace: workspace, view: workspace.view, update: { [unowned workspace] _, _ in workspace.update() },
                                    connect: { [unowned app, unowned workspace] in
                app.session.onOpenVisualScript = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.visualScript)
                }
            })
        }
    }

    static let behaviorTreeAsset = EditorBuilderAsset(isFile: { $0.isBehaviorFile($1) }, newTitle: "New Behavior Tree", newCommand: BehaviorNewCommand.id,
                                             create: { $0.run(BehaviorNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(BehaviorOpenCommand.self, .init(asset: AssetReference($1))) })

    static var behaviorTree: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.behaviorTree, title: "Behavior Tree", commands: EditorBehaviorCommands.all + EditorNavigationCommands.all, asset: behaviorTreeAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isBehaviorFile(id) else { return nil }
            let open = Button("Open in Behavior Tree Builder", role: .primary, name: "openBehaviorTree") { [unowned session] in
                session.run(BehaviorOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = BehaviorOpenCommand.id.rawValue
            open.tooltip = "Edit this tree in the Behavior Tree tab (or double-click it in the Assets panel)"
            let count = session.assets?.behaviorTreeContents(of: id)?.nodes.count ?? 0
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("NPC AI of \(count) node\(count == 1 ? "" : "s"). An entity runs it in play mode with a BehaviorTreeRunner component (behavior.assign).")]
        }) { app in
            let workspace = BehaviorTreeWorkspace(session: app.session)
            return EditorBuilderTab(workspace: workspace, view: workspace.view, update: { [unowned workspace] _, _ in workspace.update() },
                                    connect: { [unowned app, unowned workspace] in
                app.session.onOpenBehavior = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.behaviorTree)
                }
            })
        }
    }

    static let dialogueAsset = EditorBuilderAsset(isFile: { $0.isDialogueFile($1) }, newTitle: "New Dialogue", newCommand: DialogueNewCommand.id,
                                             create: { $0.run(DialogueNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(DialogueOpenCommand.self, .init(asset: AssetReference($1))) })

    static var dialogue: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.dialogueBuilder, title: "Dialogue", commands: EditorDialogueCommands.all, asset: dialogueAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isDialogueFile(id) else { return nil }
            let open = Button("Open in Dialogue Builder", role: .primary, name: "openDialogueBuilder") { [unowned session] in
                session.run(DialogueOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = DialogueOpenCommand.id.rawValue
            open.tooltip = "Edit this conversation in the Dialogue tab (or double-click it in the Assets panel)"
            let dialogue = session.assets?.dialogueContents(of: id)
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("A conversation of \(dialogue?.nodes.count ?? 0) nodes. A DialoguePlayer component plays it in game; the Dialogue tab has a graph view and a play-through preview.")]
        }) { app in
            let workspace = DialogueWorkspace(session: app.session)
            workspace.images = { [unowned app] path in app.projectTexture(path, fullSize: false) }
            return EditorBuilderTab(workspace: workspace, view: workspace.view, update: { [unowned workspace] _, _ in workspace.update() },
                                    connect: { [unowned app, unowned workspace] in
                app.session.onOpenDialogue = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.dialogueBuilder)
                }
            })
        }
    }
}


extension EditorApp {
    /// The Visual Script tab (VisualScriptWorkspace.swift).
    public var visualScriptWorkspace: VisualScriptWorkspace! { builderWorkspace(VisualScriptWorkspace.self) }
    /// The Behavior Tree tab (BehaviorTreeWorkspace.swift).
    public var behaviorWorkspace: BehaviorTreeWorkspace! { builderWorkspace(BehaviorTreeWorkspace.self) }
    /// The Dialogue tab (DialogueWorkspace.swift).
    public var dialogueWorkspace: DialogueWorkspace! { builderWorkspace(DialogueWorkspace.self) }
}

extension AssetBrowserModel {
    /// Creates a visual script in the current folder (`vscript.new`) and selects it.
    @discardableResult
    public func newVisualScript() -> AssetID? { newBuilderAsset(EditorBuildersLogic.visualScriptAsset) }

    /// Creates a behavior tree in the current folder (`behavior.new`) and selects it.
    @discardableResult
    public func newBehaviorTree() -> AssetID? { newBuilderAsset(EditorBuildersLogic.behaviorTreeAsset) }

    /// Creates a dialogue in the current folder (`dialogue.new`) and selects it.
    @discardableResult
    public func newDialogue() -> AssetID? { newBuilderAsset(EditorBuildersLogic.dialogueAsset) }
}
