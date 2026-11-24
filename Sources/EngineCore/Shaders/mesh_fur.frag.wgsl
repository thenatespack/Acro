// Generated from mesh_fur.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 739f498607fb7b57
// glsl-fnv1a64: ebbc8c74cfa1f850

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

struct type_33 {
    member: array<vec4<f32>, 1024>,
}

struct type_39 {
    member: array<vec4<u32>, 1024>,
}

struct type_45 {
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
var<uniform> global_5: type_33;
var<private> global_6: vec3<f32>;
@group(2) @binding(4) 
var<uniform> global_7: type_33;
@group(2) @binding(5) 
var<uniform> global_8: type_33;
var<private> global_9: vec4<f32>;
@group(2) @binding(6) 
var<uniform> global_10: type_39;
@group(2) @binding(7) 
var<uniform> global_11: type_39;
var<private> global_12: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_13: type_45;
@group(2) @binding(10) 
var global_14: texture_2d<f32>;
var<private> global_15: vec2<f32>;
var<private> global_16: vec3<f32>;
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
    var local_7: array<vec2<f32>, 3>;
    var local_8: array<vec2<f32>, 3>;
    var local_9: array<vec2<f32>, 3>;
    var local_10: array<vec2<f32>, 3>;
    var local_11: array<vec3<f32>, 4>;
    var local_12: array<vec3<f32>, 4>;
    var phi_4398_: f32;
    var phi_4397_: f32;
    var phi_4385_: vec3<f32>;
    var phi_4386_: vec3<f32>;
    var phi_4388_: vec3<f32>;
    var phi_4392_: vec3<f32>;
    var phi_4589_: f32;
    var phi_4404_: f32;
    var phi_4400_: f32;
    var phi_4586_: f32;
    var phi_4401_: f32;
    var phi_4399_: f32;
    var phi_4405_: f32;
    var phi_1774_: bool;
    var phi_4407_: vec3<f32>;
    var phi_4408_: i32;
    var phi_2532_: bool;
    var local_13: i32;
    var local_14: i32;
    var local_15: i32;
    var phi_2645_: bool;
    var phi_2652_: bool;
    var phi_2659_: bool;
    var local_16: i32;
    var local_17: i32;
    var local_18: i32;
    var phi_4413_: f32;
    var phi_4410_: i32;
    var phi_4419_: f32;
    var phi_4416_: i32;
    var local_19: f32;
    var phi_4420_: f32;
    var phi_4421_: f32;
    var local_20: i32;
    var local_21: i32;
    var local_22: i32;
    var phi_2932_: bool;
    var phi_2939_: bool;
    var phi_2946_: bool;
    var phi_4433_: f32;
    var phi_4430_: i32;
    var phi_4439_: f32;
    var phi_4436_: i32;
    var local_23: f32;
    var phi_4440_: f32;
    var phi_4441_: f32;
    var phi_4462_: f32;
    var phi_4459_: vec3<f32>;
    var phi_4461_: f32;
    var phi_4458_: vec3<f32>;
    var phi_4464_: vec3<f32>;
    var phi_4463_: f32;
    var phi_4561_: f32;
    var phi_4560_: vec3<f32>;
    var phi_4563_: vec3<f32>;
    var phi_4562_: i32;
    var local_24: vec3<f32>;
    var phi_4564_: vec3<f32>;
    var phi_4573_: vec3<f32>;
    var phi_4569_: u32;
    var phi_3615_: bool;
    var phi_3622_: bool;
    var phi_3629_: bool;
    var phi_3636_: bool;
    var phi_4640_: f32;
    var phi_4637_: i32;
    var phi_4646_: f32;
    var phi_4643_: i32;
    var local_25: f32;
    var phi_4647_: f32;
    var phi_3706_: bool;
    var phi_4625_: i32;
    var phi_4624_: i32;
    var phi_4622_: f32;
    var phi_4629_: f32;
    var phi_4626_: i32;
    var phi_4635_: f32;
    var phi_4632_: i32;
    var local_26: f32;
    var phi_4636_: f32;
    var phi_4648_: f32;
    var phi_4700_: vec3<f32>;
    var phi_4572_: vec3<f32>;
    var phi_4570_: f32;
    var phi_4575_: f32;
    var phi_4576_: vec3<f32>;
    var phi_4618_: vec2<f32>;
    var local_27: f32;
    var local_28: f32;
    var local_29: vec3<f32>;
    var local_30: f32;
    var local_31: f32;
    var local_32: vec3<f32>;

