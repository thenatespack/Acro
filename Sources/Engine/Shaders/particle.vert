#version 450
#extension GL_GOOGLE_include_directive : require

// Camera-facing particle quads, drawn indirectly: instance i is the particle in slot
// drawList[i], vertex 0...5 a corner of its quad. Color and size follow the emitter's
// gradient and curve over the particle's life; `stretch` elongates it along its velocity.

#include "particles.glsl"

// Must match ParticleDrawUniforms in ParticleSystem.swift.
layout(set = 2, binding = 2, std140) uniform Draw {
    mat4 viewProj;
    vec4 camera;        // xyz camera position
    vec4 colors[4];     // linear RGBA keys
    vec4 colorTimes;    // their times (life fraction), ascending
    vec4 sizes;         // size multipliers
    vec4 sizeTimes;
    vec4 params;        // x stretch, y intensity, z brightness variation, w unused
    vec4 counts;        // x color keys, y size keys
} draw;
layout(set = 2, binding = 24, std430) readonly buffer Particles { Particle particles[]; };
layout(set = 2, binding = 25, std430) readonly buffer DrawList { uint drawList[]; };

layout(location = 0) out vec2 vCorner;
layout(location = 1) out vec4 vColor;

vec4 gradient(float t) {
    int count = int(draw.counts.x);
    vec4 color = draw.colors[0];
    for (int i = 1; i < 4; i++) {
        if (i >= count) break;
        float t0 = draw.colorTimes[i - 1], t1 = draw.colorTimes[i];
        if (t > t0) color = mix(draw.colors[i - 1], draw.colors[i], clamp((t - t0) / max(t1 - t0, 1e-5), 0.0, 1.0));
    }
    return color;
}

float curve(float t) {
    int count = int(draw.counts.y);
    float value = draw.sizes[0];
    for (int i = 1; i < 4; i++) {
        if (i >= count) break;
        float t0 = draw.sizeTimes[i - 1], t1 = draw.sizeTimes[i];
        if (t > t0) value = mix(draw.sizes[i - 1], draw.sizes[i], clamp((t - t0) / max(t1 - t0, 1e-5), 0.0, 1.0));
    }
    return value;
}

void main() {
    const vec2 corners[6] = vec2[](vec2(-1, -1), vec2(1, -1), vec2(1, 1), vec2(-1, -1), vec2(1, 1), vec2(-1, 1));
    Particle p = particles[drawList[gl_InstanceIndex]];
    vec2 corner = corners[gl_VertexIndex];
    float life = clamp(p.position.w / max(p.velocity.w, 1e-5), 0.0, 1.0);
    float size = p.attributes.x * curve(life);

    vec3 position = p.position.xyz;
    vec3 toCamera = draw.camera.xyz - position;
    toCamera = dot(toCamera, toCamera) > 1e-10 ? normalize(toCamera) : vec3(0, 0, 1);
    vec3 helper = abs(toCamera.y) < 0.999 ? vec3(0, 1, 0) : vec3(1, 0, 0);
    vec3 right = normalize(cross(helper, toCamera));
    vec3 up = cross(toCamera, right);
    float lengthScale = 1.0;
    vec3 velocity = p.velocity.xyz - toCamera * dot(p.velocity.xyz, toCamera);
    float speed = length(velocity);
    if (draw.params.x > 0.0 && speed > 1e-4) {
        // Streaks: the quad's long axis follows the velocity as seen from the camera.
        up = velocity / speed;
        right = cross(up, toCamera);
        lengthScale = 1.0 + draw.params.x * speed;
    } else {
        float angle = p.attributes.y + p.attributes.z * p.position.w;
        float c = cos(angle), s = sin(angle);
        vec3 rotatedRight = right * c + up * s;
        up = up * c - right * s;
        right = rotatedRight;
    }
    vec3 world = position + (right * corner.x + up * corner.y * lengthScale) * size;

    vec4 color = gradient(life);
    color.rgb *= draw.params.y * mix(1.0, p.attributes.w, draw.params.z);
    vCorner = corner;
    vColor = color;
    gl_Position = draw.viewProj * vec4(world, 1.0);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
}
