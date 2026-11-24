// Generated from volumetric_fog.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 4d9d5b2d6d7a13d9
// glsl-fnv1a64: fa56cfd039d94239

diagnostic(off, derivative_uniformity);

struct type_11 {
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

struct type_25 {
    member: array<vec4<u32>, 1024>,
}

struct type_29 {
    member: array<vec4<f32>, 1024>,
}

struct type_32 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
}

@group(0) @binding(0) 
var<uniform> global: type_11;
@group(2) @binding(11) 
var global_1: texture_2d<f32>;
@group(2) @binding(17) 
var global_2: sampler;
@group(2) @binding(6) 
var<uniform> global_3: type_25;
@group(2) @binding(7) 
var<uniform> global_4: type_25;
@group(2) @binding(3) 
var<uniform> global_5: type_29;
@group(2) @binding(4) 
var<uniform> global_6: type_29;
@group(2) @binding(5) 
var<uniform> global_7: type_29;
var<private> global_8: vec4<f32>;
@group(2) @binding(9) 
var global_9: texture_2d<f32>;
@group(2) @binding(10) 
var global_10: texture_2d<f32>;
@group(3) @binding(0) 
var<uniform> global_11: type_32;
var<private> global_12: vec4<f32>;

fn function_() {
    var local: array<f32, 4>;
    var local_1: array<f32, 4>;
    var phi_1628_: bool;
    var phi_1629_: f32;
    var phi_808_: bool;
    var phi_1634_: f32;
    var phi_1631_: vec3<f32>;
    var phi_1630_: i32;
    var phi_1632_: f32;
    var phi_1635_: i32;
    var phi_990_: bool;
    var local_2: i32;
    var local_3: i32;
    var phi_1077_: bool;
    var phi_1084_: bool;
    var phi_1091_: bool;
    var local_4: i32;
    var local_5: i32;
    var local_6: i32;
    var phi_1637_: i32;
    var phi_1638_: f32;
    var local_7: i32;
    var local_8: i32;
    var local_9: vec4<f32>;
    var phi_1239_: bool;
    var phi_1246_: bool;
    var phi_1253_: bool;
    var phi_1644_: i32;
    var phi_1645_: f32;
    var phi_1646_: f32;
    var phi_1647_: f32;
    var phi_1648_: f32;
    var phi_1649_: f32;
    var phi_1437_: bool;
    var phi_1444_: bool;
    var phi_1451_: bool;
    var phi_1651_: vec3<f32>;
    var phi_1650_: u32;
    var phi_1652_: vec3<f32>;
    var phi_1658_: vec3<f32>;
    var local_10: vec3<f32>;
    var local_11: f32;
    var local_12: vec3<f32>;
    var local_13: vec3<f32>;

    let _e65 = global_8;
    let _e67 = vec2<i32>(_e65.xy);
    let _e68 = textureLoad(global_9, _e67, 0i);
    let _e70 = textureLoad(global_10, _e67, 0i);
    let _e72 = textureDimensions(global_9, 0i);
    let _e75 = vec2<f32>(_e67);
    let _e79 = ((((_e75 + vec2<f32>(0.5f, 0.5f)) / vec2<f32>(vec2<i32>(_e72))) * 2f) - vec2<f32>(1f, 1f));
    let _e81 = -(_e79.y);
    let _e83 = global.member_6;
    let _e84 = _e83.xyz;
    let _e86 = global_11.member;
    let _e89 = (_e86 * vec4<f32>(_e79.x, _e81, 0.5f, 1f));
    let _e95 = normalize(((_e89.xyz / vec3(_e89.w)) - _e84));
    let _e98 = global_11.member_1[2u];
    let _e101 = global_11.member_2[0u];
    if (_e101 > 0.5f) {
        phi_1628_ = (_e70.x <= 0f);
    } else {
        phi_1628_ = (_e70.x >= 1f);
    }
    let _e106 = phi_1628_;
    phi_1629_ = _e98;
    if !(_e106) {
        let _e109 = (_e86 * vec4<f32>(_e79.x, _e81, _e70.x, 1f));
        phi_1629_ = min(length(((_e109.xyz / vec3(_e109.w)) - _e84)), _e98);
    }
    let _e118 = phi_1629_;
    let _e121 = global_11.member_1[3u];
    let _e122 = i32(_e121);
    let _e124 = (_e118 / f32(_e122));
    let _e130 = global.member_5;
    let _e134 = global.member_4[3u];
    let _e137 = global.member_4;
    let _e143 = global_11.member_1[1u];
    let _e144 = (_e143 * _e143);
    let _e156 = global.member_5[3u];
    let _e160 = global_11.member_2[1u];
    let _e161 = (_e160 > 0.5f);
    phi_808_ = _e161;
    if _e161 {
        let _e164 = global.member_13[3u];
        phi_808_ = (_e164 > 0.5f);
    }
    let _e167 = phi_808_;
    phi_1634_ = 0f;
    phi_1631_ = vec3<f32>(0f, 0f, 0f);
    phi_1630_ = 0i;
    loop {
        let _e169 = phi_1634_;
        let _e171 = phi_1631_;
        let _e173 = phi_1630_;
        local_10 = _e171;
        if (_e173 < _e122) {
            let _e179 = (_e84 + (_e95 * ((f32(_e173) + fract((52.982918f * fract(dot(_e75, vec2<f32>(0.06711056f, 0.00583715f)))))) * _e124)));
            let _e183 = global.member_9[3u];
            if (_e183 == 0f) {
                let _e187 = global.member_7[3u];
                phi_1632_ = _e187;
            } else {
                let _e190 = global.member_7[3u];
                let _e194 = global.member_6[3u];
                phi_1632_ = (_e190 * exp(min((-(_e183) * (_e179.y - _e194)), 30f)));
            }
            let _e201 = phi_1632_;
            let _e202 = (_e201 * _e124);
            local_11 = (_e169 + _e202);
            if (_e156 > 0.5f) {
                switch bitcast<i32>(0u) {
                    default: {
                        let _e211 = global.member_21[0u];
                        let _e212 = i32(_e211);
                        let _e214 = global.member_20;
                        let _e219 = global.member_20[3u];
                        let _e220 = (dot(_e214.xyz, _e179) + _e219);
                        phi_1635_ = 0i;
                        loop {
                            let _e222 = phi_1635_;
                            local_2 = _e222;
                            local_3 = _e222;
                            local_4 = _e222;
                            local_5 = _e222;
                            local_6 = _e222;
                            local_7 = _e222;
                            local_8 = _e222;
                            let _e224 = (_e222 < (_e212 - 1i));
                            phi_990_ = _e224;
                            if _e224 {
                                let _e227 = global.member_16[_e222];
                                phi_990_ = (_e220 > _e227);
                            }
                            let _e230 = phi_990_;
                            if _e230 {
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                phi_1635_ = (_e222 + 1i);
                            }
                        }
                        let _e234 = local_2;
                        let _e236 = global.member_16[_e234];
                        if (_e220 > _e236) {
                            phi_1648_ = 1f;
                            break;
                        }
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e241 = local_3;
                                let _e243 = global.member_14[_e241];
                                let _e246 = vec4<f32>(_e179.x, _e179.y, _e179.z, 1f);
                                let _e247 = (_e243 * _e246);
                                let _e249 = (_e247.x < 0f);
                                phi_1077_ = _e249;
                                local_9 = _e246;
                                if !(_e249) {
                                    phi_1077_ = (_e247.x > 1f);
                                }
                                let _e253 = phi_1077_;
                                phi_1084_ = _e253;
                                if !(_e253) {
                                    phi_1084_ = (_e247.y < 0f);
                                }
                                let _e258 = phi_1084_;
                                phi_1091_ = _e258;
                                if !(_e258) {
                                    phi_1091_ = (_e247.y > 1f);
                                }
                                let _e263 = phi_1091_;
                                if _e263 {
                                    phi_1638_ = 1f;
                                    break;
                                }
                                let _e265 = global.member_22;
                                let _e267 = (vec2<f32>(1f, 1f) / _e265.xy);
                                let _e269 = local_4;
                                let _e273 = local_5;
                                let _e279 = global.member_23;
                                let _e280 = _e279.xy;
                                let _e281 = (vec2<f32>(f32((_e269 & 1i)), f32((_e273 >> bitcast<u32>(1i)))) * _e280);
                                let _e294 = local_6;
                                let _e296 = global.member_19[_e294];
                                let _e302 = (((_e281 + (_e247.xy * _e280)) * _e267) - vec2<f32>(0.5f, 0.5f));
                                let _e303 = floor(_e302);
                                let _e304 = (_e302 - _e303);
                                phi_1637_ = 0i;
                                loop {
                                    let _e306 = phi_1637_;
                                    if (_e306 < 4i) {
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e315 = textureLoad(global_1, clamp((vec2<i32>(_e303) + vec2<i32>((_e306 & 1i), (_e306 >> bitcast<u32>(1i)))), vec2<i32>(((_e281 * _e267) + vec2<f32>(0.5f, 0.5f))), (vec2<i32>((((_e281 + _e280) * _e267) + vec2<f32>(0.5f, 0.5f))) - vec2<i32>(1i, 1i))), 0i);
                                        local_1[_e306] = select(0f, 1f, ((min(_e247.z, 1f) - _e296) <= _e315.x));
                                        phi_1637_ = (_e306 + 1i);
                                    }
                                }
                                let _e322 = local_1[0i];
                                let _e324 = local_1[1i];
                                let _e328 = local_1[2i];
                                let _e330 = local_1[3i];
                                phi_1638_ = mix(mix(_e322, _e324, _e304.x), mix(_e328, _e330, _e304.x), _e304.y);
                                break;
                            }
                        }
                        let _e335 = phi_1638_;
                        let _e338 = local_7;
                        let _e340 = global.member_17[_e338];
                        phi_1647_ = _e335;
                        if (_e220 > _e340) {
                            let _e346 = local_8;
                            let _e347 = (_e346 + 1i);
                            if (_e347 < _e212) {
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e352 = global.member_14[_e347];
                                        let _e354 = local_9;
                                        let _e355 = (_e352 * _e354);
                                        let _e357 = (_e355.x < 0f);
                                        phi_1239_ = _e357;
                                        if !(_e357) {
                                            phi_1239_ = (_e355.x > 1f);
                                        }
                                        let _e361 = phi_1239_;
                                        phi_1246_ = _e361;
                                        if !(_e361) {
                                            phi_1246_ = (_e355.y < 0f);
                                        }
                                        let _e366 = phi_1246_;
                                        phi_1253_ = _e366;
                                        if !(_e366) {
                                            phi_1253_ = (_e355.y > 1f);
                                        }
                                        let _e371 = phi_1253_;
                                        if _e371 {
                                            phi_1645_ = 1f;
                                            break;
                                        }
                                        let _e373 = global.member_22;
                                        let _e375 = (vec2<f32>(1f, 1f) / _e373.xy);
                                        let _e383 = global.member_23;
                                        let _e384 = _e383.xy;
                                        let _e385 = (vec2<f32>(f32((_e347 & 1i)), f32((_e347 >> bitcast<u32>(1i)))) * _e384);
                                        let _e398 = global.member_19[_e347];
                                        let _e404 = (((_e385 + (_e355.xy * _e384)) * _e375) - vec2<f32>(0.5f, 0.5f));
                                        let _e405 = floor(_e404);
                                        let _e406 = (_e404 - _e405);
                                        phi_1644_ = 0i;
                                        loop {
                                            let _e408 = phi_1644_;
                                            if (_e408 < 4i) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e417 = textureLoad(global_1, clamp((vec2<i32>(_e405) + vec2<i32>((_e408 & 1i), (_e408 >> bitcast<u32>(1i)))), vec2<i32>(((_e385 * _e375) + vec2<f32>(0.5f, 0.5f))), (vec2<i32>((((_e385 + _e384) * _e375) + vec2<f32>(0.5f, 0.5f))) - vec2<i32>(1i, 1i))), 0i);
                                                local[_e408] = select(0f, 1f, ((min(_e355.z, 1f) - _e398) <= _e417.x));
                                                phi_1644_ = (_e408 + 1i);
                                            }
                                        }
                                        let _e424 = local[0i];
                                        let _e426 = local[1i];
                                        let _e430 = local[2i];
                                        let _e432 = local[3i];
                                        phi_1645_ = mix(mix(_e424, _e426, _e406.x), mix(_e430, _e432, _e406.x), _e406.y);
                                        break;
                                    }
                                }
                                let _e437 = phi_1645_;
                                phi_1646_ = _e437;
                            } else {
                                phi_1646_ = 1f;
                            }
                            let _e439 = phi_1646_;
                            phi_1647_ = mix(_e335, _e439, ((_e220 - _e340) / (_e236 - _e340)));
                        }
                        let _e442 = phi_1647_;
                        phi_1648_ = _e442;
                        break;
                    }
                }
                let _e444 = phi_1648_;
                phi_1649_ = _e444;
            } else {
                phi_1649_ = 1f;
            }
            let _e446 = phi_1649_;
            let _e447 = (((_e130.xyz * _e134) * ((1f - _e144) / pow(max(((1f + _e144) - ((2f * _e143) * dot(_e95, normalize(_e137.xyz)))), 0.0001f), 1.5f))) * _e446);
            phi_1658_ = _e447;
            if _e167 {
                switch bitcast<i32>(0u) {
                    default: {
                        let _e450 = global.member;
                        let _e454 = (_e450 * vec4<f32>(_e179.x, _e179.y, _e179.z, 1f));
                        if (_e454.w <= 0f) {
                            phi_1652_ = vec3<f32>(0f, 0f, 0f);
                            break;
                        }
                        let _e458 = global.member_11;
                        let _e463 = global.member_11[3u];
                        let _e468 = (((_e454.x / _e454.w) * 0.5f) + 0.5f);
                        let _e472 = (0.5f - ((_e454.y / _e454.w) * 0.5f));
                        let _e474 = (_e468 < 0f);
                        phi_1437_ = _e474;
                        if !(_e474) {
                            phi_1437_ = (_e468 >= 1f);
                        }
                        let _e478 = phi_1437_;
                        phi_1444_ = _e478;
                        if !(_e478) {
                            phi_1444_ = (_e472 < 0f);
                        }
                        let _e482 = phi_1444_;
                        phi_1451_ = _e482;
                        if !(_e482) {
                            phi_1451_ = (_e472 >= 1f);
                        }
                        let _e486 = phi_1451_;
                        if _e486 {
                            phi_1652_ = vec3<f32>(0f, 0f, 0f);
                            break;
                        }
                        let _e488 = global.member_13;
                        let _e489 = _e488.xy;
                        let _e493 = clamp(floor((vec2<f32>(_e468, _e472) * _e489)), vec2<f32>(0f, 0f), (_e489 - vec2<f32>(1f, 1f)));
                        let _e498 = global.member_12[2u];
                        let _e502 = global.member_12[3u];
                        let _e507 = global.member_13[2u];
                        let _e512 = global.member_13[1u];
                        let _e518 = global.member_13[0u];
                        let _e522 = u32(((((clamp(floor(((log2(max((dot(_e458.xyz, _e179) + _e463), 0.000001f)) * _e498) + _e502)), 0f, (_e507 - 1f)) * _e512) + _e493.y) * _e518) + _e493.x));
                        let _e529 = global_3.member[(_e522 >> bitcast<u32>(2i))][(_e522 & 3u)];
                        let _e530 = (_e529 & 65535u);
                        phi_1651_ = vec3<f32>(0f, 0f, 0f);
                        phi_1650_ = _e530;
                        loop {
                            let _e534 = phi_1651_;
                            let _e536 = phi_1650_;
                            local_13 = _e534;
                            if (_e536 < (_e530 + (_e529 >> bitcast<u32>(16i)))) {
                                continue;
                            } else {
                                break;
                            }
                            continuing {
                                let _e539 = (_e536 / 3u);
                                let _e546 = global_4.member[(_e539 >> bitcast<u32>(2i))][(_e539 & 3u)];
                                let _e552 = ((_e546 >> bitcast<u32>(((_e536 - (_e539 * 3u)) * 10u))) & 1023u);
                                let _e555 = global_5.member[_e552];
                                let _e557 = (_e555.xyz - _e179);
                                let _e558 = dot(_e557, _e557);
                                let _e560 = (_e558 * _e555.w);
                                let _e563 = clamp((1f - (_e560 * _e560)), 0f, 1f);
                                let _e569 = global_6.member[_e552];
                                let _e572 = global_7.member[_e552];
                                let _e580 = clamp(((dot(-((_e557 * inverseSqrt(max(_e558, 0.00000001f)))), _e572.xyz) * _e569.w) + _e572.w), 0f, 1f);
                                phi_1651_ = (_e534 + (_e569.xyz * ((((_e563 * _e563) * _e580) * _e580) / max(_e558, 0.25f))));
                                phi_1650_ = (_e536 + bitcast<u32>(1i));
                            }
                        }
                        let _e653 = local_13;
                        phi_1652_ = _e653;
                        break;
                    }
                }
                let _e592 = phi_1652_;
                phi_1658_ = (_e447 + _e592);
            }
            let _e595 = phi_1658_;
            local_12 = (_e171 + (_e595 * (_e202 * exp(-((_e169 + (0.5f * _e202)))))));
            continue;
        } else {
            break;
        }
        continuing {
            let _e616 = local_11;
            phi_1634_ = _e616;
            let _e619 = local_12;
            phi_1631_ = _e619;
            phi_1630_ = (_e173 + 1i);
        }
    }
    let _e602 = global_11.member_1[0u];
    let _e604 = local_10;
    let _e606 = (_e68.xyz + (_e604 * _e602));
    global_12 = vec4<f32>(_e606.x, _e606.y, _e606.z, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_8 = param;
    function_();
    let _e3 = global_12;
    return _e3;
}
