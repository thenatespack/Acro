// Generated from mesh_fur_depth_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 80119e685d2b8a7b
// glsl-fnv1a64: ba2babc36f09d628

diagnostic(off, derivative_uniformity);

struct type_12 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 8>,
    member_2: array<vec4<f32>, 128>,
    member_3: array<vec4<f32>, 384>,
    member_4: array<vec4<f32>, 384>,
}

struct type_20 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
}

struct type_24 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(8) member_1: vec4<f32>,
    @location(2) member_2: vec2<f32>,
    @location(4) member_3: vec3<f32>,
    @location(10) member_4: vec3<f32>,
}

var<private> global: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_1: type_12;
var<private> global_2: vec4<f32>;
var<private> global_3: vec3<f32>;
var<private> global_4: vec3<f32>;
var<private> global_5: vec2<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec4<f32>;
var<private> global_11: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_12: type_20;
var<private> global_13: type_24 = type_24(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_14: vec4<f32>;
var<private> global_15: vec2<f32>;
var<private> global_16: vec3<f32>;
var<private> global_17: vec3<f32>;

fn function_() {
    var phi_1122_: vec4<f32>;
    var phi_1121_: vec4<f32>;
    var phi_1120_: vec4<f32>;
    var phi_1119_: i32;
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var local_2: vec4<f32>;
    var phi_1124_: vec3<f32>;
    var phi_1123_: i32;
    var local_3: vec3<f32>;
    var phi_1125_: f32;
    var phi_1126_: vec3<f32>;
    var phi_1127_: vec3<f32>;
    var local_4: bool;
    var phi_618_: bool;
    var local_5: bool;
    var phi_1128_: f32;
    var local_6: bool;
    var phi_1129_: f32;
    var local_7: bool;
    var phi_1130_: f32;
    var phi_656_: bool;
    var local_8: vec3<f32>;
    var local_9: vec3<f32>;

    let _e65 = global_8;
    let _e66 = global_9;
    let _e67 = global_10;
    let _e68 = global_11;
    phi_1122_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1121_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1120_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1119_ = 0i;
    loop {
        let _e71 = phi_1122_;
        let _e73 = phi_1121_;
        let _e75 = phi_1120_;
        let _e77 = phi_1119_;
        local = _e75;
        local_1 = _e73;
        local_2 = _e71;
        if (_e77 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e80 = global[_e77];
            let _e82 = (i32(_e80) * 3i);
            let _e85 = global_1.member_3[_e82];
            let _e87 = global_2[_e77];
            let _e93 = global_1.member_3[(_e82 + 1i)];
            let _e99 = global_1.member_3[(_e82 + 2i)];
            phi_1122_ = (_e71 + (_e99 * _e87));
            phi_1121_ = (_e73 + (_e93 * _e87));
            phi_1120_ = (_e75 + (_e85 * _e87));
            phi_1119_ = (_e77 + 1i);
        }
    }
    let _e104 = local;
    let _e106 = local_1;
    let _e108 = local_2;
    let _e111 = (mat4x4<f32>(_e65, _e66, _e67, _e68) * transpose(mat4x4<f32>(_e104, _e106, _e108, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e115 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e117 = global_3;
            let _e123 = (_e111 * vec4<f32>(_e117.x, _e117.y, _e117.z, 1f)).xyz;
            let _e125 = _e111[0].xyz;
            let _e127 = _e111[1].xyz;
            let _e129 = _e111[2].xyz;
            let _e132 = cross(_e125, _e127);
            let _e137 = global_4;
            let _e140 = normalize(((mat3x3<f32>(cross(_e127, _e129), cross(_e129, _e125), _e132) * _e137) * select(1f, -1f, (dot(_e132, _e129) < 0f))));
            let _e144 = global_1.member_1[2i][0u];
            let _e148 = global_1.member_1[3i][3u];
            let _e149 = (_e148 > 0.5f);
            let _e154 = global_1.member_1[5i];
            let _e156 = _e111[3].xz;
            let _e161 = ((dot(_e156, _e154.xy) * 0.35f) + (dot(_e156, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e175 = global_1.member_1[5i][3u];
            let _e181 = (dot(_e111[3].xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e198 = global_1.member_1[5i][2u];
            phi_1124_ = vec3<f32>(0f, 0f, 0f);
            phi_1123_ = 0i;
            local_4 = _e149;
            local_5 = _e149;
            local_6 = _e149;
            local_7 = _e149;
            local_8 = _e117;
            local_9 = _e137;
            loop {
                let _e204 = phi_1124_;
                let _e206 = phi_1123_;
                local_3 = _e204;
                if (_e206 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e209 = global[_e206];
                    let _e213 = global_1.member_2[i32(_e209)];
                    let _e216 = global_2[_e206];
                    phi_1124_ = (_e204 + (_e213.xyz * _e216));
                    phi_1123_ = (_e206 + 1i);
                }
            }
            let _e223 = global_1.member_1[0i][0u];
            let _e227 = local_3;
            let _e230 = (((vec3<f32>(_e154.x, 0f, _e154.y) * (((_e198 * (1f + (_e175 * (((0.5f + ((0.5f * sin(((_e115 * 0.61f) + _e161))) * sin(((_e115 * 0.23f) + (_e161 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e115 * 4.7f) + _e181))) * sin(((_e115 * 2.9f) + (_e181 * 0.37f)))))) * 0.35f)) + (_e227 / vec3(max(_e223, 0.001f)))) * _e144);
            if _e149 {
                let _e232 = global_5[1u];
                phi_1127_ = (_e123 + (_e230 * ((_e223 * _e232) * _e232)));
                break;
            }
            let _e238 = global_7[1u];
            let _e239 = (_e238 > 1.5f);
            if _e239 {
                let _e241 = global_5[1u];
                phi_1125_ = _e241;
            } else {
                phi_1125_ = _e238;
            }
            let _e243 = phi_1125_;
            let _e245 = global_6[3u];
            let _e248 = (_e223 * max((_e245 - 1f), 0f));
            if ((_e243 <= 0f) && !(_e239)) {
                phi_1127_ = (_e123 + (_e140 * ((_e248 * 0.04f) + 0.0004f)));
                break;
            }
            let _e269 = global_6;
            let _e271 = (mat3x3<f32>(vec3<f32>(_e111[0].x, _e111[0].y, _e111[0].z), vec3<f32>(_e111[1].x, _e111[1].y, _e111[1].z), vec3<f32>(_e111[2].x, _e111[2].y, _e111[2].z)) * _e269.xyz);
            let _e277 = global_1.member_1[1i][3u];
            let _e288 = (_e248 * _e243);
            let _e289 = (normalize((((_e140 * (1f - min(length(_e271), 1f))) + _e271) + ((vec3<f32>(0f, -(_e277), 0f) + _e230) * (0.5f * _e243)))) * _e288);
            let _e290 = dot(_e289, _e140);
            let _e291 = (_e288 * 0.12f);
            phi_1126_ = _e289;
            if (_e290 < _e291) {
                phi_1126_ = (_e289 + (_e140 * (_e291 - _e290)));
            }
            let _e297 = phi_1126_;
            phi_1127_ = (_e123 + _e297);
            break;
        }
    }
    let _e300 = phi_1127_;
    let _e302 = global_12.member;
    global_13.member = (_e302 * vec4<f32>(_e300.x, _e300.y, _e300.z, 1f));
    let _e311 = global_13.member[1u];
    global_13.member[1u] = -(_e311);
    let _e314 = local_4;
    let _e315 = !(_e314);
    phi_618_ = _e315;
    if _e315 {
        let _e317 = global_7[1u];
        phi_618_ = (_e317 > 1.5f);
    }
    let _e320 = phi_618_;
    let _e322 = local_5;
    if (_e322 || _e320) {
        let _e325 = global_5[1u];
        phi_1128_ = _e325;
    } else {
        let _e327 = global_7[1u];
        phi_1128_ = _e327;
    }
    let _e329 = phi_1128_;
    let _e331 = local_6;
    if _e331 {
        let _e333 = global_6[3u];
        phi_1129_ = fract(_e333);
    } else {
        phi_1129_ = 0f;
    }
    let _e336 = phi_1129_;
    let _e338 = local_7;
    if _e338 {
        phi_1130_ = 1f;
    } else {
        phi_1130_ = select(0f, 2f, _e320);
    }
    let _e341 = phi_1130_;
    phi_656_ = _e315;
    if _e315 {
        let _e343 = global_7[1u];
        phi_656_ = (_e343 <= 0f);
    }
    let _e346 = phi_656_;
    global_14 = vec4<f32>(_e329, _e336, _e341, select(0f, 1f, _e346));
    let _e349 = global_5;
    global_15 = _e349;
    let _e351 = local_8;
    global_16 = _e351;
    let _e353 = local_9;
    global_17 = _e353;
    return;
}

@vertex 
fn main(@location(14) param: vec4<f32>, @location(15) param_1: vec4<f32>, @location(0) param_2: vec3<f32>, @location(1) param_3: vec3<f32>, @location(2) param_4: vec2<f32>, @location(13) param_5: vec4<f32>, @location(12) param_6: vec4<f32>, @location(3) param_7: vec4<f32>, @location(4) param_8: vec4<f32>, @location(5) param_9: vec4<f32>, @location(6) param_10: vec4<f32>) -> VertexOutput {
    global = param;
    global_2 = param_1;
    global_3 = param_2;
    global_4 = param_3;
    global_5 = param_4;
    global_6 = param_5;
    global_7 = param_6;
    global_8 = param_7;
    global_9 = param_8;
    global_10 = param_9;
    global_11 = param_10;
    function_();
    let _e29 = global_13.member.y;
    global_13.member.y = -(_e29);
    let _e31 = global_13.member;
    let _e32 = global_14;
    let _e33 = global_15;
    let _e34 = global_16;
    let _e35 = global_17;
    return VertexOutput(_e31, _e32, _e33, _e34, _e35);
}
