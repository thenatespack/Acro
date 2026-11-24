// Generated from text3d.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 5e7e76e20eaacb81
// glsl-fnv1a64: 9505a72cad9404a7

diagnostic(off, derivative_uniformity);

struct type_4 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
}

struct type_8 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
}

struct type_18 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @location(2) @interpolate(flat) member: f32,
    @builtin(position) member_1: vec4<f32>,
    @location(0) member_2: vec2<f32>,
    @location(1) member_3: f32,
}

@group(2) @binding(2) 
var<uniform> global: type_4;
@group(0) @binding(0) 
var<uniform> global_1: type_8;
var<private> global_2: vec2<f32>;
var<private> global_3: f32;
var<private> global_4: type_18 = type_18(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_5: vec2<f32>;
var<private> global_6: vec2<f32>;
var<private> global_7: f32;

fn function_() {
    var phi_142_: vec3<f32>;
    var phi_141_: f32;

    let _e21 = global.member[3];
    let _e22 = _e21.xyz;
    let _e24 = global_1.member_6;
    let _e25 = _e24.xyz;
    let _e29 = global.member_1[3u];
    if (_e29 > 0.5f) {
        let _e33 = global.member[0];
        let _e38 = global.member[1];
        let _e42 = global.member_1;
        let _e45 = global_2[0u];
        let _e50 = global.member_2;
        let _e53 = global_2[1u];
        phi_142_ = ((_e22 + (_e42.xyz * (_e45 * length(_e33.xyz)))) + (_e50.xyz * (_e53 * length(_e38.xyz))));
        phi_141_ = 1f;
    } else {
        let _e58 = global.member;
        let _e59 = global_2;
        let _e67 = global.member[0];
        let _e71 = global.member[1];
        phi_142_ = (_e58 * vec4<f32>(_e59.x, _e59.y, 0f, 1f)).xyz;
        phi_141_ = dot(cross(_e67.xyz, _e71.xyz), (_e25 - _e22));
    }
    let _e76 = phi_142_;
    let _e78 = phi_141_;
    let _e81 = global.member_2[3u];
    global_3 = select(0f, 1f, ((_e81 < 0.5f) || (_e78 >= 0f)));
    let _e87 = global_1.member;
    global_4.member = (_e87 * vec4<f32>(_e76.x, _e76.y, _e76.z, 1f));
    let _e96 = global_4.member[1u];
    global_4.member[1u] = -(_e96);
    let _e98 = global_6;
    global_5 = _e98;
    global_7 = length((_e25 - _e76));
    return;
}

@vertex 
fn main(@location(0) param: vec2<f32>, @location(1) param_1: vec2<f32>) -> VertexOutput {
    global_2 = param;
    global_6 = param_1;
    function_();
    let _e10 = global_4.member.y;
    global_4.member.y = -(_e10);
    let _e12 = global_3;
    let _e13 = global_4.member;
    let _e14 = global_5;
    let _e15 = global_7;
    return VertexOutput(_e12, _e13, _e14, _e15);
}
