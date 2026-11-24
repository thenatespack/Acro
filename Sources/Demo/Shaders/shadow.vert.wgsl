// Generated from shadow.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 9880248748432611
// glsl-fnv1a64: 3e7e47147ef1908d

diagnostic(off, derivative_uniformity);

struct type_9 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
}

struct type_15 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

var<private> global: vec4<f32>;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_5: type_9;
var<private> global_6: vec3<f32>;
var<private> global_7: type_15 = type_15(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());

fn function_() {
    var phi_200_: vec4<f32>;

    let _e17 = global;
    let _e18 = global_1;
    let _e19 = global_2;
    let _e20 = global_3;
    let _e21 = mat4x4<f32>(_e17, _e18, _e19, _e20);
    let _e23 = global_4[3u];
    if (_e23 > 0f) {
        let _e25 = global_4;
        let _e28 = global_5.member_3[3u];
        let _e30 = (_e28 + _e25.z);
        let _e31 = cos(_e30);
        let _e32 = sin(_e30);
        let _e37 = global_6;
        let _e38 = (mat3x3<f32>(vec3<f32>(_e31, 0f, -(_e32)), vec3<f32>(0f, 1f, 0f), vec3<f32>(_e32, 0f, _e31)) * _e37);
        phi_200_ = ((_e21 * vec4<f32>(_e38.x, _e38.y, _e38.z, 1f)) + vec4<f32>(0f, (sin(((_e28 * 2f) + _e25.z)) * _e25.w), 0f, 0f));
    } else {
        let _e51 = global_6;
        phi_200_ = (_e21 * vec4<f32>(_e51.x, _e51.y, _e51.z, 1f));
    }
    let _e58 = phi_200_;
    let _e60 = global_5.member_1;
    global_7.member = (_e60 * _e58);
    let _e65 = global_7.member[1u];
    global_7.member[1u] = -(_e65);
    return;
}

@vertex 
fn main(@location(2) param: vec4<f32>, @location(3) param_1: vec4<f32>, @location(4) param_2: vec4<f32>, @location(5) param_3: vec4<f32>, @location(7) param_4: vec4<f32>, @location(0) param_5: vec3<f32>) -> @builtin(position) vec4<f32> {
    global = param;
    global_1 = param_1;
    global_2 = param_2;
    global_3 = param_3;
    global_4 = param_4;
    global_6 = param_5;
    function_();
    let _e15 = global_7.member.y;
    global_7.member.y = -(_e15);
    let _e17 = global_7.member;
    return _e17;
}
