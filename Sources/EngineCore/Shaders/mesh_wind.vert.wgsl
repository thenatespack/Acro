// Generated from mesh_wind.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 1604910177fb01d7
// glsl-fnv1a64: b94c27ee91d897e9

diagnostic(off, derivative_uniformity);

struct type_7 {
    member: array<vec4<f32>, 8>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
}

struct type_17 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct type_19 {
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
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec3<f32>,
    @location(1) member_2: vec3<f32>,
    @location(2) member_3: vec2<f32>,
    @location(3) member_4: vec4<f32>,
    @location(5) member_5: vec4<f32>,
    @location(6) member_6: vec4<f32>,
    @location(7) member_7: vec4<f32>,
    @location(8) member_8: vec4<f32>,
    @location(4) member_9: vec3<f32>,
}

@group(2) @binding(2) 
var<uniform> global: type_7;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec3<f32>;
var<private> global_10: type_17 = type_17(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(0) @binding(0) 
var<uniform> global_11: type_19;
var<private> global_12: vec3<f32>;
var<private> global_13: vec3<f32>;
var<private> global_14: vec3<f32>;
var<private> global_15: vec2<f32>;
var<private> global_16: vec2<f32>;
var<private> global_17: vec4<f32>;
var<private> global_18: vec4<f32>;
var<private> global_19: vec4<f32>;
var<private> global_20: vec4<f32>;
var<private> global_21: vec4<f32>;
var<private> global_22: vec4<f32>;
var<private> global_23: vec4<f32>;
var<private> global_24: vec4<f32>;
var<private> global_25: vec3<f32>;

fn function_() {
    var phi_973_: vec3<f32>;
    var phi_974_: vec3<f32>;

    let _e70 = global_1;
    let _e71 = global_2;
    let _e72 = global_3;
    let _e73 = global_4;
    let _e74 = mat4x4<f32>(_e70, _e71, _e72, _e73);
    let _e75 = global_5;
    let _e76 = global_6;
    let _e77 = global_7;
    let _e78 = global_8;
    let _e79 = mat4x4<f32>(_e75, _e76, _e77, _e78);
    let _e80 = global_9;
    let _e83 = global.member_4[0u];
    let _e85 = global.member_1;
    let _e90 = vec4<f32>(_e85.x, _e85.y, _e85.z, 1f);
    let _e104 = mat3x3<f32>(vec3<f32>(_e70.x, _e70.y, _e70.z), vec3<f32>(_e71.x, _e71.y, _e71.z), vec3<f32>(_e72.x, _e72.y, _e72.z));
    let _e106 = global.member_2;
    let _e107 = _e106.xyz;
    let _e110 = max(dot(_e107, (_e80 - _e85.xyz)), 0f);
    let _e113 = global.member_3[2u];
    let _e115 = global.member_3;
    let _e116 = _e115.xy;
    let _e117 = (_e74 * _e90).xz;
    let _e122 = ((dot(_e117, _e116) * 0.35f) + (dot(_e117, vec2<f32>(0.83f, -0.57f)) * 1.7f));
    let _e135 = global.member_3[3u];
    let _e139 = (1f + (_e135 * (((0.5f + ((0.5f * sin(((_e83 * 0.61f) + _e122))) * sin(((_e83 * 0.23f) + (_e122 * 0.7f))))) * 1.6f) - 0.6f)));
    let _e153 = global.member_2[3u];
    let _e154 = ((((((_e113 * _e139) * (0.75f + (0.25f * sin(((_e83 * 1.7f) + (_e122 * 1.3f)))))) * 0.06f) * _e110) * _e110) * _e153);
    let _e158 = vec3<f32>(_e115.x, 0f, _e115.y);
    let _e159 = (transpose(_e104) * _e158);
    let _e160 = dot(_e159, _e159);
    if (_e160 > 0.000000000001f) {
        phi_973_ = (_e159 * inverseSqrt(_e160));
    } else {
        phi_973_ = vec3<f32>(0f, 0f, 0f);
    }
    let _e165 = phi_973_;
    let _e169 = max(_e110, 0.001f);
    let _e173 = dot(_e80, vec3<f32>(3.1f, 2.3f, 2.7f));
    let _e179 = (_e173 * 1.7f);
    let _e188 = global.member_1[3u];
    let _e189 = (_e188 * _e113);
    let _e194 = clamp((_e110 * 3f), 0f, 1f);
    let _e205 = vec3<f32>(sin(((_e173 * 1.3f) + 1f)), cos((_e173 * 0.9f)), sin((_e179 + 2f)));
    let _e208 = (_e80 + (((_e165 * _e154) - (_e107 * (((0.5f * _e154) * _e154) / _e169))) + (_e205 * ((((_e189 * (0.6f + (0.4f * _e139))) * _e194) * 0.02f) * (sin((((_e83 * 7.3f) + _e173) + _e122)) + (0.5f * sin((((_e83 * 11.1f) + _e179) + (_e122 * 2.1f)))))))));
    let _e211 = global.member_4[1u];
    let _e226 = (_e79 * _e90).xz;
    let _e231 = ((dot(_e226, _e116) * 0.35f) + (dot(_e226, vec2<f32>(0.83f, -0.57f)) * 1.7f));
    let _e245 = (1f + (_e135 * (((0.5f + ((0.5f * sin(((_e211 * 0.61f) + _e231))) * sin(((_e211 * 0.23f) + (_e231 * 0.7f))))) * 1.6f) - 0.6f)));
    let _e257 = ((((((_e113 * _e245) * (0.75f + (0.25f * sin(((_e211 * 1.7f) + (_e231 * 1.3f)))))) * 0.06f) * _e110) * _e110) * _e153);
    let _e259 = (transpose(mat3x3<f32>(vec3<f32>(_e75.x, _e75.y, _e75.z), vec3<f32>(_e76.x, _e76.y, _e76.z), vec3<f32>(_e77.x, _e77.y, _e77.z))) * _e158);
    let _e260 = dot(_e259, _e259);
    if (_e260 > 0.000000000001f) {
        phi_974_ = (_e259 * inverseSqrt(_e260));
    } else {
        phi_974_ = vec3<f32>(0f, 0f, 0f);
    }
    let _e265 = phi_974_;
    let _e291 = (_e80 + (((_e265 * _e257) - (_e107 * (((0.5f * _e257) * _e257) / _e169))) + (_e205 * ((((_e189 * (0.6f + (0.4f * _e245))) * _e194) * 0.02f) * (sin((((_e211 * 7.3f) + _e173) + _e231)) + (0.5f * sin((((_e211 * 11.1f) + _e179) + (_e231 * 2.1f)))))))));
    let _e296 = (_e74 * vec4<f32>(_e208.x, _e208.y, _e208.z, 1f));
    let _e302 = _e70.xyz;
    let _e303 = _e71.xyz;
    let _e304 = _e72.xyz;
    let _e307 = cross(_e302, _e303);
    let _e311 = select(1f, -1f, (dot(_e307, _e304) < 0f));
    let _e313 = global_11.member;
    global_10.member = (_e313 * _e296);
    let _e318 = global_10.member[1u];
    global_10.member[1u] = -(_e318);
    global_12 = _e296.xyz;
    let _e321 = global_14;
    global_13 = ((mat3x3<f32>(cross(_e303, _e304), cross(_e304, _e302), _e307) * _e321) * _e311);
    let _e324 = global_16;
    global_15 = _e324;
    let _e325 = global_18;
    global_17 = _e325;
    let _e326 = global_20;
    global_19 = _e326;
    let _e328 = global_11.member_2;
    global_21 = (_e328 * _e296);
    let _e331 = global_11.member_3;
    global_22 = (_e331 * (_e79 * vec4<f32>(_e291.x, _e291.y, _e291.z, 1f)));
    let _e333 = global_24;
    let _e335 = (_e104 * _e333.xyz);
    let _e337 = global_24[3u];
    global_23 = vec4<f32>(_e335.x, _e335.y, _e335.z, (_e337 * _e311));
    global_25 = _e80;
    return;
}

@vertex 
fn main(@location(3) param: vec4<f32>, @location(4) param_1: vec4<f32>, @location(5) param_2: vec4<f32>, @location(6) param_3: vec4<f32>, @location(7) param_4: vec4<f32>, @location(8) param_5: vec4<f32>, @location(9) param_6: vec4<f32>, @location(10) param_7: vec4<f32>, @location(0) param_8: vec3<f32>, @location(1) param_9: vec3<f32>, @location(2) param_10: vec2<f32>, @location(11) param_11: vec4<f32>, @location(12) param_12: vec4<f32>, @location(13) param_13: vec4<f32>) -> VertexOutput {
    global_1 = param;
    global_2 = param_1;
    global_3 = param_2;
    global_4 = param_3;
    global_5 = param_4;
    global_6 = param_5;
    global_7 = param_6;
    global_8 = param_7;
    global_9 = param_8;
    global_14 = param_9;
    global_16 = param_10;
    global_18 = param_11;
    global_20 = param_12;
    global_24 = param_13;
    function_();
    let _e40 = global_10.member.y;
    global_10.member.y = -(_e40);
    let _e42 = global_10.member;
    let _e43 = global_12;
    let _e44 = global_13;
    let _e45 = global_15;
    let _e46 = global_17;
    let _e47 = global_19;
    let _e48 = global_21;
    let _e49 = global_22;
    let _e50 = global_23;
    let _e51 = global_25;
    return VertexOutput(_e42, _e43, _e44, _e45, _e46, _e47, _e48, _e49, _e50, _e51);
}
