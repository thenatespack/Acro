#version 450
#extension GL_GOOGLE_include_directive : require

// SceneRenderer's light probe debug spheres (`LightProbeDebug.showsProbes`, with mesh.vert):
// reflection probes as mirror balls showing their own image, irradiance probes shaded by their
// SH (red when inside geometry). See mesh_surface.glsl's PROBE_DEBUG block.
#define PROBE_DEBUG
#include "mesh_surface.glsl"
