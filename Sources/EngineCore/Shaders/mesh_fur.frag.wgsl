// Generated from mesh_fur.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 449e9296fb71c82b
// glsl-fnv1a64: bb19ffbedd20c8f5

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

struct type_43 {
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
var<private> global_12: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_13: type_43;
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
    var local_11: array<vec2<f32>, 3>;
    var local_12: array<vec2<f32>, 3>;
    var local_13: array<vec2<f32>, 3>;
    var local_14: array<vec2<f32>, 3>;
    var local_15: array<vec2<f32>, 3>;
    var local_16: array<vec2<f32>, 3>;
    var local_17: array<vec2<f32>, 3>;
    var local_18: array<vec2<f32>, 3>;
    var local_19: array<vec3<f32>, 4>;
    var local_20: array<vec3<f32>, 4>;
    var phi_6936_: f32;
    var phi_6935_: f32;
    var phi_6971_: f32;
    var phi_6923_: vec3<f32>;
    var phi_6924_: vec3<f32>;
    var phi_6926_: vec3<f32>;
    var phi_6930_: vec3<f32>;
    var phi_6973_: f32;
    var phi_6964_: f32;
    var phi_6955_: f32;
    var phi_6946_: f32;
    var phi_6972_: f32;
    var phi_6963_: f32;
    var phi_6954_: f32;
    var phi_6945_: f32;
    var phi_6965_: f32;
    var phi_6956_: f32;
    var phi_6947_: f32;
    var phi_6938_: f32;
    var phi_6937_: bool;
    var phi_6974_: f32;
    var phi_6975_: f32;
    var phi_7246_: f32;
    var phi_2279_: bool;
    var phi_6979_: vec3<f32>;
    var phi_6980_: i32;
    var phi_3412_: bool;
    var local_21: i32;
    var local_22: i32;
    var local_23: i32;
    var phi_3541_: bool;
    var phi_3548_: bool;
    var phi_3555_: bool;
    var local_24: i32;
    var local_25: i32;
    var local_26: i32;
    var phi_6985_: f32;
    var phi_6982_: i32;
    var phi_6991_: f32;
    var phi_6988_: i32;
    var local_27: f32;
    var phi_6992_: f32;
    var local_28: bool;
    var local_29: i32;
    var phi_6996_: f32;
    var phi_6993_: i32;
    var phi_7002_: f32;
    var phi_6999_: i32;
    var local_30: f32;
    var phi_7003_: f32;
    var local_31: bool;
    var local_32: i32;
    var phi_7011_: f32;
    var phi_7008_: i32;
    var phi_7017_: f32;
    var phi_7014_: i32;
    var local_33: f32;
    var phi_7018_: f32;
    var phi_7023_: f32;
    var local_34: i32;
    var local_35: i32;
    var local_36: i32;
    var phi_4311_: bool;
    var phi_4318_: bool;
    var phi_4325_: bool;
    var phi_7043_: f32;
    var phi_7040_: i32;
    var phi_7049_: f32;
    var phi_7046_: i32;
    var local_37: f32;
    var phi_7050_: f32;
    var local_38: bool;
    var local_39: i32;
    var phi_7054_: f32;
    var phi_7051_: i32;
    var phi_7060_: f32;
    var phi_7057_: i32;
    var local_40: f32;
    var phi_7061_: f32;
    var local_41: bool;
    var local_42: i32;
    var phi_7069_: f32;
    var phi_7066_: i32;
    var phi_7075_: f32;
    var phi_7072_: i32;
    var local_43: f32;
    var phi_7076_: f32;
    var phi_7081_: f32;
    var phi_7118_: f32;
    var phi_7115_: vec3<f32>;
    var phi_7117_: f32;
    var phi_7114_: vec3<f32>;
    var phi_7120_: vec3<f32>;
    var phi_7119_: f32;
    var phi_7239_: f32;
    var phi_7238_: vec3<f32>;
    var phi_7240_: f32;
    var phi_7287_: vec3<f32>;
    var phi_7286_: i32;
    var local_44: vec3<f32>;
    var phi_7288_: vec3<f32>;
    var phi_7300_: vec3<f32>;
    var phi_7296_: u32;
    var phi_5788_: bool;
    var phi_5795_: bool;
    var phi_5802_: bool;
    var phi_5809_: bool;
    var phi_7326_: f32;
    var phi_7323_: i32;
    var phi_7332_: f32;
    var phi_7329_: i32;
    var local_45: f32;
    var phi_7333_: f32;
    var phi_5879_: bool;
    var phi_7311_: i32;
    var phi_7310_: i32;
    var phi_7308_: f32;
    var phi_7315_: f32;
    var phi_7312_: i32;
    var phi_7321_: f32;
    var phi_7318_: i32;
    var local_46: f32;
    var phi_7322_: f32;
    var phi_7334_: f32;
    var phi_7335_: f32;
    var phi_7371_: f32;
    var phi_7299_: vec3<f32>;
    var phi_7297_: f32;
    var phi_7302_: f32;
    var phi_7303_: vec3<f32>;
    var phi_7304_: vec2<f32>;
    var local_47: f32;
    var local_48: f32;
    var local_49: f32;
    var local_50: f32;
    var local_51: f32;
    var local_52: f32;
    var local_53: vec3<f32>;
    var local_54: f32;
    var local_55: f32;
    var local_56: vec3<f32>;

