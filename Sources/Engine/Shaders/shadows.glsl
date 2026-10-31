// SceneRenderer's shadow lookups, included by mesh_surface.glsl after the `Frame` block and
// the shadow atlas (`shadowMap`). Not compiled on its own; rerun Scripts/compile-shaders.sh
// after editing it. The CPU side is ShadowMaps.swift.
//
// Every shadow lives in one depth texture, the atlas (`ShadowAtlasLayout`): directional-light
// cascades in a 2-column grid at the top, then spot-light maps and point-light face blocks
// (3 x 2 faces). Each lookup maps the world position into its tile's 0-1 coordinates, offsets
// that into the atlas and filters with tent PCF, its taps clamped to the tile.
//
// - Cascades: picked by view depth (`cascadeSplits`); inside the last `cascadeBlend` of a
//   cascade's range the next one is sampled too and blended in (the last fades to lit).
//   Receivers move along their normal by a per-cascade offset (texel-sized) first.
// - Spot lights: a perspective map; point lights: six 90-degree faces (picked by the major
//   axis of the light-to-receiver vector), both widened a little so the filter stays inside
//   the tile. Receivers move along their normal and toward the light by a few texels at their
//   distance. Light index i (in the clustered light list) has spot shadow i if
//   i < shadowInfo.z, else point shadow i - shadowInfo.z if that is < shadowInfo.w.

// Tent-filtered PCF over (2r+1)² texels from 4 (r = 1) or 9 (r = 2) hardware comparison
// taps, each placed and weighted by where the sample falls inside its texel (Castaño,
// "Shadow Mapping Summary", 2013). `uv` is in atlas coordinates; taps are clamped to
// `bounds` (min xy, max zw) so they never read a neighboring tile.
float shadowPCF(vec2 uv, float ref, vec4 bounds) {
    vec2 texel = frame.shadowAtlas.xy;
    int radius = int(frame.shadowAtlas.z);
    if (radius <= 0) return texture(shadowMap, vec3(clamp(uv, bounds.xy, bounds.zw), ref));

    vec2 p = uv / texel;  // in texels
    vec2 base = floor(p + 0.5);
    vec2 st = p + 0.5 - base;
    base = (base - 0.5) * texel;
    vec2 w[3], o[3];
    int n;
    float norm;
    if (radius == 1) {
        w[0] = 3.0 - 2.0 * st; w[1] = 1.0 + 2.0 * st;
        o[0] = (2.0 - st) / w[0] - 1.0; o[1] = st / w[1] + 1.0;
        n = 2;
        norm = 1.0 / 16.0;
    } else {
        w[0] = 4.0 - 3.0 * st; w[1] = vec2(7.0); w[2] = 1.0 + 3.0 * st;
        o[0] = (3.0 - 2.0 * st) / w[0] - 2.0; o[1] = (3.0 + st) / w[1]; o[2] = st / w[2] + 2.0;
        n = 3;
        norm = 1.0 / 144.0;
    }
    float sum = 0.0;
    for (int j = 0; j < n; j++) {
        for (int i = 0; i < n; i++) {
            vec2 tap = clamp(base + vec2(o[i].x, o[j].y) * texel, bounds.xy, bounds.zw);
            sum += w[i].x * w[j].y * texture(shadowMap, vec3(tap, ref));
        }
    }
    return sum * norm;
}

// Filters tile coordinates `local` (0-1 across a tile at `origin` of `size`, atlas coordinates).
float tileShadow(vec2 local, float ref, vec2 origin, vec2 size) {
    vec2 halfTexel = frame.shadowAtlas.xy * 0.5;
    return shadowPCF(origin + local * size, ref, vec4(origin + halfTexel, origin + size - halfTexel));
}

float cascadeShadow(int c, vec3 p) {
    vec3 local = (frame.cascadeMatrices[c] * vec4(p, 1.0)).xyz;
    if (local.x < 0.0 || local.x > 1.0 || local.y < 0.0 || local.y > 1.0) return 1.0;
    vec2 origin = vec2(float(c & 1), float(c >> 1)) * frame.shadowTiles.xy;
    return tileShadow(local.xy, min(local.z, 1.0) - frame.cascadeBiases[c], origin, frame.shadowTiles.xy);
}

const vec3 cascadeTints[4] = vec3[4](vec3(1.0, 0.45, 0.45), vec3(0.45, 1.0, 0.45), vec3(0.5, 0.6, 1.0), vec3(1.0, 1.0, 0.4));

