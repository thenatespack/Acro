// Generated from env_pack.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 3acd7ff4d37e137f
// glsl-fnv1a64: ee12627daabade21

diagnostic(off, derivative_uniformity);

struct type_8 {
    member: vec2<i32>,
}

var<private> global: vec4<f32>;
@group(2) @binding(9) 
var global_1: texture_2d<f32>;
@group(2) @binding(17) 
var global_2: sampler;
var<private> global_3: vec4<f32>;
@group(3) @binding(0) 
var<uniform> global_4: type_8;

fn function_() {
    let _e6 = global_3;
    let _e10 = global_4.member;
    let _e12 = textureLoad(global_1, (vec2<i32>(_e6.xy) - _e10), 0i);
    global = _e12;
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_3 = param;
    function_();
    let _e3 = global;
    return _e3;
}
