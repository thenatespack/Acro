// Generated from exposure_adapt.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 449e45e48ec9c048
// glsl-fnv1a64: d15be63d50739b57

diagnostic(off, derivative_uniformity);

struct type_3 {
    member: vec2<i32>,
    member_1: f32,
    member_2: f32,
    member_3: f32,
    member_4: f32,
}

@group(3) @binding(0) 
var<uniform> global: type_3;
@group(2) @binding(9) 
var global_1: texture_2d<f32>;
@group(2) @binding(17) 
var global_2: sampler;
@group(2) @binding(10) 
var global_3: texture_2d<f32>;
var<private> global_4: vec4<f32>;

fn function_() {
    var phi_124_: f32;
    var phi_123_: i32;
    var phi_127_: f32;
    var phi_126_: i32;
    var local: f32;
    var local_1: i32;
    var local_2: f32;
    var phi_125_: f32;
    var local_3: f32;

    phi_124_ = 0f;
    phi_123_ = 0i;
    loop {
        let _e16 = phi_124_;
        let _e18 = phi_123_;
        let _e21 = global.member[1u];
        local_1 = _e21;
        local_2 = _e16;
        if (_e18 < _e21) {
            phi_127_ = 0f;
            phi_126_ = 0i;
            loop {
                let _e24 = phi_127_;
                let _e26 = phi_126_;
                let _e29 = global.member[0u];
                local = _e24;
                if (_e26 < _e29) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e32 = textureLoad(global_1, vec2<i32>(_e26, _e18), 0i);
                    phi_127_ = (_e24 + _e32.x);
                    phi_126_ = (_e26 + 1i);
                }
            }
            let _e37 = local;
            local_3 = (_e16 + _e37);
            continue;
        } else {
            break;
        }
        continuing {
            let _e71 = local_3;
            phi_124_ = _e71;
            phi_123_ = (_e18 + 1i);
        }
    }
    let _e42 = global.member[0u];
    let _e44 = local_1;
    let _e48 = local_2;
    let _e51 = global.member_2;
    let _e54 = global.member_3;
    let _e56 = global.member_4;
    let _e57 = clamp((_e51 - (_e48 / f32((_e42 * _e44)))), _e54, _e56);
    let _e58 = textureLoad(global_3, vec2<i32>(0i, 0i), 0i);
    let _e61 = global.member_1;
    if (_e61 >= 1f) {
        phi_125_ = _e57;
    } else {
        phi_125_ = (_e58.x + ((_e57 - _e58.x) * _e61));
    }
    let _e67 = phi_125_;
    global_4 = vec4<f32>(_e67, 0f, 0f, 1f);
    return;
}

@fragment 
fn main() -> @location(0) vec4<f32> {
    function_();
    let _e1 = global_4;
    return _e1;
}
