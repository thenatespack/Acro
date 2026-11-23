// Light probes (see LightProbes.swift and SceneRenderer+Probes.swift), included by
// mesh_surface.glsl after environment.glsl. The includer declares `frame` with its `probes` row
// (x: reflection probes, y: irradiance volumes). Not compiled on its own; rerun
// Scripts/compile-shaders.sh after editing it.
//
// Everything is in storage buffer 1 as 32-bit words (`ProbeBufferLayout`), read as uvec4s:
// - Records of eight vec4s: the reflection probes first (in blending order), then the volumes.
//   Rows 0-2 map world space to the probe's own space (rotation and translation; scale is
//   ignored). Reflection probe: row 3 influence half extents and blend distance, row 4
//   projection half extents and 1 for box projection, row 5 capture point (probe space) and
//   intensity, row 6 x the first texel of its image (an integer). Volume: row 3 half extents
//   and blend distance, row 4 probe counts, row 5 normal bias, view bias and intensity, row 6 x
//   the first vec4 of its SH coefficients (an integer).
// - Irradiance probes: four vec4s each, 28 half floats: the RGB SH9 coefficients of irradiance /
//   pi in the volume's space (coefficient k at halves 3k...3k+2), then 1, or 0 for a probe inside
//   geometry, which is skipped.
// - Reflection probe images: `ReflectionProbeImage`, six equirectangular levels for roughness
//   0, 0.2, … 1, two words (four half floats) per texel. Read with exact loads and bilinear
//   weights computed here (as sampleEquirect does), so Metal and Vulkan agree exactly.

// Read four words at a time (one 16-byte load).
layout(set = 2, binding = 25, std430) readonly buffer ProbeData {
    uvec4 words[];
} probeData;

const int PROBE_RECORD = 8;

vec4 probeVec4(int i) {
    return uintBitsToFloat(probeData.words[i]);
}

int probeInt(int i) {
    return int(probeData.words[i].x);
}

// `ReflectionProbeImage.levels`: first texel, width, height.
const ivec3 PROBE_LEVELS[6] = ivec3[6](
    ivec3(0, 256, 128), ivec3(32768, 128, 64), ivec3(40960, 64, 32),
    ivec3(43008, 32, 16), ivec3(43520, 16, 8), ivec3(43648, 8, 4));

// Images start on an even texel, so texel t is half of vec4 t / 2.
vec3 probeTexel(int first, int x, int y, int width) {
    int t = first + y * width + x;
    uvec4 pair = probeData.words[t >> 1];
    uvec2 texel = (t & 1) == 0 ? pair.xy : pair.zw;
    return vec3(unpackHalf2x16(texel.x), unpackHalf2x16(texel.y).x);
}

// Bilinear filtering of one level of the image starting at texel `image` (wraps horizontally,
// clamps vertically, like sampleEquirect).
vec3 sampleProbeLevel(int image, int level, vec2 uv) {
    ivec3 l = PROBE_LEVELS[level];
    int first = image + l.x;
    vec2 p = uv * vec2(l.yz) - 0.5;
    vec2 f = floor(p);
    vec2 t = p - f;
    int x0 = int(f.x), y0 = int(f.y);
    if (x0 < 0) x0 += l.y;
    if (x0 >= l.y) x0 -= l.y;
    int x1 = x0 + 1 == l.y ? 0 : x0 + 1;
    int y1 = min(y0 + 1, l.z - 1);
    y0 = max(y0, 0);
    vec3 a = probeTexel(first, x0, y0, l.y);
    vec3 b = probeTexel(first, x1, y0, l.y);
    vec3 c = probeTexel(first, x0, y1, l.y);
    vec3 d = probeTexel(first, x1, y1, l.y);
    return mix(mix(a, b, t.x), mix(c, d, t.x), t.y);
}

// The image's radiance from direction d (probe space) prefiltered for `roughness`.
vec3 probeImageRadiance(int image, vec3 d, float roughness) {
    vec2 uv = equirectUV(d);
    float level = roughness * 5.0;
    int i = min(int(level), 4);
    return mix(sampleProbeLevel(image, i, uv), sampleProbeLevel(image, i + 1, uv), level - float(i));
}

vec3 probeLocal(int record, vec3 p) {
    vec4 r0 = probeVec4(record), r1 = probeVec4(record + 1), r2 = probeVec4(record + 2);
    return vec3(dot(r0.xyz, p) + r0.w, dot(r1.xyz, p) + r1.w, dot(r2.xyz, p) + r2.w);
}

