// Generated from particle_sort_write.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: b3fb08b5145c4f06
// glsl-fnv1a64: 418a9f39cbe2e0eb

diagnostic(off, derivative_uniformity);

struct type_5 {
    member: array<u32>,
}

struct type_12 {
    member: array<vec2<u32>>,
}

var<private> global: vec3<u32>;
@group(2) @binding(30) 
var<storage> global_1: type_5;
@group(2) @binding(26) 
var<storage, read_write> global_2: type_5;
@group(2) @binding(31) 
var<storage> global_3: type_12;

fn function_() {
    let _e11 = global[0u];
    let _e14 = global_1.member[1i];
    if (_e11 < _e14) {
        let _e19 = global_3.member[_e11][1u];
        global_2.member[_e11] = _e19;
    }
    return;
}

@compute @workgroup_size(256, 1, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global = param;
    function_();
}
