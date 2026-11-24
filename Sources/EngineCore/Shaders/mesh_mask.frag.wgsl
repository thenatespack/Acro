// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 5fd77116879aa74d
// glsl-fnv1a64: 4f56061c7a0a3fa1

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
    var phi_7688_: vec3<f32>;
    var phi_7686_: f32;
    var local_22: vec3<f32>;
    var phi_7849_: vec2<f32>;
    var phi_7816_: f32;
    var phi_7785_: vec3<f32>;
    var phi_7689_: vec2<f32>;
    var phi_7690_: vec3<f32>;
    var phi_7699_: vec3<f32>;
    var phi_7698_: vec3<f32>;
    var phi_7695_: f32;
    var phi_2344_: bool;
    var phi_7885_: vec3<f32>;
    var phi_7700_: i32;
    var phi_3946_: bool;
    var local_23: i32;
    var local_24: i32;
    var local_25: i32;
    var phi_4059_: bool;
    var phi_4066_: bool;
    var phi_4073_: bool;
    var local_26: i32;
    var local_27: i32;
    var local_28: i32;
    var phi_7705_: f32;
    var phi_7702_: i32;
    var phi_7711_: f32;
    var phi_7708_: i32;
    var local_29: f32;
    var phi_7712_: f32;
    var phi_7713_: f32;
    var local_30: i32;
    var local_31: i32;
    var local_32: i32;
    var phi_4346_: bool;
    var phi_4353_: bool;
    var phi_4360_: bool;
    var phi_7725_: f32;
    var phi_7722_: i32;
    var phi_7731_: f32;
    var phi_7728_: i32;
    var local_33: f32;
    var phi_7732_: f32;
    var phi_7733_: f32;
    var phi_7754_: f32;
    var phi_7751_: vec3<f32>;
    var phi_7753_: f32;
    var phi_7750_: vec3<f32>;
    var phi_7756_: vec3<f32>;
    var phi_7755_: f32;
    var phi_7919_: f32;
    var phi_7879_: vec3<f32>;
    var phi_7808_: f32;
    var phi_8009_: f32;
    var phi_8158_: vec3<f32>;
    var phi_8157_: i32;
    var local_34: vec3<f32>;
    var phi_8159_: vec3<f32>;
    var phi_8169_: vec3<f32>;
    var phi_8166_: u32;
    var phi_5001_: bool;
    var phi_5008_: bool;
    var phi_5015_: bool;
    var phi_5022_: bool;
    var phi_8312_: f32;
    var phi_8309_: i32;
    var phi_8318_: f32;
    var phi_8315_: i32;
    var local_35: f32;
    var phi_8319_: f32;
    var phi_5092_: bool;
    var phi_8297_: i32;
    var phi_8296_: i32;
    var phi_8294_: f32;
    var phi_8301_: f32;
    var phi_8298_: i32;
    var phi_8307_: f32;
    var phi_8304_: i32;
    var local_36: f32;
    var phi_8308_: f32;
    var phi_8320_: f32;
    var phi_8374_: vec3<f32>;
    var phi_8168_: vec3<f32>;
    var phi_7880_: f32;
    var phi_7875_: f32;
    var phi_7909_: vec3<f32>;
    var phi_7908_: vec3<f32>;
    var phi_7913_: f32;
    var phi_7912_: f32;
    var phi_8023_: vec3<f32>;
    var phi_7931_: vec3<f32>;
    var phi_7930_: i32;
    var local_37: vec3<f32>;
    var phi_7934_: i32;
    var phi_7935_: i32;
    var phi_7941_: i32;
    var phi_7942_: i32;
    var phi_7985_: vec3<f32>;
    var phi_7973_: vec2<f32>;
    var phi_7949_: vec3<f32>;
    var phi_2819_: bool;
    var phi_7969_: f32;
    var phi_7968_: vec3<f32>;
    var phi_7967_: i32;
    var local_38: vec3<f32>;
    var local_39: f32;
    var phi_7970_: vec3<f32>;
    var phi_7994_: vec3<f32>;
    var phi_8123_: vec3<f32>;
    var phi_8026_: u32;
    var phi_6683_: bool;
    var phi_6690_: bool;
    var phi_6697_: bool;
    var phi_6704_: bool;
    var phi_8045_: f32;
    var phi_8042_: i32;
    var phi_8051_: f32;
    var phi_8048_: i32;
    var local_40: f32;
    var phi_8052_: f32;
    var phi_6774_: bool;
    var phi_8030_: i32;
    var phi_8029_: i32;
    var phi_8027_: f32;
    var phi_8034_: f32;
    var phi_8031_: i32;
    var phi_8040_: f32;
    var phi_8037_: i32;
    var local_41: f32;
    var phi_8041_: f32;
    var phi_8053_: f32;
    var phi_8121_: vec3<f32>;
    var phi_8170_: vec3<f32>;
    var phi_8167_: vec3<f32>;
    var phi_8209_: f32;
    var phi_8212_: f32;
    var phi_8213_: vec3<f32>;
    var phi_8293_: vec2<f32>;
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
    let _e257 = global_7.member[3u];
    let _e262 = global_7.member_6[0u];
    if ((_e257 * _e246.w) < _e262) {
        discard;
    }
    let _e265 = global_21[3u];
    let _e268 = global_7.member_1[0u];
    phi_7688_ = _e254;
    if (_e268 > 0.5f) {
        let _e270 = global_12;
        let _e273 = floor((_e270.xz * vec2<f32>(0.5f, 0.5f)));
        let _e277 = abs((_e273.x + _e273.y));
        phi_7688_ = (_e254 * select(0.75f, 1f, ((_e277 - (floor((_e277 / 2f)) * 2f)) < 0.5f)));
    }
    let _e286 = phi_7688_;
    let _e289 = global_7.member_3[3u];
    phi_7849_ = vec2<f32>(0f, 0f);
    phi_7816_ = 0f;
    phi_7785_ = _e286;
    if (_e289 > 0.5f) {
        switch bitcast<i32>(0u) {
            default: {
                let _e294 = global_7.member_2[3u];
                let _e296 = vec4<f32>(_e294, _e289, 0f, 0f).xyy;
                let _e298 = floor((_e296 * vec3<f32>(0.000015258789f, 0.000015258789f, 0.000015258789f)));
                let _e300 = (_e296 - (_e298 * 65536f));
                let _e302 = floor((_e300 * vec3<f32>(0.00390625f, 0.00390625f, 0.00390625f)));
                let _e304 = (_e300 - (_e302 * 256f));
                let _e316 = (_e298.y - 128f);
                let _e323 = (floor((_e316 * 0.03125f)) * 0.33333334f);
                let _e327 = global_8;
                let _e328 = normalize(_e327);
                let _e329 = global_9;
                let _e330 = _e329.xyz;
                let _e331 = dot(_e328, _e330);
                let _e337 = ((_e331 / max(length((_e330 - (_e328 * _e331))), 0.000001f)) * 25.5f);
                local_22 = ((vec3<f32>(_e304.x, _e302.x, _e298.x) * vec3<f32>(0.003921569f, 0.003921569f, 0.003921569f)) * 2f);
                local_42 = (vec2<f32>(_e304.y, _e302.y) * vec2<f32>(0.003921569f, 0.003921569f));
                if ((-24f + _e337) < -2f) {
                    phi_7686_ = 0f;
                    break;
                }
                let _e340 = global_10;
                let _e341 = (_e340 * (4f * exp2(((_e316 - (floor((_e316 / 32f)) * 32f)) * 0.33333334f))));
                let _e342 = floor(_e341);
                let _e343 = (_e341 - _e342);
                let _e347 = ((_e343 * _e343) * (vec3<f32>(3f, 3f, 3f) - (_e343 * 2f)));
                let _e349 = bitcast<vec3<u32>>(vec3<i32>(_e342));
                let _e358 = ((((_e349.x * 1597334677u) ^ (_e349.y * 3812015801u)) ^ (_e349.z * 2798796415u)) * 1597334677u);
                let _e367 = bitcast<vec3<u32>>(vec3<i32>((_e342 + vec3<f32>(1f, 0f, 0f))));
                let _e376 = ((((_e367.x * 1597334677u) ^ (_e367.y * 3812015801u)) ^ (_e367.z * 2798796415u)) * 1597334677u);
                let _e387 = bitcast<vec3<u32>>(vec3<i32>((_e342 + vec3<f32>(0f, 1f, 0f))));
                let _e396 = ((((_e387.x * 1597334677u) ^ (_e387.y * 3812015801u)) ^ (_e387.z * 2798796415u)) * 1597334677u);
                let _e405 = bitcast<vec3<u32>>(vec3<i32>((_e342 + vec3<f32>(1f, 1f, 0f))));
                let _e414 = ((((_e405.x * 1597334677u) ^ (_e405.y * 3812015801u)) ^ (_e405.z * 2798796415u)) * 1597334677u);
                let _e426 = bitcast<vec3<u32>>(vec3<i32>((_e342 + vec3<f32>(0f, 0f, 1f))));
                let _e435 = ((((_e426.x * 1597334677u) ^ (_e426.y * 3812015801u)) ^ (_e426.z * 2798796415u)) * 1597334677u);
                let _e444 = bitcast<vec3<u32>>(vec3<i32>((_e342 + vec3<f32>(1f, 0f, 1f))));
                let _e453 = ((((_e444.x * 1597334677u) ^ (_e444.y * 3812015801u)) ^ (_e444.z * 2798796415u)) * 1597334677u);
                let _e463 = bitcast<vec3<u32>>(vec3<i32>((_e342 + vec3<f32>(0f, 1f, 1f))));
                let _e472 = ((((_e463.x * 1597334677u) ^ (_e463.y * 3812015801u)) ^ (_e463.z * 2798796415u)) * 1597334677u);
                let _e481 = bitcast<vec3<u32>>(vec3<i32>((_e342 + vec3<f32>(1f, 1f, 1f))));
                let _e490 = ((((_e481.x * 1597334677u) ^ (_e481.y * 3812015801u)) ^ (_e481.z * 2798796415u)) * 1597334677u);
                let _e503 = ((_e341 * 2.7f) + vec3<f32>(17.3f, 5.1f, 9.7f));
                let _e504 = floor(_e503);
                let _e505 = (_e503 - _e504);
                let _e509 = ((_e505 * _e505) * (vec3<f32>(3f, 3f, 3f) - (_e505 * 2f)));
                let _e511 = bitcast<vec3<u32>>(vec3<i32>(_e504));
                let _e520 = ((((_e511.x * 1597334677u) ^ (_e511.y * 3812015801u)) ^ (_e511.z * 2798796415u)) * 1597334677u);
                let _e529 = bitcast<vec3<u32>>(vec3<i32>((_e504 + vec3<f32>(1f, 0f, 0f))));
                let _e538 = ((((_e529.x * 1597334677u) ^ (_e529.y * 3812015801u)) ^ (_e529.z * 2798796415u)) * 1597334677u);
                let _e549 = bitcast<vec3<u32>>(vec3<i32>((_e504 + vec3<f32>(0f, 1f, 0f))));
                let _e558 = ((((_e549.x * 1597334677u) ^ (_e549.y * 3812015801u)) ^ (_e549.z * 2798796415u)) * 1597334677u);
                let _e567 = bitcast<vec3<u32>>(vec3<i32>((_e504 + vec3<f32>(1f, 1f, 0f))));
                let _e576 = ((((_e567.x * 1597334677u) ^ (_e567.y * 3812015801u)) ^ (_e567.z * 2798796415u)) * 1597334677u);
                let _e588 = bitcast<vec3<u32>>(vec3<i32>((_e504 + vec3<f32>(0f, 0f, 1f))));
                let _e597 = ((((_e588.x * 1597334677u) ^ (_e588.y * 3812015801u)) ^ (_e588.z * 2798796415u)) * 1597334677u);
                let _e606 = bitcast<vec3<u32>>(vec3<i32>((_e504 + vec3<f32>(1f, 0f, 1f))));
                let _e615 = ((((_e606.x * 1597334677u) ^ (_e606.y * 3812015801u)) ^ (_e606.z * 2798796415u)) * 1597334677u);
                let _e625 = bitcast<vec3<u32>>(vec3<i32>((_e504 + vec3<f32>(0f, 1f, 1f))));
                let _e634 = ((((_e625.x * 1597334677u) ^ (_e625.y * 3812015801u)) ^ (_e625.z * 2798796415u)) * 1597334677u);
                let _e643 = bitcast<vec3<u32>>(vec3<i32>((_e504 + vec3<f32>(1f, 1f, 1f))));
                let _e652 = ((((_e643.x * 1597334677u) ^ (_e643.y * 3812015801u)) ^ (_e643.z * 2798796415u)) * 1597334677u);
                let _e665 = mix(0.45f, 0.05f, _e323);
                phi_7686_ = smoothstep(-(_e665), _e665, ((_e337 + -24.45f) + ((((mix(mix(mix((f32(((_e358 ^ (_e358 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e376 ^ (_e376 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e347.x), mix((f32(((_e396 ^ (_e396 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e414 ^ (_e414 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e347.x), _e347.y), mix(mix((f32(((_e435 ^ (_e435 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e453 ^ (_e453 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e347.x), mix((f32(((_e472 ^ (_e472 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e490 ^ (_e490 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e347.x), _e347.y), _e347.z) * 0.65f) + (mix(mix(mix((f32(((_e520 ^ (_e520 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e538 ^ (_e538 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e509.x), mix((f32(((_e558 ^ (_e558 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e576 ^ (_e576 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e509.x), _e509.y), mix(mix((f32(((_e597 ^ (_e597 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e615 ^ (_e615 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e509.x), mix((f32(((_e634 ^ (_e634 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e652 ^ (_e652 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e509.x), _e509.y), _e509.z) * 0.35f)) - 0.5f) * mix(0.8f, 2.2f, _e323))));
                break;
            }
        }
        let _e674 = phi_7686_;
        let _e676 = local_22;
        let _e3010 = local_42;
        phi_7849_ = _e3010;
        phi_7816_ = _e674;
        phi_7785_ = mix(_e286, ((_e248 * _e676) * mix(vec3<f32>(1f, 1f, 1f), (_e253 * 2f), vec3<f32>(0.5f, 0.5f, 0.5f))), vec3(_e674));
    }
    let _e684 = phi_7849_;
    let _e686 = phi_7816_;
    let _e688 = phi_7785_;
    let _e689 = global_8;
    let _e690 = normalize(_e689);
    let _e693 = global_7.member_6[1u];
    phi_7698_ = _e690;
    if (_e693 > 0.5f) {
        let _e695 = global_9;
        let _e696 = _e695.xyz;
        let _e699 = (_e696 - (_e690 * dot(_e690, _e696)));
        phi_7699_ = _e690;
        if (dot(_e699, _e699) > 0.000000000001f) {
            let _e702 = normalize(_e699);
            let _e705 = global_9[3u];
            let _e709 = textureSample(global_22, global_4, _e245);
            let _e712 = global_7.member_6[2u];
            if (_e712 > 0.5f) {
                if (_e712 > 1.5f) {
                    phi_7689_ = _e709.xw;
                } else {
                    phi_7689_ = _e709.xy;
                }
                let _e718 = phi_7689_;
                let _e720 = ((_e718 * 2f) - vec2<f32>(1f, 1f));
                phi_7690_ = vec3<f32>(_e720.x, _e720.y, sqrt(clamp((1f - dot(_e720, _e720)), 0f, 1f)));
            } else {
                phi_7690_ = ((_e709.xyz * 2f) - vec3<f32>(1f, 1f, 1f));
            }
            let _e732 = phi_7690_;
            let _e735 = global_7.member_4[2u];
            let _e737 = (_e732.xy * _e735);
            phi_7699_ = normalize((((_e702 * _e737.x) + ((cross(_e690, _e702) * select(1f, -1f, (_e705 < 0f))) * _e737.y)) + (_e690 * _e732.z)));
        }
        let _e748 = phi_7699_;
        phi_7698_ = _e748;
    }
    let _e750 = phi_7698_;
    let _e753 = global_7.member_5[3u];
    let _e754 = (_e753 > 0.5f);
    if _e754 {
        let _e757 = global_7.member_1[2u];
        phi_7695_ = clamp(_e757, 0f, 1f);
    } else {
        phi_7695_ = 0f;
    }
    let _e760 = phi_7695_;
    phi_2344_ = _e754;
    if _e754 {
        let _e761 = global_23;
        phi_2344_ = !(_e761);
    }
    let _e764 = phi_2344_;
    phi_7885_ = _e750;
    if (_e764 && (_e760 <= 0f)) {
        phi_7885_ = -(_e750);
    }
    let _e769 = phi_7885_;
    let _e771 = global.member_4;
    let _e773 = normalize(_e771.xyz);
    let _e775 = global.member_6;
    let _e776 = _e775.xyz;
    let _e777 = global_12;
    let _e778 = (_e776 - _e777);
    let _e779 = normalize(_e778);
    let _e781 = normalize((_e773 + _e779));
    let _e782 = global_23;
    let _e784 = (_e690 * select(-1f, 1f, _e782));
    let _e786 = global_24[0u];
    let _e787 = (_e786 > 0.5f);
    let _e790 = global.member_5[3u];
    phi_7919_ = 1f;
    phi_7879_ = _e688;
    if ((_e790 > 0.5f) && _e787) {
        switch bitcast<i32>(0u) {
            default: {
                let _e796 = global.member_21[0u];
                let _e797 = i32(_e796);
                let _e799 = global.member_20;
                let _e804 = global.member_20[3u];
                let _e805 = (dot(_e799.xyz, _e777) + _e804);
                phi_7700_ = 0i;
                loop {
                    let _e807 = phi_7700_;
                    local_23 = _e807;
                    local_24 = _e807;
                    local_25 = _e807;
                    local_26 = _e807;
                    local_27 = _e807;
                    local_28 = _e807;
                    local_30 = _e807;
                    local_31 = _e807;
                    local_32 = _e807;
                    let _e809 = (_e807 < (_e797 - 1i));
                    phi_3946_ = _e809;
                    if _e809 {
                        let _e812 = global.member_16[_e807];
                        phi_3946_ = (_e805 > _e812);
                    }
                    let _e815 = phi_3946_;
                    if _e815 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_7700_ = (_e807 + 1i);
                    }
                }
                let _e819 = local_23;
                let _e821 = global.member_16[_e819];
                if (_e805 > _e821) {
                    phi_7756_ = vec3<f32>(1f, 1f, 1f);
                    phi_7755_ = 1f;
                    break;
                }
                let _e825 = local_24;
                let _e827 = global.member_18[_e825];
                let _e829 = (_e777 + (_e784 * _e827));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e833 = local_25;
                        let _e835 = global.member_14[_e833];
                        let _e840 = (_e835 * vec4<f32>(_e829.x, _e829.y, _e829.z, 1f));
                        let _e842 = (_e840.x < 0f);
                        phi_4059_ = _e842;
                        if !(_e842) {
                            phi_4059_ = (_e840.x > 1f);
                        }
                        let _e846 = phi_4059_;
                        phi_4066_ = _e846;
                        if !(_e846) {
                            phi_4066_ = (_e840.y < 0f);
                        }
                        let _e851 = phi_4066_;
                        phi_4073_ = _e851;
                        if !(_e851) {
                            phi_4073_ = (_e840.y > 1f);
                        }
                        let _e856 = phi_4073_;
                        if _e856 {
                            phi_7713_ = 1f;
                            break;
                        }
                        let _e858 = local_26;
                        let _e862 = local_27;
                        let _e868 = global.member_23;
                        let _e869 = _e868.xy;
                        let _e870 = (vec2<f32>(f32((_e858 & 1i)), f32((_e862 >> bitcast<u32>(1i)))) * _e869);
                        let _e875 = local_28;
                        let _e877 = global.member_19[_e875];
                        let _e878 = (min(_e840.z, 1f) - _e877);
                        let _e881 = global.member_22;
                        let _e882 = _e881.xy;
                        let _e883 = (_e882 * 0.5f);
                        let _e885 = (_e870 + (_e840.xy * _e869));
                        let _e886 = (_e870 + _e883);
                        let _e888 = ((_e870 + _e869) - _e883);
                        let _e893 = vec4<f32>(_e886.x, _e886.y, _e888.x, _e888.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e897 = global.member_22[2u];
                                let _e898 = i32(_e897);
                                if (_e898 <= 0i) {
                                    let _e902 = clamp(_e885, _e893.xy, _e893.zw);
                                    let _e907 = textureSampleCompare(global_2, global_1, vec3<f32>(_e902.x, _e902.y, _e878).xy, _e878);
                                    phi_7712_ = _e907;
                                    break;
                                }
                                let _e909 = ((_e885 / _e882) + vec2<f32>(0.5f, 0.5f));
                                let _e910 = floor(_e909);
                                let _e911 = (_e909 - _e910);
                                let _e913 = (_e898 == 1i);
                                if _e913 {
                                    let _e914 = (_e911 * 2f);
                                    local_18[0i] = (vec2<f32>(3f, 3f) - _e914);
                                    local_18[1i] = (vec2<f32>(1f, 1f) + _e914);
                                    let _e920 = local_18[0i];
                                    local_19[0i] = (((vec2<f32>(2f, 2f) - _e911) / _e920) - vec2<f32>(1f, 1f));
                                    let _e924 = local_18[1i];
                                    local_19[1i] = ((_e911 / _e924) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e928 = (_e911 * 3f);
                                    local_18[0i] = (vec2<f32>(4f, 4f) - _e928);
                                    local_18[1i] = vec2<f32>(7f, 7f);
                                    local_18[2i] = (vec2<f32>(1f, 1f) + _e928);
                                    let _e936 = local_18[0i];
                                    local_19[0i] = (((vec2<f32>(3f, 3f) - (_e911 * 2f)) / _e936) - vec2<f32>(2f, 2f));
                                    let _e941 = local_18[1i];
                                    local_19[1i] = ((vec2<f32>(3f, 3f) + _e911) / _e941);
                                    let _e944 = local_18[2i];
                                    local_19[2i] = ((_e911 / _e944) + vec2<f32>(2f, 2f));
                                }
                                let _e949 = select(3i, 2i, _e913);
                                phi_7705_ = 0f;
                                phi_7702_ = 0i;
                                loop {
                                    let _e951 = phi_7705_;
                                    let _e953 = phi_7702_;
                                    local_29 = _e951;
                                    if (_e953 < _e949) {
                                        phi_7711_ = _e951;
                                        phi_7708_ = 0i;
                                        loop {
                                            let _e956 = phi_7711_;
                                            let _e958 = phi_7708_;
                                            local_43 = _e956;
                                            if (_e958 < _e949) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e962 = local_19[_e958][0u];
                                                let _e965 = local_19[_e953][1u];
                                                let _e971 = clamp((_e882 * ((_e910 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e962, _e965))), _e893.xy, _e893.zw);
                                                let _e974 = local_18[_e958][0u];
                                                let _e977 = local_18[_e953][1u];
                                                let _e983 = textureSampleCompare(global_2, global_1, vec3<f32>(_e971.x, _e971.y, _e878).xy, _e878);
                                                phi_7711_ = (_e956 + ((_e974 * _e977) * _e983));
                                                phi_7708_ = (_e958 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e3033 = local_43;
                                        phi_7705_ = _e3033;
                                        phi_7702_ = (_e953 + 1i);
                                    }
                                }
                                let _e989 = local_29;
                                phi_7712_ = (_e989 * select(0.0069444445f, 0.0625f, _e913));
                                break;
                            }
                        }
                        let _e992 = phi_7712_;
                        phi_7713_ = _e992;
                        break;
                    }
                }
                let _e994 = phi_7713_;
                local_20 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e996 = local_30;
                let _e998 = local_20[_e996];
                let _e1001 = local_31;
                let _e1003 = global.member_17[_e1001];
                phi_7753_ = _e994;
                phi_7750_ = _e998;
                if (_e805 > _e1003) {
                    let _e1007 = ((_e805 - _e1003) / (_e821 - _e1003));
                    let _e1009 = local_32;
                    let _e1010 = (_e1009 + 1i);
                    if (_e1010 < _e797) {
                        let _e1014 = global.member_18[_e1010];
                        let _e1016 = (_e777 + (_e784 * _e1014));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1020 = global.member_14[_e1010];
                                let _e1025 = (_e1020 * vec4<f32>(_e1016.x, _e1016.y, _e1016.z, 1f));
                                let _e1027 = (_e1025.x < 0f);
                                phi_4346_ = _e1027;
                                if !(_e1027) {
                                    phi_4346_ = (_e1025.x > 1f);
                                }
                                let _e1031 = phi_4346_;
                                phi_4353_ = _e1031;
                                if !(_e1031) {
                                    phi_4353_ = (_e1025.y < 0f);
                                }
                                let _e1036 = phi_4353_;
                                phi_4360_ = _e1036;
                                if !(_e1036) {
                                    phi_4360_ = (_e1025.y > 1f);
                                }
                                let _e1041 = phi_4360_;
                                if _e1041 {
                                    phi_7733_ = 1f;
                                    break;
                                }
                                let _e1049 = global.member_23;
                                let _e1050 = _e1049.xy;
                                let _e1051 = (vec2<f32>(f32((_e1010 & 1i)), f32((_e1010 >> bitcast<u32>(1i)))) * _e1050);
                                let _e1056 = global.member_19[_e1010];
                                let _e1057 = (min(_e1025.z, 1f) - _e1056);
                                let _e1060 = global.member_22;
                                let _e1061 = _e1060.xy;
                                let _e1062 = (_e1061 * 0.5f);
                                let _e1064 = (_e1051 + (_e1025.xy * _e1050));
                                let _e1065 = (_e1051 + _e1062);
                                let _e1067 = ((_e1051 + _e1050) - _e1062);
                                let _e1072 = vec4<f32>(_e1065.x, _e1065.y, _e1067.x, _e1067.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1076 = global.member_22[2u];
                                        let _e1077 = i32(_e1076);
                                        if (_e1077 <= 0i) {
                                            let _e1081 = clamp(_e1064, _e1072.xy, _e1072.zw);
                                            let _e1086 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1081.x, _e1081.y, _e1057).xy, _e1057);
                                            phi_7732_ = _e1086;
                                            break;
                                        }
                                        let _e1088 = ((_e1064 / _e1061) + vec2<f32>(0.5f, 0.5f));
                                        let _e1089 = floor(_e1088);
                                        let _e1090 = (_e1088 - _e1089);
                                        let _e1092 = (_e1077 == 1i);
                                        if _e1092 {
                                            let _e1093 = (_e1090 * 2f);
                                            local_16[0i] = (vec2<f32>(3f, 3f) - _e1093);
                                            local_16[1i] = (vec2<f32>(1f, 1f) + _e1093);
                                            let _e1099 = local_16[0i];
                                            local_17[0i] = (((vec2<f32>(2f, 2f) - _e1090) / _e1099) - vec2<f32>(1f, 1f));
                                            let _e1103 = local_16[1i];
                                            local_17[1i] = ((_e1090 / _e1103) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1107 = (_e1090 * 3f);
                                            local_16[0i] = (vec2<f32>(4f, 4f) - _e1107);
                                            local_16[1i] = vec2<f32>(7f, 7f);
                                            local_16[2i] = (vec2<f32>(1f, 1f) + _e1107);
                                            let _e1115 = local_16[0i];
                                            local_17[0i] = (((vec2<f32>(3f, 3f) - (_e1090 * 2f)) / _e1115) - vec2<f32>(2f, 2f));
                                            let _e1120 = local_16[1i];
                                            local_17[1i] = ((vec2<f32>(3f, 3f) + _e1090) / _e1120);
                                            let _e1123 = local_16[2i];
                                            local_17[2i] = ((_e1090 / _e1123) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1128 = select(3i, 2i, _e1092);
                                        phi_7725_ = 0f;
                                        phi_7722_ = 0i;
                                        loop {
                                            let _e1130 = phi_7725_;
                                            let _e1132 = phi_7722_;
                                            local_33 = _e1130;
                                            if (_e1132 < _e1128) {
                                                phi_7731_ = _e1130;
                                                phi_7728_ = 0i;
                                                loop {
                                                    let _e1135 = phi_7731_;
                                                    let _e1137 = phi_7728_;
                                                    local_44 = _e1135;
                                                    if (_e1137 < _e1128) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1141 = local_17[_e1137][0u];
                                                        let _e1144 = local_17[_e1132][1u];
                                                        let _e1150 = clamp((_e1061 * ((_e1089 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1141, _e1144))), _e1072.xy, _e1072.zw);
                                                        let _e1153 = local_16[_e1137][0u];
                                                        let _e1156 = local_16[_e1132][1u];
                                                        let _e1162 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1150.x, _e1150.y, _e1057).xy, _e1057);
                                                        phi_7731_ = (_e1135 + ((_e1153 * _e1156) * _e1162));
                                                        phi_7728_ = (_e1137 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3048 = local_44;
                                                phi_7725_ = _e3048;
                                                phi_7722_ = (_e1132 + 1i);
                                            }
                                        }
                                        let _e1168 = local_33;
                                        phi_7732_ = (_e1168 * select(0.0069444445f, 0.0625f, _e1092));
                                        break;
                                    }
                                }
                                let _e1171 = phi_7732_;
                                phi_7733_ = _e1171;
                                break;
                            }
                        }
                        let _e1173 = phi_7733_;
                        local_21 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1176 = local_21[_e1010];
                        phi_7754_ = mix(_e994, _e1173, _e1007);
                        phi_7751_ = mix(_e998, _e1176, vec3(_e1007));
                    } else {
                        phi_7754_ = mix(_e994, 1f, _e1007);
                        phi_7751_ = _e998;
                    }
                    let _e1181 = phi_7754_;
                    let _e1183 = phi_7751_;
                    phi_7753_ = _e1181;
                    phi_7750_ = _e1183;
                }
                let _e1185 = phi_7753_;
                let _e1187 = phi_7750_;
                let _e1190 = global.member_22[3u];
                phi_7756_ = select(vec3<f32>(1f, 1f, 1f), _e1187, vec3((_e1190 > 0.5f)));
                phi_7755_ = _e1185;
                break;
            }
        }
        let _e1195 = phi_7756_;
        let _e1197 = phi_7755_;
        phi_7919_ = _e1197;
        phi_7879_ = (_e688 * _e1195);
    }
    let _e1200 = phi_7919_;
    let _e1202 = phi_7879_;
    let _e1204 = global.member_5;
    let _e1208 = global.member_4[3u];
    let _e1209 = (_e1204.xyz * _e1208);
    let _e1212 = global_7.member_6[3u];
    let _e1213 = (_e1212 > 0.5f);
    if _e1213 {
        phi_7808_ = 1f;
    } else {
        let _e1216 = global_7.member_4[3u];
        let _e1217 = textureSample(global_18, global_4, _e245);
        phi_7808_ = (1f + (_e1216 * (_e1217.x - 1f)));
    }
    let _e1223 = phi_7808_;
    let _e1225 = global_9[3u];
    let _e1226 = abs(_e1225);
    phi_8009_ = _e1223;
    if (_e1226 > 0f) {
        phi_8009_ = (_e1223 * min(_e1226, 1f));
    }
    let _e1231 = phi_8009_;
    if !(_e754) {
        let _e1233 = dot(_e769, _e773);
        let _e1240 = global_7.member_1[3u];
        let _e1244 = global_7.member_1[2u];
        let _e1251 = global.member_29[0u];
        if (_e1251 > 0.5f) {
            let _e1254 = global.member_29;
            let _e1261 = ((_e1254.z * _e769.x) - (_e1254.w * _e769.z));
            let _e1265 = ((_e1254.w * _e769.x) + (_e1254.z * _e769.z));
            let _e1269 = (1.092548f * _e1261);
            local_15 = array<f32, 9>(0.282095f, (0.488603f * _e769.y), (0.488603f * _e1265), (0.488603f * _e1261), (_e1269 * _e769.y), ((1.092548f * _e769.y) * _e1265), (0.315392f * (((3f * _e1265) * _e1265) - 1f)), (_e1269 * _e1265), (0.546274f * ((_e1261 * _e1261) - (_e769.y * _e769.y))));
            phi_8158_ = vec3<f32>(0f, 0f, 0f);
            phi_8157_ = 0i;
            loop {
                let _e1284 = phi_8158_;
                let _e1286 = phi_8157_;
                local_34 = _e1284;
                if (_e1286 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1290 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e1286, 0i)), 0i);
                    let _e1293 = local_15[_e1286];
                    phi_8158_ = (_e1284 + (_e1290.xyz * _e1293));
                    phi_8157_ = (_e1286 + 1i);
                }
            }
            let _e1298 = local_34;
            let _e1302 = global.member_29[1u];
            phi_8159_ = (max(_e1298, vec3<f32>(0f, 0f, 0f)) * _e1302);
        } else {
            let _e1305 = global.member_9;
            let _e1308 = global.member_8;
            let _e1317 = global.member_8[3u];
            phi_8159_ = (mix(_e1305.xyz, _e1308.xyz, vec3(((_e769.y * 0.5f) + 0.5f))) * _e1317);
        }
        let _e1320 = phi_8159_;
        let _e1326 = ((_e1202 * ((_e1320 * _e1231) + ((_e1209 * max(_e1233, 0f)) * _e1200))) + ((_e1209 * ((pow(max(dot(_e769, _e781), 0f), _e1240) * _e1244) * step(0f, _e1233))) * _e1200));
        let _e1329 = global.member_13[3u];
        phi_8168_ = _e1326;
        if (_e1329 > 0.5f) {
            let _e1332 = global.member_11;
            let _e1337 = global.member_11[3u];
            let _e1339 = global_15;
            let _e1342 = global.member_12;
            let _e1347 = global.member_13;
            let _e1350 = clamp(floor((_e1339.xy * _e1342.xy)), vec2<f32>(0f, 0f), (_e1347.xy - vec2<f32>(1f, 1f)));
            let _e1355 = global.member_12[2u];
            let _e1359 = global.member_12[3u];
            let _e1364 = global.member_13[2u];
            let _e1369 = global.member_13[1u];
            let _e1375 = global.member_13[0u];
            let _e1379 = u32(((((clamp(floor(((log2(max((dot(_e1332.xyz, _e777) + _e1337), 0.000001f)) * _e1355) + _e1359)), 0f, (_e1364 - 1f)) * _e1369) + _e1350.y) * _e1375) + _e1350.x));
            let _e1386 = global_16.member[(_e1379 >> bitcast<u32>(2i))][(_e1379 & 3u)];
            let _e1387 = (_e1386 & 65535u);
            phi_8169_ = _e1326;
            phi_8166_ = _e1387;
            loop {
                let _e1391 = phi_8169_;
                let _e1393 = phi_8166_;
                local_48 = _e1391;
                if (_e1393 < (_e1387 + (_e1386 >> bitcast<u32>(16i)))) {
                    let _e1396 = (_e1393 / 3u);
                    let _e1403 = global_17.member[(_e1396 >> bitcast<u32>(2i))][(_e1396 & 3u)];
                    let _e1409 = ((_e1403 >> bitcast<u32>(((_e1393 - (_e1396 * 3u)) * 10u))) & 1023u);
                    let _e1412 = global_11.member[_e1409];
                    let _e1414 = (_e1412.xyz - _e777);
                    let _e1415 = dot(_e1414, _e1414);
                    let _e1417 = (_e1415 * _e1412.w);
                    let _e1420 = clamp((1f - (_e1417 * _e1417)), 0f, 1f);
                    let _e1423 = (_e1414 * inverseSqrt(max(_e1415, 0.00000001f)));
                    let _e1426 = global_13.member[_e1409];
                    let _e1429 = global_14.member[_e1409];
                    let _e1437 = clamp(((dot(-(_e1423), _e1429.xyz) * _e1426.w) + _e1429.w), 0f, 1f);
                    let _e1444 = (_e1426.xyz * ((((_e1420 * _e1420) * _e1437) * _e1437) / max(_e1415, 0.0001f)));
                    phi_8374_ = _e1444;
                    if _e787 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1448 = global.member_21[2u];
                                let _e1449 = u32(_e1448);
                                if (_e1409 < _e1449) {
                                    let _e1453 = global.member_26[_e1409];
                                    let _e1456 = global.member_15[_e1409];
                                    let _e1465 = (_e1453.z * max((_e1456 * vec4<f32>(_e777.x, _e777.y, _e777.z, 1f)).w, 0f));
                                    let _e1468 = global.member_25[0u];
                                    let _e1474 = global.member_25[1u];
                                    let _e1477 = ((_e777 + (_e784 * (_e1465 * _e1468))) + (_e1423 * (_e1465 * _e1474)));
                                    let _e1482 = (_e1456 * vec4<f32>(_e1477.x, _e1477.y, _e1477.z, 1f));
                                    if (_e1482.w <= 0f) {
                                        phi_8320_ = 1f;
                                        break;
                                    }
                                    let _e1487 = (_e1482.xyz / vec3(_e1482.w));
                                    let _e1489 = (_e1487.x < 0f);
                                    phi_5001_ = _e1489;
                                    if !(_e1489) {
                                        phi_5001_ = (_e1487.x > 1f);
                                    }
                                    let _e1493 = phi_5001_;
                                    phi_5008_ = _e1493;
                                    if !(_e1493) {
                                        phi_5008_ = (_e1487.y < 0f);
                                    }
                                    let _e1498 = phi_5008_;
                                    phi_5015_ = _e1498;
                                    if !(_e1498) {
                                        phi_5015_ = (_e1487.y > 1f);
                                    }
                                    let _e1503 = phi_5015_;
                                    phi_5022_ = _e1503;
                                    if !(_e1503) {
                                        phi_5022_ = (_e1487.z > 1f);
                                    }
                                    let _e1508 = phi_5022_;
                                    if _e1508 {
                                        phi_8320_ = 1f;
                                        break;
                                    }
                                    let _e1511 = _e1453.xy;
                                    let _e1513 = global.member_23;
                                    let _e1514 = _e1513.zw;
                                    let _e1516 = global.member_22;
                                    let _e1517 = _e1516.xy;
                                    let _e1518 = (_e1517 * 0.5f);
                                    let _e1520 = (_e1511 + (_e1487.xy * _e1514));
                                    let _e1521 = (_e1511 + _e1518);
                                    let _e1523 = ((_e1511 + _e1514) - _e1518);
                                    let _e1528 = vec4<f32>(_e1521.x, _e1521.y, _e1523.x, _e1523.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e1532 = global.member_22[2u];
                                            let _e1533 = i32(_e1532);
                                            if (_e1533 <= 0i) {
                                                let _e1537 = clamp(_e1520, _e1528.xy, _e1528.zw);
                                                let _e1542 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1537.x, _e1537.y, _e1487.z).xy, _e1487.z);
                                                phi_8319_ = _e1542;
                                                break;
                                            }
                                            let _e1544 = ((_e1520 / _e1517) + vec2<f32>(0.5f, 0.5f));
                                            let _e1545 = floor(_e1544);
                                            let _e1546 = (_e1544 - _e1545);
                                            let _e1548 = (_e1533 == 1i);
                                            if _e1548 {
                                                let _e1549 = (_e1546 * 2f);
                                                local_11[0i] = (vec2<f32>(3f, 3f) - _e1549);
                                                local_11[1i] = (vec2<f32>(1f, 1f) + _e1549);
                                                let _e1555 = local_11[0i];
                                                local_12[0i] = (((vec2<f32>(2f, 2f) - _e1546) / _e1555) - vec2<f32>(1f, 1f));
                                                let _e1559 = local_11[1i];
                                                local_12[1i] = ((_e1546 / _e1559) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e1563 = (_e1546 * 3f);
                                                local_11[0i] = (vec2<f32>(4f, 4f) - _e1563);
                                                local_11[1i] = vec2<f32>(7f, 7f);
                                                local_11[2i] = (vec2<f32>(1f, 1f) + _e1563);
                                                let _e1571 = local_11[0i];
                                                local_12[0i] = (((vec2<f32>(3f, 3f) - (_e1546 * 2f)) / _e1571) - vec2<f32>(2f, 2f));
                                                let _e1576 = local_11[1i];
                                                local_12[1i] = ((vec2<f32>(3f, 3f) + _e1546) / _e1576);
                                                let _e1579 = local_11[2i];
                                                local_12[2i] = ((_e1546 / _e1579) + vec2<f32>(2f, 2f));
                                            }
                                            let _e1584 = select(3i, 2i, _e1548);
                                            phi_8312_ = 0f;
                                            phi_8309_ = 0i;
                                            loop {
                                                let _e1586 = phi_8312_;
                                                let _e1588 = phi_8309_;
                                                local_35 = _e1586;
                                                if (_e1588 < _e1584) {
                                                    phi_8318_ = _e1586;
                                                    phi_8315_ = 0i;
                                                    loop {
                                                        let _e1591 = phi_8318_;
                                                        let _e1593 = phi_8315_;
                                                        local_46 = _e1591;
                                                        if (_e1593 < _e1584) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e1597 = local_12[_e1593][0u];
                                                            let _e1600 = local_12[_e1588][1u];
                                                            let _e1606 = clamp((_e1517 * ((_e1545 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1597, _e1600))), _e1528.xy, _e1528.zw);
                                                            let _e1609 = local_11[_e1593][0u];
                                                            let _e1612 = local_11[_e1588][1u];
                                                            let _e1618 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1606.x, _e1606.y, _e1487.z).xy, _e1487.z);
                                                            phi_8318_ = (_e1591 + ((_e1609 * _e1612) * _e1618));
                                                            phi_8315_ = (_e1593 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e3079 = local_46;
                                                    phi_8312_ = _e3079;
                                                    phi_8309_ = (_e1588 + 1i);
                                                }
                                            }
                                            let _e1624 = local_35;
                                            phi_8319_ = (_e1624 * select(0.0069444445f, 0.0625f, _e1548));
                                            break;
                                        }
                                    }
                                    let _e1627 = phi_8319_;
                                    phi_8320_ = _e1627;
                                    break;
                                }
                                let _e1628 = (_e1409 - _e1449);
                                let _e1631 = global.member_21[3u];
                                if (_e1628 >= u32(_e1631)) {
                                    phi_8320_ = 1f;
                                    break;
                                }
                                let _e1636 = global.member_27[_e1628];
                                let _e1639 = global.member_28[_e1628];
                                let _e1641 = _e1636.xyz;
                                let _e1644 = (_e1636.w * length((_e777 - _e1641)));
                                let _e1647 = global.member_25[0u];
                                let _e1653 = global.member_25[1u];
                                let _e1657 = (((_e777 + (_e784 * (_e1644 * _e1647))) + (_e1423 * (_e1644 * _e1653))) - _e1641);
                                let _e1658 = abs(_e1657);
                                let _e1661 = (_e1658.x >= _e1658.y);
                                phi_5092_ = _e1661;
                                if _e1661 {
                                    phi_5092_ = (_e1658.x >= _e1658.z);
                                }
                                let _e1665 = phi_5092_;
                                if _e1665 {
                                    phi_8296_ = select(1i, 0i, (_e1657.x > 0f));
                                    phi_8294_ = _e1658.x;
                                } else {
                                    let _e1670 = (_e1658.y >= _e1658.z);
                                    if _e1670 {
                                        phi_8297_ = select(3i, 2i, (_e1657.y > 0f));
                                    } else {
                                        phi_8297_ = select(5i, 4i, (_e1657.z > 0f));
                                    }
                                    let _e1678 = phi_8297_;
                                    phi_8296_ = _e1678;
                                    phi_8294_ = select(_e1658.z, _e1658.y, _e1670);
                                }
                                let _e1681 = phi_8296_;
                                let _e1683 = phi_8294_;
                                if (_e1683 <= 0f) {
                                    phi_8320_ = 1f;
                                    break;
                                }
                                local_13 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e1686 = local_13[_e1681];
                                local_14 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e1689 = local_14[_e1681];
                                let _e1694 = global.member_24[2u];
                                let _e1697 = (vec2<f32>(dot(_e1657, _e1686), dot(_e1657, _e1689)) / vec2((_e1683 * _e1694)));
                                let _e1701 = (_e1639.z + (_e1639.w / _e1683));
                                if (_e1701 > 1f) {
                                    phi_8320_ = 1f;
                                    break;
                                }
                                let _e1716 = global.member_24;
                                let _e1717 = _e1716.xy;
                                let _e1719 = (_e1639.xy + (vec2<f32>(f32((_e1681 - (i32(floor((f32(_e1681) / f32(3i)))) * 3i))), f32((_e1681 / 3i))) * _e1717));
                                let _e1728 = global.member_22;
                                let _e1729 = _e1728.xy;
                                let _e1730 = (_e1729 * 0.5f);
                                let _e1732 = (_e1719 + (vec2<f32>((0.5f + (0.5f * _e1697.x)), (0.5f - (0.5f * _e1697.y))) * _e1717));
                                let _e1733 = (_e1719 + _e1730);
                                let _e1735 = ((_e1719 + _e1717) - _e1730);
                                let _e1740 = vec4<f32>(_e1733.x, _e1733.y, _e1735.x, _e1735.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1744 = global.member_22[2u];
                                        let _e1745 = i32(_e1744);
                                        if (_e1745 <= 0i) {
                                            let _e1749 = clamp(_e1732, _e1740.xy, _e1740.zw);
                                            let _e1754 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1749.x, _e1749.y, _e1701).xy, _e1701);
                                            phi_8308_ = _e1754;
                                            break;
                                        }
                                        let _e1756 = ((_e1732 / _e1729) + vec2<f32>(0.5f, 0.5f));
                                        let _e1757 = floor(_e1756);
                                        let _e1758 = (_e1756 - _e1757);
                                        let _e1760 = (_e1745 == 1i);
                                        if _e1760 {
                                            let _e1761 = (_e1758 * 2f);
                                            local_9[0i] = (vec2<f32>(3f, 3f) - _e1761);
                                            local_9[1i] = (vec2<f32>(1f, 1f) + _e1761);
                                            let _e1767 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(2f, 2f) - _e1758) / _e1767) - vec2<f32>(1f, 1f));
                                            let _e1771 = local_9[1i];
                                            local_10[1i] = ((_e1758 / _e1771) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1775 = (_e1758 * 3f);
                                            local_9[0i] = (vec2<f32>(4f, 4f) - _e1775);
                                            local_9[1i] = vec2<f32>(7f, 7f);
                                            local_9[2i] = (vec2<f32>(1f, 1f) + _e1775);
                                            let _e1783 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(3f, 3f) - (_e1758 * 2f)) / _e1783) - vec2<f32>(2f, 2f));
                                            let _e1788 = local_9[1i];
                                            local_10[1i] = ((vec2<f32>(3f, 3f) + _e1758) / _e1788);
                                            let _e1791 = local_9[2i];
                                            local_10[2i] = ((_e1758 / _e1791) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1796 = select(3i, 2i, _e1760);
                                        phi_8301_ = 0f;
                                        phi_8298_ = 0i;
                                        loop {
                                            let _e1798 = phi_8301_;
                                            let _e1800 = phi_8298_;
                                            local_36 = _e1798;
                                            if (_e1800 < _e1796) {
                                                phi_8307_ = _e1798;
                                                phi_8304_ = 0i;
                                                loop {
                                                    let _e1803 = phi_8307_;
                                                    let _e1805 = phi_8304_;
                                                    local_47 = _e1803;
                                                    if (_e1805 < _e1796) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1809 = local_10[_e1805][0u];
                                                        let _e1812 = local_10[_e1800][1u];
                                                        let _e1818 = clamp((_e1729 * ((_e1757 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1809, _e1812))), _e1740.xy, _e1740.zw);
                                                        let _e1821 = local_9[_e1805][0u];
                                                        let _e1824 = local_9[_e1800][1u];
                                                        let _e1830 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1818.x, _e1818.y, _e1701).xy, _e1701);
                                                        phi_8307_ = (_e1803 + ((_e1821 * _e1824) * _e1830));
                                                        phi_8304_ = (_e1805 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3091 = local_47;
                                                phi_8301_ = _e3091;
                                                phi_8298_ = (_e1800 + 1i);
                                            }
                                        }
                                        let _e1836 = local_36;
                                        phi_8308_ = (_e1836 * select(0.0069444445f, 0.0625f, _e1760));
                                        break;
                                    }
                                }
                                let _e1839 = phi_8308_;
                                phi_8320_ = _e1839;
                                break;
                            }
                        }
                        let _e1841 = phi_8320_;
                        phi_8374_ = (_e1444 * _e1841);
                    }
                    let _e1844 = phi_8374_;
                    let _e1845 = dot(_e769, _e1423);
                    local_45 = (_e1391 + (((_e1202 * max(_e1845, 0f)) * _e1844) + (_e1844 * ((pow(max(dot(_e769, normalize((_e1423 + _e779))), 0f), _e1240) * _e1244) * step(0f, _e1845)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3071 = local_45;
                    phi_8169_ = _e3071;
                    phi_8166_ = (_e1393 + bitcast<u32>(1i));
                }
            }
            let _e3101 = local_48;
            phi_8168_ = _e3101;
        }
        let _e1863 = phi_8168_;
        phi_8167_ = _e1863;
    } else {
        let _e1864 = textureSample(global_25, global_4, _e245);
        let _e1867 = global_7.member_4[0u];
        let _e1870 = clamp((_e1867 * _e1864.z), 0f, 1f);
        let _e1873 = global_7.member_4[1u];
        let _e1876 = clamp((_e1873 * _e1864.y), 0.045f, 1f);
        phi_7880_ = _e1870;
        phi_7875_ = _e1876;
        if (_e686 > 0f) {
            phi_7880_ = mix(_e1870, _e684.y, _e686);
            phi_7875_ = mix(_e1876, max(_e684.x, 0.045f), _e686);
        }
        let _e1884 = phi_7880_;
        let _e1886 = phi_7875_;
        let _e1887 = (_e1886 * _e1886);
        let _e1889 = (_e1202 * (1f - _e1884));
        let _e1891 = mix(vec3<f32>(0.04f, 0.04f, 0.04f), _e1202, vec3(_e1884));
        let _e1892 = (_e760 > 0f);
        phi_7908_ = _e769;
        if _e1892 {
            let _e1893 = dpdx(_e777);
            let _e1894 = dpdy(_e777);
            let _e1895 = cross(_e1893, _e1894);
            phi_7909_ = _e769;
            if (dot(_e1895, _e1895) > 0.00000000000000000001f) {
                phi_7909_ = normalize(((normalize(_e1895) * select(1f, -1f, (dot(_e1895, _e779) < 0f))) + (_e769 - _e690)));
            }
            let _e1907 = phi_7909_;
            phi_7908_ = _e1907;
        }
        let _e1909 = phi_7908_;
        let _e1911 = max(dot(_e1909, _e779), 0.0001f);
        let _e1914 = dot(_e1909, _e773);
        let _e1915 = clamp(_e1914, 0f, 1f);
        let _e1917 = clamp(dot(_e1909, _e781), 0f, 1f);
        let _e1919 = clamp(dot(_e779, _e781), 0f, 1f);
        phi_7913_ = _e1911;
        phi_7912_ = _e1919;
        if _e1892 {
            phi_7913_ = max(_e1911, 0.5f);
            phi_7912_ = max(_e1919, 0.5f);
        }
        let _e1923 = phi_7913_;
        let _e1925 = phi_7912_;
        let _e1928 = (vec3<f32>(1f, 1f, 1f) - _e1891);
        let _e1930 = (_e1891 + (_e1928 * pow((1f - _e1925), 5f)));
        let _e1931 = (_e1887 * _e1887);
        let _e1933 = (_e1931 - 1f);
        let _e1935 = (((_e1917 * _e1917) * _e1933) + 1f);
        let _e1940 = (1f - _e1931);
        let _e1943 = sqrt((((_e1923 * _e1923) * _e1940) + _e1931));
        let _e1962 = ((((((vec3<f32>(1f, 1f, 1f) - _e1930) * _e1889) * clamp(dot(_e769, _e773), 0f, 1f)) + (((_e1930 * ((_e1931 / ((3.1415927f * _e1935) * _e1935)) * (0.5f / max(((_e1915 * _e1943) + (_e1923 * sqrt((((_e1915 * _e1915) * _e1940) + _e1931)))), 0.00001f)))) * 3.1415927f) * _e1915)) * _e1209) * _e1200);
        phi_8023_ = _e1962;
        if _e1892 {
            phi_8023_ = (_e1962 + (((((_e1889 * _e1209) * _e1200) * _e760) * clamp(-(_e1914), 0f, 1f)) * (0.35f + (0.65f * pow(clamp(dot(-(_e779), _e773), 0f, 1f), 3f)))));
        }
        let _e1978 = phi_8023_;
        let _e1981 = global.member_29[0u];
        if (_e1981 > 0.5f) {
            let _e1987 = textureSample(global_5, global_6, (((vec2<f32>(_e1923, _e1886) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
            let _e1990 = global.member_29;
            let _e1997 = ((_e1990.z * _e769.x) - (_e1990.w * _e769.z));
            let _e2001 = ((_e1990.w * _e769.x) + (_e1990.z * _e769.z));
            let _e2005 = (1.092548f * _e1997);
            local_8 = array<f32, 9>(0.282095f, (0.488603f * _e769.y), (0.488603f * _e2001), (0.488603f * _e1997), (_e2005 * _e769.y), ((1.092548f * _e769.y) * _e2001), (0.315392f * (((3f * _e2001) * _e2001) - 1f)), (_e2005 * _e2001), (0.546274f * ((_e1997 * _e1997) - (_e769.y * _e769.y))));
            phi_7931_ = vec3<f32>(0f, 0f, 0f);
            phi_7930_ = 0i;
            loop {
                let _e2020 = phi_7931_;
                let _e2022 = phi_7930_;
                local_37 = _e2020;
                if (_e2022 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e2026 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e2022, 0i)), 0i);
                    let _e2029 = local_8[_e2022];
                    phi_7931_ = (_e2020 + (_e2026.xyz * _e2029));
                    phi_7930_ = (_e2022 + 1i);
                }
            }
            let _e2034 = local_37;
            let _e2038 = global.member_29[1u];
            let _e2041 = reflect(-(_e779), _e1909);
            let _e2058 = vec2<f32>(((atan2(((_e1990.z * _e2041.x) - (_e1990.w * _e2041.z)), -(((_e1990.w * _e2041.x) + (_e1990.z * _e2041.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e2041.y, -1f, 1f)) * 0.31830987f));
            let _e2059 = (_e1886 * 5f);
            let _e2061 = min(i32(_e2059), 4i);
            local_6 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e2063 = local_6[_e2061];
            let _e2067 = ((_e2058 * vec2<f32>(_e2063.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e2068 = floor(_e2067);
            let _e2069 = (_e2067 - _e2068);
            let _e2071 = i32(_e2068.x);
            let _e2073 = i32(_e2068.y);
            phi_7934_ = _e2071;
            if (_e2071 < 0i) {
                phi_7934_ = (_e2071 + _e2063.z);
            }
            let _e2078 = phi_7934_;
            phi_7935_ = _e2078;
            if (_e2078 >= _e2063.z) {
                phi_7935_ = (_e2078 - _e2063.z);
            }
            let _e2083 = phi_7935_;
            let _e2084 = (_e2083 + 1i);
            let _e2086 = select(_e2084, 0i, (_e2084 == _e2063.z));
            let _e2090 = min((_e2073 + 1i), (_e2063.w - 1i));
            let _e2091 = max(_e2073, 0i);
            let _e2092 = _e2063.xy;
            let _e2095 = textureLoad(global_3, (_e2092 + vec2<i32>(_e2083, _e2091)), 0i);
            let _e2099 = textureLoad(global_3, (_e2092 + vec2<i32>(_e2086, _e2091)), 0i);
            let _e2103 = textureLoad(global_3, (_e2092 + vec2<i32>(_e2083, _e2090)), 0i);
            let _e2107 = textureLoad(global_3, (_e2092 + vec2<i32>(_e2086, _e2090)), 0i);
            let _e2110 = vec3(_e2069.x);
            local_7 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e2118 = local_7[(_e2061 + 1i)];
            let _e2122 = ((_e2058 * vec2<f32>(_e2118.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e2123 = floor(_e2122);
            let _e2124 = (_e2122 - _e2123);
            let _e2126 = i32(_e2123.x);
            let _e2128 = i32(_e2123.y);
            phi_7941_ = _e2126;
            if (_e2126 < 0i) {
                phi_7941_ = (_e2126 + _e2118.z);
            }
            let _e2133 = phi_7941_;
            phi_7942_ = _e2133;
            if (_e2133 >= _e2118.z) {
                phi_7942_ = (_e2133 - _e2118.z);
            }
            let _e2138 = phi_7942_;
            let _e2139 = (_e2138 + 1i);
            let _e2141 = select(_e2139, 0i, (_e2139 == _e2118.z));
            let _e2145 = min((_e2128 + 1i), (_e2118.w - 1i));
            let _e2146 = max(_e2128, 0i);
            let _e2147 = _e2118.xy;
            let _e2150 = textureLoad(global_3, (_e2147 + vec2<i32>(_e2138, _e2146)), 0i);
            let _e2154 = textureLoad(global_3, (_e2147 + vec2<i32>(_e2141, _e2146)), 0i);
            let _e2158 = textureLoad(global_3, (_e2147 + vec2<i32>(_e2138, _e2145)), 0i);
            let _e2162 = textureLoad(global_3, (_e2147 + vec2<i32>(_e2141, _e2145)), 0i);
            let _e2165 = vec3(_e2124.x);
            phi_7985_ = (max(_e2034, vec3<f32>(0f, 0f, 0f)) * _e2038);
            phi_7973_ = _e1987.xy;
            phi_7949_ = (mix(mix(mix(_e2095.xyz, _e2099.xyz, _e2110), mix(_e2103.xyz, _e2107.xyz, _e2110), vec3(_e2069.y)), mix(mix(_e2150.xyz, _e2154.xyz, _e2165), mix(_e2158.xyz, _e2162.xyz, _e2165), vec3(_e2124.y)), vec3((_e2059 - f32(_e2061)))) * _e2038);
        } else {
            let _e2177 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e1886) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
            let _e2190 = global.member_9;
            let _e2191 = _e2190.xyz;
            let _e2193 = global.member_8;
            let _e2194 = _e2193.xyz;
            let _e2202 = global.member_8[3u];
            let _e2203 = (mix(_e2191, _e2194, vec3(((_e769.y * 0.5f) + 0.5f))) * _e2202);
            phi_7985_ = _e2203;
            phi_7973_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e2177.x * _e2177.x), exp2((-9.28f * _e1923))) * _e2177.x) + _e2177.y)) + _e2177.zw);
            phi_7949_ = mix((mix(_e2191, _e2194, vec3(((reflect(-(_e779), _e1909).y * 0.5f) + 0.5f))) * _e2202), _e2203, vec3(_e1886));
        }
        let _e2215 = phi_7985_;
        let _e2217 = phi_7973_;
        let _e2219 = phi_7949_;
        phi_2819_ = _e1213;
        if _e1213 {
            let _e2222 = global.member_33[2u];
            phi_2819_ = (_e2222 > 0.5f);
        }
        let _e2225 = phi_2819_;
        phi_7994_ = _e2219;
        if _e2225 {
            switch bitcast<i32>(0u) {
                default: {
                    let _e2228 = global.member_31;
                    let _e2229 = _e2228.xyz;
                    let _e2232 = global.member_33[0u];
                    let _e2237 = global.member_31[3u];
                    let _e2246 = global.member_32[1u];
                    let _e2252 = global.member_32[0u];
                    let _e2255 = (((_e2252 * (1f - smoothstep((_e2232 * 0.5f), _e2232, abs((dot(_e2229, _e777) - _e2237))))) * smoothstep(0.5f, 0.9f, dot(_e784, _e2229))) * (1f - smoothstep((_e2246 * 0.5f), _e2246, _e1886)));
                    if (_e2255 <= 0f) {
                        phi_7970_ = _e2219;
                        break;
                    }
                    let _e2262 = global.member_32[3u];
                    let _e2264 = (_e777 + ((_e769 - (_e2229 * dot(_e769, _e2229))) * _e2262));
                    let _e2266 = global.member_30;
                    let _e2271 = (_e2266 * vec4<f32>(_e2264.x, _e2264.y, _e2264.z, 1f));
                    let _e2283 = global.member_32[2u];
                    phi_7969_ = 0f;
                    phi_7968_ = vec3<f32>(0f, 0f, 0f);
                    phi_7967_ = 0i;
                    loop {
                        let _e2286 = phi_7969_;
                        let _e2288 = phi_7968_;
                        let _e2290 = phi_7967_;
                        local_38 = _e2288;
                        local_39 = _e2286;
                        if (_e2290 < 12i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e2292 = f32(_e2290);
                            let _e2297 = (_e2292 * 2.3999631f);
                            let _e2301 = global.member_33[1u];
                            let _e2306 = ((((vec2<f32>(_e2271.x, -(_e2271.y)) / vec2(_e2271.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e2297) * _e2301), sin(_e2297)) * (sqrt(((_e2292 + 0.5f) * 0.083333336f)) * (_e2283 * _e1886))));
                            let _e2308 = min(_e2306, (vec2<f32>(1f, 1f) - _e2306));
                            let _e2312 = smoothstep(0f, 0.04f, min(_e2308.x, _e2308.y));
                            let _e2314 = textureSampleLevel(global_18, global_4, clamp(_e2306, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                            let _e2315 = _e2314.xyz;
                            phi_7969_ = (_e2286 + (_e2314.w * _e2312));
                            phi_7968_ = (_e2288 + ((_e2315 / (vec3<f32>(1f, 1f, 1f) - min(_e2315, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e2312));
                            phi_7967_ = (_e2290 + 1i);
                        }
                    }
                    let _e2326 = local_38;
                    let _e2329 = local_39;
                    phi_7970_ = mix(_e2219, ((_e2326 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e2219 * (1f - (_e2329 * 0.083333336f)))), vec3(_e2255));
                    break;
                }
            }
            let _e2337 = phi_7970_;
            phi_7994_ = _e2337;
        }
        let _e2339 = phi_7994_;
        let _e2344 = ((_e1891 * _e2217.x) + vec3(_e2217.y));
        let _e2351 = (_e1978 + (((((vec3<f32>(1f, 1f, 1f) - _e2344) * _e1889) * _e2215) + (_e2344 * _e2339)) * _e1231));
        let _e2354 = global.member_13[3u];
        phi_8170_ = _e2351;
        if (_e2354 > 0.5f) {
            let _e2357 = global.member_11;
            let _e2362 = global.member_11[3u];
            let _e2364 = global_15;
            let _e2367 = global.member_12;
            let _e2372 = global.member_13;
            let _e2375 = clamp(floor((_e2364.xy * _e2367.xy)), vec2<f32>(0f, 0f), (_e2372.xy - vec2<f32>(1f, 1f)));
            let _e2380 = global.member_12[2u];
            let _e2384 = global.member_12[3u];
            let _e2389 = global.member_13[2u];
            let _e2394 = global.member_13[1u];
            let _e2400 = global.member_13[0u];
            let _e2404 = u32(((((clamp(floor(((log2(max((dot(_e2357.xyz, _e777) + _e2362), 0.000001f)) * _e2380) + _e2384)), 0f, (_e2389 - 1f)) * _e2394) + _e2375.y) * _e2400) + _e2375.x));
            let _e2411 = global_16.member[(_e2404 >> bitcast<u32>(2i))][(_e2404 & 3u)];
            let _e2412 = (_e2411 & 65535u);
            phi_8123_ = _e2351;
            phi_8026_ = _e2412;
            loop {
                let _e2416 = phi_8123_;
                let _e2418 = phi_8026_;
                local_52 = _e2416;
                if (_e2418 < (_e2412 + (_e2411 >> bitcast<u32>(16i)))) {
                    let _e2421 = (_e2418 / 3u);
                    let _e2428 = global_17.member[(_e2421 >> bitcast<u32>(2i))][(_e2421 & 3u)];
                    let _e2434 = ((_e2428 >> bitcast<u32>(((_e2418 - (_e2421 * 3u)) * 10u))) & 1023u);
                    let _e2437 = global_11.member[_e2434];
                    let _e2439 = (_e2437.xyz - _e777);
                    let _e2440 = dot(_e2439, _e2439);
                    let _e2442 = (_e2440 * _e2437.w);
                    let _e2445 = clamp((1f - (_e2442 * _e2442)), 0f, 1f);
                    let _e2448 = (_e2439 * inverseSqrt(max(_e2440, 0.00000001f)));
                    let _e2451 = global_13.member[_e2434];
                    let _e2454 = global_14.member[_e2434];
                    let _e2462 = clamp(((dot(-(_e2448), _e2454.xyz) * _e2451.w) + _e2454.w), 0f, 1f);
                    let _e2469 = (_e2451.xyz * ((((_e2445 * _e2445) * _e2462) * _e2462) / max(_e2440, 0.0001f)));
                    phi_8121_ = _e2469;
                    if _e787 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e2473 = global.member_21[2u];
                                let _e2474 = u32(_e2473);
                                if (_e2434 < _e2474) {
                                    let _e2478 = global.member_26[_e2434];
                                    let _e2481 = global.member_15[_e2434];
                                    let _e2490 = (_e2478.z * max((_e2481 * vec4<f32>(_e777.x, _e777.y, _e777.z, 1f)).w, 0f));
                                    let _e2493 = global.member_25[0u];
                                    let _e2499 = global.member_25[1u];
                                    let _e2502 = ((_e777 + (_e784 * (_e2490 * _e2493))) + (_e2448 * (_e2490 * _e2499)));
                                    let _e2507 = (_e2481 * vec4<f32>(_e2502.x, _e2502.y, _e2502.z, 1f));
                                    if (_e2507.w <= 0f) {
                                        phi_8053_ = 1f;
                                        break;
                                    }
                                    let _e2512 = (_e2507.xyz / vec3(_e2507.w));
                                    let _e2514 = (_e2512.x < 0f);
                                    phi_6683_ = _e2514;
                                    if !(_e2514) {
                                        phi_6683_ = (_e2512.x > 1f);
                                    }
                                    let _e2518 = phi_6683_;
                                    phi_6690_ = _e2518;
                                    if !(_e2518) {
                                        phi_6690_ = (_e2512.y < 0f);
                                    }
                                    let _e2523 = phi_6690_;
                                    phi_6697_ = _e2523;
                                    if !(_e2523) {
                                        phi_6697_ = (_e2512.y > 1f);
                                    }
                                    let _e2528 = phi_6697_;
                                    phi_6704_ = _e2528;
                                    if !(_e2528) {
                                        phi_6704_ = (_e2512.z > 1f);
                                    }
                                    let _e2533 = phi_6704_;
                                    if _e2533 {
                                        phi_8053_ = 1f;
                                        break;
                                    }
                                    let _e2536 = _e2478.xy;
                                    let _e2538 = global.member_23;
                                    let _e2539 = _e2538.zw;
                                    let _e2541 = global.member_22;
                                    let _e2542 = _e2541.xy;
                                    let _e2543 = (_e2542 * 0.5f);
                                    let _e2545 = (_e2536 + (_e2512.xy * _e2539));
                                    let _e2546 = (_e2536 + _e2543);
                                    let _e2548 = ((_e2536 + _e2539) - _e2543);
                                    let _e2553 = vec4<f32>(_e2546.x, _e2546.y, _e2548.x, _e2548.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e2557 = global.member_22[2u];
                                            let _e2558 = i32(_e2557);
                                            if (_e2558 <= 0i) {
                                                let _e2562 = clamp(_e2545, _e2553.xy, _e2553.zw);
                                                let _e2567 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2562.x, _e2562.y, _e2512.z).xy, _e2512.z);
                                                phi_8052_ = _e2567;
                                                break;
                                            }
                                            let _e2569 = ((_e2545 / _e2542) + vec2<f32>(0.5f, 0.5f));
                                            let _e2570 = floor(_e2569);
                                            let _e2571 = (_e2569 - _e2570);
                                            let _e2573 = (_e2558 == 1i);
                                            if _e2573 {
                                                let _e2574 = (_e2571 * 2f);
                                                local_2[0i] = (vec2<f32>(3f, 3f) - _e2574);
                                                local_2[1i] = (vec2<f32>(1f, 1f) + _e2574);
                                                let _e2580 = local_2[0i];
                                                local_3[0i] = (((vec2<f32>(2f, 2f) - _e2571) / _e2580) - vec2<f32>(1f, 1f));
                                                let _e2584 = local_2[1i];
                                                local_3[1i] = ((_e2571 / _e2584) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e2588 = (_e2571 * 3f);
                                                local_2[0i] = (vec2<f32>(4f, 4f) - _e2588);
                                                local_2[1i] = vec2<f32>(7f, 7f);
                                                local_2[2i] = (vec2<f32>(1f, 1f) + _e2588);
                                                let _e2596 = local_2[0i];
                                                local_3[0i] = (((vec2<f32>(3f, 3f) - (_e2571 * 2f)) / _e2596) - vec2<f32>(2f, 2f));
                                                let _e2601 = local_2[1i];
                                                local_3[1i] = ((vec2<f32>(3f, 3f) + _e2571) / _e2601);
                                                let _e2604 = local_2[2i];
                                                local_3[2i] = ((_e2571 / _e2604) + vec2<f32>(2f, 2f));
                                            }
                                            let _e2609 = select(3i, 2i, _e2573);
                                            phi_8045_ = 0f;
                                            phi_8042_ = 0i;
                                            loop {
                                                let _e2611 = phi_8045_;
                                                let _e2613 = phi_8042_;
                                                local_40 = _e2611;
                                                if (_e2613 < _e2609) {
                                                    phi_8051_ = _e2611;
                                                    phi_8048_ = 0i;
                                                    loop {
                                                        let _e2616 = phi_8051_;
                                                        let _e2618 = phi_8048_;
                                                        local_50 = _e2616;
                                                        if (_e2618 < _e2609) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e2622 = local_3[_e2618][0u];
                                                            let _e2625 = local_3[_e2613][1u];
                                                            let _e2631 = clamp((_e2542 * ((_e2570 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2622, _e2625))), _e2553.xy, _e2553.zw);
                                                            let _e2634 = local_2[_e2618][0u];
                                                            let _e2637 = local_2[_e2613][1u];
                                                            let _e2643 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2631.x, _e2631.y, _e2512.z).xy, _e2512.z);
                                                            phi_8051_ = (_e2616 + ((_e2634 * _e2637) * _e2643));
                                                            phi_8048_ = (_e2618 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e3137 = local_50;
                                                    phi_8045_ = _e3137;
                                                    phi_8042_ = (_e2613 + 1i);
                                                }
                                            }
                                            let _e2649 = local_40;
                                            phi_8052_ = (_e2649 * select(0.0069444445f, 0.0625f, _e2573));
                                            break;
                                        }
                                    }
                                    let _e2652 = phi_8052_;
                                    phi_8053_ = _e2652;
                                    break;
                                }
                                let _e2653 = (_e2434 - _e2474);
                                let _e2656 = global.member_21[3u];
                                if (_e2653 >= u32(_e2656)) {
                                    phi_8053_ = 1f;
                                    break;
                                }
                                let _e2661 = global.member_27[_e2653];
                                let _e2664 = global.member_28[_e2653];
                                let _e2666 = _e2661.xyz;
                                let _e2669 = (_e2661.w * length((_e777 - _e2666)));
                                let _e2672 = global.member_25[0u];
                                let _e2678 = global.member_25[1u];
                                let _e2682 = (((_e777 + (_e784 * (_e2669 * _e2672))) + (_e2448 * (_e2669 * _e2678))) - _e2666);
                                let _e2683 = abs(_e2682);
                                let _e2686 = (_e2683.x >= _e2683.y);
                                phi_6774_ = _e2686;
                                if _e2686 {
                                    phi_6774_ = (_e2683.x >= _e2683.z);
                                }
                                let _e2690 = phi_6774_;
                                if _e2690 {
                                    phi_8029_ = select(1i, 0i, (_e2682.x > 0f));
                                    phi_8027_ = _e2683.x;
                                } else {
                                    let _e2695 = (_e2683.y >= _e2683.z);
                                    if _e2695 {
                                        phi_8030_ = select(3i, 2i, (_e2682.y > 0f));
                                    } else {
                                        phi_8030_ = select(5i, 4i, (_e2682.z > 0f));
                                    }
                                    let _e2703 = phi_8030_;
                                    phi_8029_ = _e2703;
                                    phi_8027_ = select(_e2683.z, _e2683.y, _e2695);
                                }
                                let _e2706 = phi_8029_;
                                let _e2708 = phi_8027_;
                                if (_e2708 <= 0f) {
                                    phi_8053_ = 1f;
                                    break;
                                }
                                local_4 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e2711 = local_4[_e2706];
                                local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e2714 = local_5[_e2706];
                                let _e2719 = global.member_24[2u];
                                let _e2722 = (vec2<f32>(dot(_e2682, _e2711), dot(_e2682, _e2714)) / vec2((_e2708 * _e2719)));
                                let _e2726 = (_e2664.z + (_e2664.w / _e2708));
                                if (_e2726 > 1f) {
                                    phi_8053_ = 1f;
                                    break;
                                }
                                let _e2741 = global.member_24;
                                let _e2742 = _e2741.xy;
                                let _e2744 = (_e2664.xy + (vec2<f32>(f32((_e2706 - (i32(floor((f32(_e2706) / f32(3i)))) * 3i))), f32((_e2706 / 3i))) * _e2742));
                                let _e2753 = global.member_22;
                                let _e2754 = _e2753.xy;
                                let _e2755 = (_e2754 * 0.5f);
                                let _e2757 = (_e2744 + (vec2<f32>((0.5f + (0.5f * _e2722.x)), (0.5f - (0.5f * _e2722.y))) * _e2742));
                                let _e2758 = (_e2744 + _e2755);
                                let _e2760 = ((_e2744 + _e2742) - _e2755);
                                let _e2765 = vec4<f32>(_e2758.x, _e2758.y, _e2760.x, _e2760.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e2769 = global.member_22[2u];
                                        let _e2770 = i32(_e2769);
                                        if (_e2770 <= 0i) {
                                            let _e2774 = clamp(_e2757, _e2765.xy, _e2765.zw);
                                            let _e2779 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2774.x, _e2774.y, _e2726).xy, _e2726);
                                            phi_8041_ = _e2779;
                                            break;
                                        }
                                        let _e2781 = ((_e2757 / _e2754) + vec2<f32>(0.5f, 0.5f));
                                        let _e2782 = floor(_e2781);
                                        let _e2783 = (_e2781 - _e2782);
                                        let _e2785 = (_e2770 == 1i);
                                        if _e2785 {
                                            let _e2786 = (_e2783 * 2f);
                                            local[0i] = (vec2<f32>(3f, 3f) - _e2786);
                                            local[1i] = (vec2<f32>(1f, 1f) + _e2786);
                                            let _e2792 = local[0i];
                                            local_1[0i] = (((vec2<f32>(2f, 2f) - _e2783) / _e2792) - vec2<f32>(1f, 1f));
                                            let _e2796 = local[1i];
                                            local_1[1i] = ((_e2783 / _e2796) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e2800 = (_e2783 * 3f);
                                            local[0i] = (vec2<f32>(4f, 4f) - _e2800);
                                            local[1i] = vec2<f32>(7f, 7f);
                                            local[2i] = (vec2<f32>(1f, 1f) + _e2800);
                                            let _e2808 = local[0i];
                                            local_1[0i] = (((vec2<f32>(3f, 3f) - (_e2783 * 2f)) / _e2808) - vec2<f32>(2f, 2f));
                                            let _e2813 = local[1i];
                                            local_1[1i] = ((vec2<f32>(3f, 3f) + _e2783) / _e2813);
                                            let _e2816 = local[2i];
                                            local_1[2i] = ((_e2783 / _e2816) + vec2<f32>(2f, 2f));
                                        }
                                        let _e2821 = select(3i, 2i, _e2785);
                                        phi_8034_ = 0f;
                                        phi_8031_ = 0i;
                                        loop {
                                            let _e2823 = phi_8034_;
                                            let _e2825 = phi_8031_;
                                            local_41 = _e2823;
                                            if (_e2825 < _e2821) {
                                                phi_8040_ = _e2823;
                                                phi_8037_ = 0i;
                                                loop {
                                                    let _e2828 = phi_8040_;
                                                    let _e2830 = phi_8037_;
                                                    local_51 = _e2828;
                                                    if (_e2830 < _e2821) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e2834 = local_1[_e2830][0u];
                                                        let _e2837 = local_1[_e2825][1u];
                                                        let _e2843 = clamp((_e2754 * ((_e2782 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2834, _e2837))), _e2765.xy, _e2765.zw);
                                                        let _e2846 = local[_e2830][0u];
                                                        let _e2849 = local[_e2825][1u];
                                                        let _e2855 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2843.x, _e2843.y, _e2726).xy, _e2726);
                                                        phi_8040_ = (_e2828 + ((_e2846 * _e2849) * _e2855));
                                                        phi_8037_ = (_e2830 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3149 = local_51;
                                                phi_8034_ = _e3149;
                                                phi_8031_ = (_e2825 + 1i);
                                            }
                                        }
                                        let _e2861 = local_41;
                                        phi_8041_ = (_e2861 * select(0.0069444445f, 0.0625f, _e2785));
                                        break;
                                    }
                                }
                                let _e2864 = phi_8041_;
                                phi_8053_ = _e2864;
                                break;
                            }
                        }
                        let _e2866 = phi_8053_;
                        phi_8121_ = (_e2469 * _e2866);
                    }
                    let _e2869 = phi_8121_;
                    let _e2871 = normalize((_e2448 + _e779));
                    let _e2873 = clamp(dot(_e769, _e2448), 0f, 1f);
                    let _e2875 = clamp(dot(_e769, _e2871), 0f, 1f);
                    let _e2881 = (_e1891 + (_e1928 * pow((1f - clamp(dot(_e779, _e2871), 0f, 1f)), 5f)));
                    let _e2884 = (((_e2875 * _e2875) * _e1933) + 1f);
                    local_49 = (_e2416 + (((((vec3<f32>(1f, 1f, 1f) - _e2881) * _e1889) + ((_e2881 * ((_e1931 / ((3.1415927f * _e2884) * _e2884)) * (0.5f / max(((_e2873 * _e1943) + (_e1923 * sqrt((((_e2873 * _e2873) * _e1940) + _e1931)))), 0.00001f)))) * 3.1415927f)) * _e2873) * _e2869));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3129 = local_49;
                    phi_8123_ = _e3129;
                    phi_8026_ = (_e2418 + bitcast<u32>(1i));
                }
            }
            let _e3159 = local_52;
            phi_8170_ = _e3159;
        }
        let _e2909 = phi_8170_;
        phi_8167_ = _e2909;
    }
    let _e2911 = phi_8167_;
    let _e2914 = global_7.member_1[1u];
    let _e2918 = global_7.member_5;
    let _e2920 = textureSample(global_26, global_4, _e245);
    let _e2923 = global_24;
    let _e2929 = -(length(_e778));
    let _e2932 = global.member_7[3u];
    let _e2938 = global.member_9[3u];
    phi_8212_ = (1f - exp((_e2929 * _e2932)));
    if (_e2938 != 0f) {
        let _e2942 = (_e2938 * (_e777 - _e776).y);
        if (abs(_e2942) < 0.0001f) {
            phi_8209_ = (1f - (0.5f * _e2942));
        } else {
            phi_8209_ = ((1f - exp(min(-(_e2942), 60f))) / _e2942);
        }
        let _e2953 = phi_8209_;
        let _e2957 = global.member_6[1u];
        let _e2960 = global.member_6[3u];
        phi_8212_ = (1f - exp(((_e2929 * (_e2932 * exp(min((-(_e2938) * (_e2957 - _e2960)), 30f)))) * _e2953)));
    }
    let _e2971 = phi_8212_;
    let _e2973 = global.member_7;
    let _e2976 = mix((mix(_e2911, _e1202, vec3(_e2914)) + ((_e2918.xyz * _e2920.xyz) * (vec3<f32>(1f, 1f, 1f) + _e2923.yzw))), _e2973.xyz, vec3(_e2971));
    let _e2979 = global.member_33[3u];
    phi_8213_ = _e2976;
    if (_e2979 > 0.5f) {
        phi_8213_ = (_e2976 / (vec3<f32>(1f, 1f, 1f) + _e2976));
    }
    let _e2984 = phi_8213_;
    global_27 = vec4<f32>(_e2984.x, _e2984.y, _e2984.z, _e265);
    let _e2989 = global_29;
    let _e2990 = global_30;
    switch bitcast<i32>(0u) {
        default: {
            if (_e2990.w <= 0f) {
                phi_8293_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_8293_ = (((_e2990.xy / vec2(_e2990.w)) - (_e2989.xy / vec2(_e2989.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e3004 = phi_8293_;
    global_28 = _e3004;
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
