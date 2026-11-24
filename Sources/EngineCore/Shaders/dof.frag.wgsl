// Generated from dof.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 8f6172556eb870a3
// glsl-fnv1a64: 0ed45bba6fbcfdd0

diagnostic(off, derivative_uniformity);

struct type_8 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec2<i32>,
    member_3: f32,
    member_4: f32,
}

@group(2) @binding(10) 
var global: texture_2d<f32>;
@group(2) @binding(17) 
var global_1: sampler;
@group(3) @binding(0) 
var<uniform> global_2: type_8;
var<private> global_3: vec4<f32>;
@group(2) @binding(9) 
var global_4: texture_2d<f32>;
var<private> global_5: vec4<f32>;

fn function_() {
    var phi_352_: f32;
    var phi_360_: f32;
    var phi_358_: f32;
    var phi_356_: vec3<f32>;
    var phi_354_: f32;
    var phi_353_: i32;
    var phi_150_: bool;
    var phi_362_: f32;
    var phi_365_: f32;
    var local: f32;
    var local_1: f32;
    var local_2: f32;
    var local_3: vec3<f32>;
    var local_4: f32;
    var local_5: f32;
    var local_6: vec3<f32>;
    var local_7: f32;

    let _e24 = global_3;
    let _e26 = vec2<i32>(_e24.xy);
    let _e27 = textureLoad(global, _e26, 0i);
    let _e31 = global_2.member[2u];
    let _e35 = global_2.member[3u];
    let _e36 = ((_e31 * _e27.x) + _e35);
    if (abs(_e36) < 0.000000000001f) {
        phi_352_ = 1000000f;
    } else {
        let _e41 = global_2.member[0u];
        let _e45 = global_2.member[1u];
        phi_352_ = abs((((_e41 * _e27.x) + _e45) / _e36));
    }
    let _e50 = phi_352_;
    let _e51 = clamp(_e50, 0.0001f, 1000000f);
    let _e54 = global_2.member_1[2u];
    let _e57 = global_2.member_1[0u];
    let _e62 = global_2.member_1[1u];
    let _e69 = global_2.member_1[3u];
    let _e71 = textureLoad(global_4, _e26, 0i);
    let _e74 = global_2.member_3;
    phi_360_ = 0f;
    phi_358_ = 1f;
    phi_356_ = _e71.xyz;
    phi_354_ = _e74;
    phi_353_ = 0i;
    loop {
        let _e76 = phi_360_;
        let _e78 = phi_358_;
        let _e80 = phi_356_;
        let _e82 = phi_354_;
        let _e84 = phi_353_;
        local = _e78;
        local_1 = _e78;
        local_2 = _e78;
        local_3 = _e80;
        let _e85 = (_e84 < 160i);
        phi_150_ = _e85;
        if _e85 {
            phi_150_ = (_e82 < _e69);
        }
        let _e88 = phi_150_;
        if _e88 {
            let _e97 = global_2.member_2;
            let _e98 = clamp((_e26 + vec2<i32>(round((vec2<f32>(cos(_e76), sin(_e76)) * _e82)))), vec2<i32>(0i, 0i), _e97);
            let _e99 = textureLoad(global_4, _e98, 0i);
            let _e101 = textureLoad(global, _e98, 0i);
            let _e104 = ((_e31 * _e101.x) + _e35);
            if (abs(_e104) < 0.000000000001f) {
                phi_362_ = 1000000f;
            } else {
                let _e109 = global_2.member[0u];
                let _e113 = global_2.member[1u];
                phi_362_ = abs((((_e109 * _e101.x) + _e113) / _e104));
            }
            let _e118 = phi_362_;
            let _e119 = clamp(_e118, 0.0001f, 1000000f);
            let _e126 = min(((_e54 * max((abs((_e119 - _e57)) - _e62), 0f)) / _e119), _e69);
            phi_365_ = _e126;
            if (_e119 > _e51) {
                phi_365_ = clamp(_e126, 0f, (min(((_e54 * max((abs((_e51 - _e57)) - _e62), 0f)) / _e51), _e69) * 2f));
            }
            let _e131 = phi_365_;
            local_4 = (_e76 + 2.3999631f);
            local_5 = (_e78 + 1f);
            local_6 = (_e80 + mix((_e80 / vec3(_e78)), _e99.xyz, vec3(smoothstep((_e82 - 0.5f), (_e82 + 0.5f), _e131))));
            local_7 = (_e82 + (_e74 / _e82));
            continue;
        } else {
            break;
        }
        continuing {
            let _e162 = local_4;
            phi_360_ = _e162;
            let _e165 = local_5;
            phi_358_ = _e165;
            let _e168 = local_6;
            phi_356_ = _e168;
            let _e171 = local_7;
            phi_354_ = _e171;
            phi_353_ = (_e84 + 1i);
        }
    }
    let _e146 = local;
    let _e148 = local_1;
    let _e150 = local_2;
    let _e153 = local_3;
    let _e154 = (_e153 / vec3<f32>(_e146, _e148, _e150));
    global_5 = vec4<f32>(_e154.x, _e154.y, _e154.z, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_3 = param;
    function_();
    let _e3 = global_5;
    return _e3;
}
