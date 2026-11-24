// Generated from fsr3_rcas.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 9bb12bb62f414d8e
// glsl-fnv1a64: 8f43f2f9e47c8b85

diagnostic(off, derivative_uniformity);

struct type_9 {
    member: vec2<i32>,
    member_1: vec2<i32>,
    member_2: vec2<i32>,
    member_3: vec2<i32>,
    member_4: vec4<f32>,
    member_5: vec2<f32>,
    member_6: vec2<f32>,
    member_7: vec2<f32>,
    member_8: f32,
    member_9: f32,
    member_10: f32,
    member_11: f32,
    member_12: f32,
    member_13: f32,
    member_14: f32,
    member_15: f32,
    member_16: f32,
    member_17: f32,
    member_18: f32,
    member_19: vec2<u32>,
}

@group(3) @binding(0) 
var<uniform> global: type_9;
@group(2) @binding(9) 
var global_1: texture_2d<f32>;
@group(2) @binding(32) 
var global_2: texture_storage_2d<rgba16float,write>;
var<private> global_3: vec3<u32>;
var<private> global_4: vec3<u32>;

fn function_() {
    var phi_4794_: vec4<f32>;
    var phi_4795_: vec4<f32>;
    var phi_4796_: vec4<f32>;
    var phi_4797_: vec4<f32>;
    var phi_4798_: vec4<f32>;
    var phi_4811_: vec4<f32>;
    var phi_4812_: vec4<f32>;
    var phi_4813_: vec4<f32>;
    var phi_4814_: vec4<f32>;
    var phi_4815_: vec4<f32>;
    var phi_4833_: vec4<f32>;
    var phi_4834_: vec4<f32>;
    var phi_4835_: vec4<f32>;
    var phi_4836_: vec4<f32>;
    var phi_4837_: vec4<f32>;
    var phi_4861_: vec4<f32>;
    var phi_4862_: vec4<f32>;
    var phi_4863_: vec4<f32>;
    var phi_4864_: vec4<f32>;
    var phi_4865_: vec4<f32>;

    let _e31 = global_3;
    let _e32 = global_4;
    let _e51 = (vec2<u32>(extractBits(_e31.x, bitcast<u32>(1i), bitcast<u32>(3i)), insertBits(extractBits(_e31.x, bitcast<u32>(3i), bitcast<u32>(3i)), _e31.x, bitcast<u32>(0i), bitcast<u32>(1i))) + vec2<u32>((_e32.x << bitcast<u32>(4u)), (_e32.y << bitcast<u32>(4u))));
    let _e53 = global.member_19;
    let _e55 = bitcast<vec2<i32>>(_e51);
    let _e56 = (_e55 + vec2<i32>(0i, -1i));
    let _e58 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e56) < bitcast<vec2<u32>>(vec2<i32>(_e58)))) {
        let _e63 = textureLoad(global_1, _e56, 0i);
        phi_4794_ = _e63;
    } else {
        phi_4794_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e65 = phi_4794_;
    let _e67 = global.member_18;
    let _e69 = select(_e67, 1f, (_e67 == 0f));
    let _e71 = (_e65.xyz * _e69);
    let _e75 = (_e55 + vec2<i32>(-1i, 0i));
    let _e77 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e75) < bitcast<vec2<u32>>(vec2<i32>(_e77)))) {
        let _e82 = textureLoad(global_1, _e75, 0i);
        phi_4795_ = _e82;
    } else {
        phi_4795_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e84 = phi_4795_;
    let _e86 = (_e84.xyz * _e69);
    let _e90 = textureDimensions(global_1, 0i);
    if all((_e51 < bitcast<vec2<u32>>(vec2<i32>(_e90)))) {
        let _e95 = textureLoad(global_1, _e55, 0i);
        phi_4796_ = _e95;
    } else {
        phi_4796_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e97 = phi_4796_;
    let _e99 = (_e97.xyz * _e69);
    let _e103 = (_e55 + vec2<i32>(1i, 0i));
    let _e105 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e103) < bitcast<vec2<u32>>(vec2<i32>(_e105)))) {
        let _e110 = textureLoad(global_1, _e103, 0i);
        phi_4797_ = _e110;
    } else {
        phi_4797_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e112 = phi_4797_;
    let _e114 = (_e112.xyz * _e69);
    let _e118 = (_e55 + vec2<i32>(0i, 1i));
    let _e120 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e118) < bitcast<vec2<u32>>(vec2<i32>(_e120)))) {
        let _e125 = textureLoad(global_1, _e118, 0i);
        phi_4798_ = _e125;
    } else {
        phi_4798_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e127 = phi_4798_;
    let _e129 = (_e127.xyz * _e69);
    let _e136 = ((_e71.z * 0.5f) + ((_e71.x * 0.5f) + _e71.y));
    let _e140 = ((_e86.z * 0.5f) + ((_e86.x * 0.5f) + _e86.y));
    let _e144 = ((_e99.z * 0.5f) + ((_e99.x * 0.5f) + _e99.y));
    let _e148 = ((_e114.z * 0.5f) + ((_e114.x * 0.5f) + _e114.y));
    let _e152 = ((_e129.z * 0.5f) + ((_e129.x * 0.5f) + _e129.y));
    let _e167 = (max(max(_e136, max(_e140, _e144)), max(_e148, _e152)) - min(min(_e136, min(_e140, _e144)), min(_e148, _e152)));
    let _e170 = bitcast<f32>((2129764351u - bitcast<u32>(_e167)));
    let _e181 = min(min(_e71.x, min(_e86.x, _e114.x)), _e129.x);
    let _e184 = min(min(_e71.y, min(_e86.y, _e114.y)), _e129.y);
    let _e187 = min(min(_e71.z, min(_e86.z, _e114.z)), _e129.z);
    let _e190 = max(max(_e71.x, max(_e86.x, _e114.x)), _e129.x);
    let _e193 = max(max(_e71.y, max(_e86.y, _e114.y)), _e129.y);
    let _e196 = max(max(_e71.z, max(_e86.z, _e114.z)), _e129.z);
    let _e228 = bitcast<f32>(_e53.x);
    let _e230 = ((max(-0.1875f, min(max(max(-((_e181 * (0.25f / _e190))), ((1f - _e190) * (1f / ((4f * _e181) + -4f)))), max(max(-((_e184 * (0.25f / _e193))), ((1f - _e193) * (1f / ((4f * _e184) + -4f)))), max(-((_e187 * (0.25f / _e196))), ((1f - _e196) * (1f / ((4f * _e187) + -4f)))))), 0f)) * _e228) * ((-0.5f * clamp((abs(((0.25f * (((_e136 + _e140) + _e148) + _e152)) - _e144)) * (_e170 * ((-(_e170) * _e167) + 2f))), 0f, 1f)) + 1f));
    let _e232 = ((4f * _e230) + 1f);
    let _e235 = bitcast<f32>((2129764351u - bitcast<u32>(_e232)));
    let _e239 = (_e235 * ((-(_e235) * _e232) + 2f));
    let _e259 = vec3(_e69);
    let _e260 = (vec3<f32>((((_e230 * (((_e71.x + _e86.x) + _e129.x) + _e114.x)) + _e99.x) * _e239), (((_e230 * (((_e71.y + _e86.y) + _e129.y) + _e114.y)) + _e99.y) * _e239), (((_e230 * (((_e71.z + _e86.z) + _e129.z) + _e114.z)) + _e99.z) * _e239)) / _e259);
    let _e261 = textureDimensions(global_2);
    if all((_e51 < bitcast<vec2<u32>>(vec2<i32>(_e261)))) {
        textureStore(global_2, _e55, vec4<f32>(_e260.x, _e260.y, _e260.z, 1f));
    }
    let _e271 = (_e51.x + 8u);
    let _e274 = vec2<u32>(_e271, _e51.y);
    let _e275 = bitcast<vec2<i32>>(_e274);
    let _e276 = (_e275 + vec2<i32>(0i, -1i));
    let _e278 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e276) < bitcast<vec2<u32>>(vec2<i32>(_e278)))) {
        let _e283 = textureLoad(global_1, _e276, 0i);
        phi_4811_ = _e283;
    } else {
        phi_4811_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e285 = phi_4811_;
    let _e287 = (_e285.xyz * _e69);
    let _e291 = (_e275 + vec2<i32>(-1i, 0i));
    let _e293 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e291) < bitcast<vec2<u32>>(vec2<i32>(_e293)))) {
        let _e298 = textureLoad(global_1, _e291, 0i);
        phi_4812_ = _e298;
    } else {
        phi_4812_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e300 = phi_4812_;
    let _e302 = (_e300.xyz * _e69);
    let _e306 = textureDimensions(global_1, 0i);
    if all((_e274 < bitcast<vec2<u32>>(vec2<i32>(_e306)))) {
        let _e311 = textureLoad(global_1, _e275, 0i);
        phi_4813_ = _e311;
    } else {
        phi_4813_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e313 = phi_4813_;
    let _e315 = (_e313.xyz * _e69);
    let _e319 = (_e275 + vec2<i32>(1i, 0i));
    let _e321 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e319) < bitcast<vec2<u32>>(vec2<i32>(_e321)))) {
        let _e326 = textureLoad(global_1, _e319, 0i);
        phi_4814_ = _e326;
    } else {
        phi_4814_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e328 = phi_4814_;
    let _e330 = (_e328.xyz * _e69);
    let _e334 = (_e275 + vec2<i32>(0i, 1i));
    let _e336 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e334) < bitcast<vec2<u32>>(vec2<i32>(_e336)))) {
        let _e341 = textureLoad(global_1, _e334, 0i);
        phi_4815_ = _e341;
    } else {
        phi_4815_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e343 = phi_4815_;
    let _e345 = (_e343.xyz * _e69);
    let _e352 = ((_e287.z * 0.5f) + ((_e287.x * 0.5f) + _e287.y));
    let _e356 = ((_e302.z * 0.5f) + ((_e302.x * 0.5f) + _e302.y));
    let _e360 = ((_e315.z * 0.5f) + ((_e315.x * 0.5f) + _e315.y));
    let _e364 = ((_e330.z * 0.5f) + ((_e330.x * 0.5f) + _e330.y));
    let _e368 = ((_e345.z * 0.5f) + ((_e345.x * 0.5f) + _e345.y));
    let _e383 = (max(max(_e352, max(_e356, _e360)), max(_e364, _e368)) - min(min(_e352, min(_e356, _e360)), min(_e364, _e368)));
    let _e386 = bitcast<f32>((2129764351u - bitcast<u32>(_e383)));
    let _e397 = min(min(_e287.x, min(_e302.x, _e330.x)), _e345.x);
    let _e400 = min(min(_e287.y, min(_e302.y, _e330.y)), _e345.y);
    let _e403 = min(min(_e287.z, min(_e302.z, _e330.z)), _e345.z);
    let _e406 = max(max(_e287.x, max(_e302.x, _e330.x)), _e345.x);
    let _e409 = max(max(_e287.y, max(_e302.y, _e330.y)), _e345.y);
    let _e412 = max(max(_e287.z, max(_e302.z, _e330.z)), _e345.z);
    let _e445 = ((max(-0.1875f, min(max(max(-((_e397 * (0.25f / _e406))), ((1f - _e406) * (1f / ((4f * _e397) + -4f)))), max(max(-((_e400 * (0.25f / _e409))), ((1f - _e409) * (1f / ((4f * _e400) + -4f)))), max(-((_e403 * (0.25f / _e412))), ((1f - _e412) * (1f / ((4f * _e403) + -4f)))))), 0f)) * _e228) * ((-0.5f * clamp((abs(((0.25f * (((_e352 + _e356) + _e364) + _e368)) - _e360)) * (_e386 * ((-(_e386) * _e383) + 2f))), 0f, 1f)) + 1f));
    let _e447 = ((4f * _e445) + 1f);
    let _e450 = bitcast<f32>((2129764351u - bitcast<u32>(_e447)));
    let _e454 = (_e450 * ((-(_e450) * _e447) + 2f));
    let _e474 = (vec3<f32>((((_e445 * (((_e287.x + _e302.x) + _e345.x) + _e330.x)) + _e315.x) * _e454), (((_e445 * (((_e287.y + _e302.y) + _e345.y) + _e330.y)) + _e315.y) * _e454), (((_e445 * (((_e287.z + _e302.z) + _e345.z) + _e330.z)) + _e315.z) * _e454)) / _e259);
    let _e475 = textureDimensions(global_2);
    if all((_e274 < bitcast<vec2<u32>>(vec2<i32>(_e475)))) {
        textureStore(global_2, _e275, vec4<f32>(_e474.x, _e474.y, _e474.z, 1f));
    }
    let _e486 = vec2<u32>(_e271, (_e51.y + 8u));
    let _e487 = bitcast<vec2<i32>>(_e486);
    let _e488 = (_e487 + vec2<i32>(0i, -1i));
    let _e490 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e488) < bitcast<vec2<u32>>(vec2<i32>(_e490)))) {
        let _e495 = textureLoad(global_1, _e488, 0i);
        phi_4833_ = _e495;
    } else {
        phi_4833_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e497 = phi_4833_;
    let _e499 = (_e497.xyz * _e69);
    let _e503 = (_e487 + vec2<i32>(-1i, 0i));
    let _e505 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e503) < bitcast<vec2<u32>>(vec2<i32>(_e505)))) {
        let _e510 = textureLoad(global_1, _e503, 0i);
        phi_4834_ = _e510;
    } else {
        phi_4834_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e512 = phi_4834_;
    let _e514 = (_e512.xyz * _e69);
    let _e518 = textureDimensions(global_1, 0i);
    if all((_e486 < bitcast<vec2<u32>>(vec2<i32>(_e518)))) {
        let _e523 = textureLoad(global_1, _e487, 0i);
        phi_4835_ = _e523;
    } else {
        phi_4835_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e525 = phi_4835_;
    let _e527 = (_e525.xyz * _e69);
    let _e531 = (_e487 + vec2<i32>(1i, 0i));
    let _e533 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e531) < bitcast<vec2<u32>>(vec2<i32>(_e533)))) {
        let _e538 = textureLoad(global_1, _e531, 0i);
        phi_4836_ = _e538;
    } else {
        phi_4836_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e540 = phi_4836_;
    let _e542 = (_e540.xyz * _e69);
    let _e546 = (_e487 + vec2<i32>(0i, 1i));
    let _e548 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e546) < bitcast<vec2<u32>>(vec2<i32>(_e548)))) {
        let _e553 = textureLoad(global_1, _e546, 0i);
        phi_4837_ = _e553;
    } else {
        phi_4837_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e555 = phi_4837_;
    let _e557 = (_e555.xyz * _e69);
    let _e564 = ((_e499.z * 0.5f) + ((_e499.x * 0.5f) + _e499.y));
    let _e568 = ((_e514.z * 0.5f) + ((_e514.x * 0.5f) + _e514.y));
    let _e572 = ((_e527.z * 0.5f) + ((_e527.x * 0.5f) + _e527.y));
    let _e576 = ((_e542.z * 0.5f) + ((_e542.x * 0.5f) + _e542.y));
    let _e580 = ((_e557.z * 0.5f) + ((_e557.x * 0.5f) + _e557.y));
    let _e595 = (max(max(_e564, max(_e568, _e572)), max(_e576, _e580)) - min(min(_e564, min(_e568, _e572)), min(_e576, _e580)));
    let _e598 = bitcast<f32>((2129764351u - bitcast<u32>(_e595)));
    let _e609 = min(min(_e499.x, min(_e514.x, _e542.x)), _e557.x);
    let _e612 = min(min(_e499.y, min(_e514.y, _e542.y)), _e557.y);
    let _e615 = min(min(_e499.z, min(_e514.z, _e542.z)), _e557.z);
    let _e618 = max(max(_e499.x, max(_e514.x, _e542.x)), _e557.x);
    let _e621 = max(max(_e499.y, max(_e514.y, _e542.y)), _e557.y);
    let _e624 = max(max(_e499.z, max(_e514.z, _e542.z)), _e557.z);
    let _e657 = ((max(-0.1875f, min(max(max(-((_e609 * (0.25f / _e618))), ((1f - _e618) * (1f / ((4f * _e609) + -4f)))), max(max(-((_e612 * (0.25f / _e621))), ((1f - _e621) * (1f / ((4f * _e612) + -4f)))), max(-((_e615 * (0.25f / _e624))), ((1f - _e624) * (1f / ((4f * _e615) + -4f)))))), 0f)) * _e228) * ((-0.5f * clamp((abs(((0.25f * (((_e564 + _e568) + _e576) + _e580)) - _e572)) * (_e598 * ((-(_e598) * _e595) + 2f))), 0f, 1f)) + 1f));
    let _e659 = ((4f * _e657) + 1f);
    let _e662 = bitcast<f32>((2129764351u - bitcast<u32>(_e659)));
    let _e666 = (_e662 * ((-(_e662) * _e659) + 2f));
    let _e686 = (vec3<f32>((((_e657 * (((_e499.x + _e514.x) + _e557.x) + _e542.x)) + _e527.x) * _e666), (((_e657 * (((_e499.y + _e514.y) + _e557.y) + _e542.y)) + _e527.y) * _e666), (((_e657 * (((_e499.z + _e514.z) + _e557.z) + _e542.z)) + _e527.z) * _e666)) / _e259);
    let _e687 = textureDimensions(global_2);
    if all((_e486 < bitcast<vec2<u32>>(vec2<i32>(_e687)))) {
        textureStore(global_2, _e487, vec4<f32>(_e686.x, _e686.y, _e686.z, 1f));
    }
    let _e698 = vec2<u32>(_e51.x, _e486.y);
    let _e699 = bitcast<vec2<i32>>(_e698);
    let _e700 = (_e699 + vec2<i32>(0i, -1i));
    let _e702 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e700) < bitcast<vec2<u32>>(vec2<i32>(_e702)))) {
        let _e707 = textureLoad(global_1, _e700, 0i);
        phi_4861_ = _e707;
    } else {
        phi_4861_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e709 = phi_4861_;
    let _e711 = (_e709.xyz * _e69);
    let _e715 = (_e699 + vec2<i32>(-1i, 0i));
    let _e717 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e715) < bitcast<vec2<u32>>(vec2<i32>(_e717)))) {
        let _e722 = textureLoad(global_1, _e715, 0i);
        phi_4862_ = _e722;
    } else {
        phi_4862_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e724 = phi_4862_;
    let _e726 = (_e724.xyz * _e69);
    let _e730 = textureDimensions(global_1, 0i);
    if all((_e698 < bitcast<vec2<u32>>(vec2<i32>(_e730)))) {
        let _e735 = textureLoad(global_1, _e699, 0i);
        phi_4863_ = _e735;
    } else {
        phi_4863_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e737 = phi_4863_;
    let _e739 = (_e737.xyz * _e69);
    let _e743 = (_e699 + vec2<i32>(1i, 0i));
    let _e745 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e743) < bitcast<vec2<u32>>(vec2<i32>(_e745)))) {
        let _e750 = textureLoad(global_1, _e743, 0i);
        phi_4864_ = _e750;
    } else {
        phi_4864_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e752 = phi_4864_;
    let _e754 = (_e752.xyz * _e69);
    let _e758 = (_e699 + vec2<i32>(0i, 1i));
    let _e760 = textureDimensions(global_1, 0i);
    if all((bitcast<vec2<u32>>(_e758) < bitcast<vec2<u32>>(vec2<i32>(_e760)))) {
        let _e765 = textureLoad(global_1, _e758, 0i);
        phi_4865_ = _e765;
    } else {
        phi_4865_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e767 = phi_4865_;
    let _e769 = (_e767.xyz * _e69);
    let _e776 = ((_e711.z * 0.5f) + ((_e711.x * 0.5f) + _e711.y));
    let _e780 = ((_e726.z * 0.5f) + ((_e726.x * 0.5f) + _e726.y));
    let _e784 = ((_e739.z * 0.5f) + ((_e739.x * 0.5f) + _e739.y));
    let _e788 = ((_e754.z * 0.5f) + ((_e754.x * 0.5f) + _e754.y));
    let _e792 = ((_e769.z * 0.5f) + ((_e769.x * 0.5f) + _e769.y));
    let _e807 = (max(max(_e776, max(_e780, _e784)), max(_e788, _e792)) - min(min(_e776, min(_e780, _e784)), min(_e788, _e792)));
    let _e810 = bitcast<f32>((2129764351u - bitcast<u32>(_e807)));
    let _e821 = min(min(_e711.x, min(_e726.x, _e754.x)), _e769.x);
    let _e824 = min(min(_e711.y, min(_e726.y, _e754.y)), _e769.y);
    let _e827 = min(min(_e711.z, min(_e726.z, _e754.z)), _e769.z);
    let _e830 = max(max(_e711.x, max(_e726.x, _e754.x)), _e769.x);
    let _e833 = max(max(_e711.y, max(_e726.y, _e754.y)), _e769.y);
    let _e836 = max(max(_e711.z, max(_e726.z, _e754.z)), _e769.z);
    let _e869 = ((max(-0.1875f, min(max(max(-((_e821 * (0.25f / _e830))), ((1f - _e830) * (1f / ((4f * _e821) + -4f)))), max(max(-((_e824 * (0.25f / _e833))), ((1f - _e833) * (1f / ((4f * _e824) + -4f)))), max(-((_e827 * (0.25f / _e836))), ((1f - _e836) * (1f / ((4f * _e827) + -4f)))))), 0f)) * _e228) * ((-0.5f * clamp((abs(((0.25f * (((_e776 + _e780) + _e788) + _e792)) - _e784)) * (_e810 * ((-(_e810) * _e807) + 2f))), 0f, 1f)) + 1f));
    let _e871 = ((4f * _e869) + 1f);
    let _e874 = bitcast<f32>((2129764351u - bitcast<u32>(_e871)));
    let _e878 = (_e874 * ((-(_e874) * _e871) + 2f));
    let _e898 = (vec3<f32>((((_e869 * (((_e711.x + _e726.x) + _e769.x) + _e754.x)) + _e739.x) * _e878), (((_e869 * (((_e711.y + _e726.y) + _e769.y) + _e754.y)) + _e739.y) * _e878), (((_e869 * (((_e711.z + _e726.z) + _e769.z) + _e754.z)) + _e739.z) * _e878)) / _e259);
    let _e899 = textureDimensions(global_2);
    if all((_e698 < bitcast<vec2<u32>>(vec2<i32>(_e899)))) {
        textureStore(global_2, _e699, vec4<f32>(_e898.x, _e898.y, _e898.z, 1f));
    }
    return;
}

@compute @workgroup_size(64, 1, 1) 
fn main(@builtin(local_invocation_id) param: vec3<u32>, @builtin(workgroup_id) param_1: vec3<u32>) {
    global_3 = param;
    global_4 = param_1;
    function_();
}
