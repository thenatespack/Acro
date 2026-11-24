// Generated from mesh_shadow_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: c9170889009cf0f1
// glsl-fnv1a64: 5a3f20b268ccdd21

diagnostic(off, derivative_uniformity);

struct type_3 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
}

@group(2) @binding(2) 
var<uniform> global: type_3;
var<private> global_1: vec2<f32>;
@group(2) @binding(9) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;

fn function_() {
    let _e12 = global.member_2;
    let _e14 = global_1;
    let _e18 = global.member_2[2u];
    let _e21 = global.member_3;
    let _e26 = global.member_3[2u];
    let _e31 = global.member[3u];
    let _e32 = textureSample(global_2, global_3, vec2<f32>((dot(_e12.xy, _e14) + _e18), (dot(_e21.xy, _e14) + _e26)));
    let _e37 = global.member_6[0u];
    if ((_e31 * _e32.w) < _e37) {
        discard;
    }
    return;
}

@fragment 
fn main(@location(0) param: vec2<f32>) {
    global_1 = param;
    function_();
}
