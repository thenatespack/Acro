
// The particle vertex shader, included by particle.vert and particle_lit.vert (which defines
// LIT). Not compiled on its own; rerun Scripts/compile-shaders.sh after editing it.
//
// Camera-facing particle quads, drawn indirectly: instance i is the particle in slot
// drawList[i], vertex 0...5 a corner of its quad. Color and size follow the emitter's
// gradient and curve over the particle's life; `stretch` elongates it along its velocity.
// With a texture atlas (flipbook), the corner's UVs in this frame's cell and the next one's,
// and how far the particle is between them. LIT: the color is an albedo, lit at the corner
// (particle_lighting.glsl).

#include "particles.glsl"
#include "particle_draw.glsl"

layout(set = 2, binding = 24, std430) readonly buffer Particles { Particle particles[]; };
layout(set = 2, binding = 25, std430) readonly buffer DrawList { uint drawList[]; };

layout(location = 0) out vec2 vCorner;
layout(location = 1) out vec4 vColor;
layout(location = 2) out vec4 vUV;       // xy this frame's cell, zw the next frame's
layout(location = 3) out float vBlend;   // 0...1 toward the next frame

#ifdef LIT
#include "particle_lighting.glsl"
#endif

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

// The UVs of `uv` (0-1 across the quad, v down) in atlas cell `frame` (row-major from the top left).
vec2 cellUV(float frame, vec2 uv) {
    float column = mod(frame, draw.atlas.x), row = floor(frame / draw.atlas.x);
    return (vec2(column, row) + uv) / draw.atlas.xy;
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
    float lengthScale = 1.0, lengthAdd = 0.0;
    vec3 velocity = p.velocity.xyz - toCamera * dot(p.velocity.xyz, toCamera);
    float speed = length(velocity);
    if (draw.params.x > 0.0 && speed > 1e-4) {
        // Streaks: the quad's long axis follows the velocity as seen from the camera.
        up = velocity / speed;
        right = cross(up, toCamera);
        if (draw.params.w > 0.5) lengthAdd = 0.5 * draw.params.x * speed;  // streak: 2 size + stretch speed long
        else lengthScale = 1.0 + draw.params.x * speed;
    } else {
        float angle = p.attributes.y + p.attributes.z * p.position.w;
        float c = cos(angle), s = sin(angle);
        vec3 rotatedRight = right * c + up * s;
        up = up * c - right * s;
        right = rotatedRight;
    }
    vec3 world = position + (right * corner.x + up * corner.y * lengthScale) * size + up * (corner.y * lengthAdd);

    vec4 color = gradient(life);
    color.rgb *= draw.params.y * mix(1.0, p.attributes.w, draw.params.z);
    vCorner = corner;
    vColor = color;
    vUV = vec4(0.0);
    vBlend = 0.0;
    if (draw.atlasFlags.z > 0.5) {
        // Flipbook: frame over life (once) or at a rate (looping), from a random start frame.
        float frames = draw.atlas.z;
        float frame = draw.atlas.w > 0.0 ? p.position.w * draw.atlas.w : life * frames;
        if (draw.atlasFlags.x > 0.5) frame += floor(p.attributes.w * frames);
        bool loops = draw.atlas.w > 0.0 || draw.atlasFlags.x > 0.5;
        float first = floor(frame);
        vBlend = draw.atlasFlags.y > 0.5 ? frame - first : 0.0;
        float next = first + 1.0;
        if (loops) {
            first = mod(first, frames);
            next = mod(next, frames);
        } else {
            first = min(first, frames - 1.0);
            next = min(next, frames - 1.0);
        }
        vec2 uv = vec2(corner.x * 0.5 + 0.5, 0.5 - corner.y * 0.5);
        vUV = vec4(cellUV(first, uv), cellUV(next, uv));
    }
    gl_Position = draw.viewProj * vec4(world, 1.0);
#ifdef LIT
    vec3 toEye = draw.camera.xyz - world;
    vColor.rgb *= particleLight(world, dot(toEye, toEye) > 1e-10 ? normalize(toEye) : toCamera, gl_Position, draw.soft.w > 0.5);
#endif
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
}
