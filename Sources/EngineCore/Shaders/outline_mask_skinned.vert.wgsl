// Generated from outline_mask_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: f2ee3bc3241f131c
// glsl-fnv1a64: f0de2dcd52e191e9

diagnostic(off, derivative_uniformity);

struct type_10 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 384>,
    member_2: array<vec4<f32>, 384>,
}

struct type_13 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
}

struct type_19 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

var<private> global: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_1: type_10;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;
@group(3) @binding(0) 
var<uniform> global_7: type_13;
var<private> global_8: vec3<f32>;
var<private> global_9: type_19 = type_19(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());

fn function_() {
    var phi_256_: vec4<f32>;
    var phi_255_: vec4<f32>;
    var phi_254_: vec4<f32>;
    var phi_253_: i32;
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var local_2: vec4<f32>;

    let _e22 = global_3;
    let _e23 = global_4;
    let _e24 = global_5;
    let _e25 = global_6;
    phi_256_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_255_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_254_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_253_ = 0i;
    loop {
        let _e28 = phi_256_;
        let _e30 = phi_255_;
        let _e32 = phi_254_;
        let _e34 = phi_253_;
        local = _e32;
        local_1 = _e30;
        local_2 = _e28;
        if (_e34 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e37 = global[_e34];
            let _e39 = (i32(_e37) * 3i);
            let _e42 = global_1.member_1[_e39];
            let _e44 = global_2[_e34];
            let _e50 = global_1.member_1[(_e39 + 1i)];
            let _e56 = global_1.member_1[(_e39 + 2i)];
            phi_256_ = (_e28 + (_e56 * _e44));
            phi_255_ = (_e30 + (_e50 * _e44));
            phi_254_ = (_e32 + (_e42 * _e44));
            phi_253_ = (_e34 + 1i);
        }
    }
    let _e61 = local;
    let _e63 = local_1;
    let _e65 = local_2;
    let _e70 = global_7.member;
    let _e71 = global_8;
    global_9.member = (_e70 * ((mat4x4<f32>(_e22, _e23, _e24, _e25) * transpose(mat4x4<f32>(_e61, _e63, _e65, vec4<f32>(0f, 0f, 0f, 1f)))) * vec4<f32>(_e71.x, _e71.y, _e71.z, 1f)));
    let _e81 = global_9.member[1u];
    global_9.member[1u] = -(_e81);
    return;
}

@vertex 
fn main(@location(14) param: vec4<f32>, @location(15) param_1: vec4<f32>, @location(3) param_2: vec4<f32>, @location(4) param_3: vec4<f32>, @location(5) param_4: vec4<f32>, @location(6) param_5: vec4<f32>, @location(0) param_6: vec3<f32>) -> @builtin(position) vec4<f32> {
    global = param;
    global_2 = param_1;
    global_3 = param_2;
    global_4 = param_3;
    global_5 = param_4;
    global_6 = param_5;
    global_8 = param_6;
    function_();
    let _e17 = global_9.member.y;
    global_9.member.y = -(_e17);
    let _e19 = global_9.member;
    return _e19;
}
