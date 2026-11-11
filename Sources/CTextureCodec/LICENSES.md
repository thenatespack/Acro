# Vendored texture codecs

Upstream sources; `codec.cpp` and `bc6h.cpp` are the engine's adapters (`include/CTextureCodec.h`) and `bc5.cpp` the engine's own BC5 codec (not vendored, same license as the engine).

| Files | Version | Upstream | License |
|---|---|---|---|
| `vendor/bc7enc/bc7enc.c`, `bc7enc.h`, `bc7decomp.cpp`, `bc7decomp.h` | 2020-03-31 revision (current master) | https://github.com/richgel999/bc7enc | MIT or public domain (Unlicense), at your choice; see `vendor/bc7enc/LICENSE` |
| `vendor/astcenc/astcenc*.cpp`, `astcenc*.h` (the library; not the command-line tool) | 5.7.0 | https://github.com/ARM-software/astc-encoder | Apache License 2.0; see `vendor/astcenc/LICENSE.txt` |
| `vendor/cvtt/ConvectionKernels*` (the BC6H / BC7 kernels and what they include; not the ETC / S3TC ones, `MakeTables` or `etc2packer`) | master, commit 350416d (2022-06-22) | https://github.com/elasota/ConvectionKernels | MIT (Convection Texture Tools, itself based on Microsoft's MIT-licensed DirectXTex); see `vendor/cvtt/LICENSE.txt` |

Local changes, marked `acro:`: in `bc7enc.c`, opaque blocks encoded in mode 6
only use p-bit 1, so their alpha decodes to 255 instead of sometimes 254; in
`ConvectionKernels_BC67.cpp`, `PackingVector::InitPacked` zeroes the words past the header
(upstream left the last one uninitialized and ORed BC6H indices into it, so stack garbage
corrupted texels 8-15 of a block now and then). astc-encoder is unmodified.

The Apache License requires shipping its text with source or binary redistributions of
astc-encoder (section 4); upstream has no NOTICE file. bc7enc needs no attribution. The MIT
License asks for its copyright notice (in `vendor/cvtt/LICENSE.txt`) in copies of Convection
Texture Tools' kernels.
