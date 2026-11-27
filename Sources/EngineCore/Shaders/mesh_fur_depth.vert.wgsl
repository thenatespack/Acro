// Generated from mesh_fur_depth.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 33ecaacfab9688dc
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
    var phi_863_: vec3<f32>;
    var phi_864_: vec3<f32>;
    var local: bool;
    var phi_865_: f32;
    var local_1: bool;
    var phi_866_: f32;
    var local_2: bool;
    var local_3: bool;
    var phi_510_: bool;
    var local_4: vec3<f32>;
    var local_5: vec3<f32>;

    let _e55 = global_6;
    let _e56 = global_7;
    let _e57 = global_8;
    let _e58 = global_9;
    let _e63 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e65 = global_2;
            let _e71 = (mat4x4<f32>(_e55, _e56, _e57, _e58) * vec4<f32>(_e65.x, _e65.y, _e65.z, 1f)).xyz;
            let _e72 = _e55.xyz;
            let _e73 = _e56.xyz;
            let _e74 = _e57.xyz;
            let _e77 = cross(_e72, _e73);
            let _e82 = global_3;
            let _e85 = normalize(((mat3x3<f32>(cross(_e73, _e74), cross(_e74, _e72), _e77) * _e82) * select(1f, -1f, (dot(_e77, _e74) < 0f))));
            let _e89 = global_1.member_1[2i][0u];
            let _e93 = global_1.member_1[3i][3u];
            let _e94 = (_e93 > 0.5f);
            let _e98 = global_1.member_1[5i];
            let _e100 = _e58.xz;
            let _e105 = ((dot(_e100, _e98.xy) * 0.35f) + (dot(_e100, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e119 = global_1.member_1[5i][3u];
            let _e125 = (dot(_e58.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e142 = global_1.member_1[5i][2u];
            let _e148 = global[2u];
            let _e150 = global[3u];
            let _e155 = global_1.member_1[0i][0u];
            let _e160 = (((vec3<f32>(_e98.x, 0f, _e98.y) * (((_e142 * (1f + (_e119 * (((0.5f + ((0.5f * sin(((_e63 * 0.61f) + _e105))) * sin(((_e63 * 0.23f) + (_e105 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e63 * 4.7f) + _e125))) * sin(((_e63 * 2.9f) + (_e125 * 0.37f)))))) * 0.35f)) + (vec3<f32>(_e148, 0f, _e150) / vec3(max(_e155, 0.001f)))) * _e89);
            local = _e94;
            local_1 = _e94;
            local_2 = _e94;
            local_3 = _e94;
            local_4 = _e65;
            local_5 = _e82;
            if _e94 {
                let _e162 = global_4[1u];
                phi_864_ = (_e71 + (_e160 * ((_e155 * _e162) * _e162)));
                break;
            }
            let _e168 = global[1u];
            let _e170 = global_5[3u];
            let _e173 = (_e155 * max((_e170 - 1f), 0f));
            if (_e168 <= 0f) {
                phi_864_ = (_e71 + (_e85 * ((_e173 * 0.04f) + 0.0004f)));
                break;
            }
            let _e192 = global_5;
            let _e194 = (mat3x3<f32>(vec3<f32>(_e55.x, _e55.y, _e55.z), vec3<f32>(_e56.x, _e56.y, _e56.z), vec3<f32>(_e57.x, _e57.y, _e57.z)) * _e192.xyz);
            let _e200 = global_1.member_1[1i][3u];
            let _e211 = (_e173 * _e168);
            let _e212 = (normalize((((_e85 * (1f - min(length(_e194), 1f))) + _e194) + ((vec3<f32>(0f, -(_e200), 0f) + _e160) * (0.5f * _e168)))) * _e211);
            let _e213 = dot(_e212, _e85);
            let _e214 = (_e211 * 0.12f);
            phi_863_ = _e212;
            if (_e213 < _e214) {
                phi_863_ = (_e212 + (_e85 * (_e214 - _e213)));
            }
            let _e220 = phi_863_;
            phi_864_ = (_e71 + _e220);
            break;
        }
    }
    let _e223 = phi_864_;
    let _e225 = global_10.member;
    global_11.member = (_e225 * vec4<f32>(_e223.x, _e223.y, _e223.z, 1f));
    let _e234 = global_11.member[1u];
    global_11.member[1u] = -(_e234);
    let _e237 = local;
    if _e237 {
        let _e239 = global_4[1u];
        phi_865_ = _e239;
    } else {
        let _e241 = global[1u];
        phi_865_ = _e241;
    }
    let _e243 = phi_865_;
    let _e245 = local_1;
    if _e245 {
        let _e247 = global_5[3u];
        phi_866_ = fract(_e247);
    } else {
        phi_866_ = 0f;
    }
    let _e250 = phi_866_;
    let _e252 = local_2;
    let _e255 = local_3;
    let _e256 = !(_e255);
    phi_510_ = _e256;
    if _e256 {
        let _e258 = global[1u];
        phi_510_ = (_e258 <= 0f);
    }
    let _e261 = phi_510_;
    global_12 = vec4<f32>(_e243, _e250, select(0f, 1f, _e252), select(0f, 1f, _e261));
    let _e264 = global_4;
    global_13 = _e264;
    let _e266 = local_4;
    global_14 = _e266;
    let _e268 = local_5;
    global_15 = _e268;
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
