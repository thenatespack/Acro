// Generated from outline_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 5b2e3713436dd0c8
// glsl-fnv1a64: 4e8e08f628d5118e

diagnostic(off, derivative_uniformity);

struct type_4 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
}

var<private> global: vec4<f32>;
@group(3) @binding(0) 
var<uniform> global_1: type_4;

fn function_() {
    let _e4 = global_1.member_1;
    global = _e4;
    return;
}

@fragment 
fn main() -> @location(0) vec4<f32> {
    function_();
    let _e1 = global;
    return _e1;
}
