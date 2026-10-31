# Vendored audio libraries

Each file is unmodified upstream source (stb_vorbis.c is renamed to `stb_vorbis.h` so SwiftPM
doesn't compile it on its own; `codecs.c` includes it once). The full license text is at the
end of each file.

| File | Version | Upstream | License |
|---|---|---|---|
| `vendor/miniaudio.h` | 0.11.25 | https://github.com/mackron/miniaudio | Public domain (Unlicense) or MIT No Attribution, at your choice |
| `vendor/stb_vorbis.h` | 1.22 (`stb_vorbis.c`) | https://github.com/nothings/stb | Public domain (Unlicense) or MIT, at your choice |
| `vendor/dr_mp3.h` | 0.7.4 | https://github.com/mackron/dr_libs | Public domain (Unlicense) or MIT No Attribution, at your choice |

None of them require attribution in binary distributions.
