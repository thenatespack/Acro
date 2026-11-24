// Generated from mesh_shadow_graph_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: d0434e084c4e40c4
// glsl-fnv1a64: 0465ea86b096f023

diagnostic(off, derivative_uniformity);

struct type_10 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 384>,
    member_2: array<vec4<f32>, 384>,
}

struct type_16 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
}

struct type_20 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec3<f32>,
    @location(1) member_2: vec3<f32>,
    @location(2) member_3: vec2<f32>,
    @location(3) member_4: vec4<f32>,
}

var<private> global: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_1: type_10;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec3<f32>;
@group(0) @binding(0) 
var<uniform> global_8: type_16;
var<private> global_9: type_20 = type_20(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_10: vec3<f32>;
var<private> global_11: vec3<f32>;
var<private> global_12: vec3<f32>;
var<private> global_13: vec2<f32>;
var<private> global_14: vec2<f32>;
var<private> global_15: vec4<f32>;
var<private> global_16: vec4<f32>;

fn function_() {
    var phi_329_: vec4<f32>;
    var phi_328_: vec4<f32>;
    var phi_327_: vec4<f32>;
    var phi_326_: i32;
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var local_2: vec4<f32>;

    let _e30 = global_3;
    let _e31 = global_4;
    let _e32 = global_5;
    let _e33 = global_6;
    phi_329_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_328_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_327_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_326_ = 0i;
    loop {
        let _e36 = phi_329_;
        let _e38 = phi_328_;
        let _e40 = phi_327_;
        let _e42 = phi_326_;
        local = _e40;
        local_1 = _e38;
        local_2 = _e36;
        if (_e42 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e45 = global[_e42];
            let _e47 = (i32(_e45) * 3i);
            let _e50 = global_1.member_1[_e47];
            let _e52 = global_2[_e42];
            let _e58 = global_1.member_1[(_e47 + 1i)];
            let _e64 = global_1.member_1[(_e47 + 2i)];
            phi_329_ = (_e36 + (_e64 * _e52));
            phi_328_ = (_e38 + (_e58 * _e52));
            phi_327_ = (_e40 + (_e50 * _e52));
            phi_326_ = (_e42 + 1i);
        }
    }
    let _e69 = local;
    let _e71 = local_1;
    let _e73 = local_2;
    let _e76 = (mat4x4<f32>(_e30, _e31, _e32, _e33) * transpose(mat4x4<f32>(_e69, _e71, _e73, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e77 = global_7;
    let _e82 = (_e76 * vec4<f32>(_e77.x, _e77.y, _e77.z, 1f));
    let _e84 = _e76[0].xyz;
    let _e86 = _e76[1].xyz;
    let _e88 = _e76[2].xyz;
    let _e91 = cross(_e84, _e86);
    let _e97 = global_8.member_1;
    global_9.member = (_e97 * _e82);
    let _e102 = global_9.member[1u];
    global_9.member[1u] = -(_e102);
    global_10 = _e82.xyz;
    let _e105 = global_12;
    global_11 = ((mat3x3<f32>(cross(_e86, _e88), cross(_e88, _e84), _e91) * _e105) * select(1f, -1f, (dot(_e91, _e88) < 0f)));
    let _e108 = global_14;
    global_13 = _e108;
    let _e109 = global_16;
    global_15 = _e109;
    return;
}

@vertex 
fn main(@location(14) param: vec4<f32>, @location(15) param_1: vec4<f32>, @location(3) param_2: vec4<f32>, @location(4) param_3: vec4<f32>, @location(5) param_4: vec4<f32>, @location(6) param_5: vec4<f32>, @location(0) param_6: vec3<f32>, @location(1) param_7: vec3<f32>, @location(2) param_8: vec2<f32>, @location(11) param_9: vec4<f32>) -> VertexOutput {
    global = param;
    global_2 = param_1;
    global_3 = param_2;
    global_4 = param_3;
    global_5 = param_4;
    global_6 = param_5;
    global_7 = param_6;
    global_12 = param_7;
    global_14 = param_8;
    global_16 = param_9;
    function_();
    let _e27 = global_9.member.y;
    global_9.member.y = -(_e27);
    let _e29 = global_9.member;
    let _e30 = global_10;
    let _e31 = global_11;
    let _e32 = global_13;
    let _e33 = global_15;
    return VertexOutput(_e29, _e30, _e31, _e32, _e33);
}
