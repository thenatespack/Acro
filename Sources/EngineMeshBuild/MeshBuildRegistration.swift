import EngineAssets

/// Registers this module's importers in `AssetImporterRegistry.builtIn`. Declared (without a
/// body) in EngineAssets/Assets/AssetImporter.swift, which can't import this module; the linker
/// resolves that declaration to this function by its symbol name.
@_silgen_name("acro_engineMeshBuild_registerImporters")
package func registerMeshBuildImporters(_ registry: inout AssetImporterRegistry) {
    registry.register(ProceduralTextureImporter())
    registry.register(MeshBuildImporter())
    registry.register(TerrainImporter())
    registry.register(GridMapImporter())
    registry.register(PathBuildImporter())
    registry.register(CharacterImporter())
    registry.register(GroomImporter())
}
