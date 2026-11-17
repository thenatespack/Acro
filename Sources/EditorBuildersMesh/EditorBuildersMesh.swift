import EditorCore
import Engine
import Foundation

/// The builder tabs of this module: the Mesh Builder, the VFX Builder and the Material Builder (see EditorCore/EditorBuilders.swift).
@MainActor
package enum EditorBuildersMesh {
    package static var modules: [EditorBuilderModule] { [meshBuild, vfx, material] }

    static let meshBuildAsset = EditorBuilderAsset(isFile: { $0.isMeshBuildFile($1) }, newTitle: "New Mesh Build", newCommand: MeshBuildNewCommand.id,
                                             create: { $0.run(MeshBuildNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(MeshBuildOpenCommand.self, .init(asset: AssetReference($1))) })

    static var meshBuild: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.meshBuilder, title: "Mesh Builder", passesPointerThrough: true, commands: EditorMeshBuildCommands.all, asset: meshBuildAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isMeshBuildFile(id) else { return nil }
            let open = Button("Open in Mesh Builder", role: .primary, name: "openMeshBuilder") { [unowned session] in
                session.run(MeshBuildOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = MeshBuildOpenCommand.id.rawValue
            open.tooltip = "Edit this model in the Mesh Builder tab (or double-click it in the Assets panel)"
            let parts = session.assets?.meshBuild(of: id)?.parts.count ?? 0
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("A model built from \(parts) shape\(parts == 1 ? "" : "s"). The Mesh Builder shows it in a view of its own, with gizmos, the parts list and live animation.")]
        }) { app in
            let workspace = MeshBuilderWorkspace(session: app.session)
            return .viewport(workspace, app: app) { [unowned app, unowned workspace] in
                app.session.onOpenMeshBuild = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.meshBuilder)
                }
            }
        }
    }

    static let vfxAsset = EditorBuilderAsset(isFile: { $0.isVFXFile($1) }, newTitle: "New VFX", newCommand: VFXNewCommand.id,
                                             create: { $0.run(VFXNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(VFXOpenCommand.self, .init(asset: AssetReference($1))) })

    static var vfx: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.vfxBuilder, title: "VFX Builder", passesPointerThrough: true, commands: EditorVFXCommands.all, asset: vfxAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isVFXFile(id) else { return nil }
            let open = Button("Open in VFX Builder", role: .primary, name: "openVFXBuilder") { [unowned session] in
                session.run(VFXOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = VFXOpenCommand.id.rawValue
            open.tooltip = "Edit this effect in the VFX Builder tab (or double-click it in the Assets panel)"
            let count = session.assets?.vfx(of: id)?.emitters.count ?? 0
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("A visual effect of \(count) particle emitter\(count == 1 ? "" : "s"). Place it like a model; the VFX Builder previews it looping.")]
        }) { app in
            let workspace = VFXBuilderWorkspace(session: app.session)
            return .viewport(workspace, app: app) { [unowned app, unowned workspace] in
                app.session.onOpenVFX = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.vfxBuilder)
                }
            }
        }
    }

    static let materialAsset = EditorBuilderAsset(isFile: { $0.isMaterialFile($1) }, newTitle: "New Material Graph", newCommand: MaterialGraphNewCommand.id,
                                             create: { $0.run(MaterialGraphNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(MaterialGraphOpenCommand.self, .init(asset: AssetReference($1))) })

    static var material: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.materialBuilder, title: "Material Builder", passesPointerThrough: true, commands: EditorMaterialGraphCommands.all, asset: materialAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isMaterialFile(id) else { return nil }
            let open = Button("Open in Material Builder", role: .primary, name: "openMaterialBuilder") { [unowned session] in
                session.run(MaterialGraphOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = MaterialGraphOpenCommand.id.rawValue
            open.tooltip = "Build this material's look as a node graph in the Material Builder tab (or double-click it in the Assets panel)"
            let nodes = session.assets?.materialFile(of: id)?.graph?.nodes.count
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note(nodes.map { "A node graph of \($0) node\($0 == 1 ? "" : "s"), compiled into a shader variant; the fields below are unused apart from alpha, sides and sampling." }
                         ?? "Fixed PBR settings. The Material Builder can convert them to a node graph.")]
        }) { app in
            let workspace = MaterialBuilderWorkspace(session: app.session)
            return .viewport(workspace, app: app) { [unowned app, unowned workspace] in
                app.session.onOpenMaterialGraph = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    workspace.applyRequest(from: app.session)
                    app.showBuilderPanel(EditorLayout.materialBuilder)
                }
            }
        }
    }
}

extension MeshBuilderWorkspace: EditorViewportBuilder {}
extension VFXBuilderWorkspace: EditorViewportBuilder {}
extension MaterialBuilderWorkspace: EditorViewportBuilder {}

extension EditorApp {
    /// The Mesh Builder tab (MeshBuilderWorkspace.swift).
    public var meshWorkspace: MeshBuilderWorkspace! { builderWorkspace(MeshBuilderWorkspace.self) }
    /// The VFX Builder tab (VFXBuilderWorkspace.swift).
    public var vfxWorkspace: VFXBuilderWorkspace! { builderWorkspace(VFXBuilderWorkspace.self) }
    /// The Material Builder tab (MaterialBuilderWorkspace.swift).
    public var materialWorkspace: MaterialBuilderWorkspace! { builderWorkspace(MaterialBuilderWorkspace.self) }
}

extension AssetBrowserModel {
    /// Creates a mesh build in the current folder (`meshBuild.new`) and selects it, so the
    /// inspector shows the Mesh Builder.
    @discardableResult
    public func newMeshBuild() -> AssetID? { newBuilderAsset(EditorBuildersMesh.meshBuildAsset) }

    /// Creates a VFX effect in the current folder (`vfx.new`) and selects it.
    @discardableResult
    public func newVFX() -> AssetID? { newBuilderAsset(EditorBuildersMesh.vfxAsset) }

    /// Creates a material with a node graph in the current folder (`materialGraph.new`) and selects it.
    @discardableResult
    public func newMaterialGraph() -> AssetID? { newBuilderAsset(EditorBuildersMesh.materialAsset) }
}
