// Generated from mesh_fur.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: f901a8995896e267
// glsl-fnv1a64: be42f480620b7c36

diagnostic(off, derivative_uniformity);

struct type_17 {
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
}

struct type_31 {
    member: array<vec4<f32>, 1024>,
}

struct type_37 {
    member: array<vec4<u32>, 1024>,
}

struct type_42 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 8>,
}

struct FragmentOutput {
    @location(0) member: vec4<f32>,
    @location(1) member_1: vec2<f32>,
}

@group(0) @binding(0) 
var<uniform> global: type_17;
@group(1) @binding(0) 
var global_1: texture_depth_2d;
@group(2) @binding(14) 
var global_2: texture_2d<f32>;
@group(1) @binding(1) 
var global_3: sampler_comparison;
@group(2) @binding(17) 
var global_4: sampler;
@group(2) @binding(3) 
var<uniform> global_5: type_31;
var<private> global_6: vec3<f32>;
@group(2) @binding(4) 
var<uniform> global_7: type_31;
@group(2) @binding(5) 
var<uniform> global_8: type_31;
var<private> global_9: vec4<f32>;
@group(2) @binding(6) 
var<uniform> global_10: type_37;
@group(2) @binding(7) 
var<uniform> global_11: type_37;
@group(2) @binding(2) 
var<uniform> global_12: type_42;
var<private> global_13: vec4<f32>;
var<private> global_14: vec3<f32>;
var<private> global_15: vec2<f32>;
@group(2) @binding(10) 
var global_16: texture_2d<f32>;
var<private> global_17: vec3<f32>;
var<private> global_18: vec4<f32>;
var<private> global_19: vec3<f32>;
var<private> global_20: bool;
var<private> global_21: vec3<f32>;
var<private> global_22: vec4<f32>;
var<private> global_23: vec4<f32>;
var<private> global_24: vec2<f32>;
var<private> global_25: vec4<f32>;
var<private> global_26: vec4<f32>;

