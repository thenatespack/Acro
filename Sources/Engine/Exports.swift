// `import Engine` brings in the whole engine: it is split into modules (see Package.swift) so
// release builds can compile them in parallel, and this module re-exports them all.
@_exported import EngineCore
@_exported import EngineScene
@_exported import EngineGraphics
@_exported import EngineBackends
@_exported import EngineText
@_exported import EnginePhysics
@_exported import EngineAudio
@_exported import EngineAssets
@_exported import EngineMeshBuild
@_exported import EngineNet
@_exported import EngineUI
@_exported import EngineRendering
