#version 450
#extension GL_GOOGLE_include_directive : require

// Decals (`Decal`, see SceneRenderer+Decals.swift): the fragment of a projector box's back face
// finds the opaque surface at its pixel and paints the texture onto it.
//
// - Position: the depth prepass's depth at this pixel through the inverse view-projection; the
//   normal from the neighboring texels (the smaller difference on each axis, so depth edges
//   don't bend it, as particle_simulate.comp), facing the camera. Outside the unit box in
//   decal space the fragment is discarded.
// - Texture: decal space xy (u right, v down, projected along local -Z), sampled with gradients
//   from the same neighbors, so mips are right at depth edges.
// - Alpha: texture alpha x opacity x angle fade (cos between the normal and the way back to
//   the projector, over `angleFade`).
// - Shading: PBR as mesh_surface.glsl with the decal's color as a dielectric albedo (F0 0.04)
//   and its roughness: sun with its cascaded shadow, ambient or environment diffuse and
//   specular, clustered point / spot lights with their shadows; then `emissive` x color added
//   unlit and the mesh shader's fog. The output is straight alpha, blended over the scene.
//
// Frame, the light buffers and the lookups below mirror mesh_surface.glsl (keep them in sync);
// rerun Scripts/compile-shaders.sh after editing.

#include "decal_surface.glsl"
