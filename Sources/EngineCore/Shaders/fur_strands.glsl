// Fur and hair strand coverage, shared by mesh_fur.frag (shading) and mesh_fur_depth.frag (the
// shadow atlas), so fur casts the same strands it draws. Not compiled on its own; rerun
// Scripts/compile-shaders.sh after editing it. Expects fur.glsl's varyings (vFur, vObjectPos,
// vObjectNormal, vUV), the `furData` block, `maskMap` and `materialSampler`.
//
// Coverage is analytic and filtered, never a hard hit: how much of this pixel the strands cover,
// 0...1 (AMD TressFX's distance-to-axis coverage), from the pixel's footprint (screen-space
// derivatives of the strand coordinates):
// - the strand's edge is smoothed over one pixel;
// - thin visibility (Frostbite strand hair, Tafuri 2019): a strand thinner than a pixel is drawn
//   a pixel wide with its coverage scaled by (true width / pixel width), so thin strands fade to
//   faint lines instead of popping in and out;
// - prefiltering: as the strand spacing approaches a pixel, the pattern blends into its average
//   coverage (density x strand area, of the strands still alive at this height), continuously,
//   like a mip level; shells keep tufts a few strands wide in it (their own length and color,
//   smooth noise) until those get near a pixel too: far fur is a soft volume, not noise.
//
// - shells: the strand a fragment belongs to comes from its root in the mesh's own space
//   (vObjectPos, bind pose, so strands stay on an animated mesh and don't depend on UVs): the
//   space is cut into cubes one strand spacing wide, each holding one strand at a random point
//   (its center projected onto the surface). Toward the tip the root is pulled toward a clump
//   center (clumping), circles it (curl) and wobbles (frizz). Each shell is a slice through the
//   strands: a dot per strand (radius root to tip thickness x `radiusScale`), gone above its
//   random length or the mask texture's length;
// - cards: strandsPerCard strands across each card (UV x), a soft fade toward the tips;
// - fins (vFur.z 2, `GroomFins`): quads standing on the mesh's edges along the fur; UV x counts
//   strands along the edge (FUR_FIN_DENSITY per strand spacing: a fin stands for the strands of a
//   slab around the edge), UV y is the height. Drawn like card strands;
// - the undercoat (height 0) is solid wherever fur grows.

// Strands per strand spacing along a fin (GroomFins writes UV x in these units).
#define FUR_FIN_DENSITY 2.0
// Tufts (the averaged pattern's structure) are this many strand spacings wide.
#define FUR_TUFT 3.0

// Three random numbers in 0...1 for integer cell `c`.
vec3 hash3(vec3 c) {
    uvec3 q = uvec3(ivec3(c) + ivec3(1 << 20));
    uint h = q.x * 1597334677u ^ q.y * 3812015801u ^ q.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u; h ^= h >> 13;
    uint h2 = h * 3266489917u; h2 ^= h2 >> 16;
    uint h3 = h2 * 668265263u; h3 ^= h3 >> 15;
    return vec3(float(h & 0xFFFFu), float(h2 & 0xFFFFu), float(h3 & 0xFFFFu)) / 65535.0;
}

// Smooth value noise at `x` (two channels in 0...1, trilinear between integer cells).
vec2 furValueNoise(vec3 x) {
    vec3 i = floor(x), f = x - i;
    f = f * f * (3.0 - 2.0 * f);
    vec2 a = mix(mix(hash3(i).xy, hash3(i + vec3(1.0, 0.0, 0.0)).xy, f.x),
                 mix(hash3(i + vec3(0.0, 1.0, 0.0)).xy, hash3(i + vec3(1.0, 1.0, 0.0)).xy, f.x), f.y);
    vec2 b = mix(mix(hash3(i + vec3(0.0, 0.0, 1.0)).xy, hash3(i + vec3(1.0, 0.0, 1.0)).xy, f.x),
                 mix(hash3(i + vec3(0.0, 1.0, 1.0)).xy, hash3(i + vec3(1.0, 1.0, 1.0)).xy, f.x), f.y);
    return mix(a, b, f.z);
}

