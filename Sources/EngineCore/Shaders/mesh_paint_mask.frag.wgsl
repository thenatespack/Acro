// Generated from mesh_paint_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 4b017794001962cc
// glsl-fnv1a64: 72efd934e73050e1

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
    var phi_7707_: vec3<f32>;
    var phi_7705_: f32;
    var local_22: vec3<f32>;
    var phi_7868_: vec2<f32>;
    var phi_7835_: f32;
    var phi_7804_: vec3<f32>;
    var phi_7708_: vec2<f32>;
    var phi_7709_: vec3<f32>;
    var phi_7718_: vec3<f32>;
    var phi_7717_: vec3<f32>;
    var phi_7714_: f32;
    var phi_2353_: bool;
    var phi_7904_: vec3<f32>;
    var phi_7719_: i32;
    var phi_3965_: bool;
    var local_23: i32;
    var local_24: i32;
    var local_25: i32;
    var phi_4078_: bool;
    var phi_4085_: bool;
    var phi_4092_: bool;
    var local_26: i32;
    var local_27: i32;
    var local_28: i32;
    var phi_7724_: f32;
    var phi_7721_: i32;
    var phi_7730_: f32;
    var phi_7727_: i32;
    var local_29: f32;
    var phi_7731_: f32;
    var phi_7732_: f32;
    var local_30: i32;
    var local_31: i32;
    var local_32: i32;
    var phi_4365_: bool;
    var phi_4372_: bool;
    var phi_4379_: bool;
    var phi_7744_: f32;
    var phi_7741_: i32;
    var phi_7750_: f32;
    var phi_7747_: i32;
    var local_33: f32;
    var phi_7751_: f32;
    var phi_7752_: f32;
    var phi_7773_: f32;
    var phi_7770_: vec3<f32>;
    var phi_7772_: f32;
    var phi_7769_: vec3<f32>;
    var phi_7775_: vec3<f32>;
    var phi_7774_: f32;
    var phi_7938_: f32;
    var phi_7898_: vec3<f32>;
    var phi_7827_: f32;
    var phi_8028_: f32;
    var phi_8177_: vec3<f32>;
    var phi_8176_: i32;
    var local_34: vec3<f32>;
    var phi_8178_: vec3<f32>;
    var phi_8188_: vec3<f32>;
    var phi_8185_: u32;
    var phi_5020_: bool;
    var phi_5027_: bool;
    var phi_5034_: bool;
    var phi_5041_: bool;
    var phi_8331_: f32;
    var phi_8328_: i32;
    var phi_8337_: f32;
    var phi_8334_: i32;
    var local_35: f32;
    var phi_8338_: f32;
    var phi_5111_: bool;
    var phi_8316_: i32;
    var phi_8315_: i32;
    var phi_8313_: f32;
    var phi_8320_: f32;
    var phi_8317_: i32;
    var phi_8326_: f32;
    var phi_8323_: i32;
    var local_36: f32;
    var phi_8327_: f32;
    var phi_8339_: f32;
    var phi_8393_: vec3<f32>;
    var phi_8187_: vec3<f32>;
    var phi_7899_: f32;
    var phi_7894_: f32;
    var phi_7928_: vec3<f32>;
    var phi_7927_: vec3<f32>;
    var phi_7932_: f32;
    var phi_7931_: f32;
    var phi_8042_: vec3<f32>;
    var phi_7950_: vec3<f32>;
    var phi_7949_: i32;
    var local_37: vec3<f32>;
    var phi_7953_: i32;
    var phi_7954_: i32;
    var phi_7960_: i32;
    var phi_7961_: i32;
    var phi_8004_: vec3<f32>;
    var phi_7992_: vec2<f32>;
    var phi_7968_: vec3<f32>;
    var phi_2835_: bool;
    var phi_7988_: f32;
    var phi_7987_: vec3<f32>;
    var phi_7986_: i32;
    var local_38: vec3<f32>;
    var local_39: f32;
    var phi_7989_: vec3<f32>;
    var phi_8013_: vec3<f32>;
    var phi_8142_: vec3<f32>;
    var phi_8045_: u32;
    var phi_6702_: bool;
    var phi_6709_: bool;
    var phi_6716_: bool;
    var phi_6723_: bool;
    var phi_8064_: f32;
    var phi_8061_: i32;
    var phi_8070_: f32;
    var phi_8067_: i32;
    var local_40: f32;
    var phi_8071_: f32;
    var phi_6793_: bool;
    var phi_8049_: i32;
    var phi_8048_: i32;
    var phi_8046_: f32;
    var phi_8053_: f32;
    var phi_8050_: i32;
    var phi_8059_: f32;
    var phi_8056_: i32;
    var local_41: f32;
    var phi_8060_: f32;
    var phi_8072_: f32;
    var phi_8140_: vec3<f32>;
    var phi_8189_: vec3<f32>;
    var phi_8186_: vec3<f32>;
    var phi_8228_: f32;
    var phi_8231_: f32;
    var phi_8232_: vec3<f32>;
    var phi_8312_: vec2<f32>;
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
    let _e259 = global_7.member[3u];
    let _e264 = global_7.member_6[0u];
    if ((_e259 * _e248.w) < _e264) {
        discard;
    }
    let _e267 = global_21[3u];
    let _e268 = global_22;
    let _e270 = (((_e250 * _e252.xyz) * _e255) * _e268.xyz);
    let _e272 = global_22[3u];
    let _e276 = global_7.member_1[0u];
    phi_7707_ = _e270;
    if (_e276 > 0.5f) {
        let _e278 = global_12;
        let _e281 = floor((_e278.xz * vec2<f32>(0.5f, 0.5f)));
        let _e285 = abs((_e281.x + _e281.y));
        phi_7707_ = (_e270 * select(0.75f, 1f, ((_e285 - (floor((_e285 / 2f)) * 2f)) < 0.5f)));
    }
    let _e294 = phi_7707_;
    let _e297 = global_7.member_3[3u];
    phi_7868_ = vec2<f32>(0f, 0f);
    phi_7835_ = 0f;
    phi_7804_ = _e294;
    if (_e297 > 0.5f) {
        switch bitcast<i32>(0u) {
            default: {
                let _e302 = global_7.member_2[3u];
                let _e304 = vec4<f32>(_e302, _e297, 0f, 0f).xyy;
                let _e306 = floor((_e304 * vec3<f32>(0.000015258789f, 0.000015258789f, 0.000015258789f)));
                let _e308 = (_e304 - (_e306 * 65536f));
                let _e310 = floor((_e308 * vec3<f32>(0.00390625f, 0.00390625f, 0.00390625f)));
                let _e312 = (_e308 - (_e310 * 256f));
                let _e324 = (_e306.y - 128f);
                let _e331 = (floor((_e324 * 0.03125f)) * 0.33333334f);
                let _e335 = global_8;
                let _e336 = normalize(_e335);
                let _e337 = global_9;
                let _e338 = _e337.xyz;
                let _e339 = dot(_e336, _e338);
                let _e345 = ((_e339 / max(length((_e338 - (_e336 * _e339))), 0.000001f)) * 25.5f);
                local_22 = ((vec3<f32>(_e312.x, _e310.x, _e306.x) * vec3<f32>(0.003921569f, 0.003921569f, 0.003921569f)) * 2f);
                local_42 = (vec2<f32>(_e312.y, _e310.y) * vec2<f32>(0.003921569f, 0.003921569f));
                if ((-24f + _e345) < -2f) {
                    phi_7705_ = 0f;
                    break;
                }
                let _e348 = global_10;
                let _e349 = (_e348 * (4f * exp2(((_e324 - (floor((_e324 / 32f)) * 32f)) * 0.33333334f))));
                let _e350 = floor(_e349);
                let _e351 = (_e349 - _e350);
                let _e355 = ((_e351 * _e351) * (vec3<f32>(3f, 3f, 3f) - (_e351 * 2f)));
                let _e357 = bitcast<vec3<u32>>(vec3<i32>(_e350));
                let _e366 = ((((_e357.x * 1597334677u) ^ (_e357.y * 3812015801u)) ^ (_e357.z * 2798796415u)) * 1597334677u);
                let _e375 = bitcast<vec3<u32>>(vec3<i32>((_e350 + vec3<f32>(1f, 0f, 0f))));
                let _e384 = ((((_e375.x * 1597334677u) ^ (_e375.y * 3812015801u)) ^ (_e375.z * 2798796415u)) * 1597334677u);
                let _e395 = bitcast<vec3<u32>>(vec3<i32>((_e350 + vec3<f32>(0f, 1f, 0f))));
                let _e404 = ((((_e395.x * 1597334677u) ^ (_e395.y * 3812015801u)) ^ (_e395.z * 2798796415u)) * 1597334677u);
                let _e413 = bitcast<vec3<u32>>(vec3<i32>((_e350 + vec3<f32>(1f, 1f, 0f))));
                let _e422 = ((((_e413.x * 1597334677u) ^ (_e413.y * 3812015801u)) ^ (_e413.z * 2798796415u)) * 1597334677u);
                let _e434 = bitcast<vec3<u32>>(vec3<i32>((_e350 + vec3<f32>(0f, 0f, 1f))));
                let _e443 = ((((_e434.x * 1597334677u) ^ (_e434.y * 3812015801u)) ^ (_e434.z * 2798796415u)) * 1597334677u);
                let _e452 = bitcast<vec3<u32>>(vec3<i32>((_e350 + vec3<f32>(1f, 0f, 1f))));
                let _e461 = ((((_e452.x * 1597334677u) ^ (_e452.y * 3812015801u)) ^ (_e452.z * 2798796415u)) * 1597334677u);
                let _e471 = bitcast<vec3<u32>>(vec3<i32>((_e350 + vec3<f32>(0f, 1f, 1f))));
                let _e480 = ((((_e471.x * 1597334677u) ^ (_e471.y * 3812015801u)) ^ (_e471.z * 2798796415u)) * 1597334677u);
                let _e489 = bitcast<vec3<u32>>(vec3<i32>((_e350 + vec3<f32>(1f, 1f, 1f))));
                let _e498 = ((((_e489.x * 1597334677u) ^ (_e489.y * 3812015801u)) ^ (_e489.z * 2798796415u)) * 1597334677u);
                let _e511 = ((_e349 * 2.7f) + vec3<f32>(17.3f, 5.1f, 9.7f));
                let _e512 = floor(_e511);
                let _e513 = (_e511 - _e512);
                let _e517 = ((_e513 * _e513) * (vec3<f32>(3f, 3f, 3f) - (_e513 * 2f)));
                let _e519 = bitcast<vec3<u32>>(vec3<i32>(_e512));
                let _e528 = ((((_e519.x * 1597334677u) ^ (_e519.y * 3812015801u)) ^ (_e519.z * 2798796415u)) * 1597334677u);
                let _e537 = bitcast<vec3<u32>>(vec3<i32>((_e512 + vec3<f32>(1f, 0f, 0f))));
                let _e546 = ((((_e537.x * 1597334677u) ^ (_e537.y * 3812015801u)) ^ (_e537.z * 2798796415u)) * 1597334677u);
                let _e557 = bitcast<vec3<u32>>(vec3<i32>((_e512 + vec3<f32>(0f, 1f, 0f))));
                let _e566 = ((((_e557.x * 1597334677u) ^ (_e557.y * 3812015801u)) ^ (_e557.z * 2798796415u)) * 1597334677u);
                let _e575 = bitcast<vec3<u32>>(vec3<i32>((_e512 + vec3<f32>(1f, 1f, 0f))));
                let _e584 = ((((_e575.x * 1597334677u) ^ (_e575.y * 3812015801u)) ^ (_e575.z * 2798796415u)) * 1597334677u);
                let _e596 = bitcast<vec3<u32>>(vec3<i32>((_e512 + vec3<f32>(0f, 0f, 1f))));
                let _e605 = ((((_e596.x * 1597334677u) ^ (_e596.y * 3812015801u)) ^ (_e596.z * 2798796415u)) * 1597334677u);
                let _e614 = bitcast<vec3<u32>>(vec3<i32>((_e512 + vec3<f32>(1f, 0f, 1f))));
                let _e623 = ((((_e614.x * 1597334677u) ^ (_e614.y * 3812015801u)) ^ (_e614.z * 2798796415u)) * 1597334677u);
                let _e633 = bitcast<vec3<u32>>(vec3<i32>((_e512 + vec3<f32>(0f, 1f, 1f))));
                let _e642 = ((((_e633.x * 1597334677u) ^ (_e633.y * 3812015801u)) ^ (_e633.z * 2798796415u)) * 1597334677u);
                let _e651 = bitcast<vec3<u32>>(vec3<i32>((_e512 + vec3<f32>(1f, 1f, 1f))));
                let _e660 = ((((_e651.x * 1597334677u) ^ (_e651.y * 3812015801u)) ^ (_e651.z * 2798796415u)) * 1597334677u);
                let _e673 = mix(0.45f, 0.05f, _e331);
                phi_7705_ = smoothstep(-(_e673), _e673, ((_e345 + -24.45f) + ((((mix(mix(mix((f32(((_e366 ^ (_e366 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e384 ^ (_e384 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e355.x), mix((f32(((_e404 ^ (_e404 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e422 ^ (_e422 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e355.x), _e355.y), mix(mix((f32(((_e443 ^ (_e443 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e461 ^ (_e461 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e355.x), mix((f32(((_e480 ^ (_e480 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e498 ^ (_e498 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e355.x), _e355.y), _e355.z) * 0.65f) + (mix(mix(mix((f32(((_e528 ^ (_e528 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e546 ^ (_e546 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e517.x), mix((f32(((_e566 ^ (_e566 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e584 ^ (_e584 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e517.x), _e517.y), mix(mix((f32(((_e605 ^ (_e605 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e623 ^ (_e623 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e517.x), mix((f32(((_e642 ^ (_e642 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), (f32(((_e660 ^ (_e660 >> bitcast<u32>(16i))) & 65535u)) * 0.000015259022f), _e517.x), _e517.y), _e517.z) * 0.35f)) - 0.5f) * mix(0.8f, 2.2f, _e331))));
                break;
            }
        }
        let _e682 = phi_7705_;
        let _e684 = local_22;
        let _e3027 = local_42;
        phi_7868_ = _e3027;
        phi_7835_ = _e682;
        phi_7804_ = mix(_e294, ((_e250 * _e684) * mix(vec3<f32>(1f, 1f, 1f), (_e255 * 2f), vec3<f32>(0.5f, 0.5f, 0.5f))), vec3(_e682));
    }
    let _e692 = phi_7868_;
    let _e694 = phi_7835_;
    let _e696 = phi_7804_;
    let _e697 = global_8;
    let _e698 = normalize(_e697);
    let _e701 = global_7.member_6[1u];
    phi_7717_ = _e698;
    if (_e701 > 0.5f) {
        let _e703 = global_9;
        let _e704 = _e703.xyz;
        let _e707 = (_e704 - (_e698 * dot(_e698, _e704)));
        phi_7718_ = _e698;
        if (dot(_e707, _e707) > 0.000000000001f) {
            let _e710 = normalize(_e707);
            let _e713 = global_9[3u];
            let _e717 = textureSample(global_23, global_4, _e247);
            let _e720 = global_7.member_6[2u];
            if (_e720 > 0.5f) {
                if (_e720 > 1.5f) {
                    phi_7708_ = _e717.xw;
                } else {
                    phi_7708_ = _e717.xy;
                }
                let _e726 = phi_7708_;
                let _e728 = ((_e726 * 2f) - vec2<f32>(1f, 1f));
                phi_7709_ = vec3<f32>(_e728.x, _e728.y, sqrt(clamp((1f - dot(_e728, _e728)), 0f, 1f)));
            } else {
                phi_7709_ = ((_e717.xyz * 2f) - vec3<f32>(1f, 1f, 1f));
            }
            let _e740 = phi_7709_;
            let _e743 = global_7.member_4[2u];
            let _e745 = (_e740.xy * _e743);
            phi_7718_ = normalize((((_e710 * _e745.x) + ((cross(_e698, _e710) * select(1f, -1f, (_e713 < 0f))) * _e745.y)) + (_e698 * _e740.z)));
        }
        let _e756 = phi_7718_;
        phi_7717_ = _e756;
    }
    let _e758 = phi_7717_;
    let _e761 = global_7.member_5[3u];
    let _e762 = (_e761 > 0.5f);
    if _e762 {
        let _e765 = global_7.member_1[2u];
        phi_7714_ = clamp(_e765, 0f, 1f);
    } else {
        phi_7714_ = 0f;
    }
    let _e768 = phi_7714_;
    phi_2353_ = _e762;
    if _e762 {
        let _e769 = global_24;
        phi_2353_ = !(_e769);
    }
    let _e772 = phi_2353_;
    phi_7904_ = _e758;
    if (_e772 && (_e768 <= 0f)) {
        phi_7904_ = -(_e758);
    }
    let _e777 = phi_7904_;
    let _e779 = global.member_4;
    let _e781 = normalize(_e779.xyz);
    let _e783 = global.member_6;
    let _e784 = _e783.xyz;
    let _e785 = global_12;
    let _e786 = (_e784 - _e785);
    let _e787 = normalize(_e786);
    let _e789 = normalize((_e781 + _e787));
    let _e790 = global_24;
    let _e792 = (_e698 * select(-1f, 1f, _e790));
    let _e794 = global_25[0u];
    let _e795 = (_e794 > 0.5f);
    let _e798 = global.member_5[3u];
    phi_7938_ = 1f;
    phi_7898_ = _e696;
    if ((_e798 > 0.5f) && _e795) {
        switch bitcast<i32>(0u) {
            default: {
                let _e804 = global.member_21[0u];
                let _e805 = i32(_e804);
                let _e807 = global.member_20;
                let _e812 = global.member_20[3u];
                let _e813 = (dot(_e807.xyz, _e785) + _e812);
                phi_7719_ = 0i;
                loop {
                    let _e815 = phi_7719_;
                    local_23 = _e815;
                    local_24 = _e815;
                    local_25 = _e815;
                    local_26 = _e815;
                    local_27 = _e815;
                    local_28 = _e815;
                    local_30 = _e815;
                    local_31 = _e815;
                    local_32 = _e815;
                    let _e817 = (_e815 < (_e805 - 1i));
                    phi_3965_ = _e817;
                    if _e817 {
                        let _e820 = global.member_16[_e815];
                        phi_3965_ = (_e813 > _e820);
                    }
                    let _e823 = phi_3965_;
                    if _e823 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_7719_ = (_e815 + 1i);
                    }
                }
                let _e827 = local_23;
                let _e829 = global.member_16[_e827];
                if (_e813 > _e829) {
                    phi_7775_ = vec3<f32>(1f, 1f, 1f);
                    phi_7774_ = 1f;
                    break;
                }
                let _e833 = local_24;
                let _e835 = global.member_18[_e833];
                let _e837 = (_e785 + (_e792 * _e835));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e841 = local_25;
                        let _e843 = global.member_14[_e841];
                        let _e848 = (_e843 * vec4<f32>(_e837.x, _e837.y, _e837.z, 1f));
                        let _e850 = (_e848.x < 0f);
                        phi_4078_ = _e850;
                        if !(_e850) {
                            phi_4078_ = (_e848.x > 1f);
                        }
                        let _e854 = phi_4078_;
                        phi_4085_ = _e854;
                        if !(_e854) {
                            phi_4085_ = (_e848.y < 0f);
                        }
                        let _e859 = phi_4085_;
                        phi_4092_ = _e859;
                        if !(_e859) {
                            phi_4092_ = (_e848.y > 1f);
                        }
                        let _e864 = phi_4092_;
                        if _e864 {
                            phi_7732_ = 1f;
                            break;
                        }
                        let _e866 = local_26;
                        let _e870 = local_27;
                        let _e876 = global.member_23;
                        let _e877 = _e876.xy;
                        let _e878 = (vec2<f32>(f32((_e866 & 1i)), f32((_e870 >> bitcast<u32>(1i)))) * _e877);
                        let _e883 = local_28;
                        let _e885 = global.member_19[_e883];
                        let _e886 = (min(_e848.z, 1f) - _e885);
                        let _e889 = global.member_22;
                        let _e890 = _e889.xy;
                        let _e891 = (_e890 * 0.5f);
                        let _e893 = (_e878 + (_e848.xy * _e877));
                        let _e894 = (_e878 + _e891);
                        let _e896 = ((_e878 + _e877) - _e891);
                        let _e901 = vec4<f32>(_e894.x, _e894.y, _e896.x, _e896.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e905 = global.member_22[2u];
                                let _e906 = i32(_e905);
                                if (_e906 <= 0i) {
                                    let _e910 = clamp(_e893, _e901.xy, _e901.zw);
                                    let _e915 = textureSampleCompare(global_2, global_1, vec3<f32>(_e910.x, _e910.y, _e886).xy, _e886);
                                    phi_7731_ = _e915;
                                    break;
                                }
                                let _e917 = ((_e893 / _e890) + vec2<f32>(0.5f, 0.5f));
                                let _e918 = floor(_e917);
                                let _e919 = (_e917 - _e918);
                                let _e921 = (_e906 == 1i);
                                if _e921 {
                                    let _e922 = (_e919 * 2f);
                                    local_18[0i] = (vec2<f32>(3f, 3f) - _e922);
                                    local_18[1i] = (vec2<f32>(1f, 1f) + _e922);
                                    let _e928 = local_18[0i];
                                    local_19[0i] = (((vec2<f32>(2f, 2f) - _e919) / _e928) - vec2<f32>(1f, 1f));
                                    let _e932 = local_18[1i];
                                    local_19[1i] = ((_e919 / _e932) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e936 = (_e919 * 3f);
                                    local_18[0i] = (vec2<f32>(4f, 4f) - _e936);
                                    local_18[1i] = vec2<f32>(7f, 7f);
                                    local_18[2i] = (vec2<f32>(1f, 1f) + _e936);
                                    let _e944 = local_18[0i];
                                    local_19[0i] = (((vec2<f32>(3f, 3f) - (_e919 * 2f)) / _e944) - vec2<f32>(2f, 2f));
                                    let _e949 = local_18[1i];
                                    local_19[1i] = ((vec2<f32>(3f, 3f) + _e919) / _e949);
                                    let _e952 = local_18[2i];
                                    local_19[2i] = ((_e919 / _e952) + vec2<f32>(2f, 2f));
                                }
                                let _e957 = select(3i, 2i, _e921);
                                phi_7724_ = 0f;
                                phi_7721_ = 0i;
                                loop {
                                    let _e959 = phi_7724_;
                                    let _e961 = phi_7721_;
                                    local_29 = _e959;
                                    if (_e961 < _e957) {
                                        phi_7730_ = _e959;
                                        phi_7727_ = 0i;
                                        loop {
                                            let _e964 = phi_7730_;
                                            let _e966 = phi_7727_;
                                            local_43 = _e964;
                                            if (_e966 < _e957) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e970 = local_19[_e966][0u];
                                                let _e973 = local_19[_e961][1u];
                                                let _e979 = clamp((_e890 * ((_e918 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e970, _e973))), _e901.xy, _e901.zw);
                                                let _e982 = local_18[_e966][0u];
                                                let _e985 = local_18[_e961][1u];
                                                let _e991 = textureSampleCompare(global_2, global_1, vec3<f32>(_e979.x, _e979.y, _e886).xy, _e886);
                                                phi_7730_ = (_e964 + ((_e982 * _e985) * _e991));
                                                phi_7727_ = (_e966 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e3050 = local_43;
                                        phi_7724_ = _e3050;
                                        phi_7721_ = (_e961 + 1i);
                                    }
                                }
                                let _e997 = local_29;
                                phi_7731_ = (_e997 * select(0.0069444445f, 0.0625f, _e921));
                                break;
                            }
                        }
                        let _e1000 = phi_7731_;
                        phi_7732_ = _e1000;
                        break;
                    }
                }
                let _e1002 = phi_7732_;
                local_20 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e1004 = local_30;
                let _e1006 = local_20[_e1004];
                let _e1009 = local_31;
                let _e1011 = global.member_17[_e1009];
                phi_7772_ = _e1002;
                phi_7769_ = _e1006;
                if (_e813 > _e1011) {
                    let _e1015 = ((_e813 - _e1011) / (_e829 - _e1011));
                    let _e1017 = local_32;
                    let _e1018 = (_e1017 + 1i);
                    if (_e1018 < _e805) {
                        let _e1022 = global.member_18[_e1018];
                        let _e1024 = (_e785 + (_e792 * _e1022));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1028 = global.member_14[_e1018];
                                let _e1033 = (_e1028 * vec4<f32>(_e1024.x, _e1024.y, _e1024.z, 1f));
                                let _e1035 = (_e1033.x < 0f);
                                phi_4365_ = _e1035;
                                if !(_e1035) {
                                    phi_4365_ = (_e1033.x > 1f);
                                }
                                let _e1039 = phi_4365_;
                                phi_4372_ = _e1039;
                                if !(_e1039) {
                                    phi_4372_ = (_e1033.y < 0f);
                                }
                                let _e1044 = phi_4372_;
                                phi_4379_ = _e1044;
                                if !(_e1044) {
                                    phi_4379_ = (_e1033.y > 1f);
                                }
                                let _e1049 = phi_4379_;
                                if _e1049 {
                                    phi_7752_ = 1f;
                                    break;
                                }
                                let _e1057 = global.member_23;
                                let _e1058 = _e1057.xy;
                                let _e1059 = (vec2<f32>(f32((_e1018 & 1i)), f32((_e1018 >> bitcast<u32>(1i)))) * _e1058);
                                let _e1064 = global.member_19[_e1018];
                                let _e1065 = (min(_e1033.z, 1f) - _e1064);
                                let _e1068 = global.member_22;
                                let _e1069 = _e1068.xy;
                                let _e1070 = (_e1069 * 0.5f);
                                let _e1072 = (_e1059 + (_e1033.xy * _e1058));
                                let _e1073 = (_e1059 + _e1070);
                                let _e1075 = ((_e1059 + _e1058) - _e1070);
                                let _e1080 = vec4<f32>(_e1073.x, _e1073.y, _e1075.x, _e1075.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1084 = global.member_22[2u];
                                        let _e1085 = i32(_e1084);
                                        if (_e1085 <= 0i) {
                                            let _e1089 = clamp(_e1072, _e1080.xy, _e1080.zw);
                                            let _e1094 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1089.x, _e1089.y, _e1065).xy, _e1065);
                                            phi_7751_ = _e1094;
                                            break;
                                        }
                                        let _e1096 = ((_e1072 / _e1069) + vec2<f32>(0.5f, 0.5f));
                                        let _e1097 = floor(_e1096);
                                        let _e1098 = (_e1096 - _e1097);
                                        let _e1100 = (_e1085 == 1i);
                                        if _e1100 {
                                            let _e1101 = (_e1098 * 2f);
                                            local_16[0i] = (vec2<f32>(3f, 3f) - _e1101);
                                            local_16[1i] = (vec2<f32>(1f, 1f) + _e1101);
                                            let _e1107 = local_16[0i];
                                            local_17[0i] = (((vec2<f32>(2f, 2f) - _e1098) / _e1107) - vec2<f32>(1f, 1f));
                                            let _e1111 = local_16[1i];
                                            local_17[1i] = ((_e1098 / _e1111) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1115 = (_e1098 * 3f);
                                            local_16[0i] = (vec2<f32>(4f, 4f) - _e1115);
                                            local_16[1i] = vec2<f32>(7f, 7f);
                                            local_16[2i] = (vec2<f32>(1f, 1f) + _e1115);
                                            let _e1123 = local_16[0i];
                                            local_17[0i] = (((vec2<f32>(3f, 3f) - (_e1098 * 2f)) / _e1123) - vec2<f32>(2f, 2f));
                                            let _e1128 = local_16[1i];
                                            local_17[1i] = ((vec2<f32>(3f, 3f) + _e1098) / _e1128);
                                            let _e1131 = local_16[2i];
                                            local_17[2i] = ((_e1098 / _e1131) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1136 = select(3i, 2i, _e1100);
                                        phi_7744_ = 0f;
                                        phi_7741_ = 0i;
                                        loop {
                                            let _e1138 = phi_7744_;
                                            let _e1140 = phi_7741_;
                                            local_33 = _e1138;
                                            if (_e1140 < _e1136) {
                                                phi_7750_ = _e1138;
                                                phi_7747_ = 0i;
                                                loop {
                                                    let _e1143 = phi_7750_;
                                                    let _e1145 = phi_7747_;
                                                    local_44 = _e1143;
                                                    if (_e1145 < _e1136) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1149 = local_17[_e1145][0u];
                                                        let _e1152 = local_17[_e1140][1u];
                                                        let _e1158 = clamp((_e1069 * ((_e1097 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1149, _e1152))), _e1080.xy, _e1080.zw);
                                                        let _e1161 = local_16[_e1145][0u];
                                                        let _e1164 = local_16[_e1140][1u];
                                                        let _e1170 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1158.x, _e1158.y, _e1065).xy, _e1065);
                                                        phi_7750_ = (_e1143 + ((_e1161 * _e1164) * _e1170));
                                                        phi_7747_ = (_e1145 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3065 = local_44;
                                                phi_7744_ = _e3065;
                                                phi_7741_ = (_e1140 + 1i);
                                            }
                                        }
                                        let _e1176 = local_33;
                                        phi_7751_ = (_e1176 * select(0.0069444445f, 0.0625f, _e1100));
                                        break;
                                    }
                                }
                                let _e1179 = phi_7751_;
                                phi_7752_ = _e1179;
                                break;
                            }
                        }
                        let _e1181 = phi_7752_;
                        local_21 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1184 = local_21[_e1018];
                        phi_7773_ = mix(_e1002, _e1181, _e1015);
                        phi_7770_ = mix(_e1006, _e1184, vec3(_e1015));
                    } else {
                        phi_7773_ = mix(_e1002, 1f, _e1015);
                        phi_7770_ = _e1006;
                    }
                    let _e1189 = phi_7773_;
                    let _e1191 = phi_7770_;
                    phi_7772_ = _e1189;
                    phi_7769_ = _e1191;
                }
                let _e1193 = phi_7772_;
                let _e1195 = phi_7769_;
                let _e1198 = global.member_22[3u];
                phi_7775_ = select(vec3<f32>(1f, 1f, 1f), _e1195, vec3((_e1198 > 0.5f)));
                phi_7774_ = _e1193;
                break;
            }
        }
        let _e1203 = phi_7775_;
        let _e1205 = phi_7774_;
        phi_7938_ = _e1205;
        phi_7898_ = (_e696 * _e1203);
    }
    let _e1208 = phi_7938_;
    let _e1210 = phi_7898_;
    let _e1212 = global.member_5;
    let _e1216 = global.member_4[3u];
    let _e1217 = (_e1212.xyz * _e1216);
    let _e1220 = global_7.member_6[3u];
    let _e1221 = (_e1220 > 0.5f);
    if _e1221 {
        phi_7827_ = 1f;
    } else {
        let _e1224 = global_7.member_4[3u];
        let _e1225 = textureSample(global_18, global_4, _e247);
        phi_7827_ = (1f + (_e1224 * (_e1225.x - 1f)));
    }
    let _e1231 = phi_7827_;
    let _e1233 = global_9[3u];
    let _e1234 = abs(_e1233);
    phi_8028_ = _e1231;
    if (_e1234 > 0f) {
        phi_8028_ = (_e1231 * min(_e1234, 1f));
    }
    let _e1239 = phi_8028_;
    if !(_e762) {
        let _e1241 = dot(_e777, _e781);
        let _e1248 = global_7.member_1[3u];
        let _e1252 = global_7.member_1[2u];
        let _e1259 = global.member_29[0u];
        if (_e1259 > 0.5f) {
            let _e1262 = global.member_29;
            let _e1269 = ((_e1262.z * _e777.x) - (_e1262.w * _e777.z));
            let _e1273 = ((_e1262.w * _e777.x) + (_e1262.z * _e777.z));
            let _e1277 = (1.092548f * _e1269);
            local_15 = array<f32, 9>(0.282095f, (0.488603f * _e777.y), (0.488603f * _e1273), (0.488603f * _e1269), (_e1277 * _e777.y), ((1.092548f * _e777.y) * _e1273), (0.315392f * (((3f * _e1273) * _e1273) - 1f)), (_e1277 * _e1273), (0.546274f * ((_e1269 * _e1269) - (_e777.y * _e777.y))));
            phi_8177_ = vec3<f32>(0f, 0f, 0f);
            phi_8176_ = 0i;
            loop {
                let _e1292 = phi_8177_;
                let _e1294 = phi_8176_;
                local_34 = _e1292;
                if (_e1294 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1298 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e1294, 0i)), 0i);
                    let _e1301 = local_15[_e1294];
                    phi_8177_ = (_e1292 + (_e1298.xyz * _e1301));
                    phi_8176_ = (_e1294 + 1i);
                }
            }
            let _e1306 = local_34;
            let _e1310 = global.member_29[1u];
            phi_8178_ = (max(_e1306, vec3<f32>(0f, 0f, 0f)) * _e1310);
        } else {
            let _e1313 = global.member_9;
            let _e1316 = global.member_8;
            let _e1325 = global.member_8[3u];
            phi_8178_ = (mix(_e1313.xyz, _e1316.xyz, vec3(((_e777.y * 0.5f) + 0.5f))) * _e1325);
        }
        let _e1328 = phi_8178_;
        let _e1334 = ((_e1210 * ((_e1328 * _e1239) + ((_e1217 * max(_e1241, 0f)) * _e1208))) + ((_e1217 * ((pow(max(dot(_e777, _e789), 0f), _e1248) * _e1252) * step(0f, _e1241))) * _e1208));
        let _e1337 = global.member_13[3u];
        phi_8187_ = _e1334;
        if (_e1337 > 0.5f) {
            let _e1340 = global.member_11;
            let _e1345 = global.member_11[3u];
            let _e1347 = global_15;
            let _e1350 = global.member_12;
            let _e1355 = global.member_13;
            let _e1358 = clamp(floor((_e1347.xy * _e1350.xy)), vec2<f32>(0f, 0f), (_e1355.xy - vec2<f32>(1f, 1f)));
            let _e1363 = global.member_12[2u];
            let _e1367 = global.member_12[3u];
            let _e1372 = global.member_13[2u];
            let _e1377 = global.member_13[1u];
            let _e1383 = global.member_13[0u];
            let _e1387 = u32(((((clamp(floor(((log2(max((dot(_e1340.xyz, _e785) + _e1345), 0.000001f)) * _e1363) + _e1367)), 0f, (_e1372 - 1f)) * _e1377) + _e1358.y) * _e1383) + _e1358.x));
            let _e1394 = global_16.member[(_e1387 >> bitcast<u32>(2i))][(_e1387 & 3u)];
            let _e1395 = (_e1394 & 65535u);
            phi_8188_ = _e1334;
            phi_8185_ = _e1395;
            loop {
                let _e1399 = phi_8188_;
                let _e1401 = phi_8185_;
                local_48 = _e1399;
                if (_e1401 < (_e1395 + (_e1394 >> bitcast<u32>(16i)))) {
                    let _e1404 = (_e1401 / 3u);
                    let _e1411 = global_17.member[(_e1404 >> bitcast<u32>(2i))][(_e1404 & 3u)];
                    let _e1417 = ((_e1411 >> bitcast<u32>(((_e1401 - (_e1404 * 3u)) * 10u))) & 1023u);
                    let _e1420 = global_11.member[_e1417];
                    let _e1422 = (_e1420.xyz - _e785);
                    let _e1423 = dot(_e1422, _e1422);
                    let _e1425 = (_e1423 * _e1420.w);
                    let _e1428 = clamp((1f - (_e1425 * _e1425)), 0f, 1f);
                    let _e1431 = (_e1422 * inverseSqrt(max(_e1423, 0.00000001f)));
                    let _e1434 = global_13.member[_e1417];
                    let _e1437 = global_14.member[_e1417];
                    let _e1445 = clamp(((dot(-(_e1431), _e1437.xyz) * _e1434.w) + _e1437.w), 0f, 1f);
                    let _e1452 = (_e1434.xyz * ((((_e1428 * _e1428) * _e1445) * _e1445) / max(_e1423, 0.0001f)));
                    phi_8393_ = _e1452;
                    if _e795 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1456 = global.member_21[2u];
                                let _e1457 = u32(_e1456);
                                if (_e1417 < _e1457) {
                                    let _e1461 = global.member_26[_e1417];
                                    let _e1464 = global.member_15[_e1417];
                                    let _e1473 = (_e1461.z * max((_e1464 * vec4<f32>(_e785.x, _e785.y, _e785.z, 1f)).w, 0f));
                                    let _e1476 = global.member_25[0u];
                                    let _e1482 = global.member_25[1u];
                                    let _e1485 = ((_e785 + (_e792 * (_e1473 * _e1476))) + (_e1431 * (_e1473 * _e1482)));
                                    let _e1490 = (_e1464 * vec4<f32>(_e1485.x, _e1485.y, _e1485.z, 1f));
                                    if (_e1490.w <= 0f) {
                                        phi_8339_ = 1f;
                                        break;
                                    }
                                    let _e1495 = (_e1490.xyz / vec3(_e1490.w));
                                    let _e1497 = (_e1495.x < 0f);
                                    phi_5020_ = _e1497;
                                    if !(_e1497) {
                                        phi_5020_ = (_e1495.x > 1f);
                                    }
                                    let _e1501 = phi_5020_;
                                    phi_5027_ = _e1501;
                                    if !(_e1501) {
                                        phi_5027_ = (_e1495.y < 0f);
                                    }
                                    let _e1506 = phi_5027_;
                                    phi_5034_ = _e1506;
                                    if !(_e1506) {
                                        phi_5034_ = (_e1495.y > 1f);
                                    }
                                    let _e1511 = phi_5034_;
                                    phi_5041_ = _e1511;
                                    if !(_e1511) {
                                        phi_5041_ = (_e1495.z > 1f);
                                    }
                                    let _e1516 = phi_5041_;
                                    if _e1516 {
                                        phi_8339_ = 1f;
                                        break;
                                    }
                                    let _e1519 = _e1461.xy;
                                    let _e1521 = global.member_23;
                                    let _e1522 = _e1521.zw;
                                    let _e1524 = global.member_22;
                                    let _e1525 = _e1524.xy;
                                    let _e1526 = (_e1525 * 0.5f);
                                    let _e1528 = (_e1519 + (_e1495.xy * _e1522));
                                    let _e1529 = (_e1519 + _e1526);
                                    let _e1531 = ((_e1519 + _e1522) - _e1526);
                                    let _e1536 = vec4<f32>(_e1529.x, _e1529.y, _e1531.x, _e1531.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e1540 = global.member_22[2u];
                                            let _e1541 = i32(_e1540);
                                            if (_e1541 <= 0i) {
                                                let _e1545 = clamp(_e1528, _e1536.xy, _e1536.zw);
                                                let _e1550 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1545.x, _e1545.y, _e1495.z).xy, _e1495.z);
                                                phi_8338_ = _e1550;
                                                break;
                                            }
                                            let _e1552 = ((_e1528 / _e1525) + vec2<f32>(0.5f, 0.5f));
                                            let _e1553 = floor(_e1552);
                                            let _e1554 = (_e1552 - _e1553);
                                            let _e1556 = (_e1541 == 1i);
                                            if _e1556 {
                                                let _e1557 = (_e1554 * 2f);
                                                local_11[0i] = (vec2<f32>(3f, 3f) - _e1557);
                                                local_11[1i] = (vec2<f32>(1f, 1f) + _e1557);
                                                let _e1563 = local_11[0i];
                                                local_12[0i] = (((vec2<f32>(2f, 2f) - _e1554) / _e1563) - vec2<f32>(1f, 1f));
                                                let _e1567 = local_11[1i];
                                                local_12[1i] = ((_e1554 / _e1567) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e1571 = (_e1554 * 3f);
                                                local_11[0i] = (vec2<f32>(4f, 4f) - _e1571);
                                                local_11[1i] = vec2<f32>(7f, 7f);
                                                local_11[2i] = (vec2<f32>(1f, 1f) + _e1571);
                                                let _e1579 = local_11[0i];
                                                local_12[0i] = (((vec2<f32>(3f, 3f) - (_e1554 * 2f)) / _e1579) - vec2<f32>(2f, 2f));
                                                let _e1584 = local_11[1i];
                                                local_12[1i] = ((vec2<f32>(3f, 3f) + _e1554) / _e1584);
                                                let _e1587 = local_11[2i];
                                                local_12[2i] = ((_e1554 / _e1587) + vec2<f32>(2f, 2f));
                                            }
                                            let _e1592 = select(3i, 2i, _e1556);
                                            phi_8331_ = 0f;
                                            phi_8328_ = 0i;
                                            loop {
                                                let _e1594 = phi_8331_;
                                                let _e1596 = phi_8328_;
                                                local_35 = _e1594;
                                                if (_e1596 < _e1592) {
                                                    phi_8337_ = _e1594;
                                                    phi_8334_ = 0i;
                                                    loop {
                                                        let _e1599 = phi_8337_;
                                                        let _e1601 = phi_8334_;
                                                        local_46 = _e1599;
                                                        if (_e1601 < _e1592) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e1605 = local_12[_e1601][0u];
                                                            let _e1608 = local_12[_e1596][1u];
                                                            let _e1614 = clamp((_e1525 * ((_e1553 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1605, _e1608))), _e1536.xy, _e1536.zw);
                                                            let _e1617 = local_11[_e1601][0u];
                                                            let _e1620 = local_11[_e1596][1u];
                                                            let _e1626 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1614.x, _e1614.y, _e1495.z).xy, _e1495.z);
                                                            phi_8337_ = (_e1599 + ((_e1617 * _e1620) * _e1626));
                                                            phi_8334_ = (_e1601 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e3096 = local_46;
                                                    phi_8331_ = _e3096;
                                                    phi_8328_ = (_e1596 + 1i);
                                                }
                                            }
                                            let _e1632 = local_35;
                                            phi_8338_ = (_e1632 * select(0.0069444445f, 0.0625f, _e1556));
                                            break;
                                        }
                                    }
                                    let _e1635 = phi_8338_;
                                    phi_8339_ = _e1635;
                                    break;
                                }
                                let _e1636 = (_e1417 - _e1457);
                                let _e1639 = global.member_21[3u];
                                if (_e1636 >= u32(_e1639)) {
                                    phi_8339_ = 1f;
                                    break;
                                }
                                let _e1644 = global.member_27[_e1636];
                                let _e1647 = global.member_28[_e1636];
                                let _e1649 = _e1644.xyz;
                                let _e1652 = (_e1644.w * length((_e785 - _e1649)));
                                let _e1655 = global.member_25[0u];
                                let _e1661 = global.member_25[1u];
                                let _e1665 = (((_e785 + (_e792 * (_e1652 * _e1655))) + (_e1431 * (_e1652 * _e1661))) - _e1649);
                                let _e1666 = abs(_e1665);
                                let _e1669 = (_e1666.x >= _e1666.y);
                                phi_5111_ = _e1669;
                                if _e1669 {
                                    phi_5111_ = (_e1666.x >= _e1666.z);
                                }
                                let _e1673 = phi_5111_;
                                if _e1673 {
                                    phi_8315_ = select(1i, 0i, (_e1665.x > 0f));
                                    phi_8313_ = _e1666.x;
                                } else {
                                    let _e1678 = (_e1666.y >= _e1666.z);
                                    if _e1678 {
                                        phi_8316_ = select(3i, 2i, (_e1665.y > 0f));
                                    } else {
                                        phi_8316_ = select(5i, 4i, (_e1665.z > 0f));
                                    }
                                    let _e1686 = phi_8316_;
                                    phi_8315_ = _e1686;
                                    phi_8313_ = select(_e1666.z, _e1666.y, _e1678);
                                }
                                let _e1689 = phi_8315_;
                                let _e1691 = phi_8313_;
                                if (_e1691 <= 0f) {
                                    phi_8339_ = 1f;
                                    break;
                                }
                                local_13 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e1694 = local_13[_e1689];
                                local_14 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e1697 = local_14[_e1689];
                                let _e1702 = global.member_24[2u];
                                let _e1705 = (vec2<f32>(dot(_e1665, _e1694), dot(_e1665, _e1697)) / vec2((_e1691 * _e1702)));
                                let _e1709 = (_e1647.z + (_e1647.w / _e1691));
                                if (_e1709 > 1f) {
                                    phi_8339_ = 1f;
                                    break;
                                }
                                let _e1724 = global.member_24;
                                let _e1725 = _e1724.xy;
                                let _e1727 = (_e1647.xy + (vec2<f32>(f32((_e1689 - (i32(floor((f32(_e1689) / f32(3i)))) * 3i))), f32((_e1689 / 3i))) * _e1725));
                                let _e1736 = global.member_22;
                                let _e1737 = _e1736.xy;
                                let _e1738 = (_e1737 * 0.5f);
                                let _e1740 = (_e1727 + (vec2<f32>((0.5f + (0.5f * _e1705.x)), (0.5f - (0.5f * _e1705.y))) * _e1725));
                                let _e1741 = (_e1727 + _e1738);
                                let _e1743 = ((_e1727 + _e1725) - _e1738);
                                let _e1748 = vec4<f32>(_e1741.x, _e1741.y, _e1743.x, _e1743.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1752 = global.member_22[2u];
                                        let _e1753 = i32(_e1752);
                                        if (_e1753 <= 0i) {
                                            let _e1757 = clamp(_e1740, _e1748.xy, _e1748.zw);
                                            let _e1762 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1757.x, _e1757.y, _e1709).xy, _e1709);
                                            phi_8327_ = _e1762;
                                            break;
                                        }
                                        let _e1764 = ((_e1740 / _e1737) + vec2<f32>(0.5f, 0.5f));
                                        let _e1765 = floor(_e1764);
                                        let _e1766 = (_e1764 - _e1765);
                                        let _e1768 = (_e1753 == 1i);
                                        if _e1768 {
                                            let _e1769 = (_e1766 * 2f);
                                            local_9[0i] = (vec2<f32>(3f, 3f) - _e1769);
                                            local_9[1i] = (vec2<f32>(1f, 1f) + _e1769);
                                            let _e1775 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(2f, 2f) - _e1766) / _e1775) - vec2<f32>(1f, 1f));
                                            let _e1779 = local_9[1i];
                                            local_10[1i] = ((_e1766 / _e1779) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1783 = (_e1766 * 3f);
                                            local_9[0i] = (vec2<f32>(4f, 4f) - _e1783);
                                            local_9[1i] = vec2<f32>(7f, 7f);
                                            local_9[2i] = (vec2<f32>(1f, 1f) + _e1783);
                                            let _e1791 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(3f, 3f) - (_e1766 * 2f)) / _e1791) - vec2<f32>(2f, 2f));
                                            let _e1796 = local_9[1i];
                                            local_10[1i] = ((vec2<f32>(3f, 3f) + _e1766) / _e1796);
                                            let _e1799 = local_9[2i];
                                            local_10[2i] = ((_e1766 / _e1799) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1804 = select(3i, 2i, _e1768);
                                        phi_8320_ = 0f;
                                        phi_8317_ = 0i;
                                        loop {
                                            let _e1806 = phi_8320_;
                                            let _e1808 = phi_8317_;
                                            local_36 = _e1806;
                                            if (_e1808 < _e1804) {
                                                phi_8326_ = _e1806;
                                                phi_8323_ = 0i;
                                                loop {
                                                    let _e1811 = phi_8326_;
                                                    let _e1813 = phi_8323_;
                                                    local_47 = _e1811;
                                                    if (_e1813 < _e1804) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1817 = local_10[_e1813][0u];
                                                        let _e1820 = local_10[_e1808][1u];
                                                        let _e1826 = clamp((_e1737 * ((_e1765 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1817, _e1820))), _e1748.xy, _e1748.zw);
                                                        let _e1829 = local_9[_e1813][0u];
                                                        let _e1832 = local_9[_e1808][1u];
                                                        let _e1838 = textureSampleCompare(global_2, global_1, vec3<f32>(_e1826.x, _e1826.y, _e1709).xy, _e1709);
                                                        phi_8326_ = (_e1811 + ((_e1829 * _e1832) * _e1838));
                                                        phi_8323_ = (_e1813 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3108 = local_47;
                                                phi_8320_ = _e3108;
                                                phi_8317_ = (_e1808 + 1i);
                                            }
                                        }
                                        let _e1844 = local_36;
                                        phi_8327_ = (_e1844 * select(0.0069444445f, 0.0625f, _e1768));
                                        break;
                                    }
                                }
                                let _e1847 = phi_8327_;
                                phi_8339_ = _e1847;
                                break;
                            }
                        }
                        let _e1849 = phi_8339_;
                        phi_8393_ = (_e1452 * _e1849);
                    }
                    let _e1852 = phi_8393_;
                    let _e1853 = dot(_e777, _e1431);
                    local_45 = (_e1399 + (((_e1210 * max(_e1853, 0f)) * _e1852) + (_e1852 * ((pow(max(dot(_e777, normalize((_e1431 + _e787))), 0f), _e1248) * _e1252) * step(0f, _e1853)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3088 = local_45;
                    phi_8188_ = _e3088;
                    phi_8185_ = (_e1401 + bitcast<u32>(1i));
                }
            }
            let _e3118 = local_48;
            phi_8187_ = _e3118;
        }
        let _e1871 = phi_8187_;
        phi_8186_ = _e1871;
    } else {
        let _e1872 = textureSample(global_26, global_4, _e247);
        let _e1875 = global_7.member_4[0u];
        let _e1879 = global_27[1u];
        let _e1881 = clamp(((_e1875 * _e1872.z) * _e1879), 0f, 1f);
        let _e1884 = global_7.member_4[1u];
        let _e1888 = global_27[0u];
        let _e1890 = clamp(((_e1884 * _e1872.y) * _e1888), 0.045f, 1f);
        phi_7899_ = _e1881;
        phi_7894_ = _e1890;
        if (_e694 > 0f) {
            phi_7899_ = mix(_e1881, _e692.y, _e694);
            phi_7894_ = mix(_e1890, max(_e692.x, 0.045f), _e694);
        }
        let _e1898 = phi_7899_;
        let _e1900 = phi_7894_;
        let _e1901 = (_e1900 * _e1900);
        let _e1903 = (_e1210 * (1f - _e1898));
        let _e1905 = mix(vec3<f32>(0.04f, 0.04f, 0.04f), _e1210, vec3(_e1898));
        let _e1906 = (_e768 > 0f);
        phi_7927_ = _e777;
        if _e1906 {
            let _e1907 = dpdx(_e785);
            let _e1908 = dpdy(_e785);
            let _e1909 = cross(_e1907, _e1908);
            phi_7928_ = _e777;
            if (dot(_e1909, _e1909) > 0.00000000000000000001f) {
                phi_7928_ = normalize(((normalize(_e1909) * select(1f, -1f, (dot(_e1909, _e787) < 0f))) + (_e777 - _e698)));
            }
            let _e1921 = phi_7928_;
            phi_7927_ = _e1921;
        }
        let _e1923 = phi_7927_;
        let _e1925 = max(dot(_e1923, _e787), 0.0001f);
        let _e1928 = dot(_e1923, _e781);
        let _e1929 = clamp(_e1928, 0f, 1f);
        let _e1931 = clamp(dot(_e1923, _e789), 0f, 1f);
        let _e1933 = clamp(dot(_e787, _e789), 0f, 1f);
        phi_7932_ = _e1925;
        phi_7931_ = _e1933;
        if _e1906 {
            phi_7932_ = max(_e1925, 0.5f);
            phi_7931_ = max(_e1933, 0.5f);
        }
        let _e1937 = phi_7932_;
        let _e1939 = phi_7931_;
        let _e1942 = (vec3<f32>(1f, 1f, 1f) - _e1905);
        let _e1944 = (_e1905 + (_e1942 * pow((1f - _e1939), 5f)));
        let _e1945 = (_e1901 * _e1901);
        let _e1947 = (_e1945 - 1f);
        let _e1949 = (((_e1931 * _e1931) * _e1947) + 1f);
        let _e1954 = (1f - _e1945);
        let _e1957 = sqrt((((_e1937 * _e1937) * _e1954) + _e1945));
        let _e1976 = ((((((vec3<f32>(1f, 1f, 1f) - _e1944) * _e1903) * clamp(dot(_e777, _e781), 0f, 1f)) + (((_e1944 * ((_e1945 / ((3.1415927f * _e1949) * _e1949)) * (0.5f / max(((_e1929 * _e1957) + (_e1937 * sqrt((((_e1929 * _e1929) * _e1954) + _e1945)))), 0.00001f)))) * 3.1415927f) * _e1929)) * _e1217) * _e1208);
        phi_8042_ = _e1976;
        if _e1906 {
            phi_8042_ = (_e1976 + (((((_e1903 * _e1217) * _e1208) * _e768) * clamp(-(_e1928), 0f, 1f)) * (0.35f + (0.65f * pow(clamp(dot(-(_e787), _e781), 0f, 1f), 3f)))));
        }
        let _e1992 = phi_8042_;
        let _e1995 = global.member_29[0u];
        if (_e1995 > 0.5f) {
            let _e2001 = textureSample(global_5, global_6, (((vec2<f32>(_e1937, _e1900) * 31f) + vec2<f32>(0.5f, 0.5f)) * vec2<f32>(0.03125f, 0.03125f)));
            let _e2004 = global.member_29;
            let _e2011 = ((_e2004.z * _e777.x) - (_e2004.w * _e777.z));
            let _e2015 = ((_e2004.w * _e777.x) + (_e2004.z * _e777.z));
            let _e2019 = (1.092548f * _e2011);
            local_8 = array<f32, 9>(0.282095f, (0.488603f * _e777.y), (0.488603f * _e2015), (0.488603f * _e2011), (_e2019 * _e777.y), ((1.092548f * _e777.y) * _e2015), (0.315392f * (((3f * _e2015) * _e2015) - 1f)), (_e2019 * _e2015), (0.546274f * ((_e2011 * _e2011) - (_e777.y * _e777.y))));
            phi_7950_ = vec3<f32>(0f, 0f, 0f);
            phi_7949_ = 0i;
            loop {
                let _e2034 = phi_7950_;
                let _e2036 = phi_7949_;
                local_37 = _e2034;
                if (_e2036 < 9i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e2040 = textureLoad(global_3, (vec2<i32>(496i, 256i) + vec2<i32>(_e2036, 0i)), 0i);
                    let _e2043 = local_8[_e2036];
                    phi_7950_ = (_e2034 + (_e2040.xyz * _e2043));
                    phi_7949_ = (_e2036 + 1i);
                }
            }
            let _e2048 = local_37;
            let _e2052 = global.member_29[1u];
            let _e2055 = reflect(-(_e787), _e1923);
            let _e2072 = vec2<f32>(((atan2(((_e2004.z * _e2055.x) - (_e2004.w * _e2055.z)), -(((_e2004.w * _e2055.x) + (_e2004.z * _e2055.z)))) * 0.15915494f) + 0.5f), (acos(clamp(_e2055.y, -1f, 1f)) * 0.31830987f));
            let _e2073 = (_e1900 * 5f);
            let _e2075 = min(i32(_e2073), 4i);
            local_6 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e2077 = local_6[_e2075];
            let _e2081 = ((_e2072 * vec2<f32>(_e2077.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e2082 = floor(_e2081);
            let _e2083 = (_e2081 - _e2082);
            let _e2085 = i32(_e2082.x);
            let _e2087 = i32(_e2082.y);
            phi_7953_ = _e2085;
            if (_e2085 < 0i) {
                phi_7953_ = (_e2085 + _e2077.z);
            }
            let _e2092 = phi_7953_;
            phi_7954_ = _e2092;
            if (_e2092 >= _e2077.z) {
                phi_7954_ = (_e2092 - _e2077.z);
            }
            let _e2097 = phi_7954_;
            let _e2098 = (_e2097 + 1i);
            let _e2100 = select(_e2098, 0i, (_e2098 == _e2077.z));
            let _e2104 = min((_e2087 + 1i), (_e2077.w - 1i));
            let _e2105 = max(_e2087, 0i);
            let _e2106 = _e2077.xy;
            let _e2109 = textureLoad(global_3, (_e2106 + vec2<i32>(_e2097, _e2105)), 0i);
            let _e2113 = textureLoad(global_3, (_e2106 + vec2<i32>(_e2100, _e2105)), 0i);
            let _e2117 = textureLoad(global_3, (_e2106 + vec2<i32>(_e2097, _e2104)), 0i);
            let _e2121 = textureLoad(global_3, (_e2106 + vec2<i32>(_e2100, _e2104)), 0i);
            let _e2124 = vec3(_e2083.x);
            local_7 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
            let _e2132 = local_7[(_e2075 + 1i)];
            let _e2136 = ((_e2072 * vec2<f32>(_e2132.zw)) - vec2<f32>(0.5f, 0.5f));
            let _e2137 = floor(_e2136);
            let _e2138 = (_e2136 - _e2137);
            let _e2140 = i32(_e2137.x);
            let _e2142 = i32(_e2137.y);
            phi_7960_ = _e2140;
            if (_e2140 < 0i) {
                phi_7960_ = (_e2140 + _e2132.z);
            }
            let _e2147 = phi_7960_;
            phi_7961_ = _e2147;
            if (_e2147 >= _e2132.z) {
                phi_7961_ = (_e2147 - _e2132.z);
            }
            let _e2152 = phi_7961_;
            let _e2153 = (_e2152 + 1i);
            let _e2155 = select(_e2153, 0i, (_e2153 == _e2132.z));
            let _e2159 = min((_e2142 + 1i), (_e2132.w - 1i));
            let _e2160 = max(_e2142, 0i);
            let _e2161 = _e2132.xy;
            let _e2164 = textureLoad(global_3, (_e2161 + vec2<i32>(_e2152, _e2160)), 0i);
            let _e2168 = textureLoad(global_3, (_e2161 + vec2<i32>(_e2155, _e2160)), 0i);
            let _e2172 = textureLoad(global_3, (_e2161 + vec2<i32>(_e2152, _e2159)), 0i);
            let _e2176 = textureLoad(global_3, (_e2161 + vec2<i32>(_e2155, _e2159)), 0i);
            let _e2179 = vec3(_e2138.x);
            phi_8004_ = (max(_e2048, vec3<f32>(0f, 0f, 0f)) * _e2052);
            phi_7992_ = _e2001.xy;
            phi_7968_ = (mix(mix(mix(_e2109.xyz, _e2113.xyz, _e2124), mix(_e2117.xyz, _e2121.xyz, _e2124), vec3(_e2083.y)), mix(mix(_e2164.xyz, _e2168.xyz, _e2179), mix(_e2172.xyz, _e2176.xyz, _e2179), vec3(_e2138.y)), vec3((_e2073 - f32(_e2075)))) * _e2052);
        } else {
            let _e2191 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e1900) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
            let _e2204 = global.member_9;
            let _e2205 = _e2204.xyz;
            let _e2207 = global.member_8;
            let _e2208 = _e2207.xyz;
            let _e2216 = global.member_8[3u];
            let _e2217 = (mix(_e2205, _e2208, vec3(((_e777.y * 0.5f) + 0.5f))) * _e2216);
            phi_8004_ = _e2217;
            phi_7992_ = ((vec2<f32>(-1.04f, 1.04f) * ((min((_e2191.x * _e2191.x), exp2((-9.28f * _e1937))) * _e2191.x) + _e2191.y)) + _e2191.zw);
            phi_7968_ = mix((mix(_e2205, _e2208, vec3(((reflect(-(_e787), _e1923).y * 0.5f) + 0.5f))) * _e2216), _e2217, vec3(_e1900));
        }
        let _e2229 = phi_8004_;
        let _e2231 = phi_7992_;
        let _e2233 = phi_7968_;
        phi_2835_ = _e1221;
        if _e1221 {
            let _e2236 = global.member_33[2u];
            phi_2835_ = (_e2236 > 0.5f);
        }
        let _e2239 = phi_2835_;
        phi_8013_ = _e2233;
        if _e2239 {
            switch bitcast<i32>(0u) {
                default: {
                    let _e2242 = global.member_31;
                    let _e2243 = _e2242.xyz;
                    let _e2246 = global.member_33[0u];
                    let _e2251 = global.member_31[3u];
                    let _e2260 = global.member_32[1u];
                    let _e2266 = global.member_32[0u];
                    let _e2269 = (((_e2266 * (1f - smoothstep((_e2246 * 0.5f), _e2246, abs((dot(_e2243, _e785) - _e2251))))) * smoothstep(0.5f, 0.9f, dot(_e792, _e2243))) * (1f - smoothstep((_e2260 * 0.5f), _e2260, _e1900)));
                    if (_e2269 <= 0f) {
                        phi_7989_ = _e2233;
                        break;
                    }
                    let _e2276 = global.member_32[3u];
                    let _e2278 = (_e785 + ((_e777 - (_e2243 * dot(_e777, _e2243))) * _e2276));
                    let _e2280 = global.member_30;
                    let _e2285 = (_e2280 * vec4<f32>(_e2278.x, _e2278.y, _e2278.z, 1f));
                    let _e2297 = global.member_32[2u];
                    phi_7988_ = 0f;
                    phi_7987_ = vec3<f32>(0f, 0f, 0f);
                    phi_7986_ = 0i;
                    loop {
                        let _e2300 = phi_7988_;
                        let _e2302 = phi_7987_;
                        let _e2304 = phi_7986_;
                        local_38 = _e2302;
                        local_39 = _e2300;
                        if (_e2304 < 12i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e2306 = f32(_e2304);
                            let _e2311 = (_e2306 * 2.3999631f);
                            let _e2315 = global.member_33[1u];
                            let _e2320 = ((((vec2<f32>(_e2285.x, -(_e2285.y)) / vec2(_e2285.w)) * 0.5f) + vec2<f32>(0.5f, 0.5f)) + (vec2<f32>((cos(_e2311) * _e2315), sin(_e2311)) * (sqrt(((_e2306 + 0.5f) * 0.083333336f)) * (_e2297 * _e1900))));
                            let _e2322 = min(_e2320, (vec2<f32>(1f, 1f) - _e2320));
                            let _e2326 = smoothstep(0f, 0.04f, min(_e2322.x, _e2322.y));
                            let _e2328 = textureSampleLevel(global_18, global_4, clamp(_e2320, vec2<f32>(0f, 0f), vec2<f32>(1f, 1f)), 0f);
                            let _e2329 = _e2328.xyz;
                            phi_7988_ = (_e2300 + (_e2328.w * _e2326));
                            phi_7987_ = (_e2302 + ((_e2329 / (vec3<f32>(1f, 1f, 1f) - min(_e2329, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e2326));
                            phi_7986_ = (_e2304 + 1i);
                        }
                    }
                    let _e2340 = local_38;
                    let _e2343 = local_39;
                    phi_7989_ = mix(_e2233, ((_e2340 * vec3<f32>(0.083333336f, 0.083333336f, 0.083333336f)) + (_e2233 * (1f - (_e2343 * 0.083333336f)))), vec3(_e2269));
                    break;
                }
            }
            let _e2351 = phi_7989_;
            phi_8013_ = _e2351;
        }
        let _e2353 = phi_8013_;
        let _e2358 = ((_e1905 * _e2231.x) + vec3(_e2231.y));
        let _e2365 = (_e1992 + (((((vec3<f32>(1f, 1f, 1f) - _e2358) * _e1903) * _e2229) + (_e2358 * _e2353)) * _e1239));
        let _e2368 = global.member_13[3u];
        phi_8189_ = _e2365;
        if (_e2368 > 0.5f) {
            let _e2371 = global.member_11;
            let _e2376 = global.member_11[3u];
            let _e2378 = global_15;
            let _e2381 = global.member_12;
            let _e2386 = global.member_13;
            let _e2389 = clamp(floor((_e2378.xy * _e2381.xy)), vec2<f32>(0f, 0f), (_e2386.xy - vec2<f32>(1f, 1f)));
            let _e2394 = global.member_12[2u];
            let _e2398 = global.member_12[3u];
            let _e2403 = global.member_13[2u];
            let _e2408 = global.member_13[1u];
            let _e2414 = global.member_13[0u];
            let _e2418 = u32(((((clamp(floor(((log2(max((dot(_e2371.xyz, _e785) + _e2376), 0.000001f)) * _e2394) + _e2398)), 0f, (_e2403 - 1f)) * _e2408) + _e2389.y) * _e2414) + _e2389.x));
            let _e2425 = global_16.member[(_e2418 >> bitcast<u32>(2i))][(_e2418 & 3u)];
            let _e2426 = (_e2425 & 65535u);
            phi_8142_ = _e2365;
            phi_8045_ = _e2426;
            loop {
                let _e2430 = phi_8142_;
                let _e2432 = phi_8045_;
                local_52 = _e2430;
                if (_e2432 < (_e2426 + (_e2425 >> bitcast<u32>(16i)))) {
                    let _e2435 = (_e2432 / 3u);
                    let _e2442 = global_17.member[(_e2435 >> bitcast<u32>(2i))][(_e2435 & 3u)];
                    let _e2448 = ((_e2442 >> bitcast<u32>(((_e2432 - (_e2435 * 3u)) * 10u))) & 1023u);
                    let _e2451 = global_11.member[_e2448];
                    let _e2453 = (_e2451.xyz - _e785);
                    let _e2454 = dot(_e2453, _e2453);
                    let _e2456 = (_e2454 * _e2451.w);
                    let _e2459 = clamp((1f - (_e2456 * _e2456)), 0f, 1f);
                    let _e2462 = (_e2453 * inverseSqrt(max(_e2454, 0.00000001f)));
                    let _e2465 = global_13.member[_e2448];
                    let _e2468 = global_14.member[_e2448];
                    let _e2476 = clamp(((dot(-(_e2462), _e2468.xyz) * _e2465.w) + _e2468.w), 0f, 1f);
                    let _e2483 = (_e2465.xyz * ((((_e2459 * _e2459) * _e2476) * _e2476) / max(_e2454, 0.0001f)));
                    phi_8140_ = _e2483;
                    if _e795 {
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e2487 = global.member_21[2u];
                                let _e2488 = u32(_e2487);
                                if (_e2448 < _e2488) {
                                    let _e2492 = global.member_26[_e2448];
                                    let _e2495 = global.member_15[_e2448];
                                    let _e2504 = (_e2492.z * max((_e2495 * vec4<f32>(_e785.x, _e785.y, _e785.z, 1f)).w, 0f));
                                    let _e2507 = global.member_25[0u];
                                    let _e2513 = global.member_25[1u];
                                    let _e2516 = ((_e785 + (_e792 * (_e2504 * _e2507))) + (_e2462 * (_e2504 * _e2513)));
                                    let _e2521 = (_e2495 * vec4<f32>(_e2516.x, _e2516.y, _e2516.z, 1f));
                                    if (_e2521.w <= 0f) {
                                        phi_8072_ = 1f;
                                        break;
                                    }
                                    let _e2526 = (_e2521.xyz / vec3(_e2521.w));
                                    let _e2528 = (_e2526.x < 0f);
                                    phi_6702_ = _e2528;
                                    if !(_e2528) {
                                        phi_6702_ = (_e2526.x > 1f);
                                    }
                                    let _e2532 = phi_6702_;
                                    phi_6709_ = _e2532;
                                    if !(_e2532) {
                                        phi_6709_ = (_e2526.y < 0f);
                                    }
                                    let _e2537 = phi_6709_;
                                    phi_6716_ = _e2537;
                                    if !(_e2537) {
                                        phi_6716_ = (_e2526.y > 1f);
                                    }
                                    let _e2542 = phi_6716_;
                                    phi_6723_ = _e2542;
                                    if !(_e2542) {
                                        phi_6723_ = (_e2526.z > 1f);
                                    }
                                    let _e2547 = phi_6723_;
                                    if _e2547 {
                                        phi_8072_ = 1f;
                                        break;
                                    }
                                    let _e2550 = _e2492.xy;
                                    let _e2552 = global.member_23;
                                    let _e2553 = _e2552.zw;
                                    let _e2555 = global.member_22;
                                    let _e2556 = _e2555.xy;
                                    let _e2557 = (_e2556 * 0.5f);
                                    let _e2559 = (_e2550 + (_e2526.xy * _e2553));
                                    let _e2560 = (_e2550 + _e2557);
                                    let _e2562 = ((_e2550 + _e2553) - _e2557);
                                    let _e2567 = vec4<f32>(_e2560.x, _e2560.y, _e2562.x, _e2562.y);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e2571 = global.member_22[2u];
                                            let _e2572 = i32(_e2571);
                                            if (_e2572 <= 0i) {
                                                let _e2576 = clamp(_e2559, _e2567.xy, _e2567.zw);
                                                let _e2581 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2576.x, _e2576.y, _e2526.z).xy, _e2526.z);
                                                phi_8071_ = _e2581;
                                                break;
                                            }
                                            let _e2583 = ((_e2559 / _e2556) + vec2<f32>(0.5f, 0.5f));
                                            let _e2584 = floor(_e2583);
                                            let _e2585 = (_e2583 - _e2584);
                                            let _e2587 = (_e2572 == 1i);
                                            if _e2587 {
                                                let _e2588 = (_e2585 * 2f);
                                                local_2[0i] = (vec2<f32>(3f, 3f) - _e2588);
                                                local_2[1i] = (vec2<f32>(1f, 1f) + _e2588);
                                                let _e2594 = local_2[0i];
                                                local_3[0i] = (((vec2<f32>(2f, 2f) - _e2585) / _e2594) - vec2<f32>(1f, 1f));
                                                let _e2598 = local_2[1i];
                                                local_3[1i] = ((_e2585 / _e2598) + vec2<f32>(1f, 1f));
                                            } else {
                                                let _e2602 = (_e2585 * 3f);
                                                local_2[0i] = (vec2<f32>(4f, 4f) - _e2602);
                                                local_2[1i] = vec2<f32>(7f, 7f);
                                                local_2[2i] = (vec2<f32>(1f, 1f) + _e2602);
                                                let _e2610 = local_2[0i];
                                                local_3[0i] = (((vec2<f32>(3f, 3f) - (_e2585 * 2f)) / _e2610) - vec2<f32>(2f, 2f));
                                                let _e2615 = local_2[1i];
                                                local_3[1i] = ((vec2<f32>(3f, 3f) + _e2585) / _e2615);
                                                let _e2618 = local_2[2i];
                                                local_3[2i] = ((_e2585 / _e2618) + vec2<f32>(2f, 2f));
                                            }
                                            let _e2623 = select(3i, 2i, _e2587);
                                            phi_8064_ = 0f;
                                            phi_8061_ = 0i;
                                            loop {
                                                let _e2625 = phi_8064_;
                                                let _e2627 = phi_8061_;
                                                local_40 = _e2625;
                                                if (_e2627 < _e2623) {
                                                    phi_8070_ = _e2625;
                                                    phi_8067_ = 0i;
                                                    loop {
                                                        let _e2630 = phi_8070_;
                                                        let _e2632 = phi_8067_;
                                                        local_50 = _e2630;
                                                        if (_e2632 < _e2623) {
                                                            continue;
                                                        } else {
                                                            break;
                                                        }
                                                        continuing {
                                                            let _e2636 = local_3[_e2632][0u];
                                                            let _e2639 = local_3[_e2627][1u];
                                                            let _e2645 = clamp((_e2556 * ((_e2584 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2636, _e2639))), _e2567.xy, _e2567.zw);
                                                            let _e2648 = local_2[_e2632][0u];
                                                            let _e2651 = local_2[_e2627][1u];
                                                            let _e2657 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2645.x, _e2645.y, _e2526.z).xy, _e2526.z);
                                                            phi_8070_ = (_e2630 + ((_e2648 * _e2651) * _e2657));
                                                            phi_8067_ = (_e2632 + 1i);
                                                        }
                                                    }
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e3154 = local_50;
                                                    phi_8064_ = _e3154;
                                                    phi_8061_ = (_e2627 + 1i);
                                                }
                                            }
                                            let _e2663 = local_40;
                                            phi_8071_ = (_e2663 * select(0.0069444445f, 0.0625f, _e2587));
                                            break;
                                        }
                                    }
                                    let _e2666 = phi_8071_;
                                    phi_8072_ = _e2666;
                                    break;
                                }
                                let _e2667 = (_e2448 - _e2488);
                                let _e2670 = global.member_21[3u];
                                if (_e2667 >= u32(_e2670)) {
                                    phi_8072_ = 1f;
                                    break;
                                }
                                let _e2675 = global.member_27[_e2667];
                                let _e2678 = global.member_28[_e2667];
                                let _e2680 = _e2675.xyz;
                                let _e2683 = (_e2675.w * length((_e785 - _e2680)));
                                let _e2686 = global.member_25[0u];
                                let _e2692 = global.member_25[1u];
                                let _e2696 = (((_e785 + (_e792 * (_e2683 * _e2686))) + (_e2462 * (_e2683 * _e2692))) - _e2680);
                                let _e2697 = abs(_e2696);
                                let _e2700 = (_e2697.x >= _e2697.y);
                                phi_6793_ = _e2700;
                                if _e2700 {
                                    phi_6793_ = (_e2697.x >= _e2697.z);
                                }
                                let _e2704 = phi_6793_;
                                if _e2704 {
                                    phi_8048_ = select(1i, 0i, (_e2696.x > 0f));
                                    phi_8046_ = _e2697.x;
                                } else {
                                    let _e2709 = (_e2697.y >= _e2697.z);
                                    if _e2709 {
                                        phi_8049_ = select(3i, 2i, (_e2696.y > 0f));
                                    } else {
                                        phi_8049_ = select(5i, 4i, (_e2696.z > 0f));
                                    }
                                    let _e2717 = phi_8049_;
                                    phi_8048_ = _e2717;
                                    phi_8046_ = select(_e2697.z, _e2697.y, _e2709);
                                }
                                let _e2720 = phi_8048_;
                                let _e2722 = phi_8046_;
                                if (_e2722 <= 0f) {
                                    phi_8072_ = 1f;
                                    break;
                                }
                                local_4 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                                let _e2725 = local_4[_e2720];
                                local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                                let _e2728 = local_5[_e2720];
                                let _e2733 = global.member_24[2u];
                                let _e2736 = (vec2<f32>(dot(_e2696, _e2725), dot(_e2696, _e2728)) / vec2((_e2722 * _e2733)));
                                let _e2740 = (_e2678.z + (_e2678.w / _e2722));
                                if (_e2740 > 1f) {
                                    phi_8072_ = 1f;
                                    break;
                                }
                                let _e2755 = global.member_24;
                                let _e2756 = _e2755.xy;
                                let _e2758 = (_e2678.xy + (vec2<f32>(f32((_e2720 - (i32(floor((f32(_e2720) / f32(3i)))) * 3i))), f32((_e2720 / 3i))) * _e2756));
                                let _e2767 = global.member_22;
                                let _e2768 = _e2767.xy;
                                let _e2769 = (_e2768 * 0.5f);
                                let _e2771 = (_e2758 + (vec2<f32>((0.5f + (0.5f * _e2736.x)), (0.5f - (0.5f * _e2736.y))) * _e2756));
                                let _e2772 = (_e2758 + _e2769);
                                let _e2774 = ((_e2758 + _e2756) - _e2769);
                                let _e2779 = vec4<f32>(_e2772.x, _e2772.y, _e2774.x, _e2774.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e2783 = global.member_22[2u];
                                        let _e2784 = i32(_e2783);
                                        if (_e2784 <= 0i) {
                                            let _e2788 = clamp(_e2771, _e2779.xy, _e2779.zw);
                                            let _e2793 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2788.x, _e2788.y, _e2740).xy, _e2740);
                                            phi_8060_ = _e2793;
                                            break;
                                        }
                                        let _e2795 = ((_e2771 / _e2768) + vec2<f32>(0.5f, 0.5f));
                                        let _e2796 = floor(_e2795);
                                        let _e2797 = (_e2795 - _e2796);
                                        let _e2799 = (_e2784 == 1i);
                                        if _e2799 {
                                            let _e2800 = (_e2797 * 2f);
                                            local[0i] = (vec2<f32>(3f, 3f) - _e2800);
                                            local[1i] = (vec2<f32>(1f, 1f) + _e2800);
                                            let _e2806 = local[0i];
                                            local_1[0i] = (((vec2<f32>(2f, 2f) - _e2797) / _e2806) - vec2<f32>(1f, 1f));
                                            let _e2810 = local[1i];
                                            local_1[1i] = ((_e2797 / _e2810) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e2814 = (_e2797 * 3f);
                                            local[0i] = (vec2<f32>(4f, 4f) - _e2814);
                                            local[1i] = vec2<f32>(7f, 7f);
                                            local[2i] = (vec2<f32>(1f, 1f) + _e2814);
                                            let _e2822 = local[0i];
                                            local_1[0i] = (((vec2<f32>(3f, 3f) - (_e2797 * 2f)) / _e2822) - vec2<f32>(2f, 2f));
                                            let _e2827 = local[1i];
                                            local_1[1i] = ((vec2<f32>(3f, 3f) + _e2797) / _e2827);
                                            let _e2830 = local[2i];
                                            local_1[2i] = ((_e2797 / _e2830) + vec2<f32>(2f, 2f));
                                        }
                                        let _e2835 = select(3i, 2i, _e2799);
                                        phi_8053_ = 0f;
                                        phi_8050_ = 0i;
                                        loop {
                                            let _e2837 = phi_8053_;
                                            let _e2839 = phi_8050_;
                                            local_41 = _e2837;
                                            if (_e2839 < _e2835) {
                                                phi_8059_ = _e2837;
                                                phi_8056_ = 0i;
                                                loop {
                                                    let _e2842 = phi_8059_;
                                                    let _e2844 = phi_8056_;
                                                    local_51 = _e2842;
                                                    if (_e2844 < _e2835) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e2848 = local_1[_e2844][0u];
                                                        let _e2851 = local_1[_e2839][1u];
                                                        let _e2857 = clamp((_e2768 * ((_e2796 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2848, _e2851))), _e2779.xy, _e2779.zw);
                                                        let _e2860 = local[_e2844][0u];
                                                        let _e2863 = local[_e2839][1u];
                                                        let _e2869 = textureSampleCompare(global_2, global_1, vec3<f32>(_e2857.x, _e2857.y, _e2740).xy, _e2740);
                                                        phi_8059_ = (_e2842 + ((_e2860 * _e2863) * _e2869));
                                                        phi_8056_ = (_e2844 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e3166 = local_51;
                                                phi_8053_ = _e3166;
                                                phi_8050_ = (_e2839 + 1i);
                                            }
                                        }
                                        let _e2875 = local_41;
                                        phi_8060_ = (_e2875 * select(0.0069444445f, 0.0625f, _e2799));
                                        break;
                                    }
                                }
                                let _e2878 = phi_8060_;
                                phi_8072_ = _e2878;
                                break;
                            }
                        }
                        let _e2880 = phi_8072_;
                        phi_8140_ = (_e2483 * _e2880);
                    }
                    let _e2883 = phi_8140_;
                    let _e2885 = normalize((_e2462 + _e787));
                    let _e2887 = clamp(dot(_e777, _e2462), 0f, 1f);
                    let _e2889 = clamp(dot(_e777, _e2885), 0f, 1f);
                    let _e2895 = (_e1905 + (_e1942 * pow((1f - clamp(dot(_e787, _e2885), 0f, 1f)), 5f)));
                    let _e2898 = (((_e2889 * _e2889) * _e1947) + 1f);
                    local_49 = (_e2430 + (((((vec3<f32>(1f, 1f, 1f) - _e2895) * _e1903) + ((_e2895 * ((_e1945 / ((3.1415927f * _e2898) * _e2898)) * (0.5f / max(((_e2887 * _e1957) + (_e1937 * sqrt((((_e2887 * _e2887) * _e1954) + _e1945)))), 0.00001f)))) * 3.1415927f)) * _e2887) * _e2883));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e3146 = local_49;
                    phi_8142_ = _e3146;
                    phi_8045_ = (_e2432 + bitcast<u32>(1i));
                }
            }
            let _e3176 = local_52;
            phi_8189_ = _e3176;
        }
        let _e2923 = phi_8189_;
        phi_8186_ = _e2923;
    }
    let _e2925 = phi_8186_;
    let _e2928 = global_7.member_1[1u];
    let _e2932 = global_7.member_5;
    let _e2934 = textureSample(global_28, global_4, _e247);
    let _e2937 = global_25;
    let _e2942 = global_27[2u];
    let _e2946 = -(length(_e786));
    let _e2949 = global.member_7[3u];
    let _e2955 = global.member_9[3u];
    phi_8231_ = (1f - exp((_e2946 * _e2949)));
    if (_e2955 != 0f) {
        let _e2959 = (_e2955 * (_e785 - _e784).y);
        if (abs(_e2959) < 0.0001f) {
            phi_8228_ = (1f - (0.5f * _e2959));
        } else {
            phi_8228_ = ((1f - exp(min(-(_e2959), 60f))) / _e2959);
        }
        let _e2970 = phi_8228_;
        let _e2974 = global.member_6[1u];
        let _e2977 = global.member_6[3u];
        phi_8231_ = (1f - exp(((_e2946 * (_e2949 * exp(min((-(_e2955) * (_e2974 - _e2977)), 30f)))) * _e2970)));
    }
    let _e2988 = phi_8231_;
    let _e2990 = global.member_7;
    let _e2993 = mix((mix(_e2925, _e1210, vec3(_e2928)) + (((_e2932.xyz * _e2934.xyz) * (vec3<f32>(1f, 1f, 1f) + _e2937.yzw)) * _e2942)), _e2990.xyz, vec3(_e2988));
    let _e2996 = global.member_33[3u];
    phi_8232_ = _e2993;
    if (_e2996 > 0.5f) {
        phi_8232_ = (_e2993 / (vec3<f32>(1f, 1f, 1f) + _e2993));
    }
    let _e3001 = phi_8232_;
    global_29 = vec4<f32>(_e3001.x, _e3001.y, _e3001.z, (_e267 * _e272));
    let _e3006 = global_31;
    let _e3007 = global_32;
    switch bitcast<i32>(0u) {
        default: {
            if (_e3007.w <= 0f) {
                phi_8312_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_8312_ = (((_e3007.xy / vec2(_e3007.w)) - (_e3006.xy / vec2(_e3006.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e3021 = phi_8312_;
    global_30 = _e3021;
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
