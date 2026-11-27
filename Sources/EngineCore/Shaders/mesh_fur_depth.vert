#version 450
#extension GL_GOOGLE_include_directive : require

// The shadow atlas's fur casters (SceneRenderer+Fur.swift): mesh_fur.vert's strands, position
// only, paired with mesh_fur_depth.frag (see fur.glsl).
#define FUR_DEPTH
#include "fur.glsl"
