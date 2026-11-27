// Generated from mesh_fur_depth_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 4d5220664c4791d5
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
    var phi_1074_: vec4<f32>;
    var phi_1073_: vec4<f32>;
    var phi_1072_: vec4<f32>;
    var phi_1071_: i32;
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var local_2: vec4<f32>;
    var phi_1076_: vec3<f32>;
    var phi_1075_: i32;
    var local_3: vec3<f32>;
    var phi_1077_: vec3<f32>;
    var phi_1078_: vec3<f32>;
    var local_4: bool;
    var phi_1079_: f32;
    var local_5: bool;
    var phi_1080_: f32;
    var local_6: bool;
    var local_7: bool;
    var phi_623_: bool;
    var local_8: vec3<f32>;
    var local_9: vec3<f32>;

    let _e63 = global_8;
    let _e64 = global_9;
    let _e65 = global_10;
    let _e66 = global_11;
    phi_1074_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1073_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1072_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1071_ = 0i;
    loop {
        let _e69 = phi_1074_;
        let _e71 = phi_1073_;
        let _e73 = phi_1072_;
        let _e75 = phi_1071_;
        local = _e73;
        local_1 = _e71;
        local_2 = _e69;
        if (_e75 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e78 = global[_e75];
            let _e80 = (i32(_e78) * 3i);
            let _e83 = global_1.member_3[_e80];
            let _e85 = global_2[_e75];
            let _e91 = global_1.member_3[(_e80 + 1i)];
            let _e97 = global_1.member_3[(_e80 + 2i)];
            phi_1074_ = (_e69 + (_e97 * _e85));
            phi_1073_ = (_e71 + (_e91 * _e85));
            phi_1072_ = (_e73 + (_e83 * _e85));
            phi_1071_ = (_e75 + 1i);
        }
    }
    let _e102 = local;
    let _e104 = local_1;
    let _e106 = local_2;
    let _e109 = (mat4x4<f32>(_e63, _e64, _e65, _e66) * transpose(mat4x4<f32>(_e102, _e104, _e106, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e113 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e115 = global_3;
            let _e121 = (_e109 * vec4<f32>(_e115.x, _e115.y, _e115.z, 1f)).xyz;
            let _e123 = _e109[0].xyz;
            let _e125 = _e109[1].xyz;
            let _e127 = _e109[2].xyz;
            let _e130 = cross(_e123, _e125);
            let _e135 = global_4;
            let _e138 = normalize(((mat3x3<f32>(cross(_e125, _e127), cross(_e127, _e123), _e130) * _e135) * select(1f, -1f, (dot(_e130, _e127) < 0f))));
            let _e142 = global_1.member_1[2i][0u];
            let _e146 = global_1.member_1[3i][3u];
            let _e147 = (_e146 > 0.5f);
            let _e152 = global_1.member_1[5i];
            let _e154 = _e109[3].xz;
            let _e159 = ((dot(_e154, _e152.xy) * 0.35f) + (dot(_e154, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e173 = global_1.member_1[5i][3u];
            let _e179 = (dot(_e109[3].xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e196 = global_1.member_1[5i][2u];
            phi_1076_ = vec3<f32>(0f, 0f, 0f);
            phi_1075_ = 0i;
            local_4 = _e147;
            local_5 = _e147;
            local_6 = _e147;
            local_7 = _e147;
            local_8 = _e115;
            local_9 = _e135;
            loop {
                let _e202 = phi_1076_;
                let _e204 = phi_1075_;
                local_3 = _e202;
                if (_e204 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e207 = global[_e204];
                    let _e211 = global_1.member_2[i32(_e207)];
                    let _e214 = global_2[_e204];
                    phi_1076_ = (_e202 + (_e211.xyz * _e214));
                    phi_1075_ = (_e204 + 1i);
                }
            }
            let _e221 = global_1.member_1[0i][0u];
            let _e225 = local_3;
            let _e228 = (((vec3<f32>(_e152.x, 0f, _e152.y) * (((_e196 * (1f + (_e173 * (((0.5f + ((0.5f * sin(((_e113 * 0.61f) + _e159))) * sin(((_e113 * 0.23f) + (_e159 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e113 * 4.7f) + _e179))) * sin(((_e113 * 2.9f) + (_e179 * 0.37f)))))) * 0.35f)) + (_e225 / vec3(max(_e221, 0.001f)))) * _e142);
            if _e147 {
                let _e230 = global_5[1u];
                phi_1078_ = (_e121 + (_e228 * ((_e221 * _e230) * _e230)));
                break;
            }
            let _e236 = global_7[1u];
            let _e238 = global_6[3u];
            let _e241 = (_e221 * max((_e238 - 1f), 0f));
            if (_e236 <= 0f) {
                phi_1078_ = (_e121 + (_e138 * ((_e241 * 0.04f) + 0.0004f)));
                break;
            }
            let _e260 = global_6;
            let _e262 = (mat3x3<f32>(vec3<f32>(_e109[0].x, _e109[0].y, _e109[0].z), vec3<f32>(_e109[1].x, _e109[1].y, _e109[1].z), vec3<f32>(_e109[2].x, _e109[2].y, _e109[2].z)) * _e260.xyz);
            let _e268 = global_1.member_1[1i][3u];
            let _e279 = (_e241 * _e236);
            let _e280 = (normalize((((_e138 * (1f - min(length(_e262), 1f))) + _e262) + ((vec3<f32>(0f, -(_e268), 0f) + _e228) * (0.5f * _e236)))) * _e279);
            let _e281 = dot(_e280, _e138);
            let _e282 = (_e279 * 0.12f);
            phi_1077_ = _e280;
            if (_e281 < _e282) {
                phi_1077_ = (_e280 + (_e138 * (_e282 - _e281)));
            }
            let _e288 = phi_1077_;
            phi_1078_ = (_e121 + _e288);
            break;
        }
    }
    let _e291 = phi_1078_;
    let _e293 = global_12.member;
    global_13.member = (_e293 * vec4<f32>(_e291.x, _e291.y, _e291.z, 1f));
    let _e302 = global_13.member[1u];
    global_13.member[1u] = -(_e302);
    let _e305 = local_4;
    if _e305 {
        let _e307 = global_5[1u];
        phi_1079_ = _e307;
    } else {
        let _e309 = global_7[1u];
        phi_1079_ = _e309;
    }
    let _e311 = phi_1079_;
    let _e313 = local_5;
    if _e313 {
        let _e315 = global_6[3u];
        phi_1080_ = fract(_e315);
    } else {
        phi_1080_ = 0f;
    }
    let _e318 = phi_1080_;
    let _e320 = local_6;
    let _e323 = local_7;
    let _e324 = !(_e323);
    phi_623_ = _e324;
    if _e324 {
        let _e326 = global_7[1u];
        phi_623_ = (_e326 <= 0f);
    }
    let _e329 = phi_623_;
    global_14 = vec4<f32>(_e311, _e318, select(0f, 1f, _e320), select(0f, 1f, _e329));
    let _e332 = global_5;
    global_15 = _e332;
    let _e334 = local_8;
    global_16 = _e334;
    let _e336 = local_9;
    global_17 = _e336;
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
