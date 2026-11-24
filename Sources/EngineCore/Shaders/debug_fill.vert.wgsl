// Generated from debug_fill.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 28cb792195098208
// glsl-fnv1a64: 22218318aeeefe3b

diagnostic(off, derivative_uniformity);

struct type_9 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct type_12 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
}

struct VertexOutput {
    @location(0) member: vec4<f32>,
    @builtin(position) member_1: vec4<f32>,
}

var<private> global: i32;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: type_9 = type_9(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(3) @binding(0) 
var<uniform> global_7: type_12;

fn function_() {
    var phi_71_: vec3<f32>;
    var phi_72_: vec3<f32>;

    let _e12 = global;
    if (_e12 == 0i) {
        let _e14 = global_1;
        phi_72_ = _e14.xyz;
    } else {
        if (_e12 == 1i) {
            let _e17 = global_2;
            phi_71_ = _e17.xyz;
        } else {
            let _e19 = global_3;
            phi_71_ = _e19.xyz;
        }
        let _e22 = phi_71_;
        phi_72_ = _e22;
    }
    let _e24 = phi_72_;
    let _e25 = global_5;
    global_4 = _e25;
    let _e27 = global_7.member;
    global_6.member = (_e27 * vec4<f32>(_e24.x, _e24.y, _e24.z, 1f));
    let _e36 = global_6.member[1u];
    global_6.member[1u] = -(_e36);
    return;
}

@vertex 
fn main(@builtin(vertex_index) param: u32, @location(0) param_1: vec4<f32>, @location(1) param_2: vec4<f32>, @location(2) param_3: vec4<f32>, @location(3) param_4: vec4<f32>) -> VertexOutput {
    global = i32(param);
    global_1 = param_1;
    global_2 = param_2;
    global_3 = param_3;
    global_5 = param_4;
    function_();
    let _e15 = global_6.member.y;
    global_6.member.y = -(_e15);
    let _e17 = global_4;
    let _e18 = global_6.member;
    return VertexOutput(_e17, _e18);
}
