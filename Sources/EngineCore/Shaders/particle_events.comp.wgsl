// Generated from particle_events.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: b29620524b430bb7
// glsl-fnv1a64: 38067ac9133ddbca

diagnostic(off, derivative_uniformity);

struct type_6 {
    member: array<u32>,
}

struct type_10 {
    member: vec4<u32>,
    member_1: vec4<u32>,
}

struct type_19 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
}

struct type_21 {
    member: array<type_19>,
}

struct type_25 {
    member: array<vec4<f32>>,
}

var<private> global: u32;
var<private> global_1: vec3<u32>;
var<private> global_2: vec3<u32>;
@group(2) @binding(25) 
var<storage> global_3: type_6;
@group(3) @binding(0) 
var<uniform> global_4: type_10;
var<workgroup> global_5: array<u32, 256>;
@group(2) @binding(27) 
var<storage> global_6: type_6;
@group(2) @binding(24) 
var<storage> global_7: type_21;
@group(2) @binding(28) 
var<storage, read_write> global_8: type_25;
@group(2) @binding(29) 
var<storage, read_write> global_9: type_6;

fn function_() {
    var phi_291_: u32;
    var phi_290_: u32;
    var local: u32;
    var phi_292_: u32;
    var phi_116_: bool;
    var phi_293_: u32;
    var phi_294_: u32;
    var phi_167_: bool;

    let _e28 = global;
    let _e30 = global_1[0u];
    let _e32 = global_2[0u];
    phi_291_ = 0u;
    phi_290_ = _e28;
    loop {
        let _e34 = phi_291_;
        let _e36 = phi_290_;
        local = _e34;
        if (_e36 < _e30) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e40 = global_4.member[3u];
            let _e44 = global_3.member[(_e40 + _e36)];
            phi_291_ = (_e34 + _e44);
            phi_290_ = (_e36 + 256u);
        }
    }
    let _e49 = local;
    global_5[_e28] = _e49;
    workgroupBarrier();
    phi_292_ = 128u;
    loop {
        let _e51 = phi_292_;
        if (_e51 > 0u) {
            if (_e28 < _e51) {
                let _e56 = global_5[(_e28 + _e51)];
                let _e57 = global_5[_e28];
                global_5[_e28] = (_e57 + _e56);
            }
            workgroupBarrier();
            continue;
        } else {
            break;
        }
        continuing {
            phi_292_ = (_e51 >> bitcast<u32>(1i));
        }
    }
    let _e62 = global_5[0i];
    workgroupBarrier();
    let _e65 = global_4.member[0u];
    let _e66 = (_e32 < _e65);
    phi_116_ = _e66;
    if _e66 {
        let _e69 = global_6.member[_e32];
        let _e72 = global_4.member[2u];
        phi_116_ = ((_e69 & _e72) != 0u);
    }
    let _e76 = phi_116_;
    global_5[_e28] = select(0u, 1u, _e76);
    workgroupBarrier();
    phi_293_ = 1u;
    loop {
        let _e79 = phi_293_;
        if (_e79 < 256u) {
            if (_e28 >= _e79) {
                let _e84 = global_5[(_e28 - _e79)];
                phi_294_ = _e84;
            } else {
                phi_294_ = 0u;
            }
            let _e86 = phi_294_;
            workgroupBarrier();
            let _e87 = global_5[_e28];
            global_5[_e28] = (_e87 + _e86);
            workgroupBarrier();
            continue;
        } else {
            break;
        }
        continuing {
            phi_293_ = (_e79 << bitcast<u32>(1i));
        }
    }
    let _e91 = global_5[_e28];
    let _e93 = ((_e62 + _e91) - 1u);
    phi_167_ = _e76;
    if _e76 {
        let _e96 = global_4.member_1[0u];
        phi_167_ = (_e93 < _e96);
    }
    let _e99 = phi_167_;
    if _e99 {
        let _e103 = global_7.member[_e32].member;
        let _e105 = global_7.member[_e32].member_1;
        let _e106 = (2u * _e93);
        global_8.member[_e106] = vec4<f32>(_e103.x, _e103.y, _e103.z, 0f);
        global_8.member[(_e106 + 1u)] = vec4<f32>(_e105.x, _e105.y, _e105.z, 0f);
    }
    let _e122 = global_4.member[1u];
    if ((_e30 == (_e122 - 1u)) && (_e28 == 255u)) {
        let _e127 = global_5[_e28];
        let _e131 = global_4.member_1[0u];
        let _e135 = global_4.member_1[1u];
        let _e139 = global_4.member_1[2u];
        let _e140 = min((min((_e62 + _e127), _e131) * _e135), _e139);
        let _e143 = global_9.member[7i];
        global_9.member[0i] = ((_e140 + 255u) / 256u);
        global_9.member[1i] = 1u;
        global_9.member[2i] = 1u;
        global_9.member[4i] = _e143;
        global_9.member[5i] = _e140;
        let _e158 = global_9.member[8i];
        global_9.member[6i] = _e158;
        global_9.member[7i] = ((_e143 + _e140) % _e139);
        let _e163 = global_9.member[8i];
        global_9.member[8i] = (_e163 + _e140);
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