vec3 probeLocalDirection(int record, vec3 d) {
    return vec3(dot(probeVec4(record).xyz, d), dot(probeVec4(record + 1).xyz, d), dot(probeVec4(record + 2).xyz, d));
}

// `LightProbeMath.influence`: 1 at least `blend` inside every face of the box, smoothly 0 at them.
float probeInfluence(vec3 q, vec3 halfExtents, float blend) {
    vec3 d = halfExtents - abs(q);
    float inside = min(d.x, min(d.y, d.z));
    if (inside <= 0.0) return 0.0;
    if (blend <= 0.0) return 1.0;
    float t = min(inside / blend, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

// `LightProbeMath.boxProjected`: from the capture point toward where ray r from q leaves the box.
vec3 probeBoxProjected(vec3 q, vec3 r, vec3 halfExtents, vec3 capture) {
    vec3 o = clamp(q, -halfExtents, halfExtents);
    vec3 planes = mix(-halfExtents, halfExtents, step(vec3(0.0), r));
    vec3 safe = mix(vec3(1e-6), r, step(vec3(1e-6), abs(r)));
    vec3 ts = mix(vec3(1e30), (planes - o) / safe, step(vec3(1e-6), abs(r)));
    float t = max(min(ts.x, min(ts.y, ts.z)), 0.0);
    vec3 d = o + r * t - capture;
    return dot(d, d) > 1e-12 ? normalize(d) : r;
}

// The reflection probes' radiance along r (world space) at p, blended over `fallback` (the
// environment's): probes in order, each covering what the ones before left.
vec3 probeReflection(vec3 fallback, vec3 p, vec3 r, float roughness) {
    int count = int(frame.probes.x);
    vec3 sum = vec3(0.0);
    float total = 0.0;
    for (int i = 0; i < count; i++) {
        if (total > 0.999) break;
        int record = i * PROBE_RECORD;
        vec3 q = probeLocal(record, p);
        vec4 influence = probeVec4(record + 3);
        float w = probeInfluence(q, influence.xyz, influence.w);
        if (w <= 0.0) continue;
        vec4 projection = probeVec4(record + 4);
        vec4 capture = probeVec4(record + 5);
        vec3 rl = probeLocalDirection(record, r);
        vec3 d = projection.w > 0.5 ? probeBoxProjected(q, rl, projection.xyz, capture.xyz) : rl;
        vec3 c = probeImageRadiance(probeInt(record + 6), d, roughness) * capture.w;
        float a = w * (1.0 - total);
        sum += c * a;
        total += a;
    }
    return sum + fallback * (1.0 - total);
}

// Whether the irradiance probe at vec4 `first` is used (not inside geometry).
bool probeValid(int first) {
    return unpackHalf2x16(probeData.words[first + 3].y).y > 0.5;
}

// The irradiance probe at vec4 `first` evaluated with the SH basis `y` (of the normal): the
// coefficients are unpacked one at a time, so few stay live.
// The SH basis at unit direction d (`shBasis`) as two vec4s and a float (no arrays, which the
// Metal compiler may keep in memory).
struct ProbeBasis {
    vec4 a;
    vec4 b;
    float c;
};

ProbeBasis probeBasis(vec3 d) {
    ProbeBasis y;
    y.a = vec4(0.282095, 0.488603 * d.y, 0.488603 * d.z, 0.488603 * d.x);
    y.b = vec4(1.092548 * d.x * d.y, 1.092548 * d.y * d.z, 0.315392 * (3.0 * d.z * d.z - 1.0), 1.092548 * d.x * d.z);
    y.c = 0.546274 * (d.x * d.x - d.y * d.y);
    return y;
}

vec3 probeSHDot(int first, ProbeBasis y) {
    uvec4 a = probeData.words[first], b = probeData.words[first + 1], d = probeData.words[first + 2], e = probeData.words[first + 3];
    vec2 h0 = unpackHalf2x16(a.x), h1 = unpackHalf2x16(a.y), h2 = unpackHalf2x16(a.z), h3 = unpackHalf2x16(a.w);
    vec2 h4 = unpackHalf2x16(b.x), h5 = unpackHalf2x16(b.y), h6 = unpackHalf2x16(b.z), h7 = unpackHalf2x16(b.w);
    vec2 h8 = unpackHalf2x16(d.x), h9 = unpackHalf2x16(d.y), h10 = unpackHalf2x16(d.z), h11 = unpackHalf2x16(d.w);
    vec2 h12 = unpackHalf2x16(e.x), h13 = unpackHalf2x16(e.y);
    return vec3(h0, h1.x) * y.a.x + vec3(h1.y, h2) * y.a.y + vec3(h3, h4.x) * y.a.z + vec3(h4.y, h5) * y.a.w
        + vec3(h6, h7.x) * y.b.x + vec3(h7.y, h8) * y.b.y + vec3(h9, h10.x) * y.b.z + vec3(h10.y, h11) * y.b.w
        + vec3(h12, h13.x) * y.c;
}

// One corner of the trilinear lookup: its light times its weight (trilinear, backface, 0 for a
// probe inside geometry) and the weight.
vec4 probeCorner(ivec3 o, ivec3 g0, ivec3 nc, vec3 f, vec3 cells, vec3 halfExtents, vec3 q, vec3 nl, int shFirst, ProbeBasis y) {
    ivec3 cell = min(g0 + o, nc - 1);
    int sh = shFirst + (cell.x + nc.x * (cell.y + nc.y * cell.z)) * 4;
    vec3 t = mix(1.0 - f, f, vec3(o));
    vec3 toProbe = -halfExtents + (vec3(cell) + 0.5) / cells * halfExtents * 2.0 - q;
    float b = (dot(toProbe * inversesqrt(max(dot(toProbe, toProbe), 1e-10)), nl) + 1.0) * 0.5;
    float weight = t.x * t.y * t.z * (b * b + 0.2) * (probeValid(sh) ? 1.0 : 0.0);
    return vec4(probeSHDot(sh, y) * weight, weight);
}

// The irradiance volumes' light at p for normal n (v toward the viewer), blended over
// `fallback` (the environment's or the hemisphere's): trilinear between the eight probes
// around the biased point, skipping probes inside geometry and weighing down those behind the
// surface (`IrradianceVolumeBake.irradiance` does the same on the CPU).
vec3 probeIrradiance(vec3 fallback, vec3 p, vec3 n, vec3 v) {
    int volumes = int(frame.probes.y);
    int firstRecord = int(frame.probes.x) * PROBE_RECORD;
    vec3 result = fallback;
    for (int j = 0; j < volumes; j++) {
        int record = firstRecord + j * PROBE_RECORD;
        vec4 box = probeVec4(record + 3);
        vec3 q = probeLocal(record, p);
        float w = probeInfluence(q, box.xyz, box.w);
        if (w <= 0.0) continue;
        vec3 cells = probeVec4(record + 4).xyz;
        vec4 bias = probeVec4(record + 5);
        int shFirst = probeInt(record + 6);
        vec3 nl = probeLocalDirection(record, n);
        vec3 qb = probeLocal(record, p + n * bias.x + v * bias.y);
        vec3 g = clamp((qb + box.xyz) / max(box.xyz * 2.0, vec3(1e-6)) * cells - 0.5, vec3(0.0), cells - 1.0);
        ivec3 nc = ivec3(cells);
        ivec3 g0 = min(ivec3(g), max(nc - 2, ivec3(0)));
        vec3 f = g - vec3(g0);
        ProbeBasis y = probeBasis(nl);
        // The eight corners written out (no loop, no early exits), so their loads overlap.
        vec4 acc = vec4(0.0);
        acc += probeCorner(ivec3(0, 0, 0), g0, nc, f, cells, box.xyz, q, nl, shFirst, y);
        acc += probeCorner(ivec3(1, 0, 0), g0, nc, f, cells, box.xyz, q, nl, shFirst, y);
        acc += probeCorner(ivec3(0, 1, 0), g0, nc, f, cells, box.xyz, q, nl, shFirst, y);
        acc += probeCorner(ivec3(1, 1, 0), g0, nc, f, cells, box.xyz, q, nl, shFirst, y);
        acc += probeCorner(ivec3(0, 0, 1), g0, nc, f, cells, box.xyz, q, nl, shFirst, y);
        acc += probeCorner(ivec3(1, 0, 1), g0, nc, f, cells, box.xyz, q, nl, shFirst, y);
        acc += probeCorner(ivec3(0, 1, 1), g0, nc, f, cells, box.xyz, q, nl, shFirst, y);
        acc += probeCorner(ivec3(1, 1, 1), g0, nc, f, cells, box.xyz, q, nl, shFirst, y);
        vec3 sum = acc.rgb;
        float total = acc.a;
        if (total > 1e-5) result = mix(result, max(sum, vec3(0.0)) / total * bias.z, w);
    }
    return result;
}