    let _e172 = global_12[0u];
    let _e174 = global_12[2u];
    let _e175 = (_e174 > 0.5f);
    let _e177 = global_12[3u];
    let _e178 = (_e177 > 0.5f);
    let _e181 = global_13.member_1[0i];
    let _e184 = global_13.member_1[1i];
    let _e187 = global_13.member_1[2i];
    let _e191 = global_13.member_1[6i][2u];
    phi_4397_ = 1f;
    if (_e191 > 0.5f) {
        let _e193 = global_15;
        let _e194 = textureSample(global_14, global_4, _e193);
        let _e199 = global_13.member_1[6i][3u];
        phi_4398_ = _e194.x;
        if (_e199 > 0.5f) {
            phi_4398_ = (1f - _e194.x);
        }
        let _e203 = phi_4398_;
        phi_4397_ = _e203;
    }
    let _e205 = phi_4397_;
    if _e178 {
        if (_e205 < 0.02f) {
            discard;
        }
        let _e207 = global_16;
        let _e215 = bitcast<vec3<u32>>((vec3<i32>(floor((_e207 / vec3(max(_e181.y, 0.00001f))))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
        let _e223 = (((_e215.x * 1597334677u) ^ (_e215.y * 3812015801u)) ^ (_e215.z * 2798796415u));
        let _e227 = ((_e223 ^ (_e223 >> bitcast<u32>(15i))) * 2246822519u);
        let _e231 = ((_e227 ^ (_e227 >> bitcast<u32>(13i))) * 3266489917u);
        let _e235 = ((_e231 ^ (_e231 >> bitcast<u32>(16i))) * 668265263u);
        phi_4586_ = 1f;
        phi_4401_ = 0f;
        phi_4399_ = (vec3<f32>(f32(), f32(), f32(((_e235 ^ (_e235 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).z;
    } else {
        if !(_e175) {
            let _e246 = max(_e181.y, 0.00001f);
            let _e247 = global_17;
            let _e248 = normalize(_e247);
            let _e249 = global_16;
            phi_4385_ = _e249;
            if (_e184.x > 0f) {
                let _e252 = (_e246 * 4f);
                let _e255 = floor((_e249 / vec3(_e252)));
                let _e260 = bitcast<vec3<u32>>((vec3<i32>((_e255 + vec3<f32>(31f, 17f, 5f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e268 = (((_e260.x * 1597334677u) ^ (_e260.y * 3812015801u)) ^ (_e260.z * 2798796415u));
                let _e272 = ((_e268 ^ (_e268 >> bitcast<u32>(15i))) * 2246822519u);
                let _e275 = (_e272 ^ (_e272 >> bitcast<u32>(13i)));
                let _e276 = (_e275 * 3266489917u);
                let _e279 = (_e276 ^ (_e276 >> bitcast<u32>(16i)));
                let _e280 = (_e279 * 668265263u);
                let _e295 = (((_e255 + vec3<f32>(0.5f, 0.5f, 0.5f)) + (((vec3<f32>(f32((_e275 & 65535u)), f32((_e279 & 65535u)), f32(((_e280 ^ (_e280 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)) - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.6f)) * _e252);
                let _e299 = (_e295 - (_e248 * dot((_e295 - _e249), _e248)));
                phi_4385_ = (_e299 + ((_e249 - _e299) / vec3((1f - min(((_e184.x * _e172) * 0.85f), 0.9f)))));
            }
            let _e309 = phi_4385_;
            let _e312 = floor((_e309 / vec3(_e246)));
            let _e315 = bitcast<vec3<u32>>((vec3<i32>(_e312) + vec3<i32>(1048576i, 1048576i, 1048576i)));
            let _e323 = (((_e315.x * 1597334677u) ^ (_e315.y * 3812015801u)) ^ (_e315.z * 2798796415u));
            let _e327 = ((_e323 ^ (_e323 >> bitcast<u32>(15i))) * 2246822519u);
            let _e330 = (_e327 ^ (_e327 >> bitcast<u32>(13i)));
            let _e331 = (_e330 * 3266489917u);
            let _e334 = (_e331 ^ (_e331 >> bitcast<u32>(16i)));
            let _e335 = (_e334 * 668265263u);
            let _e346 = (vec3<f32>(f32((_e330 & 65535u)), f32((_e334 & 65535u)), f32(((_e335 ^ (_e335 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
            let _e351 = (((_e312 + vec3<f32>(0.5f, 0.5f, 0.5f)) + ((_e346 - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.5f)) * _e246);
            if (abs(_e248.y) < 0.9f) {
                phi_4386_ = cross(_e248, vec3<f32>(0f, 1f, 0f));
            } else {
                phi_4386_ = cross(_e248, vec3<f32>(1f, 0f, 0f));
            }
            let _e358 = phi_4386_;
            let _e359 = normalize(_e358);
            phi_4388_ = _e351;
            if (_e184.y > 0f) {
                let _e366 = ((_e172 * 12.566f) + (_e346.x * 6.283f));
                phi_4388_ = (_e351 + (((_e359 * cos(_e366)) + (cross(_e248, _e359) * sin(_e366))) * ((_e184.y * 0.3f) * _e246)));
            }
            let _e377 = phi_4388_;
            phi_4392_ = _e377;
            if (_e184.z > 0f) {
                let _e380 = (_e172 * 4f);
                let _e382 = (floor(_e380) * 7f);
                let _e387 = bitcast<vec3<u32>>((vec3<i32>((_e312 + vec3<f32>(_e382, 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e395 = (((_e387.x * 1597334677u) ^ (_e387.y * 3812015801u)) ^ (_e387.z * 2798796415u));
                let _e399 = ((_e395 ^ (_e395 >> bitcast<u32>(15i))) * 2246822519u);
                let _e402 = (_e399 ^ (_e399 >> bitcast<u32>(13i)));
                let _e403 = (_e402 * 3266489917u);
                let _e406 = (_e403 ^ (_e403 >> bitcast<u32>(16i)));
                let _e407 = (_e406 * 668265263u);
                let _e424 = bitcast<vec3<u32>>((vec3<i32>((_e312 + vec3<f32>((_e382 + 7f), 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e432 = (((_e424.x * 1597334677u) ^ (_e424.y * 3812015801u)) ^ (_e424.z * 2798796415u));
                let _e436 = ((_e432 ^ (_e432 >> bitcast<u32>(15i))) * 2246822519u);
                let _e439 = (_e436 ^ (_e436 >> bitcast<u32>(13i)));
                let _e440 = (_e439 * 3266489917u);
                let _e443 = (_e440 ^ (_e440 >> bitcast<u32>(16i)));
                let _e444 = (_e443 * 668265263u);
                phi_4392_ = (_e377 + ((mix((vec3<f32>(f32((_e402 & 65535u)), f32((_e406 & 65535u)), f32(((_e407 ^ (_e407 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), (vec3<f32>(f32((_e439 & 65535u)), f32((_e443 & 65535u)), f32(((_e444 ^ (_e444 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), vec3(smoothstep(0f, 1f, fract(_e380)))) - vec3<f32>(0.5f, 0.5f, 0.5f)) * (((_e184.z * 0.4f) * _e246) * _e172)));
            }
            let _e467 = phi_4392_;
            let _e468 = (_e309 - _e467);
            let _e471 = (_e468 - (_e248 * dot(_e468, _e248)));
            let _e477 = ((1f - (_e187.y * _e346.y)) * min(_e205, 1f));
            if (_e172 > _e477) {
                discard;
            }
            let _e482 = (_e172 / max(_e477, 0.001f));
            let _e485 = ((mix(_e181.z, _e181.w, _e482) * 0.5f) * _e246);
            if (dot(_e471, _e471) > (_e485 * _e485)) {
                discard;
            }
            phi_4589_ = 1f;
            phi_4404_ = _e482;
            phi_4400_ = _e346.z;
        } else {
            let _e493 = global_13.member_1[4i][3u];
            let _e496 = global_15[0u];
            let _e497 = (_e496 * max(_e493, 1f));
            let _e500 = global_12[1u];
            let _e506 = bitcast<vec3<u32>>((vec3<i32>(vec3<f32>(floor(_e497), floor((_e500 * 65535f)), 7f)) + vec3<i32>(1048576i, 1048576i, 1048576i)));
            let _e514 = (((_e506.x * 1597334677u) ^ (_e506.y * 3812015801u)) ^ (_e506.z * 2798796415u));
            let _e518 = ((_e514 ^ (_e514 >> bitcast<u32>(15i))) * 2246822519u);
            let _e521 = (_e518 ^ (_e518 >> bitcast<u32>(13i)));
            let _e522 = (_e521 * 3266489917u);
            let _e525 = (_e522 ^ (_e522 >> bitcast<u32>(16i)));
            let _e526 = (_e525 * 668265263u);
            let _e537 = (vec3<f32>(f32((_e521 & 65535u)), f32((_e525 & 65535u)), f32(((_e526 ^ (_e526 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
            let _e547 = (1f - (_e187.y * _e537.y));
            if (_e172 > _e547) {
                discard;
            }
            let _e550 = (_e172 / max(_e547, 0.001f));
            let _e553 = mix(_e181.z, _e181.w, _e550);
            let _e561 = ((1f - smoothstep((_e553 * 0.275f), (_e553 * 0.5f), abs(((fract(_e497) - 0.5f) + ((_e537.x - 0.5f) * 0.3f))))) * (1f - smoothstep(0.85f, 1f, _e550)));
            if (_e561 < 0.03f) {
                discard;
            }
            phi_4589_ = _e561;
            phi_4404_ = _e550;
            phi_4400_ = _e537.z;
        }
        let _e565 = phi_4589_;
        let _e567 = phi_4404_;
        let _e569 = phi_4400_;
        phi_4586_ = _e565;
        phi_4401_ = _e567;
        phi_4399_ = _e569;
    }
    let _e571 = phi_4586_;
    let _e573 = phi_4401_;
    let _e575 = phi_4399_;
    let _e578 = global_13.member_1[3i];
    let _e582 = global_13.member_1[4i];
    let _e583 = _e582.xyz;
    let _e584 = (_e575 - 0.5f);
    let _e594 = global_18;
    let _e596 = ((mix(_e578.xyz, _e583, vec3(pow(_e573, 0.8f))) * max((1f + ((_e584 * 2f) * _e187.z)), 0f)) * _e594.xyz);
    if _e178 {
        phi_4405_ = 0.4f;
    } else {
        phi_4405_ = mix(0.4f, 1f, _e573);
    }
    let _e599 = phi_4405_;
    let _e600 = global_19;
    let _e601 = normalize(_e600);
    phi_1774_ = _e175;
    if _e175 {
        let _e602 = global_20;
        phi_1774_ = !(_e602);
    }
    let _e605 = phi_1774_;
    phi_4407_ = _e601;
    if _e605 {
        phi_4407_ = -(_e601);
    }
    let _e608 = phi_4407_;
    let _e609 = global_21;
    let _e610 = normalize(_e609);
    let _e612 = global.member_4;
    let _e614 = normalize(_e612.xyz);
    let _e616 = global.member_6;
    let _e617 = _e616.xyz;
    let _e618 = global_6;
    let _e619 = (_e617 - _e618);
    let _e622 = normalize((_e614 + normalize(_e619)));
    let _e624 = global_22[0u];
    let _e625 = (_e624 > 0.5f);
    let _e628 = global.member_5[3u];
    phi_4561_ = 1f;
    phi_4560_ = _e596;
    if ((_e628 > 0.5f) && _e625) {
        switch bitcast<i32>(0u) {
            default: {
                let _e634 = global.member_21[0u];
                let _e635 = i32(_e634);
                let _e637 = global.member_20;
                let _e642 = global.member_20[3u];
                let _e643 = (dot(_e637.xyz, _e618) + _e642);
                phi_4408_ = 0i;
                loop {
                    let _e645 = phi_4408_;
                    local_13 = _e645;
                    local_14 = _e645;
                    local_15 = _e645;
                    local_16 = _e645;
                    local_17 = _e645;
                    local_18 = _e645;
                    local_20 = _e645;
                    local_21 = _e645;
                    local_22 = _e645;
                    let _e647 = (_e645 < (_e635 - 1i));
                    phi_2532_ = _e647;
                    if _e647 {
                        let _e650 = global.member_16[_e645];
                        phi_2532_ = (_e643 > _e650);
                    }
                    let _e653 = phi_2532_;
                    if _e653 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_4408_ = (_e645 + 1i);
                    }
                }
                let _e657 = local_13;
                let _e659 = global.member_16[_e657];
                if (_e643 > _e659) {
                    phi_4464_ = vec3<f32>(1f, 1f, 1f);
                    phi_4463_ = 1f;
                    break;
                }
                let _e663 = local_14;
                let _e665 = global.member_18[_e663];
                let _e667 = (_e618 + (_e608 * _e665));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e671 = local_15;
                        let _e673 = global.member_14[_e671];
                        let _e678 = (_e673 * vec4<f32>(_e667.x, _e667.y, _e667.z, 1f));
                        let _e680 = (_e678.x < 0f);
                        phi_2645_ = _e680;
                        if !(_e680) {
                            phi_2645_ = (_e678.x > 1f);
                        }
                        let _e684 = phi_2645_;
                        phi_2652_ = _e684;
                        if !(_e684) {
                            phi_2652_ = (_e678.y < 0f);
                        }
                        let _e689 = phi_2652_;
                        phi_2659_ = _e689;
                        if !(_e689) {
                            phi_2659_ = (_e678.y > 1f);
                        }
                        let _e694 = phi_2659_;
                        if _e694 {
                            phi_4421_ = 1f;
                            break;
                        }
                        let _e696 = local_16;
                        let _e700 = local_17;
                        let _e706 = global.member_23;
                        let _e707 = _e706.xy;
                        let _e708 = (vec2<f32>(f32((_e696 & 1i)), f32((_e700 >> bitcast<u32>(1i)))) * _e707);
                        let _e713 = local_18;
                        let _e715 = global.member_19[_e713];
                        let _e716 = (min(_e678.z, 1f) - _e715);
                        let _e719 = global.member_22;
                        let _e720 = _e719.xy;
                        let _e721 = (_e720 * 0.5f);
                        let _e723 = (_e708 + (_e678.xy * _e707));
                        let _e724 = (_e708 + _e721);
                        let _e726 = ((_e708 + _e707) - _e721);
                        let _e731 = vec4<f32>(_e724.x, _e724.y, _e726.x, _e726.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e735 = global.member_22[2u];
                                let _e736 = i32(_e735);
                                if (_e736 <= 0i) {
                                    let _e740 = clamp(_e723, _e731.xy, _e731.zw);
                                    let _e745 = textureSampleCompare(global_1, global_3, vec3<f32>(_e740.x, _e740.y, _e716).xy, _e716);
                                    phi_4420_ = _e745;
                                    break;
                                }
                                let _e747 = ((_e723 / _e720) + vec2<f32>(0.5f, 0.5f));
                                let _e748 = floor(_e747);
                                let _e749 = (_e747 - _e748);
                                let _e751 = (_e736 == 1i);
                                if _e751 {
                                    let _e752 = (_e749 * 2f);
                                    local_9[0i] = (vec2<f32>(3f, 3f) - _e752);
                                    local_9[1i] = (vec2<f32>(1f, 1f) + _e752);
                                    let _e758 = local_9[0i];
                                    local_10[0i] = (((vec2<f32>(2f, 2f) - _e749) / _e758) - vec2<f32>(1f, 1f));
                                    let _e762 = local_9[1i];
                                    local_10[1i] = ((_e749 / _e762) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e766 = (_e749 * 3f);
                                    local_9[0i] = (vec2<f32>(4f, 4f) - _e766);
                                    local_9[1i] = vec2<f32>(7f, 7f);
                                    local_9[2i] = (vec2<f32>(1f, 1f) + _e766);
                                    let _e774 = local_9[0i];
                                    local_10[0i] = (((vec2<f32>(3f, 3f) - (_e749 * 2f)) / _e774) - vec2<f32>(2f, 2f));
                                    let _e779 = local_9[1i];
                                    local_10[1i] = ((vec2<f32>(3f, 3f) + _e749) / _e779);
                                    let _e782 = local_9[2i];
                                    local_10[2i] = ((_e749 / _e782) + vec2<f32>(2f, 2f));
                                }
                                let _e787 = select(3i, 2i, _e751);
                                phi_4413_ = 0f;
                                phi_4410_ = 0i;
                                loop {
                                    let _e789 = phi_4413_;
                                    let _e791 = phi_4410_;
                                    local_19 = _e789;
                                    if (_e791 < _e787) {
                                        phi_4419_ = _e789;
                                        phi_4416_ = 0i;
                                        loop {
                                            let _e794 = phi_4419_;
                                            let _e796 = phi_4416_;
                                            local_27 = _e794;
                                            if (_e796 < _e787) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e800 = local_10[_e796][0u];
                                                let _e803 = local_10[_e791][1u];
                                                let _e809 = clamp((_e720 * ((_e748 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e800, _e803))), _e731.xy, _e731.zw);
                                                let _e812 = local_9[_e796][0u];
                                                let _e815 = local_9[_e791][1u];
                                                let _e821 = textureSampleCompare(global_1, global_3, vec3<f32>(_e809.x, _e809.y, _e716).xy, _e716);
                                                phi_4419_ = (_e794 + ((_e812 * _e815) * _e821));
                                                phi_4416_ = (_e796 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e1799 = local_27;
                                        phi_4413_ = _e1799;
                                        phi_4410_ = (_e791 + 1i);
                                    }
                                }
                                let _e827 = local_19;
                                phi_4420_ = (_e827 * select(0.0069444445f, 0.0625f, _e751));
                                break;
                            }
                        }
                        let _e830 = phi_4420_;
                        phi_4421_ = _e830;
                        break;
                    }
                }
                let _e832 = phi_4421_;
                local_11 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e834 = local_20;
                let _e836 = local_11[_e834];
                let _e839 = local_21;
                let _e841 = global.member_17[_e839];
                phi_4461_ = _e832;
                phi_4458_ = _e836;
                if (_e643 > _e841) {
                    let _e845 = ((_e643 - _e841) / (_e659 - _e841));
                    let _e847 = local_22;
                    let _e848 = (_e847 + 1i);
                    if (_e848 < _e635) {
                        let _e852 = global.member_18[_e848];
                        let _e854 = (_e618 + (_e608 * _e852));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e858 = global.member_14[_e848];
                                let _e863 = (_e858 * vec4<f32>(_e854.x, _e854.y, _e854.z, 1f));
                                let _e865 = (_e863.x < 0f);
                                phi_2932_ = _e865;
                                if !(_e865) {
                                    phi_2932_ = (_e863.x > 1f);
                                }
                                let _e869 = phi_2932_;
                                phi_2939_ = _e869;
                                if !(_e869) {
                                    phi_2939_ = (_e863.y < 0f);
                                }
                                let _e874 = phi_2939_;
                                phi_2946_ = _e874;
                                if !(_e874) {
                                    phi_2946_ = (_e863.y > 1f);
                                }
                                let _e879 = phi_2946_;
                                if _e879 {
                                    phi_4441_ = 1f;
                                    break;
                                }
                                let _e887 = global.member_23;
                                let _e888 = _e887.xy;
                                let _e889 = (vec2<f32>(f32((_e848 & 1i)), f32((_e848 >> bitcast<u32>(1i)))) * _e888);
                                let _e894 = global.member_19[_e848];
                                let _e895 = (min(_e863.z, 1f) - _e894);
                                let _e898 = global.member_22;
                                let _e899 = _e898.xy;
                                let _e900 = (_e899 * 0.5f);
                                let _e902 = (_e889 + (_e863.xy * _e888));
                                let _e903 = (_e889 + _e900);
                                let _e905 = ((_e889 + _e888) - _e900);
                                let _e910 = vec4<f32>(_e903.x, _e903.y, _e905.x, _e905.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e914 = global.member_22[2u];
                                        let _e915 = i32(_e914);
                                        if (_e915 <= 0i) {
                                            let _e919 = clamp(_e902, _e910.xy, _e910.zw);
                                            let _e924 = textureSampleCompare(global_1, global_3, vec3<f32>(_e919.x, _e919.y, _e895).xy, _e895);
                                            phi_4440_ = _e924;
                                            break;
                                        }
                                        let _e926 = ((_e902 / _e899) + vec2<f32>(0.5f, 0.5f));
                                        let _e927 = floor(_e926);
                                        let _e928 = (_e926 - _e927);
                                        let _e930 = (_e915 == 1i);
                                        if _e930 {
                                            let _e931 = (_e928 * 2f);
                                            local_7[0i] = (vec2<f32>(3f, 3f) - _e931);
                                            local_7[1i] = (vec2<f32>(1f, 1f) + _e931);
                                            let _e937 = local_7[0i];
                                            local_8[0i] = (((vec2<f32>(2f, 2f) - _e928) / _e937) - vec2<f32>(1f, 1f));
                                            let _e941 = local_7[1i];
                                            local_8[1i] = ((_e928 / _e941) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e945 = (_e928 * 3f);
                                            local_7[0i] = (vec2<f32>(4f, 4f) - _e945);
                                            local_7[1i] = vec2<f32>(7f, 7f);
                                            local_7[2i] = (vec2<f32>(1f, 1f) + _e945);
                                            let _e953 = local_7[0i];
                                            local_8[0i] = (((vec2<f32>(3f, 3f) - (_e928 * 2f)) / _e953) - vec2<f32>(2f, 2f));
                                            let _e958 = local_7[1i];
                                            local_8[1i] = ((vec2<f32>(3f, 3f) + _e928) / _e958);
                                            let _e961 = local_7[2i];
                                            local_8[2i] = ((_e928 / _e961) + vec2<f32>(2f, 2f));
                                        }
                                        let _e966 = select(3i, 2i, _e930);
                                        phi_4433_ = 0f;
                                        phi_4430_ = 0i;
                                        loop {
                                            let _e968 = phi_4433_;
                                            let _e970 = phi_4430_;
                                            local_23 = _e968;
                                            if (_e970 < _e966) {
                                                phi_4439_ = _e968;
                                                phi_4436_ = 0i;
                                                loop {
                                                    let _e973 = phi_4439_;
                                                    let _e975 = phi_4436_;
                                                    local_28 = _e973;
                                                    if (_e975 < _e966) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e979 = local_8[_e975][0u];
                                                        let _e982 = local_8[_e970][1u];
                                                        let _e988 = clamp((_e899 * ((_e927 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e979, _e982))), _e910.xy, _e910.zw);
                                                        let _e991 = local_7[_e975][0u];
                                                        let _e994 = local_7[_e970][1u];
                                                        let _e1000 = textureSampleCompare(global_1, global_3, vec3<f32>(_e988.x, _e988.y, _e895).xy, _e895);
                                                        phi_4439_ = (_e973 + ((_e991 * _e994) * _e1000));
                                                        phi_4436_ = (_e975 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e1814 = local_28;
                                                phi_4433_ = _e1814;
                                                phi_4430_ = (_e970 + 1i);
                                            }
                                        }
                                        let _e1006 = local_23;
                                        phi_4440_ = (_e1006 * select(0.0069444445f, 0.0625f, _e930));
                                        break;
                                    }
                                }
                                let _e1009 = phi_4440_;
                                phi_4441_ = _e1009;
                                break;
                            }
                        }
                        let _e1011 = phi_4441_;
                        local_12 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1014 = local_12[_e848];
                        phi_4462_ = mix(_e832, _e1011, _e845);
                        phi_4459_ = mix(_e836, _e1014, vec3(_e845));
                    } else {
                        phi_4462_ = mix(_e832, 1f, _e845);
                        phi_4459_ = _e836;
                    }
                    let _e1019 = phi_4462_;
                    let _e1021 = phi_4459_;
                    phi_4461_ = _e1019;
                    phi_4458_ = _e1021;
                }
                let _e1023 = phi_4461_;
                let _e1025 = phi_4458_;
                let _e1028 = global.member_22[3u];
                phi_4464_ = select(vec3<f32>(1f, 1f, 1f), _e1025, vec3((_e1028 > 0.5f)));
                phi_4463_ = _e1023;
                break;
            }
        }
        let _e1033 = phi_4464_;
        let _e1035 = phi_4463_;
        phi_4561_ = _e1035;
        phi_4560_ = (_e596 * _e1033);
    }
    let _e1038 = phi_4561_;
    let _e1040 = phi_4560_;
    let _e1042 = global.member_5;
    let _e1046 = global.member_4[3u];
    let _e1048 = dot(_e608, _e614);
    let _e1051 = clamp(((_e1048 * 0.6f) + 0.4f), 0f, 1f);
    let _e1055 = (_e584 * 0.3f);
    let _e1065 = dot(normalize((_e610 + (_e608 * (0.1f + _e1055)))), _e622);
    let _e1073 = dot(normalize((_e610 + (_e608 * (-0.12f + _e1055)))), _e622);
    let _e1091 = global.member_29[0u];
    if (_e1091 > 0.5f) {
        let _e1094 = global.member_29;
        let _e1101 = ((_e1094.z * _e608.x) - (_e1094.w * _e608.z));
        let _e1105 = ((_e1094.w * _e608.x) + (_e1094.z * _e608.z));
        let _e1109 = (1.092548f * _e1101);
        local_6 = array<f32, 9>(0.282095f, (0.488603f * _e608.y), (0.488603f * _e1105), (0.488603f * _e1101), (_e1109 * _e608.y), ((1.092548f * _e608.y) * _e1105), (0.315392f * (((3f * _e1105) * _e1105) - 1f)), (_e1109 * _e1105), (0.546274f * ((_e1101 * _e1101) - (_e608.y * _e608.y))));
        phi_4563_ = vec3<f32>(0f, 0f, 0f);
        phi_4562_ = 0i;
        loop {
            let _e1124 = phi_4563_;
            let _e1126 = phi_4562_;
            local_24 = _e1124;
            if (_e1126 < 9i) {
                continue;
            } else {
                break;
            }
            continuing {
                let _e1130 = textureLoad(global_2, (vec2<i32>(496i, 256i) + vec2<i32>(_e1126, 0i)), 0i);
                let _e1133 = local_6[_e1126];
                phi_4563_ = (_e1124 + (_e1130.xyz * _e1133));
                phi_4562_ = (_e1126 + 1i);
            }
        }
        let _e1138 = local_24;
        let _e1142 = global.member_29[1u];
        phi_4564_ = (max(_e1138, vec3<f32>(0f, 0f, 0f)) * _e1142);
    } else {
        let _e1145 = global.member_9;
        let _e1148 = global.member_8;
        let _e1157 = global.member_8[3u];
        phi_4564_ = (mix(_e1145.xyz, _e1148.xyz, vec3(((_e608.y * 0.5f) + 0.5f))) * _e1157);
    }
    let _e1160 = phi_4564_;
    let _e1163 = (((((_e1040 * ((_e1051 * _e1051) * mix(0.75f, 1f, _e599))) + (((vec3<f32>(0.22f, 0.22f, 0.22f) * pow(sqrt(max((1f - (_e1065 * _e1065)), 0f)), 90f)) + ((_e583 * 0.55f) * pow(sqrt(max((1f - (_e1073 * _e1073)), 0f)), 18f))) * ((_e187.w * smoothstep(-0.2f, 0.35f, _e1048)) * _e599))) * (_e1042.xyz * _e1046)) * _e1038) + ((_e1040 * _e1160) * _e599));
    let _e1166 = global.member_13[3u];
    phi_4572_ = _e1163;
    if (_e1166 > 0.5f) {
        let _e1169 = global.member_11;
        let _e1174 = global.member_11[3u];
        let _e1176 = global_9;
        let _e1179 = global.member_12;
        let _e1184 = global.member_13;
        let _e1187 = clamp(floor((_e1176.xy * _e1179.xy)), vec2<f32>(0f, 0f), (_e1184.xy - vec2<f32>(1f, 1f)));
        let _e1192 = global.member_12[2u];
        let _e1196 = global.member_12[3u];
        let _e1201 = global.member_13[2u];
        let _e1206 = global.member_13[1u];
        let _e1212 = global.member_13[0u];
        let _e1216 = u32(((((clamp(floor(((log2(max((dot(_e1169.xyz, _e618) + _e1174), 0.000001f)) * _e1192) + _e1196)), 0f, (_e1201 - 1f)) * _e1206) + _e1187.y) * _e1212) + _e1187.x));
        let _e1223 = global_10.member[(_e1216 >> bitcast<u32>(2i))][(_e1216 & 3u)];
        let _e1224 = (_e1223 & 65535u);
        phi_4573_ = _e1163;
        phi_4569_ = _e1224;
        loop {
            let _e1228 = phi_4573_;
            let _e1230 = phi_4569_;
            local_32 = _e1228;
            if (_e1230 < (_e1224 + (_e1223 >> bitcast<u32>(16i)))) {
                let _e1233 = (_e1230 / 3u);
                let _e1240 = global_11.member[(_e1233 >> bitcast<u32>(2i))][(_e1233 & 3u)];
                let _e1246 = ((_e1240 >> bitcast<u32>(((_e1230 - (_e1233 * 3u)) * 10u))) & 1023u);
                let _e1249 = global_5.member[_e1246];
                let _e1251 = (_e1249.xyz - _e618);
                let _e1252 = dot(_e1251, _e1251);
                let _e1254 = (_e1252 * _e1249.w);
                let _e1257 = clamp((1f - (_e1254 * _e1254)), 0f, 1f);
                let _e1260 = (_e1251 * inverseSqrt(max(_e1252, 0.00000001f)));
                let _e1263 = global_7.member[_e1246];
                let _e1266 = global_8.member[_e1246];
                let _e1274 = clamp(((dot(-(_e1260), _e1266.xyz) * _e1263.w) + _e1266.w), 0f, 1f);
                let _e1281 = (_e1263.xyz * ((((_e1257 * _e1257) * _e1274) * _e1274) / max(_e1252, 0.0001f)));
                phi_4700_ = _e1281;
                if _e625 {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e1285 = global.member_21[2u];
                            let _e1286 = u32(_e1285);
                            if (_e1246 < _e1286) {
                                let _e1290 = global.member_26[_e1246];
                                let _e1293 = global.member_15[_e1246];
                                let _e1302 = (_e1290.z * max((_e1293 * vec4<f32>(_e618.x, _e618.y, _e618.z, 1f)).w, 0f));
                                let _e1305 = global.member_25[0u];
                                let _e1311 = global.member_25[1u];
                                let _e1314 = ((_e618 + (_e608 * (_e1302 * _e1305))) + (_e1260 * (_e1302 * _e1311)));
                                let _e1319 = (_e1293 * vec4<f32>(_e1314.x, _e1314.y, _e1314.z, 1f));
                                if (_e1319.w <= 0f) {
                                    phi_4648_ = 1f;
                                    break;
                                }
                                let _e1324 = (_e1319.xyz / vec3(_e1319.w));
                                let _e1326 = (_e1324.x < 0f);
                                phi_3615_ = _e1326;
                                if !(_e1326) {
                                    phi_3615_ = (_e1324.x > 1f);
                                }
                                let _e1330 = phi_3615_;
                                phi_3622_ = _e1330;
                                if !(_e1330) {
                                    phi_3622_ = (_e1324.y < 0f);
                                }
                                let _e1335 = phi_3622_;
                                phi_3629_ = _e1335;
                                if !(_e1335) {
                                    phi_3629_ = (_e1324.y > 1f);
                                }
                                let _e1340 = phi_3629_;
                                phi_3636_ = _e1340;
                                if !(_e1340) {
                                    phi_3636_ = (_e1324.z > 1f);
                                }
                                let _e1345 = phi_3636_;
                                if _e1345 {
                                    phi_4648_ = 1f;
                                    break;
                                }
                                let _e1348 = _e1290.xy;
                                let _e1350 = global.member_23;
                                let _e1351 = _e1350.zw;
                                let _e1353 = global.member_22;
                                let _e1354 = _e1353.xy;
                                let _e1355 = (_e1354 * 0.5f);
                                let _e1357 = (_e1348 + (_e1324.xy * _e1351));
                                let _e1358 = (_e1348 + _e1355);
                                let _e1360 = ((_e1348 + _e1351) - _e1355);
                                let _e1365 = vec4<f32>(_e1358.x, _e1358.y, _e1360.x, _e1360.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1369 = global.member_22[2u];
                                        let _e1370 = i32(_e1369);
                                        if (_e1370 <= 0i) {
                                            let _e1374 = clamp(_e1357, _e1365.xy, _e1365.zw);
                                            let _e1379 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1374.x, _e1374.y, _e1324.z).xy, _e1324.z);
                                            phi_4647_ = _e1379;
                                            break;
                                        }
                                        let _e1381 = ((_e1357 / _e1354) + vec2<f32>(0.5f, 0.5f));
                                        let _e1382 = floor(_e1381);
                                        let _e1383 = (_e1381 - _e1382);
                                        let _e1385 = (_e1370 == 1i);
                                        if _e1385 {
                                            let _e1386 = (_e1383 * 2f);
                                            local_2[0i] = (vec2<f32>(3f, 3f) - _e1386);
                                            local_2[1i] = (vec2<f32>(1f, 1f) + _e1386);
                                            let _e1392 = local_2[0i];
                                            local_3[0i] = (((vec2<f32>(2f, 2f) - _e1383) / _e1392) - vec2<f32>(1f, 1f));
                                            let _e1396 = local_2[1i];
                                            local_3[1i] = ((_e1383 / _e1396) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1400 = (_e1383 * 3f);
                                            local_2[0i] = (vec2<f32>(4f, 4f) - _e1400);
                                            local_2[1i] = vec2<f32>(7f, 7f);
                                            local_2[2i] = (vec2<f32>(1f, 1f) + _e1400);
                                            let _e1408 = local_2[0i];
                                            local_3[0i] = (((vec2<f32>(3f, 3f) - (_e1383 * 2f)) / _e1408) - vec2<f32>(2f, 2f));
                                            let _e1413 = local_2[1i];
                                            local_3[1i] = ((vec2<f32>(3f, 3f) + _e1383) / _e1413);
                                            let _e1416 = local_2[2i];
                                            local_3[2i] = ((_e1383 / _e1416) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1421 = select(3i, 2i, _e1385);
                                        phi_4640_ = 0f;
                                        phi_4637_ = 0i;
                                        loop {
                                            let _e1423 = phi_4640_;
                                            let _e1425 = phi_4637_;
                                            local_25 = _e1423;
                                            if (_e1425 < _e1421) {
                                                phi_4646_ = _e1423;
                                                phi_4643_ = 0i;
                                                loop {
                                                    let _e1428 = phi_4646_;
                                                    let _e1430 = phi_4643_;
                                                    local_30 = _e1428;
                                                    if (_e1430 < _e1421) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1434 = local_3[_e1430][0u];
                                                        let _e1437 = local_3[_e1425][1u];
                                                        let _e1443 = clamp((_e1354 * ((_e1382 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1434, _e1437))), _e1365.xy, _e1365.zw);
                                                        let _e1446 = local_2[_e1430][0u];
                                                        let _e1449 = local_2[_e1425][1u];
                                                        let _e1455 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1443.x, _e1443.y, _e1324.z).xy, _e1324.z);
                                                        phi_4646_ = (_e1428 + ((_e1446 * _e1449) * _e1455));
                                                        phi_4643_ = (_e1430 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e1843 = local_30;
                                                phi_4640_ = _e1843;
                                                phi_4637_ = (_e1425 + 1i);
                                            }
                                        }
                                        let _e1461 = local_25;
                                        phi_4647_ = (_e1461 * select(0.0069444445f, 0.0625f, _e1385));
                                        break;
                                    }
                                }
                                let _e1464 = phi_4647_;
                                phi_4648_ = _e1464;
                                break;
                            }
                            let _e1465 = (_e1246 - _e1286);
                            let _e1468 = global.member_21[3u];
                            if (_e1465 >= u32(_e1468)) {
                                phi_4648_ = 1f;
                                break;
                            }
                            let _e1473 = global.member_27[_e1465];
                            let _e1476 = global.member_28[_e1465];
                            let _e1478 = _e1473.xyz;
                            let _e1481 = (_e1473.w * length((_e618 - _e1478)));
                            let _e1484 = global.member_25[0u];
                            let _e1490 = global.member_25[1u];
                            let _e1494 = (((_e618 + (_e608 * (_e1481 * _e1484))) + (_e1260 * (_e1481 * _e1490))) - _e1478);
                            let _e1495 = abs(_e1494);
                            let _e1498 = (_e1495.x >= _e1495.y);
                            phi_3706_ = _e1498;
                            if _e1498 {
                                phi_3706_ = (_e1495.x >= _e1495.z);
                            }
                            let _e1502 = phi_3706_;
                            if _e1502 {
                                phi_4624_ = select(1i, 0i, (_e1494.x > 0f));
                                phi_4622_ = _e1495.x;
                            } else {
                                let _e1507 = (_e1495.y >= _e1495.z);
                                if _e1507 {
                                    phi_4625_ = select(3i, 2i, (_e1494.y > 0f));
                                } else {
                                    phi_4625_ = select(5i, 4i, (_e1494.z > 0f));
                                }
                                let _e1515 = phi_4625_;
                                phi_4624_ = _e1515;
                                phi_4622_ = select(_e1495.z, _e1495.y, _e1507);
                            }
                            let _e1518 = phi_4624_;
                            let _e1520 = phi_4622_;
                            if (_e1520 <= 0f) {
                                phi_4648_ = 1f;
                                break;
                            }
                            local_4 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                            let _e1523 = local_4[_e1518];
                            local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                            let _e1526 = local_5[_e1518];
                            let _e1531 = global.member_24[2u];
                            let _e1534 = (vec2<f32>(dot(_e1494, _e1523), dot(_e1494, _e1526)) / vec2((_e1520 * _e1531)));
                            let _e1538 = (_e1476.z + (_e1476.w / _e1520));
                            if (_e1538 > 1f) {
                                phi_4648_ = 1f;
                                break;
                            }
                            let _e1553 = global.member_24;
                            let _e1554 = _e1553.xy;
                            let _e1556 = (_e1476.xy + (vec2<f32>(f32((_e1518 - (i32(floor((f32(_e1518) / f32(3i)))) * 3i))), f32((_e1518 / 3i))) * _e1554));
                            let _e1565 = global.member_22;
                            let _e1566 = _e1565.xy;
                            let _e1567 = (_e1566 * 0.5f);
                            let _e1569 = (_e1556 + (vec2<f32>((0.5f + (0.5f * _e1534.x)), (0.5f - (0.5f * _e1534.y))) * _e1554));
                            let _e1570 = (_e1556 + _e1567);
                            let _e1572 = ((_e1556 + _e1554) - _e1567);
                            let _e1577 = vec4<f32>(_e1570.x, _e1570.y, _e1572.x, _e1572.y);
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e1581 = global.member_22[2u];
                                    let _e1582 = i32(_e1581);
                                    if (_e1582 <= 0i) {
                                        let _e1586 = clamp(_e1569, _e1577.xy, _e1577.zw);
                                        let _e1591 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1586.x, _e1586.y, _e1538).xy, _e1538);
                                        phi_4636_ = _e1591;
                                        break;
                                    }
                                    let _e1593 = ((_e1569 / _e1566) + vec2<f32>(0.5f, 0.5f));
                                    let _e1594 = floor(_e1593);
                                    let _e1595 = (_e1593 - _e1594);
                                    let _e1597 = (_e1582 == 1i);
                                    if _e1597 {
                                        let _e1598 = (_e1595 * 2f);
                                        local[0i] = (vec2<f32>(3f, 3f) - _e1598);
                                        local[1i] = (vec2<f32>(1f, 1f) + _e1598);
                                        let _e1604 = local[0i];
                                        local_1[0i] = (((vec2<f32>(2f, 2f) - _e1595) / _e1604) - vec2<f32>(1f, 1f));
                                        let _e1608 = local[1i];
                                        local_1[1i] = ((_e1595 / _e1608) + vec2<f32>(1f, 1f));
                                    } else {
                                        let _e1612 = (_e1595 * 3f);
                                        local[0i] = (vec2<f32>(4f, 4f) - _e1612);
                                        local[1i] = vec2<f32>(7f, 7f);
                                        local[2i] = (vec2<f32>(1f, 1f) + _e1612);
                                        let _e1620 = local[0i];
                                        local_1[0i] = (((vec2<f32>(3f, 3f) - (_e1595 * 2f)) / _e1620) - vec2<f32>(2f, 2f));
                                        let _e1625 = local[1i];
                                        local_1[1i] = ((vec2<f32>(3f, 3f) + _e1595) / _e1625);
                                        let _e1628 = local[2i];
                                        local_1[2i] = ((_e1595 / _e1628) + vec2<f32>(2f, 2f));
                                    }
                                    let _e1633 = select(3i, 2i, _e1597);
                                    phi_4629_ = 0f;
                                    phi_4626_ = 0i;
                                    loop {
                                        let _e1635 = phi_4629_;
                                        let _e1637 = phi_4626_;
                                        local_26 = _e1635;
                                        if (_e1637 < _e1633) {
                                            phi_4635_ = _e1635;
                                            phi_4632_ = 0i;
                                            loop {
                                                let _e1640 = phi_4635_;
                                                let _e1642 = phi_4632_;
                                                local_31 = _e1640;
                                                if (_e1642 < _e1633) {
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e1646 = local_1[_e1642][0u];
                                                    let _e1649 = local_1[_e1637][1u];
                                                    let _e1655 = clamp((_e1566 * ((_e1594 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1646, _e1649))), _e1577.xy, _e1577.zw);
                                                    let _e1658 = local[_e1642][0u];
                                                    let _e1661 = local[_e1637][1u];
                                                    let _e1667 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1655.x, _e1655.y, _e1538).xy, _e1538);
                                                    phi_4635_ = (_e1640 + ((_e1658 * _e1661) * _e1667));
                                                    phi_4632_ = (_e1642 + 1i);
                                                }
                                            }
                                            continue;
                                        } else {
                                            break;
                                        }
                                        continuing {
                                            let _e1855 = local_31;
                                            phi_4629_ = _e1855;
                                            phi_4626_ = (_e1637 + 1i);
                                        }
                                    }
                                    let _e1673 = local_26;
                                    phi_4636_ = (_e1673 * select(0.0069444445f, 0.0625f, _e1597));
                                    break;
                                }
                            }
                            let _e1676 = phi_4636_;
                            phi_4648_ = _e1676;
                            break;
                        }
                    }
                    let _e1678 = phi_4648_;
                    phi_4700_ = (_e1281 * _e1678);
                }
                let _e1681 = phi_4700_;
                let _e1685 = clamp(((dot(_e608, _e1260) * 0.6f) + 0.4f), 0f, 1f);
                local_29 = (_e1228 + (((_e1040 * _e1685) * _e1685) * _e1681));
                continue;
            } else {
                break;
            }
            continuing {
                let _e1835 = local_29;
                phi_4573_ = _e1835;
                phi_4569_ = (_e1230 + bitcast<u32>(1i));
            }
        }
        let _e1865 = local_32;
        phi_4572_ = _e1865;
    }
    let _e1693 = phi_4572_;
    let _e1695 = -(length(_e619));
    let _e1698 = global.member_7[3u];
    let _e1704 = global.member_9[3u];
    phi_4575_ = (1f - exp((_e1695 * _e1698)));
    if (_e1704 != 0f) {
        let _e1708 = (_e1704 * (_e618 - _e617).y);
        if (abs(_e1708) < 0.0001f) {
            phi_4570_ = (1f - (0.5f * _e1708));
        } else {
            phi_4570_ = ((1f - exp(min(-(_e1708), 60f))) / _e1708);
        }
        let _e1719 = phi_4570_;
        let _e1723 = global.member_6[1u];
        let _e1726 = global.member_6[3u];
        phi_4575_ = (1f - exp(((_e1695 * (_e1698 * exp(min((-(_e1704) * (_e1723 - _e1726)), 30f)))) * _e1719)));
    }
    let _e1737 = phi_4575_;
    let _e1739 = global.member_7;
    let _e1742 = mix(_e1693, _e1739.xyz, vec3(_e1737));
    let _e1745 = global.member_33[3u];
    phi_4576_ = _e1742;
    if (_e1745 > 0.5f) {
        phi_4576_ = (_e1742 / (vec3<f32>(1f, 1f, 1f) + _e1742));
    }
    let _e1750 = phi_4576_;
    global_23 = vec4<f32>(_e1750.x, _e1750.y, _e1750.z, _e571);
    let _e1755 = global_25;
    let _e1756 = global_26;
    switch bitcast<i32>(0u) {
        default: {
            if (_e1756.w <= 0f) {
                phi_4618_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_4618_ = (((_e1756.xy / vec2(_e1756.w)) - (_e1755.xy / vec2(_e1755.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e1770 = phi_4618_;
    global_24 = _e1770;
    return;
}

@fragment 
fn main(@location(0) param: vec3<f32>, @builtin(position) param_1: vec4<f32>, @location(8) param_2: vec4<f32>, @location(2) param_3: vec2<f32>, @location(4) param_4: vec3<f32>, @location(10) param_5: vec3<f32>, @location(3) param_6: vec4<f32>, @location(1) param_7: vec3<f32>, @builtin(front_facing) param_8: bool, @location(9) param_9: vec3<f32>, @location(5) param_10: vec4<f32>, @location(6) param_11: vec4<f32>, @location(7) param_12: vec4<f32>) -> FragmentOutput {
    global_6 = param;
    global_9 = param_1;
    global_12 = param_2;
    global_15 = param_3;
    global_16 = param_4;
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
