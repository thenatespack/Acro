#version 450
#extension GL_GOOGLE_include_directive : require

// SceneRenderer's lit forward shader for alpha-tested materials (AlphaMode.mask): a separate
// variant so the discard costs early depth testing only where it is needed.
#define ALPHA_MASK
#include "mesh_surface.glsl"
