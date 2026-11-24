// Generated from bloom_up.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 4fe6ec8fa5f05808
// glsl-fnv1a64: fb37b91f71b9693a

diagnostic(off, derivative_uniformity);

struct type_12 {
    member: vec2<i32>,
}

@group(2) @binding(17) 
var global: sampler;
var<private> global_1: vec4<f32>;
@group(2) @binding(9) 
var global_2: texture_2d<f32>;
@group(3) @binding(0) 
var<uniform> global_3: type_12;
@group(2) @binding(10) 
var global_4: texture_2d<f32>;
var<private> global_5: vec4<f32>;

fn function_() {
    var local: vec4<f32>;
    var local_1: vec4<f32>;
    var phi_299_: i32;
    var phi_301_: i32;
    var phi_304_: vec3<f32>;
    var phi_303_: i32;
    var phi_306_: vec3<f32>;
    var phi_305_: i32;
    var local_2: vec3<f32>;
    var local_3: vec3<f32>;
    var local_4: vec3<f32>;

    let _e23 = global_1;
    let _e25 = vec2<i32>(_e23.xy);
    let _e27 = global_3.member;
    let _e30 = (_e25.x >> bitcast<u32>(1i));
    let _e32 = ((_e25.x & 1i) == 0i);
    if _e32 {
        phi_299_ = (_e30 - 2i);
    } else {
        phi_299_ = (_e30 - 1i);
    }
    let _e36 = phi_299_;
    local = select(vec4<f32>(0.1875f, 0.4375f, 0.3125f, 0.0625f), vec4<f32>(0.0625f, 0.3125f, 0.4375f, 0.1875f), vec4(_e32));
    let _e41 = (_e25.y >> bitcast<u32>(1i));
    let _e43 = ((_e25.y & 1i) == 0i);
    if _e43 {
        phi_301_ = (_e41 - 2i);
    } else {
        phi_301_ = (_e41 - 1i);
    }
    let _e47 = phi_301_;
    local_1 = select(vec4<f32>(0.1875f, 0.4375f, 0.3125f, 0.0625f), vec4<f32>(0.0625f, 0.3125f, 0.4375f, 0.1875f), vec4(_e43));
    phi_304_ = vec3<f32>(0f, 0f, 0f);
    phi_303_ = 0i;
    loop {
        let _e51 = phi_304_;
        let _e53 = phi_303_;
        local_3 = _e51;
        if (_e53 < 4i) {
            phi_306_ = vec3<f32>(0f, 0f, 0f);
            phi_305_ = 0i;
            loop {
                let _e56 = phi_306_;
                let _e58 = phi_305_;
                local_2 = _e56;
                if (_e58 < 4i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e64 = textureLoad(global_2, clamp(vec2<i32>((_e36 + _e58), (_e47 + _e53)), vec2<i32>(0i, 0i), _e27), 0i);
                    let _e67 = local[_e58];
                    phi_306_ = (_e56 + (_e64.xyz * _e67));
                    phi_305_ = (_e58 + 1i);
                }
            }
            let _e72 = local_1[_e53];
            let _e74 = local_2;
            local_4 = (_e51 + (_e74 * _e72));
            continue;
        } else {
            break;
        }
        continuing {
            let _e92 = local_4;
            phi_304_ = _e92;
            phi_303_ = (_e53 + 1i);
        }
    }
    let _e78 = textureLoad(global_4, _e25, 0i);
    let _e81 = local_3;
    let _e83 = ((_e78.xyz + _e81) * 0.5f);
    global_5 = vec4<f32>(_e83.x, _e83.y, _e83.z, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_1 = param;
    function_();
    let _e3 = global_5;
    return _e3;
}
