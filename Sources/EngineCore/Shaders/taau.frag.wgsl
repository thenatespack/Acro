// Generated from taau.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 7c6a34f0121a6bb5
// glsl-fnv1a64: 46f83127659db351

diagnostic(off, derivative_uniformity);

struct type_9 {
    member: vec2<f32>,
    member_1: vec2<f32>,
    member_2: vec2<f32>,
    member_3: vec2<f32>,
    member_4: vec2<i32>,
    member_5: vec2<i32>,
    member_6: f32,
    member_7: f32,
}

@group(2) @binding(12) 
var global: texture_2d<f32>;
@group(2) @binding(17) 
var global_1: sampler;
@group(3) @binding(0) 
var<uniform> global_2: type_9;
var<private> global_3: vec4<f32>;
@group(2) @binding(9) 
var global_4: texture_2d<f32>;
@group(2) @binding(10) 
var global_5: texture_2d<f32>;
@group(2) @binding(11) 
var global_6: texture_2d<f32>;
var<private> global_7: vec4<f32>;

fn function_() {
    var local: array<f32, 4>;
    var local_1: array<f32, 4>;
    var phi_805_: vec3<f32>;
    var phi_800_: vec3<f32>;
    var phi_795_: vec3<f32>;
    var phi_790_: vec3<f32>;
    var phi_784_: vec2<i32>;
    var phi_780_: vec3<f32>;
    var phi_779_: f32;
    var phi_778_: f32;
    var phi_777_: vec3<f32>;
    var phi_776_: i32;
    var phi_822_: f32;
    var phi_821_: f32;
    var phi_820_: vec3<f32>;
    var phi_819_: vec3<f32>;
    var phi_818_: vec3<f32>;
    var phi_817_: vec3<f32>;
    var phi_816_: f32;
    var phi_815_: vec3<f32>;
    var phi_814_: f32;
    var phi_813_: vec3<f32>;
    var phi_811_: i32;
    var phi_826_: vec2<i32>;
    var phi_823_: bool;
    var local_2: f32;
    var local_3: f32;
    var local_4: f32;
    var local_5: vec3<f32>;
    var local_6: f32;
    var local_7: f32;
    var local_8: f32;
    var local_9: f32;
    var local_10: vec3<f32>;
    var phi_781_: vec3<f32>;
    var local_11: f32;
    var local_12: vec2<i32>;
    var phi_362_: bool;
    var phi_370_: bool;
    var phi_806_: vec3<f32>;
    var phi_785_: i32;
    var phi_808_: vec3<f32>;
    var phi_807_: i32;
    var local_13: vec3<f32>;
    var local_14: vec3<f32>;
    var local_15: vec3<f32>;
    var local_16: vec3<f32>;
    var local_17: vec3<f32>;
    var local_18: vec3<f32>;
    var local_19: vec3<f32>;
    var local_20: vec3<f32>;
    var local_21: vec3<f32>;
    var local_22: vec3<f32>;
    var local_23: vec3<f32>;
    var local_24: vec3<f32>;
    var local_25: vec2<i32>;
    var local_26: vec3<f32>;
    var local_27: f32;
    var local_28: f32;
    var local_29: vec3<f32>;
    var local_30: f32;
    var local_31: f32;
    var local_32: vec3<f32>;
    var local_33: vec3<f32>;
    var local_34: vec3<f32>;
    var local_35: vec3<f32>;
    var local_36: f32;
    var local_37: vec3<f32>;
    var local_38: f32;
    var local_39: vec3<f32>;
    var local_40: vec2<i32>;
    var local_41: vec3<f32>;

    switch bitcast<i32>(0u) {
        default: {
            let _e49 = global_3;
            let _e50 = _e49.xy;
            let _e52 = global_2.member;
            let _e53 = (_e50 * _e52);
            let _e55 = global_2.member_2;
            let _e58 = vec2<i32>(floor((_e53 + _e55)));
            let _e64 = global_2.member_7;
            let _e65 = (_e64 > 0.5f);
            phi_805_ = vec3<f32>(-1000000000f, -1000000000f, -1000000000f);
            phi_800_ = vec3<f32>(1000000000f, 1000000000f, 1000000000f);
            phi_795_ = vec3<f32>(0f, 0f, 0f);
            phi_790_ = vec3<f32>(0f, 0f, 0f);
            phi_784_ = _e58;
            phi_780_ = vec3<f32>(0f, 0f, 0f);
            phi_779_ = 0f;
            phi_778_ = 0f;
            phi_777_ = vec3<f32>(0f, 0f, 0f);
            phi_776_ = -1i;
            phi_822_ = select(2f, -1f, _e65);
            loop {
                let _e68 = phi_805_;
                let _e70 = phi_800_;
                let _e72 = phi_795_;
                let _e74 = phi_790_;
                let _e76 = phi_784_;
                let _e78 = phi_780_;
                let _e80 = phi_779_;
                let _e82 = phi_778_;
                let _e84 = phi_777_;
                let _e86 = phi_776_;
                let _e88 = phi_822_;
                local_2 = _e82;
                local_3 = _e82;
                local_4 = _e82;
                local_5 = _e84;
                local_6 = _e80;
                local_7 = _e80;
                local_8 = _e80;
                local_9 = _e80;
                local_10 = _e78;
                local_11 = _e80;
                local_12 = _e76;
                local_14 = _e74;
                local_15 = _e72;
                local_16 = _e70;
                local_17 = _e68;
                if (_e86 <= 1i) {
                    phi_821_ = _e88;
                    phi_820_ = _e68;
                    phi_819_ = _e70;
                    phi_818_ = _e72;
                    phi_817_ = _e74;
                    phi_816_ = _e80;
                    phi_815_ = _e78;
                    phi_814_ = _e82;
                    phi_813_ = _e84;
                    phi_811_ = -1i;
                    phi_826_ = _e76;
                    loop {
                        let _e91 = phi_821_;
                        let _e93 = phi_820_;
                        let _e95 = phi_819_;
                        let _e97 = phi_818_;
                        let _e99 = phi_817_;
                        let _e101 = phi_816_;
                        let _e103 = phi_815_;
                        let _e105 = phi_814_;
                        let _e107 = phi_813_;
                        let _e109 = phi_811_;
                        let _e111 = phi_826_;
                        local_21 = _e93;
                        local_22 = _e95;
                        local_23 = _e97;
                        local_24 = _e99;
                        local_25 = _e111;
                        local_26 = _e103;
                        local_27 = _e101;
                        local_28 = _e105;
                        local_29 = _e107;
                        local_30 = _e91;
                        if (_e109 <= 1i) {
                            let _e116 = global_2.member_4;
                            let _e117 = clamp((_e58 + vec2<i32>(_e109, _e86)), vec2<i32>(0i, 0i), _e116);
                            let _e118 = textureLoad(global_4, _e117, 0i);
                            let _e120 = (_e118.x * 0.25f);
                            let _e122 = (_e118.y * 0.5f);
                            let _e125 = (_e118.z * 0.25f);
                            let _e131 = vec3<f32>(((_e120 + _e122) + _e125), (0.5f * (_e118.x - _e118.z)), ((_e122 - _e120) - _e125));
                            let _e135 = ((((vec2<f32>(_e58) + vec2<f32>(0.5f, 0.5f)) - _e55) - _e53) + vec2<f32>(f32(_e109), f32(_e86)));
                            let _e137 = global_2.member_1;
                            let _e138 = (_e135 * _e137);
                            let _e142 = max((1f - (dot(_e135, _e135) * 0.44444445f)), 0f);
                            let _e143 = (_e142 * _e142);
                            let _e146 = max((1f - dot(_e138, _e138)), 0f);
                            let _e147 = (_e146 * _e146);
                            let _e159 = textureLoad(global_5, _e117, 0i);
                            local_32 = max(_e93, _e131);
                            local_33 = min(_e95, _e131);
                            local_34 = (_e97 + (_e131 * _e131));
                            local_35 = (_e99 + _e131);
                            local_36 = (_e101 + _e147);
                            local_37 = (_e103 + (_e131 * _e147));
                            local_38 = (_e105 + _e143);
                            local_39 = (_e107 + (_e131 * _e143));
                            if _e65 {
                                phi_823_ = (_e159.x > _e91);
                            } else {
                                phi_823_ = (_e159.x < _e91);
                            }
                            let _e164 = phi_823_;
                            local_31 = select(_e91, _e159.x, _e164);
                            local_40 = select(_e111, _e117, vec2(_e164));
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e382 = local_31;
                            phi_821_ = _e382;
                            let _e385 = local_32;
                            phi_820_ = _e385;
                            let _e388 = local_33;
                            phi_819_ = _e388;
                            let _e391 = local_34;
                            phi_818_ = _e391;
                            let _e394 = local_35;
                            phi_817_ = _e394;
                            let _e397 = local_36;
                            phi_816_ = _e397;
                            let _e400 = local_37;
                            phi_815_ = _e400;
                            let _e403 = local_38;
                            phi_814_ = _e403;
                            let _e406 = local_39;
                            phi_813_ = _e406;
                            phi_811_ = (_e109 + 1i);
                            let _e410 = local_40;
                            phi_826_ = _e410;
                        }
                    }
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e351 = local_21;
                    phi_805_ = _e351;
                    let _e354 = local_22;
                    phi_800_ = _e354;
                    let _e357 = local_23;
                    phi_795_ = _e357;
                    let _e360 = local_24;
                    phi_790_ = _e360;
                    let _e363 = local_25;
                    phi_784_ = _e363;
                    let _e366 = local_26;
                    phi_780_ = _e366;
                    let _e369 = local_27;
                    phi_779_ = _e369;
                    let _e372 = local_28;
                    phi_778_ = _e372;
                    let _e375 = local_29;
                    phi_777_ = _e375;
                    phi_776_ = (_e86 + 1i);
                    let _e379 = local_30;
                    phi_822_ = _e379;
                }
            }
            let _e171 = local_2;
            let _e173 = local_3;
            let _e175 = local_4;
            let _e178 = local_5;
            let _e179 = (_e178 / vec3<f32>(_e171, _e173, _e175));
            let _e181 = local_6;
            if (_e181 > 0.0009765625f) {
                let _e184 = local_7;
                let _e186 = local_8;
                let _e188 = local_9;
                let _e191 = local_10;
                phi_781_ = (_e191 / vec3<f32>(_e184, _e186, _e188));
            } else {
                phi_781_ = _e179;
            }
            let _e194 = phi_781_;
            let _e196 = local_11;
            let _e197 = min(_e196, 1f);
            let _e199 = local_12;
            let _e200 = textureLoad(global_6, _e199, 0i);
            let _e203 = global_2.member_3;
            let _e205 = (_e50 + (_e200.xy * _e203));
            let _e207 = global_2.member_6;
            let _e208 = (_e207 < 0.5f);
            phi_362_ = _e208;
            if _e208 {
                phi_362_ = all((_e205 >= vec2<f32>(0f, 0f)));
            }
            let _e212 = phi_362_;
            phi_370_ = _e212;
            if _e212 {
                phi_370_ = all((_e205 <= _e203));
            }
            let _e216 = phi_370_;
            if !(_e216) {
                global_7 = vec4<f32>(((_e179.x + _e179.y) - _e179.z), (_e179.x + _e179.z), ((_e179.x - _e179.y) - _e179.z), _e197);
                break;
            }
            let _e227 = (_e205 - vec2<f32>(0.5f, 0.5f));
            let _e228 = floor(_e227);
            let _e229 = (_e227 - _e228);
            let _e232 = (_e229 * 0.5f);
            let _e236 = (_e229 * (vec2<f32>(-0.5f, -0.5f) + (_e229 * (vec2<f32>(1f, 1f) - _e232))));
            let _e237 = (_e229 * _e229);
            let _e238 = (_e229 * 1.5f);
            let _e241 = (vec2<f32>(1f, 1f) + (_e237 * (vec2<f32>(-2.5f, -2.5f) + _e238)));
            let _e245 = (_e229 * (vec2<f32>(0.5f, 0.5f) + (_e229 * (vec2<f32>(2f, 2f) - _e238))));
            let _e247 = (_e237 * (vec2<f32>(-0.5f, -0.5f) + _e232));
            local = array<f32, 4>(_e236.x, _e241.x, _e245.x, _e247.x);
            local_1 = array<f32, 4>(_e236.y, _e241.y, _e245.y, _e247.y);
            phi_806_ = vec3<f32>(0f, 0f, 0f);
            phi_785_ = 0i;
            loop {
                let _e259 = phi_806_;
                let _e261 = phi_785_;
                local_18 = _e259;
                local_19 = _e259;
                local_20 = _e259;
                if (_e261 < 4i) {
                    phi_808_ = vec3<f32>(0f, 0f, 0f);
                    phi_807_ = 0i;
                    loop {
                        let _e264 = phi_808_;
                        let _e266 = phi_807_;
                        local_13 = _e264;
                        if (_e266 < 4i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e271 = global_2.member_5;
                            let _e273 = textureLoad(global, clamp(((vec2<i32>(_e228) - vec2<i32>(1i, 1i)) + vec2<i32>(_e266, _e261)), vec2<i32>(0i, 0i), _e271), 0i);
                            let _e276 = local[_e266];
                            phi_808_ = (_e264 + (_e273.xyz * _e276));
                            phi_807_ = (_e266 + 1i);
                        }
                    }
                    let _e281 = local_1[_e261];
                    let _e283 = local_13;
                    local_41 = (_e259 + (_e283 * _e281));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e428 = local_41;
                    phi_806_ = _e428;
                    phi_785_ = (_e261 + 1i);
                }
            }
            let _e290 = global_2.member_5;
            let _e292 = textureLoad(global, clamp(vec2<i32>(floor(_e205)), vec2<i32>(0i, 0i), _e290), 0i);
            let _e295 = local_14;
            let _e296 = (_e295 * 0.11111111f);
            let _e298 = local_15;
            let _e304 = (sqrt(max(((_e298 * 0.11111111f) - (_e296 * _e296)), vec3<f32>(0f, 0f, 0f))) * 1.25f);
            let _e307 = local_16;
            let _e311 = local_17;
            let _e314 = local_18;
            let _e316 = (_e314.x * 0.25f);
            let _e318 = local_19;
            let _e320 = (_e318.y * 0.5f);
            let _e323 = local_20;
            let _e325 = (_e323.z * 0.25f);
            let _e334 = (min(_e292.w, 12f) + _e197);
            let _e338 = mix(clamp(vec3<f32>(((_e316 + _e320) + _e325), (0.5f * (_e314.x - _e323.z)), ((_e320 - _e316) - _e325)), max(_e307, (_e296 - _e304)), min(_e311, (_e296 + _e304))), _e194, vec3((_e197 / max(_e334, 0.0009765625f))));
            global_7 = vec4<f32>(((_e338.x + _e338.y) - _e338.z), (_e338.x + _e338.z), ((_e338.x - _e338.y) - _e338.z), min(_e334, 12f));
            break;
        }
    }
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_3 = param;
    function_();
    let _e3 = global_7;
    return _e3;
}
