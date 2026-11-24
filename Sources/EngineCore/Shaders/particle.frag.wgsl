// Generated from particle.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 8d2398c2d0f7c792
// glsl-fnv1a64: 270ecc2a7da9a11b

diagnostic(off, derivative_uniformity);

struct type_6 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: array<vec4<f32>, 4>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
    member_9: vec4<f32>,
    member_10: vec4<f32>,
}

var<private> global: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_1: type_6;
@group(2) @binding(9) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;
var<private> global_4: vec4<f32>;
var<private> global_5: f32;
var<private> global_6: vec2<f32>;
@group(2) @binding(10) 
var global_7: texture_2d<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;

fn function_() {
    var phi_143_: vec4<f32>;
    var phi_145_: vec4<f32>;
    var phi_146_: vec4<f32>;

    let _e20 = global;
    let _e23 = global_1.member_9[2u];
    if (_e23 > 0.5f) {
        let _e25 = global_4;
        let _e27 = textureSample(global_2, global_3, _e25.xy);
        let _e28 = global_5;
        phi_143_ = _e27;
        if (_e28 > 0f) {
            let _e31 = textureSample(global_2, global_3, _e25.zw);
            phi_143_ = mix(_e27, _e31, vec4(_e28));
        }
        let _e35 = phi_143_;
        phi_145_ = (_e20 * _e35);
    } else {
        let _e37 = global_6;
        let _e40 = clamp((1f - dot(_e37, _e37)), 0f, 1f);
        phi_145_ = vec4<f32>(_e20.x, _e20.y, _e20.z, (_e20.w * (_e40 * _e40)));
    }
    let _e50 = phi_145_;
    let _e53 = global_1.member_10[0u];
    phi_146_ = _e50;
    if (_e53 > 0f) {
        let _e55 = global_8;
        let _e58 = textureLoad(global_7, vec2<i32>(_e55.xy), 0i);
        let _e62 = global_1.member_10[1u];
        let _e65 = global_1.member_10[2u];
        let _e69 = global_8[2u];
        phi_146_ = vec4<f32>(_e50.x, _e50.y, _e50.z, (_e50.w * clamp((((_e62 / (_e58.x + _e65)) - (_e62 / (_e69 + _e65))) * _e53), 0f, 1f)));
    }
    let _e83 = phi_146_;
    global_9 = _e83;
    return;
}

@fragment 
fn main(@location(1) param: vec4<f32>, @location(2) param_1: vec4<f32>, @location(3) param_2: f32, @location(0) param_3: vec2<f32>, @builtin(position) param_4: vec4<f32>) -> @location(0) vec4<f32> {
    global = param;
    global_4 = param_1;
    global_5 = param_2;
    global_6 = param_3;
    global_8 = param_4;
    function_();
    let _e11 = global_9;
    return _e11;
}
