// On Darwin, Linux and Windows, Foundation re-exports the C library (sinf, memcpy, ...); on
// WASI it doesn't, so EngineCore re-exports it for every module built on top of it.
#if os(WASI)
@_exported import WASILibc
#endif
