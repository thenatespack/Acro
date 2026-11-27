// Generated from lit.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: b3b642b378acd82f
// glsl-fnv1a64: d682e5fe29f57afc

diagnostic(off, derivative_uniformity);

struct type_14 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
}

struct FragmentOutput {
    @location(0) member: vec4<f32>,
    @location(1) member_1: vec2<f32>,
}

@group(1) @binding(1) 
var global: sampler_comparison;
@group(1) @binding(0) 
var global_1: texture_depth_2d;
var<private> global_2: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_3: type_14;
var<private> global_4: vec3<f32>;
var<private> global_5: vec3<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec2<f32>;
var<private> global_10: vec4<f32>;
var<private> global_11: vec4<f32>;

fn function_() {
    var local: array<vec2<f32>, 3>;
    var local_1: array<vec2<f32>, 3>;
    var phi_772_: vec3<f32>;
    var phi_677_: bool;
    var phi_767_: f32;
    var phi_755_: f32;
    var phi_752_: i32;
    var phi_764_: f32;
    var phi_758_: i32;
    var phi_704_: bool;
    var phi_761_: f32;
    var local_2: f32;
    var phi_768_: f32;
    var phi_778_: vec2<f32>;
    var local_3: f32;
    var local_4: f32;

    let _e54 = global_4;
    let _e55 = normalize(_e54);
    let _e57 = global_3.member_2;
    let _e59 = normalize(_e57.xyz);
    let _e61 = global_3.member_3;
    let _e63 = global_5;
    let _e64 = (_e61.xyz - _e63);
    let _e68 = global_6;
    let _e69 = _e68.xyz;
    let _e71 = global_7[0u];
    phi_772_ = _e69;
    if (_e71 > 0.5f) {
        let _e75 = floor((_e63.xz * vec2<f32>(0.5f, 0.5f)));
        let _e79 = abs((_e75.x + _e75.y));
        phi_772_ = (_e69 * select(0.75f, 1f, ((_e79 - (floor((_e79 / 2f)) * 2f)) < 0.5f)));
    }
    let _e88 = phi_772_;
    switch bitcast<i32>(0u) {
        default: {
            let _e90 = global_2;
            let _e93 = global_2[3u];
            let _e95 = (_e90.xyz / vec3(_e93));
            let _e98 = ((_e95.x * 0.5f) + 0.5f);
            let _e101 = (0.5f - (_e95.y * 0.5f));
            let _e102 = vec2<f32>(_e98, _e101);
            let _e107 = global_3.member_5[1u];
            let _e108 = (min(_e95.z, 1f) - _e107);
            let _e111 = global_3.member_5[0u];
            let _e114 = global_3.member_5[2u];
            let _e115 = i32(_e114);
            if (_e115 <= 0i) {
                switch bitcast<i32>(0u) {
                    default: {
                        let _e119 = any((_e102 < vec2<f32>(0f, 0f)));
                        phi_677_ = _e119;
                        if !(_e119) {
                            phi_677_ = any((_e102 > vec2<f32>(1f, 1f)));
                        }
                        let _e124 = phi_677_;
                        if _e124 {
                            phi_767_ = 1f;
                            break;
                        }
                        let _e127 = textureSampleCompare(global_1, global, vec3<f32>(_e98, _e101, _e108).xy, _e108);
                        phi_767_ = _e127;
                        break;
                    }
                }
                let _e129 = phi_767_;
                phi_768_ = _e129;
                break;
            }
            let _e132 = ((_e102 / vec2(_e111)) + vec2<f32>(0.5f, 0.5f));
            let _e133 = floor(_e132);
            let _e134 = (_e132 - _e133);
            let _e137 = (_e115 == 1i);
            if _e137 {
                let _e138 = (_e134 * 2f);
                local[0i] = (vec2<f32>(3f, 3f) - _e138);
                local[1i] = (vec2<f32>(1f, 1f) + _e138);
                let _e144 = local[0i];
                local_1[0i] = (((vec2<f32>(2f, 2f) - _e134) / _e144) - vec2<f32>(1f, 1f));
                let _e148 = local[1i];
                local_1[1i] = ((_e134 / _e148) + vec2<f32>(1f, 1f));
            } else {
                let _e152 = (_e134 * 3f);
                local[0i] = (vec2<f32>(4f, 4f) - _e152);
                local[1i] = vec2<f32>(7f, 7f);
                local[2i] = (vec2<f32>(1f, 1f) + _e152);
                let _e160 = local[0i];
                local_1[0i] = (((vec2<f32>(3f, 3f) - (_e134 * 2f)) / _e160) - vec2<f32>(2f, 2f));
                let _e165 = local[1i];
                local_1[1i] = ((vec2<f32>(3f, 3f) + _e134) / _e165);
                let _e168 = local[2i];
                local_1[2i] = ((_e134 / _e168) + vec2<f32>(2f, 2f));
            }
            let _e173 = select(3i, 2i, _e137);
            phi_755_ = 0f;
            phi_752_ = 0i;
            loop {
                let _e175 = phi_755_;
                let _e177 = phi_752_;
                local_2 = _e175;
                if (_e177 < _e173) {
                    phi_764_ = _e175;
                    phi_758_ = 0i;
                    loop {
                        let _e180 = phi_764_;
                        let _e182 = phi_758_;
                        local_3 = _e180;
                        if (_e182 < _e173) {
                            let _e186 = local[_e182][0u];
                            let _e189 = local[_e177][1u];
                            let _e193 = local_1[_e182][0u];
                            let _e196 = local_1[_e177][1u];
                            let _e199 = (((_e133 - vec2<f32>(0.5f, 0.5f)) * _e111) + (vec2<f32>(_e193, _e196) * _e111));
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e202 = any((_e199 < vec2<f32>(0f, 0f)));
                                    phi_704_ = _e202;
                                    if !(_e202) {
                                        phi_704_ = any((_e199 > vec2<f32>(1f, 1f)));
                                    }
                                    let _e207 = phi_704_;
                                    if _e207 {
                                        phi_761_ = 1f;
                                        break;
                                    }
                                    let _e212 = textureSampleCompare(global_1, global, vec3<f32>(_e199.x, _e199.y, _e108).xy, _e108);
                                    phi_761_ = _e212;
                                    break;
                                }
                            }
                            let _e214 = phi_761_;
                            local_4 = (_e180 + ((_e186 * _e189) * _e214));
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e297 = local_4;
                            phi_764_ = _e297;
                            phi_758_ = (_e182 + 1i);
                        }
                    }
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e293 = local_3;
                    phi_755_ = _e293;
                    phi_752_ = (_e177 + 1i);
                }
            }
            let _e220 = local_2;
            phi_768_ = (_e220 * select(0.0069444445f, 0.0625f, _e137));
            break;
        }
    }
    let _e223 = phi_768_;
    let _e224 = dot(_e55, _e59);
    let _e228 = global_3.member_2[3u];
    let _e250 = global_7[1u];
    let _e257 = global_3.member_4[3u];
    let _e262 = global_3.member_4;
    let _e265 = mix(mix(((_e88 * ((mix(vec3<f32>(0.12f, 0.1f, 0.09f), vec3<f32>(0.55f, 0.65f, 0.85f), vec3(((_e55.y * 0.5f) + 0.5f))) * 0.3f) + vec3(((max(_e224, 0f) * _e228) * _e223)))) + vec3((((pow(max(dot(_e55, normalize((_e59 + normalize(_e64)))), 0f), 48f) * 0.35f) * step(0f, _e224)) * _e223))), _e88, vec3(_e250)), _e262.xyz, vec3((1f - exp((-(length(_e64)) * _e257)))));
    let _e267 = global_6[3u];
    global_8 = vec4<f32>(_e265.x, _e265.y, _e265.z, _e267);
    let _e272 = global_10;
    let _e273 = global_11;
    switch bitcast<i32>(0u) {
        default: {
            if (_e273.w <= 0f) {
                phi_778_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_778_ = (((_e273.xy / vec2(_e273.w)) - (_e272.xy / vec2(_e272.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e287 = phi_778_;
    global_9 = _e287;
    return;
}

@fragment 
fn main(@location(3) param: vec4<f32>, @location(1) param_1: vec3<f32>, @location(0) param_2: vec3<f32>, @location(2) param_3: vec4<f32>, @location(4) param_4: vec4<f32>, @location(5) param_5: vec4<f32>, @location(6) param_6: vec4<f32>) -> FragmentOutput {
    global_2 = param;
    global_4 = param_1;
    global_5 = param_2;
    global_6 = param_3;
    global_7 = param_4;
    global_10 = param_5;
    global_11 = param_6;
    function_();
    let _e16 = global_8;
    let _e17 = global_9;
    return FragmentOutput(_e16, _e17);
}
