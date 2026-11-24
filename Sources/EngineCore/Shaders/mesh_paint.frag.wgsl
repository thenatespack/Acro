// Generated from mesh_paint.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 1fa264a0ec117506
// glsl-fnv1a64: a46ad71f169736b6

diagnostic(off, derivative_uniformity);

struct type_21 {
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
    member_30: mat4x4<f32>,
    member_31: vec4<f32>,
    member_32: vec4<f32>,
    member_33: vec4<f32>,
    member_34: vec4<f32>,
}

struct type_38 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
}

struct type_43 {
    member: array<vec4<f32>, 1024>,
}

struct type_47 {
    member: array<vec4<u32>, 1024>,
}

struct FragmentOutput {
    @location(0) member: vec4<f32>,
    @location(1) member_1: vec2<f32>,
}

@group(0) @binding(0) 
var<uniform> global: type_21;
@group(1) @binding(1) 
var global_1: sampler_comparison;
@group(1) @binding(0) 
var global_2: texture_depth_2d;
@group(2) @binding(14) 
var global_3: texture_2d<f32>;
@group(2) @binding(17) 
var global_4: sampler;
@group(2) @binding(15) 
var global_5: texture_2d<f32>;
@group(2) @binding(23) 
var global_6: sampler;
@group(2) @binding(2) 
var<uniform> global_7: type_38;
var<private> global_8: vec3<f32>;
var<private> global_9: vec4<f32>;
var<private> global_10: vec3<f32>;
@group(2) @binding(3) 
var<uniform> global_11: type_43;
var<private> global_12: vec3<f32>;
@group(2) @binding(4) 
var<uniform> global_13: type_43;
@group(2) @binding(5) 
var<uniform> global_14: type_43;
var<private> global_15: vec4<f32>;
@group(2) @binding(6) 
var<uniform> global_16: type_47;
@group(2) @binding(7) 
var<uniform> global_17: type_47;
@group(2) @binding(12) 
var global_18: texture_2d<f32>;
var<private> global_19: vec2<f32>;
@group(2) @binding(9) 
var global_20: texture_2d<f32>;
var<private> global_21: vec4<f32>;
var<private> global_22: vec4<f32>;
@group(2) @binding(11) 
var global_23: texture_2d<f32>;
var<private> global_24: bool;
var<private> global_25: vec4<f32>;
@group(2) @binding(10) 
var global_26: texture_2d<f32>;
var<private> global_27: vec4<f32>;
@group(2) @binding(13) 
var global_28: texture_2d<f32>;
var<private> global_29: vec4<f32>;
var<private> global_30: vec2<f32>;
var<private> global_31: vec4<f32>;
var<private> global_32: vec4<f32>;

