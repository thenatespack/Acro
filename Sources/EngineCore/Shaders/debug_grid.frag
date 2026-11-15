#version 450

// Debug ground grid: lines a fixed number of pixels wide, found from the distance to the nearest
// grid line over its screen-space derivative (so they stay antialiased at any distance). Minor
// and major lines fade out where their cells shrink below a few pixels (no moiré at grazing
// angles), and everything fades with distance from the camera. Straight alpha.

layout(set = 2, binding = 2, std140) uniform Grid {
    mat4 viewProj;
    vec4 camera;  // xyz: camera position, w: grid height
    vec4 params;  // x: spacing, y: major line every n cells, z: fade distance, w: line width in pixels
    vec4 minorColor;
    vec4 majorColor;
    vec4 xAxisColor;
    vec4 zAxisColor;
} grid;

layout(location = 0) in vec3 vWorld;
layout(location = 0) out vec4 outColor;

// Coverage of lines `width` pixels wide at every integer of `coord`, and the cell size in pixels.
float lines(vec2 coord, float width, out float cellPixels) {
    vec2 derivative = max(fwidth(coord), vec2(1e-6));
    vec2 pixels = abs(fract(coord - 0.5) - 0.5) / derivative;
    vec2 coverage = clamp(width * 0.5 + 0.5 - pixels, 0.0, 1.0);
    cellPixels = 1.0 / max(derivative.x, derivative.y);
    return max(coverage.x, coverage.y);
}

vec4 over(vec4 below, vec4 color, float coverage) {
    return vec4(mix(below.rgb, color.rgb, coverage), max(below.a, color.a * coverage));
}

void main() {
    vec2 p = vWorld.xz;
    float width = grid.params.w;
    float minorCell, majorCell;
    vec2 cell = p / grid.params.x;
    float minor = lines(cell, width, minorCell) * smoothstep(4.0, 12.0, minorCell);
    float major = lines(cell / grid.params.y, width, majorCell) * smoothstep(4.0, 12.0, majorCell);
    // The x axis runs along z = 0, the z axis along x = 0; both twice as wide.
    vec2 axis = clamp(width + 0.5 - abs(p) / max(fwidth(p), vec2(1e-6)), 0.0, 1.0);

    vec4 color = vec4(grid.minorColor.rgb, grid.minorColor.a * minor);
    color = over(color, grid.majorColor, major);
    color = over(color, grid.xAxisColor, axis.y);
    color = over(color, grid.zAxisColor, axis.x);
    float distance = length(p - grid.camera.xz);
    color.a *= 1.0 - smoothstep(grid.params.z * 0.4, grid.params.z, distance);
    if (color.a <= 0.0) discard;
    outColor = color;
}
