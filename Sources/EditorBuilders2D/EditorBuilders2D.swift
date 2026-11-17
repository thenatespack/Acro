import EditorCore
import Engine
import Foundation

/// The builder tabs of this module: the Pixel Sprite Builder, the Tilemap Builder and the UI Builder (see EditorCore/EditorBuilders.swift).
@MainActor
package enum EditorBuilders2D {
    package static var modules: [EditorBuilderModule] { [pixelSprite, tilemap, uiLayout] }

    static let pixelSpriteAsset = EditorBuilderAsset(isFile: { $0.isPixelSpriteFile($1) }, newTitle: "New Sprite", newCommand: PixelSpriteNewCommand.id,
                                             create: { $0.run(PixelSpriteNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(PixelSpriteOpenCommand.self, .init(asset: AssetReference($1))) })

    static var pixelSprite: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.spriteBuilder, title: "Pixel Sprite Builder", commands: EditorPixelSpriteCommands.all, asset: pixelSpriteAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            if session.assets?.record(id)?.importer == TextureImporter().name { return [sheetImport(context)] }
            guard session.isPixelSpriteFile(id) else { return nil }
            let open = Button("Open in Pixel Sprite Builder", role: .primary, name: "openSpriteBuilder") { [unowned session] in
                session.run(PixelSpriteOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = PixelSpriteOpenCommand.id.rawValue
            open.tooltip = "Draw and animate this sprite in the Pixel Sprite Builder tab (or double-click it in the Assets panel)"
            let sprite = session.assets?.pixelSprite(of: id)
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("Pixel art, \(sprite?.width ?? 0) x \(sprite?.height ?? 0) px, \(sprite?.frames.count ?? 0) frames, \(sprite?.tags.count ?? 0) tags. Imported as an atlas texture; SpriteAssetLibrary gives a SpriteAtlas and one SpriteAnimator clip per tag.")]
        }) { app in
            let workspace = PixelSpriteWorkspace(session: app.session)
            return EditorBuilderTab(workspace: workspace, view: workspace.view, update: { [unowned workspace] _, dt in workspace.update(dt: dt) },
                                    connect: { [unowned app, unowned workspace] in
                app.session.onOpenPixelSprite = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.spriteBuilder)
                }
            })
        }
    }

    static let tilemapAsset = EditorBuilderAsset(isFile: { $0.isTilemapFile($1) }, newTitle: "New Tilemap", newCommand: TilemapNewCommand.id,
                                             create: { $0.run(TilemapNewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(TilemapOpenCommand.self, .init(asset: AssetReference($1))) })

    static var tilemap: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.tilemapBuilder, title: "Tilemap Builder", commands: EditorTilemapCommands.all, asset: tilemapAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isTilemapFile(id) else { return nil }
            let open = Button("Open in Tilemap Builder", role: .primary, name: "openTilemapBuilder") { [unowned session] in
                session.run(TilemapOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = TilemapOpenCommand.id.rawValue
            open.tooltip = "Paint this map in the Tilemap Builder tab (or double-click it in the Assets panel)"
            let map = session.assets?.tilemapContents(of: id)
            return [HStack(spacing: 6, [open, Spacer()]),
                    context.note("A \(map?.cols ?? 0) x \(map?.rowCount ?? 0) tilemap with \(map?.layers.count ?? 0) layers. Placed, it is layer meshes, merged Collider2D shapes and object points; game code reads it with assets.tilemap(path:).")]
        }) { app in
            let workspace = TilemapWorkspace(session: app.session)
            workspace.device = app.builderDevice
            return EditorBuilderTab(workspace: workspace, view: workspace.view, update: { [unowned workspace] _, dt in workspace.update(dt: dt) },
                                    connect: { [unowned app, unowned workspace] in
                app.session.onOpenTilemap = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.tilemapBuilder)
                }
            })
        }
    }

    static let uiLayoutAsset = EditorBuilderAsset(isFile: { $0.isUIBuildFile($1) }, newTitle: "New UI Layout", newCommand: UINewCommand.id,
                                             create: { $0.run(UINewCommand.self, .init(folder: $1))?.asset },
                                             open: { $0.run(UIOpenCommand.self, .init(asset: AssetReference($1))) })

    static var uiLayout: EditorBuilderModule {
        EditorBuilderModule(panelID: EditorLayout.uiBuilder, title: "UI Builder", commands: EditorUIBuildCommands.all, asset: uiLayoutAsset,
                            inspector: { context in
            let session = context.session, id = context.asset
            guard session.isUIBuildFile(id) else { return nil }
            let open = Button("Open in UI Builder", role: .primary, name: "openUIBuilder") { [unowned session] in
                session.run(UIOpenCommand.self, .init(asset: AssetReference(id)))
            }
            open.command = UIOpenCommand.id.rawValue
            open.tooltip = "Lay out this menu or HUD in the UI Builder tab (or double-click it in the Assets panel)"
            let place = Button("Add to Scene", name: "addUILayoutPlayer") { [unowned session] in
                session.run(UIPlaceCommand.self, .init(asset: AssetReference(id)))
            }
            place.command = UIPlaceCommand.id.rawValue
            place.tooltip = "Add an entity with a UILayoutPlayer that shows this layout over the game while it plays"
            let build = session.assets?.uiBuild(of: id)
            return [HStack(spacing: 6, [open, place, Spacer()]),
                    context.note("A game menu or HUD of \(build?.widgets.count ?? 0) widgets. A UILayoutPlayer component shows it over the game (Add to Scene); game code sets values with world.gameUI?.set(key, value) and handles events with on(event).")]
        }) { app in
            let workspace = UIBuilderWorkspace(session: app.session)
            workspace.images = { [unowned app] reference in app.assetThumbnail(reference, kind: .texture) }
            return EditorBuilderTab(workspace: workspace, view: workspace.view, update: { [unowned workspace] _, _ in workspace.update() },
                                    connect: { [unowned app, unowned workspace] in
                app.session.onOpenUIBuild = { [unowned app, unowned workspace] id in
                    guard workspace.open(id) else { return }
                    app.showBuilderPanel(EditorLayout.uiBuilder)
                }
            })
        }
    }

    /// Frame size fields and a button that turn a texture (a sprite sheet) into a .sprite next to it.
    static func sheetImport(_ context: EditorBuilderInspection) -> Widget {
        let session = context.session, id = context.asset
        let width = NumberField(value: 16, isInteger: true, range: 1...Double(PixelSprite.maxSize), step: 1, name: "sheetFrameWidth")
        let height = NumberField(value: 16, isInteger: true, range: 1...Double(PixelSprite.maxSize), step: 1, name: "sheetFrameHeight")
        width.prefix = "W"
        height.prefix = "H"
        width.tooltip = "Frame width in pixels"
        height.tooltip = "Frame height in pixels"
        let button = Button("Import as Pixel Sprite", name: "importSpriteSheet") { [unowned session] in
            let arguments = PixelSpriteImportSheetCommand.Arguments(image: AssetReference(id), frameWidth: Int(width.value), frameHeight: Int(height.value))
            if let result = session.run(PixelSpriteImportSheetCommand.self, arguments) {
                session.run(PixelSpriteOpenCommand.self, .init(asset: AssetReference(result.asset)))
            }
        }
        button.command = PixelSpriteImportSheetCommand.id.rawValue
        button.tooltip = "Slice this sheet into frames of this size (left to right, top to bottom) and write a .sprite with its colors as the palette"
        return VStack(spacing: 4, name: "spriteSheetImport", [HStack(spacing: 6, [width, height, button, Spacer()]),
                                                              context.note("As a sprite sheet: cells of W x H become the frames of a .sprite.")])
    }
}


