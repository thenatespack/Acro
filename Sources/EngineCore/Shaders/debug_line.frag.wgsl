// Generated from debug_line.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 4c9e2afb3c0fc84e
// glsl-fnv1a64: 786f7f4e864cddb9

diagnostic(off, derivative_uniformity);

var<private> global: vec2<f32>;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;

fn function_() {
    let _e11 = global[1u];
    let _e15 = global[0u];
    let _e22 = global_2;
    let _e24 = global_2[3u];
    global_1 = vec4<f32>(_e22.x, _e22.y, _e22.z, (_e24 * (clamp(((max(_e11, 0.5f) + 0.5f) - abs(_e15)), 0f, 1f) * min((_e11 * 2f), 1f))));
    return;
}

@fragment 
fn main(@location(1) @interpolate(linear) param: vec2<f32>, @location(0) param_1: vec4<f32>) -> @location(0) vec4<f32> {
    global = param;
    global_2 = param_1;
    function_();
    let _e5 = global_1;
    return _e5;
}
