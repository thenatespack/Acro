// Generated from probe_debug.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 224e407e02a0917a
// glsl-fnv1a64: 03a6f22025cdef19

diagnostic(off, derivative_uniformity);

struct type_13 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
    member_9: vec4<f32>,
    member_10: vec4<f32>,
    member_11: vec4<f32>,
    member_12: vec4<f32>,
    member_13: vec4<f32>,
    member_14: array<mat4x4<f32>, 4>,
    member_15: array<mat4x4<f32>, 8>,
    member_16: vec4<f32>,
    member_17: vec4<f32>,
    member_18: vec4<f32>,
    member_19: vec4<f32>,
    member_20: vec4<f32>,
    member_21: vec4<f32>,
    member_22: vec4<f32>,
    member_23: vec4<f32>,
    member_24: vec4<f32>,
    member_25: vec4<f32>,
    member_26: array<vec4<f32>, 8>,
    member_27: array<vec4<f32>, 4>,
    member_28: array<vec4<f32>, 4>,
    member_29: vec4<f32>,
    member_30: mat4x4<f32>,
    member_31: vec4<f32>,
    member_32: vec4<f32>,
    member_33: vec4<f32>,
    member_34: vec4<f32>,
}

struct type_18 {
    member: array<vec4<u32>>,
}

struct FragmentOutput {
    @location(0) member: vec4<f32>,
    @location(1) member_1: vec2<f32>,
}

@group(0) @binding(0) 
var<uniform> global: type_13;
@group(2) @binding(25) 
var<storage> global_1: type_18;
var<private> global_2: vec3<f32>;
var<private> global_3: vec3<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec2<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;