extension EditorApp {
    /// The Pixel Sprite Builder tab (PixelSpriteWorkspace.swift).
    public var spriteWorkspace: PixelSpriteWorkspace! { builderWorkspace(PixelSpriteWorkspace.self) }
    /// The Tilemap Builder tab (TilemapWorkspace.swift).
    public var tilemapWorkspace: TilemapWorkspace! { builderWorkspace(TilemapWorkspace.self) }
    /// The UI Builder tab (UIBuilderWorkspace.swift).
    public var uiWorkspace: UIBuilderWorkspace! { builderWorkspace(UIBuilderWorkspace.self) }
}

extension AssetBrowserModel {
    /// Creates a pixel sprite in the current folder (`sprite.new`) and selects it.
    @discardableResult
    public func newPixelSprite() -> AssetID? { newBuilderAsset(EditorBuilders2D.pixelSpriteAsset) }

    /// Creates a tilemap (with the starter tile set) in the current folder (`tilemap.new`) and selects it.
    @discardableResult
    public func newTilemap() -> AssetID? { newBuilderAsset(EditorBuilders2D.tilemapAsset) }

    /// Creates a UI layout (a starter HUD) in the current folder (`uiLayout.new`) and selects it.
    @discardableResult
    public func newUILayout() -> AssetID? { newBuilderAsset(EditorBuilders2D.uiLayoutAsset) }
}
