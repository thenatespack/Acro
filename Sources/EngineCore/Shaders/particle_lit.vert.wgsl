// Generated from particle_lit.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 86dab7c4c55cccfe
// glsl-fnv1a64: e72c8f15689d6942

diagnostic(off, derivative_uniformity);

struct type_16 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
    member_9: vec4<f32>,
    member_10: vec4<f32>,
    member_11: vec4<f32>,
    member_12: vec4<f32>,
    member_13: vec4<f32>,
    member_14: array<mat4x4<f32>, 4>,
    member_15: array<mat4x4<f32>, 8>,
    member_16: vec4<f32>,
    member_17: vec4<f32>,
    member_18: vec4<f32>,
    member_19: vec4<f32>,
    member_20: vec4<f32>,
    member_21: vec4<f32>,
    member_22: vec4<f32>,
    member_23: vec4<f32>,
    member_24: vec4<f32>,
    member_25: vec4<f32>,
    member_26: array<vec4<f32>, 8>,
    member_27: array<vec4<f32>, 4>,
    member_28: array<vec4<f32>, 4>,
    member_29: vec4<f32>,
}

struct type_28 {
    member: array<vec4<u32>, 1024>,
}

struct type_32 {
    member: array<vec4<f32>, 1024>,
}

struct type_34 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: array<vec4<f32>, 4>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
    member_9: vec4<f32>,
    member_10: vec4<f32>,
}

struct type_36 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
}

struct type_38 {
    member: array<type_36>,
}

struct type_41 {
    member: array<u32>,
}

struct type_53 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @location(0) member: vec2<f32>,
    @location(1) member_1: vec4<f32>,
    @location(2) member_2: vec4<f32>,
    @location(3) member_3: f32,
    @builtin(position) member_4: vec4<f32>,
}

@group(0) @binding(0) 
var<uniform> global: type_16;
@group(2) @binding(14) 
var global_1: texture_2d<f32>;
@group(2) @binding(17) 
var global_2: sampler;
@group(2) @binding(11) 
var global_3: texture_2d<f32>;
@group(2) @binding(6) 
var<uniform> global_4: type_28;
@group(2) @binding(7) 
var<uniform> global_5: type_28;
@group(2) @binding(3) 
var<uniform> global_6: type_32;
@group(2) @binding(4) 
var<uniform> global_7: type_32;
@group(2) @binding(5) 
var<uniform> global_8: type_32;
@group(2) @binding(2) 
var<uniform> global_9: type_34;
@group(2) @binding(24) 
var<storage> global_10: type_38;
@group(2) @binding(25) 
var<storage> global_11: type_41;
var<private> global_12: i32;
var<private> global_13: i32;
var<private> global_14: vec2<f32>;
var<private> global_15: vec4<f32>;
var<private> global_16: vec4<f32>;
var<private> global_17: f32;
var<private> global_18: type_53 = type_53(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());

