// Generated from mesh_fur_depth.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 57c0baf8a0e3d4a2
// glsl-fnv1a64: c394983351f825f5

diagnostic(off, derivative_uniformity);

struct type_9 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 8>,
}

struct type_18 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
}

struct type_22 {
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
var<uniform> global_1: type_9;
var<private> global_2: vec3<f32>;
var<private> global_3: vec3<f32>;
var<private> global_4: vec2<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_10: type_18;
var<private> global_11: type_22 = type_22(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_12: vec4<f32>;
var<private> global_13: vec2<f32>;
var<private> global_14: vec3<f32>;
var<private> global_15: vec3<f32>;

fn function_() {
    var phi_911_: f32;
    var phi_912_: vec3<f32>;
    var phi_913_: vec3<f32>;
    var local: bool;
    var phi_505_: bool;
    var local_1: bool;
    var phi_914_: f32;
    var local_2: bool;
    var phi_915_: f32;
    var local_3: bool;
    var phi_916_: f32;
    var phi_543_: bool;
    var local_4: vec3<f32>;
    var local_5: vec3<f32>;

    let _e57 = global_6;
    let _e58 = global_7;
    let _e59 = global_8;
    let _e60 = global_9;
    let _e65 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e67 = global_2;
            let _e73 = (mat4x4<f32>(_e57, _e58, _e59, _e60) * vec4<f32>(_e67.x, _e67.y, _e67.z, 1f)).xyz;
            let _e74 = _e57.xyz;
            let _e75 = _e58.xyz;
            let _e76 = _e59.xyz;
            let _e79 = cross(_e74, _e75);
            let _e84 = global_3;
            let _e87 = normalize(((mat3x3<f32>(cross(_e75, _e76), cross(_e76, _e74), _e79) * _e84) * select(1f, -1f, (dot(_e79, _e76) < 0f))));
            let _e91 = global_1.member_1[2i][0u];
            let _e95 = global_1.member_1[3i][3u];
            let _e96 = (_e95 > 0.5f);
            let _e100 = global_1.member_1[5i];
            let _e102 = _e60.xz;
            let _e107 = ((dot(_e102, _e100.xy) * 0.35f) + (dot(_e102, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e121 = global_1.member_1[5i][3u];
            let _e127 = (dot(_e60.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e144 = global_1.member_1[5i][2u];
            let _e150 = global[2u];
            let _e152 = global[3u];
            let _e157 = global_1.member_1[0i][0u];
            let _e162 = (((vec3<f32>(_e100.x, 0f, _e100.y) * (((_e144 * (1f + (_e121 * (((0.5f + ((0.5f * sin(((_e65 * 0.61f) + _e107))) * sin(((_e65 * 0.23f) + (_e107 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e65 * 4.7f) + _e127))) * sin(((_e65 * 2.9f) + (_e127 * 0.37f)))))) * 0.35f)) + (vec3<f32>(_e150, 0f, _e152) / vec3(max(_e157, 0.001f)))) * _e91);
            local = _e96;
            local_1 = _e96;
            local_2 = _e96;
            local_3 = _e96;
            local_4 = _e67;
            local_5 = _e84;
            if _e96 {
                let _e164 = global_4[1u];
                phi_913_ = (_e73 + (_e162 * ((_e157 * _e164) * _e164)));
                break;
            }
            let _e170 = global[1u];
            let _e171 = (_e170 > 1.5f);
            if _e171 {
                let _e173 = global_4[1u];
                phi_911_ = _e173;
            } else {
                phi_911_ = _e170;
            }
            let _e175 = phi_911_;
            let _e177 = global_5[3u];
            let _e180 = (_e157 * max((_e177 - 1f), 0f));
            if ((_e175 <= 0f) && !(_e171)) {
                phi_913_ = (_e73 + (_e87 * ((_e180 * 0.04f) + 0.0004f)));
                break;
            }
            let _e201 = global_5;
            let _e203 = (mat3x3<f32>(vec3<f32>(_e57.x, _e57.y, _e57.z), vec3<f32>(_e58.x, _e58.y, _e58.z), vec3<f32>(_e59.x, _e59.y, _e59.z)) * _e201.xyz);
            let _e209 = global_1.member_1[1i][3u];
            let _e220 = (_e180 * _e175);
            let _e221 = (normalize((((_e87 * (1f - min(length(_e203), 1f))) + _e203) + ((vec3<f32>(0f, -(_e209), 0f) + _e162) * (0.5f * _e175)))) * _e220);
            let _e222 = dot(_e221, _e87);
            let _e223 = (_e220 * 0.12f);
            phi_912_ = _e221;
            if (_e222 < _e223) {
                phi_912_ = (_e221 + (_e87 * (_e223 - _e222)));
            }
            let _e229 = phi_912_;
            phi_913_ = (_e73 + _e229);
            break;
        }
    }
    let _e232 = phi_913_;
    let _e234 = global_10.member;
    global_11.member = (_e234 * vec4<f32>(_e232.x, _e232.y, _e232.z, 1f));
    let _e243 = global_11.member[1u];
    global_11.member[1u] = -(_e243);
    let _e246 = local;
    let _e247 = !(_e246);
    phi_505_ = _e247;
    if _e247 {
        let _e249 = global[1u];
        phi_505_ = (_e249 > 1.5f);
    }
    let _e252 = phi_505_;
    let _e254 = local_1;
    if (_e254 || _e252) {
        let _e257 = global_4[1u];
        phi_914_ = _e257;
    } else {
        let _e259 = global[1u];
        phi_914_ = _e259;
    }
    let _e261 = phi_914_;
    let _e263 = local_2;
    if _e263 {
        let _e265 = global_5[3u];
        phi_915_ = fract(_e265);
    } else {
        phi_915_ = 0f;
    }
    let _e268 = phi_915_;
    let _e270 = local_3;
    if _e270 {
        phi_916_ = 1f;
    } else {
        phi_916_ = select(0f, 2f, _e252);
    }
    let _e273 = phi_916_;
    phi_543_ = _e247;
    if _e247 {
        let _e275 = global[1u];
        phi_543_ = (_e275 <= 0f);
    }
    let _e278 = phi_543_;
    global_12 = vec4<f32>(_e261, _e268, _e273, select(0f, 1f, _e278));
    let _e281 = global_4;
    global_13 = _e281;
    let _e283 = local_4;
    global_14 = _e283;
    let _e285 = local_5;
    global_15 = _e285;
    return;
}

@vertex 
fn main(@location(12) param: vec4<f32>, @location(0) param_1: vec3<f32>, @location(1) param_2: vec3<f32>, @location(2) param_3: vec2<f32>, @location(13) param_4: vec4<f32>, @location(3) param_5: vec4<f32>, @location(4) param_6: vec4<f32>, @location(5) param_7: vec4<f32>, @location(6) param_8: vec4<f32>) -> VertexOutput {
    global = param;
    global_2 = param_1;
    global_3 = param_2;
    global_4 = param_3;
    global_5 = param_4;
    global_6 = param_5;
    global_7 = param_6;
    global_8 = param_7;
    global_9 = param_8;
    function_();
    let _e25 = global_11.member.y;
    global_11.member.y = -(_e25);
    let _e27 = global_11.member;
    let _e28 = global_12;
    let _e29 = global_13;
    let _e30 = global_14;
    let _e31 = global_15;
    return VertexOutput(_e27, _e28, _e29, _e30, _e31);
}
