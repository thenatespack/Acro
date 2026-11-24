// Generated from text.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 6daf82505a92d45b
// glsl-fnv1a64: 41a6411f7fa80bdb

diagnostic(off, derivative_uniformity);

@group(2) @binding(9) 
var global: texture_2d<f32>;
@group(2) @binding(17) 
var global_1: sampler;
var<private> global_2: vec2<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;

fn function_() {
    let _e8 = global_2;
    let _e9 = textureSample(global, global_1, _e8);
    let _e11 = fwidth(_e9.x);
    let _e13 = max((_e11 * 0.5f), 0.001953125f);
    let _e17 = global_4;
    let _e19 = global_4[3u];
    global_3 = vec4<f32>(_e17.x, _e17.y, _e17.z, (_e19 * smoothstep((0.5f - _e13), (0.5f + _e13), _e9.x)));
    return;
}

@fragment 
fn main(@location(0) param: vec2<f32>, @location(1) param_1: vec4<f32>) -> @location(0) vec4<f32> {
    global_2 = param;
    global_4 = param_1;
    function_();
    let _e5 = global_3;
    return _e5;
}
