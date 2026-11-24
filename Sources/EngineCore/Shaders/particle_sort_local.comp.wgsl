// Generated from particle_sort_local.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 128d9e944dd41860
// glsl-fnv1a64: 252276dafcf82af4

diagnostic(off, derivative_uniformity);

struct type_11 {
    member: array<vec2<u32>>,
}

struct type_15 {
    member: vec4<u32>,
}

var<private> global: u32;
var<workgroup> global_1: array<vec2<u32>, 2048>;
var<private> global_2: vec3<u32>;
@group(2) @binding(31) 
var<storage, read_write> global_3: type_11;
@group(3) @binding(0) 
var<uniform> global_4: type_15;

fn function_() {
    var phi_432_: u32;
    var phi_439_: u32;
    var phi_441_: u32;
    var phi_443_: u32;
    var phi_330_: bool;
    var phi_332_: bool;
    var phi_433_: u32;
    var phi_434_: u32;
    var phi_417_: bool;
    var phi_419_: bool;
    var phi_440_: u32;

    let _e18 = global_2[0u];
    let _e19 = (_e18 * 2048u);
    let _e20 = global;
    phi_432_ = 0u;
    loop {
        let _e22 = phi_432_;
        if (_e22 < 8u) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e24 = (256u * _e22);
            let _e30 = global_3.member[((_e19 + _e20) + _e24)];
            global_1[(_e20 + _e24)] = _e30;
            phi_432_ = (_e22 + bitcast<u32>(1i));
        }
    }
    workgroupBarrier();
    let _e36 = global_4.member[0u];
    if (_e36 == 0u) {
        phi_439_ = 2u;
        loop {
            let _e39 = phi_439_;
            if (_e39 <= 2048u) {
                phi_441_ = (_e39 >> bitcast<u32>(1i));
                loop {
                    let _e44 = phi_441_;
                    if (_e44 > 0u) {
                        phi_443_ = 0u;
                        loop {
                            let _e47 = phi_443_;
                            if (_e47 < 4u) {
                                let _e50 = (_e20 + (256u * _e47));
                                let _e55 = (((2u * _e44) * (_e50 / _e44)) + (_e50 % _e44));
                                let _e61 = global_1[(_e55 + _e44)];
                                let _e63 = global_1[_e55];
                                let _e66 = (_e61.x < _e63.x);
                                phi_332_ = _e66;
                                if !(_e66) {
                                    let _e68 = (_e61.x == _e63.x);
                                    phi_330_ = _e68;
                                    if _e68 {
                                        phi_330_ = (_e61.y < _e63.y);
                                    }
                                    let _e73 = phi_330_;
                                    phi_332_ = _e73;
                                }
                                let _e75 = phi_332_;
                                if (_e75 == (((_e19 + _e55) & _e39) == 0u)) {
                                    let _e77 = global_1[_e55];
                                    let _e78 = global_1[(_e55 + _e44)];
                                    global_1[_e55] = _e78;
                                    global_1[(_e55 + _e44)] = _e77;
                                }
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_443_ = (_e47 + bitcast<u32>(1i));
                            }
                        }
                        workgroupBarrier();
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_441_ = (_e44 >> bitcast<u32>(1i));
                    }
                }
                continue;
            } else {
                break;
            }
            continuing {
                phi_439_ = (_e39 << bitcast<u32>(1i));
            }
        }
    } else {
        phi_433_ = 1024u;
        loop {
            let _e86 = phi_433_;
            if (_e86 > 0u) {
                phi_434_ = 0u;
                loop {
                    let _e89 = phi_434_;
                    if (_e89 < 4u) {
                        let _e92 = (_e20 + (256u * _e89));
                        let _e97 = (((2u * _e86) * (_e92 / _e86)) + (_e92 % _e86));
                        let _e103 = global_1[(_e97 + _e86)];
                        let _e105 = global_1[_e97];
                        let _e108 = (_e103.x < _e105.x);
                        phi_419_ = _e108;
                        if !(_e108) {
                            let _e110 = (_e103.x == _e105.x);
                            phi_417_ = _e110;
                            if _e110 {
                                phi_417_ = (_e103.y < _e105.y);
                            }
                            let _e115 = phi_417_;
                            phi_419_ = _e115;
                        }
                        let _e117 = phi_419_;
                        if (_e117 == (((_e19 + _e97) & _e36) == 0u)) {
                            let _e119 = global_1[_e97];
                            let _e120 = global_1[(_e97 + _e86)];
                            global_1[_e97] = _e120;
                            global_1[(_e97 + _e86)] = _e119;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_434_ = (_e89 + bitcast<u32>(1i));
                    }
                }
                workgroupBarrier();
                continue;
            } else {
                break;
            }
            continuing {
                phi_433_ = (_e86 >> bitcast<u32>(1i));
            }
        }
    }
    phi_440_ = 0u;
    loop {
        let _e126 = phi_440_;
        if (_e126 < 8u) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e129 = (256u * _e126);
            let _e133 = global_1[(_e20 + _e129)];
            global_3.member[((_e19 + _e20) + _e129)] = _e133;
            phi_440_ = (_e126 + bitcast<u32>(1i));
        }
    }
    return;
}

@compute @workgroup_size(256, 1, 1) 
fn main(@builtin(local_invocation_index) param: u32, @builtin(workgroup_id) param_1: vec3<u32>) {
    global = param;
    global_2 = param_1;
    function_();
}