fn function_() {
    var phi_4796_: i32;
    var phi_4797_: i32;
    var phi_4803_: vec2<u32>;
    var phi_4805_: vec2<u32>;
    var phi_4808_: vec2<u32>;
    var phi_4809_: vec2<u32>;
    var phi_4795_: vec3<f32>;
    var phi_4824_: vec3<f32>;
    var phi_4825_: vec2<f32>;

    let _e43 = global_2;
    let _e44 = normalize(_e43);
    let _e46 = global.member_6;
    let _e48 = global_3;
    let _e52 = global_4[0u];
    if (_e52 < 0.5f) {
        let _e55 = global_4[1u];
        let _e57 = i32((_e55 + 0.5f));
        let _e62 = global_1.member[(_e57 + 6i)][0u];
        let _e63 = bitcast<i32>(_e62);
        let _e65 = reflect(-(normalize((_e46.xyz - _e48))), _e44);
        let _e68 = global_1.member[_e57];
        let _e75 = global_1.member[(_e57 + 1i)];
        let _e82 = global_1.member[(_e57 + 2i)];
        let _e95 = ((vec2<f32>(((atan2(dot(bitcast<vec4<f32>>(_e68).xyz, _e65), -(dot(bitcast<vec4<f32>>(_e82).xyz, _e65))) * 0.15915494f) + 0.5f), (acos(clamp(dot(bitcast<vec4<f32>>(_e75).xyz, _e65), -1f, 1f)) * 0.31830987f)) * vec2<f32>(256f, 128f)) - vec2<f32>(0.5f, 0.5f));
        let _e96 = floor(_e95);
        let _e97 = (_e95 - _e96);
        let _e99 = i32(_e96.x);
        let _e101 = i32(_e96.y);
        phi_4796_ = _e99;
        if (_e99 < 0i) {
            phi_4796_ = (_e99 + 256i);
        }
        let _e105 = phi_4796_;
        phi_4797_ = _e105;
        if (_e105 >= 256i) {
            phi_4797_ = (_e105 - 256i);
        }
        let _e109 = phi_4797_;
        let _e110 = (_e109 + 1i);
        let _e112 = select(_e110, 0i, (_e110 == 256i));
        let _e117 = (_e63 + (max(_e101, 0i) * 256i));
        let _e118 = (_e117 + _e109);
        let _e123 = global_1.member[(_e118 >> bitcast<u32>(1i))];
        if ((_e118 & 1i) == 0i) {
            phi_4803_ = _e123.xy;
        } else {
            phi_4803_ = _e123.zw;
        }
        let _e129 = phi_4803_;
        let _e131 = unpack2x16float(_e129.x);
        let _e138 = (_e117 + _e112);
        let _e143 = global_1.member[(_e138 >> bitcast<u32>(1i))];
        if ((_e138 & 1i) == 0i) {
            phi_4805_ = _e143.xy;
        } else {
            phi_4805_ = _e143.zw;
        }
        let _e149 = phi_4805_;
        let _e151 = unpack2x16float(_e149.x);
        let _e159 = (_e63 + (min((_e101 + 1i), 127i) * 256i));
        let _e160 = (_e159 + _e109);
        let _e165 = global_1.member[(_e160 >> bitcast<u32>(1i))];
        if ((_e160 & 1i) == 0i) {
            phi_4808_ = _e165.xy;
        } else {
            phi_4808_ = _e165.zw;
        }
        let _e171 = phi_4808_;
        let _e173 = unpack2x16float(_e171.x);
        let _e180 = (_e159 + _e112);
        let _e185 = global_1.member[(_e180 >> bitcast<u32>(1i))];
        if ((_e180 & 1i) == 0i) {
            phi_4809_ = _e185.xy;
        } else {
            phi_4809_ = _e185.zw;
        }
        let _e191 = phi_4809_;
        let _e193 = unpack2x16float(_e191.x);
        let _e201 = vec3(_e97.x);
        phi_4824_ = mix(mix(vec3<f32>(_e131.x, _e131.y, unpack2x16float(_e129.y).x), vec3<f32>(_e151.x, _e151.y, unpack2x16float(_e149.y).x), _e201), mix(vec3<f32>(_e173.x, _e173.y, unpack2x16float(_e171.y).x), vec3<f32>(_e193.x, _e193.y, unpack2x16float(_e191.y).x), _e201), vec3(_e97.y));
    } else {
        let _e208 = global_4[1u];
        let _e210 = i32((_e208 + 0.5f));
        let _e211 = (_e210 + 3i);
        let _e215 = global_1.member[_e211][1u];
        if (unpack2x16float(_e215).y > 0.5f) {
            let _e220 = global_4[2u];
            let _e222 = i32((_e220 + 0.5f));
            let _e225 = global_1.member[_e222];
            let _e228 = dot(bitcast<vec4<f32>>(_e225).xyz, _e44);
            let _e232 = global_1.member[(_e222 + 1i)];
            let _e235 = dot(bitcast<vec4<f32>>(_e232).xyz, _e44);
            let _e239 = global_1.member[(_e222 + 2i)];
            let _e242 = dot(bitcast<vec4<f32>>(_e239).xyz, _e44);
            let _e246 = (1.092548f * _e228);
            let _e261 = global_1.member[_e210];
            let _e265 = global_1.member[(_e210 + 1i)];
            let _e269 = global_1.member[(_e210 + 2i)];
            let _e272 = global_1.member[_e211];
            let _e274 = unpack2x16float(_e261.x);
            let _e276 = unpack2x16float(_e261.y);
            let _e278 = unpack2x16float(_e261.z);
            let _e280 = unpack2x16float(_e261.w);
            let _e282 = unpack2x16float(_e265.x);
            let _e284 = unpack2x16float(_e265.y);
            let _e286 = unpack2x16float(_e265.z);
            let _e288 = unpack2x16float(_e265.w);
            let _e290 = unpack2x16float(_e269.x);
            let _e292 = unpack2x16float(_e269.y);
            let _e294 = unpack2x16float(_e269.z);
            let _e296 = unpack2x16float(_e269.w);
            let _e298 = unpack2x16float(_e272.x);
            phi_4795_ = max((((((((((vec3<f32>(_e274.x, _e274.y, _e276.x) * 0.282095f) + (vec3<f32>(_e276.y, _e278.x, _e278.y) * (0.488603f * _e235))) + (vec3<f32>(_e280.x, _e280.y, _e282.x) * (0.488603f * _e242))) + (vec3<f32>(_e282.y, _e284.x, _e284.y) * (0.488603f * _e228))) + (vec3<f32>(_e286.x, _e286.y, _e288.x) * (_e246 * _e235))) + (vec3<f32>(_e288.y, _e290.x, _e290.y) * ((1.092548f * _e235) * _e242))) + (vec3<f32>(_e292.x, _e292.y, _e294.x) * (0.315392f * (((3f * _e242) * _e242) - 1f)))) + (vec3<f32>(_e294.y, _e296.x, _e296.y) * (_e246 * _e242))) + (vec3<f32>(_e298.x, _e298.y, unpack2x16float(_e272.y).x) * (0.546274f * ((_e228 * _e228) - (_e235 * _e235))))), vec3<f32>(0f, 0f, 0f));
        } else {
            phi_4795_ = vec3<f32>(0.6f, 0f, 0f);
        }
        let _e356 = phi_4795_;
        phi_4824_ = _e356;
    }
    let _e358 = phi_4824_;
    global_5 = vec4<f32>(_e358.x, _e358.y, _e358.z, 1f);
    let _e363 = global_7;
    let _e364 = global_8;
    switch bitcast<i32>(0u) {
        default: {
            if (_e364.w <= 0f) {
                phi_4825_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_4825_ = (((_e364.xy / vec2(_e364.w)) - (_e363.xy / vec2(_e363.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e378 = phi_4825_;
    global_6 = _e378;
    return;
}

@fragment 
fn main(@location(1) param: vec3<f32>, @location(0) param_1: vec3<f32>, @location(3) param_2: vec4<f32>, @location(6) param_3: vec4<f32>, @location(7) param_4: vec4<f32>) -> FragmentOutput {
    global_2 = param;
    global_3 = param_1;
    global_4 = param_2;
    global_7 = param_3;
    global_8 = param_4;
    function_();
    let _e12 = global_5;
    let _e13 = global_6;
    return FragmentOutput(_e12, _e13);
}