// Interleaved gradient noise (Jimenez 2014): a per-pixel threshold in 0...1 for hashed alpha.
float furPixelNoise(vec2 pixel) {
    return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

// The fraction of strands still growing at height `h` when lengths are 1 - variation x random.
float furAlive(float h, float variation) {
    return clamp((1.0 - h) / max(variation, 0.02), 0.0, 1.0);
}

// Coverage of a pixel `w` wide by a line of half width `halfWidth` whose axis is `x` away, with
// thin visibility (both in the same units).
float furLineCoverage(float x, float halfWidth, float w) {
    float wide = max(halfWidth, 0.5 * w);
    return (1.0 - smoothstep(wide - 0.5 * w, wide + 0.5 * w, x)) * (halfWidth / wide);
}

// Coverage of a pixel `w` wide by a dot (a strand crossing a shell) of radius `radius` whose
// center is `x` away: as furLineCoverage, scaled by area.
float furDotCoverage(float x, float radius, float w) {
    float wide = max(radius, 0.5 * w);
    float k = radius / wide;
    return (1.0 - smoothstep(wide - 0.5 * w, wide + 0.5 * w, x)) * k * k;
}

// Card and fin strands: `u` counts strands across (one per unit), `uWidth` the pixel's width in
// those units, `v` the height 0...1, `id` a number per card or fin.
float furStripCoverage(float u, float uWidth, float v, float id, float halfScale, float variation,
                       out float along, out float strandRandom) {
    vec4 f0 = furData.fur[0];
    // Past about a pixel per strand, the strands blend into their average.
    float lod = smoothstep(0.45, 1.3, uWidth);
    float averageHalf = mix(f0.z, f0.w, v) * 0.5 * halfScale;
    float average = min(2.0 * averageHalf, 1.0) * furAlive(v, variation) * (1.0 - smoothstep(0.75, 1.0, v));
    along = v;
    strandRandom = 0.5;
    float coverage = average;
    if (lod < 0.999) {
        float index = floor(u);
        vec3 r = hash3(vec3(index, id, 7.0));
        float x = abs(fract(u) - 0.5 + (r.x - 0.5) * 0.3);
        float strandLength = 1.0 - variation * r.y;
        float strand = 0.0;
        if (v <= strandLength) {
            float a = v / max(strandLength, 1e-3);
            float halfWidth = mix(f0.z, f0.w, a) * 0.5 * halfScale;
            strand = furLineCoverage(x, halfWidth, max(uWidth, 1e-4)) * (1.0 - smoothstep(0.75, 1.0, a));
            along = mix(a, v, lod);
        }
        coverage = mix(strand, average, lod);
        strandRandom = mix(r.z, 0.5, lod);
    }
    return coverage;
}

// How much of this pixel the strands cover (0...1). `along` 0 root ... 1 tip of its strand,
// `strandRandom` a number per strand, `exposed` 0...1 how far out of its clump the strand sits
// (clumped fur opens gaps that let light down to the roots), `blur` for shells how far the
// pattern has blended away (1 only the average with tufts, 2 only the plain average: shells
// then look alike, so mesh_fur.frag can draw every 2nd or 4th one, more opaque).
float furCoverage(float radiusScale, out float along, out float strandRandom, out float exposed, out float blur) {
    float h = vFur.x;
    bool cards = vFur.z > 0.5 && vFur.z < 1.5;
    bool fin = vFur.z > 1.5;
    bool undercoat = vFur.w > 0.5;
    vec4 f0 = furData.fur[0], f1 = furData.fur[1], f2 = furData.fur[2];
    // The pixel's footprint (derivatives first, while every pixel of the quad is still running).
    vec3 dpx = dFdx(vObjectPos), dpy = dFdy(vObjectPos);
    vec2 dux = vec2(dFdx(vUV.x), dFdy(vUV.x));
    along = 0.0;
    strandRandom = 0.5;
    exposed = 0.0;
    blur = 0.0;
    float maskLength = 1.0;
    if (furData.fur[6].z > 0.5 && !fin) {
        maskLength = texture(sampler2D(maskMap, materialSampler), vUV).r;
        if (furData.fur[6].w > 0.5) maskLength = 1.0 - maskLength;
    }
    if (undercoat) {
        if (maskLength < 0.02) return 0.0;
        strandRandom = hash3(floor(vObjectPos / max(f0.y, 1e-5))).z;
        return 1.0;
    }
    if (cards) {
        float strands = max(furData.fur[4].w, 1.0);
        return furStripCoverage(vUV.x * strands, length(dux) * strands, h, floor(vFur.y * 65535.0), radiusScale, f2.y,
                                along, strandRandom);
    }
    if (fin) {
        // Half the strands' width and coverage: a fin only adds the strands the shells miss
        // edge-on, and its roots are hidden behind the body.
        float c = furStripCoverage(vUV.x, length(dux), h, 3.0, radiusScale * FUR_FIN_DENSITY * 0.5, max(f2.y, 0.3),
                                   along, strandRandom);
        // Fins are for close-ups: once their strands blend into an average (thinner than a
        // pixel), the shells' own averaged silhouette is soft already, and a fin would only add
        // a flat translucent sheet.
        return c * 0.6 * smoothstep(0.0, 0.35, h) * (1.0 - smoothstep(0.3, 0.9, length(dux)));
    }

    float spacing = max(f0.y, 1e-5);
    vec3 n = normalize(vObjectNormal);
    vec3 p = vObjectPos;
    float warp = 1.0;
    // Clumps: roots pulled toward a clump center (4 spacings apart) toward the tip.
    if (f1.x > 0.0) {
        float size = spacing * 4.0;
        vec3 cc = floor(p / size);
        vec3 center = (cc + 0.5 + (hash3(cc + vec3(31.0, 17.0, 5.0)) - 0.5) * 0.6) * size;
        center -= n * dot(center - p, n);
        exposed = f1.x * smoothstep(0.15, 0.6, length(p - center) / size);
        float pull = min(f1.x * h * 0.85, 0.9);
        warp = 1.0 / (1.0 - pull);
        p = center + (p - center) * warp;
    }
    // The pixel's footprint on the surface, in the (clumped) root space.
    vec3 tx = (dpx - n * dot(dpx, n)) * warp, ty = (dpy - n * dot(dpy, n)) * warp;
    float footprint = sqrt(max(dot(tx, tx), dot(ty, ty)));
    float ratio = footprint / spacing;
    // Single strands while they are wider apart than about a pixel; past that, their average.
    float lod = smoothstep(0.6, 1.6, ratio);
    float m = min(maskLength, 1.0);
    float averageRadius = mix(f0.z, f0.w, h) * 0.5 * radiusScale;
    float area = 3.14159265 * averageRadius * averageRadius;
    float coverage = 0.0;
    along = h;
    if (lod > 0.001 && m > 0.01) {
        // The average keeps tufts (FUR_TUFT spacings wide, smooth noise): their own length and
        // color, so mid-distance fur still has structure; farther, the plain average.
        float tuftLod = smoothstep(2.0, 5.0, ratio);
        blur = lod >= 1.0 ? 1.0 + step(1.0, tuftLod) : 0.0;
        vec2 tuft = furValueNoise(vObjectPos / (spacing * FUR_TUFT));
        float spread = max(f2.y * 0.35, 0.04);
        float tuftAlive = clamp(((1.0 - f2.y * tuft.x) - h / m) / spread + 0.5, 0.0, 1.0);
        coverage = area * mix(tuftAlive, furAlive(h / m, f2.y), tuftLod);
        strandRandom = mix(tuft.y, 0.5, tuftLod);
    }
    if (lod < 0.999) {
        vec3 cell = floor(p / spacing);
        vec3 r = hash3(cell);
        vec3 strand = (cell + 0.5 + (r - 0.5) * 0.5) * spacing;
        vec3 e1 = normalize(abs(n.y) < 0.9 ? cross(n, vec3(0.0, 1.0, 0.0)) : cross(n, vec3(1.0, 0.0, 0.0)));
        vec3 e2 = cross(n, e1);
        if (f1.y > 0.0) {
            float angle = h * 12.566 + r.x * 6.283;
            strand += (e1 * cos(angle) + e2 * sin(angle)) * (f1.y * 0.3 * spacing);
        }
        if (f1.z > 0.0) {
            float k = h * 4.0;
            vec3 a = hash3(cell + vec3(floor(k) * 7.0, 3.0, 11.0)), b = hash3(cell + vec3(floor(k) * 7.0 + 7.0, 3.0, 11.0));
            strand += (mix(a, b, smoothstep(0.0, 1.0, fract(k))) - 0.5) * (f1.z * 0.4 * spacing * h);
        }
        vec3 d = p - strand;
        d -= n * dot(d, n);
        float strandLength = (1.0 - f2.y * r.y) * m;
        float hit = 0.0;
        if (h <= strandLength) {
            float a = h / max(strandLength, 1e-3);
            float radius = mix(f0.z, f0.w, a) * 0.5 * spacing * radiusScale;
            float x = length(d);
            vec3 dir = x > 1e-9 ? d / x : e1;
            // The footprint across the strand (toward its axis).
            float w = max(sqrt(dot(tx, dir) * dot(tx, dir) + dot(ty, dir) * dot(ty, dir)), spacing * 1e-3);
            hit = furDotCoverage(x, radius, w);
            along = mix(a, h, lod);
        }
        coverage = mix(hit, coverage, lod);
        strandRandom = mix(r.z, strandRandom, lod);
    }
    return coverage;
}
