// Fur and hair strand coverage, shared by mesh_fur.frag (shading) and mesh_fur_depth.frag (the
// shadow atlas), so fur casts the same strands it draws. Not compiled on its own; rerun
// Scripts/compile-shaders.sh after editing it. Expects fur.glsl's varyings (vFur, vObjectPos,
// vObjectNormal, vUV), the `furData` block, `maskMap` and `materialSampler`.
//
// - shells: the strand a fragment belongs to comes from its root in the mesh's own space
//   (vObjectPos, bind pose, so strands stay on an animated mesh and don't depend on UVs): the
//   space is cut into cubes one strand spacing wide, each holding one strand at a random point
//   (its center projected onto the surface). Toward the tip the root is pulled toward a clump
//   center (clumping), circles it (curl) and wobbles (frizz). Fragments outside the strand's
//   radius (root to tip thickness, x `radiusScale`), above its random length or above the mask
//   texture's length are not covered;
// - cards: strandsPerCard strands across each card (UV x), tapering to a soft edge (`alpha`);
// - the undercoat (height 0) is solid wherever fur grows.

// Three random numbers in 0...1 for integer cell `c`.
vec3 hash3(vec3 c) {
    uvec3 q = uvec3(ivec3(c) + ivec3(1 << 20));
    uint h = q.x * 1597334677u ^ q.y * 3812015801u ^ q.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u; h ^= h >> 13;
    uint h2 = h * 3266489917u; h2 ^= h2 >> 16;
    uint h3 = h2 * 668265263u; h3 ^= h3 >> 15;
    return vec3(float(h & 0xFFFFu), float(h2 & 0xFFFFu), float(h3 & 0xFFFFu)) / 65535.0;
}

// Whether this fragment lies on a strand. `along` 0 root ... 1 tip of its strand, `strandRandom`
// a number per strand, `alpha` the card coverage (1 for shells), `exposed` 0...1 how far out of
// its clump the strand sits (clumped fur opens gaps that let light down to the roots).
bool furCoverage(float radiusScale, out float along, out float strandRandom, out float alpha, out float exposed) {
    float h = vFur.x;
    bool cards = vFur.z > 0.5;
    bool undercoat = vFur.w > 0.5;
    vec4 f0 = furData.fur[0], f1 = furData.fur[1], f2 = furData.fur[2];
    along = 0.0;
    strandRandom = 0.5;
    alpha = 1.0;
    exposed = 0.0;
    float maskLength = 1.0;
    if (furData.fur[6].z > 0.5) {
        maskLength = texture(sampler2D(maskMap, materialSampler), vUV).r;
        if (furData.fur[6].w > 0.5) maskLength = 1.0 - maskLength;
    }
    if (undercoat) {
        if (maskLength < 0.02) return false;
        strandRandom = hash3(floor(vObjectPos / max(f0.y, 1e-5))).z;
    } else if (!cards) {
        float spacing = max(f0.y, 1e-5);
        vec3 n = normalize(vObjectNormal);
        vec3 p = vObjectPos;
        // Clumps: roots pulled toward a clump center (4 spacings apart) toward the tip.
        if (f1.x > 0.0) {
            float size = spacing * 4.0;
            vec3 cc = floor(p / size);
            vec3 center = (cc + 0.5 + (hash3(cc + vec3(31.0, 17.0, 5.0)) - 0.5) * 0.6) * size;
            center -= n * dot(center - p, n);
            exposed = f1.x * smoothstep(0.15, 0.6, length(p - center) / size);
            float pull = min(f1.x * h * 0.85, 0.9);
            p = center + (p - center) / (1.0 - pull);
        }
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
        float strandLength = (1.0 - f2.y * r.y) * min(maskLength, 1.0);
        if (h > strandLength) return false;
        float radius = mix(f0.z, f0.w, h / max(strandLength, 1e-3)) * 0.5 * spacing * radiusScale;
        if (dot(d, d) > radius * radius) return false;
        along = h / max(strandLength, 1e-3);
        strandRandom = r.z;
    } else {
        float strands = max(furData.fur[4].w, 1.0);
        float u = vUV.x * strands;
        float index = floor(u);
        vec3 r = hash3(vec3(index, floor(vFur.y * 65535.0), 7.0));
        float x = fract(u) - 0.5 + (r.x - 0.5) * 0.3;
        float v = h;
        float strandLength = 1.0 - f2.y * r.y;
        if (v > strandLength) return false;
        along = v / max(strandLength, 1e-3);
        float halfWidth = mix(f0.z, f0.w, along) * 0.5 * radiusScale;
        alpha = 1.0 - smoothstep(halfWidth * 0.55, halfWidth, abs(x));
        alpha *= 1.0 - smoothstep(0.85, 1.0, along);
        if (alpha < 0.03) return false;
        strandRandom = r.z;
    }
    return true;
}
