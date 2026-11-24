// Generated from sky.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 1dd939ef2c066d33
// glsl-fnv1a64: 8e97b8b7cec86dd8

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

struct type_16 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
}

struct FragmentOutput {
    @location(0) member: vec4<f32>,
    @location(1) member_1: vec2<f32>,
}

@group(2) @binding(2) 
var<uniform> global: type_8;
var<private> global_1: vec4<f32>;
@group(2) @binding(9) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;
var<private> global_4: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_5: type_16;
var<private> global_6: vec2<f32>;

fn function_() {
    var phi_587_: vec3<f32>;
    var phi_588_: vec3<f32>;
    var phi_341_: bool;
    var phi_589_: vec2<f32>;

    let _e30 = global_1;
    let _e33 = global_1[3u];
    let _e36 = normalize((_e30.xyz / vec3(_e33)));
    let _e39 = global.member_1[0u];
    if (_e39 > 0.5f) {
        let _e92 = global.member_1;
        let _e111 = vec2<f32>(((atan2(((_e92.z * _e36.x) - (_e92.w * _e36.z)), -(((_e92.w * _e36.x) + (_e92.z * _e36.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e36.y, -1f, 1f)) * 0.31830987f));
        let _e112 = dpdx(_e111);
        let _e113 = dpdy(_e111);
        let _e126 = textureSampleGrad(global_2, global_3, _e111, vec2<f32>((_e112.x - round(_e112.x)), _e112.y), vec2<f32>((_e113.x - round(_e113.x)), _e113.y));
        phi_587_ = _e126.xyz;
    } else {
        let _e42 = global.member_3;
        let _e45 = global.member_4;
        let _e48 = global.member_5;
        let _e51 = global.member_6;
        let _e54 = global.member_7;
        let _e55 = _e54.xyz;
        let _e57 = global.member_8;
        let _e61 = smoothstep(0f, 0.03f, -(_e36.y));
        let _e68 = max(dot(_e36, _e51.xyz), 0f);
        let _e69 = (_e68 * _e68);
        let _e70 = (_e69 * _e69);
        let _e71 = (_e70 * _e70);
        let _e72 = (_e71 * _e71);
        phi_587_ = (mix(mix(_e45.xyz, _e42.xyz, vec3(sqrt(clamp(_e36.y, 0f, 1f)))), _e48.xyz, vec3(_e61)) + (((_e55 * (_e57.w * ((0.25f * _e71) + (((_e72 * _e72) * _e72) * _e72)))) + (_e55 * (_e57.z * smoothstep(_e57.x, _e57.y, _e68)))) * (1f - _e61)));
    }
    let _e129 = phi_587_;
    let _e132 = global.member_1[1u];
    let _e133 = (_e129 * _e132);
    let _e136 = global.member_2[1u];
    phi_588_ = _e133;
    if (_e136 > 0.5f) {
        phi_588_ = (_e133 / (vec3<f32>(1f, 1f, 1f) + _e133));
    }
    let _e141 = phi_588_;
    global_4 = vec4<f32>(_e141.x, _e141.y, _e141.z, 1f);
    let _e147 = global_5.member_2;
    let _e151 = vec4<f32>(_e36.x, _e36.y, _e36.z, 0f);
    let _e152 = (_e147 * _e151);
    let _e154 = global_5.member_3;
    let _e155 = (_e154 * _e151);
    let _e157 = (_e155.w <= 0f);
    phi_341_ = _e157;
    if !(_e157) {
        phi_341_ = (_e152.w <= 0f);
    }
    let _e162 = phi_341_;
    if _e162 {
        phi_589_ = vec2<f32>(0f, 0f);
    } else {
        phi_589_ = (((_e155.xy / vec2(_e155.w)) - (_e152.xy / vec2(_e152.w))) * vec2<f32>(0.5f, -0.5f));
    }
    let _e173 = phi_589_;
    global_6 = _e173;
    return;
}

@fragment 
fn main(@location(0) param: vec4<f32>) -> FragmentOutput {
    global_1 = param;
    function_();
    let _e4 = global_4;
    let _e5 = global_6;
    return FragmentOutput(_e4, _e5);
}