fn function_() {
    var local: array<f32, 4>;
    var local_1: array<f32, 4>;
    var local_2: array<f32, 9>;
    var local_3: array<vec2<f32>, 6>;
    var phi_2433_: i32;
    var phi_2436_: f32;
    var phi_2437_: f32;
    var local_4: f32;
    var phi_2438_: vec3<f32>;
    var phi_2446_: f32;
    var phi_2444_: f32;
    var phi_2445_: f32;
    var phi_2443_: f32;
    var phi_2441_: vec3<f32>;
    var phi_2439_: vec3<f32>;
    var phi_2447_: i32;
    var phi_2450_: vec4<f32>;
    var phi_2451_: vec4<f32>;
    var local_5: vec4<f32>;
    var local_6: vec4<f32>;
    var local_7: vec4<f32>;
    var phi_2452_: f32;
    var phi_2454_: f32;
    var phi_2455_: f32;
    var phi_2458_: f32;
    var phi_2457_: f32;
    var phi_2470_: vec3<f32>;
    var phi_2472_: vec3<f32>;
    var phi_2471_: i32;
    var local_8: vec3<f32>;
    var phi_2473_: vec3<f32>;
    var phi_2474_: i32;
    var phi_1955_: bool;
    var local_9: i32;
    var local_10: i32;
    var phi_2042_: bool;
    var phi_2049_: bool;
    var phi_2056_: bool;
    var local_11: i32;
    var local_12: i32;
    var local_13: i32;
    var phi_2476_: i32;
    var phi_2477_: f32;
    var local_14: i32;
    var local_15: i32;
    var phi_2204_: bool;
    var phi_2211_: bool;
    var phi_2218_: bool;
    var phi_2483_: i32;
    var phi_2484_: f32;
    var phi_2485_: f32;
    var phi_2486_: f32;
    var phi_2487_: f32;
    var phi_2488_: f32;
    var phi_1593_: bool;
    var phi_2508_: vec3<f32>;
    var phi_2505_: u32;
    var phi_2506_: vec3<f32>;
    var local_16: f32;
    var local_17: vec4<f32>;
    var local_18: vec3<f32>;

    let _e91 = global_12;
    let _e94 = global_11.member[_e91];
    let _e98 = global_10.member[_e94].member;
    let _e100 = global_10.member[_e94].member_1;
    let _e102 = global_10.member[_e94].member_2;
    let _e103 = global_13;
    local_3 = array<vec2<f32>, 6>(vec2<f32>(-1f, -1f), vec2<f32>(1f, -1f), vec2<f32>(1f, 1f), vec2<f32>(-1f, -1f), vec2<f32>(1f, 1f), vec2<f32>(-1f, 1f));
    let _e105 = local_3[_e103];
    let _e110 = clamp((_e98.w / max(_e100.w, 0.00001f)), 0f, 1f);
    let _e114 = global_9.member_7[1u];
    let _e118 = global_9.member_4[0u];
    phi_2433_ = 1i;
    phi_2436_ = _e118;
    loop {
        let _e120 = phi_2433_;
        let _e122 = phi_2436_;
        local_4 = _e122;
        if (_e120 < 4i) {
            if (_e120 >= i32(_e114)) {
                break;
            }
            let _e125 = (_e120 - 1i);
            let _e128 = global_9.member_5[_e125];
            let _e131 = global_9.member_5[_e120];
            phi_2437_ = _e122;
            if (_e110 > _e128) {
                let _e135 = global_9.member_4[_e125];
                let _e138 = global_9.member_4[_e120];
                phi_2437_ = mix(_e135, _e138, clamp(((_e110 - _e128) / max((_e131 - _e128), 0.00001f)), 0f, 1f));
            }
            let _e146 = phi_2437_;
            local_16 = _e146;
            continue;
        } else {
            break;
        }
        continuing {
            phi_2433_ = (_e120 + 1i);
            let _e882 = local_16;
            phi_2436_ = _e882;
        }
    }
    let _e149 = local_4;
    let _e151 = _e98.xyz;
    let _e153 = global_9.member_1;
    let _e154 = _e153.xyz;
    let _e155 = (_e154 - _e151);
    if (dot(_e155, _e155) > 0.0000000001f) {
        phi_2438_ = normalize(_e155);
    } else {
        phi_2438_ = vec3<f32>(0f, 0f, 1f);
    }
    let _e160 = phi_2438_;
    let _e167 = normalize(cross(select(vec3<f32>(1f, 0f, 0f), vec3<f32>(0f, 1f, 0f), vec3((abs(_e160.y) < 0.999f))), _e160));
    let _e168 = cross(_e160, _e167);
    let _e169 = _e100.xyz;
    let _e172 = (_e169 - (_e160 * dot(_e169, _e160)));
    let _e173 = length(_e172);
    let _e176 = global_9.member_6[0u];
    if ((_e176 > 0f) && (_e173 > 0.0001f)) {
        let _e181 = (_e172 / vec3(_e173));
        let _e185 = global_9.member_6[3u];
        if (_e185 > 0.5f) {
            phi_2446_ = ((0.5f * _e176) * _e173);
            phi_2444_ = 1f;
        } else {
            phi_2446_ = 0f;
            phi_2444_ = (1f + (_e176 * _e173));
        }
        let _e192 = phi_2446_;
        let _e194 = phi_2444_;
        phi_2445_ = _e192;
        phi_2443_ = _e194;
        phi_2441_ = _e181;
        phi_2439_ = cross(_e181, _e160);
    } else {
        let _e198 = (_e102.y + (_e102.z * _e98.w));
        let _e199 = cos(_e198);
        let _e200 = sin(_e198);
        phi_2445_ = 0f;
        phi_2443_ = 1f;
        phi_2441_ = ((_e168 * _e199) - (_e167 * _e200));
        phi_2439_ = ((_e167 * _e199) + (_e168 * _e200));
    }
    let _e208 = phi_2445_;
    let _e210 = phi_2443_;
    let _e212 = phi_2441_;
    let _e214 = phi_2439_;
    let _e225 = ((_e151 + (((_e214 * _e105.x) + ((_e212 * _e105.y) * _e210)) * (_e102.x * _e149))) + (_e212 * (_e105.y * _e208)));
    let _e228 = global_9.member_7[0u];
    let _e232 = global_9.member_2[0i];
    phi_2447_ = 1i;
    phi_2450_ = _e232;
    loop {
        let _e234 = phi_2447_;
        let _e236 = phi_2450_;
        local_5 = _e236;
        local_6 = _e236;
        local_7 = _e236;
        if (_e234 < 4i) {
            if (_e234 >= i32(_e228)) {
                break;
            }
            let _e239 = (_e234 - 1i);
            let _e242 = global_9.member_3[_e239];
            let _e245 = global_9.member_3[_e234];
            phi_2451_ = _e236;
            if (_e110 > _e242) {
                let _e249 = global_9.member_2[_e239];
                let _e252 = global_9.member_2[_e234];
                phi_2451_ = mix(_e249, _e252, vec4(clamp(((_e110 - _e242) / max((_e245 - _e242), 0.00001f)), 0f, 1f)));
            }
            let _e261 = phi_2451_;
            local_17 = _e261;
            continue;
        } else {
            break;
        }
        continuing {
            phi_2447_ = (_e234 + 1i);
            let _e895 = local_17;
            phi_2450_ = _e895;
        }
    }
    let _e265 = global_9.member_6[1u];
    let _e269 = global_9.member_6[2u];
    let _e273 = local_5;
    let _e277 = (_e273.xyz * (_e265 * mix(1f, _e102.w, _e269)));
    let _e280 = local_7;
    let _e285 = vec4<f32>(_e277.x, _e280.y, _e280.z, _e280.w);
    let _e291 = vec4<f32>(_e285.x, _e277.y, _e285.z, _e285.w);
    global_14 = _e105;
    global_15 = vec4<f32>(_e291.x, _e291.y, _e277.z, _e291.w);
    global_16 = vec4<f32>(0f, 0f, 0f, 0f);
    global_17 = 0f;
    let _e300 = global_9.member_9[2u];
    if (_e300 > 0.5f) {
        let _e304 = global_9.member_8[2u];
        let _e307 = global_9.member_8[3u];
        let _e308 = (_e307 > 0f);
        if _e308 {
            phi_2452_ = (_e98.w * _e307);
        } else {
            phi_2452_ = (_e110 * _e304);
        }
        let _e312 = phi_2452_;
        let _e315 = global_9.member_9[0u];
        let _e316 = (_e315 > 0.5f);
        phi_2454_ = _e312;
        if _e316 {
            phi_2454_ = (_e312 + floor((_e102.w * _e304)));
        }
        let _e321 = phi_2454_;
        let _e324 = floor(_e321);
        let _e327 = global_9.member_9[1u];
        if (_e327 > 0.5f) {
            phi_2455_ = (_e321 - _e324);
        } else {
            phi_2455_ = 0f;
        }
        let _e331 = phi_2455_;
        global_17 = _e331;
        let _e332 = (_e324 + 1f);
        if select(_e308, _e316, !(_e308)) {
            phi_2458_ = (_e332 - (floor((_e332 / _e304)) * _e304));
            phi_2457_ = (_e324 - (floor((_e324 / _e304)) * _e304));
        } else {
            let _e341 = (_e304 - 1f);
            phi_2458_ = min(_e332, _e341);
            phi_2457_ = min(_e324, _e341);
        }
        let _e345 = phi_2458_;
        let _e347 = phi_2457_;
        let _e352 = vec2<f32>(((_e105.x * 0.5f) + 0.5f), (0.5f - (_e105.y * 0.5f)));
        let _e355 = global_9.member_8[0u];
        let _e365 = global_9.member_8;
        let _e366 = _e365.xy;
        let _e367 = ((vec2<f32>((_e347 - (floor((_e347 / _e355)) * _e355)), floor((_e347 / _e355))) + _e352) / _e366);
        let _e376 = ((vec2<f32>((_e345 - (floor((_e345 / _e355)) * _e355)), floor((_e345 / _e355))) + _e352) / _e366);
        global_16 = vec4<f32>(_e367.x, _e367.y, _e376.x, _e376.y);
    }
    let _e383 = global_9.member;
    let _e387 = vec4<f32>(_e225.x, _e225.y, _e225.z, 1f);
    global_18.member = (_e383 * _e387);
    let _e390 = (_e154 - _e225);
    if (dot(_e390, _e390) > 0.0000000001f) {
        phi_2470_ = normalize(_e390);
    } else {
        phi_2470_ = _e160;
    }
    let _e395 = phi_2470_;
    let _e398 = global_9.member_10[3u];
    let _e400 = global_18.member;
    switch bitcast<i32>(0u) {
        default: {
            let _e404 = global.member_29[0u];
            if (_e404 > 0.5f) {
                let _e407 = global.member_29;
                let _e414 = ((_e407.z * _e395.x) - (_e407.w * _e395.z));
                let _e418 = ((_e407.w * _e395.x) + (_e407.z * _e395.z));
                let _e422 = (1.092548f * _e414);
                local_2 = array<f32, 9>(0.282095f, (0.488603f * _e395.y), (0.488603f * _e418), (0.488603f * _e414), (_e422 * _e395.y), ((1.092548f * _e395.y) * _e418), (0.315392f * (((3f * _e418) * _e418) - 1f)), (_e422 * _e418), (0.546274f * ((_e414 * _e414) - (_e395.y * _e395.y))));
                phi_2472_ = vec3<f32>(0f, 0f, 0f);
                phi_2471_ = 0i;
                loop {
                    let _e437 = phi_2472_;
                    let _e439 = phi_2471_;
                    local_8 = _e437;
                    if (_e439 < 9i) {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e443 = textureLoad(global_1, (vec2<i32>(496i, 256i) + vec2<i32>(_e439, 0i)), 0i);
                        let _e446 = local_2[_e439];
                        phi_2472_ = (_e437 + (_e443.xyz * _e446));
                        phi_2471_ = (_e439 + 1i);
                    }
                }
                let _e451 = local_8;
                let _e455 = global.member_29[1u];
                phi_2473_ = (max(_e451, vec3<f32>(0f, 0f, 0f)) * _e455);
                break;
            }
            let _e458 = global.member_9;
            let _e461 = global.member_8;
            let _e470 = global.member_8[3u];
            phi_2473_ = (mix(_e458.xyz, _e461.xyz, vec3(((_e395.y * 0.5f) + 0.5f))) * _e470);
            break;
        }
    }
    let _e473 = phi_2473_;
    let _e475 = global.member_4;
    let _e480 = global.member_5[3u];
    if ((_e480 > 0.5f) && (_e398 > 0.5f)) {
        switch bitcast<i32>(0u) {
            default: {
                let _e486 = global.member_21[0u];
                let _e487 = i32(_e486);
                let _e489 = global.member_20;
                let _e494 = global.member_20[3u];
                let _e495 = (dot(_e489.xyz, _e225) + _e494);
                phi_2474_ = 0i;
                loop {
                    let _e497 = phi_2474_;
                    local_9 = _e497;
                    local_10 = _e497;
                    local_11 = _e497;
                    local_12 = _e497;
                    local_13 = _e497;
                    local_14 = _e497;
                    local_15 = _e497;
                    let _e499 = (_e497 < (_e487 - 1i));
                    phi_1955_ = _e499;
                    if _e499 {
                        let _e502 = global.member_16[_e497];
                        phi_1955_ = (_e495 > _e502);
                    }
                    let _e505 = phi_1955_;
                    if _e505 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_2474_ = (_e497 + 1i);
                    }
                }
                let _e509 = local_9;
                let _e511 = global.member_16[_e509];
                if (_e495 > _e511) {
                    phi_2487_ = 1f;
                    break;
                }
                switch bitcast<i32>(0u) {
                    default: {
                        let _e516 = local_10;
                        let _e518 = global.member_14[_e516];
                        let _e519 = (_e518 * _e387);
                        let _e521 = (_e519.x < 0f);
                        phi_2042_ = _e521;
                        if !(_e521) {
                            phi_2042_ = (_e519.x > 1f);
                        }
                        let _e525 = phi_2042_;
                        phi_2049_ = _e525;
                        if !(_e525) {
                            phi_2049_ = (_e519.y < 0f);
                        }
                        let _e530 = phi_2049_;
                        phi_2056_ = _e530;
                        if !(_e530) {
                            phi_2056_ = (_e519.y > 1f);
                        }
                        let _e535 = phi_2056_;
                        if _e535 {
                            phi_2477_ = 1f;
                            break;
                        }
                        let _e537 = global.member_22;
                        let _e539 = (vec2<f32>(1f, 1f) / _e537.xy);
                        let _e541 = local_11;
                        let _e545 = local_12;
                        let _e551 = global.member_23;
                        let _e552 = _e551.xy;
                        let _e553 = (vec2<f32>(f32((_e541 & 1i)), f32((_e545 >> bitcast<u32>(1i)))) * _e552);
                        let _e566 = local_13;
                        let _e568 = global.member_19[_e566];
                        let _e574 = (((_e553 + (_e519.xy * _e552)) * _e539) - vec2<f32>(0.5f, 0.5f));
                        let _e575 = floor(_e574);
                        let _e576 = (_e574 - _e575);
                        phi_2476_ = 0i;
                        loop {
                            let _e578 = phi_2476_;
                            if (_e578 < 4i) {
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                let _e587 = textureLoad(global_3, clamp((vec2<i32>(_e575) + vec2<i32>((_e578 & 1i), (_e578 >> bitcast<u32>(1i)))), vec2<i32>(((_e553 * _e539) + vec2<f32>(0.5f, 0.5f))), (vec2<i32>((((_e553 + _e552) * _e539) + vec2<f32>(0.5f, 0.5f))) - vec2<i32>(1i, 1i))), 0i);
                                local_1[_e578] = select(0f, 1f, ((min(_e519.z, 1f) - _e568) <= _e587.x));
                                phi_2476_ = (_e578 + 1i);
                            }
                        }
                        let _e594 = local_1[0i];
                        let _e596 = local_1[1i];
                        let _e600 = local_1[2i];
                        let _e602 = local_1[3i];
                        phi_2477_ = mix(mix(_e594, _e596, _e576.x), mix(_e600, _e602, _e576.x), _e576.y);
                        break;
                    }
                }
                let _e607 = phi_2477_;
                let _e610 = local_14;
                let _e612 = global.member_17[_e610];
                phi_2486_ = _e607;
                if (_e495 > _e612) {
                    let _e618 = local_15;
                    let _e619 = (_e618 + 1i);
                    if (_e619 < _e487) {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e624 = global.member_14[_e619];
                                let _e625 = (_e624 * _e387);
                                let _e627 = (_e625.x < 0f);
                                phi_2204_ = _e627;
                                if !(_e627) {
                                    phi_2204_ = (_e625.x > 1f);
                                }
                                let _e631 = phi_2204_;
                                phi_2211_ = _e631;
                                if !(_e631) {
                                    phi_2211_ = (_e625.y < 0f);
                                }
                                let _e636 = phi_2211_;
                                phi_2218_ = _e636;
                                if !(_e636) {
                                    phi_2218_ = (_e625.y > 1f);
                                }
                                let _e641 = phi_2218_;
                                if _e641 {
                                    phi_2484_ = 1f;
                                    break;
                                }
                                let _e643 = global.member_22;
                                let _e645 = (vec2<f32>(1f, 1f) / _e643.xy);
                                let _e653 = global.member_23;
                                let _e654 = _e653.xy;
                                let _e655 = (vec2<f32>(f32((_e619 & 1i)), f32((_e619 >> bitcast<u32>(1i)))) * _e654);
                                let _e668 = global.member_19[_e619];
                                let _e674 = (((_e655 + (_e625.xy * _e654)) * _e645) - vec2<f32>(0.5f, 0.5f));
                                let _e675 = floor(_e674);
                                let _e676 = (_e674 - _e675);
                                phi_2483_ = 0i;
                                loop {
                                    let _e678 = phi_2483_;
                                    if (_e678 < 4i) {
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e687 = textureLoad(global_3, clamp((vec2<i32>(_e675) + vec2<i32>((_e678 & 1i), (_e678 >> bitcast<u32>(1i)))), vec2<i32>(((_e655 * _e645) + vec2<f32>(0.5f, 0.5f))), (vec2<i32>((((_e655 + _e654) * _e645) + vec2<f32>(0.5f, 0.5f))) - vec2<i32>(1i, 1i))), 0i);
                                        local[_e678] = select(0f, 1f, ((min(_e625.z, 1f) - _e668) <= _e687.x));
                                        phi_2483_ = (_e678 + 1i);
                                    }
                                }
                                let _e694 = local[0i];
                                let _e696 = local[1i];
                                let _e700 = local[2i];
                                let _e702 = local[3i];
                                phi_2484_ = mix(mix(_e694, _e696, _e676.x), mix(_e700, _e702, _e676.x), _e676.y);
                                break;
                            }
                        }
                        let _e707 = phi_2484_;
                        phi_2485_ = _e707;
                    } else {
                        phi_2485_ = 1f;
                    }
                    let _e709 = phi_2485_;
                    phi_2486_ = mix(_e607, _e709, ((_e495 - _e612) / (_e511 - _e612)));
                }
                let _e712 = phi_2486_;
                phi_2487_ = _e712;
                break;
            }
        }
        let _e714 = phi_2487_;
        phi_2488_ = _e714;
    } else {
        phi_2488_ = 1f;
    }
    let _e716 = phi_2488_;
    let _e718 = global.member_5;
    let _e722 = global.member_4[3u];
    let _e729 = (_e473 + (((_e718.xyz * _e722) * ((dot(_e395, normalize(_e475.xyz)) * 0.5f) + 0.5f)) * _e716));
    let _e732 = global.member_13[3u];
    let _e733 = (_e732 > 0.5f);
    phi_1593_ = _e733;
    if _e733 {
        phi_1593_ = (_e400.w > 0f);
    }
    let _e737 = phi_1593_;
    phi_2506_ = _e729;
    if _e737 {
        let _e739 = global.member_11;
        let _e744 = global.member_11[3u];
        let _e757 = global.member_13;
        let _e758 = _e757.xy;
        let _e762 = clamp(floor((vec2<f32>((((_e400.x / _e400.w) * 0.5f) + 0.5f), (0.5f - ((_e400.y / _e400.w) * 0.5f))) * _e758)), vec2<f32>(0f, 0f), (_e758 - vec2<f32>(1f, 1f)));
        let _e767 = global.member_12[2u];
        let _e771 = global.member_12[3u];
        let _e776 = global.member_13[2u];
        let _e781 = global.member_13[1u];
        let _e787 = global.member_13[0u];
        let _e791 = u32(((((clamp(floor(((log2(max((dot(_e739.xyz, _e225) + _e744), 0.000001f)) * _e767) + _e771)), 0f, (_e776 - 1f)) * _e781) + _e762.y) * _e787) + _e762.x));
        let _e798 = global_4.member[(_e791 >> bitcast<u32>(2i))][(_e791 & 3u)];
        let _e799 = (_e798 & 65535u);
        phi_2508_ = _e729;
        phi_2505_ = _e799;
        loop {
            let _e803 = phi_2508_;
            let _e805 = phi_2505_;
            local_18 = _e803;
            if (_e805 < (_e799 + (_e798 >> bitcast<u32>(16i)))) {
                continue;
            } else {
                break;
            }
            continuing {
                let _e808 = (_e805 / 3u);
                let _e815 = global_5.member[(_e808 >> bitcast<u32>(2i))][(_e808 & 3u)];
                let _e821 = ((_e815 >> bitcast<u32>(((_e805 - (_e808 * 3u)) * 10u))) & 1023u);
                let _e824 = global_6.member[_e821];
                let _e826 = (_e824.xyz - _e225);
                let _e827 = dot(_e826, _e826);
                let _e829 = (_e827 * _e824.w);
                let _e832 = clamp((1f - (_e829 * _e829)), 0f, 1f);
                let _e835 = (_e826 * inverseSqrt(max(_e827, 0.00000001f)));
                let _e838 = global_7.member[_e821];
                let _e841 = global_8.member[_e821];
                let _e849 = clamp(((dot(-(_e835), _e841.xyz) * _e838.w) + _e841.w), 0f, 1f);
                phi_2508_ = (_e803 + ((_e838.xyz * ((((_e832 * _e832) * _e849) * _e849) / max(_e827, 0.0001f))) * ((dot(_e395, _e835) * 0.5f) + 0.5f)));
                phi_2505_ = (_e805 + bitcast<u32>(1i));
            }
        }
        let _e938 = local_18;
        phi_2506_ = _e938;
    }
    let _e865 = phi_2506_;
    let _e866 = global_15;
    let _e868 = (_e866.xyz * _e865);
    global_15[0u] = _e868.x;
    global_15[1u] = _e868.y;
    global_15[2u] = _e868.z;
    let _e877 = global_18.member[1u];
    global_18.member[1u] = -(_e877);
    return;
}

@vertex 
fn main(@builtin(instance_index) param: u32, @builtin(vertex_index) param_1: u32) -> VertexOutput {
    global_12 = i32(param);
    global_13 = i32(param_1);
    function_();
    let _e13 = global_18.member.y;
    global_18.member.y = -(_e13);
    let _e15 = global_14;
    let _e16 = global_15;
    let _e17 = global_16;
    let _e18 = global_17;
    let _e19 = global_18.member;
    return VertexOutput(_e15, _e16, _e17, _e18, _e19);
}
