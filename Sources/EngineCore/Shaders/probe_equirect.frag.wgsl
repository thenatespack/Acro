// Generated from probe_equirect.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 5915a9127fd36320
// glsl-fnv1a64: c68d18831a6a5220

diagnostic(off, derivative_uniformity);

struct type_10 {
    member: vec2<i32>,
    member_1: i32,
}

@group(2) @binding(9) 
var global: texture_2d<f32>;
@group(2) @binding(17) 
var global_1: sampler;
@group(2) @binding(10) 
var global_2: texture_2d<f32>;
@group(2) @binding(11) 
var global_3: texture_2d<f32>;
@group(2) @binding(12) 
var global_4: texture_2d<f32>;
@group(2) @binding(13) 
var global_5: texture_2d<f32>;
@group(2) @binding(14) 
var global_6: texture_2d<f32>;
var<private> global_7: vec4<f32>;
@group(3) @binding(0) 
var<uniform> global_8: type_10;
var<private> global_9: vec4<f32>;

fn function_() {
    var phi_186_: bool;
    var phi_730_: i32;
    var phi_728_: vec3<f32>;
    var phi_726_: vec3<f32>;
    var phi_729_: i32;
    var phi_727_: vec3<f32>;
    var phi_725_: vec3<f32>;
    var phi_735_: vec3<f32>;
    var phi_734_: vec3<f32>;
    var phi_733_: vec3<f32>;
    var phi_732_: vec3<f32>;
    var phi_731_: vec3<f32>;
    var phi_745_: vec3<f32>;
    var phi_744_: vec3<f32>;
    var phi_743_: vec3<f32>;
    var phi_742_: vec3<f32>;
    var phi_741_: vec3<f32>;
    var phi_755_: vec3<f32>;
    var phi_754_: vec3<f32>;
    var phi_753_: vec3<f32>;
    var phi_752_: vec3<f32>;
    var phi_751_: vec3<f32>;
    var phi_765_: vec3<f32>;
    var phi_764_: vec3<f32>;
    var phi_763_: vec3<f32>;
    var phi_762_: vec3<f32>;
    var phi_761_: vec3<f32>;

    let _e29 = global_7;
    let _e32 = global_8.member;
    let _e34 = (_e29.xy / vec2<f32>(_e32));
    let _e37 = ((_e34.x - 0.5f) * 6.2831855f);
    let _e39 = (_e34.y * 3.1415927f);
    let _e40 = sin(_e39);
    let _e42 = (_e40 * sin(_e37));
    let _e43 = cos(_e39);
    let _e46 = (-(_e40) * cos(_e37));
    let _e47 = vec3<f32>(_e42, _e43, _e46);
    let _e48 = abs(_e47);
    let _e51 = (_e48.x >= _e48.y);
    phi_186_ = _e51;
    if _e51 {
        phi_186_ = (_e48.x >= _e48.z);
    }
    let _e55 = phi_186_;
    if _e55 {
        let _e56 = (_e42 >= 0f);
        phi_729_ = select(1i, 0i, _e56);
        phi_727_ = vec3<f32>(0f, 1f, 0f);
        phi_725_ = vec3<f32>(select(-1f, 1f, _e56), 0f, 0f);
    } else {
        if (_e48.y >= _e48.z) {
            let _e62 = (_e43 >= 0f);
            let _e64 = select(-1f, 1f, _e62);
            phi_730_ = select(3i, 2i, _e62);
            phi_728_ = vec3<f32>(0f, 0f, _e64);
            phi_726_ = vec3<f32>(0f, _e64, 0f);
        } else {
            let _e67 = (_e46 >= 0f);
            phi_730_ = select(5i, 4i, _e67);
            phi_728_ = vec3<f32>(0f, 1f, 0f);
            phi_726_ = vec3<f32>(0f, 0f, select(-1f, 1f, _e67));
        }
        let _e72 = phi_730_;
        let _e74 = phi_728_;
        let _e76 = phi_726_;
        phi_729_ = _e72;
        phi_727_ = _e74;
        phi_725_ = _e76;
    }
    let _e78 = phi_729_;
    let _e80 = phi_727_;
    let _e82 = phi_725_;
    let _e84 = dot(_e47, _e82);
    let _e95 = global_8.member_1;
    let _e98 = ((vec2<f32>((0.5f + ((0.5f * dot(_e47, cross(_e82, _e80))) / _e84)), (0.5f - ((0.5f * dot(_e47, _e80)) / _e84))) * f32(_e95)) - vec2<f32>(0.5f, 0.5f));
    let _e99 = floor(_e98);
    let _e100 = (_e98 - _e99);
    let _e102 = vec2<i32>(_e99);
    let _e103 = vec2((_e95 - 1i));
    let _e104 = clamp(_e102, vec2<i32>(0i, 0i), _e103);
    let _e106 = clamp((_e102 + vec2<i32>(1i, 1i)), vec2<i32>(0i, 0i), _e103);
    let _e107 = (_e78 == 0i);
    if _e107 {
        let _e108 = textureLoad(global, _e104, 0i);
        phi_731_ = _e108.xyz;
    } else {
        if (_e78 == 1i) {
            let _e111 = textureLoad(global_2, _e104, 0i);
            phi_732_ = _e111.xyz;
        } else {
            if (_e78 == 2i) {
                let _e114 = textureLoad(global_3, _e104, 0i);
                phi_733_ = _e114.xyz;
            } else {
                if (_e78 == 3i) {
                    let _e117 = textureLoad(global_4, _e104, 0i);
                    phi_734_ = _e117.xyz;
                } else {
                    if (_e78 == 4i) {
                        let _e120 = textureLoad(global_5, _e104, 0i);
                        phi_735_ = _e120.xyz;
                    } else {
                        let _e122 = textureLoad(global_6, _e104, 0i);
                        phi_735_ = _e122.xyz;
                    }
                    let _e125 = phi_735_;
                    phi_734_ = _e125;
                }
                let _e127 = phi_734_;
                phi_733_ = _e127;
            }
            let _e129 = phi_733_;
            phi_732_ = _e129;
        }
        let _e131 = phi_732_;
        phi_731_ = _e131;
    }
    let _e133 = phi_731_;
    let _e139 = vec2<i32>(_e106.x, _e104.y);
    if _e107 {
        let _e140 = textureLoad(global, _e139, 0i);
        phi_741_ = _e140.xyz;
    } else {
        if (_e78 == 1i) {
            let _e143 = textureLoad(global_2, _e139, 0i);
            phi_742_ = _e143.xyz;
        } else {
            if (_e78 == 2i) {
                let _e146 = textureLoad(global_3, _e139, 0i);
                phi_743_ = _e146.xyz;
            } else {
                if (_e78 == 3i) {
                    let _e149 = textureLoad(global_4, _e139, 0i);
                    phi_744_ = _e149.xyz;
                } else {
                    if (_e78 == 4i) {
                        let _e152 = textureLoad(global_5, _e139, 0i);
                        phi_745_ = _e152.xyz;
                    } else {
                        let _e154 = textureLoad(global_6, _e139, 0i);
                        phi_745_ = _e154.xyz;
                    }
                    let _e157 = phi_745_;
                    phi_744_ = _e157;
                }
                let _e159 = phi_744_;
                phi_743_ = _e159;
            }
            let _e161 = phi_743_;
            phi_742_ = _e161;
        }
        let _e163 = phi_742_;
        phi_741_ = _e163;
    }
    let _e165 = phi_741_;
    let _e171 = vec2<i32>(_e104.x, _e106.y);
    if _e107 {
        let _e172 = textureLoad(global, _e171, 0i);
        phi_751_ = _e172.xyz;
    } else {
        if (_e78 == 1i) {
            let _e175 = textureLoad(global_2, _e171, 0i);
            phi_752_ = _e175.xyz;
        } else {
            if (_e78 == 2i) {
                let _e178 = textureLoad(global_3, _e171, 0i);
                phi_753_ = _e178.xyz;
            } else {
                if (_e78 == 3i) {
                    let _e181 = textureLoad(global_4, _e171, 0i);
                    phi_754_ = _e181.xyz;
                } else {
                    if (_e78 == 4i) {
                        let _e184 = textureLoad(global_5, _e171, 0i);
                        phi_755_ = _e184.xyz;
                    } else {
                        let _e186 = textureLoad(global_6, _e171, 0i);
                        phi_755_ = _e186.xyz;
                    }
                    let _e189 = phi_755_;
                    phi_754_ = _e189;
                }
                let _e191 = phi_754_;
                phi_753_ = _e191;
            }
            let _e193 = phi_753_;
            phi_752_ = _e193;
        }
        let _e195 = phi_752_;
        phi_751_ = _e195;
    }
    let _e197 = phi_751_;
    if _e107 {
        let _e201 = textureLoad(global, _e106, 0i);
        phi_761_ = _e201.xyz;
    } else {
        if (_e78 == 1i) {
            let _e204 = textureLoad(global_2, _e106, 0i);
            phi_762_ = _e204.xyz;
        } else {
            if (_e78 == 2i) {
                let _e207 = textureLoad(global_3, _e106, 0i);
                phi_763_ = _e207.xyz;
            } else {
                if (_e78 == 3i) {
                    let _e210 = textureLoad(global_4, _e106, 0i);
                    phi_764_ = _e210.xyz;
                } else {
                    if (_e78 == 4i) {
                        let _e213 = textureLoad(global_5, _e106, 0i);
                        phi_765_ = _e213.xyz;
                    } else {
                        let _e215 = textureLoad(global_6, _e106, 0i);
                        phi_765_ = _e215.xyz;
                    }
                    let _e218 = phi_765_;
                    phi_764_ = _e218;
                }
                let _e220 = phi_764_;
                phi_763_ = _e220;
            }
            let _e222 = phi_763_;
            phi_762_ = _e222;
        }
        let _e224 = phi_762_;
        phi_761_ = _e224;
    }
    let _e226 = phi_761_;
    let _e231 = vec3(_e100.x);
    let _e236 = mix(mix((_e133 / (vec3<f32>(1f, 1f, 1f) - min(_e133, vec3<f32>(0.995f, 0.995f, 0.995f)))), (_e165 / (vec3<f32>(1f, 1f, 1f) - min(_e165, vec3<f32>(0.995f, 0.995f, 0.995f)))), _e231), mix((_e197 / (vec3<f32>(1f, 1f, 1f) - min(_e197, vec3<f32>(0.995f, 0.995f, 0.995f)))), (_e226 / (vec3<f32>(1f, 1f, 1f) - min(_e226, vec3<f32>(0.995f, 0.995f, 0.995f)))), _e231), vec3(_e100.y));
    global_9 = vec4<f32>(_e236.x, _e236.y, _e236.z, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_7 = param;
    function_();
    let _e3 = global_9;
    return _e3;
}
