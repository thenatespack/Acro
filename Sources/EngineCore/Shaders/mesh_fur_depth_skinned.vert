#version 450
#extension GL_GOOGLE_include_directive : require

// mesh_fur_depth.vert for skinned meshes (see fur.glsl).
#define FUR_DEPTH
#define SKINNED
#include "fur.glsl"
