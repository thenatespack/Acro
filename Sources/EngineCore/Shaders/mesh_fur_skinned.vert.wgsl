// Generated from mesh_fur_skinned.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: b79a1ee65ad1e6c4
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
    @location(0) member_1: vec3<f32>,
    @location(1) member_2: vec3<f32>,
    @location(2) member_3: vec2<f32>,
    @location(3) member_4: vec4<f32>,
    @location(5) member_5: vec4<f32>,
    @location(6) member_6: vec4<f32>,
    @location(7) member_7: vec4<f32>,
    @location(8) member_8: vec4<f32>,
    @location(9) member_9: vec3<f32>,
    @location(4) member_10: vec3<f32>,
    @location(10) member_11: vec3<f32>,
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
var<private> global_12: vec4<f32>;
var<private> global_13: vec4<f32>;
var<private> global_14: vec4<f32>;
var<private> global_15: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_16: type_20;
var<private> global_17: type_24 = type_24(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_18: vec3<f32>;
var<private> global_19: vec3<f32>;
var<private> global_20: vec2<f32>;
var<private> global_21: vec4<f32>;
var<private> global_22: vec4<f32>;
var<private> global_23: vec4<f32>;
var<private> global_24: vec4<f32>;
var<private> global_25: vec4<f32>;
var<private> global_26: vec4<f32>;
var<private> global_27: vec3<f32>;
var<private> global_28: vec3<f32>;
var<private> global_29: vec3<f32>;

fn function_() {
    var phi_1699_: vec4<f32>;
    var phi_1698_: vec4<f32>;
    var phi_1697_: vec4<f32>;
    var phi_1696_: i32;
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var local_2: vec4<f32>;
    var phi_1704_: vec4<f32>;
    var phi_1703_: vec4<f32>;
    var phi_1702_: vec4<f32>;
    var phi_1701_: i32;
    var local_3: vec4<f32>;
    var local_4: vec4<f32>;
    var local_5: vec4<f32>;
    var phi_1707_: vec3<f32>;
    var phi_1706_: i32;
    var local_6: vec3<f32>;
    var phi_1708_: vec3<f32>;
    var phi_1710_: vec3<f32>;
    var phi_1709_: vec3<f32>;
    var local_7: vec4<f32>;
    var local_8: vec3<f32>;
    var local_9: vec2<f32>;
    var local_10: f32;
    var local_11: f32;
    var local_12: vec3<f32>;
    var phi_1716_: vec3<f32>;
    var phi_1715_: i32;
    var local_13: vec3<f32>;
    var local_14: vec3<f32>;
    var local_15: f32;
    var local_16: bool;
    var local_17: f32;
    var local_18: f32;
    var phi_1717_: vec3<f32>;
    var phi_1718_: vec3<f32>;
    var local_19: vec3<f32>;
    var local_20: vec3<f32>;
    var local_21: mat3x3<f32>;
    var local_22: vec3<f32>;
    var local_23: bool;
    var phi_1725_: f32;
    var local_24: bool;
    var phi_1726_: f32;
    var local_25: bool;
    var local_26: bool;
    var phi_827_: bool;
    var local_27: vec3<f32>;
    var local_28: vec3<f32>;

    let _e76 = global_8;
    let _e77 = global_9;
    let _e78 = global_10;
    let _e79 = global_11;
    let _e81 = global_12;
    let _e82 = global_13;
    let _e83 = global_14;
    let _e84 = global_15;
    phi_1699_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1698_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1697_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1696_ = 0i;
    loop {
        let _e87 = phi_1699_;
        let _e89 = phi_1698_;
        let _e91 = phi_1697_;
        let _e93 = phi_1696_;
        local = _e91;
        local_1 = _e89;
        local_2 = _e87;
        if (_e93 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e96 = global[_e93];
            let _e98 = (i32(_e96) * 3i);
            let _e101 = global_1.member_3[_e98];
            let _e103 = global_2[_e93];
            let _e109 = global_1.member_3[(_e98 + 1i)];
            let _e115 = global_1.member_3[(_e98 + 2i)];
            phi_1699_ = (_e87 + (_e115 * _e103));
            phi_1698_ = (_e89 + (_e109 * _e103));
            phi_1697_ = (_e91 + (_e101 * _e103));
            phi_1696_ = (_e93 + 1i);
        }
    }
    let _e120 = local;
    let _e122 = local_1;
    let _e124 = local_2;
    let _e127 = (mat4x4<f32>(_e76, _e77, _e78, _e79) * transpose(mat4x4<f32>(_e120, _e122, _e124, vec4<f32>(0f, 0f, 0f, 1f))));
    phi_1704_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1703_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1702_ = vec4<f32>(0f, 0f, 0f, 0f);
    phi_1701_ = 0i;
    loop {
        let _e129 = phi_1704_;
        let _e131 = phi_1703_;
        let _e133 = phi_1702_;
        let _e135 = phi_1701_;
        local_3 = _e133;
        local_4 = _e131;
        local_5 = _e129;
        if (_e135 < 4i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e138 = global[_e135];
            let _e140 = (i32(_e138) * 3i);
            let _e143 = global_1.member_4[_e140];
            let _e145 = global_2[_e135];
            let _e151 = global_1.member_4[(_e140 + 1i)];
            let _e157 = global_1.member_4[(_e140 + 2i)];
            phi_1704_ = (_e129 + (_e157 * _e145));
            phi_1703_ = (_e131 + (_e151 * _e145));
            phi_1702_ = (_e133 + (_e143 * _e145));
            phi_1701_ = (_e135 + 1i);
        }
    }
    let _e162 = local_3;
    let _e164 = local_4;
    let _e166 = local_5;
    let _e169 = (mat4x4<f32>(_e81, _e82, _e83, _e84) * transpose(mat4x4<f32>(_e162, _e164, _e166, vec4<f32>(0f, 0f, 0f, 1f))));
    let _e173 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e175 = global_3;
            let _e179 = vec4<f32>(_e175.x, _e175.y, _e175.z, 1f);
            let _e181 = (_e127 * _e179).xyz;
            let _e183 = _e127[0].xyz;
            let _e185 = _e127[1].xyz;
            let _e187 = _e127[2].xyz;
            let _e190 = cross(_e183, _e185);
            let _e191 = mat3x3<f32>(cross(_e185, _e187), cross(_e187, _e183), _e190);
            let _e195 = global_4;
            let _e198 = normalize(((_e191 * _e195) * select(1f, -1f, (dot(_e190, _e187) < 0f))));
            let _e202 = global_1.member_1[2i][0u];
            let _e206 = global_1.member_1[3i][3u];
            let _e207 = (_e206 > 0.5f);
            let _e212 = global_1.member_1[5i];
            let _e213 = _e212.xy;
            let _e214 = _e127[3].xz;
            let _e219 = ((dot(_e214, _e213) * 0.35f) + (dot(_e214, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e233 = global_1.member_1[5i][3u];
            let _e239 = (dot(_e127[3].xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e252 = vec3<f32>(_e212.x, 0f, _e212.y);
            let _e256 = global_1.member_1[5i][2u];
            phi_1707_ = vec3<f32>(0f, 0f, 0f);
            phi_1706_ = 0i;
            local_7 = _e179;
            local_8 = _e195;
            local_9 = _e213;
            local_10 = _e233;
            local_11 = _e256;
            local_12 = _e252;
            local_15 = _e202;
            local_16 = _e207;
            local_19 = _e190;
            local_20 = _e187;
            local_21 = _e191;
            local_22 = _e195;
            local_23 = _e207;
            local_24 = _e207;
            local_25 = _e207;
            local_26 = _e207;
            local_27 = _e175;
            local_28 = _e195;
            loop {
                let _e262 = phi_1707_;
                let _e264 = phi_1706_;
                local_6 = _e262;
                if (_e264 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e267 = global[_e264];
                    let _e271 = global_1.member_2[i32(_e267)];
                    let _e274 = global_2[_e264];
                    phi_1707_ = (_e262 + (_e271.xyz * _e274));
                    phi_1706_ = (_e264 + 1i);
                }
            }
            let _e281 = global_1.member_1[0i][0u];
            let _e283 = vec3(max(_e281, 0.001f));
            let _e285 = local_6;
            let _e288 = (((_e252 * (((_e256 * (1f + (_e233 * (((0.5f + ((0.5f * sin(((_e173 * 0.61f) + _e219))) * sin(((_e173 * 0.23f) + (_e219 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e173 * 4.7f) + _e239))) * sin(((_e173 * 2.9f) + (_e239 * 0.37f)))))) * 0.35f)) + (_e285 / _e283)) * _e202);
            local_14 = _e283;
            local_17 = _e281;
            local_18 = _e281;
            if _e207 {
                let _e290 = global_5[1u];
                let _e304 = global_6;
                phi_1710_ = normalize(((mat3x3<f32>(vec3<f32>(_e127[0].x, _e127[0].y, _e127[0].z), vec3<f32>(_e127[1].x, _e127[1].y, _e127[1].z), vec3<f32>(_e127[2].x, _e127[2].y, _e127[2].z)) * _e304.xyz) + (_e288 * (2f * _e290))));
                phi_1709_ = (_e181 + (_e288 * ((_e281 * _e290) * _e290)));
                break;
            }
            let _e316 = global_7[1u];
            let _e318 = global_6[3u];
            let _e321 = (_e281 * max((_e318 - 1f), 0f));
            if (_e316 <= 0f) {
                phi_1710_ = _e198;
                phi_1709_ = (_e181 + (_e198 * ((_e321 * 0.04f) + 0.0004f)));
                break;
            }
            let _e340 = global_6;
            let _e342 = (mat3x3<f32>(vec3<f32>(_e127[0].x, _e127[0].y, _e127[0].z), vec3<f32>(_e127[1].x, _e127[1].y, _e127[1].z), vec3<f32>(_e127[2].x, _e127[2].y, _e127[2].z)) * _e340.xyz);
            let _e344 = min(length(_e342), 1f);
            let _e348 = global_1.member_1[1i][3u];
            let _e351 = (vec3<f32>(0f, -(_e348), 0f) + _e288);
            let _e365 = (_e321 * _e316);
            let _e366 = (normalize((((_e198 * (1f - _e344)) + _e342) + (_e351 * (0.5f * _e316)))) * _e365);
            let _e367 = dot(_e366, _e198);
            let _e368 = (_e365 * 0.12f);
            phi_1708_ = _e366;
            if (_e367 < _e368) {
                phi_1708_ = (_e366 + (_e198 * (_e368 - _e367)));
            }
            let _e374 = phi_1708_;
            phi_1710_ = normalize((((_e198 * (1f - _e344)) + _e342) + (_e351 * _e316)));
            phi_1709_ = (_e181 + _e374);
            break;
        }
    }
    let _e377 = phi_1710_;
    let _e379 = phi_1709_;
    let _e383 = global_1.member_1[6i][1u];
    switch bitcast<i32>(0u) {
        default: {
            let _e386 = local_7;
            let _e388 = (_e169 * _e386).xyz;
            let _e390 = _e169[0].xyz;
            let _e392 = _e169[1].xyz;
            let _e394 = _e169[2].xyz;
            let _e397 = cross(_e390, _e392);
            let _e403 = local_8;
            let _e406 = normalize(((mat3x3<f32>(cross(_e392, _e394), cross(_e394, _e390), _e397) * _e403) * select(1f, -1f, (dot(_e397, _e394) < 0f))));
            let _e409 = _e169[3].xz;
            let _e411 = local_9;
            let _e416 = ((dot(_e409, _e411) * 0.35f) + (dot(_e409, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e430 = local_10;
            let _e434 = (dot(_e169[3].xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e446 = local_11;
            let _e451 = local_12;
            phi_1716_ = vec3<f32>(0f, 0f, 0f);
            phi_1715_ = 0i;
            loop {
                let _e454 = phi_1716_;
                let _e456 = phi_1715_;
                local_13 = _e454;
                if (_e456 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e459 = global[_e456];
                    let _e463 = global_1.member_2[i32(_e459)];
                    let _e466 = global_2[_e456];
                    phi_1716_ = (_e454 + (_e463.xyz * _e466));
                    phi_1715_ = (_e456 + 1i);
                }
            }
            let _e471 = local_13;
            let _e473 = local_14;
            let _e477 = local_15;
            let _e478 = (((_e451 * (((_e446 * (1f + (_e430 * (((0.5f + ((0.5f * sin(((_e383 * 0.61f) + _e416))) * sin(((_e383 * 0.23f) + (_e416 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e383 * 4.7f) + _e434))) * sin(((_e383 * 2.9f) + (_e434 * 0.37f)))))) * 0.35f)) + (_e471 / _e473)) * _e477);
            let _e480 = local_16;
            if _e480 {
                let _e482 = global_5[1u];
                let _e484 = local_17;
                phi_1718_ = (_e388 + (_e478 * ((_e484 * _e482) * _e482)));
                break;
            }
            let _e490 = global_7[1u];
            let _e492 = global_6[3u];
            let _e496 = local_18;
            let _e497 = (_e496 * max((_e492 - 1f), 0f));
            if (_e490 <= 0f) {
                phi_1718_ = (_e388 + (_e406 * ((_e497 * 0.04f) + 0.0004f)));
                break;
            }
            let _e516 = global_6;
            let _e518 = (mat3x3<f32>(vec3<f32>(_e169[0].x, _e169[0].y, _e169[0].z), vec3<f32>(_e169[1].x, _e169[1].y, _e169[1].z), vec3<f32>(_e169[2].x, _e169[2].y, _e169[2].z)) * _e516.xyz);
            let _e524 = global_1.member_1[1i][3u];
            let _e535 = (_e497 * _e490);
            let _e536 = (normalize((((_e406 * (1f - min(length(_e518), 1f))) + _e518) + ((vec3<f32>(0f, -(_e524), 0f) + _e478) * (0.5f * _e490)))) * _e535);
            let _e537 = dot(_e536, _e406);
            let _e538 = (_e535 * 0.12f);
            phi_1717_ = _e536;
            if (_e537 < _e538) {
                phi_1717_ = (_e536 + (_e406 * (_e538 - _e537)));
            }
            let _e544 = phi_1717_;
            phi_1718_ = (_e388 + _e544);
            break;
        }
    }
    let _e547 = phi_1718_;
    let _e549 = local_19;
    let _e551 = local_20;
    let _e556 = global_16.member;
    let _e560 = vec4<f32>(_e379.x, _e379.y, _e379.z, 1f);
    global_17.member = (_e556 * _e560);
    let _e565 = global_17.member[1u];
    global_17.member[1u] = -(_e565);
    global_18 = _e379;
    let _e568 = local_21;
    let _e570 = local_22;
    global_19 = ((_e568 * _e570) * select(1f, -1f, (dot(_e549, _e551) < 0f)));
    let _e573 = global_5;
    global_20 = _e573;
    let _e574 = global_22;
    global_21 = _e574;
    let _e576 = global_7[0u];
    global_23 = vec4<f32>(_e576, 0f, 0f, 0f);
    let _e579 = global_16.member_2;
    let _e582 = global_16.member_3;
    global_24 = (_e579 * _e560);
    global_25 = (_e582 * vec4<f32>(_e547.x, _e547.y, _e547.z, 1f));
    let _e589 = local_23;
    if _e589 {
        let _e591 = global_5[1u];
        phi_1725_ = _e591;
    } else {
        let _e593 = global_7[1u];
        phi_1725_ = _e593;
    }
    let _e595 = phi_1725_;
    let _e597 = local_24;
    if _e597 {
        let _e599 = global_6[3u];
        phi_1726_ = fract(_e599);
    } else {
        phi_1726_ = 0f;
    }
    let _e602 = phi_1726_;
    let _e604 = local_25;
    let _e607 = local_26;
    let _e608 = !(_e607);
    phi_827_ = _e608;
    if _e608 {
        let _e610 = global_7[1u];
        phi_827_ = (_e610 <= 0f);
    }
    let _e613 = phi_827_;
    global_26 = vec4<f32>(_e595, _e602, select(0f, 1f, _e604), select(0f, 1f, _e613));
    global_27 = _e377;
    let _e617 = local_27;
    global_28 = _e617;
    let _e619 = local_28;
    global_29 = _e619;
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
    global_12 = param_11;
    global_13 = param_12;
    global_14 = param_13;
    global_15 = param_14;
    global_22 = param_15;
    function_();
    let _e46 = global_17.member.y;
    global_17.member.y = -(_e46);
    let _e48 = global_17.member;
    let _e49 = global_18;
    let _e50 = global_19;
    let _e51 = global_20;
    let _e52 = global_21;
    let _e53 = global_23;
    let _e54 = global_24;
    let _e55 = global_25;
    let _e56 = global_26;
    let _e57 = global_27;
    let _e58 = global_28;
    let _e59 = global_29;
    return VertexOutput(_e48, _e49, _e50, _e51, _e52, _e53, _e54, _e55, _e56, _e57, _e58, _e59);
}
