import EditorCore
import Engine
import Foundation

/// The builder tabs of this module: the Timeline, the Animation Graph Builder and the Character Builder (see EditorCore/EditorBuilders.swift).
@MainActor
package enum EditorBuildersAnimation {
    package static var modules: [EditorBuilderModule] { [timeline, animationGraph, character] }

    static let timelineAsset = EditorBuilderAsset(isFile: { $0.isTimelineFile($1) }, newTitle: "New Timeline", newCommand: TimelineNewCommand.id,
                                             create: { $0.run(TimelineNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(TimelineOpenCommand.self, .init(asset: AssetReference($1))) })

    static var timeline: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.timeline, title: "Timeline", passesPointerThrough: true, commands: EditorTimelineCommands.all, asset: timelineAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isTimelineFile(id) else { return nil }
            let open = Button("Open in Timeline", role: .primary, name: "openTimeline") { [unowned session] in
                session.run(TimelineOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = TimelineOpenCommand.id.rawValue
            open.tooltip = "Edit this cutscene in the Timeline tab (or double-click it in the Assets panel)"
            let addPlayer = Button("Add Player to Scene", name: "addTimelinePlayer") { [unowned session] in
                session.addTimelinePlayer(for: id)
            }
            addPlayer.tooltip = "Add an entity with a TimelinePlayer that plays this timeline when the game runs"
            let timeline = session.assets?.timeline(of: id)
            return [HStack(spacing: 6, [open, addPlayer, Spacer()]),
                    context.note(String(format: "A %.1f s cutscene with %d track%@. A TimelinePlayer component plays it; game code reads its events.",
                                timeline?.duration ?? 0, timeline?.tracks.count ?? 0, (timeline?.tracks.count ?? 0) == 1 ? "" : "s"))]
        }) { app in
            let workspace = TimelineWorkspace(session: app.session)
            return .viewport(workspace, app: app) { [unowned app, unowned workspace] in
                app.session.onOpenTimeline = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.timeline)
                }
            }
        }
    }

    static let animationGraphAsset = EditorBuilderAsset(isFile: { $0.isAnimationGraphFile($1) }, newTitle: "New Animation Graph", newCommand: AnimGraphNewCommand.id,
                                             create: { $0.run(AnimGraphNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(AnimGraphOpenCommand.self, .init(asset: AssetReference($1))) })

    static var animationGraph: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.animationGraph, title: "Animation Graph", passesPointerThrough: true, commands: EditorAnimationGraphCommands.all, asset: animationGraphAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isAnimationGraphFile(id) else { return nil }
            let open = Button("Open in Animation Graph Builder", role: .primary, name: "openAnimationGraphBuilder") { [unowned session] in
                session.run(AnimGraphOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = AnimGraphOpenCommand.id.rawValue
            open.tooltip = "Edit this graph's states and transitions in the Animation Graph Builder tab (or double-click it in the Assets panel)"
            let graph = session.assets?.animationGraph(of: id)
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("An animation state machine of \(graph?.states.count ?? 0) states and \(graph?.transitions.count ?? 0) transitions. Put it on a placed model with animGraph.assign (or the builder's Put on Selection).")]
        }) { app in
            let workspace = AnimationGraphWorkspace(session: app.session)
            return .viewport(workspace, app: app) { [unowned app, unowned workspace] in
                app.session.onOpenAnimationGraph = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.animationGraph)
                }
            }
        }
    }

    static let characterAsset = EditorBuilderAsset(isFile: { $0.isCharacterFile($1) }, newTitle: "New Character", newCommand: CharacterNewCommand.id,
                                             create: { $0.run(CharacterNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(CharacterOpenCommand.self, .init(asset: AssetReference($1))) })

    static var character: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.characterBuilder, title: "Character Builder", passesPointerThrough: true, commands: EditorCharacterCommands.all, asset: characterAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isCharacterFile(id) else { return nil }
            let open = Button("Open in Character Builder", role: .primary, name: "openCharacterBuilder") { [unowned session] in
                session.run(CharacterOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = CharacterOpenCommand.id.rawValue
            open.tooltip = "Shape, color, gear up and preview this character in the Character Builder tab (or double-click it in the Assets panel)"
            let character = session.assets?.character(of: id)
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("A rigged \(character?.template.rawValue ?? "") character with \(character?.rig.bones.count ?? 0) bones and \(character?.clipNames.count ?? 0) stock clips, imported as a skinned prefab with an Animator.")]
        }) { app in
            let workspace = CharacterBuilderWorkspace(session: app.session)
            return .viewport(workspace, app: app) { [unowned app, unowned workspace] in
                app.session.onOpenCharacter = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.characterBuilder)
                }
            }
        }
    }
}

extension TimelineWorkspace: EditorViewportBuilder {}
extension AnimationGraphWorkspace: EditorViewportBuilder {}
extension CharacterBuilderWorkspace: EditorViewportBuilder {}

extension EditorApp {
    /// The Timeline tab (TimelineWorkspace.swift).
    public var timelineWorkspace: TimelineWorkspace! { builderWorkspace(TimelineWorkspace.self) }
    /// The Animation Graph Builder tab (AnimationGraphWorkspace.swift).
    public var animGraphWorkspace: AnimationGraphWorkspace! { builderWorkspace(AnimationGraphWorkspace.self) }
    /// The Character Builder tab (CharacterBuilderWorkspace.swift).
    public var characterWorkspace: CharacterBuilderWorkspace! { builderWorkspace(CharacterBuilderWorkspace.self) }
}

extension AssetBrowserModel {
    /// Creates a timeline in the current folder (`timeline.new`) and selects it.
    @discardableResult
    public func newTimeline() -> AssetID? { newBuilderAsset(EditorBuildersAnimation.timelineAsset) }

    /// Creates an animation graph in the current folder (`animGraph.new`) and selects it.
    @discardableResult
    public func newAnimationGraph() -> AssetID? { newBuilderAsset(EditorBuildersAnimation.animationGraphAsset) }

    /// Creates a character in the current folder (`character.new`) and selects it.
    @discardableResult
    public func newCharacter() -> AssetID? { newBuilderAsset(EditorBuildersAnimation.characterAsset) }
}
