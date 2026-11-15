// The draw uniforms of particle.vert, particle.frag and particle_lit.frag (ParticleSystem.swift).
// Not compiled on its own; rerun Scripts/compile-shaders.sh after editing it.

// Must match ParticleDrawUniforms in ParticleSystem.swift.
layout(set = 2, binding = 2, std140) uniform Draw {
    mat4 viewProj;
    vec4 camera;        // xyz camera position
    vec4 colors[4];     // linear RGBA keys
    vec4 colorTimes;    // their times (life fraction), ascending
    vec4 sizes;         // size multipliers
    vec4 sizeTimes;
    vec4 params;        // x stretch, y intensity, z brightness variation, w stretch mode (1: streak, else scaled)
    vec4 counts;        // x color keys, y size keys
    vec4 atlas;         // flipbook: x columns, y rows, z frames, w frames per second (0: once over the particle's life)
    vec4 atlasFlags;    // x random start frame, y blend between frames, z textured (else a soft disc)
    vec4 soft;          // x 1 / soft fade distance (0: off), y, z view depth of a depth value d: y / (d + z), w receives the sun's shadow
} draw;