    let _e208 = global_12[0u];
    let _e210 = global_12[2u];
    let _e211 = (_e210 > 0.5f);
    let _e213 = global_12[3u];
    let _e214 = (_e213 > 0.5f);
    let _e217 = global_13.member_1[0i];
    let _e220 = global_13.member_1[2i];
    switch bitcast<i32>(0u) {
        default: {
            let _e224 = global_13.member_1[1i];
            let _e228 = global_13.member_1[6i][2u];
            phi_6935_ = 1f;
            if (_e228 > 0.5f) {
                let _e230 = global_15;
                let _e231 = textureSample(global_14, global_4, _e230);
                let _e236 = global_13.member_1[6i][3u];
                phi_6936_ = _e231.x;
                if (_e236 > 0.5f) {
                    phi_6936_ = (1f - _e231.x);
                }
                let _e240 = phi_6936_;
                phi_6935_ = _e240;
            }
            let _e242 = phi_6935_;
            if _e214 {
                if (_e242 < 0.02f) {
                    phi_6965_ = 0f;
                    phi_6956_ = 1f;
                    phi_6947_ = 0.5f;
                    phi_6938_ = 0f;
                    phi_6937_ = false;
                    break;
                }
                let _e244 = global_16;
                let _e252 = bitcast<vec3<u32>>((vec3<i32>(floor((_e244 / vec3(max(_e217.y, 0.00001f))))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e260 = (((_e252.x * 1597334677u) ^ (_e252.y * 3812015801u)) ^ (_e252.z * 2798796415u));
                let _e264 = ((_e260 ^ (_e260 >> bitcast<u32>(15i))) * 2246822519u);
                let _e268 = ((_e264 ^ (_e264 >> bitcast<u32>(13i))) * 3266489917u);
                let _e272 = ((_e268 ^ (_e268 >> bitcast<u32>(16i))) * 668265263u);
                phi_6972_ = 0f;
                phi_6963_ = 1f;
                phi_6954_ = (vec3<f32>(f32(), f32(), f32(((_e272 ^ (_e272 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).z;
                phi_6945_ = 0f;
            } else {
                if !(_e211) {
                    let _e283 = max(_e217.y, 0.00001f);
                    let _e284 = global_17;
                    let _e285 = normalize(_e284);
                    let _e286 = global_16;
                    phi_6971_ = 0f;
                    phi_6923_ = _e286;
                    if (_e224.x > 0f) {
                        let _e289 = (_e283 * 4f);
                        let _e292 = floor((_e286 / vec3(_e289)));
                        let _e297 = bitcast<vec3<u32>>((vec3<i32>((_e292 + vec3<f32>(31f, 17f, 5f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                        let _e305 = (((_e297.x * 1597334677u) ^ (_e297.y * 3812015801u)) ^ (_e297.z * 2798796415u));
                        let _e309 = ((_e305 ^ (_e305 >> bitcast<u32>(15i))) * 2246822519u);
                        let _e312 = (_e309 ^ (_e309 >> bitcast<u32>(13i)));
                        let _e313 = (_e312 * 3266489917u);
                        let _e316 = (_e313 ^ (_e313 >> bitcast<u32>(16i)));
                        let _e317 = (_e316 * 668265263u);
                        let _e332 = (((_e292 + vec3<f32>(0.5f, 0.5f, 0.5f)) + (((vec3<f32>(f32((_e312 & 65535u)), f32((_e316 & 65535u)), f32(((_e317 ^ (_e317 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)) - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.6f)) * _e289);
                        let _e336 = (_e332 - (_e285 * dot((_e332 - _e286), _e285)));
                        let _e337 = (_e286 - _e336);
                        phi_6971_ = (_e224.x * smoothstep(0.15f, 0.6f, (length(_e337) / _e289)));
                        phi_6923_ = (_e336 + (_e337 / vec3((1f - min(((_e224.x * _e208) * 0.85f), 0.9f)))));
                    }
                    let _e350 = phi_6971_;
                    let _e352 = phi_6923_;
                    let _e355 = floor((_e352 / vec3(_e283)));
                    let _e358 = bitcast<vec3<u32>>((vec3<i32>(_e355) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e366 = (((_e358.x * 1597334677u) ^ (_e358.y * 3812015801u)) ^ (_e358.z * 2798796415u));
                    let _e370 = ((_e366 ^ (_e366 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e373 = (_e370 ^ (_e370 >> bitcast<u32>(13i)));
                    let _e374 = (_e373 * 3266489917u);
                    let _e377 = (_e374 ^ (_e374 >> bitcast<u32>(16i)));
                    let _e378 = (_e377 * 668265263u);
                    let _e389 = (vec3<f32>(f32((_e373 & 65535u)), f32((_e377 & 65535u)), f32(((_e378 ^ (_e378 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                    let _e394 = (((_e355 + vec3<f32>(0.5f, 0.5f, 0.5f)) + ((_e389 - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.5f)) * _e283);
                    if (abs(_e285.y) < 0.9f) {
                        phi_6924_ = cross(_e285, vec3<f32>(0f, 1f, 0f));
                    } else {
                        phi_6924_ = cross(_e285, vec3<f32>(1f, 0f, 0f));
                    }
                    let _e401 = phi_6924_;
                    let _e402 = normalize(_e401);
                    phi_6926_ = _e394;
                    if (_e224.y > 0f) {
                        let _e409 = ((_e208 * 12.566f) + (_e389.x * 6.283f));
                        phi_6926_ = (_e394 + (((_e402 * cos(_e409)) + (cross(_e285, _e402) * sin(_e409))) * ((_e224.y * 0.3f) * _e283)));
                    }
                    let _e420 = phi_6926_;
                    phi_6930_ = _e420;
                    if (_e224.z > 0f) {
                        let _e423 = (_e208 * 4f);
                        let _e425 = (floor(_e423) * 7f);
                        let _e430 = bitcast<vec3<u32>>((vec3<i32>((_e355 + vec3<f32>(_e425, 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                        let _e438 = (((_e430.x * 1597334677u) ^ (_e430.y * 3812015801u)) ^ (_e430.z * 2798796415u));
                        let _e442 = ((_e438 ^ (_e438 >> bitcast<u32>(15i))) * 2246822519u);
                        let _e445 = (_e442 ^ (_e442 >> bitcast<u32>(13i)));
                        let _e446 = (_e445 * 3266489917u);
                        let _e449 = (_e446 ^ (_e446 >> bitcast<u32>(16i)));
                        let _e450 = (_e449 * 668265263u);
                        let _e467 = bitcast<vec3<u32>>((vec3<i32>((_e355 + vec3<f32>((_e425 + 7f), 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                        let _e475 = (((_e467.x * 1597334677u) ^ (_e467.y * 3812015801u)) ^ (_e467.z * 2798796415u));
                        let _e479 = ((_e475 ^ (_e475 >> bitcast<u32>(15i))) * 2246822519u);
                        let _e482 = (_e479 ^ (_e479 >> bitcast<u32>(13i)));
                        let _e483 = (_e482 * 3266489917u);
                        let _e486 = (_e483 ^ (_e483 >> bitcast<u32>(16i)));
                        let _e487 = (_e486 * 668265263u);
                        phi_6930_ = (_e420 + ((mix((vec3<f32>(f32((_e445 & 65535u)), f32((_e449 & 65535u)), f32(((_e450 ^ (_e450 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), (vec3<f32>(f32((_e482 & 65535u)), f32((_e486 & 65535u)), f32(((_e487 ^ (_e487 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), vec3(smoothstep(0f, 1f, fract(_e423)))) - vec3<f32>(0.5f, 0.5f, 0.5f)) * (((_e224.z * 0.4f) * _e283) * _e208)));
                    }
                    let _e510 = phi_6930_;
                    let _e511 = (_e352 - _e510);
                    let _e514 = (_e511 - (_e285 * dot(_e511, _e285)));
                    let _e520 = ((1f - (_e220.y * _e389.y)) * min(_e242, 1f));
                    if (_e208 > _e520) {
                        phi_6965_ = _e350;
                        phi_6956_ = 1f;
                        phi_6947_ = 0.5f;
                        phi_6938_ = 0f;
                        phi_6937_ = false;
                        break;
                    }
                    let _e525 = (_e208 / max(_e520, 0.001f));
                    let _e528 = ((mix(_e217.z, _e217.w, _e525) * 0.5f) * _e283);
                    if (dot(_e514, _e514) > (_e528 * _e528)) {
                        phi_6965_ = _e350;
                        phi_6956_ = 1f;
                        phi_6947_ = 0.5f;
                        phi_6938_ = 0f;
                        phi_6937_ = false;
                        break;
                    }
                    phi_6973_ = _e350;
                    phi_6964_ = 1f;
                    phi_6955_ = _e389.z;
                    phi_6946_ = _e525;
                } else {
                    let _e536 = global_13.member_1[4i][3u];
                    let _e539 = global_15[0u];
                    let _e540 = (_e539 * max(_e536, 1f));
                    let _e543 = global_12[1u];
                    let _e549 = bitcast<vec3<u32>>((vec3<i32>(vec3<f32>(floor(_e540), floor((_e543 * 65535f)), 7f)) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e557 = (((_e549.x * 1597334677u) ^ (_e549.y * 3812015801u)) ^ (_e549.z * 2798796415u));
                    let _e561 = ((_e557 ^ (_e557 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e564 = (_e561 ^ (_e561 >> bitcast<u32>(13i)));
                    let _e565 = (_e564 * 3266489917u);
                    let _e568 = (_e565 ^ (_e565 >> bitcast<u32>(16i)));
                    let _e569 = (_e568 * 668265263u);
                    let _e580 = (vec3<f32>(f32((_e564 & 65535u)), f32((_e568 & 65535u)), f32(((_e569 ^ (_e569 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                    let _e590 = (1f - (_e220.y * _e580.y));
                    if (_e208 > _e590) {
                        phi_6965_ = 0f;
                        phi_6956_ = 1f;
                        phi_6947_ = 0.5f;
                        phi_6938_ = 0f;
                        phi_6937_ = false;
                        break;
                    }
                    let _e593 = (_e208 / max(_e590, 0.001f));
                    let _e596 = mix(_e217.z, _e217.w, _e593);
                    let _e604 = ((1f - smoothstep((_e596 * 0.275f), (_e596 * 0.5f), abs(((fract(_e540) - 0.5f) + ((_e580.x - 0.5f) * 0.3f))))) * (1f - smoothstep(0.85f, 1f, _e593)));
                    if (_e604 < 0.03f) {
                        phi_6965_ = 0f;
                        phi_6956_ = _e604;
                        phi_6947_ = 0.5f;
                        phi_6938_ = _e593;
                        phi_6937_ = false;
                        break;
                    }
                    phi_6973_ = 0f;
                    phi_6964_ = _e604;
                    phi_6955_ = _e580.z;
                    phi_6946_ = _e593;
                }
                let _e608 = phi_6973_;
                let _e610 = phi_6964_;
                let _e612 = phi_6955_;
                let _e614 = phi_6946_;
                phi_6972_ = _e608;
                phi_6963_ = _e610;
                phi_6954_ = _e612;
                phi_6945_ = _e614;
            }
            let _e616 = phi_6972_;
            let _e618 = phi_6963_;
            let _e620 = phi_6954_;
            let _e622 = phi_6945_;
            phi_6965_ = _e616;
            phi_6956_ = _e618;
            phi_6947_ = _e620;
            phi_6938_ = _e622;
            phi_6937_ = true;
            break;
        }
    }
    let _e624 = phi_6965_;
    let _e626 = phi_6956_;
    let _e628 = phi_6947_;
    let _e630 = phi_6938_;
    let _e632 = phi_6937_;
    if !(_e632) {
        discard;
    }
    let _e636 = global_13.member_1[3i];
    let _e640 = global_13.member_1[4i];
    let _e642 = (_e628 - 0.5f);
    let _e652 = global_18;
    let _e654 = ((mix(_e636.xyz, _e640.xyz, vec3(pow(_e630, 0.8f))) * max((1f + ((_e642 * 2f) * _e220.z)), 0f)) * _e652.xyz);
    if _e211 {
        phi_6974_ = 3f;
    } else {
        phi_6974_ = (((_e217.x * (_e217.z + _e217.w)) * 0.5f) / max(_e217.y, 0.00001f));
    }
    let _e665 = phi_6974_;
    let _e671 = (1f - exp(((_e665 * (1f - (0.6f * _e624))) * -0.2f)));
    if _e214 {
        phi_6975_ = 1f;
    } else {
        phi_6975_ = (1f - select(_e208, _e630, _e211));
    }
    let _e676 = phi_6975_;
    let _e685 = max(mix(exp(((_e671 * -2.5f) * _e676)), 1f, (0.3f * sqrt(clamp(dot(_e654, vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0f, 1f)))), 0.12f);
    phi_7246_ = _e685;
    if _e211 {
        phi_7246_ = (_e685 * mix(0.85f, 1f, _e628));
    }
    let _e689 = phi_7246_;
    let _e690 = global_19;
    let _e691 = normalize(_e690);
    phi_2279_ = _e211;
    if _e211 {
        let _e692 = global_20;
        phi_2279_ = !(_e692);
    }
    let _e695 = phi_2279_;
    phi_6979_ = _e691;
    if _e695 {
        phi_6979_ = -(_e691);
    }
    let _e698 = phi_6979_;
    let _e699 = global_21;
    let _e700 = normalize(_e699);
    let _e702 = global.member_4;
    let _e704 = normalize(_e702.xyz);
    let _e706 = global.member_6;
    let _e707 = _e706.xyz;
    let _e708 = global_6;
    let _e709 = (_e707 - _e708);
    let _e710 = normalize(_e709);
    let _e712 = global_22[0u];
    let _e713 = (_e712 > 0.5f);
    let _e718 = clamp(((_e217.x * 2f) / max((5f * _e671), 1f)), 0.004f, 0.06f);
    let _e721 = global.member_5[3u];
    phi_7239_ = 1f;
    phi_7238_ = _e654;
    if ((_e721 > 0.5f) && _e713) {
        switch bitcast<i32>(0u) {
            default: {
                let _e727 = global.member_21[0u];
                let _e728 = i32(_e727);
                let _e730 = global.member_20;
                let _e735 = global.member_20[3u];
                let _e736 = (dot(_e730.xyz, _e708) + _e735);
                phi_6980_ = 0i;
                loop {
                    let _e738 = phi_6980_;
                    local_21 = _e738;
                    local_22 = _e738;
                    local_23 = _e738;
                    local_24 = _e738;
                    local_25 = _e738;
                    local_26 = _e738;
                    local_34 = _e738;
                    local_35 = _e738;
                    local_36 = _e738;
                    let _e740 = (_e738 < (_e728 - 1i));
                    phi_3412_ = _e740;
                    if _e740 {
                        let _e743 = global.member_16[_e738];
                        phi_3412_ = (_e736 > _e743);
                    }
                    let _e746 = phi_3412_;
                    if _e746 {
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        phi_6980_ = (_e738 + 1i);
                    }
                }
                let _e750 = local_21;
                let _e752 = global.member_16[_e750];
                if (_e736 > _e752) {
                    phi_7120_ = vec3<f32>(1f, 1f, 1f);
                    phi_7119_ = 1f;
                    break;
                }
                let _e756 = local_22;
                let _e758 = global.member_18[_e756];
                let _e760 = (_e708 + (_e698 * _e758));
                switch bitcast<i32>(0u) {
                    default: {
                        let _e764 = local_23;
                        let _e766 = global.member_14[_e764];
                        let _e771 = (_e766 * vec4<f32>(_e760.x, _e760.y, _e760.z, 1f));
                        let _e773 = (_e771.x < 0f);
                        phi_3541_ = _e773;
                        if !(_e773) {
                            phi_3541_ = (_e771.x > 1f);
                        }
                        let _e777 = phi_3541_;
                        phi_3548_ = _e777;
                        if !(_e777) {
                            phi_3548_ = (_e771.y < 0f);
                        }
                        let _e782 = phi_3548_;
                        phi_3555_ = _e782;
                        if !(_e782) {
                            phi_3555_ = (_e771.y > 1f);
                        }
                        let _e787 = phi_3555_;
                        if _e787 {
                            phi_7023_ = 1f;
                            break;
                        }
                        let _e789 = local_24;
                        let _e793 = local_25;
                        let _e799 = global.member_23;
                        let _e800 = _e799.xy;
                        let _e801 = (vec2<f32>(f32((_e789 & 1i)), f32((_e793 >> bitcast<u32>(1i)))) * _e800);
                        let _e806 = local_26;
                        let _e808 = global.member_19[_e806];
                        let _e809 = (min(_e771.z, 1f) - _e808);
                        let _e818 = (_e718 * length(vec3<f32>(_e766[0].z, _e766[1].z, _e766[2].z)));
                        let _e820 = (_e809 - (_e818 * 0.18f));
                        let _e823 = global.member_22;
                        let _e824 = _e823.xy;
                        let _e825 = (_e824 * 0.5f);
                        let _e827 = (_e801 + (_e771.xy * _e800));
                        let _e828 = (_e801 + _e825);
                        let _e830 = ((_e801 + _e800) - _e825);
                        let _e835 = vec4<f32>(_e828.x, _e828.y, _e830.x, _e830.y);
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e839 = global.member_22[2u];
                                let _e840 = i32(_e839);
                                let _e841 = (_e840 <= 0i);
                                local_28 = _e841;
                                local_29 = _e840;
                                local_31 = _e841;
                                local_32 = _e840;
                                if _e841 {
                                    let _e844 = clamp(_e827, _e835.xy, _e835.zw);
                                    let _e849 = textureSampleCompare(global_1, global_3, vec3<f32>(_e844.x, _e844.y, _e820).xy, _e820);
                                    phi_6992_ = _e849;
                                    break;
                                }
                                let _e851 = ((_e827 / _e824) + vec2<f32>(0.5f, 0.5f));
                                let _e852 = floor(_e851);
                                let _e853 = (_e851 - _e852);
                                let _e855 = (_e840 == 1i);
                                if _e855 {
                                    let _e856 = (_e853 * 2f);
                                    local_17[0i] = (vec2<f32>(3f, 3f) - _e856);
                                    local_17[1i] = (vec2<f32>(1f, 1f) + _e856);
                                    let _e862 = local_17[0i];
                                    local_18[0i] = (((vec2<f32>(2f, 2f) - _e853) / _e862) - vec2<f32>(1f, 1f));
                                    let _e866 = local_17[1i];
                                    local_18[1i] = ((_e853 / _e866) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e870 = (_e853 * 3f);
                                    local_17[0i] = (vec2<f32>(4f, 4f) - _e870);
                                    local_17[1i] = vec2<f32>(7f, 7f);
                                    local_17[2i] = (vec2<f32>(1f, 1f) + _e870);
                                    let _e878 = local_17[0i];
                                    local_18[0i] = (((vec2<f32>(3f, 3f) - (_e853 * 2f)) / _e878) - vec2<f32>(2f, 2f));
                                    let _e883 = local_17[1i];
                                    local_18[1i] = ((vec2<f32>(3f, 3f) + _e853) / _e883);
                                    let _e886 = local_17[2i];
                                    local_18[2i] = ((_e853 / _e886) + vec2<f32>(2f, 2f));
                                }
                                let _e891 = select(3i, 2i, _e855);
                                phi_6985_ = 0f;
                                phi_6982_ = 0i;
                                loop {
                                    let _e893 = phi_6985_;
                                    let _e895 = phi_6982_;
                                    local_27 = _e893;
                                    if (_e895 < _e891) {
                                        phi_6991_ = _e893;
                                        phi_6988_ = 0i;
                                        loop {
                                            let _e898 = phi_6991_;
                                            let _e900 = phi_6988_;
                                            local_47 = _e898;
                                            if (_e900 < _e891) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e904 = local_18[_e900][0u];
                                                let _e907 = local_18[_e895][1u];
                                                let _e913 = clamp((_e824 * ((_e852 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e904, _e907))), _e835.xy, _e835.zw);
                                                let _e916 = local_17[_e900][0u];
                                                let _e919 = local_17[_e895][1u];
                                                let _e925 = textureSampleCompare(global_1, global_3, vec3<f32>(_e913.x, _e913.y, _e820).xy, _e820);
                                                phi_6991_ = (_e898 + ((_e916 * _e919) * _e925));
                                                phi_6988_ = (_e900 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e2588 = local_47;
                                        phi_6985_ = _e2588;
                                        phi_6982_ = (_e895 + 1i);
                                    }
                                }
                                let _e931 = local_27;
                                phi_6992_ = (_e931 * select(0.0069444445f, 0.0625f, _e855));
                                break;
                            }
                        }
                        let _e934 = phi_6992_;
                        let _e936 = (_e809 - (_e818 * 0.69f));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e939 = local_28;
                                if _e939 {
                                    let _e942 = clamp(_e827, _e835.xy, _e835.zw);
                                    let _e947 = textureSampleCompare(global_1, global_3, vec3<f32>(_e942.x, _e942.y, _e936).xy, _e936);
                                    phi_7003_ = _e947;
                                    break;
                                }
                                let _e949 = ((_e827 / _e824) + vec2<f32>(0.5f, 0.5f));
                                let _e950 = floor(_e949);
                                let _e951 = (_e949 - _e950);
                                let _e954 = local_29;
                                let _e955 = (_e954 == 1i);
                                if _e955 {
                                    let _e956 = (_e951 * 2f);
                                    local_15[0i] = (vec2<f32>(3f, 3f) - _e956);
                                    local_15[1i] = (vec2<f32>(1f, 1f) + _e956);
                                    let _e962 = local_15[0i];
                                    local_16[0i] = (((vec2<f32>(2f, 2f) - _e951) / _e962) - vec2<f32>(1f, 1f));
                                    let _e966 = local_15[1i];
                                    local_16[1i] = ((_e951 / _e966) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e970 = (_e951 * 3f);
                                    local_15[0i] = (vec2<f32>(4f, 4f) - _e970);
                                    local_15[1i] = vec2<f32>(7f, 7f);
                                    local_15[2i] = (vec2<f32>(1f, 1f) + _e970);
                                    let _e978 = local_15[0i];
                                    local_16[0i] = (((vec2<f32>(3f, 3f) - (_e951 * 2f)) / _e978) - vec2<f32>(2f, 2f));
                                    let _e983 = local_15[1i];
                                    local_16[1i] = ((vec2<f32>(3f, 3f) + _e951) / _e983);
                                    let _e986 = local_15[2i];
                                    local_16[2i] = ((_e951 / _e986) + vec2<f32>(2f, 2f));
                                }
                                let _e991 = select(3i, 2i, _e955);
                                phi_6996_ = 0f;
                                phi_6993_ = 0i;
                                loop {
                                    let _e993 = phi_6996_;
                                    let _e995 = phi_6993_;
                                    local_30 = _e993;
                                    if (_e995 < _e991) {
                                        phi_7002_ = _e993;
                                        phi_6999_ = 0i;
                                        loop {
                                            let _e998 = phi_7002_;
                                            let _e1000 = phi_6999_;
                                            local_48 = _e998;
                                            if (_e1000 < _e991) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e1004 = local_16[_e1000][0u];
                                                let _e1007 = local_16[_e995][1u];
                                                let _e1013 = clamp((_e824 * ((_e950 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1004, _e1007))), _e835.xy, _e835.zw);
                                                let _e1016 = local_15[_e1000][0u];
                                                let _e1019 = local_15[_e995][1u];
                                                let _e1025 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1013.x, _e1013.y, _e936).xy, _e936);
                                                phi_7002_ = (_e998 + ((_e1016 * _e1019) * _e1025));
                                                phi_6999_ = (_e1000 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e2598 = local_48;
                                        phi_6996_ = _e2598;
                                        phi_6993_ = (_e995 + 1i);
                                    }
                                }
                                let _e1031 = local_30;
                                phi_7003_ = (_e1031 * select(0.0069444445f, 0.0625f, _e955));
                                break;
                            }
                        }
                        let _e1034 = phi_7003_;
                        let _e1037 = (_e809 - (_e818 * 1.79f));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1040 = local_31;
                                if _e1040 {
                                    let _e1043 = clamp(_e827, _e835.xy, _e835.zw);
                                    let _e1048 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1043.x, _e1043.y, _e1037).xy, _e1037);
                                    phi_7018_ = _e1048;
                                    break;
                                }
                                let _e1050 = ((_e827 / _e824) + vec2<f32>(0.5f, 0.5f));
                                let _e1051 = floor(_e1050);
                                let _e1052 = (_e1050 - _e1051);
                                let _e1055 = local_32;
                                let _e1056 = (_e1055 == 1i);
                                if _e1056 {
                                    let _e1057 = (_e1052 * 2f);
                                    local_13[0i] = (vec2<f32>(3f, 3f) - _e1057);
                                    local_13[1i] = (vec2<f32>(1f, 1f) + _e1057);
                                    let _e1063 = local_13[0i];
                                    local_14[0i] = (((vec2<f32>(2f, 2f) - _e1052) / _e1063) - vec2<f32>(1f, 1f));
                                    let _e1067 = local_13[1i];
                                    local_14[1i] = ((_e1052 / _e1067) + vec2<f32>(1f, 1f));
                                } else {
                                    let _e1071 = (_e1052 * 3f);
                                    local_13[0i] = (vec2<f32>(4f, 4f) - _e1071);
                                    local_13[1i] = vec2<f32>(7f, 7f);
                                    local_13[2i] = (vec2<f32>(1f, 1f) + _e1071);
                                    let _e1079 = local_13[0i];
                                    local_14[0i] = (((vec2<f32>(3f, 3f) - (_e1052 * 2f)) / _e1079) - vec2<f32>(2f, 2f));
                                    let _e1084 = local_13[1i];
                                    local_14[1i] = ((vec2<f32>(3f, 3f) + _e1052) / _e1084);
                                    let _e1087 = local_13[2i];
                                    local_14[2i] = ((_e1052 / _e1087) + vec2<f32>(2f, 2f));
                                }
                                let _e1092 = select(3i, 2i, _e1056);
                                phi_7011_ = 0f;
                                phi_7008_ = 0i;
                                loop {
                                    let _e1094 = phi_7011_;
                                    let _e1096 = phi_7008_;
                                    local_33 = _e1094;
                                    if (_e1096 < _e1092) {
                                        phi_7017_ = _e1094;
                                        phi_7014_ = 0i;
                                        loop {
                                            let _e1099 = phi_7017_;
                                            let _e1101 = phi_7014_;
                                            local_49 = _e1099;
                                            if (_e1101 < _e1092) {
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e1105 = local_14[_e1101][0u];
                                                let _e1108 = local_14[_e1096][1u];
                                                let _e1114 = clamp((_e824 * ((_e1051 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1105, _e1108))), _e835.xy, _e835.zw);
                                                let _e1117 = local_13[_e1101][0u];
                                                let _e1120 = local_13[_e1096][1u];
                                                let _e1126 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1114.x, _e1114.y, _e1037).xy, _e1037);
                                                phi_7017_ = (_e1099 + ((_e1117 * _e1120) * _e1126));
                                                phi_7014_ = (_e1101 + 1i);
                                            }
                                        }
                                        continue;
                                    } else {
                                        break;
                                    }
                                    continuing {
                                        let _e2608 = local_49;
                                        phi_7011_ = _e2608;
                                        phi_7008_ = (_e1096 + 1i);
                                    }
                                }
                                let _e1132 = local_33;
                                phi_7018_ = (_e1132 * select(0.0069444445f, 0.0625f, _e1056));
                                break;
                            }
                        }
                        let _e1135 = phi_7018_;
                        phi_7023_ = (((_e934 + _e1034) + _e1135) * 0.33333334f);
                        break;
                    }
                }
                let _e1139 = phi_7023_;
                local_19 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                let _e1141 = local_34;
                let _e1143 = local_19[_e1141];
                let _e1146 = local_35;
                let _e1148 = global.member_17[_e1146];
                phi_7117_ = _e1139;
                phi_7114_ = _e1143;
                if (_e736 > _e1148) {
                    let _e1152 = ((_e736 - _e1148) / (_e752 - _e1148));
                    let _e1154 = local_36;
                    let _e1155 = (_e1154 + 1i);
                    if (_e1155 < _e728) {
                        let _e1159 = global.member_18[_e1155];
                        let _e1161 = (_e708 + (_e698 * _e1159));
                        switch bitcast<i32>(0u) {
                            default: {
                                let _e1165 = global.member_14[_e1155];
                                let _e1170 = (_e1165 * vec4<f32>(_e1161.x, _e1161.y, _e1161.z, 1f));
                                let _e1172 = (_e1170.x < 0f);
                                phi_4311_ = _e1172;
                                if !(_e1172) {
                                    phi_4311_ = (_e1170.x > 1f);
                                }
                                let _e1176 = phi_4311_;
                                phi_4318_ = _e1176;
                                if !(_e1176) {
                                    phi_4318_ = (_e1170.y < 0f);
                                }
                                let _e1181 = phi_4318_;
                                phi_4325_ = _e1181;
                                if !(_e1181) {
                                    phi_4325_ = (_e1170.y > 1f);
                                }
                                let _e1186 = phi_4325_;
                                if _e1186 {
                                    phi_7081_ = 1f;
                                    break;
                                }
                                let _e1194 = global.member_23;
                                let _e1195 = _e1194.xy;
                                let _e1196 = (vec2<f32>(f32((_e1155 & 1i)), f32((_e1155 >> bitcast<u32>(1i)))) * _e1195);
                                let _e1201 = global.member_19[_e1155];
                                let _e1202 = (min(_e1170.z, 1f) - _e1201);
                                let _e1211 = (_e718 * length(vec3<f32>(_e1165[0].z, _e1165[1].z, _e1165[2].z)));
                                let _e1213 = (_e1202 - (_e1211 * 0.18f));
                                let _e1216 = global.member_22;
                                let _e1217 = _e1216.xy;
                                let _e1218 = (_e1217 * 0.5f);
                                let _e1220 = (_e1196 + (_e1170.xy * _e1195));
                                let _e1221 = (_e1196 + _e1218);
                                let _e1223 = ((_e1196 + _e1195) - _e1218);
                                let _e1228 = vec4<f32>(_e1221.x, _e1221.y, _e1223.x, _e1223.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1232 = global.member_22[2u];
                                        let _e1233 = i32(_e1232);
                                        let _e1234 = (_e1233 <= 0i);
                                        local_38 = _e1234;
                                        local_39 = _e1233;
                                        local_41 = _e1234;
                                        local_42 = _e1233;
                                        if _e1234 {
                                            let _e1237 = clamp(_e1220, _e1228.xy, _e1228.zw);
                                            let _e1242 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1237.x, _e1237.y, _e1213).xy, _e1213);
                                            phi_7050_ = _e1242;
                                            break;
                                        }
                                        let _e1244 = ((_e1220 / _e1217) + vec2<f32>(0.5f, 0.5f));
                                        let _e1245 = floor(_e1244);
                                        let _e1246 = (_e1244 - _e1245);
                                        let _e1248 = (_e1233 == 1i);
                                        if _e1248 {
                                            let _e1249 = (_e1246 * 2f);
                                            local_11[0i] = (vec2<f32>(3f, 3f) - _e1249);
                                            local_11[1i] = (vec2<f32>(1f, 1f) + _e1249);
                                            let _e1255 = local_11[0i];
                                            local_12[0i] = (((vec2<f32>(2f, 2f) - _e1246) / _e1255) - vec2<f32>(1f, 1f));
                                            let _e1259 = local_11[1i];
                                            local_12[1i] = ((_e1246 / _e1259) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1263 = (_e1246 * 3f);
                                            local_11[0i] = (vec2<f32>(4f, 4f) - _e1263);
                                            local_11[1i] = vec2<f32>(7f, 7f);
                                            local_11[2i] = (vec2<f32>(1f, 1f) + _e1263);
                                            let _e1271 = local_11[0i];
                                            local_12[0i] = (((vec2<f32>(3f, 3f) - (_e1246 * 2f)) / _e1271) - vec2<f32>(2f, 2f));
                                            let _e1276 = local_11[1i];
                                            local_12[1i] = ((vec2<f32>(3f, 3f) + _e1246) / _e1276);
                                            let _e1279 = local_11[2i];
                                            local_12[2i] = ((_e1246 / _e1279) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1284 = select(3i, 2i, _e1248);
                                        phi_7043_ = 0f;
                                        phi_7040_ = 0i;
                                        loop {
                                            let _e1286 = phi_7043_;
                                            let _e1288 = phi_7040_;
                                            local_37 = _e1286;
                                            if (_e1288 < _e1284) {
                                                phi_7049_ = _e1286;
                                                phi_7046_ = 0i;
                                                loop {
                                                    let _e1291 = phi_7049_;
                                                    let _e1293 = phi_7046_;
                                                    local_50 = _e1291;
                                                    if (_e1293 < _e1284) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1297 = local_12[_e1293][0u];
                                                        let _e1300 = local_12[_e1288][1u];
                                                        let _e1306 = clamp((_e1217 * ((_e1245 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1297, _e1300))), _e1228.xy, _e1228.zw);
                                                        let _e1309 = local_11[_e1293][0u];
                                                        let _e1312 = local_11[_e1288][1u];
                                                        let _e1318 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1306.x, _e1306.y, _e1213).xy, _e1213);
                                                        phi_7049_ = (_e1291 + ((_e1309 * _e1312) * _e1318));
                                                        phi_7046_ = (_e1293 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e2623 = local_50;
                                                phi_7043_ = _e2623;
                                                phi_7040_ = (_e1288 + 1i);
                                            }
                                        }
                                        let _e1324 = local_37;
                                        phi_7050_ = (_e1324 * select(0.0069444445f, 0.0625f, _e1248));
                                        break;
                                    }
                                }
                                let _e1327 = phi_7050_;
                                let _e1329 = (_e1202 - (_e1211 * 0.69f));
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1332 = local_38;
                                        if _e1332 {
                                            let _e1335 = clamp(_e1220, _e1228.xy, _e1228.zw);
                                            let _e1340 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1335.x, _e1335.y, _e1329).xy, _e1329);
                                            phi_7061_ = _e1340;
                                            break;
                                        }
                                        let _e1342 = ((_e1220 / _e1217) + vec2<f32>(0.5f, 0.5f));
                                        let _e1343 = floor(_e1342);
                                        let _e1344 = (_e1342 - _e1343);
                                        let _e1347 = local_39;
                                        let _e1348 = (_e1347 == 1i);
                                        if _e1348 {
                                            let _e1349 = (_e1344 * 2f);
                                            local_9[0i] = (vec2<f32>(3f, 3f) - _e1349);
                                            local_9[1i] = (vec2<f32>(1f, 1f) + _e1349);
                                            let _e1355 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(2f, 2f) - _e1344) / _e1355) - vec2<f32>(1f, 1f));
                                            let _e1359 = local_9[1i];
                                            local_10[1i] = ((_e1344 / _e1359) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1363 = (_e1344 * 3f);
                                            local_9[0i] = (vec2<f32>(4f, 4f) - _e1363);
                                            local_9[1i] = vec2<f32>(7f, 7f);
                                            local_9[2i] = (vec2<f32>(1f, 1f) + _e1363);
                                            let _e1371 = local_9[0i];
                                            local_10[0i] = (((vec2<f32>(3f, 3f) - (_e1344 * 2f)) / _e1371) - vec2<f32>(2f, 2f));
                                            let _e1376 = local_9[1i];
                                            local_10[1i] = ((vec2<f32>(3f, 3f) + _e1344) / _e1376);
                                            let _e1379 = local_9[2i];
                                            local_10[2i] = ((_e1344 / _e1379) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1384 = select(3i, 2i, _e1348);
                                        phi_7054_ = 0f;
                                        phi_7051_ = 0i;
                                        loop {
                                            let _e1386 = phi_7054_;
                                            let _e1388 = phi_7051_;
                                            local_40 = _e1386;
                                            if (_e1388 < _e1384) {
                                                phi_7060_ = _e1386;
                                                phi_7057_ = 0i;
                                                loop {
                                                    let _e1391 = phi_7060_;
                                                    let _e1393 = phi_7057_;
                                                    local_51 = _e1391;
                                                    if (_e1393 < _e1384) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1397 = local_10[_e1393][0u];
                                                        let _e1400 = local_10[_e1388][1u];
                                                        let _e1406 = clamp((_e1217 * ((_e1343 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1397, _e1400))), _e1228.xy, _e1228.zw);
                                                        let _e1409 = local_9[_e1393][0u];
                                                        let _e1412 = local_9[_e1388][1u];
                                                        let _e1418 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1406.x, _e1406.y, _e1329).xy, _e1329);
                                                        phi_7060_ = (_e1391 + ((_e1409 * _e1412) * _e1418));
                                                        phi_7057_ = (_e1393 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e2633 = local_51;
                                                phi_7054_ = _e2633;
                                                phi_7051_ = (_e1388 + 1i);
                                            }
                                        }
                                        let _e1424 = local_40;
                                        phi_7061_ = (_e1424 * select(0.0069444445f, 0.0625f, _e1348));
                                        break;
                                    }
                                }
                                let _e1427 = phi_7061_;
                                let _e1430 = (_e1202 - (_e1211 * 1.79f));
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1433 = local_41;
                                        if _e1433 {
                                            let _e1436 = clamp(_e1220, _e1228.xy, _e1228.zw);
                                            let _e1441 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1436.x, _e1436.y, _e1430).xy, _e1430);
                                            phi_7076_ = _e1441;
                                            break;
                                        }
                                        let _e1443 = ((_e1220 / _e1217) + vec2<f32>(0.5f, 0.5f));
                                        let _e1444 = floor(_e1443);
                                        let _e1445 = (_e1443 - _e1444);
                                        let _e1448 = local_42;
                                        let _e1449 = (_e1448 == 1i);
                                        if _e1449 {
                                            let _e1450 = (_e1445 * 2f);
                                            local_7[0i] = (vec2<f32>(3f, 3f) - _e1450);
                                            local_7[1i] = (vec2<f32>(1f, 1f) + _e1450);
                                            let _e1456 = local_7[0i];
                                            local_8[0i] = (((vec2<f32>(2f, 2f) - _e1445) / _e1456) - vec2<f32>(1f, 1f));
                                            let _e1460 = local_7[1i];
                                            local_8[1i] = ((_e1445 / _e1460) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e1464 = (_e1445 * 3f);
                                            local_7[0i] = (vec2<f32>(4f, 4f) - _e1464);
                                            local_7[1i] = vec2<f32>(7f, 7f);
                                            local_7[2i] = (vec2<f32>(1f, 1f) + _e1464);
                                            let _e1472 = local_7[0i];
                                            local_8[0i] = (((vec2<f32>(3f, 3f) - (_e1445 * 2f)) / _e1472) - vec2<f32>(2f, 2f));
                                            let _e1477 = local_7[1i];
                                            local_8[1i] = ((vec2<f32>(3f, 3f) + _e1445) / _e1477);
                                            let _e1480 = local_7[2i];
                                            local_8[2i] = ((_e1445 / _e1480) + vec2<f32>(2f, 2f));
                                        }
                                        let _e1485 = select(3i, 2i, _e1449);
                                        phi_7069_ = 0f;
                                        phi_7066_ = 0i;
                                        loop {
                                            let _e1487 = phi_7069_;
                                            let _e1489 = phi_7066_;
                                            local_43 = _e1487;
                                            if (_e1489 < _e1485) {
                                                phi_7075_ = _e1487;
                                                phi_7072_ = 0i;
                                                loop {
                                                    let _e1492 = phi_7075_;
                                                    let _e1494 = phi_7072_;
                                                    local_52 = _e1492;
                                                    if (_e1494 < _e1485) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e1498 = local_8[_e1494][0u];
                                                        let _e1501 = local_8[_e1489][1u];
                                                        let _e1507 = clamp((_e1217 * ((_e1444 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e1498, _e1501))), _e1228.xy, _e1228.zw);
                                                        let _e1510 = local_7[_e1494][0u];
                                                        let _e1513 = local_7[_e1489][1u];
                                                        let _e1519 = textureSampleCompare(global_1, global_3, vec3<f32>(_e1507.x, _e1507.y, _e1430).xy, _e1430);
                                                        phi_7075_ = (_e1492 + ((_e1510 * _e1513) * _e1519));
                                                        phi_7072_ = (_e1494 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e2643 = local_52;
                                                phi_7069_ = _e2643;
                                                phi_7066_ = (_e1489 + 1i);
                                            }
                                        }
                                        let _e1525 = local_43;
                                        phi_7076_ = (_e1525 * select(0.0069444445f, 0.0625f, _e1449));
                                        break;
                                    }
                                }
                                let _e1528 = phi_7076_;
                                phi_7081_ = (((_e1327 + _e1427) + _e1528) * 0.33333334f);
                                break;
                            }
                        }
                        let _e1532 = phi_7081_;
                        local_20 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
                        let _e1535 = local_20[_e1155];
                        phi_7118_ = mix(_e1139, _e1532, _e1152);
                        phi_7115_ = mix(_e1143, _e1535, vec3(_e1152));
                    } else {
                        phi_7118_ = mix(_e1139, 1f, _e1152);
                        phi_7115_ = _e1143;
                    }
                    let _e1540 = phi_7118_;
                    let _e1542 = phi_7115_;
                    phi_7117_ = _e1540;
                    phi_7114_ = _e1542;
                }
                let _e1544 = phi_7117_;
                let _e1546 = phi_7114_;
                let _e1549 = global.member_22[3u];
                phi_7120_ = select(vec3<f32>(1f, 1f, 1f), _e1546, vec3((_e1549 > 0.5f)));
                phi_7119_ = _e1544;
                break;
            }
        }
        let _e1554 = phi_7120_;
        let _e1556 = phi_7119_;
        phi_7239_ = _e1556;
        phi_7238_ = (_e654 * _e1554);
    }
    let _e1559 = phi_7239_;
    let _e1561 = phi_7238_;
    let _e1563 = (0.06f + (_e642 * 0.08f));
    let _e1564 = select(0.45f, 0.38f, _e211);
    let _e1567 = global.member_5;
    let _e1571 = global.member_4[3u];
    let _e1573 = !(_e211);
    let _e1575 = clamp(dot(_e700, _e704), -1f, 1f);
    let _e1577 = clamp(dot(_e700, _e710), -1f, 1f);
    let _e1578 = asin(_e1577);
    let _e1584 = max(cos((0.5f * abs((_e1578 - asin(_e1575))))), 0.05f);
    let _e1586 = (_e704 - (_e700 * _e1575));
    let _e1588 = (_e710 - (_e700 * _e1577));
    let _e1591 = dot(_e1588, _e1588);
    let _e1595 = (dot(_e1586, _e1588) * inverseSqrt(max((dot(_e1586, _e1586) * _e1591), 0.000001f)));
    let _e1599 = sqrt(clamp((0.5f + (0.5f * _e1595)), 0f, 1f));
    let _e1600 = (_e1564 * _e1564);
    let _e1601 = (_e1575 + _e1577);
    let _e1602 = (2f * _e1563);
    let _e1603 = (_e1601 + _e1602);
    let _e1606 = (_e1600 * _e1600);
    let _e1607 = (1.9999615f * _e1606);
    let _e1610 = (_e1600 * 3.5448735f);
    let _e1620 = (1f - clamp(sqrt(clamp((0.5f + (0.5f * dot(_e704, _e710))), 0f, 1f)), 0f, 1f));
    let _e1621 = (_e1620 * _e1620);
    let _e1630 = ((_e1600 * 0.5f) + 0.08f);
    let _e1631 = (_e1601 - _e1563);
    let _e1634 = (_e1630 * _e1630);
    let _e1637 = (2.5066283f * _e1630);
    let _e1643 = (_e1599 * (1f + (0.6451613f * (0.6f - (0.8f * _e1595)))));
    let _e1644 = (_e1643 * _e1643);
    let _e1650 = (1f - clamp((_e1584 * sqrt(clamp((1f - _e1644), 0f, 1f))), 0f, 1f));
    let _e1651 = (_e1650 * _e1650);
    let _e1655 = max(_e1561, vec3<f32>(0.0001f, 0.0001f, 0.0001f));
    let _e1667 = (0.95348f - (((0.95348f * _e1651) * _e1651) * _e1650));
    let _e1672 = (4f * _e1563);
    let _e1673 = (_e1601 - _e1672);
    let _e1676 = (7.999846f * _e1606);
    let _e1679 = (_e1600 * 7.089747f);
    let _e1683 = (1f - clamp((_e1584 * 0.5f), 0f, 1f));
    let _e1684 = (_e1683 * _e1683);
    let _e1687 = (((0.95348f * _e1684) * _e1684) * _e1683);
    let _e1696 = (0.95348f - _e1687);
    if _e1573 {
        let _e1706 = clamp(((dot(_e698, _e704) * 0.6f) + 0.4f), 0f, 1f);
        phi_7240_ = (_e1706 * _e1706);
    } else {
        phi_7240_ = mix(clamp(((dot((_e1588 * inverseSqrt(max(_e1591, 0.000001f))), _e704) + 1f) * 0.5f), 0f, 1f), (1f - abs(_e1575)), 0.33f);
    }
    let _e1719 = phi_7240_;
    let _e1723 = (_e1655 / vec3(max(dot(_e1561, vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0.0001f)));
    let _e1728 = pow(_e1655, vec3<f32>(0.92f, 0.92f, 0.92f));
    let _e1731 = (_e220.w * 3.1415927f);
    let _e1736 = mix(0.5f, 1f, _e689);
    let _e1740 = global.member_29[0u];
    if (_e1740 > 0.5f) {
        let _e1743 = global.member_29;
        let _e1750 = ((_e1743.z * _e698.x) - (_e1743.w * _e698.z));
        let _e1754 = ((_e1743.w * _e698.x) + (_e1743.z * _e698.z));
        let _e1758 = (1.092548f * _e1750);
        local_6 = array<f32, 9>(0.282095f, (0.488603f * _e698.y), (0.488603f * _e1754), (0.488603f * _e1750), (_e1758 * _e698.y), ((1.092548f * _e698.y) * _e1754), (0.315392f * (((3f * _e1754) * _e1754) - 1f)), (_e1758 * _e1754), (0.546274f * ((_e1750 * _e1750) - (_e698.y * _e698.y))));
        phi_7287_ = vec3<f32>(0f, 0f, 0f);
        phi_7286_ = 0i;
        loop {
            let _e1773 = phi_7287_;
            let _e1775 = phi_7286_;
            local_44 = _e1773;
            if (_e1775 < 9i) {
                continue;
            } else {
                break;
            }
            continuing {
                let _e1779 = textureLoad(global_2, (vec2<i32>(496i, 256i) + vec2<i32>(_e1775, 0i)), 0i);
                let _e1782 = local_6[_e1775];
                phi_7287_ = (_e1773 + (_e1779.xyz * _e1782));
                phi_7286_ = (_e1775 + 1i);
            }
        }
        let _e1787 = local_44;
        let _e1791 = global.member_29[1u];
        phi_7288_ = (max(_e1787, vec3<f32>(0f, 0f, 0f)) * _e1791);
    } else {
        let _e1794 = global.member_9;
        let _e1797 = global.member_8;
        let _e1806 = global.member_8[3u];
        phi_7288_ = (mix(_e1794.xyz, _e1797.xyz, vec3(((_e698.y * 0.5f) + 0.5f))) * _e1806);
    }
    let _e1809 = phi_7288_;
    let _e1812 = (((((((_e1728 * pow(_e1723, vec3(((1f - _e1559) * 0.35f)))) * _e1719) + (((vec3((((((exp((((-0.5f * _e1603) * _e1603) / _e1607)) / _e1610) * 0.25f) * _e1599) * (0.04652f + (((0.95348f * _e1621) * _e1621) * _e1620))) * 3f)) + (pow(_e1655, vec3((sqrt(clamp((1f - (_e1644 * 0.41623306f)), 0f, 1f)) / _e1584))) * ((((exp((((-0.5f * _e1631) * _e1631) / _e1634)) / _e1637) * exp(((-3.65f * _e1595) - 3.98f))) * _e1667) * _e1667))) + ((pow(_e1655, vec3((0.8f / _e1584))) * (((((exp((((-0.5f * _e1673) * _e1673) / _e1676)) / _e1679) * exp(((17f * _e1595) - 16.78f))) * _e1696) * _e1696) * (0.04652f + _e1687))) * 4f)) * _e1731)) * (_e1567.xyz * _e1571)) * _e1559) * _e1736) + ((_e1561 * _e1809) * _e689));
    let _e1815 = global.member_13[3u];
    phi_7299_ = _e1812;
    if (_e1815 > 0.5f) {
        let _e1818 = global.member_11;
        let _e1823 = global.member_11[3u];
        let _e1825 = global_9;
        let _e1828 = global.member_12;
        let _e1833 = global.member_13;
        let _e1836 = clamp(floor((_e1825.xy * _e1828.xy)), vec2<f32>(0f, 0f), (_e1833.xy - vec2<f32>(1f, 1f)));
        let _e1841 = global.member_12[2u];
        let _e1845 = global.member_12[3u];
        let _e1850 = global.member_13[2u];
        let _e1855 = global.member_13[1u];
        let _e1861 = global.member_13[0u];
        let _e1865 = u32(((((clamp(floor(((log2(max((dot(_e1818.xyz, _e708) + _e1823), 0.000001f)) * _e1841) + _e1845)), 0f, (_e1850 - 1f)) * _e1855) + _e1836.y) * _e1861) + _e1836.x));
        let _e1872 = global_10.member[(_e1865 >> bitcast<u32>(2i))][(_e1865 & 3u)];
        let _e1873 = (_e1872 & 65535u);
        phi_7300_ = _e1812;
        phi_7296_ = _e1873;
        loop {
            let _e1877 = phi_7300_;
            let _e1879 = phi_7296_;
            local_56 = _e1877;
            if (_e1879 < (_e1873 + (_e1872 >> bitcast<u32>(16i)))) {
                let _e1882 = (_e1879 / 3u);
                let _e1889 = global_11.member[(_e1882 >> bitcast<u32>(2i))][(_e1882 & 3u)];
                let _e1895 = ((_e1889 >> bitcast<u32>(((_e1879 - (_e1882 * 3u)) * 10u))) & 1023u);
                let _e1898 = global_5.member[_e1895];
                let _e1900 = (_e1898.xyz - _e708);
                let _e1901 = dot(_e1900, _e1900);
                let _e1903 = (_e1901 * _e1898.w);
                let _e1906 = clamp((1f - (_e1903 * _e1903)), 0f, 1f);
                let _e1909 = (_e1900 * inverseSqrt(max(_e1901, 0.00000001f)));
                let _e1912 = global_7.member[_e1895];
                let _e1915 = global_8.member[_e1895];
                let _e1923 = clamp(((dot(-(_e1909), _e1915.xyz) * _e1912.w) + _e1915.w), 0f, 1f);
                if _e713 {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e1934 = global.member_21[2u];
                            let _e1935 = u32(_e1934);
                            if (_e1895 < _e1935) {
                                let _e1939 = global.member_26[_e1895];
                                let _e1942 = global.member_15[_e1895];
                                let _e1951 = (_e1939.z * max((_e1942 * vec4<f32>(_e708.x, _e708.y, _e708.z, 1f)).w, 0f));
                                let _e1954 = global.member_25[0u];
                                let _e1960 = global.member_25[1u];
                                let _e1963 = ((_e708 + (_e698 * (_e1951 * _e1954))) + (_e1909 * (_e1951 * _e1960)));
                                let _e1968 = (_e1942 * vec4<f32>(_e1963.x, _e1963.y, _e1963.z, 1f));
                                if (_e1968.w <= 0f) {
                                    phi_7334_ = 1f;
                                    break;
                                }
                                let _e1973 = (_e1968.xyz / vec3(_e1968.w));
                                let _e1975 = (_e1973.x < 0f);
                                phi_5788_ = _e1975;
                                if !(_e1975) {
                                    phi_5788_ = (_e1973.x > 1f);
                                }
                                let _e1979 = phi_5788_;
                                phi_5795_ = _e1979;
                                if !(_e1979) {
                                    phi_5795_ = (_e1973.y < 0f);
                                }
                                let _e1984 = phi_5795_;
                                phi_5802_ = _e1984;
                                if !(_e1984) {
                                    phi_5802_ = (_e1973.y > 1f);
                                }
                                let _e1989 = phi_5802_;
                                phi_5809_ = _e1989;
                                if !(_e1989) {
                                    phi_5809_ = (_e1973.z > 1f);
                                }
                                let _e1994 = phi_5809_;
                                if _e1994 {
                                    phi_7334_ = 1f;
                                    break;
                                }
                                let _e1997 = _e1939.xy;
                                let _e1999 = global.member_23;
                                let _e2000 = _e1999.zw;
                                let _e2002 = global.member_22;
                                let _e2003 = _e2002.xy;
                                let _e2004 = (_e2003 * 0.5f);
                                let _e2006 = (_e1997 + (_e1973.xy * _e2000));
                                let _e2007 = (_e1997 + _e2004);
                                let _e2009 = ((_e1997 + _e2000) - _e2004);
                                let _e2014 = vec4<f32>(_e2007.x, _e2007.y, _e2009.x, _e2009.y);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e2018 = global.member_22[2u];
                                        let _e2019 = i32(_e2018);
                                        if (_e2019 <= 0i) {
                                            let _e2023 = clamp(_e2006, _e2014.xy, _e2014.zw);
                                            let _e2028 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2023.x, _e2023.y, _e1973.z).xy, _e1973.z);
                                            phi_7333_ = _e2028;
                                            break;
                                        }
                                        let _e2030 = ((_e2006 / _e2003) + vec2<f32>(0.5f, 0.5f));
                                        let _e2031 = floor(_e2030);
                                        let _e2032 = (_e2030 - _e2031);
                                        let _e2034 = (_e2019 == 1i);
                                        if _e2034 {
                                            let _e2035 = (_e2032 * 2f);
                                            local_2[0i] = (vec2<f32>(3f, 3f) - _e2035);
                                            local_2[1i] = (vec2<f32>(1f, 1f) + _e2035);
                                            let _e2041 = local_2[0i];
                                            local_3[0i] = (((vec2<f32>(2f, 2f) - _e2032) / _e2041) - vec2<f32>(1f, 1f));
                                            let _e2045 = local_2[1i];
                                            local_3[1i] = ((_e2032 / _e2045) + vec2<f32>(1f, 1f));
                                        } else {
                                            let _e2049 = (_e2032 * 3f);
                                            local_2[0i] = (vec2<f32>(4f, 4f) - _e2049);
                                            local_2[1i] = vec2<f32>(7f, 7f);
                                            local_2[2i] = (vec2<f32>(1f, 1f) + _e2049);
                                            let _e2057 = local_2[0i];
                                            local_3[0i] = (((vec2<f32>(3f, 3f) - (_e2032 * 2f)) / _e2057) - vec2<f32>(2f, 2f));
                                            let _e2062 = local_2[1i];
                                            local_3[1i] = ((vec2<f32>(3f, 3f) + _e2032) / _e2062);
                                            let _e2065 = local_2[2i];
                                            local_3[2i] = ((_e2032 / _e2065) + vec2<f32>(2f, 2f));
                                        }
                                        let _e2070 = select(3i, 2i, _e2034);
                                        phi_7326_ = 0f;
                                        phi_7323_ = 0i;
                                        loop {
                                            let _e2072 = phi_7326_;
                                            let _e2074 = phi_7323_;
                                            local_45 = _e2072;
                                            if (_e2074 < _e2070) {
                                                phi_7332_ = _e2072;
                                                phi_7329_ = 0i;
                                                loop {
                                                    let _e2077 = phi_7332_;
                                                    let _e2079 = phi_7329_;
                                                    local_54 = _e2077;
                                                    if (_e2079 < _e2070) {
                                                        continue;
                                                    } else {
                                                        break;
                                                    }
                                                    continuing {
                                                        let _e2083 = local_3[_e2079][0u];
                                                        let _e2086 = local_3[_e2074][1u];
                                                        let _e2092 = clamp((_e2003 * ((_e2031 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2083, _e2086))), _e2014.xy, _e2014.zw);
                                                        let _e2095 = local_2[_e2079][0u];
                                                        let _e2098 = local_2[_e2074][1u];
                                                        let _e2104 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2092.x, _e2092.y, _e1973.z).xy, _e1973.z);
                                                        phi_7332_ = (_e2077 + ((_e2095 * _e2098) * _e2104));
                                                        phi_7329_ = (_e2079 + 1i);
                                                    }
                                                }
                                                continue;
                                            } else {
                                                break;
                                            }
                                            continuing {
                                                let _e2673 = local_54;
                                                phi_7326_ = _e2673;
                                                phi_7323_ = (_e2074 + 1i);
                                            }
                                        }
                                        let _e2110 = local_45;
                                        phi_7333_ = (_e2110 * select(0.0069444445f, 0.0625f, _e2034));
                                        break;
                                    }
                                }
                                let _e2113 = phi_7333_;
                                phi_7334_ = _e2113;
                                break;
                            }
                            let _e2114 = (_e1895 - _e1935);
                            let _e2117 = global.member_21[3u];
                            if (_e2114 >= u32(_e2117)) {
                                phi_7334_ = 1f;
                                break;
                            }
                            let _e2122 = global.member_27[_e2114];
                            let _e2125 = global.member_28[_e2114];
                            let _e2127 = _e2122.xyz;
                            let _e2130 = (_e2122.w * length((_e708 - _e2127)));
                            let _e2133 = global.member_25[0u];
                            let _e2139 = global.member_25[1u];
                            let _e2143 = (((_e708 + (_e698 * (_e2130 * _e2133))) + (_e1909 * (_e2130 * _e2139))) - _e2127);
                            let _e2144 = abs(_e2143);
                            let _e2147 = (_e2144.x >= _e2144.y);
                            phi_5879_ = _e2147;
                            if _e2147 {
                                phi_5879_ = (_e2144.x >= _e2144.z);
                            }
                            let _e2151 = phi_5879_;
                            if _e2151 {
                                phi_7310_ = select(1i, 0i, (_e2143.x > 0f));
                                phi_7308_ = _e2144.x;
                            } else {
                                let _e2156 = (_e2144.y >= _e2144.z);
                                if _e2156 {
                                    phi_7311_ = select(3i, 2i, (_e2143.y > 0f));
                                } else {
                                    phi_7311_ = select(5i, 4i, (_e2143.z > 0f));
                                }
                                let _e2164 = phi_7311_;
                                phi_7310_ = _e2164;
                                phi_7308_ = select(_e2144.z, _e2144.y, _e2156);
                            }
                            let _e2167 = phi_7310_;
                            let _e2169 = phi_7308_;
                            if (_e2169 <= 0f) {
                                phi_7334_ = 1f;
                                break;
                            }
                            local_4 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
                            let _e2172 = local_4[_e2167];
                            local_5 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
                            let _e2175 = local_5[_e2167];
                            let _e2180 = global.member_24[2u];
                            let _e2183 = (vec2<f32>(dot(_e2143, _e2172), dot(_e2143, _e2175)) / vec2((_e2169 * _e2180)));
                            let _e2187 = (_e2125.z + (_e2125.w / _e2169));
                            if (_e2187 > 1f) {
                                phi_7334_ = 1f;
                                break;
                            }
                            let _e2202 = global.member_24;
                            let _e2203 = _e2202.xy;
                            let _e2205 = (_e2125.xy + (vec2<f32>(f32((_e2167 - (i32(floor((f32(_e2167) / f32(3i)))) * 3i))), f32((_e2167 / 3i))) * _e2203));
                            let _e2214 = global.member_22;
                            let _e2215 = _e2214.xy;
                            let _e2216 = (_e2215 * 0.5f);
                            let _e2218 = (_e2205 + (vec2<f32>((0.5f + (0.5f * _e2183.x)), (0.5f - (0.5f * _e2183.y))) * _e2203));
                            let _e2219 = (_e2205 + _e2216);
                            let _e2221 = ((_e2205 + _e2203) - _e2216);
                            let _e2226 = vec4<f32>(_e2219.x, _e2219.y, _e2221.x, _e2221.y);
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e2230 = global.member_22[2u];
                                    let _e2231 = i32(_e2230);
                                    if (_e2231 <= 0i) {
                                        let _e2235 = clamp(_e2218, _e2226.xy, _e2226.zw);
                                        let _e2240 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2235.x, _e2235.y, _e2187).xy, _e2187);
                                        phi_7322_ = _e2240;
                                        break;
                                    }
                                    let _e2242 = ((_e2218 / _e2215) + vec2<f32>(0.5f, 0.5f));
                                    let _e2243 = floor(_e2242);
                                    let _e2244 = (_e2242 - _e2243);
                                    let _e2246 = (_e2231 == 1i);
                                    if _e2246 {
                                        let _e2247 = (_e2244 * 2f);
                                        local[0i] = (vec2<f32>(3f, 3f) - _e2247);
                                        local[1i] = (vec2<f32>(1f, 1f) + _e2247);
                                        let _e2253 = local[0i];
                                        local_1[0i] = (((vec2<f32>(2f, 2f) - _e2244) / _e2253) - vec2<f32>(1f, 1f));
                                        let _e2257 = local[1i];
                                        local_1[1i] = ((_e2244 / _e2257) + vec2<f32>(1f, 1f));
                                    } else {
                                        let _e2261 = (_e2244 * 3f);
                                        local[0i] = (vec2<f32>(4f, 4f) - _e2261);
                                        local[1i] = vec2<f32>(7f, 7f);
                                        local[2i] = (vec2<f32>(1f, 1f) + _e2261);
                                        let _e2269 = local[0i];
                                        local_1[0i] = (((vec2<f32>(3f, 3f) - (_e2244 * 2f)) / _e2269) - vec2<f32>(2f, 2f));
                                        let _e2274 = local[1i];
                                        local_1[1i] = ((vec2<f32>(3f, 3f) + _e2244) / _e2274);
                                        let _e2277 = local[2i];
                                        local_1[2i] = ((_e2244 / _e2277) + vec2<f32>(2f, 2f));
                                    }
                                    let _e2282 = select(3i, 2i, _e2246);
                                    phi_7315_ = 0f;
                                    phi_7312_ = 0i;
                                    loop {
                                        let _e2284 = phi_7315_;
                                        let _e2286 = phi_7312_;
                                        local_46 = _e2284;
                                        if (_e2286 < _e2282) {
                                            phi_7321_ = _e2284;
                                            phi_7318_ = 0i;
                                            loop {
                                                let _e2289 = phi_7321_;
                                                let _e2291 = phi_7318_;
                                                local_55 = _e2289;
                                                if (_e2291 < _e2282) {
                                                    continue;
                                                } else {
                                                    break;
                                                }
                                                continuing {
                                                    let _e2295 = local_1[_e2291][0u];
                                                    let _e2298 = local_1[_e2286][1u];
                                                    let _e2304 = clamp((_e2215 * ((_e2243 - vec2<f32>(0.5f, 0.5f)) + vec2<f32>(_e2295, _e2298))), _e2226.xy, _e2226.zw);
                                                    let _e2307 = local[_e2291][0u];
                                                    let _e2310 = local[_e2286][1u];
                                                    let _e2316 = textureSampleCompare(global_1, global_3, vec3<f32>(_e2304.x, _e2304.y, _e2187).xy, _e2187);
                                                    phi_7321_ = (_e2289 + ((_e2307 * _e2310) * _e2316));
                                                    phi_7318_ = (_e2291 + 1i);
                                                }
                                            }
                                            continue;
                                        } else {
                                            break;
                                        }
                                        continuing {
                                            let _e2685 = local_55;
                                            phi_7315_ = _e2685;
                                            phi_7312_ = (_e2286 + 1i);
                                        }
                                    }
                                    let _e2322 = local_46;
                                    phi_7322_ = (_e2322 * select(0.0069444445f, 0.0625f, _e2246));
                                    break;
                                }
                            }
                            let _e2325 = phi_7322_;
                            phi_7334_ = _e2325;
                            break;
                        }
                    }
                    let _e2327 = phi_7334_;
                    phi_7335_ = _e2327;
                } else {
                    phi_7335_ = 1f;
                }
                let _e2329 = phi_7335_;
                let _e2331 = clamp(dot(_e700, _e1909), -1f, 1f);
                let _e2337 = max(cos((0.5f * abs((_e1578 - asin(_e2331))))), 0.05f);
                let _e2339 = (_e1909 - (_e700 * _e2331));
                let _e2345 = (dot(_e2339, _e1588) * inverseSqrt(max((dot(_e2339, _e2339) * _e1591), 0.000001f)));
                let _e2349 = sqrt(clamp((0.5f + (0.5f * _e2345)), 0f, 1f));
                let _e2350 = (_e2331 + _e1577);
                let _e2351 = (_e2350 + _e1602);
                let _e2365 = (1f - clamp(sqrt(clamp((0.5f + (0.5f * dot(_e1909, _e710))), 0f, 1f)), 0f, 1f));
                let _e2366 = (_e2365 * _e2365);
                let _e2374 = (_e2350 - _e1563);
                let _e2384 = (_e2349 * (1f + (0.6451613f * (0.6f - (0.8f * _e2345)))));
                let _e2385 = (_e2384 * _e2384);
                let _e2391 = (1f - clamp((_e2337 * sqrt(clamp((1f - _e2385), 0f, 1f))), 0f, 1f));
                let _e2392 = (_e2391 * _e2391);
                let _e2407 = (0.95348f - (((0.95348f * _e2392) * _e2392) * _e2391));
                let _e2412 = (_e2350 - _e1672);
                let _e2420 = (1f - clamp((_e2337 * 0.5f), 0f, 1f));
                let _e2421 = (_e2420 * _e2420);
                let _e2424 = (((0.95348f * _e2421) * _e2421) * _e2420);
                let _e2433 = (0.95348f - _e2424);
                if _e1573 {
                    let _e2443 = clamp(((dot(_e698, _e1909) * 0.6f) + 0.4f), 0f, 1f);
                    phi_7371_ = (_e2443 * _e2443);
                } else {
                    phi_7371_ = mix(clamp(((dot((_e1588 * inverseSqrt(max(_e1591, 0.000001f))), _e1909) + 1f) * 0.5f), 0f, 1f), (1f - abs(_e2331)), 0.33f);
                }
                let _e2456 = phi_7371_;
                local_53 = (_e1877 + ((((((_e1728 * pow(_e1723, vec3(((1f - _e2329) * 0.35f)))) * _e2456) + (((vec3((((((exp((((-0.5f * _e2351) * _e2351) / _e1607)) / _e1610) * 0.25f) * _e2349) * (0.04652f + (((0.95348f * _e2366) * _e2366) * _e2365))) * 3f)) + (pow(_e1655, vec3((sqrt(clamp((1f - (_e2385 * 0.41623306f)), 0f, 1f)) / _e2337))) * ((((exp((((-0.5f * _e2374) * _e2374) / _e1634)) / _e1637) * exp(((-3.65f * _e2345) - 3.98f))) * _e2407) * _e2407))) + ((pow(_e1655, vec3((0.8f / _e2337))) * (((((exp((((-0.5f * _e2412) * _e2412) / _e1676)) / _e1679) * exp(((17f * _e2345) - 16.78f))) * _e2433) * _e2433) * (0.04652f + _e2424))) * 4f)) * _e1731)) * (_e1912.xyz * ((((_e1906 * _e1906) * _e1923) * _e1923) / max(_e1901, 0.0001f)))) * _e2329) * _e1736));
                continue;
            } else {
                break;
            }
            continuing {
                let _e2665 = local_53;
                phi_7300_ = _e2665;
                phi_7296_ = (_e1879 + bitcast<u32>(1i));
            }
        }
        let _e2696 = local_56;
        phi_7299_ = _e2696;
    }
    let _e2472 = phi_7299_;
    let _e2474 = -(length(_e709));
    let _e2477 = global.member_7[3u];
    let _e2483 = global.member_9[3u];
    phi_7302_ = (1f - exp((_e2474 * _e2477)));
    if (_e2483 != 0f) {
        let _e2487 = (_e2483 * (_e708 - _e707).y);
        if (abs(_e2487) < 0.0001f) {
            phi_7297_ = (1f - (0.5f * _e2487));
        } else {
            phi_7297_ = ((1f - exp(min(-(_e2487), 60f))) / _e2487);
        }
        let _e2498 = phi_7297_;
        let _e2502 = global.member_6[1u];
        let _e2505 = global.member_6[3u];
        phi_7302_ = (1f - exp(((_e2474 * (_e2477 * exp(min((-(_e2483) * (_e2502 - _e2505)), 30f)))) * _e2498)));
    }
    let _e2516 = phi_7302_;
    let _e2518 = global.member_7;
    let _e2521 = mix(_e2472, _e2518.xyz, vec3(_e2516));
    let _e2524 = global.member_33[3u];
    phi_7303_ = _e2521;
    if (_e2524 > 0.5f) {
        phi_7303_ = (_e2521 / (vec3<f32>(1f, 1f, 1f) + _e2521));
    }
    let _e2529 = phi_7303_;
    global_23 = vec4<f32>(_e2529.x, _e2529.y, _e2529.z, _e626);
    let _e2534 = global_25;
    let _e2535 = global_26;
    switch bitcast<i32>(0u) {
        default: {
            if (_e2535.w <= 0f) {
                phi_7304_ = vec2<f32>(0f, 0f);
                break;
            }
            phi_7304_ = (((_e2535.xy / vec2(_e2535.w)) - (_e2534.xy / vec2(_e2534.w))) * vec2<f32>(0.5f, -0.5f));
            break;
        }
    }
    let _e2549 = phi_7304_;
    global_24 = _e2549;
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
