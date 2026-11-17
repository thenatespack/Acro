import EditorBuildersAnimation
import EditorBuilders2D
import EditorBuildersLogic
import EditorBuildersMesh
import EditorBuildersWorld
import EditorCore

/// Registers every builder module's tabs with EditorCore (`EditorBuilderRegistry`). The Editor
/// executable calls `registerAll()` at launch, before it makes the app; other hosts that link
/// this module (the tests) get it called the first time EditorCore needs the builders (it finds
/// this type by its mangled name, `EditorBuilderRegistry.providerTypeName`).
@MainActor
public enum EditorBuilders: EditorBuilderProvider {
    private static var registered = false

    public static func registerAll() {
        guard !registered else { return }
        registered = true
        EditorBuilderRegistry.register(EditorBuildersMesh.modules + EditorBuildersWorld.modules + EditorBuilders2D.modules
                                       + EditorBuildersAnimation.modules + EditorBuildersLogic.modules)
    }
}
