// The single implementations of stb_vorbis and dr_mp3 (vendored in vendor/). Both decode
// from memory only: the engine reads the compressed file and streams the decode from that.
// vendor/stb_vorbis.h is stb_vorbis.c v1.22, renamed (unmodified) so SwiftPM doesn't compile
// it on its own. To update either, replace the file and run `swift test --filter AudioTests`.
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wtautological-compare"  // an upstream overflow check clang flags
#endif
#define STB_VORBIS_NO_STDIO
#define STB_VORBIS_NO_PUSHDATA_API
#include "vendor/stb_vorbis.h"

#define DR_MP3_NO_STDIO
#define DR_MP3_IMPLEMENTATION
#include "vendor/dr_mp3.h"
