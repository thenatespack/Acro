// Generated from particle_sort_keys.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 8aab4b4bdcb8c07d
// glsl-fnv1a64: 9c17953233f2e4d7

diagnostic(off, derivative_uniformity);

struct type_5 {
    member: array<u32>,
}

struct type_13 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
}

struct type_15 {
    member: array<type_13>,
}

struct type_19 {
    member: vec4<f32>,
}

struct type_23 {
    member: array<vec2<u32>>,
}

var<private> global: vec3<u32>;
@group(2) @binding(30) 
var<storage> global_1: type_5;
@group(2) @binding(26) 
var<storage> global_2: type_5;
@group(2) @binding(24) 
var<storage> global_3: type_15;
@group(2) @binding(2) 
var<uniform> global_4: type_19;
@group(2) @binding(31) 
var<storage, read_write> global_5: type_23;

fn function_() {
    var phi_101_: vec2<u32>;

    switch bitcast<i32>(0u) {
        default: {
            let _e17 = global[0u];
            let _e20 = global_1.member[0i];
            if (_e17 >= _e20) {
                break;
            }
            let _e24 = global_1.member[1i];
            phi_101_ = vec2<u32>(4294967295u, 4294967295u);
            if (_e17 < _e24) {
                let _e28 = global_2.member[_e17];
                let _e32 = global_3.member[_e28].member;
                let _e35 = global_4.member;
                phi_101_ = vec2<u32>(~(bitcast<u32>(max(length((_e32.xyz - _e35.xyz)), 0.000001f))), _e28);
            }
            let _e44 = phi_101_;
            global_5.member[_e17] = _e44;
            break;
        }
    }
    return;
}

@compute @workgroup_size(256, 1, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global = param;
    function_();
}
