import EditorCore
import Engine
import Foundation

/// The builder tabs of this module: the Terrain Builder, the GridMap Builder and the Path Builder (see EditorCore/EditorBuilders.swift).
@MainActor
package enum EditorBuildersWorld {
    package static var modules: [EditorBuilderModule] { [terrain, gridMap, path] }

    static let terrainAsset = EditorBuilderAsset(isFile: { $0.isTerrainFile($1) }, newTitle: "New Terrain", newCommand: TerrainNewCommand.id,
                                             create: { $0.run(TerrainNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(TerrainOpenCommand.self, .init(asset: AssetReference($1))) })

    static var terrain: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.terrainBuilder, title: "Terrain Builder", passesPointerThrough: true, commands: EditorTerrainCommands.all, asset: terrainAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isTerrainFile(id) else { return nil }
            let open = Button("Open in Terrain Builder", role: .primary, name: "openTerrainBuilder") { [unowned session] in
                session.run(TerrainOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = TerrainOpenCommand.id.rawValue
            open.tooltip = "Sculpt, paint and scatter this terrain in the Terrain Builder tab (or double-click it in the Assets panel)"
            let size = session.assets?.terrain(of: id)?.size ?? .zero
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("A heightmap terrain, \(Int(size.x)) x \(Int(size.y)) m, split into chunks with colliders. The Terrain Builder has brushes, texture layers and scatter rules.")]
        }) { app in
            let workspace = TerrainBuilderWorkspace(session: app.session)
            return .viewport(workspace, app: app) { [unowned app, unowned workspace] in
                app.session.onOpenTerrain = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.terrainBuilder)
                }
            }
        }
    }

    static let gridMapAsset = EditorBuilderAsset(isFile: { $0.isGridMapFile($1) }, newTitle: "New GridMap", newCommand: GridMapNewCommand.id,
                                             create: { $0.run(GridMapNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(GridMapOpenCommand.self, .init(asset: AssetReference($1))) })

    static var gridMap: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.gridMapBuilder, title: "GridMap Builder", passesPointerThrough: true, commands: EditorGridMapCommands.all, asset: gridMapAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isGridMapFile(id) else { return nil }
            let open = Button("Open in GridMap Builder", role: .primary, name: "openGridMapBuilder") { [unowned session] in
                session.run(GridMapOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = GridMapOpenCommand.id.rawValue
            open.tooltip = "Paint this level from its piece library in the GridMap Builder tab (or double-click it in the Assets panel)"
            let map = session.assets?.gridMap(of: id)
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("A grid map of \(map?.cells.count ?? 0) cells from \(map?.pieces.count ?? 0) pieces on \(map?.floors.count ?? 0) floors, drawn instanced with one collider per chunk.")]
        }) { app in
            let workspace = GridMapWorkspace(session: app.session)
            var tab = EditorBuilderTab.viewport(workspace, app: app) { [unowned app, unowned workspace] in
                app.session.onOpenGridMap = { [unowned app, unowned workspace] id in
                    guard workspace.open(id, floor: app.session.openGridMapFloor) else { return }
                    app.showBuilderPanel(EditorLayout.gridMapBuilder)
                }
            }
            tab.handleKeys = { [unowned workspace] keys, pointer in _ = workspace.handleKeys(keys, pointer: pointer) }
            return tab
        }
    }

    static let pathAsset = EditorBuilderAsset(isFile: { $0.isPathBuildFile($1) }, newTitle: "New Path", newCommand: PathNewCommand.id,
                                             create: { $0.run(PathNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(PathOpenCommand.self, .init(asset: AssetReference($1))) })

    static var path: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.pathBuilder, title: "Path Builder", passesPointerThrough: true, commands: EditorPathCommands.all, asset: pathAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isPathBuildFile(id) else { return nil }
            let open = Button("Open in Path Builder", role: .primary, name: "openPathBuilder") { [unowned session] in
                session.run(PathOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = PathOpenCommand.id.rawValue
            open.tooltip = "Edit this path's points, profiles and pieces in the Path Builder tab (or double-click it in the Assets panel)"
            let build = session.assets?.pathBuild(of: id)
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("A \(build?.kind.rawValue ?? "path") spline through \(build?.points.count ?? 0) points, with geometry generated along it. The Path Builder has control-point gizmos, profiles, pieces and terrain following.")]
        }) { app in
            let workspace = PathBuilderWorkspace(session: app.session)
            return .viewport(workspace, app: app) { [unowned app, unowned workspace] in
                app.session.onOpenPathBuild = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.pathBuilder)
                }
            }
        }
    }
}

extension TerrainBuilderWorkspace: EditorViewportBuilder {}
extension GridMapWorkspace: EditorViewportBuilder {}
extension PathBuilderWorkspace: EditorViewportBuilder {}

extension EditorApp {
    /// The Terrain Builder tab (TerrainBuilderWorkspace.swift).
    public var terrainWorkspace: TerrainBuilderWorkspace! { builderWorkspace(TerrainBuilderWorkspace.self) }
    /// The GridMap Builder tab (GridMapWorkspace.swift).
    public var gridMapWorkspace: GridMapWorkspace! { builderWorkspace(GridMapWorkspace.self) }
    /// The Path Builder tab (PathBuilderWorkspace.swift).
    public var pathWorkspace: PathBuilderWorkspace! { builderWorkspace(PathBuilderWorkspace.self) }
}

extension AssetBrowserModel {
    /// Creates a terrain in the current folder (`terrain.new`) and selects it.
    @discardableResult
    public func newTerrain() -> AssetID? { newBuilderAsset(EditorBuildersWorld.terrainAsset) }

    /// Creates a grid map (with the starter pieces) in the current folder (`gridMap.new`) and selects it.
    @discardableResult
    public func newGridMap() -> AssetID? { newBuilderAsset(EditorBuildersWorld.gridMapAsset) }

    /// Creates a path (a road) in the current folder (`path.new`) and selects it.
    @discardableResult
    public func newPathBuild() -> AssetID? { newBuilderAsset(EditorBuildersWorld.pathAsset) }
}
