#version 450

// Debug lines (DebugDraw): one instance per segment, expanded into a screen-space quad (two
// triangles from the vertex index) with square caps and a one-pixel antialiasing margin.

layout(location = 0) in vec4 inStart;  // xyz: start, w: width in pixels, or minus the width in world units
layout(location = 1) in vec4 inEnd;    // xyz: end
layout(location = 2) in vec4 inColor;  // linear RGBA

layout(push_constant) uniform PushConstants {
    mat4 viewProj;
    vec4 viewport;  // x, y: target size in pixels, z: reversed-Z (0 / 1), w: projection y scale (P[1][1])
} pc;

layout(location = 0) out vec4 vColor;
// x: distance from the center line in pixels (signed), y: half the line width in pixels.
layout(location = 1) noperspective out vec2 vEdge;

const vec2 corners[6] = vec2[](vec2(0, -1), vec2(1, -1), vec2(1, 1), vec2(0, -1), vec2(1, 1), vec2(0, 1));

void main() {
    vec4 a = pc.viewProj * vec4(inStart.xyz, 1.0);
    vec4 b = pc.viewProj * vec4(inEnd.xyz, 1.0);
    // Clip to the near plane (clip z = 0, or z = w with reversed-Z), so an endpoint behind the
    // camera can't flip the line's direction on screen.
    float da = pc.viewport.z > 0.5 ? a.w - a.z : a.z;
    float db = pc.viewport.z > 0.5 ? b.w - b.z : b.z;
    vColor = inColor;
    if (da < 0.0 && db < 0.0) {
        gl_Position = vec4(0.0, 0.0, 0.5, 1.0);  // all six vertices equal: nothing is drawn
        vEdge = vec2(0.0);
        return;
    }
    vec4 a0 = a, b0 = b;
    if (da < 0.0) a = mix(a0, b0, da / (da - db));
    if (db < 0.0) b = mix(b0, a0, db / (db - da));

    vec2 halfViewport = pc.viewport.xy * 0.5;
    vec2 sa = a.xy / a.w * halfViewport;
    vec2 sb = b.xy / b.w * halfViewport;
    vec2 d = sb - sa;
    float len = length(d);
    vec2 dir = len > 1e-4 ? d / len : vec2(1.0, 0.0);
    vec2 normal = vec2(-dir.y, dir.x);

    vec2 corner = corners[gl_VertexIndex];
    bool atEnd = corner.x > 0.5;
    vec4 p = atEnd ? b : a;
    float width = inStart.w >= 0.0 ? inStart.w : -inStart.w * halfViewport.y * pc.viewport.w / p.w;
    float halfWidth = 0.5 * width;
    float extent = halfWidth + 1.0;
    vec2 screen = (atEnd ? sb : sa) + normal * (corner.y * extent) + dir * ((atEnd ? 1.0 : -1.0) * extent);
    gl_Position = vec4(screen / halfViewport * p.w, p.z, p.w);
    vEdge = vec2(corner.y * extent, halfWidth);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
}
