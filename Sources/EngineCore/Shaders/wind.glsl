// Wind sway for SceneRenderer meshes whose material has wind (`Material.wind`, MaterialWind):
// included by mesh_wind.vert (lit passes) and mesh_shadow_wind.vert (shadows and depth prepasses),
// so a swaying plant's shadow sways with it. Materials without wind never run this: they draw
// with mesh.vert / mesh_shadow*.vert, unchanged. Must match `WindUniforms` (SceneRenderer+Wind.swift)
// and its CPU mirror `WindSway.offset` (Wind.swift), which the tests check.
//
// Uniform buffer 2 holds the material first (the fragment shaders read it as MaterialData, see
// mesh_surface.glsl), padded to 128 bytes like skinning.glsl's block, then:
// - plant: xyz the plant's base point in object space (where it stands), w its flutter amount;
// - axis: xyz the plant's up axis in object space (unit), w 1 / its height (0: no trunk bend);
// - global: xy the wind's world direction in XZ (unit), z its strength, w its gustiness
//   (`SceneEnvironment.wind`);
// - clock: x the time in seconds, y last frame's (motion vectors).
//
// The sway comes from the object-space position alone (no vertex attribute) and the plant's base:
// - trunk bend: along the wind, strength x gust x 0.06 x h² / height, h the height above the base
//   along the up axis, so the base stays put and the top moves about 6% of the plant's height at
//   strength 1; points also drop by bend² / 2h, so branches swing on an arc instead of stretching;
// - flutter: a small wobble (up to 3 cm x flutter x strength) whose phase is a cheap noise of the
//   object position, so cards on one branch don't move as one; it fades in over the first 0.33 m
//   above the base;
// - every plant's gusts and sway are offset by its base's world position (a phase that also rolls
//   along the wind), so a forest of instanced copies doesn't sway in sync.
layout(set = 2, binding = 2, std140) uniform WindData {
    vec4 material[8];
    vec4 plant;
    vec4 axis;
    vec4 global;
    vec4 clock;
} wind;

// The object-space offset of object-space `p` at `time`, for a plant whose model matrix has the
// 3x3 part `basis` and whose base is at `base` in world space.
vec3 windOffset(vec3 p, mat3 basis, vec3 base, float time) {
    float h = max(dot(wind.axis.xyz, p - wind.plant.xyz), 0.0);
    float strength = wind.global.z;
    vec2 dir = wind.global.xy;
    float phase = dot(base.xz, dir) * 0.35 + dot(base.xz, vec2(0.83, -0.57)) * 1.7;
    float g = 0.5 + 0.5 * sin(time * 0.61 + phase) * sin(time * 0.23 + phase * 0.7);
    float gust = 1.0 + wind.global.w * (g * 1.6 - 0.6);
    float sway = 0.75 + 0.25 * sin(time * 1.7 + phase * 1.3);
    float bend = strength * gust * sway * 0.06 * h * h * wind.axis.w;
    // The world direction in object space (the basis's transpose undoes its rotation).
    vec3 along = transpose(basis) * vec3(dir.x, 0.0, dir.y);
    float n2 = dot(along, along);
    along = n2 > 1e-12 ? along * inversesqrt(n2) : vec3(0.0);
    vec3 offset = along * bend - wind.axis.xyz * (0.5 * bend * bend / max(h, 1e-3));
    float n = dot(p, vec3(3.1, 2.3, 2.7));
    float wave = sin(time * 7.3 + n + phase) + 0.5 * sin(time * 11.1 + n * 1.7 + phase * 2.1);
    float flutter = wind.plant.w * strength * (0.6 + 0.4 * gust) * clamp(h * 3.0, 0.0, 1.0) * 0.02 * wave;
    return offset + vec3(sin(n * 1.3 + 1.0), cos(n * 0.9), sin(n * 1.7 + 2.0)) * flutter;
}

// Any mesh vertex shader sways by including this file and replacing its object-space position
// with windSwayed(position, model, wind.clock.x) (and, for motion vectors, the previous position
// with windSwayed(position, previousModel, wind.clock.y)) before multiplying by the model matrix.
vec3 windSwayed(vec3 p, mat4 model, float time) {
    vec3 base = (model * vec4(wind.plant.xyz, 1.0)).xyz;
    return p + windOffset(p, mat3(model[0].xyz, model[1].xyz, model[2].xyz), base, time);
}
