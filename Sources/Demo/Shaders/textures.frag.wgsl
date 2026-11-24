// Generated from textures.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: f7b89778d88aa8a0
// glsl-fnv1a64: 2ea6da69276412ef

diagnostic(off, derivative_uniformity);

struct type_7 {
    member: vec4<f32>,
    member_1: vec4<f32>,
}

struct type_13 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
}

struct FragmentOutput {
    @location(0) member: vec4<f32>,
    @location(1) member_1: vec2<f32>,
}

@group(2) @binding(9) 
var global: texture_2d<f32>;
@group(2) @binding(17) 
var global_1: sampler;
var<private> global_2: vec2<f32>;
@group(2) @binding(2) 
var<uniform> global_3: type_7;
var<private> global_4: vec3<f32>;
@group(0) @binding(0) 
var<uniform> global_5: type_13;
var<private> global_6: vec3<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec2<f32>;

fn function_() {
    var phi_168_: vec2<f32>;

    let _e31 = global_2;
    let _e32 = textureSample(global, global_1, _e31);
    let _e35 = global_3.member_1;
    let _e38 = global_4;
    let _e39 = normalize(_e38);
    let _e41 = global_5.member_2;
    let _e48 = global_5.member_2[3u];
    let _e60 = global_5.member_3;
    let _e62 = global_6;
    let _e68 = global_5.member_4[3u];
    let _e73 = global_5.member_4;
    let _e76 = mix(((_e32.xyz * _e35.xyz) * ((mix(vec3<f32>(0.12f, 0.1f, 0.09f), vec3<f32>(0.55f, 0.65f, 0.85f), vec3(((_e39.y * 0.5f) + 0.5f))) * 0.3f) + vec3((max(dot(_e39, normalize(_e41.xyz)), 0f) * _e48)))), _e73.xyz, vec3((1f - exp((-(length((_e60.xyz - _e62))) * _e68)))));
    global_7 = vec4<f32>(_e76.x, _e76.y, _e76.z, 1f);
    let _e81 = global_8;
    let _e82 = global_9;
    if (_e82.w > 0f) {
        phi_168_ = (((_e82.xy / vec2(_e82.w)) - (_e81.xy / vec2(_e81.w))) * vec2<f32>(0.5f, -0.5f));
    } else {
        phi_168_ = vec2<f32>(0f, 0f);
    }
    let _e95 = phi_168_;
    global_10 = _e95;
    return;
}

@fragment 
fn main(@location(2) param: vec2<f32>, @location(1) param_1: vec3<f32>, @location(0) param_2: vec3<f32>, @location(3) param_3: vec4<f32>, @location(4) param_4: vec4<f32>) -> FragmentOutput {
    global_2 = param;
    global_4 = param_1;
    global_6 = param_2;
    global_8 = param_3;
    global_9 = param_4;
    function_();
    let _e12 = global_7;
    let _e13 = global_10;
    return FragmentOutput(_e12, _e13);
}
