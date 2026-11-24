// Generated from env_base.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 9d447ea6db25bef4
// glsl-fnv1a64: 6a0b877ebf393ae9

diagnostic(off, derivative_uniformity);

struct type_8 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
}

@group(2) @binding(2) 
var<uniform> global: type_8;
var<private> global_1: vec4<f32>;
@group(2) @binding(9) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;
var<private> global_4: vec4<f32>;

fn function_() {
    var phi_429_: vec3<f32>;

    let _e25 = global_1;
    let _e28 = global.member_2;
    let _e30 = (_e25.xy / _e28.zw);
    let _e33 = global.member_1[0u];
    if (_e33 > 0.5f) {
        let _e92 = global.member_2[1u];
        let _e93 = textureSampleLevel(global_2, global_3, _e30, _e92);
        phi_429_ = min(_e93.xyz, vec3<f32>(60000f, 60000f, 60000f));
    } else {
        let _e36 = global.member_3;
        let _e39 = global.member_4;
        let _e42 = global.member_5;
        let _e45 = global.member_6;
        let _e48 = global.member_7;
        let _e51 = global.member_8;
        let _e54 = ((_e30.x - 0.5f) * 6.2831855f);
        let _e56 = (_e30.y * 3.1415927f);
        let _e57 = sin(_e56);
        let _e60 = cos(_e56);
        let _e67 = smoothstep(0f, 0.03f, -(_e60));
        let _e74 = max(dot(vec3<f32>((_e57 * sin(_e54)), _e60, (-(_e57) * cos(_e54))), _e45.xyz), 0f);
        let _e75 = (_e74 * _e74);
        let _e76 = (_e75 * _e75);
        let _e77 = (_e76 * _e76);
        let _e78 = (_e77 * _e77);
        phi_429_ = (mix(mix(_e39.xyz, _e36.xyz, vec3(sqrt(clamp(_e60, 0f, 1f)))), _e42.xyz, vec3(_e67)) + ((_e48.xyz * (_e51.w * ((0.25f * _e77) + (((_e78 * _e78) * _e78) * _e78)))) * (1f - _e67)));
    }
    let _e97 = phi_429_;
    let _e98 = max(_e97, vec3<f32>(0f, 0f, 0f));
    global_4 = vec4<f32>(_e98.x, _e98.y, _e98.z, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_1 = param;
    function_();
    let _e3 = global_4;
    return _e3;
}
