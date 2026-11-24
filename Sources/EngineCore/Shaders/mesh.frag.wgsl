// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 6789c53dcabdd880
// glsl-fnv1a64: 8ca1a5e24f97303a

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
@group(2) @binding(11) 
var global_22: texture_2d<f32>;
var<private> global_23: bool;
var<private> global_24: vec4<f32>;
@group(2) @binding(10) 
var global_25: texture_2d<f32>;
@group(2) @binding(13) 
var global_26: texture_2d<f32>;
var<private> global_27: vec4<f32>;
var<private> global_28: vec2<f32>;
var<private> global_29: vec4<f32>;
var<private> global_30: vec4<f32>;

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
    var phi_7674_: vec3<f32>;
    var phi_7672_: f32;
    var local_22: vec3<f32>;
    var phi_7835_: vec2<f32>;
    var phi_7802_: f32;
    var phi_7771_: vec3<f32>;
    var phi_7675_: vec2<f32>;
    var phi_7676_: vec3<f32>;
    var phi_7685_: vec3<f32>;
    var phi_7684_: vec3<f32>;
    var phi_7681_: f32;
    var phi_2331_: bool;
    var phi_7871_: vec3<f32>;
    var phi_7686_: i32;
    var phi_3933_: bool;
    var local_23: i32;
    var local_24: i32;
    var local_25: i32;
    var phi_4046_: bool;
    var phi_4053_: bool;
    var phi_4060_: bool;
    var local_26: i32;
    var local_27: i32;
    var local_28: i32;
    var phi_7691_: f32;
    var phi_7688_: i32;
    var phi_7697_: f32;
    var phi_7694_: i32;
    var local_29: f32;
    var phi_7698_: f32;
    var phi_7699_: f32;
    var local_30: i32;
    var local_31: i32;
    var local_32: i32;
    var phi_4333_: bool;
    var phi_4340_: bool;
    var phi_4347_: bool;
    var phi_7711_: f32;
    var phi_7708_: i32;
    var phi_7717_: f32;
    var phi_7714_: i32;
    var local_33: f32;
    var phi_7718_: f32;
    var phi_7719_: f32;
    var phi_7740_: f32;
    var phi_7737_: vec3<f32>;
    var phi_7739_: f32;
    var phi_7736_: vec3<f32>;
    var phi_7742_: vec3<f32>;
    var phi_7741_: f32;
    var phi_7905_: f32;
    var phi_7865_: vec3<f32>;
    var phi_7794_: f32;
    var phi_7995_: f32;
    var phi_8144_: vec3<f32>;
    var phi_8143_: i32;
    var local_34: vec3<f32>;
    var phi_8145_: vec3<f32>;
    var phi_8155_: vec3<f32>;
    var phi_8152_: u32;
    var phi_4988_: bool;
    var phi_4995_: bool;
    var phi_5002_: bool;
    var phi_5009_: bool;
    var phi_8219_: f32;
    var phi_8216_: i32;
    var phi_8225_: f32;
    var phi_8222_: i32;
    var local_35: f32;
    var phi_8226_: f32;
    var phi_5079_: bool;
    var phi_8204_: i32;
    var phi_8203_: i32;
    var phi_8201_: f32;
    var phi_8208_: f32;
    var phi_8205_: i32;
    var phi_8214_: f32;
    var phi_8211_: i32;
    var local_36: f32;
    var phi_8215_: f32;
    var phi_8227_: f32;
    var phi_8281_: vec3<f32>;
    var phi_8154_: vec3<f32>;
    var phi_7866_: f32;
    var phi_7861_: f32;
    var phi_7895_: vec3<f32>;
    var phi_7894_: vec3<f32>;
    var phi_7899_: f32;
    var phi_7898_: f32;
    var phi_8009_: vec3<f32>;
    var phi_7917_: vec3<f32>;
    var phi_7916_: i32;
    var local_37: vec3<f32>;
    var phi_7920_: i32;
    var phi_7921_: i32;
    var phi_7927_: i32;
    var phi_7928_: i32;
    var phi_7971_: vec3<f32>;
    var phi_7959_: vec2<f32>;
    var phi_7935_: vec3<f32>;
    var phi_2806_: bool;
    var phi_7955_: f32;
    var phi_7954_: vec3<f32>;
    var phi_7953_: i32;
    var local_38: vec3<f32>;
    var local_39: f32;
    var phi_7956_: vec3<f32>;
    var phi_7980_: vec3<f32>;
    var phi_8109_: vec3<f32>;
    var phi_8012_: u32;
    var phi_6670_: bool;
    var phi_6677_: bool;
    var phi_6684_: bool;
    var phi_6691_: bool;
    var phi_8031_: f32;
    var phi_8028_: i32;
    var phi_8037_: f32;
    var phi_8034_: i32;
    var local_40: f32;
    var phi_8038_: f32;
    var phi_6761_: bool;
    var phi_8016_: i32;
    var phi_8015_: i32;
    var phi_8013_: f32;
    var phi_8020_: f32;
    var phi_8017_: i32;
    var phi_8026_: f32;
    var phi_8023_: i32;
    var local_41: f32;
    var phi_8027_: f32;
    var phi_8039_: f32;
    var phi_8107_: vec3<f32>;
    var phi_8156_: vec3<f32>;
    var phi_8153_: vec3<f32>;
    var phi_8195_: f32;
    var phi_8198_: f32;
    var phi_8199_: vec3<f32>;
    var phi_8200_: vec2<f32>;
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

    let _e229 = global_7.member_2;
    let _e231 = global_19;
    let _e235 = global_7.member_2[2u];
    let _e238 = global_7.member_3;
    let _e243 = global_7.member_3[2u];
    let _e245 = vec2<f32>((dot(_e229.xy, _e231) + _e235), (dot(_e238.xy, _e231) + _e243));
    let _e246 = textureSample(global_20, global_4, _e245);
    let _e247 = global_21;
    let _e248 = _e247.xyz;
    let _e250 = global_7.member;
    let _e253 = _e246.xyz;
    let _e254 = ((_e248 * _e250.xyz) * _e253);
    let _e256 = global_21[3u];
    let _e259 = global_7.member[3u];
    let _e265 = global_7.member_1[0u];
    phi_7674_ = _e254;
    if (_e265 > 0.5f) {
        let _e267 = global_12;
        let _e270 = floor((_e267.xz * vec2<f32>(0.5f, 0.5f)));
        let _e274 = abs((_e270.x + _e270.y));
        phi_7674_ = (_e254 * select(0.75f, 1f, ((_e274 - (floor((_e274 / 2f)) * 2f)) < 0.5f)));
    }
    let _e283 = phi_7674_;
    let _e286 = global_7.member_3[3u];
    phi_7835_ = vec2<f32>(0f, 0f);
    phi_7802_ = 0f;
    phi_7771_ = _e283;
    if (_e286 > 0.5f) {
        switch bitcast<i32>(0u) {
            default: {
                let _e291 = global_7.member_2[3u];
                let _e293 = vec4<f32>(_e291, _e286, 0f, 0f).xyy;
                let _e295 = floor((_e293 * vec3<f32>(0.000015258789f, 0.000015258789f, 0.000015258789f)));
                let _e297 = (_e293 - (_e295 * 65536f));
                let _e299 = floor((_e297 * vec3<f32>(0.00390625f, 0.00390625f, 0.00390625f)));
                let _e301 = (_e297 - (_e299 * 256f));
                let _e313 = (_e295.y - 128f);
                let _e320 = (floor((_e313 * 0.03125f)) * 0.33333334f);
                let _e324 = global_8;
                let _e325 = normalize(_e324);
                let _e326 = global_9;
                let _e327 = _e326.xyz;
                let _e328 = dot(_e325, _e327);
                let _e334 = ((_e328 / max(length((_e327 - (_e325 * _e328))), 0.000001f)) * 25.5f);
                local_22 = ((vec3<f32>(_e301.x, _e299.x, _e295.x) * vec3<f32>(0.003921569f, 0.003921569f, 0.003921569f)) * 2f);
                local_42 = (vec2<f32>(_e301.y, _e299.y) * vec2<f32>(0.003921569f, 0.003921569f));
                if ((-24f + _e334) < -2f) {
                    phi_7672_ = 0f;
                    break;
                }
                let _e337 = global_10;
                let _e338 = (_e337 * (4f * exp2(((_e313 - (floor((_e313 / 32f)) * 32f)) * 0.33333334f))));
                let _e339 = floor(_e338);
                let _e340 = (_e338 - _e339);
                let _e344 = ((_e340 * _e340) * (vec3<f32>(3f, 3f, 3f) - (_e340 * 2f)));
                let _e346 = bitcast<vec3<u32>>(vec3<i32>(_e339));
                let _e355 = ((((_e346.x * 1597334677u) ^ (_e346.y * 3812015801u)) ^ (_e346.z * 2798796415u)) * 1597334677u);
                let _e364 = bitcast<vec3<u32>>(vec3<i32>((_e339 + vec3<f32>(1f, 0f, 0f))));
                let _e373 = ((((_e364.x * 1597334677u) ^ (_e364.y * 3812015801u)) ^ (_e364.z * 2798796415u)) * 1597334677u);
                let _e384 = bitcast<vec3<u32>>(vec3<i32>((_e339 + vec3<f32>(0f, 1f, 0f))));
                let _e393 = ((((_e384.x * 1597334677u) ^ (_e384.y * 3812015801u)) ^ (_e384.z * 2798796415u)) * 1597334677u);
                let _e402 = bitcast<vec3<u32>>(vec3<i32>((_e339 + vec3<f32>(1f, 1f, 0f))));
                let _e411 = ((((_e402.x * 1597334677u) ^ (_e402.y * 3812015801u)) ^ (_e402.z * 2798796415u)) * 1597334677u);
                let _e423 = bitcast<vec3<u32>>(vec3<i32>((_e339 + vec3<f32>(0f, 0f, 1f))));
                let _e432 = ((((_e423.x * 1597334677u) ^ (_e423.y * 3812015801u)) ^ (_e423.z * 2798796415u)) * 1597334677u);
                let _e441 = bitcast<vec3<u32>>(vec3<i32>((_e339 + vec3<f32>(1f, 0f, 1f))));
                let _e450 = ((((_e441.x * 1597334677u) ^ (_e441.y * 3812015801u)) ^ (_e441.z * 2798796415u)) * 1597334677u);
                let _e460 = bitcast<vec3<u32>>(vec3<i32>((_e339 + vec3<f32>(0f, 1f, 1f))));
                let _e469 = ((((_e460.x * 1597334677u) ^ (_e460.y * 3812015801u)) ^ (_e460.z * 2798796415u)) * 1597334677u);
                let _e478 = bitcast<vec3<u32>>(vec3<i32>((_e339 + vec3<f32>(1f, 1f, 1f))));
                let _e487 = ((((_e478.x * 1597334677u) ^ (_e478.y * 3812015801u)) ^ (_e478.z * 2798796415u)) * 1597334677u);
                let _e500 = ((_e338 * 2.7f) + vec3<f32>(17.3f, 5.1f, 9.7f));
                let _e501 = floor(_e500);
                let _e502 = (_e500 - _e501);
                let _e506 = ((_e502 * _e502) * (vec3<f32>(3f, 3f, 3f) - (_e502 * 2f)));
                let _e508 = bitcast<vec3<u32>>(vec3<i32>(_e501));
                let _e517 = ((((_e508.x * 1597334677u) ^ (_e508.y * 3812015801u)) ^ (_e508.z * 2798796415u)) * 1597334677u);
                let _e526 = bitcast<vec3<u32>>(vec3<i32>((_e501 + vec3<f32>(1f, 0f, 0f))));
                let _e535 = ((((_e526.x * 1597334677u) ^ (_e526.y * 3812015801u)) ^ (_e526.z * 2798796415u)) * 1597334677u);
                let _e546 = bitcast<vec3<u32>>(vec3<i32>((_e501 + vec3<f32>(0f, 1f, 0f))));
                let _e555 = ((((_e546.x * 1597334677u) ^ (_e546.y * 3812015801u)) ^ (_e546.z * 2798796415u)) * 1597334677u);
                let _e564 = bitcast<vec3<u32>>(vec3<i32>((_e501 + vec3<f32>(1f, 1f, 0f))));
                let _e573 = ((((_e564.x * 1597334677u) ^ (_e564.y * 3812015801u)) ^ (_e564.z * 2798796415u)) * 1597334677u);
                let _e585 = bitcast<vec3<u32>>(vec3<i32>((_e501 + vec3<f32>(0f, 0f, 1f))));
                let _e594 = ((((_e585.x * 1597334677u) ^ (_e585.y * 3812015801u)) ^ (_e585.z * 2798796415u)) * 1597334677u);
                let _e603 = bitcast<vec3<u32>>(vec3<i32>((_e501 + vec3<f32>(1f, 0f, 1f))));
                let _e612 = ((((_e603.x * 1597334677u) ^ (_e603.y * 3812015801u)) ^ (_e603.z * 2798796415u)) * 1597334677u);
                let _e622 = bitcast<vec3<u32>>(vec3<i32>((_e501 + vec3<f32>(0f, 1f, 1f))));
                let _e631 = ((((_e622.x * 1597334677u) ^ (_e622.y * 3812015801u)) ^ (_e622.z * 2798796415u)) * 1597334677u);
                let _e640 = bitcast<vec3<u32>>(vec3<i32>((_e501 + vec3<f32>(1f, 1f, 1f))));
                let _e649 = ((((_e640.x * 1597334677u) ^ (_e640.y * 3812015801u)) ^ (_e640.z * 2798796415u)) * 1597334677u);
                let _e662 = mix(0.45f, 0.05f, _e320);
                phi_7672_ = smoothstep(-(_e662), _e662, ((_e334 + -24.45f) + ((((mix(mix(mix((f32(((_e355 ^ (_e355 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e373 ^ (_e373 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e344.x), mix((f32(((_e393 ^ (_e393 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e411 ^ (_e411 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e344.x), _e344.y), mix(mix((f32(((_e432 ^ (_e432 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e450 ^ (_e450 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e344.x), mix((f32(((_e469 ^ (_e469 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e487 ^ (_e487 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e344.x), _e344.y), _e344.z) * 0.65f) + (mix(mix(mix((f32(((_e517 ^ (_e517 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e535 ^ (_e535 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e506.x), mix((f32(((_e555 ^ (_e555 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e573 ^ (_e573 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e506.x), _e506.y), mix(mix((f32(((_e594 ^ (_e594 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e612 ^ (_e612 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e506.x), mix((f32(((_e631 ^ (_e631 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e649 ^ (_e649 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e506.x), _e506.y), _e506.z) * 0.35f)) - 0.5f) * mix(0.8f, 2.2f, _e320))));
                break;
            }
        }
        let _e671 = phi_7672_;
        let _e673 = local_22;
        let _e3007 = local_42;
        phi_7835_ = _e3007;
        phi_7802_ = _e671;
        phi_7771_ = mix(_e283, ((_e248 * _e673) * mix(vec3<f32>(1f, 1f, 1f), (_e253 * 2f), vec3<f32>(0.5f, 0.5f, 0.5f))), vec3(_e671));
    }
    let _e681 = phi_7835_;
    let _e683 = phi_7802_;
    let _e685 = phi_7771_;
    let _e686 = global_8;
    let _e687 = normalize(_e686);
    let _e690 = global_7.member_6[1u];
    phi_7684_ = _e687;
    if (_e690 > 0.5f) {
        let _e692 = global_9;
        let _e693 = _e692.xyz;
        let _e696 = (_e693 - (_e687 * dot(_e687, _e693)));
        phi_7685_ = _e687;
        if (dot(_e696, _e696) > 0.000000000001f) {
            let _e699 = normalize(_e696);
            let _e702 = global_9[3u];
            let _e706 = textureSample(global_22, global_4, _e245);
            let _e709 = global_7.member_6[2u];
            if (_e709 > 0.5f) {
                if (_e709 > 1.5f) {
                    phi_7675_ = _e706.xw;
                } else {
                    phi_7675_ = _e706.xy;
                }
                let _e715 = phi_7675_;
                let _e717 = ((_e715 * 2f) - vec2<f32>(1f, 1f));
                phi_7676_ = vec3<f32>(_e717.x, _e717.y, sqrt(clamp((1f - dot(_e717, _e717)), 0f, 1f)));
            } else {
                phi_7676_ = ((_e706.xyz * 2f) - vec3<f32>(1f, 1f, 1f));
            }
            let _e729 = phi_7676_;
            let _e732 = global_7.member_4[2u];
            let _e734 = (_e729.xy * _e732);
            phi_7685_ = normalize((((_e699 * _e734.x) + ((cross(_e687, _e699) * select(1f, -1f, (_e702 < 0f))) * _e734.y)) + (_e687 * _e729.z)));
        }
        let _e745 = phi_7685_;
        phi_7684_ = _e745;
    }
    let _e747 = phi_7684_;
    let _e750 = global_7.member_5[3u];
    let _e751 = (_e750 > 0.5f);
    if _e751 {
        let _e754 = global_7.member_1[2u];
        phi_7681_ = clamp(_e754, 0f, 1f);
    } else {
        phi_7681_ = 0f;
    }
    let _e757 = phi_7681_;
    phi_2331_ = _e751;
    if _e751 {
        let _e758 = global_23;
        phi_2331_ = !(_e758);
    }
    let _e761 = phi_2331_;
    phi_7871_ = _e747;
    if (_e761 && (_e757 <= 0f)) {
        phi_7871_ = -(_e747);
    }
    let _e766 = phi_7871_;
    let _e768 = global.member_4;
    let _e770 = normalize(_e768.xyz);
    let _e772 = global.member_6;
    let _e773 = _e772.xyz;
    let _e774 = global_12;
    let _e775 = (_e773 - _e774);
    let _e776 = normalize(_e775);
    let _e778 = normalize((_e770 + _e776));
    let _e779 = global_23;
    let _e781 = (_e687 * select(-1f, 1f, _e779));
    let _e783 = global_24[0u];
    let _e784 = (_e783 > 0.5f);
    let _e787 = global.member_5[3u];
    phi_7905_ = 1f;
    phi_7865_ = _e685;
    if ((_e787 > 0.5f) && _e784) {
        switch bitcast<i32>(0u) {
            default: {
                let _e793 = global.member_21[0u];
                let _e794 = i32(_e793);
                let _e796 = global.member_20;
                let _e801 = global.member_20[3u];
                let _e802 = (dot(_e796.xyz, _e774) + _e801);
                phi_7686_ = 0i;
                loop {
                    let _e804 = phi_7686_;
                    local_23 = _e804;
                    local_24 = _e804;
                    local_25 = _e804;
                    local_26 = _e804;
                    local_27 = _e804;
                    local_28 = _e804;
                    local_30 = _e804;
                    local_31 = _e804;
                    local_32 = _e804;
                    let _e806 = (_e804 < (_e794 - 1i));
                    phi_3933_ = _e806;
                    if _e806 {
                        let _e809 = global.member_16[_e804];
                        phi_3933_ = (_e802 > _e809);
                    }
                    let _e812 = phi_3933_;
                    if _e812 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_7686_ = (_e804 + 1i);
                    }
                }
                let _e816 = local_23;
                let _e818 = global.member_16[_e816];
                if (_e802 > _e818) {
                    phi_7742_ = vec3<f32>(1f, 1f, 1f);
                    phi_7741_ = 1f;
                    break;
                }
                let _e822 = local_24;
                let _e824 = global.member_18[_e822];
                let _e826 = (_e774 + (_e781 * _e824));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e830 = local_25;
                        let _e832 = global.member_14[_e830];
                        let _e837 = (_e832 * vec4<f32>(_e826.x, _e826.y, _e826.z, 1f));
                        let _e839 = (_e837.x < 0f);
                        phi_4046_ = _e839;
                        if !(_e839) {
                            phi_4046_ = (_e837.x > 1f);
                        }
                        let _e843 = phi_4046_;
                        phi_4053_ = _e843;
                        if !(_e843) {
                            phi_4053_ = (_e837.y < 0f);
                        }
                        let _e848 = phi_4053_;
                        phi_4060_ = _e848;
                        if !(_e848) {
                            phi_4060_ = (_e837.y > 1f);
                        }
                        let _e853 = phi_4060_;
                        if _e853 {
                            phi_7699_ = 1f;
                            break;
                        }
                        let _e855 = local_26;
                        let _e859 = local_27;
                        let _e865 = global.member_23;
                        let _e866 = _e865.xy;
                        let _e867 = (vec2<f32>(f32((_e855 & 1i)), f32((_e859 >> bitcast<u32>(1i)))) * _e866);
                        let _e872 = local_28;
                        let _e874 = global.member_19[_e872];
                        let _e875 = (min(_e837.z, 1f) - _e874);
                        let _e878 = global.member_22;
                        let _e879 = _e878.xy;
                        let _e880 = (_e879 * 0.5f);
                        let _e882 = (_e867 + (_e837.xy * _e866));
                        let _e883 = (_e867 + _e880);
                        let _e885 = ((_e867 + _e866) - _e880);
                        let _e890 = vec4<f32>(_e883.x, _e883.y, _e885.x, _e885.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e894 = global.member_22[2u];
                                let _e895 = i32(_e894);
                                if (_e895 <= 0i) {
                                    let _e899 = clamp(_e882, _e890.xy, _e890.zw);
                                    let _e904 = textureSampleCompare(global_2, global_1, vec3<f32>(_e899.x, _e899.y, _e875).xy, _e875);
                                    phi_7698_ = _e904;
                                    break;
                                }
                                let _e906 = ((_e882 / _e879) + vec2<f32>(0.5f, 0.5f));
                                let _e907 = floor(_e906);
                                let _e908 = (_e906 - _e907);
                                let _e910 = (_e895 == 1i);
                                if _e910 {
                                    let _e911 = (_e908 * 2f);
                                    local_18[0i] = (vec2<f32>(3f, 3f) - _e911);
                                    local_18[1i] = (vec2<f32>(1f, 1f) + _e911);
                                    let _e917 = local_18[0i];
                                    local_19[0i] = (((vec2<f32>(2f, 2f) - _e908) / _e917) - vec2<f32>(1f, 1f));
                                    let _e921 = local_18[1i];
                                    local_19[1i] = ((_e908 / _e921) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e925 = (_e908 * 3f);
                                    local_18[0i] = (vec2<f32>(4f, 4f) - _e925);
                                    local_18[1i] = vec2<f32>(7f, 7f);
                                    local_18[2i] = (vec2<f32>(1f, 1f) + _e925);
                                    let _e933 = local_18[0i];
                                    local_19[0i] = (((vec2<f32>(3f, 3f) - (_e908 * 2f)) / _e933) - vec2<f32>(2f, 2f));
                                    let _e938 = local_18[1i];
                                    local_19[1i] = ((vec2<f32>(3f, 3f) + _e908) / _e938);
                                    let _e941 = local_18[2i];
                                    local_19[2i] = ((_e908 / _e941) + vec2<f32>(2f, 2f));
                                }
                                let _e946 = select(3i, 2i, _e910);
                                phi_7691_ = 0f;
                                phi_7688_ = 0i;
                                loop {
                                    let _e948 = phi_7691_;
                                    let _e950 = phi_7688_;
                                    local_29 = _e948;
                                    if (_e950 < _e946) {
                                        phi_7697_ = _e948;
                                        phi_7694_ = 0i;
                                        loop {
                                            let _e953 = phi_7697_;
                                            let _e955 = phi_7694_;
                                            local_43 = _e953;
                                            if (_e955 < _e946) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e959 = local_19[_e955][0u];
                                                let _e962 = local_19[_e950][1u];
                                                let _e968 = clamp((_e879 * ((_e907 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e959, _e962))), _e890.xy, _e890.zw);
                                                let _e971 = local_18[_e955][0u];
                                                let _e974 = local_18[_e950][1u];
                                                let _e980 = textureSampleCompare(global_2, global_1, vec3<f32>(_e968.x, _e968.y, _e875).xy, _e875);
                                                phi_7697_ = (_e953 + ((_e971 * _e974) * _e980));
                                                phi_7694_ = (_e955 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e3030 = local_43;
                                        phi_7691_ = _e3030;
                                        phi_7688_ = (_e950 + 1i);
                                    }
                                }
                                let _e986 = local_29;
                                phi_7698_ = (_e986 * select(0.0069444445f, 0.0625f, _e910));
                                break;
                            }
                        }
                        let _e989 = phi_7698_;
                        phi_7699_ = _e989;
                        break;
                    }
                }
                let _e991 = phi_7699_;
                local_20 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e993 = local_30;
                let _e995 = local_20[_e993];
                let _e998 = local_31;
                let _e1000 = global.member_17[_e998];
                phi_7739_ = _e991;
                phi_7736_ = _e995;
                if (_e802 > _e1000) {
                    let _e1004 = ((_e802 - _e1000) / (_e818 - _e1000));
                    let _e1006 = local_32;
                    let _e1007 = (_e1006 + 1i);
                    if (_e1007 < _e794) {
                        let _e1011 = global.member_18[_e1007];
                        let _e1013 = (_e774 + (_e781 * _e1011));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1017 = global.member_14[_e1007];
                                let _e1022 = (_e1017 * vec4<f32>(_e1013.x, _e1013.y, _e1013.z, 1f));
                                let _e1024 = (_e1022.x < 0f);
                                phi_4333_ = _e1024;
                                if !(_e1024) {
                                    phi_4333_ = (_e1022.x > 1f);
                                }
                                let _e1028 = phi_4333_;
                                phi_4340_ = _e1028;
                                if !(_e1028) {
                                    phi_4340_ = (_e1022.y < 0f);
                                }
                                let _e1033 = phi_4340_;
                                phi_4347_ = _e1033;
                                if !(_e1033) {
                                    phi_4347_ = (_e1022.y > 1f);
                                }
                                let _e1038 = phi_4347_;
                                if _e1038 {
                                    phi_7719_ = 1f;
                                    break;
                                }
                                let _e1046 = global.member_23;
                                let _e1047 = _e1046.xy;
                                let _e1048 = (vec2<f32>(f32((_e1007 & 1i)), f32((_e1007 >> bitcast<u32>(1i)))) * _e1047);
                                let _e1053 = global.member_19[_e1007];
                                let _e1054 = (min(_e1022.z, 1f) - _e1053);
                                let _e1057 = global.member_22;
                                let _e1058 = _e1057.xy;
                                let _e1059 = (_e1058 * 0.5f);
                                let _e1061 = (_e1048 + (_e1022.xy * _e1047));
                                let _e1062 = (_e1048 + _e1059);
                                let _e1064 = ((_e1048 + _e1047) - _e1059);
                                let _e1069 = vec4<f32>(_e1062.x, _e1062.y, _e1064.x, _e1064.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1073 = global.member_22[2u];
                                        let _e1074 = i32(_e1073);
                                        if (_e1074 <= 0i) {
                                            let _e1078 = clamp(_e1061, _e1069.xy, _e1069.zw);
                                            let _e1083 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1078.x, _e1078.y, _e1054).xy, _e1054);
                                            phi_7718_ = _e1083;
                                            break;
                                        }
                                        let _e1085 = ((_e1061 / _e1058) + vec2<f32>(0.5f, 0.5f));
                                        let _e1086 = floor(_e1085);
                                        let _e1087 = (_e1085 - _e1086);
                                        let _e1089 = (_e1074 == 1i);
                                        if _e1089 {
                                            let _e1090 = (_e1087 * 2f);
                                            local_16[0i] = (vec2<f32>(3f, 3f) - _e1090);
                                            local_16[1i] = (vec2<f32>(1f, 1f) + _e1090);
                                            let _e1096 = local_16[0i];
                                            local_17[0i] = (((vec2<f32>(2f, 2f) - _e1087) / _e1096) - vec2<f32>(1f, 1f));
                                            let _e1100 = local_16[1i];
                                            local_17[1i] = ((_e1087 / _e1100) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1104 = (_e1087 * 3f);
                                            local_16[0i] = (vec2<f32>(4f, 4f) - _e1104);
                                            local_16[1i] = vec2<f32>(7f, 7f);
                                            local_16[2i] = (vec2<f32>(1f, 1f) + _e1104);
                                            let _e1112 = local_16[0i];
                                            local_17[0i] = (((vec2<f32>(3f, 3f) - (_e1087 * 2f)) / _e1112) - vec2<f32>(2f, 2f));
                                            let _e1117 = local_16[1i];
                                            local_17[1i] = ((vec2<f32>(3f, 3f) + _e1087) / _e1117);
                                            let _e1120 = local_16[2i];
                                            local_17[2i] = ((_e1087 / _e1120) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1125 = select(3i, 2i, _e1089);
                                        phi_7711_ = 0f;
                                        phi_7708_ = 0i;
                                        loop {
                                            let _e1127 = phi_7711_;
                                            let _e1129 = phi_7708_;
                                            local_33 = _e1127;
                                            if (_e1129 < _e1125) {
                                                phi_7717_ = _e1127;
                                                phi_7714_ = 0i;
                                                loop {
                                                    let _e1132 = phi_7717_;
                                                    let _e1134 = phi_7714_;
                                                    local_44 = _e1132;
                                                    if (_e1134 < _e1125) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1138 = local_17[_e1134][0u];
                                                        let _e1141 = local_17[_e1129][1u];
                                                        let _e1147 = clamp((_e1058 * ((_e1086 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1138, _e1141))), _e1069.xy, _e1069.zw);
                                                        let _e1150 = local_16[_e1134][0u];
                                                        let _e1153 = local_16[_e1129][1u];
                                                        let _e1159 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1147.x, _e1147.y, _e1054).xy, _e1054);
                                                        phi_7717_ = (_e1132 + ((_e1150 * _e1153) * _e1159));
                                                        phi_7714_ = (_e1134 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3045 = local_44;
                                                phi_7711_ = _e3045;
                                                phi_7708_ = (_e1129 + 1i);
                                            }
                                        }
                                        let _e1165 = local_33;
                                        phi_7718_ = (_e1165 * select(0.0069444445f, 0.0625f, _e1089));
                                        break;
                                    }
                                }
                                let _e1168 = phi_7718_;
                                phi_7719_ = _e1168;
                                break;
                            }
                        }
                        let _e1170 = phi_7719_;
                        local_21 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1173 = local_21[_e1007];
                        phi_7740_ = mix(_e991, _e1170, _e1004);
                        phi_7737_ = mix(_e995, _e1173, vec3(_e1004));
                    } else {
                        phi_7740_ = mix(_e991, 1f, _e1004);
                        phi_7737_ = _e995;
                    }
                    let _e1178 = phi_7740_;
                    let _e1180 = phi_7737_;
                    phi_7739_ = _e1178;
                    phi_7736_ = _e1180;
                }
                let _e1182 = phi_7739_;
                let _e1184 = phi_7736_;
                let _e1187 = global.member_22[3u];
                phi_7742_ = select(vec3<f32>(1f, 1f, 1f), _e1184, vec3((_e1187 > 0.5f)));
                phi_7741_ = _e1182;
                break;
            }
        }
        let _e1192 = phi_7742_;
        let _e1194 = phi_7741_;
        phi_7905_ = _e1194;
        phi_7865_ = (_e685 * _e1192);
    }
    let _e1197 = phi_7905_;
    let _e1199 = phi_7865_;
    let _e1201 = global.member_5;
    let _e1205 = global.member_4[3u];
    let _e1206 = (_e1201.xyz * _e1205);
    let _e1209 = global_7.member_6[3u];
    let _e1210 = (_e1209 > 0.5f);
    if _e1210 {
        phi_7794_ = 1f;
    } else {
        let _e1213 = global_7.member_4[3u];
        let _e1214 = textureSample(global_18, global_4, _e245);
        phi_7794_ = (1f + (_e1213 * (_e1214.x - 1f)));
    }
    let _e1220 = phi_7794_;
    let _e1222 = global_9[3u];
    let _e1223 = abs(_e1222);
    phi_7995_ = _e1220;
    if (_e1223 > 0f) {
        phi_7995_ = (_e1220 * min(_e1223, 1f));
    }
    let _e1228 = phi_7995_;
    if !(_e751) {
        let _e1230 = dot(_e766, _e770);
        let _e1237 = global_7.member_1[3u];
        let _e1241 = global_7.member_1[2u];
        let _e1248 = global.member_29[0u];
        if (_e1248 > 0.5f) {
            let _e1251 = global.member_29;
            let _e1258 = ((_e1251.z * _e766.x) - (_e1251.w * _e766.z));
            let _e1262 = ((_e1251.w * _e766.x) + (_e1251.z * _e766.z));
            let _e1266 = (1.092548f * _e1258);
            local_15 = array<f32, 9>(0.282095f, (0.488603f * _e766.y), (0.488603f * _e1262), (0.488603f * _e1258), (_e1266 * _e766.y), ((1.092548f * _e766.y) * _e1262), (0.315392f * (((3f * _e1262) * _e1262) - 1f)), (_e1266 * _e1262), (0.546274f * ((_e1258 * _e1258) - (_e766.y * _e766.y))));
            phi_8144_ = vec3<f32>(0f, 0f, 0f);
            phi_8143_ = 0i;
            loop {
                let _e1281 = phi_8144_;
                let _e1283 = phi_8143_;
                local_34 = _e1281;
                if (_e1283 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1287 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e1283, 0i)), 0i);
                    let _e1290 = local_15[_e1283];
                    phi_8144_ = (_e1281 + (_e1287.xyz * _e1290));
                    phi_8143_ = (_e1283 + 1i);
                }
            }
            let _e1295 = local_34;
            let _e1299 = global.member_29[1u];
            phi_8145_ = (max(_e1295, vec3<f32>(0f, 0f, 0f)) * _e1299);
        } else {
            let _e1302 = global.member_9;
            let _e1305 = global.member_8;
            let _e1314 = global.member_8[3u];
            phi_8145_ = (mix(_e1302.xyz, _e1305.xyz, vec3(((_e766.y * 0.5f) + 0.5f))) * _e1314);
        }
        let _e1317 = phi_8145_;
        let _e1323 = ((_e1199 * ((_e1317 * _e1228) + ((_e1206 * max(_e1230, 0f)) * _e1197))) + ((_e1206 * ((pow(max(dot(_e766, _e778), 0f), _e1237) * _e1241) * step(0f, _e1230))) * _e1197));
        let _e1326 = global.member_13[3u];
        phi_8154_ = _e1323;
        if (_e1326 > 0.5f) {
            let _e1329 = global.member_11;
            let _e1334 = global.member_11[3u];
            let _e1336 = global_15;
            let _e1339 = global.member_12;
            let _e1344 = global.member_13;
            let _e1347 = clamp(floor((_e1336.xy * _e1339.xy)), vec2<f32>(0f, 0f), (_e1344.xy - vec2<f32>(1f, 1f)));
            let _e1352 = global.member_12[2u];
            let _e1356 = global.member_12[3u];
            let _e1361 = global.member_13[2u];
            let _e1366 = global.member_13[1u];
            let _e1372 = global.member_13[0u];
            let _e1376 = u32(((((clamp(floor(((log2(max((dot(_e1329.xyz, _e774) + _e1334), 0.000001f)) * _e1352) + _e1356)), 0f, (_e1361 - 1f)) * _e1366) + _e1347.y) * _e1372) + _e1347.x));
            let _e1383 = global_16.member[(_e1376 >> bitcast<u32>(2i))][(_e1376 & 3u)];
            let _e1384 = (_e1383 & 65535u);
            phi_8155_ = _e1323;
            phi_8152_ = _e1384;
            loop {
                let _e1388 = phi_8155_;
                let _e1390 = phi_8152_;
                local_48 = _e1388;
                if (_e1390 < (_e1384 + (_e1383 >> bitcast<u32>(16i)))) {
                    let _e1393 = (_e1390 / 3u);
                    let _e1400 = global_17.member[(_e1393 >> bitcast<u32>(2i))][(_e1393 & 3u)];
                    let _e1406 = ((_e1400 >> bitcast<u32>(((_e1390 - (_e1393 * 3u)) * 10u))) & 1023u);
                    let _e1409 = global_11.member[_e1406];
                    let _e1411 = (_e1409.xyz - _e774);
                    let _e1412 = dot(_e1411, _e1411);
                    let _e1414 = (_e1412 * _e1409.w);
                    let _e1417 = clamp((1f - (_e1414 * _e1414)), 0f, 1f);
                    let _e1420 = (_e1411 * inverseSqrt(max(_e1412, 0.00000001f)));
                    let _e1423 = global_13.member[_e1406];
                    let _e1426 = global_14.member[_e1406];
                    let _e1434 = clamp(((dot(-(_e1420), _e1426.xyz) * _e1423.w) + _e1426.w), 0f, 1f);
                    let _e1441 = (_e1423.xyz * ((((_e1417 * _e1417) * _e1434) * _e1434) / max(_e1412, 0.0001f)));
                    phi_8281_ = _e1441;
                    if _e784 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1445 = global.member_21[2u];
                                let _e1446 = u32(_e1445);
                                if (_e1406 < _e1446) {
                                    let _e1450 = global.member_26[_e1406];
                                    let _e1453 = global.member_15[_e1406];
                                    let _e1462 = (_e1450.z * max((_e1453 * vec4<f32>(_e774.x, _e774.y, _e774.z, 1f)).w, 0f));
                                    let _e1465 = global.member_25[0u];
                                    let _e1471 = global.member_25[1u];
                                    let _e1474 = ((_e774 + (_e781 * (_e1462 * _e1465))) + (_e1420 * (_e1462 * _e1471)));
                                    let _e1479 = (_e1453 * vec4<f32>(_e1474.x, _e1474.y, _e1474.z, 1f));
                                    if (_e1479.w <= 0f) {
                                        phi_8227_ = 1f;
                                        break;
                                    }
                                    let _e1484 = (_e1479.xyz / vec3(_e1479.w));
                                    let _e1486 = (_e1484.x < 0f);
                                    phi_4988_ = _e1486;
                                    if !(_e1486) {
                                        phi_4988_ = (_e1484.x > 1f);
                                    }
                                    let _e1490 = phi_4988_;
                                    phi_4995_ = _e1490;
                                    if !(_e1490) {
                                        phi_4995_ = (_e1484.y < 0f);
                                    }
                                    let _e1495 = phi_4995_;
                                    phi_5002_ = _e1495;
                                    if !(_e1495) {
                                        phi_5002_ = (_e1484.y > 1f);
                                    }
                                    let _e1500 = phi_5002_;
                                    phi_5009_ = _e1500;
                                    if !(_e1500) {
                                        phi_5009_ = (_e1484.z > 1f);
                                    }
                                    let _e1505 = phi_5009_;
                                    if _e1505 {
                                        phi_8227_ = 1f;
                                        break;
                                    }
                                    let _e1508 = _e1450.xy;
                                    let _e1510 = global.member_23;
                                    let _e1511 = _e1510.zw;
                                    let _e1513 = global.member_22;
                                    let _e1514 = _e1513.xy;
                                    let _e1515 = (_e1514 * 0.5f);
                                    let _e1517 = (_e1508 + (_e1484.xy * _e1511));
                                    let _e1518 = (_e1508 + _e1515);
                                    let _e1520 = ((_e1508 + _e1511) - _e1515);
                                    let _e1525 = vec4<f32>(_e1518.x, _e1518.y, _e1520.x, _e1520.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e1529 = global.member_22[2u];
                                            let _e1530 = i32(_e1529);
                                            if (_e1530 <= 0i) {
                                                let _e1534 = clamp(_e1517, _e1525.xy, _e1525.zw);
                                                let _e1539 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1534.x, _e1534.y, _e1484.z).xy, _e1484.z);
                                                phi_8226_ = _e1539;
                                                break;
                                            }
                                            let _e1541 = ((_e1517 / _e1514) + vec2<f32>(0.5f, 0.5f));
                                            let _e1542 = floor(_e1541);
                                            let _e1543 = (_e1541 - _e1542);
                                            let _e1545 = (_e1530 == 1i);
                                            if _e1545 {
                                                let _e1546 = (_e1543 * 2f);
                                                local_11[0i] = (vec2<f32>(3f, 3f) - _e1546);
                                                local_11[1i] = (vec2<f32>(1f, 1f) + _e1546);
                                                let _e1552 = local_11[0i];
                                                local_12[0i] = (((vec2<f32>(2f, 2f) - _e1543) / _e1552) - vec2<f32>(1f, 1f));
                                                let _e1556 = local_11[1i];
                                                local_12[1i] = ((_e1543 / _e1556) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e1560 = (_e1543 * 3f);
                                                local_11[0i] = (vec2<f32>(4f, 4f) - _e1560);
                                                local_11[1i] = vec2<f32>(7f, 7f);
                                                local_11[2i] = (vec2<f32>(1f, 1f) + _e1560);
                                                let _e1568 = local_11[0i];
                                                local_12[0i] = (((vec2<f32>(3f, 3f) - (_e1543 * 2f)) / _e1568) - vec2<f32>(2f, 2f));
                                                let _e1573 = local_11[1i];
                                                local_12[1i] = ((vec2<f32>(3f, 3f) + _e1543) / _e1573);
                                                let _e1576 = local_11[2i];
                                                local_12[2i] = ((_e1543 / _e1576) + vec2<f32>(2f, 2f));
                                            }
                                            let _e1581 = select(3i, 2i, _e1545);
                                            phi_8219_ = 0f;
                                            phi_8216_ = 0i;
                                            loop {
                                                let _e1583 = phi_8219_;
                                                let _e1585 = phi_8216_;
                                                local_35 = _e1583;
                                                if (_e1585 < _e1581) {
                                                    phi_8225_ = _e1583;
                                                    phi_8222_ = 0i;
                                                    loop {
                                                        let _e1588 = phi_8225_;
                                                        let _e1590 = phi_8222_;
                                                        local_46 = _e1588;
                                                        if (_e1590 < _e1581) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e1594 = local_12[_e1590][0u];
                                                            let _e1597 = local_12[_e1585][1u];
                                                            let _e1603 = clamp((_e1514 * ((_e1542 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1594, _e1597))), _e1525.xy, _e1525.zw);
                                                            let _e1606 = local_11[_e1590][0u];
                                                            let _e1609 = local_11[_e1585][1u];
                                                            let _e1615 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1603.x, _e1603.y, _e1484.z).xy, _e1484.z);
                                                            phi_8225_ = (_e1588 + ((_e1606 * _e1609) * _e1615));
                                                            phi_8222_ = (_e1590 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e3076 = local_46;
                                                    phi_8219_ = _e3076;
                                                    phi_8216_ = (_e1585 + 1i);
                                                }
                                            }
                                            let _e1621 = local_35;
                                            phi_8226_ = (_e1621 * select(0.0069444445f, 0.0625f, _e1545));
                                            break;
                                        }
                                    }
                                    let _e1624 = phi_8226_;
                                    phi_8227_ = _e1624;
                                    break;
                                }
                                let _e1625 = (_e1406 - _e1446);
                                let _e1628 = global.member_21[3u];
                                if (_e1625 >= u32(_e1628)) {
                                    phi_8227_ = 1f;
                                    break;
                                }
                                let _e1633 = global.member_27[_e1625];
                                let _e1636 = global.member_28[_e1625];
                                let _e1638 = _e1633.xyz;
                                let _e1641 = (_e1633.w * length((_e774 - _e1638)));
                                let _e1644 = global.member_25[0u];
                                let _e1650 = global.member_25[1u];
                                let _e1654 = (((_e774 + (_e781 * (_e1641 * _e1644))) + (_e1420 * (_e1641 * _e1650))) - _e1638);
                                let _e1655 = abs(_e1654);
                                let _e1658 = (_e1655.x >= _e1655.y);
                                phi_5079_ = _e1658;
                                if _e1658 {
                                    phi_5079_ = (_e1655.x >= _e1655.z);
                                }
                                let _e1662 = phi_5079_;
                                if _e1662 {
                                    phi_8203_ = select(1i, 0i, (_e1654.x > 0f));
                                    phi_8201_ = _e1655.x;
                                } else {
                                    let _e1667 = (_e1655.y >= _e1655.z);
                                    if _e1667 {
                                        phi_8204_ = select(3i, 2i, (_e1654.y > 0f));
                                    } else {
                                        phi_8204_ = select(5i, 4i, (_e1654.z > 0f));
                                    }
                                    let _e1675 = phi_8204_;
                                    phi_8203_ = _e1675;
                                    phi_8201_ = select(_e1655.z, _e1655.y, _e1667);
                                }
                                let _e1678 = phi_8203_;
                                let _e1680 = phi_8201_;
                                if (_e1680 <= 0f) {
                                    phi_8227_ = 1f;
                                    break;
                                }
                                local_13 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e1683 = local_13[_e1678];
                                local_14 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e1686 = local_14[_e1678];
                                let _e1691 = global.member_24[2u];
                                let _e1694 = (vec2<f32>(dot(_e1654, _e1683), dot(_e1654, _e1686)) / vec2((_e1680 * _e1691)));
                                let _e1698 = (_e1636.z + (_e1636.w / _e1680));
                                if (_e1698 > 1f) {
                                    phi_8227_ = 1f;
                                    break;
                                }
                                let _e1713 = global.member_24;
                                let _e1714 = _e1713.xy;
                                let _e1716 = (_e1636.xy + (vec2<f32>(f32((_e1678 - (i32(floor((f32(_e1678) / f32(3i)))) * 3i))), f32((_e1678 / 3i))) * _e1714));
                                let _e1725 = global.member_22;
                                let _e1726 = _e1725.xy;
                                let _e1727 = (_e1726 * 0.5f);
                                let _e1729 = (_e1716 + (vec2<f32>((0.5f + (0.5f * _e1694.x)), (0.5f - (0.5f * _e1694.y))) * _e1714));
                                let _e1730 = (_e1716 + _e1727);
                                let _e1732 = ((_e1716 + _e1714) - _e1727);
                                let _e1737 = vec4<f32>(_e1730.x, _e1730.y, _e1732.x, _e1732.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1741 = global.member_22[2u];
                                        let _e1742 = i32(_e1741);
                                        if (_e1742 <= 0i) {
                                            let _e1746 = clamp(_e1729, _e1737.xy, _e1737.zw);
                                            let _e1751 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1746.x, _e1746.y, _e1698).xy, _e1698);
                                            phi_8215_ = _e1751;
                                            break;
                                        }
                                        let _e1753 = ((_e1729 / _e1726) + vec2<f32>(0.5f, 0.5f));
                                        let _e1754 = floor(_e1753);
                                        let _e1755 = (_e1753 - _e1754);
                                        let _e1757 = (_e1742 == 1i);
                                        if _e1757 {
                                            let _e1758 = (_e1755 * 2f);
                                            local_9[0i] = (vec2<f32>(3f, 3f) - _e1758);
                                            local_9[1i] = (vec2<f32>(1f, 1f) + _e1758);
                                            let _e1764 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(2f, 2f) - _e1755) / _e1764) - vec2<f32>(1f, 1f));
                                            let _e1768 = local_9[1i];
                                            local_10[1i] = ((_e1755 / _e1768) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1772 = (_e1755 * 3f);
                                            local_9[0i] = (vec2<f32>(4f, 4f) - _e1772);
                                            local_9[1i] = vec2<f32>(7f, 7f);
                                            local_9[2i] = (vec2<f32>(1f, 1f) + _e1772);
                                            let _e1780 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(3f, 3f) - (_e1755 * 2f)) / _e1780) - vec2<f32>(2f, 2f));
                                            let _e1785 = local_9[1i];
                                            local_10[1i] = ((vec2<f32>(3f, 3f) + _e1755) / _e1785);
                                            let _e1788 = local_9[2i];
                                            local_10[2i] = ((_e1755 / _e1788) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1793 = select(3i, 2i, _e1757);
                                        phi_8208_ = 0f;
                                        phi_8205_ = 0i;
                                        loop {
                                            let _e1795 = phi_8208_;
                                            let _e1797 = phi_8205_;
                                            local_36 = _e1795;
                                            if (_e1797 < _e1793) {
                                                phi_8214_ = _e1795;
                                                phi_8211_ = 0i;
                                                loop {
                                                    let _e1800 = phi_8214_;
                                                    let _e1802 = phi_8211_;
                                                    local_47 = _e1800;
                                                    if (_e1802 < _e1793) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1806 = local_10[_e1802][0u];
                                                        let _e1809 = local_10[_e1797][1u];
                                                        let _e1815 = clamp((_e1726 * ((_e1754 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1806, _e1809))), _e1737.xy, _e1737.zw);
                                                        let _e1818 = local_9[_e1802][0u];
                                                        let _e1821 = local_9[_e1797][1u];
                                                        let _e1827 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1815.x, _e1815.y, _e1698).xy, _e1698);
                                                        phi_8214_ = (_e1800 + ((_e1818 * _e1821) * _e1827));
                                                        phi_8211_ = (_e1802 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3088 = local_47;
                                                phi_8208_ = _e3088;
                                                phi_8205_ = (_e1797 + 1i);
                                            }
                                        }
                                        let _e1833 = local_36;
                                        phi_8215_ = (_e1833 * select(0.0069444445f, 0.0625f, _e1757));
                                        break;
                                    }
                                }
                                let _e1836 = phi_8215_;
                                phi_8227_ = _e1836;
                                break;
                            }
                        }
                        let _e1838 = phi_8227_;
                        phi_8281_ = (_e1441 * _e1838);
                    }
                    let _e1841 = phi_8281_;
                    let _e1842 = dot(_e766, _e1420);
                    local_45 = (_e1388 + (((_e1199 * max(_e1842, 0f)) * _e1841) + (_e1841 * ((pow(max(dot(_e766, normalize((_e1420 + _e776))), 0f), _e1237) * _e1241) * step(0f, _e1842)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3068 = local_45;
                    phi_8155_ = _e3068;
                    phi_8152_ = (_e1390 + bitcast<u32>(1i));
                }
            }
            let _e3098 = local_48;
            phi_8154_ = _e3098;
        }
        let _e1860 = phi_8154_;
        phi_8153_ = _e1860;
    } else {
        let _e1861 = textureSample(global_25, global_4, _e245);
        let _e1864 = global_7.member_4[0u];
        let _e1867 = clamp((_e1864 * _e1861.z), 0f, 1f);
        let _e1870 = global_7.member_4[1u];
        let _e1873 = clamp((_e1870 * _e1861.y), 0.045f, 1f);
        phi_7866_ = _e1867;
        phi_7861_ = _e1873;
        if (_e683 > 0f) {
            phi_7866_ = mix(_e1867, _e681.y, _e683);
            phi_7861_ = mix(_e1873, max(_e681.x, 0.045f), _e683);
        }
        let _e1881 = phi_7866_;
        let _e1883 = phi_7861_;
        let _e1884 = (_e1883 * _e1883);
        let _e1886 = (_e1199 * (1f - _e1881));
        let _e1888 = mix(vec3<f32>(0.04f, 0.04f, 0.04f), _e1199, vec3(_e1881));
        let _e1889 = (_e757 > 0f);
        phi_7894_ = _e766;
        if _e1889 {
            let _e1890 = dpdx(_e774);
            let _e1891 = dpdy(_e774);
            let _e1892 = cross(_e1890, _e1891);
            phi_7895_ = _e766;
            if (dot(_e1892, _e1892) > 0.00000000000000000001f) {
                phi_7895_ = normalize(((normalize(_e1892) * select(1f, -1f, (dot(_e1892, _e776) < 0f))) + (_e766 - _e687)));
            }
            let _e1904 = phi_7895_;
            phi_7894_ = _e1904;
        }
        let _e1906 = phi_7894_;
        let _e1908 = max(dot(_e1906, _e776), 0.0001f);
        let _e1911 = dot(_e1906, _e770);
        let _e1912 = clamp(_e1911, 0f, 1f);
        let _e1914 = clamp(dot(_e1906, _e778), 0f, 1f);
        let _e1916 = clamp(dot(_e776, _e778), 0f, 1f);
        phi_7899_ = _e1908;
        phi_7898_ = _e1916;
        if _e1889 {
            phi_7899_ = max(_e1908, 0.5f);
            phi_7898_ = max(_e1916, 0.5f);
        }
        let _e1920 = phi_7899_;
        let _e1922 = phi_7898_;
        let _e1925 = (vec3<f32>(1f, 1f, 1f) - _e1888);
        let _e1927 = (_e1888 + (_e1925 * pow((1f - _e1922), 5f)));
        let _e1928 = (_e1884 * _e1884);
        let _e1930 = (_e1928 - 1f);
        let _e1932 = (((_e1914 * _e1914) * _e1930) + 1f);
        let _e1937 = (1f - _e1928);
        let _e1940 = sqrt((((_e1920 * _e1920) * _e1937) + _e1928));
        let _e1959 = ((((((vec3<f32>(1f, 1f, 1f) - _e1927) * _e1886) * clamp(dot(_e766, _e770), 0f, 1f)) + (((_e1927 * ((_e1928 / ((3.1415927f * _e1932) * _e1932)) * (0.5f / max(((_e1912 * _e1940) + (_e1920 * sqrt((((_e1912 * _e1912) * _e1937) + _e1928)))), 0.00001f)))) * 3.1415927f) * _e1912)) * _e1206) * _e1197);
        phi_8009_ = _e1959;
        if _e1889 {
            phi_8009_ = (_e1959 + (((((_e1886 * _e1206) * _e1197) * _e757) * clamp(-(_e1911), 0f, 1f)) * (0.35f + (0.65f * pow(clamp(dot(-(_e776), _e770), 0f, 1f), 3f)))));
        }
        let _e1975 = phi_8009_;
        let _e1978 = global.member_29[0u];
        if (_e1978 > 0.5f) {
            let _e1984 = textureSample(global_5, global_6, (((vec2<f32>(_e1920, _e1883) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
            let _e1987 = global.member_29;
            let _e1994 = ((_e1987.z * _e766.x) - (_e1987.w * _e766.z));
            let _e1998 = ((_e1987.w * _e766.x) + (_e1987.z * _e766.z));
            let _e2002 = (1.092548f * _e1994);
            local_8 = array<f32, 9>(0.282095f, (0.488603f * _e766.y), (0.488603f * _e1998), (0.488603f * _e1994), (_e2002 * _e766.y), ((1.092548f * _e766.y) * _e1998), (0.315392f * (((3f * _e1998) * _e1998) - 1f)), (_e2002 * _e1998), (0.546274f * ((_e1994 * _e1994) - (_e766.y * _e766.y))));
            phi_7917_ = vec3<f32>(0f, 0f, 0f);
            phi_7916_ = 0i;
            loop {
                let _e2017 = phi_7917_;
                let _e2019 = phi_7916_;
                local_37 = _e2017;
                if (_e2019 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e2023 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e2019, 0i)), 0i);
                    let _e2026 = local_8[_e2019];
                    phi_7917_ = (_e2017 + (_e2023.xyz * _e2026));
                    phi_7916_ = (_e2019 + 1i);
                }
            }
            let _e2031 = local_37;
            let _e2035 = global.member_29[1u];
            let _e2038 = reflect(-(_e776), _e1906);
            let _e2055 = vec2<f32>(((atan2(((_e1987.z * _e2038.x) - (_e1987.w * _e2038.z)), -(((_e1987.w * _e2038.x) + (_e1987.z * _e2038.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e2038.y, -1f, 1f)) * 0.31830987f));
            let _e2056 = (_e1883 * 5f);
            let _e2058 = min(i32(_e2056), 4i);
            local_6 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e2060 = local_6[_e2058];
            let _e2064 = ((_e2055 * vec2<f32>(_e2060.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e2065 = floor(_e2064);
            let _e2066 = (_e2064 - _e2065);
            let _e2068 = i32(_e2065.x);
            let _e2070 = i32(_e2065.y);
            phi_7920_ = _e2068;
            if (_e2068 < 0i) {
                phi_7920_ = (_e2068 + _e2060.z);
            }
            let _e2075 = phi_7920_;
            phi_7921_ = _e2075;
            if (_e2075 >= _e2060.z) {
                phi_7921_ = (_e2075 - _e2060.z);
            }
            let _e2080 = phi_7921_;
            let _e2081 = (_e2080 + 1i);
            let _e2083 = select(_e2081, 0i, (_e2081 == _e2060.z));
            let _e2087 = min((_e2070 + 1i), (_e2060.w - 1i));
            let _e2088 = max(_e2070, 0i);
            let _e2089 = _e2060.xy;
            let _e2092 = textureLoad(global_3, (_e2089 + vec2<i32>(_e2080, _e2088)), 0i);
            let _e2096 = textureLoad(global_3, (_e2089 + vec2<i32>(_e2083, _e2088)), 0i);
            let _e2100 = textureLoad(global_3, (_e2089 + vec2<i32>(_e2080, _e2087)), 0i);
            let _e2104 = textureLoad(global_3, (_e2089 + vec2<i32>(_e2083, _e2087)), 0i);
            let _e2107 = vec3(_e2066.x);
            local_7 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e2115 = local_7[(_e2058 + 1i)];
            let _e2119 = ((_e2055 * vec2<f32>(_e2115.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e2120 = floor(_e2119);
            let _e2121 = (_e2119 - _e2120);
            let _e2123 = i32(_e2120.x);
            let _e2125 = i32(_e2120.y);
            phi_7927_ = _e2123;
            if (_e2123 < 0i) {
                phi_7927_ = (_e2123 + _e2115.z);
            }
            let _e2130 = phi_7927_;
            phi_7928_ = _e2130;
            if (_e2130 >= _e2115.z) {
                phi_7928_ = (_e2130 - _e2115.z);
            }
            let _e2135 = phi_7928_;
            let _e2136 = (_e2135 + 1i);
            let _e2138 = select(_e2136, 0i, (_e2136 == _e2115.z));
            let _e2142 = min((_e2125 + 1i), (_e2115.w - 1i));
            let _e2143 = max(_e2125, 0i);
            let _e2144 = _e2115.xy;
            let _e2147 = textureLoad(global_3, (_e2144 + vec2<i32>(_e2135, _e2143)), 0i);
            let _e2151 = textureLoad(global_3, (_e2144 + vec2<i32>(_e2138, _e2143)), 0i);
            let _e2155 = textureLoad(global_3, (_e2144 + vec2<i32>(_e2135, _e2142)), 0i);
            let _e2159 = textureLoad(global_3, (_e2144 + vec2<i32>(_e2138, _e2142)), 0i);
            let _e2162 = vec3(_e2121.x);
            phi_7971_ = (max(_e2031, vec3<f32>(0f, 0f, 0f)) * _e2035);
            phi_7959_ = _e1984.xy;
            phi_7935_ = (mix(mix(mix(_e2092.xyz, _e2096.xyz, _e2107), mix(_e2100.xyz, _e2104.xyz, _e2107), vec3(_e2066.y)), mix(mix(_e2147.xyz, _e2151.xyz, _e2162), mix(_e2155.xyz, _e2159.xyz, _e2162), vec3(_e2121.y)), vec3((_e2056 - f32(_e2058)))) * _e2035);
        } else {
            let _e2174 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e1883) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
            let _e2187 = global.member_9;
            let _e2188 = _e2187.xyz;
            let _e2190 = global.member_8;
            let _e2191 = _e2190.xyz;
            let _e2199 = global.member_8[3u];
            let _e2200 = (mix(_e2188, _e2191, vec3(((_e766.y * 0.5f) + 0.5f))) * _e2199);
            phi_7971_ = _e2200;
            phi_7959_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e2174.x * _e2174.x), exp2((-9.28f * _e1920))) * _e2174.x) + _e2174.y)) + _e2174.zw);
            phi_7935_ = mix((mix(_e2188, _e2191, vec3(((reflect(-(_e776), _e1906).y * 0.5f) + 0.5f))) * _e2199), _e2200, vec3(_e1883));
        }
        let _e2212 = phi_7971_;
        let _e2214 = phi_7959_;
        let _e2216 = phi_7935_;
        phi_2806_ = _e1210;
        if _e1210 {
            let _e2219 = global.member_33[2u];
            phi_2806_ = (_e2219 > 0.5f);
        }
        let _e2222 = phi_2806_;
        phi_7980_ = _e2216;
        if _e2222 {
            switch bitcast<i32>(0u) {
                default: {
                    let _e2225 = global.member_31;
                    let _e2226 = _e2225.xyz;
                    let _e2229 = global.member_33[0u];
                    let _e2234 = global.member_31[3u];
                    let _e2243 = global.member_32[1u];
                    let _e2249 = global.member_32[0u];
                    let _e2252 = (((_e2249 * (1f - smoothstep((_e2229 * 0.5f), _e2229, abs((dot(_e2226, _e774) - _e2234))))) * smoothstep(0.5f, 0.9f, dot(_e781, _e2226))) * (1f - smoothstep((_e2243 * 0.5f), _e2243, _e1883)));
                    if (_e2252 <= 0f) {
                        phi_7956_ = _e2216;
                        break;
                    }
                    let _e2259 = global.member_32[3u];
                    let _e2261 = (_e774 + ((_e766 - (_e2226 * dot(_e766, _e2226))) * _e2259));
                    let _e2263 = global.member_30;
                    let _e2268 = (_e2263 * vec4<f32>(_e2261.x, _e2261.y, _e2261.z, 1f));
                    let _e2280 = global.member_32[2u];
                    phi_7955_ = 0f;
                    phi_7954_ = vec3<f32>(0f, 0f, 0f);
                    phi_7953_ = 0i;
                    loop {
                        let _e2283 = phi_7955_;
                        let _e2285 = phi_7954_;
                        let _e2287 = phi_7953_;
                        local_38 = _e2285;
                        local_39 = _e2283;
                        if (_e2287 < 12i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e2289 = f32(_e2287);
                            let _e2294 = (_e2289 * 2.3999631f);
                            let _e2298 = global.member_33[1u];
                            let _e2303 = ((((vec2<f32>(_e2268.x, -(_e2268.y)) / vec2(_e2268.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e2294) * _e2298), sin(_e2294)) * (sqrt(((_e2289 + 0.5f) * 0.083333336f)) * (_e2280 * _e1883))));
                            let _e2305 = min(_e2303, (vec2<f32>(1f, 1f) - _e2303));
                            let _e2309 = smoothstep(0f, 0.04f, min(_e2305.x, _e2305.y));
                            let _e2311 = textureSampleLevel(global_18, global_4, clamp(_e2303, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                            let _e2312 = _e2311.xyz;
                            phi_7955_ = (_e2283 + (_e2311.w * _e2309));
                            phi_7954_ = (_e2285 + ((_e2312 / (vec3<f32>(1f, 1f, 1f) - min(_e2312, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e2309));
                            phi_7953_ = (_e2287 + 1i);
                        }
                    }
                    let _e2323 = local_38;
                    let _e2326 = local_39;
                    phi_7956_ = mix(_e2216, ((_e2323 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e2216 * (1f - (_e2326 * 0.083333336f)))), vec3(_e2252));
                    break;
                }
            }
            let _e2334 = phi_7956_;
            phi_7980_ = _e2334;
        }
        let _e2336 = phi_7980_;
        let _e2341 = ((_e1888 * _e2214.x) + vec3(_e2214.y));
        let _e2348 = (_e1975 + (((((vec3<f32>(1f, 1f, 1f) - _e2341) * _e1886) * _e2212) + (_e2341 * _e2336)) * _e1228));
        let _e2351 = global.member_13[3u];
        phi_8156_ = _e2348;
        if (_e2351 > 0.5f) {
            let _e2354 = global.member_11;
            let _e2359 = global.member_11[3u];
            let _e2361 = global_15;
            let _e2364 = global.member_12;
            let _e2369 = global.member_13;
            let _e2372 = clamp(floor((_e2361.xy * _e2364.xy)), vec2<f32>(0f, 0f), (_e2369.xy - vec2<f32>(1f, 1f)));
            let _e2377 = global.member_12[2u];
            let _e2381 = global.member_12[3u];
            let _e2386 = global.member_13[2u];
            let _e2391 = global.member_13[1u];
            let _e2397 = global.member_13[0u];
            let _e2401 = u32(((((clamp(floor(((log2(max((dot(_e2354.xyz, _e774) + _e2359), 0.000001f)) * _e2377) + _e2381)), 0f, (_e2386 - 1f)) * _e2391) + _e2372.y) * _e2397) + _e2372.x));
            let _e2408 = global_16.member[(_e2401 >> bitcast<u32>(2i))][(_e2401 & 3u)];
            let _e2409 = (_e2408 & 65535u);
            phi_8109_ = _e2348;
            phi_8012_ = _e2409;
            loop {
                let _e2413 = phi_8109_;
                let _e2415 = phi_8012_;
                local_52 = _e2413;
                if (_e2415 < (_e2409 + (_e2408 >> bitcast<u32>(16i)))) {
                    let _e2418 = (_e2415 / 3u);
                    let _e2425 = global_17.member[(_e2418 >> bitcast<u32>(2i))][(_e2418 & 3u)];
                    let _e2431 = ((_e2425 >> bitcast<u32>(((_e2415 - (_e2418 * 3u)) * 10u))) & 1023u);
                    let _e2434 = global_11.member[_e2431];
                    let _e2436 = (_e2434.xyz - _e774);
                    let _e2437 = dot(_e2436, _e2436);
                    let _e2439 = (_e2437 * _e2434.w);
                    let _e2442 = clamp((1f - (_e2439 * _e2439)), 0f, 1f);
                    let _e2445 = (_e2436 * inverseSqrt(max(_e2437, 0.00000001f)));
                    let _e2448 = global_13.member[_e2431];
                    let _e2451 = global_14.member[_e2431];
                    let _e2459 = clamp(((dot(-(_e2445), _e2451.xyz) * _e2448.w) + _e2451.w), 0f, 1f);
                    let _e2466 = (_e2448.xyz * ((((_e2442 * _e2442) * _e2459) * _e2459) / max(_e2437, 0.0001f)));
                    phi_8107_ = _e2466;
                    if _e784 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e2470 = global.member_21[2u];
                                let _e2471 = u32(_e2470);
                                if (_e2431 < _e2471) {
                                    let _e2475 = global.member_26[_e2431];
                                    let _e2478 = global.member_15[_e2431];
                                    let _e2487 = (_e2475.z * max((_e2478 * vec4<f32>(_e774.x, _e774.y, _e774.z, 1f)).w, 0f));
                                    let _e2490 = global.member_25[0u];
                                    let _e2496 = global.member_25[1u];
                                    let _e2499 = ((_e774 + (_e781 * (_e2487 * _e2490))) + (_e2445 * (_e2487 * _e2496)));
                                    let _e2504 = (_e2478 * vec4<f32>(_e2499.x, _e2499.y, _e2499.z, 1f));
                                    if (_e2504.w <= 0f) {
                                        phi_8039_ = 1f;
                                        break;
                                    }
                                    let _e2509 = (_e2504.xyz / vec3(_e2504.w));
                                    let _e2511 = (_e2509.x < 0f);
                                    phi_6670_ = _e2511;
                                    if !(_e2511) {
                                        phi_6670_ = (_e2509.x > 1f);
                                    }
                                    let _e2515 = phi_6670_;
                                    phi_6677_ = _e2515;
                                    if !(_e2515) {
                                        phi_6677_ = (_e2509.y < 0f);
                                    }
                                    let _e2520 = phi_6677_;
                                    phi_6684_ = _e2520;
                                    if !(_e2520) {
                                        phi_6684_ = (_e2509.y > 1f);
                                    }
                                    let _e2525 = phi_6684_;
                                    phi_6691_ = _e2525;
                                    if !(_e2525) {
                                        phi_6691_ = (_e2509.z > 1f);
                                    }
                                    let _e2530 = phi_6691_;
                                    if _e2530 {
                                        phi_8039_ = 1f;
                                        break;
                                    }
                                    let _e2533 = _e2475.xy;
                                    let _e2535 = global.member_23;
                                    let _e2536 = _e2535.zw;
                                    let _e2538 = global.member_22;
                                    let _e2539 = _e2538.xy;
                                    let _e2540 = (_e2539 * 0.5f);
                                    let _e2542 = (_e2533 + (_e2509.xy * _e2536));
                                    let _e2543 = (_e2533 + _e2540);
                                    let _e2545 = ((_e2533 + _e2536) - _e2540);
                                    let _e2550 = vec4<f32>(_e2543.x, _e2543.y, _e2545.x, _e2545.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e2554 = global.member_22[2u];
                                            let _e2555 = i32(_e2554);
                                            if (_e2555 <= 0i) {
                                                let _e2559 = clamp(_e2542, _e2550.xy, _e2550.zw);
                                                let _e2564 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2559.x, _e2559.y, _e2509.z).xy, _e2509.z);
                                                phi_8038_ = _e2564;
                                                break;
                                            }
                                            let _e2566 = ((_e2542 / _e2539) + vec2<f32>(0.5f, 0.5f));
                                            let _e2567 = floor(_e2566);
                                            let _e2568 = (_e2566 - _e2567);
                                            let _e2570 = (_e2555 == 1i);
                                            if _e2570 {
                                                let _e2571 = (_e2568 * 2f);
                                                local_2[0i] = (vec2<f32>(3f, 3f) - _e2571);
                                                local_2[1i] = (vec2<f32>(1f, 1f) + _e2571);
                                                let _e2577 = local_2[0i];
                                                local_3[0i] = (((vec2<f32>(2f, 2f) - _e2568) / _e2577) - vec2<f32>(1f, 1f));
                                                let _e2581 = local_2[1i];
                                                local_3[1i] = ((_e2568 / _e2581) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e2585 = (_e2568 * 3f);
                                                local_2[0i] = (vec2<f32>(4f, 4f) - _e2585);
                                                local_2[1i] = vec2<f32>(7f, 7f);
                                                local_2[2i] = (vec2<f32>(1f, 1f) + _e2585);
                                                let _e2593 = local_2[0i];
                                                local_3[0i] = (((vec2<f32>(3f, 3f) - (_e2568 * 2f)) / _e2593) - vec2<f32>(2f, 2f));
                                                let _e2598 = local_2[1i];
                                                local_3[1i] = ((vec2<f32>(3f, 3f) + _e2568) / _e2598);
                                                let _e2601 = local_2[2i];
                                                local_3[2i] = ((_e2568 / _e2601) + vec2<f32>(2f, 2f));
                                            }
                                            let _e2606 = select(3i, 2i, _e2570);
                                            phi_8031_ = 0f;
                                            phi_8028_ = 0i;
                                            loop {
                                                let _e2608 = phi_8031_;
                                                let _e2610 = phi_8028_;
                                                local_40 = _e2608;
                                                if (_e2610 < _e2606) {
                                                    phi_8037_ = _e2608;
                                                    phi_8034_ = 0i;
                                                    loop {
                                                        let _e2613 = phi_8037_;
                                                        let _e2615 = phi_8034_;
                                                        local_50 = _e2613;
                                                        if (_e2615 < _e2606) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e2619 = local_3[_e2615][0u];
                                                            let _e2622 = local_3[_e2610][1u];
                                                            let _e2628 = clamp((_e2539 * ((_e2567 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2619, _e2622))), _e2550.xy, _e2550.zw);
                                                            let _e2631 = local_2[_e2615][0u];
                                                            let _e2634 = local_2[_e2610][1u];
                                                            let _e2640 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2628.x, _e2628.y, _e2509.z).xy, _e2509.z);
                                                            phi_8037_ = (_e2613 + ((_e2631 * _e2634) * _e2640));
                                                            phi_8034_ = (_e2615 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e3134 = local_50;
                                                    phi_8031_ = _e3134;
                                                    phi_8028_ = (_e2610 + 1i);
                                                }
                                            }
                                            let _e2646 = local_40;
                                            phi_8038_ = (_e2646 * select(0.0069444445f, 0.0625f, _e2570));
                                            break;
                                        }
                                    }
                                    let _e2649 = phi_8038_;
                                    phi_8039_ = _e2649;
                                    break;
                                }
                                let _e2650 = (_e2431 - _e2471);
                                let _e2653 = global.member_21[3u];
                                if (_e2650 >= u32(_e2653)) {
                                    phi_8039_ = 1f;
                                    break;
                                }
                                let _e2658 = global.member_27[_e2650];
                                let _e2661 = global.member_28[_e2650];
                                let _e2663 = _e2658.xyz;
                                let _e2666 = (_e2658.w * length((_e774 - _e2663)));
                                let _e2669 = global.member_25[0u];
                                let _e2675 = global.member_25[1u];
                                let _e2679 = (((_e774 + (_e781 * (_e2666 * _e2669))) + (_e2445 * (_e2666 * _e2675))) - _e2663);
                                let _e2680 = abs(_e2679);
                                let _e2683 = (_e2680.x >= _e2680.y);
                                phi_6761_ = _e2683;
                                if _e2683 {
                                    phi_6761_ = (_e2680.x >= _e2680.z);
                                }
                                let _e2687 = phi_6761_;
                                if _e2687 {
                                    phi_8015_ = select(1i, 0i, (_e2679.x > 0f));
                                    phi_8013_ = _e2680.x;
                                } else {
                                    let _e2692 = (_e2680.y >= _e2680.z);
                                    if _e2692 {
                                        phi_8016_ = select(3i, 2i, (_e2679.y > 0f));
                                    } else {
                                        phi_8016_ = select(5i, 4i, (_e2679.z > 0f));
                                    }
                                    let _e2700 = phi_8016_;
                                    phi_8015_ = _e2700;
                                    phi_8013_ = select(_e2680.z, _e2680.y, _e2692);
                                }
                                let _e2703 = phi_8015_;
                                let _e2705 = phi_8013_;
                                if (_e2705 <= 0f) {
                                    phi_8039_ = 1f;
                                    break;
                                }
                                local_4 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e2708 = local_4[_e2703];
                                local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e2711 = local_5[_e2703];
                                let _e2716 = global.member_24[2u];
                                let _e2719 = (vec2<f32>(dot(_e2679, _e2708), dot(_e2679, _e2711)) / vec2((_e2705 * _e2716)));
                                let _e2723 = (_e2661.z + (_e2661.w / _e2705));
                                if (_e2723 > 1f) {
                                    phi_8039_ = 1f;
                                    break;
                                }
                                let _e2738 = global.member_24;
                                let _e2739 = _e2738.xy;
                                let _e2741 = (_e2661.xy + (vec2<f32>(f32((_e2703 - (i32(floor((f32(_e2703) / f32(3i)))) * 3i))), f32((_e2703 / 3i))) * _e2739));
                                let _e2750 = global.member_22;
                                let _e2751 = _e2750.xy;
                                let _e2752 = (_e2751 * 0.5f);
                                let _e2754 = (_e2741 + (vec2<f32>((0.5f + (0.5f * _e2719.x)), (0.5f - (0.5f * _e2719.y))) * _e2739));
                                let _e2755 = (_e2741 + _e2752);
                                let _e2757 = ((_e2741 + _e2739) - _e2752);
                                let _e2762 = vec4<f32>(_e2755.x, _e2755.y, _e2757.x, _e2757.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e2766 = global.member_22[2u];
                                        let _e2767 = i32(_e2766);
                                        if (_e2767 <= 0i) {
                                            let _e2771 = clamp(_e2754, _e2762.xy, _e2762.zw);
                                            let _e2776 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2771.x, _e2771.y, _e2723).xy, _e2723);
                                            phi_8027_ = _e2776;
                                            break;
                                        }
                                        let _e2778 = ((_e2754 / _e2751) + vec2<f32>(0.5f, 0.5f));
                                        let _e2779 = floor(_e2778);
                                        let _e2780 = (_e2778 - _e2779);
                                        let _e2782 = (_e2767 == 1i);
                                        if _e2782 {
                                            let _e2783 = (_e2780 * 2f);
                                            local[0i] = (vec2<f32>(3f, 3f) - _e2783);
                                            local[1i] = (vec2<f32>(1f, 1f) + _e2783);
                                            let _e2789 = local[0i];
                                            local_1[0i] = (((vec2<f32>(2f, 2f) - _e2780) / _e2789) - vec2<f32>(1f, 1f));
                                            let _e2793 = local[1i];
                                            local_1[1i] = ((_e2780 / _e2793) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e2797 = (_e2780 * 3f);
                                            local[0i] = (vec2<f32>(4f, 4f) - _e2797);
                                            local[1i] = vec2<f32>(7f, 7f);
                                            local[2i] = (vec2<f32>(1f, 1f) + _e2797);
                                            let _e2805 = local[0i];
                                            local_1[0i] = (((vec2<f32>(3f, 3f) - (_e2780 * 2f)) / _e2805) - vec2<f32>(2f, 2f));
                                            let _e2810 = local[1i];
                                            local_1[1i] = ((vec2<f32>(3f, 3f) + _e2780) / _e2810);
                                            let _e2813 = local[2i];
                                            local_1[2i] = ((_e2780 / _e2813) + vec2<f32>(2f, 2f));
                                        }
                                        let _e2818 = select(3i, 2i, _e2782);
                                        phi_8020_ = 0f;
                                        phi_8017_ = 0i;
                                        loop {
                                            let _e2820 = phi_8020_;
                                            let _e2822 = phi_8017_;
                                            local_41 = _e2820;
                                            if (_e2822 < _e2818) {
                                                phi_8026_ = _e2820;
                                                phi_8023_ = 0i;
                                                loop {
                                                    let _e2825 = phi_8026_;
                                                    let _e2827 = phi_8023_;
                                                    local_51 = _e2825;
                                                    if (_e2827 < _e2818) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e2831 = local_1[_e2827][0u];
                                                        let _e2834 = local_1[_e2822][1u];
                                                        let _e2840 = clamp((_e2751 * ((_e2779 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2831, _e2834))), _e2762.xy, _e2762.zw);
                                                        let _e2843 = local[_e2827][0u];
                                                        let _e2846 = local[_e2822][1u];
                                                        let _e2852 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2840.x, _e2840.y, _e2723).xy, _e2723);
                                                        phi_8026_ = (_e2825 + ((_e2843 * _e2846) * _e2852));
                                                        phi_8023_ = (_e2827 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3146 = local_51;
                                                phi_8020_ = _e3146;
                                                phi_8017_ = (_e2822 + 1i);
                                            }
                                        }
                                        let _e2858 = local_41;
                                        phi_8027_ = (_e2858 * select(0.0069444445f, 0.0625f, _e2782));
                                        break;
                                    }
                                }
                                let _e2861 = phi_8027_;
                                phi_8039_ = _e2861;
                                break;
                            }
                        }
                        let _e2863 = phi_8039_;
                        phi_8107_ = (_e2466 * _e2863);
                    }
                    let _e2866 = phi_8107_;
                    let _e2868 = normalize((_e2445 + _e776));
                    let _e2870 = clamp(dot(_e766, _e2445), 0f, 1f);
                    let _e2872 = clamp(dot(_e766, _e2868), 0f, 1f);
                    let _e2878 = (_e1888 + (_e1925 * pow((1f - clamp(dot(_e776, _e2868), 0f, 1f)), 5f)));
                    let _e2881 = (((_e2872 * _e2872) * _e1930) + 1f);
                    local_49 = (_e2413 + (((((vec3<f32>(1f, 1f, 1f) - _e2878) * _e1886) + ((_e2878 * ((_e1928 / ((3.1415927f * _e2881) * _e2881)) * (0.5f / max(((_e2870 * _e1940) + (_e1920 * sqrt((((_e2870 * _e2870) * _e1937) + _e1928)))), 0.00001f)))) * 3.1415927f)) * _e2870) * _e2866));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3126 = local_49;
                    phi_8109_ = _e3126;
                    phi_8012_ = (_e2415 + bitcast<u32>(1i));
                }
            }
            let _e3156 = local_52;
            phi_8156_ = _e3156;
        }
        let _e2906 = phi_8156_;
        phi_8153_ = _e2906;
    }
    let _e2908 = phi_8153_;
    let _e2911 = global_7.member_1[1u];
    let _e2915 = global_7.member_5;
    let _e2917 = textureSample(global_26, global_4, _e245);
    let _e2920 = global_24;
    let _e2926 = -(length(_e775));
    let _e2929 = global.member_7[3u];
    let _e2935 = global.member_9[3u];
    phi_8198_ = (1f - exp((_e2926 * _e2929)));
    if (_e2935 != 0f) {
        let _e2939 = (_e2935 * (_e774 - _e773).y);
        if (abs(_e2939) < 0.0001f) {
            phi_8195_ = (1f - (0.5f * _e2939));
        } else {
            phi_8195_ = ((1f - exp(min(-(_e2939), 60f))) / _e2939);
        }
        let _e2950 = phi_8195_;
        let _e2954 = global.member_6[1u];
        let _e2957 = global.member_6[3u];
        phi_8198_ = (1f - exp(((_e2926 * (_e2929 * exp(min((-(_e2935) * (_e2954 - _e2957)), 30f)))) * _e2950)));
    }
    let _e2968 = phi_8198_;
    let _e2970 = global.member_7;
    let _e2973 = mix((mix(_e2908, _e1199, vec3(_e2911)) + ((_e2915.xyz * _e2917.xyz) * (vec3<f32>(1f, 1f, 1f) + _e2920.yzw))), _e2970.xyz, vec3(_e2968));
    let _e2976 = global.member_33[3u];
    phi_8199_ = _e2973;
    if (_e2976 > 0.5f) {
        phi_8199_ = (_e2973 / (vec3<f32>(1f, 1f, 1f) + _e2973));
    }
    let _e2981 = phi_8199_;
    global_27 = vec4<f32>(_e2981.x, _e2981.y, _e2981.z, ((_e256 * _e259) * _e246.w));
    let _e2986 = global_29;
    let _e2987 = global_30;
    switch bitcast<i32>(0u) {
        default: {
            if (_e2987.w <= 0f) {
                phi_8200_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_8200_ = (((_e2987.xy / vec2(_e2987.w)) - (_e2986.xy / vec2(_e2986.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e3001 = phi_8200_;
    global_28 = _e3001;
    return;
}

@fragment 
fn main(@location(1) param: vec3<f32>, @location(8) param_1: vec4<f32>, @location(4) param_2: vec3<f32>, @location(0) param_3: vec3<f32>, @builtin(position) param_4: vec4<f32>, @location(2) param_5: vec2<f32>, @location(3) param_6: vec4<f32>, @builtin(front_facing) param_7: bool, @location(5) param_8: vec4<f32>, @location(6) param_9: vec4<f32>, @location(7) param_10: vec4<f32>) -> FragmentOutput {
    global_8 = param;
    global_9 = param_1;
    global_10 = param_2;
    global_12 = param_3;
    global_15 = param_4;
    global_19 = param_5;
    global_21 = param_6;
    global_23 = param_7;
    global_24 = param_8;
    global_29 = param_9;
    global_30 = param_10;
    function_();
    let _e24 = global_27;
    let _e25 = global_28;
    return FragmentOutput(_e24, _e25);
}