// The directional light's shadow at world position p with geometric normal ng (unit, facing
// the viewer's side). `tint` is the cascade's debug color (white unless shadowAtlas.w is set).
float directionalShadow(vec3 p, vec3 ng, out vec3 tint) {
    tint = vec3(1.0);
    int count = int(frame.shadowInfo.x);
    float depth = dot(frame.shadowDepthRow.xyz, p) + frame.shadowDepthRow.w;
    int c = 0;
    while (c < count - 1 && depth > frame.cascadeSplits[c]) c++;
    if (depth > frame.cascadeSplits[c]) return 1.0;
    float s = cascadeShadow(c, p + ng * frame.cascadeNormalOffsets[c]);
    vec3 t = cascadeTints[c];
    float start = frame.cascadeBlendStarts[c];
    if (depth > start) {
        float f = (depth - start) / (frame.cascadeSplits[c] - start);
        if (c + 1 < count) {
            s = mix(s, cascadeShadow(c + 1, p + ng * frame.cascadeNormalOffsets[c + 1]), f);
            t = mix(t, cascadeTints[c + 1], f);
        } else {
            s = mix(s, 1.0, f);
        }
    }
    if (frame.shadowAtlas.w > 0.5) tint = t;
    return s;
}

// Point-light faces, as `LocalLightShadows.faces`: right = forward x up.
const vec3 faceRight[6] = vec3[6](vec3(0, 0, 1), vec3(0, 0, -1), vec3(-1, 0, 0), vec3(-1, 0, 0), vec3(-1, 0, 0), vec3(1, 0, 0));
const vec3 faceUp[6] = vec3[6](vec3(0, 1, 0), vec3(0, 1, 0), vec3(0, 0, -1), vec3(0, 0, 1), vec3(0, 1, 0), vec3(0, 1, 0));

// Shadow of clustered light `index` (unit direction toward it `l`) at p with geometric normal
// ng; 1 for lights without a shadow map.
float localShadow(uint index, vec3 p, vec3 ng, vec3 l) {
    uint spots = uint(frame.shadowInfo.z);
    if (index < spots) {
        vec4 params = frame.spotShadowParams[index];
        vec4 clip0 = frame.spotShadowMatrices[index] * vec4(p, 1.0);
        float texel = params.z * max(clip0.w, 0.0);  // w: depth along the spot's axis
        vec3 q = p + ng * (texel * frame.shadowLocal.x) + l * (texel * frame.shadowLocal.y);
        vec4 clip = frame.spotShadowMatrices[index] * vec4(q, 1.0);
        if (clip.w <= 0.0) return 1.0;
        vec3 local = clip.xyz / clip.w;
        if (local.x < 0.0 || local.x > 1.0 || local.y < 0.0 || local.y > 1.0 || local.z > 1.0) return 1.0;
        return tileShadow(local.xy, local.z, params.xy, frame.shadowTiles.zw);
    }
    uint point = index - spots;
    if (point >= uint(frame.shadowInfo.w)) return 1.0;
    vec4 position = frame.pointShadowPositions[point];
    vec4 params = frame.pointShadowParams[point];
    float texel = position.w * length(p - position.xyz);
    vec3 d = p + ng * (texel * frame.shadowLocal.x) + l * (texel * frame.shadowLocal.y) - position.xyz;
    vec3 a = abs(d);
    int face;
    float m;
    if (a.x >= a.y && a.x >= a.z) {
        face = d.x > 0.0 ? 0 : 1;
        m = a.x;
    } else if (a.y >= a.z) {
        face = d.y > 0.0 ? 2 : 3;
        m = a.y;
    } else {
        face = d.z > 0.0 ? 4 : 5;
        m = a.z;
    }
    if (m <= 0.0) return 1.0;
    vec2 st = vec2(dot(d, faceRight[face]), dot(d, faceUp[face])) / (m * frame.shadowFaces.z);
    float ref = params.z + params.w / m;
    if (ref > 1.0) return 1.0;
    vec2 origin = params.xy + vec2(float(face % 3), float(face / 3)) * frame.shadowFaces.xy;
    return tileShadow(vec2(0.5 + 0.5 * st.x, 0.5 - 0.5 * st.y), ref, origin, frame.shadowFaces.xy);
}
