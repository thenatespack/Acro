// Generated from fsr3_luma_instability.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 55bcae762df76012
// glsl-fnv1a64: 90ab26ec2374ec68

diagnostic(off, derivative_uniformity);

struct type_10 {
    member: vec2<i32>,
    member_1: vec2<i32>,
    member_2: vec2<i32>,
    member_3: vec2<i32>,
    member_4: vec4<f32>,
    member_5: vec2<f32>,
    member_6: vec2<f32>,
    member_7: vec2<f32>,
    member_8: f32,
    member_9: f32,
    member_10: f32,
    member_11: f32,
    member_12: f32,
    member_13: f32,
    member_14: f32,
    member_15: f32,
    member_16: f32,
    member_17: f32,
    member_18: f32,
    member_19: vec2<u32>,
}

@group(3) @binding(0) 
var<uniform> global: type_10;
@group(2) @binding(32) 
var global_1: texture_storage_2d<rgba16float,write>;
@group(2) @binding(11) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;
@group(2) @binding(13) 
var global_4: texture_2d<f32>;
@group(2) @binding(33) 
var global_5: texture_storage_2d<r16float,write>;
@group(2) @binding(10) 
var global_6: texture_2d<f32>;
@group(2) @binding(9) 
var global_7: texture_2d<f32>;
var<private> global_8: vec3<u32>;

fn function_() {
    var local: vec4<f32>;
    var phi_1342_: vec4<f32>;
    var phi_871_: bool;
    var phi_881_: bool;
    var phi_883_: bool;
    var phi_1347_: f32;
    var phi_1349_: f32;
    var phi_1348_: i32;
    var phi_1361_: f32;
    var phi_1365_: f32;
    var local_1: f32;
    var phi_1350_: f32;
    var phi_1360_: f32;
    var phi_1357_: vec4<f32>;
    var phi_1359_: f32;
    var phi_1352_: vec4<f32>;
    var local_2: f32;

    let _e33 = global_8;
    let _e34 = _e33.xy;
    let _e35 = bitcast<vec2<i32>>(_e34);
    let _e36 = textureDimensions(global_6, 0i);
    if all((_e34 < bitcast<vec2<u32>>(vec2<i32>(_e36)))) {
        let _e41 = textureLoad(global_6, _e35, 0i);
        phi_1342_ = _e41;
    } else {
        phi_1342_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e43 = phi_1342_;
    let _e44 = _e43.xy;
    let _e48 = global.member;
    let _e49 = vec2<f32>(_e48);
    let _e50 = ((vec2<f32>(_e35) + vec2<f32>(0.5f, 0.5f)) / _e49);
    let _e52 = global.member_5;
    let _e56 = global.member_6;
    let _e58 = global.member_1;
    let _e59 = vec2<f32>(_e58);
    let _e62 = ((_e50 + (_e56 / _e59)) + _e44);
    let _e64 = (_e62.x >= 0f);
    phi_871_ = _e64;
    if _e64 {
        phi_871_ = (_e62.x <= 1f);
    }
    let _e67 = phi_871_;
    phi_883_ = _e67;
    if _e67 {
        let _e69 = (_e62.y >= 0f);
        phi_881_ = _e69;
        if _e69 {
            phi_881_ = (_e62.y <= 1f);
        }
        let _e72 = phi_881_;
        phi_883_ = _e72;
    }
    let _e74 = phi_883_;
    phi_1359_ = 0f;
    phi_1352_ = vec4<f32>(0f, 0f, 0f, 0f);
    if _e74 {
        let _e79 = (max(vec2<f32>(0.5f, 0.5f), min(((_e50 + (_e52 / _e49)) * _e49), (_e49 - vec2<f32>(0.5f, 0.5f)))) / _e49);
        let _e80 = textureSampleLevel(global_7, global_3, _e79, 0f);
        phi_1360_ = 0f;
        phi_1357_ = vec4<f32>(0f, 0f, 0f, 0f);
        if (clamp(_e80.w, 0f, 1f) > 0.9f) {
            let _e90 = textureSampleLevel(global_4, global_3, _e79, 0f);
            let _e93 = global.member_18;
            let _e95 = select(_e93, 1f, (_e93 == 0f));
            let _e96 = (_e90.x * _e95);
            let _e102 = textureSampleLevel(global_2, global_3, (max(vec2<f32>(0.5f, 0.5f), min((_e62 * _e59), (_e59 - vec2<f32>(0.5f, 0.5f)))) / _e49), 0f);
            let _e104 = global.member_10;
            local = ((_e102 * _e104) * _e95);
            let _e108 = local[0u];
            let _e110 = local[0u];
            let _e111 = max(_e96, _e110);
            if (_e111 != 0f) {
                phi_1347_ = (min(_e96, _e110) / _e111);
            } else {
                phi_1347_ = 1f;
            }
            let _e116 = phi_1347_;
            phi_1350_ = 0f;
            if (_e116 < 1f) {
                phi_1349_ = _e116;
                phi_1348_ = 1i;
                loop {
                    let _e119 = phi_1349_;
                    let _e121 = phi_1348_;
                    local_1 = _e119;
                    if (_e121 <= 3i) {
                        let _e124 = local[_e121];
                        let _e126 = local[_e121];
                        let _e127 = max(_e96, _e126);
                        if (_e127 != 0f) {
                            phi_1361_ = (min(_e96, _e126) / _e127);
                        } else {
                            phi_1361_ = 0f;
                        }
                        let _e132 = phi_1361_;
                        phi_1365_ = _e119;
                        if (sign((_e96 - _e108)) == sign((_e96 - _e124))) {
                            phi_1365_ = max(_e119, _e132);
                        }
                        let _e138 = phi_1365_;
                        local_2 = _e138;
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e197 = local_2;
                        phi_1349_ = _e197;
                        phi_1348_ = (_e121 + 1i);
                    }
                }
                let _e141 = local_1;
                phi_1350_ = select(0f, 1f, (_e141 > _e116));
            }
            let _e145 = phi_1350_;
            let _e147 = local[2u];
            local[3u] = _e147;
            let _e150 = local[1u];
            local[2u] = _e150;
            let _e151 = local[0u];
            local[1u] = _e151;
            local[0u] = _e96;
            let _e152 = local;
            let _e154 = (_e152 / vec4(_e95));
            local = _e154;
            let _e155 = local[3u];
            phi_1360_ = ((_e145 * select(0f, 1f, (_e155 != 0f))) * ((((1f - clamp((length((_e44 * vec2<f32>(3840f, 2160f))) * 0.05f), 0f, 1f)) * (1f - clamp(_e80.y, 0f, 1f))) * (1f - clamp(_e80.x, 0f, 1f))) * (1f - clamp(_e80.z, 0f, 1f))));
            phi_1357_ = _e154;
        }
        let _e172 = phi_1360_;
        let _e174 = phi_1357_;
        phi_1359_ = _e172;
        phi_1352_ = _e174;
    }
    let _e176 = phi_1359_;
    let _e178 = phi_1352_;
    let _e179 = textureDimensions(global_1);
    if all((_e34 < bitcast<vec2<u32>>(vec2<i32>(_e179)))) {
        textureStore(global_1, _e35, _e178);
    }
    let _e184 = textureDimensions(global_5);
    if all((_e34 < bitcast<vec2<u32>>(vec2<i32>(_e184)))) {
        textureStore(global_5, _e35, vec4<f32>(_e176, 0f, 0f, 0f));
    }
    return;
}

@compute @workgroup_size(8, 8, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global_8 = param;
    function_();
}
