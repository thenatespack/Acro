// Generated from tonemap.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: d6bdde9c65d82695
// glsl-fnv1a64: 71279423d5c3e078

diagnostic(off, derivative_uniformity);

struct type_10 {
    member: f32,
    member_1: f32,
    member_2: i32,
    member_3: f32,
    member_4: vec2<i32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
    member_9: vec4<f32>,
    member_10: vec4<f32>,
}

@group(2) @binding(17) 
var global: sampler;
@group(2) @binding(12) 
var global_1: texture_2d<f32>;
@group(3) @binding(0) 
var<uniform> global_2: type_10;
var<private> global_3: vec4<f32>;
@group(2) @binding(9) 
var global_4: texture_2d<f32>;
@group(2) @binding(13) 
var global_5: texture_2d<f32>;
var<private> global_6: vec4<f32>;
@group(2) @binding(10) 
var global_7: texture_2d<f32>;
@group(2) @binding(11) 
var global_8: texture_2d<f32>;

fn function_() {
    var phi_1696_: f32;
    var phi_1698_: vec3<f32>;
    var phi_1682_: vec3<f32>;
    var phi_1684_: vec3<f32>;
    var phi_1685_: f32;
    var phi_1686_: f32;
    var phi_1688_: vec3<f32>;
    var phi_1691_: vec3<f32>;
    var phi_1690_: vec3<f32>;
    var phi_1689_: vec3<f32>;
    var phi_1692_: vec3<f32>;
    var phi_1693_: vec3<f32>;
    var phi_1694_: vec3<f32>;
    var phi_1695_: vec3<f32>;

    switch bitcast<i32>(0u) {
        default: {
            let _e110 = global_3;
            let _e111 = _e110.xy;
            let _e112 = vec2<i32>(_e111);
            let _e113 = textureDimensions(global_4, 0i);
            let _e114 = vec2<i32>(_e113);
            let _e117 = global_2.member_9[3u];
            if (_e117 > 0f) {
                let _e121 = (_e117 * f32(_e114.x));
                let _e123 = f32(_e112.x);
                if (_e123 < (_e121 - 1f)) {
                    let _e126 = textureLoad(global_5, _e112, 0i);
                    let _e128 = max(_e126.xyz, vec3<f32>(0f, 0f, 0f));
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e134 = min(_e128.x, min(_e128.y, _e128.z));
                            if (_e134 < 0.08f) {
                                phi_1696_ = (_e134 - ((6.25f * _e134) * _e134));
                            } else {
                                phi_1696_ = 0.04f;
                            }
                            let _e140 = phi_1696_;
                            let _e142 = (_e128 - vec3(_e140));
                            let _e147 = max(_e142.x, max(_e142.y, _e142.z));
                            if (_e147 < 0.76f) {
                                phi_1698_ = _e142;
                                break;
                            }
                            let _e151 = (1f - (0.0576f / (_e147 + -0.52f)));
                            phi_1698_ = mix((_e142 * (_e151 / _e147)), vec3(_e151), vec3((1f - (1f / ((0.15f * (_e147 - _e151)) + 1f)))));
                            break;
                        }
                    }
                    let _e163 = phi_1698_;
                    let _e164 = clamp(_e163, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
                    global_6 = vec4<f32>(_e164.x, _e164.y, _e164.z, 1f);
                    break;
                }
                if (_e123 < (_e121 + 1f)) {
                    global_6 = vec4<f32>(1f, 1f, 1f, 1f);
                    break;
                }
            }
            let _e171 = textureLoad(global_4, _e112, 0i);
            let _e172 = _e171.xyz;
            let _e175 = vec2<f32>(_e114);
            let _e176 = ((vec2<f32>(_e112) + vec2<f32>(0.5f, 0.5f)) / _e175);
            let _e178 = ((_e176 * 2f) - vec2<f32>(1f, 1f));
            let _e191 = global_2.member_9[0u];
            phi_1682_ = _e172;
            if (_e191 > 0f) {
                let _e197 = (_e114 - vec2<i32>(1i, 1i));
                let _e199 = vec2<i32>(round(((((_e176 - vec2<f32>(0.5f, 0.5f)) * _e175) * _e191) * 0.02f)));
                let _e202 = textureLoad(global_4, clamp((_e112 + _e199), vec2<i32>(0i, 0i), _e197), 0i);
                let _e207 = vec3<f32>(_e202.x, _e172.y, _e172.z);
                let _e210 = textureLoad(global_4, clamp((_e112 - _e199), vec2<i32>(0i, 0i), _e197), 0i);
                phi_1682_ = vec3<f32>(_e207.x, _e207.y, _e210.z);
            }
            let _e217 = phi_1682_;
            let _e219 = global_2.member_1;
            phi_1684_ = _e217;
            if (_e219 > 0f) {
                let _e222 = global_2.member_4;
                let _e226 = (_e112 & vec2<i32>(1i, 1i));
                let _e227 = (((_e112 >> bitcast<vec2<u32>>(vec2<i32>(1i, 1i))) - vec2<i32>(1i, 1i)) + _e226);
                let _e230 = ((vec2<f32>(_e226) * 0.5f) + vec2<f32>(0.25f, 0.25f));
                let _e232 = textureLoad(global_7, clamp(_e227, vec2<i32>(0i, 0i), _e222), 0i);
                let _e236 = textureLoad(global_7, clamp((_e227 + vec2<i32>(1i, 0i)), vec2<i32>(0i, 0i), _e222), 0i);
                let _e240 = textureLoad(global_7, clamp((_e227 + vec2<i32>(0i, 1i)), vec2<i32>(0i, 0i), _e222), 0i);
                let _e244 = textureLoad(global_7, clamp((_e227 + vec2<i32>(1i, 1i)), vec2<i32>(0i, 0i), _e222), 0i);
                let _e247 = vec3(_e230.x);
                phi_1684_ = mix(_e217, mix(mix(_e236.xyz, _e232.xyz, _e247), mix(_e244.xyz, _e240.xyz, _e247), vec3((1f - _e230.y))), vec3(_e219));
            }
            let _e257 = phi_1684_;
            let _e259 = global_2.member;
            let _e261 = global_2.member_3;
            phi_1685_ = _e259;
            if (_e261 > 0.5f) {
                let _e263 = textureLoad(global_8, vec2<i32>(0i, 0i), 0i);
                phi_1685_ = (_e259 * exp2(_e263.x));
            }
            let _e268 = phi_1685_;
            let _e270 = max((_e257 * _e268), vec3<f32>(0f, 0f, 0f));
            let _e272 = global_2.member_2;
            if (_e272 == 1i) {
                phi_1689_ = (_e270 / (vec3<f32>(1f, 1f, 1f) + _e270));
            } else {
                if (_e272 == 2i) {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e282 = min(_e270.x, min(_e270.y, _e270.z));
                            if (_e282 < 0.08f) {
                                phi_1686_ = (_e282 - ((6.25f * _e282) * _e282));
                            } else {
                                phi_1686_ = 0.04f;
                            }
                            let _e288 = phi_1686_;
                            let _e290 = (_e270 - vec3(_e288));
                            let _e295 = max(_e290.x, max(_e290.y, _e290.z));
                            if (_e295 < 0.76f) {
                                phi_1688_ = _e290;
                                break;
                            }
                            let _e299 = (1f - (0.0576f / (_e295 + -0.52f)));
                            phi_1688_ = mix((_e290 * (_e299 / _e295)), vec3(_e299), vec3((1f - (1f / ((0.15f * (_e295 - _e299)) + 1f)))));
                            break;
                        }
                    }
                    let _e311 = phi_1688_;
                    phi_1690_ = _e311;
                } else {
                    phi_1691_ = _e270;
                    if (_e272 == 3i) {
                        let _e316 = vec3<f32>(dot(vec3<f32>(0.59719f, 0.35458f, 0.04823f), _e270), dot(vec3<f32>(0.076f, 0.90834f, 0.01566f), _e270), dot(vec3<f32>(0.0284f, 0.13383f, 0.83777f), _e270));
                        let _e324 = (((_e316 * (_e316 + vec3<f32>(0.0245786f, 0.0245786f, 0.0245786f))) - vec3<f32>(0.000090537f, 0.000090537f, 0.000090537f)) / ((_e316 * ((_e316 * 0.983729f) + vec3<f32>(0.432951f, 0.432951f, 0.432951f))) + vec3<f32>(0.238081f, 0.238081f, 0.238081f)));
                        phi_1691_ = vec3<f32>(dot(vec3<f32>(1.60475f, -0.53108f, -0.07367f), _e324), dot(vec3<f32>(-0.10208f, 1.10813f, -0.00605f), _e324), dot(vec3<f32>(-0.00327f, -0.07276f, 1.07602f), _e324));
                    }
                    let _e330 = phi_1691_;
                    phi_1690_ = _e330;
                }
                let _e332 = phi_1690_;
                phi_1689_ = _e332;
            }
            let _e334 = phi_1689_;
            let _e335 = clamp(_e334, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e338 = global_2.member_10[1u];
            phi_1692_ = _e335;
            if (_e338 > 1.5f) {
                let _e340 = i32(_e338);
                let _e341 = clamp(_e335, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
                let _e351 = (clamp(mix((_e341 * 12.92f), ((pow(_e341, vec3<f32>(0.41666666f, 0.41666666f, 0.41666666f)) * 1.055f) - vec3<f32>(0.055f, 0.055f, 0.055f)), step(vec3<f32>(0.0031308f, 0.0031308f, 0.0031308f), _e341)), vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f)) * f32((_e340 - 1i)));
                let _e356 = min(vec3<i32>(floor(_e351)), vec3((_e340 - 2i)));
                let _e358 = (_e351 - vec3<f32>(_e356));
                let _e362 = (_e356.z * _e340);
                let _e363 = (_e356.x + _e362);
                let _e365 = textureLoad(global_1, vec2<i32>(_e363, _e356.y), 0i);
                let _e367 = (_e356.x + 1i);
                let _e368 = (_e367 + _e362);
                let _e370 = textureLoad(global_1, vec2<i32>(_e368, _e356.y), 0i);
                let _e373 = vec3(_e358.x);
                let _e375 = (_e356.y + 1i);
                let _e377 = textureLoad(global_1, vec2<i32>(_e363, _e375), 0i);
                let _e380 = textureLoad(global_1, vec2<i32>(_e368, _e375), 0i);
                let _e384 = ((_e356.z + 1i) * _e340);
                let _e385 = (_e356.x + _e384);
                let _e387 = textureLoad(global_1, vec2<i32>(_e385, _e356.y), 0i);
                let _e389 = (_e367 + _e384);
                let _e391 = textureLoad(global_1, vec2<i32>(_e389, _e356.y), 0i);
                let _e395 = textureLoad(global_1, vec2<i32>(_e385, _e375), 0i);
                let _e398 = textureLoad(global_1, vec2<i32>(_e389, _e375), 0i);
                let _e402 = vec3(_e358.y);
                let _e408 = clamp(mix(mix(mix(_e365.xyz, _e370.xyz, _e373), mix(_e377.xyz, _e380.xyz, _e373), _e402), mix(mix(_e387.xyz, _e391.xyz, _e373), mix(_e395.xyz, _e398.xyz, _e373), _e402), vec3(_e358.z)), vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
                let _e417 = global_2.member_10[0u];
                phi_1692_ = mix(_e335, mix((_e408 * vec3<f32>(0.07739938f, 0.07739938f, 0.07739938f)), pow(((_e408 + vec3<f32>(0.055f, 0.055f, 0.055f)) * vec3<f32>(0.94786733f, 0.94786733f, 0.94786733f)), vec3<f32>(2.4f, 2.4f, 2.4f)), step(vec3<f32>(0.04045f, 0.04045f, 0.04045f), _e408)), vec3(_e417));
            }
            let _e421 = phi_1692_;
            let _e424 = global_2.member_5[3u];
            phi_1693_ = _e421;
            if (_e424 > 0.5f) {
                let _e429 = global_2.member_8[1u];
                let _e432 = max((((_e421 - vec3<f32>(0.18f, 0.18f, 0.18f)) * _e429) + vec3<f32>(0.18f, 0.18f, 0.18f)), vec3<f32>(0f, 0f, 0f));
                let _e434 = global_2.member_7;
                let _e438 = global_2.member_5;
                let _e445 = global_2.member_6;
                let _e447 = pow(max(((_e432 * _e434.xyz) + (_e438.xyz * (vec3<f32>(1f, 1f, 1f) - _e432))), vec3<f32>(0f, 0f, 0f)), _e445.xyz);
                let _e452 = global_2.member_8[0u];
                phi_1693_ = mix(vec3(dot(_e447, vec3<f32>(0.2126f, 0.7152f, 0.0722f))), _e447, vec3(_e452));
            }
            let _e456 = phi_1693_;
            let _e459 = global_2.member_8[2u];
            phi_1694_ = _e456;
            if (_e459 > 0f) {
                let _e465 = global_2.member_8[3u];
                phi_1694_ = (_e456 * mix(1f, smoothstep(1f, (1f - max(_e465, 0.01f)), (length(vec2<f32>((_e178.x * (f32(_e114.x) / f32(_e114.y))), _e178.y)) * 0.7071f)), _e459));
            }
            let _e472 = phi_1694_;
            let _e475 = global_2.member_9[1u];
            phi_1695_ = _e472;
            if (_e475 > 0f) {
                let _e479 = global_2.member_9[2u];
                let _e486 = fract(((_e111 + vec2((fract(_e479) * 1000f))).xyx * 0.1031f));
                let _e491 = (_e486 + vec3(dot(_e486, (_e486.yzx + vec3<f32>(33.33f, 33.33f, 33.33f)))));
                phi_1695_ = (_e472 + vec3(((((fract(((_e491.x + _e491.y) * _e491.z)) - 0.5f) * _e475) * 0.25f) * (1f - (0.5f * dot(_e472, vec3<f32>(0.2126f, 0.7152f, 0.0722f)))))));
            }
            let _e508 = phi_1695_;
            let _e509 = clamp(_e508, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            global_6 = vec4<f32>(_e509.x, _e509.y, _e509.z, 1f);
            break;
        }
    }
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_3 = param;
    function_();
    let _e3 = global_6;
    return _e3;
}
