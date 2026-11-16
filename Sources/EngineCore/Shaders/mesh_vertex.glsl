// SceneRenderer's lit forward vertex shader, included by mesh.vert, mesh_paint.vert (which
// defines VERTEX_PAINT: the mesh's vertex paint stream, vertex buffer 2, attributes 14 and 15,
// which unskinned meshes leave free; see `VertexPaint`), mesh_wind.vert (which defines WIND: the
// object-space position sways first, wind.glsl) and mesh_paint_wind.vert (both). Not compiled on its own; rerun
// Scripts/compile-shaders.sh after editing it.
// Must match `SceneRenderer.FrameUniforms`.
layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;          // jittered with a temporal upscaler
    mat4 lightViewProj;     // unused here (the shadow passes' projection)
    mat4 currentViewProj;   // unjittered, for motion vectors
    mat4 previousViewProj;  // last frame's, unjittered
    vec4 lightDir;          // xyz: direction toward the light, w: intensity
    vec4 lightColor;        // rgb: color, w: 1 when shadows are enabled
    vec4 cameraPos;         // xyz: eye, w: height fog base height
    vec4 fogColor;          // rgb: fog color, w: density
    vec4 skyColor;          // rgb: hemisphere sky color, w: ambient intensity
    vec4 groundColor;       // rgb: hemisphere ground color, w: height fog falloff
    vec4 shadowParams;      // x: shadow-map texel size, y: depth bias, z: PCF radius in texels
} frame;

#ifdef WIND
#include "wind.glsl"
#endif

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;
layout(location = 3) in vec4 model0;
layout(location = 4) in vec4 model1;
layout(location = 5) in vec4 model2;
layout(location = 6) in vec4 model3;
layout(location = 7) in vec4 previous0;  // last frame's model matrix, for motion vectors
layout(location = 8) in vec4 previous1;
layout(location = 9) in vec4 previous2;
layout(location = 10) in vec4 previous3;
layout(location = 11) in vec4 inColor;   // linear rgb, a: opacity
layout(location = 12) in vec4 inParams;  // x: receives shadows, yzw: emissive multiplier - 1
layout(location = 13) in vec4 inTangent; // xyz: tangent (increasing U), w: bitangent sign x baked occlusion (MeshVertex.tangent)
#ifdef VERTEX_PAINT
layout(location = 14) in vec4 inPaintColor;    // VertexPaint.color: rgb albedo factor, a: opacity factor
layout(location = 15) in vec4 inPaintSurface;  // VertexPaint.surface: x roughness, y metallic, z emission factors
#endif

layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec3 vNormal;
layout(location = 2) out vec2 vUV;
layout(location = 3) out vec4 vColor;
layout(location = 5) out vec4 vParams;
layout(location = 6) out vec4 vCurrentClip;   // unjittered, for motion vectors
layout(location = 7) out vec4 vPreviousClip;
layout(location = 8) out vec4 vTangent;       // world-space tangent, w: bitangent sign (mirroring included)
layout(location = 4) out vec3 vObjectPos;     // the position before the model transform, for edge wear
#ifdef VERTEX_PAINT
layout(location = 9) out vec4 vPaintColor;
layout(location = 10) out vec4 vPaintSurface;
#endif

void main() {
    mat4 model = mat4(model0, model1, model2, model3);
    mat4 previousModel = mat4(previous0, previous1, previous2, previous3);
#ifdef WIND
    // Sway at this frame's time, and at last frame's for the motion vector (`precise` keeps
    // Metal and Vulkan in step). Normals don't turn with the sway.
    vec3 swayed = windSwayed(inPosition, model, wind.clock.x);
    vec3 previousSwayed = windSwayed(inPosition, previousModel, wind.clock.y);
    precise vec4 world = model * vec4(swayed, 1.0);
    precise vec4 previousWorld = previousModel * vec4(previousSwayed, 1.0);
#else
    vec4 world = model * vec4(inPosition, 1.0);
    vec4 previousWorld = previousModel * vec4(inPosition, 1.0);
#endif

    // The cofactor matrix is the inverse transpose up to a scale factor, so it transforms
    // normals correctly for any affine model matrix (non-uniform scale under a rotated
    // parent, mirroring). The fragment shader normalizes.
    vec3 a = model0.xyz, b = model1.xyz, c = model2.xyz;
    mat3 cofactor = mat3(cross(b, c), cross(c, a), cross(a, b));
    float handedness = dot(cross(a, b), c) < 0.0 ? -1.0 : 1.0;

    gl_Position = frame.viewProj * world;
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    vWorldPos = world.xyz;
    vNormal = cofactor * inNormal * handedness;
    vUV = inUV;
    vColor = inColor;
    vParams = inParams;
    vCurrentClip = frame.currentViewProj * world;
    vPreviousClip = frame.previousViewProj * previousWorld;
    // Tangents transform like positions; a mirroring model matrix flips the bitangent.
    vTangent = vec4(mat3(a, b, c) * inTangent.xyz, inTangent.w * handedness);
    vObjectPos = inPosition;
#ifdef VERTEX_PAINT
    vPaintColor = inPaintColor;
    vPaintSurface = inPaintSurface;
#endif
}