fn function_() {
    var local: array<vec2<f32>, 3>;
    var local_1: array<vec2<f32>, 3>;
    var local_2: array<vec2<f32>, 3>;
    var local_3: array<vec2<f32>, 3>;
    var local_4: array<vec3<f32>, 6>;
    var local_5: array<vec3<f32>, 6>;
    var local_6: array<f32, 9>;
    var local_7: array<vec3<f32>, 4>;
    var local_8: array<vec3<f32>, 4>;
    var phi_2672_: bool;
    var phi_3491_: bool;
    var phi_7600_: f32;
    var phi_7599_: f32;
    var phi_7638_: f32;
    var phi_7635_: f32;
    var phi_7639_: f32;
    var phi_7637_: f32;
    var phi_7636_: f32;
    var phi_7633_: f32;
    var phi_7630_: f32;
    var phi_7634_: f32;
    var phi_7632_: f32;
    var phi_7631_: f32;
    var phi_7662_: f32;
    var phi_7603_: vec3<f32>;
    var phi_7597_: f32;
    var phi_7601_: f32;
    var phi_7677_: f32;
    var phi_7624_: f32;
    var phi_7618_: f32;
    var phi_7605_: vec3<f32>;
    var phi_7607_: vec3<f32>;
    var phi_7611_: vec3<f32>;
    var phi_7612_: vec3<f32>;
    var phi_7647_: f32;
    var phi_7613_: f32;
    var phi_7652_: f32;
    var phi_7644_: f32;
    var phi_7629_: f32;
    var phi_7669_: f32;
    var phi_7653_: f32;
    var phi_7651_: f32;
    var phi_7641_: f32;
    var phi_7640_: f32;
    var local_9: bool;
    var phi_7685_: f32;
    var phi_2781_: bool;
    var phi_7686_: f32;
    var phi_7687_: vec2<f32>;
    var phi_7690_: f32;
    var phi_7689_: f32;
    var phi_7691_: f32;
    var phi_7692_: f32;
    var phi_7773_: f32;
    var phi_3030_: bool;
    var phi_7696_: vec3<f32>;
    var phi_7697_: i32;
    var phi_5247_: bool;
    var local_10: i32;
    var local_11: i32;
    var local_12: i32;
    var phi_5368_: bool;
    var phi_5375_: bool;
    var phi_5382_: bool;
    var local_13: i32;
    var local_14: i32;
    var local_15: i32;
    var phi_7699_: f32;
    var local_16: i32;
    var local_17: i32;
    var local_18: i32;
    var phi_5532_: bool;
    var phi_5539_: bool;
    var phi_5546_: bool;
    var phi_7704_: f32;
    var phi_7717_: f32;
    var phi_7714_: vec3<f32>;
    var phi_7716_: f32;
    var phi_7713_: vec3<f32>;
    var phi_7719_: vec3<f32>;
    var phi_7718_: f32;
    var phi_7766_: f32;
    var phi_7765_: vec3<f32>;
    var phi_7767_: f32;
    var phi_7790_: vec3<f32>;
    var phi_7789_: i32;
    var local_19: vec3<f32>;
    var phi_7791_: vec3<f32>;
    var phi_7803_: vec3<f32>;
    var phi_7799_: u32;
    var phi_6411_: bool;
    var phi_6418_: bool;
    var phi_6425_: bool;
    var phi_6432_: bool;
    var phi_7857_: f32;
    var phi_7854_: i32;
    var phi_7863_: f32;
    var phi_7860_: i32;
    var local_20: f32;
    var phi_7864_: f32;
    var phi_6502_: bool;
    var phi_7842_: i32;
    var phi_7841_: i32;
    var phi_7839_: f32;
    var phi_7846_: f32;
    var phi_7843_: i32;
    var phi_7852_: f32;
    var phi_7849_: i32;
    var local_21: f32;
    var phi_7853_: f32;
    var phi_7865_: f32;
    var phi_7866_: f32;
    var phi_7902_: f32;
    var phi_7802_: vec3<f32>;
    var phi_7800_: f32;
    var phi_7805_: f32;
    var phi_7806_: vec3<f32>;
    var phi_7835_: vec2<f32>;
    var local_22: vec3<f32>;
    var local_23: f32;
    var local_24: f32;
    var local_25: vec3<f32>;

    let _e228 = global_13[0u];
    let _e230 = global_13[2u];
    let _e231 = (_e230 > 0.5f);
    phi_2672_ = _e231;
    if _e231 {
        phi_2672_ = (_e230 < 1.5f);
    }
    let _e234 = phi_2672_;
    let _e235 = (_e230 > 1.5f);
    let _e237 = global_13[3u];
    let _e238 = (_e237 > 0.5f);
    let _e241 = global_12.member_1[0i];
    let _e244 = global_12.member_1[2i];
    let _e246 = global.member_6;
    let _e247 = _e246.xyz;
    let _e248 = global_6;
    let _e249 = (_e247 - _e248);
    let _e250 = normalize(_e249);
    let _e251 = dpdx(_e248);
    let _e252 = dpdy(_e248);
    let _e253 = cross(_e251, _e252);
    switch bitcast<i32>(0u) {
        default: {
            phi_3491_ = _e231;
            if _e231 {
                phi_3491_ = (_e230 < 1.5f);
            }
            let _e257 = phi_3491_;
            let _e260 = global_12.member_1[1i];
            let _e261 = global_14;
            let _e262 = dpdx(_e261);
            let _e263 = dpdy(_e261);
            let _e265 = global_15[0u];
            let _e266 = dpdx(_e265);
            let _e267 = dpdy(_e265);
            let _e268 = vec2<f32>(_e266, _e267);
            let _e272 = global_12.member_1[6i][2u];
            let _e274 = !(_e235);
            phi_7599_ = 1f;
            local_9 = _e274;
            if ((_e272 > 0.5f) && _e274) {
                let _e276 = global_15;
                let _e277 = textureSample(global_16, global_4, _e276);
                let _e282 = global_12.member_1[6i][3u];
                phi_7600_ = _e277.x;
                if (_e282 > 0.5f) {
                    phi_7600_ = (1f - _e277.x);
                }
                let _e286 = phi_7600_;
                phi_7599_ = _e286;
            }
            let _e288 = phi_7599_;
            if _e238 {
                if (_e288 < 0.02f) {
                    phi_7669_ = 0f;
                    phi_7653_ = 0f;
                    phi_7651_ = 0.5f;
                    phi_7641_ = 0f;
                    phi_7640_ = 0f;
                    break;
                }
                let _e297 = bitcast<vec3<u32>>((vec3<i32>(floor((_e261 / vec3(max(_e241.y, 0.00001f))))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e305 = (((_e297.x * 1597334677u) ^ (_e297.y * 3812015801u)) ^ (_e297.z * 2798796415u));
                let _e309 = ((_e305 ^ (_e305 >> bitcast<u32>(15i))) * 2246822519u);
                let _e313 = ((_e309 ^ (_e309 >> bitcast<u32>(13i))) * 3266489917u);
                let _e317 = ((_e313 ^ (_e313 >> bitcast<u32>(16i))) * 668265263u);
                phi_7669_ = 0f;
                phi_7653_ = 0f;
                phi_7651_ = (vec3<f32>(f32(), f32(), f32(((_e317 ^ (_e317 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).z;
                phi_7641_ = 0f;
                phi_7640_ = 1f;
                break;
            }
            if _e257 {
                let _e329 = global_12.member_1[4i][3u];
                let _e330 = max(_e329, 1f);
                let _e331 = (_e265 * _e330);
                let _e333 = (length(_e268) * _e330);
                let _e335 = global_13[1u];
                let _e339 = smoothstep(0.45f, 1.3f, _e333);
                let _e351 = ((min(mix(_e241.z, _e241.w, _e228), 1f) * clamp(((1f - _e228) / max(_e244.y, 0.02f)), 0f, 1f)) * (1f - smoothstep(0.75f, 1f, _e228)));
                phi_7639_ = 0.5f;
                phi_7637_ = _e228;
                phi_7636_ = _e351;
                if (_e339 < 0.999f) {
                    let _e357 = bitcast<vec3<u32>>((vec3<i32>(vec3<f32>(floor(_e331), floor((_e335 * 65535f)), 7f)) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e365 = (((_e357.x * 1597334677u) ^ (_e357.y * 3812015801u)) ^ (_e357.z * 2798796415u));
                    let _e369 = ((_e365 ^ (_e365 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e372 = (_e369 ^ (_e369 >> bitcast<u32>(13i)));
                    let _e373 = (_e372 * 3266489917u);
                    let _e376 = (_e373 ^ (_e373 >> bitcast<u32>(16i)));
                    let _e377 = (_e376 * 668265263u);
                    let _e388 = (vec3<f32>(f32((_e372 & 65535u)), f32((_e376 & 65535u)), f32(((_e377 ^ (_e377 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                    let _e398 = (1f - (_e244.y * _e388.y));
                    phi_7638_ = _e228;
                    phi_7635_ = 0f;
                    if (_e228 <= _e398) {
                        let _e401 = (_e228 / max(_e398, 0.001f));
                        let _e403 = (mix(_e241.z, _e241.w, _e401) * 0.5f);
                        let _e405 = (0.5f * max(_e333, 0.0001f));
                        let _e406 = max(_e403, _e405);
                        phi_7638_ = mix(_e401, _e228, _e339);
                        phi_7635_ = (((1f - smoothstep((_e406 - _e405), (_e406 + _e405), abs(((fract(_e331) - 0.5f) + ((_e388.x - 0.5f) * 0.3f))))) * (_e403 / _e406)) * (1f - smoothstep(0.75f, 1f, _e401)));
                    }
                    let _e418 = phi_7638_;
                    let _e420 = phi_7635_;
                    phi_7639_ = mix(_e388.z, 0.5f, _e339);
                    phi_7637_ = _e418;
                    phi_7636_ = mix(_e420, _e351, _e339);
                }
                let _e425 = phi_7639_;
                let _e427 = phi_7637_;
                let _e429 = phi_7636_;
                phi_7669_ = 0f;
                phi_7653_ = 0f;
                phi_7651_ = _e425;
                phi_7641_ = _e427;
                phi_7640_ = _e429;
                break;
            }
            if _e235 {
                let _e430 = length(_e268);
                let _e432 = max(_e244.y, 0.3f);
                let _e433 = smoothstep(0.45f, 1.3f, _e430);
                let _e445 = ((min(mix(_e241.z, _e241.w, _e228), 1f) * clamp(((1f - _e228) / max(_e432, 0.02f)), 0f, 1f)) * (1f - smoothstep(0.75f, 1f, _e228)));
                phi_7634_ = 0.5f;
                phi_7632_ = _e228;
                phi_7631_ = _e445;
                if (_e433 < 0.999f) {
                    let _e451 = bitcast<vec3<u32>>((vec3<i32>(vec3<f32>(floor(_e265), 3f, 7f)) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e459 = (((_e451.x * 1597334677u) ^ (_e451.y * 3812015801u)) ^ (_e451.z * 2798796415u));
                    let _e463 = ((_e459 ^ (_e459 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e466 = (_e463 ^ (_e463 >> bitcast<u32>(13i)));
                    let _e467 = (_e466 * 3266489917u);
                    let _e470 = (_e467 ^ (_e467 >> bitcast<u32>(16i)));
                    let _e471 = (_e470 * 668265263u);
                    let _e482 = (vec3<f32>(f32((_e466 & 65535u)), f32((_e470 & 65535u)), f32(((_e471 ^ (_e471 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                    let _e492 = (1f - (_e432 * _e482.y));
                    phi_7633_ = _e228;
                    phi_7630_ = 0f;
                    if (_e228 <= _e492) {
                        let _e495 = (_e228 / max(_e492, 0.001f));
                        let _e497 = (mix(_e241.z, _e241.w, _e495) * 0.5f);
                        let _e499 = (0.5f * max(_e430, 0.0001f));
                        let _e500 = max(_e497, _e499);
                        phi_7633_ = mix(_e495, _e228, _e433);
                        phi_7630_ = (((1f - smoothstep((_e500 - _e499), (_e500 + _e499), abs(((fract(_e265) - 0.5f) + ((_e482.x - 0.5f) * 0.3f))))) * (_e497 / _e500)) * (1f - smoothstep(0.75f, 1f, _e495)));
                    }
                    let _e512 = phi_7633_;
                    let _e514 = phi_7630_;
                    phi_7634_ = mix(_e482.z, 0.5f, _e433);
                    phi_7632_ = _e512;
                    phi_7631_ = mix(_e514, _e445, _e433);
                }
                let _e519 = phi_7634_;
                let _e521 = phi_7632_;
                let _e523 = phi_7631_;
                phi_7669_ = 0f;
                phi_7653_ = 0f;
                phi_7651_ = _e519;
                phi_7641_ = _e521;
                phi_7640_ = (((_e523 * 0.6f) * smoothstep(0f, 0.35f, _e228)) * (1f - smoothstep(0.3f, 0.9f, _e430)));
                break;
            }
            let _e531 = max(_e241.y, 0.00001f);
            let _e532 = global_17;
            let _e533 = normalize(_e532);
            phi_7662_ = 0f;
            phi_7603_ = _e261;
            phi_7597_ = 1f;
            if (_e260.x > 0f) {
                let _e536 = (_e531 * 4f);
                let _e539 = floor((_e261 / vec3(_e536)));
                let _e544 = bitcast<vec3<u32>>((vec3<i32>((_e539 + vec3<f32>(31f, 17f, 5f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e552 = (((_e544.x * 1597334677u) ^ (_e544.y * 3812015801u)) ^ (_e544.z * 2798796415u));
                let _e556 = ((_e552 ^ (_e552 >> bitcast<u32>(15i))) * 2246822519u);
                let _e559 = (_e556 ^ (_e556 >> bitcast<u32>(13i)));
                let _e560 = (_e559 * 3266489917u);
                let _e563 = (_e560 ^ (_e560 >> bitcast<u32>(16i)));
                let _e564 = (_e563 * 668265263u);
                let _e579 = (((_e539 + vec3<f32>(0.5f, 0.5f, 0.5f)) + (((vec3<f32>(f32((_e559 & 65535u)), f32((_e563 & 65535u)), f32(((_e564 ^ (_e564 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)) - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.6f)) * _e536);
                let _e583 = (_e579 - (_e533 * dot((_e579 - _e261), _e533)));
                let _e584 = (_e261 - _e583);
                let _e593 = (1f / (1f - min(((_e260.x * _e228) * 0.85f), 0.9f)));
                phi_7662_ = (_e260.x * smoothstep(0.15f, 0.6f, (length(_e584) / _e536)));
                phi_7603_ = (_e583 + (_e584 * _e593));
                phi_7597_ = _e593;
            }
            let _e597 = phi_7662_;
            let _e599 = phi_7603_;
            let _e601 = phi_7597_;
            let _e605 = ((_e262 - (_e533 * dot(_e262, _e533))) * _e601);
            let _e609 = ((_e263 - (_e533 * dot(_e263, _e533))) * _e601);
            let _e614 = (sqrt(max(dot(_e605, _e605), dot(_e609, _e609))) / _e531);
            let _e615 = smoothstep(0.6f, 1.6f, _e614);
            let _e616 = min(_e288, 1f);
            let _e619 = mix(_e241.z, _e241.w, _e228);
            phi_7677_ = 0f;
            phi_7624_ = 0.5f;
            phi_7618_ = 0f;
            if ((_e615 > 0.001f) && (_e616 > 0.01f)) {
                let _e625 = smoothstep(2f, 5f, _e614);
                if (_e615 >= 1f) {
                    phi_7601_ = (1f + step(1f, _e625));
                } else {
                    phi_7601_ = 0f;
                }
                let _e630 = phi_7601_;
                let _e633 = (_e261 / vec3((_e531 * 3f)));
                let _e634 = floor(_e633);
                let _e635 = (_e633 - _e634);
                let _e639 = ((_e635 * _e635) * (vec3<f32>(3f, 3f, 3f) - (_e635 * 2f)));
                let _e642 = bitcast<vec3<u32>>((vec3<i32>(_e634) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e650 = (((_e642.x * 1597334677u) ^ (_e642.y * 3812015801u)) ^ (_e642.z * 2798796415u));
                let _e654 = ((_e650 ^ (_e650 >> bitcast<u32>(15i))) * 2246822519u);
                let _e657 = (_e654 ^ (_e654 >> bitcast<u32>(13i)));
                let _e658 = (_e657 * 3266489917u);
                let _e672 = bitcast<vec3<u32>>((vec3<i32>((_e634 + vec3<f32>(1f, 0f, 0f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e680 = (((_e672.x * 1597334677u) ^ (_e672.y * 3812015801u)) ^ (_e672.z * 2798796415u));
                let _e684 = ((_e680 ^ (_e680 >> bitcast<u32>(15i))) * 2246822519u);
                let _e687 = (_e684 ^ (_e684 >> bitcast<u32>(13i)));
                let _e688 = (_e687 * 3266489917u);
                let _e700 = vec2(_e639.x);
                let _e705 = bitcast<vec3<u32>>((vec3<i32>((_e634 + vec3<f32>(0f, 1f, 0f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e713 = (((_e705.x * 1597334677u) ^ (_e705.y * 3812015801u)) ^ (_e705.z * 2798796415u));
                let _e717 = ((_e713 ^ (_e713 >> bitcast<u32>(15i))) * 2246822519u);
                let _e720 = (_e717 ^ (_e717 >> bitcast<u32>(13i)));
                let _e721 = (_e720 * 3266489917u);
                let _e735 = bitcast<vec3<u32>>((vec3<i32>((_e634 + vec3<f32>(1f, 1f, 0f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e743 = (((_e735.x * 1597334677u) ^ (_e735.y * 3812015801u)) ^ (_e735.z * 2798796415u));
                let _e747 = ((_e743 ^ (_e743 >> bitcast<u32>(15i))) * 2246822519u);
                let _e750 = (_e747 ^ (_e747 >> bitcast<u32>(13i)));
                let _e751 = (_e750 * 3266489917u);
                let _e764 = vec2(_e639.y);
                let _e769 = bitcast<vec3<u32>>((vec3<i32>((_e634 + vec3<f32>(0f, 0f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e777 = (((_e769.x * 1597334677u) ^ (_e769.y * 3812015801u)) ^ (_e769.z * 2798796415u));
                let _e781 = ((_e777 ^ (_e777 >> bitcast<u32>(15i))) * 2246822519u);
                let _e784 = (_e781 ^ (_e781 >> bitcast<u32>(13i)));
                let _e785 = (_e784 * 3266489917u);
                let _e799 = bitcast<vec3<u32>>((vec3<i32>((_e634 + vec3<f32>(1f, 0f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e807 = (((_e799.x * 1597334677u) ^ (_e799.y * 3812015801u)) ^ (_e799.z * 2798796415u));
                let _e811 = ((_e807 ^ (_e807 >> bitcast<u32>(15i))) * 2246822519u);
                let _e814 = (_e811 ^ (_e811 >> bitcast<u32>(13i)));
                let _e815 = (_e814 * 3266489917u);
                let _e830 = bitcast<vec3<u32>>((vec3<i32>((_e634 + vec3<f32>(0f, 1f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e838 = (((_e830.x * 1597334677u) ^ (_e830.y * 3812015801u)) ^ (_e830.z * 2798796415u));
                let _e842 = ((_e838 ^ (_e838 >> bitcast<u32>(15i))) * 2246822519u);
                let _e845 = (_e842 ^ (_e842 >> bitcast<u32>(13i)));
                let _e846 = (_e845 * 3266489917u);
                let _e860 = bitcast<vec3<u32>>((vec3<i32>((_e634 + vec3<f32>(1f, 1f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e868 = (((_e860.x * 1597334677u) ^ (_e860.y * 3812015801u)) ^ (_e860.z * 2798796415u));
                let _e872 = ((_e868 ^ (_e868 >> bitcast<u32>(15i))) * 2246822519u);
                let _e875 = (_e872 ^ (_e872 >> bitcast<u32>(13i)));
                let _e876 = (_e875 * 3266489917u);
                let _e891 = mix(mix(mix((vec3<f32>(f32((_e657 & 65535u)), f32(((_e658 ^ (_e658 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32((_e687 & 65535u)), f32(((_e688 ^ (_e688 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e700), mix((vec3<f32>(f32((_e720 & 65535u)), f32(((_e721 ^ (_e721 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32((_e750 & 65535u)), f32(((_e751 ^ (_e751 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e700), _e764), mix(mix((vec3<f32>(f32((_e784 & 65535u)), f32(((_e785 ^ (_e785 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32((_e814 & 65535u)), f32(((_e815 ^ (_e815 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e700), mix((vec3<f32>(f32((_e845 & 65535u)), f32(((_e846 ^ (_e846 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32((_e875 & 65535u)), f32(((_e876 ^ (_e876 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e700), _e764), vec2(_e639.z));
                let _e898 = (_e228 / _e616);
                phi_7677_ = _e630;
                phi_7624_ = mix(_e891.y, 0.5f, _e625);
                phi_7618_ = ((0.7853982f * (_e619 * _e619)) * mix(clamp(((((1f - (_e244.y * _e891.x)) - _e898) / max((_e244.y * 0.35f), 0.04f)) + 0.5f), 0f, 1f), clamp(((1f - _e898) / max(_e244.y, 0.02f)), 0f, 1f), _e625));
            }
            let _e912 = phi_7677_;
            let _e914 = phi_7624_;
            let _e916 = phi_7618_;
            phi_7652_ = _e914;
            phi_7644_ = _e228;
            phi_7629_ = _e916;
            if (_e615 < 0.999f) {
                let _e920 = floor((_e599 / vec3(_e531)));
                let _e923 = bitcast<vec3<u32>>((vec3<i32>(_e920) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e931 = (((_e923.x * 1597334677u) ^ (_e923.y * 3812015801u)) ^ (_e923.z * 2798796415u));
                let _e935 = ((_e931 ^ (_e931 >> bitcast<u32>(15i))) * 2246822519u);
                let _e938 = (_e935 ^ (_e935 >> bitcast<u32>(13i)));
                let _e939 = (_e938 * 3266489917u);
                let _e942 = (_e939 ^ (_e939 >> bitcast<u32>(16i)));
                let _e943 = (_e942 * 668265263u);
                let _e954 = (vec3<f32>(f32((_e938 & 65535u)), f32((_e942 & 65535u)), f32(((_e943 ^ (_e943 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                let _e959 = (((_e920 + vec3<f32>(0.5f, 0.5f, 0.5f)) + ((_e954 - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.5f)) * _e531);
                if (abs(_e533.y) < 0.9f) {
                    phi_7605_ = cross(_e533, vec3<f32>(0f, 1f, 0f));
                } else {
                    phi_7605_ = cross(_e533, vec3<f32>(1f, 0f, 0f));
                }
                let _e966 = phi_7605_;
                let _e967 = normalize(_e966);
                phi_7607_ = _e959;
                if (_e260.y > 0f) {
                    let _e974 = ((_e228 * 12.566f) + (_e954.x * 6.283f));
                    phi_7607_ = (_e959 + (((_e967 * cos(_e974)) + (cross(_e533, _e967) * sin(_e974))) * ((_e260.y * 0.3f) * _e531)));
                }
                let _e985 = phi_7607_;
                phi_7611_ = _e985;
                if (_e260.z > 0f) {
                    let _e988 = (_e228 * 4f);
                    let _e990 = (floor(_e988) * 7f);
                    let _e995 = bitcast<vec3<u32>>((vec3<i32>((_e920 + vec3<f32>(_e990, 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e1003 = (((_e995.x * 1597334677u) ^ (_e995.y * 3812015801u)) ^ (_e995.z * 2798796415u));
                    let _e1007 = ((_e1003 ^ (_e1003 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e1010 = (_e1007 ^ (_e1007 >> bitcast<u32>(13i)));
                    let _e1011 = (_e1010 * 3266489917u);
                    let _e1014 = (_e1011 ^ (_e1011 >> bitcast<u32>(16i)));
                    let _e1015 = (_e1014 * 668265263u);
                    let _e1032 = bitcast<vec3<u32>>((vec3<i32>((_e920 + vec3<f32>((_e990 + 7f), 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e1040 = (((_e1032.x * 1597334677u) ^ (_e1032.y * 3812015801u)) ^ (_e1032.z * 2798796415u));
                    let _e1044 = ((_e1040 ^ (_e1040 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e1047 = (_e1044 ^ (_e1044 >> bitcast<u32>(13i)));
                    let _e1048 = (_e1047 * 3266489917u);
                    let _e1051 = (_e1048 ^ (_e1048 >> bitcast<u32>(16i)));
                    let _e1052 = (_e1051 * 668265263u);
                    phi_7611_ = (_e985 + ((mix((vec3<f32>(f32((_e1010 & 65535u)), f32((_e1014 & 65535u)), f32(((_e1015 ^ (_e1015 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), (vec3<f32>(f32((_e1047 & 65535u)), f32((_e1051 & 65535u)), f32(((_e1052 ^ (_e1052 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), vec3(smoothstep(0f, 1f, fract(_e988)))) - vec3<f32>(0.5f, 0.5f, 0.5f)) * (((_e260.z * 0.4f) * _e531) * _e228)));
                }
                let _e1075 = phi_7611_;
                let _e1076 = (_e599 - _e1075);
                let _e1079 = (_e1076 - (_e533 * dot(_e1076, _e533)));
                let _e1084 = ((1f - (_e244.y * _e954.y)) * _e616);
                phi_7647_ = _e228;
                phi_7613_ = 0f;
                if (_e228 <= _e1084) {
                    let _e1087 = (_e228 / max(_e1084, 0.001f));
                    let _e1090 = ((mix(_e241.z, _e241.w, _e1087) * 0.5f) * _e531);
                    let _e1091 = length(_e1079);
                    if (_e1091 > 0.000000001f) {
                        phi_7612_ = (_e1079 / vec3(_e1091));
                    } else {
                        phi_7612_ = _e967;
                    }
                    let _e1096 = phi_7612_;
                    let _e1097 = dot(_e605, _e1096);
                    let _e1099 = dot(_e609, _e1096);
                    let _e1105 = (0.5f * max(sqrt(((_e1097 * _e1097) + (_e1099 * _e1099))), (_e531 * 0.001f)));
                    let _e1106 = max(_e1090, _e1105);
                    let _e1107 = (_e1090 / _e1106);
                    phi_7647_ = mix(_e1087, _e228, _e615);
                    phi_7613_ = (((1f - smoothstep((_e1106 - _e1105), (_e1106 + _e1105), _e1091)) * _e1107) * _e1107);
                }
                let _e1116 = phi_7647_;
                let _e1118 = phi_7613_;
                phi_7652_ = mix(_e954.z, _e914, _e615);
                phi_7644_ = _e1116;
                phi_7629_ = mix(_e1118, _e916, _e615);
            }
            let _e1123 = phi_7652_;
            let _e1125 = phi_7644_;
            let _e1127 = phi_7629_;
            phi_7669_ = _e912;
            phi_7653_ = _e597;
            phi_7651_ = _e1123;
            phi_7641_ = _e1125;
            phi_7640_ = _e1127;
            break;
        }
    }
    let _e1129 = phi_7669_;
    let _e1131 = phi_7653_;
    let _e1133 = phi_7651_;
    let _e1135 = phi_7641_;
    let _e1137 = phi_7640_;
    let _e1139 = global_18[3u];
    let _e1140 = floor(_e1139);
    let _e1141 = (_e1139 - _e1140);
    let _e1142 = !(_e234);
    let _e1144 = local_9;
    let _e1147 = ((_e1142 && _e1144) && !(_e238));
    phi_7685_ = _e1137;
    if (_e1147 && (_e1141 > 0.005f)) {
        phi_7685_ = (1f - pow((1f - min(_e1137, 0.999f)), (1f + ((_e1141 - 0.01f) * 8.163265f))));
    }
    let _e1158 = phi_7685_;
    let _e1162 = ((_e1147 && (_e1129 > 0.5f)) && (_e1140 >= 8f));
    phi_2781_ = _e1162;
    if _e1162 {
        let _e1163 = global_19;
        phi_2781_ = (abs(dot(normalize(_e1163), _e250)) > 0.45f);
    }
    let _e1169 = phi_2781_;
    phi_7686_ = _e1158;
    if _e1169 {
        let _e1173 = select(2f, 4f, ((_e1129 > 1.5f) && (_e1140 >= 16f)));
        let _e1176 = floor(((_e228 * _e1140) + 0.5f));
        if ((_e1176 - (floor((_e1176 / _e1173)) * _e1173)) > 0.5f) {
            discard;
        }
        phi_7686_ = (1f - pow((1f - min(_e1158, 0.999f)), _e1173));
    }
    let _e1187 = phi_7686_;
    if _e234 {
        let _e1188 = global_19;
        let _e1198 = global_12.member_1[7i][0u];
        let _e1199 = clamp(_e1198, 1f, 8f);
        let _e1200 = global_9;
        if (_e1199 < 1.5f) {
            let _e1206 = global_12.member_1[7i][1u];
            phi_7687_ = (vec2<f32>(5.588238f, 3.1416f) * _e1206);
        } else {
            phi_7687_ = vec2<f32>(0f, 0f);
        }
        let _e1209 = phi_7687_;
        let _e1219 = global_13[1u];
        if (floor((((_e1187 * mix(0.35f, 1f, smoothstep(0.03f, 0.3f, abs(dot(normalize(_e1188), _e250))))) * _e1199) + fract(((fract((52.982918f * fract(dot((_e1200.xy + _e1209), vec2<f32>(0.06711056f, 0.00583715f))))) + (_e1133 * 0.618034f)) + (_e1219 * 0.414214f))))) < 0.5f) {
            discard;
        }
        phi_7689_ = 1f;
    } else {
        phi_7690_ = _e1187;
        if _e235 {
            let _e1226 = global_19;
            phi_7690_ = (_e1187 * (smoothstep(0.72f, 0.95f, (1f - abs(dot(normalize(_e1226), _e250)))) * smoothstep(0.08f, 0.35f, abs(dot((_e253 * inverseSqrt(max(dot(_e253, _e253), 0.00000000000000000001f))), _e250)))));
        }
        let _e1242 = phi_7690_;
        phi_7689_ = _e1242;
    }
    let _e1244 = phi_7689_;
    if (_e1244 < 0.004f) {
        discard;
    }
    let _e1248 = global_12.member_1[3i];
    let _e1252 = global_12.member_1[4i];
    let _e1254 = (_e1133 - 0.5f);
    let _e1264 = global_18;
    let _e1266 = ((mix(_e1248.xyz, _e1252.xyz, vec3(pow(_e1135, 0.8f))) * max((1f + ((_e1254 * 2f) * _e244.z)), 0f)) * _e1264.xyz);
    if _e234 {
        phi_7691_ = 3f;
    } else {
        phi_7691_ = (((_e241.x * (_e241.z + _e241.w)) * 0.5f) / max(_e241.y, 0.00001f));
    }
    let _e1277 = phi_7691_;
    let _e1283 = (1f - exp(((_e1277 * (1f - (0.6f * _e1131))) * -0.2f)));
    if _e238 {
        phi_7692_ = 1f;
    } else {
        phi_7692_ = (1f - select(_e228, _e1135, _e234));
    }
    let _e1288 = phi_7692_;
    let _e1297 = max(mix(exp(((_e1283 * -2.5f) * _e1288)), 1f, (0.3f * sqrt(clamp(dot(_e1266, vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0f, 1f)))), 0.12f);
    phi_7773_ = _e1297;
    if _e234 {
        phi_7773_ = (_e1297 * mix(0.85f, 1f, _e1133));
    }
    let _e1301 = phi_7773_;
    let _e1302 = global_19;
    let _e1303 = normalize(_e1302);
    phi_3030_ = _e234;
    if _e234 {
        let _e1304 = global_20;
        phi_3030_ = !(_e1304);
    }
    let _e1307 = phi_3030_;
    phi_7696_ = _e1303;
    if _e1307 {
        phi_7696_ = -(_e1303);
    }
    let _e1310 = phi_7696_;
    let _e1311 = global_21;
    let _e1312 = normalize(_e1311);
    let _e1314 = global.member_4;
    let _e1316 = normalize(_e1314.xyz);
    let _e1318 = global_22[0u];
    let _e1319 = (_e1318 > 0.5f);
    let _e1324 = clamp(((_e241.x * 2f) / max((5f * _e1283), 1f)), 0.004f, 0.06f);
    let _e1327 = global.member_5[3u];
    phi_7766_ = 1f;
    phi_7765_ = _e1266;
    if ((_e1327 > 0.5f) && _e1319) {
        switch bitcast<i32>(0u) {
            default: {
                let _e1333 = global.member_21[0u];
                let _e1334 = i32(_e1333);
                let _e1336 = global.member_20;
                let _e1341 = global.member_20[3u];
                let _e1342 = (dot(_e1336.xyz, _e248) + _e1341);
                phi_7697_ = 0i;
                loop {
                    let _e1344 = phi_7697_;
                    local_10 = _e1344;
                    local_11 = _e1344;
                    local_12 = _e1344;
                    local_13 = _e1344;
                    local_14 = _e1344;
                    local_15 = _e1344;
                    local_16 = _e1344;
                    local_17 = _e1344;
                    local_18 = _e1344;
                    let _e1346 = (_e1344 < (_e1334 - 1i));
                    phi_5247_ = _e1346;
                    if _e1346 {
                        let _e1349 = global.member_16[_e1344];
                        phi_5247_ = (_e1342 > _e1349);
                    }
                    let _e1352 = phi_5247_;
                    if _e1352 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_7697_ = (_e1344 + 1i);
                    }
                }
                let _e1356 = local_10;
                let _e1358 = global.member_16[_e1356];
                if (_e1342 > _e1358) {
                    phi_7719_ = vec3<f32>(1f, 1f, 1f);
                    phi_7718_ = 1f;
                    break;
                }
                let _e1362 = local_11;
                let _e1364 = global.member_18[_e1362];
                let _e1366 = (_e248 + (_e1310 * _e1364));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e1370 = local_12;
                        let _e1372 = global.member_14[_e1370];
                        let _e1377 = (_e1372 * vec4<f32>(_e1366.x, _e1366.y, _e1366.z, 1f));
                        let _e1379 = (_e1377.x < 0f);
                        phi_5368_ = _e1379;
                        if !(_e1379) {
                            phi_5368_ = (_e1377.x > 1f);
                        }
                        let _e1383 = phi_5368_;
                        phi_5375_ = _e1383;
                        if !(_e1383) {
                            phi_5375_ = (_e1377.y < 0f);
                        }
                        let _e1388 = phi_5375_;
                        phi_5382_ = _e1388;
                        if !(_e1388) {
                            phi_5382_ = (_e1377.y > 1f);
                        }
                        let _e1393 = phi_5382_;
                        if _e1393 {
                            phi_7699_ = 1f;
                            break;
                        }
                        let _e1395 = local_13;
                        let _e1399 = local_14;
                        let _e1405 = global.member_23;
                        let _e1406 = _e1405.xy;
                        let _e1407 = (vec2<f32>(f32((_e1395 & 1i)), f32((_e1399 >> bitcast<u32>(1i)))) * _e1406);
                        let _e1412 = local_15;
                        let _e1414 = global.member_19[_e1412];
                        let _e1415 = (min(_e1377.z, 1f) - _e1414);
                        let _e1424 = (_e1324 * length(vec3<f32>(_e1372[0].z, _e1372[1].z, _e1372[2].z)));
                        let _e1426 = global.member_22;
                        let _e1427 = _e1426.xy;
                        let _e1428 = (_e1427 * 0.5f);
                        let _e1429 = (_e1407 + _e1428);
                        let _e1431 = ((_e1407 + _e1406) - _e1428);
                        let _e1434 = (_e1407 + (_e1377.xy * _e1406));
                        let _e1437 = clamp((_e1434 + (_e1427 * vec2<f32>(0f, 0.85f))), _e1429, _e1431);
                        let _e1439 = (_e1415 - (_e1424 * 0.18f));
                        let _e1444 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1437.x, _e1437.y, _e1439).xy, _e1439);
                        let _e1447 = clamp((_e1434 + (_e1427 * vec2<f32>(-0.74f, -0.43f))), _e1429, _e1431);
                        let _e1449 = (_e1415 - (_e1424 * 0.69f));
                        let _e1454 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1447.x, _e1447.y, _e1449).xy, _e1449);
                        let _e1458 = clamp((_e1434 + (_e1427 * vec2<f32>(0.74f, -0.43f))), _e1429, _e1431);
                        let _e1460 = (_e1415 - (_e1424 * 1.79f));
                        let _e1465 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1458.x, _e1458.y, _e1460).xy, _e1460);
                        phi_7699_ = (((_e1444 + _e1454) + _e1465) * 0.33333334f);
                        break;
                    }
                }
                let _e1469 = phi_7699_;
                local_7 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e1471 = local_16;
                let _e1473 = local_7[_e1471];
                let _e1476 = local_17;
                let _e1478 = global.member_17[_e1476];
                phi_7716_ = _e1469;
                phi_7713_ = _e1473;
                if (_e1342 > _e1478) {
                    let _e1482 = ((_e1342 - _e1478) / (_e1358 - _e1478));
                    let _e1484 = local_18;
                    let _e1485 = (_e1484 + 1i);
                    if (_e1485 < _e1334) {
                        let _e1489 = global.member_18[_e1485];
                        let _e1491 = (_e248 + (_e1310 * _e1489));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1495 = global.member_14[_e1485];
                                let _e1500 = (_e1495 * vec4<f32>(_e1491.x, _e1491.y, _e1491.z, 1f));
                                let _e1502 = (_e1500.x < 0f);
                                phi_5532_ = _e1502;
                                if !(_e1502) {
                                    phi_5532_ = (_e1500.x > 1f);
                                }
                                let _e1506 = phi_5532_;
                                phi_5539_ = _e1506;
                                if !(_e1506) {
                                    phi_5539_ = (_e1500.y < 0f);
                                }
                                let _e1511 = phi_5539_;
                                phi_5546_ = _e1511;
                                if !(_e1511) {
                                    phi_5546_ = (_e1500.y > 1f);
                                }
                                let _e1516 = phi_5546_;
                                if _e1516 {
                                    phi_7704_ = 1f;
                                    break;
                                }
                                let _e1524 = global.member_23;
                                let _e1525 = _e1524.xy;
                                let _e1526 = (vec2<f32>(f32((_e1485 & 1i)), f32((_e1485 >> bitcast<u32>(1i)))) * _e1525);
                                let _e1531 = global.member_19[_e1485];
                                let _e1532 = (min(_e1500.z, 1f) - _e1531);
                                let _e1541 = (_e1324 * length(vec3<f32>(_e1495[0].z, _e1495[1].z, _e1495[2].z)));
                                let _e1543 = global.member_22;
                                let _e1544 = _e1543.xy;
                                let _e1545 = (_e1544 * 0.5f);
                                let _e1546 = (_e1526 + _e1545);
                                let _e1548 = ((_e1526 + _e1525) - _e1545);
                                let _e1551 = (_e1526 + (_e1500.xy * _e1525));
                                let _e1554 = clamp((_e1551 + (_e1544 * vec2<f32>(0f, 0.85f))), _e1546, _e1548);
                                let _e1556 = (_e1532 - (_e1541 * 0.18f));
                                let _e1561 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1554.x, _e1554.y, _e1556).xy, _e1556);
                                let _e1564 = clamp((_e1551 + (_e1544 * vec2<f32>(-0.74f, -0.43f))), _e1546, _e1548);
                                let _e1566 = (_e1532 - (_e1541 * 0.69f));
                                let _e1571 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1564.x, _e1564.y, _e1566).xy, _e1566);
                                let _e1575 = clamp((_e1551 + (_e1544 * vec2<f32>(0.74f, -0.43f))), _e1546, _e1548);
                                let _e1577 = (_e1532 - (_e1541 * 1.79f));
                                let _e1582 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1575.x, _e1575.y, _e1577).xy, _e1577);
                                phi_7704_ = (((_e1561 + _e1571) + _e1582) * 0.33333334f);
                                break;
                            }
                        }
                        let _e1586 = phi_7704_;
                        local_8 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1589 = local_8[_e1485];
                        phi_7717_ = mix(_e1469, _e1586, _e1482);
                        phi_7714_ = mix(_e1473, _e1589, vec3(_e1482));
                    } else {
                        phi_7717_ = mix(_e1469, 1f, _e1482);
                        phi_7714_ = _e1473;
                    }
                    let _e1594 = phi_7717_;
                    let _e1596 = phi_7714_;
                    phi_7716_ = _e1594;
                    phi_7713_ = _e1596;
                }
                let _e1598 = phi_7716_;
                let _e1600 = phi_7713_;
                let _e1603 = global.member_22[3u];
                phi_7719_ = select(vec3<f32>(1f, 1f, 1f), _e1600, vec3((_e1603 > 0.5f)));
                phi_7718_ = _e1598;
                break;
            }
        }
        let _e1608 = phi_7719_;
        let _e1610 = phi_7718_;
        phi_7766_ = _e1610;
        phi_7765_ = (_e1266 * _e1608);
    }
    let _e1613 = phi_7766_;
    let _e1615 = phi_7765_;
    let _e1617 = (0.06f + (_e1254 * 0.08f));
    let _e1618 = select(0.45f, 0.38f, _e234);
    let _e1621 = global.member_5;
    let _e1625 = global.member_4[3u];
    let _e1628 = clamp(dot(_e1312, _e1316), -1f, 1f);
    let _e1630 = clamp(dot(_e1312, _e250), -1f, 1f);
    let _e1631 = asin(_e1630);
    let _e1637 = max(cos((0.5f * abs((_e1631 - asin(_e1628))))), 0.05f);
    let _e1639 = (_e1316 - (_e1312 * _e1628));
    let _e1641 = (_e250 - (_e1312 * _e1630));
    let _e1644 = dot(_e1641, _e1641);
    let _e1648 = (dot(_e1639, _e1641) * inverseSqrt(max((dot(_e1639, _e1639) * _e1644), 0.000001f)));
    let _e1652 = sqrt(clamp((0.5f + (0.5f * _e1648)), 0f, 1f));
    let _e1653 = (_e1618 * _e1618);
    let _e1654 = (_e1628 + _e1630);
    let _e1655 = (2f * _e1617);
    let _e1656 = (_e1654 + _e1655);
    let _e1659 = (_e1653 * _e1653);
    let _e1660 = (1.9999615f * _e1659);
    let _e1663 = (_e1653 * 3.5448735f);
    let _e1673 = (1f - clamp(sqrt(clamp((0.5f + (0.5f * dot(_e1316, _e250))), 0f, 1f)), 0f, 1f));
    let _e1674 = (_e1673 * _e1673);
    let _e1683 = ((_e1653 * 0.5f) + 0.08f);
    let _e1684 = (_e1654 - _e1617);
    let _e1687 = (_e1683 * _e1683);
    let _e1690 = (2.5066283f * _e1683);
    let _e1696 = (_e1652 * (1f + (0.6451613f * (0.6f - (0.8f * _e1648)))));
    let _e1697 = (_e1696 * _e1696);
    let _e1703 = (1f - clamp((_e1637 * sqrt(clamp((1f - _e1697), 0f, 1f))), 0f, 1f));
    let _e1704 = (_e1703 * _e1703);
    let _e1708 = max(_e1615, vec3<f32>(0.0001f, 0.0001f, 0.0001f));
    let _e1720 = (0.95348f - (((0.95348f * _e1704) * _e1704) * _e1703));
    let _e1725 = (4f * _e1617);
    let _e1726 = (_e1654 - _e1725);
    let _e1729 = (7.999846f * _e1659);
    let _e1732 = (_e1653 * 7.089747f);
    let _e1736 = (1f - clamp((_e1637 * 0.5f), 0f, 1f));
    let _e1737 = (_e1736 * _e1736);
    let _e1740 = (((0.95348f * _e1737) * _e1737) * _e1736);
    let _e1749 = (0.95348f - _e1740);
    if _e1142 {
        let _e1759 = clamp(((dot(_e1310, _e1316) * 0.6f) + 0.4f), 0f, 1f);
        phi_7767_ = (_e1759 * _e1759);
    } else {
        phi_7767_ = mix(clamp(((dot((_e1641 * inverseSqrt(max(_e1644, 0.000001f))), _e1316) + 1f) * 0.5f), 0f, 1f), (1f - abs(_e1628)), 0.33f);
    }
    let _e1772 = phi_7767_;
    let _e1776 = (_e1708 / vec3(max(dot(_e1615, vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0.0001f)));
    let _e1781 = pow(_e1708, vec3<f32>(0.92f, 0.92f, 0.92f));
    let _e1784 = (_e244.w * 3.1415927f);
    let _e1789 = mix(0.5f, 1f, _e1301);
    let _e1793 = global.member_29[0u];
    if (_e1793 > 0.5f) {
        let _e1796 = global.member_29;
        let _e1803 = ((_e1796.z * _e1310.x) - (_e1796.w * _e1310.z));
        let _e1807 = ((_e1796.w * _e1310.x) + (_e1796.z * _e1310.z));
        let _e1811 = (1.092548f * _e1803);
        local_6 = array<f32, 9>(0.282095f, (0.488603f * _e1310.y), (0.488603f * _e1807), (0.488603f * _e1803), (_e1811 * _e1310.y), ((1.092548f * _e1310.y) * _e1807), (0.315392f * (((3f * _e1807) * _e1807) - 1f)), (_e1811 * _e1807), (0.546274f * ((_e1803 * _e1803) - (_e1310.y * _e1310.y))));
        phi_7790_ = vec3<f32>(0f, 0f, 0f);
        phi_7789_ = 0i;
        loop {
            let _e1826 = phi_7790_;
            let _e1828 = phi_7789_;
            local_19 = _e1826;
            if (_e1828 < 9i) {
                continue;
            } else {
                break;
            }
            continuing {
                let _e1832 = textureLoad(global_2, (vec2<i32>(496i, 256i) + vec2<i32>(_e1828, 0i)), 0i);
                let _e1835 = local_6[_e1828];
                phi_7790_ = (_e1826 + (_e1832.xyz * _e1835));
                phi_7789_ = (_e1828 + 1i);
            }
        }
        let _e1840 = local_19;
        let _e1844 = global.member_29[1u];
        phi_7791_ = (max(_e1840, vec3<f32>(0f, 0f, 0f)) * _e1844);
    } else {
        let _e1847 = global.member_9;
        let _e1850 = global.member_8;
        let _e1859 = global.member_8[3u];
        phi_7791_ = (mix(_e1847.xyz, _e1850.xyz, vec3(((_e1310.y * 0.5f) + 0.5f))) * _e1859);
    }
    let _e1862 = phi_7791_;
    let _e1865 = (((((((_e1781 * pow(_e1776, vec3(((1f - _e1613) * 0.35f)))) * _e1772) + (((vec3((((((exp((((-0.5f * _e1656) * _e1656) / _e1660)) / _e1663) * 0.25f) * _e1652) * (0.04652f + (((0.95348f * _e1674) * _e1674) * _e1673))) * 3f)) + (pow(_e1708, vec3((sqrt(clamp((1f - (_e1697 * 0.41623306f)), 0f, 1f)) / _e1637))) * ((((exp((((-0.5f * _e1684) * _e1684) / _e1687)) / _e1690) * exp(((-3.65f * _e1648) - 3.98f))) * _e1720) * _e1720))) + ((pow(_e1708, vec3((0.8f / _e1637))) * (((((exp((((-0.5f * _e1726) * _e1726) / _e1729)) / _e1732) * exp(((17f * _e1648) - 16.78f))) * _e1749) * _e1749) * (0.04652f + _e1740))) * 4f)) * _e1784)) * (_e1621.xyz * _e1625)) * _e1613) * _e1789) + ((_e1615 * _e1862) * _e1301));
    let _e1868 = global.member_13[3u];
    phi_7802_ = _e1865;
    if (_e1868 > 0.5f) {
        let _e1871 = global.member_11;
        let _e1876 = global.member_11[3u];
        let _e1878 = global_9;
        let _e1881 = global.member_12;
        let _e1886 = global.member_13;
        let _e1889 = clamp(floor((_e1878.xy * _e1881.xy)), vec2<f32>(0f, 0f), (_e1886.xy - vec2<f32>(1f, 1f)));
        let _e1894 = global.member_12[2u];
        let _e1898 = global.member_12[3u];
        let _e1903 = global.member_13[2u];
        let _e1908 = global.member_13[1u];
        let _e1914 = global.member_13[0u];
        let _e1918 = u32(((((clamp(floor(((log2(max((dot(_e1871.xyz, _e248) + _e1876), 0.000001f)) * _e1894) + _e1898)), 0f, (_e1903 - 1f)) * _e1908) + _e1889.y) * _e1914) + _e1889.x));
        let _e1925 = global_10.member[(_e1918 >> bitcast<u32>(2i))][(_e1918 & 3u)];
        let _e1926 = (_e1925 & 65535u);
        phi_7803_ = _e1865;
        phi_7799_ = _e1926;
        loop {
            let _e1930 = phi_7803_;
            let _e1932 = phi_7799_;
            local_25 = _e1930;
            if (_e1932 < (_e1926 + (_e1925 >> bitcast<u32>(16i)))) {
                let _e1935 = (_e1932 / 3u);
                let _e1942 = global_11.member[(_e1935 >> bitcast<u32>(2i))][(_e1935 & 3u)];
                let _e1948 = ((_e1942 >> bitcast<u32>(((_e1932 - (_e1935 * 3u)) * 10u))) & 1023u);
                let _e1951 = global_5.member[_e1948];
                let _e1953 = (_e1951.xyz - _e248);
                let _e1954 = dot(_e1953, _e1953);
                let _e1956 = (_e1954 * _e1951.w);
                let _e1959 = clamp((1f - (_e1956 * _e1956)), 0f, 1f);
                let _e1962 = (_e1953 * inverseSqrt(max(_e1954, 0.00000001f)));
                let _e1965 = global_7.member[_e1948];
                let _e1968 = global_8.member[_e1948];
                let _e1976 = clamp(((dot(-(_e1962), _e1968.xyz) * _e1965.w) + _e1968.w), 0f, 1f);
                if _e1319 {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e1987 = global.member_21[2u];
                            let _e1988 = u32(_e1987);
                            if (_e1948 < _e1988) {
                                let _e1992 = global.member_26[_e1948];
                                let _e1995 = global.member_15[_e1948];
                                let _e2004 = (_e1992.z * max((_e1995 * vec4<f32>(_e248.x, _e248.y, _e248.z, 1f)).w, 0f));
                                let _e2007 = global.member_25[0u];
                                let _e2013 = global.member_25[1u];
                                let _e2016 = ((_e248 + (_e1310 * (_e2004 * _e2007))) + (_e1962 * (_e2004 * _e2013)));
                                let _e2021 = (_e1995 * vec4<f32>(_e2016.x, _e2016.y, _e2016.z, 1f));
                                if (_e2021.w <= 0f) {
                                    phi_7865_ = 1f;
                                    break;
                                }
                                let _e2026 = (_e2021.xyz / vec3(_e2021.w));
                                let _e2028 = (_e2026.x < 0f);
                                phi_6411_ = _e2028;
                                if !(_e2028) {
                                    phi_6411_ = (_e2026.x > 1f);
                                }
                                let _e2032 = phi_6411_;
                                phi_6418_ = _e2032;
                                if !(_e2032) {
                                    phi_6418_ = (_e2026.y < 0f);
                                }
                                let _e2037 = phi_6418_;
                                phi_6425_ = _e2037;
                                if !(_e2037) {
                                    phi_6425_ = (_e2026.y > 1f);
                                }
                                let _e2042 = phi_6425_;
                                phi_6432_ = _e2042;
                                if !(_e2042) {
                                    phi_6432_ = (_e2026.z > 1f);
                                }
                                let _e2047 = phi_6432_;
                                if _e2047 {
                                    phi_7865_ = 1f;
                                    break;
                                }
                                let _e2050 = _e1992.xy;
                                let _e2052 = global.member_23;
                                let _e2053 = _e2052.zw;
                                let _e2055 = global.member_22;
                                let _e2056 = _e2055.xy;
                                let _e2057 = (_e2056 * 0.5f);
                                let _e2059 = (_e2050 + (_e2026.xy * _e2053));
                                let _e2060 = (_e2050 + _e2057);
                                let _e2062 = ((_e2050 + _e2053) - _e2057);
                                let _e2067 = vec4<f32>(_e2060.x, _e2060.y, _e2062.x, _e2062.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e2071 = global.member_22[2u];
                                        let _e2072 = i32(_e2071);
                                        if (_e2072 <= 0i) {
                                            let _e2076 = clamp(_e2059, _e2067.xy, _e2067.zw);
                                            let _e2081 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2076.x, _e2076.y, _e2026.z).xy, _e2026.z);
                                            phi_7864_ = _e2081;
                                            break;
                                        }
                                        let _e2083 = ((_e2059 / _e2056) + vec2<f32>(0.5f, 0.5f));
                                        let _e2084 = floor(_e2083);
                                        let _e2085 = (_e2083 - _e2084);
                                        let _e2087 = (_e2072 == 1i);
                                        if _e2087 {
                                            let _e2088 = (_e2085 * 2f);
                                            local_2[0i] = (vec2<f32>(3f, 3f) - _e2088);
                                            local_2[1i] = (vec2<f32>(1f, 1f) + _e2088);
                                            let _e2094 = local_2[0i];
                                            local_3[0i] = (((vec2<f32>(2f, 2f) - _e2085) / _e2094) - vec2<f32>(1f, 1f));
                                            let _e2098 = local_2[1i];
                                            local_3[1i] = ((_e2085 / _e2098) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e2102 = (_e2085 * 3f);
                                            local_2[0i] = (vec2<f32>(4f, 4f) - _e2102);
                                            local_2[1i] = vec2<f32>(7f, 7f);
                                            local_2[2i] = (vec2<f32>(1f, 1f) + _e2102);
                                            let _e2110 = local_2[0i];
                                            local_3[0i] = (((vec2<f32>(3f, 3f) - (_e2085 * 2f)) / _e2110) - vec2<f32>(2f, 2f));
                                            let _e2115 = local_2[1i];
                                            local_3[1i] = ((vec2<f32>(3f, 3f) + _e2085) / _e2115);
                                            let _e2118 = local_2[2i];
                                            local_3[2i] = ((_e2085 / _e2118) + vec2<f32>(2f, 2f));
                                        }
                                        let _e2123 = select(3i, 2i, _e2087);
                                        phi_7857_ = 0f;
                                        phi_7854_ = 0i;
                                        loop {
                                            let _e2125 = phi_7857_;
                                            let _e2127 = phi_7854_;
                                            local_20 = _e2125;
                                            if (_e2127 < _e2123) {
                                                phi_7863_ = _e2125;
                                                phi_7860_ = 0i;
                                                loop {
                                                    let _e2130 = phi_7863_;
                                                    let _e2132 = phi_7860_;
                                                    local_23 = _e2130;
                                                    if (_e2132 < _e2123) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e2136 = local_3[_e2132][0u];
                                                        let _e2139 = local_3[_e2127][1u];
                                                        let _e2145 = clamp((_e2056 * ((_e2084 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2136, _e2139))), _e2067.xy, _e2067.zw);
                                                        let _e2148 = local_2[_e2132][0u];
                                                        let _e2151 = local_2[_e2127][1u];
                                                        let _e2157 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2145.x, _e2145.y, _e2026.z).xy, _e2026.z);
                                                        phi_7863_ = (_e2130 + ((_e2148 * _e2151) * _e2157));
                                                        phi_7860_ = (_e2132 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e2692 = local_23;
                                                phi_7857_ = _e2692;
                                                phi_7854_ = (_e2127 + 1i);
                                            }
                                        }
                                        let _e2163 = local_20;
                                        phi_7864_ = (_e2163 * select(0.0069444445f, 0.0625f, _e2087));
                                        break;
                                    }
                                }
                                let _e2166 = phi_7864_;
                                phi_7865_ = _e2166;
                                break;
                            }
                            let _e2167 = (_e1948 - _e1988);
                            let _e2170 = global.member_21[3u];
                            if (_e2167 >= u32(_e2170)) {
                                phi_7865_ = 1f;
                                break;
                            }
                            let _e2175 = global.member_27[_e2167];
                            let _e2178 = global.member_28[_e2167];
                            let _e2180 = _e2175.xyz;
                            let _e2183 = (_e2175.w * length((_e248 - _e2180)));
                            let _e2186 = global.member_25[0u];
                            let _e2192 = global.member_25[1u];
                            let _e2196 = (((_e248 + (_e1310 * (_e2183 * _e2186))) + (_e1962 * (_e2183 * _e2192))) - _e2180);
                            let _e2197 = abs(_e2196);
                            let _e2200 = (_e2197.x >= _e2197.y);
                            phi_6502_ = _e2200;
                            if _e2200 {
                                phi_6502_ = (_e2197.x >= _e2197.z);
                            }
                            let _e2204 = phi_6502_;
                            if _e2204 {
                                phi_7841_ = select(1i, 0i, (_e2196.x > 0f));
                                phi_7839_ = _e2197.x;
                            } else {
                                let _e2209 = (_e2197.y >= _e2197.z);
                                if _e2209 {
                                    phi_7842_ = select(3i, 2i, (_e2196.y > 0f));
                                } else {
                                    phi_7842_ = select(5i, 4i, (_e2196.z > 0f));
                                }
                                let _e2217 = phi_7842_;
                                phi_7841_ = _e2217;
                                phi_7839_ = select(_e2197.z, _e2197.y, _e2209);
                            }
                            let _e2220 = phi_7841_;
                            let _e2222 = phi_7839_;
                            if (_e2222 <= 0f) {
                                phi_7865_ = 1f;
                                break;
                            }
                            local_4 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                            let _e2225 = local_4[_e2220];
                            local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                            let _e2228 = local_5[_e2220];
                            let _e2233 = global.member_24[2u];
                            let _e2236 = (vec2<f32>(dot(_e2196, _e2225), dot(_e2196, _e2228)) / vec2((_e2222 * _e2233)));
                            let _e2240 = (_e2178.z + (_e2178.w / _e2222));
                            if (_e2240 > 1f) {
                                phi_7865_ = 1f;
                                break;
                            }
                            let _e2255 = global.member_24;
                            let _e2256 = _e2255.xy;
                            let _e2258 = (_e2178.xy + (vec2<f32>(f32((_e2220 - (i32(floor((f32(_e2220) / f32(3i)))) * 3i))), f32((_e2220 / 3i))) * _e2256));
                            let _e2267 = global.member_22;
                            let _e2268 = _e2267.xy;
                            let _e2269 = (_e2268 * 0.5f);
                            let _e2271 = (_e2258 + (vec2<f32>((0.5f + (0.5f * _e2236.x)), (0.5f - (0.5f * _e2236.y))) * _e2256));
                            let _e2272 = (_e2258 + _e2269);
                            let _e2274 = ((_e2258 + _e2256) - _e2269);
                            let _e2279 = vec4<f32>(_e2272.x, _e2272.y, _e2274.x, _e2274.y);
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e2283 = global.member_22[2u];
                                    let _e2284 = i32(_e2283);
                                    if (_e2284 <= 0i) {
                                        let _e2288 = clamp(_e2271, _e2279.xy, _e2279.zw);
                                        let _e2293 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2288.x, _e2288.y, _e2240).xy, _e2240);
                                        phi_7853_ = _e2293;
                                        break;
                                    }
                                    let _e2295 = ((_e2271 / _e2268) + vec2<f32>(0.5f, 0.5f));
                                    let _e2296 = floor(_e2295);
                                    let _e2297 = (_e2295 - _e2296);
                                    let _e2299 = (_e2284 == 1i);
                                    if _e2299 {
                                        let _e2300 = (_e2297 * 2f);
                                        local[0i] = (vec2<f32>(3f, 3f) - _e2300);
                                        local[1i] = (vec2<f32>(1f, 1f) + _e2300);
                                        let _e2306 = local[0i];
                                        local_1[0i] = (((vec2<f32>(2f, 2f) - _e2297) / _e2306) - vec2<f32>(1f, 1f));
                                        let _e2310 = local[1i];
                                        local_1[1i] = ((_e2297 / _e2310) + vec2<f32>(1f, 1f));
                                    } else {
                                        let _e2314 = (_e2297 * 3f);
                                        local[0i] = (vec2<f32>(4f, 4f) - _e2314);
                                        local[1i] = vec2<f32>(7f, 7f);
                                        local[2i] = (vec2<f32>(1f, 1f) + _e2314);
                                        let _e2322 = local[0i];
                                        local_1[0i] = (((vec2<f32>(3f, 3f) - (_e2297 * 2f)) / _e2322) - vec2<f32>(2f, 2f));
                                        let _e2327 = local[1i];
                                        local_1[1i] = ((vec2<f32>(3f, 3f) + _e2297) / _e2327);
                                        let _e2330 = local[2i];
                                        local_1[2i] = ((_e2297 / _e2330) + vec2<f32>(2f, 2f));
                                    }
                                    let _e2335 = select(3i, 2i, _e2299);
                                    phi_7846_ = 0f;
                                    phi_7843_ = 0i;
                                    loop {
                                        let _e2337 = phi_7846_;
                                        let _e2339 = phi_7843_;
                                        local_21 = _e2337;
                                        if (_e2339 < _e2335) {
                                            phi_7852_ = _e2337;
                                            phi_7849_ = 0i;
                                            loop {
                                                let _e2342 = phi_7852_;
                                                let _e2344 = phi_7849_;
                                                local_24 = _e2342;
                                                if (_e2344 < _e2335) {
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e2348 = local_1[_e2344][0u];
                                                    let _e2351 = local_1[_e2339][1u];
                                                    let _e2357 = clamp((_e2268 * ((_e2296 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2348, _e2351))), _e2279.xy, _e2279.zw);
                                                    let _e2360 = local[_e2344][0u];
                                                    let _e2363 = local[_e2339][1u];
                                                    let _e2369 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2357.x, _e2357.y, _e2240).xy, _e2240);
                                                    phi_7852_ = (_e2342 + ((_e2360 * _e2363) * _e2369));
                                                    phi_7849_ = (_e2344 + 1i);
                                                }
                                            }
                                            continue;
                                        } else {
                                            break;
                                        }
                                        continuing {
                                            let _e2704 = local_24;
                                            phi_7846_ = _e2704;
                                            phi_7843_ = (_e2339 + 1i);
                                        }
                                    }
                                    let _e2375 = local_21;
                                    phi_7853_ = (_e2375 * select(0.0069444445f, 0.0625f, _e2299));
                                    break;
                                }
                            }
                            let _e2378 = phi_7853_;
                            phi_7865_ = _e2378;
                            break;
                        }
                    }
                    let _e2380 = phi_7865_;
                    phi_7866_ = _e2380;
                } else {
                    phi_7866_ = 1f;
                }
                let _e2382 = phi_7866_;
                let _e2384 = clamp(dot(_e1312, _e1962), -1f, 1f);
                let _e2390 = max(cos((0.5f * abs((_e1631 - asin(_e2384))))), 0.05f);
                let _e2392 = (_e1962 - (_e1312 * _e2384));
                let _e2398 = (dot(_e2392, _e1641) * inverseSqrt(max((dot(_e2392, _e2392) * _e1644), 0.000001f)));
                let _e2402 = sqrt(clamp((0.5f + (0.5f * _e2398)), 0f, 1f));
                let _e2403 = (_e2384 + _e1630);
                let _e2404 = (_e2403 + _e1655);
                let _e2418 = (1f - clamp(sqrt(clamp((0.5f + (0.5f * dot(_e1962, _e250))), 0f, 1f)), 0f, 1f));
                let _e2419 = (_e2418 * _e2418);
                let _e2427 = (_e2403 - _e1617);
                let _e2437 = (_e2402 * (1f + (0.6451613f * (0.6f - (0.8f * _e2398)))));
                let _e2438 = (_e2437 * _e2437);
                let _e2444 = (1f - clamp((_e2390 * sqrt(clamp((1f - _e2438), 0f, 1f))), 0f, 1f));
                let _e2445 = (_e2444 * _e2444);
                let _e2460 = (0.95348f - (((0.95348f * _e2445) * _e2445) * _e2444));
                let _e2465 = (_e2403 - _e1725);
                let _e2473 = (1f - clamp((_e2390 * 0.5f), 0f, 1f));
                let _e2474 = (_e2473 * _e2473);
                let _e2477 = (((0.95348f * _e2474) * _e2474) * _e2473);
                let _e2486 = (0.95348f - _e2477);
                if _e1142 {
                    let _e2496 = clamp(((dot(_e1310, _e1962) * 0.6f) + 0.4f), 0f, 1f);
                    phi_7902_ = (_e2496 * _e2496);
                } else {
                    phi_7902_ = mix(clamp(((dot((_e1641 * inverseSqrt(max(_e1644, 0.000001f))), _e1962) + 1f) * 0.5f), 0f, 1f), (1f - abs(_e2384)), 0.33f);
                }
                let _e2509 = phi_7902_;
                local_22 = (_e1930 + ((((((_e1781 * pow(_e1776, vec3(((1f - _e2382) * 0.35f)))) * _e2509) + (((vec3((((((exp((((-0.5f * _e2404) * _e2404) / _e1660)) / _e1663) * 0.25f) * _e2402) * (0.04652f + (((0.95348f * _e2419) * _e2419) * _e2418))) * 3f)) + (pow(_e1708, vec3((sqrt(clamp((1f - (_e2438 * 0.41623306f)), 0f, 1f)) / _e2390))) * ((((exp((((-0.5f * _e2427) * _e2427) / _e1687)) / _e1690) * exp(((-3.65f * _e2398) - 3.98f))) * _e2460) * _e2460))) + ((pow(_e1708, vec3((0.8f / _e2390))) * (((((exp((((-0.5f * _e2465) * _e2465) / _e1729)) / _e1732) * exp(((17f * _e2398) - 16.78f))) * _e2486) * _e2486) * (0.04652f + _e2477))) * 4f)) * _e1784)) * (_e1965.xyz * ((((_e1959 * _e1959) * _e1976) * _e1976) / max(_e1954, 0.0001f)))) * _e2382) * _e1789));
                continue;
            } else {
                break;
            }
            continuing {
                let _e2684 = local_22;
                phi_7803_ = _e2684;
                phi_7799_ = (_e1932 + bitcast<u32>(1i));
            }
        }
        let _e2715 = local_25;
        phi_7802_ = _e2715;
    }
    let _e2525 = phi_7802_;
    let _e2527 = -(length(_e249));
    let _e2530 = global.member_7[3u];
    let _e2536 = global.member_9[3u];
    phi_7805_ = (1f - exp((_e2527 * _e2530)));
    if (_e2536 != 0f) {
        let _e2540 = (_e2536 * (_e248 - _e247).y);
        if (abs(_e2540) < 0.0001f) {
            phi_7800_ = (1f - (0.5f * _e2540));
        } else {
            phi_7800_ = ((1f - exp(min(-(_e2540), 60f))) / _e2540);
        }
        let _e2551 = phi_7800_;
        let _e2555 = global.member_6[1u];
        let _e2558 = global.member_6[3u];
        phi_7805_ = (1f - exp(((_e2527 * (_e2530 * exp(min((-(_e2536) * (_e2555 - _e2558)), 30f)))) * _e2551)));
    }
    let _e2569 = phi_7805_;
    let _e2571 = global.member_7;
    let _e2574 = mix(_e2525, _e2571.xyz, vec3(_e2569));
    let _e2577 = global.member_33[3u];
    phi_7806_ = _e2574;
    if (_e2577 > 0.5f) {
        phi_7806_ = (_e2574 / (vec3<f32>(1f, 1f, 1f) + _e2574));
    }
    let _e2582 = phi_7806_;
    global_23 = vec4<f32>(_e2582.x, _e2582.y, _e2582.z, _e1244);
    let _e2587 = global_25;
    let _e2588 = global_26;
    switch bitcast<i32>(0u) {
        default: {
            if (_e2588.w <= 0f) {
                phi_7835_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_7835_ = (((_e2588.xy / vec2(_e2588.w)) - (_e2587.xy / vec2(_e2587.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e2602 = phi_7835_;
    global_24 = _e2602;
    return;
}

@fragment 
fn main(@location(0) param: vec3<f32>, @builtin(position) param_1: vec4<f32>, @location(8) param_2: vec4<f32>, @location(4) param_3: vec3<f32>, @location(2) param_4: vec2<f32>, @location(10) param_5: vec3<f32>, @location(3) param_6: vec4<f32>, @location(1) param_7: vec3<f32>, @builtin(front_facing) param_8: bool, @location(9) param_9: vec3<f32>, @location(5) param_10: vec4<f32>, @location(6) param_11: vec4<f32>, @location(7) param_12: vec4<f32>) -> FragmentOutput {
    global_6 = param;
    global_9 = param_1;
    global_13 = param_2;
    global_14 = param_3;
    global_15 = param_4;
    global_17 = param_5;
    global_18 = param_6;
    global_19 = param_7;
    global_20 = param_8;
    global_21 = param_9;
    global_22 = param_10;
    global_25 = param_11;
    global_26 = param_12;
    function_();
    let _e28 = global_23;
    let _e29 = global_24;
    return FragmentOutput(_e28, _e29);
}
