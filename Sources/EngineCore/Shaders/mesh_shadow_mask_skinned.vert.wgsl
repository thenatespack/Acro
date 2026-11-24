// Generated from mesh_shadow_mask_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: d29357ae853f142b
// glsl-fnv1a64: 183c28eabc2e461c

diagnostic(off, derivative_uniformity);

struct type_10 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 384>,
    member_2: array<vec4<f32>, 384>,
}

struct type_13 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
}

struct type_19 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec2<f32>,
}

var<private> global: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_1: type_10;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_7: type_13;
var<private> global_8: vec3<f32>;
var<private> global_9: type_19 = type_19(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_10: vec2<f32>;
var<private> global_11: vec2<f32>;

fn function_() {
    var phi_262_: vec4<f32>;
    var phi_261_: vec4<f32>;
    var phi_260_: vec4<f32>;
    var phi_259_: i32;
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var local_2: vec4<f32>;

    let _e24 = global_3;
    let _e25 = global_4;
    let _e26 = global_5;
    let _e27 = global_6;
    phi_262_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_261_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_260_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_259_ = 0i;
    loop {
        let _e30 = phi_262_;
        let _e32 = phi_261_;
        let _e34 = phi_260_;
        let _e36 = phi_259_;
        local = _e34;
        local_1 = _e32;
        local_2 = _e30;
        if (_e36 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e39 = global[_e36];
            let _e41 = (i32(_e39) * 3i);
            let _e44 = global_1.member_1[_e41];
            let _e46 = global_2[_e36];
            let _e52 = global_1.member_1[(_e41 + 1i)];
            let _e58 = global_1.member_1[(_e41 + 2i)];
            phi_262_ = (_e30 + (_e58 * _e46));
            phi_261_ = (_e32 + (_e52 * _e46));
            phi_260_ = (_e34 + (_e44 * _e46));
            phi_259_ = (_e36 + 1i);
        }
    }
    let _e63 = local;
    let _e65 = local_1;
    let _e67 = local_2;
    let _e72 = global_7.member_1;
    let _e73 = global_8;
    global_9.member = (_e72 * ((mat4x4<f32>(_e24, _e25, _e26, _e27) * transpose(mat4x4<f32>(_e63, _e65, _e67, vec4<f32>(0f, 0f, 0f, 1f)))) * vec4<f32>(_e73.x, _e73.y, _e73.z, 1f)));
    let _e83 = global_9.member[1u];
    global_9.member[1u] = -(_e83);
    let _e85 = global_11;
    global_10 = _e85;
    return;
}

@vertex 
fn main(@location(14) param: vec4<f32>, @location(15) param_1: vec4<f32>, @location(3) param_2: vec4<f32>, @location(4) param_3: vec4<f32>, @location(5) param_4: vec4<f32>, @location(6) param_5: vec4<f32>, @location(0) param_6: vec3<f32>, @location(2) param_7: vec2<f32>) -> VertexOutput {
    global = param;
    global_2 = param_1;
    global_3 = param_2;
    global_4 = param_3;
    global_5 = param_4;
    global_6 = param_5;
    global_8 = param_6;
    global_11 = param_7;
    function_();
    let _e20 = global_9.member.y;
    global_9.member.y = -(_e20);
    let _e22 = global_9.member;
    let _e23 = global_10;
    return VertexOutput(_e22, _e23);
}
