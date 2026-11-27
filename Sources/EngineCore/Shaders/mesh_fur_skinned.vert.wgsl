// Generated from mesh_fur_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 1f4f9fe8aceb91f6
// glsl-fnv1a64: b04aa777f9f00a8c

diagnostic(off, derivative_uniformity);

struct type_12 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 8>,
    member_2: array<vec4<f32>, 128>,
    member_3: array<vec4<f32>, 384>,
    member_4: array<vec4<f32>, 384>,
}

struct type_20 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
}

struct type_24 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(8) member_1: vec4<f32>,
    @location(2) member_2: vec2<f32>,
    @location(4) member_3: vec3<f32>,
    @location(10) member_4: vec3<f32>,
    @location(0) member_5: vec3<f32>,
    @location(1) member_6: vec3<f32>,
    @location(3) member_7: vec4<f32>,
    @location(5) member_8: vec4<f32>,
    @location(6) member_9: vec4<f32>,
    @location(7) member_10: vec4<f32>,
    @location(9) member_11: vec3<f32>,
}

var<private> global: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_1: type_12;
var<private> global_2: vec4<f32>;
var<private> global_3: vec3<f32>;
var<private> global_4: vec3<f32>;
var<private> global_5: vec2<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec4<f32>;
var<private> global_11: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_12: type_20;
var<private> global_13: type_24 = type_24(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_14: vec4<f32>;
var<private> global_15: vec2<f32>;
var<private> global_16: vec3<f32>;
var<private> global_17: vec3<f32>;
var<private> global_18: vec4<f32>;
var<private> global_19: vec4<f32>;
var<private> global_20: vec4<f32>;
var<private> global_21: vec4<f32>;
var<private> global_22: vec3<f32>;
var<private> global_23: vec3<f32>;
var<private> global_24: vec4<f32>;
var<private> global_25: vec4<f32>;
var<private> global_26: vec4<f32>;
var<private> global_27: vec4<f32>;
var<private> global_28: vec4<f32>;
var<private> global_29: vec3<f32>;

fn function_() {
    var phi_1762_: vec4<f32>;
    var phi_1761_: vec4<f32>;
    var phi_1760_: vec4<f32>;
    var phi_1759_: i32;
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var local_2: vec4<f32>;
    var phi_1764_: vec3<f32>;
    var phi_1763_: i32;
    var local_3: vec3<f32>;
    var phi_1765_: f32;
    var phi_1766_: vec3<f32>;
    var phi_1768_: vec3<f32>;
    var phi_1767_: vec3<f32>;
    var local_4: bool;
    var phi_695_: bool;
    var local_5: bool;
    var phi_1770_: f32;
    var local_6: bool;
    var phi_1771_: f32;
    var local_7: bool;
    var phi_1772_: f32;
    var phi_733_: bool;
    var local_8: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_1776_: vec4<f32>;
    var phi_1775_: vec4<f32>;
    var phi_1774_: vec4<f32>;
    var phi_1773_: i32;
    var local_10: vec4<f32>;
    var local_11: vec4<f32>;
    var local_12: vec4<f32>;
    var local_13: vec4<f32>;
    var local_14: vec3<f32>;
    var local_15: vec2<f32>;
    var local_16: f32;
    var local_17: f32;
    var local_18: vec3<f32>;
    var phi_1778_: vec3<f32>;
    var phi_1777_: i32;
    var local_19: vec3<f32>;
    var local_20: vec3<f32>;
    var local_21: f32;
    var local_22: bool;
    var local_23: f32;
    var phi_1779_: f32;
    var local_24: f32;
    var phi_1780_: vec3<f32>;
    var phi_1781_: vec3<f32>;
    var local_25: vec3<f32>;
    var local_26: vec3<f32>;
    var local_27: mat3x3<f32>;
    var local_28: vec3<f32>;

    let _e77 = global_8;
    let _e78 = global_9;
    let _e79 = global_10;
    let _e80 = global_11;
    phi_1762_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1761_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1760_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1759_ = 0i;
    loop {
        let _e83 = phi_1762_;
        let _e85 = phi_1761_;
        let _e87 = phi_1760_;
        let _e89 = phi_1759_;
        local = _e87;
        local_1 = _e85;
        local_2 = _e83;
        if (_e89 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e92 = global[_e89];
            let _e94 = (i32(_e92) * 3i);
            let _e97 = global_1.member_3[_e94];
            let _e99 = global_2[_e89];
            let _e105 = global_1.member_3[(_e94 + 1i)];
            let _e111 = global_1.member_3[(_e94 + 2i)];
            phi_1762_ = (_e83 + (_e111 * _e99));
            phi_1761_ = (_e85 + (_e105 * _e99));
            phi_1760_ = (_e87 + (_e97 * _e99));
            phi_1759_ = (_e89 + 1i);
        }
    }
    let _e116 = local;
    let _e118 = local_1;
    let _e120 = local_2;
    let _e123 = (mat4x4<f32>(_e77, _e78, _e79, _e80) * transpose(mat4x4<f32>(_e116, _e118, _e120, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e127 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e129 = global_3;
            let _e133 = vec4<f32>(_e129.x, _e129.y, _e129.z, 1f);
            let _e135 = (_e123 * _e133).xyz;
            let _e137 = _e123[0].xyz;
            let _e139 = _e123[1].xyz;
            let _e141 = _e123[2].xyz;
            let _e144 = cross(_e137, _e139);
            let _e145 = mat3x3<f32>(cross(_e139, _e141), cross(_e141, _e137), _e144);
            let _e149 = global_4;
            let _e152 = normalize(((_e145 * _e149) * select(1f, -1f, (dot(_e144, _e141) < 0f))));
            let _e156 = global_1.member_1[2i][0u];
            let _e160 = global_1.member_1[3i][3u];
            let _e161 = (_e160 > 0.5f);
            let _e166 = global_1.member_1[5i];
            let _e167 = _e166.xy;
            let _e168 = _e123[3].xz;
            let _e173 = ((dot(_e168, _e167) * 0.35f) + (dot(_e168, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e187 = global_1.member_1[5i][3u];
            let _e193 = (dot(_e123[3].xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e206 = vec3<f32>(_e166.x, 0f, _e166.y);
            let _e210 = global_1.member_1[5i][2u];
            phi_1764_ = vec3<f32>(0f, 0f, 0f);
            phi_1763_ = 0i;
            local_4 = _e161;
            local_5 = _e161;
            local_6 = _e161;
            local_7 = _e161;
            local_8 = _e129;
            local_9 = _e149;
            local_13 = _e133;
            local_14 = _e149;
            local_15 = _e167;
            local_16 = _e187;
            local_17 = _e210;
            local_18 = _e206;
            local_21 = _e156;
            local_22 = _e161;
            local_25 = _e144;
            local_26 = _e141;
            local_27 = _e145;
            local_28 = _e149;
            loop {
                let _e216 = phi_1764_;
                let _e218 = phi_1763_;
                local_3 = _e216;
                if (_e218 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e221 = global[_e218];
                    let _e225 = global_1.member_2[i32(_e221)];
                    let _e228 = global_2[_e218];
                    phi_1764_ = (_e216 + (_e225.xyz * _e228));
                    phi_1763_ = (_e218 + 1i);
                }
            }
            let _e235 = global_1.member_1[0i][0u];
            let _e237 = vec3(max(_e235, 0.001f));
            let _e239 = local_3;
            let _e242 = (((_e206 * (((_e210 * (1f + (_e187 * (((0.5f + ((0.5f * sin(((_e127 * 0.61f) + _e173))) * sin(((_e127 * 0.23f) + (_e173 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e127 * 4.7f) + _e193))) * sin(((_e127 * 2.9f) + (_e193 * 0.37f)))))) * 0.35f)) + (_e239 / _e237)) * _e156);
            local_20 = _e237;
            local_23 = _e235;
            local_24 = _e235;
            if _e161 {
                let _e244 = global_5[1u];
                let _e258 = global_6;
                phi_1768_ = normalize(((mat3x3<f32>(vec3<f32>(_e123[0].x, _e123[0].y, _e123[0].z), vec3<f32>(_e123[1].x, _e123[1].y, _e123[1].z), vec3<f32>(_e123[2].x, _e123[2].y, _e123[2].z)) * _e258.xyz) + (_e242 * (2f * _e244))));
                phi_1767_ = (_e135 + (_e242 * ((_e235 * _e244) * _e244)));
                break;
            }
            let _e270 = global_7[1u];
            let _e271 = (_e270 > 1.5f);
            if _e271 {
                let _e273 = global_5[1u];
                phi_1765_ = _e273;
            } else {
                phi_1765_ = _e270;
            }
            let _e275 = phi_1765_;
            let _e277 = global_6[3u];
            let _e280 = (_e235 * max((_e277 - 1f), 0f));
            if ((_e275 <= 0f) && !(_e271)) {
                phi_1768_ = _e152;
                phi_1767_ = (_e135 + (_e152 * ((_e280 * 0.04f) + 0.0004f)));
                break;
            }
            let _e301 = global_6;
            let _e303 = (mat3x3<f32>(vec3<f32>(_e123[0].x, _e123[0].y, _e123[0].z), vec3<f32>(_e123[1].x, _e123[1].y, _e123[1].z), vec3<f32>(_e123[2].x, _e123[2].y, _e123[2].z)) * _e301.xyz);
            let _e305 = min(length(_e303), 1f);
            let _e309 = global_1.member_1[1i][3u];
            let _e312 = (vec3<f32>(0f, -(_e309), 0f) + _e242);
            let _e326 = (_e280 * _e275);
            let _e327 = (normalize((((_e152 * (1f - _e305)) + _e303) + (_e312 * (0.5f * _e275)))) * _e326);
            let _e328 = dot(_e327, _e152);
            let _e329 = (_e326 * 0.12f);
            phi_1766_ = _e327;
            if (_e328 < _e329) {
                phi_1766_ = (_e327 + (_e152 * (_e329 - _e328)));
            }
            let _e335 = phi_1766_;
            phi_1768_ = normalize((((_e152 * (1f - _e305)) + _e303) + (_e312 * _e275)));
            phi_1767_ = (_e135 + _e335);
            break;
        }
    }
    let _e338 = phi_1768_;
    let _e340 = phi_1767_;
    let _e342 = global_12.member;
    let _e346 = vec4<f32>(_e340.x, _e340.y, _e340.z, 1f);
    global_13.member = (_e342 * _e346);
    let _e351 = global_13.member[1u];
    global_13.member[1u] = -(_e351);
    let _e354 = local_4;
    let _e355 = !(_e354);
    phi_695_ = _e355;
    if _e355 {
        let _e357 = global_7[1u];
        phi_695_ = (_e357 > 1.5f);
    }
    let _e360 = phi_695_;
    let _e362 = local_5;
    if (_e362 || _e360) {
        let _e365 = global_5[1u];
        phi_1770_ = _e365;
    } else {
        let _e367 = global_7[1u];
        phi_1770_ = _e367;
    }
    let _e369 = phi_1770_;
    let _e371 = local_6;
    if _e371 {
        let _e373 = global_6[3u];
        phi_1771_ = fract(_e373);
    } else {
        phi_1771_ = 0f;
    }
    let _e376 = phi_1771_;
    let _e378 = local_7;
    if _e378 {
        phi_1772_ = 1f;
    } else {
        phi_1772_ = select(0f, 2f, _e360);
    }
    let _e381 = phi_1772_;
    phi_733_ = _e355;
    if _e355 {
        let _e383 = global_7[1u];
        phi_733_ = (_e383 <= 0f);
    }
    let _e386 = phi_733_;
    global_14 = vec4<f32>(_e369, _e376, _e381, select(0f, 1f, _e386));
    let _e389 = global_5;
    global_15 = _e389;
    let _e391 = local_8;
    global_16 = _e391;
    let _e393 = local_9;
    global_17 = _e393;
    let _e394 = global_18;
    let _e395 = global_19;
    let _e396 = global_20;
    let _e397 = global_21;
    phi_1776_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1775_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1774_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1773_ = 0i;
    loop {
        let _e400 = phi_1776_;
        let _e402 = phi_1775_;
        let _e404 = phi_1774_;
        let _e406 = phi_1773_;
        local_10 = _e404;
        local_11 = _e402;
        local_12 = _e400;
        if (_e406 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e409 = global[_e406];
            let _e411 = (i32(_e409) * 3i);
            let _e414 = global_1.member_4[_e411];
            let _e416 = global_2[_e406];
            let _e422 = global_1.member_4[(_e411 + 1i)];
            let _e428 = global_1.member_4[(_e411 + 2i)];
            phi_1776_ = (_e400 + (_e428 * _e416));
            phi_1775_ = (_e402 + (_e422 * _e416));
            phi_1774_ = (_e404 + (_e414 * _e416));
            phi_1773_ = (_e406 + 1i);
        }
    }
    let _e433 = local_10;
    let _e435 = local_11;
    let _e437 = local_12;
    let _e440 = (mat4x4<f32>(_e394, _e395, _e396, _e397) * transpose(mat4x4<f32>(_e433, _e435, _e437, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e444 = global_1.member_1[6i][1u];
    switch bitcast<i32>(0u) {
        default: {
            let _e447 = local_13;
            let _e449 = (_e440 * _e447).xyz;
            let _e451 = _e440[0].xyz;
            let _e453 = _e440[1].xyz;
            let _e455 = _e440[2].xyz;
            let _e458 = cross(_e451, _e453);
            let _e464 = local_14;
            let _e467 = normalize(((mat3x3<f32>(cross(_e453, _e455), cross(_e455, _e451), _e458) * _e464) * select(1f, -1f, (dot(_e458, _e455) < 0f))));
            let _e470 = _e440[3].xz;
            let _e472 = local_15;
            let _e477 = ((dot(_e470, _e472) * 0.35f) + (dot(_e470, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e491 = local_16;
            let _e495 = (dot(_e440[3].xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e507 = local_17;
            let _e512 = local_18;
            phi_1778_ = vec3<f32>(0f, 0f, 0f);
            phi_1777_ = 0i;
            loop {
                let _e515 = phi_1778_;
                let _e517 = phi_1777_;
                local_19 = _e515;
                if (_e517 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e520 = global[_e517];
                    let _e524 = global_1.member_2[i32(_e520)];
                    let _e527 = global_2[_e517];
                    phi_1778_ = (_e515 + (_e524.xyz * _e527));
                    phi_1777_ = (_e517 + 1i);
                }
            }
            let _e532 = local_19;
            let _e534 = local_20;
            let _e538 = local_21;
            let _e539 = (((_e512 * (((_e507 * (1f + (_e491 * (((0.5f + ((0.5f * sin(((_e444 * 0.61f) + _e477))) * sin(((_e444 * 0.23f) + (_e477 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e444 * 4.7f) + _e495))) * sin(((_e444 * 2.9f) + (_e495 * 0.37f)))))) * 0.35f)) + (_e532 / _e534)) * _e538);
            let _e541 = local_22;
            if _e541 {
                let _e543 = global_5[1u];
                let _e545 = local_23;
                phi_1781_ = (_e449 + (_e539 * ((_e545 * _e543) * _e543)));
                break;
            }
            let _e551 = global_7[1u];
            let _e552 = (_e551 > 1.5f);
            if _e552 {
                let _e554 = global_5[1u];
                phi_1779_ = _e554;
            } else {
                phi_1779_ = _e551;
            }
            let _e556 = phi_1779_;
            let _e558 = global_6[3u];
            let _e562 = local_24;
            let _e563 = (_e562 * max((_e558 - 1f), 0f));
            if ((_e556 <= 0f) && !(_e552)) {
                phi_1781_ = (_e449 + (_e467 * ((_e563 * 0.04f) + 0.0004f)));
                break;
            }
            let _e584 = global_6;
            let _e586 = (mat3x3<f32>(vec3<f32>(_e440[0].x, _e440[0].y, _e440[0].z), vec3<f32>(_e440[1].x, _e440[1].y, _e440[1].z), vec3<f32>(_e440[2].x, _e440[2].y, _e440[2].z)) * _e584.xyz);
            let _e592 = global_1.member_1[1i][3u];
            let _e603 = (_e563 * _e556);
            let _e604 = (normalize((((_e467 * (1f - min(length(_e586), 1f))) + _e586) + ((vec3<f32>(0f, -(_e592), 0f) + _e539) * (0.5f * _e556)))) * _e603);
            let _e605 = dot(_e604, _e467);
            let _e606 = (_e603 * 0.12f);
            phi_1780_ = _e604;
            if (_e605 < _e606) {
                phi_1780_ = (_e604 + (_e467 * (_e606 - _e605)));
            }
            let _e612 = phi_1780_;
            phi_1781_ = (_e449 + _e612);
            break;
        }
    }
    let _e615 = phi_1781_;
    let _e617 = local_25;
    let _e619 = local_26;
    global_22 = _e340;
    let _e624 = local_27;
    let _e626 = local_28;
    global_23 = ((_e624 * _e626) * select(1f, -1f, (dot(_e617, _e619) < 0f)));
    let _e629 = global_25;
    global_24 = _e629;
    let _e631 = global_7[0u];
    global_26 = vec4<f32>(_e631, 0f, 0f, 0f);
    let _e634 = global_12.member_2;
    let _e637 = global_12.member_3;
    global_27 = (_e634 * _e346);
    global_28 = (_e637 * vec4<f32>(_e615.x, _e615.y, _e615.z, 1f));
    global_29 = _e338;
    return;
}

@vertex 
fn main(@location(14) param: vec4<f32>, @location(15) param_1: vec4<f32>, @location(0) param_2: vec3<f32>, @location(1) param_3: vec3<f32>, @location(2) param_4: vec2<f32>, @location(13) param_5: vec4<f32>, @location(12) param_6: vec4<f32>, @location(3) param_7: vec4<f32>, @location(4) param_8: vec4<f32>, @location(5) param_9: vec4<f32>, @location(6) param_10: vec4<f32>, @location(7) param_11: vec4<f32>, @location(8) param_12: vec4<f32>, @location(9) param_13: vec4<f32>, @location(10) param_14: vec4<f32>, @location(11) param_15: vec4<f32>) -> VertexOutput {
    global = param;
    global_2 = param_1;
    global_3 = param_2;
    global_4 = param_3;
    global_5 = param_4;
    global_6 = param_5;
    global_7 = param_6;
    global_8 = param_7;
    global_9 = param_8;
    global_10 = param_9;
    global_11 = param_10;
    global_18 = param_11;
    global_19 = param_12;
    global_20 = param_13;
    global_21 = param_14;
    global_25 = param_15;
    function_();
    let _e46 = global_13.member.y;
    global_13.member.y = -(_e46);
    let _e48 = global_13.member;
    let _e49 = global_14;
    let _e50 = global_15;
    let _e51 = global_16;
    let _e52 = global_17;
    let _e53 = global_22;
    let _e54 = global_23;
    let _e55 = global_24;
    let _e56 = global_26;
    let _e57 = global_27;
    let _e58 = global_28;
    let _e59 = global_29;
    return VertexOutput(_e48, _e49, _e50, _e51, _e52, _e53, _e54, _e55, _e56, _e57, _e58, _e59);
}
