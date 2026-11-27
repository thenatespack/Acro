// Generated from mesh_fur.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: b76619b2e051032d
// glsl-fnv1a64: dd5c39d1755d11cf

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
    var phi_3458_: bool;
    var phi_7567_: f32;
    var phi_7566_: f32;
    var phi_7605_: f32;
    var phi_7602_: f32;
    var phi_7606_: f32;
    var phi_7604_: f32;
    var phi_7603_: f32;
    var phi_7600_: f32;
    var phi_7597_: f32;
    var phi_7601_: f32;
    var phi_7599_: f32;
    var phi_7598_: f32;
    var phi_7629_: f32;
    var phi_7570_: vec3<f32>;
    var phi_7564_: f32;
    var phi_7568_: f32;
    var phi_7644_: f32;
    var phi_7591_: f32;
    var phi_7585_: f32;
    var phi_7572_: vec3<f32>;
    var phi_7574_: vec3<f32>;
    var phi_7578_: vec3<f32>;
    var phi_7579_: vec3<f32>;
    var phi_7614_: f32;
    var phi_7580_: f32;
    var phi_7619_: f32;
    var phi_7611_: f32;
    var phi_7596_: f32;
    var phi_7636_: f32;
    var phi_7620_: f32;
    var phi_7618_: f32;
    var phi_7608_: f32;
    var phi_7607_: f32;
    var local_9: bool;
    var phi_2748_: bool;
    var phi_7652_: f32;
    var phi_7653_: vec2<f32>;
    var phi_7656_: f32;
    var phi_7655_: f32;
    var phi_7657_: f32;
    var phi_7658_: f32;
    var phi_7739_: f32;
    var phi_2997_: bool;
    var phi_7662_: vec3<f32>;
    var phi_7663_: i32;
    var phi_5214_: bool;
    var local_10: i32;
    var local_11: i32;
    var local_12: i32;
    var phi_5335_: bool;
    var phi_5342_: bool;
    var phi_5349_: bool;
    var local_13: i32;
    var local_14: i32;
    var local_15: i32;
    var phi_7665_: f32;
    var local_16: i32;
    var local_17: i32;
    var local_18: i32;
    var phi_5499_: bool;
    var phi_5506_: bool;
    var phi_5513_: bool;
    var phi_7670_: f32;
    var phi_7683_: f32;
    var phi_7680_: vec3<f32>;
    var phi_7682_: f32;
    var phi_7679_: vec3<f32>;
    var phi_7685_: vec3<f32>;
    var phi_7684_: f32;
    var phi_7732_: f32;
    var phi_7731_: vec3<f32>;
    var phi_7733_: f32;
    var phi_7756_: vec3<f32>;
    var phi_7755_: i32;
    var local_19: vec3<f32>;
    var phi_7757_: vec3<f32>;
    var phi_7769_: vec3<f32>;
    var phi_7765_: u32;
    var phi_6378_: bool;
    var phi_6385_: bool;
    var phi_6392_: bool;
    var phi_6399_: bool;
    var phi_7823_: f32;
    var phi_7820_: i32;
    var phi_7829_: f32;
    var phi_7826_: i32;
    var local_20: f32;
    var phi_7830_: f32;
    var phi_6469_: bool;
    var phi_7808_: i32;
    var phi_7807_: i32;
    var phi_7805_: f32;
    var phi_7812_: f32;
    var phi_7809_: i32;
    var phi_7818_: f32;
    var phi_7815_: i32;
    var local_21: f32;
    var phi_7819_: f32;
    var phi_7831_: f32;
    var phi_7832_: f32;
    var phi_7868_: f32;
    var phi_7768_: vec3<f32>;
    var phi_7766_: f32;
    var phi_7771_: f32;
    var phi_7772_: vec3<f32>;
    var phi_7801_: vec2<f32>;
    var local_22: vec3<f32>;
    var local_23: f32;
    var local_24: f32;
    var local_25: vec3<f32>;

    let _e226 = global_13[0u];
    let _e228 = global_13[2u];
    let _e229 = (_e228 > 0.5f);
    phi_2672_ = _e229;
    if _e229 {
        phi_2672_ = (_e228 < 1.5f);
    }
    let _e232 = phi_2672_;
    let _e233 = (_e228 > 1.5f);
    let _e235 = global_13[3u];
    let _e236 = (_e235 > 0.5f);
    let _e239 = global_12.member_1[0i];
    let _e242 = global_12.member_1[2i];
    let _e244 = global.member_6;
    let _e245 = _e244.xyz;
    let _e246 = global_6;
    let _e247 = (_e245 - _e246);
    let _e248 = normalize(_e247);
    let _e249 = dpdx(_e246);
    let _e250 = dpdy(_e246);
    let _e251 = cross(_e249, _e250);
    switch bitcast<i32>(0u) {
        default: {
            phi_3458_ = _e229;
            if _e229 {
                phi_3458_ = (_e228 < 1.5f);
            }
            let _e255 = phi_3458_;
            let _e258 = global_12.member_1[1i];
            let _e259 = global_14;
            let _e260 = dpdx(_e259);
            let _e261 = dpdy(_e259);
            let _e263 = global_15[0u];
            let _e264 = dpdx(_e263);
            let _e265 = dpdy(_e263);
            let _e266 = vec2<f32>(_e264, _e265);
            let _e270 = global_12.member_1[6i][2u];
            let _e272 = !(_e233);
            phi_7566_ = 1f;
            local_9 = _e272;
            if ((_e270 > 0.5f) && _e272) {
                let _e274 = global_15;
                let _e275 = textureSample(global_16, global_4, _e274);
                let _e280 = global_12.member_1[6i][3u];
                phi_7567_ = _e275.x;
                if (_e280 > 0.5f) {
                    phi_7567_ = (1f - _e275.x);
                }
                let _e284 = phi_7567_;
                phi_7566_ = _e284;
            }
            let _e286 = phi_7566_;
            if _e236 {
                if (_e286 < 0.02f) {
                    phi_7636_ = 0f;
                    phi_7620_ = 0f;
                    phi_7618_ = 0.5f;
                    phi_7608_ = 0f;
                    phi_7607_ = 0f;
                    break;
                }
                let _e295 = bitcast<vec3<u32>>((vec3<i32>(floor((_e259 / vec3(max(_e239.y, 0.00001f))))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e303 = (((_e295.x * 1597334677u) ^ (_e295.y * 3812015801u)) ^ (_e295.z * 2798796415u));
                let _e307 = ((_e303 ^ (_e303 >> bitcast<u32>(15i))) * 2246822519u);
                let _e311 = ((_e307 ^ (_e307 >> bitcast<u32>(13i))) * 3266489917u);
                let _e315 = ((_e311 ^ (_e311 >> bitcast<u32>(16i))) * 668265263u);
                phi_7636_ = 0f;
                phi_7620_ = 0f;
                phi_7618_ = (vec3<f32>(f32(), f32(), f32(((_e315 ^ (_e315 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).z;
                phi_7608_ = 0f;
                phi_7607_ = 1f;
                break;
            }
            if _e255 {
                let _e327 = global_12.member_1[4i][3u];
                let _e328 = max(_e327, 1f);
                let _e329 = (_e263 * _e328);
                let _e331 = (length(_e266) * _e328);
                let _e333 = global_13[1u];
                let _e337 = smoothstep(0.45f, 1.3f, _e331);
                let _e349 = ((min(mix(_e239.z, _e239.w, _e226), 1f) * clamp(((1f - _e226) / max(_e242.y, 0.02f)), 0f, 1f)) * (1f - smoothstep(0.75f, 1f, _e226)));
                phi_7606_ = 0.5f;
                phi_7604_ = _e226;
                phi_7603_ = _e349;
                if (_e337 < 0.999f) {
                    let _e355 = bitcast<vec3<u32>>((vec3<i32>(vec3<f32>(floor(_e329), floor((_e333 * 65535f)), 7f)) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e363 = (((_e355.x * 1597334677u) ^ (_e355.y * 3812015801u)) ^ (_e355.z * 2798796415u));
                    let _e367 = ((_e363 ^ (_e363 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e370 = (_e367 ^ (_e367 >> bitcast<u32>(13i)));
                    let _e371 = (_e370 * 3266489917u);
                    let _e374 = (_e371 ^ (_e371 >> bitcast<u32>(16i)));
                    let _e375 = (_e374 * 668265263u);
                    let _e386 = (vec3<f32>(f32((_e370 & 65535u)), f32((_e374 & 65535u)), f32(((_e375 ^ (_e375 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                    let _e396 = (1f - (_e242.y * _e386.y));
                    phi_7605_ = _e226;
                    phi_7602_ = 0f;
                    if (_e226 <= _e396) {
                        let _e399 = (_e226 / max(_e396, 0.001f));
                        let _e401 = (mix(_e239.z, _e239.w, _e399) * 0.5f);
                        let _e403 = (0.5f * max(_e331, 0.0001f));
                        let _e404 = max(_e401, _e403);
                        phi_7605_ = mix(_e399, _e226, _e337);
                        phi_7602_ = (((1f - smoothstep((_e404 - _e403), (_e404 + _e403), abs(((fract(_e329) - 0.5f) + ((_e386.x - 0.5f) * 0.3f))))) * (_e401 / _e404)) * (1f - smoothstep(0.75f, 1f, _e399)));
                    }
                    let _e416 = phi_7605_;
                    let _e418 = phi_7602_;
                    phi_7606_ = mix(_e386.z, 0.5f, _e337);
                    phi_7604_ = _e416;
                    phi_7603_ = mix(_e418, _e349, _e337);
                }
                let _e423 = phi_7606_;
                let _e425 = phi_7604_;
                let _e427 = phi_7603_;
                phi_7636_ = 0f;
                phi_7620_ = 0f;
                phi_7618_ = _e423;
                phi_7608_ = _e425;
                phi_7607_ = _e427;
                break;
            }
            if _e233 {
                let _e428 = length(_e266);
                let _e430 = max(_e242.y, 0.3f);
                let _e431 = smoothstep(0.45f, 1.3f, _e428);
                let _e443 = ((min(mix(_e239.z, _e239.w, _e226), 1f) * clamp(((1f - _e226) / max(_e430, 0.02f)), 0f, 1f)) * (1f - smoothstep(0.75f, 1f, _e226)));
                phi_7601_ = 0.5f;
                phi_7599_ = _e226;
                phi_7598_ = _e443;
                if (_e431 < 0.999f) {
                    let _e449 = bitcast<vec3<u32>>((vec3<i32>(vec3<f32>(floor(_e263), 3f, 7f)) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e457 = (((_e449.x * 1597334677u) ^ (_e449.y * 3812015801u)) ^ (_e449.z * 2798796415u));
                    let _e461 = ((_e457 ^ (_e457 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e464 = (_e461 ^ (_e461 >> bitcast<u32>(13i)));
                    let _e465 = (_e464 * 3266489917u);
                    let _e468 = (_e465 ^ (_e465 >> bitcast<u32>(16i)));
                    let _e469 = (_e468 * 668265263u);
                    let _e480 = (vec3<f32>(f32((_e464 & 65535u)), f32((_e468 & 65535u)), f32(((_e469 ^ (_e469 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                    let _e490 = (1f - (_e430 * _e480.y));
                    phi_7600_ = _e226;
                    phi_7597_ = 0f;
                    if (_e226 <= _e490) {
                        let _e493 = (_e226 / max(_e490, 0.001f));
                        let _e495 = (mix(_e239.z, _e239.w, _e493) * 0.5f);
                        let _e497 = (0.5f * max(_e428, 0.0001f));
                        let _e498 = max(_e495, _e497);
                        phi_7600_ = mix(_e493, _e226, _e431);
                        phi_7597_ = (((1f - smoothstep((_e498 - _e497), (_e498 + _e497), abs(((fract(_e263) - 0.5f) + ((_e480.x - 0.5f) * 0.3f))))) * (_e495 / _e498)) * (1f - smoothstep(0.75f, 1f, _e493)));
                    }
                    let _e510 = phi_7600_;
                    let _e512 = phi_7597_;
                    phi_7601_ = mix(_e480.z, 0.5f, _e431);
                    phi_7599_ = _e510;
                    phi_7598_ = mix(_e512, _e443, _e431);
                }
                let _e517 = phi_7601_;
                let _e519 = phi_7599_;
                let _e521 = phi_7598_;
                phi_7636_ = 0f;
                phi_7620_ = 0f;
                phi_7618_ = _e517;
                phi_7608_ = _e519;
                phi_7607_ = (((_e521 * 0.6f) * smoothstep(0f, 0.35f, _e226)) * (1f - smoothstep(0.3f, 0.9f, _e428)));
                break;
            }
            let _e529 = max(_e239.y, 0.00001f);
            let _e530 = global_17;
            let _e531 = normalize(_e530);
            phi_7629_ = 0f;
            phi_7570_ = _e259;
            phi_7564_ = 1f;
            if (_e258.x > 0f) {
                let _e534 = (_e529 * 4f);
                let _e537 = floor((_e259 / vec3(_e534)));
                let _e542 = bitcast<vec3<u32>>((vec3<i32>((_e537 + vec3<f32>(31f, 17f, 5f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e550 = (((_e542.x * 1597334677u) ^ (_e542.y * 3812015801u)) ^ (_e542.z * 2798796415u));
                let _e554 = ((_e550 ^ (_e550 >> bitcast<u32>(15i))) * 2246822519u);
                let _e557 = (_e554 ^ (_e554 >> bitcast<u32>(13i)));
                let _e558 = (_e557 * 3266489917u);
                let _e561 = (_e558 ^ (_e558 >> bitcast<u32>(16i)));
                let _e562 = (_e561 * 668265263u);
                let _e577 = (((_e537 + vec3<f32>(0.5f, 0.5f, 0.5f)) + (((vec3<f32>(f32((_e557 & 65535u)), f32((_e561 & 65535u)), f32(((_e562 ^ (_e562 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)) - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.6f)) * _e534);
                let _e581 = (_e577 - (_e531 * dot((_e577 - _e259), _e531)));
                let _e582 = (_e259 - _e581);
                let _e591 = (1f / (1f - min(((_e258.x * _e226) * 0.85f), 0.9f)));
                phi_7629_ = (_e258.x * smoothstep(0.15f, 0.6f, (length(_e582) / _e534)));
                phi_7570_ = (_e581 + (_e582 * _e591));
                phi_7564_ = _e591;
            }
            let _e595 = phi_7629_;
            let _e597 = phi_7570_;
            let _e599 = phi_7564_;
            let _e603 = ((_e260 - (_e531 * dot(_e260, _e531))) * _e599);
            let _e607 = ((_e261 - (_e531 * dot(_e261, _e531))) * _e599);
            let _e612 = (sqrt(max(dot(_e603, _e603), dot(_e607, _e607))) / _e529);
            let _e613 = smoothstep(0.6f, 1.6f, _e612);
            let _e614 = min(_e286, 1f);
            let _e617 = mix(_e239.z, _e239.w, _e226);
            phi_7644_ = 0f;
            phi_7591_ = 0.5f;
            phi_7585_ = 0f;
            if ((_e613 > 0.001f) && (_e614 > 0.01f)) {
                let _e623 = smoothstep(2f, 5f, _e612);
                if (_e613 >= 1f) {
                    phi_7568_ = (1f + step(1f, _e623));
                } else {
                    phi_7568_ = 0f;
                }
                let _e628 = phi_7568_;
                let _e631 = (_e259 / vec3((_e529 * 3f)));
                let _e632 = floor(_e631);
                let _e633 = (_e631 - _e632);
                let _e637 = ((_e633 * _e633) * (vec3<f32>(3f, 3f, 3f) - (_e633 * 2f)));
                let _e640 = bitcast<vec3<u32>>((vec3<i32>(_e632) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e648 = (((_e640.x * 1597334677u) ^ (_e640.y * 3812015801u)) ^ (_e640.z * 2798796415u));
                let _e652 = ((_e648 ^ (_e648 >> bitcast<u32>(15i))) * 2246822519u);
                let _e655 = (_e652 ^ (_e652 >> bitcast<u32>(13i)));
                let _e656 = (_e655 * 3266489917u);
                let _e670 = bitcast<vec3<u32>>((vec3<i32>((_e632 + vec3<f32>(1f, 0f, 0f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e678 = (((_e670.x * 1597334677u) ^ (_e670.y * 3812015801u)) ^ (_e670.z * 2798796415u));
                let _e682 = ((_e678 ^ (_e678 >> bitcast<u32>(15i))) * 2246822519u);
                let _e685 = (_e682 ^ (_e682 >> bitcast<u32>(13i)));
                let _e686 = (_e685 * 3266489917u);
                let _e698 = vec2(_e637.x);
                let _e703 = bitcast<vec3<u32>>((vec3<i32>((_e632 + vec3<f32>(0f, 1f, 0f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e711 = (((_e703.x * 1597334677u) ^ (_e703.y * 3812015801u)) ^ (_e703.z * 2798796415u));
                let _e715 = ((_e711 ^ (_e711 >> bitcast<u32>(15i))) * 2246822519u);
                let _e718 = (_e715 ^ (_e715 >> bitcast<u32>(13i)));
                let _e719 = (_e718 * 3266489917u);
                let _e733 = bitcast<vec3<u32>>((vec3<i32>((_e632 + vec3<f32>(1f, 1f, 0f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e741 = (((_e733.x * 1597334677u) ^ (_e733.y * 3812015801u)) ^ (_e733.z * 2798796415u));
                let _e745 = ((_e741 ^ (_e741 >> bitcast<u32>(15i))) * 2246822519u);
                let _e748 = (_e745 ^ (_e745 >> bitcast<u32>(13i)));
                let _e749 = (_e748 * 3266489917u);
                let _e762 = vec2(_e637.y);
                let _e767 = bitcast<vec3<u32>>((vec3<i32>((_e632 + vec3<f32>(0f, 0f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e775 = (((_e767.x * 1597334677u) ^ (_e767.y * 3812015801u)) ^ (_e767.z * 2798796415u));
                let _e779 = ((_e775 ^ (_e775 >> bitcast<u32>(15i))) * 2246822519u);
                let _e782 = (_e779 ^ (_e779 >> bitcast<u32>(13i)));
                let _e783 = (_e782 * 3266489917u);
                let _e797 = bitcast<vec3<u32>>((vec3<i32>((_e632 + vec3<f32>(1f, 0f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e805 = (((_e797.x * 1597334677u) ^ (_e797.y * 3812015801u)) ^ (_e797.z * 2798796415u));
                let _e809 = ((_e805 ^ (_e805 >> bitcast<u32>(15i))) * 2246822519u);
                let _e812 = (_e809 ^ (_e809 >> bitcast<u32>(13i)));
                let _e813 = (_e812 * 3266489917u);
                let _e828 = bitcast<vec3<u32>>((vec3<i32>((_e632 + vec3<f32>(0f, 1f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e836 = (((_e828.x * 1597334677u) ^ (_e828.y * 3812015801u)) ^ (_e828.z * 2798796415u));
                let _e840 = ((_e836 ^ (_e836 >> bitcast<u32>(15i))) * 2246822519u);
                let _e843 = (_e840 ^ (_e840 >> bitcast<u32>(13i)));
                let _e844 = (_e843 * 3266489917u);
                let _e858 = bitcast<vec3<u32>>((vec3<i32>((_e632 + vec3<f32>(1f, 1f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e866 = (((_e858.x * 1597334677u) ^ (_e858.y * 3812015801u)) ^ (_e858.z * 2798796415u));
                let _e870 = ((_e866 ^ (_e866 >> bitcast<u32>(15i))) * 2246822519u);
                let _e873 = (_e870 ^ (_e870 >> bitcast<u32>(13i)));
                let _e874 = (_e873 * 3266489917u);
                let _e889 = mix(mix(mix((vec3<f32>(f32((_e655 & 65535u)), f32(((_e656 ^ (_e656 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32((_e685 & 65535u)), f32(((_e686 ^ (_e686 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e698), mix((vec3<f32>(f32((_e718 & 65535u)), f32(((_e719 ^ (_e719 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32((_e748 & 65535u)), f32(((_e749 ^ (_e749 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e698), _e762), mix(mix((vec3<f32>(f32((_e782 & 65535u)), f32(((_e783 ^ (_e783 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32((_e812 & 65535u)), f32(((_e813 ^ (_e813 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e698), mix((vec3<f32>(f32((_e843 & 65535u)), f32(((_e844 ^ (_e844 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32((_e873 & 65535u)), f32(((_e874 ^ (_e874 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e698), _e762), vec2(_e637.z));
                let _e896 = (_e226 / _e614);
                phi_7644_ = _e628;
                phi_7591_ = mix(_e889.y, 0.5f, _e623);
                phi_7585_ = ((0.7853982f * (_e617 * _e617)) * mix(clamp(((((1f - (_e242.y * _e889.x)) - _e896) / max((_e242.y * 0.35f), 0.04f)) + 0.5f), 0f, 1f), clamp(((1f - _e896) / max(_e242.y, 0.02f)), 0f, 1f), _e623));
            }
            let _e910 = phi_7644_;
            let _e912 = phi_7591_;
            let _e914 = phi_7585_;
            phi_7619_ = _e912;
            phi_7611_ = _e226;
            phi_7596_ = _e914;
            if (_e613 < 0.999f) {
                let _e918 = floor((_e597 / vec3(_e529)));
                let _e921 = bitcast<vec3<u32>>((vec3<i32>(_e918) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e929 = (((_e921.x * 1597334677u) ^ (_e921.y * 3812015801u)) ^ (_e921.z * 2798796415u));
                let _e933 = ((_e929 ^ (_e929 >> bitcast<u32>(15i))) * 2246822519u);
                let _e936 = (_e933 ^ (_e933 >> bitcast<u32>(13i)));
                let _e937 = (_e936 * 3266489917u);
                let _e940 = (_e937 ^ (_e937 >> bitcast<u32>(16i)));
                let _e941 = (_e940 * 668265263u);
                let _e952 = (vec3<f32>(f32((_e936 & 65535u)), f32((_e940 & 65535u)), f32(((_e941 ^ (_e941 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                let _e957 = (((_e918 + vec3<f32>(0.5f, 0.5f, 0.5f)) + ((_e952 - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.5f)) * _e529);
                if (abs(_e531.y) < 0.9f) {
                    phi_7572_ = cross(_e531, vec3<f32>(0f, 1f, 0f));
                } else {
                    phi_7572_ = cross(_e531, vec3<f32>(1f, 0f, 0f));
                }
                let _e964 = phi_7572_;
                let _e965 = normalize(_e964);
                phi_7574_ = _e957;
                if (_e258.y > 0f) {
                    let _e972 = ((_e226 * 12.566f) + (_e952.x * 6.283f));
                    phi_7574_ = (_e957 + (((_e965 * cos(_e972)) + (cross(_e531, _e965) * sin(_e972))) * ((_e258.y * 0.3f) * _e529)));
                }
                let _e983 = phi_7574_;
                phi_7578_ = _e983;
                if (_e258.z > 0f) {
                    let _e986 = (_e226 * 4f);
                    let _e988 = (floor(_e986) * 7f);
                    let _e993 = bitcast<vec3<u32>>((vec3<i32>((_e918 + vec3<f32>(_e988, 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e1001 = (((_e993.x * 1597334677u) ^ (_e993.y * 3812015801u)) ^ (_e993.z * 2798796415u));
                    let _e1005 = ((_e1001 ^ (_e1001 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e1008 = (_e1005 ^ (_e1005 >> bitcast<u32>(13i)));
                    let _e1009 = (_e1008 * 3266489917u);
                    let _e1012 = (_e1009 ^ (_e1009 >> bitcast<u32>(16i)));
                    let _e1013 = (_e1012 * 668265263u);
                    let _e1030 = bitcast<vec3<u32>>((vec3<i32>((_e918 + vec3<f32>((_e988 + 7f), 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e1038 = (((_e1030.x * 1597334677u) ^ (_e1030.y * 3812015801u)) ^ (_e1030.z * 2798796415u));
                    let _e1042 = ((_e1038 ^ (_e1038 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e1045 = (_e1042 ^ (_e1042 >> bitcast<u32>(13i)));
                    let _e1046 = (_e1045 * 3266489917u);
                    let _e1049 = (_e1046 ^ (_e1046 >> bitcast<u32>(16i)));
                    let _e1050 = (_e1049 * 668265263u);
                    phi_7578_ = (_e983 + ((mix((vec3<f32>(f32((_e1008 & 65535u)), f32((_e1012 & 65535u)), f32(((_e1013 ^ (_e1013 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), (vec3<f32>(f32((_e1045 & 65535u)), f32((_e1049 & 65535u)), f32(((_e1050 ^ (_e1050 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), vec3(smoothstep(0f, 1f, fract(_e986)))) - vec3<f32>(0.5f, 0.5f, 0.5f)) * (((_e258.z * 0.4f) * _e529) * _e226)));
                }
                let _e1073 = phi_7578_;
                let _e1074 = (_e597 - _e1073);
                let _e1077 = (_e1074 - (_e531 * dot(_e1074, _e531)));
                let _e1082 = ((1f - (_e242.y * _e952.y)) * _e614);
                phi_7614_ = _e226;
                phi_7580_ = 0f;
                if (_e226 <= _e1082) {
                    let _e1085 = (_e226 / max(_e1082, 0.001f));
                    let _e1088 = ((mix(_e239.z, _e239.w, _e1085) * 0.5f) * _e529);
                    let _e1089 = length(_e1077);
                    if (_e1089 > 0.000000001f) {
                        phi_7579_ = (_e1077 / vec3(_e1089));
                    } else {
                        phi_7579_ = _e965;
                    }
                    let _e1094 = phi_7579_;
                    let _e1095 = dot(_e603, _e1094);
                    let _e1097 = dot(_e607, _e1094);
                    let _e1103 = (0.5f * max(sqrt(((_e1095 * _e1095) + (_e1097 * _e1097))), (_e529 * 0.001f)));
                    let _e1104 = max(_e1088, _e1103);
                    let _e1105 = (_e1088 / _e1104);
                    phi_7614_ = mix(_e1085, _e226, _e613);
                    phi_7580_ = (((1f - smoothstep((_e1104 - _e1103), (_e1104 + _e1103), _e1089)) * _e1105) * _e1105);
                }
                let _e1114 = phi_7614_;
                let _e1116 = phi_7580_;
                phi_7619_ = mix(_e952.z, _e912, _e613);
                phi_7611_ = _e1114;
                phi_7596_ = mix(_e1116, _e914, _e613);
            }
            let _e1121 = phi_7619_;
            let _e1123 = phi_7611_;
            let _e1125 = phi_7596_;
            phi_7636_ = _e910;
            phi_7620_ = _e595;
            phi_7618_ = _e1121;
            phi_7608_ = _e1123;
            phi_7607_ = _e1125;
            break;
        }
    }
    let _e1127 = phi_7636_;
    let _e1129 = phi_7620_;
    let _e1131 = phi_7618_;
    let _e1133 = phi_7608_;
    let _e1135 = phi_7607_;
    let _e1137 = global_18[3u];
    let _e1138 = !(_e232);
    let _e1140 = local_9;
    let _e1147 = ((((_e1138 && _e1140) && !(_e236)) && (_e1127 > 0.5f)) && (_e1137 >= 8f));
    phi_2748_ = _e1147;
    if _e1147 {
        let _e1148 = global_19;
        phi_2748_ = (abs(dot(normalize(_e1148), _e248)) > 0.45f);
    }
    let _e1154 = phi_2748_;
    phi_7652_ = _e1135;
    if _e1154 {
        let _e1158 = select(2f, 4f, ((_e1127 > 1.5f) && (_e1137 >= 16f)));
        let _e1161 = floor(((_e226 * _e1137) + 0.5f));
        if ((_e1161 - (floor((_e1161 / _e1158)) * _e1158)) > 0.5f) {
            discard;
        }
        phi_7652_ = (1f - pow((1f - min(_e1135, 0.999f)), _e1158));
    }
    let _e1172 = phi_7652_;
    if _e232 {
        let _e1173 = global_19;
        let _e1183 = global_12.member_1[7i][0u];
        let _e1184 = clamp(_e1183, 1f, 8f);
        let _e1185 = global_9;
        if (_e1184 < 1.5f) {
            let _e1191 = global_12.member_1[7i][1u];
            phi_7653_ = (vec2<f32>(5.588238f, 3.1416f) * _e1191);
        } else {
            phi_7653_ = vec2<f32>(0f, 0f);
        }
        let _e1194 = phi_7653_;
        let _e1204 = global_13[1u];
        if (floor((((_e1172 * mix(0.35f, 1f, smoothstep(0.03f, 0.3f, abs(dot(normalize(_e1173), _e248))))) * _e1184) + fract(((fract((52.982918f * fract(dot((_e1185.xy + _e1194), vec2<f32>(0.06711056f, 0.00583715f))))) + (_e1131 * 0.618034f)) + (_e1204 * 0.414214f))))) < 0.5f) {
            discard;
        }
        phi_7655_ = 1f;
    } else {
        phi_7656_ = _e1172;
        if _e233 {
            let _e1211 = global_19;
            phi_7656_ = (_e1172 * (smoothstep(0.72f, 0.95f, (1f - abs(dot(normalize(_e1211), _e248)))) * smoothstep(0.08f, 0.35f, abs(dot((_e251 * inverseSqrt(max(dot(_e251, _e251), 0.00000000000000000001f))), _e248)))));
        }
        let _e1227 = phi_7656_;
        phi_7655_ = _e1227;
    }
    let _e1229 = phi_7655_;
    if (_e1229 < 0.004f) {
        discard;
    }
    let _e1233 = global_12.member_1[3i];
    let _e1237 = global_12.member_1[4i];
    let _e1239 = (_e1131 - 0.5f);
    let _e1249 = global_18;
    let _e1251 = ((mix(_e1233.xyz, _e1237.xyz, vec3(pow(_e1133, 0.8f))) * max((1f + ((_e1239 * 2f) * _e242.z)), 0f)) * _e1249.xyz);
    if _e232 {
        phi_7657_ = 3f;
    } else {
        phi_7657_ = (((_e239.x * (_e239.z + _e239.w)) * 0.5f) / max(_e239.y, 0.00001f));
    }
    let _e1262 = phi_7657_;
    let _e1268 = (1f - exp(((_e1262 * (1f - (0.6f * _e1129))) * -0.2f)));
    if _e236 {
        phi_7658_ = 1f;
    } else {
        phi_7658_ = (1f - select(_e226, _e1133, _e232));
    }
    let _e1273 = phi_7658_;
    let _e1282 = max(mix(exp(((_e1268 * -2.5f) * _e1273)), 1f, (0.3f * sqrt(clamp(dot(_e1251, vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0f, 1f)))), 0.12f);
    phi_7739_ = _e1282;
    if _e232 {
        phi_7739_ = (_e1282 * mix(0.85f, 1f, _e1131));
    }
    let _e1286 = phi_7739_;
    let _e1287 = global_19;
    let _e1288 = normalize(_e1287);
    phi_2997_ = _e232;
    if _e232 {
        let _e1289 = global_20;
        phi_2997_ = !(_e1289);
    }
    let _e1292 = phi_2997_;
    phi_7662_ = _e1288;
    if _e1292 {
        phi_7662_ = -(_e1288);
    }
    let _e1295 = phi_7662_;
    let _e1296 = global_21;
    let _e1297 = normalize(_e1296);
    let _e1299 = global.member_4;
    let _e1301 = normalize(_e1299.xyz);
    let _e1303 = global_22[0u];
    let _e1304 = (_e1303 > 0.5f);
    let _e1309 = clamp(((_e239.x * 2f) / max((5f * _e1268), 1f)), 0.004f, 0.06f);
    let _e1312 = global.member_5[3u];
    phi_7732_ = 1f;
    phi_7731_ = _e1251;
    if ((_e1312 > 0.5f) && _e1304) {
        switch bitcast<i32>(0u) {
            default: {
                let _e1318 = global.member_21[0u];
                let _e1319 = i32(_e1318);
                let _e1321 = global.member_20;
                let _e1326 = global.member_20[3u];
                let _e1327 = (dot(_e1321.xyz, _e246) + _e1326);
                phi_7663_ = 0i;
                loop {
                    let _e1329 = phi_7663_;
                    local_10 = _e1329;
                    local_11 = _e1329;
                    local_12 = _e1329;
                    local_13 = _e1329;
                    local_14 = _e1329;
                    local_15 = _e1329;
                    local_16 = _e1329;
                    local_17 = _e1329;
                    local_18 = _e1329;
                    let _e1331 = (_e1329 < (_e1319 - 1i));
                    phi_5214_ = _e1331;
                    if _e1331 {
                        let _e1334 = global.member_16[_e1329];
                        phi_5214_ = (_e1327 > _e1334);
                    }
                    let _e1337 = phi_5214_;
                    if _e1337 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_7663_ = (_e1329 + 1i);
                    }
                }
                let _e1341 = local_10;
                let _e1343 = global.member_16[_e1341];
                if (_e1327 > _e1343) {
                    phi_7685_ = vec3<f32>(1f, 1f, 1f);
                    phi_7684_ = 1f;
                    break;
                }
                let _e1347 = local_11;
                let _e1349 = global.member_18[_e1347];
                let _e1351 = (_e246 + (_e1295 * _e1349));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e1355 = local_12;
                        let _e1357 = global.member_14[_e1355];
                        let _e1362 = (_e1357 * vec4<f32>(_e1351.x, _e1351.y, _e1351.z, 1f));
                        let _e1364 = (_e1362.x < 0f);
                        phi_5335_ = _e1364;
                        if !(_e1364) {
                            phi_5335_ = (_e1362.x > 1f);
                        }
                        let _e1368 = phi_5335_;
                        phi_5342_ = _e1368;
                        if !(_e1368) {
                            phi_5342_ = (_e1362.y < 0f);
                        }
                        let _e1373 = phi_5342_;
                        phi_5349_ = _e1373;
                        if !(_e1373) {
                            phi_5349_ = (_e1362.y > 1f);
                        }
                        let _e1378 = phi_5349_;
                        if _e1378 {
                            phi_7665_ = 1f;
                            break;
                        }
                        let _e1380 = local_13;
                        let _e1384 = local_14;
                        let _e1390 = global.member_23;
                        let _e1391 = _e1390.xy;
                        let _e1392 = (vec2<f32>(f32((_e1380 & 1i)), f32((_e1384 >> bitcast<u32>(1i)))) * _e1391);
                        let _e1397 = local_15;
                        let _e1399 = global.member_19[_e1397];
                        let _e1400 = (min(_e1362.z, 1f) - _e1399);
                        let _e1409 = (_e1309 * length(vec3<f32>(_e1357[0].z, _e1357[1].z, _e1357[2].z)));
                        let _e1411 = global.member_22;
                        let _e1412 = _e1411.xy;
                        let _e1413 = (_e1412 * 0.5f);
                        let _e1414 = (_e1392 + _e1413);
                        let _e1416 = ((_e1392 + _e1391) - _e1413);
                        let _e1419 = (_e1392 + (_e1362.xy * _e1391));
                        let _e1422 = clamp((_e1419 + (_e1412 * vec2<f32>(0f, 0.85f))), _e1414, _e1416);
                        let _e1424 = (_e1400 - (_e1409 * 0.18f));
                        let _e1429 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1422.x, _e1422.y, _e1424).xy, _e1424);
                        let _e1432 = clamp((_e1419 + (_e1412 * vec2<f32>(-0.74f, -0.43f))), _e1414, _e1416);
                        let _e1434 = (_e1400 - (_e1409 * 0.69f));
                        let _e1439 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1432.x, _e1432.y, _e1434).xy, _e1434);
                        let _e1443 = clamp((_e1419 + (_e1412 * vec2<f32>(0.74f, -0.43f))), _e1414, _e1416);
                        let _e1445 = (_e1400 - (_e1409 * 1.79f));
                        let _e1450 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1443.x, _e1443.y, _e1445).xy, _e1445);
                        phi_7665_ = (((_e1429 + _e1439) + _e1450) * 0.33333334f);
                        break;
                    }
                }
                let _e1454 = phi_7665_;
                local_7 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e1456 = local_16;
                let _e1458 = local_7[_e1456];
                let _e1461 = local_17;
                let _e1463 = global.member_17[_e1461];
                phi_7682_ = _e1454;
                phi_7679_ = _e1458;
                if (_e1327 > _e1463) {
                    let _e1467 = ((_e1327 - _e1463) / (_e1343 - _e1463));
                    let _e1469 = local_18;
                    let _e1470 = (_e1469 + 1i);
                    if (_e1470 < _e1319) {
                        let _e1474 = global.member_18[_e1470];
                        let _e1476 = (_e246 + (_e1295 * _e1474));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1480 = global.member_14[_e1470];
                                let _e1485 = (_e1480 * vec4<f32>(_e1476.x, _e1476.y, _e1476.z, 1f));
                                let _e1487 = (_e1485.x < 0f);
                                phi_5499_ = _e1487;
                                if !(_e1487) {
                                    phi_5499_ = (_e1485.x > 1f);
                                }
                                let _e1491 = phi_5499_;
                                phi_5506_ = _e1491;
                                if !(_e1491) {
                                    phi_5506_ = (_e1485.y < 0f);
                                }
                                let _e1496 = phi_5506_;
                                phi_5513_ = _e1496;
                                if !(_e1496) {
                                    phi_5513_ = (_e1485.y > 1f);
                                }
                                let _e1501 = phi_5513_;
                                if _e1501 {
                                    phi_7670_ = 1f;
                                    break;
                                }
                                let _e1509 = global.member_23;
                                let _e1510 = _e1509.xy;
                                let _e1511 = (vec2<f32>(f32((_e1470 & 1i)), f32((_e1470 >> bitcast<u32>(1i)))) * _e1510);
                                let _e1516 = global.member_19[_e1470];
                                let _e1517 = (min(_e1485.z, 1f) - _e1516);
                                let _e1526 = (_e1309 * length(vec3<f32>(_e1480[0].z, _e1480[1].z, _e1480[2].z)));
                                let _e1528 = global.member_22;
                                let _e1529 = _e1528.xy;
                                let _e1530 = (_e1529 * 0.5f);
                                let _e1531 = (_e1511 + _e1530);
                                let _e1533 = ((_e1511 + _e1510) - _e1530);
                                let _e1536 = (_e1511 + (_e1485.xy * _e1510));
                                let _e1539 = clamp((_e1536 + (_e1529 * vec2<f32>(0f, 0.85f))), _e1531, _e1533);
                                let _e1541 = (_e1517 - (_e1526 * 0.18f));
                                let _e1546 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1539.x, _e1539.y, _e1541).xy, _e1541);
                                let _e1549 = clamp((_e1536 + (_e1529 * vec2<f32>(-0.74f, -0.43f))), _e1531, _e1533);
                                let _e1551 = (_e1517 - (_e1526 * 0.69f));
                                let _e1556 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1549.x, _e1549.y, _e1551).xy, _e1551);
                                let _e1560 = clamp((_e1536 + (_e1529 * vec2<f32>(0.74f, -0.43f))), _e1531, _e1533);
                                let _e1562 = (_e1517 - (_e1526 * 1.79f));
                                let _e1567 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1560.x, _e1560.y, _e1562).xy, _e1562);
                                phi_7670_ = (((_e1546 + _e1556) + _e1567) * 0.33333334f);
                                break;
                            }
                        }
                        let _e1571 = phi_7670_;
                        local_8 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1574 = local_8[_e1470];
                        phi_7683_ = mix(_e1454, _e1571, _e1467);
                        phi_7680_ = mix(_e1458, _e1574, vec3(_e1467));
                    } else {
                        phi_7683_ = mix(_e1454, 1f, _e1467);
                        phi_7680_ = _e1458;
                    }
                    let _e1579 = phi_7683_;
                    let _e1581 = phi_7680_;
                    phi_7682_ = _e1579;
                    phi_7679_ = _e1581;
                }
                let _e1583 = phi_7682_;
                let _e1585 = phi_7679_;
                let _e1588 = global.member_22[3u];
                phi_7685_ = select(vec3<f32>(1f, 1f, 1f), _e1585, vec3((_e1588 > 0.5f)));
                phi_7684_ = _e1583;
                break;
            }
        }
        let _e1593 = phi_7685_;
        let _e1595 = phi_7684_;
        phi_7732_ = _e1595;
        phi_7731_ = (_e1251 * _e1593);
    }
    let _e1598 = phi_7732_;
    let _e1600 = phi_7731_;
    let _e1602 = (0.06f + (_e1239 * 0.08f));
    let _e1603 = select(0.45f, 0.38f, _e232);
    let _e1606 = global.member_5;
    let _e1610 = global.member_4[3u];
    let _e1613 = clamp(dot(_e1297, _e1301), -1f, 1f);
    let _e1615 = clamp(dot(_e1297, _e248), -1f, 1f);
    let _e1616 = asin(_e1615);
    let _e1622 = max(cos((0.5f * abs((_e1616 - asin(_e1613))))), 0.05f);
    let _e1624 = (_e1301 - (_e1297 * _e1613));
    let _e1626 = (_e248 - (_e1297 * _e1615));
    let _e1629 = dot(_e1626, _e1626);
    let _e1633 = (dot(_e1624, _e1626) * inverseSqrt(max((dot(_e1624, _e1624) * _e1629), 0.000001f)));
    let _e1637 = sqrt(clamp((0.5f + (0.5f * _e1633)), 0f, 1f));
    let _e1638 = (_e1603 * _e1603);
    let _e1639 = (_e1613 + _e1615);
    let _e1640 = (2f * _e1602);
    let _e1641 = (_e1639 + _e1640);
    let _e1644 = (_e1638 * _e1638);
    let _e1645 = (1.9999615f * _e1644);
    let _e1648 = (_e1638 * 3.5448735f);
    let _e1658 = (1f - clamp(sqrt(clamp((0.5f + (0.5f * dot(_e1301, _e248))), 0f, 1f)), 0f, 1f));
    let _e1659 = (_e1658 * _e1658);
    let _e1668 = ((_e1638 * 0.5f) + 0.08f);
    let _e1669 = (_e1639 - _e1602);
    let _e1672 = (_e1668 * _e1668);
    let _e1675 = (2.5066283f * _e1668);
    let _e1681 = (_e1637 * (1f + (0.6451613f * (0.6f - (0.8f * _e1633)))));
    let _e1682 = (_e1681 * _e1681);
    let _e1688 = (1f - clamp((_e1622 * sqrt(clamp((1f - _e1682), 0f, 1f))), 0f, 1f));
    let _e1689 = (_e1688 * _e1688);
    let _e1693 = max(_e1600, vec3<f32>(0.0001f, 0.0001f, 0.0001f));
    let _e1705 = (0.95348f - (((0.95348f * _e1689) * _e1689) * _e1688));
    let _e1710 = (4f * _e1602);
    let _e1711 = (_e1639 - _e1710);
    let _e1714 = (7.999846f * _e1644);
    let _e1717 = (_e1638 * 7.089747f);
    let _e1721 = (1f - clamp((_e1622 * 0.5f), 0f, 1f));
    let _e1722 = (_e1721 * _e1721);
    let _e1725 = (((0.95348f * _e1722) * _e1722) * _e1721);
    let _e1734 = (0.95348f - _e1725);
    if _e1138 {
        let _e1744 = clamp(((dot(_e1295, _e1301) * 0.6f) + 0.4f), 0f, 1f);
        phi_7733_ = (_e1744 * _e1744);
    } else {
        phi_7733_ = mix(clamp(((dot((_e1626 * inverseSqrt(max(_e1629, 0.000001f))), _e1301) + 1f) * 0.5f), 0f, 1f), (1f - abs(_e1613)), 0.33f);
    }
    let _e1757 = phi_7733_;
    let _e1761 = (_e1693 / vec3(max(dot(_e1600, vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0.0001f)));
    let _e1766 = pow(_e1693, vec3<f32>(0.92f, 0.92f, 0.92f));
    let _e1769 = (_e242.w * 3.1415927f);
    let _e1774 = mix(0.5f, 1f, _e1286);
    let _e1778 = global.member_29[0u];
    if (_e1778 > 0.5f) {
        let _e1781 = global.member_29;
        let _e1788 = ((_e1781.z * _e1295.x) - (_e1781.w * _e1295.z));
        let _e1792 = ((_e1781.w * _e1295.x) + (_e1781.z * _e1295.z));
        let _e1796 = (1.092548f * _e1788);
        local_6 = array<f32, 9>(0.282095f, (0.488603f * _e1295.y), (0.488603f * _e1792), (0.488603f * _e1788), (_e1796 * _e1295.y), ((1.092548f * _e1295.y) * _e1792), (0.315392f * (((3f * _e1792) * _e1792) - 1f)), (_e1796 * _e1792), (0.546274f * ((_e1788 * _e1788) - (_e1295.y * _e1295.y))));
        phi_7756_ = vec3<f32>(0f, 0f, 0f);
        phi_7755_ = 0i;
        loop {
            let _e1811 = phi_7756_;
            let _e1813 = phi_7755_;
            local_19 = _e1811;
            if (_e1813 < 9i) {
                continue;
            } else {
                break;
            }
            continuing {
                let _e1817 = textureLoad(global_2, (vec2<i32>(496i, 256i) + vec2<i32>(_e1813, 0i)), 0i);
                let _e1820 = local_6[_e1813];
                phi_7756_ = (_e1811 + (_e1817.xyz * _e1820));
                phi_7755_ = (_e1813 + 1i);
            }
        }
        let _e1825 = local_19;
        let _e1829 = global.member_29[1u];
        phi_7757_ = (max(_e1825, vec3<f32>(0f, 0f, 0f)) * _e1829);
    } else {
        let _e1832 = global.member_9;
        let _e1835 = global.member_8;
        let _e1844 = global.member_8[3u];
        phi_7757_ = (mix(_e1832.xyz, _e1835.xyz, vec3(((_e1295.y * 0.5f) + 0.5f))) * _e1844);
    }
    let _e1847 = phi_7757_;
    let _e1850 = (((((((_e1766 * pow(_e1761, vec3(((1f - _e1598) * 0.35f)))) * _e1757) + (((vec3((((((exp((((-0.5f * _e1641) * _e1641) / _e1645)) / _e1648) * 0.25f) * _e1637) * (0.04652f + (((0.95348f * _e1659) * _e1659) * _e1658))) * 3f)) + (pow(_e1693, vec3((sqrt(clamp((1f - (_e1682 * 0.41623306f)), 0f, 1f)) / _e1622))) * ((((exp((((-0.5f * _e1669) * _e1669) / _e1672)) / _e1675) * exp(((-3.65f * _e1633) - 3.98f))) * _e1705) * _e1705))) + ((pow(_e1693, vec3((0.8f / _e1622))) * (((((exp((((-0.5f * _e1711) * _e1711) / _e1714)) / _e1717) * exp(((17f * _e1633) - 16.78f))) * _e1734) * _e1734) * (0.04652f + _e1725))) * 4f)) * _e1769)) * (_e1606.xyz * _e1610)) * _e1598) * _e1774) + ((_e1600 * _e1847) * _e1286));
    let _e1853 = global.member_13[3u];
    phi_7768_ = _e1850;
    if (_e1853 > 0.5f) {
        let _e1856 = global.member_11;
        let _e1861 = global.member_11[3u];
        let _e1863 = global_9;
        let _e1866 = global.member_12;
        let _e1871 = global.member_13;
        let _e1874 = clamp(floor((_e1863.xy * _e1866.xy)), vec2<f32>(0f, 0f), (_e1871.xy - vec2<f32>(1f, 1f)));
        let _e1879 = global.member_12[2u];
        let _e1883 = global.member_12[3u];
        let _e1888 = global.member_13[2u];
        let _e1893 = global.member_13[1u];
        let _e1899 = global.member_13[0u];
        let _e1903 = u32(((((clamp(floor(((log2(max((dot(_e1856.xyz, _e246) + _e1861), 0.000001f)) * _e1879) + _e1883)), 0f, (_e1888 - 1f)) * _e1893) + _e1874.y) * _e1899) + _e1874.x));
        let _e1910 = global_10.member[(_e1903 >> bitcast<u32>(2i))][(_e1903 & 3u)];
        let _e1911 = (_e1910 & 65535u);
        phi_7769_ = _e1850;
        phi_7765_ = _e1911;
        loop {
            let _e1915 = phi_7769_;
            let _e1917 = phi_7765_;
            local_25 = _e1915;
            if (_e1917 < (_e1911 + (_e1910 >> bitcast<u32>(16i)))) {
                let _e1920 = (_e1917 / 3u);
                let _e1927 = global_11.member[(_e1920 >> bitcast<u32>(2i))][(_e1920 & 3u)];
                let _e1933 = ((_e1927 >> bitcast<u32>(((_e1917 - (_e1920 * 3u)) * 10u))) & 1023u);
                let _e1936 = global_5.member[_e1933];
                let _e1938 = (_e1936.xyz - _e246);
                let _e1939 = dot(_e1938, _e1938);
                let _e1941 = (_e1939 * _e1936.w);
                let _e1944 = clamp((1f - (_e1941 * _e1941)), 0f, 1f);
                let _e1947 = (_e1938 * inverseSqrt(max(_e1939, 0.00000001f)));
                let _e1950 = global_7.member[_e1933];
                let _e1953 = global_8.member[_e1933];
                let _e1961 = clamp(((dot(-(_e1947), _e1953.xyz) * _e1950.w) + _e1953.w), 0f, 1f);
                if _e1304 {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e1972 = global.member_21[2u];
                            let _e1973 = u32(_e1972);
                            if (_e1933 < _e1973) {
                                let _e1977 = global.member_26[_e1933];
                                let _e1980 = global.member_15[_e1933];
                                let _e1989 = (_e1977.z * max((_e1980 * vec4<f32>(_e246.x, _e246.y, _e246.z, 1f)).w, 0f));
                                let _e1992 = global.member_25[0u];
                                let _e1998 = global.member_25[1u];
                                let _e2001 = ((_e246 + (_e1295 * (_e1989 * _e1992))) + (_e1947 * (_e1989 * _e1998)));
                                let _e2006 = (_e1980 * vec4<f32>(_e2001.x, _e2001.y, _e2001.z, 1f));
                                if (_e2006.w <= 0f) {
                                    phi_7831_ = 1f;
                                    break;
                                }
                                let _e2011 = (_e2006.xyz / vec3(_e2006.w));
                                let _e2013 = (_e2011.x < 0f);
                                phi_6378_ = _e2013;
                                if !(_e2013) {
                                    phi_6378_ = (_e2011.x > 1f);
                                }
                                let _e2017 = phi_6378_;
                                phi_6385_ = _e2017;
                                if !(_e2017) {
                                    phi_6385_ = (_e2011.y < 0f);
                                }
                                let _e2022 = phi_6385_;
                                phi_6392_ = _e2022;
                                if !(_e2022) {
                                    phi_6392_ = (_e2011.y > 1f);
                                }
                                let _e2027 = phi_6392_;
                                phi_6399_ = _e2027;
                                if !(_e2027) {
                                    phi_6399_ = (_e2011.z > 1f);
                                }
                                let _e2032 = phi_6399_;
                                if _e2032 {
                                    phi_7831_ = 1f;
                                    break;
                                }
                                let _e2035 = _e1977.xy;
                                let _e2037 = global.member_23;
                                let _e2038 = _e2037.zw;
                                let _e2040 = global.member_22;
                                let _e2041 = _e2040.xy;
                                let _e2042 = (_e2041 * 0.5f);
                                let _e2044 = (_e2035 + (_e2011.xy * _e2038));
                                let _e2045 = (_e2035 + _e2042);
                                let _e2047 = ((_e2035 + _e2038) - _e2042);
                                let _e2052 = vec4<f32>(_e2045.x, _e2045.y, _e2047.x, _e2047.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e2056 = global.member_22[2u];
                                        let _e2057 = i32(_e2056);
                                        if (_e2057 <= 0i) {
                                            let _e2061 = clamp(_e2044, _e2052.xy, _e2052.zw);
                                            let _e2066 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2061.x, _e2061.y, _e2011.z).xy, _e2011.z);
                                            phi_7830_ = _e2066;
                                            break;
                                        }
                                        let _e2068 = ((_e2044 / _e2041) + vec2<f32>(0.5f, 0.5f));
                                        let _e2069 = floor(_e2068);
                                        let _e2070 = (_e2068 - _e2069);
                                        let _e2072 = (_e2057 == 1i);
                                        if _e2072 {
                                            let _e2073 = (_e2070 * 2f);
                                            local_2[0i] = (vec2<f32>(3f, 3f) - _e2073);
                                            local_2[1i] = (vec2<f32>(1f, 1f) + _e2073);
                                            let _e2079 = local_2[0i];
                                            local_3[0i] = (((vec2<f32>(2f, 2f) - _e2070) / _e2079) - vec2<f32>(1f, 1f));
                                            let _e2083 = local_2[1i];
                                            local_3[1i] = ((_e2070 / _e2083) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e2087 = (_e2070 * 3f);
                                            local_2[0i] = (vec2<f32>(4f, 4f) - _e2087);
                                            local_2[1i] = vec2<f32>(7f, 7f);
                                            local_2[2i] = (vec2<f32>(1f, 1f) + _e2087);
                                            let _e2095 = local_2[0i];
                                            local_3[0i] = (((vec2<f32>(3f, 3f) - (_e2070 * 2f)) / _e2095) - vec2<f32>(2f, 2f));
                                            let _e2100 = local_2[1i];
                                            local_3[1i] = ((vec2<f32>(3f, 3f) + _e2070) / _e2100);
                                            let _e2103 = local_2[2i];
                                            local_3[2i] = ((_e2070 / _e2103) + vec2<f32>(2f, 2f));
                                        }
                                        let _e2108 = select(3i, 2i, _e2072);
                                        phi_7823_ = 0f;
                                        phi_7820_ = 0i;
                                        loop {
                                            let _e2110 = phi_7823_;
                                            let _e2112 = phi_7820_;
                                            local_20 = _e2110;
                                            if (_e2112 < _e2108) {
                                                phi_7829_ = _e2110;
                                                phi_7826_ = 0i;
                                                loop {
                                                    let _e2115 = phi_7829_;
                                                    let _e2117 = phi_7826_;
                                                    local_23 = _e2115;
                                                    if (_e2117 < _e2108) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e2121 = local_3[_e2117][0u];
                                                        let _e2124 = local_3[_e2112][1u];
                                                        let _e2130 = clamp((_e2041 * ((_e2069 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2121, _e2124))), _e2052.xy, _e2052.zw);
                                                        let _e2133 = local_2[_e2117][0u];
                                                        let _e2136 = local_2[_e2112][1u];
                                                        let _e2142 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2130.x, _e2130.y, _e2011.z).xy, _e2011.z);
                                                        phi_7829_ = (_e2115 + ((_e2133 * _e2136) * _e2142));
                                                        phi_7826_ = (_e2117 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e2676 = local_23;
                                                phi_7823_ = _e2676;
                                                phi_7820_ = (_e2112 + 1i);
                                            }
                                        }
                                        let _e2148 = local_20;
                                        phi_7830_ = (_e2148 * select(0.0069444445f, 0.0625f, _e2072));
                                        break;
                                    }
                                }
                                let _e2151 = phi_7830_;
                                phi_7831_ = _e2151;
                                break;
                            }
                            let _e2152 = (_e1933 - _e1973);
                            let _e2155 = global.member_21[3u];
                            if (_e2152 >= u32(_e2155)) {
                                phi_7831_ = 1f;
                                break;
                            }
                            let _e2160 = global.member_27[_e2152];
                            let _e2163 = global.member_28[_e2152];
                            let _e2165 = _e2160.xyz;
                            let _e2168 = (_e2160.w * length((_e246 - _e2165)));
                            let _e2171 = global.member_25[0u];
                            let _e2177 = global.member_25[1u];
                            let _e2181 = (((_e246 + (_e1295 * (_e2168 * _e2171))) + (_e1947 * (_e2168 * _e2177))) - _e2165);
                            let _e2182 = abs(_e2181);
                            let _e2185 = (_e2182.x >= _e2182.y);
                            phi_6469_ = _e2185;
                            if _e2185 {
                                phi_6469_ = (_e2182.x >= _e2182.z);
                            }
                            let _e2189 = phi_6469_;
                            if _e2189 {
                                phi_7807_ = select(1i, 0i, (_e2181.x > 0f));
                                phi_7805_ = _e2182.x;
                            } else {
                                let _e2194 = (_e2182.y >= _e2182.z);
                                if _e2194 {
                                    phi_7808_ = select(3i, 2i, (_e2181.y > 0f));
                                } else {
                                    phi_7808_ = select(5i, 4i, (_e2181.z > 0f));
                                }
                                let _e2202 = phi_7808_;
                                phi_7807_ = _e2202;
                                phi_7805_ = select(_e2182.z, _e2182.y, _e2194);
                            }
                            let _e2205 = phi_7807_;
                            let _e2207 = phi_7805_;
                            if (_e2207 <= 0f) {
                                phi_7831_ = 1f;
                                break;
                            }
                            local_4 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                            let _e2210 = local_4[_e2205];
                            local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                            let _e2213 = local_5[_e2205];
                            let _e2218 = global.member_24[2u];
                            let _e2221 = (vec2<f32>(dot(_e2181, _e2210), dot(_e2181, _e2213)) / vec2((_e2207 * _e2218)));
                            let _e2225 = (_e2163.z + (_e2163.w / _e2207));
                            if (_e2225 > 1f) {
                                phi_7831_ = 1f;
                                break;
                            }
                            let _e2240 = global.member_24;
                            let _e2241 = _e2240.xy;
                            let _e2243 = (_e2163.xy + (vec2<f32>(f32((_e2205 - (i32(floor((f32(_e2205) / f32(3i)))) * 3i))), f32((_e2205 / 3i))) * _e2241));
                            let _e2252 = global.member_22;
                            let _e2253 = _e2252.xy;
                            let _e2254 = (_e2253 * 0.5f);
                            let _e2256 = (_e2243 + (vec2<f32>((0.5f + (0.5f * _e2221.x)), (0.5f - (0.5f * _e2221.y))) * _e2241));
                            let _e2257 = (_e2243 + _e2254);
                            let _e2259 = ((_e2243 + _e2241) - _e2254);
                            let _e2264 = vec4<f32>(_e2257.x, _e2257.y, _e2259.x, _e2259.y);
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e2268 = global.member_22[2u];
                                    let _e2269 = i32(_e2268);
                                    if (_e2269 <= 0i) {
                                        let _e2273 = clamp(_e2256, _e2264.xy, _e2264.zw);
                                        let _e2278 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2273.x, _e2273.y, _e2225).xy, _e2225);
                                        phi_7819_ = _e2278;
                                        break;
                                    }
                                    let _e2280 = ((_e2256 / _e2253) + vec2<f32>(0.5f, 0.5f));
                                    let _e2281 = floor(_e2280);
                                    let _e2282 = (_e2280 - _e2281);
                                    let _e2284 = (_e2269 == 1i);
                                    if _e2284 {
                                        let _e2285 = (_e2282 * 2f);
                                        local[0i] = (vec2<f32>(3f, 3f) - _e2285);
                                        local[1i] = (vec2<f32>(1f, 1f) + _e2285);
                                        let _e2291 = local[0i];
                                        local_1[0i] = (((vec2<f32>(2f, 2f) - _e2282) / _e2291) - vec2<f32>(1f, 1f));
                                        let _e2295 = local[1i];
                                        local_1[1i] = ((_e2282 / _e2295) + vec2<f32>(1f, 1f));
                                    } else {
                                        let _e2299 = (_e2282 * 3f);
                                        local[0i] = (vec2<f32>(4f, 4f) - _e2299);
                                        local[1i] = vec2<f32>(7f, 7f);
                                        local[2i] = (vec2<f32>(1f, 1f) + _e2299);
                                        let _e2307 = local[0i];
                                        local_1[0i] = (((vec2<f32>(3f, 3f) - (_e2282 * 2f)) / _e2307) - vec2<f32>(2f, 2f));
                                        let _e2312 = local[1i];
                                        local_1[1i] = ((vec2<f32>(3f, 3f) + _e2282) / _e2312);
                                        let _e2315 = local[2i];
                                        local_1[2i] = ((_e2282 / _e2315) + vec2<f32>(2f, 2f));
                                    }
                                    let _e2320 = select(3i, 2i, _e2284);
                                    phi_7812_ = 0f;
                                    phi_7809_ = 0i;
                                    loop {
                                        let _e2322 = phi_7812_;
                                        let _e2324 = phi_7809_;
                                        local_21 = _e2322;
                                        if (_e2324 < _e2320) {
                                            phi_7818_ = _e2322;
                                            phi_7815_ = 0i;
                                            loop {
                                                let _e2327 = phi_7818_;
                                                let _e2329 = phi_7815_;
                                                local_24 = _e2327;
                                                if (_e2329 < _e2320) {
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e2333 = local_1[_e2329][0u];
                                                    let _e2336 = local_1[_e2324][1u];
                                                    let _e2342 = clamp((_e2253 * ((_e2281 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2333, _e2336))), _e2264.xy, _e2264.zw);
                                                    let _e2345 = local[_e2329][0u];
                                                    let _e2348 = local[_e2324][1u];
                                                    let _e2354 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2342.x, _e2342.y, _e2225).xy, _e2225);
                                                    phi_7818_ = (_e2327 + ((_e2345 * _e2348) * _e2354));
                                                    phi_7815_ = (_e2329 + 1i);
                                                }
                                            }
                                            continue;
                                        } else {
                                            break;
                                        }
                                        continuing {
                                            let _e2688 = local_24;
                                            phi_7812_ = _e2688;
                                            phi_7809_ = (_e2324 + 1i);
                                        }
                                    }
                                    let _e2360 = local_21;
                                    phi_7819_ = (_e2360 * select(0.0069444445f, 0.0625f, _e2284));
                                    break;
                                }
                            }
                            let _e2363 = phi_7819_;
                            phi_7831_ = _e2363;
                            break;
                        }
                    }
                    let _e2365 = phi_7831_;
                    phi_7832_ = _e2365;
                } else {
                    phi_7832_ = 1f;
                }
                let _e2367 = phi_7832_;
                let _e2369 = clamp(dot(_e1297, _e1947), -1f, 1f);
                let _e2375 = max(cos((0.5f * abs((_e1616 - asin(_e2369))))), 0.05f);
                let _e2377 = (_e1947 - (_e1297 * _e2369));
                let _e2383 = (dot(_e2377, _e1626) * inverseSqrt(max((dot(_e2377, _e2377) * _e1629), 0.000001f)));
                let _e2387 = sqrt(clamp((0.5f + (0.5f * _e2383)), 0f, 1f));
                let _e2388 = (_e2369 + _e1615);
                let _e2389 = (_e2388 + _e1640);
                let _e2403 = (1f - clamp(sqrt(clamp((0.5f + (0.5f * dot(_e1947, _e248))), 0f, 1f)), 0f, 1f));
                let _e2404 = (_e2403 * _e2403);
                let _e2412 = (_e2388 - _e1602);
                let _e2422 = (_e2387 * (1f + (0.6451613f * (0.6f - (0.8f * _e2383)))));
                let _e2423 = (_e2422 * _e2422);
                let _e2429 = (1f - clamp((_e2375 * sqrt(clamp((1f - _e2423), 0f, 1f))), 0f, 1f));
                let _e2430 = (_e2429 * _e2429);
                let _e2445 = (0.95348f - (((0.95348f * _e2430) * _e2430) * _e2429));
                let _e2450 = (_e2388 - _e1710);
                let _e2458 = (1f - clamp((_e2375 * 0.5f), 0f, 1f));
                let _e2459 = (_e2458 * _e2458);
                let _e2462 = (((0.95348f * _e2459) * _e2459) * _e2458);
                let _e2471 = (0.95348f - _e2462);
                if _e1138 {
                    let _e2481 = clamp(((dot(_e1295, _e1947) * 0.6f) + 0.4f), 0f, 1f);
                    phi_7868_ = (_e2481 * _e2481);
                } else {
                    phi_7868_ = mix(clamp(((dot((_e1626 * inverseSqrt(max(_e1629, 0.000001f))), _e1947) + 1f) * 0.5f), 0f, 1f), (1f - abs(_e2369)), 0.33f);
                }
                let _e2494 = phi_7868_;
                local_22 = (_e1915 + ((((((_e1766 * pow(_e1761, vec3(((1f - _e2367) * 0.35f)))) * _e2494) + (((vec3((((((exp((((-0.5f * _e2389) * _e2389) / _e1645)) / _e1648) * 0.25f) * _e2387) * (0.04652f + (((0.95348f * _e2404) * _e2404) * _e2403))) * 3f)) + (pow(_e1693, vec3((sqrt(clamp((1f - (_e2423 * 0.41623306f)), 0f, 1f)) / _e2375))) * ((((exp((((-0.5f * _e2412) * _e2412) / _e1672)) / _e1675) * exp(((-3.65f * _e2383) - 3.98f))) * _e2445) * _e2445))) + ((pow(_e1693, vec3((0.8f / _e2375))) * (((((exp((((-0.5f * _e2450) * _e2450) / _e1714)) / _e1717) * exp(((17f * _e2383) - 16.78f))) * _e2471) * _e2471) * (0.04652f + _e2462))) * 4f)) * _e1769)) * (_e1950.xyz * ((((_e1944 * _e1944) * _e1961) * _e1961) / max(_e1939, 0.0001f)))) * _e2367) * _e1774));
                continue;
            } else {
                break;
            }
            continuing {
                let _e2668 = local_22;
                phi_7769_ = _e2668;
                phi_7765_ = (_e1917 + bitcast<u32>(1i));
            }
        }
        let _e2699 = local_25;
        phi_7768_ = _e2699;
    }
    let _e2510 = phi_7768_;
    let _e2512 = -(length(_e247));
    let _e2515 = global.member_7[3u];
    let _e2521 = global.member_9[3u];
    phi_7771_ = (1f - exp((_e2512 * _e2515)));
    if (_e2521 != 0f) {
        let _e2525 = (_e2521 * (_e246 - _e245).y);
        if (abs(_e2525) < 0.0001f) {
            phi_7766_ = (1f - (0.5f * _e2525));
        } else {
            phi_7766_ = ((1f - exp(min(-(_e2525), 60f))) / _e2525);
        }
        let _e2536 = phi_7766_;
        let _e2540 = global.member_6[1u];
        let _e2543 = global.member_6[3u];
        phi_7771_ = (1f - exp(((_e2512 * (_e2515 * exp(min((-(_e2521) * (_e2540 - _e2543)), 30f)))) * _e2536)));
    }
    let _e2554 = phi_7771_;
    let _e2556 = global.member_7;
    let _e2559 = mix(_e2510, _e2556.xyz, vec3(_e2554));
    let _e2562 = global.member_33[3u];
    phi_7772_ = _e2559;
    if (_e2562 > 0.5f) {
        phi_7772_ = (_e2559 / (vec3<f32>(1f, 1f, 1f) + _e2559));
    }
    let _e2567 = phi_7772_;
    global_23 = vec4<f32>(_e2567.x, _e2567.y, _e2567.z, _e1229);
    let _e2572 = global_25;
    let _e2573 = global_26;
    switch bitcast<i32>(0u) {
        default: {
            if (_e2573.w <= 0f) {
                phi_7801_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_7801_ = (((_e2573.xy / vec2(_e2573.w)) - (_e2572.xy / vec2(_e2572.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e2587 = phi_7801_;
    global_24 = _e2587;
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