fn function_() {
    var local: array<vec2<f32>, 3>;
    var local_1: array<vec2<f32>, 3>;
    var local_2: array<vec2<f32>, 3>;
    var local_3: array<vec2<f32>, 3>;
    var local_4: array<vec3<f32>, 6>;
    var local_5: array<vec3<f32>, 6>;
    var local_6: array<vec4<i32>, 6>;
    var local_7: array<vec4<i32>, 6>;
    var local_8: array<f32, 9>;
    var local_9: array<vec2<f32>, 3>;
    var local_10: array<vec2<f32>, 3>;
    var local_11: array<vec2<f32>, 3>;
    var local_12: array<vec2<f32>, 3>;
    var local_13: array<vec3<f32>, 6>;
    var local_14: array<vec3<f32>, 6>;
    var local_15: array<f32, 9>;
    var local_16: array<vec2<f32>, 3>;
    var local_17: array<vec2<f32>, 3>;
    var local_18: array<vec2<f32>, 3>;
    var local_19: array<vec2<f32>, 3>;
    var local_20: array<vec3<f32>, 4>;
    var local_21: array<vec3<f32>, 4>;
    var phi_7693_: vec3<f32>;
    var phi_7691_: f32;
    var local_22: vec3<f32>;
    var phi_7854_: vec2<f32>;
    var phi_7821_: f32;
    var phi_7790_: vec3<f32>;
    var phi_7694_: vec2<f32>;
    var phi_7695_: vec3<f32>;
    var phi_7704_: vec3<f32>;
    var phi_7703_: vec3<f32>;
    var phi_7700_: f32;
    var phi_2340_: bool;
    var phi_7890_: vec3<f32>;
    var phi_7705_: i32;
    var phi_3952_: bool;
    var local_23: i32;
    var local_24: i32;
    var local_25: i32;
    var phi_4065_: bool;
    var phi_4072_: bool;
    var phi_4079_: bool;
    var local_26: i32;
    var local_27: i32;
    var local_28: i32;
    var phi_7710_: f32;
    var phi_7707_: i32;
    var phi_7716_: f32;
    var phi_7713_: i32;
    var local_29: f32;
    var phi_7717_: f32;
    var phi_7718_: f32;
    var local_30: i32;
    var local_31: i32;
    var local_32: i32;
    var phi_4352_: bool;
    var phi_4359_: bool;
    var phi_4366_: bool;
    var phi_7730_: f32;
    var phi_7727_: i32;
    var phi_7736_: f32;
    var phi_7733_: i32;
    var local_33: f32;
    var phi_7737_: f32;
    var phi_7738_: f32;
    var phi_7759_: f32;
    var phi_7756_: vec3<f32>;
    var phi_7758_: f32;
    var phi_7755_: vec3<f32>;
    var phi_7761_: vec3<f32>;
    var phi_7760_: f32;
    var phi_7924_: f32;
    var phi_7884_: vec3<f32>;
    var phi_7813_: f32;
    var phi_8014_: f32;
    var phi_8163_: vec3<f32>;
    var phi_8162_: i32;
    var local_34: vec3<f32>;
    var phi_8164_: vec3<f32>;
    var phi_8174_: vec3<f32>;
    var phi_8171_: u32;
    var phi_5007_: bool;
    var phi_5014_: bool;
    var phi_5021_: bool;
    var phi_5028_: bool;
    var phi_8238_: f32;
    var phi_8235_: i32;
    var phi_8244_: f32;
    var phi_8241_: i32;
    var local_35: f32;
    var phi_8245_: f32;
    var phi_5098_: bool;
    var phi_8223_: i32;
    var phi_8222_: i32;
    var phi_8220_: f32;
    var phi_8227_: f32;
    var phi_8224_: i32;
    var phi_8233_: f32;
    var phi_8230_: i32;
    var local_36: f32;
    var phi_8234_: f32;
    var phi_8246_: f32;
    var phi_8300_: vec3<f32>;
    var phi_8173_: vec3<f32>;
    var phi_7885_: f32;
    var phi_7880_: f32;
    var phi_7914_: vec3<f32>;
    var phi_7913_: vec3<f32>;
    var phi_7918_: f32;
    var phi_7917_: f32;
    var phi_8028_: vec3<f32>;
    var phi_7936_: vec3<f32>;
    var phi_7935_: i32;
    var local_37: vec3<f32>;
    var phi_7939_: i32;
    var phi_7940_: i32;
    var phi_7946_: i32;
    var phi_7947_: i32;
    var phi_7990_: vec3<f32>;
    var phi_7978_: vec2<f32>;
    var phi_7954_: vec3<f32>;
    var phi_2822_: bool;
    var phi_7974_: f32;
    var phi_7973_: vec3<f32>;
    var phi_7972_: i32;
    var local_38: vec3<f32>;
    var local_39: f32;
    var phi_7975_: vec3<f32>;
    var phi_7999_: vec3<f32>;
    var phi_8128_: vec3<f32>;
    var phi_8031_: u32;
    var phi_6689_: bool;
    var phi_6696_: bool;
    var phi_6703_: bool;
    var phi_6710_: bool;
    var phi_8050_: f32;
    var phi_8047_: i32;
    var phi_8056_: f32;
    var phi_8053_: i32;
    var local_40: f32;
    var phi_8057_: f32;
    var phi_6780_: bool;
    var phi_8035_: i32;
    var phi_8034_: i32;
    var phi_8032_: f32;
    var phi_8039_: f32;
    var phi_8036_: i32;
    var phi_8045_: f32;
    var phi_8042_: i32;
    var local_41: f32;
    var phi_8046_: f32;
    var phi_8058_: f32;
    var phi_8126_: vec3<f32>;
    var phi_8175_: vec3<f32>;
    var phi_8172_: vec3<f32>;
    var phi_8214_: f32;
    var phi_8217_: f32;
    var phi_8218_: vec3<f32>;
    var phi_8219_: vec2<f32>;
    var local_42: vec2<f32>;
    var local_43: f32;
    var local_44: f32;
    var local_45: vec3<f32>;
    var local_46: f32;
    var local_47: f32;
    var local_48: vec3<f32>;
    var local_49: vec3<f32>;
    var local_50: f32;
    var local_51: f32;
    var local_52: vec3<f32>;

    let _e231 = global_7.member_2;
    let _e233 = global_19;
    let _e237 = global_7.member_2[2u];
    let _e240 = global_7.member_3;
    let _e245 = global_7.member_3[2u];
    let _e247 = vec2<f32>((dot(_e231.xy, _e233) + _e237), (dot(_e240.xy, _e233) + _e245));
    let _e248 = textureSample(global_20, global_4, _e247);
    let _e249 = global_21;
    let _e250 = _e249.xyz;
    let _e252 = global_7.member;
    let _e255 = _e248.xyz;
    let _e258 = global_21[3u];
    let _e261 = global_7.member[3u];
    let _e265 = global_22;
    let _e267 = (((_e250 * _e252.xyz) * _e255) * _e265.xyz);
    let _e269 = global_22[3u];
    let _e273 = global_7.member_1[0u];
    phi_7693_ = _e267;
    if (_e273 > 0.5f) {
        let _e275 = global_12;
        let _e278 = floor((_e275.xz * vec2<f32>(0.5f, 0.5f)));
        let _e282 = abs((_e278.x + _e278.y));
        phi_7693_ = (_e267 * select(0.75f, 1f, ((_e282 - (floor((_e282 / 2f)) * 2f)) < 0.5f)));
    }
    let _e291 = phi_7693_;
    let _e294 = global_7.member_3[3u];
    phi_7854_ = vec2<f32>(0f, 0f);
    phi_7821_ = 0f;
    phi_7790_ = _e291;
    if (_e294 > 0.5f) {
        switch bitcast<i32>(0u) {
            default: {
                let _e299 = global_7.member_2[3u];
                let _e301 = vec4<f32>(_e299, _e294, 0f, 0f).xyy;
                let _e303 = floor((_e301 * vec3<f32>(0.000015258789f, 0.000015258789f, 0.000015258789f)));
                let _e305 = (_e301 - (_e303 * 65536f));
                let _e307 = floor((_e305 * vec3<f32>(0.00390625f, 0.00390625f, 0.00390625f)));
                let _e309 = (_e305 - (_e307 * 256f));
                let _e321 = (_e303.y - 128f);
                let _e328 = (floor((_e321 * 0.03125f)) * 0.33333334f);
                let _e332 = global_8;
                let _e333 = normalize(_e332);
                let _e334 = global_9;
                let _e335 = _e334.xyz;
                let _e336 = dot(_e333, _e335);
                let _e342 = ((_e336 / max(length((_e335 - (_e333 * _e336))), 0.000001f)) * 25.5f);
                local_22 = ((vec3<f32>(_e309.x, _e307.x, _e303.x) * vec3<f32>(0.003921569f, 0.003921569f, 0.003921569f)) * 2f);
                local_42 = (vec2<f32>(_e309.y, _e307.y) * vec2<f32>(0.003921569f, 0.003921569f));
                if ((-24f + _e342) < -2f) {
                    phi_7691_ = 0f;
                    break;
                }
                let _e345 = global_10;
                let _e346 = (_e345 * (4f * exp2(((_e321 - (floor((_e321 / 32f)) * 32f)) * 0.33333334f))));
                let _e347 = floor(_e346);
                let _e348 = (_e346 - _e347);
                let _e352 = ((_e348 * _e348) * (vec3<f32>(3f, 3f, 3f) - (_e348 * 2f)));
                let _e354 = bitcast<vec3<u32>>(vec3<i32>(_e347));
                let _e363 = ((((_e354.x * 1597334677u) ^ (_e354.y * 3812015801u)) ^ (_e354.z * 2798796415u)) * 1597334677u);
                let _e372 = bitcast<vec3<u32>>(vec3<i32>((_e347 + vec3<f32>(1f, 0f, 0f))));
                let _e381 = ((((_e372.x * 1597334677u) ^ (_e372.y * 3812015801u)) ^ (_e372.z * 2798796415u)) * 1597334677u);
                let _e392 = bitcast<vec3<u32>>(vec3<i32>((_e347 + vec3<f32>(0f, 1f, 0f))));
                let _e401 = ((((_e392.x * 1597334677u) ^ (_e392.y * 3812015801u)) ^ (_e392.z * 2798796415u)) * 1597334677u);
                let _e410 = bitcast<vec3<u32>>(vec3<i32>((_e347 + vec3<f32>(1f, 1f, 0f))));
                let _e419 = ((((_e410.x * 1597334677u) ^ (_e410.y * 3812015801u)) ^ (_e410.z * 2798796415u)) * 1597334677u);
                let _e431 = bitcast<vec3<u32>>(vec3<i32>((_e347 + vec3<f32>(0f, 0f, 1f))));
                let _e440 = ((((_e431.x * 1597334677u) ^ (_e431.y * 3812015801u)) ^ (_e431.z * 2798796415u)) * 1597334677u);
                let _e449 = bitcast<vec3<u32>>(vec3<i32>((_e347 + vec3<f32>(1f, 0f, 1f))));
                let _e458 = ((((_e449.x * 1597334677u) ^ (_e449.y * 3812015801u)) ^ (_e449.z * 2798796415u)) * 1597334677u);
                let _e468 = bitcast<vec3<u32>>(vec3<i32>((_e347 + vec3<f32>(0f, 1f, 1f))));
                let _e477 = ((((_e468.x * 1597334677u) ^ (_e468.y * 3812015801u)) ^ (_e468.z * 2798796415u)) * 1597334677u);
                let _e486 = bitcast<vec3<u32>>(vec3<i32>((_e347 + vec3<f32>(1f, 1f, 1f))));
                let _e495 = ((((_e486.x * 1597334677u) ^ (_e486.y * 3812015801u)) ^ (_e486.z * 2798796415u)) * 1597334677u);
                let _e508 = ((_e346 * 2.7f) + vec3<f32>(17.3f, 5.1f, 9.7f));
                let _e509 = floor(_e508);
                let _e510 = (_e508 - _e509);
                let _e514 = ((_e510 * _e510) * (vec3<f32>(3f, 3f, 3f) - (_e510 * 2f)));
                let _e516 = bitcast<vec3<u32>>(vec3<i32>(_e509));
                let _e525 = ((((_e516.x * 1597334677u) ^ (_e516.y * 3812015801u)) ^ (_e516.z * 2798796415u)) * 1597334677u);
                let _e534 = bitcast<vec3<u32>>(vec3<i32>((_e509 + vec3<f32>(1f, 0f, 0f))));
                let _e543 = ((((_e534.x * 1597334677u) ^ (_e534.y * 3812015801u)) ^ (_e534.z * 2798796415u)) * 1597334677u);
                let _e554 = bitcast<vec3<u32>>(vec3<i32>((_e509 + vec3<f32>(0f, 1f, 0f))));
                let _e563 = ((((_e554.x * 1597334677u) ^ (_e554.y * 3812015801u)) ^ (_e554.z * 2798796415u)) * 1597334677u);
                let _e572 = bitcast<vec3<u32>>(vec3<i32>((_e509 + vec3<f32>(1f, 1f, 0f))));
                let _e581 = ((((_e572.x * 1597334677u) ^ (_e572.y * 3812015801u)) ^ (_e572.z * 2798796415u)) * 1597334677u);
                let _e593 = bitcast<vec3<u32>>(vec3<i32>((_e509 + vec3<f32>(0f, 0f, 1f))));
                let _e602 = ((((_e593.x * 1597334677u) ^ (_e593.y * 3812015801u)) ^ (_e593.z * 2798796415u)) * 1597334677u);
                let _e611 = bitcast<vec3<u32>>(vec3<i32>((_e509 + vec3<f32>(1f, 0f, 1f))));
                let _e620 = ((((_e611.x * 1597334677u) ^ (_e611.y * 3812015801u)) ^ (_e611.z * 2798796415u)) * 1597334677u);
                let _e630 = bitcast<vec3<u32>>(vec3<i32>((_e509 + vec3<f32>(0f, 1f, 1f))));
                let _e639 = ((((_e630.x * 1597334677u) ^ (_e630.y * 3812015801u)) ^ (_e630.z * 2798796415u)) * 1597334677u);
                let _e648 = bitcast<vec3<u32>>(vec3<i32>((_e509 + vec3<f32>(1f, 1f, 1f))));
                let _e657 = ((((_e648.x * 1597334677u) ^ (_e648.y * 3812015801u)) ^ (_e648.z * 2798796415u)) * 1597334677u);
                let _e670 = mix(0.45f, 0.05f, _e328);
                phi_7691_ = smoothstep(-(_e670), _e670, ((_e342 + -24.45f) + ((((mix(mix(mix((f32(((_e363 ^ (_e363 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e381 ^ (_e381 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e352.x), mix((f32(((_e401 ^ (_e401 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e419 ^ (_e419 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e352.x), _e352.y), mix(mix((f32(((_e440 ^ (_e440 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e458 ^ (_e458 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e352.x), mix((f32(((_e477 ^ (_e477 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e495 ^ (_e495 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e352.x), _e352.y), _e352.z) * 0.65f) + (mix(mix(mix((f32(((_e525 ^ (_e525 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e543 ^ (_e543 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e514.x), mix((f32(((_e563 ^ (_e563 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e581 ^ (_e581 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e514.x), _e514.y), mix(mix((f32(((_e602 ^ (_e602 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e620 ^ (_e620 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e514.x), mix((f32(((_e639 ^ (_e639 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e657 ^ (_e657 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e514.x), _e514.y), _e514.z) * 0.35f)) - 0.5f) * mix(0.8f, 2.2f, _e328))));
                break;
            }
        }
        let _e679 = phi_7691_;
        let _e681 = local_22;
        let _e3024 = local_42;
        phi_7854_ = _e3024;
        phi_7821_ = _e679;
        phi_7790_ = mix(_e291, ((_e250 * _e681) * mix(vec3<f32>(1f, 1f, 1f), (_e255 * 2f), vec3<f32>(0.5f, 0.5f, 0.5f))), vec3(_e679));
    }
    let _e689 = phi_7854_;
    let _e691 = phi_7821_;
    let _e693 = phi_7790_;
    let _e694 = global_8;
    let _e695 = normalize(_e694);
    let _e698 = global_7.member_6[1u];
    phi_7703_ = _e695;
    if (_e698 > 0.5f) {
        let _e700 = global_9;
        let _e701 = _e700.xyz;
        let _e704 = (_e701 - (_e695 * dot(_e695, _e701)));
        phi_7704_ = _e695;
        if (dot(_e704, _e704) > 0.000000000001f) {
            let _e707 = normalize(_e704);
            let _e710 = global_9[3u];
            let _e714 = textureSample(global_23, global_4, _e247);
            let _e717 = global_7.member_6[2u];
            if (_e717 > 0.5f) {
                if (_e717 > 1.5f) {
                    phi_7694_ = _e714.xw;
                } else {
                    phi_7694_ = _e714.xy;
                }
                let _e723 = phi_7694_;
                let _e725 = ((_e723 * 2f) - vec2<f32>(1f, 1f));
                phi_7695_ = vec3<f32>(_e725.x, _e725.y, sqrt(clamp((1f - dot(_e725, _e725)), 0f, 1f)));
            } else {
                phi_7695_ = ((_e714.xyz * 2f) - vec3<f32>(1f, 1f, 1f));
            }
            let _e737 = phi_7695_;
            let _e740 = global_7.member_4[2u];
            let _e742 = (_e737.xy * _e740);
            phi_7704_ = normalize((((_e707 * _e742.x) + ((cross(_e695, _e707) * select(1f, -1f, (_e710 < 0f))) * _e742.y)) + (_e695 * _e737.z)));
        }
        let _e753 = phi_7704_;
        phi_7703_ = _e753;
    }
    let _e755 = phi_7703_;
    let _e758 = global_7.member_5[3u];
    let _e759 = (_e758 > 0.5f);
    if _e759 {
        let _e762 = global_7.member_1[2u];
        phi_7700_ = clamp(_e762, 0f, 1f);
    } else {
        phi_7700_ = 0f;
    }
    let _e765 = phi_7700_;
    phi_2340_ = _e759;
    if _e759 {
        let _e766 = global_24;
        phi_2340_ = !(_e766);
    }
    let _e769 = phi_2340_;
    phi_7890_ = _e755;
    if (_e769 && (_e765 <= 0f)) {
        phi_7890_ = -(_e755);
    }
    let _e774 = phi_7890_;
    let _e776 = global.member_4;
    let _e778 = normalize(_e776.xyz);
    let _e780 = global.member_6;
    let _e781 = _e780.xyz;
    let _e782 = global_12;
    let _e783 = (_e781 - _e782);
    let _e784 = normalize(_e783);
    let _e786 = normalize((_e778 + _e784));
    let _e787 = global_24;
    let _e789 = (_e695 * select(-1f, 1f, _e787));
    let _e791 = global_25[0u];
    let _e792 = (_e791 > 0.5f);
    let _e795 = global.member_5[3u];
    phi_7924_ = 1f;
    phi_7884_ = _e693;
    if ((_e795 > 0.5f) && _e792) {
        switch bitcast<i32>(0u) {
            default: {
                let _e801 = global.member_21[0u];
                let _e802 = i32(_e801);
                let _e804 = global.member_20;
                let _e809 = global.member_20[3u];
                let _e810 = (dot(_e804.xyz, _e782) + _e809);
                phi_7705_ = 0i;
                loop {
                    let _e812 = phi_7705_;
                    local_23 = _e812;
                    local_24 = _e812;
                    local_25 = _e812;
                    local_26 = _e812;
                    local_27 = _e812;
                    local_28 = _e812;
                    local_30 = _e812;
                    local_31 = _e812;
                    local_32 = _e812;
                    let _e814 = (_e812 < (_e802 - 1i));
                    phi_3952_ = _e814;
                    if _e814 {
                        let _e817 = global.member_16[_e812];
                        phi_3952_ = (_e810 > _e817);
                    }
                    let _e820 = phi_3952_;
                    if _e820 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_7705_ = (_e812 + 1i);
                    }
                }
                let _e824 = local_23;
                let _e826 = global.member_16[_e824];
                if (_e810 > _e826) {
                    phi_7761_ = vec3<f32>(1f, 1f, 1f);
                    phi_7760_ = 1f;
                    break;
                }
                let _e830 = local_24;
                let _e832 = global.member_18[_e830];
                let _e834 = (_e782 + (_e789 * _e832));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e838 = local_25;
                        let _e840 = global.member_14[_e838];
                        let _e845 = (_e840 * vec4<f32>(_e834.x, _e834.y, _e834.z, 1f));
                        let _e847 = (_e845.x < 0f);
                        phi_4065_ = _e847;
                        if !(_e847) {
                            phi_4065_ = (_e845.x > 1f);
                        }
                        let _e851 = phi_4065_;
                        phi_4072_ = _e851;
                        if !(_e851) {
                            phi_4072_ = (_e845.y < 0f);
                        }
                        let _e856 = phi_4072_;
                        phi_4079_ = _e856;
                        if !(_e856) {
                            phi_4079_ = (_e845.y > 1f);
                        }
                        let _e861 = phi_4079_;
                        if _e861 {
                            phi_7718_ = 1f;
                            break;
                        }
                        let _e863 = local_26;
                        let _e867 = local_27;
                        let _e873 = global.member_23;
                        let _e874 = _e873.xy;
                        let _e875 = (vec2<f32>(f32((_e863 & 1i)), f32((_e867 >> bitcast<u32>(1i)))) * _e874);
                        let _e880 = local_28;
                        let _e882 = global.member_19[_e880];
                        let _e883 = (min(_e845.z, 1f) - _e882);
                        let _e886 = global.member_22;
                        let _e887 = _e886.xy;
                        let _e888 = (_e887 * 0.5f);
                        let _e890 = (_e875 + (_e845.xy * _e874));
                        let _e891 = (_e875 + _e888);
                        let _e893 = ((_e875 + _e874) - _e888);
                        let _e898 = vec4<f32>(_e891.x, _e891.y, _e893.x, _e893.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e902 = global.member_22[2u];
                                let _e903 = i32(_e902);
                                if (_e903 <= 0i) {
                                    let _e907 = clamp(_e890, _e898.xy, _e898.zw);
                                    let _e912 = textureSampleCompare(global_2, global_1, vec3<f32>(_e907.x, _e907.y, _e883).xy, _e883);
                                    phi_7717_ = _e912;
                                    break;
                                }
                                let _e914 = ((_e890 / _e887) + vec2<f32>(0.5f, 0.5f));
                                let _e915 = floor(_e914);
                                let _e916 = (_e914 - _e915);
                                let _e918 = (_e903 == 1i);
                                if _e918 {
                                    let _e919 = (_e916 * 2f);
                                    local_18[0i] = (vec2<f32>(3f, 3f) - _e919);
                                    local_18[1i] = (vec2<f32>(1f, 1f) + _e919);
                                    let _e925 = local_18[0i];
                                    local_19[0i] = (((vec2<f32>(2f, 2f) - _e916) / _e925) - vec2<f32>(1f, 1f));
                                    let _e929 = local_18[1i];
                                    local_19[1i] = ((_e916 / _e929) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e933 = (_e916 * 3f);
                                    local_18[0i] = (vec2<f32>(4f, 4f) - _e933);
                                    local_18[1i] = vec2<f32>(7f, 7f);
                                    local_18[2i] = (vec2<f32>(1f, 1f) + _e933);
                                    let _e941 = local_18[0i];
                                    local_19[0i] = (((vec2<f32>(3f, 3f) - (_e916 * 2f)) / _e941) - vec2<f32>(2f, 2f));
                                    let _e946 = local_18[1i];
                                    local_19[1i] = ((vec2<f32>(3f, 3f) + _e916) / _e946);
                                    let _e949 = local_18[2i];
                                    local_19[2i] = ((_e916 / _e949) + vec2<f32>(2f, 2f));
                                }
                                let _e954 = select(3i, 2i, _e918);
                                phi_7710_ = 0f;
                                phi_7707_ = 0i;
                                loop {
                                    let _e956 = phi_7710_;
                                    let _e958 = phi_7707_;
                                    local_29 = _e956;
                                    if (_e958 < _e954) {
                                        phi_7716_ = _e956;
                                        phi_7713_ = 0i;
                                        loop {
                                            let _e961 = phi_7716_;
                                            let _e963 = phi_7713_;
                                            local_43 = _e961;
                                            if (_e963 < _e954) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e967 = local_19[_e963][0u];
                                                let _e970 = local_19[_e958][1u];
                                                let _e976 = clamp((_e887 * ((_e915 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e967, _e970))), _e898.xy, _e898.zw);
                                                let _e979 = local_18[_e963][0u];
                                                let _e982 = local_18[_e958][1u];
                                                let _e988 = textureSampleCompare(global_2, global_1, vec3<f32>(_e976.x, _e976.y, _e883).xy, _e883);
                                                phi_7716_ = (_e961 + ((_e979 * _e982) * _e988));
                                                phi_7713_ = (_e963 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e3047 = local_43;
                                        phi_7710_ = _e3047;
                                        phi_7707_ = (_e958 + 1i);
                                    }
                                }
                                let _e994 = local_29;
                                phi_7717_ = (_e994 * select(0.0069444445f, 0.0625f, _e918));
                                break;
                            }
                        }
                        let _e997 = phi_7717_;
                        phi_7718_ = _e997;
                        break;
                    }
                }
                let _e999 = phi_7718_;
                local_20 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e1001 = local_30;
                let _e1003 = local_20[_e1001];
                let _e1006 = local_31;
                let _e1008 = global.member_17[_e1006];
                phi_7758_ = _e999;
                phi_7755_ = _e1003;
                if (_e810 > _e1008) {
                    let _e1012 = ((_e810 - _e1008) / (_e826 - _e1008));
                    let _e1014 = local_32;
                    let _e1015 = (_e1014 + 1i);
                    if (_e1015 < _e802) {
                        let _e1019 = global.member_18[_e1015];
                        let _e1021 = (_e782 + (_e789 * _e1019));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1025 = global.member_14[_e1015];
                                let _e1030 = (_e1025 * vec4<f32>(_e1021.x, _e1021.y, _e1021.z, 1f));
                                let _e1032 = (_e1030.x < 0f);
                                phi_4352_ = _e1032;
                                if !(_e1032) {
                                    phi_4352_ = (_e1030.x > 1f);
                                }
                                let _e1036 = phi_4352_;
                                phi_4359_ = _e1036;
                                if !(_e1036) {
                                    phi_4359_ = (_e1030.y < 0f);
                                }
                                let _e1041 = phi_4359_;
                                phi_4366_ = _e1041;
                                if !(_e1041) {
                                    phi_4366_ = (_e1030.y > 1f);
                                }
                                let _e1046 = phi_4366_;
                                if _e1046 {
                                    phi_7738_ = 1f;
                                    break;
                                }
                                let _e1054 = global.member_23;
                                let _e1055 = _e1054.xy;
                                let _e1056 = (vec2<f32>(f32((_e1015 & 1i)), f32((_e1015 >> bitcast<u32>(1i)))) * _e1055);
                                let _e1061 = global.member_19[_e1015];
                                let _e1062 = (min(_e1030.z, 1f) - _e1061);
                                let _e1065 = global.member_22;
                                let _e1066 = _e1065.xy;
                                let _e1067 = (_e1066 * 0.5f);
                                let _e1069 = (_e1056 + (_e1030.xy * _e1055));
                                let _e1070 = (_e1056 + _e1067);
                                let _e1072 = ((_e1056 + _e1055) - _e1067);
                                let _e1077 = vec4<f32>(_e1070.x, _e1070.y, _e1072.x, _e1072.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1081 = global.member_22[2u];
                                        let _e1082 = i32(_e1081);
                                        if (_e1082 <= 0i) {
                                            let _e1086 = clamp(_e1069, _e1077.xy, _e1077.zw);
                                            let _e1091 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1086.x, _e1086.y, _e1062).xy, _e1062);
                                            phi_7737_ = _e1091;
                                            break;
                                        }
                                        let _e1093 = ((_e1069 / _e1066) + vec2<f32>(0.5f, 0.5f));
                                        let _e1094 = floor(_e1093);
                                        let _e1095 = (_e1093 - _e1094);
                                        let _e1097 = (_e1082 == 1i);
                                        if _e1097 {
                                            let _e1098 = (_e1095 * 2f);
                                            local_16[0i] = (vec2<f32>(3f, 3f) - _e1098);
                                            local_16[1i] = (vec2<f32>(1f, 1f) + _e1098);
                                            let _e1104 = local_16[0i];
                                            local_17[0i] = (((vec2<f32>(2f, 2f) - _e1095) / _e1104) - vec2<f32>(1f, 1f));
                                            let _e1108 = local_16[1i];
                                            local_17[1i] = ((_e1095 / _e1108) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1112 = (_e1095 * 3f);
                                            local_16[0i] = (vec2<f32>(4f, 4f) - _e1112);
                                            local_16[1i] = vec2<f32>(7f, 7f);
                                            local_16[2i] = (vec2<f32>(1f, 1f) + _e1112);
                                            let _e1120 = local_16[0i];
                                            local_17[0i] = (((vec2<f32>(3f, 3f) - (_e1095 * 2f)) / _e1120) - vec2<f32>(2f, 2f));
                                            let _e1125 = local_16[1i];
                                            local_17[1i] = ((vec2<f32>(3f, 3f) + _e1095) / _e1125);
                                            let _e1128 = local_16[2i];
                                            local_17[2i] = ((_e1095 / _e1128) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1133 = select(3i, 2i, _e1097);
                                        phi_7730_ = 0f;
                                        phi_7727_ = 0i;
                                        loop {
                                            let _e1135 = phi_7730_;
                                            let _e1137 = phi_7727_;
                                            local_33 = _e1135;
                                            if (_e1137 < _e1133) {
                                                phi_7736_ = _e1135;
                                                phi_7733_ = 0i;
                                                loop {
                                                    let _e1140 = phi_7736_;
                                                    let _e1142 = phi_7733_;
                                                    local_44 = _e1140;
                                                    if (_e1142 < _e1133) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1146 = local_17[_e1142][0u];
                                                        let _e1149 = local_17[_e1137][1u];
                                                        let _e1155 = clamp((_e1066 * ((_e1094 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1146, _e1149))), _e1077.xy, _e1077.zw);
                                                        let _e1158 = local_16[_e1142][0u];
                                                        let _e1161 = local_16[_e1137][1u];
                                                        let _e1167 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1155.x, _e1155.y, _e1062).xy, _e1062);
                                                        phi_7736_ = (_e1140 + ((_e1158 * _e1161) * _e1167));
                                                        phi_7733_ = (_e1142 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3062 = local_44;
                                                phi_7730_ = _e3062;
                                                phi_7727_ = (_e1137 + 1i);
                                            }
                                        }
                                        let _e1173 = local_33;
                                        phi_7737_ = (_e1173 * select(0.0069444445f, 0.0625f, _e1097));
                                        break;
                                    }
                                }
                                let _e1176 = phi_7737_;
                                phi_7738_ = _e1176;
                                break;
                            }
                        }
                        let _e1178 = phi_7738_;
                        local_21 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1181 = local_21[_e1015];
                        phi_7759_ = mix(_e999, _e1178, _e1012);
                        phi_7756_ = mix(_e1003, _e1181, vec3(_e1012));
                    } else {
                        phi_7759_ = mix(_e999, 1f, _e1012);
                        phi_7756_ = _e1003;
                    }
                    let _e1186 = phi_7759_;
                    let _e1188 = phi_7756_;
                    phi_7758_ = _e1186;
                    phi_7755_ = _e1188;
                }
                let _e1190 = phi_7758_;
                let _e1192 = phi_7755_;
                let _e1195 = global.member_22[3u];
                phi_7761_ = select(vec3<f32>(1f, 1f, 1f), _e1192, vec3((_e1195 > 0.5f)));
                phi_7760_ = _e1190;
                break;
            }
        }
        let _e1200 = phi_7761_;
        let _e1202 = phi_7760_;
        phi_7924_ = _e1202;
        phi_7884_ = (_e693 * _e1200);
    }
    let _e1205 = phi_7924_;
    let _e1207 = phi_7884_;
    let _e1209 = global.member_5;
    let _e1213 = global.member_4[3u];
    let _e1214 = (_e1209.xyz * _e1213);
    let _e1217 = global_7.member_6[3u];
    let _e1218 = (_e1217 > 0.5f);
    if _e1218 {
        phi_7813_ = 1f;
    } else {
        let _e1221 = global_7.member_4[3u];
        let _e1222 = textureSample(global_18, global_4, _e247);
        phi_7813_ = (1f + (_e1221 * (_e1222.x - 1f)));
    }
    let _e1228 = phi_7813_;
    let _e1230 = global_9[3u];
    let _e1231 = abs(_e1230);
    phi_8014_ = _e1228;
    if (_e1231 > 0f) {
        phi_8014_ = (_e1228 * min(_e1231, 1f));
    }
    let _e1236 = phi_8014_;
    if !(_e759) {
        let _e1238 = dot(_e774, _e778);
        let _e1245 = global_7.member_1[3u];
        let _e1249 = global_7.member_1[2u];
        let _e1256 = global.member_29[0u];
        if (_e1256 > 0.5f) {
            let _e1259 = global.member_29;
            let _e1266 = ((_e1259.z * _e774.x) - (_e1259.w * _e774.z));
            let _e1270 = ((_e1259.w * _e774.x) + (_e1259.z * _e774.z));
            let _e1274 = (1.092548f * _e1266);
            local_15 = array<f32, 9>(0.282095f, (0.488603f * _e774.y), (0.488603f * _e1270), (0.488603f * _e1266), (_e1274 * _e774.y), ((1.092548f * _e774.y) * _e1270), (0.315392f * (((3f * _e1270) * _e1270) - 1f)), (_e1274 * _e1270), (0.546274f * ((_e1266 * _e1266) - (_e774.y * _e774.y))));
            phi_8163_ = vec3<f32>(0f, 0f, 0f);
            phi_8162_ = 0i;
            loop {
                let _e1289 = phi_8163_;
                let _e1291 = phi_8162_;
                local_34 = _e1289;
                if (_e1291 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1295 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e1291, 0i)), 0i);
                    let _e1298 = local_15[_e1291];
                    phi_8163_ = (_e1289 + (_e1295.xyz * _e1298));
                    phi_8162_ = (_e1291 + 1i);
                }
            }
            let _e1303 = local_34;
            let _e1307 = global.member_29[1u];
            phi_8164_ = (max(_e1303, vec3<f32>(0f, 0f, 0f)) * _e1307);
        } else {
            let _e1310 = global.member_9;
            let _e1313 = global.member_8;
            let _e1322 = global.member_8[3u];
            phi_8164_ = (mix(_e1310.xyz, _e1313.xyz, vec3(((_e774.y * 0.5f) + 0.5f))) * _e1322);
        }
        let _e1325 = phi_8164_;
        let _e1331 = ((_e1207 * ((_e1325 * _e1236) + ((_e1214 * max(_e1238, 0f)) * _e1205))) + ((_e1214 * ((pow(max(dot(_e774, _e786), 0f), _e1245) * _e1249) * step(0f, _e1238))) * _e1205));
        let _e1334 = global.member_13[3u];
        phi_8173_ = _e1331;
        if (_e1334 > 0.5f) {
            let _e1337 = global.member_11;
            let _e1342 = global.member_11[3u];
            let _e1344 = global_15;
            let _e1347 = global.member_12;
            let _e1352 = global.member_13;
            let _e1355 = clamp(floor((_e1344.xy * _e1347.xy)), vec2<f32>(0f, 0f), (_e1352.xy - vec2<f32>(1f, 1f)));
            let _e1360 = global.member_12[2u];
            let _e1364 = global.member_12[3u];
            let _e1369 = global.member_13[2u];
            let _e1374 = global.member_13[1u];
            let _e1380 = global.member_13[0u];
            let _e1384 = u32(((((clamp(floor(((log2(max((dot(_e1337.xyz, _e782) + _e1342), 0.000001f)) * _e1360) + _e1364)), 0f, (_e1369 - 1f)) * _e1374) + _e1355.y) * _e1380) + _e1355.x));
            let _e1391 = global_16.member[(_e1384 >> bitcast<u32>(2i))][(_e1384 & 3u)];
            let _e1392 = (_e1391 & 65535u);
            phi_8174_ = _e1331;
            phi_8171_ = _e1392;
            loop {
                let _e1396 = phi_8174_;
                let _e1398 = phi_8171_;
                local_48 = _e1396;
                if (_e1398 < (_e1392 + (_e1391 >> bitcast<u32>(16i)))) {
                    let _e1401 = (_e1398 / 3u);
                    let _e1408 = global_17.member[(_e1401 >> bitcast<u32>(2i))][(_e1401 & 3u)];
                    let _e1414 = ((_e1408 >> bitcast<u32>(((_e1398 - (_e1401 * 3u)) * 10u))) & 1023u);
                    let _e1417 = global_11.member[_e1414];
                    let _e1419 = (_e1417.xyz - _e782);
                    let _e1420 = dot(_e1419, _e1419);
                    let _e1422 = (_e1420 * _e1417.w);
                    let _e1425 = clamp((1f - (_e1422 * _e1422)), 0f, 1f);
                    let _e1428 = (_e1419 * inverseSqrt(max(_e1420, 0.00000001f)));
                    let _e1431 = global_13.member[_e1414];
                    let _e1434 = global_14.member[_e1414];
                    let _e1442 = clamp(((dot(-(_e1428), _e1434.xyz) * _e1431.w) + _e1434.w), 0f, 1f);
                    let _e1449 = (_e1431.xyz * ((((_e1425 * _e1425) * _e1442) * _e1442) / max(_e1420, 0.0001f)));
                    phi_8300_ = _e1449;
                    if _e792 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1453 = global.member_21[2u];
                                let _e1454 = u32(_e1453);
                                if (_e1414 < _e1454) {
                                    let _e1458 = global.member_26[_e1414];
                                    let _e1461 = global.member_15[_e1414];
                                    let _e1470 = (_e1458.z * max((_e1461 * vec4<f32>(_e782.x, _e782.y, _e782.z, 1f)).w, 0f));
                                    let _e1473 = global.member_25[0u];
                                    let _e1479 = global.member_25[1u];
                                    let _e1482 = ((_e782 + (_e789 * (_e1470 * _e1473))) + (_e1428 * (_e1470 * _e1479)));
                                    let _e1487 = (_e1461 * vec4<f32>(_e1482.x, _e1482.y, _e1482.z, 1f));
                                    if (_e1487.w <= 0f) {
                                        phi_8246_ = 1f;
                                        break;
                                    }
                                    let _e1492 = (_e1487.xyz / vec3(_e1487.w));
                                    let _e1494 = (_e1492.x < 0f);
                                    phi_5007_ = _e1494;
                                    if !(_e1494) {
                                        phi_5007_ = (_e1492.x > 1f);
                                    }
                                    let _e1498 = phi_5007_;
                                    phi_5014_ = _e1498;
                                    if !(_e1498) {
                                        phi_5014_ = (_e1492.y < 0f);
                                    }
                                    let _e1503 = phi_5014_;
                                    phi_5021_ = _e1503;
                                    if !(_e1503) {
                                        phi_5021_ = (_e1492.y > 1f);
                                    }
                                    let _e1508 = phi_5021_;
                                    phi_5028_ = _e1508;
                                    if !(_e1508) {
                                        phi_5028_ = (_e1492.z > 1f);
                                    }
                                    let _e1513 = phi_5028_;
                                    if _e1513 {
                                        phi_8246_ = 1f;
                                        break;
                                    }
                                    let _e1516 = _e1458.xy;
                                    let _e1518 = global.member_23;
                                    let _e1519 = _e1518.zw;
                                    let _e1521 = global.member_22;
                                    let _e1522 = _e1521.xy;
                                    let _e1523 = (_e1522 * 0.5f);
                                    let _e1525 = (_e1516 + (_e1492.xy * _e1519));
                                    let _e1526 = (_e1516 + _e1523);
                                    let _e1528 = ((_e1516 + _e1519) - _e1523);
                                    let _e1533 = vec4<f32>(_e1526.x, _e1526.y, _e1528.x, _e1528.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e1537 = global.member_22[2u];
                                            let _e1538 = i32(_e1537);
                                            if (_e1538 <= 0i) {
                                                let _e1542 = clamp(_e1525, _e1533.xy, _e1533.zw);
                                                let _e1547 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1542.x, _e1542.y, _e1492.z).xy, _e1492.z);
                                                phi_8245_ = _e1547;
                                                break;
                                            }
                                            let _e1549 = ((_e1525 / _e1522) + vec2<f32>(0.5f, 0.5f));
                                            let _e1550 = floor(_e1549);
                                            let _e1551 = (_e1549 - _e1550);
                                            let _e1553 = (_e1538 == 1i);
                                            if _e1553 {
                                                let _e1554 = (_e1551 * 2f);
                                                local_11[0i] = (vec2<f32>(3f, 3f) - _e1554);
                                                local_11[1i] = (vec2<f32>(1f, 1f) + _e1554);
                                                let _e1560 = local_11[0i];
                                                local_12[0i] = (((vec2<f32>(2f, 2f) - _e1551) / _e1560) - vec2<f32>(1f, 1f));
                                                let _e1564 = local_11[1i];
                                                local_12[1i] = ((_e1551 / _e1564) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e1568 = (_e1551 * 3f);
                                                local_11[0i] = (vec2<f32>(4f, 4f) - _e1568);
                                                local_11[1i] = vec2<f32>(7f, 7f);
                                                local_11[2i] = (vec2<f32>(1f, 1f) + _e1568);
                                                let _e1576 = local_11[0i];
                                                local_12[0i] = (((vec2<f32>(3f, 3f) - (_e1551 * 2f)) / _e1576) - vec2<f32>(2f, 2f));
                                                let _e1581 = local_11[1i];
                                                local_12[1i] = ((vec2<f32>(3f, 3f) + _e1551) / _e1581);
                                                let _e1584 = local_11[2i];
                                                local_12[2i] = ((_e1551 / _e1584) + vec2<f32>(2f, 2f));
                                            }
                                            let _e1589 = select(3i, 2i, _e1553);
                                            phi_8238_ = 0f;
                                            phi_8235_ = 0i;
                                            loop {
                                                let _e1591 = phi_8238_;
                                                let _e1593 = phi_8235_;
                                                local_35 = _e1591;
                                                if (_e1593 < _e1589) {
                                                    phi_8244_ = _e1591;
                                                    phi_8241_ = 0i;
                                                    loop {
                                                        let _e1596 = phi_8244_;
                                                        let _e1598 = phi_8241_;
                                                        local_46 = _e1596;
                                                        if (_e1598 < _e1589) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e1602 = local_12[_e1598][0u];
                                                            let _e1605 = local_12[_e1593][1u];
                                                            let _e1611 = clamp((_e1522 * ((_e1550 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1602, _e1605))), _e1533.xy, _e1533.zw);
                                                            let _e1614 = local_11[_e1598][0u];
                                                            let _e1617 = local_11[_e1593][1u];
                                                            let _e1623 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1611.x, _e1611.y, _e1492.z).xy, _e1492.z);
                                                            phi_8244_ = (_e1596 + ((_e1614 * _e1617) * _e1623));
                                                            phi_8241_ = (_e1598 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e3093 = local_46;
                                                    phi_8238_ = _e3093;
                                                    phi_8235_ = (_e1593 + 1i);
                                                }
                                            }
                                            let _e1629 = local_35;
                                            phi_8245_ = (_e1629 * select(0.0069444445f, 0.0625f, _e1553));
                                            break;
                                        }
                                    }
                                    let _e1632 = phi_8245_;
                                    phi_8246_ = _e1632;
                                    break;
                                }
                                let _e1633 = (_e1414 - _e1454);
                                let _e1636 = global.member_21[3u];
                                if (_e1633 >= u32(_e1636)) {
                                    phi_8246_ = 1f;
                                    break;
                                }
                                let _e1641 = global.member_27[_e1633];
                                let _e1644 = global.member_28[_e1633];
                                let _e1646 = _e1641.xyz;
                                let _e1649 = (_e1641.w * length((_e782 - _e1646)));
                                let _e1652 = global.member_25[0u];
                                let _e1658 = global.member_25[1u];
                                let _e1662 = (((_e782 + (_e789 * (_e1649 * _e1652))) + (_e1428 * (_e1649 * _e1658))) - _e1646);
                                let _e1663 = abs(_e1662);
                                let _e1666 = (_e1663.x >= _e1663.y);
                                phi_5098_ = _e1666;
                                if _e1666 {
                                    phi_5098_ = (_e1663.x >= _e1663.z);
                                }
                                let _e1670 = phi_5098_;
                                if _e1670 {
                                    phi_8222_ = select(1i, 0i, (_e1662.x > 0f));
                                    phi_8220_ = _e1663.x;
                                } else {
                                    let _e1675 = (_e1663.y >= _e1663.z);
                                    if _e1675 {
                                        phi_8223_ = select(3i, 2i, (_e1662.y > 0f));
                                    } else {
                                        phi_8223_ = select(5i, 4i, (_e1662.z > 0f));
                                    }
                                    let _e1683 = phi_8223_;
                                    phi_8222_ = _e1683;
                                    phi_8220_ = select(_e1663.z, _e1663.y, _e1675);
                                }
                                let _e1686 = phi_8222_;
                                let _e1688 = phi_8220_;
                                if (_e1688 <= 0f) {
                                    phi_8246_ = 1f;
                                    break;
                                }
                                local_13 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e1691 = local_13[_e1686];
                                local_14 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e1694 = local_14[_e1686];
                                let _e1699 = global.member_24[2u];
                                let _e1702 = (vec2<f32>(dot(_e1662, _e1691), dot(_e1662, _e1694)) / vec2((_e1688 * _e1699)));
                                let _e1706 = (_e1644.z + (_e1644.w / _e1688));
                                if (_e1706 > 1f) {
                                    phi_8246_ = 1f;
                                    break;
                                }
                                let _e1721 = global.member_24;
                                let _e1722 = _e1721.xy;
                                let _e1724 = (_e1644.xy + (vec2<f32>(f32((_e1686 - (i32(floor((f32(_e1686) / f32(3i)))) * 3i))), f32((_e1686 / 3i))) * _e1722));
                                let _e1733 = global.member_22;
                                let _e1734 = _e1733.xy;
                                let _e1735 = (_e1734 * 0.5f);
                                let _e1737 = (_e1724 + (vec2<f32>((0.5f + (0.5f * _e1702.x)), (0.5f - (0.5f * _e1702.y))) * _e1722));
                                let _e1738 = (_e1724 + _e1735);
                                let _e1740 = ((_e1724 + _e1722) - _e1735);
                                let _e1745 = vec4<f32>(_e1738.x, _e1738.y, _e1740.x, _e1740.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1749 = global.member_22[2u];
                                        let _e1750 = i32(_e1749);
                                        if (_e1750 <= 0i) {
                                            let _e1754 = clamp(_e1737, _e1745.xy, _e1745.zw);
                                            let _e1759 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1754.x, _e1754.y, _e1706).xy, _e1706);
                                            phi_8234_ = _e1759;
                                            break;
                                        }
                                        let _e1761 = ((_e1737 / _e1734) + vec2<f32>(0.5f, 0.5f));
                                        let _e1762 = floor(_e1761);
                                        let _e1763 = (_e1761 - _e1762);
                                        let _e1765 = (_e1750 == 1i);
                                        if _e1765 {
                                            let _e1766 = (_e1763 * 2f);
                                            local_9[0i] = (vec2<f32>(3f, 3f) - _e1766);
                                            local_9[1i] = (vec2<f32>(1f, 1f) + _e1766);
                                            let _e1772 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(2f, 2f) - _e1763) / _e1772) - vec2<f32>(1f, 1f));
                                            let _e1776 = local_9[1i];
                                            local_10[1i] = ((_e1763 / _e1776) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1780 = (_e1763 * 3f);
                                            local_9[0i] = (vec2<f32>(4f, 4f) - _e1780);
                                            local_9[1i] = vec2<f32>(7f, 7f);
                                            local_9[2i] = (vec2<f32>(1f, 1f) + _e1780);
                                            let _e1788 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(3f, 3f) - (_e1763 * 2f)) / _e1788) - vec2<f32>(2f, 2f));
                                            let _e1793 = local_9[1i];
                                            local_10[1i] = ((vec2<f32>(3f, 3f) + _e1763) / _e1793);
                                            let _e1796 = local_9[2i];
                                            local_10[2i] = ((_e1763 / _e1796) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1801 = select(3i, 2i, _e1765);
                                        phi_8227_ = 0f;
                                        phi_8224_ = 0i;
                                        loop {
                                            let _e1803 = phi_8227_;
                                            let _e1805 = phi_8224_;
                                            local_36 = _e1803;
                                            if (_e1805 < _e1801) {
                                                phi_8233_ = _e1803;
                                                phi_8230_ = 0i;
                                                loop {
                                                    let _e1808 = phi_8233_;
                                                    let _e1810 = phi_8230_;
                                                    local_47 = _e1808;
                                                    if (_e1810 < _e1801) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1814 = local_10[_e1810][0u];
                                                        let _e1817 = local_10[_e1805][1u];
                                                        let _e1823 = clamp((_e1734 * ((_e1762 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1814, _e1817))), _e1745.xy, _e1745.zw);
                                                        let _e1826 = local_9[_e1810][0u];
                                                        let _e1829 = local_9[_e1805][1u];
                                                        let _e1835 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1823.x, _e1823.y, _e1706).xy, _e1706);
                                                        phi_8233_ = (_e1808 + ((_e1826 * _e1829) * _e1835));
                                                        phi_8230_ = (_e1810 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3105 = local_47;
                                                phi_8227_ = _e3105;
                                                phi_8224_ = (_e1805 + 1i);
                                            }
                                        }
                                        let _e1841 = local_36;
                                        phi_8234_ = (_e1841 * select(0.0069444445f, 0.0625f, _e1765));
                                        break;
                                    }
                                }
                                let _e1844 = phi_8234_;
                                phi_8246_ = _e1844;
                                break;
                            }
                        }
                        let _e1846 = phi_8246_;
                        phi_8300_ = (_e1449 * _e1846);
                    }
                    let _e1849 = phi_8300_;
                    let _e1850 = dot(_e774, _e1428);
                    local_45 = (_e1396 + (((_e1207 * max(_e1850, 0f)) * _e1849) + (_e1849 * ((pow(max(dot(_e774, normalize((_e1428 + _e784))), 0f), _e1245) * _e1249) * step(0f, _e1850)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3085 = local_45;
                    phi_8174_ = _e3085;
                    phi_8171_ = (_e1398 + bitcast<u32>(1i));
                }
            }
            let _e3115 = local_48;
            phi_8173_ = _e3115;
        }
        let _e1868 = phi_8173_;
        phi_8172_ = _e1868;
    } else {
        let _e1869 = textureSample(global_26, global_4, _e247);
        let _e1872 = global_7.member_4[0u];
        let _e1876 = global_27[1u];
        let _e1878 = clamp(((_e1872 * _e1869.z) * _e1876), 0f, 1f);
        let _e1881 = global_7.member_4[1u];
        let _e1885 = global_27[0u];
        let _e1887 = clamp(((_e1881 * _e1869.y) * _e1885), 0.045f, 1f);
        phi_7885_ = _e1878;
        phi_7880_ = _e1887;
        if (_e691 > 0f) {
            phi_7885_ = mix(_e1878, _e689.y, _e691);
            phi_7880_ = mix(_e1887, max(_e689.x, 0.045f), _e691);
        }
        let _e1895 = phi_7885_;
        let _e1897 = phi_7880_;
        let _e1898 = (_e1897 * _e1897);
        let _e1900 = (_e1207 * (1f - _e1895));
        let _e1902 = mix(vec3<f32>(0.04f, 0.04f, 0.04f), _e1207, vec3(_e1895));
        let _e1903 = (_e765 > 0f);
        phi_7913_ = _e774;
        if _e1903 {
            let _e1904 = dpdx(_e782);
            let _e1905 = dpdy(_e782);
            let _e1906 = cross(_e1904, _e1905);
            phi_7914_ = _e774;
            if (dot(_e1906, _e1906) > 0.00000000000000000001f) {
                phi_7914_ = normalize(((normalize(_e1906) * select(1f, -1f, (dot(_e1906, _e784) < 0f))) + (_e774 - _e695)));
            }
            let _e1918 = phi_7914_;
            phi_7913_ = _e1918;
        }
        let _e1920 = phi_7913_;
        let _e1922 = max(dot(_e1920, _e784), 0.0001f);
        let _e1925 = dot(_e1920, _e778);
        let _e1926 = clamp(_e1925, 0f, 1f);
        let _e1928 = clamp(dot(_e1920, _e786), 0f, 1f);
        let _e1930 = clamp(dot(_e784, _e786), 0f, 1f);
        phi_7918_ = _e1922;
        phi_7917_ = _e1930;
        if _e1903 {
            phi_7918_ = max(_e1922, 0.5f);
            phi_7917_ = max(_e1930, 0.5f);
        }
        let _e1934 = phi_7918_;
        let _e1936 = phi_7917_;
        let _e1939 = (vec3<f32>(1f, 1f, 1f) - _e1902);
        let _e1941 = (_e1902 + (_e1939 * pow((1f - _e1936), 5f)));
        let _e1942 = (_e1898 * _e1898);
        let _e1944 = (_e1942 - 1f);
        let _e1946 = (((_e1928 * _e1928) * _e1944) + 1f);
        let _e1951 = (1f - _e1942);
        let _e1954 = sqrt((((_e1934 * _e1934) * _e1951) + _e1942));
        let _e1973 = ((((((vec3<f32>(1f, 1f, 1f) - _e1941) * _e1900) * clamp(dot(_e774, _e778), 0f, 1f)) + (((_e1941 * ((_e1942 / ((3.1415927f * _e1946) * _e1946)) * (0.5f / max(((_e1926 * _e1954) + (_e1934 * sqrt((((_e1926 * _e1926) * _e1951) + _e1942)))), 0.00001f)))) * 3.1415927f) * _e1926)) * _e1214) * _e1205);
        phi_8028_ = _e1973;
        if _e1903 {
            phi_8028_ = (_e1973 + (((((_e1900 * _e1214) * _e1205) * _e765) * clamp(-(_e1925), 0f, 1f)) * (0.35f + (0.65f * pow(clamp(dot(-(_e784), _e778), 0f, 1f), 3f)))));
        }
        let _e1989 = phi_8028_;
        let _e1992 = global.member_29[0u];
        if (_e1992 > 0.5f) {
            let _e1998 = textureSample(global_5, global_6, (((vec2<f32>(_e1934, _e1897) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
            let _e2001 = global.member_29;
            let _e2008 = ((_e2001.z * _e774.x) - (_e2001.w * _e774.z));
            let _e2012 = ((_e2001.w * _e774.x) + (_e2001.z * _e774.z));
            let _e2016 = (1.092548f * _e2008);
            local_8 = array<f32, 9>(0.282095f, (0.488603f * _e774.y), (0.488603f * _e2012), (0.488603f * _e2008), (_e2016 * _e774.y), ((1.092548f * _e774.y) * _e2012), (0.315392f * (((3f * _e2012) * _e2012) - 1f)), (_e2016 * _e2012), (0.546274f * ((_e2008 * _e2008) - (_e774.y * _e774.y))));
            phi_7936_ = vec3<f32>(0f, 0f, 0f);
            phi_7935_ = 0i;
            loop {
                let _e2031 = phi_7936_;
                let _e2033 = phi_7935_;
                local_37 = _e2031;
                if (_e2033 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e2037 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e2033, 0i)), 0i);
                    let _e2040 = local_8[_e2033];
                    phi_7936_ = (_e2031 + (_e2037.xyz * _e2040));
                    phi_7935_ = (_e2033 + 1i);
                }
            }
            let _e2045 = local_37;
            let _e2049 = global.member_29[1u];
            let _e2052 = reflect(-(_e784), _e1920);
            let _e2069 = vec2<f32>(((atan2(((_e2001.z * _e2052.x) - (_e2001.w * _e2052.z)), -(((_e2001.w * _e2052.x) + (_e2001.z * _e2052.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e2052.y, -1f, 1f)) * 0.31830987f));
            let _e2070 = (_e1897 * 5f);
            let _e2072 = min(i32(_e2070), 4i);
            local_6 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e2074 = local_6[_e2072];
            let _e2078 = ((_e2069 * vec2<f32>(_e2074.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e2079 = floor(_e2078);
            let _e2080 = (_e2078 - _e2079);
            let _e2082 = i32(_e2079.x);
            let _e2084 = i32(_e2079.y);
            phi_7939_ = _e2082;
            if (_e2082 < 0i) {
                phi_7939_ = (_e2082 + _e2074.z);
            }
            let _e2089 = phi_7939_;
            phi_7940_ = _e2089;
            if (_e2089 >= _e2074.z) {
                phi_7940_ = (_e2089 - _e2074.z);
            }
            let _e2094 = phi_7940_;
            let _e2095 = (_e2094 + 1i);
            let _e2097 = select(_e2095, 0i, (_e2095 == _e2074.z));
            let _e2101 = min((_e2084 + 1i), (_e2074.w - 1i));
            let _e2102 = max(_e2084, 0i);
            let _e2103 = _e2074.xy;
            let _e2106 = textureLoad(global_3, (_e2103 + vec2<i32>(_e2094, _e2102)), 0i);
            let _e2110 = textureLoad(global_3, (_e2103 + vec2<i32>(_e2097, _e2102)), 0i);
            let _e2114 = textureLoad(global_3, (_e2103 + vec2<i32>(_e2094, _e2101)), 0i);
            let _e2118 = textureLoad(global_3, (_e2103 + vec2<i32>(_e2097, _e2101)), 0i);
            let _e2121 = vec3(_e2080.x);
            local_7 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e2129 = local_7[(_e2072 + 1i)];
            let _e2133 = ((_e2069 * vec2<f32>(_e2129.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e2134 = floor(_e2133);
            let _e2135 = (_e2133 - _e2134);
            let _e2137 = i32(_e2134.x);
            let _e2139 = i32(_e2134.y);
            phi_7946_ = _e2137;
            if (_e2137 < 0i) {
                phi_7946_ = (_e2137 + _e2129.z);
            }
            let _e2144 = phi_7946_;
            phi_7947_ = _e2144;
            if (_e2144 >= _e2129.z) {
                phi_7947_ = (_e2144 - _e2129.z);
            }
            let _e2149 = phi_7947_;
            let _e2150 = (_e2149 + 1i);
            let _e2152 = select(_e2150, 0i, (_e2150 == _e2129.z));
            let _e2156 = min((_e2139 + 1i), (_e2129.w - 1i));
            let _e2157 = max(_e2139, 0i);
            let _e2158 = _e2129.xy;
            let _e2161 = textureLoad(global_3, (_e2158 + vec2<i32>(_e2149, _e2157)), 0i);
            let _e2165 = textureLoad(global_3, (_e2158 + vec2<i32>(_e2152, _e2157)), 0i);
            let _e2169 = textureLoad(global_3, (_e2158 + vec2<i32>(_e2149, _e2156)), 0i);
            let _e2173 = textureLoad(global_3, (_e2158 + vec2<i32>(_e2152, _e2156)), 0i);
            let _e2176 = vec3(_e2135.x);
            phi_7990_ = (max(_e2045, vec3<f32>(0f, 0f, 0f)) * _e2049);
            phi_7978_ = _e1998.xy;
            phi_7954_ = (mix(mix(mix(_e2106.xyz, _e2110.xyz, _e2121), mix(_e2114.xyz, _e2118.xyz, _e2121), vec3(_e2080.y)), mix(mix(_e2161.xyz, _e2165.xyz, _e2176), mix(_e2169.xyz, _e2173.xyz, _e2176), vec3(_e2135.y)), vec3((_e2070 - f32(_e2072)))) * _e2049);
        } else {
            let _e2188 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e1897) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
            let _e2201 = global.member_9;
            let _e2202 = _e2201.xyz;
            let _e2204 = global.member_8;
            let _e2205 = _e2204.xyz;
            let _e2213 = global.member_8[3u];
            let _e2214 = (mix(_e2202, _e2205, vec3(((_e774.y * 0.5f) + 0.5f))) * _e2213);
            phi_7990_ = _e2214;
            phi_7978_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e2188.x * _e2188.x), exp2((-9.28f * _e1934))) * _e2188.x) + _e2188.y)) + _e2188.zw);
            phi_7954_ = mix((mix(_e2202, _e2205, vec3(((reflect(-(_e784), _e1920).y * 0.5f) + 0.5f))) * _e2213), _e2214, vec3(_e1897));
        }
        let _e2226 = phi_7990_;
        let _e2228 = phi_7978_;
        let _e2230 = phi_7954_;
        phi_2822_ = _e1218;
        if _e1218 {
            let _e2233 = global.member_33[2u];
            phi_2822_ = (_e2233 > 0.5f);
        }
        let _e2236 = phi_2822_;
        phi_7999_ = _e2230;
        if _e2236 {
            switch bitcast<i32>(0u) {
                default: {
                    let _e2239 = global.member_31;
                    let _e2240 = _e2239.xyz;
                    let _e2243 = global.member_33[0u];
                    let _e2248 = global.member_31[3u];
                    let _e2257 = global.member_32[1u];
                    let _e2263 = global.member_32[0u];
                    let _e2266 = (((_e2263 * (1f - smoothstep((_e2243 * 0.5f), _e2243, abs((dot(_e2240, _e782) - _e2248))))) * smoothstep(0.5f, 0.9f, dot(_e789, _e2240))) * (1f - smoothstep((_e2257 * 0.5f), _e2257, _e1897)));
                    if (_e2266 <= 0f) {
                        phi_7975_ = _e2230;
                        break;
                    }
                    let _e2273 = global.member_32[3u];
                    let _e2275 = (_e782 + ((_e774 - (_e2240 * dot(_e774, _e2240))) * _e2273));
                    let _e2277 = global.member_30;
                    let _e2282 = (_e2277 * vec4<f32>(_e2275.x, _e2275.y, _e2275.z, 1f));
                    let _e2294 = global.member_32[2u];
                    phi_7974_ = 0f;
                    phi_7973_ = vec3<f32>(0f, 0f, 0f);
                    phi_7972_ = 0i;
                    loop {
                        let _e2297 = phi_7974_;
                        let _e2299 = phi_7973_;
                        let _e2301 = phi_7972_;
                        local_38 = _e2299;
                        local_39 = _e2297;
                        if (_e2301 < 12i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e2303 = f32(_e2301);
                            let _e2308 = (_e2303 * 2.3999631f);
                            let _e2312 = global.member_33[1u];
                            let _e2317 = ((((vec2<f32>(_e2282.x, -(_e2282.y)) / vec2(_e2282.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e2308) * _e2312), sin(_e2308)) * (sqrt(((_e2303 + 0.5f) * 0.083333336f)) * (_e2294 * _e1897))));
                            let _e2319 = min(_e2317, (vec2<f32>(1f, 1f) - _e2317));
                            let _e2323 = smoothstep(0f, 0.04f, min(_e2319.x, _e2319.y));
                            let _e2325 = textureSampleLevel(global_18, global_4, clamp(_e2317, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                            let _e2326 = _e2325.xyz;
                            phi_7974_ = (_e2297 + (_e2325.w * _e2323));
                            phi_7973_ = (_e2299 + ((_e2326 / (vec3<f32>(1f, 1f, 1f) - min(_e2326, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e2323));
                            phi_7972_ = (_e2301 + 1i);
                        }
                    }
                    let _e2337 = local_38;
                    let _e2340 = local_39;
                    phi_7975_ = mix(_e2230, ((_e2337 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e2230 * (1f - (_e2340 * 0.083333336f)))), vec3(_e2266));
                    break;
                }
            }
            let _e2348 = phi_7975_;
            phi_7999_ = _e2348;
        }
        let _e2350 = phi_7999_;
        let _e2355 = ((_e1902 * _e2228.x) + vec3(_e2228.y));
        let _e2362 = (_e1989 + (((((vec3<f32>(1f, 1f, 1f) - _e2355) * _e1900) * _e2226) + (_e2355 * _e2350)) * _e1236));
        let _e2365 = global.member_13[3u];
        phi_8175_ = _e2362;
        if (_e2365 > 0.5f) {
            let _e2368 = global.member_11;
            let _e2373 = global.member_11[3u];
            let _e2375 = global_15;
            let _e2378 = global.member_12;
            let _e2383 = global.member_13;
            let _e2386 = clamp(floor((_e2375.xy * _e2378.xy)), vec2<f32>(0f, 0f), (_e2383.xy - vec2<f32>(1f, 1f)));
            let _e2391 = global.member_12[2u];
            let _e2395 = global.member_12[3u];
            let _e2400 = global.member_13[2u];
            let _e2405 = global.member_13[1u];
            let _e2411 = global.member_13[0u];
            let _e2415 = u32(((((clamp(floor(((log2(max((dot(_e2368.xyz, _e782) + _e2373), 0.000001f)) * _e2391) + _e2395)), 0f, (_e2400 - 1f)) * _e2405) + _e2386.y) * _e2411) + _e2386.x));
            let _e2422 = global_16.member[(_e2415 >> bitcast<u32>(2i))][(_e2415 & 3u)];
            let _e2423 = (_e2422 & 65535u);
            phi_8128_ = _e2362;
            phi_8031_ = _e2423;
            loop {
                let _e2427 = phi_8128_;
                let _e2429 = phi_8031_;
                local_52 = _e2427;
                if (_e2429 < (_e2423 + (_e2422 >> bitcast<u32>(16i)))) {
                    let _e2432 = (_e2429 / 3u);
                    let _e2439 = global_17.member[(_e2432 >> bitcast<u32>(2i))][(_e2432 & 3u)];
                    let _e2445 = ((_e2439 >> bitcast<u32>(((_e2429 - (_e2432 * 3u)) * 10u))) & 1023u);
                    let _e2448 = global_11.member[_e2445];
                    let _e2450 = (_e2448.xyz - _e782);
                    let _e2451 = dot(_e2450, _e2450);
                    let _e2453 = (_e2451 * _e2448.w);
                    let _e2456 = clamp((1f - (_e2453 * _e2453)), 0f, 1f);
                    let _e2459 = (_e2450 * inverseSqrt(max(_e2451, 0.00000001f)));
                    let _e2462 = global_13.member[_e2445];
                    let _e2465 = global_14.member[_e2445];
                    let _e2473 = clamp(((dot(-(_e2459), _e2465.xyz) * _e2462.w) + _e2465.w), 0f, 1f);
                    let _e2480 = (_e2462.xyz * ((((_e2456 * _e2456) * _e2473) * _e2473) / max(_e2451, 0.0001f)));
                    phi_8126_ = _e2480;
                    if _e792 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e2484 = global.member_21[2u];
                                let _e2485 = u32(_e2484);
                                if (_e2445 < _e2485) {
                                    let _e2489 = global.member_26[_e2445];
                                    let _e2492 = global.member_15[_e2445];
                                    let _e2501 = (_e2489.z * max((_e2492 * vec4<f32>(_e782.x, _e782.y, _e782.z, 1f)).w, 0f));
                                    let _e2504 = global.member_25[0u];
                                    let _e2510 = global.member_25[1u];
                                    let _e2513 = ((_e782 + (_e789 * (_e2501 * _e2504))) + (_e2459 * (_e2501 * _e2510)));
                                    let _e2518 = (_e2492 * vec4<f32>(_e2513.x, _e2513.y, _e2513.z, 1f));
                                    if (_e2518.w <= 0f) {
                                        phi_8058_ = 1f;
                                        break;
                                    }
                                    let _e2523 = (_e2518.xyz / vec3(_e2518.w));
                                    let _e2525 = (_e2523.x < 0f);
                                    phi_6689_ = _e2525;
                                    if !(_e2525) {
                                        phi_6689_ = (_e2523.x > 1f);
                                    }
                                    let _e2529 = phi_6689_;
                                    phi_6696_ = _e2529;
                                    if !(_e2529) {
                                        phi_6696_ = (_e2523.y < 0f);
                                    }
                                    let _e2534 = phi_6696_;
                                    phi_6703_ = _e2534;
                                    if !(_e2534) {
                                        phi_6703_ = (_e2523.y > 1f);
                                    }
                                    let _e2539 = phi_6703_;
                                    phi_6710_ = _e2539;
                                    if !(_e2539) {
                                        phi_6710_ = (_e2523.z > 1f);
                                    }
                                    let _e2544 = phi_6710_;
                                    if _e2544 {
                                        phi_8058_ = 1f;
                                        break;
                                    }
                                    let _e2547 = _e2489.xy;
                                    let _e2549 = global.member_23;
                                    let _e2550 = _e2549.zw;
                                    let _e2552 = global.member_22;
                                    let _e2553 = _e2552.xy;
                                    let _e2554 = (_e2553 * 0.5f);
                                    let _e2556 = (_e2547 + (_e2523.xy * _e2550));
                                    let _e2557 = (_e2547 + _e2554);
                                    let _e2559 = ((_e2547 + _e2550) - _e2554);
                                    let _e2564 = vec4<f32>(_e2557.x, _e2557.y, _e2559.x, _e2559.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e2568 = global.member_22[2u];
                                            let _e2569 = i32(_e2568);
                                            if (_e2569 <= 0i) {
                                                let _e2573 = clamp(_e2556, _e2564.xy, _e2564.zw);
                                                let _e2578 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2573.x, _e2573.y, _e2523.z).xy, _e2523.z);
                                                phi_8057_ = _e2578;
                                                break;
                                            }
                                            let _e2580 = ((_e2556 / _e2553) + vec2<f32>(0.5f, 0.5f));
                                            let _e2581 = floor(_e2580);
                                            let _e2582 = (_e2580 - _e2581);
                                            let _e2584 = (_e2569 == 1i);
                                            if _e2584 {
                                                let _e2585 = (_e2582 * 2f);
                                                local_2[0i] = (vec2<f32>(3f, 3f) - _e2585);
                                                local_2[1i] = (vec2<f32>(1f, 1f) + _e2585);
                                                let _e2591 = local_2[0i];
                                                local_3[0i] = (((vec2<f32>(2f, 2f) - _e2582) / _e2591) - vec2<f32>(1f, 1f));
                                                let _e2595 = local_2[1i];
                                                local_3[1i] = ((_e2582 / _e2595) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e2599 = (_e2582 * 3f);
                                                local_2[0i] = (vec2<f32>(4f, 4f) - _e2599);
                                                local_2[1i] = vec2<f32>(7f, 7f);
                                                local_2[2i] = (vec2<f32>(1f, 1f) + _e2599);
                                                let _e2607 = local_2[0i];
                                                local_3[0i] = (((vec2<f32>(3f, 3f) - (_e2582 * 2f)) / _e2607) - vec2<f32>(2f, 2f));
                                                let _e2612 = local_2[1i];
                                                local_3[1i] = ((vec2<f32>(3f, 3f) + _e2582) / _e2612);
                                                let _e2615 = local_2[2i];
                                                local_3[2i] = ((_e2582 / _e2615) + vec2<f32>(2f, 2f));
                                            }
                                            let _e2620 = select(3i, 2i, _e2584);
                                            phi_8050_ = 0f;
                                            phi_8047_ = 0i;
                                            loop {
                                                let _e2622 = phi_8050_;
                                                let _e2624 = phi_8047_;
                                                local_40 = _e2622;
                                                if (_e2624 < _e2620) {
                                                    phi_8056_ = _e2622;
                                                    phi_8053_ = 0i;
                                                    loop {
                                                        let _e2627 = phi_8056_;
                                                        let _e2629 = phi_8053_;
                                                        local_50 = _e2627;
                                                        if (_e2629 < _e2620) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e2633 = local_3[_e2629][0u];
                                                            let _e2636 = local_3[_e2624][1u];
                                                            let _e2642 = clamp((_e2553 * ((_e2581 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2633, _e2636))), _e2564.xy, _e2564.zw);
                                                            let _e2645 = local_2[_e2629][0u];
                                                            let _e2648 = local_2[_e2624][1u];
                                                            let _e2654 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2642.x, _e2642.y, _e2523.z).xy, _e2523.z);
                                                            phi_8056_ = (_e2627 + ((_e2645 * _e2648) * _e2654));
                                                            phi_8053_ = (_e2629 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e3151 = local_50;
                                                    phi_8050_ = _e3151;
                                                    phi_8047_ = (_e2624 + 1i);
                                                }
                                            }
                                            let _e2660 = local_40;
                                            phi_8057_ = (_e2660 * select(0.0069444445f, 0.0625f, _e2584));
                                            break;
                                        }
                                    }
                                    let _e2663 = phi_8057_;
                                    phi_8058_ = _e2663;
                                    break;
                                }
                                let _e2664 = (_e2445 - _e2485);
                                let _e2667 = global.member_21[3u];
                                if (_e2664 >= u32(_e2667)) {
                                    phi_8058_ = 1f;
                                    break;
                                }
                                let _e2672 = global.member_27[_e2664];
                                let _e2675 = global.member_28[_e2664];
                                let _e2677 = _e2672.xyz;
                                let _e2680 = (_e2672.w * length((_e782 - _e2677)));
                                let _e2683 = global.member_25[0u];
                                let _e2689 = global.member_25[1u];
                                let _e2693 = (((_e782 + (_e789 * (_e2680 * _e2683))) + (_e2459 * (_e2680 * _e2689))) - _e2677);
                                let _e2694 = abs(_e2693);
                                let _e2697 = (_e2694.x >= _e2694.y);
                                phi_6780_ = _e2697;
                                if _e2697 {
                                    phi_6780_ = (_e2694.x >= _e2694.z);
                                }
                                let _e2701 = phi_6780_;
                                if _e2701 {
                                    phi_8034_ = select(1i, 0i, (_e2693.x > 0f));
                                    phi_8032_ = _e2694.x;
                                } else {
                                    let _e2706 = (_e2694.y >= _e2694.z);
                                    if _e2706 {
                                        phi_8035_ = select(3i, 2i, (_e2693.y > 0f));
                                    } else {
                                        phi_8035_ = select(5i, 4i, (_e2693.z > 0f));
                                    }
                                    let _e2714 = phi_8035_;
                                    phi_8034_ = _e2714;
                                    phi_8032_ = select(_e2694.z, _e2694.y, _e2706);
                                }
                                let _e2717 = phi_8034_;
                                let _e2719 = phi_8032_;
                                if (_e2719 <= 0f) {
                                    phi_8058_ = 1f;
                                    break;
                                }
                                local_4 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e2722 = local_4[_e2717];
                                local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e2725 = local_5[_e2717];
                                let _e2730 = global.member_24[2u];
                                let _e2733 = (vec2<f32>(dot(_e2693, _e2722), dot(_e2693, _e2725)) / vec2((_e2719 * _e2730)));
                                let _e2737 = (_e2675.z + (_e2675.w / _e2719));
                                if (_e2737 > 1f) {
                                    phi_8058_ = 1f;
                                    break;
                                }
                                let _e2752 = global.member_24;
                                let _e2753 = _e2752.xy;
                                let _e2755 = (_e2675.xy + (vec2<f32>(f32((_e2717 - (i32(floor((f32(_e2717) / f32(3i)))) * 3i))), f32((_e2717 / 3i))) * _e2753));
                                let _e2764 = global.member_22;
                                let _e2765 = _e2764.xy;
                                let _e2766 = (_e2765 * 0.5f);
                                let _e2768 = (_e2755 + (vec2<f32>((0.5f + (0.5f * _e2733.x)), (0.5f - (0.5f * _e2733.y))) * _e2753));
                                let _e2769 = (_e2755 + _e2766);
                                let _e2771 = ((_e2755 + _e2753) - _e2766);
                                let _e2776 = vec4<f32>(_e2769.x, _e2769.y, _e2771.x, _e2771.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e2780 = global.member_22[2u];
                                        let _e2781 = i32(_e2780);
                                        if (_e2781 <= 0i) {
                                            let _e2785 = clamp(_e2768, _e2776.xy, _e2776.zw);
                                            let _e2790 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2785.x, _e2785.y, _e2737).xy, _e2737);
                                            phi_8046_ = _e2790;
                                            break;
                                        }
                                        let _e2792 = ((_e2768 / _e2765) + vec2<f32>(0.5f, 0.5f));
                                        let _e2793 = floor(_e2792);
                                        let _e2794 = (_e2792 - _e2793);
                                        let _e2796 = (_e2781 == 1i);
                                        if _e2796 {
                                            let _e2797 = (_e2794 * 2f);
                                            local[0i] = (vec2<f32>(3f, 3f) - _e2797);
                                            local[1i] = (vec2<f32>(1f, 1f) + _e2797);
                                            let _e2803 = local[0i];
                                            local_1[0i] = (((vec2<f32>(2f, 2f) - _e2794) / _e2803) - vec2<f32>(1f, 1f));
                                            let _e2807 = local[1i];
                                            local_1[1i] = ((_e2794 / _e2807) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e2811 = (_e2794 * 3f);
                                            local[0i] = (vec2<f32>(4f, 4f) - _e2811);
                                            local[1i] = vec2<f32>(7f, 7f);
                                            local[2i] = (vec2<f32>(1f, 1f) + _e2811);
                                            let _e2819 = local[0i];
                                            local_1[0i] = (((vec2<f32>(3f, 3f) - (_e2794 * 2f)) / _e2819) - vec2<f32>(2f, 2f));
                                            let _e2824 = local[1i];
                                            local_1[1i] = ((vec2<f32>(3f, 3f) + _e2794) / _e2824);
                                            let _e2827 = local[2i];
                                            local_1[2i] = ((_e2794 / _e2827) + vec2<f32>(2f, 2f));
                                        }
                                        let _e2832 = select(3i, 2i, _e2796);
                                        phi_8039_ = 0f;
                                        phi_8036_ = 0i;
                                        loop {
                                            let _e2834 = phi_8039_;
                                            let _e2836 = phi_8036_;
                                            local_41 = _e2834;
                                            if (_e2836 < _e2832) {
                                                phi_8045_ = _e2834;
                                                phi_8042_ = 0i;
                                                loop {
                                                    let _e2839 = phi_8045_;
                                                    let _e2841 = phi_8042_;
                                                    local_51 = _e2839;
                                                    if (_e2841 < _e2832) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e2845 = local_1[_e2841][0u];
                                                        let _e2848 = local_1[_e2836][1u];
                                                        let _e2854 = clamp((_e2765 * ((_e2793 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2845, _e2848))), _e2776.xy, _e2776.zw);
                                                        let _e2857 = local[_e2841][0u];
                                                        let _e2860 = local[_e2836][1u];
                                                        let _e2866 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2854.x, _e2854.y, _e2737).xy, _e2737);
                                                        phi_8045_ = (_e2839 + ((_e2857 * _e2860) * _e2866));
                                                        phi_8042_ = (_e2841 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3163 = local_51;
                                                phi_8039_ = _e3163;
                                                phi_8036_ = (_e2836 + 1i);
                                            }
                                        }
                                        let _e2872 = local_41;
                                        phi_8046_ = (_e2872 * select(0.0069444445f, 0.0625f, _e2796));
                                        break;
                                    }
                                }
                                let _e2875 = phi_8046_;
                                phi_8058_ = _e2875;
                                break;
                            }
                        }
                        let _e2877 = phi_8058_;
                        phi_8126_ = (_e2480 * _e2877);
                    }
                    let _e2880 = phi_8126_;
                    let _e2882 = normalize((_e2459 + _e784));
                    let _e2884 = clamp(dot(_e774, _e2459), 0f, 1f);
                    let _e2886 = clamp(dot(_e774, _e2882), 0f, 1f);
                    let _e2892 = (_e1902 + (_e1939 * pow((1f - clamp(dot(_e784, _e2882), 0f, 1f)), 5f)));
                    let _e2895 = (((_e2886 * _e2886) * _e1944) + 1f);
                    local_49 = (_e2427 + (((((vec3<f32>(1f, 1f, 1f) - _e2892) * _e1900) + ((_e2892 * ((_e1942 / ((3.1415927f * _e2895) * _e2895)) * (0.5f / max(((_e2884 * _e1954) + (_e1934 * sqrt((((_e2884 * _e2884) * _e1951) + _e1942)))), 0.00001f)))) * 3.1415927f)) * _e2884) * _e2880));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3143 = local_49;
                    phi_8128_ = _e3143;
                    phi_8031_ = (_e2429 + bitcast<u32>(1i));
                }
            }
            let _e3173 = local_52;
            phi_8175_ = _e3173;
        }
        let _e2920 = phi_8175_;
        phi_8172_ = _e2920;
    }
    let _e2922 = phi_8172_;
    let _e2925 = global_7.member_1[1u];
    let _e2929 = global_7.member_5;
    let _e2931 = textureSample(global_28, global_4, _e247);
    let _e2934 = global_25;
    let _e2939 = global_27[2u];
    let _e2943 = -(length(_e783));
    let _e2946 = global.member_7[3u];
    let _e2952 = global.member_9[3u];
    phi_8217_ = (1f - exp((_e2943 * _e2946)));
    if (_e2952 != 0f) {
        let _e2956 = (_e2952 * (_e782 - _e781).y);
        if (abs(_e2956) < 0.0001f) {
            phi_8214_ = (1f - (0.5f * _e2956));
        } else {
            phi_8214_ = ((1f - exp(min(-(_e2956), 60f))) / _e2956);
        }
        let _e2967 = phi_8214_;
        let _e2971 = global.member_6[1u];
        let _e2974 = global.member_6[3u];
        phi_8217_ = (1f - exp(((_e2943 * (_e2946 * exp(min((-(_e2952) * (_e2971 - _e2974)), 30f)))) * _e2967)));
    }
    let _e2985 = phi_8217_;
    let _e2987 = global.member_7;
    let _e2990 = mix((mix(_e2922, _e1207, vec3(_e2925)) + (((_e2929.xyz * _e2931.xyz) * (vec3<f32>(1f, 1f, 1f) + _e2934.yzw)) * _e2939)), _e2987.xyz, vec3(_e2985));
    let _e2993 = global.member_33[3u];
    phi_8218_ = _e2990;
    if (_e2993 > 0.5f) {
        phi_8218_ = (_e2990 / (vec3<f32>(1f, 1f, 1f) + _e2990));
    }
    let _e2998 = phi_8218_;
    global_29 = vec4<f32>(_e2998.x, _e2998.y, _e2998.z, (((_e258 * _e261) * _e248.w) * _e269));
    let _e3003 = global_31;
    let _e3004 = global_32;
    switch bitcast<i32>(0u) {
        default: {
            if (_e3004.w <= 0f) {
                phi_8219_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_8219_ = (((_e3004.xy / vec2(_e3004.w)) - (_e3003.xy / vec2(_e3003.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e3018 = phi_8219_;
    global_30 = _e3018;
    return;
}

@fragment 
fn main(@location(1) param: vec3<f32>, @location(8) param_1: vec4<f32>, @location(4) param_2: vec3<f32>, @location(0) param_3: vec3<f32>, @builtin(position) param_4: vec4<f32>, @location(2) param_5: vec2<f32>, @location(3) param_6: vec4<f32>, @location(9) param_7: vec4<f32>, @builtin(front_facing) param_8: bool, @location(5) param_9: vec4<f32>, @location(10) param_10: vec4<f32>, @location(6) param_11: vec4<f32>, @location(7) param_12: vec4<f32>) -> FragmentOutput {
    global_8 = param;
    global_9 = param_1;
    global_10 = param_2;
    global_12 = param_3;
    global_15 = param_4;
    global_19 = param_5;
    global_21 = param_6;
    global_22 = param_7;
    global_24 = param_8;
    global_25 = param_9;
    global_27 = param_10;
    global_31 = param_11;
    global_32 = param_12;
    function_();
    let _e28 = global_29;
    let _e29 = global_30;
    return FragmentOutput(_e28, _e29);
}
