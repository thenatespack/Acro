#version 450
#extension GL_GOOGLE_include_directive : require
// compile-shaders: gles -DPARTICLES_INSTANCED

// Lit particles (`ParticleEmitter.lit`): lit per vertex (see particle_vertex.glsl and
// particle_lighting.glsl), drawn with particle.frag.
#define LIT
#include "particle_vertex.glsl"
