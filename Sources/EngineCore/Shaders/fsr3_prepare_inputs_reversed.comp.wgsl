// Generated from fsr3_prepare_inputs_reversed.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 0b9dde7c21e5404c
// glsl-fnv1a64: dd4436b606bf0b28

diagnostic(off, derivative_uniformity);

struct type_13 {
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

struct type_23 {
    member: array<u32>,
}

struct type_40 {
    member: array<atomic<u32>>,
}

@group(3) @binding(0) 
var<uniform> global: type_13;
@group(2) @binding(10) 
var global_1: texture_2d<f32>;
@group(2) @binding(11) 
var global_2: texture_2d<f32>;
@group(2) @binding(9) 
var global_3: texture_2d<f32>;
@group(2) @binding(34) 
var global_4: texture_storage_2d<r16float,write>;
@group(2) @binding(35) 
var global_5: texture_storage_2d<r16float,write>;
@group(2) @binding(24) 
var<storage, read_write> global_6: type_40;
@group(2) @binding(33) 
var global_7: texture_storage_2d<r32float,write>;
@group(2) @binding(32) 
var global_8: texture_storage_2d<rg16float,write>;
var<private> global_9: vec3<u32>;

fn function_() {
    var local: array<f32, 4>;
    var local_1: array<vec2<i32>, 4>;
    var local_2: array<vec2<i32>, 9>;
    var local_3: array<f32, 9>;
    var local_4: array<vec2<i32>, 9>;
    var phi_1419_: i32;
    var phi_1432_: vec4<f32>;
    var phi_1423_: f32;
    var phi_1422_: vec2<i32>;
    var phi_1421_: f32;
    var phi_1420_: i32;
    var phi_1435_: f32;
    var phi_1438_: f32;
    var phi_1436_: vec2<i32>;
    var phi_1434_: f32;
    var local_5: vec2<i32>;
    var local_6: vec2<i32>;
    var phi_1424_: vec4<f32>;
    var local_7: f32;
    var phi_1425_: i32;
    var local_8: f32;
    var local_9: f32;
    var local_10: f32;
    var phi_1426_: vec4<f32>;
    var local_11: f32;
    var local_12: vec2<i32>;
    var local_13: f32;

    let _e56 = global_9;
    let _e57 = _e56.xy;
    let _e58 = bitcast<vec2<i32>>(_e57);
    phi_1419_ = 0i;
    loop {
        let _e60 = phi_1419_;
        if (_e60 < 9i) {
            local_2 = array<vec2<i32>, 9>(vec2<i32>(0i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, 1i), vec2<i32>(0i, -1i), vec2<i32>(-1i, 0i), vec2<i32>(-1i, 1i), vec2<i32>(1i, 1i), vec2<i32>(-1i, -1i), vec2<i32>(1i, -1i));
            let _e63 = local_2[_e60];
            let _e64 = (_e58 + _e63);
            let _e66 = textureDimensions(global_1, 0i);
            if all((bitcast<vec2<u32>>(_e64) < bitcast<vec2<u32>>(vec2<i32>(_e66)))) {
                let _e71 = textureLoad(global_1, _e64, 0i);
                phi_1432_ = _e71;
            } else {
                phi_1432_ = vec4<f32>(0f, 0f, 0f, 0f);
            }
            let _e73 = phi_1432_;
            local_3[_e60] = _e73.x;
            continue;
        } else {
            break;
        }
        continuing {
            phi_1419_ = (_e60 + 1i);
        }
    }
    let _e78 = local_3[0i];
    let _e79 = local_3[0i];
    phi_1423_ = _e78;
    phi_1422_ = _e58;
    phi_1421_ = _e79;
    phi_1420_ = 1i;
    loop {
        let _e81 = phi_1423_;
        let _e83 = phi_1422_;
        let _e85 = phi_1421_;
        let _e87 = phi_1420_;
        local_5 = _e83;
        local_6 = _e83;
        local_7 = _e81;
        local_8 = _e81;
        local_9 = _e81;
        local_10 = _e85;
        if (_e87 < 9i) {
            local_4 = array<vec2<i32>, 9>(vec2<i32>(0i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, 1i), vec2<i32>(0i, -1i), vec2<i32>(-1i, 0i), vec2<i32>(-1i, 1i), vec2<i32>(1i, 1i), vec2<i32>(-1i, -1i), vec2<i32>(1i, -1i));
            let _e90 = local_4[_e87];
            let _e91 = (_e58 + _e90);
            let _e93 = global.member;
            phi_1438_ = _e81;
            phi_1436_ = _e83;
            phi_1434_ = _e85;
            if all((bitcast<vec2<u32>>(_e91) < bitcast<vec2<u32>>(_e93))) {
                let _e99 = local_3[_e87];
                let _e100 = (_e99 > _e81);
                phi_1435_ = _e85;
                if _e100 {
                    phi_1435_ = min(_e85, _e99);
                }
                let _e103 = phi_1435_;
                phi_1438_ = select(_e81, _e99, _e100);
                phi_1436_ = select(_e83, _e91, vec2(_e100));
                phi_1434_ = _e103;
            }
            let _e108 = phi_1438_;
            let _e110 = phi_1436_;
            let _e112 = phi_1434_;
            local_11 = _e108;
            local_12 = _e110;
            local_13 = _e112;
            continue;
        } else {
            break;
        }
        continuing {
            let _e246 = local_11;
            phi_1423_ = _e246;
            let _e249 = local_12;
            phi_1422_ = _e249;
            let _e252 = local_13;
            phi_1421_ = _e252;
            phi_1420_ = (_e87 + 1i);
        }
    }
    let _e115 = local_5;
    let _e117 = textureDimensions(global_3, 0i);
    if all((bitcast<vec2<u32>>(_e115) < bitcast<vec2<u32>>(vec2<i32>(_e117)))) {
        let _e123 = local_6;
        let _e124 = textureLoad(global_3, _e123, 0i);
        phi_1424_ = _e124;
    } else {
        phi_1424_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e126 = phi_1424_;
    let _e127 = _e126.xy;
    let _e129 = global.member_4;
    let _e133 = local_7;
    let _e137 = global.member_11;
    let _e151 = global.member;
    let _e152 = vec2<f32>(_e151);
    let _e156 = (((((vec2<f32>(_e58) + vec2<f32>(0.5f, 0.5f)) / _e152) + (_e127 * select(0f, 1f, (length((_e127 * vec2<f32>(3840f, 2160f))) > mix(0.25f, 0.75f, clamp((min(((_e129.y / (_e133 - _e129.x)) * _e137), 65504f) * 0.01f), 0f, 1f)))))) * _e152) - vec2<f32>(0.5f, 0.5f));
    let _e159 = fract(_e156);
    let _e161 = (1f - _e159.x);
    let _e163 = (1f - _e159.y);
    local_1 = array<vec2<i32>, 4>(vec2<i32>(0i, 0i), vec2<i32>(1i, 0i), vec2<i32>(0i, 1i), vec2<i32>(1i, 1i));
    local = array<f32, 4>((_e161 * _e163), (_e159.x * _e163), (_e161 * _e159.y), (_e159.x * _e159.y));
    phi_1425_ = 0i;
    loop {
        let _e170 = phi_1425_;
        if (_e170 < 4i) {
            let _e173 = local_1[_e170];
            let _e175 = local[_e170];
            if (_e175 > 0.00061f) {
                let _e177 = (vec2<i32>(floor(_e156)) + _e173);
                let _e181 = all((bitcast<vec2<u32>>(_e177) < bitcast<vec2<u32>>(_e151)));
                if _e181 {
                    switch bitcast<i32>(0u) {
                        default: {
                            if !(_e181) {
                                break;
                            }
                            let _e185 = local_8;
                            let _e195 = atomicMax((&global_6.member[bitcast<u32>(((_e177.y * _e151.x) + _e177.x))]), bitcast<u32>(_e185));
                            break;
                        }
                    }
                }
            }
            continue;
        } else {
            break;
        }
        continuing {
            phi_1425_ = (_e170 + 1i);
        }
    }
    let _e197 = textureDimensions(global_8);
    if all((_e57 < bitcast<vec2<u32>>(vec2<i32>(_e197)))) {
        textureStore(global_8, _e58, vec4<f32>(_e126.x, _e126.y, 0f, 0f));
    }
    let _e205 = textureDimensions(global_7);
    if all((_e57 < bitcast<vec2<u32>>(vec2<i32>(_e205)))) {
        let _e211 = local_9;
        textureStore(global_7, _e58, vec4<f32>(_e211, 0f, 0f, 0f));
    }
    let _e214 = local_10;
    let _e219 = textureDimensions(global_4);
    if all((_e57 < bitcast<vec2<u32>>(vec2<i32>(_e219)))) {
        textureStore(global_4, _e58, vec4<f32>(min(((_e129.y / (_e214 - _e129.x)) * _e137), 65504f), 0f, 0f, 0f));
    }
    let _e225 = textureDimensions(global_2, 0i);
    if all((_e57 < bitcast<vec2<u32>>(vec2<i32>(_e225)))) {
        let _e230 = textureLoad(global_2, _e58, 0i);
        phi_1426_ = _e230;
    } else {
        phi_1426_ = vec4<f32>(0f, 0f, 0f, 0f);
    }
    let _e232 = phi_1426_;
    let _e236 = textureDimensions(global_5);
    if all((_e57 < bitcast<vec2<u32>>(vec2<i32>(_e236)))) {
        textureStore(global_5, _e58, vec4<f32>(dot(max(vec3<f32>(0f, 0f, 0f), _e232.xyz), vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0f, 0f, 0f));
    }
    return;
}

@compute @workgroup_size(8, 8, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global_9 = param;
    function_();
}
