# Vendored zlib (WebAssembly builds only)

zlib 1.3.1 (https://github.com/madler/zlib/releases/tag/v1.3.1, `zlib-1.3.1.tar.gz`,
SHA-256 `9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23`), unmodified: the
deflate/inflate library sources, without the `gz*` file functions, examples and build files.
License: zlib (see `LICENSE`).

The WASI sysroot has no zlib, so `ENGINE_WASM=1` builds compile this as the `CZlib` module
(`include/module.modulemap`); native builds keep the system zlib (`Sources/CZlib`). Both give
the same `import CZlib` API, used by `PNGEncoder` (EngineCore) and `NetCompression` (EngineNet).
