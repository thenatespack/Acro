// Generated from blit.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 7954f8fb45ade5b1
// glsl-fnv1a64: ae509c44d944b3bd

diagnostic(off, derivative_uniformity);

struct type_7 {
    member: vec2<f32>,
    member_1: vec2<i32>,
    member_2: vec2<i32>,
    member_3: vec2<i32>,
}

var<private> global: vec4<f32>;
@group(3) @binding(0) 
var<uniform> global_1: type_7;
var<private> global_2: vec4<f32>;
@group(1) @binding(1) 
var global_3: sampler;
@group(1) @binding(0) 
var global_4: texture_2d<f32>;
var<private> global_5: vec2<f32>;

fn function_() {
    var phi_218_: bool;
    var phi_668_: vec3<f32>;
    var phi_667_: i32;
    var phi_671_: i32;
    var phi_673_: vec3<f32>;
    var phi_672_: i32;
    var phi_681_: i32;
    var phi_683_: f32;
    var phi_676_: f32;
    var local: vec3<f32>;
    var phi_669_: f32;
    var phi_670_: f32;
    var local_1: vec3<f32>;
    var local_2: vec3<f32>;
    var local_3: vec3<f32>;

    switch bitcast<i32>(0u) {
        default: {
            let _e19 = global;
            let _e23 = global_1.member_1;
            let _e24 = (vec2<i32>(_e19.xy) - _e23);
            let _e26 = global_1.member_3;
            let _e28 = global_1.member_2;
            if all((_e26 == _e28)) {
                let _e31 = textureLoad(global_4, _e24, 0i);
                global_2 = vec4<f32>(_e31.x, _e31.y, _e31.z, 1f);
                break;
            }
            let _e38 = global_1.member_3[0u];
            let _e41 = global_1.member_2[0u];
            let _e42 = (_e38 <= _e41);
            phi_218_ = _e42;
            if _e42 {
                let _e45 = global_1.member_3[1u];
                let _e48 = global_1.member_2[1u];
                phi_218_ = (_e45 <= _e48);
            }
            let _e51 = phi_218_;
            if _e51 {
                let _e52 = global_5;
                let _e53 = textureSample(global_4, global_3, _e52);
                global_2 = vec4<f32>(_e53.x, _e53.y, _e53.z, 1f);
                break;
            }
            let _e59 = (_e24.x * _e38);
            let _e60 = (_e59 + _e38);
            let _e61 = (_e59 / _e41);
            let _e65 = ((((_e60 - 1i) / _e41) - _e61) + 1i);
            let _e66 = (_e65 > 8i);
            let _e71 = global_1.member_3[1u];
            let _e74 = global_1.member_2[1u];
            let _e75 = (_e24.y * _e71);
            let _e76 = (_e75 + _e71);
            let _e77 = (_e75 / _e74);
            let _e81 = ((((_e76 - 1i) / _e74) - _e77) + 1i);
            let _e82 = (_e81 > 8i);
            phi_668_ = vec3<f32>(0f, 0f, 0f);
            phi_667_ = 0i;
            loop {
                let _e85 = phi_668_;
                let _e87 = phi_667_;
                local_1 = _e85;
                if (_e87 < select(_e81, 4i, _e82)) {
                    if _e82 {
                        phi_671_ = ((_e75 + ((((2i * _e87) + 1i) * _e71) / 8i)) / _e74);
                    } else {
                        phi_671_ = (_e77 + _e87);
                    }
                    let _e97 = phi_671_;
                    phi_673_ = vec3<f32>(0f, 0f, 0f);
                    phi_672_ = 0i;
                    loop {
                        let _e99 = phi_673_;
                        let _e101 = phi_672_;
                        local = _e99;
                        if (_e101 < select(_e65, 4i, _e66)) {
                            if _e66 {
                                phi_681_ = ((_e59 + ((((2i * _e101) + 1i) * _e38) / 8i)) / _e41);
                            } else {
                                phi_681_ = (_e61 + _e101);
                            }
                            let _e111 = phi_681_;
                            let _e113 = textureLoad(global_4, vec2<i32>(_e111, _e97), 0i);
                            switch bitcast<i32>(0u) {
                                default: {
                                    if _e66 {
                                        phi_683_ = 1f;
                                        break;
                                    }
                                    let _e116 = (_e61 + _e101);
                                    phi_683_ = f32((min(_e60, ((_e116 + 1i) * _e41)) - max(_e59, (_e116 * _e41))));
                                    break;
                                }
                            }
                            let _e125 = phi_683_;
                            local_3 = fma(_e113.xyz, vec3(_e125), _e99);
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e168 = local_3;
                            phi_673_ = _e168;
                            phi_672_ = (_e101 + 1i);
                        }
                    }
                    switch bitcast<i32>(0u) {
                        default: {
                            if _e82 {
                                phi_676_ = 1f;
                                break;
                            }
                            let _e130 = (_e77 + _e87);
                            phi_676_ = f32((min(_e76, ((_e130 + 1i) * _e74)) - max(_e75, (_e130 * _e74))));
                            break;
                        }
                    }
                    let _e139 = phi_676_;
                    let _e142 = local;
                    local_2 = fma(_e142, vec3(_e139), _e85);
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e163 = local_2;
                    phi_668_ = _e163;
                    phi_667_ = (_e87 + 1i);
                }
            }
            if _e66 {
                phi_669_ = 4f;
            } else {
                phi_669_ = f32(_e38);
            }
            let _e147 = phi_669_;
            if _e82 {
                phi_670_ = 4f;
            } else {
                phi_670_ = f32(_e71);
            }
            let _e150 = phi_670_;
            let _e154 = local_1;
            let _e155 = (_e154 / vec3((_e147 * _e150)));
            global_2 = vec4<f32>(_e155.x, _e155.y, _e155.z, 1f);
            break;
        }
    }
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>, @location(0) param_1: vec2<f32>) -> @location(0) vec4<f32> {
    global = param;
    global_5 = param_1;
    function_();
    let _e5 = global_2;
    return _e5;
}
