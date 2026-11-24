// Generated from env_downsample.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 3c5a07c7c55f9623
// glsl-fnv1a64: 8bc218e852f50e2c

diagnostic(off, derivative_uniformity);

struct type_6 {
    member: i32,
    member_1: i32,
}

var<private> global: vec4<f32>;
@group(3) @binding(0) 
var<uniform> global_1: type_6;
@group(2) @binding(9) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;
var<private> global_4: vec4<f32>;

fn function_() {
    var phi_153_: f32;
    var phi_152_: vec3<f32>;
    var phi_151_: i32;
    var phi_155_: vec3<f32>;
    var phi_154_: i32;
    var local: vec3<f32>;
    var local_1: f32;
    var local_2: f32;
    var local_3: f32;
    var local_4: vec3<f32>;
    var local_5: f32;
    var local_6: vec3<f32>;

    let _e12 = global;
    let _e16 = global_1.member;
    let _e18 = (vec2<i32>(_e12.xy) * vec2(_e16));
    phi_153_ = 0f;
    phi_152_ = vec3<f32>(0f, 0f, 0f);
    phi_151_ = 0i;
    loop {
        let _e20 = phi_153_;
        let _e22 = phi_152_;
        let _e24 = phi_151_;
        local_1 = _e20;
        local_2 = _e20;
        local_3 = _e20;
        local_4 = _e22;
        if (_e24 < _e16) {
            let _e27 = (_e18.y + _e24);
            let _e31 = global_1.member_1;
            let _e35 = sin((((f32(_e27) + 0.5f) / f32(_e31)) * 3.1415927f));
            phi_155_ = vec3<f32>(0f, 0f, 0f);
            phi_154_ = 0i;
            loop {
                let _e37 = phi_155_;
                let _e39 = phi_154_;
                local = _e37;
                if (_e39 < _e16) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e44 = textureLoad(global_2, vec2<i32>((_e18.x + _e39), _e27), 0i);
                    phi_155_ = (_e37 + _e44.xyz);
                    phi_154_ = (_e39 + 1i);
                }
            }
            let _e49 = local;
            local_5 = (_e20 + (_e35 * f32(_e16)));
            local_6 = (_e22 + (_e49 * _e35));
            continue;
        } else {
            break;
        }
        continuing {
            let _e72 = local_5;
            phi_153_ = _e72;
            let _e75 = local_6;
            phi_152_ = _e75;
            phi_151_ = (_e24 + 1i);
        }
    }
    let _e57 = local_1;
    let _e59 = local_2;
    let _e61 = local_3;
    let _e64 = local_4;
    let _e65 = (_e64 / vec3<f32>(_e57, _e59, _e61));
    global_4 = vec4<f32>(_e65.x, _e65.y, _e65.z, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global = param;
    function_();
    let _e3 = global_4;
    return _e3;
}
