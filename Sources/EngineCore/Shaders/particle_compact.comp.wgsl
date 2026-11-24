// Generated from particle_compact.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 1e13b3ecd3d730b5
// glsl-fnv1a64: bb641916ba5e9e44

diagnostic(off, derivative_uniformity);

struct type_6 {
    member: array<u32>,
}

struct type_18 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
    member_9: vec4<u32>,
    member_10: vec4<u32>,
    member_11: vec4<f32>,
    member_12: vec4<u32>,
    member_13: vec4<f32>,
    member_14: vec4<f32>,
    member_15: vec4<f32>,
    member_16: mat4x4<f32>,
    member_17: mat4x4<f32>,
    member_18: array<vec4<f32>, 8>,
}

struct type_19 {
    member: type_18,
}

struct type_22 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
}

struct type_24 {
    member: array<type_22>,
}

var<private> global: u32;
var<private> global_1: vec3<u32>;
var<private> global_2: vec3<u32>;
@group(2) @binding(25) 
var<storage, read_write> global_3: type_6;
var<workgroup> global_4: array<u32, 256>;
@group(2) @binding(2) 
var<uniform> global_5: type_19;
@group(2) @binding(24) 
var<storage> global_6: type_24;
@group(2) @binding(26) 
var<storage, read_write> global_7: type_6;

fn function_() {
    var phi_199_: u32;
    var phi_198_: u32;
    var local: u32;
    var phi_200_: u32;
    var phi_122_: bool;
    var phi_201_: u32;
    var phi_202_: u32;

    let _e26 = global;
    let _e28 = global_1[0u];
    let _e30 = global_2[0u];
    phi_199_ = 0u;
    phi_198_ = _e26;
    loop {
        let _e32 = phi_199_;
        let _e34 = phi_198_;
        local = _e32;
        if (_e34 < _e28) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e39 = global_3.member[(4u + _e34)];
            phi_199_ = (_e32 + _e39);
            phi_198_ = (_e34 + 256u);
        }
    }
    let _e44 = local;
    global_4[_e26] = _e44;
    workgroupBarrier();
    phi_200_ = 128u;
    loop {
        let _e46 = phi_200_;
        if (_e46 > 0u) {
            if (_e26 < _e46) {
                let _e51 = global_4[(_e26 + _e46)];
                let _e52 = global_4[_e26];
                global_4[_e26] = (_e52 + _e51);
            }
            workgroupBarrier();
            continue;
        } else {
            break;
        }
        continuing {
            phi_200_ = (_e46 >> bitcast<u32>(1i));
        }
    }
    let _e57 = global_4[0i];
    workgroupBarrier();
    let _e61 = global_5.member.member_10[0u];
    let _e62 = (_e30 < _e61);
    phi_122_ = _e62;
    if _e62 {
        let _e67 = global_6.member[_e30].member_1[3u];
        phi_122_ = (_e67 > 0f);
    }
    let _e70 = phi_122_;
    global_4[_e26] = select(0u, 1u, _e70);
    workgroupBarrier();
    phi_201_ = 1u;
    loop {
        let _e73 = phi_201_;
        if (_e73 < 256u) {
            if (_e26 >= _e73) {
                let _e78 = global_4[(_e26 - _e73)];
                phi_202_ = _e78;
            } else {
                phi_202_ = 0u;
            }
            let _e80 = phi_202_;
            workgroupBarrier();
            let _e81 = global_4[_e26];
            global_4[_e26] = (_e81 + _e80);
            workgroupBarrier();
            continue;
        } else {
            break;
        }
        continuing {
            phi_201_ = (_e73 << bitcast<u32>(1i));
        }
    }
    if _e70 {
        let _e85 = global_4[_e26];
        global_7.member[((_e57 + _e85) - 1u)] = _e30;
    }
    let _e93 = global_5.member.member_10[1u];
    if ((_e28 == (_e93 - 1u)) && (_e26 == 255u)) {
        global_3.member[0i] = 6u;
        let _e100 = global_4[_e26];
        global_3.member[1i] = (_e57 + _e100);
        global_3.member[2i] = 0u;
        global_3.member[3i] = 0u;
    }
    return;
}

@compute @workgroup_size(256, 1, 1) 
fn main(@builtin(local_invocation_index) param: u32, @builtin(workgroup_id) param_1: vec3<u32>, @builtin(global_invocation_id) param_2: vec3<u32>) {
    global = param;
    global_1 = param_1;
    global_2 = param_2;
    function_();
}
