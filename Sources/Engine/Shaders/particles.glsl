// GPU particles (ParticleSystem.swift): the particle record, the per-emitter simulation
// parameters and the random numbers, shared by particle_*.comp and particle.vert.
//
// Determinism: every particle lives in a fixed slot of its emitter's ring (the CPU picks the
// slots each step spawns into), its random numbers hash its spawn index with the emitter's
// seed, and simulation is per slot. Counts use integer sums (order-independent), so the draw
// list, and with it the blending order, is the same on every run and backend.

// One particle (48 bytes, std430). A slot is dead while velocity.w (its lifetime) is 0.
struct Particle {
    vec4 position;    // xyz world position, w age in seconds
    vec4 velocity;    // xyz world velocity, w lifetime in seconds (0: dead)
    vec4 attributes;  // x size, y rotation, z spin (radians / s), w random 0...1 (brightness)
};

// Must match ParticleSimulationUniforms in ParticleSystem.swift (std140: mat4 / vec4 / uvec4 only).
struct EmitterParams {
    mat4 transform;   // emitter world matrix: spawn positions and directions are local to it
    vec4 shape;       // x kind (0 point, 1 sphere, 2 box, 3 disc), yzw size (radius / half extents / radius, thickness)
    vec4 direction;   // xyz local direction, w cos(spread)
    vec4 speedLife;   // x, y speed range; z, w lifetime range
    vec4 sizeSpin;    // x, y size range; z max spin; w orbit (tangential speed factor)
    vec4 forces;      // xyz gravity, w drag
    vec4 turbulence;  // x strength, y frequency, z time, w attraction toward the emitter (per unit of distance)
    vec4 ground;      // x 1 when colliding, y height, z bounce, w friction
    vec4 disc;        // x spiral arms (0: none), y twist (radians per unit of radius), z arm width (radians), w dt
    uvec4 spawn;      // x first slot, y count, z spawn index of the first, w seed
    uvec4 info;       // x capacity, y workgroups
    vec4 arms;        // x rotation of the spiral arms (radians): they turn with the orbit
};

// PCG-style integer hash (Jarzynski & Olano, "Hash Functions for GPU Rendering").
uint pcgHash(uint v) {
    uint state = v * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

// The k-th random number of a particle in [0, 1), exact in float (24 bits).
float particleRandom(uint key, uint k) {
    return float(pcgHash(key + k * 0x9E3779B9u) >> 8) * (1.0 / 16777216.0);
}
