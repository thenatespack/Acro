// Generated from sprite.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 8a16bd8393f06c77
// glsl-fnv1a64: e47c018cf9396629

diagnostic(off, derivative_uniformity);

var<private> global: vec4<f32>;
@group(2) @binding(9) 
var global_1: texture_2d<f32>;
@group(2) @binding(17) 
var global_2: sampler;
var<private> global_3: vec2<f32>;
var<private> global_4: vec4<f32>;

fn function_() {
    let _e5 = global_3;
    let _e6 = textureSample(global_1, global_2, _e5);
    let _e7 = global_4;
    global = (_e6 * _e7);
    return;
}

@fragment 
fn main(@location(0) param: vec2<f32>, @location(1) param_1: vec4<f32>) -> @location(0) vec4<f32> {
    global_3 = param;
    global_4 = param_1;
    function_();
    let _e5 = global;
    return _e5;
}
