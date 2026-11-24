// Generated from mesh_shadow_wind.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 19e72d3438b37467
// glsl-fnv1a64: 6409d66e3301d2f8

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
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec2<f32>,
}

@group(2) @binding(2) 
var<uniform> global: type_7;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: vec3<f32>;
var<private> global_6: type_17 = type_17(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(0) @binding(0) 
var<uniform> global_7: type_19;
var<private> global_8: vec2<f32>;
var<private> global_9: vec2<f32>;

fn function_() {
    var phi_599_: vec3<f32>;

    let _e53 = global_1;
    let _e54 = global_2;
    let _e55 = global_3;
    let _e56 = global_4;
    let _e57 = mat4x4<f32>(_e53, _e54, _e55, _e56);
    let _e58 = global_5;
    let _e61 = global.member_4[0u];
    let _e63 = global.member_1;
    let _e84 = global.member_2;
    let _e85 = _e84.xyz;
    let _e88 = max(dot(_e85, (_e58 - _e63.xyz)), 0f);
    let _e91 = global.member_3[2u];
    let _e93 = global.member_3;
    let _e95 = (_e57 * vec4<f32>(_e63.x, _e63.y, _e63.z, 1f)).xz;
    let _e100 = ((dot(_e95, _e93.xy) * 0.35f) + (dot(_e95, vec2<f32>(0.83f, -0.57f)) * 1.7f));
    let _e113 = global.member_3[3u];
    let _e117 = (1f + (_e113 * (((0.5f + ((0.5f * sin(((_e61 * 0.61f) + _e100))) * sin(((_e61 * 0.23f) + (_e100 * 0.7f))))) * 1.6f) - 0.6f)));
    let _e131 = global.member_2[3u];
    let _e132 = ((((((_e91 * _e117) * (0.75f + (0.25f * sin(((_e61 * 1.7f) + (_e100 * 1.3f)))))) * 0.06f) * _e88) * _e88) * _e131);
    let _e137 = (transpose(mat3x3<f32>(vec3<f32>(_e53.x, _e53.y, _e53.z), vec3<f32>(_e54.x, _e54.y, _e54.z), vec3<f32>(_e55.x, _e55.y, _e55.z))) * vec3<f32>(_e93.x, 0f, _e93.y));
    let _e138 = dot(_e137, _e137);
    if (_e138 > 0.000000000001f) {
        phi_599_ = (_e137 * inverseSqrt(_e138));
    } else {
        phi_599_ = vec3<f32>(0f, 0f, 0f);
    }
    let _e143 = phi_599_;
    let _e151 = dot(_e58, vec3<f32>(3.1f, 2.3f, 2.7f));
    let _e157 = (_e151 * 1.7f);
    let _e166 = global.member_1[3u];
    let _e186 = (_e58 + (((_e143 * _e132) - (_e85 * (((0.5f * _e132) * _e132) / max(_e88, 0.001f)))) + (vec3<f32>(sin(((_e151 * 1.3f) + 1f)), cos((_e151 * 0.9f)), sin((_e157 + 2f))) * (((((_e166 * _e91) * (0.6f + (0.4f * _e117))) * clamp((_e88 * 3f), 0f, 1f)) * 0.02f) * (sin((((_e61 * 7.3f) + _e151) + _e100)) + (0.5f * sin((((_e61 * 11.1f) + _e157) + (_e100 * 2.1f)))))))));
    let _e193 = global_7.member_1;
    global_6.member = (_e193 * (_e57 * vec4<f32>(_e186.x, _e186.y, _e186.z, 1f)));
    let _e198 = global_6.member[1u];
    global_6.member[1u] = -(_e198);
    let _e200 = global_9;
    global_8 = _e200;
    return;
}

@vertex 
fn main(@location(3) param: vec4<f32>, @location(4) param_1: vec4<f32>, @location(5) param_2: vec4<f32>, @location(6) param_3: vec4<f32>, @location(0) param_4: vec3<f32>, @location(2) param_5: vec2<f32>) -> VertexOutput {
    global_1 = param;
    global_2 = param_1;
    global_3 = param_2;
    global_4 = param_3;
    global_5 = param_4;
    global_9 = param_5;
    function_();
    let _e16 = global_6.member.y;
    global_6.member.y = -(_e16);
    let _e18 = global_6.member;
    let _e19 = global_8;
    return VertexOutput(_e18, _e19);
}
