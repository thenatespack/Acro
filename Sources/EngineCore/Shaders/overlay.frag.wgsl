// Generated from overlay.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 4879c39683ce66e0
// glsl-fnv1a64: 8a2785e21cb5ab84

diagnostic(off, derivative_uniformity);

var<private> global: vec4<f32>;
var<private> global_1: vec4<f32>;

fn function_() {
    let _e2 = global_1;
    global = _e2;
    return;
}

@fragment 
fn main(@location(0) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_1 = param;
    function_();
    let _e3 = global;
    return _e3;
}
