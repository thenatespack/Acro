// Generated from outline_composite.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 93b75bea5b58fb78
// glsl-fnv1a64: 1c1fcfd816ee96c5

diagnostic(off, derivative_uniformity);

struct type_11 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<i32>,
}

var<private> global: vec4<f32>;
@group(2) @binding(9) 
var global_1: texture_2d<f32>;
@group(2) @binding(17) 
var global_2: sampler;
@group(3) @binding(0) 
var<uniform> global_3: type_11;
var<private> global_4: vec4<f32>;

fn function_() {
    var phi_236_: f32;
    var phi_235_: f32;
    var phi_234_: f32;
    var phi_233_: i32;
    var phi_258_: f32;
    var phi_253_: f32;
    var phi_249_: f32;
    var phi_238_: i32;
    var phi_96_: bool;
    var phi_107_: bool;
    var phi_116_: bool;
    var phi_270_: f32;
    var phi_272_: f32;
    var phi_271_: f32;
    var phi_268_: f32;
    var phi_265_: f32;
    var local: f32;
    var local_1: f32;
    var local_2: f32;
    var local_3: f32;
    var phi_237_: vec4<f32>;
    var local_4: f32;
    var local_5: f32;
    var local_6: f32;

    let _e16 = global;
    let _e18 = vec2<i32>(_e16.xy);
    let _e19 = textureLoad(global_1, _e18, 0i);
    if (_e19.x > 0.5f) {
        discard;
    }
    let _e24 = global_3.member_2[2u];
    let _e25 = i32(_e24);
    let _e26 = -(_e25);
    phi_236_ = 1000000000f;
    phi_235_ = 1000000000f;
    phi_234_ = 1000000000f;
    phi_233_ = _e26;
    loop {
        let _e28 = phi_236_;
        let _e30 = phi_235_;
        let _e32 = phi_234_;
        let _e34 = phi_233_;
        local = _e32;
        local_1 = _e30;
        local_2 = _e28;
        local_3 = _e30;
        if (_e34 <= _e25) {
            phi_258_ = _e28;
            phi_253_ = _e32;
            phi_249_ = _e30;
            phi_238_ = _e26;
            loop {
                let _e37 = phi_258_;
                let _e39 = phi_253_;
                let _e41 = phi_249_;
                let _e43 = phi_238_;
                local_4 = _e37;
                local_5 = _e41;
                local_6 = _e39;
                if (_e43 <= _e25) {
                    let _e46 = (_e18 + vec2<i32>(_e43, _e34));
                    let _e48 = (_e46.x < 0i);
                    phi_96_ = _e48;
                    if !(_e48) {
                        phi_96_ = (_e46.y < 0i);
                    }
                    let _e53 = phi_96_;
                    phi_107_ = _e53;
                    if !(_e53) {
                        let _e57 = global_3.member_3[0u];
                        phi_107_ = (_e46.x > _e57);
                    }
                    let _e60 = phi_107_;
                    phi_116_ = _e60;
                    if !(_e60) {
                        let _e65 = global_3.member_3[1u];
                        phi_116_ = (_e46.y > _e65);
                    }
                    let _e68 = phi_116_;
                    if _e68 {
                        phi_271_ = _e37;
                        phi_268_ = _e39;
                        phi_265_ = _e41;
                        continue;
                    }
                    let _e69 = textureLoad(global_1, _e46, 0i);
                    if (_e69.x < 0.5f) {
                        phi_271_ = _e37;
                        phi_268_ = _e39;
                        phi_265_ = _e41;
                        continue;
                    }
                    let _e76 = sqrt(f32(((_e43 * _e43) + (_e34 * _e34))));
                    phi_270_ = _e39;
                    if (_e69.y > 0.5f) {
                        phi_270_ = min(_e39, _e76);
                    }
                    let _e82 = phi_270_;
                    phi_272_ = _e37;
                    if (_e69.z > 0.5f) {
                        phi_272_ = min(_e37, _e76);
                    }
                    let _e87 = phi_272_;
                    phi_271_ = _e87;
                    phi_268_ = _e82;
                    phi_265_ = min(_e41, _e76);
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e89 = phi_271_;
                    let _e91 = phi_268_;
                    let _e93 = phi_265_;
                    phi_258_ = _e89;
                    phi_253_ = _e91;
                    phi_249_ = _e93;
                    phi_238_ = (_e43 + 1i);
                }
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e133 = local_4;
            phi_236_ = _e133;
            let _e136 = local_5;
            phi_235_ = _e136;
            let _e139 = local_6;
            phi_234_ = _e139;
            phi_233_ = (_e34 + 1i);
        }
    }
    let _e98 = global_3.member_2[0u];
    let _e99 = (_e98 + 1f);
    let _e101 = local;
    let _e105 = local_1;
    let _e110 = global_3.member_2[1u];
    let _e112 = max(clamp((_e99 - _e101), 0f, 1f), (clamp((_e99 - _e105), 0f, 1f) * _e110));
    if (_e112 <= 0f) {
        discard;
    }
    let _e115 = local_2;
    let _e117 = local_3;
    if (_e115 <= _e117) {
        let _e120 = global_3.member;
        phi_237_ = _e120;
    } else {
        let _e122 = global_3.member_1;
        phi_237_ = _e122;
    }
    let _e124 = phi_237_;
    global_4 = vec4<f32>(_e124.x, _e124.y, _e124.z, (_e124.w * _e112));
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global = param;
    function_();
    let _e3 = global_4;
    return _e3;
}
