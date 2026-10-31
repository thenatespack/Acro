// The single implementation of stb_image (vendored in include/, public domain).
// Pinned to stb_image.h v2.30 (https://github.com/nothings/stb). To update, replace the
// header and re-run the image tests.
//
// Only the formats the engine imports are compiled in, and only decoding from memory.
// The engine never calls the global-state functions (stbi_set_flip_vertically_on_load,
// stbi_set_unpremultiply_on_load, ...), and stbi_failure_reason() is thread-local, so decoding
// is safe on any number of threads at once.
#define STBI_ONLY_PNG
#define STBI_ONLY_JPEG
#define STBI_ONLY_TGA
#define STBI_ONLY_HDR
#define STBI_NO_STDIO
#define STBI_FAILURE_USERMSG
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
