// Generated from exposure_reduce.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 6bf3fc4809e2b5e4
// glsl-fnv1a64: c5887e23c92485e4

diagnostic(off, derivative_uniformity);

struct type_8 {
    member: vec2<i32>,
    member_1: vec2<i32>,
}

var<private> global: vec4<f32>;
@group(3) @binding(0) 
var<uniform> global_1: type_8;
@group(2) @binding(9) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;
var<private> global_4: vec4<f32>;

fn function_() {
    var phi_124_: f32;
    var phi_123_: i32;
    var phi_127_: f32;
    var phi_125_: i32;
    var local: f32;
    var local_1: f32;

    let _e22 = global;
    phi_124_ = 0f;
    phi_123_ = 0i;
    loop {
        let _e26 = phi_124_;
        let _e28 = phi_123_;
        local = _e26;
        if (_e28 < 8i) {
            phi_127_ = _e26;
            phi_125_ = 0i;
            loop {
                let _e31 = phi_127_;
                let _e33 = phi_125_;
                local_1 = _e31;
                if (_e33 < 8i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e41 = global_1.member;
                    let _e44 = global_1.member_1;
                    let _e47 = textureLoad(global_2, ((((((vec2<i32>(_e22.xy) * vec2<i32>(8i, 8i)) + vec2<i32>(_e33, _e28)) * vec2<i32>(2i, 2i)) + vec2<i32>(1i, 1i)) * _e41) / (_e44 * vec2<i32>(16i, 16i))), 0i);
                    phi_127_ = (_e31 + log2(max(dot(_e47.xyz, vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0.000015258789f)));
                    phi_125_ = (_e33 + 1i);
                }
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e61 = local_1;
            phi_124_ = _e61;
            phi_123_ = (_e28 + 1i);
        }
    }
    let _e56 = local;
    global_4 = vec4<f32>((_e56 * 0.015625f), 0f, 0f, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global = param;
    function_();
    let _e3 = global_4;
    return _e3;
}
