// Generated from debug_grid.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 590329dd26619eaa
// glsl-fnv1a64: fabc356a27b91b45

diagnostic(off, derivative_uniformity);

struct type_7 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
}

var<private> global: vec3<f32>;
@group(2) @binding(2) 
var<uniform> global_1: type_7;
var<private> global_2: vec4<f32>;

fn function_() {
    let _e24 = global;
    let _e25 = _e24.xz;
    let _e28 = global_1.member_2[3u];
    let _e31 = global_1.member_2[0u];
    let _e33 = (_e25 / vec2(_e31));
    let _e34 = fwidth(_e33);
    let _e35 = max(_e34, vec2<f32>(0.000001f, 0.000001f));
    let _e43 = vec2(((_e28 * 0.5f) + 0.5f));
    let _e45 = clamp((_e43 - (abs((fract((_e33 - vec2<f32>(0.5f, 0.5f))) - vec2<f32>(0.5f, 0.5f))) / _e35)), vec2<f32>(0f, 0f), vec2<f32>(1f, 1f));
    let _e57 = global_1.member_2[1u];
    let _e59 = (_e33 / vec2(_e57));
    let _e60 = fwidth(_e59);
    let _e61 = max(_e60, vec2<f32>(0.000001f, 0.000001f));
    let _e68 = clamp((_e43 - (abs((fract((_e59 - vec2<f32>(0.5f, 0.5f))) - vec2<f32>(0.5f, 0.5f))) / _e61)), vec2<f32>(0f, 0f), vec2<f32>(1f, 1f));
    let _e77 = (max(_e68.x, _e68.y) * smoothstep(4f, 12f, (1f / max(_e61.x, _e61.y))));
    let _e80 = fwidth(_e25);
    let _e85 = clamp((vec2((_e28 + 0.5f)) - (abs(_e25) / max(_e80, vec2<f32>(0.000001f, 0.000001f)))), vec2<f32>(0f, 0f), vec2<f32>(1f, 1f));
    let _e87 = global_1.member_3;
    let _e90 = global_1.member_3[3u];
    let _e91 = (_e90 * (max(_e45.x, _e45.y) * smoothstep(4f, 12f, (1f / max(_e35.x, _e35.y)))));
    let _e97 = global_1.member_4;
    let _e101 = mix(vec4<f32>(_e87.x, _e87.y, _e87.z, _e91).xyz, _e97.xyz, vec3(_e77));
    let _e104 = max(_e91, (_e97.w * _e77));
    let _e110 = global_1.member_5;
    let _e115 = mix(vec4<f32>(_e101.x, _e101.y, _e101.z, _e104).xyz, _e110.xyz, vec3(_e85.y));
    let _e118 = max(_e104, (_e110.w * _e85.y));
    let _e124 = global_1.member_6;
    let _e129 = mix(vec4<f32>(_e115.x, _e115.y, _e115.z, _e118).xyz, _e124.xyz, vec3(_e85.x));
    let _e132 = max(_e118, (_e124.w * _e85.x));
    let _e136 = vec4<f32>(_e129.x, _e129.y, _e129.z, _e132);
    let _e138 = global_1.member_1;
    let _e144 = global_1.member_2[2u];
    let _e148 = (_e132 * (1f - smoothstep((_e144 * 0.4f), _e144, length((_e25 - _e138.xz)))));
    if (_e148 <= 0f) {
        discard;
    }
    global_2 = vec4<f32>(_e136.x, _e136.y, _e136.z, _e148);
    return;
}

@fragment 
fn main(@location(0) param: vec3<f32>) -> @location(0) vec4<f32> {
    global = param;
    function_();
    let _e3 = global_2;
    return _e3;
}
