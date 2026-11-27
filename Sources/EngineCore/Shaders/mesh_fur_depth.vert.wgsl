// Generated from mesh_fur_depth.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: b41c07030a2b9499
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
var<private> global_4: vec4<f32>;
var<private> global_5: vec2<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_11: type_18;
var<private> global_12: type_22 = type_22(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_13: vec4<f32>;
var<private> global_14: vec2<f32>;
var<private> global_15: vec3<f32>;
var<private> global_16: vec3<f32>;

fn function_() {
    var phi_926_: f32;
    var phi_927_: vec3<f32>;
    var phi_928_: vec3<f32>;
    var local: bool;
    var phi_514_: bool;
    var local_1: bool;
    var phi_929_: f32;
    var local_2: bool;
    var phi_930_: f32;
    var local_3: bool;
    var phi_931_: f32;
    var phi_552_: bool;
    var local_4: vec3<f32>;
    var local_5: vec3<f32>;

    let _e59 = global_7;
    let _e60 = global_8;
    let _e61 = global_9;
    let _e62 = global_10;
    let _e67 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e69 = global_2;
            let _e75 = (mat4x4<f32>(_e59, _e60, _e61, _e62) * vec4<f32>(_e69.x, _e69.y, _e69.z, 1f)).xyz;
            let _e76 = _e59.xyz;
            let _e77 = _e60.xyz;
            let _e78 = _e61.xyz;
            let _e81 = cross(_e76, _e77);
            let _e86 = global_3;
            let _e89 = normalize(((mat3x3<f32>(cross(_e77, _e78), cross(_e78, _e76), _e81) * _e86) * select(1f, -1f, (dot(_e81, _e78) < 0f))));
            let _e93 = global_1.member_1[2i][0u];
            let _e97 = global_1.member_1[3i][3u];
            let _e98 = (_e97 > 0.5f);
            let _e100 = global_4[3u];
            let _e106 = global_1.member_1[5i];
            let _e108 = _e62.xz;
            let _e113 = ((dot(_e108, _e106.xy) * 0.35f) + (dot(_e108, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e127 = global_1.member_1[5i][3u];
            let _e133 = (dot(_e62.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e150 = global_1.member_1[5i][2u];
            let _e156 = global[2u];
            let _e158 = global[3u];
            let _e163 = global_1.member_1[0i][0u];
            let _e169 = (((vec3<f32>(_e106.x, 0f, _e106.y) * (((_e150 * (1f + (_e127 * (((0.5f + ((0.5f * sin(((_e67 * 0.61f) + _e113))) * sin(((_e67 * 0.23f) + (_e113 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e67 * 4.7f) + _e133))) * sin(((_e67 * 2.9f) + (_e133 * 0.37f)))))) * 0.35f)) + (vec3<f32>(_e156, 0f, _e158) / vec3(max(_e163, 0.001f)))) * (_e93 * select(1f, 0f, (_e100 < -0.5f))));
            local = _e98;
            local_1 = _e98;
            local_2 = _e98;
            local_3 = _e98;
            local_4 = _e69;
            local_5 = _e86;
            if _e98 {
                let _e171 = global_5[1u];
                phi_928_ = (_e75 + (_e169 * ((_e163 * _e171) * _e171)));
                break;
            }
            let _e177 = global[1u];
            let _e178 = (_e177 > 1.5f);
            if _e178 {
                let _e180 = global_5[1u];
                phi_926_ = _e180;
            } else {
                phi_926_ = _e177;
            }
            let _e182 = phi_926_;
            let _e184 = global_6[3u];
            let _e187 = (_e163 * max((_e184 - 1f), 0f));
            if ((_e182 <= 0f) && !(_e178)) {
                phi_928_ = (_e75 + (_e89 * ((_e187 * 0.04f) + 0.0004f)));
                break;
            }
            let _e208 = global_6;
            let _e210 = (mat3x3<f32>(vec3<f32>(_e59.x, _e59.y, _e59.z), vec3<f32>(_e60.x, _e60.y, _e60.z), vec3<f32>(_e61.x, _e61.y, _e61.z)) * _e208.xyz);
            let _e216 = global_1.member_1[1i][3u];
            let _e227 = (_e187 * _e182);
            let _e228 = (normalize((((_e89 * (1f - min(length(_e210), 1f))) + _e210) + ((vec3<f32>(0f, -(_e216), 0f) + _e169) * (0.5f * _e182)))) * _e227);
            let _e229 = dot(_e228, _e89);
            let _e230 = (_e227 * 0.12f);
            phi_927_ = _e228;
            if (_e229 < _e230) {
                phi_927_ = (_e228 + (_e89 * (_e230 - _e229)));
            }
            let _e236 = phi_927_;
            phi_928_ = (_e75 + _e236);
            break;
        }
    }
    let _e239 = phi_928_;
    let _e241 = global_11.member;
    global_12.member = (_e241 * vec4<f32>(_e239.x, _e239.y, _e239.z, 1f));
    let _e250 = global_12.member[1u];
    global_12.member[1u] = -(_e250);
    let _e253 = local;
    let _e254 = !(_e253);
    phi_514_ = _e254;
    if _e254 {
        let _e256 = global[1u];
        phi_514_ = (_e256 > 1.5f);
    }
    let _e259 = phi_514_;
    let _e261 = local_1;
    if (_e261 || _e259) {
        let _e264 = global_5[1u];
        phi_929_ = _e264;
    } else {
        let _e266 = global[1u];
        phi_929_ = _e266;
    }
    let _e268 = phi_929_;
    let _e270 = local_2;
    if _e270 {
        let _e272 = global_6[3u];
        phi_930_ = fract(_e272);
    } else {
        phi_930_ = 0f;
    }
    let _e275 = phi_930_;
    let _e277 = local_3;
    if _e277 {
        phi_931_ = 1f;
    } else {
        phi_931_ = select(0f, 2f, _e259);
    }
    let _e280 = phi_931_;
    phi_552_ = _e254;
    if _e254 {
        let _e282 = global[1u];
        phi_552_ = (_e282 <= 0f);
    }
    let _e285 = phi_552_;
    global_13 = vec4<f32>(_e268, _e275, _e280, select(0f, 1f, _e285));
    let _e288 = global_5;
    global_14 = _e288;
    let _e290 = local_4;
    global_15 = _e290;
    let _e292 = local_5;
    global_16 = _e292;
    return;
}

@vertex 
fn main(@location(12) param: vec4<f32>, @location(0) param_1: vec3<f32>, @location(1) param_2: vec3<f32>, @location(11) param_3: vec4<f32>, @location(2) param_4: vec2<f32>, @location(13) param_5: vec4<f32>, @location(3) param_6: vec4<f32>, @location(4) param_7: vec4<f32>, @location(5) param_8: vec4<f32>, @location(6) param_9: vec4<f32>) -> VertexOutput {
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
    function_();
    let _e27 = global_12.member.y;
    global_12.member.y = -(_e27);
    let _e29 = global_12.member;
    let _e30 = global_13;
    let _e31 = global_14;
    let _e32 = global_15;
    let _e33 = global_16;
    return VertexOutput(_e29, _e30, _e31, _e32, _e33);
}
