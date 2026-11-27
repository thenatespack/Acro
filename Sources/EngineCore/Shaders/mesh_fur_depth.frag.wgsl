// Generated from mesh_fur_depth.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 4aefead5b55c101e
// glsl-fnv1a64: a072e97be0050a13

diagnostic(off, derivative_uniformity);

struct type_9 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 8>,
}

@group(2) @binding(2) 
var<uniform> global: type_9;
var<private> global_1: vec4<f32>;
var<private> global_2: vec3<f32>;
var<private> global_3: vec2<f32>;
@group(2) @binding(10) 
var global_4: texture_2d<f32>;
@group(2) @binding(17) 
var global_5: sampler;
var<private> global_6: vec3<f32>;
var<private> global_7: vec4<f32>;

fn function_() {
    var phi_1187_: bool;
    var phi_2984_: f32;
    var phi_2983_: f32;
    var phi_3005_: f32;
    var phi_3006_: f32;
    var phi_3003_: f32;
    var phi_3004_: f32;
    var phi_2986_: vec3<f32>;
    var phi_2981_: f32;
    var phi_3000_: f32;
    var phi_2987_: vec3<f32>;
    var phi_2989_: vec3<f32>;
    var phi_2993_: vec3<f32>;
    var phi_2994_: vec3<f32>;
    var phi_2995_: f32;
    var phi_3002_: f32;
    var phi_3007_: f32;

    let _e84 = global_1[2u];
    let _e85 = (_e84 > 0.5f);
    let _e86 = select(1.7f, 1f, _e85);
    switch bitcast<i32>(0u) {
        default: {
            let _e89 = global_1[0u];
            phi_1187_ = _e85;
            if _e85 {
                phi_1187_ = (_e84 < 1.5f);
            }
            let _e92 = phi_1187_;
            let _e93 = (_e84 > 1.5f);
            let _e95 = global_1[3u];
            let _e99 = global.member_1[0i];
            let _e102 = global.member_1[1i];
            let _e105 = global.member_1[2i];
            let _e106 = global_2;
            let _e107 = dpdx(_e106);
            let _e108 = dpdy(_e106);
            let _e110 = global_3[0u];
            let _e111 = dpdx(_e110);
            let _e112 = dpdy(_e110);
            let _e113 = vec2<f32>(_e111, _e112);
            let _e117 = global.member_1[6i][2u];
            phi_2983_ = 1f;
            if ((_e117 > 0.5f) && !(_e93)) {
                let _e121 = global_3;
                let _e122 = textureSample(global_4, global_5, _e121);
                let _e127 = global.member_1[6i][3u];
                phi_2984_ = _e122.x;
                if (_e127 > 0.5f) {
                    phi_2984_ = (1f - _e122.x);
                }
                let _e131 = phi_2984_;
                phi_2983_ = _e131;
            }
            let _e133 = phi_2983_;
            if (_e95 > 0.5f) {
                if (_e133 < 0.02f) {
                    phi_3007_ = 0f;
                    break;
                }
                phi_3007_ = 1f;
                break;
            }
            if _e92 {
                let _e138 = global.member_1[4i][3u];
                let _e139 = max(_e138, 1f);
                let _e140 = (_e110 * _e139);
                let _e142 = (length(_e113) * _e139);
                let _e144 = global_1[1u];
                let _e148 = smoothstep(0.45f, 1.3f, _e142);
                let _e163 = ((min((2f * ((mix(_e99.z, _e99.w, _e89) * 0.5f) * _e86)), 1f) * clamp(((1f - _e89) / max(_e105.y, 0.02f)), 0f, 1f)) * (1f - smoothstep(0.75f, 1f, _e89)));
                phi_3006_ = _e163;
                if (_e148 < 0.999f) {
                    let _e169 = bitcast<vec3<u32>>((vec3<i32>(vec3<f32>(floor(_e140), floor((_e144 * 65535f)), 7f)) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e177 = (((_e169.x * 1597334677u) ^ (_e169.y * 3812015801u)) ^ (_e169.z * 2798796415u));
                    let _e181 = ((_e177 ^ (_e177 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e184 = (_e181 ^ (_e181 >> bitcast<u32>(13i)));
                    let _e185 = (_e184 * 3266489917u);
                    let _e194 = (vec3<f32>(f32((_e184 & 65535u)), f32(((_e185 ^ (_e185 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                    let _e204 = (1f - (_e105.y * _e194.y));
                    phi_3005_ = 0f;
                    if (_e89 <= _e204) {
                        let _e207 = (_e89 / max(_e204, 0.001f));
                        let _e210 = ((mix(_e99.z, _e99.w, _e207) * 0.5f) * _e86);
                        let _e212 = (0.5f * max(_e142, 0.0001f));
                        let _e213 = max(_e210, _e212);
                        phi_3005_ = (((1f - smoothstep((_e213 - _e212), (_e213 + _e212), abs(((fract(_e140) - 0.5f) + ((_e194.x - 0.5f) * 0.3f))))) * (_e210 / _e213)) * (1f - smoothstep(0.75f, 1f, _e207)));
                    }
                    let _e224 = phi_3005_;
                    phi_3006_ = mix(_e224, _e163, _e148);
                }
                let _e227 = phi_3006_;
                phi_3007_ = _e227;
                break;
            }
            if _e93 {
                let _e228 = length(_e113);
                let _e230 = max(_e105.y, 0.3f);
                let _e231 = smoothstep(0.45f, 1.3f, _e228);
                let _e246 = ((min((2f * ((mix(_e99.z, _e99.w, _e89) * 0.5f) * _e86)), 1f) * clamp(((1f - _e89) / max(_e230, 0.02f)), 0f, 1f)) * (1f - smoothstep(0.75f, 1f, _e89)));
                phi_3004_ = _e246;
                if (_e231 < 0.999f) {
                    let _e252 = bitcast<vec3<u32>>((vec3<i32>(vec3<f32>(floor(_e110), 3f, 7f)) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e260 = (((_e252.x * 1597334677u) ^ (_e252.y * 3812015801u)) ^ (_e252.z * 2798796415u));
                    let _e264 = ((_e260 ^ (_e260 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e267 = (_e264 ^ (_e264 >> bitcast<u32>(13i)));
                    let _e268 = (_e267 * 3266489917u);
                    let _e277 = (vec3<f32>(f32((_e267 & 65535u)), f32(((_e268 ^ (_e268 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                    let _e287 = (1f - (_e230 * _e277.y));
                    phi_3003_ = 0f;
                    if (_e89 <= _e287) {
                        let _e290 = (_e89 / max(_e287, 0.001f));
                        let _e293 = ((mix(_e99.z, _e99.w, _e290) * 0.5f) * _e86);
                        let _e295 = (0.5f * max(_e228, 0.0001f));
                        let _e296 = max(_e293, _e295);
                        phi_3003_ = (((1f - smoothstep((_e296 - _e295), (_e296 + _e295), abs(((fract(_e110) - 0.5f) + ((_e277.x - 0.5f) * 0.3f))))) * (_e293 / _e296)) * (1f - smoothstep(0.75f, 1f, _e290)));
                    }
                    let _e307 = phi_3003_;
                    phi_3004_ = mix(_e307, _e246, _e231);
                }
                let _e310 = phi_3004_;
                phi_3007_ = (((_e310 * 0.6f) * smoothstep(0f, 0.35f, _e89)) * (1f - smoothstep(0.3f, 0.9f, _e228)));
                break;
            }
            let _e318 = max(_e99.y, 0.00001f);
            let _e319 = global_6;
            let _e320 = normalize(_e319);
            phi_2986_ = _e106;
            phi_2981_ = 1f;
            if (_e102.x > 0f) {
                let _e323 = (_e318 * 4f);
                let _e326 = floor((_e106 / vec3(_e323)));
                let _e331 = bitcast<vec3<u32>>((vec3<i32>((_e326 + vec3<f32>(31f, 17f, 5f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e339 = (((_e331.x * 1597334677u) ^ (_e331.y * 3812015801u)) ^ (_e331.z * 2798796415u));
                let _e343 = ((_e339 ^ (_e339 >> bitcast<u32>(15i))) * 2246822519u);
                let _e346 = (_e343 ^ (_e343 >> bitcast<u32>(13i)));
                let _e347 = (_e346 * 3266489917u);
                let _e350 = (_e347 ^ (_e347 >> bitcast<u32>(16i)));
                let _e351 = (_e350 * 668265263u);
                let _e366 = (((_e326 + vec3<f32>(0.5f, 0.5f, 0.5f)) + (((vec3<f32>(f32((_e346 & 65535u)), f32((_e350 & 65535u)), f32(((_e351 ^ (_e351 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)) - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.6f)) * _e323);
                let _e370 = (_e366 - (_e320 * dot((_e366 - _e106), _e320)));
                let _e375 = (1f / (1f - min(((_e102.x * _e89) * 0.85f), 0.9f)));
                phi_2986_ = (_e370 + ((_e106 - _e370) * _e375));
                phi_2981_ = _e375;
            }
            let _e380 = phi_2986_;
            let _e382 = phi_2981_;
            let _e386 = ((_e107 - (_e320 * dot(_e107, _e320))) * _e382);
            let _e390 = ((_e108 - (_e320 * dot(_e108, _e320))) * _e382);
            let _e395 = (sqrt(max(dot(_e386, _e386), dot(_e390, _e390))) / _e318);
            let _e396 = smoothstep(0.6f, 1.6f, _e395);
            let _e397 = min(_e133, 1f);
            let _e402 = ((mix(_e99.z, _e99.w, _e89) * 0.5f) * _e86);
            phi_3000_ = 0f;
            if ((_e396 > 0.001f) && (_e397 > 0.01f)) {
                let _e411 = (_e106 / vec3((_e318 * 3f)));
                let _e412 = floor(_e411);
                let _e413 = (_e411 - _e412);
                let _e417 = ((_e413 * _e413) * (vec3<f32>(3f, 3f, 3f) - (_e413 * 2f)));
                let _e420 = bitcast<vec3<u32>>((vec3<i32>(_e412) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e428 = (((_e420.x * 1597334677u) ^ (_e420.y * 3812015801u)) ^ (_e420.z * 2798796415u));
                let _e432 = ((_e428 ^ (_e428 >> bitcast<u32>(15i))) * 2246822519u);
                let _e444 = bitcast<vec3<u32>>((vec3<i32>((_e412 + vec3<f32>(1f, 0f, 0f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e452 = (((_e444.x * 1597334677u) ^ (_e444.y * 3812015801u)) ^ (_e444.z * 2798796415u));
                let _e456 = ((_e452 ^ (_e452 >> bitcast<u32>(15i))) * 2246822519u);
                let _e466 = vec2(_e417.x);
                let _e471 = bitcast<vec3<u32>>((vec3<i32>((_e412 + vec3<f32>(0f, 1f, 0f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e479 = (((_e471.x * 1597334677u) ^ (_e471.y * 3812015801u)) ^ (_e471.z * 2798796415u));
                let _e483 = ((_e479 ^ (_e479 >> bitcast<u32>(15i))) * 2246822519u);
                let _e495 = bitcast<vec3<u32>>((vec3<i32>((_e412 + vec3<f32>(1f, 1f, 0f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e503 = (((_e495.x * 1597334677u) ^ (_e495.y * 3812015801u)) ^ (_e495.z * 2798796415u));
                let _e507 = ((_e503 ^ (_e503 >> bitcast<u32>(15i))) * 2246822519u);
                let _e518 = vec2(_e417.y);
                let _e523 = bitcast<vec3<u32>>((vec3<i32>((_e412 + vec3<f32>(0f, 0f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e531 = (((_e523.x * 1597334677u) ^ (_e523.y * 3812015801u)) ^ (_e523.z * 2798796415u));
                let _e535 = ((_e531 ^ (_e531 >> bitcast<u32>(15i))) * 2246822519u);
                let _e547 = bitcast<vec3<u32>>((vec3<i32>((_e412 + vec3<f32>(1f, 0f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e555 = (((_e547.x * 1597334677u) ^ (_e547.y * 3812015801u)) ^ (_e547.z * 2798796415u));
                let _e559 = ((_e555 ^ (_e555 >> bitcast<u32>(15i))) * 2246822519u);
                let _e572 = bitcast<vec3<u32>>((vec3<i32>((_e412 + vec3<f32>(0f, 1f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e580 = (((_e572.x * 1597334677u) ^ (_e572.y * 3812015801u)) ^ (_e572.z * 2798796415u));
                let _e584 = ((_e580 ^ (_e580 >> bitcast<u32>(15i))) * 2246822519u);
                let _e596 = bitcast<vec3<u32>>((vec3<i32>((_e412 + vec3<f32>(1f, 1f, 1f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e604 = (((_e596.x * 1597334677u) ^ (_e596.y * 3812015801u)) ^ (_e596.z * 2798796415u));
                let _e608 = ((_e604 ^ (_e604 >> bitcast<u32>(15i))) * 2246822519u);
                let _e628 = (_e89 / _e397);
                phi_3000_ = (((3.1415927f * _e402) * _e402) * mix(clamp(((((1f - (_e105.y * mix(mix(mix((vec3<f32>(f32(((_e432 ^ (_e432 >> bitcast<u32>(13i))) & 65535u)), f32(), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32(((_e456 ^ (_e456 >> bitcast<u32>(13i))) & 65535u)), f32(), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e466), mix((vec3<f32>(f32(((_e483 ^ (_e483 >> bitcast<u32>(13i))) & 65535u)), f32(), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32(((_e507 ^ (_e507 >> bitcast<u32>(13i))) & 65535u)), f32(), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e466), _e518), mix(mix((vec3<f32>(f32(((_e535 ^ (_e535 >> bitcast<u32>(13i))) & 65535u)), f32(), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32(((_e559 ^ (_e559 >> bitcast<u32>(13i))) & 65535u)), f32(), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e466), mix((vec3<f32>(f32(((_e584 ^ (_e584 >> bitcast<u32>(13i))) & 65535u)), f32(), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, (vec3<f32>(f32(((_e608 ^ (_e608 >> bitcast<u32>(13i))) & 65535u)), f32(), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)).xy, _e466), _e518), vec2(_e417.z)).x)) - _e628) / max((_e105.y * 0.35f), 0.04f)) + 0.5f), 0f, 1f), clamp(((1f - _e628) / max(_e105.y, 0.02f)), 0f, 1f), smoothstep(2f, 5f, _e395)));
            }
            let _e640 = phi_3000_;
            phi_3002_ = _e640;
            if (_e396 < 0.999f) {
                let _e644 = floor((_e380 / vec3(_e318)));
                let _e647 = bitcast<vec3<u32>>((vec3<i32>(_e644) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                let _e655 = (((_e647.x * 1597334677u) ^ (_e647.y * 3812015801u)) ^ (_e647.z * 2798796415u));
                let _e659 = ((_e655 ^ (_e655 >> bitcast<u32>(15i))) * 2246822519u);
                let _e662 = (_e659 ^ (_e659 >> bitcast<u32>(13i)));
                let _e663 = (_e662 * 3266489917u);
                let _e666 = (_e663 ^ (_e663 >> bitcast<u32>(16i)));
                let _e667 = (_e666 * 668265263u);
                let _e678 = (vec3<f32>(f32((_e662 & 65535u)), f32((_e666 & 65535u)), f32(((_e667 ^ (_e667 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                let _e683 = (((_e644 + vec3<f32>(0.5f, 0.5f, 0.5f)) + ((_e678 - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.5f)) * _e318);
                if (abs(_e320.y) < 0.9f) {
                    phi_2987_ = cross(_e320, vec3<f32>(0f, 1f, 0f));
                } else {
                    phi_2987_ = cross(_e320, vec3<f32>(1f, 0f, 0f));
                }
                let _e690 = phi_2987_;
                let _e691 = normalize(_e690);
                phi_2989_ = _e683;
                if (_e102.y > 0f) {
                    let _e698 = ((_e89 * 12.566f) + (_e678.x * 6.283f));
                    phi_2989_ = (_e683 + (((_e691 * cos(_e698)) + (cross(_e320, _e691) * sin(_e698))) * ((_e102.y * 0.3f) * _e318)));
                }
                let _e709 = phi_2989_;
                phi_2993_ = _e709;
                if (_e102.z > 0f) {
                    let _e712 = (_e89 * 4f);
                    let _e714 = (floor(_e712) * 7f);
                    let _e719 = bitcast<vec3<u32>>((vec3<i32>((_e644 + vec3<f32>(_e714, 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e727 = (((_e719.x * 1597334677u) ^ (_e719.y * 3812015801u)) ^ (_e719.z * 2798796415u));
                    let _e731 = ((_e727 ^ (_e727 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e734 = (_e731 ^ (_e731 >> bitcast<u32>(13i)));
                    let _e735 = (_e734 * 3266489917u);
                    let _e738 = (_e735 ^ (_e735 >> bitcast<u32>(16i)));
                    let _e739 = (_e738 * 668265263u);
                    let _e756 = bitcast<vec3<u32>>((vec3<i32>((_e644 + vec3<f32>((_e714 + 7f), 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e764 = (((_e756.x * 1597334677u) ^ (_e756.y * 3812015801u)) ^ (_e756.z * 2798796415u));
                    let _e768 = ((_e764 ^ (_e764 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e771 = (_e768 ^ (_e768 >> bitcast<u32>(13i)));
                    let _e772 = (_e771 * 3266489917u);
                    let _e775 = (_e772 ^ (_e772 >> bitcast<u32>(16i)));
                    let _e776 = (_e775 * 668265263u);
                    phi_2993_ = (_e709 + ((mix((vec3<f32>(f32((_e734 & 65535u)), f32((_e738 & 65535u)), f32(((_e739 ^ (_e739 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), (vec3<f32>(f32((_e771 & 65535u)), f32((_e775 & 65535u)), f32(((_e776 ^ (_e776 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), vec3(smoothstep(0f, 1f, fract(_e712)))) - vec3<f32>(0.5f, 0.5f, 0.5f)) * (((_e102.z * 0.4f) * _e318) * _e89)));
                }
                let _e799 = phi_2993_;
                let _e800 = (_e380 - _e799);
                let _e803 = (_e800 - (_e320 * dot(_e800, _e320)));
                let _e808 = ((1f - (_e105.y * _e678.y)) * _e397);
                phi_2995_ = 0f;
                if (_e89 <= _e808) {
                    let _e815 = (((mix(_e99.z, _e99.w, (_e89 / max(_e808, 0.001f))) * 0.5f) * _e318) * _e86);
                    let _e816 = length(_e803);
                    if (_e816 > 0.000000001f) {
                        phi_2994_ = (_e803 / vec3(_e816));
                    } else {
                        phi_2994_ = _e691;
                    }
                    let _e821 = phi_2994_;
                    let _e822 = dot(_e386, _e821);
                    let _e824 = dot(_e390, _e821);
                    let _e830 = (0.5f * max(sqrt(((_e822 * _e822) + (_e824 * _e824))), (_e318 * 0.001f)));
                    let _e831 = max(_e815, _e830);
                    let _e832 = (_e815 / _e831);
                    phi_2995_ = (((1f - smoothstep((_e831 - _e830), (_e831 + _e830), _e816)) * _e832) * _e832);
                }
                let _e840 = phi_2995_;
                phi_3002_ = mix(_e840, _e640, _e396);
            }
            let _e843 = phi_3002_;
            phi_3007_ = _e843;
            break;
        }
    }
    let _e845 = phi_3007_;
    let _e846 = global_7;
    if (_e845 <= ((fract((52.982918f * fract(dot(_e846.xy, vec2<f32>(0.06711056f, 0.00583715f))))) * 0.98f) + 0.01f)) {
        discard;
    }
    return;
}

@fragment 
fn main(@location(8) param: vec4<f32>, @location(4) param_1: vec3<f32>, @location(2) param_2: vec2<f32>, @location(10) param_3: vec3<f32>, @builtin(position) param_4: vec4<f32>) {
    global_1 = param;
    global_2 = param_1;
    global_3 = param_2;
    global_6 = param_3;
    global_7 = param_4;
    function_();
}
