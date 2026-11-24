#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

/// Shows a `.ui` layout (a HUD or menu from the UI Builder) over the game while it plays, with no
/// game code: the game UI layer (`World.addGameUI`, Engine module) keeps a `UIBuildView` for each
/// of these, follows hot reloads of the file and draws it over the scene in the editor's Game
/// view, `GameRunner` and exported games.
///
/// Game code reaches the layouts through `world.gameUI` (a `GameUILayer`):
///
/// ```swift
/// world.gameUI?.set("health", 64)                    // every layout's bars and {health} text
/// world.gameUI?.on("pause") { _, _ in pauseGame() }  // a button's event, from any layout
/// world.uiLayout(for: hudEntity)?.set("score", 10)   // one layout
/// ```
public struct UILayoutPlayer: Component, Codable, Equatable, Sendable {
    public static let componentName = "UILayoutPlayer"
    public static var fieldHints: [String: FieldHints] {
        ["layout": FieldHints(tooltip: "A .ui file: a path under Assets/ or asset:<id>"),
         "visible": FieldHints(tooltip: "Shown while playing (game code can show and hide it, with the layout's transition)"),
         "order": FieldHints(range: -100...100, step: 1, tooltip: "Drawing order between layouts: higher draws on top"),
         "focus": FieldHints(tooltip: "Give the layout keyboard / gamepad focus when it shows (menus)")]
    }

    /// The `.ui` file: a path under `Assets/` or "asset:<id>".
    public var layout: String
    /// Shown while playing.
    public var visible: Bool
    /// Higher draws on top of lower.
    public var order: Int
    /// Focus the layout's first focusable widget (or its `focus` widget) when it shows, so the
    /// keyboard and gamepad can drive it (menus).
    public var focus: Bool

    public init(layout: String = "", visible: Bool = true, order: Int = 0, focus: Bool = false) {
        self.layout = layout
        self.visible = visible
        self.order = order
        self.focus = focus
    }

    private enum CodingKeys: String, CodingKey { case layout, visible, order, focus }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(layout: try c.decodeIfPresent(String.self, forKey: .layout) ?? "",
                  visible: try c.decodeIfPresent(Bool.self, forKey: .visible) ?? true,
                  order: try c.decodeIfPresent(Int.self, forKey: .order) ?? 0,
                  focus: try c.decodeIfPresent(Bool.self, forKey: .focus) ?? false)
    }
}
