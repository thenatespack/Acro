// Generated from probe_store.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 9074fe49add72079
// glsl-fnv1a64: 05345543a44a840e

diagnostic(off, derivative_uniformity);

struct type_10 {
    member: vec4<i32>,
    member_1: vec4<f32>,
}

struct type_17 {
    member: array<u32>,
}

var<private> global: vec3<u32>;
@group(3) @binding(0) 
var<uniform> global_1: type_10;
@group(2) @binding(9) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;
@group(2) @binding(24) 
var<storage, read_write> global_4: type_17;

fn function_() {
    var local: array<f32, 32>;
    var phi_43_: bool;
    var phi_215_: i32;
    var phi_216_: i32;
    var phi_217_: i32;

    switch bitcast<i32>(0u) {
        default: {
            let _e24 = global;
            let _e26 = bitcast<vec2<i32>>(_e24.xy);
            let _e30 = global_1.member[0u];
            let _e31 = (_e26.x >= _e30);
            phi_43_ = _e31;
            if !(_e31) {
                let _e36 = global_1.member[1u];
                phi_43_ = (_e26.y >= _e36);
            }
            let _e39 = phi_43_;
            if _e39 {
                break;
            }
            let _e40 = textureLoad(global_2, _e26, 0i);
            let _e43 = ((_e26.y * _e30) + _e26.x);
            let _e46 = global_1.member[3u];
            if (_e46 == 0i) {
                let _e50 = global_1.member[2u];
                let _e52 = (_e50 + (_e43 * 2i));
                global_4.member[_e52] = pack2x16float(_e40.xy);
                global_4.member[(_e52 + 1i)] = pack2x16float(_e40.zw);
            } else {
                if (_e43 == 0i) {
                    phi_215_ = 0i;
                    loop {
                        let _e64 = phi_215_;
                        if (_e64 < 9i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e67 = textureLoad(global_2, vec2<i32>(_e64, 0i), 0i);
                            let _e68 = (_e64 * 3i);
                            local[_e68] = _e67.x;
                            local[(_e68 + 1i)] = _e67.y;
                            local[(_e68 + 2i)] = _e67.z;
                            phi_215_ = (_e64 + 1i);
                        }
                    }
                    let _e80 = global_1.member_1[0u];
                    local[27i] = _e80;
                    phi_216_ = 28i;
                    loop {
                        let _e83 = phi_216_;
                        if (_e83 < 32i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            local[_e83] = 0f;
                            phi_216_ = (_e83 + 1i);
                        }
                    }
                    phi_217_ = 0i;
                    loop {
                        let _e88 = phi_217_;
                        if (_e88 < 16i) {
                            continue;
                        } else {
                            break;
                        }
                        continuing {
                            let _e92 = global_1.member[2u];
                            let _e94 = (_e88 * 2i);
                            let _e96 = local[_e94];
                            let _e99 = local[(_e94 + 1i)];
                            global_4.member[(_e92 + _e88)] = pack2x16float(vec2<f32>(_e96, _e99));
                            phi_217_ = (_e88 + 1i);
                        }
                    }
                }
            }
            break;
        }
    }
    return;
}

@compute @workgroup_size(8, 8, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global = param;
    function_();
}
