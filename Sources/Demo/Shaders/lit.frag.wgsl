// Generated from lit.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 2ebfa28bda9a2685
// glsl-fnv1a64: 87ae7a3e10624e75

diagnostic(off, derivative_uniformity);

struct type_11 {
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

var<private> global: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_1: type_11;
@group(1) @binding(1) 
var global_2: sampler_comparison;
@group(1) @binding(0) 
var global_3: texture_depth_2d;
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
    var phi_687_: vec3<f32>;
    var phi_678_: f32;
    var phi_675_: i32;
    var phi_684_: f32;
    var phi_681_: i32;
    var local_2: f32;
    var phi_685_: f32;
    var phi_691_: vec2<f32>;
    var local_3: f32;

    let _e54 = global_4;
    let _e55 = normalize(_e54);
    let _e57 = global_1.member_2;
    let _e59 = normalize(_e57.xyz);
    let _e61 = global_1.member_3;
    let _e63 = global_5;
    let _e64 = (_e61.xyz - _e63);
    let _e68 = global_6;
    let _e69 = _e68.xyz;
    let _e71 = global_7[0u];
    phi_687_ = _e69;
    if (_e71 > 0.5f) {
        let _e75 = floor((_e63.xz * vec2<f32>(0.5f, 0.5f)));
        let _e79 = abs((_e75.x + _e75.y));
        phi_687_ = (_e69 * select(0.75f, 1f, ((_e79 - (floor((_e79 / 2f)) * 2f)) < 0.5f)));
    }
    let _e88 = phi_687_;
    switch bitcast<i32>(0u) {
        default: {
            let _e90 = global;
            let _e93 = global[3u];
            let _e95 = (_e90.xyz / vec3(_e93));
            let _e98 = ((_e95.x * 0.5f) + 0.5f);
            let _e101 = (0.5f - (_e95.y * 0.5f));
            let _e107 = global_1.member_5[1u];
            let _e108 = (min(_e95.z, 1f) - _e107);
            let _e111 = global_1.member_5[0u];
            let _e114 = global_1.member_5[2u];
            let _e115 = i32(_e114);
            if (_e115 <= 0i) {
                let _e119 = textureSampleCompare(global_3, global_2, vec3<f32>(_e98, _e101, _e108).xy, _e108);
                phi_685_ = _e119;
                break;
            }
            let _e122 = ((vec2<f32>(_e98, _e101) / vec2(_e111)) + vec2<f32>(0.5f, 0.5f));
            let _e123 = floor(_e122);
            let _e124 = (_e122 - _e123);
            let _e127 = (_e115 == 1i);
            if _e127 {
                let _e128 = (_e124 * 2f);
                local[0i] = (vec2<f32>(3f, 3f) - _e128);
                local[1i] = (vec2<f32>(1f, 1f) + _e128);
                let _e134 = local[0i];
                local_1[0i] = (((vec2<f32>(2f, 2f) - _e124) / _e134) - vec2<f32>(1f, 1f));
                let _e138 = local[1i];
                local_1[1i] = ((_e124 / _e138) + vec2<f32>(1f, 1f));
            } else {
                let _e142 = (_e124 * 3f);
                local[0i] = (vec2<f32>(4f, 4f) - _e142);
                local[1i] = vec2<f32>(7f, 7f);
                local[2i] = (vec2<f32>(1f, 1f) + _e142);
                let _e150 = local[0i];
                local_1[0i] = (((vec2<f32>(3f, 3f) - (_e124 * 2f)) / _e150) - vec2<f32>(2f, 2f));
                let _e155 = local[1i];
                local_1[1i] = ((vec2<f32>(3f, 3f) + _e124) / _e155);
                let _e158 = local[2i];
                local_1[2i] = ((_e124 / _e158) + vec2<f32>(2f, 2f));
            }
            let _e163 = select(3i, 2i, _e127);
            phi_678_ = 0f;
            phi_675_ = 0i;
            loop {
                let _e165 = phi_678_;
                let _e167 = phi_675_;
                local_2 = _e165;
                if (_e167 < _e163) {
                    phi_684_ = _e165;
                    phi_681_ = 0i;
                    loop {
                        let _e170 = phi_684_;
                        let _e172 = phi_681_;
                        local_3 = _e170;
                        if (_e172 < _e163) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e176 = local[_e172][0u];
                            let _e179 = local[_e167][1u];
                            let _e183 = local_1[_e172][0u];
                            let _e186 = local_1[_e167][1u];
                            let _e189 = (((_e123 - vec2<f32>(0.5f, 0.5f)) * _e111) + (vec2<f32>(_e183, _e186) * _e111));
                            let _e194 = textureSampleCompare(global_3, global_2, vec3<f32>(_e189.x, _e189.y, _e108).xy, _e108);
                            phi_684_ = (_e170 + ((_e176 * _e179) * _e194));
                            phi_681_ = (_e172 + 1i);
                        }
                    }
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e271 = local_3;
                    phi_678_ = _e271;
                    phi_675_ = (_e167 + 1i);
                }
            }
            let _e200 = local_2;
            phi_685_ = (_e200 * select(0.0069444445f, 0.0625f, _e127));
            break;
        }
    }
    let _e203 = phi_685_;
    let _e204 = dot(_e55, _e59);
    let _e208 = global_1.member_2[3u];
    let _e230 = global_7[1u];
    let _e237 = global_1.member_4[3u];
    let _e242 = global_1.member_4;
    let _e245 = mix(mix(((_e88 * ((mix(vec3<f32>(0.12f, 0.1f, 0.09f), vec3<f32>(0.55f, 0.65f, 0.85f), vec3(((_e55.y * 0.5f) + 0.5f))) * 0.3f) + vec3(((max(_e204, 0f) * _e208) * _e203)))) + vec3((((pow(max(dot(_e55, normalize((_e59 + normalize(_e64)))), 0f), 48f) * 0.35f) * step(0f, _e204)) * _e203))), _e88, vec3(_e230)), _e242.xyz, vec3((1f - exp((-(length(_e64)) * _e237)))));
    let _e247 = global_6[3u];
    global_8 = vec4<f32>(_e245.x, _e245.y, _e245.z, _e247);
    let _e252 = global_10;
    let _e253 = global_11;
    switch bitcast<i32>(0u) {
        default: {
            if (_e253.w <= 0f) {
                phi_691_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_691_ = (((_e253.xy / vec2(_e253.w)) - (_e252.xy / vec2(_e252.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e267 = phi_691_;
    global_9 = _e267;
    return;
}

@fragment 
fn main(@location(3) param: vec4<f32>, @location(1) param_1: vec3<f32>, @location(0) param_2: vec3<f32>, @location(2) param_3: vec4<f32>, @location(4) param_4: vec4<f32>, @location(5) param_5: vec4<f32>, @location(6) param_6: vec4<f32>) -> FragmentOutput {
    global = param;
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
