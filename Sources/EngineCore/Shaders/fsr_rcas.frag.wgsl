// Generated from fsr_rcas.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 1a5ab98c9d5c3255
// glsl-fnv1a64: b70bd71f99229e17

diagnostic(off, derivative_uniformity);

struct type_7 {
    member: vec2<i32>,
    member_1: vec2<i32>,
    member_2: f32,
    member_3: f32,
}

@group(1) @binding(1) 
var global: sampler;
@group(1) @binding(0) 
var global_1: texture_2d<f32>;
@group(3) @binding(0) 
var<uniform> global_2: type_7;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;

fn function_() {
    let _e35 = global_3;
    let _e39 = global_2.member;
    let _e40 = (vec2<i32>(_e35.xy) - _e39);
    let _e43 = global_2.member_1;
    let _e45 = textureLoad(global_1, clamp((_e40 + vec2<i32>(0i, -1i)), vec2<i32>(0i, 0i), _e43), 0i);
    let _e46 = _e45.xyz;
    let _e49 = textureLoad(global_1, clamp((_e40 + vec2<i32>(-1i, 0i)), vec2<i32>(0i, 0i), _e43), 0i);
    let _e50 = _e49.xyz;
    let _e52 = textureLoad(global_1, clamp(_e40, vec2<i32>(0i, 0i), _e43), 0i);
    let _e53 = _e52.xyz;
    let _e56 = textureLoad(global_1, clamp((_e40 + vec2<i32>(1i, 0i)), vec2<i32>(0i, 0i), _e43), 0i);
    let _e57 = _e56.xyz;
    let _e60 = textureLoad(global_1, clamp((_e40 + vec2<i32>(0i, 1i)), vec2<i32>(0i, 0i), _e43), 0i);
    let _e61 = _e60.xyz;
    let _e64 = min(min(_e46, _e50), min(_e57, _e61));
    let _e67 = max(max(_e46, _e50), max(_e57, _e61));
    let _e79 = max(-((min(_e64, _e53) / max((_e67 * 4f), vec3<f32>(0.000015258789f, 0.000015258789f, 0.000015258789f)))), ((vec3<f32>(1f, 1f, 1f) - max(_e67, _e53)) / min(((_e64 * 4f) - vec3<f32>(4f, 4f, 4f)), vec3<f32>(-0.000015258789f, -0.000015258789f, -0.000015258789f))));
    let _e88 = global_2.member_2;
    let _e89 = (max(-0.1875f, min(max(_e79.x, max(_e79.y, _e79.z)), 0f)) * _e88);
    let _e102 = clamp(((((((_e46 * _e89) + (_e50 * _e89)) + (_e61 * _e89)) + (_e57 * _e89)) + _e53) / vec3(((4f * _e89) + 1f))), vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e108 = mix((_e102 * vec3<f32>(0.07739938f, 0.07739938f, 0.07739938f)), pow(((_e102 + vec3<f32>(0.055f, 0.055f, 0.055f)) * vec3<f32>(0.94786733f, 0.94786733f, 0.94786733f)), vec3<f32>(2.4f, 2.4f, 2.4f)), step(vec3<f32>(0.04045f, 0.04045f, 0.04045f), _e102));
    global_4 = vec4<f32>(_e108.x, _e108.y, _e108.z, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_3 = param;
    function_();
    let _e3 = global_4;
    return _e3;
}
