// Generated from mesh_fur_depth_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 09676756adff21d3
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
var<private> global_5: vec4<f32>;
var<private> global_6: vec2<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec4<f32>;
var<private> global_11: vec4<f32>;
var<private> global_12: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_13: type_20;
var<private> global_14: type_24 = type_24(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_15: vec4<f32>;
var<private> global_16: vec2<f32>;
var<private> global_17: vec3<f32>;
var<private> global_18: vec3<f32>;

fn function_() {
    var phi_1137_: vec4<f32>;
    var phi_1136_: vec4<f32>;
    var phi_1135_: vec4<f32>;
    var phi_1134_: i32;
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var local_2: vec4<f32>;
    var phi_1139_: vec3<f32>;
    var phi_1138_: i32;
    var local_3: vec3<f32>;
    var phi_1140_: f32;
    var phi_1141_: vec3<f32>;
    var phi_1142_: vec3<f32>;
    var local_4: bool;
    var phi_627_: bool;
    var local_5: bool;
    var phi_1143_: f32;
    var local_6: bool;
    var phi_1144_: f32;
    var local_7: bool;
    var phi_1145_: f32;
    var phi_665_: bool;
    var local_8: vec3<f32>;
    var local_9: vec3<f32>;

    let _e67 = global_9;
    let _e68 = global_10;
    let _e69 = global_11;
    let _e70 = global_12;
    phi_1137_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1136_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1135_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1134_ = 0i;
    loop {
        let _e73 = phi_1137_;
        let _e75 = phi_1136_;
        let _e77 = phi_1135_;
        let _e79 = phi_1134_;
        local = _e77;
        local_1 = _e75;
        local_2 = _e73;
        if (_e79 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e82 = global[_e79];
            let _e84 = (i32(_e82) * 3i);
            let _e87 = global_1.member_3[_e84];
            let _e89 = global_2[_e79];
            let _e95 = global_1.member_3[(_e84 + 1i)];
            let _e101 = global_1.member_3[(_e84 + 2i)];
            phi_1137_ = (_e73 + (_e101 * _e89));
            phi_1136_ = (_e75 + (_e95 * _e89));
            phi_1135_ = (_e77 + (_e87 * _e89));
            phi_1134_ = (_e79 + 1i);
        }
    }
    let _e106 = local;
    let _e108 = local_1;
    let _e110 = local_2;
    let _e113 = (mat4x4<f32>(_e67, _e68, _e69, _e70) * transpose(mat4x4<f32>(_e106, _e108, _e110, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e117 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e119 = global_3;
            let _e125 = (_e113 * vec4<f32>(_e119.x, _e119.y, _e119.z, 1f)).xyz;
            let _e127 = _e113[0].xyz;
            let _e129 = _e113[1].xyz;
            let _e131 = _e113[2].xyz;
            let _e134 = cross(_e127, _e129);
            let _e139 = global_4;
            let _e142 = normalize(((mat3x3<f32>(cross(_e129, _e131), cross(_e131, _e127), _e134) * _e139) * select(1f, -1f, (dot(_e134, _e131) < 0f))));
            let _e146 = global_1.member_1[2i][0u];
            let _e150 = global_1.member_1[3i][3u];
            let _e151 = (_e150 > 0.5f);
            let _e153 = global_5[3u];
            let _e160 = global_1.member_1[5i];
            let _e162 = _e113[3].xz;
            let _e167 = ((dot(_e162, _e160.xy) * 0.35f) + (dot(_e162, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e181 = global_1.member_1[5i][3u];
            let _e187 = (dot(_e113[3].xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e204 = global_1.member_1[5i][2u];
            phi_1139_ = vec3<f32>(0f, 0f, 0f);
            phi_1138_ = 0i;
            local_4 = _e151;
            local_5 = _e151;
            local_6 = _e151;
            local_7 = _e151;
            local_8 = _e119;
            local_9 = _e139;
            loop {
                let _e210 = phi_1139_;
                let _e212 = phi_1138_;
                local_3 = _e210;
                if (_e212 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e215 = global[_e212];
                    let _e219 = global_1.member_2[i32(_e215)];
                    let _e222 = global_2[_e212];
                    phi_1139_ = (_e210 + (_e219.xyz * _e222));
                    phi_1138_ = (_e212 + 1i);
                }
            }
            let _e229 = global_1.member_1[0i][0u];
            let _e233 = local_3;
            let _e237 = (((vec3<f32>(_e160.x, 0f, _e160.y) * (((_e204 * (1f + (_e181 * (((0.5f + ((0.5f * sin(((_e117 * 0.61f) + _e167))) * sin(((_e117 * 0.23f) + (_e167 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e117 * 4.7f) + _e187))) * sin(((_e117 * 2.9f) + (_e187 * 0.37f)))))) * 0.35f)) + (_e233 / vec3(max(_e229, 0.001f)))) * (_e146 * select(1f, 0f, (_e153 < -0.5f))));
            if _e151 {
                let _e239 = global_6[1u];
                phi_1142_ = (_e125 + (_e237 * ((_e229 * _e239) * _e239)));
                break;
            }
            let _e245 = global_8[1u];
            let _e246 = (_e245 > 1.5f);
            if _e246 {
                let _e248 = global_6[1u];
                phi_1140_ = _e248;
            } else {
                phi_1140_ = _e245;
            }
            let _e250 = phi_1140_;
            let _e252 = global_7[3u];
            let _e255 = (_e229 * max((_e252 - 1f), 0f));
            if ((_e250 <= 0f) && !(_e246)) {
                phi_1142_ = (_e125 + (_e142 * ((_e255 * 0.04f) + 0.0004f)));
                break;
            }
            let _e276 = global_7;
            let _e278 = (mat3x3<f32>(vec3<f32>(_e113[0].x, _e113[0].y, _e113[0].z), vec3<f32>(_e113[1].x, _e113[1].y, _e113[1].z), vec3<f32>(_e113[2].x, _e113[2].y, _e113[2].z)) * _e276.xyz);
            let _e284 = global_1.member_1[1i][3u];
            let _e295 = (_e255 * _e250);
            let _e296 = (normalize((((_e142 * (1f - min(length(_e278), 1f))) + _e278) + ((vec3<f32>(0f, -(_e284), 0f) + _e237) * (0.5f * _e250)))) * _e295);
            let _e297 = dot(_e296, _e142);
            let _e298 = (_e295 * 0.12f);
            phi_1141_ = _e296;
            if (_e297 < _e298) {
                phi_1141_ = (_e296 + (_e142 * (_e298 - _e297)));
            }
            let _e304 = phi_1141_;
            phi_1142_ = (_e125 + _e304);
            break;
        }
    }
    let _e307 = phi_1142_;
    let _e309 = global_13.member;
    global_14.member = (_e309 * vec4<f32>(_e307.x, _e307.y, _e307.z, 1f));
    let _e318 = global_14.member[1u];
    global_14.member[1u] = -(_e318);
    let _e321 = local_4;
    let _e322 = !(_e321);
    phi_627_ = _e322;
    if _e322 {
        let _e324 = global_8[1u];
        phi_627_ = (_e324 > 1.5f);
    }
    let _e327 = phi_627_;
    let _e329 = local_5;
    if (_e329 || _e327) {
        let _e332 = global_6[1u];
        phi_1143_ = _e332;
    } else {
        let _e334 = global_8[1u];
        phi_1143_ = _e334;
    }
    let _e336 = phi_1143_;
    let _e338 = local_6;
    if _e338 {
        let _e340 = global_7[3u];
        phi_1144_ = fract(_e340);
    } else {
        phi_1144_ = 0f;
    }
    let _e343 = phi_1144_;
    let _e345 = local_7;
    if _e345 {
        phi_1145_ = 1f;
    } else {
        phi_1145_ = select(0f, 2f, _e327);
    }
    let _e348 = phi_1145_;
    phi_665_ = _e322;
    if _e322 {
        let _e350 = global_8[1u];
        phi_665_ = (_e350 <= 0f);
    }
    let _e353 = phi_665_;
    global_15 = vec4<f32>(_e336, _e343, _e348, select(0f, 1f, _e353));
    let _e356 = global_6;
    global_16 = _e356;
    let _e358 = local_8;
    global_17 = _e358;
    let _e360 = local_9;
    global_18 = _e360;
    return;
}

@vertex 
fn main(@location(14) param: vec4<f32>, @location(15) param_1: vec4<f32>, @location(0) param_2: vec3<f32>, @location(1) param_3: vec3<f32>, @location(11) param_4: vec4<f32>, @location(2) param_5: vec2<f32>, @location(13) param_6: vec4<f32>, @location(12) param_7: vec4<f32>, @location(3) param_8: vec4<f32>, @location(4) param_9: vec4<f32>, @location(5) param_10: vec4<f32>, @location(6) param_11: vec4<f32>) -> VertexOutput {
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
    global_12 = param_11;
    function_();
    let _e31 = global_14.member.y;
    global_14.member.y = -(_e31);
    let _e33 = global_14.member;
    let _e34 = global_15;
    let _e35 = global_16;
    let _e36 = global_17;
    let _e37 = global_18;
    return VertexOutput(_e33, _e34, _e35, _e36, _e37);
}
