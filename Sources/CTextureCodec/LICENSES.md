# Vendored texture codecs

Upstream sources; `codec.cpp` is the engine's adapter (`include/CTextureCodec.h`).

| Files | Version | Upstream | License |
|---|---|---|---|
| `vendor/bc7enc/bc7enc.c`, `bc7enc.h`, `bc7decomp.cpp`, `bc7decomp.h` | 2020-03-31 revision (current master) | https://github.com/richgel999/bc7enc | MIT or public domain (Unlicense), at your choice; see `vendor/bc7enc/LICENSE` |
| `vendor/astcenc/astcenc*.cpp`, `astcenc*.h` (the library; not the command-line tool) | 5.7.0 | https://github.com/ARM-software/astc-encoder | Apache License 2.0; see `vendor/astcenc/LICENSE.txt` |

One local change, marked `swift-game-engine:` in `bc7enc.c`: opaque blocks encoded in mode 6
only use p-bit 1, so their alpha decodes to 255 instead of sometimes 254. astc-encoder is
unmodified.

The Apache License requires shipping its text with source or binary redistributions of
astc-encoder (section 4); upstream has no NOTICE file. bc7enc needs no attribution.
