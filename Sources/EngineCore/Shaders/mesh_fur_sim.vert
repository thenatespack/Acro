#version 450
#extension GL_GOOGLE_include_directive : require

// mesh_fur.vert for simulated hair cards (HairSimulation.swift): world-space vertices and last
// frame's positions in attribute 14, for the motion vectors (see fur.glsl).
#define SIMULATED
#include "fur.glsl"
