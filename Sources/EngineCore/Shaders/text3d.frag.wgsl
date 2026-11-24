// Generated from text3d.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 6403a3086bd58aa4
// glsl-fnv1a64: f3f9431411ff6165

diagnostic(off, derivative_uniformity);

struct type_11 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
}

struct type_16 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
}

var<private> global: f32;
@group(2) @binding(9) 
var global_1: texture_2d<f32>;
@group(2) @binding(17) 
var global_2: sampler;
var<private> global_3: vec2<f32>;
@group(2) @binding(2) 
var<uniform> global_4: type_11;
var<private> global_5: f32;
@group(0) @binding(0) 
var<uniform> global_6: type_16;
var<private> global_7: vec4<f32>;

fn function_() {
    var phi_178_: vec3<f32>;
    var phi_177_: f32;
    var phi_180_: vec3<f32>;
    var phi_179_: f32;

    let _e19 = global;
    if (_e19 < 0.5f) {
        discard;
    }
    let _e21 = global_3;
    let _e22 = textureSample(global_1, global_2, _e21);
    let _e24 = fwidth(_e22.x);
    let _e26 = max((_e24 * 0.5f), 0.001953125f);
    let _e29 = smoothstep((0.5f - _e26), (0.5f + _e26), _e22.x);
    let _e31 = global_4.member_3;
    let _e34 = global_4.member_4;
    let _e36 = (_e31.xyz + _e34.xyz);
    let _e39 = global_4.member_5[3u];
    phi_178_ = _e36;
    phi_177_ = _e29;
    if (_e39 > 0f) {
        let _e41 = (0.5f - _e39);
        let _e46 = global_4.member_5;
        phi_178_ = mix(_e46.xyz, _e36, vec3(_e29));
        phi_177_ = smoothstep((_e41 - _e26), (_e41 + _e26), _e22.x);
    }
    let _e51 = phi_178_;
    let _e53 = phi_177_;
    let _e56 = global_4.member_6[3u];
    phi_180_ = _e51;
    phi_179_ = _e53;
    if (_e56 > 0f) {
        let _e61 = clamp(((_e22.x - (0.5f - _e56)) / _e56), 0f, 1f);
        let _e64 = ((_e61 * _e61) * (1f - _e53));
        let _e65 = (_e53 + _e64);
        let _e68 = global_4.member_6;
        phi_180_ = (((_e51 * _e53) + (_e68.xyz * _e64)) / vec3(max(_e65, 0.00001f)));
        phi_179_ = _e65;
    }
    let _e76 = phi_180_;
    let _e78 = phi_179_;
    let _e81 = global_4.member_3[3u];
    let _e82 = (_e78 * _e81);
    if (_e82 <= 0f) {
        discard;
    }
    let _e84 = global_5;
    let _e88 = global_6.member_7[3u];
    let _e93 = global_6.member_7;
    let _e96 = mix(_e76, _e93.xyz, vec3((1f - exp((-(_e84) * _e88)))));
    global_7 = vec4<f32>(_e96.x, _e96.y, _e96.z, _e82);
    return;
}

@fragment 
fn main(@location(2) @interpolate(flat) param: f32, @location(0) param_1: vec2<f32>, @location(1) param_2: f32) -> @location(0) vec4<f32> {
    global = param;
    global_3 = param_1;
    global_5 = param_2;
    function_();
    let _e7 = global_7;
    return _e7;
}
