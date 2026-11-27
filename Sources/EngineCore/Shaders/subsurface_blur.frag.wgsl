// Generated from subsurface_blur.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: cbbb534940e8d3ea
// glsl-fnv1a64: bc9898baf9cea962

diagnostic(off, derivative_uniformity);

struct type_9 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<i32>,
}

struct type_16 {
    member: array<vec4<f32>, 25>,
}

@group(2) @binding(10) 
var global: texture_2d<f32>;
@group(2) @binding(17) 
var global_1: sampler;
@group(3) @binding(0) 
var<uniform> global_2: type_9;
var<private> global_3: vec4<f32>;
@group(2) @binding(9) 
var global_4: texture_2d<f32>;
var<private> global_5: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_6: type_16;

fn function_() {
    var phi_401_: vec3<f32>;
    var phi_402_: f32;
    var phi_184_: bool;
    var phi_406_: vec3<f32>;
    var phi_403_: i32;
    var phi_408_: vec3<f32>;
    var phi_409_: f32;
    var phi_410_: vec3<f32>;
    var phi_404_: vec3<f32>;
    var phi_407_: vec4<f32>;
    var local: vec3<f32>;
    var local_1: vec3<f32>;

    switch bitcast<i32>(0u) {
        default: {
            let _e29 = global_3;
            let _e31 = vec2<i32>(_e29.xy);
            let _e32 = textureLoad(global_4, _e31, 0i);
            let _e35 = global_2.member_1[3u];
            let _e36 = (_e35 > 0.5f);
            if (_e32.w > -0.5f) {
                global_5 = vec4<f32>(_e32.x, _e32.y, _e32.z, select(_e32.w, 1f, _e36));
                break;
            }
            let _e45 = max((-1f - _e32.w), 0f);
            if _e36 {
                phi_401_ = _e32.xyz;
            } else {
                phi_401_ = max((_e32.xyz - vec3(_e45)), vec3<f32>(0f, 0f, 0f));
            }
            let _e52 = phi_401_;
            let _e53 = textureLoad(global, _e31, 0i);
            let _e57 = global_2.member[2u];
            let _e61 = global_2.member[3u];
            let _e62 = ((_e57 * _e53.x) + _e61);
            if (abs(_e62) < 0.000000000001f) {
                phi_402_ = 1000000f;
            } else {
                let _e67 = global_2.member[0u];
                let _e71 = global_2.member[1u];
                phi_402_ = abs((((_e67 * _e53.x) + _e71) / _e62));
            }
            let _e76 = phi_402_;
            let _e77 = clamp(_e76, 0.0001f, 1000000f);
            let _e80 = global_2.member_1[0u];
            let _e83 = global_2.member_1[1u];
            let _e85 = ((_e80 * _e83) / _e77);
            let _e89 = global_6.member[1i][3u];
            let _e90 = (_e85 * _e89);
            let _e91 = (_e90 > 0.25f);
            phi_184_ = _e91;
            if !(_e91) {
                phi_184_ = (_e90 < -0.25f);
            }
            let _e95 = phi_184_;
            phi_404_ = _e52;
            if _e95 {
                let _e98 = global_6.member[0i];
                let _e103 = global_2.member_1[2u];
                phi_406_ = (_e52 * _e98.xyz);
                phi_403_ = 1i;
                loop {
                    let _e106 = phi_406_;
                    let _e108 = phi_403_;
                    local_1 = _e106;
                    if (_e108 < i32(_e103)) {
                        let _e112 = global_6.member[_e108];
                        let _e114 = global_2.member_2;
                        let _e123 = global_2.member_3;
                        let _e125 = clamp((_e31 + vec2<i32>(round((_e114.xy * (_e112.w * _e85))))), vec2<i32>(0i, 0i), _e123.xy);
                        let _e126 = textureLoad(global_4, _e125, 0i);
                        phi_410_ = _e52;
                        if (_e126.w < -0.5f) {
                            if _e36 {
                                phi_408_ = _e126.xyz;
                            } else {
                                phi_408_ = max((_e126.xyz - vec3(max((-1f - _e126.w), 0f))), vec3<f32>(0f, 0f, 0f));
                            }
                            let _e137 = phi_408_;
                            let _e138 = textureLoad(global, _e125, 0i);
                            let _e141 = ((_e57 * _e138.x) + _e61);
                            if (abs(_e141) < 0.000000000001f) {
                                phi_409_ = 1000000f;
                            } else {
                                let _e146 = global_2.member[0u];
                                let _e150 = global_2.member[1u];
                                phi_409_ = abs((((_e146 * _e138.x) + _e150) / _e141));
                            }
                            let _e155 = phi_409_;
                            let _e161 = global_2.member_2[2u];
                            phi_410_ = mix(_e137, _e52, vec3(clamp((abs((clamp(_e155, 0.0001f, 1000000f) - _e77)) * _e161), 0f, 1f)));
                        }
                        let _e167 = phi_410_;
                        local = (_e106 + (_e112.xyz * _e167));
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e191 = local;
                        phi_406_ = _e191;
                        phi_403_ = (_e108 + 1i);
                    }
                }
                let _e198 = local_1;
                phi_404_ = _e198;
            }
            let _e173 = phi_404_;
            if _e36 {
                let _e175 = (_e173 + vec3(_e45));
                phi_407_ = vec4<f32>(_e175.x, _e175.y, _e175.z, 1f);
            } else {
                phi_407_ = vec4<f32>(_e173.x, _e173.y, _e173.z, _e32.w);
            }
            let _e185 = phi_407_;
            global_5 = _e185;
            break;
        }
    }
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_3 = param;
    function_();
    let _e3 = global_5;
    return _e3;
}
