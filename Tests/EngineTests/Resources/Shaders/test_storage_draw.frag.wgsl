// Generated from test_storage_draw.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 4cfabfada863d48f
// glsl-fnv1a64: a80ff571cdad8bd3

diagnostic(off, derivative_uniformity);

struct type_3 {
    member: vec4<f32>,
}

var<private> global: vec4<f32>;
@group(3) @binding(0) 
var<uniform> global_1: type_3;

fn function_() {
    let _e4 = global_1.member;
    global = _e4;
    return;
}

@fragment 
fn main() -> @location(0) vec4<f32> {
    function_();
    let _e1 = global;
    return _e1;
}
