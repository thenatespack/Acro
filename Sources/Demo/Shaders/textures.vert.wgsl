// Generated from textures.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: a1e636f739047e9e
// glsl-fnv1a64: d485bc52c10c6349

diagnostic(off, derivative_uniformity);

struct type_10 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct type_13 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: mat4x4<f32>,
    member_7: mat4x4<f32>,
}

struct type_18 {
    member: vec4<f32>,
    member_1: vec4<f32>,
}

struct type_21 {
    member: vec4<f32>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec3<f32>,
    @location(1) member_2: vec3<f32>,
    @location(2) member_3: vec2<f32>,
    @location(3) member_4: vec4<f32>,
    @location(4) member_5: vec4<f32>,
}

var<private> global: vec4<f32>;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec3<f32>;
var<private> global_5: type_10 = type_10(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(0) @binding(0) 
var<uniform> global_6: type_13;
var<private> global_7: vec3<f32>;
var<private> global_8: vec3<f32>;
var<private> global_9: vec3<f32>;
var<private> global_10: vec2<f32>;
@group(2) @binding(2) 
var<uniform> global_11: type_18;
@group(2) @binding(3) 
var<uniform> global_12: type_21;
var<private> global_13: vec4<f32>;
var<private> global_14: vec4<f32>;

fn function_() {
    var phi_198_: bool;
    var phi_224_: vec2<f32>;
    var phi_225_: vec2<f32>;

    let _e22 = global;
    let _e23 = global_1;
    let _e24 = global_2;
    let _e25 = global_3;
    let _e27 = global_4;
    let _e32 = (mat4x4<f32>(_e22, _e23, _e24, _e25) * vec4<f32>(_e27.x, _e27.y, _e27.z, 1f));
    let _e34 = global_6.member;
    global_5.member = (_e34 * _e32);
    let _e39 = global_5.member[1u];
    global_5.member[1u] = -(_e39);
    global_7 = _e32.xyz;
    let _e42 = global_9;
    global_8 = _e42;
    switch bitcast<i32>(0u) {
        default: {
            let _e44 = abs(_e42);
            let _e47 = (_e44.y >= _e44.x);
            phi_198_ = _e47;
            if _e47 {
                phi_198_ = (_e44.y >= _e44.z);
            }
            let _e51 = phi_198_;
            if _e51 {
                phi_225_ = _e32.xz;
                break;
            }
            if (_e44.x >= _e44.z) {
                phi_224_ = _e32.zy;
            } else {
                phi_224_ = _e32.xy;
            }
            let _e58 = phi_224_;
            phi_225_ = _e58;
            break;
        }
    }
    let _e60 = phi_225_;
    let _e62 = global_11.member;
    let _e66 = global_12.member;
    global_10 = ((_e60 * _e62.xy) + _e66.xy);
    let _e70 = global_6.member_6;
    global_13 = (_e70 * _e32);
    let _e73 = global_6.member_7;
    global_14 = (_e73 * _e32);
    return;
}

@vertex 
fn main(@location(2) param: vec4<f32>, @location(3) param_1: vec4<f32>, @location(4) param_2: vec4<f32>, @location(5) param_3: vec4<f32>, @location(0) param_4: vec3<f32>, @location(1) param_5: vec3<f32>) -> VertexOutput {
    global = param;
    global_1 = param_1;
    global_2 = param_2;
    global_3 = param_3;
    global_4 = param_4;
    global_9 = param_5;
    function_();
    let _e20 = global_5.member.y;
    global_5.member.y = -(_e20);
    let _e22 = global_5.member;
    let _e23 = global_7;
    let _e24 = global_8;
    let _e25 = global_10;
    let _e26 = global_13;
    let _e27 = global_14;
    return VertexOutput(_e22, _e23, _e24, _e25, _e26, _e27);
}
