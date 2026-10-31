// Shared by the environment shaders (sky.vert / sky.frag, env_*.frag) and mesh_surface.glsl
// (see EnvironmentLighting.swift): the equirectangular mapping, filtering with exact texel
// loads, the procedural sky, the environment atlas layout and the SH9 basis. Not compiled on
// its own; rerun Scripts/compile-shaders.sh after editing it.
//
// Equirectangular layout (`EnvironmentMath.equirectUV`): u = 0.5 looks down -Z, u grows toward
// +X (turning right), v = 0 is straight up (+Y), the first texture row. Every environment
// lookup goes through `environmentDirection`, which turns a world direction by the
// environment's rotation about +Y.

const float ENV_PI = 3.14159265;

// Must match `EnvironmentAtlas`: prefiltered radiance for perceptual roughness 0, 0.2, 0.4,
// 0.6, 0.8 and 1, each an equirectangular image at (x, y) of size (z, w) texels, then the nine
// SH irradiance coefficients in one row.
const ivec4 ENV_LEVELS[6] = ivec4[6](
    ivec4(0, 0, 512, 256), ivec4(0, 256, 256, 128), ivec4(256, 256, 128, 64),
    ivec4(384, 256, 64, 32), ivec4(448, 256, 32, 16), ivec4(480, 256, 16, 8));
const ivec2 ENV_SH = ivec2(496, 256);
// Size of the split-sum BRDF table (`EnvironmentMath.brdfLUTSize`).
const float ENV_LUT_SIZE = 32.0;

vec2 equirectUV(vec3 d) {
    return vec2(atan(d.x, -d.z) * (0.5 / ENV_PI) + 0.5, acos(clamp(d.y, -1.0, 1.0)) * (1.0 / ENV_PI));
}

vec3 equirectDirection(vec2 uv) {
    float phi = (uv.x - 0.5) * (2.0 * ENV_PI);
    float theta = uv.y * ENV_PI;
    float s = sin(theta);
    return vec3(s * sin(phi), cos(theta), -s * cos(phi));
}

// World direction -> environment direction: turned by -rotation about +Y (cs = cos, sin of
// the environment's rotation), so the environment appears turned by +rotation.
vec3 environmentDirection(vec3 d, vec2 cs) {
    return vec3(cs.x * d.x - cs.y * d.z, d.y, cs.y * d.x + cs.x * d.z);
}

// Bilinear filtering of the equirectangular image at `region` (x, y, width, height) of `image`
// at `uv`, from four texel loads: wraps horizontally, clamps vertically. Exact loads keep the
// regions of an atlas apart and give the same result on every backend.
vec3 sampleEquirect(texture2D image, sampler s, ivec4 region, vec2 uv) {
    vec2 p = uv * vec2(region.zw) - 0.5;
    vec2 f = floor(p);
    vec2 t = p - f;
    int x0 = int(f.x), y0 = int(f.y);
    if (x0 < 0) x0 += region.z;
    if (x0 >= region.z) x0 -= region.z;
    int x1 = x0 + 1 == region.z ? 0 : x0 + 1;
    int y1 = min(y0 + 1, region.w - 1);
    y0 = max(y0, 0);
    vec3 a = texelFetch(sampler2D(image, s), region.xy + ivec2(x0, y0), 0).rgb;
    vec3 b = texelFetch(sampler2D(image, s), region.xy + ivec2(x1, y0), 0).rgb;
    vec3 c = texelFetch(sampler2D(image, s), region.xy + ivec2(x0, y1), 0).rgb;
    vec3 d = texelFetch(sampler2D(image, s), region.xy + ivec2(x1, y1), 0).rgb;
    return mix(mix(a, b, t.x), mix(c, d, t.x), t.y);
}

// The real SH basis up to band 2 (`EnvironmentMath.shBasis`).
void shBasis(vec3 d, out float y[9]) {
    y[0] = 0.282095;
    y[1] = 0.488603 * d.y;
    y[2] = 0.488603 * d.z;
    y[3] = 0.488603 * d.x;
    y[4] = 1.092548 * d.x * d.y;
    y[5] = 1.092548 * d.y * d.z;
    y[6] = 0.315392 * (3.0 * d.z * d.z - 1.0);
    y[7] = 1.092548 * d.x * d.z;
    y[8] = 0.546274 * (d.x * d.x - d.y * d.y);
}

// The procedural sky (`ProceduralSky`): a horizon-to-zenith gradient, the ground below a soft
// horizon, a glow around the sun and, with `disk`, the sun's disk. Linear radiance.
struct Sky {
    vec3 zenith;
    vec3 horizon;
    vec3 ground;
    vec3 sunDirection;  // toward the sun
    vec3 sunColor;      // the directional light's color x intensity
    vec4 sun;           // x, y: cos of the disk's outer and inner edge, z: disk radiance scale, w: glow
};

vec3 proceduralSky(Sky sky, vec3 d, bool disk) {
    float above = clamp(d.y, 0.0, 1.0);
    float ground = smoothstep(0.0, 0.03, -d.y);
    vec3 color = mix(mix(sky.horizon, sky.zenith, sqrt(above)), sky.ground, ground);
    float c = max(dot(d, sky.sunDirection), 0.0);
    float c2 = c * c, c4 = c2 * c2, c8 = c4 * c4, c16 = c8 * c8, c64 = c16 * c16 * c16 * c16;
    vec3 sun = sky.sunColor * (sky.sun.w * (0.25 * c8 + c64));
    if (disk) sun += sky.sunColor * (sky.sun.z * smoothstep(sky.sun.x, sky.sun.y, c));
    return color + sun * (1.0 - ground);
}
